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
#   2 - Block the tool call (security-reviewer attempting out-of-scope Edit/Write)
#       stderr message is fed back to Claude as the rejection reason

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Agent-type guard — only enforce when running under security-reviewer
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')

if [ "$AGENT_TYPE" != "security-reviewer" ]; then
  # Not our subagent (could be main session, or a different subagent)
  # Allow without further checks
  exit 0
fi

# Extract file_path from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

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
