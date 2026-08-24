<#
.SYNOPSIS
    Link this repo into ~/.claude so Claude Code loads its config from here.

.DESCRIPTION
    Creates directory junctions (no elevation or Developer Mode needed) for
    agents/, hooks/, rules/, and skills/ under ~/.claude, pointing back into
    this repo. Junctions already pointing at the right target are left
    alone; junctions pointing elsewhere (e.g. after the repo folder moved or
    was renamed) are replaced. A real directory occupying a link path is
    never removed unless -Force is passed.

    CLAUDE.md and settings.json cannot be junctioned (file symlinks require
    elevation or Developer Mode, and hard links silently break when git
    replaces the file by rename on pull/checkout), so they are mirrored as
    plain copies: copied when missing at home, reported when they drift,
    and pushed repo -> home only with -Force. Reconcile drift manually
    before forcing — the home copy may hold edits the repo lacks.

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

$RepoRoot  = Split-Path -Parent $PSScriptRoot
$LinkDirs  = 'agents', 'hooks', 'rules', 'skills'
$MirrorFiles = 'CLAUDE.md', 'settings.json'
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

foreach ($name in $LinkDirs) {
    $target = Join-Path $RepoRoot $name
    $link   = Join-Path $ClaudeDir $name

    if (-not (Test-Path $target)) {
        Write-Warning "Repo directory missing, skipped: $target"
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

foreach ($name in $MirrorFiles) {
    $src = Join-Path $RepoRoot $name
    $dst = Join-Path $ClaudeDir $name

    if (-not (Test-Path $src)) {
        Write-Warning "Repo file missing, skipped: $src"
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
