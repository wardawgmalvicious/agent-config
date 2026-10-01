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
git fetch origin                # origin/main current before anything reads it
git status --short              # see below — clean, or knowingly left
git branch --show-current       # must not be main
git log --oneline origin/main..HEAD
git rev-parse origin/main       # <base>, kept like step 7's <sha>: after the merge, nothing else says where main stood
git log --merges --oneline origin/main | wc -l   # the history's merges so far, for step 6
git worktree list               # separate trees — not who shares this one
git branch -vv                  # where HEAD is, and each branch's tip
git rev-parse --path-format=absolute --git-dir --git-common-dir   # two paths: a linked worktree
```

**A dirty tree is not automatically unfinished work.** `commit` ends on
a clean tree *or* on remaining lines it names as intentionally left, so
a leftover is a question rather than a stop: ask whether it belongs in
this branch. Uncommitted work does not travel into the PR either way —
what matters is that nothing which *should* have been committed is
sitting unstaged. Anything you cannot account for, stop and ask.

Nothing to land means there is nothing to do — say so rather than
opening an empty PR.

**Where the repo's instructions land this branch without a push, follow
them instead**, unless a push or a PR was asked for: step 3 publishes
every unpushed commit beneath the branch. agent-config's
`docs/handoffs/CLAUDE.md` lands a brief's worktree that way.

**Two different paths from the last command mean a linked worktree**:
steps 7 to 9 change there, and a generated branch name is renamed first.
Read [references/linked-worktree.md](references/linked-worktree.md)
before step 3.

**Check whether another session is live in this working tree, then
ask.** Step 7's default runs `git switch`, and one working tree has one
HEAD, so the switch is not scoped to you — it moves the branch under
anyone else working here. **`ListAgents` answers this; the two git
commands above cannot.** They report worktrees and refs, and print the
same thing whether one session shares this HEAD or five — measured
2026-09-22, when both came back clean while `ListAgents` named two live
sessions in the tree. Read every row rather than matching on the repo's
name: a session is named for its working directory, so one in a
subdirectory shares this HEAD under another name. What the git commands
do show is a branch tip equal to your own — the tell that someone cut
their branch from yours, which is what makes the merge method at step 7
load-bearing. Asked directly, a user answers about *subject matter* —
"working on something else that won't touch your edits" is truthful and
entirely compatible with sharing this HEAD, which is what it turned out
to mean on 2026-09-15.

**The answer expires.** Re-run `ListAgents` immediately before each
command that moves HEAD — step 7's `git switch`, and step 9's when it
has one — and read HEAD in the same command as the move, because a
session that has *ended* is invisible to `ListAgents` while its moves of
HEAD are not. On 2026-09-22 a switch made after the check, once the one
peer it found had ended and two others had started, put one of their
next commits on `main`, unnoticed for over an hour. The reflog records
every move and never the mover, so the check comes before the move.
**A row `scripts/never-prompted.sh` passes was never prompted and is
not live** ([why](references/never-prompted-sessions.md)): give it the
rows here and again in each move's command, ahead of the move, and name
at step 6 what it passed. A failed read keeps a row live.

Someone being live is **not** a reason to abandon the landing — step 7
has a no-checkout route for exactly this case. Disclose it at step 6
and take it. The structural answer is a worktree per session, each with
its own HEAD — a decision about how sessions start, not one to make
mid-landing.

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
2026-09-04): the shell profiles — and, for callers that never read one,
wrapper files on `PATH` — wrap `gh` to act as the account named
by the repo's `user.name`, resolved per call through a scoped
`GH_TOKEN`, so a personal repo gets the personal account and a client
root gets the client one. Four consequences.

- `gh auth status` reports the keyring's *active* account, not the one
  the wrapper will use. **`gh api user -q .login` is the honest probe**
  either way, which is why it is the command above.
- The probe vouches only for a `gh` that reaches the wrapper, and what
  reaches it depends on how the wrapper is built. A shell function is
  invisible to anything that execs `gh` — `timeout`, `env`, `xargs`, a
  script. A wrapper file on `PATH` catches those unless a `gh.exe` sits
  earlier on `PATH`, and never catches a native program, which on
  Windows looks only for `gh.exe`. Whatever misses the wrapper acts as
  the keyring's active account, so the probe passes while the action
  runs as someone else. **Probe through the exact invocation the action
  will use.** This machine's wrappers, and the `GH_TOKEN` pin for a
  caller they cannot reach, are in `~/.claude/CLAUDE.md` § "Git identity
  is folder-scoped".
- **A wrapper that resolves nothing falls through to the active account
  as well.** It has nothing to go on where `user.name` is unset — any
  clone outside every identity root — or names no keyring login, and it
  can do so without a word (measured 2026-09-23). The probe reports the
  fallback honestly, so compare its answer with the owner in
  `git remote -v`, never with `user.name`: that is empty there, or is
  the very name that failed to resolve.
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

**On a private repo the same gap is a 404**: GitHub answers 404 rather
than confirm the repo exists, and a fine-grained token reaches only its
resource owner's repos, or a selection, and public ones alone while an
organization's approval is pending (docs.github.com, re-read
2026-09-29). Step 2's match settles `~/.claude/CLAUDE.md`'s
identity-first reading, so take the 403's fallback; the same tool
reading a public repo confirms it. Seen on a client's private repo,
2026-09-27, where the confirmed `gh` then opened the PR.

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
exactly what happens next: which route step 7 will take and what chose
it (a repo document, by name, or the default), its write to `main`, and
**then deleting the branch locally and on `origin`** (step 9). The
deletion is disclosed here rather than prompted for afterwards — one
decision taken before the work, not a third gate on an action this
recoverable. Ask in the same breath whether anything outside git is
bound to the branch — a workspace synced to it (Fabric's "branch out"
creates one), a preview environment, a deploy target pinned to the ref.
Step 9's other exceptions are all git-internal and cannot see one.
**Then wait.**

Everything past this point writes to `main`. Do not continue on your own
initiative, even when the merge looks routine, and even when the local
half would plainly succeed on its own — this checkpoint is the skill's
whole reason for not being one command.

## 7. Integrate — preserving every SHA

**Pin the write to one SHA first.** Read the PR's head immediately
before integrating — after required checks pass, where `main` has any —
and call it `<sha>`:

```bash
gh pr view <n> --json headRefOid -q .headRefOid   # pull_request_read method get: head.sha
```

Every route then refuses any other head — the local ones by comparing
in the same command as the write, the PR merge by
`--match-head-commit <sha>` (gh) or `expectedHeadSha`
(`merge_pull_request`) — and step 9 keys the deletion on it. A mismatch
is the answer, not an error to retry; the reference below says why
heads move and how to find which side did.

```bash
[[ "$(git branch --show-current)" == "<branch>" && "$(git rev-parse <branch>)" == "<sha>" ]] \
  && git switch main && git merge --ff-only <branch> && git push origin main
```

Re-run `ListAgents` just before (step 1); HEAD off `<branch>` catches a
mover it cannot see. A peer who appeared after step 6 moves you to the
table's second row — the same write, without the checkout. These guards
are Bash: PowerShell's `&&` runs its right side whenever the left side
*ran*, true or false, so a literal port never refuses — use
`if (…) { … }` (measured 2026-09-23, pwsh 7.6).

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
| `main` requires no pull request, and another session holds the tree (step 1) | `git push origin <branch>:main`, behind the same `<sha>` check |
| `main` requires no pull request, and the branch is in a linked worktree (step 1) | that push, or the main checkout's route: [references/linked-worktree.md](references/linked-worktree.md) |
| `main` requires a pull request — **whether or not you could bypass it** | `gh pr merge <n> -R <owner>/<repo> --merge --match-head-commit <sha> --subject … --body …` |
| `main` also requires linear history | stop — every route inside the gate rewrites SHAs; name which, then wait |
| The repo's documents name a mechanism — `CONTRIBUTING.md`, agent instructions, read before step 6 | treat it as asked for (the rows below), naming the document |
| A squash was asked for | name what it collapses, then wait |
| A merge commit was asked for | one clause of disclosure, then proceed |

**Route on the requirement, never on a refused push**: an account that
can bypass is never refused, so its push lands outside every required
check and reports success. A `pull_request` type from the first read
is the third row; `true` from the second needs the reference.

**Anything but the first row — read
[references/integration-routes.md](references/integration-routes.md)
before the step 6 disclosure**, not after it. Step 6 states which route
step 7 will take, so the mechanics have to be in hand while that
disclosure is being written. That file carries why each alternative is
not the default, how to read what `main` requires and why a refusal
cannot tell you, the refspec mechanics of the no-checkout route and its
two silent traps, the `gh api` settings read with its `null` caveat, and
what a squash or a merge commit costs, and the message each passes.

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
- **`get_check_runs` can refuse a token that opened the PR** — step 2
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
- **To wait for CI, give `gh pr checks <n> --watch` the Bash tool's
  `timeout` parameter or `run_in_background` rather than coreutils
  `timeout`.** Those keep `gh` bare, on the path step 2's probe vouched
  for, while `timeout gh` reaches a wrapper only where a wrapper file
  sits on `PATH` ahead of `gh.exe`. Where none did, in a client repo,
  the keyring's active account answered
  `Could not resolve to a Repository`, which reads as a bad slug
  (2026-09-23).
- **Read `origin/main` against the pins, never HEAD**, which the refspec
  push and the PR merge leave on the branch:

  ```bash
  git fetch origin
  git merge-base --is-ancestor <sha> origin/main          # exit 0: the pinned head landed as-is
  git log --merges --oneline <base>..origin/main | wc -l   # the branch's own merges, +1 for a merge commit
  ```

  A failed ancestor check is a squash or rebase merge, which no count
  sees; a higher count is `main` moving under the PR merge, and step 7's
  subject names yours ([measured](references/integration-routes.md#verifying-what-landed)).
- `main` and `origin/main` at one SHA: `git rev-parse main origin/main`
  prints two identical lines, after `git fetch origin main:main` wherever
  HEAD is off `main`, since a plain fetch moves `origin/main` alone.
  Never `--short`, which fails exit 128; the reference has both.

Report the PR number, the merged state, and the CI conclusions. If CI is
still running, say so rather than implying it passed.

## 9. Delete the branch

Step 8 has just proven the merge — the PR reads as merged, the pinned
head is in `origin/main`, `main` and `origin/main` at one SHA — so it
holds nothing that is not in `main`. That is what makes this cleanup
rather than a judgement call, and why it is disclosed at step 6 instead
of gated here.
[references/branch-deletion.md](references/branch-deletion.md) carries
that argument in full, including why it still holds in a shared repo and
why the exemption does not generalise to any other remote delete.

```bash
# Local — move off <branch> first if HEAD is on it; alone by a ListAgents run now
[[ "$(git branch --show-current)" == "<branch>" ]] && git switch main
git merge-base --is-ancestor <branch> <sha> && git branch -D <branch>   # keyed on <sha>, step 7's pin

# Remote — probe, don't infer. GitHub may have done it already.
git ls-remote --heads origin <branch>        # empty = already gone
# Only when that came back non-empty; deletes only while origin holds <sha>:
git push --force-with-lease=<branch>:<sha> origin --delete <branch>

git fetch origin --prune                     # both paths
```

**Both halves key on `<sha>`, never on reachability from `main`**, which
a squash or rebase merge defeats while every change is in `main`. The
reference has the measurements, including why `-d` and `git cherry`
both misfire there.

- **Local.** `--is-ancestor <branch> <sha>` exits 0 when every local
  commit is in what merged; non-zero means one reached the branch after
  the pin — keep it and report. Behind that check `-D` is safe.
- **Remote.** The lease deletes only while `origin` still holds `<sha>`.
  A refusal — `! [rejected] (delete) -> <branch> (stale info)`, exit 1
  — means someone pushed after the merge, and that work is not in
  `main`: stop and report, don't retry. A delete needs no force; the
  lease adds only the condition.

**Run each command separately** — chained, one refusal silently skips
the rest. A `<sha>` this clone lacks fails
`--is-ancestor` with `fatal: Not a valid commit name`;
`git fetch origin pull/<n>/head` brings it in, and outlives the branch.

**HEAD on `<branch>` is the one local case that needs the move**: `-D`
refuses it, and the PR merge leaves you there when you hold the tree.
With anyone else live (step 1), keep the local branch and say so. A refusing
guard is an answer: HEAD on `main` needs no move, and on any other branch
someone moved it — stop and report. Step 8 left local `main` current.
Never switch just to make the delete succeed: step 1's 2026-09-22 failure.

**Empty from `ls-remote` means GitHub already deleted the branch**: say
so rather than claiming the delete, and never infer it from
`delete_branch_on_merge`, which changed mid-run once (2026-09-16). **The
prune runs on both paths**: an auto-deleted branch leaves this clone's
remote-tracking ref behind. The reference has the evidence for both.

Do not delete, and say why, when:

- The PR is not merged, or `--ff-only` failed. The branch is the
  recovery path.
- The user asked to keep it. Honour that with no round — it costs
  nothing, and the reference says why.
- Another session is live in the tree, or is on this branch — by a
  `ListAgents` run now and step 1's script, since step 1's answer has
  expired. Note this blocks the *deletion*, not the landing — step 7's
  variant covers that.
- **The branch is checked out in a linked worktree** still on disk: git
  refuses the local delete from either side until the worktree goes;
  [references/linked-worktree.md](references/linked-worktree.md) says
  when the worktree can go, and what to hand the user.
- **Something outside git is bound to the branch** — the question step
  6 asked. What breaks when a bound branch is deleted has never been
  tested; the question is here because asking it only after the merge
  cost a round trip once (2026-09-22).
- **The branch is the base of another open PR.** Deleting it retargets
  that PR or closes it. This is the only exception steps 6 to 8 do not
  already establish — merge state does not show it — so it is the one
  that needs its own call, through the tool step 2 confirmed:

```bash
gh pr list --base <branch> --state open
```

or `list_pull_requests` with `base`.

## Constraints

**Two kinds, and the difference is the point.** The first are
correctness and identity — an instruction does not lift them. The second
are convention — the repo's written one, else this skill's default —
yours to override; make the override informed rather than refusing it.

### Absolute — an instruction to do these is a stop, not an override

- **Never file the PR through an identity step 2 did not confirm.**
  Identity, not preference. "Just use `gh`" is not a licence on its
  own, because it files under whichever account `gh` resolves to here,
  and that is not something anyone can consent to without first being
  told which one. Once the login is confirmed against the repo, `gh` is
  as good as the MCP; until then, report the mismatch.
- **Never `--force`, never `--no-verify`** — including to get past a
  failed `--ff-only`. Step 9's `--force-with-lease` is on a *delete*,
  which needs no force; there it only adds a condition, and it licenses
  nothing anywhere else.
- **Never write to `main` before step 6.** Opening a PR and pushing
  `main` are two decisions, not one.
- **Never `git switch` while another session is live in the tree** —
  live by a `ListAgents` run immediately before the switch and step 1's
  script inside its command, never by step 1's run or by an instruction.
- If the repo is not one the authenticated identity owns, stop and
  report rather than working around it. **A protected `main` is not
  that case** — a ruleset requiring pull requests is the repo working
  as intended, and step 7's PR merge lands inside it rather than
  around it. What stays banned is the workaround, and the silent form
  is the one to watch for: an account that can bypass has its direct
  push *accepted*, skipping every required status check with no
  rejection to evade. That is why step 7 routes on the requirement.

### Repo convention — overridable, but never silently

A squash and a merge commit are **defaults, not laws**, gated by what
they cost. **A squash keeps the full round**: name the commits it would
collapse, then wait, since a request that named it up front has not
heard the cost, and record it in the PR body. A merge commit, or a
squash of one commit, gets one clause and proceeds. Once reaffirmed, do
it: pressing the point twice is worse than the squash.
[references/integration-routes.md](references/integration-routes.md)
§ "Overriding the default" has each in full; step 9, the kept branch.
