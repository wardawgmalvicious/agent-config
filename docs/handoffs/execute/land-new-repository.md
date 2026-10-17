---
status: open
priority: 3
needs: []
blocked-by: []
written: 2026-10-17
---

# Handoff: land has no route for a repo with no GitHub remote yet

- **Written**: 2026-10-17, from one inbox note of 2026-10-16 by a
  session that built a new org-internal repo under a client root and
  landed its first branch (Claude Code 2.1.301, gh 2.101.0, git
  2.55.0.windows.3). Re-measured against the payload at `7d0757e`, which
  covers none of it.
- **Kind**: an edit, a new reference and a pointer to it. Nothing is
  drafted beyond the steps below.

## The gap

`land` assumes an `origin`. Step 1 opens with `git fetch origin`, which
fails with no remote; step 2's `git remote -v` prints nothing, leaving
no owner to compare the login against; and step 5's "No GitHub remote,
or no confirmed identity? Stop." was written for an `origin` that is not
GitHub, not for none at all. Two cases, then: an `origin` that is not
GitHub stays a stop, while no `origin`, with the user asking to publish,
is a creation step through the confirmed identity, gated on the user
naming the owner and the visibility. It is the one outward action land
would take that it does not already gate, so it is disclosed as step 6
discloses, then done. The user, 2026-10-16: rare enough for a reference
rather than the body.

Re-measured 2026-10-17: a grep of `skills/workflow/land/` for
`repo create`, `no remote` and `new repo` finds nothing, and its
`references/` hold `branch-deletion.md`, `integration-routes.md`,
`linked-worktree.md` and `never-prompted-sessions.md`.

## The route, as it ran once

Reproduced once end to end by the note's session, 2026-10-16: repo
created, base and branch pushed, PR opened, CI green, fast-forward merge
checked with `git merge-base --is-ancestor`, branch deleted on both
sides.

1. **Owner and visibility are the user's.** Name both before creating
   anything. The owner was inferred from sibling repos under the same
   client root (`git -C <sibling> remote get-url origin`) and stated in
   the go-ahead. `private` is the reversible default: `internal` needs
   GitHub Enterprise.
2. **Identity first, against the intended owner.** The usual token pin
   and `gh api user -q .login`, then the membership answer in place of
   step 2's `git remote -v` comparison:

   ```bash
   gh api user/memberships/orgs/<org> -q '.role + " " + .state'
   gh api orgs/<org> -q '[.plan.name, (.members_can_create_private_repositories|tostring), (.members_can_create_internal_repositories|tostring)] | join(" ")'
   ```

3. **Confirm the repo is absent, after the identity passes.**
   `gh repo view <org>/<repo>` answers `Could not resolve to a
   Repository`, which `claude/CLAUDE.md` reads as wrong identity first,
   so it means absent only once step 2 has passed.
4. **Check that the push meets no credential prompt.**
   `git credential-manager github list` listed both accounts, and the
   client root's `includeIf` file set
   `credential.https://github.com.username`, so the HTTPS push took the
   work account unprompted.
5. **Create the repo bare, then add the remote.**
   `gh repo create <org>/<repo> --private --description "…"`, with no
   `--source` or `--push`, so pushing stays with git under the folder's
   identity and step 3 keeps its usual control; then
   `git remote add origin https://github.com/<org>/<repo>.git`.
6. **Push the base before the branch**, `git push -u origin main`, then
   the branch, and land resumes at step 4. That a PR needs its base on
   the remote is reasoned, not tested: base-first never met the failure.
7. **A new repo starts unprotected.** Rulesets `[]`, `.protected`
   `false`, `delete_branch_on_merge` `false`, so step 7 took its default
   fast-forward route, and the PR's run was the repo's first CI run.

## Where it lands

A new `skills/workflow/land/references/new-repository.md` holding the
route, and one line in `skills/workflow/land/SKILL.md` that separates no
`origin` from an `origin` that is not GitHub: at step 1's preflight,
where `git fetch origin` fails first, or at step 5's stop. A body edit,
so `land` needs a behaviour retest after (`skill-status.py --stale`
already lists it).

## Not checked

- Nothing was re-run here: it needs a GitHub organization and a new
  repository.
- A PR opened before its base is pushed.
- The `internal` visibility route.

## Scrubbing

The note genericized the organization, repo, client root and work login
as `<org>`, `<repo>`, `<client root>` and `<work-login>`; they stay so.

## Re-measure before acting

```bash
grep -rn -i "repo create\|no remote\|new-repository" skills/workflow/land/   # 2026-10-17: nothing
grep -n "git fetch origin\|No GitHub remote" skills/workflow/land/SKILL.md
```
