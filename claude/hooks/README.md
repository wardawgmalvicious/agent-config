# Hooks

Scripts wired into Claude Code via [settings.json](../settings.json).
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
  through unchanged. Requires [jq](https://jqlang.org); input it cannot
  read allows the call under a `hook error` notice saying so.
- [identity-guard.sh](identity-guard.sh) — fires on `PreToolUse` and
  `PostToolUse` with matcher `Bash|PowerShell`, and acts only when the
  command carries a `git commit` or `git push`. Blocks a commit whose
  staged diff *adds* a line containing a term from
  `~/.config/identity-denylist.txt`, feeds back after a commit whose
  message does, and blocks a push while any unpushed commit on the
  pushed ref carries one in its message or added lines. The denylist —
  client and employer names, account names, your own profile path —
  lives **outside every repo** because it is itself the thing that must
  not be committed; `exempt: <path>` lines skip repo roots where the
  name is legitimately present (a client's own repo). No denylist means
  no check, silently. Fails open by design: a broken hook must not wedge
  every commit on the machine, and
  [tests/hooks/identity-guard/](../../tests/hooks/identity-guard/) is
  what makes that acceptable. Open is not silent where the scan never
  ran: with jq missing or unable to read the input, the call proceeds
  under a `hook error` notice saying it was not scanned. Exists because
  gitleaks matches secrets,
  not identities, and never reads a commit message (measured 2026-09-04
  on 8.30.1). Requires [jq](https://jqlang.org).

  Those events see only commits Claude Code issues. The same script
  also runs as a **git hook** (`--git-hook pre-commit|commit-msg|pre-push`,
  no jq needed), which a repo opts into through its pre-commit config —
  agent-config does — so a commit from Copilot, VS Code's Source Control
  view or a terminal is gated too.
- [name-session.sh](name-session.sh) — fires on `UserPromptSubmit` and
  names a session from its first prompt, so `ListAgents`, `claude agents`
  and the `/resume` picker show what it is for rather than a default such
  as `agent-config-67`. First match wins: a skill or command
  (`/test-skill prune-branches` → `test-skill: prune-branches`), a handoff
  brief (`brief: <slug>`), an inbox note (`inbox: <slug>`), a worktree
  (`brief: <name>` when that brief exists, else `worktree: <name>`), or a
  branch other than `main` or `master`. Anything else keeps the default,
  and `/rename` with no argument names a session from its conversation.
  It decides once, and never renames a session that already has a name or
  was under way when it first saw it: `SendMessage` addresses a live
  session by name, so a rename strands the peer using it. A new session's
  first prompt starts nothing but bash, and every later prompt costs one
  bash start and two file tests. Its cases are
  [tests/hooks/name-session/](../../tests/hooks/name-session/test-name-session.sh).
- [prune-probe-sessions.sh](prune-probe-sessions.sh) and
  [prune-probe-sessions.py](prune-probe-sessions.py) — fire on
  `SessionStart` (matcher `startup`, async) and, at most once a day,
  delete each probe session two days after it last ran: one whose cwd is
  in the temp folder, where every probe root lives, or whose name starts
  `probe:`, which a probe started from a real repo takes with
  `-n "probe: <topic>"`. Then go folders left holding no file, chiefly
  the empty scratch folders Claude Code's `cleanupPeriodDays` leaves under
  `<temp>/claude`. The `.sh` is the gate and spawns nothing until a sweep
  is due; the `.py` does the work through the Agent SDK's
  `list_sessions()`, via uv. Run the `.py` by hand to see what it would
  delete: without `--apply` it only reports. Its deletions are logged to
  `~/.claude/logs/prune-probe-sessions.log`, its errors to `.err` beside
  it. Its cases are
  [tests/hooks/prune-probe-sessions/](../../tests/hooks/prune-probe-sessions/test-prune-probe-sessions.sh).
- [offer-handoff.sh](offer-handoff.sh) — fires on `SessionStart` with
  matcher `compact`, after every compaction, auto or manual. Where the
  checkout holding the session's `cwd` keeps briefs under `docs/handoffs/`,
  it tells Claude that a brief could be written while the summary still
  holds the thread, that the user decides when to hand off, and which
  briefs exist, one line each: status, priority, needs, blockers and a
  deferred brief's trigger. Elsewhere it prints nothing. It offers and
  never blocks: a PreCompact hook that stopped a bare `/compact` was tried
  in a client repo on 2026-10-01 and dropped the same day, since the user
  judges when a session has run long enough. No other event could make the
  offer: nothing PreCompact or PostCompact prints reaches Claude (each
  event's readers are in
  [coding-bash.md](../rules/coding-bash.md#claude-code-hooks)), and no hook
  input carries the context's size as it fills, so nothing can warn before
  an auto compaction. Claude Code runs an identical command once across
  settings files, but a repo's own copy of this hook under another command
  runs beside it, so the two would offer twice. A brief is what
  `scripts/handoff-status.py` counts; the cases, a comparison with that
  script among them, are
  [tests/hooks/offer-handoff/](../../tests/hooks/offer-handoff/test-offer-handoff.sh).

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
