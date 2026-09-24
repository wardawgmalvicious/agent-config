---
paths:
  - "claude/hooks/**"
  - "claude/agents/**"
  - "claude/settings.json"
  - "scripts/push-gate.sh"
  - "tests/hooks/*/*"
---

# Hooks, the subagent and the push gate

- A hook in `claude/hooks/*.sh` fires on an event registered in
  `claude/settings.json`, and its command is hardcoded to
  `$HOME/.claude/...`, which resolves only because the linker deploys there:
  never make it repo-relative. An edit is not live until
  `scripts/link-claude.ps1` runs; until then the deployed copy runs the old
  version, and nothing says so.
- The `security-reviewer` subagent is scoped by an explicit tool allowlist
  plus a `PreToolUse` hook that blocks any Edit or Write outside
  `~/.claude/agent-memory/security-reviewer/`. Its procedure is
  `tests/agents/security-reviewer/README.md`.
- `identity-guard` gates `git commit` and `git push` issued through Bash or
  PowerShell against `~/.config/identity-denylist.txt`, a local file never
  in any repo, because the list is the leak. After any edit, run
  `tests/hooks/identity-guard/` against the repo copy, then again against
  the deployed copy once the linker has run.
- That hook sees Claude Code's commits only: a Copilot-authored commit took
  a client name to public `main` past it on 2026-09-10. So
  `.pre-commit-config.yaml` runs the same script as a git hook at commit,
  message and push, whoever commits, and a clone re-runs
  `pre-commit install` (or `scripts/bootstrap-pre-commit`) once to gain the
  last two.
- `scripts/push-gate.sh`, a pre-push hook beside it, refuses any push not
  issued from Claude Code unless a human overrides it, so another harness's
  commits wait for a Claude session's review; the identity guard knows only
  names already on its list. It guards against accidents, not intent:
  `--no-verify` skips it, as it skips every hook. A session here passes on
  `CLAUDECODE=1`, so `/land` and a plain `git push` work. The human override
  is one command, `git -c agentconfig.push=reviewed push ...` (2026-09-11).
