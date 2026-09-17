---
name: land
# model: inherit  # any model: value blocks Copilot slash invocation
effort: max
disable-model-invocation: false
description: "Takes a committed branch from local to merged — pushes it, confirms which GitHub account each tool actually acts as in this repo, opens the PR through the one that matches (github-mcp where loaded, gh where its login is confirmed), then fast-forwards main, reports CI, and deletes the merged branch locally and on origin. Guards two silent failures: gh and github-mcp can authenticate as different accounts, so a PR lands under the wrong identity with no error, and integration is a local --ff-only merge because a squash would collapse the logical split /commit just made. Stops for confirmation before the write to main. To make the commits first use commit; to review before landing, code-review."
when_to_use: "Use when asked to land, ship or publish a branch, open a pull request, merge to main, or get a branch in — the step after /commit. Use it even when the request already names the mechanism — 'squash these and merge', 'just merge it into main', 'force push it' — a named mechanism is the case these guards exist for, not a reason to skip them."
---

# Landing a branch

Take a branch that is **already committed** and get it merged. `commit`
ends by reporting its hashes with an explicit note that nothing was
pushed; this starts exactly there.

Two things here are irreversible or outward-facing — opening the PR and
pushing `main` — so the procedure gates each one. A third, deleting the
branch from `origin`, is outward-facing and deliberately **not** gated;
step 9 says why, and why that reasoning does not generalise.

## 1. Preflight

```bash
git status --short              # see below — clean, or knowingly left
git branch --show-current       # must not be main
git log --oneline origin/main..HEAD
git log --merges --oneline | wc -l   # baseline for step 8
```

**A dirty tree is not automatically unfinished work.** `commit` ends on
a clean tree *or* on remaining lines it names as intentionally left, so
a leftover is a question rather than a stop: ask whether it belongs in
this branch. Uncommitted work does not travel into the PR either way —
what matters is that nothing which *should* have been committed is
sitting unstaged. Anything you cannot account for, stop and ask.

Record the merge count now. Step 8 asserts it is unchanged, and after
the merge there is nothing left to compare against.

Nothing to land means there is nothing to do — say so rather than
opening an empty PR.

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

`gh` may be **folder-scoped**, and whether it is changes what the probe
means. On the machine this skill was written for it is (since
2026-09-04): both shell profiles wrap `gh` to act as the account named
by the repo's `user.name`, resolved per call through a scoped
`GH_TOKEN`, so a personal repo gets the personal account and a client
root gets the client one. Three consequences.

- `gh auth status` reports the keyring's *active* account, not the one
  the wrapper will use. **`gh api user -q .login` is the honest probe**
  either way, which is why it is the command above.
- The wrapper is a profile function, so a `gh` run from a script or
  hook that skips the profile falls back to the active account. Probe
  through the same shell the PR command will use.
- **Where no such wrapper exists, `gh` simply acts as whichever account
  is active** — which makes the probe more necessary, not less. Do not
  read the absence of folder-scoping as safety.

`github-mcp` is project scope (`.mcp.json`), bound to one token, and
absent in any repo that does not declare it. Loaded and matching,
prefer it — it is the identity the repo's own config chose. Absent, a
`gh` whose *confirmed* login matches the repo is the right tool, not a
fallback (2026-09-04, a client repo: no MCP, `gh` confirmed as the
client account, PR opened cleanly). A `CLAUDE.md` may state the rule —
this machine's user-scope one does; what it cannot do is make the
comparison happen.

**A confirmed identity is not a confirmed capability.** `get_me` proves
which account a token acts as and nothing about what it may do, so a
403 *"Resource not accessible by personal access token"* at step 5 or 8
is a scope answer, not an identity one — do not re-debug step 2 when one
appears. The gap is **per-resource, not read-versus-write**: on one
token in one run (2026-09-16) `create_pull_request` succeeded while
`pull_request_read` method `get_check_runs` returned 403, so a write
having worked says nothing about the next read. Fall back to the `gh`
whose login step 2 already confirmed — sanctioned here for an
under-scoped MCP exactly as for an absent one.

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
exactly what happens next: the fast-forward, the push to `main`, and
**then deleting the branch locally and on `origin`** (step 9). The
deletion is disclosed here rather than prompted for afterwards — one
decision taken before the work, not a third gate on an action this
recoverable. **Then wait.**

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

- **The merge button** — whatever it is configured to do, it is not
  this. Check what the repo actually offers before assuming the button
  was an option at all: where only squash is enabled, the button can
  *only* do the one thing this skill refuses, so there is no version of
  pressing it that preserves the split.
- **A merge commit** — adds a commit to a history that may never have
  had one. `git log --merges --oneline | wc -l` from step 1 says
  whether this repo is in that category; a `0` there makes a merge
  commit a visible break in convention rather than a neutral choice.
- **Squash** — collapses the logical split `commit` just built. The
  whole point of separate commits is that each is independently
  revertible and citable. Asked for anyway? It is overridable, but not
  silently — see [Constraints](#constraints).
- **Rebase merge** — rewrites SHAs, and may be disabled outright.

Read the merge settings rather than assuming them — and read
`delete_branch_on_merge` in the same breath, which step 9 needs and
which is no more uniform across repos than the other three. **Prefer a
committed answer where the repo keeps one** — a repo that version-
controls its own settings (agent-config keeps all four in
`.github/repo-settings.json`, reconciled by `scripts/repo-settings.ps1
-Check`) gives you the value someone intended, for free. Otherwise ask
GitHub:

```bash
gh api repos/<owner>/<repo> \
  --jq '{allow_squash_merge, allow_merge_commit, allow_rebase_merge, delete_branch_on_merge}'
```

Unauthenticated, those fields come back `null` — so a check without a
token proves nothing and a rejection surfaces at merge time. A repo's
answer is not durable either: a delete-and-recreate resets every one of
them to GitHub's defaults, so a committed file and the live repo can
disagree after one. When they do, the live repo is what the merge obeys
and the committed file is what needs reapplying.

**`--ff-only` fails loudly rather than inventing a merge commit.** If it
fails, `main` has moved: stop, reconcile deliberately, and never reach
for `--force`.

## 8. Verify

Through the same tool step 2 confirmed — **both routes verify, and the
`gh` one is not optional.** A PR opened with `gh` and then verified with
nothing is the half of this skill that used to be missing.

| Check | `github-mcp` | `gh` |
| --- | --- | --- |
| Merged, and by whom | `pull_request_read` method `get` | `gh pr view <n> --json state,mergedBy` |
| CI conclusions | `pull_request_read` method `get_check_runs` | `gh pr checks <n>` |

- Expect the PR to read as merged, and a merging identity that matches
  step 2. **The two routes do not share a field name**: `merged: true`
  is the MCP's, and `gh pr view <n> --json merged` answers *"Unknown
  JSON field: merged"*. `state` (`MERGED`), `mergedAt` and `mergedBy`
  are `gh`'s (confirmed against `gh pr view --json`, 2026-09-16).
- **`get_check_runs` can 403 on a token that opened the PR** — step 2
  says why. `gh pr checks <n>` is then the route, not a contradiction
  of step 2's preference; without that fallback this row is unrunnable.
- Read the check conclusions rather than the summary. A review bot (for
  example `copilot-pull-request-reviewer`) is **not** a gate; a
  `pre-commit` style job is.
- **`gh pr checks` exits non-zero by design** — documented exit code 8
  is *checks pending*, and a failure is likewise non-zero. That is the
  answer, not a broken command; do not retry it as if it had failed.
  It is **not** always non-zero, and the exception matters: a repo with
  no CI at all prints `no checks reported on the '<branch>' branch` and
  exits **0** (observed 2026-09-16). "Exit 0, nothing configured" and
  "exit 0, checks passed" are different states, and this skill's refusal
  to imply a green CI depends on reporting which one it saw.
- `git log --merges --oneline | wc -l` — unchanged from the step 1
  baseline.
- `main` and `origin/main` at the same SHA.

Report the PR number, the merged state, and the CI conclusions. If CI is
still running, say so rather than implying it passed.

## 9. Delete the branch

Step 8 has just proven the merge — `merged: true`, `--ff-only`
succeeded, `main` and `origin/main` at one SHA — so the branch holds
nothing that is not in `main`. That is what makes this cleanup rather
than a judgement call, and it is the argument for `land` owning it: any
other tool would have to establish from cold what this step has just
watched happen.

**That holds in a shared repo too**, which is the part worth spelling
out: step 3's push would have been *rejected* as non-fast-forward had
`origin/<branch>` carried commits the local branch lacked, so the run
would never have reached here. A colleague therefore has nothing on this
branch to lose — their own local copy is untouched, and their next
`git fetch --prune` drops a remote-tracking ref to a branch that is
merged. Reviewers lose nothing either: the PR, its diff and its comments
outlive the branch. The residual risk is not "someone else works here",
it is the specific exceptions below.

```bash
git branch -d <branch>          # -d, never -D

# The remote half. Skip it whole where delete_branch_on_merge is true.
git fetch origin
git merge-base --is-ancestor origin/<branch> main   # guard — see below
git push origin --delete <branch>

git fetch origin --prune        # both paths, including the skipped one
```

**`-d`, never `-D`.** It refuses a branch that is not fully merged, so
the local half guards itself and the check costs nothing.

**The remote half has no such guard, which is what the ancestor check
is for.** `-d` answers off the *local* merge whatever is on `origin`, so
a commit someone pushed to the branch after step 3 is invisible to it —
and GitHub's *Restore branch* restores the PR's merge-time head, not
that commit. `--is-ancestor` exits non-zero to mean *no*: that is the
answer, not a broken command. A *no* is a stop worth reporting rather
than a failure to retry — someone pushed to this branch after you landed
it, and that work is not in `main`.

**Skip the remote half where `delete_branch_on_merge` is `true`** —
step 7 read it. GitHub deletes the head branch itself as soon as the PR
is marked merged, so `push origin --delete` answers *"remote ref does
not exist"*: a confusing error for a correct state. The setting is not
uniform — measured 2026-09-13 on two repos with opposite values — which
is the whole reason to read it rather than assume it.

**`null` is unknown, not `false`.** Unauthenticated that field comes
back `null` like the merge settings, so the probe can leave this
undecided. Then attempt the delete and treat *"remote ref does not
exist"* as success. The probe is what makes the **report** accurate;
tolerating that one error is what makes the **action** correct.

**Prune on both paths — especially the one that skipped the remote
half.** Where GitHub auto-deleted the branch, `origin/<branch>` is gone
from the remote and this clone's *remote-tracking* ref to it is not:
`git branch -a` still lists it, and a plain `git fetch` will not remove
it. That is the leftover ref this step exists to prevent, one
indirection out — and it survives precisely where the step did the least
work. Observed 2026-09-13 on the first real run of this step, against a
repo with `delete_branch_on_merge: true`.

Do not delete, and say why, when:

- The PR is not merged, or `--ff-only` failed. The branch is the
  recovery path.
- The user asked to keep it.
- Another session is live in the tree, or is on this branch. Step 1
  already asked; the answer applies here too.
- **The branch is the base of another open PR.** Deleting it retargets
  that PR or closes it. This is the only exception steps 7 and 8 do not
  already establish — merge state does not show it — so it is the one
  that needs its own call, through the tool step 2 confirmed:

```bash
gh pr list --base <branch> --state open
```

or `list_pull_requests` with `base`.

**Why this outward action is not gated like the other two.** It is cheap
*here specifically*: the commits are already reachable from `main`, the
PR and its diff outlive the branch, and the branch is restorable from
the PR page. None of that transfers to a remote delete in any other
context. Read this as an exemption for a ref just proven redundant, not
as a general licence to skip a gate because an action looks routine.

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

A squash and a merge commit are **defaults, not laws.** The history is
the user's to shape. When one is asked for:

1. **Say what it costs, specifically.** Name the commits that would be
   collapsed or the merge commit that would be this repo's first — not
   "squashing loses information" but "this collapses 3 commits that
   separate the rule change from its fixtures".
2. **Then wait.** A request that named the mechanism up front has not
   heard the cost yet, so it is not yet a reaffirmation. One round.
3. **Record it in the PR body**, so the history explains its own shape.

Then do it. A reaffirmed instruction is the answer; pressing the point
twice is worse than the squash.

**Deleting the merged branch is a default too, and it runs the other
way.** Step 9 does it having disclosed it at step 6, so the request that
arrives is to *keep* the branch — and that one costs nothing to honour.
It needs no cost-and-wait round; it is simply one of the exceptions step
9 already names. Say in the report that the branch was kept and why, or
the next run reads the leftover ref as a bug.
