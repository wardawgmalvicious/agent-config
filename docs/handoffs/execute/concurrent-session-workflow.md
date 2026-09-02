# Handoff: should branching become the standard workflow?

- **Written**: 2026-09-02, from the session that opened and merged
  [PR #6](https://github.com/wardawgmalvicious/agent-config/pull/6) —
  this repo's first branch — and the `/learn` that followed it.
- **Kind**: workflow decision. May produce an `/author-skill` run, but
  that is an output and not the question.
- **Status**: open. **Recommendation: settle the isolation mechanism
  first.** "Do we need a PR skill" is downstream of it and cannot be
  answered before it.
- **Run in**: a fresh session — and ideally with a second session
  actually running, since the failure this brief is about only appears
  when there are two.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.
- **Affects**: waves 12, 13 and 14 — the queue's only real dependency
  sequence, and three consecutive skill-authoring waves. Settle this
  before starting them.

## Why this exists

Work here has always been committed straight to `main`. On 2026-09-02
two sessions ran in this tree at once and edited
`docs/handoffs/execute/README.md` minutes apart; nothing warned, and
re-reading immediately before writing is the only thing that caught it.
Root [`CLAUDE.md`](../../../CLAUDE.md) already carries that scar as its
"Branching and concurrent sessions" section.

The same day the first branch in the repo's history —
`docs/rename-docs-dirs` — was created, merged as PR #6, and deleted. The
question raised afterwards: **should that become the standard workflow
rather than a one-off exception?**

## Step 1 — test the premise before designing anything

The intuition is that a branch isolates one session's work from
another's. **In a shared working tree it does not**, and root
`CLAUDE.md` already says so:

> **Two sessions in this tree share every file, branch or no branch.**
> Branching does not isolate them; only sequencing does.

One working tree is on one branch. A `git switch -c` in either session
moves the other's checkout too, uncommitted work travels with it, and
commits land on whichever branch is current regardless of who made
them. So "each session works on its own branch" is not a workflow that
exists here today.

**Confirm this still holds before proceeding.** It is the load-bearing
claim, it was written before the 2026-09-02 junction-to-copy
conversion, and if it has changed the rest of this brief is moot.

## Step 2 — worktrees are the only mechanism that isolates

Root `CLAUDE.md` names the blocker, and it is a single one:

> The per-skill junctions are absolute and keep pointing at *this*
> directory, so a second worktree's skills are edited but never
> deployed. Everything else would now deploy correctly from a worktree
> via `-ClaudeDir`.

**A second constraint is not written down anywhere and should be
established in this wave**: `~/.claude/skills` is **user scope and
singular**. Two sessions authoring skills contend on the *deployment
target* no matter how many worktrees exist — which moves the
contention rather than removing it.

The candidate fix is already supported by the linker —
`scripts/link-claude.ps1 -ClaudeDir <worktree>/.claude -SkillsOnly
-SkillGroups <group>` deploys to **project scope** instead of home.
Whether a project-scope `.claude/skills` actually takes precedence for
a session running in that worktree is **untested**, and it is the whole
question. Measure it; do not assume it.

Mind the interaction with the prune: `-SkillGroups` prunes **user
scope**, so a careless run from a worktree is the documented way to
silently undo the workflow-only prune for every session on this
machine.

## Step 3 — what integration looks like, if branching becomes routine

Settled and recorded this session, so do not re-derive:

- Rebase-merge is **disabled** on this repo (the API answers `405`), and
  squash would collapse the logical split `/commit` just made.
  `git merge --ff-only` then push is the house style — it preserves the
  exact SHAs and keeps `main` free of merge commits.
- The PR is opened through `github-mcp`, **not** `gh`; the two
  authenticate as different GitHub accounts on this machine, and
  nothing warns when the wrong one acts.

Both are in root `CLAUDE.md` and `claude/CLAUDE.md` as of commits
`1f436f4` and `f04eec1`.

What is **not** settled: whether a branch is one per wave, per brief, or
per session, and what happens to a half-finished branch when a session
ends without landing it.

## Step 4 — the skill question, which is downstream

This is where "do we need a PR skill" resolves, and only here.

The case against was made on 2026-09-02 and **is now known to rest on a
bad base rate**: one branch in 324 commits reads as rare, but all 324
predate the concurrent-session workflow that produced the branch. A rate
measured under the old regime does not predict the new one. Recorded
because the reasoning error is more reusable than the conclusion.

The criteria that actually decide it:

- **Frequency under the chosen workflow**, not the historical one.
- **Listing cost.** An unconditional skill sits permanently in a listing
  already near its budget. If the flow is fully described by two
  `CLAUDE.md` sections that already auto-load in every session, a skill
  buys nothing.
- **Whether `commit` absorbs it instead.** `commit` owns the working
  tree, not branch integration — but a new sibling skill is not the only
  alternative to leaving it alone.

## Validation

- Reproduce with **two real sessions**, not one session reasoning about
  two. The failure mode is silent, so a thought experiment cannot see
  it.
- Test the project-scope `-ClaudeDir` skills path from an actual
  worktree before writing a word of guidance about it, then confirm the
  user-scope prune survived: `ls ~/.claude/skills` should list the eight
  workflow skills and nothing else.
- Any claim about precedence between project- and user-scope skills is
  **unverified until measured**. If it lands unproven, date it and say
  so in the text.

## If the answer turns out to be no

Entirely plausible, and the residue is small: stay on `main` with
sequencing, keep "branch when you have the tree to yourself" as the
exception it is today, and the two `CLAUDE.md` sections already standing
are enough — no skill, no worktree tooling. Record the reasoning in the
commit that deletes this brief, and the reconsider-if condition: **a
second silent collision between concurrent sessions reopens it.**
