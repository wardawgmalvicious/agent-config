---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-16
---

# Handoff: the Peers paragraph places a row with placed-elsewhere.sh

- **Written**: 2026-10-16, by the session that landed
  `named-session-placement.md`, as one of two follow-ups its last commit
  names. Measured against the payload at `8d14ea0`.
- **Kind**: an edit to `claude/CLAUDE.md` § "Peers", with a ledger
  entry, a probe before landing and a `-Force` deploy. Nothing is
  drafted.

## The gap

The Peers paragraph says `ListAgents` names a session by its `/rename`
or `--name` name, else `<cwd-basename>-<hash>`, and then sends a session
to commit each finished unit unasked "while one shares your tree". It
gives no way to tell whether a row shares the tree, and leaves out the
name a hook sets: this machine's naming hook titles a session from its
first prompt, and on 2026-10-16 the registry held two such names, each
`nameSource: hook`, one of them a session in a client repo.

That rule fires before `/commit` loads, so its reader has only this
paragraph to place a row by. The last Peers entry in
`docs/evidence/user-claude-md.md`, of 2026-10-15, measured the gap:
with no peer in the tree, both arms named the testing session's
custom-named row as one they could not place, and one asked whether to
commit while the other judged it elsewhere; beside a peer, one of three
confirmed the peer's folder by the `cwd` in
`~/.claude/sessions/<pid>.json`.

`~/.claude/skills/land/scripts/placed-elsewhere.sh <name>...` now makes
that placement for any row, by its registry entry's `cwd` and git's top
level (`5b37f0e`), and `commit` defines a peer by it (`1de8c2b`).

## The edit

The naming sentence gains the hook's name beside `/rename` and
`--name`, and the unasked-commit clause names the script as how to tell
whether a row shares the tree. Its path is a deployed one, which this
file prefers to a repo path.

## Where it lands

- `claude/CLAUDE.md` § "Peers", lines 157 to 167 on 2026-10-16. The
  file is at its cap, 200 of 200 lines by `scripts/lint-claude-md.py`,
  so the words come from elsewhere in it, moved verbatim to the ledger
  as `.claude/rules/editing-claude-md.md` says.
- `docs/evidence/user-claude-md.md` under the same heading: a dated
  entry carrying the probe below and whatever moved out.
- The deploy, after the merge:

  ```powershell
  ./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force
  ```

## Probe before landing

Repeat the 2026-10-15 probe with the reworded paragraph in a probe
repo's `CLAUDE.local.md`: Opus 5.5 at `--effort xhigh`, one arm at a
time, beside an idle peer prompted once under a custom name, once in
the arm's tree and once elsewhere. It passes when each arm places the
row with the script and commits unasked only when the peer shares its
tree. Those runs cost $1.24 and $1.31, five arms each.

## Re-measure before acting

```bash
grep -n 'names a session by' claude/CLAUDE.md         # line 157 on 2026-10-16
uv run scripts/lint-claude-md.py                       # claude/CLAUDE.md 200 lines, cap 200, on 2026-10-16
ls ~/.claude/skills/land/scripts/placed-elsewhere.sh   # present since 8d14ea0
```
