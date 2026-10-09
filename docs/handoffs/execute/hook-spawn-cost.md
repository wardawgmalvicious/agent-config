---
status: open
priority: 3
needs: [user]
blocked-by: []
written: 2026-10-08
---

# Handoff: decide whether the hot-path hooks spawn less

- **Written**: 2026-10-08, from two inbox notes: a `/doctor` run of
  2026-10-08 in a client Fabric repo, and an aside in a note of
  2026-10-07 by a session in a personal repo. Re-measured against the
  payload at `fb9e38f`: the hooks are wired as the doctor read them.
- **Kind**: a decision, the user's, on hooks and `claude/settings.json`,
  which no note can move; each lever then needs proving before it ships.
  Nothing is drafted.

## The cost

Five command hooks run synchronously on hot paths, each costing at
least one Git Bash spawn: about 60 ms on a healthy machine, and about
0.5 s while `bash.exe` is in a degraded state that recurs until a
reboot (`claude/CLAUDE.md`, 2026-10-09, from a machine-config session's
inbox note; the 0.4 s measured on 2026-10-07 was that state). A silent
success leaves no timing in a transcript, so the doctor's figures are
spawn arithmetic at 0.4 s over the 50 most recent sessions, 2026-10-06
22:43Z to 2026-10-08 03:46Z, 23 of them probes:

| Hook | Event, matcher | Runs | Floor |
| --- | --- | --- | --- |
| `identity-guard.sh` | PreToolUse and PostToolUse, `Bash\|PowerShell` | 2,025 shell calls, twice each | about 27 min |
| `security-reviewer-memory-scope.sh` | PreToolUse, `Edit\|Write` | 844 | about 5.6 min |
| `name-session.sh` | UserPromptSubmit | every prompt | 0.4 s each |
| `log-instructions-loaded.sh` | InstructionsLoaded | every load | 0.4 s each |
| `log-skill-invocations.sh` | PostToolUse, `Skill` | 42 | about 17 s |

Those floors are the degraded state's. At a healthy 60 ms each is about
a seventh: `identity-guard.sh` about 4 minutes, the memory-scope hook
under one.

`offer-handoff.sh`, on SessionStart `compact`, ran 12 times: 1.3 s
median, 3.6 s worst. Re-measured 2026-10-08: `claude/settings.json`
wires each in shell form, `bash $HOME/.claude/hooks/<name>.sh`, none
with `if`, and only `prune-probe-sessions.sh` is `async`.

## Lever 1: the `if` field

A handler's `if`, in permission-rule syntax, is checked before the
command spawns. Read 2026-10-08 in the hooks docs and the CHANGELOG:

- it arrived in **2.1.85**, not 2.1.214 as the doctor's relay said, and
  has matched each subcommand of a compound command since 2.1.89;
- it works on PreToolUse, PostToolUse, PostToolUseFailure,
  PermissionRequest and PermissionDenied only, and **a hook with `if` on
  any other event never runs**, silently;
- it is best-effort: where Claude Code cannot tell what a command runs,
  the hook runs anyway, and the docs say to enforce a hard allow or deny
  with permissions, not a hook.

**For `identity-guard.sh` a filter risks a silent bypass.** Its fast
path (line 138) passes any input whose JSON holds `"command"` and `git`
anywhere, then tokenizes every `;`, `|` and `&` segment for `git commit`
or `git push`, which catches `cd x && git commit`,
`git -C <path> commit`, `/usr/bin/git` and `git.exe`. The permissions
page lists `git -C . push origin main` among what `Bash(git push *)`
does not stop, so a `Bash(git commit *)` filter would miss `-C`; how
`Bash(git *)` and a `PowerShell(...)` rule treat the other shapes is
untested. Prove any `if` against `tests/hooks/identity-guard/` plus
those four shapes, under both tools, or leave the guard unfiltered: the
spawn is the price of a guard that cannot fail open.

**For `security-reviewer-memory-scope.sh` the doctor's filter is
wrong.** The hook lets through every caller but the security reviewer,
then blocks the reviewer's writes outside
`~/.claude/agent-memory/security-reviewer/`. An `if` on that path would
run it only for the writes it allows, and the guard would fail open. A
filter has to keep every Edit and Write; moving the hook into the
subagent's own frontmatter `hooks:` might spare the main session's
edits, **unverified**.

## Lever 2: `async`

The two loggers only append to a log, so `async: true` suits them: an
async hook cannot block, and its `additionalContext` and
`systemMessage` arrive on the next turn (hooks reference, read
2026-10-08). Confirm nothing reads either log within the same turn.
`log-instructions-loaded.sh` is on InstructionsLoaded, where `if` cannot
apply, so `async` is its only lever.

## Lever 3: exec form

Since 2.1.139 a hook with `args` runs `command` directly, with no shell,
and substitutes path placeholders into each `args` element; on Windows
`command` must resolve to a real executable such as an `.exe` (hooks
reference, read 2026-10-08). A personal repo's hooks ran that way on
2.1.291 (2026-10-07): `"command": "uv"` resolved with no `.exe`, and
`${CLAUDE_PROJECT_DIR}` arrived substituted. If shell form puts a shell
around `bash`, exec form saves a spawn per run, unmeasured. A bare
`bash` may resolve on `PATH` to WSL's `bash.exe`, as it does from
PowerShell (`claude/CLAUDE.md`), so name Git's in full.

## Open question

Where the repo's git hooks (`pre-commit`, `commit-msg`, `pre-push`) are
armed, the PreToolUse layer checks the same commit a second time.
Whether both are still wanted there is a design call.

## Where it lands

`claude/settings.json` and `claude/hooks/`, on the user's yes, then
`./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`.
`.claude/rules/hooks-and-agents.md` loads on those files, so it also
takes what this brief decides as guidance, with the "keep hooks
spawn-lean" that `claude/CLAUDE.md` dropped on 2026-10-09 to stay
within its line cap.

## Not checked

No `if`, `async` or exec form was tried here. The floors are the
doctor's arithmetic, not timings, and whether shell form wraps the
command in a second shell was not measured; `hyperfine` can.

## Scrubbing

The doctor's note carried counts and timings only; the other came from a
personal repo.

## Re-measure before acting

```bash
grep -n -E '"matcher"|"command"|"async"|"if"' claude/settings.json   # five hot-path hooks, shell form, one async, no if, on 2026-10-08
sed -n '138p' claude/hooks/identity-guard.sh                         # the fast path
```

Run `bash-doctor.ps1` from the PowerShell tool before timing anything:
a timing taken while it exits 1 measures the degraded state (exit 0 on
2026-10-09).
