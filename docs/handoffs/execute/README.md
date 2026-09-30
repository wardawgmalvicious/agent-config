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
allowed more. It was read less than it was written, too: of 24 sessions
that edited a brief here between 2026-09-11 and 2026-09-27, 7 opened it
first of their own accord, 4 more because the user named it, and 11
never did ([nested-instruction-files.md](nested-instruction-files.md),
§ "Phase 2").

Surveyed the day the user decided this, everything built for parallel
agents keeps state per task and generates the view. Backlog.md holds one
file per task with frontmatter and draws its board from them; log4brains
drops sequential numbering, which its README says avoids git merge
issues, and generates its site; spec-kit and Kiro shard by feature
directory with no index across features. Taskmaster began with one
`tasks.json`, met this exact collision (its issue #744), and added tagged
task lists to fix it. Claude Code's agent teams claim tasks under file
locking, but are experimental, one team per session, and share one
working tree: a fan-out tool, not a durable backlog (docs read
2026-09-27). The brief that made the change, `queue-state-per-brief.md`,
landed that day, and `git log --diff-filter=D -- 'docs/**/<name>.md'`
recovers it as [../README.md](../README.md) says.

Priority is three buckets, not a total order: briefs in one bucket may
run in parallel, and a worktree named after a brief claims it. What still
conflicts between worktrees is real content, an evidence ledger above
all, and that surfaces at rebase rather than in silence.

Waves 1–18 are spent, closed between 2026-08-31 and 2026-09-03. Their
briefs are deleted and their outcomes live in the artifacts they changed,
per the [lifecycle](#lifecycle) below.
`git log -p -- docs/handoffs/execute/README.md` has every row the table
held, if a closed decision ever needs re-reading.

## Every brief takes a worktree

Decided 2026-09-29, in `worktree-per-brief.md`: every brief is worked in
a worktree named after it, not only one worked in parallel, since whether
work runs in parallel shows only after it starts, and only a worktree
claims a brief in the view. Root `CLAUDE.md` § "Branching and concurrent
sessions" holds the rule, and its ledger that day's evidence; what a
session must know around it is here.

**A brief's evidence is re-measured before its worktree is entered.** The
guard refused three read-only commands against client repos that day: a
`git -C` there, a `find` naming `.git` in its filter, and one it called
too complex to verify, while Glob, Grep and a plain `find` ran; a fourth,
during `/commit`, was a git command beside a shell variable, which the
session split. So the session measures from the main checkout first,
rather than route around the guard, and `EnterWorktree` fits that order;
`claude --worktree` suits a brief whose evidence needs no git outside
this repo.

**A check that needs the deployed payload runs after the merge, on
`main`**, since a worktree cannot reach it:

- a skill in a deployed group, listed by
  `ls skills/workflow skills/social skills/meta`: `~/.claude/skills`
  junctions the main checkout's copy and user scope outranks project
  scope, so a probe from a worktree tests `main`'s version with nothing
  said, and `/test-skill` stops at step 7 there;
- anything under `claude/` checked only once deployed, and `/test-skill`
  step 7, since `link-claude.ps1` refuses a linked worktree (`ac3d22e`).

A probe script runs in the worktree: `test-activation.ps1` and
`test-semantic-model-audit.ps1` mark the probe root they deploy into and
unlink its junctions in a `finally`, so `link-claude.ps1` admits a linked
worktree for that `-ClaudeDir` alone (root ledger, 2026-09-29). Run from
this brief's worktree, `test-activation.ps1 -Set pbip` junctioned 45
skills from the worktree's `skills/` and passed 16 of 16 fixtures.

A skill in `.claude/skills/` needs none of this, since a worktree loads
its own copy (root ledger, probe 6, 2026-09-24). The edit still goes in
the worktree: in the main checkout a save to a deployed group's skill is
live machine-wide at once, half-finished states included, while a
worktree lets nothing out until the whole edit lands. Staying there would
have kept unverified work out of `main`'s history only, and the history
already takes it: `land`'s four edits landed at 09:44–09:46 local that
day and `c0283d9` stamped their behaviour at 11:17, while
`skill-status.py --stale` tracks the gap. Nor could a probe stand in,
since `test-activation.ps1` deploys only `fabric` and `powerbi`, into its
probe's project scope, and leaves user scope alone. So the worktree
stays, holding the claim, and the brief stays, holding the check, until
the check passes; a fix goes forward on `main`.

**The view says how a worktree holds its brief**, from its lock and its
branch (2026-09-29). `held` is a lock whose pid is alive, or a lock that
names no pid: a session is at work there. `merged` is a branch that
committed and that the main checkout's `HEAD` contains: a brief waiting
on its check on `main`, as above. `parked` is anything else, work left
unlanded or never begun, to resume rather than start again. A lock whose
pid is gone, a crashed session's, adds `lock stale`, and
`/prune-branches` proposes the unlock. Ancestry alone would say `merged`
of a branch that never committed, which sits under `main` too, so the
branch's oldest reflog entry, where it was created, must differ from its
tip. `tests/scripts/handoff-status/` plants each case; against the
script before this change, those six failed and the other 34 passed.

## A brief's worktree lands without a push

Decided 2026-09-29, in `land-rework.md`: a brief worked in a worktree
lands from the main checkout by a fast-forward, with no push, while
`/land` stays the outward route, pushing and opening a PR. Serial work
here commits to `main` and pushes only when asked, and a worktree
branches from local `HEAD`, so `/land` would have published the branch
with every unpushed serial commit beneath it: `main` stood 4 commits
ahead of `origin` that day. Only this repo lands this way, so the
commands live in [../CLAUDE.md](../CLAUDE.md), and `/land` step 1 defers
to a repo's instructions that land without a push.

Measured that day in a scratch clone, on git 2.55.0 and Claude Code
2.1.282: from the main checkout `git merge --ff-only <branch>` refused,
`Not possible to fast-forward`, once `main` had moved, and
`git -C <worktree> rebase main` let it through; `git worktree remove`
refused a dirty tree and removed a clean one, after which
`git branch -d` deleted the branch. `ExitWorktree` `keep` returned a
`claude --worktree` session to the main checkout, though its description
scopes it to `EnterWorktree`, and released the worktree's lock, so that
session removed the worktree itself. At `/exit` a worktree holding
commits is offered keep or remove, and remove deletes the branch
(code.claude.com/docs/en/worktrees, read that day).

**The landing checks the rebased tree.** No hook runs on a rebase
or a fast-forward, and each whole-set check in `.pre-commit-config.yaml`
runs only when a file it matches is staged, so the tree a rebase builds
is one that nothing checked. Measured 2026-09-29 on git 2.55.0, in a
scratch clone at `e0fc29f`, where root `CLAUDE.md` stood at 199 lines of
its 200: two worktree branches each added one line and each passed
`lint-claude-md` at 200, and the second rebased onto the first with no
conflict, stood at 201 and still fast-forwarded. In that worktree,
`pre-commit run --all-files` failed that one hook, in 7 seconds.
`lint-briefs` meets the same case when one branch lands a brief that
another names in `blocked-by`. In a scratch repo, a pre-commit hook ran
once per commit and not at all on the rebase or the fast-forward.

**The rebase also rewrites the branch's SHAs**, and a stale one still passes
`git cat-file -e`: the pre-rebase SHA did, after `git worktree remove`
and `git branch -d` too, while `git merge-base --is-ancestor` exited 1
for it and 0 for the one that landed. The first brief landed this way,
`fabric-alter-table-and-serialization-gaps`, reworded its closing
commit after its rebase, and all six SHAs it cites are on `main`; but
it checked them with `cat-file -e`, which would have passed stale ones
as well (transcript `1c8ba406`).

**So a `/test-skill` stamp waits for the merge**, as a deployed-payload
check does: `skill-status.py --stamp` records `HEAD`'s SHA, so a stamp
taken in the worktree names a commit the rebase rewrites whenever `main`
has moved. A walkthrough retest did exactly that, noted in `b4e097b`'s
message, and the user decided the same day, 2026-09-29, that
`/test-skill` step 10 stamps on `main` once the fast-forward lands, with
the brief deleted in that commit.

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
