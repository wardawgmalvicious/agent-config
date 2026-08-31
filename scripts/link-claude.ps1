<#
.SYNOPSIS
    Link this repo into ~/.claude (or a project .claude) so Claude Code
    loads its config from here.

.DESCRIPTION
    Creates directory junctions (no elevation or Developer Mode needed) for
    agents/, hooks/, mcp/, and rules/ under $ClaudeDir, pointing back into
    this repo. The repo-side sources are NOT all at the repo root: content
    written in Claude Code's own formats lives under claude/ (claude/agents,
    claude/hooks, claude/rules, claude/mcp), while skills/ stays at the root
    in the tool-neutral Agent Skills format. See $LinkDirs for the mapping.
    (Claude Code itself doesn't read ~/.claude/mcp; the junction exists so
    the template-copy commands documented in claude/mcp/README.md resolve
    from a stable path.) Junctions already pointing at the right target are
    left alone; junctions pointing elsewhere (e.g. after the repo folder
    moved, was renamed, or after payload moved under claude/) are replaced.
    A real directory occupying a link path is never removed unless -Force
    is passed.

    SKILLS ARE DIFFERENT. The repo groups them by domain (skills/fabric/,
    skills/powerbi/, skills/workflow/), but Claude Code only discovers a
    skill at <skills-root>/<name>/SKILL.md — one level, with no group
    directory in between. A single junction for skills/ would therefore
    surface nothing at all. So $ClaudeDir/skills is a REAL directory
    holding one junction per skill, each pointing at its grouped source.
    Claude Code documents that a skill entry may be a symlink, and that it
    loads a given target once even when reachable from several locations.

    -SkillGroups selects which groups deploy, which is what makes a partial
    payload possible: pair it with -ClaudeDir and -SkillsOnly to push just
    the Fabric skills into a client repo's .claude/ without also linking
    this machine's agents, hooks, and rules there.

    Deselecting a group PRUNES its skills from the target on the next run.
    Pruning only ever deletes a junction whose target resolves inside this
    repo's skills/ tree, so a real directory or a link to somewhere else —
    a skill authored directly in the target, or one linked from another
    repo — is always left alone.

    CLAUDE.md and settings.json cannot be junctioned (file symlinks require
    elevation or Developer Mode, and hard links silently break when git
    replaces the file by rename on pull/checkout), so they are mirrored as
    plain copies: copied when missing at the target, reported when they
    drift, and pushed repo -> target only with -Force. Reconcile drift
    manually before forcing — the target copy may hold edits the repo lacks.

    ~/.claude/CLAUDE.md (user scope, all projects) is sourced from the
    repo's claude/CLAUDE.md — NOT the repo-root CLAUDE.md, which is
    project-scope instructions for working on this repo and is never
    deployed. settings.json is likewise sourced from claude/settings.json.

    settings.json gets a key-level comparison instead of a byte comparison:
    Claude Code rewrites the live copy at runtime (e.g. the model pin), so
    the check passes when every repo key is present at the target with an
    equal value, and target-only keys are ignored. -Force merges repo keys
    into the target (top-level, whole-key replacement) and keeps
    target-only keys.

    Idempotent; safe to re-run any time, including after moving or renaming
    the repo folder (the script resolves targets from its own location).

.PARAMETER Force
    Replace a real directory occupying a link path (its contents are
    DELETED) and overwrite drifted target copies of CLAUDE.md /
    settings.json with the repo versions.

.PARAMETER ClaudeDir
    The Claude Code config directory to link into. Defaults to ~/.claude.
    Point it at a project's .claude to deploy a partial payload there, or
    at a scratch directory to test this script.

.PARAMETER SkillGroups
    Which skill groups under skills/ to deploy. Defaults to all of them.
    Groups not listed are pruned from the target — see the description.

.PARAMETER SkillsOnly
    Deploy skills and nothing else: no agents/hooks/rules/mcp junctions and
    no CLAUDE.md / settings.json mirroring. Intended for project targets,
    which want this repo's skills but their own everything else.

.EXAMPLE
    ./scripts/link-claude.ps1
    Verify and relink the full user-scope payload, reporting drift.

.EXAMPLE
    ./scripts/link-claude.ps1 -Force
    Same, and push drifted CLAUDE.md / settings.json to the target.

.EXAMPLE
    ./scripts/link-claude.ps1 -SkillGroups workflow
    User scope, but only the behavioral skills; fabric and powerbi are
    pruned from ~/.claude/skills.

.EXAMPLE
    ./scripts/link-claude.ps1 -ClaudeDir C:\Repos\Client\.claude -SkillGroups fabric,powerbi -SkillsOnly
    Give a client repo the platform skills and nothing else.
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [string]$ClaudeDir = (Join-Path $HOME '.claude'),
    [string[]]$SkillGroups,
    [switch]$SkillsOnly
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
# Repo-relative source -> directory name under $ClaudeDir. The source and
# the destination differ because the repo groups Claude-format payload
# under claude/, while skills/ stays at the repo root in the tool-neutral
# Agent Skills format. The destination names are what Claude Code expects
# and never change, so hook commands in settings.json ($HOME/.claude/...)
# stay valid no matter how the repo side is arranged. skills/ is absent
# here on purpose: it deploys per-skill, not as one junction.
$LinkDirs = @(
    @{ Source = 'claude/agents'; Dest = 'agents' }
    @{ Source = 'claude/hooks';  Dest = 'hooks' }
    @{ Source = 'claude/rules';  Dest = 'rules' }
    @{ Source = 'claude/mcp';    Dest = 'mcp' }
)
# Repo-relative source -> filename under $ClaudeDir. Root CLAUDE.md is
# project-scope for this repo and deliberately absent here.
$MirrorFiles = @(
    @{ Source = 'claude/CLAUDE.md';     Dest = 'CLAUDE.md' }
    @{ Source = 'claude/settings.json'; Dest = 'settings.json' }
)
$SkillsRoot = [IO.Path]::GetFullPath((Join-Path $RepoRoot 'skills'))
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

function Set-Junction {
    # Point $Link at $Target, reusing a correct junction, replacing a stale
    # one, and refusing a real directory unless -Force. Returns $true when
    # the link ends up correct.
    param([string]$Link, [string]$Target, [string]$Label)

    $existing = Get-Item $Link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $currentTarget = Get-LinkTarget $existing
            if ($currentTarget -and (Test-SamePath $currentTarget $Target)) {
                Write-Host "OK      $Label -> $currentTarget"
                return $true
            }
            # Stale junction (repo moved/renamed, or the skill changed
            # group). Deleting a reparse point removes only the link, never
            # the target's contents.
            $existing.Delete()
            Write-Host "Relink  $Label (was -> $currentTarget)"
        }
        else {
            if (-not $Force) {
                Write-Warning ("$Link is a real directory, not a junction. " +
                    "Move it aside, or re-run with -Force to DELETE it and link the repo.")
                $script:DriftCount++
                return $false
            }
            Remove-Item $Link -Recurse -Force
            Write-Host "Removed real directory $Link (-Force)"
        }
    }

    New-Item -ItemType Junction -Path $Link -Target $Target | Out-Null
    Write-Host "Linked  $Label -> $Target"
    return $true
}

if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
    Write-Host "Created $ClaudeDir"
}

#region Format-payload junctions (agents, hooks, rules, mcp)
if ($SkillsOnly) {
    Write-Host "Skipped agents/hooks/rules/mcp (-SkillsOnly)"
}
else {
    foreach ($dir in $LinkDirs) {
        $target = Join-Path $RepoRoot $dir.Source
        if (-not (Test-Path $target)) {
            # Counts as drift: any existing junction still points at the
            # vanished path, so rules silently stop loading and the hooks
            # in settings.json stop firing.
            Write-Warning "Repo directory missing, skipped: $target"
            $script:DriftCount++
            continue
        }
        $null = Set-Junction -Link (Join-Path $ClaudeDir $dir.Dest) -Target $target -Label $dir.Dest
    }
}
#endregion

#region Skills (one junction per skill, selected by group)
$availableGroups = @(Get-ChildItem $SkillsRoot -Directory |
    Select-Object -ExpandProperty Name | Sort-Object)

if ($SkillGroups) {
    $unknown = @($SkillGroups | Where-Object { $availableGroups -notcontains $_ })
    if ($unknown.Count -gt 0) {
        throw ("Unknown skill group(s): $($unknown -join ', '). " +
               "Available: $($availableGroups -join ', ')")
    }
    $selectedGroups = @($SkillGroups)
}
else {
    $selectedGroups = $availableGroups
}

# Skill name -> grouped source directory. Names must be unique across
# groups: they collapse into one flat namespace at the target, and Claude
# Code addresses a skill by name alone.
$desiredSkills = [ordered]@{}
foreach ($group in $selectedGroups) {
    foreach ($skill in Get-ChildItem (Join-Path $SkillsRoot $group) -Directory) {
        if (-not (Test-Path (Join-Path $skill.FullName 'SKILL.md'))) {
            Write-Warning "No SKILL.md, skipped: skills/$group/$($skill.Name)"
            $script:DriftCount++
            continue
        }
        if ($desiredSkills.Contains($skill.Name)) {
            throw ("Duplicate skill name '$($skill.Name)' in more than one group. " +
                   "Skill names are a flat namespace at the target; rename one.")
        }
        $desiredSkills[$skill.Name] = $skill.FullName
    }
}

$skillsDir = Join-Path $ClaudeDir 'skills'
$existingSkillsDir = Get-Item $skillsDir -Force -ErrorAction SilentlyContinue
if ($existingSkillsDir -and
    ($existingSkillsDir.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    # Legacy layout: skills/ was one junction back when the repo tree was
    # flat. Grouping made that surface nothing, because Claude Code only
    # looks one level deep. Deleting the reparse point leaves the repo's
    # skills untouched.
    $existingSkillsDir.Delete()
    Write-Host "Removed legacy skills junction (replaced by per-skill links)"
    $existingSkillsDir = $null
}
if (-not $existingSkillsDir) {
    New-Item -ItemType Directory -Path $skillsDir | Out-Null
    Write-Host "Created $skillsDir"
}

$linked = 0
foreach ($name in $desiredSkills.Keys) {
    if (Set-Junction -Link (Join-Path $skillsDir $name) -Target $desiredSkills[$name] -Label "skills/$name") {
        $linked++
    }
}

# Prune skills from deselected groups. Only ever touch a junction whose
# target resolves inside this repo's skills/ tree — a real directory, or a
# link into another repo, belongs to someone else.
$pruned = 0
foreach ($item in Get-ChildItem $skillsDir -Force -ErrorAction SilentlyContinue) {
    if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
    if ($desiredSkills.Contains($item.Name)) { continue }
    $itemTarget = Get-LinkTarget $item
    if (-not $itemTarget) { continue }
    if (-not ([IO.Path]::GetFullPath($itemTarget).StartsWith($SkillsRoot, [StringComparison]::OrdinalIgnoreCase))) { continue }
    $item.Delete()
    Write-Host "Pruned  skills/$($item.Name) (not in selected groups)"
    $pruned++
}

Write-Host ("Skills  $linked linked from group(s): $($selectedGroups -join ', ')" +
            $(if ($pruned) { "; $pruned pruned" } else { '' }))
#endregion

#region Mirrored files (CLAUDE.md, settings.json)
if ($SkillsOnly) {
    Write-Host "Skipped CLAUDE.md/settings.json mirroring (-SkillsOnly)"
}
else {
    foreach ($mirror in $MirrorFiles) {
        $src  = Join-Path $RepoRoot $mirror.Source
        $dst  = Join-Path $ClaudeDir $mirror.Dest
        $name = $mirror.Dest

        if (-not (Test-Path $src)) {
            # Counts as drift so a mistyped or half-completed rename fails
            # loudly instead of leaving the target copy silently stale.
            Write-Warning "Repo file missing, skipped: $src"
            $script:DriftCount++
            continue
        }
        if (-not (Test-Path $dst)) {
            Copy-Item $src $dst
            Write-Host "Copied  $name (target copy was missing)"
            continue
        }
        if ($name -eq 'settings.json') {
            $srcJson = Get-Content $src -Raw | ConvertFrom-Json
            $dstJson = Get-Content $dst -Raw | ConvertFrom-Json
            if (Test-JsonSubset $srcJson $dstJson) {
                Write-Host "OK      $name (repo keys all present at target)"
            }
            elseif ($Force) {
                foreach ($p in $srcJson.PSObject.Properties) {
                    $dstJson | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force
                }
                $dstJson | ConvertTo-Json -Depth 32 | Set-Content $dst
                Write-Host "Merged  $name repo keys -> target (-Force; target-only keys kept)"
            }
            else {
                Write-Warning ("$name : repo keys are missing or differ at the target. " +
                    "Diff and reconcile (repo: $src | target: $dst), or re-run with -Force " +
                    "to merge repo keys into the target (target-only keys are kept).")
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
            Write-Host "Pushed  $name repo -> target (-Force overwrote drifted copy)"
        }
        else {
            Write-Warning ("$name differs between repo and target. The target copy may hold " +
                "edits the repo lacks — diff and reconcile (repo: $src | target: $dst), " +
                "or re-run with -Force to overwrite the target with the repo version.")
            $script:DriftCount++
        }
    }
}
#endregion

if ($script:DriftCount -gt 0) {
    Write-Host "`nDone with $script:DriftCount item(s) needing attention (see warnings above)."
    exit 1
}
Write-Host "`nDone. All links verified."
exit 0
