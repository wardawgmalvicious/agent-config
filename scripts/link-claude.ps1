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

    THIS REPO'S OWN .claude/skills IS DELIBERATELY OUT OF SCOPE HERE, and
    its absence is a design decision rather than an oversight. The skills
    that maintain this repo's payload (author-skill, test-skill, learn,
    drift-*, land) are authored at project scope in .claude/skills/ and
    deploy nowhere: they can only ever act on this working tree, so
    putting them in user scope only cost listing budget in every
    client-repo session on the machine. Nothing here needed changing when
    they moved (2026-09-09) because this script selects out of skills/ and
    they are not in it. Two consequences worth knowing. They are real
    directories rather than junctions, so even a run pointed at
    -ClaudeDir <this repo>/.claude leaves them alone -- the prune skips
    anything that is not a reparse point into skills/. And a NAME
    COLLISION between the two trees would be silent here: user scope
    outranks project scope, so re-creating one of those names under
    skills/ shadows the project-scope copy with no error anywhere, and
    nothing in this script can see it because it never reads
    .claude/skills. scripts/lint-skill-scopes.py is what catches that,
    at commit time rather than deploy time; pre-commit runs it.

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

    ~/.claude.json IS STRICTER STILL and is off by default even under
    -Force, because it is not payload at all: it is Claude Code's own
    runtime state - oauth account, project history, usage counters - and a
    live session rewrites it from memory on its own schedule. -GlobalMcp
    opts into reconciling exactly ONE key in it, top-level mcpServers,
    against claude/mcp/.mcp.global.template.json, pruning user-scope
    servers the template does not declare. Every other key is round-tripped
    untouched. Drift is REPORTED on every run either way, because Docker
    Desktop's MCP Toolkit writes an unfiltered MCP_DOCKER gateway entry
    whenever it connects a client - so this is a reconciler for something
    an external app re-adds, not a one-time cleanup.

    Two parse switches are load-bearing there, and both fail silently when
    omitted. -AsHashtable: the file carries project keys differing only in
    drive-letter casing (C:/... and c:/...), which a plain ConvertFrom-Json
    rejects outright as a duplicate-key collision, so the read throws on a
    perfectly valid file. -DateKind String: without it every ISO-8601
    timestamp in the file is parsed to [datetime] and re-emitted in LOCAL
    time, so a run that changes no server still silently rewrites the
    rate-limit caches this script does not own. With both, the round trip
    is semantically identical - verified 2026-09-07 by canonical diff
    against the live 63 KB file.

    The template's <USER> placeholder is substituted from $env:USERNAME at
    deploy time. That is deliberate rather than incidental: the literal
    profile path belongs in the live file and never in the repo.

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

.PARAMETER GlobalMcp
    Reconcile the top-level mcpServers key in ~/.claude.json against
    claude/mcp/.mcp.global.template.json, PRUNING user-scope servers the
    template does not declare. The file is backed up first. Off by default
    even with -Force, skipped entirely under -SkillsOnly, and ignored
    unless -ClaudeDir is user scope, since no other scope has this file.
    Without it, drift is reported and nothing is written.

.EXAMPLE
    ./scripts/link-claude.ps1
    Verify and relink the full user-scope payload, reporting drift.

.EXAMPLE
    ./scripts/link-claude.ps1 -Force
    Same, and push drifted CLAUDE.md / settings.json to the target.

.EXAMPLE
    ./scripts/link-claude.ps1 -SkillGroups workflow
    THIS MACHINE'S DEFAULT. User scope, but only the repo-general verbs
    (code-review, commit); fabric and powerbi are pruned from
    ~/.claude/skills. This repo's own maintenance skills are not in this
    group and are deployed by nothing -- see the .DESCRIPTION.

.EXAMPLE
    ./scripts/link-claude.ps1 -SkillGroups workflow -Force
    Same as above example but pushes drifted CLAUDE.md / settings.json to the target.

.EXAMPLE
    ./scripts/link-claude.ps1 -SkillGroups workflow -GlobalMcp
    Same, and reconcile ~/.claude.json's user-scope mcpServers down to the
    servers the global template declares.

.EXAMPLE
    ./scripts/link-claude.ps1 -ClaudeDir C:\Repos\Client\.claude -SkillGroups fabric,powerbi -SkillsOnly
    Give a client repo the platform skills and nothing else.
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [string]$ClaudeDir = (Join-Path $HOME '.claude'),
    [string[]]$SkillGroups,
    [switch]$SkillsOnly,
    [switch]$GlobalMcp
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
# User-scope MCP servers live in ~/.claude.json, which sits BESIDE ~/.claude
# rather than inside it, and exists at no other scope - a project's
# equivalent is a committed .mcp.json at its repo root, which this script
# does not deploy. So this pair is resolved once, from $HOME, and the
# reconcile is skipped when -ClaudeDir points anywhere else.
$GlobalMcpTemplate = Join-Path $RepoRoot 'claude/mcp/.mcp.global.template.json'
$GlobalMcpConfig   = Join-Path $HOME '.claude.json'
$UserScopeDir      = Join-Path $HOME '.claude'
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

function Test-JsonEqual($A, $B) {
    # Full equality over the OrderedHashtable shape ConvertFrom-Json
    # -AsHashtable produces, as opposed to Test-JsonSubset's one-way check
    # over PSCustomObjects. Deliberately ORDER-INSENSITIVE for maps: a
    # server whose keys the template writes as type/url and the live file
    # holds as url/type is the same server, and comparing serialized text
    # would report drift that no rewrite could ever settle.
    if ($A -is [System.Collections.IDictionary]) {
        if ($B -isnot [System.Collections.IDictionary]) { return $false }
        if ($A.Keys.Count -ne $B.Keys.Count) { return $false }
        foreach ($key in $A.Keys) {
            if (-not $B.Contains($key)) { return $false }
            if (-not (Test-JsonEqual $A[$key] $B[$key])) { return $false }
        }
        return $true
    }
    # Strings are not IList, so they fall through to the scalar compare.
    if ($A -is [System.Collections.IList]) {
        if ($B -isnot [System.Collections.IList]) { return $false }
        if ($A.Count -ne $B.Count) { return $false }
        for ($i = 0; $i -lt $A.Count; $i++) {
            if (-not (Test-JsonEqual $A[$i] $B[$i])) { return $false }
        }
        return $true
    }
    return $A -eq $B
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

function Sync-GlobalMcp {
    # Reconcile ONE key - top-level mcpServers - in Claude Code's runtime
    # state file against the global template. See .DESCRIPTION for why this
    # is opt-in, and why the two ConvertFrom-Json switches below are not
    # optional.
    param([string]$TemplatePath, [string]$ConfigPath, [switch]$Apply)

    if (-not (Test-Path $TemplatePath)) {
        Write-Warning "Repo file missing, skipped: $TemplatePath"
        $script:DriftCount++
        return
    }
    if (-not (Test-Path $ConfigPath)) {
        # Never create it. Claude Code owns this file's shape, and a stub
        # holding nothing but mcpServers would be a worse starting point
        # than the one it writes for itself on first run.
        Write-Warning ("$ConfigPath does not exist - Claude Code writes it on first run. " +
            "Nothing to reconcile.")
        $script:DriftCount++
        return
    }

    # <USER> is substituted at deploy time so the literal profile path lands
    # in the live file and never in the repo.
    #
    # It is taken from the PROFILE DIRECTORY, not from $env:USERNAME. Those
    # are different strings on this machine - the account was renamed after
    # the profile folder was created - and the placeholder sits inside a
    # LOCALAPPDATA path, so $env:USERNAME builds C:\Users\<account>\AppData\
    # Local, a directory that does not exist. Nothing would report that: the
    # docker gateway starts, fails to resolve Docker Desktop's per-user
    # state, and surfaces as a server that will not connect.
    $profileName  = Split-Path -Leaf $HOME
    $templateText = (Get-Content $TemplatePath -Raw).Replace('<USER>', $profileName)
    # Reconstructing the path only holds while AppData sits under the
    # profile. Say so rather than emitting a silently wrong value.
    $expectedLocalAppData = Join-Path $HOME 'AppData\Local'
    if ($env:LOCALAPPDATA -and $env:LOCALAPPDATA -ine $expectedLocalAppData) {
        Write-Warning ("LOCALAPPDATA is '$env:LOCALAPPDATA', not '$expectedLocalAppData' - " +
            "the <USER> substitution assumes AppData lives under the profile. " +
            "Edit the env block in $TemplatePath by hand.")
        $script:DriftCount++
    }
    $template = $templateText | ConvertFrom-Json -AsHashtable -DateKind String
    if (-not $template.Contains('mcpServers')) {
        Write-Warning "$TemplatePath has no top-level mcpServers key, skipped."
        $script:DriftCount++
        return
    }
    $desired = $template['mcpServers']

    $config  = Get-Content $ConfigPath -Raw | ConvertFrom-Json -AsHashtable -DateKind String
    $current = [ordered]@{}
    if ($config.Contains('mcpServers')) { $current = $config['mcpServers'] }

    $missing   = @($desired.Keys | Where-Object { -not $current.Contains($_) })
    $differing = @($desired.Keys | Where-Object {
        $current.Contains($_) -and -not (Test-JsonEqual $desired[$_] $current[$_]) })
    # Local-scope servers live under projects.<path>.mcpServers and are a
    # different key entirely, so nothing here can reach them.
    $extra     = @($current.Keys | Where-Object { -not $desired.Contains($_) })

    if ($missing.Count -eq 0 -and $differing.Count -eq 0 -and $extra.Count -eq 0) {
        Write-Host "OK      .claude.json (user-scope mcpServers match the template)"
        return
    }

    $summary = @(
        if ($missing.Count)   { "$($missing.Count) missing: $($missing -join ', ')" }
        if ($differing.Count) { "$($differing.Count) differing: $($differing -join ', ')" }
        if ($extra.Count)     { "$($extra.Count) not in template: $($extra -join ', ')" }
    ) -join '; '

    if (-not $Apply) {
        Write-Warning "user-scope mcpServers in $ConfigPath drifted from the template - $summary"
        Write-Warning ("Re-run with -GlobalMcp to reconcile (the file is backed up first). " +
            "Servers 'not in template' are DELETED from user scope; move any you still " +
            "want to the owning repo's .mcp.json first - see claude/mcp/README.md.")
        $script:DriftCount++
        return
    }

    $backup = "$ConfigPath.$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
    Copy-Item $ConfigPath $backup -Force
    Write-Host "Backed up $ConfigPath -> $(Split-Path -Leaf $backup)"

    $config['mcpServers'] = $desired
    $serialized = $config | ConvertTo-Json -Depth 100
    # Validate through the SAME switches the read used, before the write.
    # A gate that parses more strictly than the reader rejects good content
    # and abandons the write silently.
    $null = $serialized | ConvertFrom-Json -AsHashtable -DateKind String
    Set-Content -Path $ConfigPath -Value $serialized -Encoding utf8NoBOM

    foreach ($name in $extra)   { Write-Host "Pruned  mcpServers/$name (not in template)" }
    foreach ($name in $missing) { Write-Host "Added   mcpServers/$name" }
    foreach ($name in $differing) { Write-Host "Updated mcpServers/$name" }
    Write-Host ("Synced  .claude.json mcpServers ($($desired.Keys.Count) server(s): " +
                "$($desired.Keys -join ', '))")
    Write-Warning ("Claude Code rewrites $ConfigPath from memory, so a session that " +
        "started BEFORE this run can revert it on exit. Confirm in a fresh session with " +
        "'claude mcp list'.")
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

#region User-scope MCP servers (~/.claude.json)
if ($SkillsOnly) {
    Write-Host "Skipped .claude.json mcpServers (-SkillsOnly)"
}
elseif (-not (Test-SamePath $ClaudeDir $UserScopeDir)) {
    # A project target's MCP equivalent is a committed .mcp.json at its repo
    # root, which is a copy-the-template step rather than a linker one.
    Write-Host "Skipped .claude.json mcpServers (user scope only; -ClaudeDir is not $UserScopeDir)"
}
else {
    Sync-GlobalMcp -TemplatePath $GlobalMcpTemplate -ConfigPath $GlobalMcpConfig -Apply:$GlobalMcp
}
#endregion

if ($script:DriftCount -gt 0) {
    Write-Host "`nDone with $script:DriftCount item(s) needing attention (see warnings above)."
    exit 1
}
Write-Host "`nDone. Payload verified (skills linked, everything else copied)."
exit 0
