---
status: open
priority: 2
needs: [user]
blocked-by: []
written: 2026-09-27
---

# Handoff: `land` from a worktree, and the text GitHub writes for it

- **Written**: 2026-09-27, at the user's request, from two sources: step
  4 of [queue-state-per-brief.md](queue-state-per-brief.md), which sent
  parallel briefs to worktrees and left `/land` no route for one, and the
  two `land` learnings a client repo's session sent to the inbox that
  day, moved here. The note keeps its `commit` and Bicep learnings for
  `/learn`.
- **Kind**: edits to `skills/workflow/land/`, then `/test-skill land`.
  Items 2 and 3 are decided; item 1 has one question for the user.
  Nothing is drafted.

## 1. A branch in a linked worktree has no route

Root `CLAUDE.md` § "Branching and concurrent sessions" has sent a brief
worked in parallel to `claude --worktree <brief>` since `a7754da`, to be
landed and deployed from the main checkout. `/land` did not change with
it.

**What git does from a worktree**, measured 2026-09-27 on git 2.55.0:

- Git will not move `main` there: `git switch main` exits 128, "'main'
  is already used by worktree at", and three other ways of moving it
  refuse too, quoted in the step 4 entry of
  `docs/evidence/root-claude-md.md`. Step 7's default opens with that
  switch.
- Against a scratch origin, step 7's no-checkout row,
  `git push origin <branch>:main`, succeeds from the worktree, but step
  8's `git fetch origin main:main` exits 128, "refusing to fetch into
  branch 'refs/heads/main' checked out at". The main checkout's `main`
  stays behind `origin/main` until that checkout runs
  `git merge --ff-only origin/main`, and its next serial commit diverges
  if it does not.
- From the main checkout, step 9's `git branch -D <branch>` exits 1,
  "cannot delete branch … used by worktree at", while the worktree
  exists; after `git worktree remove`, `-d` deletes it.

**What a worktree session can do about it.** Its guard stops `Write` and
Bash's `git -C` into the main checkout, and a `cd` out strands it (root
`CLAUDE.md`, probed 2026-09-24); the gaps root lists are no route.
`ExitWorktree` returns the session to the main checkout: `keep` leaves
the worktree and branch, and `remove` deletes both, refusing while the
branch holds commits not on the original one. Its own description allows
it only when the user asks. Not checked: whether it acts on a worktree
made by `claude --worktree` at launch rather than by `EnterWorktree`, and
whether `remove` still finds a renamed branch.

**A proposed shape**, for the session to confirm or better:

- Step 1 notices a linked worktree: its git dir differs from the common
  one (`git rev-parse --git-dir --git-common-dir`), or `.git` is a file
  whose `gitdir` runs through `.git/worktrees/`, the check
  `link-claude.ps1` makes (`ac3d22e`).
- A branch named `worktree-<name>`, as `claude --worktree` names it, is
  renamed to `<type>/<slug>` before step 3's push, per `claude/CLAUDE.md`
  § "Branch naming": the name reaches the PR, and item 3's merge title.
  The in-flight claim keys on the worktree's directory, so the rename
  keeps it: a client repo's session renamed one on 2026-09-27
  (`docs/evidence/user-claude-md.md` § "Branch naming").
- Steps 2 to 6 run from the worktree unchanged; step 6 names the route.
- Step 7 writes `main` from the main checkout: on the user's ask, through
  `ExitWorktree` `keep` and the default route there, with `ListAgents`
  first, since that tree may be shared; otherwise by handing the user the
  guarded commands to run there. If the refspec push is taken instead,
  the report says the main checkout needs
  `git merge --ff-only origin/main` before its next commit or deploy.
- Step 8 compares `origin/main` with `<sha>` after `git fetch origin`
  wherever `main:main` is refused.
- Step 9 removes the worktree before deleting the branch, and only once
  its session has ended by `ListAgents` and its tree is clean; otherwise
  it keeps both and says so. Removal also ends the claim
  `handoff-status.py` reads.
- In this repo the deploy follows the merge, from the main checkout,
  since `link-claude.ps1` refuses a worktree.

**The question for the user: does `/land` also land locally?** Here,
serial work commits to `main` and nothing is pushed unasked, so a
finished worktree needs only `git merge --ff-only <branch>`, the deploy,
`git worktree remove` and `git branch -d`, all in the main checkout.
`/land` always pushes and opens a PR, and its step 5 calls a local merge
a way to lose review and CI. Either `/land` gains a local mode for a repo
whose instructions say to commit straight to `main`, stopping before the
push unless one was asked for, or those four commands go to
`docs/handoffs/CLAUDE.md` and `/land` stays outward-only.

## 2. A 404 on a private repo, after step 2 matched, is capability

**Problem.** Step 2's "A confirmed identity is not a confirmed
capability" names only a 403, and `claude/CLAUDE.md` § "Git identity is
folder-scoped" says to read a 404 as identity first. In a client repo on
2026-09-27, github-mcp's `get_me` matched the work account and the repo's
owner, then `create_pull_request` and `pull_request_read` on the org's
private repo both returned `404 Not Found`, a write and a read, while
the same token read a public repo's pull request. `gh`, confirmed as the
same account, opened the PR. The token was fine-grained and awaiting an
organization owner's approval.

**Cause.** GitHub answers 404 rather than 403 where a token cannot see a
private repo, so as not to confirm that the repo exists, and a
fine-grained token awaiting approval reads public resources only. Two
causes then look alike: the wrong account, or the right one holding a
token that cannot reach the repo, through its resource owner, its
repository selection or a pending approval. The session cited
docs.github.com's "Troubleshooting the REST API" and "Managing your
personal access tokens", read 2026-09-27: re-read both before quoting
either.

**Edit.** Extend step 2's capability paragraph: once step 2 has matched
the identity, a 404 on a private repo reads as the 403 does, the token's
reach, with the same fallback to the confirmed `gh`, and one call with
the same tool on a public repo tells the two causes apart.
`claude/CLAUDE.md` stays as it is: identity first is still right for the
`gh` wrapper's fall-through, and `land` is where the capability reading
belongs.

**Not checked.** Whether a GraphQL-backed call shows this case as
`Could not resolve to a Repository`, the wrong account's form in `gh`;
and whether an approved token whose selection omits the repo fails the
same way, as the docs' checklist implies.

## 3. The merge-commit route lets GitHub write the org's name into `main`

**Problem.** Step 7's pull-request row,
`gh pr merge <n> -R <owner>/<repo> --merge --match-head-commit <sha>`,
sets no message, so GitHub composes it from the repo's
`merge_commit_title`. Its default, `MERGE_MESSAGE`, titles the commit
"Merge pull request #N from `<owner>/<branch>`", and on an
organization's repo the owner is the org's account name, in `main` for
good. Measured on a client repo, 2026-09-27: its two earlier merges
through that row carry the org's name, and the two landed that day with
`--subject` do not.

**Weight.** The user said on 2026-09-27 that the concern is the name
reaching repos outside the org; inside its own repos the title is
tolerated, and the local denylist exempts the work root for that reason.
What remains is `claude/CLAUDE.md`'s "in any repo", and that a message
the server writes is the one path no local check sees: `identity-guard`
reads only Claude Code's commits.

**Edit.** `references/integration-routes.md` § "Merge commit — one
clause and proceed" carries the message over, as its squash section
already does: `--subject "Merge pull request #<n> from <branch>"` and
`--body "<PR title>"` for `gh`, `commit_title` and `commit_message` for
`merge_pull_request`. Step 7's row gains the two flags or a pointer to
that paragraph. Setting a repo's `merge_commit_title` to `PR_TITLE` is
the per-repo alternative: a settings change, so the user's call. The
general form: wherever the server would compose a message, a merge
title, a squash body or a revert title, the skill composes it instead.

**Not checked.** `merge_pull_request` with no `commit_title`, which the
repo setting should decide the same way.

## Verification

- `uv run --with pyyaml scripts/skill-status.py --stale` lists `land`
  after the body edit, and `/test-skill land` clears it.
- Item 1's route is proved in a scratch clone with a bare origin and a
  linked worktree, each step 7 route and step 9 run from both sides, as
  the measurements above were.
- `pre-commit run --all-files` passes.

## Scrubbing

This repo is public. The client org, its repo and its account stay out
of every file and commit message; cite "a client repo".
