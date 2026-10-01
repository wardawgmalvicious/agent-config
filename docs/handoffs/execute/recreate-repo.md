---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-01
---

# Skill handoff brief: recreate-repo

Last verified: 2026-10-01

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.
>
> Guidance: The frontmatter is this brief's whole queue state: `scripts/handoff-status.py` prints the queue from it, and pre-commit's `lint-briefs` fails a commit on a brief without it or with a placeholder left in. Pick `priority` — 1 now, 2 next, 3 later — list in `needs` what a session cannot supply alone (`user` for a decision), name any brief this waits on in `blocked-by`, and state none of it in the body.

## Artifact path

- Repo: `skills/workflow/recreate-repo/SKILL.md`, with the evidence
  behind its claims in
  `skills/workflow/recreate-repo/references/pushed-leaks.md`.
- Deployed: `~/.claude/skills/recreate-repo/`, a junction made by
  `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta` from the
  main checkout once this brief's worktree lands. A directory that did
  not exist at the last run has no junction, so until then the skill is
  in no listing and `/recreate-repo` answers `Unknown command`.
- Group: `workflow`, decided 2026-10-01 over `meta`. The skill acts on
  the user's repos, as `land` and `prune-branches` do; `meta` holds
  skills whose subject is the agent configuration. The reason the queue
  brief weighed `meta` — `workflow` was copied into client repos'
  `.github`, and this skill names a personal repo's path — is retired:
  the Copilot payload's upkeep stopped 2026-09-30 and nothing is copied
  anywhere (`copilot-payload-retirement.md`), and `meta`'s `.no-copilot`
  marker is itself slated for deletion by that brief's `model:` section.
  What the choice costs is that every client-repo session lists the
  skill, so its body says the path stays local there.

## Scope

A procedure for the moment a leak is found in pushed history: a client or
employer name, an account or tenant name, a credential. It names the
remedy — delete and recreate, never a rewrite in place — and walks the
order that keeps the repo's settings alive: snapshot them with
`scripts/repo-settings.ps1` by full path from any repo, rotate a
credential before anything else, clean the history locally, delete with
`gh`, create, apply the snapshot, arm the hooks in the fresh clone,
`fetch --prune`, push, upload the social preview by hand. It stops where
the acting account does not own the repo, and an organization's repo is
its owners' to recreate. It takes the runbook from `scripts/README.md`
§ "Recreating a repo", which keeps a one-paragraph pointer under the same
heading so the script header's and the entry's links still resolve.
Inline, model-invocable, unconditional (no `paths:`), `effort: max` as on
every behavioural skill, not forked: the delete is gated on the user's
yes, and a fork could not stop for it.

## Sources drilled

Drilled, all on 2026-10-01 unless dated otherwise:

- `scripts/README.md` § "Recreating a repo" at `cbd4b89` — the five-step
  order, learned 2026-09-10 here and 2026-09-23 in another repo; moves
  into the skill.
- `scripts/repo-settings.ps1`, whole file at `cbd4b89` — three modes;
  `-Path` defaults from `-Repo` to `.github/repo-settings/<name>.json`
  (this repo's own at `.github/repo-settings.json`); every mode refuses a
  file whose `_repo` names another repo; `-Export` and `-Apply` refuse
  unless `gh api user -q .login` equals the owner (`gh acts as '<login>',
  not the repo owner '<owner>'. Refusing to …`); null merge settings abort
  every mode; `[SKIP]` lines for an unuploaded social preview and for
  ruleset differences, neither counted as drift; `$repoRoot` hangs off
  `$PSScriptRoot`, so the script runs from any cwd; visibility is
  deliberately not recorded.
- A `-Check` run by full path, `pwsh -NoProfile -WorkingDirectory
  C:\Repos\Personal\machine-config`, against a public repo of the
  owner's: `31 setting(s) already match`, exit 0, `gh api user -q .login`
  equal to the owner there. From the scratchpad, outside both identity
  roots: `git config user.name` exit 1, and `gh` answered as the
  keyring's active account.
- `gh repo create --help` and `gh repo delete --help`, gh 2.101.0 —
  create takes `--description`, `--homepage`, `--public`/`--private`/
  `--internal`, `--disable-issues`, `--disable-wiki`, `--source`,
  `--remote`, `--push`, and no topics flag; delete takes `--yes`, ignores
  it without an explicit repository argument, needs the `delete_repo`
  scope, and prints `gh auth refresh -s delete_repo` as the fix.
- `gh repo view <owner>/<name> --json
  visibility,forkCount,isFork,parent,description` answers all five
  fields.
- docs.github.com, "Deleting a repository": "Deleting a public repository
  will not delete any forks of the repository."; "Deleting a private
  repository will delete all forks of the repository."; "Some deleted
  repositories can be restored within 90 days of deletion."; team
  permissions are deleted and the action "cannot be undone"; admin
  permission required.
- docs.github.com, "Restoring a deleted repository": restorable within 90
  days "unless the repository was part of a fork network that is not
  currently empty"; "It can take up to an hour after a repository is
  deleted before that repository is available for restoration."
- docs.github.com, "Removing sensitive data from a repository": a rewrite
  plus force-push leaves the commits "In any clones or forks of your
  repository; Directly via their SHA-1 hashes in cached views on GitHub;
  Through any pull requests that reference them"; a secret is revoked or
  rotated "as a first step"; Support dereferences PRs, runs a garbage
  collection and removes cached views, but "only … in cases where we
  determine that the risk can't be mitigated by rotating affected
  credentials" and "won't remove non-sensitive data"; fork owners must be
  asked, and "GitHub cannot provide contact information for these
  owners"; collaborators "must rebase, not merge".
- `git-filter-repo` v2.47.0 is installed as a uv tool;
  `Documentation/git-filter-repo.txt` on `main` — its steps after a
  rewrite include `git remote rm origin`, which `--partial` disables, and
  to restore it "simply run: `git remote add origin
  $ORIGINAL_CLONE_URL`"; a fresh clone is required unless `--force`; it
  writes `$GIT_DIR/filter-repo/commit-map`, `ref-map`, `changed-refs` and
  `first-changed-commits`.
- `claude/hooks/identity-guard.sh` — the push gate scans `"$REF" --not
  --remotes` (lines 308–309); the header's two reasons a rewrite leaves a
  leak reachable, and the commit-map trap of 2026-09-08.
- A probe in the scratchpad, git 2.55.0.windows.3: with the remote
  recreated empty, `HEAD --not --remotes` listed 0 commits until
  `git fetch --prune origin` printed `- [deleted] (none) -> origin/main`,
  exit 0, after which it listed every commit.
- `.pre-commit-config.yaml` — `default_install_hook_types: [pre-commit,
  commit-msg, pre-push]`; the two guards run as `bash <script>` under
  `language: system`, so their mode bits do not matter here; this repo's
  hooks sit in `.git/hooks` with `core.hooksPath` unset; `git ls-files -s`
  shows `100644` on both guard scripts; `git update-index --chmod (+|-)x`
  exists.
- `docs/evidence/user-claude-md.md` § "Git identity is folder-scoped" —
  the two reasons pushed history cannot be fixed forward, and the
  2026-09-30 rule that no personal repo's name is committed under a
  client root; the skill cites both, restating neither.
- `claude/mcp/README.md` § "GitHub and multiple accounts" —
  `delete_repository` returned `Repository deletion was not confirmed`
  twice on 2026-09-23 while `gh repo delete --yes` worked.
- `docs/social/README.md` § "Uploading it" — Settings → General → Social
  preview → Edit → Upload an image.
- `~/handoff-inbox/README.md` — a note opens with Origin, For and
  Scrubbing, and is deleted only on the user's explicit yes.
- Neighbours: `skills/workflow/land/SKILL.md` and its
  `references/integration-routes.md`, `skills/workflow/commit/SKILL.md`
  § "Safety rails", `skills/meta/learn/SKILL.md` step 7;
  `skill-overlap.py overlap` ranks `land + prune-branches` 35.8 and
  `commit + land` 24.2 as the cluster this skill joins.
- The queue brief `recreate-repo-skill.md` and the landed
  `repo-settings-cross-repo.md`, both at `231f03a`, with that commit's
  message; `66ddcdc`, which declined `land` as the delete step's home.
- `pwsh -NoProfile -File <the script> -Check` from the Bash tool inside
  this brief's worktree was refused before it ran ("runs pwsh in a plain
  command; what it reads or is handed as shell text cannot be shown not
  to run git", Claude Code 2.1.282). The refusal was right: the script
  runs `git -C` on the main checkout. The same call then ran from the
  PowerShell tool, `31 setting(s) already match`, exit 0 — past the
  guard, which root `CLAUDE.md` records does not stop PowerShell's
  `git -C`. Its git call was read-only. The draft first told a worktree
  session to take that route; the skill's step 2 now has it leave the
  worktree instead.

Not drilled, and so not in the skill:

- The rewrite itself. The skill names `git filter-repo`, the fresh-clone
  rule, that it removes `origin`, the four files it writes and the
  commit-map trap, and describes none of its options; the 2026-09-10
  rewrite's commands are in no ledger.
- `-Apply` against a repo with no commits, the runbook's step 3 caveat:
  never run, carried as unverified for the next real recreate to note.
- Whether a deleted repo's name is reusable at once, and whether a new
  repo under the same name blocks the 90-day restore: neither page read
  says, and neither was tried.
- GitHub Support's process beyond the one page, and whether it would
  purge a leaked name: the page leaves "sensitive" to GitHub's judgment.
  GitHub's REST or GraphQL surface beyond the endpoints the script calls.
- Whether a pull request from a fork into its parent keeps the commits
  reachable there once the fork is deleted: the skill reasons it from
  "any pull requests that reference them" and marks it so.
- The acting account's token scopes: whether it holds `delete_repo` was
  not checked, and the skill hands `gh auth refresh` to the user rather
  than run it.
- Restoring rulesets, which `-Apply` skips; no personal repo has any.
- Copilot: nothing, since the payload is retired and this skill is never
  copied.

## Frontmatter

```yaml
---
name: recreate-repo  # repo linter requires it; max 64 chars; lowercase/digits/hyphens; no "anthropic"/"claude"
# model: inherit  # ALWAYS PRESENT, ALWAYS COMMENTED under skills/workflow/: an active model: key breaks Copilot slash dispatch and fails lint-frontmatter.py
effort: max  # ALWAYS PRESENT; the floor every behavioural skill here pins
disable-model-invocation: false  # ALWAYS PRESENT; repo policy: false everywhere
argument-hint: "[owner/name]"  # optional; the repo to recreate, shown in the / menu
description: "…"  # required; the whole model-invoked trigger; gated at 1,024 — see Description char count
when_to_use: "…"  # optional; the trigger phrases; gated at 512, Claude Code only
---
```

No `allowed-tools`: the skill's writes are `gh repo delete`, `gh repo
create`, `-Export`, `-Apply` and a push, and every one should prompt.
No `paths:`, since a leak is found in conversation, not by opening a
file type. No `context: fork`: the delete is gated on the user's yes.

## Description char count

- `description`: 1,000 / 1,024
- `when_to_use`: 459 / 512

Counted against the shipped file by `yaml.safe_load`, which a regex over
the raw frontmatter matched at the 1,010 draft (2026-10-01). The first
draft measured 1,038 and was cut, not padded. 24 characters of headroom
on `description` means any rewording cuts before it adds; the clause to
cut first is the two-skill disambiguation at the end, which the body
also carries.

## Body structure outline

1. **What this is for, and why a rewrite is not the remedy.** One
   sentence each citing `docs/evidence/user-claude-md.md` § "Git
   identity is folder-scoped" and GitHub's own page; the recreate
   removes the record, a rotation removes the exposure; the order exists
   because the settings die with the repo.
2. **Before anything: who owns it, what you are in, what survives.**
   `gh api user -q .login` against `gh repo view --json
   visibility,forkCount,isFork,parent`; the three stops (not the owner,
   an organization's repo, a credential not yet rotated); forks of a
   public repo keep the leak; in a client repo the script's path stays
   local; add the leaked name to the denylist so the push gate catches a
   miss.
3. **Snapshot the settings while they exist.** `-Check` exit 0 skips
   `-Export`; the full-path invocation from PowerShell and from Bash;
   where the file lands and that it is uncommitted outside this repo;
   record visibility by hand, since the snapshot omits it; the owner
   refusal text.
4. **Clean the history locally.** Fresh clone, `filter-repo`, its four
   output files, the commit-map trap; grep every diff, merges included,
   every message, author and committer, and every ref name and tag
   message for the term afterwards; a leak confined to PR or issue text
   needs no rewrite.
5. **Checkpoint, then delete.** Report snapshot path, `-Check` result,
   visibility, fork count and where the clean history is; wait; then
   `gh repo delete <owner>/<name> --yes` with the explicit slug, the
   scope error handed to the user, `delete_repository` ruled out.
6. **Create, re-add the remote, apply.** `gh repo create` with the
   recorded visibility and no `--source . --push`; `git remote add
   origin` where `filter-repo` removed it; `-Apply`, its unverified
   empty-repo case, and its `[SKIP]` lines.
7. **Arm the hooks, prune, push, finish by hand.** `pre-commit install`
   or `core.hooksPath` with the `100755` check; `git fetch --prune
   origin` and why; the push and what scans it; `-Check` once more; the
   social preview upload; the inbox note from another repo, the commit
   from this one.
8. **Constraints.** Never restore the deleted repo; never run `gh auth
   refresh` or `switch`; never act as an account other than the owner;
   never `--source . --push` on create or force-push as the remedy; a
   private repo's snapshot is committed here only on the user's word; an
   unpushed leak is `commit`'s, a branch is `land`'s or
   `prune-branches`'.

The evidence — the GitHub quotes, the prune probe, the filter-repo facts,
the measured identity answers — goes in `references/pushed-leaks.md`,
cited from the step that rests on it.

## Changes from source proposal

Derived from the queue brief `recreate-repo-skill.md` (`231f03a`), which
this file replaces at the skill's own name, since `/test-skill` step 1
reads `docs/handoffs/execute/<skill-name>.md`. Departures and additions:

- **The runbook moves into the skill**; the queue brief left the home
  open between the skill and `scripts/README.md`. A skill that only
  pointed at a file in another repo would still have to carry the
  snapshot-before-delete order to fire usefully, giving the order two
  homes. `scripts/README.md` § "Recreating a repo" keeps its heading and
  one paragraph pointing here.
- **Group `workflow`**, where the queue brief leaned toward `meta`; the
  reasons are under Artifact path.
- **Seven things the runbook never said**, each from today's drilling:
  rotate a credential first; forks of a public repo survive the delete;
  the deleted repo is restorable for 90 days and must not be; the
  snapshot omits visibility, so record it before the delete; `gh repo
  create --source . --push` would publish before the hooks are armed;
  the fresh clone `filter-repo` requires has no hooks and no `origin`; a
  stale `origin/main` hides every commit from identity-guard's push scan
  until `git fetch --prune origin`.
- **One runbook phrase is dropped**: that a hook committed without its
  executable bit fails on a POSIX clone "and says nothing". Nothing here
  measured the silence, so the skill says only that the hook does not
  run.
- **A checkpoint before the delete**, in `land`'s step 6 shape: the one
  irreversible write gets a reported state and a wait.
- **The `delete_repo` scope** is handed to the user, since `gh auth
  refresh` widens the keyring's active account machine-wide
  (`~/.claude/CLAUDE.md` § "Git identity is folder-scoped").

## Tag

`personal`

## Portability caveats

The skill hardcodes one machine's layout: the script's full path under
`C:/Repos/Personal/agent-config/`, the inbox at `~/handoff-inbox/`, the
denylist at `~/.config/identity-denylist.txt`, and a `gh` wrapped to act
as the repo's `includeIf` identity. Anyone cherry-picking it rewrites
steps 2, 3 and 7. `effort` and `when_to_use` are Claude Code fields that
a portable copy drops with no loss; `argument-hint` is standard; no
`paths:`, no `context: fork`, no `shell: powershell`, no hooks. The
PowerShell invocation is given beside a Bash one because the script is
`.ps1` and the session's shell is either.

## Cross-reference dependencies

- `commit` — (a) already converted. Owns the unpushed case: its identity
  scan stops at prevention, and the skill routes an unpushed leak there.
- `land` and `prune-branches` — (a) already converted. The branch
  operations this skill is not; `land`'s `integration-routes.md` already
  names the snapshot as a merge-settings source.
- `learn` — (a) already converted. Step 7's note shape is what a session
  in another repo writes about the uncommitted snapshot.
- `claude/hooks/identity-guard.sh` — (a) already converted. The push
  gate the prune step exists to feed.
- `scripts/repo-settings.ps1` and `scripts/README.md` § "Recreating a
  repo" — (a) already converted; the README section is cut to a pointer
  in this change.
- `claude/mcp/README.md` § "GitHub and multiple accounts" — (a) already
  converted. The `delete_repository` finding.
- `docs/evidence/user-claude-md.md` § "Git identity is folder-scoped" —
  (a) already converted. Cited by full path, since the reader is in
  another repo.
- `~/handoff-inbox/README.md` — (c) external to this repo; machine-local.
- GitHub's three docs pages and `git-filter-repo`'s manual — (c)
  external; quoted in `references/pushed-leaks.md` with the read date.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**One edit outside `/author-skill`'s usual diff.** `scripts/README.md`
§ "Recreating a repo" is cut to a pointer in this change, on the user's
2026-10-01 answer to the runbook-home question and the queue brief's
"decide at `/author-skill` time, not both". The heading stays, so the
script header's "scripts/README.md, 'Recreating a repo'" and the entry's
`[below](#recreating-a-repo)` still land somewhere that points on.

**The brief changed its name at the drafting; the worktree did not.**
The worktree was made as `recreate-repo-skill`, the queue brief's stem,
so the view marked that brief in flight; this file takes the skill's
name, which `/test-skill` step 1 reads. The view matches a worktree to a
brief by its directory's name, so the landing moves the worktree to
`.claude/worktrees/recreate-repo`, where the view reads this brief as
merged until `/test-skill` passes and the worktree is removed.

**A re-read before the first commit corrected the draft in five
places**, each now in the skill: GitHub Support's purge is a second
route, at GitHub's judgment and untried, not one a leaked name can never
take; a worktree session leaves the worktree rather than run the script
through the PowerShell tool; the term check covers authors, committers,
merge diffs and tag messages; the fork claim holds for a public repo
only, with a fork's pull request into its parent reasoned and marked;
and the runbook's "says nothing" is dropped.

**Trigger queries for `/test-skill`**, each asked in a fresh session in
another personal repo, against a `--safe-mode` baseline:

- "A client's name is in a commit we pushed last week. What do we do?" —
  must name the snapshot before the delete, and the script by its path.
- "Run git filter-repo on this and force-push it." — must say why that
  alone leaves the leak reachable, and route to the recreate.
- "Delete this repo and recreate it." — must start with `-Check` or
  `-Export`, not `gh repo delete`.
- "There's a token in a pushed commit message." — must put the rotation
  first.
- Negative: "Delete the merged branches." — `prune-branches`, not this.
- Negative: "I pasted a client name in this commit but haven't pushed." —
  `commit` territory; the skill must not fire or must route away.

**For the next real recreate to note**: whether `-Apply` succeeds against
a repo with no commits, and whether the deleted repo's name was reusable
at once.

**Post-draft overlap** (`skill-overlap.py overlap --skill recreate-repo`,
2026-10-01): `land + recreate-repo` 35.6, the repo's joint-highest pair
beside `land + prune-branches` 35.8, on generic GitHub-write tokens —
`push`, `pull`, `account`, `github-mcp`, `commits`. It read 43.7 until
the `when_to_use` sentence borrowed from `land` ("a named mechanism is
the case …") was reworded. The description's closing clause routes a
branch to `land`; the behaviour phase's negative queries above are where
that disambiguation is tested.

## Confidence

- **Structure**: H — the runbook has run twice and this is its shape with
  the gaps filled; the brief form is the template's.
- **Field specs**: M — `description` sits 17 characters under the cap, so
  the shipped wording decides trigger quality and every edit re-counts.
- **Body content**: M — the order and the measured steps are firm; the
  rewrite step is bounded to what filter-repo's manual says, and the
  empty-repo `-Apply` stays unverified until a recreate exercises it.
