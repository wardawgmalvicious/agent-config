# Deleting the merged branch

Everything behind step 9: why the deletion is safe enough to run
without its own gate, why both halves key on the SHA step 7 pinned, what
HEAD on the branch needs, why the remote ref is probed rather than
inferred, and why the prune runs on both paths.

Step 9 carries the commands, the SHA key, the lease and the exception
list. This file carries the reasoning and the evidence — read
it when the run hits an exception, when the probe comes back in a state
the step did not predict, or when deciding whether the step's argument
still holds in a repo unlike the one it was written against.

## Why this is cleanup rather than a judgement call

Step 8 has just proven the merge — the PR reads as merged, step 7's
integration succeeded, `main` and `origin/main` at one SHA — so the
branch holds nothing that is not in `main`. That is what makes this
cleanup, and it is the argument for `land` owning it: any other tool
would have to establish from cold what this step has just watched
happen.

**That holds in a shared repo too**, which is the part worth spelling
out: step 3's push would have been *rejected* as non-fast-forward had
`origin/<branch>` carried commits the local branch lacked, so the run
would never have reached here. A colleague therefore has nothing on this
branch to lose — their own local copy is untouched, and their next
`git fetch --prune` drops a remote-tracking ref to a branch that is
merged. Reviewers lose nothing either: the PR, its diff and its comments
outlive the branch. The residual risk is not "someone else works here",
it is the specific exceptions step 9 names.

## Why this outward action is not gated like the other two

It is cheap *here specifically*: the commits are already reachable from
`main`, the PR and its diff outlive the branch, and the branch is
restorable from the PR page. None of that transfers to a remote delete
in any other context. Read this as an exemption for a ref just proven
redundant, not as a general licence to skip a gate because an action
looks routine.

## Why both halves key on the pinned SHA

**Reachability from `main` is the wrong question after a squash or a
rebase.** Both write new commits, so the branch's own SHAs are
unreachable from `main` while every change is in it. The two guards
step 9 used to run each tested reachability — `-d` for the local half,
`git merge-base --is-ancestor origin/<branch> main` for the remote — so
after a squash both said *not merged* about a merged branch, and the
ancestor check's reading, "someone pushed to this branch after you
landed it", reported a foreign push that never happened.

**`-d` was worse than wrong: it was intermittent.** It tests *merged
into its upstream* when one is set, and HEAD only when none is — a
controlled pair on git 2.55.0.windows.3, 2026-09-22:

```text
CASE A — remote-tracking upstream still present
  git branch -d feat/x -> exit 0
      warning: ... merged to 'refs/remotes/origin/feat/x',
               but not yet merged to HEAD

CASE B — same squash, remote deleted and pruned
  git branch -d feat/x -> exit 1
      error: the branch 'feat/x' is not fully merged
```

Case A reproduced 2026-09-23 on a two-commit squash. With its upstream
present `-d` passes whatever `main` holds, because step 3's push already
made "merged into its upstream" true; pruned, a squash defeats it. Step
9 ran `-d` *before* its prune, so which case a run got depended on repo
settings and fetch history — and the passing runs taught that the guard
worked.

**A patch-id check does not rescue it.** `git cherry` marks a commit `-`
only when some upstream commit carries the same patch, and a squash of
two or more commits carries none of them: after a two-commit squash it
printed `+` for both (2026-09-23). `prune-branches` reaches the same
verdict for squash repos and takes merge evidence from the PR list; this
step already holds the stronger form of that evidence — the head the
merge was pinned to.

**`<sha>` answers the actual question, on every route.** Locally,
`--is-ancestor <branch> <sha>` asks whether every local commit is inside
what merged: true after a fast-forward, a merge commit, a squash or a
rebase alike, and false exactly when a commit reached the branch after
the pin. Behind it `-D` is safe, and it is one command. The `-d || -D`
pair that might otherwise stand in fails whenever `-d` already succeeded
— `error: branch '<name>' not found` — and in an `&&` chain that skips
everything after it.

On the remote, the lease makes the delete itself conditional on
`origin` still holding exactly what merged. Measured 2026-09-23 against
a bare remote: a delete expecting a SHA the remote had moved past was
refused `! [rejected] (delete) -> feat (stale info)`, exit 1, and the
same delete expecting the current SHA went through. That refusal is the
real *someone pushed after the merge* case — and GitHub's *Restore
branch* restores the PR's merge-time head, not that commit.

**Run the two halves as separate commands.** Chained, one half's
refusal silently skips the other: measured 2026-09-22, a chain of local
delete, remote delete and prune lost both remote steps and reported
success, and only the branch listing showed it.

## HEAD on the branch

`-D` refuses the branch HEAD is on —
`error: cannot delete branch '<branch>' used by worktree at '<path>'`,
exit 1 (2026-09-23) — and step 7's PR merge leaves HEAD there whenever
you hold the tree, so on that route this is the ordinary case rather
than an edge. The move it needs is a HEAD move like any other: behind a
fresh `ListAgents` and a same-command HEAD check, and never made just so
the delete succeeds while anyone else is live. That improvised switch is
the 2026-09-22 failure step 1 records — made for cleanup, after the one
peer checked had ended. The text it replaced assumed the no-checkout
route always leaves HEAD elsewhere, when that route is chosen because a
peer is live and HEAD can still be on your branch.

## Why the remote ref is probed, not inferred

**Probe the remote ref; do not infer it from `delete_branch_on_merge`.**
Step 7 reads that setting for *planning* and for the step 6 disclosure,
which is the right thing to read there. It is the wrong thing to act on
here, because it is a read at one time driving an action at another and
the value can change in between — including by the operator, mid-run,
between two gated steps. Observed 2026-09-16: it read `false` at step 7,
was flipped to `true` before the merge, and **took effect on the PR
already open**. GitHub deleted the head branch itself, and
`git fetch --prune` reported `- [deleted] (none) -> origin/<branch>`.
The setting is not uniform either — measured 2026-09-13 on two repos
with opposite values.

`git ls-remote --heads origin <branch>` answers the question this step
actually has. **Empty means GitHub already deleted it**: nothing to do,
and say *that* in the report rather than claiming the session deleted
it. The action was right either way — the skill already tolerates the
error — but the report is what a later session reads to decide whether
the cleanup happened, and it should not describe work it did not do.
Non-empty means the delete is yours, behind the lease. This is step 2's
`gh api user -q .login` move again: probe the thing, not the thing that
usually implies it. A ref probe also has no `null` state, which that
setting does when read unauthenticated. Keep treating *"remote ref does
not exist"* as success if it still appears — probing narrows the
window, it does not close it. The lease answers a vanished ref with that
same `error: unable to delete '<branch>': remote ref does not exist`,
exit 1, as a plain delete does, so it stays distinct from the lease's
own `(stale info)` refusal (measured 2026-09-23).

## Why the prune runs on both paths

Where GitHub auto-deleted the branch, `origin/<branch>` is gone from the
remote and this clone's *remote-tracking* ref to it is not:
`git branch -a` still lists it, and a plain `git fetch` will not remove
it. That is the leftover ref this step exists to prevent, one
indirection out — and it survives precisely where the step did the least
work. Observed 2026-09-13 on the first real run of this step, against a
repo with `delete_branch_on_merge: true`.

## Keeping the branch is an override that costs nothing

**Deleting the merged branch is a default too, and it runs the other
way** from the step 7 mechanisms. Step 9 does it having disclosed it at
step 6, so the request that arrives is to *keep* the branch — and that
one costs nothing to honour. It needs no cost-and-wait round; it is
simply one of the exceptions step 9 already names. Say in the report
that the branch was kept and why, or the next run reads the leftover ref
as a bug.
