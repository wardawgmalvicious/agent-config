# Deleting the merged branch

Everything behind step 9: why the deletion is safe enough to run
without its own gate, why the remote ref is probed rather than inferred,
and why the prune runs on both paths.

Step 9 carries the commands, the `-d` rule, the ancestor guard and the
exception list. This file carries the reasoning and the evidence — read
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

## Why `-d` and the ancestor check are not the same guard

**`-d`, never `-D`.** It refuses a branch that is not fully merged, so
the local half guards itself and the check costs nothing. It also
refuses the branch you are *on* — so on the no-checkout route it
succeeds only because HEAD is elsewhere, which is the same condition
that made that route legal in the first place.

**The remote half has no such guard, which is what the ancestor check
is for.** `-d` answers off the *local* merge whatever is on `origin`, so
a commit someone pushed to the branch after step 3 is invisible to it —
and GitHub's *Restore branch* restores the PR's merge-time head, not
that commit. `--is-ancestor` exits non-zero to mean *no*: that is the
answer, not a broken command. A *no* is a stop worth reporting rather
than a failure to retry — someone pushed to this branch after you landed
it, and that work is not in `main`.

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
Non-empty means the delete is yours, and the `--is-ancestor` guard
applies. This is step 2's `gh api user -q .login` move again: probe the
thing, not the thing that usually implies it. A ref probe also has no
`null` state, which that setting does when read unauthenticated. Keep
treating *"remote ref does not exist"* as success if it still appears —
probing narrows the window, it does not close it.

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
