# Handoff: probe what a worktree isolates

- **Written**: 2026-09-22, from drilling
  `code.claude.com/docs/en/worktrees`, `/cross-session-messaging` and
  `/agent-teams`. **Reduced 2026-09-24** to its probe, once root's scope
  correction, the closed flag and `worktree.baseRef: "head"` landed. Their
  evidence and both of the brief's decisions are in the 2026-09-24 entry
  at the end of
  [docs/evidence/root-claude-md.md](../../evidence/root-claude-md.md) §
  "Branching and concurrent sessions".
- **Kind**: one probe, run by the user in a fresh interactive session.
- **Status**: **Open.** Root's § "Branching and concurrent sessions" says a
  worktree loads its own tracked `.claude/skills/`, "and by inference
  `.claude/rules/` (2026-09-24, from the docs; unprobed)". This probe
  measures that, and whether the enforcement fires on this CLI version.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The probe

One fresh session, started from the main checkout:

```bash
claude --worktree probe-isolation
```

Assert, in the worktree session:

0. **The base.** `git log -1 --oneline` in the worktree names the main
   checkout's `HEAD`, unpushed or not: `baseRef` is `"head"` since
   2026-09-24, and the default would have named `origin/main`.
1. An `Edit` creating a main-checkout path, such as
   `C:/Repos/Personal/agent-config/probe-sentinel.txt`, is refused, and
   the refusal names the worktree. If the file appears, enforcement failed:
   say so, and delete it.
2. A Bash command that `cd`s to the main checkout and runs git is refused.
3. The command-shape check fires on a computed command name, such as
   `$(echo git) status`: the one check that cannot be turned off.
4. **Skills.** Add a marker to the description in the worktree's
   `.claude/skills/author-skill/SKILL.md`. An edited skill is re-announced,
   so a `skill_listing` record with `isInitial` false carrying the marker
   witnesses that the worktree's copy is the one loaded; the main
   checkout's copy stays unchanged.
5. **Rules**, the inferred half. Read the worktree's `claude/settings.json`:
   `deploy-scripts.md` attaches as a `nested_memory` record whose `path` is
   under `.claude/worktrees/probe-isolation/`, not the main checkout's
   `.claude/rules/`. The same Read should bring no `nested_memory` for
   `claude/CLAUDE.md`: `claudeMdExcludes` matches the worktree's copy too.

Read 4 and 5 off the transcript. With `--worktree` it is kept under the
worktree's own project directory in `~/.claude/projects/`, so hand the
session id (`/status`) to a session in the main checkout to read it.

Teardown: exit and choose remove at the prompt, since the marker leaves
work in the worktree, or run
`git worktree remove --force .claude/worktrees/probe-isolation`. Delete
the `worktree-probe-isolation` branch if it is left, and confirm with
`git worktree list` that only the main checkout remains.

### Two traps that will make you read the result wrong

**Do not run `link-claude.ps1` at any point in this probe.** The
2026-09-02 measurement, in the ledger, records the trap: running the
main tree's copy with `-ClaudeDir <worktree>` relinks every junction
back to the main tree, reporting `Relink` and ending `Done`. This probe
is about project scope and file enforcement, not payload deployment, and
the linker can only contaminate it.

**The workflow skills still being the main tree's files is not an
enforcement leak.** `~/.claude/skills/<name>` is a junction into the
**main checkout's** `skills/`, so a worktree session's `commit`, `land`
and `learn` are the main tree's copies, and a `SKILL.md` edit in the
worktree changes nothing live. That is the 2026-09-02 shadowing result
holding, exactly as documented, and reading it as the enforcement
failing would report a false negative on a correct implementation.

## When it has run

Record each assertion's result as a dated entry at the end of the
ledger's § "Branching and concurrent sessions". Then make root's line
match: drop "by inference" and "unprobed" if 4 and 5 pass, or correct it
if either fails. Delete this brief and its queue row in that commit.

## Dependencies

- The peer-coordination brief that closed on 2026-09-23 ran one cold
  session in the *shared* tree with live peers (transcript `695a54ec`),
  not one in a worktree, and settles nothing here. It is only the loaded
  half of the ablation blocking the peer-session article in
  [linkedin-article-skill.md](linkedin-article-skill.md); the stripped
  half is still missing.
