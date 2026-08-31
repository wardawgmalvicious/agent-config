# Handoff: skill listing field evidence — CORRECTED

- **Written**: 2026-08-31. **Corrected 2026-08-31** in a later session, from a
  `--debug-file` capture in `C:\Repos\ACME\fabric-acme`.
- **Kind**: measurement input. No edits proposed beyond the one glob fix
  already applied (below).
- **Status**: the original brief's central finding was a **misdiagnosis** and is
  retracted here. What replaces it is actionable, but points at a different
  problem than the one the brief named.

## Retraction: there was never a listing-budget outage

The original brief reported **19 skills "absent from the listing — not
shortened, absent entirely, name and description both"**, attributed the
absence to aggregate listing-budget overflow, and recommended raising
`skillListingBudgetFraction` from 1% to 1.5% as the fix.

That is wrong. From `claude -p ... --debug-file` in the ACME repo,
Claude Code 2.1.252:

```text
[skills] 19 conditional skills stored (activated when matching files are touched)
Loaded 44 unique skills (25 unconditional, 19 conditional, user: 7, project: 37)
getSkills returning: 25 skill dir commands, 0 plugin skills, 42 bundled skills
Sending 41 skills via attachment (initial)
```

Exactly 19 skills in this repo carry `paths:` frontmatter, and they are a
**name-for-name match** with the brief's "dropped" list. They were withheld
because they are path-conditional and no matching file had entered session
scope — the documented third trigger mode, described in root `CLAUDE.md`.
41 sent = 25 unconditional + 16 bundled: nothing was omitted, nothing was
shortened.

**No budget-overflow warning appears anywhere in the debug log.** Upstream
docs state one is written whenever the listing exceeds its budget.

This resolves every anomaly the original brief could not explain:

| Original anomaly | Actual cause |
| --- | --- |
| "Drop order does NOT follow lifetime invocation count" | Not a drop order. The conditional/unconditional split is orthogonal to usage. |
| `fabric-copy-job` (0 uses) kept, `fabric-eventstream` (4 uses) dropped | `fabric-copy-job` has no `paths:`; `fabric-eventstream` does. |
| Not explained by description length or alphabet | Correct — it splits by `paths:`. |
| Docs say "the listing always contains every skill name" | No contradiction. The docs were right. |

The brief reached "that leaves the aggregate listing budget as the only
remaining explanation" without ever checking `paths:`. Its ruled-out list
covered `disable-model-invocation`, `allowed-tools`, frontmatter parsing,
name/directory agreement and junction readability — but not the one field that
actually governs conditional loading.

**Consequence: do not raise `skillListingBudgetFraction`.** There is no
overflow to fix, and raising it would spend context on a non-problem.
`skillOverrides: name-only` on the domain skills is likewise unnecessary as an
emergency measure.

Also note the original arithmetic double-counted: the 19 conditional skills
were included in the "all 44 want ~13k tokens" figure, but they cost **zero**
listing tokens until activated.

## What the listing actually costs

Real pressure comes only from the **25 unconditional** skills:

| Source | Skills | Tokens |
| --- | --- | --- |
| Unconditional repo skills | 25 | ~7,437 (20,080 desc chars @ 2.7 c/tok) |
| Bundled | 16 | ~2,460 |
| Plugins (disabled in `c7d4e30`) | 0 | 0 |
| **Total** | **41** | **~9,900** |

Against a 10,000-token budget on `opus[1m]`. Not truncated — but the headroom
is roughly one skill wide, and an activating conditional skill adds its
description to that listing.

The `/context` reading of "Skills 10k 1.0%" in the original brief was read as
proof of saturation. It is not: ~9.9k is simply what these 41 entries cost.

**The budget does bind on smaller windows.** The fraction is 1% of the
*model's* context window, so a 200k-window session gets 2,000 tokens against
~9,900 wanted. Those sessions are badly truncated, and raising the fraction to
1.5% or 2% would not come close to fixing them. Trimming descriptions is the
only lever that helps there.

## Glob audit: the 19 conditional skills against ACME

Tested with `wcmatch` (GLOBSTAR) against all 295 tracked files in
`C:\Repos\ACME\fabric-acme`. **14 of 19 activate; 5 do not, and all 5 are correct
misses** — ACME contains no `.DataAgent`, `.SQLDatabase` or `.GraphModel` items,
no `definition/cultures/*.tmdl`, and no bookmark files.

No broken globs among the misses. The original brief's complaint that "the
skills this repo exists to use" are unavailable does not hold:
`fabric-eventstream` (24 files), `fabric-warehouse` (45),
`fabric-variable-library` (7), `fabric-eventhouse` (10) and
`fabric-realtime-dashboard` (2) all activate correctly.

### One real bug, fixed

`fabric-tmdl` carried a third pattern `**/definition/**`, which matched **84
Power BI report JSON files** (`page.json`, `visual.json`) out of 107 total
matches — a semantic-model skill loading on every report-authoring session.
The other two patterns already cover all 23 genuine matches. The pattern was
removed; re-tested at 23 matches, zero false positives.

## The real finding: activation cost, not listing cost

Conditional skills are free in the listing and expensive on activation, and
their globs overlap, so they fire in clusters:

| Cluster | Trigger | Bodies loaded |
| --- | --- | --- |
| `pbip-project-structure` + `pbir-visual-json` + `pbir-conditional-formatting` + `pbir-filters` | one `visual.json` | **~11,922 tokens** |
| `fabric-spark` + `fabric-error-handling` | identical `**/*.Notebook/**` globs | ~4,418 tokens |
| `fabric-tmdl` + `pbip-project-structure` | any `.SemanticModel/` file | ~5,596 tokens |

Touching a single report visual in ACME loads **~11,922 tokens** of skill
bodies — more than the entire listing budget, from opening one file. Before
the `fabric-tmdl` glob fix it was ~14,682 across five skills.

The dominant term is `pbip-project-structure`, which matches **148 of 295**
tracked files (its globs include `**/*.Report/**` and `**/*.SemanticModel/**`)
and so co-activates with nearly everything — a ~2,837-token body on half of
all file touches in the repo.

`fabric-spark` and `fabric-error-handling` have **identical** `paths:` globs
and can never fire independently.

## Open item for a fresh session: consolidation

The evidence above argues for consolidating overlapping platform skills and
pushing detail into `references/` — merging clusters that always co-activate,
so one skill body loads instead of three. Note the two levers are aimed at
different costs:

- **Trimming descriptions** reduces *listing* cost — helps the 25 unconditional
  skills, and matters most on 200k-window sessions.
- **Consolidating bodies / using `references/`** reduces *activation* cost —
  helps the 19 conditional ones, which contribute nothing to the listing.

A third, cheaper lever for an unconditional skill: adding a `paths:` glob costs
no rewrite and removes it from the listing entirely.

Scope that work in a fresh session with its own brief.

## Reproducing this (better than `/doctor`)

`claude doctor` on the CLI is installation health only — it does not report
listing cost. The listing internals come from a one-turn print session:

```bash
cd <repo> && claude -p "Reply with exactly: ok" --model opus[1m] \
  --debug-file /path/to/dbg.log
grep -iE "conditional|unique skills|getSkills|via attachment" /path/to/dbg.log
```

Pin the same model you normally run: the budget is a fraction of *that model's*
context window, so measuring on a different model changes the numbers.

## Still standing from the original brief

- **The invocation log counts Skill-tool calls only.** `skillUsage` in
  `~/.claude.json` counts both slash and tool invocations. Confirmed:
  `commit` 54, `init` 14, `drift-update` 9, `learn` 8, `drift-audit` 5.
- **`security-reviewer-memory-scope.sh` errors on every run** — 4 runs, 4
  `hook_non_blocking_error`, 0 successes. Unrelated to skills; still open.
- The four unused plugins were disabled in `c7d4e30`, returning ~720 listing
  tokens and ~1.2k of agent context.
