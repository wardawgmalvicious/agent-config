# Hooks

PowerShell lifecycle hooks registered through the user-scope
[hooks.json](../hooks.json). Codex runs the Windows command override, so these
scripts do not depend on bare `python`, Git Bash, or `jq`.

## What's here

- [log-session-start.ps1](log-session-start.ps1) — fires asynchronously for
  `SessionStart` sources `startup`, `resume`, `clear`, and `compact`. It writes
  selected lifecycle metadata as JSONL to
  `CODEX_HOME/logs/session-started.jsonl`. It emits no hook output and fails
  open because logging must never affect the session.

The hook deliberately excludes prompts, tool inputs, tool responses, and
transcript content from the log.

## Claude parity

The Claude configuration has three hooks. Their Codex mappings are:

| Claude hook | Codex handling |
| --- | --- |
| `InstructionsLoaded` logger | Approximated with `SessionStart`. Codex builds its `AGENTS.md` chain once per run and has no documented `InstructionsLoaded` event. The log records the lifecycle event, not a claim about individual instruction files. |
| `PreToolUse` memory-scope enforcement | Not duplicated. The Codex `security_reviewer` agent has `sandbox_mode = "read-only"`, which prevents all file writes more directly. |
| `PostToolUse` matcher `Skill` | Not duplicated. Codex does not document skill loading as a hook-visible `Skill` tool event. |

Do not add speculative matchers for unsupported events. A hook that silently
never fires is worse than an explicit compatibility note.

## Wiring and trust

[scripts/link-codex.ps1](../../scripts/link-codex.ps1) copies `hooks.json` to
`CODEX_HOME/hooks.json` and the PowerShell scripts to `CODEX_HOME/hooks/`.
Codex requires review and trust for new or changed non-managed hooks. Use
`/hooks` in the Codex CLI after deployment to inspect and trust the exact
definitions.

Codex merges `hooks.json` with inline hooks in `config.toml` and warns when
both exist in one configuration layer. Keep this repository's user hooks in
`hooks.json`; reserve inline hooks for a deliberately reconciled setup.

Official reference: [Codex hooks](https://learn.chatgpt.com/docs/hooks).
