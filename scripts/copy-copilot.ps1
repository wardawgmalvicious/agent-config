<#
.SYNOPSIS
    Copy this repo's skills and Copilot instructions into a repo's .github
    so GitHub Copilot serves them to everyone who clones it.

.DESCRIPTION
    The copy-based sibling of link-claude.ps1, and deliberately shaped like
    it: -CopilotDir is to this script what -ClaudeDir is to that one, and
    -SkillGroups selects and prunes the same way.

    Two payloads, selected with -Payload: skills from skills/<group>/ into
    <CopilotDir>/skills, and instructions from copilot/instructions/ into
    <CopilotDir>/instructions. Both default on.

    TWO TARGETS, ONE MECHANISM. A repo's .github, so a teammate cloning a
    client repo gets real, committed files -- a junction points at a
    personal repo on one machine and travels nowhere. And ~/.copilot, this
    machine's user scope. That second target used to be rejected here:
    Copilot read ~/.claude/skills and ~/.claude/rules directly (measured
    2026-09-09 by toggling ~/.claude/skills in chat.agentSkillsLocations and
    watching the sidebar drop them), so a user-scope copy only duplicated
    link-claude.ps1's junctions. The same day every Claude root was switched
    off for Copilot, which left ~/.copilot as the only user-scope route; it
    was first deployed 2026-09-11 with -SkillGroups workflow, which is why
    linkedin-highlights moved to its own social group. -CopilotDir stays
    mandatory with no default, so every run names its target.

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

    LINE ENDINGS ARE NORMALIZED TO LF, and that is the one respect in which
    this is not a byte-faithful copy. It has to be: what is in THIS repo's
    working tree flips between LF and CRLF on no schedule. `* text=auto` with
    core.autocrlf false and core.eol unset means git rewrites a file to CRLF
    every time it touches one -- checkout, switch, stash, pre-commit's own
    stash/restore -- while the editors and tools that write the same files in
    between leave LF. Copying that faithfully carried the flip into the client
    repo, where a run showed every vendored file modified with nothing visibly
    changed (159 of them, 2026-09-09). Normalizing makes a deploy a function of
    content alone, and leaves the destination repo's own .gitattributes to
    decide what its checkout looks like. Files containing a NUL byte are
    treated as binary and copied untouched. The manifests get the same
    treatment, for the same reason.

    Expect ONE more whole-payload diff after this change landed: the run that
    converts an already-vendored CRLF payload to LF. It is stable from then on.

    INSTRUCTIONS ARE PRE-TRANSLATED, NOT CONVERTED HERE. Skills need no
    transformation because SKILL.md is a shared format. Rules are the
    opposite: .github/instructions takes *.instructions.md with an applyTo
    glob string, where claude/rules/ takes paths: as a list -- and an
    instructions file with no applyTo is never applied automatically at
    all, so a straight copy would ship files that silently do nothing.
    Beyond frontmatter, roughly a dozen body lines per rule are wrong for a
    Copilot reader (".claude/rules override" notes, "co-loads" wording) or
    name repos that must not appear in a client's history.

    None of that can be generated safely, so it is a ONE-TIME HAND PORT
    living in copilot/instructions/, and this script only copies what is
    already there. scripts/lint-instructions.py is what keeps the port
    honest: it validates the frontmatter, blocks a personal-repo name or
    profile path from reaching a client repo, and fails when a rule changes
    without its port following. Run it (pre-commit does) rather than
    trusting that the two stayed in step.

    Every ported instruction ships; there is no per-repo subsetting,
    because applyTo already scopes each file to its own globs. A warehouse
    repo with no .tmdl never loads the DAX conventions, so shipping all of
    them costs a reader nothing. To withhold one, do not port it --
    copilot/.source-hashes.json records that decision and why.

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

    EACH PAYLOAD KEEPS ITS OWN MANIFEST, beside its own files:
    skills/.managed-skills.json and instructions/.managed-instructions.json.
    One shared file at <CopilotDir> would read more tidily and be wrong
    twice over -- an existing skills-only deployment would need migrating,
    and every -Payload skills run would rewrite the instructions ownership
    record it knows nothing about. Separate files make that impossible by
    construction rather than by care.

    THE MANIFESTS NAME NOTHING. Each carries the managed names and
    nothing else -- no source repo, commit SHA, machine path, username,
    generator name, or prose. This repo is personal and a client repo is not
    the place to advertise it, so the manifest is scoped to the one job that
    needs a record at the target: knowing on the next run which folders are
    ours to re-sync and prune. Nothing but the skills list is ever read back,
    so any note in the file would be for a human reader alone -- and review
    on the way in catches a hand-edit better than a line inside the generated
    file it is warning about. It stays AT the target rather than in local
    state so that ownership survives running from another machine. The cost
    is accepted knowingly: nothing at the target says which version was
    vendored, or that these folders are generated at all.

    It is rewritten only when its content actually changes, so a no-op run
    leaves a clean git status rather than churning a timestamp. An earlier
    version of this script wrote a .skills-source.json and a README.md that
    both named this repo; both are removed on sight.

.PARAMETER CopilotDir
    The Copilot config directory to deploy into; skills land in
    <CopilotDir>/skills and instructions in <CopilotDir>/instructions.
    Normally a repo's .github. Required -- see the description for why
    there is no user-scope default. The directory itself is created if
    missing, but its parent must already exist, so a mistyped repo path
    fails instead of creating a tree.

.PARAMETER Payload
    Which payloads to sync: skills, instructions, or both (the default).

    A payload left out is LEFT ALONE, not pruned -- unlike -SkillGroups,
    where dropping a group removes its skills. The two read the same way
    and must not behave the same way: -SkillGroups narrows what a payload
    contains, so a group you stop selecting is one you want gone, while
    -Payload narrows what this RUN touches, and deploying skills alone
    must not quietly delete the instructions a previous run placed.

.PARAMETER SkillGroups
    Which skill groups under skills/ to copy (fabric, powerbi, workflow).
    Defaults to all of them, matching link-claude.

    THE WORKFLOW GROUP IS NOW PORTABLE, which reverses the advice that
    stood here. It used to hold this repo's own maintenance skills
    alongside the general ones, so it was harness plumbing a teammate had
    no use for. The 2026-09-09 scope split moved those to project scope in
    .claude/skills/, which this script cannot see -- it selects out of
    skills/ -- so what remains in the group is code-review and commit,
    both harness-neutral and both useful in any repo. Verified for
    Copilot: neither references github-mcp, hooks, or a ~/. path, and
    code-review's one CLAUDE.md mention stays true there because Copilot
    reads CLAUDE.md as a documented default.

    That leaves -SkillGroups meaning exactly what the group names say, with
    no per-skill selection needed. land was the reason it could not:
    it is built on github-mcp throughout, and MCP is the one payload piece
    that does not cross to Copilot. It moved to project scope with the
    rest, so a port list in a script argument or a frontmatter marker --
    both considered -- turned out to be unnecessary.

.PARAMETER Force
    Adopt and overwrite a destination skill folder or instruction file that
    collides with a selected one but was not deployed by this script.
    Without it such a collision is reported and skipped so a client's own
    work is never clobbered. It does NOT widen pruning: anything absent
    from the manifest is still never deleted.

    Expect a collision on the first run into a repo that already writes its
    own .github/instructions. That is the guard working, not a fault --
    read the file before adopting it, because -Force overwrites it.

.EXAMPLE
    ./scripts/copy-copilot.ps1 -CopilotDir C:\Repos\Client\platform\.github -SkillGroups fabric,powerbi,workflow
    The normal call. Vendors the platform skills and every ported
    instruction into the client repo's .github as committable files,
    leaving anything the client authored untouched. Commit them and every
    teammate gets them from a plain clone, with no script and no checkout
    of this repo.

.EXAMPLE
    ./scripts/copy-copilot.ps1 -CopilotDir C:\Repos\Client\platform\.github -Payload instructions
    Coding conventions only -- no skills. Useful where a team wants the
    house style without the Fabric/Power BI skill surface.

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
    [ValidateSet('skills', 'instructions')]
    [string[]]$Payload = @('skills', 'instructions'),
    [string[]]$SkillGroups,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$RepoRoot   = Split-Path -Parent $PSScriptRoot
$SkillsRoot = [IO.Path]::GetFullPath((Join-Path $RepoRoot 'skills'))
$InstructionsRoot = [IO.Path]::GetFullPath((Join-Path (Join-Path $RepoRoot 'copilot') 'instructions'))
$script:DriftCount = 0

$doSkills       = $Payload -contains 'skills'
$doInstructions = $Payload -contains 'instructions'

function Test-SamePath([string]$A, [string]$B) {
    [IO.Path]::GetFullPath($A).TrimEnd('\') -ieq [IO.Path]::GetFullPath($B).TrimEnd('\')
}

# UTF-8 with no BOM, and no newline translation on write. Set-Content and
# Out-File both emit [Environment]::NewLine instead, which is CRLF here.
$script:Utf8NoBom = [Text.UTF8Encoding]::new($false)

function Get-PayloadContent {
    # What ships: the file's content with every CRLF collapsed to LF.
    #
    # THIS IS NOT COSMETIC -- a byte-faithful copy churns the client repo.
    # Content reaches this script with whatever line endings git last left in
    # the working tree, and in THIS repo that is not stable: `* text=auto` with
    # core.autocrlf false and core.eol unset (so `native`) means git rewrites a
    # file to CRLF every time it touches one -- checkout, switch, stash, and
    # pre-commit's own stash/restore around each commit -- while the editors and
    # tools that write the same files in between leave LF. So a file's endings
    # flip back and forth on no schedule and with nothing to see in a diff here.
    # Copying those bytes faithfully propagated the flip into the client repo,
    # where it lands as every vendored file modified with nothing visibly
    # changed (159 of them on 2026-09-09, which is what prompted this).
    #
    # Normalizing makes a deploy depend on content alone. The destination repo's
    # own .gitattributes then decides what its checkout looks like, which is
    # where that decision belongs.
    [OutputType([byte[]])]
    param([string]$Path)

    $raw = [IO.File]::ReadAllBytes($Path)
    # A NUL byte means binary -- an image or archive shipped inside a skill.
    # Newline normalization would corrupt it, so those pass through untouched.
    if ($raw -contains 0) { return $raw }
    $script:Utf8NoBom.GetBytes(([IO.File]::ReadAllText($Path) -replace "`r`n", "`n"))
}

function Test-FileMatch {
    # Is the destination already exactly these bytes? Byte comparison rather
    # than Get-FileHash on both sides, because the normalized source never
    # exists on disk in the form being compared.
    [OutputType([bool])]
    param([string]$Path, [byte[]]$Bytes)

    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $existing = [IO.File]::ReadAllBytes($Path)
    if ($existing.Length -ne $Bytes.Length) { return $false }
    [Linq.Enumerable]::SequenceEqual([byte[]]$existing, [byte[]]$Bytes)
}

# Write only on real change. A timestamp field would dirty git on every run
# in a client repo, so the manifests carry none and are compared before
# writing. Shared by both payloads' manifests.
function Set-IfChanged {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param([string]$Path, [string]$Content, [string]$Label)
    # ConvertTo-Json emits CRLF between lines on Windows, so the manifests get
    # the same LF normalization as the payload -- they are committed in the
    # client repo too, and would churn there for the same reason. The trailing
    # newline is added here because nothing else adds one.
    $bytes = $script:Utf8NoBom.GetBytes((($Content -replace "`r`n", "`n") + "`n"))
    if (Test-FileMatch -Path $Path -Bytes $bytes) { return $false }
    if ($PSCmdlet.ShouldProcess($Path, "Write $Label")) {
        [IO.File]::WriteAllBytes($Path, $bytes)
        return $true
    }
    return $false
}

function Read-ManagedManifest {
    # Ownership record from a previous run: the ONLY thing that authorizes a
    # delete. A name listed here is ours to re-sync or prune; anything at the
    # destination not listed belongs to whoever put it there.
    [OutputType([string[]])]
    param([string]$Path, [string]$Key)

    if (-not (Test-Path $Path)) { return @() }
    try {
        $prior = Get-Content $Path -Raw | ConvertFrom-Json -AsHashtable
        if ($prior.Contains($Key) -and $prior[$Key]) {
            # v1 entries were objects with a name property; current format is
            # a flat list of names. Accept both so an old target still reads.
            return @($prior[$Key] | ForEach-Object {
                if ($_ -is [System.Collections.IDictionary]) { $_['name'] } else { $_ }
            })
        }
        return @()
    }
    catch {
        Write-Warning ("$Path exists but is not readable JSON; treating as no prior " +
                       "deployment. Existing files will be left alone, not pruned. " +
                       "($($_.Exception.Message))")
        $script:DriftCount++
        return @()
    }
}

#region Resolve and validate the destination
if ($doSkills -and -not (Test-Path $SkillsRoot)) {
    throw "No skills/ directory at $SkillsRoot -- is this script still inside the repo's scripts/ folder?"
}
if ($doInstructions -and -not (Test-Path $InstructionsRoot)) {
    throw ("No copilot/instructions/ directory at $InstructionsRoot -- is this script still " +
           "inside the repo's scripts/ folder?")
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

# Instructions keep their OWN manifest beside their own files rather than
# sharing one with skills. Two reasons: an existing skills-only deployment
# needs no migration, and deploying one payload can then never rewrite the
# other's ownership record -- which a shared file would do every run.
$DestInstructions     = Join-Path $CopilotDirFull 'instructions'
$InstructionsManifest = Join-Path $DestInstructions '.managed-instructions.json'
#endregion

#region Resolve selected skills (by group)
# Same selection model as link-claude: groups are the top-level directories
# under skills/, a skill is <group>/<name>/SKILL.md, and names collapse into
# one flat namespace at the destination so a duplicate across groups is an
# error.
$availableGroups = @(if ($doSkills) {
    Get-ChildItem $SkillsRoot -Directory | Select-Object -ExpandProperty Name | Sort-Object
} else { @() })

if (-not $doSkills) {
    if ($SkillGroups) {
        Write-Warning "-SkillGroups is ignored: 'skills' is not in -Payload."
    }
    $selectedGroups = @()
}
elseif ($SkillGroups) {
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

if ($doSkills -and $desiredSkills.Count -eq 0) {
    throw "No skills resolved from group(s): $($selectedGroups -join ', ')"
}
#endregion

#region Resolve selected instructions
# Flat files rather than folders, and every ported one ships. There is no
# per-repo subsetting because there is nothing to gain from it: applyTo scopes
# each file to its own globs, so a warehouse repo with no .tmdl never loads the
# DAX conventions. Shipping all of them costs a reader nothing. To withhold
# one, do not port it -- copilot/.source-hashes.json records that decision.
$desiredInstructions = [ordered]@{}   # base name -> file name
if ($doInstructions) {
    foreach ($file in Get-ChildItem $InstructionsRoot -File -Filter '*.instructions.md' | Sort-Object Name) {
        $stem = $file.Name -replace '\.instructions\.md$', ''
        $desiredInstructions[$stem] = $file.Name
    }
    if ($desiredInstructions.Count -eq 0) {
        throw "No *.instructions.md files found in $InstructionsRoot"
    }
}
#endregion

#region Report double discovery from sibling roots
# Copilot reads .claude/skills and .agents/skills beside whatever root we
# write to, so a name present in both is listed twice. One formula covers
# every scope: ~/.copilot sits beside ~/.claude exactly as <repo>/.github
# sits beside <repo>/.claude.
# It reads directories, not VS Code settings, so it cannot tell a sibling
# root that chat.*Locations has switched off -- every Claude root on this
# machine since 2026-09-09, where the warning is therefore moot.
# A STANDING CONDITION, not drift, so none of this touches $DriftCount: a repo
# that runs both agents wants .claude/ populated, and a warning that can never
# be cleared would make a nonzero exit meaningless. Report it and let the exit
# code keep meaning something.
if ($doSkills) {
    foreach ($sibling in @('.claude', '.agents')) {
        $peerRoot = Join-Path $destParent (Join-Path $sibling 'skills')
        if (-not (Test-Path $peerRoot)) { continue }
        $peerNames = @(Get-ChildItem $peerRoot -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object { $desiredSkills.Contains($_.Name) } |
            Select-Object -ExpandProperty Name)
        if ($peerNames.Count -eq 0) { continue }

        Write-Warning ("$($peerNames.Count) selected skill(s) also exist in $peerRoot, which " +
            "Copilot discovers too, so they will be listed twice: $($peerNames -join ', '). " +
            "That is expected where both agents run. To suppress it, set that root false in the " +
            "target's chat.agentSkillsLocations -- it carries a per-location boolean and the " +
            "VS Code sidebar honours a change immediately.")
    }
}

# Instructions overlap differently: the sibling root is .claude/rules, and the
# two roots spell the same guidance with different file names, so the match is
# on the stem rather than the file name. Copilot honours `paths:` in
# .claude/rules and `applyTo` here, so an overlap loads the SAME guidance twice
# on a matching file rather than merely listing it twice.
if ($doInstructions) {
    $peerRules = Join-Path $destParent (Join-Path '.claude' 'rules')
    if (Test-Path $peerRules) {
        $peerNames = @(Get-ChildItem $peerRules -File -Force -Filter '*.md' -ErrorAction SilentlyContinue |
            Where-Object { $desiredInstructions.Contains($_.BaseName) } |
            Select-Object -ExpandProperty BaseName)
        if ($peerNames.Count -gt 0) {
            Write-Warning ("$($peerNames.Count) selected instruction(s) also exist as rules in " +
                "$peerRules, which Copilot reads too, so the same guidance loads twice on a " +
                "matching file: $($peerNames -join ', '). To suppress it, set one of those roots " +
                "false in the target's chat.instructionsFilesLocations -- it takes FOLDERS only, " +
                "and the VS Code sidebar honours a change immediately.")
        }
    }
}
#endregion

#region Read prior manifest
# The manifest is the record of what THIS script deployed on past runs. It is
# the only thing that authorizes a delete: a folder named here is ours to
# prune or re-sync, a folder absent from it is the client's and is never
# touched.
# The legacy file is read only when the current one is absent, so a target
# mid-migration is never read twice.
$hadLegacyManifest = Test-Path $LegacyManifest
$readFrom = if (Test-Path $ManifestPath) { $ManifestPath }
            elseif ($hadLegacyManifest) { $LegacyManifest }
            else { $null }

$managedBefore = @(if ($readFrom) { Read-ManagedManifest -Path $readFrom -Key 'skills' } else { @() })
$managedInstructionsBefore = @(Read-ManagedManifest -Path $InstructionsManifest -Key 'instructions')
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

        $bytes = Get-PayloadContent $file.FullName
        if (Test-FileMatch -Path $target -Bytes $bytes) {
            $same++
            continue
        }
        $targetParent = Split-Path -Parent $target
        if (-not (Test-Path $targetParent)) {
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        }
        [IO.File]::WriteAllBytes($target, $bytes)
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
if ($doSkills -and -not (Test-Path $DestRoot)) {
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
#
# The $doSkills guard is load-bearing, not tidiness. With skills deselected
# $desiredSkills is empty, and an unguarded prune reads that as "nothing is
# selected any more" and deletes every skill the manifest owns. Deselecting a
# PAYLOAD must leave it alone; only deselecting a GROUP prunes.
$prunedSkills = 0
if ($doSkills) {
    $toPrune = @($managedBefore | Where-Object { -not $desiredSkills.Contains($_) })
    foreach ($name in $toPrune) {
        $destSkillDir = Join-Path $DestRoot $name
        if (-not (Test-Path $destSkillDir)) { continue }
        if ($PSCmdlet.ShouldProcess($destSkillDir, 'Prune deselected skill')) {
            Remove-Item $destSkillDir -Recurse -Force
            Write-Host "Pruned  $name (no longer selected)"
            $prunedSkills++
        }
    }
}
#endregion

#region Write manifest
# Deliberately minimal, and everything absent from it is absent on purpose:
# no source repo, commit, generator, machine path or username. See the
# .DESCRIPTION -- the only job this file has at the target is telling the
# next run which folders are ours.
if ($doSkills) {
    $manifest = [ordered]@{
        skills = @($managedNow)
    }
    $manifestJson = $manifest | ConvertTo-Json -Depth 5

    if (Set-IfChanged -Path $ManifestPath -Content $manifestJson -Label '.managed-skills.json') {
        Write-Host "Wrote   .managed-skills.json"
    }
    elseif (-not $WhatIfPreference) {
        Write-Host "OK      .managed-skills.json (unchanged)"
    }
}

# Remove what an earlier version of this script left behind. Both named this
# repo, which is the whole reason they are going. The manifest filename is
# ours by construction, so it goes on sight; README.md is a name anyone might
# use, so it is only considered when that manifest was there too -- evidence
# of an old deployment -- and only when it still carries the heading that
# version wrote. Without both, a README the repo owns is left alone silently
# rather than warned about on every future run.
$legacyFiles = @(if (-not $doSkills) { @() } else {
    @($LegacyManifest) + $(if ($hadLegacyManifest) { @($LegacyReadme) } else { @() })
})
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

#region Copy, prune and record instructions
# Same ownership model as skills, one directory over: the manifest is the only
# thing that authorizes a delete, a file absent from it belongs to the client,
# and a collision is skipped rather than clobbered unless -Force adopts it.
# The unit is a FILE here rather than a folder, which is the only real
# difference -- and the reason instructions keep their own manifest.
$instructionsCopied  = 0
$instructionsSkipped = 0
$instructionsPruned  = 0
$managedInstructionsNow = @()

if ($doInstructions) {
    if (-not (Test-Path $DestInstructions)) {
        if ($PSCmdlet.ShouldProcess($DestInstructions, 'Create instructions directory')) {
            New-Item -ItemType Directory -Path $DestInstructions -Force | Out-Null
            Write-Host "Created $DestInstructions"
        }
    }

    foreach ($stem in $desiredInstructions.Keys) {
        $fileName = $desiredInstructions[$stem]
        $src      = Join-Path $InstructionsRoot $fileName
        $dest     = Join-Path $DestInstructions $fileName
        $existsAtDest = Test-Path $dest
        $isOurs       = $managedInstructionsBefore -contains $stem

        if ($existsAtDest -and -not $isOurs -and -not $Force) {
            # Hand-authored by the client until proven otherwise. This is the
            # expected first-run outcome in a repo that already writes its own
            # instructions, not a fault.
            Write-Warning ("$fileName collides with an existing instructions/$fileName that " +
                           "this script did not deploy. Skipped. Re-run with -Force to adopt " +
                           "and overwrite it.")
            $script:DriftCount++
            $instructionsSkipped++
            continue
        }

        $bytes     = Get-PayloadContent $src
        $unchanged = $existsAtDest -and (Test-FileMatch -Path $dest -Bytes $bytes)
        $action = if ($existsAtDest -and -not $isOurs) { 'Adopt and overwrite instruction' }
                  else { 'Copy instruction' }

        if ($unchanged) {
            if (-not $WhatIfPreference) { Write-Host "OK      $fileName (unchanged)" }
        }
        elseif ($PSCmdlet.ShouldProcess($dest, "$action from copilot/instructions/$fileName")) {
            [IO.File]::WriteAllBytes($dest, $bytes)
            $tag = if ($existsAtDest -and -not $isOurs) { ' (adopted)' } else { '' }
            Write-Host "Synced  $fileName$tag"
            $instructionsCopied++
        }
        $managedInstructionsNow += $stem
    }

    # Ours, and no longer shipped by the repo -- a rule whose port was deleted.
    foreach ($stem in @($managedInstructionsBefore | Where-Object { -not $desiredInstructions.Contains($_) })) {
        $dest = Join-Path $DestInstructions "$stem.instructions.md"
        if (-not (Test-Path $dest)) { continue }
        if ($PSCmdlet.ShouldProcess($dest, 'Prune instruction no longer in the repo')) {
            Remove-Item $dest -Force
            Write-Host "Pruned  $stem.instructions.md (no longer shipped)"
            $instructionsPruned++
        }
    }

    $instructionsManifestJson = [ordered]@{
        instructions = @($managedInstructionsNow)
    } | ConvertTo-Json -Depth 5

    if (Set-IfChanged -Path $InstructionsManifest -Content $instructionsManifestJson `
            -Label '.managed-instructions.json') {
        Write-Host "Wrote   .managed-instructions.json"
    }
    elseif (-not $WhatIfPreference) {
        Write-Host "OK      .managed-instructions.json (unchanged)"
    }
}
#endregion

#region Summary
Write-Host ""
if ($doSkills) {
    Write-Host ("Skills  $copiedCount synced from group(s): $($selectedGroups -join ', ')" +
                $(if ($prunedSkills)  { "; $prunedSkills pruned" } else { '' }) +
                $(if ($skippedCount)  { "; $skippedCount skipped (collision)" } else { '' }))
}
if ($doInstructions) {
    Write-Host ("Instr   $($desiredInstructions.Count) selected, $instructionsCopied written" +
                $(if ($instructionsPruned)  { "; $instructionsPruned pruned" } else { '' }) +
                $(if ($instructionsSkipped) { "; $instructionsSkipped skipped (collision)" } else { '' }))
}
Write-Host ("Target  $CopilotDirFull" + $(if ($IsUserScope) { ' (user scope)' } else { ' (project scope)' }))

if ($script:DriftCount -gt 0) {
    Write-Host "`nDone with $script:DriftCount item(s) needing attention (see warnings above)."
    exit 1
}
if ($WhatIfPreference) {
    Write-Host "`nDone. Dry run -- nothing was written."
    exit 0
}
Write-Host "`nDone. $($Payload -join ' and ') copied."
exit 0
#endregion
