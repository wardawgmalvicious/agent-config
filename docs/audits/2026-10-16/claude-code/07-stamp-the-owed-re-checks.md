# Handoff: stamp the re-checks this audit owed

- **Audit run**: 2026-10-16
- **Source**: `claude-code`
- **Window**: floor `fbe20e00` (2026-10-06, the 2026-10-06 run's head) →
  head `c017428c` (2026-10-16)
- **Covers recommended actions**: 9
- **Kind**: bookkeeping in the committed dated ledger. Two execution logs
  gain at most one appended line each, a `**Closed**:` on one and a
  fresh `**Needs**:` on the other unless another run's stamp has written
  it; no guidance, payload or behaviour changes. Edits only, with
  nothing to decide.
- **Target**: two briefs in `docs/audits/2026-10-06/claude-code/`,
  numbered under Evidence, and the `README.md` that `audit-status.py`
  generates there

## Context

The 2026-10-16 `claude-code` audit owed two re-checks: the open
`**Needs**:` lines under `docs/audits/` that name the next
`claude-code` drift audit, or any drift audit. Its report gives each an
outcome under `## Owed re-checks`: one passed its read and failed on a
figure, which brief 03 corrects, and one passed half its check. Neither
log says so yet, and the next audit, `handoff-status.py` and the audit
indexes all read those logs to learn what still waits, and on what.

Target 2 is owed to the 2026-10-16 `fabric` run as well. That run's
stamp, `docs/audits/2026-10-16/fabric/02-stamp-the-owed-re-checks.md`,
target 6, appends the same outcome, and was unexecuted when this brief
was written.

## Evidence

A log's counting line is its last `**Needs**:` line, the one
`/drift-update` and `/drift-audit` § 2 both read. Line numbers are as of
2026-10-16.

### Target 1 — the corrected registry entry

`docs/audits/2026-10-06/claude-code/01-repair-claude-code-registry-entry.md`,
log at `:105`, `**Executed**: 2026-10-07 — applied with deferrals`.
Counting line, `:133`:

> - **Needs**: the next claude-code drift audit — reading the corrected
>   entry is the behavioural check; and the Size bullet's "~1.2 MB" for
>   two full files, which predates the 945 KB head and was unbriefed here.

Passed on the read: the run took its filter, its slice size and its
rule to read the diff's removed lines from the entry, and found 0
removed lines. Failed on "~1.2 MB": the two refs total 1,991,789 bytes,
945,458 at `fbe20e00` and 1,046,331 at `c017428c`. Brief 03 carries the
correction. The line waits on nothing else.

### Target 2 — drift-audit's tool premises

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
`references/sources/` directory listed all six registry entries, on CLI
2.1.301. § 4b: not in this window, since the run took the clone path.
The `fabric` run reported the same two outcomes the same day.

## What to change

Append to each log after its last bullet, and rewrite nothing above it.
The earlier lines were accurate when written, and only a log's last
`**Needs**:` line counts, so a fresh one supersedes without an edit.
Each new line names this run's directory,
`docs/audits/2026-10-16/claude-code/`.

1. **Target 1**: a `**Closed**: 2026-10-16 —` line. The claude-code
   drift audit of that date read the corrected entry and ran on it; the
   "~1.2 MB" figure failed, the two refs totalling 1,991,789 bytes, and
   `docs/audits/2026-10-16/claude-code/03-repair-claude-code-registry-entry.md`
   carries the correction.
2. **Target 2**: read the log's last line first.
   - If the `fabric` stamp's 2026-10-16 `**Needs**:` line is already
     there, append nothing: it records the same outcome from the same
     day, and a second line would stamp the log twice. Say so in this
     brief's execution log.
   - Otherwise append a fresh `**Needs**:` line opening "the next drift
     audit that falls back to WebFetch —", the wording the `fabric`
     stamp uses, for § 4b's completeness check alone: that it catches
     the `[WebFetch note: …]` and the summarization tells. Say that
     § 1's half passed on 2026-10-16 in this run, on CLI 2.1.301, when
     the slash-free `Glob` listed all six registry entries, and that
     the run took the clone path.
3. **Regenerate the index**:

   ```bash
   uv run scripts/audit-status.py --dir docs/audits/2026-10-06/claude-code
   ```

   Only target 1 moves, into
   `docs/audits/2026-10-06/claude-code/completed/`. Then run
   `git grep -n 01-repair-claude-code-registry-entry.md` and re-point
   any live path. On 2026-10-16, before this directory was written, it
   named only that directory's generated `README.md`, which the
   regeneration rewrites. This directory's `00-audit-report.md` and
   this brief name it too, as it stood: the report is verbatim and this
   brief's text is its own, so neither is re-pointed.

## Constraint on the fix

- **No `**Closed**:` on target 2.** `audit-status.py` reads a
  `**Closed**:` line anywhere in a log as closing the brief, and files
  it under `completed/`; target 2 still waits on half its check.
- **Edit nothing else.** The registry correction is brief 03's.

## Verification

1. `grep -n '2026-10-16' docs/audits/2026-10-06/claude-code/completed/01-repair-claude-code-registry-entry.md docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`
   — the first path exists and prints its `**Closed**:` line; the
   second prints one 2026-10-16 `**Needs**:` line, this run's or the
   `fabric` run's, never two.
2. `git diff --numstat -- docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`
   — `0` in the deletions column, or no output where step 2's first
   case applied. For target 1,
   `git show HEAD:docs/audits/2026-10-06/claude-code/01-repair-claude-code-registry-entry.md | diff --strip-trailing-cr - docs/audits/2026-10-06/claude-code/completed/01-repair-claude-code-registry-entry.md`
   — only `>` lines.
3. `grep -c '^- \*\*Closed\*\*:' docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`
   — `0`.
4. `uv run scripts/handoff-status.py` — target 1 gone from the open
   list, target 2 under its WebFetch line.
5. `uv run scripts/audit-status.py --check`.
6. `pre-commit run --all-files`.

## Sequencing note

Last in this directory, as a stamp brief always is. It names brief 03
as carrying target 1's correction and does not wait for it. If the
`fabric` stamp is still pending, running it first leaves this brief
nothing to append to target 2. Run the other way round, the `fabric`
stamp's target 6 finds this run's line last, and should append nothing
either.

## Provenance

Recommended action 9 of the 2026-10-16 `/drift-audit claude-code` run.
Its § 2 listed every open `**Needs**:` line under `docs/audits/` outside
`completed/`, kept the last in each file, and kept the two that name the
next `claude-code` drift audit or any drift audit; `00-audit-report.md`
§ Owed re-checks holds each outcome. `/drift-handoff` § 4 writes this
brief whenever a report lists owed re-checks, since stamping records
outcomes the audit already reached.
