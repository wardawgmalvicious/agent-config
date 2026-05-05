# Hooks

Shell scripts wired into Claude Code via [settings.json](../settings.json).
Hooks fire at specific events in the Claude Code lifecycle (session
start, before/after tool use, on stop, etc.).

## What's here

- [log-instructions-loaded.sh](log-instructions-loaded.sh) — fires on
  the `InstructionsLoaded` event (whenever a CLAUDE.md or rules
  `coding-*.md` file is loaded into context). Appends the JSON event
  to `~/.claude/logs/instructions-loaded.log` for later inspection.
  Pure observability; does not block.
- [security-reviewer-memory-scope.sh](security-reviewer-memory-scope.sh)
  — fires on `PreToolUse` with matcher `Edit|Write`. If the current
  agent is `security-reviewer`, enforces that the target `file_path`
  is under `~/.claude/agent-memory/security-reviewer/`; otherwise
  exits 0 (allow). Other callers (main session, other subagents) pass
  through unchanged. Requires [jq](https://jqlang.org).

## Querying the log

The InstructionsLoaded log feeds [scripts/instructions-log](../scripts/instructions-log)
— quick queries like `instructions-log today`, `instructions-log paths`,
`instructions-log reasons`, or `instructions-log tail`.

## Wiring

Hooks must be registered in `settings.json` to fire. Both hooks here
are wired in this repo's [settings.json](../settings.json) under the
`hooks` key. The committed paths are absolute (`/c/Users/<user>/.claude/...`)
— if you clone this elsewhere, edit those entries to match.
