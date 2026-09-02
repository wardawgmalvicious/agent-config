<#
.SYNOPSIS
    Link this repo into ~/.claude (or a project .claude) so Claude Code
    loads its config from here.

.DESCRIPTION
    Copies agents/, hooks/, mcp/, and rules/ into $ClaudeDir as real
    directories of real files. The repo-side sources are NOT all at the repo
    root: content written in Claude Code's own formats lives under claude/
    (claude/agents, claude/hooks, claude/rules, claude/mcp), while skills/
    stays at the root in the tool-neutral Agent Skills format. See $CopyDirs
    for the mapping. (Claude Code itself doesn't read ~/.claude/mcp; the
    copy exists so the template-copy commands documented in
    claude/mcp/README.md resolve from a stable path.)

    THESE FOUR WERE JUNCTIONS UNTIL 2026-09-02 and are copies now. A
    junction made every save live for every session on the machine before it
    was committed, which is wrong for payload that is not hot-reloaded:
    Claude Code watches skill directories, but agents, hooks and rules need
    a fresh session regardless, so immediacy bought nothing while a mid-edit
    state cost plenty. Hooks were the sharp end - they EXECUTE, so a
    half-written .sh fired on every matching tool call in every live
    session. Ordinary git operations (switch, stash, reset, rebase, and
    pre-commit's own stash/restore around a commit) all mutated live config
    as a side effect. A run of this script is now the only thing that does.

    The repo always wins on CONTENT here: nothing under these four is
    authored at the target, so a differing file is stale rather than
    precious and is overwritten without -Force. Files present only at the
    target are the opposite case - they may be hand-authored - so they are
    reported and deleted only with -Force. An existing junction is migrated
    in place: the replacement is staged alongside and swapped in, so the
    window in which a live session could miss a hook is a rename rather than
    a recursive copy.

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

    CLAUDE.md and settings.json are copies too, but on stricter terms than
    the four directories above, because the target copy really can hold
    edits the repo lacks: Claude Code rewrites settings.json at runtime.
    They are copied when missing, reported when they drift, and pushed
    repo -> target only with -Force. Reconcile drift manually before
    forcing. (They could not be junctioned in any case: file symlinks
    require elevation or Developer Mode, and hard links silently break when
    git replaces the file by rename on pull/checkout.)

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
    Delete target-only files under agents/hooks/rules/mcp that the repo no
    longer has, replace a real directory occupying a skill link path (its
    contents are DELETED), and overwrite drifted target copies of CLAUDE.md
    / settings.json with the repo versions. Pushing repo content into the
    four copied directories does NOT need it - the repo always wins there.

.PARAMETER ClaudeDir
    The Claude Code config directory to link into. Defaults to ~/.claude.
    Point it at a project's .claude to deploy a partial payload there, or
    at a scratch directory to test this script.

.PARAMETER SkillGroups
    Which skill groups under skills/ to deploy. Defaults to all of them.
    Groups not listed are pruned from the target — see the description.

.PARAMETER SkillsOnly
    Deploy skills and nothing else: no agents/hooks/rules/mcp copies and
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
    ./scripts/link-claude.ps1 -SkillGroups workflow -Force
    Same as above example but pushes drifted CLAUDE.md / settings.json to the target.

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
# here on purpose: it deploys per-skill, and stays JUNCTIONED because it is
# the one payload Claude Code hot-reloads, which is what makes edit-to-live
# worth its cost there. See the .DESCRIPTION for why these four are not.
$CopyDirs = @(
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

function Sync-PayloadDirectory {
    # Mirror $Source onto $Dest as real files. Content is one-way: nothing
    # under these directories is authored at the target, so a file that
    # differs is stale rather than precious and is overwritten with no
    # -Force. A file the target has and the repo does not is the opposite
    # case, since it may be hand-authored, so it is reported and removed
    # only with -Force.
    param([string]$Source, [string]$Dest, [string]$Label)

    $sourceRoot = [IO.Path]::GetFullPath($Source)
    $destRoot   = [IO.Path]::GetFullPath($Dest)
    $existing   = Get-Item $destRoot -Force -ErrorAction SilentlyContinue

    if ($existing -and ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        # Legacy layout: this directory was a junction into the repo. Stage
        # the replacement alongside and swap, so a live session's window to
        # miss a hook is one rename instead of a whole recursive copy.
        # Deleting a reparse point removes only the link, never the target.
        $leaf    = Split-Path -Leaf $destRoot
        $staging = Join-Path (Split-Path -Parent $destRoot) "$leaf.migrating"
        if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
        New-Item -ItemType Directory -Path $staging | Out-Null
        Copy-Item -Path (Join-Path $sourceRoot '*') -Destination $staging -Recurse -Force
        $existing.Delete()
        Rename-Item -Path $staging -NewName $leaf
        Write-Host "Migrated $Label from junction to copy (staged swap)"
    }
    elseif (-not $existing) {
        New-Item -ItemType Directory -Path $destRoot | Out-Null
        Write-Host "Created $Label"
    }

    $sourceFiles     = @(Get-ChildItem $sourceRoot -Recurse -File -Force)
    $sourceRelatives = @{}
    $copied = 0
    $same   = 0

    foreach ($file in $sourceFiles) {
        $relative = $file.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
        $sourceRelatives[$relative] = $true
        $target = Join-Path $destRoot $relative

        if ((Test-Path $target) -and
            ((Get-FileHash $file.FullName).Hash -eq (Get-FileHash $target).Hash)) {
            $same++
            continue
        }
        $targetParent = Split-Path -Parent $target
        if (-not (Test-Path $targetParent)) {
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        }
        Copy-Item $file.FullName $target -Force
        $copied++
    }

    # Target-only files. Hashtable keys are case-insensitive, which matches
    # how Windows resolves these paths.
    $stale = @()
    foreach ($file in Get-ChildItem $destRoot -Recurse -File -Force -ErrorAction SilentlyContinue) {
        $relative = $file.FullName.Substring($destRoot.Length).TrimStart('\', '/')
        if (-not $sourceRelatives.ContainsKey($relative)) { $stale += $file }
    }

    $pruned = 0
    if ($stale.Count -gt 0) {
        if ($Force) {
            foreach ($file in $stale) {
                $relative = $file.FullName.Substring($destRoot.Length).TrimStart('\', '/')
                Remove-Item $file.FullName -Force
                Write-Host "Pruned  $Label/$relative (not in repo)"
                $pruned++
            }
        }
        else {
            Write-Warning ("$Label has $($stale.Count) file(s) the repo does not: " +
                ($stale | ForEach-Object {
                    $_.FullName.Substring($destRoot.Length).TrimStart('\', '/')
                }) -join ', ')
            Write-Warning ("Those may be hand-authored. Diff and reconcile, or re-run " +
                "with -Force to DELETE them from $destRoot.")
            $script:DriftCount++
        }
    }

    Write-Host ("Synced  $Label ($copied pushed, $same unchanged" +
                $(if ($pruned) { ", $pruned pruned" } else { '' }) + ')')
}

if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir | Out-Null
    Write-Host "Created $ClaudeDir"
}

#region Format-payload copies (agents, hooks, rules, mcp)
if ($SkillsOnly) {
    Write-Host "Skipped agents/hooks/rules/mcp (-SkillsOnly)"
}
else {
    foreach ($dir in $CopyDirs) {
        $source = Join-Path $RepoRoot $dir.Source
        if (-not (Test-Path $source)) {
            # Counts as drift, and it is quieter than the junction era was:
            # a dangling junction stopped rules loading and hooks firing,
            # whereas a copy keeps serving the last content the repo had. A
            # mistyped or half-completed rename therefore looks like nothing
            # happened at all unless this says so.
            Write-Warning "Repo directory missing, skipped: $source"
            $script:DriftCount++
            continue
        }
        Sync-PayloadDirectory -Source $source -Dest (Join-Path $ClaudeDir $dir.Dest) -Label $dir.Dest
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
Write-Host "`nDone. Payload verified (skills linked, everything else copied)."
exit 0
