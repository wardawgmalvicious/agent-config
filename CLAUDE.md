# agent-config: repo instructions

This repo is the source for the user's coding-agent configuration
(skills, a subagent, coding rules, hooks, MCP server templates,
settings) — see [README.md](README.md) for the full picture. It's
written to be cherry-picked by any agentic tool, not only the ones the
user personally runs day to day (Claude Code and GitHub Copilot).

Root `CLAUDE.md` and root `AGENTS.md` are independent project-scope
instructions and are never deployed. [claude/CLAUDE.md](claude/CLAUDE.md)
is Claude's user-scope payload.

Layout convention: **`<tool>/` names the payload's *format*, not its
only consumer.** `claude/` holds everything written in Claude Code's
formats — subagent frontmatter, `paths:`-scoped rules, hook event
wiring, user-scope `CLAUDE.md` and `settings.json`. GitHub Copilot
reads most of it too (see below), so "Claude-only" would be wrong;
"Claude-format" is the useful line. Top-level directories hold content
in formats no single tool owns: `skills/` (the open Agent Skills
format) and `mcp/` (whose templates cover both Claude Code and VS Code
/ Copilot schemas). A `codex/` payload lived here until Codex went
unused; it is in the history if it is ever wanted back.

`claude/CLAUDE.md` is also why the payload cannot simply live at the
repo root: root `CLAUDE.md` is already this file, project scope. Two
files want that name, so at least one needs a directory — and once one
does, keeping the whole payload together is the consistent choice. `scripts/`, `docs/`, and `tests/` are the
shared mechanism and supporting material.

Being a `<tool>/` payload says nothing about *how* it deploys: within
`claude/`, `agents/`, `hooks/`, and `rules/` are junctioned while
`CLAUDE.md` and `settings.json` are copied. Deployment mechanism is the
table below; directory placement is only about which tool consumes the
content.

## How this repo is structured

Files here are synced into tool config directories; where an edit
lands determines when it goes live:

| Repo path | Deployed to | Mechanism | Live when |
| --- | --- | --- | --- |
| `claude/agents/`, `claude/hooks/`, `claude/rules/` | `~/.claude/agents`, `hooks`, `rules` | directory junction (`scripts/link-claude.ps1`) | immediately — same files |
| `mcp/`, `skills/` | `~/.claude/<same>` | directory junction (`scripts/link-claude.ps1`) | immediately — same files |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | plain copy | after `scripts/link-claude.ps1 -Force` |
| `claude/settings.json` | `~/.claude/settings.json` | plain copy, key-level merge | after `scripts/link-claude.ps1 -Force` |
| `skills/<name>/` | `~/.agents/skills/<name>` | per-skill junction (`scripts/link-copilot.ps1`) | immediately |

(Claude Code doesn't read `~/.claude/mcp` itself — that junction exists
so the template-copy commands in [mcp/README.md](mcp/README.md) resolve
from a stable path.)

The deployed names on the right are fixed by each tool and never
change, so repo-side moves are cheap: relocating payload under
`claude/` only changes a junction *target*, which
`scripts/link-claude.ps1` repairs on its next run with no `-Force`.
Hook commands in `settings.json` resolve via `$HOME/.claude/...`, so
they are unaffected by repo layout entirely.

GitHub Copilot needs no payload of its own. The VS Code agent surface
reads `~/.claude/rules`, `~/.claude/CLAUDE.md`, `~/.claude/agents`, and
`~/.claude/settings.json` (Claude's hook format) directly — which of
them are live is a `chat.*Locations` settings decision, not a file
placement one. `scripts/link-copilot.ps1` therefore handles only
skills, which cannot be reached that way: `chat.agentSkillsLocations`
enables `~/.agents/skills` and leaves `~/.claude/skills` off, and that
directory is shared with other providers so it cannot be junctioned
wholesale.

This file (root `CLAUDE.md`) is project scope only — it is **not**
deployed anywhere and loads only in sessions inside this repo.

## How the pieces trigger

Absorbed from a former `.github/copilot-instructions.md`, which
duplicated this file and `AGENTS.md` and was deleted rather than kept
in sync a third time.

- **Skills** (`skills/<name>/SKILL.md`) trigger three ways:
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

Linting gotchas worth keeping: PowerShell does **not** glob-expand args
for external commands, so `skills/*/SKILL.md` passes through literally
and fails — expand first with
`$files = Get-ChildItem skills -Filter SKILL.md -Recurse | % FullName`.
`tests/` and `docs/` are gitleaks-allowlisted because fixtures
intentionally contain fake credential-shaped strings.

## Editing conventions

- **Skills** — frontmatter `description` ≤ 1024 chars; lint with
  `uv run --with pyyaml scripts/lint-frontmatter.py skills/<name>/SKILL.md`
  (pre-commit runs it too). Long detail goes in
  `skills/<name>/references/`, not SKILL.md. Skill edits don't
  reliably reload mid-session on Windows — restart the session to
  test a changed SKILL.md.
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
- Capturing a session learning into skills/rules: use `/learn`.
  Committing: use `/commit`.

## Line endings

This repo auto-normalizes text and pins Windows scripts to CRLF and
shell scripts to LF in `.gitattributes`. The Fabric
portal-serialization guidance in
`claude/rules/fabric-git-serialization.md` applies to Fabric Git-synced
repos, **not** to this one.
