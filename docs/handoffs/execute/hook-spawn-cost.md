---
status: deferred
priority: 3
needs: [reboot]
blocked-by: []
reopen-when: a reboot clears the slow bash.exe and bash-doctor.ps1 exits 0
written: 2026-10-08
---

# Handoff: measure exec form for the hot-path hooks

- **Written**: 2026-10-08, from two inbox notes; narrowed 2026-10-17,
  when the user decided the other levers (the `async` loggers, the
  unfiltered guards, both commit layers kept) and left this one. The
  reasoning is in the commit and in `.claude/rules/hooks-and-agents.md`.
- **Kind**: a measurement, then the user's call on whether to ship it.

## What is left

Since 2.1.139 a hook with `args` runs `command` directly, with no shell,
and substitutes path placeholders into each `args` element; on Windows
`command` must resolve to a real executable such as an `.exe` (hooks
reference, read 2026-10-08). A personal repo's hooks ran that way on
2.1.291 (2026-10-07): `"command": "uv"` resolved with no `.exe`, and
`${CLAUDE_PROJECT_DIR}` arrived substituted. If shell form puts a shell
around `bash`, exec form saves a spawn per run. **Unmeasured.**

A bare `bash` may resolve on `PATH` to WSL's `bash.exe`, as it does from
PowerShell (`claude/CLAUDE.md`), so name Git's in full:
`C:\Program Files\Git\bin\bash.exe`.

## To do

1. Run `bash-doctor.ps1` from the PowerShell tool: it must exit 0, or the
   timings measure the degraded state (exit 1 on 2026-10-17, `bash.exe`
   at a median 3,208 ms against 43 ms for `sh.exe`).
2. With `hyperfine`, time `identity-guard.sh` on a payload with no `git`
   in it (its fast path, line 138 of the script), once as
   `bash $HOME/.claude/hooks/identity-guard.sh` from a shell and once as
   Git's `bash.exe` called directly with the script as its argument.
3. Report the difference to the user. Ship only on their yes, to
   `claude/settings.json` for the hot-path hooks, then run
   `tests/hooks/identity-guard/` against the deployed copy and
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`.
   A hook with `args` is a different handler shape, so prove it fires
   with a transcript, not a silent success.

If the saving is within noise, delete the brief and say so in the commit.

## Not checked

No exec form was tried here. Whether shell form wraps the command in a
second shell was not measured.
