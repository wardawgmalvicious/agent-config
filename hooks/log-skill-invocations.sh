#!/bin/bash
# Logs every Skill tool invocation to a local file as pure JSONL.
# Wired as a PostToolUse hook matched to the Skill tool, so it fires
# whether the model invoked the skill itself or the user typed /<name>.
# Extracts only identifying fields — the full payload carries the
# skill's entire content in tool_response, which would bloat the log.
# Pure observability: cannot block, exit code is ignored.

INPUT=$(cat)
LOG="$HOME/.claude/logs/skills-invoked.log"

mkdir -p "$(dirname "$LOG")"
TS=$(date -Iseconds)
if command -v jq >/dev/null 2>&1 \
    && OUT=$(printf '%s\n' "$INPUT" | jq -c --arg ts "$TS" \
      '{ts: $ts, session_id, cwd, skill: .tool_input.skill, args: .tool_input.args}' 2>/dev/null); then
  printf '%s\n' "$OUT" >> "$LOG"
else
  printf '{"ts":"%s","error":"jq missing or payload unparseable; skill event dropped"}\n' "$TS" >> "$LOG"
fi

exit 0
