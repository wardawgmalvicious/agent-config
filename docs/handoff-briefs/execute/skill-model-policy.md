# Handoff: skill invocation control and model policy (spend, not context)

- **Written**: 2026-08-31 as `skill-optimization-pass.md`. **Rewritten and
  renamed 2026-08-31**, stripped to the work that actually remains.
- **Kind**: policy pass. The decisions go to the user as a table **before** any
  edit; the edits themselves are small frontmatter changes.
- **Status**: open. One row applied (`commit` → `model: sonnet`, `56e00bc`);
  every other row untouched. The largest open item is a *diagnostic* question,
  not an edit — see "The unexplained 24%".
- **Run in**: a fresh session. This brief is self-contained.
- **Sibling brief**: [skill-context-cost.md](skill-context-cost.md) covers
  listing and activation **context** cost. Different subject. One shared edge:
  `disable-model-invocation` removes a skill's description from the listing
  entirely, so applying it is also a listing-cost change — if you set DMI on a
  skill, note it there.
- **Queue**: [README.md](README.md) has the execution order and what
  blocks what. This brief does not carry its own position.

## Why this exists

The user hit Max-plan weekly limits running Fable [1m] at high effort.
Usage-panel stats from the limit day:

| Share | Source |
| --- | --- |
| 50% | subagent-heavy sessions |
| 46% | sessions at >150k context |
| 24% | subagents labelled `workflow-subagent` |
| 8% / 4% | `/init` / `/commit` |

Two goals were stated: mechanical workflow skills should not run on the
session's big model, and invocation should be controlled where auto-triggering
adds no value.

**This is a spend problem, not a context problem.** Everything about listing
size, activation cost, `when_to_use`, and description trimming moved to
[skill-context-cost.md](skill-context-cost.md) — including this brief's former
steps 2, 5 and 6. Do not reopen them here.

## What was retracted from the original brief

The original carried a third motivation — *"the deployed listing is over
budget, so long descriptions are probably already being silently shortened"* —
which was **measured and disproved**. There is no overflow, and nothing is
truncated on `opus[1m]`. The skills believed dropped were path-conditional and
withheld by design.

Consequences: **do not raise `skillListingBudgetFraction`**, and do not justify
any edit in this brief with a truncation argument. Full correction is in
[skill-context-cost.md](skill-context-cost.md) under "How this brief's premises
were corrected".

## Upstream facts (verified 2026-08-31 against code.claude.com/docs/en/skills)

- **`model`** — turn-scoped override while the skill is active; the session
  model resumes on the next prompt. Accepts `/model` values or `inherit`. With
  `context: fork` it sets the forked subagent's model instead.
- **`effort`** — same shape: low / medium / high / xhigh / max, model-dependent.
  **No skill in this repo sets it.** It is the cheaper half of the spend lever
  and has never been tried — worth a row in the table below.
- **`disable-model-invocation: true`** — the docs' own example is `/commit`.
  Per the invocation table: *"Description not in context, full skill loads when
  you invoke."* So each skill it is set on **leaves the listing entirely, in
  every session on the machine**. It also blocks subagent preloading and
  scheduled-task prompt firing (v2.1.196+). If the model tries anyway, Claude
  Code blocks the call and tells it to suggest `/name` — so natural-language
  triggers in that skill's description stop working **by design**.

## Decisions already made — do not relitigate

- `DESCRIPTION_MAX = 1536` (commit `e49bc25`).
- Tool-agnostic posture abandoned; Claude Code is the payload, Copilot reads
  `~/.claude` as-is. claude.ai-upload portability is not a constraint.
- The user types the pipeline skills as slash commands in practice.
- `commit` is pinned to `model: sonnet` (`56e00bc`) and that stands.

## The work

### 1. Draft the policy table and present it for approval

One row per skill; **the user decides each row.** Proposed starting point:

| skill | DMI | model | effort | rationale / open point |
| --- | --- | --- | --- | --- |
| `commit` | **open** | sonnet ✅ | — | Docs' poster child for DMI, but the evidence cuts against it — see below. Model pin already applied. |
| `learn` | **false** | inherit | — | "learn!" as a spoken trigger is the documented interface; DMI would kill it. Judgment-heavy — keep the session model. |
| `code-review` | user call | inherit | — | Review quality is the point; don't cheapen. Check the bundled `/code-review` name collision while in there. |
| `drift-audit` | true | inherit | — | Always typed; research quality matters. |
| `drift-handoff` | true | sonnet | — | Mechanical brief-writing from existing findings. |
| `drift-update` | true | user call | — | Executes briefs and edits guidance — some judgment. sonnet defensible, inherit safer. |
| `author-skill` | true | inherit | — | Doc-drilling and writing quality. |
| `security-reviewer` (agent) | n/a | user call | — | Currently `model: inherit`, so scans run on whatever the session runs. Grep-shaped work; findings judgment is not. `sonnet` plausible. |
| platform skills (`fabric/`, `powerbi/`) | **false** | n/a | n/a | Auto-trigger is their whole point. No DMI, no model pins. |

Use model aliases (`sonnet`), not dated IDs.

**Consider `effort` before `model` on anything mechanical.** Dropping effort on
a skill that is essentially bookkeeping may capture most of the saving without
changing model at all, and it is the less disruptive of the two knobs. No row
above has been tried this way.

### 2. The `commit` DMI question — evidence, then decide

The original brief assumed `commit` was always typed. It isn't: of 23 observed
invocations in a transcript scan, **15 were typed and 8 were the model choosing
the skill.** `skillUsage` puts its lifetime total at 60, far ahead of anything
else in the repo.

DMI converts those 8 into "suggest `/commit`" turns, in exchange for ~245
tokens of listing. That is a real trade in both directions and needs the user's
call, not a default.

### 3. The unexplained 24% — diagnose before optimizing

**`workflow-subagent` accounted for 24% of limit-day usage and nobody knows
what it is.** Hypothesis: agents spawned by the Workflow tool, since no skill
here sets `context: fork` and the repo's only custom agent is
`security-reviewer`.

This is the single largest identified block of spend in the brief, and **none
of the frontmatter edits above touch it.** If workflows are the driver, the fix
is usage discipline or cheaper workflow-agent models — not skill frontmatter.
Settle this before assuming the table above is the answer; it may be worth more
than every other row combined.

### 4. Root `CLAUDE.md` touch-up

One or two sentences under Editing conventions: DMI removes a description from
every session's listing; `model:` is turn-scoped. Keep it lean — that file
loads in every session on the machine.

### 5. Validate

Per root `CLAUDE.md`:

- Lint every touched skill:
  `uv run --with pyyaml scripts/lint-frontmatter.py skills/<group>/<name>/SKILL.md`
- `pre-commit run --all-files`
- Fresh-session checks: **(a)** run `/commit` and confirm the pinned model
  appears in the status line; **(b)** ask naturally for a DMI'd skill's work and
  expect a suggestion to run `/name` rather than silent execution.
- Frontmatter is a *trigger* surface — **restart before trusting a changed
  trigger.** In-place description hot-reload is the one case unverified on this
  machine.
- `tests/` untouched; `git status` clean; finish with `/commit`.

## Unrelated open bug, carried forward so it is not lost

**`security-reviewer-memory-scope.sh` errors on every run** — 4 runs, 4
`hook_non_blocking_error`, 0 successes, per `scripts/instructions-log`. Nothing
to do with skills or models; it surfaced during the measurement work and had no
other home once the field-evidence brief was deleted. Fix it or file it, but
don't lose it again.

## Constraints

- `disable-model-invocation` on `learn` would break its spoken-trigger
  contract — that row defaults to false for a reason.
- `claude/settings.json` deploys by **copy**, not junction — re-run
  `scripts/link-claude.ps1 -Force` after editing it.
- Skills hot-reload through the junctions, but restart before trusting a
  changed trigger.
- Do not spend context-cost arguments here. If an edit is justified by listing
  size, it belongs in [skill-context-cost.md](skill-context-cost.md).
