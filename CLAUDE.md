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

Being a `<tool>/` payload says nothing about *how* it deploys: within
`claude/`, `agents/`, `hooks/`, and `rules/` are junctioned while
`CLAUDE.md` and `settings.json` are copied. Deployment mechanism is the
table below; directory placement is only about format.

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

# Query the hook observability logs (needs jq)
scripts/instructions-log today|reasons|paths|csv|skills|tail
```

```powershell
# THIS MACHINE'S DEFAULT — always use this form. Deploys the workflow
# skills only; fabric and powerbi are PRUNED from ~/.claude/skills.
# -Force also pushes claude/CLAUDE.md and claude/settings.json, which
# deploy by copy rather than junction.
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
skill listing.

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
| `claude/agents/`, `claude/hooks/`, `claude/rules/` | `~/.claude/agents`, `hooks`, `rules` | directory junction (`scripts/link-claude.ps1`) | immediately — same files |
| `claude/mcp/` | `~/.claude/mcp` | directory junction (`scripts/link-claude.ps1`) | immediately — same files |
| `skills/<group>/` | `~/.claude/skills/<name>` | one junction per skill (`scripts/link-claude.ps1`) | immediately — same files |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | plain copy | after `scripts/link-claude.ps1 -Force` |
| `claude/settings.json` | `~/.claude/settings.json` | plain copy, key-level merge | after `scripts/link-claude.ps1 -Force` |

Claude Code discovers a skill at `<skills-root>/<name>/SKILL.md` — one
level, no group directory in between — so `~/.claude/skills` is a real
directory holding one junction per skill, not a single junction for
`skills/`. (Claude Code doesn't read `~/.claude/mcp` at all; that
junction exists so the template-copy commands in
[claude/mcp/README.md](claude/mcp/README.md) resolve from a stable
path.)

The deployed names on the right are fixed by each tool and never
change, so repo-side moves are cheap: relocating payload under
`claude/` only changes a junction *target*, which
`scripts/link-claude.ps1` repairs on its next run with no `-Force`.
Hook commands in `settings.json` resolve via `$HOME/.claude/...`, so
they are unaffected by repo layout entirely.

`CLAUDE.md` and `settings.json` are copies rather than links **on
purpose** — don't "simplify" them into junctions for consistency. A
symlinked `~/.claude/settings.json` broke three times upstream in
mid-2026, once destructively: 2.1.247 had the Bash sandbox's
after-command cleanup *delete* a dotfile-managed symlink at that path.
The junctioned *directories* are a different story — their symlink-path
bugs (2.1.178, 2.1.198, 2.1.239) were fixed rather than being arguments
against junctions. The narrow claim is about the `settings.json` file.

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
- **Rules** (`claude/rules/*.md`) have no `name` or `description`, only
  `paths:` — they auto-load when a matching file enters session scope.
- **Hooks** (`claude/hooks/*.sh`) fire on events registered in
  `claude/settings.json`. Their commands are hardcoded to
  `$HOME/.claude/...` and only resolve because the link script
  junctions this repo there — **don't rewrite them to be
  repo-relative.**
- The `security-reviewer` subagent is scoped by an explicit tool
  allowlist plus the `PreToolUse` hook, which blocks any Edit/Write
  outside `~/.claude/agent-memory/security-reviewer/`.

## Working on this repo

The workflow skills in `skills/workflow/` are this repo's own operating
procedure, not generic helpers:

- `/author-skill` — new skill end to end: coverage check, naming, doc
  drilling, a filled brief in `docs/handoff-briefs/`, then the draft
  and post-draft checks. Stops at a linted draft; writes no fixtures
  and does not commit.
- `/learn` — fold a session learning into guidance that already
  exists (a `SKILL.md`, a rule, `claude/CLAUDE.md`).
- `/drift-audit` → `/drift-handoff` → `/drift-update` → `/commit` —
  the upstream-staleness pipeline. The audit is findings-only; the
  handoff writes briefs to `docs/drift-audit/<date>/<source-id>/`; the
  update executes them in numbered order and stamps each done.
- `/commit` — split the working tree into logical commits.

`docs/drift-audit/` is **gitignored generated output** with a short
half-life: working notes consumed by a follow-up run, then stale. A run
worth keeping is copied into `docs/handoff-briefs/examples/`, not
un-ignored in place. Briefs there may quote paths from before a repo
reorganization — confirm a brief's evidence still exists before acting
on it.

## Editing conventions

- **Skills** — frontmatter `description` ≤ 1536 chars, matching where
  Claude Code truncates the combined `description` + `when_to_use` text
  in the skill listing (configurable via `skillListingMaxDescChars`).
  Truncation is silent, so the linter gates at that point rather than
  below it. Keep this number and `DESCRIPTION_MAX` in
  `scripts/lint-frontmatter.py` identical. Note this is *past* the
  1024-char Agent Skills spec limit — a deliberate trade of format
  portability for trigger headroom, since the payload targets Claude
  Code and Copilot reads the same `~/.claude` paths. Lint with
  `uv run --with pyyaml scripts/lint-frontmatter.py skills/<group>/<name>/SKILL.md`
  (pre-commit runs it too). Long detail goes in
  `skills/<group>/<name>/references/`, not SKILL.md. Skills
  **hot-reload**: Claude Code watches skill directories and picks up
  changes in-session, and this works through this repo's junctions —
  verified 2026-08-31 on Claude Code 2.1.251 for skill add, skill
  removal, and `skillOverrides`. An in-place `description` edit is the
  one case not yet confirmed here, so restart before trusting a changed
  *trigger*. (Upstream fixed in-session skill reload in 2.1.216; this
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
procedure in [tests/skills/code-review/README.md](tests/skills/code-review/README.md)
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
- Compare against `expected_findings.md` rather than judging the output
  on its own — the fixtures encode what should be caught *and* what
  should not be.
- Exercise both the documented invocation and the refusal modes. A
  subagent that does the right thing but ignores its scope guard has
  failed.
- Confirm the fixtures are unmodified afterwards with `git status`. A
  run that edits its own inputs invalidates every later comparison.

## Line endings

This repo auto-normalizes text and pins Windows scripts to CRLF and
shell scripts to LF in `.gitattributes`. The Fabric
portal-serialization guidance in
`claude/rules/fabric-git-serialization.md` applies to Fabric Git-synced
repos, **not** to this one.
