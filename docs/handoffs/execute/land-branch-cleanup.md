# Handoff: branch cleanup as the last step of `land`

- **Written**: 2026-09-13, out of a session in a consuming repo that ran
  `/land` twice in one sitting and left four refs behind — two local,
  two on origin — which the user had to notice and ask to remove.
- **Kind**: one edit to
  [skills/workflow/land/SKILL.md](../../../skills/workflow/land/SKILL.md)
  — a new step after verification, one key added to a probe step 7
  already runs, and a **rewrite** of the Constraints clause that
  half-covers this today. Not a new artifact.
- **Status**: **open, written 2026-09-13.** Nothing is drafted.
- **Run in**: this repo, in a fresh session.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## Why: the skill's last action is a report, and the refs stay

`land` ends at step 8 by reporting merged state and CI. Nothing removes
the branch, so every clean run leaves two refs. Two runs on 2026-09-13
left four, and both were fully merged with nothing to decide — the
cleanup was ceremony the user had to initiate.

This is not a gap the skill is unaware of. The Constraints section
already names *"deleting the branch"* alongside squash and merge commits
as **defaults, not laws**. But that clause is written about how to handle
a *request* to delete, so it implies a default without ever stating one.
A reader asking "does `land` clean up after itself?" finds a half-answer,
which is why this arrived as a feature request rather than as a bug.

## The proposal

### 1. Disclose at the step 6 checkpoint; do not add a third gate

The skill's whole shape is one gate per irreversible action, and step 6
already stops before the write to `main`. Branch deletion belongs in
**that report** — "…then delete the branch locally and on origin" — so it
is one decision, disclosed before the work, rather than a second prompt
after step 8 when the user has mentally finished.

A step-9 gate was considered and is not recommended. The skill's tedium
budget is spent on the two gates that matter, and a third prompt for an
action this recoverable trades real friction for very little.

### 2. New step, after verification rather than before it

```bash
git branch -d <branch> && git push origin --delete <branch>
```

`-d`, never `-D`. It refuses anything not fully merged, so the local half
self-guards and the check costs nothing. Placing it after step 8 means
the merge is *proven* — `merged: true`, `--ff-only` succeeded, `main` and
`origin/main` at one SHA — before anything is removed.

That ordering is also the argument for `land` owning this at all. No
other tool is ever in as good a position, because any of them would have
to re-establish from cold what `land` has just watched happen.

### 3. Probe `delete_branch_on_merge` where step 7 already looks

GitHub's repo-level **Automatically delete head branches** setting makes
the remote half redundant where it is on, and `push origin --delete` then
fails with *"remote ref does not exist"* — a confusing error for a
correct state. Step 7 already calls `gh api repos/<owner>/<repo>` for the
three merge settings, so this is one more key in the same call:

```bash
gh api repos/<owner>/<repo> \
  --jq '{allow_squash_merge, allow_merge_commit, allow_rebase_merge, delete_branch_on_merge}'
```

Measured 2026-09-13 on two repos, which **disagree**: `false` on the
consuming repo, whose refs therefore genuinely needed removing by hand,
and `true` on this one — where GitHub deletes the head branch itself as
soon as the PR is marked merged, so the step's remote half has to be
skipped rather than attempted. The divergence was found while landing
this brief, on the second repo the step would ever have run in. The
value is not uniform, which is the whole reason to read it.

### 4. Say why this outward action is not gated like the others

The skill gates outward actions hard, so an ungated `push --delete` needs
its reasoning on the page or the next reader will either over-gate it or
generalise the exemption. It is cheap **here specifically**: the commits
are already reachable from `main`, GitHub keeps the PR, and the branch is
restorable from the PR page. None of that transfers to a remote delete in
any other context, and the skill should say so rather than leaving a
reader to infer a general rule.

## Exceptions the step must name

- The PR is not merged, or `--ff-only` failed — there is nothing to clean
  up, and the branch is the recovery path.
- The user asked to keep it.
- Another session is live in the working tree, or is on that branch.
  Step 1 already asks this; the answer applies here too.
- **The branch is the base of another open PR.** Deleting it retargets or
  closes that PR. This is the one that actually bites: it is invisible in
  merge state, and the only exception not derivable from what steps 7 and
  8 already establish.

## Rewrite the Constraints clause; do not add beside it

Whatever the new step does, the existing *"a squash, a merge commit, and
deleting the branch are defaults, not laws"* clause has to be made
consistent with it in the same edit. Leaving both is two passages
half-covering one question — the exact failure this directory's README
records from 2026-08-31, when four briefs were consolidated into two
because two of them had begun to contradict each other.

## What this brief cannot judge — left to the repo

The session behind this ran `land` in **one personal repo, with one
contributor, on branches nobody else had pulled.** `land` is in the
`workflow` group, so it also reaches client repos via
`link-claude.ps1 -SkillsOnly -SkillGroups workflow` and
`copy-copilot.ps1`, where the calculus is not the same:

- A branch a colleague has pulled is not disposable just because it
  merged.
- Org policy may already delete or retain head branches, which is what
  makes the `delete_branch_on_merge` probe worth having rather than
  optional.
- Whether "disclose at step 6, then just do it" is the right default in a
  repo with reviewers — or whether those repos want the deletion withheld
  entirely — is a portfolio judgement this brief has no evidence for.
  **If the answer differs by repo, that is an argument for reading the
  setting rather than for a second gate.**

## Out of scope, deliberately: sweeping accumulated branches

The originating conversation also asked whether branch hygiene wants its
own skill. It does not want one *here*. Cleaning the branch `land` just
merged and sweeping branches that piled up over months are different
jobs: different trigger (per-land vs. periodic), different scope (one
branch vs. many, possibly across repos), and different risk — the sweep
has to *establish* merge status where `land` has just proven it.

That second job is audit-shaped and script-shaped rather than
skill-shaped, and the consuming repo already has the pattern: a read-only
check that exits non-zero on findings, registered alongside its other
drift checks. Recorded here so the question is closed rather than
re-opened, not as work for this queue.

## Acceptance

- A run against a repo with `delete_branch_on_merge: true` completes
  without reporting a spurious failure for the already-deleted remote.
- The Constraints clause and the new step say the same thing about
  deletion.
- A run whose branch is the base of another open PR stops and says so
  instead of deleting.
- `-D` appears nowhere in the skill.

## Post-draft checklist

1. `cat` the full SKILL.md after the edit — an edit landing inside the
   frontmatter can leave YAML that still parses, into the wrong shape,
   with nothing warning.
2. Re-count `description` and `when_to_use` if either is touched. The new
   step probably needs no description change; if it gets one, the caps
   are 1,024 and 512 and `lint-frontmatter.py` enforces both separately.
3. Re-read step 6's checkpoint wording end to end. The disclosure has to
   land there, not only in the new step, or the gate says one thing and
   the procedure does another.

## Confidence

**Structure: H.** The placement argument — that `land` is uniquely well
positioned because it has just proven the merge — is the durable part and
does not depend on the originating repo.

**Defaults: M.** "Disclose at step 6, then delete without a further
prompt" is right for a single-contributor repo, and is the half this
brief cannot validate for client repos. The `delete_branch_on_merge`
probe is the hedge: where the answer differs by repo, read it.

**Evidence: M, and better on one axis than it was.** The behaviour is
two runs in one repo on one day, which is thin. But
`delete_branch_on_merge` is now measured on two repos with opposite
values, so the case for probing it is observed rather than argued.
Everything about shared branches and reviewer workflows remains reasoned,
not observed.
