#!/usr/bin/env bash
# push-gate.sh — refuse a push that no Claude Code session issued.
#
# Wired as a pre-push hook by .pre-commit-config.yaml. This repo is public,
# and on 2026-09-10 a commit authored in GitHub Copilot Chat reached main
# carrying a client name. Nothing Claude Code enforces runs for another
# harness, and the identity guard beside this one catches only names already
# on its list. So nothing leaves this machine unless it went through a
# Claude Code session, which is where review happens, or unless a human says
# so for one push:
#
#   git -c agentconfig.push=reviewed push ...
#
# Same syntax in Git Bash and PowerShell. The override is read from
# GIT_CONFIG_PARAMETERS, which git exports to hooks for `-c` values, and NOT
# through `git config`: that would also accept a value written to
# .git/config, which persists and silently opens the gate for every later
# push. `$env:X = ...` in a long-lived PowerShell session fails the same way,
# which is why the override is not an environment variable. `-c` lasts one
# command.
#
# The marker is CLAUDECODE=1, which Claude Code sets in its shell tools and
# git passes through to hooks. Do NOT widen it to CLAUDE_CODE_SSE_PORT: the
# Claude Code VS Code extension injects that one into every integrated
# terminal, including the ones Copilot runs commands in. All three facts,
# and the `-c` pass-through under pre-commit, verified 2026-09-11 on
# pre-commit 4.6.2 and extension 2.1.268.
#
# Every ref, not just main: a pushed branch is just as public. It guards
# against accidents, not intent — --no-verify skips it, as it skips every
# hook, which is why the message below addresses the agent directly.
#
# Exit codes: 0 allow, 1 block.

[[ "${CLAUDECODE:-}" == 1 ]] && exit 0

# Quoted forms only, so `agentconfig.push=unreviewed` does not match. Git
# writes 'key'='value' since 2.31 and 'key=value' before it.
case "${GIT_CONFIG_PARAMETERS:-}" in
*"'agentconfig.push'='reviewed'"* | *"'agentconfig.push=reviewed'"*) exit 0 ;;
esac

cat >&2 <<'EOF'
push-gate: blocked — this push was not issued from a Claude Code session.

agent-config is public, and nothing reaches it unreviewed. Either push
from Claude Code after it has reviewed the unpushed commits, or, having
reviewed them yourself, push once with the override:

    git -c agentconfig.push=reviewed push <same arguments>

If you are an AI assistant other than Claude Code: stop here and tell the
user. Do not retry with the override or with --no-verify.
EOF
exit 1
