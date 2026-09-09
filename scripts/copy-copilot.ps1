<#
.SYNOPSIS
    Copy this repo's skills into a repo's .github/skills so GitHub Copilot
    loads them for everyone who clones it.

.DESCRIPTION
    The copy-based sibling of link-claude.ps1, and deliberately shaped like
    it: -CopilotDir is to this script what -ClaudeDir is to that one, and
    -SkillGroups selects and prunes the same way.

    IT EXISTS FOR THE ONE THING A JUNCTION CANNOT DO. Copilot reads
    ~/.claude/skills and .claude/skills directly -- measured 2026-09-09 by
    toggling ~/.claude/skills off in chat.agentSkillsLocations and watching
    the VS Code sidebar drop them -- so link-claude.ps1's junctions already
    serve Copilot on the machine that runs it, and a user-scope copy here
    would only duplicate them. What a junction cannot be is COMMITTED: it
    points at a personal repo on one machine, so a teammate cloning a client
    repo gets nothing from it. Real files under .github/skills travel with
    the clone. That is this script's whole reason to exist, and the reason
    -CopilotDir is mandatory with no user-scope default: deploying there is
    the case this design rejects.

    WHY COPIES AND NOT JUNCTIONS. link-claude junctions one reparse point
    per skill because Claude Code hot-reloads them, which makes edit-to-live
    worth its cost there. Neither payoff exists here. A client repo is
    cloned and shared, so what it needs is real files under version control
    rather than a link back to a personal repo that exists on one machine;
    and whether Copilot hot-reloads a SKILL.md edit is unverified, so a
    junction would buy an unproven immediacy while making every mid-edit
    save live. Re-run this script to publish an edit.

    FORMAT. No transformation is applied: SKILL.md is the shared Agent
    Skills format. Copilot validates frontmatter against its own field list
    and WARNS rather than failing, so this repo's Claude-only keys (model:,
    paths:, effort:, when_to_use:) leave the skill loaded and listed with a
    diagnostic naming the key. Two consequences worth knowing. The warning
    is ambient -- every skill here already triggers it -- so a REAL
    frontmatter mistake is camouflaged by the noise. And paths: does not
    map, so a skill whose loading Claude Code gates on a path glob is
    unconditional under Copilot, loaded on description relevance like every
    other one.

    Copilot requires a skill's directory name to match its frontmatter
    name:, which Claude Code does not enforce. This script checks that
    before copying and reports a mismatch rather than shipping a skill
    Copilot will reject.

    OWNERSHIP IS THE WHOLE DIFFICULTY, and the reason this is not
    link-claude with Copy-Item. link-claude owns ~/.claude/skills outright
    and prunes anything there it did not put. A Copilot skills root may
    already hold the CLIENT'S OWN skills, so blind pruning would delete
    someone else's work. This script therefore keeps an ownership manifest
    (.managed-skills.json) at the destination listing exactly which skill
    folders it deployed, and:

      - NEVER touches a folder it did not deploy. A skill at the
        destination that is not in the manifest belongs to the client and
        is left alone.
      - Prunes a skill only when it was deployed by a previous run (it is
        in the manifest) and is no longer selected now. Deselecting a group
        therefore removes its skills on the next run, exactly as
        link-claude's group pruning does.
      - Refuses to overwrite a destination folder whose name collides with
        a selected skill but which this script did not deploy (warns and
        skips), unless -Force is given to adopt it.

    Within a folder this script owns, content is one-way from the repo: a
    file that differs is stale and is overwritten, a file the repo no
    longer has is removed. Edit skills in this repo and re-run; do not
    author them at the destination.

    DOUBLE DISCOVERY IS REPORTED, NOT PREVENTED. Copilot also discovers
    .claude/skills and .agents/skills beside the chosen root, so a skill in
    both is listed twice -- expected in a client repo that runs both agents.
    In VS Code this IS controllable: chat.agentSkillsLocations carries a
    per-location boolean for every root and the sidebar honours a change
    immediately (measured 2026-09-09). Its own docs call it deprecated and
    "only used by the Local agent", which is the sidebar itself, so read
    that note as scoping the setting away from the CLI and cloud agents
    rather than as making it inert. Nothing here can set it on a teammate's
    behalf, so the overlap is reported with the names and left to the target
    repo's settings.

    THE MANIFEST NAMES NOTHING. It carries the managed folder names and a
    do-not-edit-here note, and deliberately no source repo, commit SHA,
    machine path, username or generator name. This repo is personal and a
    client repo is not the place to advertise it, so the manifest is scoped
    to the one job that needs a record at the target -- knowing on the next
    run which folders are ours to re-sync and prune. It stays AT the target
    rather than in local state so that ownership survives running from
    another machine, and so a reviewer of the client repo learns the folders
    are generated before hand-editing one. The cost is accepted knowingly:
    nothing at the target says which version was vendored.

    It is rewritten only when its content actually changes, so a no-op run
    leaves a clean git status rather than churning a timestamp. An earlier
    version of this script wrote a .skills-source.json and a README.md that
    both named this repo; both are removed on sight.

.PARAMETER CopilotDir
    The Copilot config directory to deploy into; skills land in
    <CopilotDir>/skills. Normally a repo's .github. Required -- see the
    description for why there is no user-scope default. The directory
    itself is created if missing, but its parent must already exist, so a
    mistyped repo path fails instead of creating a tree.

.PARAMETER SkillGroups
    Which skill groups under skills/ to copy (fabric, powerbi, workflow).
    Defaults to all of them, matching link-claude. Usually
    -SkillGroups fabric,powerbi: the workflow group is Claude Code harness
    plumbing (commit, land, drift-*) with no Copilot analog, and it is not
    what a teammate cloning a client repo needs.

.PARAMETER Force
    Adopt and overwrite a destination skill folder that collides with a
    selected skill but was not deployed by this script. Without it such a
    collision is reported and skipped so a client's own skill is never
    clobbered. It does NOT widen pruning: a folder absent from the manifest
    is still never deleted.

.EXAMPLE
    ./scripts/copy-copilot.ps1 -CopilotDir C:\Repos\Client\platform\.github -SkillGroups fabric,powerbi
    The normal call. Vendors the platform skills into the client repo's
    .github/skills as committable files, leaving any skills the client
    authored untouched. Commit them and every teammate gets them from a
    plain clone, with no script and no agent-config checkout.

.EXAMPLE
    ./scripts/copy-copilot.ps1 -CopilotDir C:\Repos\Client\platform\.github -SkillGroups fabric -WhatIf
    Preview: show what would be copied, pruned or skipped, writing nothing.

.NOTES
    Copying personally authored skills into a client repo commits that
    content to the client's history. The platform (fabric/powerbi) skills
    are generic, derived from public Microsoft docs, so this is low risk --
    but it is a one-way door once pushed, so review the diff before
    committing, the same as any vendored dependency.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$CopilotDir,
    [string[]]$SkillGroups,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$RepoRoot   = Split-Path -Parent $PSScriptRoot
$SkillsRoot = [IO.Path]::GetFullPath((Join-Path $RepoRoot 'skills'))
$script:DriftCount = 0

function Test-SamePath([string]$A, [string]$B) {
    [IO.Path]::GetFullPath($A).TrimEnd('\') -ieq [IO.Path]::GetFullPath($B).TrimEnd('\')
}

#region Resolve and validate the destination
if (-not (Test-Path $SkillsRoot)) {
    throw "No skills/ directory at $SkillsRoot -- is this script still inside the repo's scripts/ folder?"
}

$CopilotDirFull = [IO.Path]::GetFullPath($CopilotDir)

# ~/.claude is link-claude's target and is junction-managed. Copying real
# directories over those junctions would be destructive and silent, so refuse
# rather than trusting a typo.
if ((Split-Path -Leaf $CopilotDirFull) -eq '.claude') {
    throw ("$CopilotDirFull is a Claude Code config directory, not a Copilot one. " +
           "Use scripts/link-claude.ps1 for that target.")
}

# The destination directory is created if absent, but its PARENT is not: a
# mistyped repo path should fail here rather than materialize a tree that
# nothing will ever read.
$destParent = Split-Path -Parent $CopilotDirFull
if (-not (Test-Path -LiteralPath $destParent)) {
    throw "Parent of CopilotDir does not exist: $destParent"
}

$DestRoot     = Join-Path $CopilotDirFull 'skills'
$ManifestPath = Join-Path $DestRoot '.managed-skills.json'
# Written by an earlier version of this script, and both named this repo.
# Read for ownership if present, then removed -- see .DESCRIPTION.
$LegacyManifest = Join-Path $DestRoot '.skills-source.json'
$LegacyReadme   = Join-Path $DestRoot 'README.md'
$IsUserScope  = Test-SamePath $CopilotDirFull (Join-Path $HOME '.copilot')
#endregion

#region Resolve selected skills (by group)
# Same selection model as link-claude: groups are the top-level directories
# under skills/, a skill is <group>/<name>/SKILL.md, and names collapse into
# one flat namespace at the destination so a duplicate across groups is an
# error.
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

$desiredSkills = [ordered]@{}   # name -> @{ Source; Group }
foreach ($group in $selectedGroups) {
    foreach ($skill in Get-ChildItem (Join-Path $SkillsRoot $group) -Directory) {
        $skillFile = Join-Path $skill.FullName 'SKILL.md'
        if (-not (Test-Path $skillFile)) {
            Write-Warning "No SKILL.md, skipped: skills/$group/$($skill.Name)"
            $script:DriftCount++
            continue
        }
        # Copilot requires the directory name to equal the frontmatter name:,
        # which Claude Code does not. Catch it here rather than shipping a
        # skill Copilot silently declines to register.
        $nameLine = Select-String -Path $skillFile -Pattern '^name:\s*(.+?)\s*$' |
            Select-Object -First 1
        if ($nameLine) {
            $declared = $nameLine.Matches[0].Groups[1].Value.Trim("'", '"')
            if ($declared -ne $skill.Name) {
                Write-Warning ("skills/$group/$($skill.Name): frontmatter name is '$declared'. " +
                    "Copilot requires the directory name to match name:; this skill will not " +
                    "register there. Skipped.")
                $script:DriftCount++
                continue
            }
        }
        if ($desiredSkills.Contains($skill.Name)) {
            throw ("Duplicate skill name '$($skill.Name)' in more than one group. " +
                   "Skill names are a flat namespace at the destination; rename one.")
        }
        $desiredSkills[$skill.Name] = @{ Source = $skill.FullName; Group = $group }
    }
}

if ($desiredSkills.Count -eq 0) {
    throw "No skills resolved from group(s): $($selectedGroups -join ', ')"
}
#endregion

#region Report double discovery from sibling roots
# Copilot reads .claude/skills and .agents/skills beside whatever root we
# write to, so a name present in both is listed twice. One formula covers
# every scope: ~/.copilot sits beside ~/.claude exactly as <repo>/.github
# sits beside <repo>/.claude.
foreach ($sibling in @('.claude', '.agents')) {
    $peerRoot = Join-Path $destParent (Join-Path $sibling 'skills')
    if (-not (Test-Path $peerRoot)) { continue }
    $peerNames = @(Get-ChildItem $peerRoot -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $desiredSkills.Contains($_.Name) } |
        Select-Object -ExpandProperty Name)
    if ($peerNames.Count -eq 0) { continue }

    # A STANDING CONDITION, not drift, so it never touches $DriftCount: a
    # repo that runs both agents wants .claude/skills, and a warning that
    # can never be cleared would make a nonzero exit meaningless. Report it
    # and let the exit code keep meaning something.
    Write-Warning ("$($peerNames.Count) selected skill(s) also exist in $peerRoot, which " +
        "Copilot discovers too, so they will be listed twice: $($peerNames -join ', '). " +
        "That is expected where both agents run. To suppress it, set that root false in the " +
        "target's chat.agentSkillsLocations -- it carries a per-location boolean and the " +
        "VS Code sidebar honours a change immediately.")
}
#endregion

#region Read prior manifest
# The manifest is the record of what THIS script deployed on past runs. It is
# the only thing that authorizes a delete: a folder named here is ours to
# prune or re-sync, a folder absent from it is the client's and is never
# touched.
$managedBefore = @()
# The legacy file is read only when the current one is absent, so a target
# mid-migration is never read twice. Its entries were objects; the current
# format is a flat list of names.
$hadLegacyManifest = Test-Path $LegacyManifest
$readFrom = if (Test-Path $ManifestPath) { $ManifestPath }
            elseif ($hadLegacyManifest) { $LegacyManifest }
            else { $null }

if ($readFrom) {
    try {
        $priorManifest = Get-Content $readFrom -Raw | ConvertFrom-Json -AsHashtable
        if ($priorManifest.Contains('skills') -and $priorManifest['skills']) {
            $managedBefore = @($priorManifest['skills'] | ForEach-Object {
                if ($_ -is [System.Collections.IDictionary]) { $_['name'] } else { $_ }
            })
        }
    }
    catch {
        Write-Warning ("$readFrom exists but is not readable JSON; treating as no prior " +
                       "deployment. Existing folders will be left alone, not pruned. " +
                       "($($_.Exception.Message))")
        $script:DriftCount++
    }
}
#endregion

#region Mirror one skill folder
function Sync-SkillFolder {
    # One-way mirror of $Source onto $Dest. The caller has established that
    # $Dest is ours, so files are overwritten and orphans removed without
    # -Force: nothing here is authored at the destination. Returns copied/
    # same/pruned counts for the summary line.
    param([string]$Source, [string]$Dest)

    $sourceRoot = [IO.Path]::GetFullPath($Source)
    $destFull   = [IO.Path]::GetFullPath($Dest)

    if (-not (Test-Path $destFull)) {
        New-Item -ItemType Directory -Path $destFull -Force | Out-Null
    }

    $sourceRelatives = @{}
    $copied = 0
    $same   = 0

    foreach ($file in Get-ChildItem $sourceRoot -Recurse -File -Force) {
        $relative = $file.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
        $sourceRelatives[$relative] = $true
        $target = Join-Path $destFull $relative

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

    # Files the destination has under this owned folder that the repo no
    # longer ships. Hashtable keys are case-insensitive, matching Windows
    # path semantics.
    $pruned = 0
    foreach ($file in Get-ChildItem $destFull -Recurse -File -Force -ErrorAction SilentlyContinue) {
        $relative = $file.FullName.Substring($destFull.Length).TrimStart('\', '/')
        if (-not $sourceRelatives.ContainsKey($relative)) {
            Remove-Item $file.FullName -Force
            $pruned++
        }
    }

    # Remove any now-empty directories left behind by a prune.
    foreach ($dir in (Get-ChildItem $destFull -Recurse -Directory -Force -ErrorAction SilentlyContinue |
                      Sort-Object { $_.FullName.Length } -Descending)) {
        if (-not (Get-ChildItem $dir.FullName -Force -ErrorAction SilentlyContinue)) {
            Remove-Item $dir.FullName -Force
        }
    }

    [pscustomobject]@{ Copied = $copied; Same = $same; Pruned = $pruned }
}
#endregion

#region Copy selected skills
if (-not (Test-Path $DestRoot)) {
    if ($PSCmdlet.ShouldProcess($DestRoot, 'Create skills directory')) {
        New-Item -ItemType Directory -Path $DestRoot -Force | Out-Null
        Write-Host "Created $DestRoot"
    }
}

$managedNow   = @()
$copiedCount  = 0
$skippedCount = 0

foreach ($name in $desiredSkills.Keys) {
    $src          = $desiredSkills[$name].Source
    $group        = $desiredSkills[$name].Group
    $destSkillDir = Join-Path $DestRoot $name
    $existsAtDest = Test-Path $destSkillDir
    $isOurs       = $managedBefore -contains $name

    if ($existsAtDest -and -not $isOurs -and -not $Force) {
        # A folder we did not deploy, colliding with a skill we want. It is
        # the client's until proven otherwise -- never clobber it silently.
        Write-Warning ("skills/$group/$name collides with an existing skills/$name that this " +
                       "script did not deploy. Skipped. Re-run with -Force to adopt and " +
                       "overwrite it.")
        $script:DriftCount++
        $skippedCount++
        continue
    }

    $action = if ($existsAtDest -and -not $isOurs) { 'Adopt and overwrite skill' } else { 'Copy skill' }
    if ($PSCmdlet.ShouldProcess($destSkillDir, "$action from skills/$group/$name")) {
        $result = Sync-SkillFolder -Source $src -Dest $destSkillDir
        $tag = if ($existsAtDest -and -not $isOurs) { ' (adopted)' } else { '' }
        Write-Host ("Synced  $name ($($result.Copied) pushed, $($result.Same) unchanged" +
                    $(if ($result.Pruned) { ", $($result.Pruned) pruned" } else { '' }) + ")$tag")
        $copiedCount++
    }
    $managedNow += $name
}
#endregion

#region Prune deselected skills this script deployed before
# Only names the manifest records as ours, and only when no longer selected.
$toPrune = @($managedBefore | Where-Object { -not $desiredSkills.Contains($_) })
$prunedSkills = 0
foreach ($name in $toPrune) {
    $destSkillDir = Join-Path $DestRoot $name
    if (-not (Test-Path $destSkillDir)) { continue }
    if ($PSCmdlet.ShouldProcess($destSkillDir, 'Prune deselected skill')) {
        Remove-Item $destSkillDir -Recurse -Force
        Write-Host "Pruned  $name (no longer selected)"
        $prunedSkills++
    }
}
#endregion

#region Write manifest
# Deliberately minimal, and everything absent from it is absent on purpose:
# no source repo, commit, generator, machine path or username. See the
# .DESCRIPTION -- the only job this file has at the target is telling the
# next run which folders are ours.
$manifest = [ordered]@{
    '$comment' = 'Generated. These skill folders are synced from an external source and are ' +
                 'overwritten on every sync -- do not edit them here. This file records which ' +
                 'folders the sync manages; anything not listed is left untouched.'
    skills     = @($managedNow)
}
$manifestJson = $manifest | ConvertTo-Json -Depth 5

# Write only on real change. A timestamp field would dirty git on every run
# in a client repo, so the manifest carries none and is compared before
# writing.
function Set-IfChanged {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param([string]$Path, [string]$Content, [string]$Label)
    # Set-Content appends a trailing newline, so compare against the content
    # plus one -- otherwise every run reports a change it did not make.
    if ((Test-Path $Path) -and ((Get-Content $Path -Raw) -eq ($Content + [Environment]::NewLine))) {
        return $false
    }
    if ($PSCmdlet.ShouldProcess($Path, "Write $Label")) {
        Set-Content -Path $Path -Value $Content -Encoding utf8NoBOM
        return $true
    }
    return $false
}

if (Set-IfChanged -Path $ManifestPath -Content $manifestJson -Label '.managed-skills.json') {
    Write-Host "Wrote   .managed-skills.json"
}
elseif (-not $WhatIfPreference) {
    Write-Host "OK      .managed-skills.json (unchanged)"
}

# Remove what an earlier version of this script left behind. Both named this
# repo, which is the whole reason they are going. The manifest filename is
# ours by construction, so it goes on sight; README.md is a name anyone might
# use, so it is only considered when that manifest was there too -- evidence
# of an old deployment -- and only when it still carries the heading that
# version wrote. Without both, a README the repo owns is left alone silently
# rather than warned about on every future run.
$legacyFiles = @($LegacyManifest) + $(if ($hadLegacyManifest) { @($LegacyReadme) } else { @() })
foreach ($legacy in $legacyFiles) {
    if (-not (Test-Path $legacy)) { continue }
    if ($legacy -eq $LegacyReadme) {
        $head = (Get-Content $legacy -TotalCount 1 -ErrorAction SilentlyContinue)
        if ($head -notmatch '^#\s*Vendored Agent Skills') {
            Write-Warning ("$legacy sits beside a manifest from an earlier version but was " +
                "not written by it (unrecognized heading). Left alone -- delete it by hand " +
                "if it is stale.")
            continue
        }
    }
    if ($PSCmdlet.ShouldProcess($legacy, 'Remove file left by an earlier version')) {
        Remove-Item $legacy -Force
        Write-Host "Removed $(Split-Path -Leaf $legacy) (left by an earlier version)"
    }
}
#endregion

#region Summary
Write-Host ""
Write-Host ("Skills  $copiedCount synced from group(s): $($selectedGroups -join ', ')" +
            $(if ($prunedSkills)  { "; $prunedSkills pruned" } else { '' }) +
            $(if ($skippedCount)  { "; $skippedCount skipped (collision)" } else { '' }))
Write-Host ("Target  $DestRoot" + $(if ($IsUserScope) { ' (user scope)' } else { ' (project scope)' }))

if ($script:DriftCount -gt 0) {
    Write-Host "`nDone with $script:DriftCount item(s) needing attention (see warnings above)."
    exit 1
}
if ($WhatIfPreference) {
    Write-Host "`nDone. Dry run -- nothing was written."
    exit 0
}
Write-Host "`nDone. Skills copied."
exit 0
#endregion
