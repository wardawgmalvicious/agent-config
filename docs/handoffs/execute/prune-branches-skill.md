# Skill handoff brief: prune-branches

Last verified: 2026-09-14

## Artifact path

`skills/workflow/prune-branches/SKILL.md`

Payload, `workflow` group — the one group `link-claude.ps1` junctions to
`~/.claude/skills/` on this machine, so it is live on save and needs no
deploy step. It sits beside `land`, `commit` and `code-review`, which are
the skills it cross-references.

## Scope

An **audit** skill: it enumerates every branch a repo carries — local,
remote, and worktree-pinned — establishes for each whether its work is
already integrated, and returns a verdict table plus the exact deletion
command for the user to run. It does not delete anything. Where it finds
a branch carrying genuinely unmerged work, it cherry-picks that work onto
a fresh branch off current `main`, verifies it against the repo's own CI
commands, and reports that branch instead of recommending deletion.
Inline execution (not `context: fork`) — rung 4 needs to put judgment
calls back to the user mid-run, which a background fork cannot do.
Model-invocable per repo policy. Not path-scoped: the trigger is repo
state, not a file being read.

## Sources drilled

Drilled:

- **One live end-to-end run**, 2026-09-14, against a private client repo
  — cited by kind only. Six branches surviving on the remote, none with
  a PR; one pinned by a stale worktree; one carrying real unmerged work
  that every commit-level heuristic reported as indistinguishable from
  two branches that carried none. This run is the whole evidence base for
  the ladder in the body outline, and every failure mode named below was
  observed in it rather than reasoned about.
- `skills/workflow/land/SKILL.md` — frontmatter shape and house prose
  style; also established the boundary in Cross-reference dependencies
  (its step 9 deletes the merged branch from `origin` deliberately
  ungated, which is exactly the case this skill never reaches).
- `docs/handoffs/templates/skill-handoff.md` and
  `docs/handoffs/execute/README.md` — brief structure, the group-directory
  requirement, and the rule that a brief outliving its session gets a
  queue row.

Not drilled:

- **Non-squash merge styles.** Everything here was validated in a repo
  that squash-merges every PR. In a true merge-commit repo `git branch
  --merged` is accurate and rung 2 is unnecessary; under rebase-merge the
  failure is the same as squash but the fix may differ. The body outline
  therefore opens by detecting merge style, but only the squash path is
  evidence-backed — say so in the skill rather than implying all three
  were tested.
- **Forges other than GitHub.** Rung 2 leans on `gh pr list`. GitLab and
  Azure DevOps equivalents were not investigated; the skill should state
  the dependency rather than pretend to be forge-agnostic.
- **`git for-each-ref` formatting alternatives** to the per-branch loop,
  and **branch-protection / auto-delete-on-merge settings** that would
  prevent the debris upstream. Both are plausible improvements; neither
  was needed to reach a correct answer, and neither is described.
- **Upstream git documentation** on `--merged` semantics. The behavior
  was measured directly, not read.

## Frontmatter

```yaml
---
name: prune-branches
description: {{see Description char count — draft text is in Notes}}
when_to_use: {{see Description char count — draft text is in Notes}}
disable-model-invocation: false  # ALWAYS PRESENT; repo policy: false everywhere
allowed-tools: Bash(git branch *) Bash(git log *) Bash(git rev-list *) Bash(git ls-remote *) Bash(git worktree list *) Bash(git show *) Bash(git diff *) Bash(git cherry *) Bash(git fetch *) Bash(gh pr list *)  # read-only probes only — pre-approving the audit half while every write stays prompted is the point; do NOT add git push, git branch -d/-D, or git worktree remove
# model: inherit  # ALWAYS PRESENT, ALWAYS COMMENTED — an active model: key blocks Copilot slash invocation and fails lint-frontmatter.py
effort: max  # repo policy: max on the workflow skills that drive this repo
---
```

Deliberately not set: `paths:` (trigger is repo state, not a file read),
`context` / `background` / `agent` (inline — see Scope), `argument-hint`
and `arguments` (the skill takes no argument; it audits the whole repo),
`user-invocable` (default true is correct), `disallowed-tools`, `hooks`,
`shell`, `metadata`.

The `allowed-tools` line is the one field worth a second look at draft
time. It pre-approves the read-only probes for the invoking turn so the
audit runs without a prompt per branch, while every mutating command —
the cherry-pick, the worktree removal, the deletion the user runs — stays
prompted. Adding a write specifier to it would quietly defeat the design
recorded under Notes.

## Description char count

Count both after drafting; do not trust the targets below to survive an
edit.

- `description`: target ~620 / 1,024
- `when_to_use`: target ~390 / 512

Draft text for both is in Notes, so it can be counted before it is
pasted rather than after.

## Body structure outline

1. **Detect the merge style first, because rung 2 depends on it.** Squash
   (`git log --merges | wc -l` near zero against many merged PRs),
   merge-commit, or rebase. Only the squash path is evidence-backed; under
   merge-commit `git branch --merged main` is sufficient and the skill
   should say so and stop early rather than perform ceremony.
2. **Rung 0 — establish what actually exists.** `git fetch origin
   --prune`, then `git worktree list` and `git ls-remote --heads origin`.
   Two distinct findings live here and `git branch -a` shows neither: a
   branch pinned by a worktree cannot be deleted at all (the error names
   the path, and removing the worktree is the fix), and a remote-tracking
   ref is not evidence a branch still exists on the remote. The observed
   run began with a user who believed these branches were already
   deleted; `ls-remote` is what settled it.
3. **Rung 1 — ahead/behind.** Per branch, `git rev-list --count
   main..origin/<b>` and the reverse. **Zero ahead ends the analysis** —
   the branch is fully contained in `main` and is safe regardless of how
   it got there. In the observed run this disposed of a third of the set
   in one pass, including one branch identical to `main`.
4. **Rung 2 — merge evidence, for anything with commits ahead.** In a
   squash repo this is `gh pr list --state all` keyed on `headRefName`.
   State plainly that **`git branch --merged` and `git cherry` are both
   wrong here, and wrong in the dangerous direction**: they report
   squash-merged branches as unmerged because patch-ids never match. In
   the observed run `git cherry` flagged every commit on every remaining
   branch as unique, including on two branches that held nothing worth
   keeping. An agent that trusts it keeps everything forever; one that
   overrides it impatiently deletes real work.
5. **Rung 3 — content recency, for branches with commits ahead and no
   PR.** This is the rung that prevents the expensive mistake, and the
   one most likely to be skipped as redundant. "Has commits `main` does
   not" and "has work worth keeping" read as the same statement and are
   not: a branch diverged from an old `main` looks identical to a
   valuable one. Resolve it per contested file with `git log -1
   --format="%h %ad %s" --date=short <ref> -- <path>` on each side and
   compare. The observed run had a branch whose seven unique commits
   looked substantial and whose contested file was the *older* copy,
   superseded on `main` by a later PR.
6. **Rung 4 — read what survives, and put judgment back to the user.**
   Three patterns worth naming, all observed: commit pairs that cancel
   exactly (verify with a `git diff --stat <first>^ <last> -- <paths>`
   that comes back empty, rather than by reading the messages); commits
   that contradict something the repo says about itself, which is where
   the skill must send the agent to the repo's own instructions before
   recommending a rescue — in the observed run a commit hand-applied a
   vendor format upgrade the repo documented as a portal-only action, and
   nothing in git would have flagged it; and genuinely unmerged work.
   The skill can teach the habit of asking the question. It cannot
   enumerate the answers, and should say so.
7. **Rescue before recommending deletion.** Branch off current `main`,
   cherry-pick only the commits that survived rung 4, then verify with
   **the repo's own** validator and guard commands — read them out of the
   project instructions rather than assuming a test runner exists. Report
   the new branch and hand the landing to `land`.
8. **Report, and stop.** A verdict table (branch, the rung that settled
   it, the evidence), the rescue branch if any, and the exact `git push
   origin --delete ...` line for the user to run. The skill never deletes
   and never pushes a deletion; Notes records why that is structural
   rather than timid.

## Changes from source proposal

Derived from a live session rather than a written proposal. Two
departures from what that session concluded in the moment, both
deliberate:

- The session scoped the skill as "audit and recommend, never delete"
  partly on the grounds that the deletion command is a one-liner the user
  can run. That reasoning stands but is secondary; the primary reason is
  recorded under Notes and should lead in the skill.
- The session ordered its ladder 0–4 and treated merge-style detection as
  implicit. The outline above promotes it to step 1, because the whole
  ladder collapses to a single built-in command in a merge-commit repo,
  and an agent that does not check will perform four rungs of unnecessary
  work and present it as rigor.

## Tag

`personal`

## Portability caveats

`effort: max` is Claude-Code-only; under GitHub Copilot it warns and is
ignored, which costs this skill nothing — no step depends on the level.
`when_to_use` is likewise ignored there and folds into the description.
No `paths:` glob, so the Copilot unconditional-load divergence does not
apply. The `allowed-tools` Bash specifiers are Claude Code syntax, written
in space form per the template's rule.

The real portability limit is not frontmatter: rung 2 is GitHub-specific
via `gh`, and the ladder as a whole is validated only against
squash-merge. Both belong in the skill body as stated limits.

## Cross-reference dependencies

- `land` (already converted, `skills/workflow/land/`) — the boundary is
  clean and worth stating in both directions. `land` deletes a branch it
  has just merged, from a known-good state, which is why its step 9
  leaves that deletion ungated. This skill handles branches whose
  provenance is unknown and which never went through `land` at all, which
  is why it gates by not deleting. Hand a rescue branch to `land`.
- `commit` (already converted) — referenced only as the source of the
  logical commit split that rung 4 reads.
- `gh` CLI (external) — rung 2. Note that this repo's guidance treats the
  GitHub API actor as a third identity: `gh` may resolve to a different
  account than the commit author. It is read-only here, so it does not
  need the `land` identity procedure, but the skill should not imply that
  `gh auth status` says who you are.

## Claude Code's post-draft checklist

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**Why audit-and-report is structural, not caution.** In the observed run
the agent attempted `git push origin --delete` on four branches it had
already verified as safe, and the auto-mode classifier denied it as
`[Git Destructive]`. That denial is correct behavior and it is not going
away, so a skill whose payoff step is the deletion would fail its last
step every time. Ending at a verified recommendation puts the output
where the value actually is and where the permission model already allows
it. Lead with this in the skill body — an agent that reads "never
deletes" as timidity will try anyway and burn the turn.

**Draft text to count and paste.**

`description` (~620):

> Audits every branch a repo carries — local, remote, and worktree-pinned
> — and sorts them into safe to delete, stale, and carrying unmerged work,
> rescuing the last group onto a fresh verified branch before recommending
> anything. Built for repos that squash-merge, where `git branch --merged`
> and `git cherry` both report merged branches as unmerged because
> patch-ids never match, so merge evidence has to come from the PR list
> instead. Separates a stale remote-tracking ref from a branch that really
> is still on the remote. Reports and recommends; never deletes a branch
> and never pushes a deletion. Complements land, which prevents this
> debris on the happy path — this cleans up what never took it.

`when_to_use` (~390):

> Use when asked to clean up, prune or audit branches, to work out which
> branches are safe to delete, or why a branch will not delete —
> including "I thought I deleted these" and a `git branch -d` that
> refuses because a worktree holds the branch. Not for deleting one
> branch already known to be merged: that is a one-liner, and `land`
> already does it for a branch it just merged.

**Evidence handling.** The live run was against a client repo and this
repo is public. Everything above is cited by kind. Do not go looking for
the original branch or file names to make the examples concrete — the
genericized form is the required form, and it is also the better skill,
since none of the reasoning depends on the specifics.

**A cheap upstream fix exists and is out of scope.** Auto-delete-on-merge
and branch protection would stop most of this debris accumulating. Worth
one sentence in the skill as a closing note; not worth a step.

## Confidence

- **Method (rungs 0–4): H.** Validated end to end on a six-branch real
  case containing one true positive, three clean negatives, and two traps
  that commit-level heuristics got wrong.
- **Structure and placement: H.** Follows the `workflow` group precedent
  exactly; the `land` boundary is explicit and non-overlapping.
- **Generalization beyond squash-merge GitHub repos: M.** Untested. The
  outline handles it by detecting merge style and stating the limit
  rather than by claiming coverage — draft it that way.
