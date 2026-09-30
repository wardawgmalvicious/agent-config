---
status: open
priority: 3
needs: [user, the Claude session target probe]
blocked-by: []
written: 2026-09-30
---

# Handoff: what a client repo's Copilot re-sync found, and what it waits on

- **Written**: 2026-09-30, from two inbox notes of 2026-09-29 by
  sessions in a client Fabric repo: one from its first
  `copy-copilot.ps1` run since port selection (`3775d1a`), the other
  from a trim of its root instruction file, findings 2 and 4.
  Re-measured against the payload at `0b1e82c`, which corrects one
  count.
- **Kind**: a decision, the user's, then an edit or a deletion for each
  item, as that decision falls. Nothing is drafted, and nothing here is
  worth building before it.

## What the items wait on

`scripts/copy-copilot.ps1` and `copilot/` were added on 2026-09-09 for a
teammate cloning a client repo, who "gets nothing" from a junction
(`068fbfe`). On 2026-09-30 the user said that reader does not exist:
they are the only developer on every repo they work in, use Copilot only
on the corporate network, on this same laptop, and want no second repo
(this repo's session memory, `sole-reader-of-the-payload`). An
exploration that day, which edited nothing (transcript `230c3b1b`), left
two paths and a probe to choose between them:

- **VS Code's Claude session target answers on the corporate network**:
  retire the Copilot payload, as Codex support was on 2026-08-28
  (`3f2c7d8`).
- **It does not**: keep Copilot at user scope only, stop vendoring into
  repos, and freeze the ports.

The probe is the user's to run. Its prompts went to a client repo's
inbox that day, and its results come back to
`~/handoff-inbox/agent-config/` as
`<date>-claude-session-target-probe-results.md`. **Nothing new is
vendored into a repo on either path**, which settles most of what is
below. On the second, a client repo's existing skill copies are either
dropped, for Copilot reading that repo's `.claude/skills` junctions, or
kept and re-synced now and then. The exploration left that open.

## 1. A repo-target run without `-SkillGroups` vendors `social`

- `skills/social/` carries no `.no-copilot` marker; only `skills/meta/`
  does. An omitted `-SkillGroups` selects every group without one
  (`$availableGroups`, in `#region Resolve selected skills`), so a run
  into a repo's `.github` that forgets the flag copies
  `linkedin-highlights` there, to be committed with the rest. Read from
  the script and `skills/*/`, not run: the client's run named
  `fabric,powerbi,workflow`, as the first `.EXAMPLE` does.
- The help is stale, twice. `-SkillGroups` reads "(fabric, powerbi,
  workflow). Defaults to all of them", no longer one set. The paragraph
  beneath says the `workflow` group holds `code-review` and `commit` and
  that `land` moved to project scope, while `skills/workflow/` holds
  `code-review`, `commit`, `land` and `prune-branches` (2026-09-30).
- The fix forks on scope. A marker on `social` also keeps it from
  `~/.copilot`, which `.claude/rules/copilot-payload.md` already says
  takes `workflow` only, "never `social`". A guard for repo targets
  alone, such as requiring `-SkillGroups` there, leaves user scope open.

**As the decision falls.** Retired, the script goes and this with it.
At user scope only, a marker on `social` turns the rule's "never
`social`" from remembered into structural, for `~/.copilot` and for any
re-sync a repo still gets: one file, whose contents say why the group
opted out.

## 2. No check keeps a personal repo's name out of a vendored skill

`lint-instructions.py` fails a port that carries `agent-config`,
`machine-config`, `claude-config` or a profile or repo-root path
(`FORBIDDEN`), because ports deploy into client repos. Skills deploy
there too, and no other `lint-*.py` looks for those names.

**Six lines in the vendorable groups name a personal repo, not the
note's eight** (2026-09-30):

| Skill | Where | Names |
| --- | --- | --- |
| `land` | `SKILL.md:48` | this repo |
| `land` | `references/integration-routes.md:49`, `:177`, `:299` | this repo |
| `land` | `references/branch-deletion.md:165` | `machine-config` |
| `fabric-eventhouse` | `references/remote-mcp.md:16` | this repo |

```bash
git grep -nP '\b(agent|machine|claude)-config\b' -- \
  skills/fabric skills/powerbi skills/workflow skills/social
```

- The note's other two, in `fabric-data-agent`, are a Learn URL whose
  slug, `data-agent-configurations`, contains the string. **`FORBIDDEN`
  matches substrings, so run over skills as it stands it fails that URL
  twice.** A check for skills needs a word boundary.
- The client repo already carries two of the six, committed by earlier
  vendoring: `fabric-eventhouse`'s, and `land`'s at what is now
  `integration-routes.md:49`. The note counted four, two of them that
  URL. A skills re-sync adds the other four, so its 2026-09-29 run used
  `-Payload instructions` and left its skills as they were until this
  is settled.
- The user's rule, stated 2026-09-30 for every internal company repo,
  is that nothing committed there names a personal repo, while what
  already exists may stay
  ([company-repos-name-no-personal-repo.md](company-repos-name-no-personal-repo.md)).
  Whether that allowance reaches the two lines already vendored was not
  asked. The other four would be new.

**As the decision falls.** Retired, the client repo's copies are
deleted and nothing is left to guard. At user scope only, they are
either dropped for the junctions or kept and re-synced, and a re-sync
commits the four lines the rule forbids. So if they are kept, the six
lines are reworded first, which is cheaper than a lint; rewording
`land` moves its body hash, so `/test-skill land` follows.

## 3. File-kind guidance shared with Copilot

`agent-instructions-scoping.md`'s table sends guidance about one kind of
file to a `.claude/rules/` file with `paths:`. Copilot never reads that
file in a repo whose Claude roots are off in
`chat.instructionsFilesLocations`, as every profile here has had them
since 2026-09-09. So the client repo took another shape, and names it
once in its root `AGENTS.md`:

- the guidance lives in `.github/instructions/<stem>.instructions.md`,
  attached by its `applyTo`;
- a same-stem `.claude/rules/<stem>.md` carries `paths:` mirroring that
  `applyTo`, one glob per item, and a body of a few lines: which file to
  read before editing, what it covers, and a reminder to keep the globs
  in step.

Three alternatives were rejected there:

- An `@`-import in the rule, which loads at launch
  ([scoped-rule-imports-and-trigger-sorting.md](scoped-rule-imports-and-trigger-sorting.md),
  item 1).
- Two full copies, which nothing holds in agreement.
- Turning `.claude/rules` on for the repo, so Copilot reads the rule
  itself. Copilot honours `paths:` there
  (`.claude/rules/copilot-payload.md`), so one file would serve both
  tools; but it reverses the Claude-roots-off convention for that repo
  and hands Copilot every Claude-only rule beside it. The note calls it
  worth weighing where all of a repo's rules are shared.

The shape costs two things: Claude gets the content one Read later, and
only if it follows the pointer; and the `paths:` and `applyTo` pair is
kept in step by hand.

Were it to land, it goes in `agent-instructions-scoping.md`, as a row
under "Where a piece of guidance lives" or a paragraph under "Sharing
one file with other tools", which covers only the root file and long
form today.

**As the decision falls.** Retired, the shape inverts: a Claude session
target reads `.claude/rules`, so the rule holds the content and the
instructions file goes, and nothing lands. At user scope only, the
shape stands wherever a repo keeps `.github/instructions/`, and the
third rejected alternative is what the exploration's option of letting
Copilot read a repo's `.claude/skills` does for skills: weigh the two
together.

## 4. The deferred `fabric-git-serialization` port

`copilot/.source-hashes.json` defers it "pending review -- most-edited
rule at 10 commits and the most Fabric-specific"; 12 commits on
2026-09-30. Evidence for that review, from the client repo on
2026-09-29:

- **Four generic facts in the repo's own guide already reach Copilot
  through the payload.** Lowercase `sysname` comes through the
  `coding-tsql` port. The data-loss block, the `.sqlproj` SDK pin and
  `logicalId` come through the vendored `fabric-gotchas` skill, which
  loads on a description match, not when a file is opened.
- **The rest of the generic content is the deferred rule's**, and
  reaches Copilot only through the repo's hand-written
  `.github/instructions/` guide of 95 lines: hand-authored files deleted
  from item folders, keeping the new `.platform`, a whole Lakehouse
  update failing on one shortcut, `DatabaseSchema.kql` syncing
  additively, and the view-header line endings. The markdown-cell `#`
  rule sits in a second repo file. The guide cites the rule's own
  incidents, and both files drift with each edit to the rule.
- **About half the guide is the repo's own**: its generator scripts, CI
  workflows and variable names. That half stays whatever is decided.

The note gives three ways to settle it: port the rule whole, which port
selection confines to repos holding Fabric item folders, at the cost of
redoing the port on every edit to the most-edited rule; port a stable
core, EOF bytes, absence is deletion, additive KQL sync, the
markdown-cell `#` and line endings, keeping dated observations on the
Claude side; or keep deferring and accept a copy in each client repo.
With either port the client repo cuts its guide to its own half.

**As the decision falls.** Retired, the question is moot. At user scope
only, with the ports frozen, it is the third way by default, and the
client repo keeps its guide.
[fabric-view-endings-and-az-rest-lro.md](fabric-view-endings-and-az-rest-lro.md)
edits the rule again meanwhile.

## Not checked

- Item 1 was read, not run. A bare run into a scratch directory would
  show it, and `-WhatIf` lists without copying.
- Which of the client repo's vendored files survive on the second path.
- Item 3's shape is one repo's, a day old when the note was written.
- [copilot-harness-switches.md](copilot-harness-switches.md)
  investigates what VS Code's other harness reads. The exploration read
  it as mattering on the second path only; that is its reading, not a
  decision recorded there.

## Landing it

Each item lands as a yes or a no once the direction is known, and a no
is recorded in the commit that deletes this brief
([README.md](README.md) § "A brief can be a decision rather than an
edit"). The direction itself is not this brief's to settle: if it gets a
brief of its own, fold this one into it.

## Scrubbing

This repo is public. The client repo is cited by kind, its files by
role, and the user's words about who reads the payload carry no name.

## Re-measure before acting

- `ls ~/handoff-inbox/agent-config/` for the probe's results note.
- `ls -a skills/*/` for the markers, and the `git grep` above for the
  six lines.
- `git log -1 --format=%h -- scripts/copy-copilot.ps1`: `3775d1a` on
  2026-09-30.
