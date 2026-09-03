---
name: land
model: inherit
effort: max
disable-model-invocation: false
description: "Take a committed branch from local to merged — push it, confirm which GitHub account is actually authenticated, open the PR through github-mcp, then fast-forward main and check CI. Use when asked to land, ship or publish a branch, open a pull request, merge to main, or get a branch in; the step after /commit. Guards two silent failures: gh and github-mcp can authenticate as different accounts, so a PR lands under the wrong identity with no error, and integration is a local --ff-only merge because a squash would collapse the logical split /commit just made. Stops for confirmation before pushing main. To make the commits first use commit; to review before landing, code-review."
---

# Landing a branch

Take a branch that is **already committed** and get it merged. `commit`
ends by reporting hashes "against a clean tree" with an explicit note
that nothing was pushed; this starts exactly there.

Two things here are irreversible or outward-facing — opening the PR and
pushing `main` — so the procedure gates each one.

## 1. Preflight

```bash
git status --short              # must be clean
git branch --show-current       # must not be main
git log --oneline origin/main..HEAD
```

A dirty tree means `commit` has not finished. Nothing to land means
there is nothing to do — say so rather than opening an empty PR.

**Ask whether another session is live in this working tree.** Step 7
runs `git switch`, and one working tree has one HEAD, so the switch is
not scoped to you — it moves the branch under anyone else working here.
If someone is, stop after step 6 and let them finish.

## 2. Establish the identity before anything outward

**This gates every outward action, and it is the step most likely to
fail silently.**

```bash
gh auth status                  # may be a different account
git remote -v                   # who owns the repo
```

Then `github-mcp` → `get_me`, and compare all three. Use the tool whose
account matches the repo owner.

On this machine they **do** differ: `gh` holds a work account and the
MCP holds the personal one, so in a personal repo `gh` is the wrong
tool. Root `CLAUDE.md` states the rule; what it cannot do is make the
comparison happen.

**Nothing warns you.** `gh` is authenticated, it works, it reports
success — the PR simply appears under the other account. A wrong-account
PR looks identical to a right-account one until someone reads the
author. If neither identity matches the repo owner, stop and ask.

## 3. Push the branch

```bash
git push -u origin <branch>
```

## 4. Survey what is actually landing

```bash
git log --oneline origin/main..HEAD
```

Read every commit, not just yours. **A commit another session made
while you were on this branch landed on this branch** — that is how one
working tree behaves, and those commits ship inside your PR. They are
not a problem to fix, but shipping someone else's work inside a PR
described entirely as yours is a review problem. Name them in the body
(step 5).

Anything that should not ship yet is a stop: say so rather than landing
it.

## 5. Open the PR — with `github-mcp`, never `gh`

`create_pull_request` with `owner`, `repo`, `title`, `head`, `base`,
`body`.

**The body is the deliverable, and it is the only judgement step in
this skill.** The diff is already visible; do not restate it. What it
owes a reader:

- **Why the change exists**, and what it decided.
- **What was verified, and what was not** — including anything believed
  but unmeasured. A claim's provenance is the part that rots first.
- **Reasoning behind any reversal** of a previous decision, quoted, so
  the reversal is auditable rather than silent.
- **Disclosure of concurrent-session commits** from step 4.
- **How it is to be integrated**, where the repo has a convention.

**No GitHub remote, or no `github-mcp`? Stop.** An `origin` that is not
GitHub — a `file://` path, another host — means there is no PR to open,
and an unavailable `github-mcp` means the same thing for a different
reason. Neither is permission to skip ahead and merge locally. A local
merge satisfies the literal words "merged into main" while discarding
review, CI and the PR body, and it makes any later PR empty because
`main` already contains the commits. Report which of the two is missing
and let the user choose. Reaching for `gh` is never the answer — step 2.

## 6. Checkpoint — stop here

**The gate is the next command that writes to `main`, not the PR.** Stop
before that command whether or not a PR exists: a PR that could not be
opened is a reason to stop sooner, never a reason to carry on.

Report where things stand — the PR URL, or what blocked it — and state
exactly what happens next. **Then wait.**

Everything past this point writes to `main`. Do not continue on your own
initiative, even when the merge looks routine, and even when the local
half would plainly succeed on its own — this checkpoint is the skill's
whole reason for not being one command.

## 7. Land by fast-forward

```bash
git switch main && git merge --ff-only <branch> && git push origin main
```

This preserves the exact SHAs, keeps `main` linear, and adds no merge
commit. GitHub marks the PR merged once its commits are reachable, so
the merge button is never needed.

Why not each alternative:

- **The merge button / a merge commit** — adds a commit that this repo
  has never had.
- **Squash** — collapses the logical split `commit` just built. The
  whole point of separate commits is that each is independently
  revertible and citable.
- **Rebase merge** — rewrites SHAs, and may be disabled outright. On
  `agent-config` the API answers `405 Rebase merges are not allowed`
  (recorded in root `CLAUDE.md`, verified there on PR #6). Merge
  settings and branch protection are not readable unauthenticated, so a
  rejection surfaces at merge time and not before.

**`--ff-only` fails loudly rather than inventing a merge commit.** If it
fails, `main` has moved: stop, reconcile deliberately, and never reach
for `--force`.

## 8. Verify

- `pull_request_read` method `get` → expect `merged: true` and a
  `merged_by` that matches the identity from step 2.
- `pull_request_read` method `get_check_runs` → read the conclusions.
  A review bot (for example `copilot-pull-request-reviewer`) is **not** a
  gate; a `pre-commit` style job is.
- `git log --merges --oneline | wc -l` — unchanged from before the
  merge.
- `main` and `origin/main` at the same SHA.

Report the PR number, the merged state, and the CI conclusions. If CI is
still running, say so rather than implying it passed.

## Constraints

- **Never `gh` for the PR.** Identity, not preference — see step 2.
- **Never merge without the checkpoint.** Opening a PR and pushing
  `main` are two decisions, not one.
- **Never `--force`, never `--no-verify`, never squash or rebase** to
  get past a failed `--ff-only`.
- **Never `git switch` while another session is live in the tree.**
- **Do not delete the branch**, locally or on the remote, unless asked.
- If the repo is not one the authenticated identity owns, or `main` is
  protected in a way that blocks a direct push, stop and report rather
  than working around it.
