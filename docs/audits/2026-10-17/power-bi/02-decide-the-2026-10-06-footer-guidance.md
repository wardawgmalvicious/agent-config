# Handoff: decide the 2026-10-06 footer guidance

- **Audit run**: 2026-10-17
- **Source**: `power-bi`
- **Window**: floor `0e80b00b` (2026-08-25, the 2026-10-06 run's head) →
  head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 2
- **Kind**: decision on one line of a verbatim audit report, not an
  edit, and it waits on brief 01. No payload or behaviour changes.
- **Target**: `docs/audits/2026-10-06/power-bi/00-audit-report.md`

## The problem

The 2026-10-17 report's action 2 reads: "**`2026-10-06/power-bi/00-audit-report.md`
footer** — once action 1 lands, its "re-run once the title moves past
August" guidance is superseded by the new entry." The line it names,
`:62`, reads:

> A SHA from any registered source's repo, or any ISO date, is
> accepted. Re-run once Learn's What's New title moves past August 2026.

If brief 01 re-points the source, that sentence no longer says when a
run is due. The action names no edit, so what happens to the line is
put to the user.

## Evidence

Three facts bound the choice, each as of 2026-10-17:

- **The file is verbatim.** `/drift-handoff` § 3 writes a run's report
  to `00-audit-report.md` verbatim, "exactly as emitted", and
  `docs/audits/README.md:4` describes each run directory as "holding the
  audit report verbatim".
- **No run reads its footer any more.** `/drift-audit` § 2 takes a
  no-argument floor from the newest run of each source, which from this
  directory's commit is `docs/audits/2026-10-17/power-bi/`. That
  report's footer already carries the guidance with the condition added:
  "Re-run once Learn's title moves past August 2026, or once action 1
  re-points the source."
- **The run is retirable.** Both of its briefs sit under `completed/`,
  and `docs/audits/README.md` § Retiring a run retires a run "once every
  brief in it is finished and a later run of the same source exists".
  `/drift-handoff` step 7 asks about it after this directory's commit,
  and `/triage` deletes it on the user's yes.

## The decision

Put to the user; never executed.

1. **As the action reads**: mark the footer superseded once brief 01
   lands, in words the user approves; the action proposes none. This
   edits a verbatim file.
2. **Leave it**: the newest footer governs, and an older report's
   superseded footer is the ledger as written.
3. **Retire the run**, through `/triage`, which deletes the file and the
   question with it.

A yes to retiring at step 7's prompt settles this brief as option 3,
before brief 01 is decided.

## Verification

1. The choice, in this brief's execution log.
2. Option 1:
   `git diff --numstat -- docs/audits/2026-10-06/power-bi/00-audit-report.md`
   — the approved lines added, `0` deleted unless the user chose to
   reword one.
3. Option 3: `ls docs/audits/2026-10-06/power-bi` fails, and
   `uv run scripts/audit-status.py --check` passes.
4. `pre-commit run --all-files`.

## Sequencing note

Waits on brief 01's choice, unless the run is retired first. Not
bundled with brief 01: another file, another verification, and a target
that is a verbatim report.

## Provenance

Recommended action 2 of the 2026-10-17 `/drift-audit power-bi` run,
written as a consequence of action 1. The three facts under Evidence
were gathered by `/drift-handoff` while writing this brief, not by the
audit.
