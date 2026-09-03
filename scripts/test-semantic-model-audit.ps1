<#
.SYNOPSIS
    Behaviour test for `fabric-semantic-model-audit` against the planning-model
    fixture -- does the planning-model carve-out actually hold?

.DESCRIPTION
    The sibling script test-activation.ps1 answers "does a `paths:` glob load
    the skill". This one answers a different question for a skill that has no
    glob at all: given the skill IS loaded, does it produce the right findings?

    Assertions live in tests/skills/fabric-semantic-model-audit/expected_findings.md.
    This script does not evaluate them -- it produces the three runs that file
    compares, reproducibly and without touching user scope. Reading the output
    against that file is a human step, deliberately.

    THREE RUNS, and the third is the one that matters:

      shipped     the skill as committed. Must stand down on the snowflake
                  (criterion 2) while still reporting auto date/time and the
                  dead IsValid measures (criterion 4).

      baseline    `claude --safe-mode`, whole payload off. This is the control
                  for "does the skill add anything", NOT for the carve-out:
                  the base model runs no checklist, never applies the
                  both-sides test, and so never reaches check 1 at all. It
                  passes criterion 2 by not asking the question. Measured
                  2026-09-03 -- do not read that pass as the carve-out being
                  worthless.

      nocarveout  the skill with the carve-out surgically removed. THIS is the
                  discriminating control. On 2026-09-03 it flagged the
                  snowflake and prescribed collapsing it, which is what earns
                  the carve-out its place in the skill.

    Two traps, both of which produce a spurious "criterion 2 passed":

    1. The skill never loads. fabric-semantic-model-audit is pruned from
       ~/.claude/skills and is unconditional, so it cannot be reached by path
       either -- an undeployed run simply audits the model off general
       knowledge and, like the baseline, never fires check 1. Guarded by
       asserting a Skill tool_use for the skill in the transcript of every
       run that expects one, and its ABSENCE in the baseline.

    2. The strip is incomplete. Removing section 3's bullet while leaving
       section 9's reference to it makes the build self-contradictory: the
       first attempt did exactly that, and the run noticed section 9 promised
       an exemption it could not read, then hedged its check-1 finding on
       those grounds. It still flagged -- so the result held a fortiori -- but
       the confound pushes toward standing down. Both references are stripped
       here and the residual count is asserted to be zero.

    DEPLOYMENT IS PROJECT-SCOPED, ON PURPOSE. The obvious route --
    `link-claude.ps1 -SkillGroups workflow,fabric -Force` -- pushes 29 skills
    into ~/.claude/skills, visible to every session on this machine until a
    restoring run happens; a forgotten restore is the 2026-08-31 failure.
    None of it is needed: project scope only ADDS names user scope lacks, and
    this skill is exactly such a name. `-SkillGroups` does not prune user
    scope when `-ClaudeDir` is given, so there is nothing to restore. The
    user-scope skill list is captured before and compared after regardless,
    and a difference is a hard failure.

.PARAMETER Mode
    Which run(s) to perform: shipped, baseline, nocarveout, or all (default).

.PARAMETER OutDir
    Where to write each run's result and transcript. Defaults to a timestamped
    directory under $env:TEMP. These are working notes, not repo artifacts.

.PARAMETER ProbeRoot
    Disposable directory to build probes in. Must be outside this repo.
    Deleted on exit unless -KeepProbe.

.PARAMETER Model
    Model for the probe sessions. Default opus[1m].

.PARAMETER KeepProbe
    Leave the probe directory in place. Skill junctions are still unlinked.

.EXAMPLE
    ./scripts/test-semantic-model-audit.ps1
    ./scripts/test-semantic-model-audit.ps1 -Mode nocarveout
#>
[CmdletBinding()]
param(
    [ValidateSet('shipped', 'baseline', 'nocarveout', 'all')][string]$Mode = 'all',
    [string]$OutDir,
    [string]$ProbeRoot,
    [string]$Model = 'opus[1m]',
    [switch]$KeepProbe
)

$ErrorActionPreference = 'Stop'

$repo       = Split-Path -Parent $PSScriptRoot
$skillName  = 'fabric-semantic-model-audit'
$fixtureSrc = Join-Path $repo "tests/skills/$skillName/fixtures"
$skillSrc   = Join-Path $repo "skills/fabric/$skillName"
$marker     = '.audit-probe'

# The prompt must NOT mention planning, snowflakes, or the carve-out. Naming
# any of them hands the model the answer and the run stops testing anything.
$prompt = 'Audit the semantic model at fixtures/semantic-modeling-sample.SemanticModel and report what you find.'

if (-not (Test-Path $fixtureSrc)) { throw "Fixture not found: $fixtureSrc" }
if (-not (Test-Path $skillSrc))   { throw "Skill not found: $skillSrc" }

if (-not $OutDir) {
    $OutDir = Join-Path $env:TEMP "semantic-model-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$userClaude = Join-Path $HOME '.claude'
$userBefore = @(Get-ChildItem (Join-Path $userClaude 'skills') -Force |
                Select-Object -ExpandProperty Name | Sort-Object)

$modes = if ($Mode -eq 'all') { @('shipped', 'baseline', 'nocarveout') } else { @($Mode) }
$results = @()

function Invoke-ProbeTeardown {
    param([string]$Root, [string]$ClaudeDir, [bool]$Keep)
    # Junctions must be deleted individually. Remove-Item -Recurse across a
    # reparse point has historically deleted the TARGET's contents, which here
    # would be this repo's skills/.
    if (Test-Path (Join-Path $ClaudeDir 'skills')) {
        Get-ChildItem (Join-Path $ClaudeDir 'skills') -Force |
            Where-Object { $_.LinkType } |
            ForEach-Object { [System.IO.Directory]::Delete($_.FullName, $false) }
    }
    if (Test-Path $ClaudeDir) { Remove-Item $ClaudeDir -Recurse -Force }
    if (-not $Keep -and (Test-Path (Join-Path $Root $marker))) {
        Remove-Item $Root -Recurse -Force
    }
}

function Invoke-BlockStrip {
    # Delete the lines from the one matching $From up to the line before the
    # one matching $To, and write the file back.
    param([string]$Path, [string]$From, [string]$To)
    $lines = Get-Content $Path
    $a = ($lines | Select-String -SimpleMatch $From | Select-Object -First 1).LineNumber
    $b = ($lines | Select-String -SimpleMatch $To   | Select-Object -First 1).LineNumber
    if (-not $a -or -not $b) { throw "Anchor not found in $Path ('$From' / '$To')." }
    $start = $a - 1
    $end   = $b - 2
    if ($end -le $start) { throw "Anchors out of order in $Path ($start..$end)." }
    $kept = @()
    if ($start -gt 0) { $kept += $lines[0..($start - 1)] }
    $kept += $lines[($end + 1)..($lines.Count - 1)]
    Set-Content -Path $Path -Value $kept -Encoding utf8
    return "$($start + 1)..$($end + 1)"
}

foreach ($m in $modes) {

    $root = if ($ProbeRoot) { "$ProbeRoot-$m" } else { Join-Path $env:TEMP "claude-audit-probe-$m" }
    $probeParent = Split-Path -Parent $root
    if (-not (Test-Path $probeParent)) { throw "ProbeRoot's parent does not exist: $probeParent" }
    $root = Join-Path (Resolve-Path $probeParent).Path (Split-Path -Leaf $root)
    $probeClaude = Join-Path $root '.claude'

    # Never deploy into user scope, and never build inside the repo -- the
    # probe creates and deletes a .claude directory.
    if ($probeClaude.TrimEnd('\', '/') -ieq $userClaude.TrimEnd('\', '/')) {
        throw "Refusing to run: the deploy target is user scope ($userClaude)."
    }
    if ($root -like "$repo*") {
        throw "Refusing to run: ProbeRoot is inside the repo ($root)."
    }
    if ((Test-Path $root) -and -not (Test-Path (Join-Path $root $marker))) {
        throw "Refusing to reuse $root - it exists and carries no $marker file."
    }

    Write-Host "`n=== $m ===" -ForegroundColor Cyan
    try {
        if (Test-Path $root) { Remove-Item $root -Recurse -Force }
        New-Item -ItemType Directory -Path $root | Out-Null
        New-Item -ItemType File -Path (Join-Path $root $marker) | Out-Null
        Copy-Item $fixtureSrc (Join-Path $root 'fixtures') -Recurse

        if ($m -ne 'baseline') {
            & (Join-Path $PSScriptRoot 'link-claude.ps1') `
                -ClaudeDir $probeClaude -SkillsOnly -SkillGroups fabric | Out-Null
            $target = Join-Path $probeClaude "skills/$skillName"
            if (-not (Test-Path $target)) { throw "$skillName did not deploy; the probe would test nothing." }
            Write-Host "  deployed project-scoped: $(@(Get-ChildItem (Join-Path $probeClaude 'skills') -Force).Count) skills"
        }

        if ($m -eq 'nocarveout') {
            # Replace the junction with a real copy we can edit.
            if ((Get-Item $target -Force).LinkType) { [System.IO.Directory]::Delete($target, $false) }
            Copy-Item $skillSrc $target -Recurse

            $sk = Join-Path $target 'SKILL.md'
            $r1 = Invoke-BlockStrip -Path $sk -From '- **Planning models**' -To 'Carry the hedge'
            $r2 = Invoke-BlockStrip -Path $sk -From 'The planning-model carve-out in' -To 'The notebook tier is documented'
            Write-Host "  stripped SKILL.md lines $r1 (section 3) and $r2 (section 9)" -ForegroundColor Yellow

            # The point-of-use pointer in check 1's remediation. \S+3 stands in
            # for the section sign so this file needs no non-ASCII literal.
            $ref = Join-Path $target 'references/REFERENCE.md'
            $raw = Get-Content $ref -Raw
            $new = $raw -replace ' \S+ \*\*but not in a planning model\*\*, see SKILL\.md \S+3', ''
            if ($raw -eq $new) { throw "REFERENCE.md check-1 pointer not matched - the wording changed; update this pattern." }
            Set-Content -Path $ref -Value $new -Encoding utf8 -NoNewline
            Write-Host "  removed REFERENCE.md check-1 pointer" -ForegroundColor Yellow

            $residual = @(Select-String -Path $sk -Pattern 'Planning models|planning grid|planning-model carve-out').Count
            if ($residual -ne 0) { throw "$residual carve-out mention(s) survive in SKILL.md; the strip is incomplete." }
            Write-Host "  residual carve-out mentions: 0" -ForegroundColor Yellow
        }

        Push-Location $root
        try {
            # Not $args -- that is an automatic variable in script scope.
            $claudeArgs = @('-p', $prompt, '--model', $Model, '--output-format', 'json',
                            '--disallowedTools', 'Write', 'Edit', 'NotebookEdit')
            if ($m -eq 'baseline') { $claudeArgs += '--safe-mode' }
            $out = & claude @claudeArgs 2>$null
        } finally { Pop-Location }

        $json = $out | Out-String | ConvertFrom-Json
        $sid  = $json.session_id
        if (-not $sid) { throw "No session_id returned; cannot locate a transcript." }

        Set-Content -Path (Join-Path $OutDir "audit-$m.md") -Value $json.result -Encoding utf8

        $t = Get-ChildItem (Join-Path $userClaude 'projects') -Recurse `
             -Filter "$sid.jsonl" -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $t) { throw "Transcript $sid.jsonl not found; cannot assert skill invocation." }
        Copy-Item $t.FullName (Join-Path $OutDir "transcript-$m.jsonl")

        # Trap 1: a run where the skill never loaded passes criterion 2 for the
        # wrong reason. Assert invocation directly rather than inferring it.
        $invoked = (Select-String -Path $t.FullName -Pattern "`"skill`":`"$skillName`"" -SimpleMatch -Quiet) -eq $true
        if ($m -eq 'baseline') {
            if ($invoked) { throw "baseline invoked $skillName - --safe-mode did not disable the payload." }
            Write-Host "  skill invoked: no (correct for baseline)" -ForegroundColor Green
        } else {
            if (-not $invoked) { throw "$skillName was never invoked; this run tests nothing." }
            Write-Host "  skill invoked: yes" -ForegroundColor Green
        }

        Write-Host ("  session {0}  cost `${1:N2}  turns {2}" -f $sid, $json.total_cost_usd, $json.num_turns)
        $results += [pscustomobject]@{
            Run = $m; Cost = $json.total_cost_usd; Invoked = $invoked
            Result = (Join-Path $OutDir "audit-$m.md")
        }
    }
    finally { Invoke-ProbeTeardown -Root $root -ClaudeDir $probeClaude -Keep $KeepProbe }
}

# --------------------------------------------------------------- summary ---

$userAfter = @(Get-ChildItem (Join-Path $userClaude 'skills') -Force |
               Select-Object -ExpandProperty Name | Sort-Object)
if (Compare-Object $userBefore $userAfter) {
    Write-Host "`nUSER SCOPE CHANGED - the workflow-only prune may be broken." -ForegroundColor Red
    Compare-Object $userBefore $userAfter | Format-Table | Out-Host
    exit 1
}
Write-Host "`nuser scope unchanged: $($userAfter.Count) skills" -ForegroundColor DarkGray

Write-Host "`n== results ==" -ForegroundColor Cyan
$results | Format-Table Run, Cost, Invoked -AutoSize | Out-Host
Write-Host "written to $OutDir"

# A hint, not a verdict. Grepping for "collapse" alone is unreliable -- the
# word turns up in unrelated DAX prose ("the window comparisons collapse") --
# so this requires a snowflake keyword too, and still only tells you where to
# look. The judgement is reading each file against expected_findings.md.
Write-Host "`n== heuristic: snowflake remediation mentioned? (NOT a verdict) ==" -ForegroundColor Cyan
foreach ($r in $results) {
    $body = Get-Content $r.Result -Raw
    $hit = ($body -match '(?i)snowflak') -and ($body -match '(?i)collaps|flatten|denormali')
    Write-Host ("  {0,-11} {1}" -f $r.Run, $(if ($hit) { 'yes - read it' } else { 'no' }))
}
Write-Host "`nCompare each against tests/skills/$skillName/expected_findings.md." -ForegroundColor DarkGray
