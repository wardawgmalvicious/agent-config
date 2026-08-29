#!/bin/bash
# Logs every InstructionsLoaded hook event to a local file as pure JSONL.
# Fires at session start for eagerly-loaded CLAUDE.md / rules files,
# and during a session for lazy-loaded (nested or path-matched) files.
# Pure observability: cannot block, exit code is ignored.

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
