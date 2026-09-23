# Integration routes

Everything behind step 7's routing table: why the default is the
default, how to read what `main` requires, the mechanics of the
no-checkout route, and what it costs to honour a request for a squash
or a merge commit.

Read this **before the step 6 disclosure** whenever the run is taking
anything but the default `--ff-only` route. Step 6 has to state which
route step 7 will take, so the mechanics have to be in hand while that
disclosure is being written, not after.

## Why not each alternative

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
  and not a round — see [Merge commit](#merge-commit--one-clause-and-proceed).
- **Squash** — collapses the logical split `commit` just built. The
  whole point of separate commits is that each is independently
  revertible and citable. Asked for anyway? It is overridable, but not
  silently — see [Squash](#squash--the-full-round).
- **Rebase merge** — rewrites SHAs, and may be disabled outright.

## Reading the repo's merge settings

Read the merge settings rather than assuming them — and read
`delete_branch_on_merge` in the same breath, which step 6's disclosure
needs and which is no more uniform across repos than the other three.
**Prefer a committed answer where the repo keeps one** — a repo that
version-controls its own settings (agent-config keeps all four in
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

**`delete_branch_on_merge` is for planning only.** Step 9 probes the
remote ref instead of acting on this value, and
[branch-deletion.md](branch-deletion.md) says why.

## Reading what `main` requires

**Route on what `main` requires, never on whether a push is refused.**
A refusal is the branch's rules *minus their bypass list, evaluated for
the account that pushes* — so for an account that can bypass, the
rejection that would have sent the run to the PR merge never comes. Its
push to a protected `main` succeeds, skips every required check, and
reports success. Succeeding is the failure mode. In a small estate the
account doing the work is routinely an admin, which makes this the
common case rather than an edge.

That account is a fourth identity beside the three step 2 probes: git
pushes through its credential helper, and
`git config --get credential.https://github.com.username` names the
account where one is pinned. It decides whether a push is refused and
says nothing about what the repo requires — the other reason a push
must not pick the route.

The evidence is one client repo's ruleset, read 2026-09-22 and relayed
rather than re-read here: `pull_request` and a required status check on
`main`, with the admin role in the bypass list at mode `always`. The
argument needs only that *some* bypass actor exists.

Read both of GitHub's systems. The branch endpoint's `protected` flag is
not documented as covering rulesets, so neither read stands in for the
other:

```bash
gh api repos/<owner>/<repo>/rules/branches/main --jq '[.[].type]'
gh api repos/<owner>/<repo>/branches/main --jq .protected
```

The first returns every **active** rule on `main` from rulesets at any
level, repository or organization, and omits rulesets set to *evaluate*
or *disabled*; a `pull_request` in it means `main` requires one. The
second is classic branch protection, which can require a pull request
too: where it reads `true`, `branches/main/protection` carries
`required_pull_request_reviews`, and a token that cannot read that
endpoint should treat `main` as requiring one — the PR merge is correct
either way, at the cost of a disclosed merge commit. On agent-config
both read `[]` and `false` (2026-09-23): consistent, and discriminating
nothing.

A ruleset's `current_user_can_bypass` — `always`, `pull_requests_only`,
`never` or `exempt` — explains why a push got through, but it is
evaluated for gh's token, not for the credential git pushes with. It is
a diagnosis, never a route.

**`required_linear_history` beside a pull-request rule is a stop.**
GitHub documents that pull requests into such a branch "must use a
squash merge or a rebase merge", so `--merge` is unavailable and every
route that respects the gate writes new SHAs — a rebase merge keeps the
split under them, a squash collapses it. Name which, as for a requested
[squash](#squash--the-full-round), then wait. Documented, not exercised.

## The no-checkout route

**`git switch` is not required to move `main`.** Two writes leave HEAD
where it is, and step 7's table picks between them on what `main`
requires. Where it requires no pull request and **another session holds
the tree** (step 1), the write is the branch pushed *to* `main` — the
default's fast-forward minus the checkout. Where it **requires a pull
request**, the write is the PR's own merge, server-side, whoever holds
the tree. Only the first line differs:

```bash
git push origin <branch>:main   # the write — ff-enforced by default
# main requires a PR? line 1 is instead: gh pr merge <n> -R <owner>/<repo> --merge
git fetch origin --quiet
git fetch origin main:main      # moves the local main REF; HEAD untouched
git merge-base --is-ancestor <branch> main
```

**Read the requirement first; never push to find out.** Until
2026-09-23 this said the reverse — push first, fall through to the PR
merge on a rejection — because the server-side `--merge` adds a merge
commit that a shared tree alone does not need. That cost is real and is
still disclosed, in [one clause](#merge-commit--one-clause-and-proceed).
But push-first sent an account that can bypass straight past the gate,
with no rejection to fall through on. **Pass `-R <owner>/<repo>` on the
PR merge**: it clears gh's `CanDeleteLocalBranch`, which gates every
local-git path, so the merge cannot switch the tree; step 9 owns the
delete. Read in gh v2.101.0.

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

## Overriding the default — never silently

A squash and a merge commit are **defaults, not laws.** The history is
the user's to shape. But the two do not cost the same, so they do not
get the same gate: one calibrated for the expensive mechanism turns the
cheap one into ceremony, and guidance that is annoying to follow
correctly gets followed loosely.

### Squash — the full round

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

### Merge commit — one clause and proceed

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
