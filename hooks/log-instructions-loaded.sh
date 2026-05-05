#!/bin/bash
# Logs every InstructionsLoaded hook event to a local file.
# Fires at session start for eagerly-loaded CLAUDE.md / rules files,
# and during a session for lazy-loaded (nested or path-matched) files.
# Pure observability: cannot block, exit code is ignored.

INPUT=$(cat)
LOG="$HOME/.claude/logs/instructions-loaded.log"

mkdir -p "$(dirname "$LOG")"
TS=$(date -Iseconds)
printf '[%s] %s\n' "$TS" "$INPUT" >> "$LOG"

exit 0