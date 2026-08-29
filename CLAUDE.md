# agent-config: repo instructions

This repo is the source for the user's coding-agent configuration
(skills, a subagent, coding rules, hooks, MCP server templates,
settings) — see [README.md](README.md) for the full picture. It's
written to be cherry-picked by any agentic tool, not only the ones the
user personally runs day to day (Claude Code and GitHub Copilot).

Root `CLAUDE.md` and root `AGENTS.md` are independent project-scope
instructions and are never deployed. [claude/CLAUDE.md](claude/CLAUDE.md)
is Claude's user-scope payload.

Layout convention: **top-level directories hold content more than one
tool consumes** (`skills/`, linked to Claude and shared to Copilot via
`~/.agents/skills`; `mcp/`, whose templates cover Claude Code and VS
Code / Copilot). **A `<tool>/` directory holds that tool's payload and
nothing else** — only `claude/` today, a new one per harness added
later. A `codex/` payload lived here until Codex went unused; it is in
the history if it is ever wanted back. `scripts/`, `docs/`, and `tests/` are the
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
| `claude/agents/*.md` | `~/.copilot/agents/*.md` | individual plain copies (`scripts/link-copilot.ps1`) | after script run; `-Force` for drift |

(Claude Code doesn't read `~/.claude/mcp` itself — that junction exists
so the template-copy commands in [mcp/README.md](mcp/README.md) resolve
from a stable path.)

The deployed names on the right are fixed by each tool and never
change, so repo-side moves are cheap: relocating payload under
`claude/` only changes a junction *target*, which
`scripts/link-claude.ps1` repairs on its next run with no `-Force`.
Hook commands in `settings.json` resolve via `$HOME/.claude/...`, so
they are unaffected by repo layout entirely.

`scripts/link-copilot.ps1` deliberately leaves `~/.copilot` real,
non-Git, and Copilot-owned, managing only the named agent files;
runtime state and machine-local configuration never flow into this
repository.

This file (root `CLAUDE.md`) is project scope only — it is **not**
deployed anywhere and loads only in sessions inside this repo.

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
