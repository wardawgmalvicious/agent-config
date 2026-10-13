<#
.SYNOPSIS
    Export, check or apply a personal repo's GitHub settings against a
    snapshot in a clone of that repo, at .github/repo-settings.json.

.DESCRIPTION
    GitHub keeps a repo's settings on the server and nowhere else, so they
    do not travel with a clone and do not survive a delete-and-recreate.
    That happened on 2026-09-10: the repo was recreated to purge leaked
    names from history, every toggle reset to GitHub's defaults, and no
    record of the old values existed to restore from. The snapshot file is
    that record, and this script is how it is read and restored.

    IT SHIPS INSIDE THE recreate-repo SKILL, whose SKILL.md, one folder up,
    is the order a recreate takes. On 2026-09-23 another repo was recreated
    for the same reason and this script was not reached for: nothing in
    that repo knew it existed. A skill's description reaches every session
    on the machine, and the skill's folder brings the script along.

    A REPO'S SNAPSHOT LIVES IN A CLONE OF THAT REPO. -Repo defaults to the
    origin of the clone the working directory is in, and -Path to that
    clone's .github/repo-settings.json, but only while -Repo is the clone's
    own repo: any other repo's snapshot needs -Path, so none lands in the
    tree of a repo it does not describe, a client's above all. The working
    directory decides, never this file's location. Deployed, the skill
    folder is a junction under ~/.claude/skills, and git run from it
    answers the checkout behind the junction, so defaults built on
    $PSScriptRoot would name that checkout's repo while writing into the
    skill folder (measured 2026-10-12). Until that day the defaults put
    every snapshot they wrote beside this script, in the repo that
    sources ~/.claude, so a recreate run from any other repo wrote into
    that one. One repo kept its own in its clone as well, from 2026-09-23.

    Three modes, one per switch. -Check is the default and is read-only.
      -Export  read the live repo and overwrite the JSON file with it
      -Check   report every setting where live and file disagree; exit 1
               on any drift, so it can gate a script
      -Apply   change the live repo to match the file, then re-check. The
               only mode that writes to GitHub.

    A SNAPSHOT NAMES ITS REPO, in its _repo key, and every mode refuses a
    file naming another repo than -Repo, -Export over one included, before
    the first gh call. Read from the source on 2026-09-30, the two defaults
    were independent, so naming one left the other on the script's own
    repo: a crossed -Export overwrote that repo's snapshot with another
    repo's settings, and a crossed -Apply patched the other repo with that
    one's, its owner check passing because one account owned both. A file
    that names no repo, or is not JSON, is refused too and never
    overwritten. One exported before 2026-10-01, when _repo arrived, has
    none: to adopt it, check from its history that it is the clone's own,
    add "_repo": "<owner>/<name>" by hand, and run -Check before -Export,
    since only every setting matching the live repo shows whose settings
    the file holds (adopted so in another repo, 2026-10-12).

    CURATED, NOT A DUMP. The file holds settable values only. The raw
    `gh api repos/...` answer also carries ids, counters, timestamps and
    URLs that move on every push, so committing it would churn on each
    export and bury the one line that matters in the diff.

    WHAT IT DOES NOT CAPTURE, and why:
      - Visibility. Recorded nowhere and never applied: a file edit must
        not be able to publish or hide a repo.
      - The social preview image. GitHub has a read side and no write side
        (measured 2026-09-23, re-run 2026-10-01): no GraphQL mutation, no
        REST endpoint and no field of PATCH /repos/{owner}/{repo} sets it,
        while GraphQL's usesCustomOpenGraphImage says whether one is
        uploaded. So -Check, and -Apply's re-check, print a SKIP line when
        none is, naming the manual upload. It never counts as drift:
        -Apply could never clear it, and a repo may rightly have no card.
      - Classic branch protection. Rulesets are the current mechanism and
        are exported and checked; no repo this has run against has any.
        Applying rulesets is not implemented -- -Apply reports a ruleset
        difference as SKIP rather than guessing at a create/update it has
        never been tested against.
      - Secrets and variables. Their values are not readable by design.

    `gh repo edit` REACHES ONLY PART OF THIS, so do not simplify the
    script into it. Its help (gh 2.101.0, read 2026-10-01) has no flag
    for secret_scanning_non_provider_patterns or _validity_checks,
    Dependabot alerts or security updates, private vulnerability
    reporting, Actions permissions or workflow permissions, rulesets,
    merge_commit_title or _message, or web_commit_signoff_required. Its
    one squash flag takes one of four presets, where this file records a
    title and a message.

    AUTHORIZATION IS CHECKED, NOT ASSUMED. Read without admin rights, the
    merge settings come back null rather than failing, and a snapshot
    taken that way would record nulls as though they were settings. So a
    null allow_squash_merge aborts every mode. -Export and -Apply also
    refuse unless `gh` acts as the repo's owner: on this machine gh is
    folder-scoped and can resolve to a different account than the one
    that owns the repo (see ~/.claude/CLAUDE.md). The same check keeps out
    an organization's repo, which is its owners' to snapshot and restore,
    never one member's.

.PARAMETER Export
    Overwrite the JSON file with the live settings.

.PARAMETER Check
    Compare live against the file and report drift. The default.

.PARAMETER Apply
    Change the live repo to match the file, then re-check.

.PARAMETER Repo
    owner/name. Defaults to the origin remote of the clone the working
    directory is in.

.PARAMETER Path
    The snapshot file. Defaults to .github/repo-settings.json in the clone
    the working directory is in, and only while -Repo is that clone's own
    repo; any other repo's snapshot needs it.

.EXAMPLE
    & <skill>/scripts/repo-settings.ps1            # check, from a clone of the repo
    & <skill>/scripts/repo-settings.ps1 -Export    # snapshot after changing a setting in the UI
    & <skill>/scripts/repo-settings.ps1 -Apply -Path <snapshot>   # restore after a recreate, from the snapshot taken before it
#>
[CmdletBinding(DefaultParameterSetName = 'Check')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Export')][switch]$Export,
    [Parameter(ParameterSetName = 'Check')][switch]$Check,
    [Parameter(Mandatory, ParameterSetName = 'Apply')][switch]$Apply,
    [string]$Repo,
    [string]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# The repository-level keys worth recording: every one is settable through
# PATCH /repos/{owner}/{repo}. Order here is the order written to the file.
$script:RepositoryKeys = @(
    'description', 'homepage',
    'has_issues', 'has_projects', 'has_wiki', 'has_discussions',
    'allow_merge_commit', 'allow_squash_merge', 'allow_rebase_merge',
    'allow_auto_merge', 'allow_update_branch', 'delete_branch_on_merge',
    'squash_merge_commit_title', 'squash_merge_commit_message',
    'merge_commit_title', 'merge_commit_message',
    'web_commit_signoff_required'
)
# Server-owned ruleset fields, stripped so a ruleset compares on content.
$script:RulesetNoise = @('id', 'node_id', 'source', 'source_type', 'created_at',
    'updated_at', '_links', 'current_user_can_bypass')
$script:Comment = 'Managed by repo-settings.ps1, from the recreate-repo skill (-Export / -Check / -Apply). ' +
    'Visibility and the social preview image are deliberately not here; see the script header.'
# Keys that document the file rather than set anything: never compared.
$script:MetaKeys = @('_comment', '_repo')

function Step { param($m) Write-Host "`n=== $m" -ForegroundColor Cyan }
function Ok { param($m) Write-Host "  [ok]    $m" -ForegroundColor Green }
function Plan { param($m) Write-Host "  [drift] $m" -ForegroundColor Yellow }
function Skip { param($m) Write-Host "  [SKIP]  $m" -ForegroundColor DarkYellow }
function Fail { param($m) Write-Host "  [FAIL]  $m" -ForegroundColor Red; $script:Failures += $m }
$script:Failures = @()

#region gh helpers
# One place that calls gh. Returns the exit code and the text; callers
# decide what a non-zero code means, because for the status-only
# endpoints a 404 is an answer ("disabled"), not an error.
#
# pwsh decodes a native command's output with [Console]::OutputEncoding,
# and that is the console's code page, not UTF-8 -- ibm437 when pwsh is
# launched from Git Bash. gh writes UTF-8, so an em dash in the
# description came back as mojibake: -Check reported drift against a
# correct file, and -Export would have written the mojibake into it
# (measured 2026-09-10; the PowerShell tool's console was UTF-8 and hid
# it). So every gh call runs under UTF-8, restored immediately after.
function Invoke-GhApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Endpoint,
        [string]$Method = 'GET',
        [object]$Body
    )
    $ghArgs = @('api', '-X', $Method, $Endpoint, '-H', 'Accept: application/vnd.github+json')
    $consoleEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    try {
        if ($null -ne $Body) {
            $out = ($Body | ConvertTo-Json -Depth 20 -Compress) | gh @ghArgs --input - 2>&1
        } else {
            $out = gh @ghArgs 2>&1
        }
        $exitCode = $LASTEXITCODE
    } finally {
        [Console]::OutputEncoding = $consoleEncoding
    }
    [pscustomobject]@{ ExitCode = $exitCode; Text = (@($out) -join "`n") }
}

function Get-GhJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Endpoint)
    $r = Invoke-GhApi -Endpoint $Endpoint
    if ($r.ExitCode -ne 0) { throw "gh api $Endpoint failed: $($r.Text)" }
    if ([string]::IsNullOrWhiteSpace($r.Text)) { return $null }
    return ($r.Text | ConvertFrom-Json -AsHashtable)
}

# 204 means on, 404 means off; anything else is a real failure.
function Get-GhFlag {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Endpoint)
    $r = Invoke-GhApi -Endpoint $Endpoint
    if ($r.ExitCode -eq 0) { return $true }
    if ($r.Text -match 'HTTP 404') { return $false }
    throw "gh api $Endpoint failed: $($r.Text)"
}

function Invoke-GhWrite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$Endpoint,
        [Parameter(Mandatory)][string]$Method,
        [object]$Body
    )
    $r = Invoke-GhApi -Endpoint $Endpoint -Method $Method -Body $Body
    if ($r.ExitCode -eq 0) { Ok "$Label applied" } else { Fail "$Label -- $($r.Text)" }
}
#endregion

#region Read live settings into the file's shape
function Get-LiveSetting {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repo)
    $repoJson = Get-GhJson "repos/$Repo"
    if (-not $repoJson.ContainsKey('allow_squash_merge') -or $null -eq $repoJson['allow_squash_merge']) {
        throw "Merge settings for $Repo came back null: gh is not authorized to read them. " +
            'A snapshot taken this way would record nulls as settings.'
    }

    # GitHub's own spelling of the name, which -Repo matches case-insensitively.
    $settings = [ordered]@{ '_comment' = $script:Comment; '_repo' = $repoJson['full_name'] }

    $repository = [ordered]@{}
    foreach ($key in $script:RepositoryKeys) {
        if ($repoJson.ContainsKey($key)) { $repository[$key] = $repoJson[$key] }
    }
    $settings['repository'] = $repository
    $settings['topics'] = @(@($repoJson['topics']) | Sort-Object)

    # security_and_analysis minus dependabot_security_updates, which lives
    # under "dependabot" below with its own endpoint -- one home per toggle.
    $security = [ordered]@{}
    if ($repoJson.ContainsKey('security_and_analysis') -and $null -ne $repoJson['security_and_analysis']) {
        foreach ($key in @($repoJson['security_and_analysis'].Keys | Sort-Object)) {
            if ($key -eq 'dependabot_security_updates') { continue }
            $security[$key] = $repoJson['security_and_analysis'][$key]['status']
        }
    }
    $settings['security_and_analysis'] = $security

    $fixes = Get-GhJson "repos/$Repo/automated-security-fixes"
    $settings['dependabot'] = [ordered]@{
        'alerts'           = Get-GhFlag "repos/$Repo/vulnerability-alerts"
        'security_updates' = [bool]$fixes['enabled']
    }
    $reporting = Get-GhJson "repos/$Repo/private-vulnerability-reporting"
    $settings['private_vulnerability_reporting'] = [bool]$reporting['enabled']

    $settings['actions'] = [ordered]@{
        'permissions'          = Get-GhJson "repos/$Repo/actions/permissions"
        'workflow_permissions' = Get-GhJson "repos/$Repo/actions/permissions/workflow"
    }

    $rulesets = @()
    foreach ($summary in @(Get-GhJson "repos/$Repo/rulesets")) {
        if ($null -eq $summary) { continue }
        $full = Get-GhJson "repos/$Repo/rulesets/$($summary['id'])"
        foreach ($noise in $script:RulesetNoise) { [void]$full.Remove($noise) }
        $rulesets += , $full
    }
    $settings['rulesets'] = @($rulesets | Sort-Object { $_['name'] })
    return $settings
}

# The social preview has a read side and no write side (see the header), so
# it is reported here and never compared.
function Write-SocialPreview {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Repo)
    $owner, $name = $Repo.Split('/')
    $query = 'query($owner: String!, $name: String!) ' +
        '{ repository(owner: $owner, name: $name) { usesCustomOpenGraphImage } }'
    $body = @{ query = $query; variables = @{ owner = $owner; name = $name } }
    $r = Invoke-GhApi -Endpoint 'graphql' -Method 'POST' -Body $body
    if ($r.ExitCode -ne 0) { throw "gh api graphql failed: $($r.Text)" }
    $repository = ($r.Text | ConvertFrom-Json -AsHashtable)['data']['repository']
    if ($repository['usesCustomOpenGraphImage']) { return }
    Skip ('social preview: none uploaded, and no API can upload one -- by hand, ' +
        'Settings > General > Social preview')
}
#endregion

#region Compare
# Flatten to "path = compact json" pairs. Arrays compare whole: a topic
# list or a ruleset is one setting, and element-wise drift in it would be
# noise. The meta keys are documentation, never a setting.
function ConvertTo-FlatSetting {
    [CmdletBinding()]
    param($Node, [string]$Prefix = '')
    $flat = [ordered]@{}
    if ($Node -is [System.Collections.IDictionary]) {
        foreach ($key in $Node.Keys) {
            if ($key -in $script:MetaKeys) { continue }
            $childPath = if ($Prefix) { "$Prefix.$key" } else { $key }
            $child = ConvertTo-FlatSetting -Node $Node[$key] -Prefix $childPath
            foreach ($k in $child.Keys) { $flat[$k] = $child[$k] }
        }
    } else {
        $flat[$Prefix] = ConvertTo-Json -InputObject $Node -Depth 20 -Compress
    }
    return $flat
}

function Compare-Setting {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Live, [Parameter(Mandatory)]$Wanted)
    # Topics are a set; GitHub returns them sorted, a hand edit may not be.
    if ($Wanted.Contains('topics')) { $Wanted['topics'] = @(@($Wanted['topics']) | Sort-Object) }
    $liveFlat = ConvertTo-FlatSetting -Node $Live
    $wantedFlat = ConvertTo-FlatSetting -Node $Wanted
    $drift = [ordered]@{}
    $same = 0
    foreach ($key in @($wantedFlat.Keys) + @($liveFlat.Keys | Where-Object { -not $wantedFlat.Contains($_) })) {
        $liveValue = if ($liveFlat.Contains($key)) { $liveFlat[$key] } else { '<absent>' }
        $wantedValue = if ($wantedFlat.Contains($key)) { $wantedFlat[$key] } else { '<absent>' }
        if ($liveValue -ne $wantedValue) {
            $drift[$key] = [pscustomobject]@{ Live = $liveValue; Wanted = $wantedValue }
        } else {
            $same++
        }
    }
    return [pscustomobject]@{ Drift = $drift; Same = $same }
}

function Write-Drift {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Result)
    foreach ($key in $Result.Drift.Keys) {
        $d = $Result.Drift[$key]
        Plan "$key : live $($d.Live) -> file $($d.Wanted)"
    }
    Ok "$($Result.Same) setting(s) already match"
}
#endregion

#region The snapshot and its repo
# owner/name of the origin remote, or $null where there is no GitHub origin.
function Get-OriginRepo {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)
    $url = git -C $Root remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0 -or $url -notmatch 'github\.com[:/](?<owner>[^/]+)/(?<name>[^/]+?)(\.git)?$') {
        return $null
    }
    return "$($Matches['owner'])/$($Matches['name'])"
}

# The snapshot at $Path, or $null where there is none yet. A file there that
# names no repo cannot be paired with -Repo, so it is refused, never
# overwritten: nothing shows whose settings it holds.
function Read-Snapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $refusal = "$Path cannot be paired with -Repo, so it is neither read nor overwritten"
    try {
        $snapshot = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable
    } catch {
        throw "${refusal}: it is not JSON."
    }
    if ($snapshot -isnot [System.Collections.IDictionary] -or -not $snapshot.Contains('_repo') -or
        $snapshot['_repo'] -isnot [string] -or [string]::IsNullOrWhiteSpace($snapshot['_repo'])) {
        throw "${refusal}: it names no repo in a _repo key."
    }
    return $snapshot
}
#endregion

#region Pre-flight
# Every refusal here comes before the first gh call, so it costs nothing and
# tests/scripts/repo-settings/ proves it offline.
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'gh not found on PATH. hint: winget install GitHub.cli'
}
# The clone the working directory is in, never this file's: see the header.
$workingDir = (Get-Location -PSProvider FileSystem).ProviderPath
$cloneRoot = git -C $workingDir rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) { $cloneRoot = $null }
$originRepo = if ($cloneRoot) { Get-OriginRepo -Root $cloneRoot } else { $null }
if (-not $Repo) {
    if (-not $originRepo) {
        throw "No GitHub origin remote for $workingDir; pass -Repo owner/name and -Path."
    }
    $Repo = $originRepo
}
if ($Repo -notmatch '^[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+$') { throw "-Repo takes owner/name, not '$Repo'." }
if (-not $Path) {
    # GitHub's names are case-insensitive, and so is -eq.
    if (-not $originRepo -or $Repo -ne $originRepo) {
        $whereItRuns = if ($originRepo) { "is a clone of $originRepo" } else { 'is in no clone with a GitHub origin' }
        throw "$Repo's snapshot has no default home in $workingDir, which $whereItRuns. " +
            "Run from a clone of $Repo, or pass -Path."
    }
    $Path = Join-Path $cloneRoot '.github/repo-settings.json'
}
# Resolved once, so the file checked here is the file -Export writes: .NET
# resolves a relative path against the process directory, not $PWD.
$Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
Step "Repo $Repo -- mode $($PSCmdlet.ParameterSetName) -- $Path"

$snapshot = Read-Snapshot -Path $Path
if ($null -eq $snapshot) {
    # After a recreate the live repo holds GitHub's defaults, and exporting
    # them would bury the snapshot that still says what it should hold.
    if (-not $Export) {
        throw "No settings file at $Path. -Export writes one from the live repo; after a " +
            'recreate, pass -Path the snapshot taken before the delete instead.'
    }
} elseif ($snapshot['_repo'] -ne $Repo) {
    throw "$Path is the snapshot of $($snapshot['_repo']), not $Repo, so it is neither read nor " +
        "overwritten. Pass -Repo $($snapshot['_repo']) to use it, or leave -Path out in a clone of $Repo."
}
#endregion

# Only a repo's owner writes its settings or snapshots them: gh can act as
# another account here, and an organization's repo is its owners'.
if ($Export -or $Apply) {
    $owner = $Repo.Split('/')[0]
    $login = gh api user -q .login
    if ($LASTEXITCODE -ne 0 -or $login -ne $owner) {
        $what = if ($Export) { 'snapshot a repo it does not own' } else { 'write settings under the wrong account' }
        throw "gh acts as '$login', not the repo owner '$owner'. Refusing to $what."
    }
}

$live = Get-LiveSetting -Repo $Repo

if ($Export) {
    [void][System.IO.Directory]::CreateDirectory((Split-Path $Path -Parent))
    $text = (ConvertTo-Json -InputObject $live -Depth 20).Replace("`r`n", "`n") + "`n"
    [System.IO.File]::WriteAllText($Path, $text, [System.Text.UTF8Encoding]::new($false))
    Ok "wrote $Path"
    exit 0
}

$wanted = $snapshot
$result = Compare-Setting -Live $live -Wanted $wanted

if (-not $Apply) {
    Write-Drift -Result $result
    Write-SocialPreview -Repo $Repo
    exit ([int]($result.Drift.Count -gt 0))
}

#region Apply
$drift = $result.Drift
if ($drift.Count -eq 0) {
    Ok 'nothing to apply'
    Write-SocialPreview -Repo $Repo
    exit 0
}
Write-Drift -Result $result
Step 'Applying'

$repoPatch = [ordered]@{}
foreach ($key in $script:RepositoryKeys) {
    if ($drift.Contains("repository.$key")) { $repoPatch[$key] = $wanted['repository'][$key] }
}
if ($repoPatch.Count) { Invoke-GhWrite -Label 'repository settings' -Endpoint "repos/$Repo" -Method 'PATCH' -Body $repoPatch }

if ($drift.Contains('topics')) {
    Invoke-GhWrite -Label 'topics' -Endpoint "repos/$Repo/topics" -Method 'PUT' -Body @{ names = @($wanted['topics']) }
}

$securityPatch = [ordered]@{}
foreach ($key in $wanted['security_and_analysis'].Keys) {
    if ($drift.Contains("security_and_analysis.$key")) {
        $securityPatch[$key] = @{ status = $wanted['security_and_analysis'][$key] }
    }
}
if ($securityPatch.Count) {
    Invoke-GhWrite -Label 'security_and_analysis' -Endpoint "repos/$Repo" -Method 'PATCH' -Body @{ security_and_analysis = $securityPatch }
}

# Security updates depend on alerts: enable alerts first, disable them last.
$alertsOn = [bool]$wanted['dependabot']['alerts']
$updatesOn = [bool]$wanted['dependabot']['security_updates']
$alertMethod = if ($alertsOn) { 'PUT' } else { 'DELETE' }
$updateMethod = if ($updatesOn) { 'PUT' } else { 'DELETE' }
$alertStep = {
    if ($drift.Contains('dependabot.alerts')) {
        Invoke-GhWrite -Label 'dependabot alerts' -Endpoint "repos/$Repo/vulnerability-alerts" -Method $alertMethod
    }
}
$updateStep = {
    if ($drift.Contains('dependabot.security_updates')) {
        Invoke-GhWrite -Label 'dependabot security updates' -Endpoint "repos/$Repo/automated-security-fixes" -Method $updateMethod
    }
}
if ($alertsOn) { & $alertStep; & $updateStep } else { & $updateStep; & $alertStep }

if ($drift.Contains('private_vulnerability_reporting')) {
    $method = if ([bool]$wanted['private_vulnerability_reporting']) { 'PUT' } else { 'DELETE' }
    Invoke-GhWrite -Label 'private vulnerability reporting' -Endpoint "repos/$Repo/private-vulnerability-reporting" -Method $method
}

if (@($drift.Keys | Where-Object { $_ -like 'actions.permissions.*' }).Count) {
    Invoke-GhWrite -Label 'actions permissions' -Endpoint "repos/$Repo/actions/permissions" -Method 'PUT' -Body $wanted['actions']['permissions']
}
if (@($drift.Keys | Where-Object { $_ -like 'actions.workflow_permissions.*' }).Count) {
    Invoke-GhWrite -Label 'workflow permissions' -Endpoint "repos/$Repo/actions/permissions/workflow" -Method 'PUT' -Body $wanted['actions']['workflow_permissions']
}

if ($drift.Contains('rulesets')) {
    Skip 'rulesets differ, and applying rulesets is not implemented -- change them in the UI, then -Export'
}

Step 'Re-checking'
$after = Compare-Setting -Live (Get-LiveSetting -Repo $Repo) -Wanted $wanted
Write-Drift -Result $after
Write-SocialPreview -Repo $Repo
if ($script:Failures.Count -or $after.Drift.Count) {
    Write-Host "`n$($script:Failures.Count) failure(s), $($after.Drift.Count) setting(s) still drifting." -ForegroundColor Red
    exit 1
}
Ok 'live settings match the file'
#endregion
