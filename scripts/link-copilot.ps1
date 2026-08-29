<#
.SYNOPSIS
    Link this repo's skills and subagents into GitHub Copilot's user scope.

.DESCRIPTION
    Most of this repo already reaches Copilot without any wiring. The VS
    Code agent surface reads Claude's user-scope paths as harness-agnostic
    defaults — ~/.claude/rules for instructions, ~/.claude/CLAUDE.md for
    always-on instructions, ~/.claude/settings.json for hooks (same JSON
    format), and ~/.claude/skills for personal skills — all of which
    scripts/link-claude.ps1 already populates. This script covers only the
    two artifacts that need Copilot-specific placement.

    1. Skills -> ~/.agents/skills, one directory junction (no elevation or
       Developer Mode needed) per skill in this repo's skills/ directory.
       Unlike ~/.claude, the whole directory cannot be junctioned:
       ~/.agents/skills is shared with skills from other providers (e.g.
       Copilot for Azure), so this repo's skills are linked individually
       alongside them. This is the path VS Code actually reads by default:
       chat.agentSkillsLocations enables ~/.agents/skills and leaves
       ~/.claude/skills off, so the junctions here are load-bearing rather
       than a duplicate of what link-claude.ps1 already provides.

    2. Subagents -> ~/.copilot/agents, as plain file copies. VS Code reads
       the Claude sub-agent format (name / description / tools frontmatter,
       mapped to VS Code tool names), but only from .claude/agents at
       WORKSPACE scope; at user scope it reads ~/.copilot/agents. So the
       repo's claude/agents/*.md must be placed there separately. Copies,
       not links, because file symlinks require elevation or Developer Mode
       and hard links break when git replaces a file by rename.

    ~/.copilot is Copilot's own runtime home (session databases, config,
    logs, installed plugins), so only the named leaf files are managed and
    the script refuses to operate when ~/.copilot is itself a reparse point
    or a Git working-tree root.

    Junctions already pointing at the right target are left alone;
    junctions pointing elsewhere (e.g. after the repo folder moved or
    was renamed) are replaced. Broken junctions whose dead target looks
    like a skills path (a skill deleted or renamed in the repo, or a
    stale pre-rename link) are pruned. A real directory occupying a
    skill's link path is never removed unless -Force is passed. Other
    providers' skill directories and agent files are never touched.

    Idempotent; safe to re-run any time, including after moving or
    renaming the repo folder.

.PARAMETER Force
    Replace a real directory occupying a skill link path (its contents
    are DELETED) and overwrite drifted agent copies under ~/.copilot/agents.

.PARAMETER AgentsDir
    The agents config directory to link into. Defaults to ~/.agents.
    Mainly for testing the script against a scratch directory.

.PARAMETER CopilotDir
    Copilot's user-scope directory, source of ~/.copilot/agents. Defaults
    to ~/.copilot. Mainly for testing the script against a scratch
    directory.

.EXAMPLE
    ./scripts/link-copilot.ps1          # verify + relink + prune
    ./scripts/link-copilot.ps1 -Force   # also replace real dirs / drifted copies
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [string]$AgentsDir = (Join-Path $HOME '.agents'),
    [string]$CopilotDir = (Join-Path $HOME '.copilot')
)

$ErrorActionPreference = 'Stop'

$RepoRoot  = Split-Path -Parent $PSScriptRoot
$SkillsSrc = Join-Path $RepoRoot 'skills'
$SkillsDst = Join-Path $AgentsDir 'skills'
# Subagents live under claude/ because the file format is Claude's; Copilot
# is a second consumer of that same format, not a reason to duplicate them.
$AgentsSrc = Join-Path $RepoRoot 'claude\agents'
$AgentsDst = Join-Path $CopilotDir 'agents'
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

#region Subagents -> ~/.copilot/agents
# VS Code reads the Claude sub-agent format at user scope only from
# ~/.copilot/agents, so these are placed as plain copies rather than
# reached through the ~/.claude junctions like everything else.
$repoAgents = @()
if (-not (Test-Path $AgentsSrc)) {
    Write-Host "SKIP    subagents (no $AgentsSrc in this repo)"
}
else {
    $repoAgents = @(Get-ChildItem $AgentsSrc -Filter '*.md' -File |
        Where-Object { $_.Name -ne 'README.md' })
    if ($repoAgents.Count -eq 0) {
        Write-Host "SKIP    subagents (no *.md under $AgentsSrc)"
    }
}

if ($repoAgents.Count -gt 0) {
    # ~/.copilot holds Copilot's own runtime state (session databases,
    # config, logs). Refuse to touch it when it is a link or a Git working
    # tree, so this script can never redirect or commit a tool's runtime
    # directory.
    $copilotExisting = Get-Item $CopilotDir -Force -ErrorAction SilentlyContinue
    if ($copilotExisting -and
        ($copilotExisting.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        Write-Warning ("$CopilotDir is a reparse point. Refusing to manage agent " +
            "files inside a redirected Copilot home.")
        $script:DriftCount++
    }
    elseif (Test-Path (Join-Path $CopilotDir '.git')) {
        Write-Warning ("$CopilotDir is a Git working-tree root. Refusing to manage " +
            "agent files inside a version-controlled Copilot home.")
        $script:DriftCount++
    }
    else {
        if (-not (Test-Path $AgentsDst)) {
            New-Item -ItemType Directory -Path $AgentsDst -Force | Out-Null
            Write-Host "Created $AgentsDst"
        }

        foreach ($agent in $repoAgents) {
            $dst = Join-Path $AgentsDst $agent.Name

            if (-not (Test-Path $dst)) {
                Copy-Item $agent.FullName $dst
                Write-Host "Copied  agents/$($agent.Name) (was missing)"
                continue
            }
            if ((Get-FileHash $agent.FullName).Hash -eq (Get-FileHash $dst).Hash) {
                Write-Host "OK      agents/$($agent.Name) (in sync)"
                continue
            }
            if ($Force) {
                Copy-Item $agent.FullName $dst -Force
                Write-Host "Pushed  agents/$($agent.Name) repo -> home (-Force)"
            }
            else {
                Write-Warning ("agents/$($agent.Name) differs between repo and home. " +
                    "The home copy may hold edits the repo lacks — diff and reconcile " +
                    "(repo: $($agent.FullName) | home: $dst), or re-run with -Force to " +
                    "overwrite home with the repo version.")
                $script:DriftCount++
            }
        }
    }
}
#endregion

if ($script:DriftCount -gt 0) {
    Write-Host "`nDone with $script:DriftCount item(s) needing attention (see warnings above)."
    exit 1
}
Write-Host "`nDone. $($repoSkills.Count) skills linked, $($repoAgents.Count) subagent(s) copied."
exit 0
