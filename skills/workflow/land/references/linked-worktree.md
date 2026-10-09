# From a linked worktree

What changes when the branch lives in a linked worktree — made by
`claude --worktree <name>`, `EnterWorktree` or `git worktree add` —
rather than in the main checkout. Step 1's last command detects one;
read this before step 3.

## Detecting one

```bash
git rev-parse --path-format=absolute --git-dir --git-common-dir
```

A linked worktree prints two paths: its own git dir, under
`<repo>/.git/worktrees/<name>`, then the shared `<repo>/.git`. The main
checkout prints the same path twice from any subdirectory, as does a
submodule, whose git dir under the superproject's `.git/modules/` is its
own common dir (git 2.55.0, 2026-09-29). `git worktree list` names every
tree, and cannot say which one you are in.

## Before step 3: a generated branch name

`claude --worktree <name>` and `EnterWorktree` put the worktree on a new
branch, `worktree-<name>` (code.claude.com/docs/en/worktrees, read
2026-09-29). That name reaches the PR and any merge title, so rename it
before the push, per `~/.claude/CLAUDE.md` § "Branch naming":

```bash
git branch -m <type>/<kebab-slug>
```

The worktree's directory keeps its name, and whatever keys on the
directory keeps working (a client repo, 2026-09-27). Steps 2 to 6 then
run from the worktree unchanged, and step 6 names the tree step 7 writes
from.

## Step 7: `main` is checked out elsewhere

The main checkout holds `main`, and git will not move a branch another
tree has checked out. From a linked worktree `git switch main` exits
128, `fatal: 'main' is already used by worktree at '<path>'`, so the
default route stops at its switch (git 2.55.0, 2026-09-27, again
2026-09-29); `git branch -f main`, `git fetch . <branch>:main` and
`git push . <branch>:main` were refused too (2026-09-27).

**From the worktree, take the write that needs no checkout**: the
refspec push where `main` requires no pull request, the PR merge where
it requires one. **Pin the push by its SHA, as two plain commands**: the
`EnterWorktree` guard refuses the route's `[[ … ]] && git push` as too
complex to verify that it stays inside the worktree, as it does
`commit`'s chain (2.1.294, 2026-10-08).

```bash
git rev-parse <branch>                    # must print <sha>; stop if not
git push origin <sha>:refs/heads/main     # pushes exactly <sha>
```

What was checked is what goes, even if the branch moves after the read;
a push to a branch still takes only a fast-forward (git-push § "PUSH
RULES"), and the pre-push hooks still run. Spell the destination in
full: git expands a short one only when it "unambiguously refers to a
ref" on the remote, or from the source ref's namespace, which a SHA
lacks (git-push, read 2026-10-09).

The push goes through from a worktree. It leaves the
main checkout's `main` behind `origin/main`, and a commit made there
before it catches up diverges, so step 8's report names the fix, to run
in the main checkout:

```bash
git merge --ff-only origin/main
```

**From the main checkout, when the user asks for it.** `ExitWorktree`
with `keep` returns the session there, leaving the worktree and branch
on disk. Its description scopes it to worktrees `EnterWorktree` made,
and to when the user asks; it worked on a `claude --worktree` launch too
(2.1.282, 2026-09-29). Run `ListAgents` first, since that tree may be
shared. HEAD there is already `main`, so the default route drops its
switch, and its guard checks for `main`:

```bash
[[ "$(git branch --show-current)" == "main" && "$(git rev-parse <branch>)" == "<sha>" ]] \
  && git merge --ff-only <branch> && git push origin main
```

Without that ask, take the worktree's route above, or hand the user this
command to run there.

## Step 8: verify against `origin/main`

Step 8's ancestor check and merge count read `origin/main` against the
pins, so they run from the worktree unchanged. Its local-`main` line
does not: `git fetch origin main:main` is refused wherever another tree
has `main` checked out, `fatal: refusing to fetch into branch
'refs/heads/main' checked out at '<path>'`, exit 128, and moves no ref
(again 2026-09-29). Skip that line and `git rev-parse main origin/main`;
step 7's catch-up in the main checkout brings its `main` current.

## Step 9: the worktree goes before the branch

Git will not delete a branch a worktree has checked out, from either
side: `git branch -D` exits 1, `error: cannot delete branch '<branch>'
used by worktree at '<path>'` (2026-09-29).

- **The remote half runs from the worktree** as step 9 has it.
- **The local half waits for the worktree's removal**, from the main
  checkout:

  ```bash
  git -C <worktree> status --short             # anything here is on no branch
  git worktree remove <worktree>               # refuses a dirty tree, and a locked one
  git merge-base --is-ancestor <branch> <sha> && git branch -D <branch>
  ```

  A dirty tree is refused, `contains modified or untracked files, use
  --force to delete it`, exit 128: never add the `--force`, which
  discards that work. A worktree Claude Code made is locked while its
  session runs, and the refusal's lock reason names that session and its
  pid: leave a live one alone, and see `prune-branches` for a lock whose
  pid is dead. `ExitWorktree` `keep` released the lock, so a session that
  came back that way removed its own worktree (2.1.282, 2026-09-29).
- **Otherwise keep both** and say so, handing the user those commands
  for once the session has ended. At `/exit` a worktree holding commits
  is offered keep or remove, and remove deletes the branch with its work
  (code.claude.com/docs/en/worktrees, read 2026-09-29).
- **`ExitWorktree` `remove` is no substitute.** It refuses while the
  branch holds commits not on the original one, and after `git branch -m`
  it removed the worktree and left the renamed branch, saying nothing of
  it (2.1.282, 2026-09-29).
