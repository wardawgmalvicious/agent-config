# Handoff: skill optimization pass (invocation control, model pins, listing budget)

- **Written**: 2026-08-31, immediately after the cap raise (`e49bc25`)
- **Kind**: policy + mechanical frontmatter pass. Policy decisions go to the
  user as a table BEFORE any edit; the edits themselves are small.
- **Status**: open brief — delete (or promote to `examples/`) once the pass
  lands, per the README convention.
- **Run in**: a fresh session. This brief is the context; nothing else from
  the authoring session is needed.

## Why

The user hit Max-plan weekly limits running Fable [1m] at high effort.
Usage-panel stats from the limit day: 50% of usage from subagent-heavy
sessions, 46% at >150k context, 24% from subagents labeled
`workflow-subagent`; skills: `/init` 8%, `/commit` 4%. Two stated goals:

1. Mechanical workflow skills should not run on the session's big model —
   `/commit` first ("would probably be fine with a lower model").
2. Leverage `when_to_use` where it is high-leverage for triggering.

And one repo-side problem found while scoping: the deployed listing is
over budget (numbers below), so long descriptions are probably already
being silently shortened in most sessions.

## Measured facts (2026-08-31, this repo)

- 44 skills; **36,830 total description chars (~9.2k tokens)**. Zero use
  `when_to_use`, `effort`, `disable-model-invocation`, or `context: fork`.
  Five workflow skills set `model: inherit` + `allowed-tools`; `commit` and
  `learn` have bare name+description frontmatter.
- Descriptions cluster just under the old 1,024 cap (27 of 44 are >800
  chars) — they were written to that cap.
- The seven workflow skills' descriptions total ~5,200 chars: commit 662,
  learn 737, code-review 266, drift-audit 990, drift-handoff 692,
  drift-update 894, author-skill 931.
- Skill-tool invocation log (`scripts/instructions-log skills`): commit 14,
  learn 5, pbir-filters 2, drift-audit 2, powerbi-report-design 1 — nothing
  else has ever fired through the Skill tool.
- `claude/agents/security-reviewer.md` has `model: inherit`, so scans run on
  whatever the session runs.
- `claude/settings.json` sets no `skillListing*` keys today.

## Upstream facts (verified 2026-08-31 against code.claude.com/docs/en/skills)

- **`model`** — turn-scoped override while the skill is active; session
  model resumes on the next prompt. Accepts `/model` values or `inherit`.
  With `context: fork` it sets the forked subagent's model instead.
  **`effort`** — same shape; low/medium/high/xhigh/max, model-dependent.
- **`disable-model-invocation: true`** — the docs' own example is
  `/commit`. Per the invocation table: "Description not in context, full
  skill loads when you invoke." So each skill it is set on leaves the
  listing entirely, in every session on the machine. It also blocks
  subagent preloading and scheduled-task prompt firing (v2.1.196+). If the
  model tries anyway, Claude Code blocks the call and tells it to suggest
  `/name` — so natural-language triggers in that skill's description stop
  working by design.
- **Listing budget** — the listing of names+descriptions has a character
  budget defaulting to **1% of the model's context window**. Overflow means
  descriptions are shortened, dropped starting with the least-invoked
  skills. Knobs: `skillListingBudgetFraction` (settings),
  `SLASH_COMMAND_TOOL_CHAR_BUDGET` (env, fixed chars), `skillOverrides`
  per-skill states (`on` / `name-only` / `user-invocable-only` / `off`).
  `/doctor` estimates the listing's cost and biggest contributors;
  `/context`'s Skills row shows the post-budget size the model receives.
- **`when_to_use`** — appended to `description` in the listing; counts
  toward the same 1,536 combined cap and the same aggregate budget. It is
  extra listing text, not free trigger signal.
- The per-skill 1,536 cap and the aggregate budget are independent limits;
  the repo linter gates only the first, and only on `description` alone.

## Decisions already made — do not relitigate

- `DESCRIPTION_MAX = 1536` (commit `e49bc25`, 2026-08-31).
- Tool-agnostic posture abandoned; Claude Code is the payload, Copilot
  reads `~/.claude` as-is. claude.ai-upload portability is not a constraint.
- The user types the pipeline skills as slash commands in practice.

## The work, in order

1. **Measure before touching anything.** `/doctor` (listing cost +
   contributors) and `/context` (Skills row) in the fresh session. Record
   the numbers in this brief. This settles whether truncation is live and
   how bad, and the budget's char-vs-token unit.
2. **Linter: measure the combined length.** `scripts/lint-frontmatter.py`
   checks `len(description)` alone; the upstream cap is
   `description + when_to_use` combined. Zero skills use `when_to_use`
   today, so the change breaks nothing — and it must land **before** any
   `when_to_use` adoption or the silent-truncation gap reopens. Keep the
   constant and root `CLAUDE.md`'s bullet in lockstep (the bullet already
   says "combined"; the linter is what lags).
3. **Draft the policy table and present it for approval.** Proposed
   starting point, one row per skill — the user decides each row:

   | skill | disable-model-invocation | model | rationale / open point |
   | --- | --- | --- | --- |
   | commit | proposed true | sonnet | Docs' own poster child. BUT its description advertises "commit this" / "make the commits" — those phrases stop auto-invoking under DMI; user must accept typing `/commit` (they already do). |
   | learn | proposed **false** | inherit | "learn!" as a spoken trigger is the documented interface; DMI would kill it. Judgment-heavy work — keep the session model. |
   | code-review | user call | inherit | Review quality is the point; don't cheapen. Check the bundled `/code-review` name collision while in there. |
   | drift-audit | true | inherit | Always typed; research quality matters, keep model. |
   | drift-handoff | true | sonnet | Mechanical brief-writing from existing findings. |
   | drift-update | true | user call | Executes briefs and edits guidance — some judgment; sonnet is defensible, inherit is safer. |
   | author-skill | true | inherit | Doc-drilling + writing quality. |
   | security-reviewer (agent, not skill) | n/a | user call | Scan work is grep-shaped; findings judgment isn't. `sonnet` plausible. |
   | platform skills (fabric/, powerbi/) | false — auto-trigger is their whole point | n/a | No DMI, no model pins. |

   Use model aliases (`sonnet`), not dated IDs.
4. **Apply the approved rows.** Frontmatter edits only; bodies untouched.
5. **Listing budget decision — SETTLED 2026-08-31: do not raise the
   fraction.** Measured in ACME via `--debug-file`: there is no listing
   overflow. The 19 skills previously believed dropped are the 19 carrying
   `paths:` frontmatter, withheld by design until a matching file enters
   scope. No budget warning is emitted; nothing is truncated on `opus[1m]`.
   See [skill-listing-field-evidence.md](skill-listing-field-evidence.md)
   for the full retraction and the replacement findings.

   What survives as real work: **trim the 25 unconditional descriptions**
   (~7,437 tokens of a ~9,900-token listing; the binding case is 200k-window
   sessions, where 1% = 2,000 tokens), and **reduce activation cost** for the
   conditional skills, whose overlapping globs load ~9.1k tokens of bodies
   from touching one `visual.json`. Consolidation is scoped to its own fresh
   session.
6. **`when_to_use` adoption — narrow, evidence-led.** Only for platform
   skills with demonstrated trigger misses (source:
   `scripts/instructions-log reasons|paths|skills` over time, and the
   user's experience). Given the budget pressure, moving trigger phrases
   from `description` into `when_to_use` is net-zero listing cost;
   *adding* text is not. Do not blanket-add to 44 skills.
7. **Root `CLAUDE.md` touch-up**: one or two sentences in Editing
   conventions — DMI removes a description from every session's listing;
   `model:` is turn-scoped — plus the linter's new combined measurement.
   Keep it lean.
8. **Validate** per root `CLAUDE.md`: lint all 44 skills + rules;
   `pre-commit run --all-files`; fresh-session checks — (a) run `/commit`
   and confirm the pinned model in the status line, (b) ask naturally for a
   DMI'd skill's work and expect the suggestion to run `/name` rather than
   silent execution, (c) `/doctor` before/after numbers recorded here.
   Trigger-relevant description edits: restart before trusting (in-place
   description hot-reload is the one unverified case). `tests/` untouched;
   `git status` clean; finish with `/commit`.

## Open questions to settle in-session

**Settled 2026-08-31** (see
[skill-listing-field-evidence.md](skill-listing-field-evidence.md)):

- *Does the invocation log capture user-typed `/slash` runs?* No — Skill-tool
  calls only. `skillUsage` in `~/.claude.json` counts both, and is the
  total-usage source: `commit` 54, `init` 14, `drift-update` 9, `learn` 8.
- *Budget unit — chars or tokens?* Tokens, at 1% of the model's context
  window. But the listing is not currently over budget, so the question is
  moot for `opus[1m]` and decisive only for 200k-window sessions.

Still open:

- **What is `workflow-subagent`?** 24% of the limit-day usage. Hypothesis:
  agents spawned by the Workflow tool (multi-agent runs), since no skill
  here uses `context: fork` and the repo's only custom agent is
  `security-reviewer`. If workflows are the driver, the fix is usage
  discipline / cheaper workflow agent models, not skill frontmatter.
- Whether `disable-model-invocation` on `commit` is worth it. The evidence
  cuts against the brief's assumption: of 23 observed invocations in the
  transcript scan, 15 were typed and **8 were the model choosing the skill**.
  DMI converts those 8 into "suggest `/commit`" turns for ~245 tokens of
  listing saved.

## What was already done in the authoring session (2026-08-31)

- `docs/handoff-briefs/templates/skill-handoff.md` synced to the current
  frontmatter reference: added `disallowed-tools`, `background`,
  `metadata` (+ a note on `license`/`compatibility`), corrected `model`
  (turn-scoped), `context: fork` (background by default), `allowed-tools`
  (permission grant, not restriction), `shell` (env var mostly obsolete),
  `name`/`description` (upstream-optional; repo-required), and the
  char-count guidance (1,536 repo default + aggregate budget caveat).
  The pass does not need to redo any template work.

## Constraints

- Fixtures under `tests/` are never modified; `docs/drift-audit/` is
  gitignored output.
- `claude/settings.json` deploys by copy — `-Force` relink after edits.
- Skills hot-reload through the junctions, but restart before trusting a
  changed *trigger* (description/frontmatter).
- Keep `DESCRIPTION_MAX` and root `CLAUDE.md`'s stated cap identical.
- `disable-model-invocation` on `learn` would break its spoken-trigger
  contract — that row defaults to false for a reason.
