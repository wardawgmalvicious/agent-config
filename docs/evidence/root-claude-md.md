# Evidence for the root `CLAUDE.md`

This ledger records why each rule in [CLAUDE.md](../../CLAUDE.md) and in
[.claude/rules/](../../.claude/rules/) says what it says: how it was
measured, what was believed before, SHAs, counts. Root loads into every
session in this repo and each rule when a file it matches is Read; this
file loads into none, which is the whole point of the split.

- **The instructions themselves live in root `CLAUDE.md`, the rules in
  `.claude/rules/`, and the skills and READMEs those point to.** Where
  they and this file disagree, they are current and this file is history.
- **Entries are dated and never corrected in place.** A rule that changes
  gets a new entry at the end of its heading, opening with its date in
  bold — `**2026-10-01.**` — saying what changed and why.
- **Headings mirror root `CLAUDE.md`'s**, so the evidence for a section
  there, and for a rule split out of it, sits under the same heading here.
  Preamble holds what sits above root's first heading.

Everything below the headers was moved verbatim out of root `CLAUDE.md`
on 2026-09-24, as whole paragraphs so that `git blame -C` still reaches
the commit that first wrote each line. It carries the dates it was
measured on and states the rules as they stood that day. Its links are
verbatim too, so they resolve from the repository root, where they were
written, not from this directory. The `**2026-09-24.**` entry closing a
heading records what the move changed.

## Preamble

This repo is the source for the user's coding-agent configuration
(skills, a subagent, coding rules, hooks, MCP server templates,
settings) — see [README.md](README.md) for the full picture. Claude
Code is the harness it is written for and validated against; the
content is structured so other tools can cherry-pick it, not promised
to work in them.

Root `CLAUDE.md` is project-scope instruction and is never deployed.
[claude/CLAUDE.md](claude/CLAUDE.md) is Claude's user-scope payload.
They share a name and nothing else — neither is a mirror of the other.
This file is also the repo's *only* project-scope instruction file. A
`.github/copilot-instructions.md` and a root `AGENTS.md` each existed
alongside it and each drifted; both were deleted rather than kept in
sync. Don't add a third.

`copilot/instructions/` is **not** a third of those, and the difference
is worth being precise about: those two were project-scope instruction
files describing *this* repo, loaded in sessions here. `copilot/` is
payload for *other* repos and is never read here. It does carry the same
drift risk, since it duplicates `claude/rules/` prose in a second
format — which is why it is the one payload with a machine-checked
staleness gate (`scripts/lint-instructions.py`) instead of an intention
to keep it in sync.

Layout convention: **`<tool>/` names the payload's *format*, not its
only consumer.** `claude/` holds everything written in Claude Code's
formats — subagent frontmatter, `paths:`-scoped rules, hook event
wiring, user-scope `CLAUDE.md` and `settings.json`, and the MCP
templates in Claude's `mcpServers` schema. `copilot/` holds the one
payload written in *Copilot's* format — `*.instructions.md` carrying an
`applyTo` glob string — which exists only because that and `paths:` are
not interchangeable. `skills/` is the only
payload at the top level, because the Agent Skills format belongs to no
single tool. Root `CLAUDE.md` is already taken by this file, so the
user-scope one needs a directory — and once one payload file does,
keeping the whole payload together is the consistent choice.

Config for *this* repo is a third category, and lives where each tool
expects to find it rather than under a payload directory: `.mcp.json`,
`.claude/settings.json`, and `.vscode/mcp.json` describe the servers
and permissions used when editing this repo. Templates describe other
repos; live config describes this one. The VS Code template is the one
deliberate exception — it sits in `.vscode/` next to the live file
because that is exactly where it deploys.

`.claude/skills/` is that third category too, and is the one place where
it holds *skills* rather than settings. Five skills live there —
`author-skill`, `test-skill`, `drift-audit`, `drift-handoff`,
`drift-update` — because their whole subject is maintaining this
repo's own payload, so they can never usefully fire anywhere else. They
are authored at project scope, deployed nowhere, and reached by no
script: `link-claude.ps1` and `copy-copilot.ps1` both select out of
`skills/`, so neither can see them and neither needed changing when they
moved there (2026-09-09). That is the point rather than an omission — a
`description` is the entire trigger mechanism and the listing has a
budget, so these sitting at user scope were being offered to every
client-repo session on this machine, where they could only ever be noise.

**`land` was a seventh and moved back to `skills/workflow/` on
2026-09-13.** The reason recorded for demoting it — that it is built on
`github-mcp`, which is project scope, so a user-scope listing advertised
it where its tools could not run — did not survive checking. Client
repos declare `github-mcp` in their own `.mcp.json` too, the skill
treats a confirmed `gh` as a first-class route rather than a fallback,
and its one real use was in a client repo ten hours before the
demotion landed. Project scope confined it to the repo whose own
convention is to commit straight to `main` and never open a PR — the
only repo where it has nothing to do.

**`learn` moved to a new `skills/meta/` group on 2026-09-15**, for the
same shape of reason and a sharper symptom. The 2026-09-09 split filed
it with the maintenance skills because its *destination* is this repo's
payload — but that is where the edit lands, not where the learning
happens. A learning is produced in the session that hit the problem,
which is routinely a client repo, and project scope meant `/learn` was
not in that session's listing at all. The failure was silent in the
worst way: nothing is reported, the learning is simply not captured.
It surfaced on 2026-09-15, in the inbox note
`2026-09-15-kusto-streaming-and-warehouse-git-serialization.md` —
nine Fabric learnings out of a client estate, whose preamble records
the diagnosis itself: "`/learn` is project scope and fires only in
sessions inside `agent-config`. This arrived from a client repo."

`learn` now carries a **mode split** rather than a repo assumption.
Inside this checkout it edits the payload and hands off to `/commit`,
exactly as before. Anywhere else it does the whole analysis — what was
learned, which guidance owns it, coverage, verification — and writes a
note to `~/handoff-inbox/` instead of editing, which is the same route
the Copilot instruction already sends client-window sessions down. So
the inbox gains a second writer and keeps one reader.

**Why a new group rather than `workflow/`.** The split is subject
matter: `commit`, `code-review`, `land` and `prune-branches` act on
*your repo*, while `learn` acts on *the agent payload* — the same
subject as the five that stayed at project scope. `learn` is simply the
one payload-maintenance skill that has to run everywhere, because
learnings happen everywhere. The group also earns its keep mechanically:
it carries a **`.no-copilot` marker file**, so `copy-copilot.ps1`
excludes it from every run including a bare one, and
`lint-frontmatter.py` reads that same file to allow an active `model:`
key. That is what lets `learn` keep `model: fable` — the `model:` ban
exists only for Copilot's sake, and now asks the question it actually
means (*can Copilot reach this file?*) rather than *which tree is it
in*, which over-applied the ban to `social` as well. The marker is a
file rather than a list in each script precisely so the two cannot
disagree; see [skills/meta/.no-copilot](skills/meta/.no-copilot).

**The cost is a prune hazard, and it is the reason every documented
invocation had to change.** `-SkillGroups` deletes what it does not
list, so a stale `workflow,social` string does not merely fail to deploy
`meta` — it removes it. Sixteen command strings across ten files carried
the old form; the live ones were all updated to `workflow,social,meta`
on 2026-09-15. The spent briefs under `docs/audits/` were deliberately
left alone, being a dated ledger rather than instructions.

That leaves the remaining five repo-specific in a way neither `land`
nor `learn` was.

`.claude/settings.json` holds more than servers and permissions: a
`skillOverrides` block collapses **every** platform skill description to
`name-only` in sessions here. Don't restate that count — it read 41 and
went stale the day the 42nd skill landed. **`scripts/lint-skill-overrides.py`
now checks the coverage**, in pre-commit, over the whole set: the block is
a by-name map with no pattern form, so a newly authored platform skill is
silently uncovered, and the pair — new skill plus unchanged settings file
— is invisible to any per-file hook. That went wrong twice in a row, once
per `/author-skill` run: `1c64590` fixed `fabric-catalog-governance` only
after the skill had landed, and `fabric-activator` the same day was
uncovered the same way, caught mid-session by a hand-written probe rather
than by anything that would catch it next time.
The check also catches a value that is not `name-only`, an override left
behind by a rename, and a **new skill group** it cannot classify — add one
to `PLATFORM_GROUPS` or `BEHAVIOURAL_GROUPS` in that script, since
`workflow`, `social` and `meta` must *not* be collapsed. Collapsing is deliberate,
and stays even
though the workflow-only prune already keeps those skills out of
`~/.claude/skills` — it keeps them auditable from this repo and holds
the shape ready for a future edit. Remember it when reasoning about
triggers *while working here*: a `description` is the entire trigger
mechanism, and in this repo the platform ones are not in the listing to
be matched against.

Being a `<tool>/` payload says nothing about *how* it deploys:
everything under `claude/` is **copied**, while `skills/` is
junctioned. Deployment mechanism is the table below; directory
placement is only about format.

**2026-09-24.** Root was trimmed from 1,215 lines and 71,133 characters to
192 lines and 11,884 characters, and everything above moved here. The memory
docs target "under 200 lines per CLAUDE.md file. Longer files consume more
context and reduce adherence." This one grew from 8.3 KB on 2026-08-28 to
34.9 KB on 2026-09-02, 50.5 KB on 2026-09-09 and 71.5 KB on 2026-09-23, over
104 commits with nothing capping it. Most of it was guidance for editing one
kind of file, so that moved to `paths:`-scoped rules in `.claude/rules/`,
which load when a matching file is Read. An unscoped rule or an `@import`
still loads at launch, so neither would have helped. A subdirectory
`CLAUDE.md` was ruled out too: one loads when Claude reads a file beneath
it, and `claude/CLAUDE.md` already does here, as a `nested_memory`
attachment in 7 sessions since 2026-09-10 at up to 32,590 characters, on top
of the deployed copy.

"This file is also the repo's *only* project-scope instruction file ...
Don't add a third" guarded against copies of this file for other tools.
It now reads that root is the only project-scope instruction file that
loads at startup, that `.claude/rules/` holds what a file triggers, and
that there is still no parallel file for another tool. Counts and group
lists became the commands that derive them: "Five skills live there" is
now `ls -d .claude/skills/*/`. "Reached by no script" said too much once
its colon clause went, since the lint scripts read `.claude/skills/`; it
is scoped to the deploy scripts. "A `description` is the entire trigger
mechanism" leaves out `when_to_use`, which the listing appends. The tree
criterion stays in root rather than moving to the ledger with the `learn`
history, because `author-skill`'s tree step is stale: it still names
`learn` and `land` among the project-scope skills and has no `meta`. The
`skillOverrides` upkeep moved to `.claude/rules/skill-overrides.md`, and
the VS Code template exception to `.claude/rules/deploy-scripts.md`.

## Commands

```bash
# Lint frontmatter (skills need name/description; rules need paths:)
# Both skill trees take the same linter: it infers kind from a `rules/`
# path segment, not from `skills/`, so project scope needs no special case.
uv run --with pyyaml scripts/lint-frontmatter.py skills/<group>/<name>/SKILL.md
uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/<name>/SKILL.md
uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/<name>.md

# Check the flat skill-name namespace across BOTH trees. Runs over the
# whole set, not changed files: a collision is a property of a pair.
uv run scripts/lint-skill-scopes.py

# Check every fabric/ and powerbi/ skill has a name-only skillOverrides
# entry in .claude/settings.json. Whole set too — the uncovered pair is a
# new skill plus a settings file nobody changed, which no per-file hook sees.
uv run scripts/lint-skill-overrides.py

# Cap claude/CLAUDE.md, which loads into every session on the machine, at
# the memory docs' line target. The number lives only in the script. A path
# argument lints another file -- that is how its failing arm is proved.
uv run scripts/lint-claude-md.py

# Which skills have been tested, and what has changed in each since. Derived
# from the stamps /test-skill writes to tests/skills/.tested.json, never kept
# by hand: --stale is the to-do list, --check the pre-commit orphan check.
# Record a run with --stamp <skill> --phase activation,behaviour (or real-use).
uv run --with pyyaml scripts/skill-status.py --stale

# Where every drift-audit brief stands: a generated README.md in each
# docs/audits/<date>/<source>/, derived from the briefs' metadata blocks
# and execution logs. Never edited by hand; --check is the pre-commit gate.
uv run scripts/audit-status.py

# Which of a repo's files activate no rule and no skill at all. One repo,
# or --sweep a parent for every repo under it, ranked by weight. Counts
# per FILE, not per extension. Findings are candidates, not work.
uv run --with pyyaml --with wcmatch python scripts/payload-coverage.py <repo>
uv run --with pyyaml --with wcmatch python scripts/payload-coverage.py --sweep C:/Repos/Personal

# Every repo's open handoff briefs and inbox notes in one view, read out of
# each repo's own index -- nothing kept here. Defaults to every repo two
# levels under C:/Repos. --check exits 1 on an unindexed brief, a row whose
# brief is gone, or an inbox note routed nowhere. Reads, never writes.
uv run scripts/handoff-status.py
bash tests/scripts/handoff-status/test-findings.sh   # its negative cases

# Skills as PAIRS, which every other checker here misses. `routing` is the
# only signal that is a bug by default and the only one wired into
# pre-commit: a DESCRIPTION naming a skill that is not installed fails, a
# prose mention is reported and never gates. `overlap` ranks two
# descriptions that half-match one request; `coactivation` finds conditional
# skills whose globs always fire together. Nothing here says delete.
uv run --with pyyaml scripts/skill-overlap.py routing
uv run --with pyyaml scripts/skill-overlap.py overlap --skill <name>
uv run --with pyyaml --with wcmatch python scripts/skill-overlap.py coactivation <repo>

# The routing gate's NEGATIVE case, against throwaway payloads. The live
# tree passing says nothing -- a gate firing on nothing looks identical.
bash tests/scripts/skill-overlap/test-routing.sh

# Validate the Copilot instruction ports: applyTo frontmatter, no leaked
# repo name or profile path, and no drift from the rule each was ported
# from. --stamp re-records the hashes after a deliberate re-port.
uv run --with pyyaml scripts/lint-instructions.py

# All checks, the way CI runs them (gitleaks, ruff, frontmatter, scopes,
# skillOverrides coverage, test-stamp orphans, audit indexes, instructions,
# claude/CLAUDE.md length, identity)
pre-commit run --all-files
pre-commit run lint-skills --all-files     # one hook only

# Fresh clone: install pre-commit via uv and wire .git/hooks
scripts/bootstrap-pre-commit

# Query the hook observability logs (needs jq). These record rules and
# skill *invocations* only — never conditional (`paths:`) activation.
scripts/instructions-log today|reasons|paths|csv|skills|tail
```

```powershell
# THIS MACHINE'S DEFAULT — always use this form. Deploys workflow, social
# and meta only (code-review, commit, land, prune-branches;
# linkedin-highlights; learn); fabric and powerbi are PRUNED from
# ~/.claude/skills, and so is any listed group left off the list.
# The five skills in .claude/skills/ are NOT here and are deployed by
# nothing — see .claude/skills/ above.
# -Force also pushes claude/CLAUDE.md and claude/settings.json, and is
# what allows deleting a target-only file under agents/hooks/rules/mcp.
# Everything except skills/ deploys by copy, so a repo edit to a rule,
# hook, agent or MCP template is NOT live until this runs.
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force

# Same, when neither copied file has changed.
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta

# Also reconcile user-scope MCP servers in ~/.claude.json down to what
# claude/mcp/.mcp.global.template.json declares, PRUNING everything else.
# Off by default even under -Force; every run without it just reports the
# drift. Re-run after a Docker Desktop update, which re-adds MCP_DOCKER.
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -GlobalMcp

# Partial payload: push only the Fabric skills into a client repo's .claude,
# without this machine's agents, hooks, or rules.
./scripts/link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups fabric

# Vendor a COMMITTABLE payload into a client repo for teammates: platform
# skills into <repo>/.github/skills, ported rules into
# <repo>/.github/instructions.
# -Payload skills|instructions does one half; a payload left out is left
# ALONE, unlike -SkillGroups, where a group left out is PRUNED.
./scripts/copy-copilot.ps1 -CopilotDir <repo>/.github -SkillGroups fabric,powerbi

# Copilot's user scope on THIS machine, the only route there since every
# Claude root was switched off for Copilot on 2026-09-09. workflow only,
# never social. meta CANNOT be named here — it carries a .no-copilot
# marker and the script refuses it, bare runs included. Copies, so re-run
# after editing commit, code-review or a ported rule.
./scripts/copy-copilot.ps1 -CopilotDir ~/.copilot -SkillGroups workflow

# This repo's GitHub settings vs .github/repo-settings.json. Check is the
# default and read-only; -Export after a UI change; -Apply to restore.
./scripts/repo-settings.ps1
```

**Never run the script bare on this machine** — neither
`./scripts/link-claude.ps1` nor `./scripts/link-claude.ps1 -Force`.
Omitting `-SkillGroups` deploys *every* group, which re-links every
platform skill and silently undoes the prune. There is no error and no
output line that reads as wrong: the run reports `Linked` once per skill
and ends `Done. All links verified.` This happened on 2026-08-31, and the
only visible symptom was 18 platform skills reappearing in the session's
skill listing. Confirm the prune held **by name, not by count** —
`ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid)-'` must come back
empty. A count is what rots here; the absence of a namespace prefix is
the thing actually being asserted.

`-SkillGroups` **prunes**: a group not listed is removed from the target
on the next run. Pruning only ever deletes a junction resolving inside
this repo's `skills/`, so a skill authored directly in the target is
left alone. The prune is **user scope** — `~/.claude/skills` serves
every session on this machine, so workflow-only holds in client repos
too, not just here. Restoring a group is therefore a deliberate act, not
something to do in passing.

`.github/workflows/pre-commit.yml` runs `pre-commit` on every push and
PR to `main`, so frontmatter and secrets *are* machine-checked — the
fixture tests in `tests/` are not.

Linting gotchas worth keeping:

- PowerShell does **not** glob-expand args for external commands, so
  `skills/*/*/SKILL.md` passes through literally and fails — expand
  first with
  `$files = Get-ChildItem skills -Filter SKILL.md -Recurse | % FullName`.
- The pre-commit hooks are **depth-pinned**. The skills hook matches
  `^(skills/[^/]+|\.claude/skills)/[^/]+/SKILL\.md$` — the two trees sit
  at different depths, so the first arm consumes a group segment and the
  second consumes none, and each is pinned exactly. That is
  `skills/<group>/<name>/SKILL.md` and `.claude/skills/<name>/SKILL.md`
  and nothing else. A skill placed flat at `skills/<name>/SKILL.md`, or
  nested a level deeper, is silently skipped by the linter *and*
  invisible to Claude Code's one-level discovery — two silent failures
  from one misplacement. The rules hook is flat in the same way and
  won't see a nested rule.
- **A `files:` pattern that misses reports success.** pre-commit prints
  `(no files to check) Skipped`, which scans as a pass, so widening one
  is not self-verifying. Prove it against a path that must match and a
  path that must not:
  `pre-commit run lint-skills --files .claude/skills/author-skill/SKILL.md`
  (expect `Passed`) and `... --files skills/author-skill/SKILL.md`
  (expect `Skipped`). Both were run when the second arm was added,
  2026-09-09, and re-proved on each rewrite since. **This example has
  now been invalidated twice by a scope move** — it named `land` until
  2026-09-13 and `learn` until 2026-09-15, each time left asserting a
  path that no longer existed. `author-skill` is chosen because its
  whole subject is this repo's own authoring conventions, so it is the
  project-scope skill least likely to become payload; if it ever moves,
  repoint this to whatever is still in `.claude/skills/` and re-run both
  arms rather than trusting the text.
- **Skill names are one flat namespace across both trees**, since Claude
  Code addresses a skill by name alone — no group segment, no scope
  qualifier. `scripts/lint-skill-scopes.py` enforces it, and runs over
  the whole set rather than changed files because a collision belongs to
  a *pair*: neither file is wrong on its own, so no per-file hook could
  ever see it. It catches two cases with opposite noise levels. A name
  in both `skills/` and `.claude/skills/` is the **silent** one — user
  scope wins, the project-scope copy stops loading, and the only symptom
  is a skill behaving like an older version of itself. A name duplicated
  across `skills/` groups is already fatal in both deploy scripts; it is
  caught here only so it fails before the commit instead of after.
- `tests/` and `docs/` are gitleaks-allowlisted because fixtures
  intentionally contain fake credential-shaped strings.

**2026-09-24.** Root keeps one line per command it still lists; the rest
are documented in `scripts/README.md`. The quoted tell of a bare run was
stale: `Done. All links verified.` left `link-claude.ps1` with the copy
conversion in 157d188 (2026-09-02), and a run now ends
`Done. Payload verified (skills linked, everything else copied).` The
linting gotchas moved to `.claude/rules/pre-commit-hooks.md` and the
PowerShell wildcard one to `editing-skills.md`. One gotcha was stale too:
only `tests/` is gitleaks-allowlisted. `docs/` has been scanned since
2026-09-07, when `docs/audits/` became tracked, and `.gitleaks.toml` says
why. The prune's detail moved to `.claude/rules/deploy-scripts.md`.

## How this repo is structured

Files here are synced into tool config directories; where an edit
lands determines when it goes live:

| Repo path | Deployed to | Mechanism | Live when |
| --- | --- | --- | --- |
| `skills/<group>/` | `~/.claude/skills/<name>` | one junction per skill (`scripts/link-claude.ps1`) | immediately — same files |
| `.claude/skills/<name>/` | nowhere — read in place at project scope | none; no script touches it | immediately, in sessions here only |
| `claude/agents/`, `claude/hooks/`, `claude/rules/` | `~/.claude/agents`, `hooks`, `rules` | directory copy (`scripts/link-claude.ps1`) | after `scripts/link-claude.ps1` |
| `claude/mcp/` | `~/.claude/mcp` | directory copy (`scripts/link-claude.ps1`) | after `scripts/link-claude.ps1` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | plain copy | after `scripts/link-claude.ps1 -Force` |
| `claude/settings.json` | `~/.claude/settings.json` | key-level merge, target-only keys kept | after `scripts/link-claude.ps1 -Force` |
| `claude/mcp/.mcp.global.template.json` | `~/.claude.json` (top-level `mcpServers` only) | single-key reconcile, prunes | after `scripts/link-claude.ps1 -GlobalMcp` |
| `copilot/instructions/` | `<repo>/.github/instructions` | file copy (`scripts/copy-copilot.ps1`) | in a teammate's clone, once committed there |

`scripts/copy-copilot.ps1` also vendors `skills/<group>/` into a
`.github/skills` or `~/.copilot/skills` payload — **except a group
carrying a `.no-copilot` marker file**, which it excludes from every
run, a bare one included, and refuses by name if asked for explicitly.
`skills/meta/` is the only marked group. That marker is the same file
`scripts/lint-frontmatter.py` reads to allow an active `model:` key, so
the exclusion and the exemption cannot drift apart.

**`settings.json` is a merge, not a copy, and `-Force` cannot lose a
runtime key.** That row read "plain copy, key-level merge" until
2026-09-14 — a contradiction, and a brief reasoned from the "copy" half
to conclude that the one flag needed to deploy a `CLAUDE.md` edit would
silently discard the four `/config`-owned keys the live file carries and
the repo copy does not (`theme`, `agentPushNotifEnabled`, `tui`,
`model`). It does not. `scripts/link-claude.ps1` special-cases the file:
repo keys are added or replaced at the top level and **every target-only
key is kept**. Measured 2026-09-14 by running that merge branch verbatim
against a copy of the live file — all four survived with their values —
and again by a real `-Force` run, which left the file byte-identical
because every repo key already matched. What `-Force` *does* replace is
a **shared** key, whole, so a runtime edit nested inside a key the repo
also owns would be lost; all eight shared keys were byte-identical when
that was checked, so nothing was at risk either way.

The last row is the odd one and deliberately so. `~/.claude.json` sits
**beside** `~/.claude`, not inside it, and is not payload at all — it is
Claude Code's runtime state, holding the oauth account, project history
and usage counters. So it is the only target with its own opt-in switch:
`-GlobalMcp` is off even under `-Force`, is skipped under `-SkillsOnly`,
and is ignored unless `-ClaudeDir` is user scope, since no other scope has
this file (a project's equivalent is a committed `.mcp.json` at its repo
root, which the linker does not deploy). Drift is *reported* on every run
regardless, because this is a reconciler rather than an install: Docker
Desktop's MCP Toolkit re-adds an unfiltered `MCP_DOCKER` gateway entry
whenever it connects a client, re-exporting a whole Azure, Docker Hub and
GitHub tool surface into every session on the machine. Since the global
template went Docker-free on 2026-09-14 nothing here needs that gateway
at all, so the entry is pure noise and the reconcile deletes it — but it
still returns on the next connect. The switch replaces exactly one key and round-trips the rest
untouched — see [claude/mcp/README.md](claude/mcp/README.md) for the two
`ConvertFrom-Json` switches that make that round trip lossless, both of
which fail silently when omitted.

**`skills/` is the only junction, and that is the whole design.** It is
the one payload Claude Code hot-reloads, so edit-to-live is the
authoring loop; agents, hooks and rules need a fresh session either way,
so a junction there bought no immediacy while making every uncommitted
save — and every `git switch`, `stash`, `reset` and `rebase`, including
pre-commit's own stash/restore around a commit — live for every session
on this machine. Hooks were the sharp end: they *execute*, so a
half-written `.sh` fired on every matching tool call. Converted
2026-09-02. The four copied directories take repo content without
`-Force`; `-Force` is only needed to **delete** a target-only file the
repo no longer has.

Claude Code discovers a skill at `<skills-root>/<name>/SKILL.md` — one
level, no group directory in between — so `~/.claude/skills` is a real
directory holding one junction per skill, not a single junction for
`skills/`. (Claude Code doesn't read `~/.claude/mcp` at all; that copy
exists so the template-copy commands in
[claude/mcp/README.md](claude/mcp/README.md) resolve from a stable
path.)

The deployed names on the right are fixed by each tool and never
change, so repo-side moves are cheap: relocating payload under
`claude/` only changes where the script reads from, which
`scripts/link-claude.ps1` picks up on its next run with no `-Force`.
Hook commands in `settings.json` resolve via `$HOME/.claude/...`, so
they are unaffected by repo layout entirely.

`CLAUDE.md` and `settings.json` are copies **on purpose** — don't
"simplify" them into links. A symlinked `~/.claude/settings.json` broke
three times upstream in mid-2026, once destructively: 2.1.247 had the
Bash sandbox's after-command cleanup *delete* a dotfile-managed symlink
at that path. The directories used to be a separate story — their
symlink-path bugs (2.1.178, 2.1.198, 2.1.239) were fixed rather than
being arguments against junctions, and that reasoning was sound while
the junction was load-bearing for syncing several payload targets at
once. That rationale is gone, and all four are copies now, so the only
surviving reparse points are the per-skill junctions. Fewer of them is
strictly less exposure to that class of bug.

GitHub Copilot **deliberately inherits nothing from `~/.claude` on this
machine** — a reversal of what stood here. Since 2026-09-09 every
`chat.*Locations` entry naming a Claude root is `false`, so Copilot
reads `.github/*` and `~/.copilot/*` only. `rules`, `skills`, `agents`,
`settings.json` and `CLAUDE.md` remain *documented defaults* on that
surface (retested 2026-09-09; a 2026-09-04 note here claimed `skills`
did not resolve and was wrong) — they are switched off, not
unsupported. So `scripts/copy-copilot.ps1` is the only route from this
repo to Copilot, in a clone and on this machine alike, and
`link-claude.ps1` now serves Claude Code alone.

`chat.useClaudeMdFile` is the one exception, and it is **per profile**
like every `chat.*` setting — each VS Code profile keeps its own
`settings.json`. It is off in the profiles client repos open in and on
in the one this repo opens in, so Copilot here gets this file and
`~/.claude/CLAUDE.md`. Copilot still does not *write* here: learnings
from client windows go to `~/handoff-inbox/` (see Working on this
repo). Corrected 2026-09-11; this paragraph said it was off everywhere,
which held for the Default profile only.

Two traps in that switchboard, both silent. **An unlisted location keeps
its default, and the default is on** — each setting is a location →
boolean map *over* the documented defaults, so disabling inheritance
means writing every Claude root out as `false`; `.claude/skills` and
`.claude/rules` stayed live by omission while every root listed beside
them read `false`. And **the Settings UI does not reliably persist
these**: object-valued `chat.*` settings edited through it can leave
`settings.json` untouched with no error, measured 2026-09-09 against an
mtime four days stale and again 2026-09-11. Edit the profile's file —
`%APPDATA%\Code\User\settings.json` is Default's alone — and check it.

The frontmatter facts below survive that change and now describe the
**vendored** `.github/skills` payload rather than an inherited one.
Copilot validates skill frontmatter against its own field list, so
`paths:` and `effort:` warn and are ignored — meaning a conditional
skill is **unconditional** there. `model:` is the exception that is
*not* merely ignored: it breaks slash dispatch outright, for which see
Editing conventions below. What no longer applies is hooks: Copilot
parses Claude's hook *format* but not its semantics — matchers are read
and ignored, so the matcher-scoped `security-reviewer` write guard once
ran far wider there — and `chat.hookFilesLocations` is now `false` at
every location, so no hook in this payload reaches it at all.

**That is a *skills* fact and does not generalize to rules.** In
`.claude/rules` Copilot implements `paths:` on purpose, as the Claude
Rules format, defaulting to `**` when absent — so a rule stays
conditional exactly as it is here while a skill does not. Measured
2026-09-09: a `.sql` file open in a client repo loaded two of the twelve
rules in `~/.claude/rules`, the two whose globs matched. The pair is
easy to conflate and the consequences run opposite ways. That
measurement predates the cutover above and stands as a **format** fact —
the mechanism is what `.github/instructions` inherits via `applyTo`; the
`~/.claude/rules` root it was measured against is now switched off.

The `~/.claude` paths could never travel in a clone, which is why
`copilot/` and `scripts/copy-copilot.ps1` exist — and since the cutover
that is the whole path rather than the half of it a teammate needed.
Full detail, including the settings block and the traps, is in
[README.md](README.md#tool-support); this repo is authored and validated
against Claude Code, and Copilot wiring is not maintained here.

This file (root `CLAUDE.md`) is project scope only — it is **not**
deployed anywhere and loads only in sessions inside this repo.

**2026-09-24.** The settings merge, `-GlobalMcp`, one-level discovery, the
copies kept on purpose and the fixed deployed names moved to
`.claude/rules/deploy-scripts.md`; the table's `settings.json` row now
says a shared key is replaced whole, `.claude/rules/` shares the
`.claude/skills/` row, and the `claude/mcp/` row joined the other copied
directories, having the same mechanism and going live at the same point.
The Copilot paragraphs moved to `.claude/rules/copilot-payload.md`,
except which VS Code profile sets which `chat.*` switch: that is machine
state, recorded above as it stood, and `~/.claude/rules/vscode-scoping.md`
carries the traps in those settings. Root keeps that Copilot takes
`CLAUDE.md` only where a profile turns `chat.useClaudeMdFile` on.

"Agents, hooks and rules need a fresh session either way, so a junction
there bought no immediacy" no longer holds for rules: a rule is read from
disk when a file matching it is Read. On 2026-09-24, on 2.1.268, a cold
session in a scratch directory Read a matching file and got the rule as a
`nested_memory` attachment. A Bash command then edited that rule and
created a second one. The edit reached the session at once, as an
`edited_text_file` attachment carrying the new text, and the new rule
attached at the session's next matching Read. The same day in this repo,
`.claude/rules/editing-claude-md.md`, created mid-session, attached on that
session's next Read of `CLAUDE.md`. So root's table says a rule is live at
its next matching Read, and the junction line rests on what still holds:
a junction made every uncommitted state live machine-wide, a half-written
hook included. `.claude/rules/editing-rules.md` said "not hot-reloaded, so
an edit reaches the next session here" as committed in 5119075; the trim
corrects it.

**2026-09-24.** Re-measured, the profile paragraph above is false in both
halves: Config, the profile this repo opens in, sets
`chat.useClaudeMdFile` `false`, and Azure, which opens only client repos
(two that day), leaves it out, which means its default, `true`. Each live
profile's `settings.json`, with the stored copies of Fabric, Config and
Azure matching the live files on these keys:

| Profile | Claude entries in `chat.*Locations` | `chat.useClaudeMdFile` |
| --- | --- | --- |
| Default | every Claude location written out `false` | `false` |
| Fabric | every Claude location written out `false` | `false` |
| Config | every Claude location written out `false` | `false` |
| Azure | one entry, `"~/.claude/agents": true` | absent, so `true` |

Agents, VS Code's built-in profile, shares Default's settings. The stored
Config has carried `false` since machine-config's `d72a414` on
2026-09-10, the day before the correction above. Azure's one entry leaves
every other Claude location at its default, which is on, so Copilot there
reads the whole `~/.claude` payload; whether that is intended went to the
user the same day, through machine-config's handoff inbox. README § Tool
support repeated the paragraph and now says where that state is kept
instead of what it is: a named profile's settings in machine-config's
`configs/vscode/profiles/`, Default's in Settings Sync.

## How the pieces trigger

- **Skills** (`skills/<group>/<name>/SKILL.md` for deployable payload,
  `.claude/skills/<name>/SKILL.md` for this repo's own) trigger three ways:
  model-invoked (the frontmatter `description` is the *entire* trigger
  mechanism — the model matches context against it), user-invoked
  (`/<name>`), or path-scoped (a `paths:` glob in frontmatter).
  Behavioral, cross-domain skills are named as the verb you invoke
  (`commit`, `learn`, `code-review`, `drift-audit`); platform skills
  carry a `fabric-`, `pbir-`, or `pbid-` namespace prefix.
  The three ways are **not independently available**: a skill carrying
  a `paths:` glob is withheld from the startup listing, so until a
  matching file is Read its description is not in context and
  `/<name>` is `Unknown command` — path is its only cold entry, and
  model-invocation becomes available only afterwards. Measured
  2026-09-02 on 2.1.252.
- **Rules** (`claude/rules/*.md`) have no `name` or `description`, only
  `paths:` — they auto-load when a matching file enters session scope.
  A rule therefore cannot govern **creating** a file: activation is
  keyed to `Read` (§ "Validating a change"), and the first file in a
  directory has nothing matching to read. Guidance about *making*
  something needs a skill description, which matches intent, or a
  hook. Reasoned 2026-09-16 from the 2026-09-01 measurement; not
  separately measured.
- **Hooks** (`claude/hooks/*.sh`) fire on events registered in
  `claude/settings.json`. Their commands are hardcoded to
  `$HOME/.claude/...` and only resolve because the link script
  deploys this repo there — **don't rewrite them to be
  repo-relative.** A hook edit is **not live until
  `scripts/link-claude.ps1` runs**; the deployed copy keeps executing
  the previous version, and nothing says so.
- The `security-reviewer` subagent is scoped by an explicit tool
  allowlist plus the `PreToolUse` hook, which blocks any Edit/Write
  outside `~/.claude/agent-memory/security-reviewer/`.
- The `identity-guard` hook gates `git commit` and `git push` issued
  through Bash or PowerShell against `~/.config/identity-denylist.txt`
  — a **local** file that is never in this repo, because the list is
  the leak. Its test in `tests/hooks/identity-guard/` is the one
  machine-checkable suite here; run it after any edit, and again
  against the deployed copy after `scripts/link-claude.ps1`.
  **That hook sees Claude Code's commits only.** On 2026-09-10 a
  Copilot-authored commit took a client name to public `main` past it,
  so `.pre-commit-config.yaml` runs the same script as a git hook at
  three stages — commit, message, push — whoever commits. A clone needs
  `pre-commit install` (or `scripts/bootstrap-pre-commit`) re-run once
  to gain the message and push stages.
- **`scripts/push-gate.sh` refuses any push not issued from Claude
  Code**, as a pre-push hook beside that one. The identity guard only
  knows names already on its list; the gate stops everything else
  another harness wrote from reaching this public repo before a Claude
  session has reviewed it. Pushes from here pass on `CLAUDECODE=1`, so
  `/land` and a plain `git push` in a session are unaffected. The human
  override is one command long: `git -c agentconfig.push=reviewed push
  ...`. Added 2026-09-11.

**2026-09-24.** Root keeps the three facts cited from elsewhere: a
`paths:` glob keeps a skill out of the listing, a hook edit waits for the
linker, and the `identity-guard` suite runs on both copies. The hook,
subagent and push-gate detail moved to `.claude/rules/hooks-and-agents.md`,
which loads on `claude/settings.json` too, since the hook commands live
there; the limit on governing file creation went to `editing-rules.md`,
and skill naming to `editing-skills.md`. "Its test in
`tests/hooks/identity-guard/` is the one machine-checkable suite here" was
stale: `tests/scripts/` holds negative-case suites for the routing gate
and `handoff-status.py`. The push gate's "before a Claude session has
reviewed it" overstated: its own header says it guards against accidents,
not intent, and `--no-verify` skips it.

## Working on this repo

This repo's own operating procedure lives in `.claude/skills/` at
project scope — these are not generic helpers, and outside this repo
they have nothing to act on. `/commit`, `/code-review`, `/land` and
`/learn` are the exceptions and stay deployable — the first three in
`skills/workflow/`, `/learn` in `skills/meta/` — being useful in any
repo:

- `/author-skill` — new skill end to end: coverage check, naming, doc
  drilling, a filled brief in `docs/handoffs/`, then the draft
  and post-draft checks. Stops at a linted draft; writes no fixtures
  and does not commit.
- `/drift-audit` → `/drift-handoff` → `/drift-update` → `/commit` —
  the upstream-staleness pipeline. The audit is findings-only; the
  handoff writes briefs to `docs/audits/<date>/<source-id>/`; the
  update executes them in numbered order and stamps each done.
- `/commit` — split the working tree into logical commits.
- `/learn` — fold a session learning into guidance that already
  exists (a `SKILL.md`, a rule, `claude/CLAUDE.md`). Payload since
  2026-09-15, so it also fires in client-repo sessions; there it
  analyses the learning and writes a note to `~/handoff-inbox/`
  instead of editing. In a session *here* it behaves as it always did.

`docs/audits/` is a **tracked, dated ledger** — one directory per run,
committed when written and kept after it is spent. See
[docs/audits/README.md](docs/audits/README.md) for the lifecycle and
why it differs from `execute/`. It was gitignored until 2026-09-07 on
the grounds that audit output is regenerable; the powerbi source 404ing
at every endpoint that same day disproved it. Briefs there may quote
paths from before a repo reorganization — confirm a brief's evidence
still exists before acting on it.

Work that is scoped but not yet done lives in
`docs/handoffs/execute/`, and
**[execute/README.md](docs/handoffs/execute/README.md) is the
queue** — the only place the execution order lives, so read it before
starting a session here. Those briefs are *not* numbered the way
`/drift-handoff` numbers its output: they are committed, deleted
individually as each is spent, and cross-linked by filename, so the
filename has to stay stable and the ordering lives in the queue file.

**Learnings from other repos arrive through `~/handoff-inbox/`**, a
local folder in no repo with **one subdirectory per target repo** —
this repo's is `~/handoff-inbox/agent-config/`, a note loose in the
root is un-routed, and the folder's own `README.md` carries the layout
(since 2026-09-16; it was flat and payload-only before). Two writers
feed this repo's directory. Copilot
sessions in client windows write their notes there instead of editing
this repo — a hand-written instruction at
`~/.copilot/instructions/cross-repo-handoffs.instructions.md` tells
them to — and since 2026-09-15 `/learn` writes there too whenever it
fires outside this checkout, which is its whole note mode. Either way a
session here turns a note into a brief with `/author-skill`, or into an
edit with `/learn` in its edit mode. Notes are raw: they
carry the names of the workspace they came from, so nothing is copied
out of one verbatim, and client evidence is cited by kind, as the
handoff template's Sources guidance requires. Remove a note once its
content has landed. It sits outside the repo on purpose: a gitignored
folder under `docs/handoffs/` would leave one ignore line between those
names and a public repo, and would turn "Copilot never writes here"
into a rule with a carve-out. Set up 2026-09-11, after a Copilot
session open on a client repo wrote a brief straight into
`docs/handoffs/execute/`.

**2026-09-24.** "Remove a note once its content has landed" now agrees
with the user-scope rule and the inbox's own `README.md`: a note is
deleted only once its content has landed and the user has said yes. "The
folder's own `README.md`" is `~/handoff-inbox/README.md`; the per-repo
directory has none.

## Branching and concurrent sessions

**Skill saves are live; nothing else is** — but *how far* they reach now
depends on which tree they are in, and the difference is the whole point
of the split. A skill under any deployed group — `skills/workflow/`,
`skills/social/`, `skills/meta/` — is junctioned into user scope, so an edit changes the payload for **every session on this
machine the moment it hits disk**, committed or not. A skill under
`.claude/skills/` is live just as immediately, and only in **sessions
inside this repo**. `rules`, `hooks`, `agents` and `mcp` were junctions
too until 2026-09-02 and are copies now, so they change only when
`scripts/link-claude.ps1` runs.

Two conversions have therefore eaten most of the hazard this section was
written for. The 2026-09-02 copy conversion took `rules`/`hooks`/
`agents`/`mcp` out of it, and the 2026-09-09 scope split took seven of
the nine workflow skills out of user scope — so a mid-edit save to
`/author-skill` or `/drift-audit` can no longer reach a client-repo
session at all. What is left at machine-wide blast radius is
`code-review`, `commit`, `prune-branches`, and the two that moved back:
`land` on 2026-09-13 and `learn` on 2026-09-15. Read that list out of
the deployed groups rather than from here — it has been wrong twice,
and both times because a skill moved *into* them.

Every commit here is on `main`, and **no merge commit has ever existed**
(measured 2026-09-02, 324 commits in). The first branch —
`docs/rename-docs-dirs`, merged the same day — did not change that,
because it was integrated by fast-forward. That is not an oversight. For
the common change — one brief, one doc, one queue row, complete in a
single commit — committing straight to `main` is correct and stays
correct.

**Branch when an intermediate state would be broken while deployed** —
that is the trigger, not "am I in a session". **Settled 2026-09-02: it
stays the trigger, and branching stays the exception.** Committing
straight to `main` remains the default; the measurement behind that is
the worktree section below, which found no isolation a branch could buy.

This is a deliberate override, not a divergence to reconcile.
`claude/CLAUDE.md` § "Branch naming" carries the machine-wide default —
branch when the work exceeds one commit — and closes by saying a repo's
own committed convention wins. This section is that convention, and the
one worked example the payload names. Edit the two together.
Reconsider if a second silent collision between concurrent sessions
happens anyway.

Note which skills that trigger actually covers: whatever the deployed
groups hold at the time, since that is the set junctioned into user
scope. The 2026-09-09 split narrowed it to two, `land` widened it on
2026-09-13 and `learn` on 2026-09-15 (into its own `skills/meta/`), and
`prune-branches` was authored in — so enumerate the directories rather
than trusting a list here:
`ls skills/workflow skills/social skills/meta`. Each `SKILL.md` save in it is in
every session's listing before the fixtures, the queue row and the rule
catch up. A **platform** skill is pruned from user scope and junctioned
nowhere, so authoring one changes no session's payload at any point and
needs no branch on these grounds. Waves 12–14 are all platform-skill
authoring.

A **project-scope** skill in `.claude/skills/` sits between the two and
lands nearer the platform case. A save is live, but only for sessions in
this repo, so the reach is one working tree rather than the machine —
and a branch cannot isolate that anyway, since both sessions share the
tree. Sequencing is the remedy there, not branching.

**Sequencing outranks branching when another session is live.** These
two rules collide, and this is the precedence: `git switch -c` is still
a switch, uncommitted work travels with it, and a commit the other
session makes while you are on your branch lands on *your* branch. So
when someone else is working in this tree, stay on `main`, commit in
small complete units, and stage explicit paths. Branch when you have
the tree to yourself.

```bash
git switch -c <type>/<kebab-slug>
```

`<type>` is the conventional-commit vocabulary `/commit` already writes
— `feat`, `fix`, `docs`, `refactor`, `chore` — so the branch and its
commits agree without a second taxonomy. `<slug>` names the subject:
`feat/fabric-ontology-skill`, `docs/semantic-model-briefs`,
`fix/coding-kql-glob`. **Don't number branches by queue wave.**
`docs/handoffs/execute/README.md` deliberately keeps positions out
of filenames because positions churn and links break; the same argument
applies here.

**Integrate by fast-forward.** Squash would collapse the logical split
`/commit` just made, and rebase-merge rewrites the SHAs it just wrote.
So land a branch locally rather than through the merge button:

```bash
git switch main && git merge --ff-only <branch> && git push origin main
```

That preserves the exact SHAs, keeps `main` linear and adds no merge
commit; GitHub marks the PR merged once its commits are reachable. Open
the PR with the `github-mcp` tools, **not `gh`** — the two authenticate
as different accounts here, and only one of them matches this repo (see
`~/.claude/CLAUDE.md`). The repo is public so CI is pollable
unauthenticated, but `allow_*_merge` and branch protection are not
(`null` / `401`), so the rebase rejection surfaces at merge time and not
before. Verified 2026-09-02 on PR #6.

**Never `git checkout` or `git switch` while another session is live in
this tree.** One working tree is on one branch, so the switch is not
scoped to you. Since the copy conversion this no longer swaps the other
session's rules and hooks — those move only when the link script runs —
but a skill present on one branch and not the other still leaves
`~/.claude/skills/<name>` dangling until `scripts/link-claude.ps1` runs
again, and the other session's *files* still change underneath it
regardless of payload.

**A worktree does isolate the files, and still isn't the way around
that.** Measured 2026-09-02 by deploying to a real worktree and probing
it cold; the paragraph that stood here named the wrong blocker. Three
results, in the order they matter:

- **The junction blocker was misidentified.** The junctions are
  absolute, but `link-claude.ps1` takes `$RepoRoot` from
  `$PSScriptRoot`, so running the *worktree's own* copy links that
  worktree's skills and a session there loads them — conditional
  activation included, and the description that loads is demonstrably
  the worktree's. The trap is running the **main tree's** copy with
  `-ClaudeDir <worktree>`: it relinks every junction back to the main
  tree, reporting `Relink` and ending `Done`. Run the script from the
  tree whose content you want deployed.
- **User scope outranks project scope**, and that is the real blocker.
  With `drift-handoff` at both scopes and a marker in only the
  worktree's copy, the listing carried the **user-scope** text and the
  marker appeared nowhere in the transcript. Project scope only adds
  names user scope lacks — and **a name it adds does resolve**, which
  was the untested half until 2026-09-09: the seven skills moved to
  `.claude/skills/` exist at project scope *only*, and a fresh session
  here listed them. Shadowing is the rule when both scopes hold a name;
  it is not a general demotion of project scope.
- **So a worktree is either unnecessary or ineffective, with no case
  in between.** A platform skill is pruned from user scope, so editing
  it here changes no session's payload and needs no isolation — the
  workflow-only prune already *is* the isolation. A workflow skill is
  at user scope, and a worktree cannot override it.

**The 2026-09-09 scope split reopens that last bullet, and it has not
been re-measured.** The dichotomy held because every workflow skill was
at user scope, where the shadowing rule made a worktree copy inert. The
five skills now in `.claude/skills/` are at project scope *only* — no
user-scope copy exists to outrank them — so a worktree plausibly does
isolate them, which would be the in-between case the bullet says cannot
exist. Treat the conclusion as covering everything in
the deployed groups, and re-run the worktree probe before relying on it
for the five that are not.

Two supporting facts, both measured the same day. `-SkillGroups` does
**not** prune user scope when `-ClaudeDir` is given — the prune loop
walks `$ClaudeDir/skills`, and user scope held at eight across four
runs; the hazard is *omitting* `-ClaudeDir`, which is the ordinary
bare-run hazard and has nothing to do with worktrees. And two
worktrees cannot share a branch: git answers `fatal: '<branch>' is
already used by worktree at ...`, so worktree-per-session means
branch-per-session by construction.

**Two sessions in this tree share every file, branch or no branch.**
Branching does not isolate them; only sequencing does. So before
editing a contended file — `docs/handoffs/execute/README.md`
above all, and each `expected_activations.md` — **re-read it
immediately first**, and stage explicit paths so a commit cannot sweep
up the other session's work. On 2026-09-02 two sessions edited the
queue minutes apart; nothing warned, and re-reading before writing is
the only thing that caught it. The failure mode is silent: your write
succeeds and drops the other session's rows.

**Explicit-path staging has a blind spot: the line you need may live
inside *their* diff.** Re-reading catches the case where your write
drops their rows; it does not catch the inverse — a fix whose target
exists only in the other session's uncommitted work and not in `HEAD`.
Path granularity cannot help, because `git add <path>` takes every hunk
in the file and an added line has no `HEAD` version to stage apart from
the block it belongs to. So before editing a contended file, check
whether the target is in `HEAD` at all:

```bash
git show HEAD:<path> | grep -n "<target>"
```

Nothing back means the line is theirs, not yours. Leave it, and record
the deferred fix in your own commit message so `git log` carries it
rather than this conversation. On 2026-09-02 a rename needed one word
changed in `tests/skills/fabric-triggers/expected_activations.md`; the
only mention sat inside another session's unstaged block, so the rename
shipped with that reference knowingly stale and a note saying so. The
other session fixed it themselves — the note is what would have carried
it if they hadn't.

**The index is shared too, so staging is not isolation — only a commit
is.** An uncommitted change of yours to a file the other session also
commits can vanish, staged or not, and `git status` afterwards looks
innocent. On 2026-09-12 a `skill-status.py --stamp` entry in
`tests/skills/.tested.json` was lost twice to the other session's
commits — once from the working tree, once from the working tree *and*
the index while it sat staged — and a `git add <path>` in between swept
in a hunk they had written seconds earlier. Which step of their commit
cycle discarded it was not established; pre-commit's stash/restore
around a commit is the likely one.

What worked is now the procedure in `/commit` — the chained
write-stage-commit, verifying `git diff --cached` before committing,
treating `.git/index.lock` as their git command in flight rather than a
stale lock, and the hand-cut patch in
`skills/workflow/commit/references/concurrent-sessions.md`. **This
section keeps the evidence; the skill keeps the procedure**, because the
skill is the copy that reaches repos where this file never loads. Edit
one or the other accordingly rather than restoring the duplicate.

**2026-09-24.** Which skills a save reaches machine-wide is now
`ls skills/workflow skills/social skills/meta`, not a list. Three claims
were stale. "Open the PR with the `github-mcp` tools, **not `gh`** — the
two authenticate as different accounts here": on 2026-09-24 the `gh`
wrapper, a bare `gh.exe` and `github-mcp` all acted as this repo's owner,
since the folder-scoped `gh` wrappers of 2026-09-04, so root now says to
open the PR as the owner, which `/land` checks. "A **platform** skill is
... junctioned nowhere": the same day one client repo's `.claude/skills`
held `-ClaudeDir` junctions to all 45 platform skills, so a save to one is
live in that repo's sessions. And "What worked is now the procedure in
`/commit`" named the one-hunk reference; the procedure is `/commit` §
"When another session shares this tree". The worktree measurement above
stands, reduced to one line in root with its open flag for
`.claude/skills/`, and `docs/handoffs/execute/worktree-isolation-scope.md`
proposes its revision. Its linker trap, and the junction a branch switch
leaves dangling, moved to `.claude/rules/deploy-scripts.md`.

The reopen condition above, "Reconsider if a second silent collision
between concurrent sessions happens anyway", has been met once: the
`--stamp` entry lost twice on 2026-09-12 was a second silent collision.
13fed79 took the question up on 2026-09-22, kept committing straight to
`main` as the default, and opened two briefs:
`handoff-queue-derived-count.md`, retired on 2026-09-23 in 4f25957, and
`worktree-isolation-scope.md`, still open. Root keeps the condition as it
stood. Of the contended files, root still names the queue;
each `expected_activations.md` is named in
`.claude/rules/activation-testing.md`, which loads when one is Read.

**2026-09-24.** The worktree verdict above answered one axis. Measured
2026-09-02 against `git worktree add` plus `link-claude.ps1`, it asked
whether a worktree isolates *payload*, and that answer stands: user scope
outranks project scope. `--worktree` and `EnterWorktree` are a different
mechanism, carrying enforcement the hand-rolled worktree had none of.
code.claude.com/docs/en/worktrees, re-fetched that day, lists four checks
on the session and every subagent it spawns: an `Edit`, `Write` or
`NotebookEdit` targeting the main checkout; a Bash, PowerShell or Monitor
command whose working directory resolves there, or cannot be verified to
stay out; git redirected there by `-C`, `--git-dir`, `GIT_DIR`,
`GIT_WORK_TREE` or a prior `cd`; and a command whose text cannot be
verified to keep git inside, of which "You can't turn this check off."
PowerShell gets the working-directory check alone.

What that buys is the index, not the document. Each worktree has its own
index, so the 2026-09-12 `--stamp` loss above, an index collision, cannot
happen across worktrees, and root now scopes "only a commit isolates" to
one tree. But two worktrees are two branches, and in a history with no
merge commit in 782, a silent overwrite of the queue becomes a merge that
`--ff-only` refuses. A worktree suits divergent state and not convergent;
the convergent case here was the queue's count line, deleted 2026-09-23
in `7d31355`.

The open flag closes without a run. The same page: "In a worktree with its
own `.claude/skills` directory, only that copy loads", the main checkout's
reading through only when there is none, which for skills needs v2.1.277
(this machine had 2.1.281). `git ls-files` counts 9 tracked files in
`.claude/skills/` and 9 in `.claude/rules/`, so a worktree of this repo
always has its own copy of both, and the in-between case the 2026-09-02
verdict calls impossible is real for the five project-scope skills. The
page does not name `.claude/rules`: that half is inferred from the rules
being tracked. Both rest on docs plus a count, not a run, and
`docs/handoffs/execute/worktree-isolation-scope.md` holds the probe that
would witness them.

`worktree.baseRef` was unset in `claude/settings.json`,
`.claude/settings.json` and `~/.claude/settings.json`, so it defaulted to
`"fresh"`: branch from the remote default branch, fetched when older than
24 hours with a five-second cap, the cached ref otherwise. `origin/main`
lags `HEAD` whenever pushes do: two commits on 2026-09-22, four through
the trim, level after a push, four again by the afternoon. A worktree, or
an `isolation: worktree` subagent, which takes the same base, would lack
them with nothing said. The user chose `"head"` in `.claude/settings.json`,
this repo only, since in a client repo a clean base matching the remote
may be the point of a worktree. Inside a worktree, `"head"` resolves to
that worktree's `HEAD`.

Preconditions, re-measured the same day: no `includeIf` in this repo's
`.git/config`, where one refuses creation with an error that reads as a
git-config problem (a global one is exempt, and this machine's identity
scoping is global); `[lfs]` holding only `repositoryformatversion`; and
`.claude`, `.claude/skills` and `.claude/rules` real directories, neither
symlink nor junction. `/.claude/*` in `.gitignore` already covers
`.claude/worktrees/`.

Two things stay ruled out. Agent teams, on their docs as drilled
2026-09-22: experimental, off behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`,
and naming this repo's failure outright, "Two teammates editing the same
file leads to overwrites"; a team can also form unasked, teammates are
scoped to one session, and split panes are unsupported in VS Code's
terminal. And a subtraction from `claude/CLAUDE.md`'s escalation
paragraph: code.claude.com/docs/en/cross-session-messaging says a peer
message "can't approve anything" and that the receiving Claude is told
"never to change permission settings, `CLAUDE.md`, or other configuration
because another session asked", which restates its first clause. The user
kept the paragraph whole, since the loaded half of the peer-subsection
ablation in `docs/handoffs/execute/linkedin-article-skill.md` ran against
its current text.

**2026-09-24.** The worktree probe ran, on 2.1.282: transcript `a3c9d394`
under the worktree's own project directory, plus `/context` from a second
session in the same worktree. A `--worktree` session loads only the
worktree's `.claude/skills/`, `.claude/rules/` and root `CLAUDE.md`, which
closes the inferred half and overturns the brief's expectation of two root
copies. The guard refused three of the four paths it covers and let
through a `cd` that leaves the worktree from inside a command. The brief's
nine assertions, with its numbering:

- **0, the base: pass.** `main` stood one commit ahead of `origin/main`,
  `3676ed0` over `2a31b2f`, and the worktree's `git log -1` printed
  `3676ed0`, so `baseRef: "head"` took local `HEAD`.
- **1, `Write` into the main checkout: refused**, in a third wording, not
  either of the two the errors page gives for commands: "This session is
  isolated in the worktree `<path>`. Edit the worktree copy of this file
  instead of the shared-checkout path." No file appeared.
- **2, Bash `cd <main> && ls`: ran**, and listed the main checkout, where
  the docs' working-directory check predicts a refusal. The shell's
  directory then stayed there, and every later Bash or PowerShell command
  was refused, "this command's working directory resolved to the shared
  checkout", `cd` and `Set-Location` back into the worktree included.
  `EnterWorktree` with the worktree's path was the way out. `Read` and
  `Grep` on main-checkout paths ran throughout, which no check covers.
- **3, Bash `git -C <main>`: refused**, "this command redirects git to the
  shared checkout via -C".
- **4, Bash `$(echo git) status`: refused**, "names git in a form too
  complex to verify that it stays inside the worktree".
- **5, outside the checks: both ran.** Bash
  `echo probe > <main>/probe-bash.txt` wrote its 6 bytes, and the `rm`
  that removed them ran too; PowerShell `git -C <main> log -1` printed
  `3676ed0`. Neither is covered by the checks as the docs word them.
- **6, skills: pass.** An `Edit` putting a marker at the head of the
  worktree's `author-skill` description brought an `isInitial: false`
  `skill_listing` six seconds later, one skill, carrying the marker, and
  the main checkout's copy stayed unchanged. The baseline, measured the
  same day outside a worktree: of the transcripts here since 2026-09-09,
  the 23 that run `Edit` or `Write` on a `.claude/skills/*/SKILL.md` each
  have a later `isInitial: false` record for every skill they edited, 32
  in all.
- **7, rules: pass.** Reading the worktree's `claude/settings.json`
  attached `deploy-scripts.md` and `hooks-and-agents.md`, and its
  `.pre-commit-config.yaml` attached `pre-commit-hooks.md`, each once, each
  under `.claude/worktrees/probe-isolation/.claude/rules/`. No record named
  the main checkout's copy, and none attached `claude/CLAUDE.md`.
- **8, root `CLAUDE.md`: one copy.** The session's `instructions` record
  holds the worktree's root `CLAUDE.md` as its only Project file, and
  `/context` lists one `CLAUDE.md`. The main checkout's root sits above the
  worktree and did not load. Auto memory is shared: the `MEMORY.md` loaded
  is the main checkout's, under `~/.claude/projects/`, not the worktree's
  project directory.

Root's line now names the copies a worktree loads and both gaps: the shell
write the guard does not see, and the `cd` that runs and then strands the
session. The brief and its queue row are deleted with this entry.

## Editing conventions

- **Skills** — Claude Code truncates the combined `description` +
  `when_to_use` text at 1536 chars in the skill listing (configurable
  via `skillListingMaxDescChars`), and truncation is silent. That 1536
  is **split into a fixed budget per field** rather than left as one
  shared pool: `description` ≤ 1024, `when_to_use` ≤ 512, enforced
  separately by `DESCRIPTION_MAX` and `WHEN_TO_USE_MAX` in
  `scripts/lint-frontmatter.py`. The split is what stops an edit to one
  field silently overflowing the other, and it makes a lint failure name
  the field to cut. 1024 is the Agent Skills spec cap and `description`
  is one of the six fields the claude.ai upload path accepts, so that
  half stays portable; `when_to_use` is a Claude Code extension the spec
  does not carry, so the remainder is spent where it is already
  non-portable. `LISTING_MAX` re-checks the sum and can only fire if the
  two constants are edited apart. Decided 2026-09-01; the field
  semantics are confirmed against `code.claude.com/docs/en/skills`.
  Lint with
  `uv run --with pyyaml scripts/lint-frontmatter.py skills/<group>/<name>/SKILL.md`
  (pre-commit runs it too, over both skill trees). Long detail goes in
  the skill's own `references/`, not SKILL.md. Skills
  **hot-reload**: Claude Code watches skill directories and picks up
  changes in-session, and this works through this repo's junctions —
  verified 2026-08-31 on Claude Code 2.1.251 for skill add, skill
  removal, `skillOverrides`, and — added 2026-09-02 on 2.1.252 — an
  in-place `description` edit: four descriptions were rewritten with
  `sed` and the next listing carried the new text, no restart. That
  confirms the *listing* refreshing, which is the surface triggers are
  matched against; it was not separately tested that a reworded trigger
  then fires. (Upstream fixed in-session skill reload in 2.1.216; this
  file previously claimed the opposite.)
- **Rules** — `paths:` frontmatter globs control auto-load; a rule
  fires when a matching file enters session scope (GitHub Copilot's
  `.instructions.md` `applyTo:` globs are the direct analog). Client
  repos can override any rule with `.claude/rules/<same-name>.md`.
  Lint with
  `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/<name>.md`
  (pre-commit runs it too). A wrong glob has no error path — the rule
  just never loads — so the linter rejects the mistakes that silently
  narrow a pattern: a backslash separator, a leading `/`, and a bare
  `*.ext` with no `/` (which matches only repo-root files; `**/*.ext`
  matches those *and* nested ones).
- **Skill invocation and spend fields** — every `SKILL.md` carries
  `effort` and `disable-model-invocation` **explicitly**, even where the
  value is the default, so the flip point for each lever is visible in
  the file rather than being an absent field. `model:` is carried the
  same way, but **active only in `.claude/skills/` and commented out
  everywhere under `skills/`** — an active `model:` key of any value stops
  GitHub Copilot dispatching the skill as a slash command, for which see
  below. The split is that the ban is a Copilot accommodation and Copilot
  cannot reach the project-scope tree from either direction:
  `scripts/copy-copilot.ps1` selects out of `skills/`, so those five are
  never vendored into a `.github/skills` payload, and all four VS Code
  profiles on this machine set `".claude/skills": false` in
  `chat.agentSkillsLocations`, so the beside-the-workspace-root
  auto-discovery is off too (both checked 2026-09-12).
  `scripts/lint-frontmatter.py` enforces exactly that split, and its two
  arms are proved the way a `files:` pattern is — one file, copied to both
  paths, must fail at `skills/workflow/…` and pass at `.claude/skills/…`.
  Of the five, `author-skill` and `drift-audit` read `model: fable` and
  the other three `model: inherit` — the split is where
  irreducible judgment sits rather than where the checklist is longest,
  so wording a `description` gets the better model while executing a
  numbered brief does not.
  `drift-update` and `test-skill` are deliberately unpinned on those
  grounds, and `drift-update` most deliberately: it hands every decision
  or investigation brief back rather than executing it, so its judgment
  is externalized by design. Fable is the Opus tier at twice the price
  (measured $10/$50 per MTok against $5/$25 on 2026-09-12), which is what
  makes this a per-skill call and not a default.

  **`learn` keeps `model: fable` as deployed payload**, which is the
  point of `skills/meta/` carrying a `.no-copilot` marker. The ban on an
  active `model:` key exists only because Copilot cannot resolve one, so
  as of 2026-09-15 `lint-frontmatter.py` asks whether Copilot can reach
  the file — `reaches_copilot()` — rather than which tree it sits in.
  `.claude/skills/` is unreachable by tree; a marked group is
  unreachable because `copy-copilot.ps1` excludes it from every run,
  bare ones included, and throws a named error if one is requested. Both
  arms were proved on 2026-09-15: the same file passes at
  `skills/meta/learn/SKILL.md`, fails when copied to
  `skills/workflow/`, and fails again at its own path with the marker
  temporarily removed — which is what shows the marker, not the group
  name, is doing the work.
  The commented values under `skills/` are still the documentation they
  always were, `# model: inherit` everywhere except `commit`
  (`# model: sonnet`).
  Note what an active pin is worth there: `model:` is slash-only, and the
  documented way to reach every one of those seven is to type its name, so
  the limit that made the field near-useless under `skills/` does not
  apply. It stays **turn-scoped** — the session model resumes on the next
  prompt.
  **Pin the alias, not the dated ID — and check the CLI before trusting
  a reading.** The CLI carries its own model table, so a stale one
  resolves an alias to an older release silently: on 2.1.252
  `model: fable` ran `claude-fable-5`, while the dated
  `claude-fable-5-1` ran but printed `[claude-code:unrecognized_model]`
  first; on 2.1.268 both run `claude-fable-5-1` clean. Same files,
  opposite readings, so any measurement of model routing is only as
  current as `claude --version` — compare it against
  `winget list --id Anthropic.ClaudeCode` first. Prefer the alias: a
  dated ID freezes the pin on one release once the next ships. Measured
  2026-09-12. (`machine-config/setup.ps1` has why the CLI was stale — an
  npm global shadowing the winget install on PATH — and the cleanup.)
  Current policy: the session default is `"effortLevel": "max"` in
  `claude/settings.json`. DMI is `false` everywhere (it is not used in
  this repo).
  `effort` is `max` on every behavioural skill in both trees except
  `commit`, which is `xhigh`, and left commented on every platform
  skill, which therefore inherits `max`. **Don't restate the count
  here** — it read "eight" while the real figure was ten, having missed
  `prune-branches` and `linkedin-highlights` when each was authored.
  Derive it:
  `grep -rln "^effort: max" skills/ .claude/skills/`.
  No scope move has changed an **`effort`** pin — not the
  2026-09-09 split, not `land` in 2026-09-13, not `learn` in
  2026-09-15: `effort` applies on both the
  slash and
  model-invocation paths and is scope-independent, so a project-scope
  skill keeps its floor exactly as a user-scope one does.
  Note what that means: *while the session actually sits at* `max`,
  only `commit` changes behaviour. But the session level is **live
  state, not the file** — it can be changed mid-session, nothing
  warns when it drifts, and the transcript is the only place the real
  value shows (observed 2026-09-01: both copies of `settings.json`
  read `max` while the session ran at `xhigh`, switched by accident
  while browsing the level list). Whenever it sits below `max` the
  `max` pins start *raising* effort rather than matching it, which is
  exactly the *floor* they were written for. Platform skills stay
  unpinned **on purpose**: they auto-trigger alongside your real work,
  so an effort pin there governs your Fabric/Power BI turn rather than
  any discrete skill run.

  **Uncommenting a `model:` key under `skills/` breaks GitHub Copilot.**
  Under `.claude/skills/` it does not, and that tree is pinned; the
  paragraph above has the reasoning and the evidence. An active
  `model:` of *any* value — `inherit` and `sonnet` alike — stops VS Code
  dispatching that skill as a slash command: nothing is sent, no session
  is created, and it reads as a hang rather than an error, so there is
  no error path to follow back to the cause. Measured 2026-09-09 with
  single-variable probes, after `/commit` and `/code-review` both hung
  in a client repo: a control skill slash-invoked fine, adding `model:`
  broke it, and `effort:`, `when_to_use:` and
  `disable-model-invocation:` were all harmless. `model` is a supported
  field on Copilot *prompt* files, where it selects the LLM, which is
  the likeliest reason a value it cannot resolve kills dispatch.
  `scripts/lint-frontmatter.py` rejects an active `model:` key under
  `skills/` so this cannot return silently.

  What follows is what the field does. It still governs the pinned seven,
  and under `skills/` it is the argument for how little was given up.

  `model:` is **turn-scoped** — it applies while the skill is active
  and the session model resumes on the next prompt. But it is also
  **slash-only**: a skill reached by model-invocation (the description
  matching, i.e. a plain-English request) runs on the *session* model
  and its `model:` pin is silently ignored. `effort:` applies on both
  paths. Measured 2026-09-01 on 2.1.252, within a single session, with
  everything else held constant — `/commit` ran `claude-sonnet-5
  xhigh`, and a plain-English commit request eleven minutes later ran
  `claude-opus-5 xhigh`. Two consequences. `commit`'s `model: sonnet`
  only saves anything when you actually type `/commit`. And a
  `model:` pin is **inert on every conditional platform skill** — a
  `paths:` glob withholds them from the startup listing, so they are
  reached by path, and `/<name>` answers `Unknown command`. It is
  **live on the unconditional ones**, which carry no glob and slash normally
  (measured with `/fabric-gotchas`, 2026-09-02 on 2.1.252). All 41
  carried `model: inherit`, so nothing was broken either way. Corrected
  2026-09-02 — this previously said all of them were inert because they
  "never" slash.

  So the whole cost of commenting the field out is that `/commit` now
  runs on the session model instead of Sonnet. That was the only
  load-bearing pin in the payload: 49 of 50 read `inherit`, which is the
  default, and a pin is ignored entirely on every conditional skill
  and on any skill reached by description rather than by name.
  `effort:` has **no
  `inherit` value**; omitting the field *is* the inherit, which is why
  it is carried as a commented placeholder rather than a written-out
  default, and an unsupported level silently falls back to the highest
  supported one at or below it.
  `disable-model-invocation: true` removes that skill's description from
  the listing **in every session on this machine** and blocks subagent
  preloading and scheduled-task firing — so it is a listing-cost change
  as much as an invocation one. And **`ultracode` is not an effort
  value**: the docs note it "is not a distinct level and reports as
  `xhigh`". It is a session orchestration mode with no frontmatter
  field, so the highest pin available is `max`.

- **Adding a harness** — create `<tool>/` and put every artifact only
  that tool reads inside it. Promote something to the repo root only
  when a second tool actually consumes it. Wire the deployment in a
  `scripts/link-<tool>.ps1` that, like the others, leaves the tool's
  home directory real and tool-owned.
- **`claude/CLAUDE.md`** — loaded into *every* session on this
  machine. Keep it lean: machine environment and pointers only. If
  guidance has a narrower trigger (a file type, a product area),
  prefer a path-scoped rule or a skill instead. A rule there carries
  itself, what its failure looks like and one date; its evidence goes
  to [docs/evidence/user-claude-md.md](docs/evidence/user-claude-md.md)
  under the same heading. `scripts/lint-claude-md.py` caps the file's
  length in pre-commit, so a learning that does not fit moves something
  out rather than raising the cap. After editing it,
  re-run `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`
  — never bare, see Commands — to push it to `~/.claude/CLAUDE.md`.

**2026-09-24.** The Skills bullet and the invocation and spend fields
moved to `.claude/rules/editing-skills.md`, the Rules bullet to
`editing-rules.md`, and the `claude/CLAUDE.md` bullet, with a new one for
root, to `editing-claude-md.md`, which loads on any Read of a `CLAUDE.md`
or a ledger; the brief planning this trim kept those two in root, and
they moved to bring root under the cap. Two claims were corrected on the
way. "The pinned seven" read six by then, the five in `.claude/skills/`
plus `learn`, so the rule derives the pins with `grep`. "Client repos can
override any rule with `.claude/rules/<same-name>.md`" was imprecise:
Claude Code loads both sets, and code.claude.com/docs/en/memory says
"Neither set overrides the other" (checked 2026-09-23 on 2.1.268). What
switches a user rule off in a repo is the "supersedes this one" sentence
each rule in `claude/rules/` carries, so a project rule named after one
disables it.

Root gained the Read-before-edit line. Edit and Write refuse a file that
has not been Read, so a rule reliably loads before any Edit of an existing
matching file, and never for a `sed` or heredoc edit or a new file. A
block-level HTML comment costs no context: on 2026-09-23, on 2.1.268, a
cold haiku session saw every visible marker and neither commented one, in
a `CLAUDE.md` and a `.claude/rules/` file alike. A Read still shows it, so
evidence kept in comments would come back on every edit.

**2026-09-24.** The pre-commit length check now covers root too:
`scripts/lint-claude-md.py` checks both files, root's failure message
naming `.claude/rules/` and this ledger, and the hook matches
`^(claude/)?CLAUDE\.md$`. Root was 192 lines when the check reached it;
before, nothing capped it, and the Preamble entry has how far it grew.

**2026-09-24.** `claude/CLAUDE.md` loaded twice in sessions here: at
launch as `~/.claude/CLAUDE.md`, byte-identical that day, and again as a
subdirectory `CLAUDE.md` on the first Read under `claude/`, which
code.claude.com/docs/en/memory gives as when a subdirectory's file loads.
Two witnesses before the fix: probe transcripts `65de8af5` and `e9ff8b72`
each held a `nested_memory` attachment for it, and the
`InstructionsLoaded` hook log held 15 `nested_traversal` loads from
2026-08-28 on, every one this file. The same page says `claudeMdExcludes`
patterns "are matched against absolute file paths using glob syntax" and
says nothing of Windows, while the log records backslashed paths whose
drive letter reads `c:` and `C:` by turns. So the key reached
`.claude/settings.json` only after one cold haiku probe per variant on
2.1.281, each through `--settings` and each Reading
`claude/mcp/.mcp.global.template.json` with Read alone. "The path" is
`C:/Repos/Personal/agent-config/claude/CLAUDE.md`; the `c:` rows were
launched through cmd from a `c:` cwd, as VS Code launches a session.

| Variant | Pattern | cwd | Read spelled | Nested load | Session |
| --- | --- | --- | --- | --- | --- |
| control | none | `C:` | `C:` | loaded | `9dd28eeb` |
| candidate | `**/claude/CLAUDE.md` | `C:` | `C:` | excluded | `c1dbf8cd` |
| absolute | the path, `C:/` | `C:` | `C:` | excluded | `9ea79328` |
| lower drive | the path, `c:/` | `C:` | `C:` | loaded | `5751437f` |
| backslash | the path, backslashed | `C:` | `C:` | excluded | `01f8361c` |
| control | none | `c:` | `c:` | loaded | `83033174` |
| candidate | `**/claude/CLAUDE.md` | `c:` | `c:` | excluded | `27204600` |
| absolute | the path, `C:/` | `c:` | `C:` | excluded | `2c2d19c7` |
| lower drive | the path, `c:/` | `c:` | `c:` | excluded | `2289891f` |
| mirror | the path, `C:/` | `c:` | `c:`, pinned | loaded | `9a69338c` |

In every run `deploy-scripts.md` still attached on the Read, and the
launch `instructions` attachment still listed root and
`~/.claude/CLAUDE.md`: the exclude leaves rules alone and does not reach
`.claude/CLAUDE.md`. A pattern naming the drive matches only when its
letter's case equals the path's, and the path takes the case the Read was
spelled in, not the cwd's: haiku wrote `C:\` from a `c:` cwd in the
second `absolute` run, which is why that row excluded and the mirror, its
Read pinned to `c:\` in the prompt, did not. That rules out an absolute
pattern even in a gitignored `settings.local.json`. Separators are
normalized, tested under `C:` only. The hook log witnessed none of it: no
probe logged a `nested_traversal` line, the control included. Re-run with
no `--settings` against the file as committed (`8b42472f`): excluded, the
rule attached, both launch files listed. The brief that planned this was
deleted in the same commit.

## Validating a change

There is no automated test suite here — `pre-commit` covers frontmatter
and secrets, and nothing else is machine-checkable. Behavior is verified
by hand against the fixtures in `tests/`.

**Which skills have had that verification is derived, not listed.**
`/test-skill` stamps each run into `tests/skills/.tested.json` with a
hash of what the phase tested, and `scripts/skill-status.py` compares
the stamp with the skill now — so its verdict says whether an edit
needs a retest at all: a `paths:` change does, a `description` or
`when_to_use` change does, a body change does on a behavioural skill,
and a `references/` change never does. Don't write a "still untested"
list anywhere; the README carried one for four months and every skill
on it had been edited since. Run `--stale` instead.

After changing a skill, rule, subagent, or enforcement hook, follow the
procedure in [tests/skills/code-review/README.md](tests/skills/code-review/README.md),
[tests/skills/fabric-semantic-model-audit/README.md](tests/skills/fabric-semantic-model-audit/README.md)
or [tests/agents/security-reviewer/README.md](tests/agents/security-reviewer/README.md):

- Run in a **fresh** agent session — for context hygiene (accumulated
  context can mask a co-load failure), and because subagents, commands,
  and rules are not watched the way skills are. Skills themselves do
  hot-reload; that is no longer the reason for the cold start.
- Establish the baseline with `claude --safe-mode`, which starts with
  this entire payload off — `CLAUDE.md`, skills, plugins, hooks, MCP
  servers, commands, agents. It is the control condition: it separates
  behavior the payload produces from behavior the base model produces.
  A flag you type, never something to wire into `settings.json` or a
  script — that would disable the payload it is meant to isolate.
  **It is the wrong control for a false-positive guard**, though, and
  silently so: a guard suppresses a finding the skill's *own* checklist
  generates, and the base model runs no checklist, so the baseline
  passes the criterion by never asking the question. Measured
  2026-09-03 on `fabric-semantic-model-audit`'s planning-model
  carve-out, where `--safe-mode` passed the criterion it was predicted
  to fail. The discriminating control there is an **ablation** — the
  same skill with the guard stripped, everything else identical
  (`test-semantic-model-audit.ps1 -Mode nocarveout`). Strip *every*
  reference to the guard: a half-strip leaves the skill
  self-contradictory, and a run that notices hedges, which biases the
  result toward standing down.
  It is the wrong control a second way for this repo's own skills:
  `--safe-mode` strips root `CLAUDE.md` with the payload, and that file
  carries most of what those skills say — `/test-skill` step 8 has the
  ablation for that case (measured 2026-09-13 on `test-skill`).
- Compare against `expected_findings.md` rather than judging the output
  on its own — the fixtures encode what should be caught *and* what
  should not be.
- Exercise both the documented invocation and the refusal modes. A
  subagent that does the right thing but ignores its scope guard has
  failed.
- Confirm the fixtures are unmodified afterwards with `git status`. A
  run that edits its own inputs invalidates every later comparison.

Changing a `paths:` glob changes *whether a skill fires at all*, which
none of the fixtures above test. That contract belongs to
[tests/skills/pbip-triggers/](tests/skills/pbip-triggers/) and
[tests/skills/fabric-triggers/](tests/skills/fabric-triggers/) —
disjoint fixture sets that between them assert **every** conditional
skill in the payload.
Assertions live in each set's `expected_activations.md`, which is where
each figure is owned — **don't restate a total anywhere else**, including
here. This count was duplicated into six files, checked by nothing, and by
2026-09-02 had drifted three ways at once (`tests/README.md` still said
19). Both sets stayed exhaustive throughout; only the prose rotted.
Derive it instead: `./scripts/test-activation.ps1 -Set fabric
-StaticOnly`, then `-Set pbip`.

**Exhaustiveness is the invariant; the number is not.** It moved three
times on 2026-09-02 alone — to 25 when workstream E made five skills
conditional, 26 when `fabric-operations-agent` landed, 27 when
`fabric-ontology` did — and again on 2026-09-12 with `fabric-activator`.
That cadence is the argument: a standing total here is wrong by the next
authoring run, so this paragraph deliberately no longer carries one. Read
it out of the owning file, or derive it with the command above.

**No *log* records conditional activation, but the session transcript
does.** `instructions-loaded.log` sees rules only; `skills-invoked.log`
and `skillUsage` count *invocations*, and a path-triggered skill is
*loaded*, never invoked, so a zero in any of them says nothing about
whether a glob matched. The transcript is the exception, and it is
authoritative: a match appends an `{"type":"attachment"}` record whose
`attachment.type` is `skill_listing`, with `isInitial` **false** and
`names` naming the skills, to
`~/.claude/projects/<project>/<session-id>.jsonl`. The `isInitial: true`
record is the startup listing and says nothing about any file. Confirmed
2026-09-01 on 2.1.252.

**But `isInitial: false` is not proof of a glob match — it is also how a
hot reload announces itself.** Editing a `SKILL.md` re-announces *that*
skill, and a `link-claude.ps1` run re-announces everything it deployed;
both produce a record indistinguishable from an activation. Measured
2026-09-03 across 268 transcripts: **438** delta announcements named a
skill that was already in the same session's startup listing, and every
one sampled was preceded by an `Edit` to its `SKILL.md` or by a
redeployment. That is not a rounding error — in this repo, where editing
skills *is* the work, it is most of the deltas. It does not affect
`test-activation.ps1`, whose probe only ever `Read`s fixtures, but it
does mean a transcript delta only witnesses activation when nothing wrote
that skill earlier in the same session. `scripts/skill-telemetry.py`
subtracts the explainable ones; anything else counting deltas must too.

The `isInitial: true` record is worth more than it looks: its `names`,
`skillCount` and rendered `content` are the only record of **what was
offered**, so "listed and not chosen" is separable from "never listed" —
which is the distinction the retracted truncation finding got wrong.

**`--debug-file` cannot see it**, which is probably how the older
"no observability" claim formed. Its `N conditional skills stored` and
`Sending N skills via attachment (initial)` lines are both emitted before
any Read runs, so neither can show a file-triggered activation.

**Activation is keyed to the `Read` tool, not to the file.** Reading a
matching file with `cat` through Bash — or with `Grep` — activates
**nothing**: no skill, no rule, no attachment. That matters here because
`claude/settings.json` sets `permissions.defaultMode` to `auto` at user
scope, so every session on this machine starts in auto mode, which
prefers `cat` for reading files. A `paths:`-scoped skill or rule is
therefore *live but dormant* through a whole session that only ever
`cat`s. Nothing is broken when this happens and nothing says so — the
file is read, the answer is right, the guidance simply never loads. Pin
`--allowedTools Read --disallowedTools Bash …` on any probe that is
*measuring* activation, and assert the `tool_use` block really was a
`Read`. Measured 2026-09-01 on 2.1.252 as a 2x2 (Read/Bash x in-repo/
scratch): `Read` activated in both directories, `cat` in neither.

**Directory properties do not affect it.** A scratch directory outside
any repo activates exactly as this repo does, with the same payload —
ruled out individually: not being a git repo, living under
`AppData/Local/Temp`, having no `.claude/settings.json`, the 8.3 short
path, and the fixture's depth below the project root. So a trigger
harness may run anywhere; what it must control is the tool.

`~/.claude/logs/instructions-loaded.log` is **not** a reliable witness
for rule loading in short `claude -p` sessions — its `InstructionsLoaded`
hook missed two of four confirmed loads on 2026-09-01. The transcript saw
all four, as `nested_memory` attachments naming the rule file. Rule
absence in that log proves nothing; use the transcript for both.

What a match injects is the skill's **listing entry, not its body** — the
body loads only on invocation. Cost models that price an activation at
body size are wrong by an order of magnitude.

**An activation is a per-session cumulative delta**, for rules as well as
skills: an attachment names only what was not already active, so a second
file matching an already-loaded skill emits *nothing*. Confirmed
2026-09-01 on 2.1.252. **Scope that to activation, though** — a hot
reload re-announces a skill that is already listed, so the deduplication
rule governs glob matches, not every delta (see above). Don't read that silence as a failed match — and
don't write a per-file cost model on top of it either. It is also what
makes the real-path test affordable: one session covers a whole fixture
set, so both sets cost ~2 sessions rather than ~70. Attachments are
flushed in batches rather than after each read, so an activation is
attributable to the run of files read since the previous flush, not
always to one file.

`./scripts/test-activation.ps1 -Set pbip|fabric` runs the whole real-path
test — deploy to a throwaway probe, one cold session, transcript
assertion, teardown in a `finally`. Add `-StaticOnly` for the glob check
alone. The cheap regression is still that static check, which needs no
session at all; a cold session only proves the harness agrees with the
globs.

**2026-09-24.** "There is no automated test suite here — `pre-commit`
covers frontmatter and secrets, and nothing else is machine-checkable" was
stale: pre-commit gates everything `.pre-commit-config.yaml` lists, and
`tests/scripts/` holds negative-case suites for the routing gate and
`handoff-status.py`. "Derive it instead:
`./scripts/test-activation.ps1 -Set fabric -StaticOnly`" never gave the
total: the static run prints the fixtures it checked ("PASS - globs and
expected_activations.md agree on all 70 fixtures", 2026-09-24), so root
points at the owning table, which says 29, and at a `grep` that counts the
same 29. "`instructions-loaded.log` sees rules only" held, but "No *log*
records conditional activation" was true of skills alone: that log records
path-matched rule loads as `path_glob_match`. What can witness an
activation moved to `.claude/rules/activation-testing.md`, and root's
probe pin regained `--disallowedTools Bash`, since `--allowedTools` alone
removes nothing. The manual procedure stays in root, shortened, because
`test-skill` sends rules, subagents and enforcement hooks there. Its fresh
session stays for context hygiene alone: "subagents, commands, and rules
are not watched the way skills are" does not hold for rules, which a
session reads when a matching file is Read (How this repo is structured,
2026-09-24).

## Line endings

Nothing moved: this section stands in root unchanged.
