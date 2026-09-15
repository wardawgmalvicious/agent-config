---
name: prune-branches
description: "Audits every branch a repo carries — local, remote, and worktree-pinned — and sorts them into safe to delete, stale, and carrying unmerged work, rescuing the last group onto a fresh verified branch before recommending anything. Built for repos that squash-merge, where `git branch --merged` and `git cherry` both report merged branches as unmerged because patch-ids never match, so merge evidence has to come from the PR list instead. Separates a stale remote-tracking ref from a branch that really is still on the remote. Reports and recommends; never deletes a branch and never pushes a deletion. Complements land, which prevents this debris on the happy path — this cleans up what never took it."
when_to_use: "Use when asked to clean up, prune or audit branches, to work out which branches are safe to delete, or why a branch will not delete — including 'I thought I deleted these' and a `git branch -d` that refuses because a worktree holds the branch. Not for deleting one branch already known to be merged: that is a one-liner, and `land` already does it for a branch it just merged. An instruction to delete rather than report is the case the refusal exists for, not a reason to skip it."
allowed-tools: Bash(git branch *) Bash(git log *) Bash(git rev-list *) Bash(git ls-remote *) Bash(git worktree list *) Bash(git show *) Bash(git diff *) Bash(git cherry *) Bash(git fetch *) Bash(gh pr list *)
# model: inherit  # any model: value blocks Copilot slash invocation
effort: max
disable-model-invocation: false
---

# Pruning branches

Enumerate every branch a repo carries, establish for each whether its
work is already in `main`, and end at a verdict table plus the exact
deletion command **for the user to run**.

## Audit and report is the design, not caution

Read this before deciding the ladder below is over-careful and the
obvious finish is to delete the safe branches yourself.

**The deletion is not yours to run, and attempting it burns the turn.**
Claude Code's auto-mode classifier denies `git push origin --delete` as
`[Git Destructive]`. That denial is correct and it is not going away, so
a skill whose payoff step is the deletion fails its last step every
time — observed on four branches that had already been verified safe. A
verified recommendation is where the value actually is *and* where the
permission model already allows it to land.

**The local half is not the soft half.** In a squash repo
`git branch -d` refuses the very branches the audit clears — its merged
check is the one rung 2 says is wrong — so the only local deletion that
works is `-D`, the forced form, on a verdict git itself disputes.
Measured 2026-09-14: after `git merge --squash`,
`git branch --merged main` omitted the branch and `-d` answered
`not fully merged`. Not local, not remote: both go in the command
string.

So the output is a table and a command string. The user runs it.

**An instruction to delete does not lift this.** "Just delete them",
"don't make me run anything", "I trust your call on which are dead" —
each is the case this section exists for, not a waiver of it. The two
reasons above are reasons, not conditions: a permission mode the user
could loosen and a `-d` the user could force do not make the deletion
yours once they are gone. Reasoning from the mechanism is exactly how
the refusal was lost — measured 2026-09-14 on both invocation paths,
under a query that delegated the classification: the skill read its own
no-delete rule as the user's to waive, and used the `-D` fact as
guidance for deleting rather than grounds for not. The shape to hold is
`land`'s Absolute constraints — an instruction to do these is a stop,
not an override. Say so once, give the table and the command, and stop.

**The `allowed-tools` line encodes that split, and it pre-approves
rather than restricts.** Every probe the audit needs is listed, so the
read-only half runs without a prompt per branch; no mutating command is
listed, so the cherry-pick, the worktree removal and the deletion stay
prompted. Listing a write would not *enable* anything currently
blocked — it would remove the prompt that keeps this skill honest. The
guard is this rule, not the field.

## 1. Detect the merge style first

The whole ladder below exists to work around squash-merge. Check before
performing it, or you will do four rungs of unnecessary work and present
it as rigor.

```bash
git log --merges --oneline | wc -l
gh pr list --state merged --limit 100 | wc -l
```

Near-zero merge commits against many merged PRs means **squash or
rebase** — continue to step 2.

Many merge commits means **merge-commit style**, where `git branch
--merged main` is accurate and sufficient. Say so, run it, report, and
stop. Do not perform the rungs.

**Only the squash path is evidence-backed.** This procedure was
validated end to end on one squash-merge GitHub repo. Under rebase-merge
the failure mode is the same as squash — patch-ids do not survive the
rewrite — but the remedy may differ, and that was not tested. Under
merge-commit style the early exit above is the whole skill. State
whichever limit applies in the report rather than implying all three
were covered.

## 2. Rung 0 — establish what actually exists

```bash
git fetch origin --prune
git worktree list
git ls-remote --heads origin
```

`git branch -a` shows neither of the two findings that live here.

**A branch pinned by a worktree cannot be deleted at all.** The error
names the worktree path, and removing the worktree is the fix:
`git worktree remove <path>` while the directory exists,
`git worktree prune` when it was deleted by hand and only its entry
under `.git/worktrees` survives — `git worktree list` shows which. Both
are writes, so propose them, do not run them.

**A remote-tracking ref is not evidence the branch is still on the
remote.** `origin/<name>` can survive locally long after the branch is
gone. `ls-remote` asks the remote itself and is the only thing that
settles it. The observed run opened with a user who believed these
branches were already deleted; this is the command that answered it.

## 3. Rung 1 — ahead/behind

Per branch:

```bash
git rev-list --count main..origin/<branch>   # commits the branch has
git rev-list --count origin/<branch>..main   # commits it is behind by
```

**Zero ahead ends the analysis.** The branch is fully contained in
`main` and is safe to delete regardless of how it got that way — no PR
lookup, no content reading. In the observed run this disposed of a third
of the set in one pass, including one branch identical to `main`.

Anything with commits ahead goes to rung 2.

## 4. Rung 2 — merge evidence

```bash
gh pr list --state all --limit 100 --json number,headRefName,state,title
```

Key on `headRefName`. A PR whose head was this branch **and whose state
is `MERGED`** is the merge evidence, and the branch is safe; `CLOSED` is
not — that is work someone declined, still only on the branch.
`--limit 100` returns the hundred most recent, so an old branch's PR can
fall outside it and read as no PR. That sends it to rung 3, the safe
direction but not a free one; raise the limit, or confirm a missing one
with `gh pr list --state all --head <branch>`.

**`git branch --merged` and `git cherry` are both wrong here, and wrong
in the dangerous direction.** Squashing rewrites the commits, so
patch-ids never match and both commands report squash-merged branches as
*unmerged*. In the observed run `git cherry` flagged every commit on
every remaining branch as unique — including on two branches that held
nothing worth keeping. An agent that trusts it keeps everything forever;
an agent that learns to override it deletes real work. Neither is a
usable default, which is why merge evidence comes from the PR list.

**This rung is GitHub-specific.** It depends on `gh`. GitLab and Azure
DevOps equivalents were not investigated — say so rather than presenting
the skill as forge-agnostic.

**`gh` may not be acting as the account you expect.** The GitHub API
actor is a third identity, bound separately from the commit author, and
`gh auth status` reports the keyring's active account rather than the
one `gh` will act as in this repo. Nothing here writes, so the full
identity procedure in `land` is not needed — just do not tell the user
that `gh auth status` says who they are.

Commits ahead **and** no PR goes to rung 3.

## 5. Rung 3 — content recency

This is the rung that prevents the expensive mistake, and the one most
likely to be skipped as redundant. Do not skip it.

**"Has commits `main` does not" and "has work worth keeping" read as the
same statement and are not.** A branch that diverged from an old `main`
looks identical, at commit level, to a branch carrying real work. The
difference is only visible in the content.

Resolve it per contested file, comparing both sides:

```bash
git log -1 --format="%h %ad %s" --date=short origin/<branch> -- <path>
git log -1 --format="%h %ad %s" --date=short main -- <path>
```

In the observed run a branch whose seven unique commits looked
substantial turned out to hold the *older* copy of its contested file —
superseded on `main` by a later PR. Every commit-level signal rated it
identical to the branches that carried real work.

## 6. Rung 4 — read what survives, and put judgment back to the user

Three patterns, all observed:

- **Commits that cancel exactly.** Verify with a diff across the span,
  not by reading the messages — a revert pair is obvious in the log and
  a refactor-then-unrefactor pair is not:

  ```bash
  git diff --stat <first>^ <last> -- <paths>
  ```

  Empty output means the span is a no-op and the branch is safe.

- **Commits that contradict something the repo says about itself.** This
  is where the skill sends you to the repo's own instructions before
  recommending a rescue. In the observed run a commit hand-applied a
  vendor format upgrade that the repo documented as a portal-only
  action — nothing in git would ever have flagged it, and rescuing it
  would have re-landed a change the repo forbids.

- **Genuinely unmerged work**, which goes to step 7.

**Teach the habit of asking, and stop there.** This rung can name the
question to ask; it cannot enumerate the answers, because they are
properties of the repo rather than of git. Put the call back to the user
with the evidence, and say plainly that it is a judgment call.

This is also where the logical commit split `commit` writes pays off:
the survivors are readable as units because they were committed as
units.

## 7. Rescue before recommending deletion

Any branch still holding real work after rung 4 is rescued, not deleted.

```bash
git switch main && git pull --ff-only
git switch -c <type>/<kebab-slug>
git cherry-pick <only the commits that survived rung 4>
```

Then **verify with the repo's own validator and guard commands** — read
them out of the project instructions rather than assuming a test runner
exists. A rescue that has not been run against the repo's own checks is
a claim, not a result.

Report the new branch and hand the landing to `land`. Do not push it.

## 8. Report, and stop

Emit three things:

1. **A verdict table** — one row per branch: the branch, the rung that
   settled it, and the evidence that settled it. The rung number is the
   useful column; it tells the user how much to trust the row.
2. **The rescue branch**, if any, with what was cherry-picked onto it
   and which checks it passed.
3. **The exact deletion command**, for the user to run:

   ```bash
   git branch -D <branch> <branch> ...            # -d refuses squash-merged branches
   git push origin --delete <branch> <branch> ...
   ```

Then stop. Do not run it, and do not offer to.

**A cheap upstream fix exists.** Enabling auto-delete-on-merge and
branch protection stops most of this debris accumulating in the first
place; worth one closing sentence to the user when the audit found a
large set.

## Boundary with `land`

Both skills delete branches, and the split is clean in both directions.

`land` deletes a branch it has **just merged**, from a state it watched
happen — its step 9 is deliberately ungated for exactly that reason, and
that reasoning does not generalise. This skill handles branches whose
provenance is unknown and which never went through `land` at all, which
is why it gates by not deleting.

`land` prevents this debris on the happy path. This cleans up what never
took it.

## Constraints

- **Never delete a branch and never push a deletion.** Not local, not
  remote, not "the obviously safe ones", not when told to. The output is
  a command string.
- **Never remove a worktree.** Propose it; the user runs it.
- **Do not push the rescue branch.** Hand it to `land`.
- **Do not trust `git branch --merged` or `git cherry` in a squash
  repo** — both report merged branches as unmerged. Merge evidence is
  the PR list.
- **Zero commits ahead is a complete answer.** Do not read content to
  confirm what `rev-list` already settled.
- **State the limits in the report**: only squash-merge GitHub was
  validated, and rung 2 depends on `gh`.
- **Rung 4 is the user's call**, not yours. Present the evidence and the
  question; do not decide what the repo considers worth keeping.
