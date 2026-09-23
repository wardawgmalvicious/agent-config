# Handoff: every guard in `land` and `commit` that reads the wrong state

- **Written**: 2026-09-22, consolidating the workflow-skill halves of two
  inbox notes filed the same day by two sessions sharing one working tree
  in a client estate repo —
  `2026-09-22-kusto-alter-table-semantics-and-branch-consumers.md`
  learnings 5 and 7–11, and
  `2026-09-22-no-tzdata-and-shared-tree-commit-guard.md` learnings 2, 4
  and 5.
- **Source notes deleted** 2026-09-22, with the user's explicit approval,
  once this brief carried their content — so this file and `git log` are
  now the only record of them.
- **Kind**: payload edits to `skills/workflow/land/SKILL.md`, its
  `references/integration-routes.md` and `references/branch-deletion.md`,
  and `skills/workflow/commit/SKILL.md`. **All four are junctioned**, so
  every edit is live in every session on this machine the moment it hits
  disk — see Deployment.
- **Status**: **Open, nothing landed.** Item 1 is a **live defect in
  deployed payload**, re-verified in this repo 2026-09-22 against the
  current file rather than taken on the note's word. Items 2, 3 and 7
  are recorded failures with timestamps. Items 4, 5 and 6 are smaller.
- **Run in**: this repo. `/test-skill` is not needed — no `paths:` glob,
  no fixture and no `description` trigger change except item 1, which is
  a correction *within* the `description` and does change the listing
  text. See Verification.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## What unites these, and why they are one brief

Every item is the same defect in a different place: **a guard that
encodes an argument through a command, where the command measures
something the argument does not depend on.** `-d` tests ancestry to
answer "is this merged". `git status` reports files to answer "is this
commit safe". A refusal tests a ruleset to answer "does a gate apply to
me". The route table tests a push failing to answer "should I push".

Each reads correctly in the case it was written for, and each keeps
returning a confident answer outside it. That is why they were found
together and why splitting them across four briefs would lose the
pattern — but they are independently landable, so execute in any order.

## Evidence status, per item

The two source notes were unusually careful about this, marking their own
inferences. That is preserved rather than flattened.

| Item | Status |
| --- | --- |
| 1 — `description` routes a protected `main` past the gate | **Re-verified here 2026-09-22** against the live junctioned file; the ruleset half is relayed and single-sourced |
| 2 — the peer check expires between step 1 and steps 7/9 | **Recorded failure**, reflog quoted, attribution confirmed by both sessions exchanging records |
| 3 — a squash defeats step 9's guards | **First-hand**, plus a **controlled two-arm repro** of the half the first note marked as inference |
| 4 — pin the merge to the validated SHA | **Pass direction used once**; the reject direction is API-documented and **not exercised** |
| 5 — a branch can have non-git consumers | **Consequence unverified** — the question is legitimate, what breaks was never tested |
| 6 — `rev-parse --short` takes one revision | **Reproduced**, git 2.55.0.windows.3 |
| 7 — a clean `git status` does not make a commit safe | **Recorded failure**, same reflog as item 2, seen from the other seat |
| 8 — `/commit` never asks whether to branch | **Observed once**; the user named the gap in their own words |

---

## 1. The `description` routes a protected `main` to the path that bypasses its own gate

**This is live.** `skills/` is junctioned, so the text below is in every
session's listing on this machine right now.

[`land/SKILL.md`](../../../skills/workflow/land/SKILL.md) line 6
advertises the no-checkout route as applying "where another session holds
the tree **or main is protected**". The body does not agree. Its route
table gives a protected `main` its own row:

```text
| Another session holds the tree (step 1) | git push origin <branch>:main   |
| A ruleset refuses that push             | gh pr merge <n> -R <o>/<r> ...  |
```

A session routing off the `description` takes the refspec push straight
into a protected branch. **The body already bans that outcome in as many
words** — Constraints says a protected `main` "is the repo working as
intended, and step 7's variant lands inside it rather than around it",
and calls an admin bypass that skips required checks "worse than the
rejection it evades". So the skill knows; the description recommends it
anyway.

**Why the body's own guard cannot catch it.** The route table branches on
the push being **refused**. That tell does not fire for an account that
can bypass. Measured in the origin repo 2026-09-22: the `main` ruleset is
active and carries `deletion`, `non_fast_forward`, `pull_request` and a
required status check — and `bypass_actors` includes the admin repository
role at `bypass_mode: always`, which the acting account holds. The push
is therefore not refused.

**Two edits, and the second is the one that matters.**

1. Fix the description. Drop "or main is protected" from the no-checkout
   route's applicability. Headroom is not the constraint: the
   `description` measured 817 of its 1024 budget on 2026-09-22, so a
   correction displaces nothing — re-measure before editing rather than
   trusting that figure.
2. **Re-key the route table row on bypass, not on refusal.** "A ruleset
   refuses that push" is an observation available only *after* attempting
   it, and it asks the wrong question. What decides the route is whether
   a gate applies **to the acting account** — the ruleset minus its
   bypass actors. Where the account can bypass, `gh pr merge` is still
   correct even though the direct push would have succeeded. Succeeding
   is the failure mode.

**One correction to the source note, found while verifying.** It states
that the description's "ref fetch" wording is wrong because "nothing in
the skill fetches anything". That is no longer true:
[`references/integration-routes.md`](../../../skills/workflow/land/references/integration-routes.md)
line 72 runs `git fetch origin main:main`, landed from the 2026-09-15
inbox note after this note's author last read the file. The naming is
still loose — the route's *write* is a refspec push and its fetch only
moves the local ref afterwards — so say "refspec push" and keep the
fetch where it is. The substantive half is untouched by this.

**Generalization worth landing somewhere.** A ruleset's existence is not
a gate. A gate is a ruleset **minus its bypass actors, evaluated for the
identity that will act**. Any guidance branching on "the protected branch
will refuse me" is unsound for an account that can bypass — which in a
small estate is routinely the only account there is.

**The ruleset facts are single-sourced.** They were read by a second
session in the same tree and relayed, not reproduced. Re-read the rule
list and the bypass mode before writing either into the payload as fact.
The reasoning survives whatever the details are, because it needs only
that *some* always-bypass actor exists.

---

## 2. The live-peer answer is taken at step 1 and acted on at steps 7 and 9

Step 1 asks whether another session is live in the tree. Steps 7 and 9
then *depend* on the answer — step 7 to choose the route, step 9 for
whether the local delete is safe — and Constraints makes it absolute:
"Never `git switch` while another session is live in the tree." Nothing
says the answer has a shelf life. It reads as a preflight fact, like the
merge-count baseline, when it is a live condition.

**What happened**, one shared tree, 2026-09-22, branch names genericized:

```text
18:55:56  main -> <branch-a>        session A
19:08:54  <branch-a> -> <branch-b>  session B, git switch -c
19:15:35  <branch-b> -> main        session A, /land step 9 cleanup
19:20:40  commit on main            session B -- LANDED ON THE WRONG BRANCH
19:21:35  main -> <branch-b>        session B, force-moving the branch to recover
```

A switched to `main` to delete its merged branch, which is exactly what
step 9 prescribes. That switch arrived between B's `switch -c` and B's
`git add`. **Nothing failed, nothing errored, and neither session noticed
for over an hour.**

**Root cause, and it is two things.**

1. **Step 1's named commands cannot answer the question it asks.**
   `git worktree list` and `git branch -vv` report worktrees and refs.
   Neither shows a live *session*, and multiple sessions in one worktree
   is precisely the case they render invisible — `git worktree list`
   prints one line whether one session or five are in it. The tool that
   answers is `ListAgents`, which step 1 never names. **This is measured,
   not reasoned**: session B ran the same step 1 in the same window, got
   both commands back clean, and `ListAgents` named two live sessions in
   the tree. That is the only reason B took the no-checkout route.
2. **Even a correct answer is a snapshot.** Session A *had* run
   `ListAgents`, found one peer, negotiated the HEAD move with it and got
   agreement. By 19:15:35 that peer had **ended** and two others had
   started. The negotiation was real and worthless.

**Both changes are required; either alone still fails.** Naming the right
command does not help if it is read once, and re-reading the wrong
command answers nothing however often it runs.

1. Name `ListAgents` in step 1. Read the **whole listing** —
   `claude/CLAUDE.md` already warns that filtering peers by repo-name
   prefix misses a session in a subdirectory, and such a session shares
   HEAD exactly like one at the root.
2. Re-run it immediately before **each HEAD-moving command** — the step 7
   integration and the step 9 `git switch` — and say that the answer
   expires. An *ended* session is invisible to the check while its
   effects on HEAD are not.

**The generalization is the part worth keeping: the reflog records the
move but never the mover.** Reconstructing this timeline took two
sessions volunteering their own records to each other, and both
mis-attributed a move before it resolved; one pair is still unattributed
and probably belongs to a session that has since ended. So the check
happens *before* the operation or not at all.

**The durable fix is structural, and it belongs to another brief.** One
worktree per session gives each its own HEAD and retires this whole class
along with the no-checkout route. That is
[worktree-isolation-scope.md](worktree-isolation-scope.md)'s subject —
and note what it concludes: a worktree buys the index and **not** the
shared document. This class is index-and-HEAD, so it is squarely the half
a worktree does fix. Propose it in the skill as the recommendation with
the coordination protocol as the fallback; do not decide it here.

---

## 3. A squash defeats step 9's guards, and the skill would misdiagnose the result

Step 9 deletes the merged branch behind two guards — `git branch -d` for
the local half, `git merge-base --is-ancestor origin/<branch> main` for
the remote half. **Both test SHA reachability.** A squash writes a new
commit and leaves the branch's own SHA unreachable from `main`, so both
say "not merged" about a branch whose every change is in `main`.

**The misdiagnosis is the worse half.** Step 9 says of `--is-ancestor`:
"someone pushed to this branch after you landed it, and that work is not
in `main`." After a squash that reading is **wrong**, and the skill would
report a foreign push that never happened.
[`references/branch-deletion.md`](../../../skills/workflow/land/references/branch-deletion.md)
line 53 carries the same sentence.

**The `-d` half was inference, and is now measured.** The first note
observed `-d` *succeeding* on a squash-merged branch and correctly
attributed it to the remote-tracking ref still existing — git accepts
"merged into its upstream" as sufficient, and the warning says so. It
marked the other half as unmeasured. The second note ran both arms
controlled, git 2.55.0.windows.3:

```text
CASE A — remote-tracking upstream still present
  git branch -d feat/x -> exit 0
      warning: ... merged to 'refs/remotes/origin/feat/x',
               but not yet merged to HEAD

CASE B — same squash, remote deleted and pruned
  git branch -d feat/x -> exit 1
      error: the branch 'feat/x' is not fully merged
```

So `-d` tests *merged into its upstream* when one is set, and falls back
to the HEAD test a squash defeats only when there is none. **Nothing in
the first note is retracted.**

**Two consequences that only appear on a run where `-d` succeeds**, and
both are landing-relevant:

- **The failure is intermittent, and step 9's own ordering hides it.**
  Step 9 runs `git branch -d` **before** its `git fetch --prune`, so on a
  repo that does not auto-delete, the upstream is still there and `-d`
  quietly succeeds. Same skill, same route, same squash — misfires or not
  depending on repo settings and fetch history. An intermittent guard is
  worse than one that always fails, because the passing runs teach that
  the guard works.
- **`-D` is not a safe unconditional replacement.** Where `-d` already
  succeeded, `-D` exits non-zero with `error: branch '<name>' not found`
  — and in an `&&` chain that skips everything after it. Measured: the
  chain doing local delete, remote delete and prune lost both remote
  steps that way, leaving `origin/<branch>` alive after a run that
  reported success. The branch listing caught it; nothing in the output
  did.

**Correct approach — branch step 9 on the route step 7 took**, the way
step 8's merge-count row already does:

- After `--ff-only` or the refspec push: the guards as written.
- After a **squash or rebase**: check *content*, not ancestry.
  `git cherry origin/main <branch>` prints `- <sha>` for each branch
  commit whose patch is already upstream; every line `-` means safe.
  Then `git branch -d <branch> || git branch -D <branch>`, which is the
  honest form given the two consequences above. Say that explicitly
  rather than leaving "never `-D`" absolute.
- In the `--is-ancestor` paragraph: non-zero after a squash is
  **expected**, not a foreign push.

A merge commit is fine — the branch tip is one of its parents — so this
is squash and rebase only.

**Two smaller things belonging in the same edit.**

- **A single-commit squash has no round to keep.** Constraints says a
  squash "keeps the full round. Name the specific commits it would
  collapse — then wait." With one commit nothing collapses, and the
  section's own principle — "a gate calibrated for the expensive
  mechanism turns the cheap one into ceremony" — says the round is empty.
  The origin landing took that exemption unasked. The skill should say
  whether it may; the note's author would say yes, with the cost stated
  in one clause like the merge-commit case.
- **Preserve the message.** An API squash defaults the body to a commit
  list, discarding the body `/commit` wrote — the text step 5 calls "the
  deliverable". Pass `commit_title` / `commit_message` (MCP) or
  `--subject` / `--body` (gh).

---

## 4. Pin the merge to the SHA that CI validated

Steps 6 to 7 wait for the required check, then merge. Between "checks
passed" and "merge issued" the PR head can move — a workflow that pushes
to PR branches, a peer session, the author. The merge then lands a head
CI never validated, and nothing reports it. Not hypothetical: the origin
repo runs a workflow on every PR that pushes a binding flip to the branch
when needed.

**Pin the merge to the validated head.** `merge_pull_request` takes
`expectedHeadSha`; `gh pr merge` takes `--match-head-commit <sha>`
(present in the installed gh, checked 2026-09-22). Read the head *after*
checks pass — `gh pr view <n> --json headRefOid`, or `pull_request_read`
— and pass that SHA. A mismatch fails the merge instead of silently
landing the wrong commit.

**Generalization.** Verification and action should share a key. "Checks
passed" is a fact about a SHA; "merge" is an action on a ref; the ref can
move between them.

**Evidence limit to carry into the text.** Used in the pass direction
once, 2026-09-22 — the merge succeeded with `expectedHeadSha` set. The
reject direction is GitHub-API-documented and **not exercised**; on that
PR the workflow ran and was a no-op, so the head did not in fact move.
The mechanism is what is real.

---

## 5. A branch can have consumers outside git

Step 9's "Do not delete, and say why, when:" list has four entries — PR
not merged, user asked to keep, another session live in the tree, branch
is the base of another open PR. **All four are git-internal.** The skill
has no notion that something outside git can be bound to a branch.

In a Fabric Git-synced repo, "branch out to new workspace" creates a live
workspace synced to that feature branch; the origin repo's own
`CONTRIBUTING.md` calls it "a live Fabric environment" and separately
warns never to rebase a branch one is bound to. Broader than Fabric, and
better written that way: a preview or ephemeral environment, a CI or
deploy target pinned to the ref.

**Where it goes.** One bullet in step 9's list, and — more usefully —
one clause in **step 6's disclosure**, so the question is asked before
the merge rather than after it. Step 6 exists precisely so the deletion
decision is taken once, up front.

**Write it as a question to ask, not a documented failure mode.** What is
established is that the question is legitimate and that asking it late
cost a round trip. What was never tested is what actually breaks when a
branch is deleted under a bound workspace — nothing was bound, so the
risk never materialized.

---

## 6. `git rev-parse --short` takes exactly one revision

Step 8's last bullet, "`main` and `origin/main` at the same SHA", gives
no command. The natural one, `git rev-parse --short main origin/main`,
fails with `fatal: Needed a single revision`, exit 128 — and was run
twice in one landing before the error was read rather than retried.
git-rev-parse(1) defines `--short` as "same as `--verify` but shortens
the object name", and `--verify` takes one revision.

Name the command in the bullet:

```bash
git rev-parse main origin/main     # two identical lines is the pass
```

**Generalization, and the reason this trivial item is here:** a
verification a skill states as a *condition* but not as a *command* gets
improvised, and the improvisation is where the error goes. It recurred
within one session.

---

## 7. In a shared tree a clean `git status` does not make a commit safe

This is item 2 from the other seat, and it is the seat `land` cannot
reach: **a session that is only committing never loads `land` at all.**

`git status` reports files and index *relative to HEAD*. It cannot report
that HEAD moved, nor where the next commit will land — which is why "the
tree is clean, so nothing is at risk" was said in that session and was
wrong. `commit`'s § "When another session shares this tree" names the
*hunk* hazard and prescribes one chained command, but **the chain never
reads the branch**, and the section's opening — "neither staging nor a
branch isolates you" — is about files.

**Put the branch check inside the chain**, immediately before staging, so
the window is the width of one process rather than an editing session:

```bash
[[ "$(git branch --show-current)" == "<branch>" ]] \
  && git add <paths> && git commit -F - <<'MSG'
…
MSG
```

A mismatch means someone moved HEAD: stop, `ListAgents`, ask, re-switch —
and re-switching is itself a HEAD move for them, so it gets the same
courtesy. If the commit has already landed on the wrong branch, recovery
is `git branch -f <branch> <sha>` plus resetting the wrong branch's ref
back to its upstream, and that reset is a HEAD move too.

**Generalization: HEAD is ambient state, not a handoff token.** Every
operation whose target is "the current branch" — `commit`, `branch -d`
(refuses the current branch), `merge --ff-only` — depends on a value any
peer in the tree can change with no error on either side. Check it in the
same command as the operation, not a step earlier.

**Two edits**: the "Write, stage and commit in one chained command"
bullet gets the guard and the sentence on what `git status` cannot show;
the section's first sentence gets HEAD alongside files and the index.
Cross-reference item 2 rather than restating the reflog.

**Note the shape this repeats.** `claude/CLAUDE.md`'s "Run `ListAgents`
before editing" paragraph already observes that `commit`'s shared-tree
section never loads for an *editing-only* session. This is the same
observation one skill along — the fix keeps being routed to the skill the
affected session does not invoke.

---

## 8. `/commit` never asks whether to branch in a PR-gated repo

`/commit` invoked on `main` in a repo whose convention is PR-only. The
skill commits where it stands. `claude/CLAUDE.md` § "Branch naming"
already states the principle — a PR-bound change wants a branch from its
first commit, because `/land`'s preflight refuses `main` — but nothing in
`/commit`'s survey asks, so the principle fires only on unprompted
recall.

The user's own reaction afterwards, *"I should have said land and not
commit"*, is the evidence: **no command covers uncommitted work on `main`
in a PR repo**, and each of the two that exist assumes the other ran.

One bullet in "Survey first":

```text
On `main`? Check whether this repo lands changes by PR —
CONTRIBUTING.md, `git log --first-parent`, or the branch ruleset. If it
does, branch before committing; /land cannot start from here.
```

Cross-reference `claude/CLAUDE.md` § "Branch naming" rather than
restating it, and note that in a shared tree the `switch -c` is itself
the HEAD move item 2 is about.

**This repo is the counter-example and the bullet must not break it.**
`agent-config`'s own convention is every commit on `main`, stated in
[CLAUDE.md](../../../CLAUDE.md) § "Branching and concurrent sessions" and
explicitly named there as the worked example of a repo convention
outranking the machine-wide default. The bullet asks a question whose
answer here is *no, this repo does not land by PR* — so it must be phrased
as a check, never as an instruction to branch.

**Generalization.** A principle in always-loaded config still needs a
prompt at the step where it applies, or it depends on recall.

---

## Deployment

All four files are under `skills/workflow/`, which is **junctioned**, so
each save is live in every session on this machine before the commit —
including the sessions of anyone else working here. `link-claude.ps1` is
**not** needed and should not be run for these edits.

That cuts both ways for item 1: it is why the defect is live now, and why
the fix is live the moment it is written.

## Verification

- `uv run --with pyyaml scripts/lint-frontmatter.py
  skills/workflow/land/SKILL.md` — item 1 edits the `description`, and
  `DESCRIPTION_MAX` is the check that it still fits. Re-measure the
  current length rather than trusting the 817 figure above.
- `uv run --with pyyaml scripts/skill-status.py --stale` — a body change
  to a behavioural skill invalidates its test stamp, so both `land` and
  `commit` will want a retest. That is the honest cost of this brief and
  it is not small.
- `pre-commit run --all-files` clean.
- **No activation run.** No `paths:` glob changes, so
  `test-activation.ps1` has nothing to say here.

**What cannot be verified from this repo**, and should be said in any
text that lands: items 1 and 4 concern GitHub ruleset and merge-API
behaviour in a repo this payload does not control. `agent-config` is
public with no PR requirement and every commit on `main`, so it cannot
exercise either path.

## Dependencies

- [worktree-isolation-scope.md](worktree-isolation-scope.md) owns the
  structural alternative to items 2 and 7 — one worktree per session,
  each with its own HEAD and index. Neither blocks the other: this brief
  fixes the guards for a shared tree, that one asks whether the tree
  should be shared. **Land this one regardless of how that decides**,
  because client repos where these failures happened are not covered by
  any choice made here.
- [peer-coordination-open-questions.md](peer-coordination-open-questions.md)
  is where `ListAgents` guidance was last decided, and its one remaining
  verification run — a cold re-run showing `ListAgents` fires before a
  queue edit — is the same instrument item 2 wants named in `land`
  step 1. Different setup, so not the same run.
- Item 3's two halves come from two notes by two sessions, the second
  annotating the first. **Land them as one edit**; the first supplies the
  argument and the route branching, the second the measurement, the
  ordering caveat and the `-d || -D` form.
- Nothing here blocks [handoff-queue-derived-count.md](handoff-queue-derived-count.md)
  or the Fabric work.
