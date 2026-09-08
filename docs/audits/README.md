# Drift audit ledger

One directory per audit run: `docs/audits/<audit-date>/<source-id>/`,
holding the audit report verbatim as `00-audit-report.md` plus the
numbered briefs `/drift-handoff` derived from it.

These are **tracked and kept**. A directory is written once, executed
once, stamped in place, and then left where it is as the dated record
of what upstream looked like that day.

## Lifecycle

| Stage | Skill | What lands here |
| --- | --- | --- |
| Audit | `/drift-audit` | nothing — findings only, emitted to the conversation |
| Handoff | `/drift-handoff` | the directory: `00-audit-report.md` + `NN-*.md` briefs |
| Execute | `/drift-update` | an execution log appended to each brief it runs |
| Commit | `/commit` | the directory, then the stamps alongside the edits they describe |

Commit the directory **before** executing it, even when the same
session will go straight on to `/drift-update`. An unexecuted directory
in git is what a second machine picks up, and it is the only state in
which the briefs are provably readable cold.

## Why this is tracked

It was gitignored until 2026-09-07, on the stated rationale that audit
output is regenerable — re-run the audit and it comes back. Two things
were wrong with that.

**Regenerable was false.** The same day, `MicrosoftDocs/powerbi-docs`
returned 404 at the API, web, and raw endpoints — no redirect, so not a
rename (commit `33425db`). The run already on disk quoted
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

- **`/drift-update` with no argument takes the most recent date
  directory.** Retention does not change that, but it does mean older
  directories are now sitting there to be named explicitly. Pass a path
  when you mean an older run.
- **Re-measure before acting on an old brief.** Briefs quote evidence —
  greps, file paths, upstream line numbers — that rots, sometimes within
  hours, and a repo reorganization can invalidate every path in a
  directory at once. A stamped brief is history; an unstamped one in an
  old directory is a claim to re-check, not an instruction.
- **`gitleaks` scans this directory.** `docs/` used to be allowlisted
  wholesale in [`.gitleaks.toml`](../../.gitleaks.toml); that entry was
  removed when this became tracked, because audit reports quote upstream
  code samples verbatim and a blanket allowlist would have left them
  unscanned. If a legitimate quote ever trips a rule, allowlist that
  path rather than the tree.

## Not the `execute/` rule

[`docs/handoffs/execute/`](../handoffs/execute/) briefs are deleted
individually when spent, and git history is their archive. That is the
right rule for a **queue**, where a spent row invites re-execution of
work already done. This directory is a **ledger**, where the date is the
index and the entry's value survives its execution. Deleting from a
queue is tidying; deleting from a ledger is losing the entry.
