<#
.SYNOPSIS
    Link this repo's skills into ~/.agents/skills for GitHub Copilot.

.DESCRIPTION
    Creates one directory junction (no elevation or Developer Mode
    needed) per skill in this repo's skills/ directory under
    ~/.agents/skills — the user-scope skills directory the VS Code
    agents surface reads. Unlike ~/.claude, the whole directory cannot
    be junctioned: ~/.agents/skills is shared with skills from other
    providers (e.g. Copilot for Azure), so this repo's skills are
    linked individually alongside them.

    Junctions already pointing at the right target are left alone;
    junctions pointing elsewhere (e.g. after the repo folder moved or
    was renamed) are replaced. Broken junctions whose dead target looks
    like a skills path (a skill deleted or renamed in the repo, or a
    stale pre-rename link) are pruned. A real directory occupying a
    skill's link path is never removed unless -Force is passed. Other
    providers' skill directories are never touched.

    Idempotent; safe to re-run any time, including after moving or
    renaming the repo folder.

.PARAMETER Force
    Replace a real directory occupying a skill link path (its contents
    are DELETED).

.PARAMETER AgentsDir
    The agents config directory to link into. Defaults to ~/.agents.
    Mainly for testing the script against a scratch directory.

.EXAMPLE
    ./scripts/link-copilot.ps1          # verify + relink + prune
    ./scripts/link-copilot.ps1 -Force   # also replace real directories
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [string]$AgentsDir = (Join-Path $HOME '.agents')
)

$ErrorActionPreference = 'Stop'

$RepoRoot  = Split-Path -Parent $PSScriptRoot
$SkillsSrc = Join-Path $RepoRoot 'skills'
$SkillsDst = Join-Path $AgentsDir 'skills'
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

if (-not (Test-Path $SkillsSrc)) {
    throw "Repo skills directory not found: $SkillsSrc"
}
if (-not (Test-Path $SkillsDst)) {
    New-Item -ItemType Directory -Path $SkillsDst -Force | Out-Null
    Write-Host "Created $SkillsDst"
}

$repoSkills = Get-ChildItem $SkillsSrc -Directory

foreach ($skill in $repoSkills) {
    $target = $skill.FullName
    $link   = Join-Path $SkillsDst $skill.Name

    $existing = Get-Item $link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            $currentTarget = Get-LinkTarget $existing
            if ($currentTarget -and (Test-SamePath $currentTarget $target)) {
                Write-Host "OK      $($skill.Name)"
                continue
            }
            # Stale junction (repo moved/renamed). Deleting a reparse
            # point removes only the link, never the target's contents.
            $existing.Delete()
            Write-Host "Relink  $($skill.Name) (was -> $currentTarget)"
        }
        else {
            if (-not $Force) {
                Write-Warning ("$link is a real directory, not a junction. " +
                    "Move it aside, or re-run with -Force to DELETE it and link the repo skill.")
                $script:DriftCount++
                continue
            }
            Remove-Item $link -Recurse -Force
            Write-Host "Removed real directory $link (-Force)"
        }
    }

    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Host "Linked  $($skill.Name) -> $target"
}

# Prune broken junctions left behind by skills deleted or renamed in the
# repo (or by a pre-rename repo path). Only junctions whose dead target
# looks like a skills path are touched; real directories and healthy
# junctions from other providers are left alone.
foreach ($entry in Get-ChildItem $SkillsDst -Force -ErrorAction SilentlyContinue) {
    if (-not ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
    $entryTarget = Get-LinkTarget $entry
    if (-not $entryTarget -or (Test-Path $entryTarget)) { continue }
    if ($entryTarget -match '[\\/]skills[\\/][^\\/]+$') {
        $entry.Delete()
        Write-Host "Pruned  $($entry.Name) (broken junction -> $entryTarget)"
    }
    else {
        Write-Warning "Broken junction left in place (target not a skills path): $($entry.FullName) -> $entryTarget"
        $script:DriftCount++
    }
}

if ($script:DriftCount -gt 0) {
    Write-Host "`nDone with $script:DriftCount item(s) needing attention (see warnings above)."
    exit 1
}
Write-Host "`nDone. $($repoSkills.Count) skills linked."
exit 0
