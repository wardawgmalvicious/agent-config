---
name: recreate-repo
# model: inherit  # any model: value blocks Copilot slash invocation
effort: max
disable-model-invocation: false
argument-hint: "[owner/name]"
description: "Routes a leak already pushed to GitHub — a client or employer name, an account or tenant name, a credential, in a file, a message or a pull request — to the immediate remedy: deleting and recreating the repository, in the order that keeps its settings alive. Snapshot them with repo-settings.ps1, run by full path from any repo; rotate a credential first; clean the history locally; delete with gh (github-mcp's delete_repository cannot confirm); create; apply the snapshot; arm the hooks in the fresh clone and fetch --prune so the first push is scanned; push; upload the social preview by hand. Says why a rewrite plus force-push is not the remedy — pull request refs and cached views keep the commits reachable — what the recreate cannot reach, the forks of a public repo, and why the 90-day restore is never used. Stops on a repo the acting account does not own; an organization's repo is its owners' to recreate. To keep a leak out of a commit not yet pushed, use commit; to land a branch, land."
when_to_use: "Use when a client name, account, token or other identity string turns up in commits, messages or pull requests already pushed; when asked to purge, scrub or rewrite pushed history, to filter-repo and force-push, or to delete and recreate a repository — before the delete, since the settings die with the repo. Use it even when asked only to force-push the rewrite or to delete the repo and start again: the snapshot and the hooks are what those requests skip."
---

# Recreating a repository after a pushed leak

A name or a credential has reached GitHub: in a file, a commit message,
a pull request, a branch name. **A rewrite in place is not the remedy.**
`refs/pull/N/head` pin every commit a pull request touched, and GitHub
serves unreachable objects by SHA until a collection on no schedule you
control — the reasoning is
`C:/Repos/Personal/agent-config/docs/evidence/user-claude-md.md`
§ "Git identity is folder-scoped", and GitHub's own page says the same of
clones, forks and "cached views"
([references/pushed-leaks.md](references/pushed-leaks.md)). Deleting the
repository and creating it again is the immediate remedy, and the one in
the owner's hands: the pull request refs go with the repository. The
settings go with it too, which is why this is an order and not one
command; it was learned twice, on 2026-09-10 when nothing recorded the
old values, and on 2026-09-23 in a repo where nothing named the script.

Two things the recreate does not undo, and step 1 names both: a
credential's exposure, and the copies in forks and clones.

## 1. Before anything: whose repo, where you are, what survives

```bash
gh api user -q .login                                   # who gh acts as, here
gh repo view <owner>/<name> --json visibility,forkCount,isFork,parent
git rev-parse --show-toplevel                           # which repo this session is in
```

- **A credential is revoked or rotated first.** The recreate removes the
  record, not the exposure, and GitHub's page puts the rotation "as a
  first step". Its Support can purge cached views and pull request refs
  after a rewrite, but only for data it judges sensitive and only where
  rotating cannot mitigate the risk; that route was never tried here,
  and the recreate needs no one's judgment.
- **The login must equal `<owner>`.** `gh` is folder-scoped on this
  machine: the repo's account inside an identity root, the keyring's
  active one outside every root (`~/.claude/CLAUDE.md` § "Git identity
  is folder-scoped"). The script refuses `-Export` and `-Apply` under any
  other login; `gh repo delete` and `gh repo create` make no such check
  and act as whatever `gh` resolves to, so the probe is yours. A mismatch
  is a stop: report it.
- **An organization's repo is a stop.** It is its owners' to recreate,
  and its snapshot would put the organization's name in a public repo
  (same section).
- **In a client repo the script's path stays local**: in the command and
  the conversation, never in a file, a commit, a pull request or a branch
  name (same section, 2026-09-30).
- **A public repo's `forkCount` above 0 means the leak outlives it.**
  "Deleting a public repository will not delete any forks of the
  repository" — a private repo's forks go with it — and the fork owners
  have to be asked: GitHub "cannot provide contact information for these
  owners". Say so; the recreate still clears this repo.
- **`isFork` true, with a pull request into its `parent`**: that pull
  request lives in the parent, where this delete does not reach, and
  pins the commits there. Reasoned from GitHub's "any pull requests that
  reference them", not tried (2026-10-01).
- **Record `visibility`.** The snapshot leaves it out on purpose, so
  once the repo is gone nothing else says whether it was public or
  private, and step 5 needs it.
- **Add a leaked name to `~/.config/identity-denylist.txt`** if it is
  not there; a credential never goes in it. `identity-guard` knows only
  what is listed, and step 6's push is where it catches whatever the
  rewrite missed.

## 2. Snapshot the settings while they exist

```powershell
& C:/Repos/Personal/agent-config/scripts/repo-settings.ps1 -Check -Repo <owner>/<name>   # exit 0: a current snapshot is committed, skip -Export
& C:/Repos/Personal/agent-config/scripts/repo-settings.ps1 -Export -Repo <owner>/<name>
```

From Bash, run the same path through `pwsh -NoProfile -File`. The script
resolves its own location, so it runs from any directory: measured
2026-10-01 from another personal repo, `31 setting(s) already match`,
exit 0. **Not from a worktree session**: the script runs git in
agent-config's checkout and writes there, outside the worktree, and the
Bash tool's guard refused it (2.1.282, 2026-10-01). Ask to leave the
worktree first.

- **It writes into agent-config, not into the repo you are in**:
  `.github/repo-settings/<name>.json` there, or `.github/repo-settings.json`
  for agent-config's own.
- It refuses a login that is not the owner — `gh acts as '<login>', not
  the repo owner '<owner>'. Refusing to snapshot a repo it does not own.`
  — a file paired with another repo, and merge settings that come back
  null, which means `gh` is not reading them as an admin.
- **Outside agent-config the file is left uncommitted and announced.**
  Write `~/handoff-inbox/agent-config/<yyyy-mm-dd>-<topic>.md`, opening
  with Origin, For and Scrubbing as the inbox's `README.md` says, naming
  the file and whether the repo is private. agent-config is public, so a
  snapshot there publishes the repo's name, description, topics and
  security toggles, and a private repo's is committed only on the user's
  word. Inside agent-config, the snapshot goes to `/commit` with the rest.
- `-Check` prints a `[SKIP]` line when no social preview is uploaded.
  Note it: step 6 ends with that upload.

## 3. Clean the history locally

The recreate publishes whatever you push, so the history is clean before
step 4 — and the rewrite is not this skill's to perform. What it holds
you to:

- **A leak confined to pull request or issue text needs no rewrite.**
  Those die with the repository.
- **`git filter-repo` runs in a fresh clone** — it refuses any other,
  `--force` overriding — **and runs `git remote rm origin` when it
  finishes**, unless `--partial`. It leaves `.git/filter-repo/commit-map`,
  `ref-map`, `changed-refs` and `first-changed-commits`. The commit-map is
  a trap in a repo rewritten before: each commit appears twice, and six
  of seven translated SHAs once landed on a stale lineage
  (`~/.claude/hooks/identity-guard.sh`, header, 2026-09-08) — assert
  `git merge-base --is-ancestor <new> main`. `first-changed-commits` is
  what GitHub Support asks for, should a credential's case go there.
- **Prove the term gone before the delete**: every diff, merges
  included, every message, author and committer, every ref name and tag
  message. Binary files are not searched.

```bash
git log --all -p -m --format='%H %an %ae %cn %ce %B' | grep -i -c '<term>'   # 0 is the pass
git for-each-ref --format='%(refname) %(contents)' | grep -i '<term>'         # nothing back is the pass
```

## 4. Checkpoint, then delete

Report where things stand: the snapshot's path and `-Check`'s exit, the
visibility recorded, the fork count, where the clean history is and that
`filter-repo` dropped `origin`, and that steps 5 and 6 follow. **Then
wait.** The delete is the one irreversible write here — "Some deleted
repositories can be restored within 90 days of deletion", but restoring
would bring the leak back, so that restore is never this skill's — and
the user asked for the recreate, not for this moment.

```bash
gh repo delete <owner>/<name> --yes    # the slug is required: without it --yes is ignored and gh prompts
```

- **The scope.** `gh repo delete --help` says deletion needs the
  `delete_repo` scope, and gives `gh auth refresh -s delete_repo` as the
  fix. Hand that to the user and stop: it widens the keyring's *active*
  account whichever folder it runs in, and waits on a browser device
  flow (`~/.claude/CLAUDE.md` § "Git identity is folder-scoped").
- **`github-mcp`'s `delete_repository` cannot do this from Claude Code.**
  Its confirmation never reaches the user, and two calls on 2026-09-23
  answered `Repository deletion was not confirmed`
  (`~/.claude/mcp/README.md`). Granting the token Administration does
  not help, and the permission outlives the attempt.
- Whether a new repo under the same name blocks the 90-day restore, and
  whether the name is reusable at once, was not checked (2026-10-01);
  both recreates so far took the same name back.

## 5. Create, re-add the remote, apply the snapshot

```bash
gh repo create <owner>/<name> --<public|private> --description '<from the snapshot>'   # no --source --push: the hooks are not armed yet
git remote -v                                           # filter-repo removed origin; put it back:
git remote add origin https://github.com/<owner>/<name>.git
```

```powershell
& C:/Repos/Personal/agent-config/scripts/repo-settings.ps1 -Apply -Repo <owner>/<name>
```

- `gh repo create` takes `--description` and `--homepage` and no topics
  (gh 2.101.0); `-Apply` restores the topics and everything else the
  snapshot holds — merge toggles, security settings, Actions
  permissions — then re-checks.
- **`-Apply` has not yet run against a repo with no commits** (unverified,
  2026-10-01). If a setting fails there, run it again after step 6 and
  note which: the next real recreate settles this.
- Rulesets print `[SKIP]`: applying them is not implemented, and no
  personal repo has had any.

## 6. Arm the hooks, prune, push, then finish by hand

**A fresh clone has no hooks**, and a push from one passes every
git-side guard a repo wires — `identity-guard`'s git-hook mode,
`push-gate.sh` — in silence. On 2026-09-23 the missing piece was
`core.hooksPath`.

```bash
pre-commit install                          # every type in default_install_hook_types, where the repo uses pre-commit
git config core.hooksPath <dir>             # a repo that commits its hooks; then:
git ls-files -s <dir>                       # 100755 each, or a POSIX clone does not run it
git update-index --chmod=+x <dir>/<hook>    # the fix for a 100644, committed before the push
```

Then the prune, and only then the push:

```bash
git fetch --prune origin        # drops the stale origin/main the deleted repo left behind
git push -u origin main
```

`identity-guard`'s push gate scans every commit on the ref that no
remote has, `--not --remotes`, and the clone's old `origin/main` still
names the deleted repo's commits, so until the prune all of them are
left out of the scan: measured 2026-10-01, `0` commits before
`- [deleted] (none) -> origin/main`, every commit after. After a
`filter-repo` rewrite the old remote is already gone. The first push to
an empty repo is then the one scan of the whole history against the
denylist, and a name step 1 added is caught here.

After the push:

- `-Check -Repo <owner>/<name>` once more: exit 0, with the `[SKIP]` for
  the social preview, which no API sets — upload it by hand at
  **Settings → General → Social preview → Edit → Upload an image**
  (`C:/Repos/Personal/agent-config/docs/social/README.md`). `-Check`
  never counts it as drift.
- Report: the snapshot's path and whether it is committed, the inbox
  note if one was written, the forks still carrying the leak, and that
  the deleted repo is not to be restored.

## Constraints

- **Never restore the deleted repository.** It brings the leak back.
- **Never `gh auth refresh` or `gh auth switch`.** Both act on the
  keyring's active account, which every session on the machine shares;
  hand them to the user.
- **Never act as an account that does not own the repo, and never on an
  organization's repo**: stop and report. The script refuses the first
  for its own writes; `gh repo delete` and `gh repo create` do not.
- **Never `gh repo create --source . --push`, and never a force-push as
  the remedy.** The first publishes before the hooks exist; the second is
  the rewrite in place this skill replaces.
- **The script's path, and agent-config's name, stay out of a client
  repo's files, commits, pull requests and branch names.**
- **A private repo's snapshot is committed in agent-config only on the
  user's word.**
- **Not this skill's:** a leak not yet pushed, which a local rewrite
  removes before any push, `commit`'s identity scan being the
  prevention; a branch to land or prune (`land`, `prune-branches`); the
  rewrite's own options, which `git filter-repo`'s manual has.
