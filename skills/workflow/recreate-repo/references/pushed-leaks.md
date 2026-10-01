# Pushed leaks: the evidence behind the order

What `SKILL.md` asserts, with the source and the date each was read or
measured. The skill cites this file; nothing here is restated there.

## Why a rewrite in place is not the remedy

The two reasons are in
`C:/Repos/Personal/agent-config/docs/evidence/user-claude-md.md`
§ "Git identity is folder-scoped": `refs/pull/N/head` pin every commit a
pull request ever touched, and GitHub serves unreachable objects by
explicit SHA until it garbage-collects, on no schedule you control.
GitHub's own page, "Removing sensitive data from a repository"
(docs.github.com, read 2026-10-01), says the same in its words:

> If you only rewrite your history and force push it, the commits with
> sensitive data may still be accessible elsewhere: In any clones or
> forks of your repository; Directly via their SHA-1 hashes in cached
> views on GitHub; Through any pull requests that reference them.

It names the one route besides the recreate, and bounds it:

> Support will then: Dereference or delete any affected PRs on GitHub.
> Run a garbage collection on the server to expunge the sensitive data
> from storage. Remove cached views.
>
> GitHub Support won't remove non-sensitive data, and will only assist in
> the removal of sensitive data in cases where we determine that the
> risk can't be mitigated by rotating affected credentials.

So a leaked name, which no rotation touches, has two routes: Support's
purge after a rewrite, on GitHub's judgment of what is sensitive and
never tried here, and the recreate, which the owner runs and which takes
effect at once — "the only immediate remedy", in the evidence file's
words. On the secret itself: "as a first step you need to revoke and/or
rotate that secret." On everyone else's copies: "You cannot remove
sensitive data from other users' clones of your repository", "You will
need to coordinate with the owners of the forks … GitHub cannot provide
contact information for these owners", and "Collaborators must rebase,
not merge, any branches they created off of your old (tainted)
repository history."

## What the delete removes, and what it does not

"Deleting a repository" and "Restoring a deleted repository"
(docs.github.com, read 2026-10-01):

- "Deleting a public repository will not delete any forks of the
  repository." and "Deleting a private repository will delete all forks
  of the repository."
- "Deleting a repository will permanently delete team permissions. This
  action cannot be undone."
- "Some deleted repositories can be restored within 90 days of
  deletion." — "unless the repository was part of a fork network that is
  not currently empty", and "It can take up to an hour after a repository
  is deleted before that repository is available for restoration."
  Restoring would restore the leak, so the skill never does.
- Admin permission on the repository is required to delete it.

The pull request refs that pinned the leaked commits are the
repository's, and go with it: that is the mechanism the recreate relies
on. Issues, releases and the wiki are the repository's too, and no
snapshot restores them; `scripts/repo-settings.ps1` records settings.

## Which account `gh` acts as

Measured 2026-10-01, `pwsh -NoProfile`, gh 2.101.0:

- From `C:\Repos\Personal\machine-config`, a repo under the personal
  identity root: `git config user.name` and `gh api user -q .login` both
  answered the personal account.
- From the session scratchpad, outside both identity roots:
  `git config user.name` exited 1, and `gh api user -q .login` answered
  the keyring's active account — the personal one that day, so the run
  could not tell the fall-through from the scoping.

The wrapper and its three fall-through cases are in
`~/.claude/CLAUDE.md` § "Git identity is folder-scoped". The script
checks the login itself before `-Export` and `-Apply`:

```text
gh acts as '<login>', not the repo owner '<owner>'. Refusing to snapshot a repo it does not own.
```

`gh repo delete` and `gh repo create` make no such check.

## The script, by full path

Measured 2026-10-01 from `C:\Repos\Personal\machine-config`, through the
call operator:

```text
=== Repo <owner>/<name> -- mode Check -- C:\Repos\Personal\agent-config\.github\repo-settings\<name>.json
  [ok]    31 setting(s) already match
exit=0
```

`$repoRoot` hangs off `$PSScriptRoot`, so `-Path` defaults into
agent-config whatever the working directory, and the script runs
`git -C <agent-config> remote get-url origin` before any `gh` call. From
a worktree session that is git outside the worktree, and the Bash
tool's guard refused `pwsh -NoProfile -File <the script>` before it ran
(Claude Code 2.1.282, 2026-10-01): "this command runs pwsh in a plain
command; what it reads or is handed as shell text cannot be shown not to
run git". So the skill has a worktree session leave first.

Visibility is left out of the snapshot by design — "a file edit must not
be able to publish or hide a repo" — and the social preview has a read
side and no write side, so `-Check` reports it as `[SKIP]` and never as
drift. Rulesets are exported and checked but not applied. The script
header has each reason.

## gh 2.101.0

`gh repo create --help`: `--description`, `--homepage`, `--public`,
`--private`, `--internal`, `--disable-issues`, `--disable-wiki`,
`--source`, `--remote`, `--push`, `--add-readme`, `--gitignore`,
`--license`, `--template`, `--team`. No flag sets topics.

`gh repo delete --help`: "For safety, when no repository argument is
provided, the `--yes` flag is ignored and you will be prompted for
confirmation." and "Deletion requires authorization with the
`delete_repo` scope. To authorize, run `gh auth refresh -s
delete_repo`" — the command the skill hands to the user.

`gh repo view <owner>/<name> --json visibility,forkCount,isFork,parent,description`
answered all five fields.

## git filter-repo

v2.47.0 is installed as a uv tool. Its manual
(`Documentation/git-filter-repo.txt` on `main`, read 2026-10-01):

- Its steps after the rewrite include `git remote rm origin`, then
  `git reset --hard`, `git reflog expire --expire=now --all` and
  `git gc --prune=now`; `--partial` disables the removal of `origin`.
  Why: "We don't want users accidentally pushing back to the original
  repo", and to restore it, "simply run: `git remote add origin
  $ORIGINAL_CLONE_URL`" — which the skill's step 5 does with the new
  repo's URL.
- "If we're not in a fresh clone, users will not be able to recover if
  they used the wrong command or ran in the wrong repo." — "Though
  `--force` overrides this check".
- It writes `$GIT_DIR/filter-repo/commit-map` ("how all commits were (or
  were not) changed"), `ref-map`, `changed-refs` and
  `first-changed-commits` ("the first commit(s) changed by the filtering
  operation").

The commit-map trap — two lineages in a repo rewritten before, six of
seven translated SHAs on the stale one — is in
`~/.claude/hooks/identity-guard.sh`'s header, from 2026-09-08.

## The stale remote-tracking ref

`identity-guard.sh` scans a push as `git log … "$REF" --not --remotes`
(lines 308–309 at `cbd4b89`). Probed 2026-10-01 in a scratch repo, git
2.55.0.windows.3: two commits pushed to a bare `origin`; the bare repo
deleted and re-initialised empty.

```text
before recreate:              remotes=[origin/main]  HEAD --not --remotes: 0
after recreate, before prune:                        HEAD --not --remotes: 0
git fetch --prune origin:  - [deleted]  (none) -> origin/main   exit 0
after prune:                  remotes=[]             HEAD --not --remotes: 2
```

So without the prune the first push to the recreated repo is scanned
against nothing. After a `filter-repo` rewrite, `git remote rm origin`
has already removed the remote and its tracking refs; after any other
cleanup the trap is live.

## Hooks in a fresh clone

agent-config wires its guards through pre-commit:
`default_install_hook_types: [pre-commit, commit-msg, pre-push]`, so one
`pre-commit install` arms all three stages, and
`scripts/bootstrap-pre-commit` does that on a fresh clone. Its two guard scripts run as `bash <script>`
under `language: system`, which is why their committed mode, `100644` by
`git ls-files -s`, does not matter there. It matters where git runs the
file itself, under `core.hooksPath`: a POSIX clone does not run a hook
without the executable bit, and the repo recreated on 2026-09-23 carried
such a window in its history. `git update-index --chmod=+x <file>` sets
the bit in the index on a machine whose filesystem does not.

## Unverified

- `-Apply` against a repository with no commits.
- Whether a repository's name is reusable at once after its deletion,
  and whether a new repository under that name blocks the 90-day
  restore. Both recreates so far took the same name back.
- Whether a pull request from a fork into its parent keeps the leaked
  commits reachable in the parent after the fork is deleted: reasoned
  from "Through any pull requests that reference them", not tried.
- GitHub Support's purge, for a name or a credential.
