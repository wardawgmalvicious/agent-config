---
name: land
# model: inherit  # any model: value blocks Copilot slash invocation
effort: max
disable-model-invocation: false
description: "Takes a committed branch from local to merged — pushes it, confirms which GitHub account each tool actually acts as in this repo, opens the PR through the one that matches (github-mcp where loaded, gh where its login is confirmed), then integrates it into main, reports CI, and deletes the merged branch locally and on origin. Guards two silent failures: gh and github-mcp can authenticate as different accounts, so a PR lands under the wrong identity with no error, and integration preserves every SHA — a local --ff-only merge by default, a no-checkout refspec push where another session holds the tree, or a server-side merge commit where main requires a pull request — because a squash would collapse the logical split /commit just made. Stops for confirmation before the write to main. To make the commits first use commit; to review before landing, code-review."
when_to_use: "Use when asked to land, ship or publish a branch, open a pull request, merge to main, or get a branch in — the step after /commit. Use it even when the request already names the mechanism — 'squash these and merge', 'just merge it into main', 'force push it' — a named mechanism is the case these guards exist for, not a reason to skip them."
---

# Landing a branch

Take a branch that is **already committed** and get it merged. `commit`
ends by reporting its hashes with an explicit note that nothing was
pushed; this starts exactly there.

Two things here are irreversible or outward-facing — opening the PR and
writing to `main` — so the procedure gates each one. A third, deleting the
branch from `origin`, is outward-facing and deliberately **not** gated;
step 9 and [references/branch-deletion.md](references/branch-deletion.md)
say why, and why that reasoning does not generalise.

## 1. Preflight

```bash
git status --short              # see below — clean, or knowingly left
git branch --show-current       # must not be main
git log --oneline origin/main..HEAD
git log --merges --oneline | wc -l   # baseline for step 8
git worktree list               # separate trees, or one shared HEAD?
git branch -vv                  # where HEAD is, and each branch's tip
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

**Check whether another session is live in this working tree, then
ask.** Step 7's default runs `git switch`, and one working tree has one
HEAD, so the switch is not scoped to you — it moves the branch under
anyone else working here. `git worktree list` and `git branch -vv`
answer this; the question alone does not. Asked directly, a user
answers about *subject matter* — "working on something else that won't
touch your edits" is truthful and entirely compatible with sharing this
HEAD, which is what it turned out to mean on 2026-09-15. A branch tip
equal to your own is the tell that someone cut their branch from yours,
which is what makes the merge method at step 7 load-bearing.

Someone being live is **not** a reason to abandon the landing — step 7
has a no-checkout route for exactly this case. Disclose it at step 6
and take it.

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
exactly what happens next: which route step 7 will take, its write to
`main`, and
**then deleting the branch locally and on `origin`** (step 9). The
deletion is disclosed here rather than prompted for afterwards — one
decision taken before the work, not a third gate on an action this
recoverable. **Then wait.**

Everything past this point writes to `main`. Do not continue on your own
initiative, even when the merge looks routine, and even when the local
half would plainly succeed on its own — this checkpoint is the skill's
whole reason for not being one command.

## 7. Integrate — preserving every SHA

```bash
git switch main && git merge --ff-only <branch> && git push origin main
```

This preserves the exact SHAs, keeps `main` linear, and adds no merge
commit. GitHub marks the PR merged once its commits are reachable, so
the merge button is never needed.

**`--ff-only` fails loudly rather than inventing a merge commit.** If it
fails, `main` has moved: stop, reconcile deliberately, and never reach
for `--force`.

Any other state routes elsewhere. Read what `main` requires — from both
of GitHub's systems, since neither read covers the other — and the
repo's merge settings with `delete_branch_on_merge` beside them, which
step 6's disclosure needs:

```bash
gh api repos/<owner>/<repo>/rules/branches/main --jq '[.[].type]'   # rulesets, any level
gh api repos/<owner>/<repo>/branches/main --jq .protected            # classic protection
```

| State | Route |
| --- | --- |
| `main` requires no pull request, and you hold the tree | the default above |
| `main` requires no pull request, and another session holds the tree (step 1) | `git push origin <branch>:main` |
| `main` requires a pull request — **whether or not you could bypass it** | `gh pr merge <n> -R <owner>/<repo> --merge` |
| `main` also requires linear history | stop — every route inside the gate rewrites SHAs; name which, then wait |
| A squash was asked for | name what it collapses, then wait |
| A merge commit was asked for | one clause of disclosure, then proceed |

**Route on the requirement, never on a refused push.** A refusal is the
rules minus their bypass list, evaluated for whoever pushes, so an
account that can bypass is never refused: its push lands on a protected
`main` outside every required check and reports success. Succeeding is
the failure mode. A `pull_request` type in the first read is the third
row; `true` from the second needs the reference to interpret.

**Anything but the first row — read
[references/integration-routes.md](references/integration-routes.md)
before the step 6 disclosure**, not after it. Step 6 states which route
step 7 will take, so the mechanics have to be in hand while that
disclosure is being written. That file carries why each alternative is
not the default, how to read what `main` requires and why a refusal
cannot tell you, the refspec mechanics of the no-checkout route and its
two silent traps, the `gh api` settings read with its `null` caveat, and
what a squash or a merge commit costs.

Whichever line writes `main` — the local merge, the refspec push, or the
PR merge — is the write step 6 gates, whoever performs it.

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
- **`gh pr checks` exits non-zero by design** — exit code 8 is *checks
  pending*, a failure is likewise non-zero, and a repo with **no CI at
  all** exits **1**, printing `no checks reported on the '<branch>'
  branch` to **stderr** with stdout empty (gh 2.101.0, measured
  2026-09-17). That is the answer, not a broken command; do not retry
  it. "No CI configured" and "checks passed" are different states the
  exit code does **not** separate — only that stderr line does, so a
  run that discarded stderr must report neither.
- `git log --merges --oneline | wc -l` against the step 1 baseline —
  and **what counts as correct depends on the route taken**: unchanged
  after a fast-forward, exactly baseline + 1 after a sanctioned
  `--no-ff`. More than +1 is the real problem on either path, and is
  what this check exists to catch. Asserting "unchanged" flat fails a
  run that did exactly what was asked (observed 2026-09-16: baseline 1,
  post-merge 2).
- `main` and `origin/main` at the same SHA.

Report the PR number, the merged state, and the CI conclusions. If CI is
still running, say so rather than implying it passed.

## 9. Delete the branch

Step 8 has just proven the merge — the PR reads as merged, step 7's
integration succeeded, `main` and `origin/main` at one SHA — so it holds
nothing that is not in `main`. That is what makes this cleanup rather
than a judgement call, and why it is disclosed at step 6 instead of
gated here.
[references/branch-deletion.md](references/branch-deletion.md) carries
that argument in full, including why it still holds in a shared repo and
why the exemption does not generalise to any other remote delete.

```bash
git branch -d <branch>          # -d, never -D

# The remote half — probe, don't infer. GitHub may have done it already.
git fetch origin --prune
git ls-remote --heads origin <branch>               # empty = already gone

# Only when that came back non-empty:
git merge-base --is-ancestor origin/<branch> main   # guard — see below
git push origin --delete <branch>
git fetch origin --prune
```

**`-d`, never `-D`.** It refuses a branch that is not fully merged, so
the local half guards itself and the check costs nothing. It also
refuses the branch you are *on*, which is why it stays legal on the
no-checkout route.

**The remote half has no such guard, which is what the ancestor check
is for.** `-d` answers off the *local* merge whatever is on `origin`, so
a commit someone pushed to the branch after step 3 is invisible to it.
`--is-ancestor` exits non-zero to mean *no*: that is the answer, not a
broken command, and it is a stop worth reporting rather than a failure
to retry — someone pushed to this branch after you landed it, and that
work is not in `main`.

**Probe the remote ref; do not infer it from `delete_branch_on_merge`.**
Step 7 reads that setting for planning; it is the wrong thing to act on
here, because the value can change between the two — observed mid-run,
2026-09-16. **Empty from `ls-remote` means GitHub already deleted the
branch**: nothing to do, and say *that* in the report rather than
claiming the session did it. Non-empty means the delete is yours, and
the `--is-ancestor` guard applies.

**Prune on both paths — which is why the block above opens with one.**
Where GitHub auto-deleted the branch, this clone's *remote-tracking* ref
survives it: `git branch -a` still lists it, and a plain `git fetch`
will not remove it.

The reference has the evidence behind each of those three, and why
probing beats inferring even though it only narrows the window.

Do not delete, and say why, when:

- The PR is not merged, or `--ff-only` failed. The branch is the
  recovery path.
- The user asked to keep it. Honour that with no round — it costs
  nothing, and the reference says why.
- Another session is live in the tree, or is on this branch. Step 1
  already checked; the answer applies here too. Note this blocks the
  *deletion*, not the landing — step 7's variant covers that.
- **The branch is the base of another open PR.** Deleting it retargets
  that PR or closes it. This is the only exception steps 7 and 8 do not
  already establish — merge state does not show it — so it is the one
  that needs its own call, through the tool step 2 confirmed:

```bash
gh pr list --base <branch> --state open
```

or `list_pull_requests` with `base`.

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
- If the repo is not one the authenticated identity owns, stop and
  report rather than working around it. **A protected `main` is not
  that case** — a ruleset requiring pull requests is the repo working
  as intended, and step 7's PR merge lands inside it rather than
  around it. What stays banned is the workaround, and the silent form
  is the one to watch for: an account that can bypass has its direct
  push *accepted*, skipping every required status check with no
  rejection to evade. That is why step 7 routes on the requirement.

### Repo convention — overridable, but never silently

A squash and a merge commit are **defaults, not laws.** The history is
the user's to shape. But the two do not cost the same, so they do not
get the same gate: one calibrated for the expensive mechanism turns the
cheap one into ceremony, and guidance that is annoying to follow
correctly gets followed loosely.

- **A squash keeps the full round.** Name the specific commits it would
  collapse — not "squashing loses information" but "this collapses 3
  commits that separate the rule change from its fixtures" — then wait,
  then record it in the PR body. A request that named the mechanism up
  front has not heard the cost yet, so it is not yet a reaffirmation.
- **A merge commit gets one clause and proceeds.** State its cost and
  the step 1 `--merges` baseline in the same turn, record it, do it. No
  wait: the round cannot tell the operator anything the clause did not.
- **Keeping the merged branch costs nothing to honour.** No round — it
  is simply one of the exceptions step 9 already names. Say in the
  report that the branch was kept and why, or the next run reads the
  leftover ref as a bug.

Then do it. A reaffirmed instruction is the answer; pressing the point
twice is worse than the squash.
[references/integration-routes.md](references/integration-routes.md)
carries what each mechanism costs — including squash's second cost when
someone branched from your tip, which is not about your history at all —
and the `git merge -F -` trap in carrying one out.
