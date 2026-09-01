#!/bin/bash
# Logs every InstructionsLoaded hook event to a local file as pure JSONL.
# Fires at session start for eagerly-loaded CLAUDE.md / rules files,
# and during a session for lazy-loaded (nested or path-matched) files.
# Pure observability: cannot block, exit code is ignored.
#
# Appends are NOT atomic here. Git Bash has no flock, and MSYS does not
# guarantee an atomic O_APPEND write on Windows, so two events firing at the
# same instant can tear a record — one log line holding a truncated object
# spliced into a whole one. Observed once in 1703 lines (2026-09-01). A lock
# is not worth it in a hook that fires dozens of times per session start and
# would wedge all logging if a lockdir ever went stale, so the tolerance
# lives in the READER instead: scripts/instructions-log parses line-at-a-time
# and drops what will not parse. Keep that reader-side guard if you change
# this writer.

INPUT=$(cat)
LOG="$HOME/.claude/logs/instructions-loaded.log"

mkdir -p "$(dirname "$LOG")"
TS=$(date -Iseconds)

# Bound jq's lifetime. jq reads stdin, so if this hook's shell dies mid-pipeline
# jq is left blocking on a stdin that never closes and holds the session's cwd
# indefinitely -- enough to block a rename of any ancestor directory. A stranded
# jq from this hook blocked the C:\GitHub -> C:\Repos move.
JQ=(jq)
if command -v timeout >/dev/null 2>&1; then JQ=(timeout 5 jq); fi

if command -v jq >/dev/null 2>&1 \
    && OUT=$(printf '%s\n' "$INPUT" | "${JQ[@]}" -c --arg ts "$TS" '{ts: $ts} + .' 2>/dev/null); then
  printf '%s\n' "$OUT" >> "$LOG"
else
  # No jq (or unparseable input): splice ts into the raw line by hand.
  printf '{"ts":"%s",%s\n' "$TS" "${INPUT#\{}" >> "$LOG"
fi

exit 0
