# Handoff: stamp the re-checks this audit owed

- **Audit run**: 2026-10-17
- **Source**: `power-bi`
- **Window**: floor `0e80b00b` (2026-08-25, the 2026-10-06 run's head) →
  head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 3
- **Kind**: bookkeeping in the committed dated ledger. Two execution logs
  gain at most one appended line between them, and none while the
  2026-10-16 stamps carrying the same outcomes are pending; no guidance,
  payload or behaviour changes. Edits only, with nothing to decide.
- **Target**: two briefs, numbered under Evidence, and the `README.md`
  that `audit-status.py` generates beside the second

## Context

The 2026-10-17 `power-bi` audit owed two re-checks: the open
`**Needs**:` lines under `docs/audits/` that name the next `power-bi`
drift audit, under its old id `powerbi`, or any drift audit. Its report
gives each an outcome under `## Owed re-checks`: target 1 was not in
this window, and target 2 half passed.

Neither outcome is new. Three 2026-10-16 runs reported on the same two
lines, and their stamps were unexecuted on 2026-10-17:

| Stamp | Target 1 | Target 2 |
| --- | --- | --- |
| `docs/audits/2026-10-16/fabric/02-stamp-the-owed-re-checks.md` | its target 5: a `**Closed**:` line, passed | its target 6: a fresh `**Needs**:` |
| `docs/audits/2026-10-16/claude-code/07-stamp-the-owed-re-checks.md` | — | its target 2: the same line, unless written |
| `docs/audits/2026-10-16/vscode-agent/05-stamp-the-owed-re-checks.md` | — | the same line, unless written |

So this brief records this run's outcomes and, in the expected order,
appends nothing: a second line would stamp a log twice.

## Evidence

A log's counting line is its last `**Needs**:` line, the one
`/drift-update` and `/drift-audit` § 2 both read. Line numbers are as of
2026-10-17.

### Target 1 — the skill-match reading

`docs/audits/2026-10-08/prompt-audit/02-point-drift-audit-at-the-repo-skill-trees.md`,
log at `:87`, `**Executed**: 2026-10-08 — applied with deferrals`, with
no `**Closed**:` line. Counting line, `:153`:

> - **Needs**: the next `/drift-audit` of `fabric` or `powerbi`, for step
>   6's skill-match reading on a real diff; the retest is done.

Its step 6, `:77`: "Not gating: the next `/drift-audit` of `fabric` or
`powerbi` should map a change to an existing platform skill as a skill
match."

Not in this window: zero landings, so no entry to map. The 2026-10-16
`fabric` run passed it on a real diff
(`docs/audits/2026-10-16/fabric/00-audit-report.md:53-56`), and that
run's stamp closes the log.

### Target 2 — drift-audit's tool premises

`docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`,
log at `:94`, `**Executed**: 2026-10-07 — escalated (both probes to a
session of their own)`. Counting line, `:135`:

> - **Needs**: the next `/drift-audit` run — the behavioural check alone,
>   as the line above says. …

The line above, `:117`, defines the check: "that § 1's slash-free
`Glob` lists the registry, and, only on a run that falls back to the
WebFetch path, that § 4b's completeness check catches the note and the
tells."

Half passed. § 1: `Glob` with pattern `*.md` and `path` the skill's
`references/sources/` directory listed all five registry entries, one
fewer than on 2026-10-16 since `34618f8` retired `skills-for-fabric`, in
a VS Code extension session whose CLI version was not read. § 4b: not
in this window, since the run took the entry's own fetch, a `curl` of
Learn's page, and no WebFetch fallback ran.

## What to change

Read each log's last lines first. Append only after the last bullet,
rewriting nothing above it.

1. **Target 1: append nothing.** If its `**Closed**: 2026-10-16` line is
   there, with the brief moved under `completed/`, the check is closed,
   and a not-in-this-window line after a pass would contradict it. If it
   is not, the `fabric` stamp is pending and writes it; a `**Needs**:`
   line first would sit above the pass that settles it. If that stamp
   has an execution log and the line is still missing, stop and ask.
2. **Target 2**, first match wins:
   - The log's last line is a `**Needs**:` opening "the next drift audit
     that falls back to WebFetch —": append nothing. It records this
     run's outcome a day earlier.
   - Any of the three 2026-10-16 stamps is unexecuted, which
     `grep -L '^- \*\*Executed\*\*:'` on their three paths lists: append
     nothing. The first of them to run writes the line, and their
     conditions look for a 2026-10-16 line, so a 2026-10-17 one now
     could have one of them write a second.
   - Otherwise append a fresh `**Needs**:` line opening "the next drift
     audit that falls back to WebFetch —", for § 4b's completeness check
     alone: that it catches the `[WebFetch note: …]` and the
     summarization tells. Say that § 1's half passed on 2026-10-17 in
     `docs/audits/2026-10-17/power-bi/`, listing five registry entries,
     and that the run took the entry's own fetch.
3. **Regenerate the index** only where a line was appended:

   ```bash
   uv run scripts/audit-status.py --dir docs/audits/2026-10-06/claude-code
   ```

   Nothing moves: brief 11 still waits on § 4b.

Record in this brief's execution log which case each target met, and
which stamp carried its line.

## Constraint on the fix

- **No `**Closed**:` on target 2.** `audit-status.py` reads one anywhere
  in a log as closing the brief, and files it under `completed/`; brief
  11 still waits on § 4b.
- **Run no other stamp from here, and edit nothing else.** The
  2026-10-16 stamps are their own briefs.

## Verification

1. `grep -c '^- \*\*Closed\*\*:' docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`
   — `0`.
2. `grep -c '^- \*\*Needs\*\*: the next drift audit that' docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`
   — `0` or `1`, never `2`.
3. `git diff --numstat -- docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`
   — `0` in the deletions column, or no output where nothing was
   appended.
4. `git diff --stat -- docs/audits/2026-10-08/prompt-audit` — empty,
   unless the `fabric` stamp ran in the same session.
5. `uv run scripts/audit-status.py --check`.
6. `pre-commit run --all-files`.

## Sequencing note

Last in this directory, as a stamp brief always is; it waits on neither
brief 01 nor 02. Best run after the three 2026-10-16 stamps, when both
targets already carry their lines and this brief records that. Run
before them, it still appends nothing while any is pending.

## Provenance

Recommended action 3 of the 2026-10-17 `/drift-audit power-bi` run. Its
§ 2 listed every open `**Needs**:` line under `docs/audits/` outside
`completed/`, kept the last in each file, and kept the two that name the
next `power-bi` drift audit or any drift audit; `00-audit-report.md`
§ Owed re-checks holds each outcome. `/drift-handoff` § 4 writes this
brief whenever a report lists owed re-checks. Target 1 departs from its
fresh `**Needs**:` for a re-check not in the window, since the
2026-10-16 `fabric` run had already passed that one.
