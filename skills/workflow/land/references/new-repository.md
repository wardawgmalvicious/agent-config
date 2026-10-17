# A repository with no `origin` yet

What changes when the branch lives in a repository GitHub has never
seen: no `origin` at all, and the user asking to publish it. Step 1's
`git fetch origin` is the first command to fail; read this before step
2. An `origin` that is not GitHub, a `file://` path or another host, is
not this case: it stays step 5's stop.

The route ran once end to end, in a new organization repository under a
client root (Claude Code 2.1.301, gh 2.101.0, git 2.55.0.windows.3,
2026-10-16): repo created, base and branch pushed, PR opened, CI green,
the fast-forward checked with `git merge-base --is-ancestor`, the branch
deleted on both sides. Nothing here has been re-run since.

## Telling it apart

```bash
git remote -v      # prints nothing
git fetch origin   # fatal: 'origin' does not appear to be a git repository; exit 128
```

Step 1's other reads of `origin/main` fail too, and `git rev-parse
origin/main` prints its argument to stdout before exiting 128, so a
captured `<base>` reads `origin/main` instead of coming back empty (git
2.55.0.windows.3, 2026-10-17). Hold step 1's `origin` reads until the
base is pushed (§ "Push the base, then resume").

With no ask to publish, there is nothing to land: say so, and name this
route.

## One ask: owner, visibility, and what follows

Creating a repository is the one outward action of land's that its steps
do not already gate, so it is asked for here, before anything exists.
**Owner and visibility are the user's to name.** Ask both in one
`AskUserQuestion` that discloses what the answer licenses: creating
`<owner>/<repo>`, adding it as `origin`, and pushing local `main` to it
as the base. Then do it; step 6 still gates the branch's write to
`main`.

- **The owner can be inferred, never assumed.** The 2026-10-16 run read
  sibling repos under the same identity root,
  `git -C <sibling> remote get-url origin`, and stated the inference in
  the ask.
- **`private` is the reversible default.** `internal` needs GitHub
  Enterprise, and is untested here.

**The base push is the one write to `main` before step 6.** It puts on
the remote only what local `main` already holds; the branch's own
commits reach `main` through step 7 alone, so opening the PR and writing
`main` stay two decisions.

## Identity, against the intended owner

Step 2 runs as written, the token pin and `gh api user -q .login`
included, except `git remote -v`, which has no owner to show. The owner
the user named takes its place:

```bash
gh api user/memberships/orgs/<org> -q '.role + " " + .state'
gh api orgs/<org> -q '[.plan.name, (.members_can_create_private_repositories|tostring), (.members_can_create_internal_repositories|tostring)] | join(" ")'
```

- **The membership read answers 404** where the login is "not
  affiliated with the organization": the wrong identity, or the wrong
  owner. `state` is `active` or `pending`, and `pending` is an
  invitation not yet taken; `role` is `admin`, `member` or
  `billing_manager` (docs.github.com, read 2026-10-17).
- **The organization read gives "the full details" only to an owner**,
  and the same page says nothing of what anyone else gets, so a `null`
  there is no answer rather than a `false`. The two
  `members_can_create_*` fields are the settings a non-owner's create
  depends on.
- **An owner that is the login itself** is a personal repository: the
  login and the owner compare directly, and neither read applies.
  Untested.

## Confirm the repository is absent

```bash
gh repo view <owner>/<repo>
```

An absent repository answers `Could not resolve to a Repository`, which
`~/.claude/CLAUDE.md` reads as the wrong identity first. It means absent
only once the identity reads above have passed: run it after them, never
in place of them.

## No credential prompt on the push

```bash
git credential-manager github list
git config --get credential.https://github.com.username
```

On 2026-10-16 the first listed both accounts, and the identity root's
`includeIf` file set the second to the work login, so the HTTPS push
took that account unprompted. A prompt blocks a tool call to its
timeout, so settle this before pushing.

## Create bare, then add the remote

```bash
gh repo create <owner>/<repo> --private --description "<one line>"
git remote add origin https://github.com/<owner>/<repo>.git
```

No `--source` and no `--push`: creating stays with `gh`, as the login
step 2 confirmed, from the shell that was probed, and pushing stays with
git, under the folder's identity, where step 3 keeps its usual control.

## Push the base, then resume

```bash
git push -u origin main
```

Then run step 1's `origin` reads, now that `origin/main` exists,
`<base>` and the merge count among them, and land resumes at step 3,
which pushes the branch. The base goes first because a PR needs its base
on the remote: reasoned, not tested, since base-first never met the
failure.

## A new repository starts unprotected

The 2026-10-16 run read rulesets `[]`, `.protected` `false` and
`delete_branch_on_merge` `false`. So step 7 took its first row, the
default fast-forward, and step 9 deleted the remote branch itself; the
PR's run was the repo's first CI run. Read all three as step 7 says
rather than carry these over: an organization's ruleset can target every
repository, a new one included.

## Not checked

- A PR opened before its base is pushed.
- The `internal` visibility, and a personal owner.
