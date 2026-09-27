#!/bin/bash
# security-reviewer-memory-scope.sh
#
# PreToolUse hook scoped to the security-reviewer subagent.
# Lives in ~/.claude/settings.json as a user-scope hook; matched on Edit|Write.
# First checks agent_type — if not security-reviewer, exits 0 (allow).
# Otherwise enforces that target file_path is inside
# ~/.claude/agent-memory/security-reviewer/.
#
# Exit codes:
#   0 - Allow the tool call
#   1 - Allow it unchecked: jq could not read the input (see unreadable below)
#   2 - Block the tool call (security-reviewer attempting out-of-scope Edit/Write)
#       stderr message is fed back to Claude as the rejection reason

set -euo pipefail

# Bound jq's lifetime. jq reads stdin, so if this hook's shell dies mid-pipeline
# jq is left blocking on a stdin that never closes and holds the session's cwd
# indefinitely -- enough to block a rename of any ancestor directory. This hook
# fires on every Edit/Write, so it is the highest-frequency jq call here.
#
# timeout is run, never probed for: `command -v timeout` finds a timeout.exe
# that Defender's ASR rule then refuses to start (exit 126, 2026-09-17), and a
# probe handed every jq call to it. 126 and 127 retry bare jq, since jq's own
# errors never use them (coding-bash.md, "Claude Code hooks").
jq_input() {
  local rc=0
  printf '%s\n' "$INPUT" | timeout 5 jq -r "$@" 2>/dev/null || rc=$?
  [ "$rc" -eq 126 ] || [ "$rc" -eq 127 ] || return "$rc"
  printf '%s\n' "$INPUT" | jq -r "$@" 2>/dev/null
}

# Input jq cannot read, or a jq that timed out (124), allows the call, as any
# exit but 2 does: the same fail-open side as before, now bounded and named.
# Exit 1 rather than 0, since Claude Code shows a non-zero exit's first stderr
# line as a hook-error notice and an exit 0's stderr only in the debug log.
unreadable() {
  echo "security-reviewer-memory-scope: jq could not read the hook input (exit $1), so this call was not checked." >&2
  exit 1
}

# Read JSON input from stdin
INPUT=$(cat)

# Agent-type guard — only enforce when running under security-reviewer
AGENT_TYPE=$(jq_input '.agent_type // empty') || unreadable $?

if [ "$AGENT_TYPE" != "security-reviewer" ]; then
  # Not our subagent (could be main session, or a different subagent)
  # Allow without further checks
  exit 0
fi

# Extract file_path from tool_input
FILE_PATH=$(jq_input '.tool_input.file_path // empty') || unreadable $?

# If no file_path, allow (defensive — shouldn't happen for Edit/Write)
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Resolve allowed directory
ALLOWED_UNIX="$HOME/.claude/agent-memory/security-reviewer/"

# Normalize file_path for comparison
# Tool calls may pass either Unix or Windows-style paths
FILE_PATH_UNIX=$(cygpath -u "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

# Check if file_path is inside allowed directory
case "$FILE_PATH_UNIX" in
  "$ALLOWED_UNIX"*)
    # Inside agent-memory dir — allow
    exit 0
    ;;
  *)
    # Outside agent-memory dir — block
    cat >&2 <<EOF
Blocked by security-reviewer-memory-scope hook.

Edit and Write tools are restricted to the agent-memory directory:
  $ALLOWED_UNIX

Attempted target: $FILE_PATH

This subagent does not modify code. Report findings; remediation is the user's responsibility.
EOF
    exit 2
    ;;
esac
