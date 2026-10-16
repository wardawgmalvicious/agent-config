---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-16
---

# Handoff: run-briefs places each live session before it lands a brief

- **Written**: 2026-10-16, by the session that landed
  `named-session-placement.md`, as one of two follow-ups its last commit
  names. Measured against the payload at `8d14ea0`.
- **Kind**: an edit to a deployed workflow skill and its reference, each
  live machine-wide once saved, then a retest. Nothing is drafted.

## The gap

`run-briefs` § "6. Land" step 1 stops a landing on another session live
in the main checkout, read from the `cwd` in `claude agents --json`, and
`references/landing-gate.md` § "This repo's landing" runs that as its
first line:

```bash
claude agents --json | jq -b -r '.[] | select(.cwd | ascii_downcase | endswith("agent-config")) | "\(.pid)\t\(.sessionId)\t\(.status)\t\(.name)"'
```

The downcase handles the drive letter: on 2026-10-16 `claude agents
--json` printed a session in the main checkout as
`c:\Repos\Personal\agent-config`, the registry's own spelling, where git
spells the top level `C:/Repos/Personal/agent-config`. The suffix does
not handle where in the tree a session sits. Over five sample rows that
day, the filter caught a session at the top level, the same path in
upper case and a clone elsewhere whose path ends in `agent-config`, and
let through one in `agent-config\skills` and one in
`.claude\worktrees\x`. The worktree is right to pass, since it has a
HEAD of its own. The subdirectory is the miss: that session shares the
main checkout's HEAD, and the fast-forward moves it with no stop. `land`
step 1 recorded the same trap for a prefix match on 2026-09-17.

## The method

`~/.claude/skills/land/scripts/placed-elsewhere.sh <name>...`, from
`5b37f0e`, places each name by its registry entry's `cwd` through git's
top level, and keeps in this tree a row it cannot place;
`land/references/never-prompted-sessions.md` § "Where a listed session
sits" has its measurements. The coordinator gives it every row but its
own: the names from the same `claude agents --json`, its own left out
by `sessionId` as the gate does now, each passed as one argument, since
a name such as `brief: <slug>` holds a space. A name two sessions share
reads as in doubt, which stops the landing, the safe side. The
`agent-config` suffix goes with it.

## Where it lands

- `skills/workflow/run-briefs/SKILL.md` § "6. Land", step 1.
- `skills/workflow/run-briefs/references/landing-gate.md` § "This repo's
  landing": the block's first line, and the paragraph on "This session's
  row" after it.
- Then `/test-skill run-briefs`, which `skill-status.py --stale` already
  reads as `retest-behaviour` on 2026-10-16. The skill spends usage and
  lands branches, so it runs only when typed.

## Not checked

No session was started in a subdirectory of the main checkout to show
the miss live: the sample rows stand in for one, read by the gate's own
filter. Whether `claude agents --json` reads the registry was not
looked at; on 2026-10-16 its `pid`, `cwd`, `name`, `sessionId` and
`status` matched the registry's for all four live sessions.

## Re-measure before acting

```bash
grep -n 'endswith("agent-config")' skills/workflow/run-briefs/references/landing-gate.md   # line 122 on 2026-10-16
grep -n 'rows carry a' skills/workflow/run-briefs/SKILL.md                              # line 155 on 2026-10-16
ls ~/.claude/skills/land/scripts/placed-elsewhere.sh                                     # present since 8d14ea0
```
