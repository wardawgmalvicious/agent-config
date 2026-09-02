# Hooks

Shell scripts wired into Claude Code via [settings.json](../settings.json).
Hooks fire at specific events in the Claude Code lifecycle (session
start, before/after tool use, on stop, etc.).

## What's here

- [log-instructions-loaded.sh](log-instructions-loaded.sh) — fires on
  the `InstructionsLoaded` event (whenever a CLAUDE.md or rules
  `coding-*.md` file is loaded into context). Appends the event as a
  pure-JSONL line (a `ts` timestamp folded into the event JSON) to
  `~/.claude/logs/instructions-loaded.log` for later inspection.
  Pure observability; does not block.
- [log-skill-invocations.sh](log-skill-invocations.sh) — fires on
  `PostToolUse` with matcher `Skill` (every skill invocation, whether
  the model triggered it or the user typed `/<name>`; the
  `InstructionsLoaded` event never sees skills — they load through
  the Skill tool). Extracts `ts` / `session_id` / `cwd` / `skill` /
  `args` only — the full payload carries the skill's entire content
  in `tool_response` — and appends pure JSONL to
  `~/.claude/logs/skills-invoked.log`. Pure observability; does not
  block. Requires [jq](https://jqlang.org) (without it, a stub line
  is logged and the event details are dropped).
- [security-reviewer-memory-scope.sh](security-reviewer-memory-scope.sh)
  — fires on `PreToolUse` with matcher `Edit|Write`. If the current
  agent is `security-reviewer`, enforces that the target `file_path`
  is under `~/.claude/agent-memory/security-reviewer/`; otherwise
  exits 0 (allow). Other callers (main session, other subagents) pass
  through unchanged. Requires [jq](https://jqlang.org).

## Querying the logs

Both logs feed [scripts/instructions-log](../../scripts/instructions-log)
— quick queries like `instructions-log today`, `instructions-log paths`,
`instructions-log reasons`, `instructions-log csv`,
`instructions-log skills`, or `instructions-log tail`.

## Wiring

Hooks must be registered in `settings.json` to fire. All hooks here
are wired in this repo's [settings.json](../settings.json) under the
`hooks` key. The committed commands resolve via `$HOME/.claude/...` —
[scripts/link-claude.ps1](../../scripts/link-claude.ps1) copies this
`hooks/` directory into `~/.claude/hooks/` and mirrors `settings.json`
there, so the paths work for any user regardless of where the repo is
cloned. **These are copies, not junctions** (changed 2026-09-02): a hook
edited here is not live until that script runs again, and the deployed
copy keeps executing the previous version until it does. That is the
point — hooks *execute*, so a junction meant every half-written save
fired on the next matching tool call in every session on the machine. If you keep your Claude Code config somewhere other than
`~/.claude`, edit the paths in `settings.json` to match.
