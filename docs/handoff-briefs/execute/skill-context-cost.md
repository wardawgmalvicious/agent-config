# Handoff: reduce skill context cost (glob hygiene, body slimming, merges, listing cleanup)

- **Written**: 2026-08-31. **Updated and consolidated 2026-08-31** after
  executing A and B.
- **Kind**: policy + content pass. Workstreams are ordered by risk, cheapest and
  safest first. **Workstream C changes skill names**; **Workstream E adds globs
  to, or relocates, unconditional skills**. Neither should start before A and B
  land — both now have.
- **Status**: **A and B are complete.** C, D and E are open. D (`when_to_use`)
  and E (is the skill necessary at all? — scoped to the **unconditional**
  skills) were added on the update and have not been started. **D gained a
  split-cap proposal on 2026-09-01** — three candidate splits, a
  recommendation, and the corpus measurement behind it. It needs a decision,
  not more research; the linter change follows from whichever split is chosen.
- **Run in**: a fresh session. **This brief is self-contained** — it is the only
  document needed for the context-cost work.
- **Sibling brief**: `skill-model-policy.md` covered
  `disable-model-invocation`, model pins, and per-session *spend*. **Retired
  2026-09-01**; recover it from git history by the recipe below. Its one edge on
  this brief is now settled rather than pending: DMI removes a skill's
  description from the listing, so it *would* be a listing-cost lever, but it
  was declined repo-wide and is `false` on all 44 skills. Nothing to re-measure
  here unless that decision is reopened.
- **Queue**: [README.md](README.md) has the execution order and what
  blocks what. This brief does not carry its own position.

## Provenance — read if a claim here looks unsupported

This brief absorbed two predecessors on 2026-08-31, both now deleted per the
[brief lifecycle](../README.md):

- `skill-listing-field-evidence.md` — the measurement record. Its live findings
  are folded in below; its central content was a **retraction**, summarized in
  "How this brief's premises were corrected".
- The listing-cost half of `skill-optimization-pass.md` (its steps 2, 5 and 6),
  now Workstreams D and E. What remained of that brief became
  `skill-model-policy.md`, which was itself executed and retired on
  2026-09-01 — its two unfinished items live on as wave 8 of the queue.

Recover either in full from git history:

```bash
git log --diff-filter=D -- 'docs/handoff-briefs/execute/skill-listing-field-evidence.md'
git show <sha>^:docs/handoff-briefs/execute/skill-listing-field-evidence.md
```

## How this brief's premises were corrected

Worth 60 seconds before trusting any measurement here, because the same error
class has now recurred twice.

An earlier pass reported "19 skills absent from the listing", blamed aggregate
listing-budget overflow, and recommended raising `skillListingBudgetFraction`.
It was wrong. Those 19 are exactly the skills carrying `paths:` frontmatter —
withheld by design until a matching file enters scope, which is the documented
third trigger mode. Nothing was truncated; no budget warning was ever emitted.
The pass reached "the aggregate budget is the only remaining explanation"
having never checked `paths:`.

The lesson that keeps mattering: **absence from a listing, or a zero in a usage
counter, is not evidence of a problem — conditional skills are withheld and
loaded rather than listed and invoked.** That premise leaked into a third brief
before it was caught. Workstream E restates it as the `skillUsage` trap.

**Consequences that still stand: do not raise `skillListingBudgetFraction`**
(there is no overflow to fix), and the ~9,900-token listing figure is simply
what 41 entries cost, not evidence of saturation.

## Why

Two different costs were conflated in earlier work. Separating them:

| Cost | Paid by | Size | Fixed by |
| --- | --- | --- | --- |
| **Listing** | the 25 **unconditional** skills, every session | ~7,438 tokens, of which **3,340 is never-invoked skills** | **Workstream E**, here |
| **Activation** | the 19 **conditional** skills, when a `paths:` glob matches | was ~64,116 tokens of bodies; **now ~50,412** | this brief |

Conditional skills cost **zero** listing tokens until they fire, so A through D
are not about the skill listing at all — they are about what lands in context
the moment a file is opened. Measured in `C:\Repos\ACME\fabric-acme` (295 tracked
files).

**Workstream E is the exception, and was added later** at the user's direction:
it targets the unconditional skills that load in *every* session, which is
listing cost. Its main lever — adding a `paths:` glob — converts a skill from
unconditional to conditional, moving it from one budget to the other. Both
budgets are this brief's; there is no second document to reconcile against.

The user's framing was consolidation. The measurements say consolidation is the
*third*-best lever and the only one carrying rename risk — two cheaper fixes
came first, and both are now done.

## What has been executed (2026-08-31)

| Commit | Change | Effect |
| --- | --- | --- |
| `7eb6d9e` | A1 — narrowed `pbip-project-structure` globs | 148 → 4 matches |
| `43f8359` | recorded A1 in this brief | — |
| `c85e996` | B — `fabric-eventstream` → `references/` | ~6,383 → ~2,810 tok |
| `325a3d4` | B — `fabric-warehouse` → `references/` | ~7,214 → ~2,975 tok |
| `b4cde33` | B — `fabric-eventhouse` → `references/` | ~4,788 → ~2,952 tok |
| `6d6dbb8` | B — `fabric-data-agent` → `references/` | ~7,128 → ~3,071 tok |

**Totals: ACME activation 1,919,257 → 1,215,862 tok (−36.6%). Conditional body
total 64,116 → 50,412 tok (−21%).** Worst single file 11,923 → 9,086 tok.

Every B refactor was verified with a content-preservation check (URL set
diff + non-verbatim line diff against `HEAD`) before commit. **That check is
not optional** — it caught real silent content loss twice, once from a
substring heading match that dropped an entire section. Use exact heading
matching with an assertion, never substring.

## Still-open verification

**CLOSED 2026-09-01.** A1 changed `paths:` frontmatter, which is a
*trigger* change, and the harness half was the last outstanding item from A
and B. Two cold `claude -p` probes, ground-truthed against the session
transcript rather than a counter or the model's self-report:

| Probe | `skill_listing` attachment, `isInitial: false` |
| --- | --- |
| `SampleReport.Report/definition.pbir` | `['pbip-project-structure']` |
| `.../visuals/Visual1/visual.json` | `['pbir-conditional-formatting', 'pbir-filters', 'pbir-visual-json']` |

Fires on the manifest, does not fire on the deep report file. Both rows
match `expected_activations.md` exactly. A1 is confirmed end to end.

**Running it needed a detour worth recording.** The platform skills are not
deployed on this machine — `~/.claude/skills` holds the seven workflow
skills only, because `-SkillGroups workflow` prunes the rest — so the
obvious version of this test reports "nothing loaded" for every fixture and
proves nothing. Neither is that visible: it looks identical to a broken
glob. The probes above ran against a **project-scope** deploy
(`link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups
powerbi`), which is gitignored, leaves the user-scope prune untouched, and
was removed afterwards. Anyone re-running this must deploy the group
somewhere first, or they are measuring an empty skills directory.

**Two findings came out of it, both larger than the assertion.** The
session transcript *does* record conditional activation — `CLAUDE.md` and
both trigger READMEs said nothing did, and are corrected. And an activation
injects the skill's **listing entry, not its body**, which is what makes
Workstream E's `fabric-spark-monitoring` row flip from "probably a bad
trade" to a good one.

One control stayed unexplained: a clean room outside this repo, with the
same skills deployed and the same fixtures, produced **no** activation at
all — and no rule load either. Ruled out: `skillOverrides`, git-vs-not, and
the 8.3 short path. Not chased further, since the in-repo positive is what
the assertion needed. Worth knowing before trusting a null from a scratch
directory.

**The glob half was already closed.** `tests/skills/pbip-triggers/` and
`tests/skills/fabric-triggers/` cover all 23 conditional skills between them,
and their static check confirms both halves of A1: `visual.json` pulls three
skills without `pbip-project-structure`, and eleven non-PBIP `.platform` files
pull it zero times. That left only "does the harness load on a match at
all", which is what the probes above answered. Grep the transcript for a
`skill_listing` attachment with `isInitial: false`; do **not** read a
counter, and do not ask the session what it can see — both were tried and
neither works.

Also usable as an A/B on a live payload edit: run the static check, change a
glob, run it again, diff. That is cheaper than a session and catches the
mistakes that have actually happened here.

## Measured facts (2026-08-31, ACME, post-A and post-B)

Worst observed single file — one report visual, now 3 skills, **~9,086 tokens**:

```text
Analytics/ACME_RP_Operation.Report/definition/pages/ProductionKPIs/visuals/tblJobs/visual.json
  -> pbir-conditional-formatting, pbir-filters, pbir-visual-json
```

Top co-activation pairs (files where both fire), post-A1:

| Files | Pair | Bodies |
| --- | --- | --- |
| 73 | `pbir-filters` + `pbir-visual-json` | ~6,390 tok |
| 73 | `pbir-conditional-formatting` + `pbir-filters` | ~5,997 tok |
| 73 | `pbir-conditional-formatting` + `pbir-visual-json` | ~5,785 tok |
| 36 | `fabric-error-handling` + `fabric-spark` | ~4,418 tok |
| 8 | `pbir-filters` + `pbir-pages` | ~6,292 tok |
| 2 | `fabric-tmdl` + `pbip-project-structure` | ~5,596 tok |

A1 removed `pbip-project-structure` from the visual cluster entirely; the
`pbir-*` trio is now the whole problem.

All 19 conditional skills, current body size and ACME reach:

| Skill | Body | refs | ACME matches | `skillUsage` |
| --- | --- | --- | --- | --- |
| `fabric-semantic-model-ai-instructions` | ~3,701 tok | 1f / 3.7 KB | 0 | never |
| `pbir-filters` | ~3,301 tok | 1f / 4.1 KB | 82 | 3 |
| `pbir-visual-json` | ~3,089 tok | 1f / 5.5 KB | 73 | 1 |
| `fabric-data-agent` | ~3,071 tok | 7f / 24.6 KB | 0 | never |
| `fabric-spark` | ~3,028 tok | 1f / 6.8 KB | 36 | 1 |
| `pbir-pages` | ~2,991 tok | 1f / 4.6 KB | 9 | never |
| `fabric-warehouse` | ~2,975 tok | 6f / 26.1 KB | 45 | 2 |
| `fabric-eventhouse` | ~2,952 tok | 6f / 21.5 KB | 10 | never |
| `pbir-themes` | ~2,913 tok | 1f / 4.5 KB | 3 | never |
| `pbip-project-structure` | ~2,837 tok | 1f / 6.9 KB | 4 | 2 |
| `fabric-eventstream` | ~2,810 tok | 5f / 18.1 KB | 24 | 4 |
| `fabric-tmdl` | ~2,759 tok | 1f / 22.4 KB | 23 | 1 |
| `pbir-conditional-formatting` | ~2,696 tok | 1f / 4.0 KB | 73 | never |
| `fabric-variable-library` | ~2,693 tok | 1f / 6.4 KB | 7 | 1 |
| `fabric-graph` | ~2,662 tok | 1f / 16.6 KB | 0 | never |
| `pbir-bookmarks` | ~2,097 tok | 1f / 3.6 KB | 0 | never |
| `fabric-realtime-dashboard` | ~1,839 tok | 1f / 3.2 KB | 2 | never |
| `fabric-error-handling` | ~1,390 tok | 1f / 6.3 KB | 36 | 1 |
| `fabric-database` | ~608 tok | 1f / 7.7 KB | 0 | never |

Body tokens estimated at ~3.5 chars/token (prose+code, looser than the ~2.7 of
description text). Treat as relative weights, not billing figures.

**Read the `skillUsage` column with care — see the trap in Workstream E.**

## Workstream A — glob hygiene — COMPLETE

**A1. `pbip-project-structure` — APPLIED (`7eb6d9e`).** Globs matched 148 of
295 files. The two `**` directory globs were the obvious offenders, but
`**/.platform` was worse and the original draft of this brief missed it:
`.platform` is a *Fabric* item marker, not a PBIP one, so dropping only the
last two globs left 38 matches of which 31 were `.platform` files in Notebooks,
Eventstreams, Lakehouses, Warehouses, KQL databases and DataPipelines. Applied
form narrows `.platform` to the two PBIP item types:

```yaml
paths:
  - "**/*.pbip"
  - "**/*.pbir"
  - "**/*.pbism"
  - "**/*.Report/.platform"
  - "**/*.SemanticModel/.platform"
```

| | matches | worst single file | total activation |
| --- | --- | --- | --- |
| before | 148 | 11,923 tok (4 skills) | 1,919,257 |
| drop 2 globs only | 38 | 9,220 tok (an Eventstream) | — |
| **applied** | **4** | **9,086 tok** (3 skills) | **1,510,729** (−21%) |

Accepted trade: it no longer fires when someone opens a report file deep inside
a project without touching a manifest — which was the point.

**A2. Audit the other 18 — DONE 2026-08-31, clean.** Every conditional skill
now lands **only** inside item folders of its own type. No cross-type leakage
anywhere:

```text
  82  pbir-filters                {Report: 82}        45  fabric-warehouse   {Warehouse: 45}
  73  pbir-conditional-formatting {Report: 73}        36  fabric-spark       {Notebook: 36}
  73  pbir-visual-json            {Report: 73}        24  fabric-eventstream {Eventstream: 24}
  36  fabric-error-handling       {Notebook: 36}      23  fabric-tmdl        {SemanticModel: 23}
  10  fabric-eventhouse           {Eventhouse: 10}     9  pbir-pages         {Report: 9}
   7  fabric-variable-library     {VariableLibrary: 7} 4  pbip-project-structure {Report: 2, SemanticModel: 2}
   3  pbir-themes                 {Report: 3}          2  fabric-realtime-dashboard {KQLDashboard: 2}
```

ACME item counts for comparison: Report 91, Warehouse 48, Notebook 36,
Eventstream 24, SemanticModel 23, Eventhouse 10, VariableLibrary 7,
DataPipeline 5, Lakehouse 4, EventSchemaSet 4, KQLQueryset 2, KQLDashboard 2.

The bug signature — a match count far above the item count of that type —
appears nowhere. `fabric-tmdl` (`a31c150`) and `pbip-project-structure`
(`7eb6d9e`) were the only two instances and both are fixed. **Do not re-run
A2 unless a glob changes.**

## Workstream B — body slimming — COMPLETE for the four named targets

`SKILL.md` **body** loads in full on activation. Files under `references/` load
only when the model chooses to read one. Moving detail from body to
`references/` cuts activation cost directly, with no merging and no rename.

All four targets are done (see the executed table above). The pattern that
worked, for anyone extending this to a fifth skill:

- Keep in the body: triggers, decision rules, the summary table, and the
  gotchas that must be known *before* acting.
- Move to `references/`: syntax tables, exhaustive property lists, long worked
  examples, API payload shapes, per-surface prerequisites.
- Split by *topic*, not by size — one reference file per thing a reader would
  go looking for. Four to six files per skill worked well.
- Every heading match must be **exact**, asserted. Verify with a URL-set diff
  and a non-verbatim-line diff against `HEAD` before committing.

### The ~2,900 cap is probably the wrong number

The brief originally suggested ~2,900 tokens (~10,150 chars) as the cap. **Nine
of 19 now exceed it — but they cluster tightly at 2,913–3,301, and three of
those were never refactored** (`pbir-themes` 2,913, `pbip-project-structure`
2,837 just under, `fabric-tmdl` 2,759 just under). Refactored and unrefactored
skills have converged on the same band.

That says ~2,700–3,100 is the natural floor for a dense platform reference
skill, not a target being missed. Three consecutive refactors landed at 2,952,
2,975 and 3,071 — further cuts removed facts rather than redundancy.
**Recommendation: set the cap at ~3,100 and treat anything above it as the real
signal.** On that basis only `fabric-semantic-model-ai-instructions` (3,701)
and `pbir-filters` (3,301) remain over, and both are better handled by
Workstream E and C2 respectively than by another body split.

## Workstream C — merges (renames skills)

Only justified where globs are identical or near-identical, so the skills can
never fire independently anyway.

**Read this first: a merge on its own saves almost nothing.** Merging three
skills does not delete their content — the merged body still carries all of it.
A merge saves one frontmatter block and some duplicated preamble. The real
saving comes from pushing detail into `references/`, which is Workstream B and
needs no rename at all. So B subsumes most of C's value at none of its risk,
and the figures below are *co-activation* totals, not merge savings.

**C1. `fabric-spark` + `fabric-error-handling`** — **identical** globs
(`**/*.Notebook/**`), confirmed 36/36 files in the A2 audit, always co-fire,
~4,418 tokens combined. There is no scenario where one is wanted and not the
other. Strongest merge case in the repo — but per the caveat above, worth only
a few hundred tokens. Consider it cleanup, not a lever.
Fixture: `tests/skills/fabric-triggers/fixtures/SampleNB.Notebook/` — all
three of its files pull exactly this pair, and no path separates them.

**C2. The `pbir-*` visual cluster** — `pbir-visual-json` (73 files),
`pbir-conditional-formatting` (73), `pbir-filters` (82). Overlapping but not
identical: `pbir-filters` also covers `report.json` and `page.json`. **~9,086
tokens combined, and post-A1 this is now the single worst activation in the
repo** — three skills on 73 files. Merging all three into one visual-authoring
skill with three `references/` files is the obvious shape, but it is also the
most opinionated change in this brief — **confirm with the user before doing
it.** Note that most of the gain here comes from the `references/` split, which
can be done *without* the merge if the rename risk is unwanted.

**C3. Leave alone.** `fabric-tmdl` + `fabric-semantic-model-ai-instructions`
have disjoint globs (`*.tmdl` vs `definition/cultures/*.tmdl`) and 0
co-activations in ACME. Not a merge candidate.

### The rename trap — read before any merge or removal

A merge or removal changes skill *names*, and three places hardcode them. None
of them error when a name goes stale; they just silently stop doing anything.

1. **`.claude/settings.json` in this repo** lists all 37 platform skill names
   under `skillOverrides`. A key naming a skill that no longer exists is
   ignored silently.
2. **`~/.claude/skills/` holds one junction per skill name.** Re-run
   `./scripts/link-claude.ps1` after any rename; a removed skill's junction is
   pruned only for names resolving inside this repo's `skills/`.
3. **Client repos deployed with `-ClaudeDir`** (ACME has 37 project skills in
   `.claude/skills`). Each needs its own relink after a rename.

Also: merged-away names lose their `skillUsage` history in `~/.claude.json`,
and any `/name` muscle memory breaks. Note the retired names in the commit
message so the history stays traceable.

## Workstream D — `when_to_use` adoption (NEW, not started)

The user wants to explore adding `when_to_use` to some skills. This section is
the grounding for that work; it has not been started.

### Blocking prerequisite — CLEARED 2026-09-01

> The linter gap described below is fixed. `scripts/lint-frontmatter.py` now
> gates `description` at 1,024 and `when_to_use` at 512 separately. Kept for
> the reasoning, not as an instruction.

**`scripts/lint-frontmatter.py` measures `len(description)` alone**
([line 180](../../../scripts/lint-frontmatter.py)), but the upstream 1,536 cap
applies to `description` + `when_to_use` **combined**. The comment at line 32
already claims "combined"; the code is what lags. Zero skills use `when_to_use`
today so nothing is broken yet — **but this must land before the first adoption
or the silent-truncation gap reopens.** Truncation has no error path. This is
inherited from the retired optimization-pass brief, and this brief now owns
it. Do it first.

**The fix is now specified — see the split-cap proposal below (2026-09-01).**
It is up to three `len()` checks rather than one, and *which* constants they
carry is an open decision. Land the decision and the linter change together: a
combined-only check written today would have to be rewritten if the split is
adopted.

### DECIDED 2026-09-01 — split A, and the premise is confirmed

**Split A is adopted: `description` ≤ 1,024, `when_to_use` ≤ 512.**
`scripts/lint-frontmatter.py` enforces both separately (`DESCRIPTION_MAX`,
`WHEN_TO_USE_MAX`, plus a `LISTING_MAX` sum assertion that can only fire if
the two are edited apart), and root `CLAUDE.md`, the handoff template, and
`author-skill` step 7 were reworded to match. All 44 skills passed the
tightened gate unchanged, as the corpus measurement predicted.

**The blocking premise is no longer unverified.**
`code.claude.com/docs/en/skills` states it three times: `when_to_use` is
"appended to `description` in the skill listing and counts toward the
1,536-character cap"; the `description` row says "the combined
`description` and `when_to_use` text is truncated at 1,536 characters in the
skill listing"; and the listing-budget section says "each entry's combined
text is capped at 1,536 characters regardless of budget". The cost model in
this workstream stands as written — it does not invert.

**One fact the drill added, which sharpened the split.** `when_to_use` is
**not** one of the six fields the claude.ai upload path accepts (`name`,
`description`, `license`, `compatibility`, `metadata`, `allowed-tools`); an
unexpected key there is a hard failure, not an ignored field. So the split
is not an arbitrary partition of 1,536: it puts the portable half in the
spec field that has to stay portable, and spends the remainder in a field
that is already Claude Code-only.

What remains open in D is **adoption** — which skills get a `when_to_use`
and what each one says. That is now its own brief:
[when-to-use-adoption.md](when-to-use-adoption.md).

### The split-cap proposal (as put on 2026-09-01, now decided)

Stop treating 1,536 as one pool the two fields compete for, and give each field
its own budget: **an explicit cap on `description`, with the remainder as the
cap on `when_to_use`.** The attraction is decoupling. Under a single combined
cap, a skill that adopts `when_to_use` silently changes how much room its
`description` has, so a later description edit can push the pair over a limit
that neither field's own text explains. Under a split, an edit to one field can
never overflow the other, and a lint failure names the field to cut.

**The corpus says the split costs nothing to adopt.** Measured 2026-09-01
across all 44 skills:

| | n | min | median | mean | max | ≥ 1,000 |
| --- | --- | --- | --- | --- | --- | --- |
| Conditional (`paths:`) | 19 | 457 | 981 | 881 | **1,024** | 7 |
| Unconditional | 25 | 266 | 822 | 803 | **1,024** | 3 |

`when_to_use` is set on **0 of 44**. The longest description in the repo is
exactly 1,024 — the Agent Skills spec cap — in *both* halves, which says
authors have been targeting the spec cap all along and the 1,536 gate has never
once been used as headroom.

| Split | `description` | `when_to_use` | What it costs |
| --- | --- | --- | --- |
| **A (recommended)** | 1,024 | 512 | Nothing today — every skill already fits, so the tightening is a no-op on the corpus. Buys back the spec cap, keeping descriptions portable to the claude.ai upload path. **But it reverses a documented decision**: root `CLAUDE.md` set the gate at 1,536 as "a deliberate trade of format portability for trigger headroom". That sentence has to be rewritten to say the *combined* cap is 1,536 while `description` keeps the 1,024 spec cap. |
| **B** | 1,280 | 256 | Keeps description headroom past the spec cap, honouring the original trade. 256 chars is about two sentences — enough for a genuine trigger clause, not enough for the "move trigger phrases out of `description`" pattern below. |
| **C (status quo intent)** | — | — | 1,536 combined, no per-field split — implement the linter fix and stop. Maximum flexibility, and keeps the coupling, including the failure mode where a description edit overflows a pair the author was not looking at. |

**Recommendation: A.** The headroom B preserves has never been used by any of
the 44 skills, and headroom whose only practical effect is to be silently
consumed by a second field is worth less than an explicit second budget. A also
makes both numbers mean something a reader can act on: 1,024 is "the spec cap,
still portable", 512 is "a trigger clause, not a second description". Note that
under A the combined check is *implied* — 1,024 + 512 = 1,536 — so the linter
needs only the two per-field checks; under C the combined check is the only
one there is.

**A does not weaken the aggregate case.** Per-field caps bound one skill; the
listing budget bounds all of them together, and that is the binding constraint
for the 25 unconditional skills (see the asymmetry table below). The split is a
*hygiene* fix — it makes overflow legible and non-interacting — not a
substitute for the narrow, evidence-led target selection this workstream
already requires.

### Verify this before adopting any of it

Every number above rests on a claim this repo has never observed: that
`when_to_use` is appended to `description` in the skill listing and counts
toward the same truncation point. **Zero skills set it**, so nothing here has
been seen to happen — the claim is currently carried by root `CLAUDE.md`, the
handoff template, and this brief, all asserting each other. Confirm it against
the Claude Code documentation or changelog — `anthropics/claude-code` is
already a registered `/drift-audit` source — before the first adoption and
before the linter constants are chosen. If `when_to_use` turns out to be
surfaced on invocation rather than in the listing, the cost model in this
workstream inverts and the split cap is unnecessary.

### The asymmetry that should drive the policy

`when_to_use` is appended to `description` in the skill listing and counts
toward both the per-skill 1,536 cap and the aggregate listing budget. It is
**extra listing text, not free trigger signal.** But the cost lands very
differently depending on the skill:

| Skill kind | Listing cost of `when_to_use` | Verdict |
| --- | --- | --- |
| **Conditional** (19, have `paths:`) | **Zero until the skill activates** — conditional skills are withheld from the listing entirely | Nearly free. Best candidates. |
| **Unconditional** (25) | Paid in **every session on this machine**, against a budget with ~100 tokens of headroom on `opus[1m]` and heavy truncation on 200k-window models | Expensive. Requires a matching `description` trim to stay net-neutral. |

This asymmetry is not stated in either predecessor brief and is the most useful
thing to carry into the work: **adding `when_to_use` to a conditional skill is
close to free; adding it to an unconditional one competes directly with every
other skill's description.**

### How to choose targets

The optimization-pass brief's rule stands — **narrow and evidence-led, not a
blanket pass over 44 skills.** A skill earns `when_to_use` when there is a
demonstrated trigger miss, sourced from `scripts/instructions-log
reasons|paths|skills` or the user's own experience of a skill that should have
fired and didn't.

For unconditional skills, prefer *moving* trigger phrases out of `description`
into `when_to_use` (net-zero listing cost) over *adding* text.

One complication to resolve before measuring anything: **`skillOverrides` in
`.claude/settings.json` currently sets all 37 platform skills to `name-only`**
(commit `a26d23b`), which suppresses their descriptions from the listing in
*this* repo. Field evidence calls that setting "unnecessary as an emergency
measure" while it is still in force. So description and `when_to_use` edits are
a **no-op locally** and only take effect in client repos like ACME, which have
no `skillOverrides`. Decide whether to keep or drop that setting before
trusting any local measurement of a listing change. This contradiction is
unresolved and belongs to whoever picks up D.

## Workstream E — is the skill necessary at all? (NEW, not started)

The user's framing: some of these are **reference documents, not workflows**.
A skill that describes a product surface but never tells you what to *do* is
paying for itself in every session to deliver something a markdown file in
`docs/fabric/` would deliver on demand.

**Scope: this workstream is about the 25 UNCONDITIONAL skills.** That is the
user's stated priority — the ones loaded at the start of every session. The
conditional skills are already handled by A, B and C.

### Read this first: what an unused unconditional skill actually costs

An unconditional skill puts **only its `description`** in the session listing.
Its **body loads only when the skill is invoked.** So a never-invoked
unconditional skill costs its description and nothing else — a few hundred
tokens per session, not the thousands its body would suggest.

Getting this backwards inflates the apparent prize by an order of magnitude.
The 12 never-invoked unconditional skills hold 44,396 tokens of body between
them, and **none of it is ever loaded.** What they actually cost is **3,340
listing tokens, in every session** — which is still 45% of the 7,438-token
listing, and the single largest cleanable block in the repo.

### Measured: the 25 unconditional skills (2026-08-31)

`listing` = description tokens at ~2.7 chars/token — the real per-session cost.
`body` is shown only to make the point that it is *not* being paid.

| uses | listing | body | skill | group |
| --- | --- | --- | --- | --- |
| 0 | 376 | 3,999 | `fabric-ai-functions` | fabric |
| 0 | 352 | 2,776 | `fabric-copy-job` | fabric |
| 0 | 350 | 4,659 | `fabric-mirroring` | fabric |
| 0 | 347 | 5,708 | `fabric-cli` | fabric |
| 0 | 335 | 5,040 | `pbid-tom-live` | powerbi |
| 0 | 285 | 3,471 | `fabric-rest-api` | fabric |
| 0 | 274 | 2,165 | `fabric-security` | fabric |
| 0 | 269 | 10,575 | `powerbi-report-authoring` | powerbi |
| 0 | 244 | 1,046 | `fabric-tmdl-api` | fabric |
| 0 | 239 | 2,030 | `fabric-spark-monitoring` | fabric |
| 0 | 170 | 1,196 | `fabric-warehouse-monitoring` | fabric |
| 0 | 99 | 1,731 | `code-review` | workflow |
| 1 | 377 | 3,130 | `fabric-gotchas` | fabric |
| 1 | 367 | 4,767 | `fabric-cicd` | fabric |
| 1 | 367 | 4,052 | `pbir-report-workflow` | powerbi |
| 1 | 304 | 1,583 | `pbir-cli` | powerbi |
| 1 | 250 | 4,766 | `powerbi-report-design` | powerbi |
| 2 | 345 | 3,909 | `author-skill` | workflow |
| 2 | 256 | 2,145 | `drift-handoff` | workflow |
| 3 | 379 | 5,222 | `fabric-mlv` | fabric |
| 3 | 237 | 1,245 | `fabric-auth` | fabric |
| 5 | 367 | 5,854 | `drift-audit` | workflow |
| 8 | 273 | 2,220 | `learn` | workflow |
| 9 | 331 | 4,043 | `drift-update` | workflow |
| 60 | 245 | 939 | `commit` | workflow |

**Total listing: 7,438 tok. Never-invoked: 12 skills, 3,340 tok.**

`code-review` at 99 tokens is a rounding error and **collides with a bundled
skill of the same name** — check that collision before judging its zero.

### Four outcomes, and the cheapest one is not demotion

| Outcome | Listing cost after | Still triggers? | Still deploys to client repos? |
| --- | --- | --- | --- |
| **Keep as-is** | full description, every session | model-invoked | yes |
| **Trim the description** | partial saving | model-invoked | yes |
| **Add a `paths:` glob** | **zero** | **yes — on matching files** | **yes** |
| **Demote to `docs/fabric/<name>.md`** | **zero** | **no** | **no** |

**Try the `paths:` glob first.** The field-evidence brief names it and nothing
has acted on it: adding a `paths:` glob converts an unconditional skill into a
conditional one, which removes its description from the listing **entirely**
while keeping the skill, its body, its `/name` invocation, and its deployment
to client repos. It costs no rewrite. For anything scoped to a Fabric item
type, this is strictly better than demotion — the skill stops costing anything
per-session *and* starts firing exactly when it is relevant, which is more
reach than it has today, not less.

Obvious glob candidates among the never-invoked, by item type:

| Skill | Plausible glob | Listing saved |
| --- | --- | --- |
| `fabric-copy-job` | `**/*.CopyJob/**` | 352 |
| `fabric-mirroring` | `**/*.MirroredDatabase/**` | 350 |
| `fabric-spark-monitoring` | `**/*.Notebook/**` — **measured: makes it the third skill on every Notebook file, 4,418 → ~6,448 tok activation.** Saves 239 listing tokens once per session and costs ~2,030 every Notebook touch. Probably a bad trade; see C1 | 239 |
| `fabric-warehouse-monitoring` | `**/*.Warehouse/**` | 170 |
| `fabric-tmdl-api` | `**/*.SemanticModel/**` or `**/*.tmdl` | 244 |
| `pbid-tom-live` | `**/*.pbix`, `**/*.pbid`? — **verify the item type exists** | 335 |
| `fabric-cicd` | `**/*.Lakehouse/alm.settings.json` + others | 367 |
| `fabric-variable-library` (already conditional) | add `**/*.Lakehouse/shortcuts.metadata.json` | 0 |
| `fabric-mlv` | `**/*.Lakehouse/**`? — **confirm where MLV definitions serialize first**; they may live in the creating Notebook | 379 |

That is **~1,690 listing tokens for six frontmatter edits and no content
changes** — the highest ratio of saving to risk left in the repo.

**Two corrections from the fixture work (`9d49302`), applied above.**
First, a `paths:` glob is not free: it trades a once-per-session listing
cost for a per-file-touch activation cost, and the `fabric-spark-monitoring`
row is a case where that trade is probably bad. Weigh both sides per row
rather than treating the glob as strictly better. Second, the last three
rows come from
[item-type-skill-lakehouse.md](item-type-skill-lakehouse.md) — the Lakehouse
decision and this table are the same decision made twice, so make it once.

**Measure every candidate glob with the static check in
`tests/skills/fabric-triggers/README.md` before committing it.** Run the
rules pass too — several of these globs land on files that already carry a
rule, and the co-loaded pair is the real cost. **Every glob
must be measured against a real repo before committing** (harness below); a
wrong glob has no error path, and this is exactly how `fabric-tmdl` and
`pbip-project-structure` got their bugs.

Demotion to `docs/` is the right answer only when the content should **not**
auto-load at all and has no natural trigger — because a file in `docs/` is
never triggered, never deployed to ACME via
`scripts/link-claude.ps1 -SkillsOnly -SkillGroups fabric`, and only gets read
if someone or something goes looking for it. That is a real loss of reach.

The genuine demotion candidates are the ones with **no natural glob**, because
they describe a tool or a cross-cutting concern rather than an item type:
`fabric-cli` (347), `fabric-rest-api` (285), `fabric-security` (274),
`fabric-ai-functions` (376), `powerbi-report-authoring` (269). Apply the test
below to each.

### The test to apply

For each candidate, ask: **does the body change what the agent does, or only
what it knows?**

- **Procedure** — ordered steps, decision rules, "when X do Y", gotchas that
  must be known *before* acting, refusal conditions. Keep as a skill.
- **Reference** — property tables, link bundles, feature explanations,
  comparison matrices, prose describing a product surface. Candidate for
  demotion.

A skill can be mostly reference and still earn its place if the *procedural*
part is load-bearing — in that case the answer is a `paths:` glob or a thin
body over a fat `references/`, not demotion.

### The `skillUsage` trap — read before using the usage column

`skillUsage` in `~/.claude.json` counts **invocations** — slash commands and
Skill-tool calls. It is meaningful for **unconditional** skills, which are in
the listing every session: a zero means the model has never once chosen it
despite always being able to see it. That is what makes the table above
actionable.

It is **not** meaningful for conditional skills. Those auto-activate through a
`paths:` glob — they are **loaded, not invoked**, and never increment the
counter. `fabric-eventhouse` reads "never" despite matching 10 live ACME files.
This is the same class of error the field-evidence brief had to retract when it
read conditional withholding as budget-driven dropping. **A skill that gets a
`paths:` glob in this workstream will stop incrementing its counter — do not
later read that as death.**

### The one hole in the A2 audit — closed 2026-08-31

A2 concluded all 19 conditional globs were sound, but three of them named
item types that no export had confirmed — `.DataAgent`, `.SQLDatabase`,
`.GraphModel` — because the names came from the skills' own claims, and a
fixture built on such a name agrees with a wrong glob rather than catching
it. So A2 really read "16 verified, 3 assumed".

All three are now verified against real Git-synced exports (sources pinned
in `tests/skills/fabric-triggers/README.md`), and all three were **right**:
no glob changed. A2 reads 19/19. The lesson survives the finding — an
item-type name a skill asserts about itself is not evidence, and E's
`paths:` candidates below should be checked against an export before they
are written, not after.

### Do not touch

- **`fabric-data-agent`** — conditional, 0 ACME matches, never invoked, and it
  would otherwise look like a demotion candidate. The user expects to start
  using it once the data side is in place. **Leave it alone.** Its body was
  already cut 57% in `6d6dbb8`.
- **The five workflow skills that carry the repo's own procedure** (`commit`,
  `learn`, `drift-*`, `author-skill`) — all invoked, all procedural.
- **Conditional skills generally.** They cost zero listing tokens; this
  workstream is not about them.

### Scoping note — E spends the other budget

**E is listing cost; A–D are activation cost.** That split used to live across
two briefs, which is how the same 25 descriptions ended up scheduled twice. The
predecessor brief's step 5 ("trim the 25 unconditional descriptions") is
**superseded by E** and that brief is deleted — there is nothing left to
reconcile against.

Keep the distinction visible anyway, because the `paths:`-glob lever crosses
it: converting an unconditional skill to a conditional one *removes* listing
cost and *adds* (small) activation cost. Re-measure both sides after any such
edit, and say in the commit message which budget the change was spending.

### The listing budget binds hardest on small-context sessions

Carried forward from the deleted field-evidence brief, and the strongest
argument for doing E at all:

The listing budget is **1% of the running model's context window**, so the
number moves with the model. On `opus[1m]` the ~9,900-token listing fits inside
a ~10,000-token budget with roughly one skill of headroom. **On a 200k-window
session the budget is 2,000 tokens against ~9,900 wanted** — those sessions are
badly truncated today, and raising `skillListingBudgetFraction` to 1.5% or 2%
would not come close to closing that gap.

Cutting what is in the listing is the only lever that helps there, which is
exactly what E does. Measure on the model you actually run.

## Verifying

### Measuring the listing itself (for D and E)

Carried forward from the deleted field-evidence brief. **`claude doctor` on the
CLI reports installation health only — it does not report listing cost.** The
listing internals come from a one-turn print session:

```bash
cd <repo> && claude -p "Reply with exactly: ok" --model opus[1m] \
  --debug-file /path/to/dbg.log
grep -iE "conditional|unique skills|getSkills|via attachment" /path/to/dbg.log
```

Expected shape, and how to read it:

```text
[skills] 19 conditional skills stored (activated when matching files are touched)
Loaded 44 unique skills (25 unconditional, 19 conditional, user: 7, project: 37)
getSkills returning: 25 skill dir commands, 0 plugin skills, 42 bundled skills
Sending 41 skills via attachment (initial)
```

41 sent = 25 unconditional + 16 bundled. **The 19 conditional skills being
absent is correct behaviour, not a truncation** — see "How this brief's
premises were corrected". A real overflow writes a budget warning to this log;
if you see no warning, there is no overflow.

Pin the same model you normally run — the budget is a fraction of *that
model's* context window. Two other things worth knowing when reading counts:

- **`scripts/instructions-log skills` counts Skill-tool calls only** — it reads
  as "how often the model chose the skill unprompted" and understates real use.
  `skillUsage` in `~/.claude.json` counts typed `/name` invocations too, and is
  the total-usage source used in E's table.
- **Bundled skills contribute ~2,460 tokens** to the listing and are not
  editable from this repo. Four plugins were disabled in `c7d4e30`, which
  already returned ~720 listing tokens; there are no plugins left to disable.

### Measuring activation (for A, B, C)

Re-run this after every glob change. It is how A1, A2 and the `fabric-tmdl`
fix were all measured:

```bash
cd <client-repo> && git ls-files > /tmp/files.txt
```

```python
# uv run --with pyyaml --with wcmatch python thisfile.py
import pathlib, yaml
from wcmatch import glob as wg
F = wg.GLOBSTAR | wg.DOTGLOB
files = [l.strip() for l in open('/tmp/files.txt', encoding='utf-8') if l.strip()]
for p in sorted(pathlib.Path('skills').glob('*/*/SKILL.md')):
    d = yaml.safe_load(p.read_text(encoding='utf-8').split('---', 2)[1])
    if not d.get('paths'):
        continue
    hits = [f for f in files if wg.globmatch(f, d['paths'], flags=F)]
    print(f"{len(hits):4d}  {d['name']}")
```

A match count far above the number of items of that type is the bug signature.

For any body edit, verify content preservation against `HEAD` before
committing — URL-set diff plus a normalized non-verbatim-line diff:

```python
n = lambda s: re.sub(r'\s+', ' ', s).strip()
u = lambda s: set(re.findall(r'https?://[^\s\)\|]+', s))
print("URLs lost:", u(orig) - u(new_skill_plus_all_references))
missing = [l for l in orig.split('\n') if len(n(l)) > 45 and n(l) not in n(new)]
```

Every surviving entry in `missing` must be explainable as an intentional
rewrite. This caught two real regressions during Workstream B.

Then, per root `CLAUDE.md`:

- Lint every touched skill:
  `uv run --with pyyaml scripts/lint-frontmatter.py skills/<group>/<name>/SKILL.md`
- `pre-commit run --all-files`
- `./scripts/link-claude.ps1` after any rename or removal; confirm
  `~/.claude/skills` holds one junction per current skill name and no stale
  ones.
- Fresh-session check: open a file that should trigger the changed skill and
  confirm it activates. `paths:` is frontmatter, so **restart before trusting
  a changed trigger** — hot-reload of an in-place frontmatter edit is the one
  case not verified on this machine.
- `tests/` untouched; `git status` clean; finish with `/commit`.

## Constraints

- Fixtures under `tests/` are never modified.
- Skill bodies are the payload — do not delete content to hit a size target.
  Move it to `references/`, or to `docs/`, or leave it alone.
- A wrong glob has no error path; it just never fires. Every glob edit gets
  re-measured, never assumed.
- Workstreams C, D and E are independent of each other. Each is safe to land
  incrementally, one skill per commit if preferred.
- Both budgets are in scope here. Workstream D moves text between
  `description` and `when_to_use`; E converts unconditional skills to
  conditional. Both cross between listing and activation cost — **say which
  budget you are spending in the commit message**, since the two are measured
  differently (~2.7 chars/token for description text, ~3.5 for bodies).
