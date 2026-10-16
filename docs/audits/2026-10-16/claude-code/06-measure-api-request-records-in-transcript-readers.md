# Handoff: measure api-request records in two transcript readers

- **Audit run**: 2026-10-16
- **Source**: `claude-code`
- **Window**: floor `fbe20e00` (2026-10-06, the 2026-10-06 run's head) →
  head `c017428c` (2026-10-16)
- **Covers recommended actions**: 7 and 8
- **Kind**: an **investigation**: measure what 2.1.300's new transcript
  records cost two scripts that parse every transcript they scan, then,
  only if it matters, a small edit to each. Both sit in deployed skill
  groups, so a saved edit is live machine-wide at once. `/drift-update`
  puts an investigation back to the user rather than executing it.
- **Target**: `skills/workflow/find-session/scripts/find-session.py`
  (record loop, lines 118–139),
  `skills/meta/scope-instructions/scripts/folder-sessions.py` (record
  loop, lines 272–293)

## The problem

Since 2.1.300 Claude Code writes each API request's system prompt, tools
and parameters into the local session transcript. `find-session.py` and
`folder-sessions.py` hand every line of every transcript they scan to
`json.loads`, then dispatch on `type` and pass over types they do not
know. Their results are unaffected. Their cost grows with whatever the
new records weigh, and nobody has measured that.

## Evidence

**Changelog**, `anthropics/claude-code` `CHANGELOG.md` at head
`c017428c8c27e604840435048d5bce6a9a22c040`, 2.1.300, verbatim:

> - Changed local session transcripts to also record each API request's
>   system prompt, tools and parameters, so a transcript you choose to
>   share can reproduce a request exactly

**One transcript.** In the audit session's own transcript, on CLI
2.1.301, a Grep on 2026-10-16 found `"api-request"` on lines 31, 55 and
76 and `"systemPrompt"` on lines 23 and 41. Line 31 opens
`{"type":"api-request"`. Record sizes were not measured, nor whether a
system prompt is written with every request or only when it changes.

**The loops.**

- `find-session.py:118–136`: `for line in fh:`, then
  `rec = json.loads(line)`, skipping a `ValueError` or a non-dict, then
  `kind = rec.get("type")`; it acts on `custom-title`, `ai-title` and
  `user`.
- `folder-sessions.py:270–289`: the same parse, then
  `kind = rec.get("type")`; it acts on `system` with subtype
  `compact_boundary`, and on `user`.

## What to change

1. **Measure.** Over the transcripts under `~/.claude/projects/` written
   on 2.1.300 or later: the share of their bytes in `api-request`
   records, and whether `systemPrompt` repeats per request. Then time
   each script, unchanged, on this machine's transcripts.
2. **Act on the numbers.** If the new records are a small share, record
   the measurement in this brief's execution log and change nothing. If
   they dominate, skip them before parsing in both scripts, for example
   a line opening `{"type":"api-request"` passed over ahead of
   `json.loads`, and time both again.

## Constraint on the fix

- A skip must never drop a record either script reads. That `type` is a
  record's first key is how one 2.1.301 transcript wrote it, not a
  documented format, so key a skip on that exact prefix, and send every
  other line through `json.loads` as now.
- These two scripts only. Other transcript readers in this repo, among
  them `scripts/skill-telemetry.py`, `scripts/activation-expect.py` and
  `claude/hooks/prune-probe-sessions.py`, were not assessed by the
  audit and stay out of this brief.
- Each skill under `skills/` is a junction from `~/.claude/skills`, so
  a save is live in every session at once: run each script's suite
  straight after saving it.

## Verification

1. The measurement in this brief's execution log: transcript count, CLI
   versions, byte share, and both timings.
2. `bash tests/scripts/find-session/test-find-session.sh`
3. `bash tests/scripts/folder-sessions/test-folder-sessions.sh`
4. If either script changed, `ruff check` on it.
5. `pre-commit run --all-files`.

## Provenance

Recommended actions 7 and 8 of the 2026-10-16 `/drift-audit claude-code`
run, which met the records in its own transcript while checking the
harness changes. The report's "each request now adds a full system
prompt" follows the changelog's wording; whether the bytes bear it out
is the measurement's to say.
