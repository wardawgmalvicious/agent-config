# Handoff: probe what a worktree isolates

- **Written**: 2026-09-22, from drilling
  `code.claude.com/docs/en/worktrees`, `/cross-session-messaging` and
  `/agent-teams`. **Reduced 2026-09-24** to its probe, once root's scope
  correction, the closed flag and `worktree.baseRef: "head"` landed. Their
  evidence and both of the brief's decisions are in the 2026-09-24 entry
  at the end of
  [docs/evidence/root-claude-md.md](../../evidence/root-claude-md.md) §
  "Branching and concurrent sessions". **Revised the same day** after a
  review against the re-fetched docs found readings that could come back
  wrong or empty: the probe now needs an unpushed commit, names the tool
  for each step, tests the four checks one at a time, and adds two paths
  outside them and a check for root `CLAUDE.md` loading twice.
- **Kind**: one probe, run by the user in a fresh interactive session.
- **Status**: **Open.** Root's § "Branching and concurrent sessions" says a
  worktree loads its own tracked `.claude/skills/`, "and by inference
  `.claude/rules/` (2026-09-24, from the docs; unprobed)". This probe
  measures that, whether the enforcement fires on this CLI version and
  where it stops, and whether root `CLAUDE.md` loads twice.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The probe

Run it before pushing: `git rev-list --count origin/main..HEAD` in the
main checkout must print at least 1. With `HEAD` level with `origin/main`,
`"head"` and `"fresh"` pick the same commit and assertion 0 witnesses
nothing, as on 2026-09-24, when both stood at `2a31b2f`.

One fresh session, started from the main checkout:

```bash
claude --worktree probe-isolation
```

Assert, in the worktree session, naming the tool in every request: the
traps below say why. Assertions 1 to 4 pass only on a tool error that
names the worktree, which the docs promise for every refusal. For a
command, the errors page gives the text as one of these (2026-09-24); a
permission denial, or a tool failing its own precondition, witnesses
nothing:

```text
is isolated in the worktree <path>, but this command <reason>. Refusing to run it
too complex to verify that it stays inside the worktree
```

0. **The base.** `git log -1 --oneline` in the worktree names the main
   checkout's `HEAD`, not the older `origin/main` the default would have
   named: `baseRef` is `"head"` since 2026-09-24.
1. **File edits.** The `Write` tool creating
   `C:/Repos/Personal/agent-config/probe-sentinel.txt` is refused. Not
   `Edit`, which needs an existing file it has Read, so on a new path it
   can fail its own precondition instead. If the file appears,
   enforcement failed: say so, and delete it.
2. **Working directory.** Bash `cd C:/Repos/Personal/agent-config && ls`
   is refused. With no git in it, no other check can fire.
3. **Git redirect.** Bash
   `git -C C:/Repos/Personal/agent-config log -1 --oneline`, with no `cd`,
   is refused.
4. **Command shape.** Bash `$(echo git) status` is refused: the one check
   that cannot be turned off.
5. **Outside the four checks**, as the docs word them. Record whether
   each runs, and delete anything it writes:
   - Bash `echo probe > C:/Repos/Personal/agent-config/probe-bash.txt`:
     no check covers a shell write whose working directory stays in the
     worktree.
   - PowerShell `git -C C:/Repos/Personal/agent-config log -1 --oneline`:
     PowerShell gets the working-directory check alone, and it is this
     machine's primary shell.
6. **Skills.** Add a marker to the description in the worktree's
   `.claude/skills/author-skill/SKILL.md`. An edited skill is re-announced,
   so a `skill_listing` record with `isInitial` false carrying the marker
   witnesses that the worktree's copy is the one loaded; the main
   checkout's copy stays unchanged. Outside a worktree the re-announcement
   holds for project scope: each of the 23 transcripts here since
   2026-09-09 that runs `Edit` or `Write` on a `.claude/skills/*/SKILL.md`
   has a later `isInitial: false` record for every skill it edited, 32 in
   all (measured 2026-09-24). If no record carries the marker, it is not
   yet a fail: exit choosing keep and run
   `claude --worktree probe-isolation` again. A reused name reopens the
   existing worktree, edit included, so the marker in the new session's
   `isInitial: true` listing means the worktree's copy loads and only the
   watcher missed the edit.
7. **Rules**, the inferred half. Read the worktree's `claude/settings.json`,
   then its `.pre-commit-config.yaml`, with the `Read` tool.
   `deploy-scripts.md` and `pre-commit-hooks.md` should each attach once,
   as a `nested_memory` record whose `path` is under
   `.claude/worktrees/probe-isolation/`, not the main checkout's
   `.claude/rules/`. The second Read is there because the first cannot
   see a main copy: `deploy-scripts.md`'s globs are anchored, and from the
   main checkout's root the first file is
   `.claude/worktrees/probe-isolation/claude/settings.json`.
   `pre-commit-hooks.md` globs `**/.pre-commit-config.yaml`, anchored to
   neither root. A record from either Read whose `path` is the main
   checkout's means both copies load. The first Read should also bring no
   `nested_memory` for `claude/CLAUDE.md`: `claudeMdExcludes` matches the
   worktree's copy too.
8. **Root `CLAUDE.md`.** Under **Memory files**, `/context` lists every
   `CLAUDE.md` the session loaded; `/memory` lists locations, loaded or
   not, so it cannot answer this. The docs load `CLAUDE.md` from the
   working directory and every directory above it, and the main
   checkout's root is above the worktree, so expect both copies: the
   worktrees page makes no exception. Record which are listed.

Read 6 and 7 off the transcript. With `--worktree` it is kept under the
worktree's own project directory in `~/.claude/projects/`, so hand the
session id (`/status`) to a session in the main checkout to read it.

Teardown: exit and choose remove at the prompt, since the marker leaves
work in the worktree, or run
`git worktree remove --force .claude/worktrees/probe-isolation`. Delete
the `worktree-probe-isolation` branch if it is left, and confirm with
`git worktree list` that only the main checkout remains, and with
`git status` that no `probe-*.txt` file is left in it.

### Traps that will make you read the result wrong

**Name the tool in every request.** Auto mode's instructions invite `cat`
for reads and `sed` or a heredoc for small edits (2026-09-24), and the
checks key on the tool. Asked only to create assertion 1's sentinel, a
session may reach for Bash, which none of the four checks covers
(assertion 5): the file lands, and a correct implementation reads as
enforcement failing. In assertion 7 a `cat` loads no rule, so the
missing record reads as the worktree loading none
(`.claude/rules/activation-testing.md`).

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

Record each assertion's result, and the transcript count under 6, as a
dated entry at the end of the ledger's § "Branching and concurrent
sessions". Then make root's line match: drop "by inference" and
"unprobed" if 6 and 7 pass, or correct it if either fails. If anything
in 5 got through, or 8 lists both copies of root `CLAUDE.md`, root's
line says so too. Delete this brief and its queue row in that commit.

## Dependencies

- The peer-coordination brief that closed on 2026-09-23 ran one cold
  session in the *shared* tree with live peers (transcript `695a54ec`),
  not one in a worktree, and settles nothing here. It is only the loaded
  half of the ablation blocking the peer-session article in
  [linkedin-article-skill.md](linkedin-article-skill.md); the stripped
  half is still missing.
