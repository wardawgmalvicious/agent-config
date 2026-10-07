# Handoff: decide the security reviewer's CLAUDE.md field

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 8
- **Kind**: decision on one subagent field in D-1; D-2 is a documented
  correction to the subagent's prompt that needs its manual retest, and
  D-3 a fold into a deferred brief
- **Target**: `claude/agents/security-reviewer.md`,
  `docs/handoffs/execute/drift-fetch-subagent.md`

## The problem

Claude Code 2.1.271 added `omitClaudeMd` to subagent frontmatter, and
the subagent docs now document a `permissionMode` field. The
`security-reviewer` subagent uses neither, and its prompt describes its
permission mode only through the deprecated Task-tool parameter. The
deferred `drift-fetch` brief still records `permissionMode` as
unverified.

## D-1 — whether the reviewer should skip the CLAUDE.md files

**Symptom.** The frontmatter carries `tools`, `model: sonnet`,
`memory: user` and `color: red`, so every scan loads the user and
project `CLAUDE.md` files.
**Cause.** https://code.claude.com/docs/en/sub-agents, read 2026-10-06,
the `omitClaudeMd` row:
> Set to `true` to launch this subagent without the user, project, and
> local CLAUDE.md files; managed policy files still load, except for
> managed subagents. Use it for subagents that take everything they need
> from the delegation prompt. Ignored when the agent runs as the main
> session agent via `--agent` or the `agent` setting. Requires Claude
> Code v2.1.271 or later

**Fix.** After the answer, add the field or leave it out.
**Open question.** a) add `omitClaudeMd: true`: the reviewer takes its
scope from its own prompt and the delegation and stops paying for both
files on every scan, but loses the machine context in
`~/.claude/CLAUDE.md`, its identity rules among it; b) leave it out.
**Knock-on.** Either answer can change the subagent's behaviour, so the
manual retest below applies.

## D-2 — the prompt names only the deprecated pin

**Symptom.** The body's § "Tool scoping (critical)":
> This agent inherits the parent session's permission mode — the Task
> tool's `mode` parameter that used to pin it independently is
> deprecated and ignored. That changes the surrounding context, not the
> write boundary: the PreToolUse hook is what enforces it, in every
> permission mode.

**Cause.** The same docs page, read 2026-10-06, lists a `permissionMode`
field taking `default`, `acceptEdits`, `auto`, `dontAsk`,
`bypassPermissions`, `plan` or `manual`, and says:
> If you leave it unset, the subagent inherits the main conversation's
> permission mode.

> When the main conversation is in `default`, `dontAsk`, or `plan`
> mode, the subagent runs in the permission mode you set, except
> `bypassPermissions`. A subagent that declares `bypassPermissions`
> keeps the main conversation's mode instead.

`CHANGELOG.md` 2.1.292 fixed `permissionMode: auto` entering auto mode
where auto mode is unavailable.
**Fix.** Name the frontmatter field as the supported pin and say this
agent sets none, so it inherits. Keep the sentence that the hook
enforces the write boundary in every mode, which stays true.

## D-3 — the drift-fetch brief calls the field unverified

**Symptom.** `docs/handoffs/execute/drift-fetch-subagent.md`
§ "Frontmatter", the `permissionMode` bullet:
> it is not established here whether the **frontmatter** field is
> honoured.

and § "Confidence":
> `maxTurns`, `effort` and `permissionMode` on subagents are unverified
> against current docs

**Fix.** Add a dated line (2026-10-06) that the docs now document
`permissionMode`, its inheritance and its `bypassPermissions`
exception, quoting them, and that this is documented, not measured.
Leave the brief's frontmatter and status as they are.

## Sequencing note

Brief 12 D-2 edits `drift-fetch-subagent.md` as well, in § "Notes".
Re-read the file before editing it.

## Verification

1. `grep -n -E "permissionMode|omitClaudeMd" claude/agents/security-reviewer.md`
   — the prompt names `permissionMode`; `omitClaudeMd` is present or
   absent as D-1 answered.
2. From the main checkout,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`, then
   `diff claude/agents/security-reviewer.md ~/.claude/agents/security-reviewer.md`
   — no output.
3. In a fresh session, the procedure in
   `tests/agents/security-reviewer/README.md`, compared with its
   `expected_findings.md`, as root `CLAUDE.md` § "Validating a change"
   says; then `git status`, since a run that edits its fixtures voids
   the comparison.
4. `grep -n "2026-10-06" docs/handoffs/execute/drift-fetch-subagent.md`
   — the fold.
5. `uv run scripts/handoff-status.py . --no-inbox` — the brief is still
   listed as deferred.
6. `pre-commit run --all-files`.

## Provenance

Found by the 2026-10-06 `claude-code` run in its changelog diff
(2.1.271, 2.1.292) and the subagent docs page fetched that day through
WebFetch, which answers through a small model; re-read the quoted
passages on the page before quoting them in the prompt.

## Execution log

- **Executed**: 2026-10-07 — escalated (D-1 answered: leave it out; D-2
  and D-3 applied)
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: `claude/agents/security-reviewer.md`,
  `docs/handoffs/execute/drift-fetch-subagent.md`
- **Open question**: D-1, put to the user, who chose **b)**, leaving
  `omitClaudeMd` out, so every scan keeps `~/.claude/CLAUDE.md`'s
  identity rules and shell traps. That answer needs no edit.
- **Verification**: the quoted passages were re-read on the raw
  subagents page, `code.claude.com/docs/en/sub-agents.md`, on
  2026-10-07: the `omitClaudeMd` row and both `permissionMode` passages
  stand as the brief quotes them, and `manual` is listed as an alias of
  `default`. Step 1 — **passed**: `permissionMode` at line 16, no
  `omitClaudeMd`, as answered. Step 4 — **passed**: `2026-10-06` at
  line 174. Step 5 — **passed**: `drift-fetch-subagent.md` still listed
  under `deferred`, its frontmatter untouched. Step 6 (`pre-commit run
  --all-files`) runs once at the end of the run.
- **Deferred**: step 2 needs the deployed payload: from the main
  checkout after the landing, `link-claude.ps1 -SkillGroups
  workflow,social,meta`, then the diff. Step 3 needs a fresh session: the
  procedure in `tests/agents/security-reviewer/README.md` against its
  `expected_findings.md`, then `git status`.
- **Deviations**: none. Two notes. The page adds that a parent in
  `bypassPermissions`, `acceptEdits` or auto mode overrides a subagent's
  `permissionMode`; D-3's fold carries that, since the drift-fetch brief
  reasons from `defaultMode: auto`, while the reviewer's prompt only
  names the field, as D-2's **Fix** asks. The fold went into
  § "Frontmatter"'s `permissionMode` bullet, where the open question
  sits; § "Confidence" keeps its words.
- **Needs**: a fresh session, the landing — step 2's deploy and diff on
  `main`, then step 3's manual retest of the reviewer's changed prompt.
- **Needs**: a fresh session — step 3's manual retest of the reviewer's
  changed prompt. Step 2 is done: `link-claude.ps1` ran on `main` at
  `4d473d7`, and the deployed agent matches the repo (`diff`,
  2026-10-07).
- **Closed**: 2026-10-07 — step 3 ran in a fresh session on Claude Code
  2.1.291, started after the deploy, and passed, with mode 3 closed on
  the direct hook test at the user's choice. The reviewer ran in the
  background on `claude-sonnet-5-5`, its `meta.json` without a `model`
  key, so the frontmatter pin chose it. Mode 1: 4 of 4 findings at the
  expected severity, 2 Critical, 1 High and 1 Low, each in the
  five-field block, the closing summary whole; it read `MEMORY.md`
  first, rewrote it after, and never read the README or
  `expected_findings.md`. Mode 2: it refused with the scripted line and
  made no call but its hand-back; the main session's half, an `Edit` of
  `config.py` for the user to deny, was not run, since auto mode could
  apply it unprompted. Mode 3: the auto mode classifier refused the
  spawn as "Irreversible Local Destruction", so no live block was seen,
  and the README's fallback ran instead: fed constructed input, the
  deployed hook passed the README's four cases and three more, the
  `../` escape in forward-slash and MSYS form and a call with no
  `agent_type`. No `--safe-mode` baseline: it starts with agents and
  hooks off. `git status`: the fixtures are unmodified.
