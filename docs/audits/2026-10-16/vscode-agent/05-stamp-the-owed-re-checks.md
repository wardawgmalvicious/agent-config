# Handoff: stamp the re-check this audit owed

- **Audit run**: 2026-10-16
- **Source**: `vscode-agent`
- **Window**: floor `c642b585` (2026-10-01, the 2026-10-06 run's head) →
  head `e6026c88` (2026-10-16)
- **Covers recommended actions**: 6
- **Kind**: bookkeeping in the committed dated ledger. One execution log
  gains at most one appended line, a fresh `**Needs**:`, unless another
  2026-10-16 run's stamp has written it; no guidance, payload or
  behaviour changes. Edits only, with nothing to decide.
- **Target**: `docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`,
  and the `README.md` that `audit-status.py` generates beside it

## Context

The 2026-10-16 `vscode-agent` audit owed one re-check: the open
`**Needs**:` line under `docs/audits/` that names any drift audit. Its
report gives the outcome under `## Owed re-checks`: half passed. The log
does not say so yet, and the next audit, `handoff-status.py` and the
audit indexes all read it to learn what still waits, and on what.

The same line is owed to that day's `claude-code` and `fabric` runs.
Their stamps,
`docs/audits/2026-10-16/claude-code/07-stamp-the-owed-re-checks.md`
target 2 and `docs/audits/2026-10-16/fabric/02-stamp-the-owed-re-checks.md`
target 6, append the same outcome, and were unexecuted when this brief
was written.

The report also lists
`docs/audits/2026-10-06/vscode-agent/04-decide-vscode-agent-source-scope.md`,
owed to the user rather than to an audit; it needs no stamp here.
Brief 03 in this directory carries its decision and closes its log.

## Evidence

A log's counting line is its last `**Needs**:` line, the one
`/drift-update` and `/drift-audit` § 2 both read. Line numbers are as of
2026-10-16.

`docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`,
log at `:94`, `**Executed**: 2026-10-07 — escalated (both probes to a
session of their own)`. Counting line, `:135`:

> - **Needs**: the next `/drift-audit` run — the behavioural check alone,
>   as the line above says. Its two adjacent findings were fixed
>   2026-10-08 at the user's word, in the commit that adds this line: …

The line above, `:117`, defines the check: "that § 1's slash-free
`Glob` lists the registry, and, only on a run that falls back to the
WebFetch path, that § 4b's completeness check catches the note and the
tells."

Half passed. § 1: `Glob` with pattern `*.md` and `path` the skill's
`references/sources/` directory listed all six registry entries, in a
VS Code extension session whose CLI version was not read. § 4b: not in
this window, since the run took the clone path and no WebFetch fallback
ran.

## What to change

Read the log's last line first.

- If a 2026-10-16 `**Needs**:` line opening "the next drift audit that
  falls back to WebFetch —" is already there, from the `claude-code` or
  the `fabric` stamp, append nothing: it records the same outcome from
  the same day, and another line would stamp the log twice. Say so in
  this brief's execution log.
- Otherwise append, after the last bullet and rewriting nothing above
  it, a fresh `**Needs**:` line opening "the next drift audit that falls
  back to WebFetch —", the wording both other stamps use, for § 4b's
  completeness check alone: that it catches the `[WebFetch note: …]` and
  the summarization tells. Say that § 1's half passed on 2026-10-16 in
  `docs/audits/2026-10-16/vscode-agent/`, when the slash-free `Glob`
  listed all six registry entries, and that the run took the clone
  path.

Then regenerate the index:

```bash
uv run scripts/audit-status.py --dir docs/audits/2026-10-06/claude-code
```

Nothing moves: brief 11 still waits on half its check.

## Constraint on the fix

- **No `**Closed**:` line.** `audit-status.py` reads one anywhere in a
  log as closing the brief, and files it under `completed/`; brief 11
  still waits on § 4b.
- **Edit nothing else.**

## Verification

1. `grep -n '2026-10-16' docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`
   — one 2026-10-16 `**Needs**:` line, this run's or another 2026-10-16
   stamp's, never two.
2. `git diff --numstat -- docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`
   — `0` in the deletions column, or no output where nothing was
   appended.
3. `grep -c '^- \*\*Closed\*\*:' docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`
   — `0`.
4. `uv run scripts/handoff-status.py` — brief 11 under its WebFetch
   line.
5. `uv run scripts/audit-status.py --check`.
6. `pre-commit run --all-files`.

## Sequencing note

Last in this directory, as a stamp brief always is; it waits on none of
briefs 01 to 04. Of the three 2026-10-16 stamps on brief 11, whichever
runs first writes the line, and the other two append nothing.

## Provenance

Recommended action 6 of the 2026-10-16 `/drift-audit vscode-agent` run.
Its § 2 listed every open `**Needs**:` line under `docs/audits/` outside
`completed/`, kept the last in each file, and kept the one that names
any drift audit; `00-audit-report.md` § Owed re-checks holds the
outcome. `/drift-handoff` § 4 writes this brief whenever a report lists
owed re-checks, since stamping records outcomes the audit already
reached.
