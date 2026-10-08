# Drift audit ledger

One directory per audit run: `docs/audits/<audit-date>/<source-id>/`,
holding the audit report verbatim as `00-audit-report.md` plus the
numbered briefs `/drift-handoff` derived from it.

These are **tracked**, and kept until a later run supersedes them. A
directory is written once, executed once and stamped brief by brief. A
brief whose log leaves nothing open moves into the directory's
`completed/`, so its top lists only what is still unrun or open. Once
nothing in a run is open and a later run of its source exists, the run
is retired, deleted whole, with git history keeping it
([below](#retiring-a-run)).

## Lifecycle

| Stage | Skill | What lands here |
| --- | --- | --- |
| Audit | `/drift-audit` | nothing — findings only, emitted to the conversation |
| Handoff | `/drift-handoff` | the directory: `00-audit-report.md` + `NN-*.md` briefs + a generated `README.md` index |
| Execute | `/drift-update` | an execution log appended to each brief it runs, the index regenerated, and each finished brief moved into `completed/` |
| Commit | `/commit` | the directory, then the stamps alongside the edits they describe |
| Sweep | `/triage <directory>` | a `**Closed**:` line on each open follow-up it settles, saying where its work went, and the index regenerated |
| Retire | `/triage <directory>`, offered by `/drift-handoff` | the directory deleted, once every brief is finished and a later run of its source exists |

Commit the directory **before** executing it, even when the same
session will go straight on to `/drift-update`. An unexecuted directory
in git is what a second machine picks up, and it is the only state in
which the briefs are provably readable cold. A pass's worktree branches
from that commit too (`/drift-update` step 2).

## Prompt-audit runs

A `/doctor prompt-audit` run is recorded here too, as
`docs/audits/<date>/prompt-audit/`: its report verbatim as
`00-audit-report.md`, its proposed patch as `prompt-audit.patch`, and
briefs in `/drift-handoff`'s format, written by hand, since
`/drift-handoff` reads only a `/drift-audit` report. A prompt audit
reads the whole payload, not a diff, so its window has no floor, and
`/drift-update` executes its briefs like any other run's. Run one after
a heavy stretch of payload edits, not per change: it finds what no hook
or drift audit checks for, at a cost the first run's record gives.
Decided by the user on 2026-10-08, closing
[brief 10](2026-10-06/claude-code/completed/10-trial-prompt-audit-and-skill-doctor.md)
of the 2026-10-06 `claude-code` run, whose log has that cost.

## Why this is tracked

It was gitignored until 2026-09-07, on the stated rationale that audit
output is regenerable — re-run the audit and it comes back. Two things
were wrong with that.

**Regenerable was false.** The same day, `MicrosoftDocs/powerbi-docs`
returned 404 at the API, web, and raw endpoints — no redirect, so not a
rename (commit `9e3d857`). The run already on disk quoted
content that could no longer be fetched from its canonical source. An
audit report is a snapshot of an upstream that moves and sometimes
disappears; that is the definition of something worth committing.

**The pipeline is three sessions and the ignore made it one machine.**
`/drift-update` is deliberately built to run cold — it reads briefs from
disk, never from the conversation, and skips ones already stamped so an
interrupted run resumes. Gitignoring its input cancelled that: the
handoff had to be executed on the filesystem that produced it. Tracking
is what makes audit → handoff → update portable.

The secondary gain is the findings that *never* become briefs.
Executed work leaves its outcome in the artifacts it changed and in the
commit message, so that half was never really lost. Undrilled bucket
entries, retractions, and explicit no-action calls had no other home,
and they are exactly what stops a later audit re-litigating a decision.

## Reading an old directory

- **Start at the directory's `README.md`.** It is one table, a row per
  brief with the actions it covers, its Kind and its status, generated
  by `scripts/audit-status.py` from the briefs' own metadata blocks and
  execution logs. It is never edited by hand — the `lint-audit-index`
  pre-commit hook fails a commit whose index disagrees with its briefs —
  so it is a derived view of the logs and not a second copy of them. An
  open row — escalated, deferred or applied with deferrals — links to the
  follow-up queue, which `handoff-status.py` prints from each open log's
  `**Needs**:` line; a `closed` date means a
  later session discharged the brief and recorded it with a `**Closed**:`
  line in the log. Added 2026-09-13, after eleven briefs in one directory
  meant eleven files to open to learn which had run.
- **What sits at the top is still open.** When it regenerates the index,
  `audit-status.py` moves each brief whose log leaves nothing open —
  applied, already-applied or closed — into the directory's
  `completed/`, and `lint-audit-index` fails a commit with one on the
  wrong side, so the folder is derived like the table. A move breaks
  any path naming the old place: re-point a live reference in the same
  commit, and leave a stamped brief's text as written. Added 2026-10-06,
  so the file tree shows which briefs still need a session without
  opening the index.
- **`/drift-update` with no argument takes the most recent date
  directory.** Retention does not change that, but it does mean older
  directories are now sitting there to be named explicitly. Pass a path
  when you mean an older run.
- **Re-measure before acting on an old brief.** Briefs quote evidence —
  greps, file paths, upstream line numbers — that rots, sometimes within
  hours, and a repo reorganization can invalidate every path in a
  directory at once. A stamped brief is history; an unstamped one in an
  old directory is a claim to re-check, not an instruction.
- **An old directory's open follow-ups sweep into the queue.**
  `/triage docs/audits/<date>` re-measures each, gives it one verdict,
  carries what is still worth doing to `docs/handoffs/execute/`, where a
  brief has a priority and a deferral, and closes it here with a
  `**Closed**:` line saying where its work went. `completed/` then
  means nothing is left in this ledger, not that the work is done.
  Added 2026-10-07, when ten September follow-ups had gone untouched
  since 2026-09-27.
- **`gitleaks` scans this directory.** `docs/` used to be allowlisted
  wholesale in [`.gitleaks.toml`](../../.gitleaks.toml); that entry was
  removed when this became tracked, because audit reports quote upstream
  code samples verbatim and a blanket allowlist would have left them
  unscanned. If a legitimate quote ever trips a rule, allowlist that
  path rather than the tree.

## Retiring a run

A run is retired, its directory deleted whole, once every brief in it
is finished and a later run of the same source exists.
`uv run scripts/audit-status.py --retirable` lists each, and the queue
view prints the same list. `/drift-handoff` offers the runs its new run
supersedes, and `/triage` retires them on the user's yes, after their
closing commit, re-pointing live links to the commit that last held
them (`.claude/skills/triage/references/audit-follow-ups.md` § 8).

**The newest run of each source stays**, finished or not. The next audit
of that source starts from it, as the 2026-10-06 `powerbi` run took its
floor from the 2026-09-07 directory, and its no-action calls are the
freshest record of what was decided.

Decided by the user on 2026-10-08. Until then this section held that a
ledger, unlike [`docs/handoffs/execute/`](../handoffs/execute/), keeps
every entry, since an entry's value survives its execution. That value
survives in git: deleting a committed directory loses no byte, which is
what [Why this is tracked](#why-this-is-tracked) was about, so a
finished run now follows the queue's rule, git history its archive.
What retiring gives up is grep: a search of `docs/audits/` no longer
sees a retired run's decisions, though `git log -S` still does. Read a
retired run back with:

```bash
git log --diff-filter=D --format=%h -1 -- docs/audits/<date>/<source-id>
git show <that-sha>^:docs/audits/<date>/<source-id>/00-audit-report.md
```
