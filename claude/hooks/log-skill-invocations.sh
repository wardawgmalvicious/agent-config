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

# Bound jq's lifetime. jq reads stdin, so if this hook's shell dies mid-pipeline
# jq is left blocking on a stdin that never closes and holds the session's cwd
# indefinitely -- enough to block a rename of any ancestor directory.
#
# timeout is run, never probed for: `command -v timeout` finds a timeout.exe
# that Defender's ASR rule then refuses to start (exit 126, 2026-09-17), which
# dropped every skill event to the stub line below. 126 and 127 retry bare jq,
# since jq's own errors never use them (coding-bash.md, "Claude Code hooks").
jq_input() {
  local rc=0
  printf '%s\n' "$INPUT" | timeout 5 jq "$@" 2>/dev/null || rc=$?
  [ "$rc" -eq 126 ] || [ "$rc" -eq 127 ] || return "$rc"
  printf '%s\n' "$INPUT" | jq "$@" 2>/dev/null
}

if command -v jq >/dev/null 2>&1 \
    && OUT=$(jq_input -c --arg ts "$TS" \
      '{ts: $ts, session_id, cwd, skill: .tool_input.skill, args: .tool_input.args}'); then
  printf '%s\n' "$OUT" >> "$LOG"
else
  printf '{"ts":"%s","error":"jq missing or payload unparseable; skill event dropped"}\n' "$TS" >> "$LOG"
fi

exit 0
