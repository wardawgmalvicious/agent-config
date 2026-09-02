<#
.SYNOPSIS
    Real-path test for `paths:` activation — does Claude Code actually load
    the conditional skills and rules the globs say it should?

.DESCRIPTION
    The static check (scripts/activation-expect.py static) compares the
    frontmatter globs against tests/skills/<set>-triggers/expected_activations.md.
    It tests the globs. It does not test that the harness acts on them.

    This script does. It deploys the platform skills to a throwaway probe
    directory, opens one cold `claude -p` session there, has it Read every
    fixture, then asserts the activations recorded in the session transcript.

    THREE TRAPS, each of which reports "nothing loaded" — the same output a
    broken glob gives. All three are handled here; don't remove the handling:

    1. The platform skills are not deployed on this machine.
       ~/.claude/skills carries the workflow group only, so an undeployed
       probe finds no fabric/powerbi skill to activate. Guarded by asserting
       that the STARTUP listing carries the unconditional skills of both
       groups before any fixture is read.

    2. Reading the debug log instead of the transcript. `--debug-file` emits
       its skill lines before any Read runs, so it can never witness an
       activation. The assertion lives in the session transcript.

    3. The probe reads with `cat`. Activation is keyed to the Read TOOL, not
       to the file — Bash `cat` and Grep touch the same bytes and activate
       nothing. This machine defaults every session to auto mode, which
       prefers `cat`, and the model's choice is not deterministic. So the
       tools are pinned below AND a non-Read tool call is a hard failure,
       never a "no activation" result.

    Activation is a per-session cumulative DELTA — an attachment names only
    what was not already active, for rules as well as skills. Expectations
    are therefore computed against the read order actually observed, so
    expected_activations.md stays a plain per-file table.

    Both skill groups deploy for either fixture set. The pbip fixtures
    activate fabric-tmdl* on their .SemanticModel files, and the fabric
    set's headline negative assertion — that pbip-project-structure must NOT
    fire on SampleNB.Notebook/.platform — is vacuous unless that skill is
    present to fail.

    The probe directory is disposable and lives outside this repo. Teardown
    runs in a finally block: an interrupted run that left skill junctions
    behind would silently change what later sessions see, which is the same
    failure class as the 2026-08-31 bare link-claude.ps1 run that undid the
    user-scope prune.

.PARAMETER Set
    Which fixture set to test: pbip or fabric.

.PARAMETER StaticOnly
    Run the glob-vs-table check and stop. No session, no tokens, no deploy.

.PARAMETER ProbeRoot
    Disposable directory to build the probe in. Must be outside this repo.
    Defaults to a path under $env:TEMP. Deleted on exit unless -KeepProbe.

.PARAMETER Model
    Model for the probe session. Default opus[1m].

.PARAMETER KeepProbe
    Leave the probe directory in place for inspection. Skill junctions are
    still unlinked.

.EXAMPLE
    ./scripts/test-activation.ps1 -Set pbip
    ./scripts/test-activation.ps1 -Set fabric -StaticOnly
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('pbip', 'fabric')][string]$Set,
    [switch]$StaticOnly,
    [string]$ProbeRoot,
    [string]$Model = 'opus[1m]',
    [switch]$KeepProbe
)

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$expect = Join-Path $PSScriptRoot 'activation-expect.py'
$fixtureSrc = Join-Path $repo "tests/skills/$Set-triggers/fixtures"
$marker = '.activation-probe'

function Invoke-Expect {
    param([string[]]$Arguments)
    # Out-Host, not the pipeline: returning the child's stdout would make
    # the caller's exit-code variable an array of report lines.
    & uv run --with pyyaml --with wcmatch python $expect @Arguments | Out-Host
    return $LASTEXITCODE
}

# ---------------------------------------------------------------- static ---

Write-Host "== static: globs vs expected_activations.md ==" -ForegroundColor Cyan
$staticCode = Invoke-Expect @('static', '--set', $Set)
if ($staticCode -ne 0) {
    Write-Host "`nStatic check failed - the globs and the contract table disagree. Fix that before spending a session." -ForegroundColor Red
    exit $staticCode
}
if ($StaticOnly) { exit 0 }

# ----------------------------------------------------------------- guards ---

if (-not $ProbeRoot) {
    $ProbeRoot = Join-Path $env:TEMP "claude-activation-probe-$Set"
}
$probeParent = Split-Path -Parent $ProbeRoot
if (-not (Test-Path $probeParent)) {
    throw "ProbeRoot's parent does not exist: $probeParent"
}
$ProbeRoot = Join-Path (Resolve-Path $probeParent).Path (Split-Path -Leaf $ProbeRoot)

# Never deploy into user scope: ~/.claude/skills serves every session on
# this machine and carries a deliberate workflow-only prune.
$userClaude = Join-Path $HOME '.claude'
$probeClaude = Join-Path $ProbeRoot '.claude'
if ($probeClaude.TrimEnd('\', '/') -ieq $userClaude.TrimEnd('\', '/')) {
    throw "Refusing to run: the deploy target is user scope ($userClaude)."
}
if ($ProbeRoot -like "$repo*") {
    throw "Refusing to run: ProbeRoot is inside the repo ($ProbeRoot). " +
          "The probe creates and deletes a .claude directory; keep it out of here."
}
if ((Test-Path $ProbeRoot) -and -not (Test-Path (Join-Path $ProbeRoot $marker))) {
    throw "Refusing to reuse $ProbeRoot - it exists and carries no $marker " +
          "file, so it is not a probe directory this script created."
}

# ------------------------------------------------------------------ setup ---

try {
    if (Test-Path $ProbeRoot) { Remove-Item $ProbeRoot -Recurse -Force }
    New-Item -ItemType Directory -Path $ProbeRoot | Out-Null
    New-Item -ItemType File -Path (Join-Path $ProbeRoot $marker) | Out-Null
    Copy-Item $fixtureSrc (Join-Path $ProbeRoot 'fixtures') -Recurse

    Write-Host "`n== deploy: fabric + powerbi -> $probeClaude ==" -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'link-claude.ps1') `
        -ClaudeDir $probeClaude -SkillsOnly -SkillGroups fabric, powerbi | Out-Null
    $linked = @(Get-ChildItem (Join-Path $probeClaude 'skills') -Force).Count
    Write-Host "   $linked skills linked"

    # ------------------------------------------------------------- probe ---

    $files = & uv run --with pyyaml --with wcmatch python $expect files --set $Set
    $n = 0
    $list = ($files | ForEach-Object { $n++; "$n. fixtures/$_" }) -join "`n"
    # The "print done N" step is load-bearing, not chatter. Claude queues
    # activation attachments and flushes them in batches; a text block
    # between reads tends to force a flush per read, which is what gives
    # per-file resolution instead of per-group. See activation-expect.py.
    $prompt = @"
Read every one of the files listed below. Use the Read tool for each one —
this matters, do not use any other means of reading them. Do not skip any,
and do not summarise or comment on what they contain.

Work through them strictly one at a time: read a file, then print the line
"done N" for that file's number, and only then move on to the next. Never
read two files before printing the line for the first.

$list

When every file above has been read, reply with just: ok
"@
    $promptFile = Join-Path $ProbeRoot 'prompt.txt'
    Set-Content -Path $promptFile -Value $prompt -Encoding utf8

    Write-Host "`n== probe: one cold session, $($files.Count) fixtures ==" -ForegroundColor Cyan
    Push-Location $ProbeRoot
    try {
        $raw = & claude -p $prompt --model $Model --output-format json `
            --allowedTools Read `
            --disallowedTools Bash PowerShell Glob Grep Agent 2>$null
    } finally { Pop-Location }

    $json = $raw | Out-String | ConvertFrom-Json
    $sid = $json.session_id
    if (-not $sid) { throw "No session_id in the probe output; cannot locate a transcript." }
    Write-Host "   session $sid"

    $transcript = Get-ChildItem (Join-Path $userClaude 'projects') -Recurse `
        -Filter "$sid.jsonl" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $transcript) { throw "Transcript $sid.jsonl not found under $userClaude/projects." }

    # ------------------------------------------------------------- check ---

    Write-Host "`n== check: transcript vs globs ==" -ForegroundColor Cyan
    $code = Invoke-Expect @(
        'check', '--set', $Set,
        '--transcript', $transcript.FullName,
        '--fixtures-root', (Join-Path $ProbeRoot 'fixtures'))
    exit $code
}
finally {
    # Junctions must be unlinked individually. Remove-Item -Recurse over a
    # reparse point has historically deleted the TARGET's contents, which
    # here would be this repo's skills.
    if (Test-Path (Join-Path $probeClaude 'skills')) {
        Get-ChildItem (Join-Path $probeClaude 'skills') -Force |
            Where-Object { $_.LinkType } |
            ForEach-Object { [System.IO.Directory]::Delete($_.FullName, $false) }
    }
    if (Test-Path $probeClaude) { Remove-Item $probeClaude -Recurse -Force }
    if (-not $KeepProbe -and (Test-Path (Join-Path $ProbeRoot $marker))) {
        Remove-Item $ProbeRoot -Recurse -Force
        Write-Host "`n(probe torn down)" -ForegroundColor DarkGray
    } elseif ($KeepProbe) {
        Write-Host "`n(probe kept at $ProbeRoot; skill junctions removed)" -ForegroundColor DarkGray
    }
}
