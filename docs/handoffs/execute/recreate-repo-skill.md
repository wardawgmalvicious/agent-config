---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-01
---

# Handoff: a skill that routes a pushed leak to the recreate runbook

- **Written**: 2026-10-01, landing `repo-settings-cross-repo.md`, whose
  item 6 asked for a pointer a session in another repo can find. The
  user chose a skill that day, over a line in `claude/CLAUDE.md` and over
  no pointer.
- **Kind**: one deployable skill, by `/author-skill` then `/test-skill`.
  Nothing is drafted.

## Why a skill

The runbook is `scripts/README.md` § "Recreating a repo": snapshot the
settings with `scripts/repo-settings.ps1 -Export -Repo <owner>/<name>`,
delete with `gh`, recreate, `-Apply`, arm hooks before the first push,
push, upload the social preview by hand. A session in another repo reads
none of this repo's files, and on 2026-09-23 one recreated a personal
repo without the script for exactly that reason: nothing there named it.

Only two things reach that session: `claude/CLAUDE.md` and the skill
listing. `claude/CLAUDE.md` stood at 199 of its 200 lines on 2026-10-01,
and on 2026-09-23 the user said they would rather it carry no repo paths
(this repo's session memory, `global-claude-md-no-repo-refs`). A skill's
description routes from any repo and adds nothing to that file.

## What the skill has to carry

- **When it fires**: a leak found in pushed history (a client's name, a
  credential), a request to purge history or rewrite a pushed commit, or
  one to delete and recreate a repo. The point is to fire before the
  delete, since the settings die with the repo.
- **That a rewrite in place is not the remedy**. The reasoning is
  `docs/evidence/user-claude-md.md` § "Git identity is folder-scoped";
  cite it, do not restate it.
- **The order**, from the runbook, with the script run by its full path
  from any repo. It writes into this repo's `.github/repo-settings/`, so
  a session elsewhere leaves the file uncommitted and says so in
  `~/handoff-inbox/agent-config/`.
- **Where it stops**: the script refuses a repo the acting account does
  not own, and a repo an organization owns is that organization's to
  recreate. A private repo's snapshot is committed here only on the
  user's word, this repo being public.

**One home for the runbook.** Either the skill takes the runbook and
`scripts/README.md` keeps a one-line pointer to it, or the skill points
at `scripts/README.md` by full path. The first puts it where every
session can read it; decide at `/author-skill` time, not both.

## Placement

- **Overlap first**: `land` pushes and reads merge settings, and its
  `references/integration-routes.md` already names the snapshot; `commit`
  carries the identity scan, which stops at prevention. `66ddcdc`
  declined `land` as the home for the delete step, since `land` never
  deletes a repository. Run `author-skill` §2's `skill-overlap.py`.
- **Group**: the skill names a personal repo's path, and
  `claude/CLAUDE.md` keeps that out of every repo under a client root,
  so it must never be copied into a client repo's `.github`. `workflow`
  is deployed everywhere and copied to `~/.copilot`; `meta`'s
  `.no-copilot` marker keeps a skill from Copilot altogether. Weigh the
  two against `copilot-payload-retirement.md`, which may settle it.

## Verification

- Carried from `repo-settings-cross-repo.md`: a fresh session in another
  repo, asked what to do about a name already pushed, names the runbook
  and puts the snapshot before the delete. That is `/test-skill`'s
  behaviour phase, against a `--safe-mode` baseline.
- `-Apply` has not yet run against a repo with no commits, the runbook's
  step 3. Note what the next real recreate shows.
