---
name: land
# model: inherit  # any model: value blocks Copilot slash invocation
effort: max
disable-model-invocation: false
description: "Takes a committed branch from local to merged — pushes it, confirms which GitHub account each tool actually acts as in this repo, opens the PR through the one that matches (github-mcp where loaded, gh where its login is confirmed), then fast-forwards main, reports CI, and deletes the merged branch locally and on origin. Guards two silent failures: gh and github-mcp can authenticate as different accounts, so a PR lands under the wrong identity with no error, and integration preserves every SHA — a local --ff-only merge by default, or a no-checkout ref fetch where another session holds the tree or main is protected — because a squash would collapse the logical split /commit just made. Stops for confirmation before the write to main. To make the commits first use commit; to review before landing, code-review."
when_to_use: "Use when asked to land, ship or publish a branch, open a pull request, merge to main, or get a branch in — the step after /commit. Use it even when the request already names the mechanism — 'squash these and merge', 'just merge it into main', 'force push it' — a named mechanism is the case these guards exist for, not a reason to skip them."
---

# Landing a branch

Take a branch that is **already committed** and get it merged. `commit`
ends by reporting its hashes with an explicit note that nothing was
pushed; this starts exactly there.

Two things here are irreversible or outward-facing — opening the PR and
writing to `main` — so the procedure gates each one. A third, deleting the
branch from `origin`, is outward-facing and deliberately **not** gated;
step 9 says why, and why that reasoning does not generalise.

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

Why not each alternative:

- **The merge button** — whatever it is configured to do, it is not
  this. Check what the repo actually offers before assuming the button
  was an option at all: where only squash is enabled, the button can
  *only* do the one thing this skill refuses, so there is no version of
  pressing it that preserves the split.
- **A merge commit** — adds a commit to a history that may never have
  had one, and collapses nothing: every SHA survives. `git log --merges
  --oneline | wc -l` from step 1 says whether this repo is in that
  category; a `0` there makes a merge commit a visible break in
  convention rather than a neutral choice, and a non-zero makes it
  close to a neutral one. Asked for, it costs a clause of disclosure
  and not a round — see [Constraints](#constraints).
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

### Variant — land without a checkout

**`git switch` is not required to move `main`.** The two conditions that
call for this route want different writes, and the difference is a merge
commit. Where **another session holds the tree** (step 1) and nothing
refuses a direct push, the write is the branch pushed *to* `main` — the
default's fast-forward minus the checkout. Where **a ruleset refuses
that push**, the merge goes server-side, and only the first line changes:

```bash
git push origin <branch>:main   # the write — ff-enforced by default
# refused by a ruleset? swap line 1 for: gh pr merge <n> -R <owner>/<repo> --merge
git fetch origin --quiet
git fetch origin main:main      # moves the local main REF; HEAD untouched
git merge-base --is-ancestor <branch> main
```

**Push first, fall through on a rejection — not the reverse.** The
server-side `--merge` adds a merge commit — a visible break where the
step 1 `--merges` baseline is `0`, and a shared tree alone needs none.
**Pass `-R <owner>/<repo>` on the fallback**: it clears gh's
`CanDeleteLocalBranch`, which gates every local-git path, so the merge
cannot switch the tree; step 9 owns the delete. Read in gh v2.101.0.

Both refspec forms **refuse a non-fast-forward without a leading `+`**
— `! [rejected] <src> -> main (non-fast-forward)`, exit 1 — so neither
can rewrite `main`, only advance it. **Never add the `+`**; that is the
`--force` of this route. The fetch has one more (pair reproduced
2026-09-16, push 2026-09-17 on git 2.55):

- **It refuses to update a branch that is currently checked out** in a
  non-bare repo: `fatal: refusing to fetch into branch
  'refs/heads/main' checked out at ...`, exit 128. So it is legal
  *precisely* when someone else's branch is HEAD, and it fails loudly
  in the one case where it would be unsafe.

This route is still gated by step 6: whichever line writes `main`, the
push or the PR merge, is the write, whoever performs it.

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

**Prune on both paths — which is why the block above opens with one.**
Where GitHub auto-deleted the branch, `origin/<branch>` is gone
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
- If the repo is not one the authenticated identity owns, stop and
  report rather than working around it. **A protected `main` is not
  that case** — a ruleset requiring pull requests is the repo working
  as intended, and step 7's variant lands inside it rather than around
  it. What stays banned is the workaround: an admin bypass that also
  skips every required status check is worse than the rejection it
  evades.

### Repo convention — overridable, but never silently

A squash and a merge commit are **defaults, not laws.** The history is
the user's to shape. But the two do not cost the same, so they do not
get the same gate: one calibrated for the expensive mechanism turns the
cheap one into ceremony, and guidance that is annoying to follow
correctly gets followed loosely.

**A squash keeps the full round.** It collapses the logical split
`commit` just built, and that is not recoverable.

1. **Say what it costs, specifically.** Name the commits that would be
   collapsed — not "squashing loses information" but "this collapses 3
   commits that separate the rule change from its fixtures".
2. **Then wait.** A request that named the mechanism up front has not
   heard the cost yet, so it is not yet a reaffirmation. One round.
3. **Record it in the PR body**, so the history explains its own shape.

Then do it. A reaffirmed instruction is the answer; pressing the point
twice is worse than the squash.

**Squash has a second cost whenever someone branched from your tip**,
and that one is not about your history. Preserving the SHAs —
`--ff-only` or a merge commit, either — leaves their base reachable
from `main`, so `git log main..<their-branch>` comes back empty and
their branch sits on `main` with nothing to rebase. A squash writes a
new SHA, leaving your commits unreachable from `main`: their branch
carries them as duplicates and their next PR re-proposes your whole
diff as theirs. Step 1's `git branch -vv` is what shows this — a branch
tip equal to your own (observed 2026-09-15).

**A merge commit gets one clause and proceeds.** It collapses nothing:
every SHA survives, and every commit stays independently revertible and
citable. Its whole cost is one extra commit and a non-linear graph — so
state that and the step 1 `--merges` baseline in the same turn, record
it in the PR body, and do it. **No wait**, because the round cannot
tell the operator anything the clause did not, and holding one is the
"pressing the point twice" this section already warns against. Reasoned
2026-09-16, on a repo whose baseline was already `1` and where a merge
commit therefore broke no convention at all.

One trap in carrying that out: **`git merge -F -` does not read
stdin.** It fails `error: could not read file '-'` (exit 129) where
`git commit -F -` succeeds, so a merge message has to go through a real
file. Reproduced 2026-09-16.

**Deleting the merged branch is a default too, and it runs the other
way.** Step 9 does it having disclosed it at step 6, so the request that
arrives is to *keep* the branch — and that one costs nothing to honour.
It needs no cost-and-wait round; it is simply one of the exceptions step
9 already names. Say in the report that the branch was kept and why, or
the next run reads the leftover ref as a bug.
