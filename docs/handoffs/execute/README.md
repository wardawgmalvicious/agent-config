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
walks those briefs in their own numbered order, so their state lives in
each brief's execution log rather than in frontmatter.
`uv run scripts/handoff-status.py` prints them after the brief queue, as
audit follow-ups: each directory holding a brief not yet executed, and
every brief whose log leaves work open — escalated, deferred or applied
with deferrals, with no `**Closed**:` line — grouped by the `**Needs**:`
line that log carries, as `needs` groups a brief here. `audit-status.py`
decides which are open, beside the directory index it builds from the
same logs, so the two cannot disagree.

**A stamped brief can still be pending.** `/drift-update` stamps every
brief it escalates, so the next run skips it, while the work its answer
implies — or a deferral it recorded — lives only in that brief's log.
Found 2026-09-11: every open follow-up had been stranded that way. A
table here carried them from then until 2026-09-27, and missed what a
hand-kept list misses: a decline recorded in a subsection after its
stamp, which left powerbi 07 reading as open for nineteen days, and a
deferral whose own log said it stayed open. The view reads every log to
its end, so it misses neither.

**The `**Needs**:` line is the follow-up's home.** `/drift-update` writes
one with every stamp that leaves work open, the frontmatter's words
(`user`, `tenant`, `desktop`, a short phrase, or `none`) with the reason
after a dash, and `lint-briefs` fails a commit on an open brief without
one. A deferred re-check gets one too, naming the audit that performs
it. When the need changes, append a new line, since the last one counts;
when the work lands, append `**Closed**: <date> — <how>` in the same
commit, which drops the brief from the view and shows it `closed` in its
directory's index.

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
