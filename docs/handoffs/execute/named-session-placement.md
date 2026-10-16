---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-15
---

# Handoff: place a named `ListAgents` row by its registry entry's `cwd`

- **Written**: 2026-10-15, from one inbox note of 2026-10-14 by a
  session in a client repo that runs a Python worker on Azure Container
  Apps, written during a `/land`. Re-measured against the payload at
  `f8abbed`: `never-prompted.sh` reads the registry by `name` and never
  its `cwd`.
- **Kind**: an edit to two deployed workflow skills and a bundled
  script, each live machine-wide once saved. Nothing is drafted.

## The gap

`land` step 1 and `commit` § "When another session shares this tree"
place a `ListAgents` row by its name. A row named for its working
directory, `<cwd-basename>-<hash>`, places itself; one named by
`/rename`, `--name` or a hook does not, and `commit` counts "a named row
you cannot place elsewhere" as a peer, under which `land` forbids its
`git switch` and keeps the local branch. On 2026-10-14 a `/land` placed
such a row, a busy `brief: <slug>`, by two indirect checks, both right
and neither a method.

## The method

`never-prompted.sh` already reads the record that answers it: the
session registry, `<config>/sessions/<pid>.json`, matched by `name`,
which carries the session's `cwd` beside the `status`, `sessionId`,
`startedAt` and `updatedAt` the script compares. For a named row, take
its one entry and compare `git -C "<cwd>" rev-parse --show-toplevel`
with this tree's, case-insensitively: the same top level shares this
HEAD, another or none places it elsewhere, and any doubt, such as no
entry, two, or no `cwd`, keeps it a peer, as the script already rules.
`nameSource` says which rows need it: `derived` for the
`<cwd-basename>-<hash>` names, `hook` for this machine's `brief: <slug>`
names.

Three traps, each observed by the note's session on 2026-10-14:

- **One directory has several spellings.** Entries held `c:\Repos\...`
  and `C:\Repos\...`, and one transcript recorded its `cwd` three ways;
  git answered `C:/Repos/...` for the lowercase one, so compare git's
  answers.
- **A linked worktree can sit inside its main checkout**, under
  `.claude/worktrees/`, which a path-prefix match counts as the main
  checkout; git gives it its own top level, and it has its own HEAD.
- **`cwd` is where the session started.** One that runs git in this tree
  by path from elsewhere stays invisible, as it already is to the
  derived names.

Measured here on 2026-10-15: the registry held seven entries, each with
`name`, `nameSource` and `cwd`, two `derived` and five `hook`, and one
`/triage` run placed its six peers by them, four in this tree and two in
a client repo, one of those busy. The registry's format is undocumented,
like the rest of what the script reads.

## Where it lands

- `skills/workflow/land/scripts/never-prompted.sh`, or a sibling reusing
  its registry read and its any-doubt-is-live rule: print each named
  row's `cwd` and whether it shares this tree. Its suite,
  `tests/scripts/never-prompted/`, gains the cases.
- `skills/workflow/land/references/never-prompted-sessions.md` § "The
  two reads": the `cwd`, `nameSource` and worktree findings.
- `skills/workflow/land/SKILL.md` § "1. Preflight", the paragraph on
  reading every row: a named row is placed by that script, not by its
  name.
- `skills/workflow/commit/SKILL.md` § "When another session shares this
  tree", where it defines "a named row you cannot place elsewhere": name
  the method.
- `.claude/skills/triage/SKILL.md` step 1, which reads the same rows.

Both workflow skills are deployed, so each save is live machine-wide;
`skill-status.py --stale` then names the retests owed.

## Re-measure before acting

```bash
grep -n -E 'cwd|nameSource' skills/workflow/land/scripts/never-prompted.sh   # nothing on 2026-10-15
grep -n 'cannot place' skills/workflow/commit/SKILL.md                      # line 171 on 2026-10-15
for f in ~/.claude/sessions/*.json; do jq -b -r '[.name, .nameSource, .cwd] | @tsv' "$f"; done
```
