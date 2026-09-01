# Open briefs — execution order

Seven briefs are open. Two waves are spent as of 2026-08-31 (struck
through below); `rule-glob-gaps.md` survives them because one of its four
findings was a decision rather than an edit, and it has been trimmed to
that. This file is the **only** place the order lives;
each brief carries its own dependencies but not its position.

## Why these are not numbered like drift briefs

`/drift-handoff` numbers its output `01-`, `02-`, … and `/drift-update`
walks that order. That works there because a
`docs/drift-audit/<date>/<source-id>/` directory is a **disposable whole**:
gitignored, executed in one pass, discarded together, and its briefs do not
cite each other.

`execute/` is the opposite on all three counts. Briefs here are committed,
deleted **individually** as each is spent, and heavily cross-linked — 17
links between the current 7 files. Numbering the filenames would mean
rewriting those 21 links now, and again on every deletion, choosing each
time between renumber-and-relink churn or a queue that reads `01, 04, 06,
08`. The filename is the link target, so it has to be the stable thing.

So: **stable kebab-case filenames, order in this file.** If a brief needs
to know it is blocked, that belongs in the brief as a dependency, not as a
position. A position is a fact about the queue and lives with the queue.

## The order

Waves, not a strict sequence — briefs inside a wave are independent of each
other and can go in any order or in parallel. Waves are ordered by
dependency and by cost of delay. Numbering starts at 1 because wave 0 —
confirming the three unverified item-type names — is spent; renumbering the
rest would only invalidate every reference to a wave elsewhere.

| # | Brief | Why here |
| --- | --- | --- |
| ~~**1**~~ | ~~[rule-glob-gaps.md](rule-glob-gaps.md) — bugs 1, 1b~~ | **Done 2026-08-31.** `coding-sparksql.md` now matches `**/*.Notebook/notebook-content.sql`; the `coding-tsql` overlap is resolved by a precedence section in each rule, keyed on the notebook kernel. Bug 1b was not a contradiction — recorded as a scope carve-out. |
| **2** | [item-type-skill-kqlqueryset.md](item-type-skill-kqlqueryset.md) + [rule-glob-gaps.md](rule-glob-gaps.md) | One decision in two files — whether KQL conventions should reach the JSON files that hold queries. Doing them apart means deciding twice. |
| **3** | [skill-model-policy.md](skill-model-policy.md) | Independent of every other brief. Addresses actual pain (weekly limits), and its biggest item — the unexplained `workflow-subagent` 24% — is a diagnostic that may be worth more than every frontmatter edit combined. Cheap to run. |
| **4** | [skill-context-cost.md](skill-context-cost.md) workstreams C + E, folding in [item-type-skill-lakehouse.md](item-type-skill-lakehouse.md) | The big pass. Lakehouse **is** an E row — its recommended fix is a `paths:` glob on `fabric-variable-library` — so run them together or E gets made twice. E's `paths:` candidates must be measured against confirmed item-type names — see the sources pinned in `tests/skills/fabric-triggers/README.md`, and add the fixture in the same commit as the glob. |
| **5** | [item-type-skill-datapipeline.md](item-type-skill-datapipeline.md) | The only "yes, author it" in the queue, and the largest single chunk of work. Nothing blocks it — it is late because it is expensive, not because it is stuck. Do it earlier if the pipeline surface is what you are actually working on. |
| ~~**6**~~ | ~~[rule-glob-gaps.md](rule-glob-gaps.md) — bug 3~~ | **Done 2026-08-31.** `**/*.GraphModel/**` added to `fabric-git-serialization.md`, with `**/*.UserDataFunction/**` and `**/*.ApacheAirflowJob/**` from a partial item-type diff. `Dataflow` confirmed correct. |
| **7** | [skill-effectiveness-telemetry.md](skill-effectiveness-telemetry.md) | Scoping only, no dependencies, no deadline. Also the one most likely to be overtaken by upstream shipping something. |

[skill-context-cost.md](skill-context-cost.md) workstream **D**
(`when_to_use`) sits outside the waves: it is blocked on a
`scripts/lint-frontmatter.py` fix for combined-length checking. Do it
whenever that lands.

## What this order is optimising for

**Bugs before improvements.** Wave 1 was the only thing in the queue
producing wrong behaviour; it landed 2026-08-31, so what remains is all
improvement and judgement work.

**Paired decisions in one sitting.** Waves 2 and 4 each merge briefs that
would otherwise make the same call twice — the failure mode that forced
the 2026-08-31 consolidation of four briefs into two.

**Cheap and independent before expensive.** Wave 3 before 4 and 5.

## Four briefs are decisions, not edits

[item-type-skill-lakehouse.md](item-type-skill-lakehouse.md),
[item-type-skill-kqlqueryset.md](item-type-skill-kqlqueryset.md),
[item-type-skill-datapipeline.md](item-type-skill-datapipeline.md) and —
since its edit findings landed —
[rule-glob-gaps.md](rule-glob-gaps.md) each open with a recommendation,
and two of them recommend **not** building the thing. `/drift-update` treats a decision-kind brief as something to put
back to the user rather than execute; the same applies here. Landing a
"no" is a real outcome — record the reasoning in the commit that deletes
the brief, or the empty column gets re-opened by whoever notices it next.

## Before touching any `paths:` glob

Run the static check in
[`../../../tests/skills/fabric-triggers/README.md`](../../../tests/skills/fabric-triggers/README.md),
over `skills/` **and** `claude/rules/`. Every glob bug this queue contains
was found that way and none was findable any other way — the linter checks
glob *syntax*, and all of these are well-formed globs that are wrong about
the world.

## Lifecycle

Unchanged from [../README.md](../README.md): **once the change lands, the
brief is deleted**, and git history is the archive. When you delete one,
strike its row here too — a queue listing a spent brief is worse than no
queue.
