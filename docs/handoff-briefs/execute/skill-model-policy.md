# Handoff: skill invocation control and model policy (spend, not context)

- **Written**: 2026-08-31 as `skill-optimization-pass.md`. **Rewritten and
  renamed 2026-08-31**, stripped to the work that actually remains.
- **Kind**: policy pass. The decisions go to the user as a table **before** any
  edit; the edits themselves are small frontmatter changes.
- **Status**: step 1 applied 2026-08-31. The frontmatter *shape* is now
  explicit on all 44 skills: `model`, `effort` and `disable-model-invocation`
  are written out rather than left to defaults, so the flip point for each is
  visible in the file. Live values: `commit` keeps `model: sonnet`
  (`56e00bc`) and pins `effort: high`; the six workflow skills pin
  `effort: max`, which matches the unchanged `max` session default and so
  acts as a floor. The 37 platform skills remain written-out defaults. The step 3 diagnostic is also answered:
  `workflow-subagent` is the Workflow tool, and it is a rare spike rather
  than a structural cost. Nothing in this brief is now blocking.
- **Run in**: a fresh session. This brief is self-contained.
- **Sibling brief**: [skill-context-cost.md](skill-context-cost.md) covers
  listing and activation **context** cost. Different subject. One shared edge:
  `disable-model-invocation` removes a skill's description from the listing
  entirely, so applying it is also a listing-cost change — if you set DMI on a
  skill, note it there.
- **Queue**: [README.md](README.md) has the execution order and what
  blocks what. This brief does not carry its own position.

## Why this exists

The user hit Max-plan weekly limits running Fable [1m] at **max** effort.
(An earlier revision of this brief said *high*; corrected 2026-08-31 by the
user. The difference matters: it is why pinning a mechanical skill to `high`
is a real reduction rather than a no-op.) Usage-panel stats from the limit
day:

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
- **`effort`** — low / medium / high / xhigh / max, model-dependent. **There
  is no `effort: inherit`** — the field has no pass-through value, and omitting
  it *is* the inherit ("Default: inherits from session"). An unsupported level
  degrades silently: "Claude Code falls back to the highest supported level at
  or below the one you set." Sonnet 5 and Opus 5 support all five. Since the
  shape pass, every skill carries a commented `# effort:` placeholder except
  `commit`, which sets `high`.
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

### 1. Policy table — DECIDED and applied 2026-08-31

The user's call was **shape first, values second**: write all three fields out
explicitly on every skill so the flip point is visible in the file, but leave
almost every value at its default.

| field | what landed | live? |
| --- | --- | --- |
| `disable-model-invocation` | `false` on all 44 skills | no — DMI is not used anywhere in this repo |
| `model` | `inherit` on 43; `sonnet` on `commit` (`56e00bc`) | only `commit` |
| `effort` | `max` on 6 workflow skills; `high` on `commit`; commented on 37 platform skills | only `commit` bites — session default stayed `max` |

`effort` is a placeholder rather than a written-out default because the field
has **no `inherit` value** — see Upstream facts. A commented line is the only
way to carry the shape without changing behaviour.

**Second pass, same day.** The six workflow skills that drive this repo pin
`effort: max`: `code-review`, `drift-audit`, `author-skill`, `learn`,
`drift-update`, `drift-handoff`. `commit` stays `high`.

The session default was dropped to `xhigh` and then **reverted to `max`** the
same day, so platform skills keep inheriting `max`. Net effect as it stands:
only `commit` actually changes behaviour, and the six `max` pins are a stated
floor rather than a live change — they take effect if the session default
ever drops. Recorded because a later reader will otherwise measure no
difference and conclude the pins do nothing.

The user first asked for `ultracode` on four of those. **There is no such
effort value** — the docs state it "is not a distinct level and reports as
`xhigh`", i.e. *below* `max`. It is a session orchestration mode with no
per-skill frontmatter field, so all six collapsed onto `max`.

The 37 platform skills stay unpinned deliberately. Their effort would govern
the surrounding Fabric/Power BI turn, not a discrete skill run, so pinning
them either direction moves the wrong thing. `drift-handoff` was pinned `max`
against a `medium` recommendation — the user's call, recorded so the next
pass does not silently "fix" it.

Still open from the original table: the **`security-reviewer` agent**, which
remains `model: inherit`. Agents take `model`, and the shape pass deliberately
did not touch `claude/agents/`.

### 2. The `commit` DMI question — CLOSED, answered "no"

The evidence, kept because it is the reason the docs' own recommendation was
rejected: of 23 observed invocations in a transcript scan, **15 were typed and
8 were the model choosing the skill.** `skillUsage` puts its lifetime total at
60, far ahead of anything else in the repo.

Setting DMI would have converted those 8 into "suggest `/commit`" turns to save
~245 tokens of listing. Declined — the auto-trigger is worth more than the
listing. `disable-model-invocation: false` is now written out on `commit` (and
everywhere else) so this decision is legible in the file rather than implied by
an absent field.

### 3. The unexplained 24% — ANSWERED 2026-08-31

`workflow-subagent` is the **Workflow tool's fan-out agents**. The hypothesis
in the original brief was right. Proof, not inference: every such transcript
sits at
`~/.claude/projects/<proj>/<session>/subagents/workflows/wf_<id>/agent-<id>.jsonl`
beside a `.meta.json` reading exactly
`{"agentType":"workflow-subagent","spawnDepth":1}` — the panel label is that
field verbatim.

**But it is not a recurring cost, and not the structural driver.** Three runs,
ever, all on `claude-fable-5`:

| date | workflow | agents | project |
| --- | --- | --- | --- |
| 2026-08-03 | `edgebridge-dependency-assessment` | 4 | fabric-acme |
| 2026-08-28 | `per-tool-restructure-assessment` | 7 | agent-config |
| 2026-08-28 | `verify-blite-and-codex-migration` | 3 | agent-config |

Across 33 days with recorded usage, workflows appear on **two**. Every other
day is 0% — including the two heaviest days in the window, 2026-08-29 and
2026-08-31, which are entirely main-session.

Share, cost-weighted (input 1x, cache-write 1.25x, cache-read 0.1x, output 5x):

- workflow agents as a share of **2026-08-28**: **14.9%**
- the whole session that ran them, week-to-date through 08-28: **17.2%**
- workflow agents as a share of the **full week** 08-25..08-31: **2.8%**

None is exactly 24%. The panel's weighting is not published, so treat 24% as
the same phenomenon measured differently rather than a fourth figure to
reconcile — the identification does not depend on the arithmetic.

**So the brief's framing was half right.** Correct that no frontmatter edit
touches this. *Incorrect* that it is "the single largest identified block of
spend": workflows are a rare spike, and ordinary main-session work is 100% of
spend on 31 of 33 days. The lever that matters is this brief's *other* stat
— sessions at >150k context running at **max** effort — which belongs to
[skill-context-cost.md](skill-context-cost.md), not here.

If a workflow is run again, the cheap fix is a per-agent model in the script
(`agent(prompt, {model: 'sonnet'})`). The 08-28 run fanned **7 agents over one
identical scoring prompt** on fable-5, which is the pattern worth pricing
before repeating.

### 4. Root `CLAUDE.md` touch-up — DONE 2026-08-31

Added as a **Skill invocation and spend fields** bullet under Editing
conventions: the shape and current policy, plus the three facts worth knowing
before changing one — `model:` is turn-scoped, `effort:` has no `inherit`
and degrades silently, and DMI removes a description from every session's
listing. (Note the original instruction's reasoning was off: root `CLAUDE.md`
is *project* scope and loads only in this repo. `claude/CLAUDE.md` is the one
that loads in every session on the machine, and it was not touched.)

### 5. Validate

Per root `CLAUDE.md`:

- Lint every touched skill:
  `uv run --with pyyaml scripts/lint-frontmatter.py skills/<group>/<name>/SKILL.md`
- `pre-commit run --all-files`
- Fresh-session checks: **(a)** run `/commit` and confirm the pinned model
  *and* `effort: high` take hold; **(b)** confirm a natural-language commit
  request still auto-triggers the skill — it must, since DMI is `false`
  everywhere. The original **(b)** tested for a DMI'd skill; none exists, so
  the check is inverted rather than dropped.
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
