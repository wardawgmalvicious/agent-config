# agent-config: repo instructions

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

Layout convention: **`<tool>/` names the payload's *format*, not its
only consumer.** `claude/` holds everything written in Claude Code's
formats — subagent frontmatter, `paths:`-scoped rules, hook event
wiring, user-scope `CLAUDE.md` and `settings.json`, and the MCP
templates in Claude's `mcpServers` schema. `skills/` is the only
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

`.claude/settings.json` holds more than servers and permissions: a
`skillOverrides` block collapses all 41 platform skill descriptions to
`name-only` in sessions here. That is deliberate, and it stays even
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

## Commands

```bash
# Lint frontmatter (skills need name/description; rules need paths:)
uv run --with pyyaml scripts/lint-frontmatter.py skills/<group>/<name>/SKILL.md
uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/<name>.md

# All checks, the way CI runs them (gitleaks + both frontmatter linters)
pre-commit run --all-files
pre-commit run lint-skills --all-files     # one hook only

# Fresh clone: install pre-commit via uv and wire .git/hooks
scripts/bootstrap-pre-commit

# Query the hook observability logs (needs jq). These record rules and
# skill *invocations* only — never conditional (`paths:`) activation.
scripts/instructions-log today|reasons|paths|csv|skills|tail
```

```powershell
# THIS MACHINE'S DEFAULT — always use this form. Deploys the workflow
# skills only; fabric and powerbi are PRUNED from ~/.claude/skills.
# -Force also pushes claude/CLAUDE.md and claude/settings.json, and is
# what allows deleting a target-only file under agents/hooks/rules/mcp.
# Everything except skills/ deploys by copy, so a repo edit to a rule,
# hook, agent or MCP template is NOT live until this runs.
./scripts/link-claude.ps1 -SkillGroups workflow -Force

# Same, when neither copied file has changed.
./scripts/link-claude.ps1 -SkillGroups workflow

# Partial payload: push only the Fabric skills into a client repo's .claude,
# without this machine's agents, hooks, or rules.
./scripts/link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups fabric
```

**Never run the script bare on this machine** — neither
`./scripts/link-claude.ps1` nor `./scripts/link-claude.ps1 -Force`.
Omitting `-SkillGroups` deploys *every* group, which re-links the 37
platform skills and silently undoes the prune. There is no error and no
output line that reads as wrong: the run reports `Linked` 37 times and
ends `Done. All links verified.` This happened on 2026-08-31, and the
only visible symptom was 18 platform skills reappearing in the session's
skill listing. Confirm the prune held with `ls ~/.claude/skills`: it
should list the eight workflow skills and nothing else.

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
  `^skills/[^/]+/[^/]+/SKILL\.md$` — that is
  `skills/<group>/<name>/SKILL.md` and nothing else. A skill placed
  flat at `skills/<name>/SKILL.md`, or nested a level deeper, is
  silently skipped by the linter *and* invisible to Claude Code's
  one-level discovery — two silent failures from one misplacement. The
  rules hook is flat in the same way and won't see a nested rule.
- `tests/` and `docs/` are gitleaks-allowlisted because fixtures
  intentionally contain fake credential-shaped strings.

## How this repo is structured

Files here are synced into tool config directories; where an edit
lands determines when it goes live:

| Repo path | Deployed to | Mechanism | Live when |
| --- | --- | --- | --- |
| `skills/<group>/` | `~/.claude/skills/<name>` | one junction per skill (`scripts/link-claude.ps1`) | immediately — same files |
| `claude/agents/`, `claude/hooks/`, `claude/rules/` | `~/.claude/agents`, `hooks`, `rules` | directory copy (`scripts/link-claude.ps1`) | after `scripts/link-claude.ps1` |
| `claude/mcp/` | `~/.claude/mcp` | directory copy (`scripts/link-claude.ps1`) | after `scripts/link-claude.ps1` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | plain copy | after `scripts/link-claude.ps1 -Force` |
| `claude/settings.json` | `~/.claude/settings.json` | plain copy, key-level merge | after `scripts/link-claude.ps1 -Force` |

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

GitHub Copilot needs no payload and no linker: the VS Code agent
surface reads the same `~/.claude` paths this repo already populates
(`rules`, `skills`, `settings.json`, `CLAUDE.md`, and `agents` once
`chat.agentFilesLocations` names it — the one path that isn't a
documented default). It parses Claude's hook *format* but not its
semantics — notably, matchers are read and ignored, so the
matcher-scoped `security-reviewer` write guard runs far wider there
than under Claude Code. Full detail, including the settings block and
the traps, is in [README.md](README.md#tool-support); this repo is
authored and validated against Claude Code, and Copilot wiring is not
maintained here.

This file (root `CLAUDE.md`) is project scope only — it is **not**
deployed anywhere and loads only in sessions inside this repo.

## How the pieces trigger

- **Skills** (`skills/<group>/<name>/SKILL.md`) trigger three ways:
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

## Working on this repo

The workflow skills in `skills/workflow/` are this repo's own operating
procedure, not generic helpers:

- `/author-skill` — new skill end to end: coverage check, naming, doc
  drilling, a filled brief in `docs/handoffs/`, then the draft
  and post-draft checks. Stops at a linted draft; writes no fixtures
  and does not commit.
- `/learn` — fold a session learning into guidance that already
  exists (a `SKILL.md`, a rule, `claude/CLAUDE.md`).
- `/drift-audit` → `/drift-handoff` → `/drift-update` → `/commit` —
  the upstream-staleness pipeline. The audit is findings-only; the
  handoff writes briefs to `docs/audits/<date>/<source-id>/`; the
  update executes them in numbered order and stamps each done.
- `/commit` — split the working tree into logical commits.

`docs/audits/` is **gitignored generated output** with a short
half-life: working notes consumed by a follow-up run, then stale. A run
worth keeping is copied into `docs/handoffs/examples/`, not
un-ignored in place. Briefs there may quote paths from before a repo
reorganization — confirm a brief's evidence still exists before acting
on it.

Work that is scoped but not yet done lives in
`docs/handoffs/execute/`, and
**[execute/README.md](docs/handoffs/execute/README.md) is the
queue** — the only place the execution order lives, so read it before
starting a session here. Those briefs are *not* numbered the way
`/drift-handoff` numbers its output: they are committed, deleted
individually as each is spent, and cross-linked by filename, so the
filename has to stay stable and the ordering lives in the queue file.

## Branching and concurrent sessions

**Skill saves are live; nothing else is.** Each skill is its own
junction into *this working tree*, so a `SKILL.md` edit changes the
payload for **every session on this machine the moment it hits disk**,
committed or not. `rules`, `hooks`, `agents` and `mcp` were junctions
too until 2026-09-02 and are copies now, so they change only when
`scripts/link-claude.ps1` runs. That conversion removed most of the
hazard this section was written for — what remains applies to `skills/`
alone.

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
Reconsider if a second silent collision between concurrent sessions
happens anyway.

Note which skills that trigger actually covers. It is the **eight
workflow skills** — they are junctioned into user scope, so each
`SKILL.md` save is in every session's listing before the fixtures, the
queue row and the rule catch up. A **platform** skill is pruned from
user scope and junctioned nowhere, so authoring one changes no
session's payload at any point and needs no branch on these grounds.
Waves 12–14 are all platform-skill authoring.

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

**Integrate by fast-forward.** Rebase-merge is **disabled on this
repo** — the API answers `405 Rebase merges are not allowed` — and
squash would collapse the logical split `/commit` just made. So land a
branch locally rather than through the merge button:

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
  names user scope lacks.
- **So a worktree is either unnecessary or ineffective, with no case
  in between.** A platform skill is pruned from user scope, so editing
  it here changes no session's payload and needs no isolation — the
  workflow-only prune already *is* the isolation. A workflow skill is
  at user scope, and a worktree cannot override it.

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
  (pre-commit runs it too). Long detail goes in
  `skills/<group>/<name>/references/`, not SKILL.md. Skills
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
  `model`, `effort` and `disable-model-invocation` **explicitly**, even
  where the value is the default. The point is that the flip point for
  each lever is visible in the file instead of being an absent field.
  Current policy: the session default is `"effortLevel": "max"` in
  `claude/settings.json`. DMI is `false` everywhere (it is not used in
  this repo). `model: inherit` everywhere except `commit` (`sonnet`).
  `effort` is `max` on the seven workflow skills that drive this repo
  — `code-review`, `drift-audit`, `author-skill`, `test-skill`,
  `learn`, `drift-update`, `drift-handoff` — `xhigh` on `commit`, and
  left commented on all 41 platform skills, which therefore inherit
  `max`.
  Note what that means: *while the session actually sits at* `max`,
  only `commit` changes behaviour. But the session level is **live
  state, not the file** — it can be changed mid-session, nothing
  warns when it drifts, and the transcript is the only place the real
  value shows (observed 2026-09-01: both copies of `settings.json`
  read `max` while the session ran at `xhigh`, switched by accident
  while browsing the level list). Whenever it sits below `max` the
  seven pins start *raising* effort rather than matching it, which is
  exactly the *floor* they were written for. Platform skills stay
  unpinned **on purpose**: they auto-trigger alongside your real work,
  so an effort pin there governs your Fabric/Power BI turn rather than
  any discrete skill run. Five things to know before changing one.
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
  `model:` pin is **inert on the 27 conditional platform skills** — a
  `paths:` glob withholds them from the startup listing, so they are
  reached by path, and `/<name>` answers `Unknown command`. It is
  **live on the other 14**, which carry no glob and slash normally
  (measured with `/fabric-gotchas`, 2026-09-02 on 2.1.252). All 41 are
  `model: inherit` today, so nothing is broken, but a future pin is
  inert or effective depending on which half it lands in. Corrected
  2026-09-02 — this previously said all of them were inert because they
  "never" slash.
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
  prefer a path-scoped rule or a skill instead. After editing it,
  re-run `scripts/link-claude.ps1 -Force` to push it to
  `~/.claude/CLAUDE.md`.

## Validating a change

There is no automated test suite here — `pre-commit` covers frontmatter
and secrets, and nothing else is machine-checkable. Behavior is verified
by hand against the fixtures in `tests/`.

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
disjoint fixture sets that between them assert **all 27** conditional
skills in the payload — 10 pbip, 17 fabric.
Assertions live in each set's `expected_activations.md`, which is where
each figure is owned — **don't restate a total anywhere else.** This
count was duplicated into six files, checked by nothing, and by
2026-09-02 had drifted three ways at once (`tests/README.md` still said
19). Both sets stayed exhaustive throughout; only the prose rotted.
Derive it instead: `./scripts/test-activation.ps1 -Set fabric
-StaticOnly`, then `-Set pbip`. Recounted twice on 2026-09-02 — first to
25 after workstream E moved five skills from unconditional to
conditional, then to 26 when `fabric-operations-agent` landed, then to 27
when `fabric-ontology` did.

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

## Line endings

This repo auto-normalizes text and pins Windows scripts to CRLF and
shell scripts to LF in `.gitattributes`. The Fabric
portal-serialization guidance in
`claude/rules/fabric-git-serialization.md` applies to Fabric Git-synced
repos, **not** to this one.
