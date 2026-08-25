#!/bin/bash
# Logs every InstructionsLoaded hook event to a local file as pure JSONL.
# Fires at session start for eagerly-loaded CLAUDE.md / rules files,
# and during a session for lazy-loaded (nested or path-matched) files.
# Pure observability: cannot block, exit code is ignored.

INPUT=$(cat)
LOG="$HOME/.claude/logs/instructions-loaded.log"

mkdir -p "$(dirname "$LOG")"
TS=$(date -Iseconds)
if command -v jq >/dev/null 2>&1 \
    && OUT=$(printf '%s\n' "$INPUT" | jq -c --arg ts "$TS" '{ts: $ts} + .' 2>/dev/null); then
  printf '%s\n' "$OUT" >> "$LOG"
else
  # No jq (or unparseable input): splice ts into the raw line by hand.
  printf '{"ts":"%s",%s\n' "$TS" "${INPUT#\{}" >> "$LOG"
fi

exit 0
