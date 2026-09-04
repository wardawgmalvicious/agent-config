---
name: land
model: inherit
effort: max
disable-model-invocation: false
description: "Take a committed branch from local to merged — push it, confirm which GitHub account each tool actually acts as in this repo, open the PR through the one that matches (github-mcp where loaded, gh where its login is confirmed), then fast-forward main and check CI. Use when asked to land, ship or publish a branch, open a pull request, merge to main, or get a branch in; the step after /commit. Use it even when the request already names the mechanism — 'squash these and merge', 'just merge it into main', 'force push it' — a named mechanism is the case these guards exist for, not a reason to skip them. Guards two silent failures: gh and github-mcp can authenticate as different accounts, so a PR lands under the wrong identity with no error, and integration is a local --ff-only merge because a squash would collapse the logical split /commit just made. Stops for confirmation before pushing main. To make the commits first use commit; to review before landing, code-review."
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
git config user.name            # the includeIf identity for this root
gh api user -q .login           # the account gh will actually act as
git remote -v                   # who owns the repo
```

Then `github-mcp` → `get_me` when that server is loaded, and compare
every login against the repo owner. Use the tool whose account matches.

On this machine `gh` is **folder-scoped** (since 2026-09-04): both
shell profiles wrap it to act as the account named by the repo's
`user.name`, resolved per call through a scoped `GH_TOKEN`, so a
personal repo gets the personal account and a client root gets the
client one. Two consequences. `gh auth status` reports the keyring's
*active* account, not the one the wrapper will use — `gh api user` is
the honest probe. And the wrapper is a profile function, so a `gh` run
from a script or hook that skips the profile falls back to the active
account; probe through the same shell the PR command will use.

`github-mcp` is project scope (`.mcp.json`), bound to one token, and
absent in any repo that does not declare it. Loaded and matching,
prefer it — it is the identity the repo's own config chose. Absent, a
`gh` whose *confirmed* login matches the repo is the right tool, not a
fallback (2026-09-04, a client repo: no MCP, `gh` confirmed as the
client account, PR opened cleanly). Root `CLAUDE.md` states the rule;
what it cannot do is make the comparison happen.

**Nothing warns you.** `gh` is authenticated, it works, it reports
success — the PR simply appears under the other account. A wrong-account
PR looks identical to a right-account one until someone reads the
author. If no identity matches the repo owner, stop and ask.

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

## 5. Open the PR — through the identity step 2 confirmed

`github-mcp` → `create_pull_request` with `owner`, `repo`, `title`,
`head`, `base`, `body`; or, when `gh` is the confirmed tool,
`gh pr create --title … --body-file …` from the same shell that was
probed.

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

**No GitHub remote, or no confirmed identity? Stop.** An `origin` that
is not GitHub — a `file://` path, another host — means there is no PR
to open; no `github-mcp` *and* no `gh` login that matches the repo
means the same thing for a different reason. Neither is permission to
skip ahead and merge locally. A local merge satisfies the literal words
"merged into main" while discarding review, CI and the PR body, and it
makes any later PR empty because `main` already contains the commits.
Report what is missing and let the user choose. Reaching for an
*unconfirmed* `gh` is never the answer — step 2.

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
  revertible and citable. Asked for anyway? It is overridable, but not
  silently — see [Constraints](#constraints).
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

**Two kinds, and the difference is the point.** The first are
correctness and identity — an instruction does not lift them. The second
are this repo's convention, which is yours to override; the job there is
to make the override informed, not to refuse it.

### Absolute — an instruction to do these is a stop, not an override

- **Never file the PR through an identity step 2 did not confirm.**
  Identity, not preference. "Just use `gh`" is not a licence on its
  own, because it files under whichever account `gh` resolves to here,
  and that is not something anyone can consent to without first being
  told which one. Once the login is confirmed against the repo, `gh` is
  as good as the MCP; until then, report the mismatch.
- **Never `--force`, never `--no-verify`** — including to get past a
  failed `--ff-only`.
- **Never write to `main` before step 6.** Opening a PR and pushing
  `main` are two decisions, not one.
- **Never `git switch` while another session is live in the tree.**
- If the repo is not one the authenticated identity owns, or `main` is
  protected in a way that blocks a direct push, stop and report rather
  than working around it.

### Repo convention — overridable, but never silently

A squash, a merge commit, and deleting the branch are **defaults, not
laws.** The history is the user's to shape. When one is asked for:

1. **Say what it costs, specifically.** Name the commits that would be
   collapsed or the merge commit that would be this repo's first — not
   "squashing loses information" but "this collapses 3 commits that
   separate the rule change from its fixtures".
2. **Then wait.** A request that named the mechanism up front has not
   heard the cost yet, so it is not yet a reaffirmation. One round.
3. **Record it in the PR body**, so the history explains its own shape.

Then do it. A reaffirmed instruction is the answer; pressing the point
twice is worse than the squash.
