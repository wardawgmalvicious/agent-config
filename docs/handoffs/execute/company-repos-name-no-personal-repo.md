---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-09-30
---

# Handoff: a company repo commits no personal repo's name

- **Written**: 2026-09-30, from the first learning of an inbox note of
  that day. Its session, in the second client repo, asked the user while
  landing that repo's copy of the 2026-09-29 per-brief note.
- **Kind**: one sentence in `claude/CLAUDE.md` with its ledger entry,
  and a question of enforcement for the user. Nothing is drafted.

## The rule

The user, 2026-09-30, asked whether a client repo's committed files may
name the path of a script in this repo:

> No outside repo names committed at all. If something already exists
> fine, but I don't want any personal repo names being committed
> anywhere in an internal company repo.

Until then the payload held it second-hand, and for one repo. The
cross-repo handoff brief, deleted when it landed on 2026-09-30, recorded
it on 2026-09-29 as the estate repo's rule, as that repo's session
reported it, and left the second client repo open. **The
user states it for every internal company repo**, which makes it
machine-wide guidance and not one repo's convention.

- **"Committed" was read as files, commit messages, pull request text
  and branch names.** The user's sentence separates none of them; the
  estate repo's reported wording was "files, commits and PRs".
- **What already exists may stay.** The second client repo's queue
  README tells a session that a payload learning belongs in this repo's
  inbox directory, by name. It predates the rule, and the user let it
  stand.
- **A command that runs a personal repo's script stays local.** There
  the view command went into the project's auto-memory, and the
  committed root file carries the path-free `grep`.

## Where it lands

`claude/CLAUDE.md` § "Git identity is folder-scoped", beside the
paragraph that keeps an organization's names out of every repo: the
same section, the other direction. Its evidence, the user's words and
their date, goes to `docs/evidence/user-claude-md.md` under the same
heading.

`claude/CLAUDE.md` stood at 189 of its 200 lines on 2026-09-30. At
`0b1e82c` neither file said anything of the kind: a search of the two
for `personal repo`, `outside repo` and `company repo` finds one
unrelated ledger line.

## Nothing enforces it

`identity-guard` and its denylist run the other way. They keep an
organization's names out of any repo, and an `exempt:` line skips a
client's own root altogether. In the second client repo the working
tree was checked by hand, and this exited 1 with no match:

```bash
git diff --no-color | grep -n -i -E \
  '^\+.*(agent-config|Repos/Personal|handoff-status|machine-config|fabric-tools)'
```

**Whether a hook should hold it is the user's call**: a change to a
guard's reach, not a wording fix. A second list, of personal repo
names, scanned only under the exempt roots, is one shape it could take.
Put the question with the diff; the sentence lands either way.

## What it touches elsewhere

- The cross-repo handoff convention, landed 2026-09-30: each company
  repo's queue README and the notes sent to it already hand over the
  path-free form, and the invariants reference it once planned was
  dropped, so what is left to apply it to is a stub or note written
  from now on.
- [copilot-client-repo-findings.md](copilot-client-repo-findings.md),
  item 2: six lines in vendorable skills name a personal repo, and a
  client repo already carries two of them. Whether "if something
  already exists fine" reaches those vendored lines was not asked. A
  re-sync that adds the other four would be new.

## Verification

- `uv run scripts/lint-claude-md.py`: `claude/CLAUDE.md` inside its
  cap.
- After the merge, `./scripts/link-claude.ps1 -SkillGroups
  workflow,social,meta -Force` from the main checkout, never bare, then
  `cmp ~/.claude/CLAUDE.md claude/CLAUDE.md`.
- A cold session in a company repo, asked to add the queue's view
  command to a committed file, offers the path-free form or keeps the
  command local.
- `pre-commit run --all-files`.

## Scrubbing

This repo is public. Both client repos are cited by kind, and the
user's words are quoted as said and carry no name. The rule itself runs
the other way from this section: it keeps this repo's name out of
theirs.
