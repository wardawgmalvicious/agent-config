# Open briefs

Each brief here holds its own state in frontmatter, and
`uv run scripts/handoff-status.py` generates the queue from it.
[../CLAUDE.md](../CLAUDE.md), which loads on the first Read under
`docs/handoffs/`, has the keys and what a session must know before
touching a brief; this file keeps the reasoning behind them.

## No file lists the queue

Until 2026-09-27 a table here was the only place the execution order
lived, so every session that started or landed a brief edited it. Two
sessions in one tree dropped each other's rows silently, as root
`CLAUDE.md` recorded from 2026-09-02, and two in worktrees would have
conflicted on it at merge, so briefs ran one at a time whatever else
allowed more. It was read less than it was written, too.
[queue-state-per-brief.md](queue-state-per-brief.md) has the measurement,
the user's decision and a survey of how other agent tooling keeps a
backlog.

Priority is three buckets, not a total order: briefs in one bucket may
run in parallel, and a worktree named after a brief claims it. What still
conflicts between worktrees is real content, an evidence ledger above
all, and that surfaces at rebase rather than in silence.

Waves 1–18 are spent, closed between 2026-08-31 and 2026-09-03. Their
briefs are deleted and their outcomes live in the artifacts they changed,
per the [lifecycle](#lifecycle) below.
`git log -p -- docs/handoffs/execute/README.md` has every row the table
held, if a closed decision ever needs re-reading.

## Audit briefs are a second queue

`/drift-handoff` writes to `docs/audits/`, not here, and `/drift-update`
walks those briefs in their own numbered order — so an unexecuted audit
run is pending work the generated queue does not list. A brief there with
no `## Execution log` section has not been executed, and each directory's
generated `README.md` says which those are in one table — read it before
opening briefs.

**A stamped brief can still be pending.** `/drift-update` stamps every
brief it escalates, so the next run skips it and the rule above reads it
as done, while the work its answer implies — or a deferral it recorded —
lives only in that brief's log. Found 2026-09-11: everything below had
been stranded that way. Entries are grouped by what each needs, not
ordered; delete one in the commit that lands its work. Deferred re-checks
are not listed — the next audit of that source is what performs them.
Read a brief's log to its end before listing it: a decision can sit in a
subsection after the stamp, as powerbi 07's 2026-09-08 decline did.
When a row's work lands, append a `**Closed**: <date> — <how>` line to
that brief's log in the same commit that deletes the row, so the
directory index shows the brief as `closed` rather than open forever.

| Needs | Audit briefs |
| --- | --- |
| A person driving Power BI Desktop | [powerbi 04](../../audits/2026-09-07/powerbi/04-catalog-new-visual-formatting-properties.md) with [10](../../audits/2026-09-07/powerbi/10-supply-drilled-evidence-for-matrix-properties.md) and [13](../../audits/2026-09-07/powerbi/13-propagate-new-formatting-to-authoring-skills.md) D-1 · [06](../../audits/2026-09-07/powerbi/06-verify-pbip-autodetect-vs-reload-bridge.md), which also needs the `powerbi-desktop` bridge CLI · [02](../../audits/2026-09-07/powerbi/02-retire-fluent2-preview-framing.md)'s 1280×720 carve-out |
| A model export with AI instructions set | [skills-for-fabric 05](../../audits/2026-09-10/skills-for-fabric/05-add-lsdl-refresh-to-ai-instructions.md)'s TMDL collision |
| A Git-synced Fabric repo to measure in | [skills-for-fabric 04](../../audits/2026-09-10/skills-for-fabric/04-measure-notebook-serialization-before-editing.md), whose need the client Fabric repo on this machine meets, so it rides with the Fabric content session above. Its step 3's `grep -c $'\r'` miscounts: `~/.claude/CLAUDE.md` § "Counting carriage returns" has the substitute |
| One open question settled, then lint code | [skills-for-fabric 08](../../audits/2026-09-10/skills-for-fabric/08-decide-catalog-budget-and-reference-lints.md): the **catalog listing-budget check only**. Its reference-lint half landed 2026-09-15 as `scripts/skill-overlap.py routing`, wired into pre-commit as `lint-skill-routing`, which settles that half's open question — what counts as a reference is a backticked platform-prefixed name, with every non-skill class derived or excluded by path. What is left needs the budget itself, and that must come from Claude Code's docs rather than upstream's numbers |

## Filenames are stable

`/drift-handoff` numbers its output `01-`, `02-`, … and `/drift-update`
walks that order. That works there because a
`docs/audits/<date>/<source-id>/` directory is a **fixed whole**: written
in one pass, executed in one pass, kept together afterwards as a dated
ledger, and its briefs do not cite each other. Numbers are safe where
nothing is ever removed.

`execute/` is the opposite on all three counts. Briefs here are committed,
deleted **individually** as each is spent, and cross-linked by filename —
so the filename is the link target and has to be the stable thing.
Numbering would mean re-linking on every deletion, choosing each time
between renumber-and-relink churn and a queue that reads `05, 07, 09, 10`.
If a brief needs to know it is blocked, that is a dependency and belongs
in its `blocked-by`. Its bucket is its `priority`, and within a bucket
there is no order to keep.

## A skill brief outlives its skill until the test runs

Since 2026-09-12 `/test-skill` deletes the brief at its last step, so a
skill brief here beside a skill that exists means the test has not run.
Before that, nothing removed one: the `fabric-catalog-governance` brief
outlived its test by a day with no row here and no reader. The test
state itself is never tracked in this file. Derive it:

```bash
uv run --with pyyaml scripts/skill-status.py --stale
```

A brief can no longer sit here unlisted. `/author-skill` writes its brief
here and edits no index, which before frontmatter left one invisible
whenever its cycle stalled: the `linkedin-highlights` brief was written,
spent and deleted without ever having a row (2026-09-10). Now the view
lists every brief with frontmatter, and `lint-briefs` fails one without.

## Re-measure a brief before acting on it

The queue's two most expensive lessons, and the only ones that still
apply to work not yet done:

- **Wave 17's evidence was never true.** The row specified an MCP template
  as the work; that template had shipped five days *before* the row was
  written, in an ordinary refactor nobody thought to check the queue
  against. Executing it as written would have produced a duplicate entry
  and no new capability.
- **Wave 14's evidence rotted in under two hours.** A grep the brief used
  as its baseline went from zero hits to five between the step 0 answer
  being committed and a re-run the same day — and the new hits pushed
  *away* from the work rather than toward it, so re-running the grep
  without reading it would have inverted the conclusion.

The interval is not the signal, and neither case was detectable without
going and looking. The trap is structural: briefs are written *about*
payload directories, but nothing links the two, so a commit outside the
queue can silently satisfy or invalidate a brief. **Re-run a brief's own
evidence before executing it** — and if it has moved, record which
direction.

## A brief can be a decision rather than an edit

[item-type-skill-fabric-plan.md](item-type-skill-fabric-plan.md) opens
with a recommendation rather than an edit list. `/drift-update` treats a
decision-kind brief as something to put back to the user rather than
execute, and the same applies here: while open, such a brief carries
`needs: [user]`. Landing a **no** is a real outcome — record the reasoning
in the commit that deletes the brief, or the question gets re-opened by
whoever notices the gap next.

Seven such briefs are spent: five "yes" and two "no", so the question has
not been a rubber stamp. **Defer** is a third outcome, and the only one
that leaves a file behind — don't read the surviving brief as an
unanswered question. It stays `deferred` and names what would re-open it
in `reopen-when`, which the queue prints; the last trigger to fire, the
CI-workflow rule's on 2026-09-25, was spent 2026-09-27 as
[coding-ci-workflows.md](../../../claude/rules/coding-ci-workflows.md).
Delete it only if the workload is abandoned upstream or ruled out
outright, and record which.

## Before touching any `paths:` glob

Run the static check — `./scripts/test-activation.ps1 -Set fabric
-StaticOnly`, then `-Set pbip`. Every glob bug this queue ever contained
was found that way and none was findable any other way: the linter checks
glob *syntax*, and these were all well-formed globs that were wrong about
the world. Derive skill counts the same way rather than restating a total
here — each figure is owned by its set's `expected_activations.md`, and
the last one that got duplicated into prose drifted three ways at once.

## Lifecycle

Unchanged from [../README.md](../README.md): **once the change lands, the
brief is deleted**, and git history is the archive. Deleting one is not
just an `rm` — **re-point whatever linked to it in the same commit**, and
drop its name from any other brief's `blocked-by`, which `lint-briefs`
fails otherwise. The test is that no surviving brief still says "read it
there" about a file that is gone.

When the last brief goes, this file is left as a heading and these
conventions. That is its correct resting state, not a sign something was
lost.
