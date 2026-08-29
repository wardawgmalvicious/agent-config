<#
.SYNOPSIS
    Link this repo into ~/.claude so Claude Code loads its config from here.

.DESCRIPTION
    Creates directory junctions (no elevation or Developer Mode needed) for
    agents/, hooks/, mcp/, rules/, and skills/ under ~/.claude, pointing
    back into this repo. The repo-side sources are NOT all at the repo
    root: Claude-only payload lives under claude/ (claude/agents,
    claude/hooks, claude/rules), while skills/ and mcp/ stay at the root
    because more than one tool consumes them. See $LinkDirs for the
    mapping. (Claude Code itself doesn't read ~/.claude/mcp; the junction
    exists so the template-copy commands documented in mcp/README.md
    resolve from a stable path.) Junctions already pointing at the right
    target are left alone; junctions pointing elsewhere (e.g. after the
    repo folder moved, was renamed, or after payload moved under claude/)
    are replaced. A real directory occupying a link path is never removed
    unless -Force is passed.

    CLAUDE.md and settings.json cannot be junctioned (file symlinks require
    elevation or Developer Mode, and hard links silently break when git
    replaces the file by rename on pull/checkout), so they are mirrored as
    plain copies: copied when missing at home, reported when they drift,
    and pushed repo -> home only with -Force. Reconcile drift manually
    before forcing — the home copy may hold edits the repo lacks.

    ~/.claude/CLAUDE.md (user scope, all projects) is sourced from the
    repo's claude/CLAUDE.md — NOT the repo-root CLAUDE.md, which is
    project-scope instructions for working on this repo and is never
    deployed. settings.json is likewise sourced from claude/settings.json.

    settings.json gets a key-level comparison instead of a byte comparison:
    Claude Code rewrites the live copy at runtime (e.g. the model pin), so
    the check passes when every repo key is present in home with an equal
    value, and home-only keys are ignored. -Force merges repo keys into
    home (top-level, whole-key replacement) and keeps home-only keys.

    Idempotent; safe to re-run any time, including after moving or renaming
    the repo folder (the script resolves targets from its own location).

.PARAMETER Force
    Replace a real directory occupying a link path (its contents are
    DELETED) and overwrite drifted home copies of CLAUDE.md / settings.json
    with the repo versions.

.PARAMETER ClaudeDir
    The Claude Code config directory to link into. Defaults to ~/.claude.
    Mainly for testing the script against a scratch directory.

.EXAMPLE
    ./scripts/link-claude.ps1           # verify + relink, report drift
    ./scripts/link-claude.ps1 -Force    # also push drifted mirror files
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [string]$ClaudeDir = (Join-Path $HOME '.claude')
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
# Repo-relative source -> directory name under $ClaudeDir. The source and
# the destination differ because the repo groups Claude-only payload under
# claude/, while skills/ and mcp/ stay at the repo root — more than one
# tool consumes those. The destination names are what Claude Code expects
# and never change, so hook commands in settings.json ($HOME/.claude/...)
# stay valid no matter how the repo side is arranged.
$LinkDirs = @(
    @{ Source = 'claude/agents'; Dest = 'agents' }
    @{ Source = 'claude/hooks';  Dest = 'hooks' }
    @{ Source = 'claude/rules';  Dest = 'rules' }
    @{ Source = 'mcp';           Dest = 'mcp' }
    @{ Source = 'skills';        Dest = 'skills' }
)
# Repo-relative source -> filename under $ClaudeDir. Root CLAUDE.md is
# project-scope for this repo and deliberately absent here.
$MirrorFiles = @(
    @{ Source = 'claude/CLAUDE.md';    Dest = 'CLAUDE.md' }
    @{ Source = 'claude/settings.json'; Dest = 'settings.json' }
)
$script:DriftCount = 0

function Get-LinkTarget([System.IO.FileSystemInfo]$Item) {
    # PS 7.1+ exposes LinkTarget; Windows PowerShell 5.1 exposes Target
    # (possibly as an array).
    if ($Item.PSObject.Properties['LinkTarget'] -and $Item.LinkTarget) {
        return $Item.LinkTarget
    }
    if ($Item.PSObject.Properties['Target'] -and $Item.Target) {
        return @($Item.Target)[0]
    }
    return $null
}

function Test-SamePath([string]$A, [string]$B) {
    [IO.Path]::GetFullPath($A).TrimEnd('\') -ieq [IO.Path]::GetFullPath($B).TrimEnd('\')
}

function Test-JsonSubset($Subset, $Superset) {
    # True when every key/value in $Subset exists with an equal value in
    # $Superset. Extra keys in $Superset are allowed.
    if ($Subset -is [System.Management.Automation.PSCustomObject]) {
        if ($Superset -isnot [System.Management.Automation.PSCustomObject]) { return $false }
        foreach ($p in $Subset.PSObject.Properties) {
            $match = $Superset.PSObject.Properties[$p.Name]
            if (-not $match) { return $false }
            if (-not (Test-JsonSubset $p.Value $match.Value)) { return $false }
        }
        return $true
    }
    if ($Subset -is [Array]) {
        if ($Superset -isnot [Array] -or $Subset.Count -ne $Superset.Count) { return $false }
        for ($i = 0; $i -lt $Subset.Count; $i++) {
            if (-not (Test-JsonSubset $Subset[$i] $Superset[$i])) { return $false }
        }
        return $true
    }
    return $Subset -eq $Superset
}

if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
    Write-Host "Created $ClaudeDir"
}

foreach ($dir in $LinkDirs) {
    $name   = $dir.Dest
    $target = Join-Path $RepoRoot $dir.Source
    $link   = Join-Path $ClaudeDir $name

    if (-not (Test-Path $target)) {
        # Counts as drift: any existing ~/.claude junction still points
        # at the vanished path, so rules and skills silently stop
        # loading and the hooks in settings.json stop firing.
        Write-Warning "Repo directory missing, skipped: $target"
        $script:DriftCount++
        continue
    }

    $existing = Get-Item $link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $currentTarget = Get-LinkTarget $existing
            if ($currentTarget -and (Test-SamePath $currentTarget $target)) {
                Write-Host "OK      $name -> $currentTarget"
                continue
            }
            # Stale junction (repo moved/renamed). Deleting a reparse point
            # removes only the link, never the target's contents.
            $existing.Delete()
            Write-Host "Relink  $name (was -> $currentTarget)"
        }
        else {
            if (-not $Force) {
                Write-Warning ("$link is a real directory, not a junction. " +
                    "Move it aside, or re-run with -Force to DELETE it and link the repo.")
                $script:DriftCount++
                continue
            }
            Remove-Item $link -Recurse -Force
            Write-Host "Removed real directory $link (-Force)"
        }
    }

    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Host "Linked  $name -> $target"
}

foreach ($mirror in $MirrorFiles) {
    $src  = Join-Path $RepoRoot $mirror.Source
    $dst  = Join-Path $ClaudeDir $mirror.Dest
    $name = $mirror.Dest

    if (-not (Test-Path $src)) {
        # Counts as drift so a mistyped or half-completed rename fails
        # loudly instead of leaving the home copy silently stale.
        Write-Warning "Repo file missing, skipped: $src"
        $script:DriftCount++
        continue
    }
    if (-not (Test-Path $dst)) {
        Copy-Item $src $dst
        Write-Host "Copied  $name (home copy was missing)"
        continue
    }
    if ($name -eq 'settings.json') {
        $srcJson = Get-Content $src -Raw | ConvertFrom-Json
        $dstJson = Get-Content $dst -Raw | ConvertFrom-Json
        if (Test-JsonSubset $srcJson $dstJson) {
            Write-Host "OK      $name (repo keys all present in home)"
        }
        elseif ($Force) {
            foreach ($p in $srcJson.PSObject.Properties) {
                $dstJson | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force
            }
            $dstJson | ConvertTo-Json -Depth 32 | Set-Content $dst
            Write-Host "Merged  $name repo keys -> home (-Force; home-only keys kept)"
        }
        else {
            Write-Warning ("$name : repo keys are missing or differ in the home copy. " +
                "Diff and reconcile (repo: $src | home: $dst), or re-run with -Force " +
                "to merge repo keys into home (home-only keys are kept).")
            $script:DriftCount++
        }
        continue
    }

    if ((Get-FileHash $src).Hash -eq (Get-FileHash $dst).Hash) {
        Write-Host "OK      $name (in sync)"
        continue
    }
    if ($Force) {
        Copy-Item $src $dst -Force
        Write-Host "Pushed  $name repo -> home (-Force overwrote drifted copy)"
    }
    else {
        Write-Warning ("$name differs between repo and home. The home copy may hold " +
            "edits the repo lacks — diff and reconcile (repo: $src | home: $dst), " +
            "or re-run with -Force to overwrite home with the repo version.")
        $script:DriftCount++
    }
}

if ($script:DriftCount -gt 0) {
    Write-Host "`nDone with $script:DriftCount item(s) needing attention (see warnings above)."
    exit 1
}
Write-Host "`nDone. All links verified."
exit 0
