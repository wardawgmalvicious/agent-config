# agent-config: repo instructions

This repo is the source for the user's coding-agent configuration
(skills, a subagent, coding rules, hooks, MCP server templates,
settings) — see [README.md](README.md) for the full picture. It's
written to be cherry-picked by any agentic tool, not only the ones the
user personally runs day to day (Claude Code, Codex, and GitHub Copilot).

Root `CLAUDE.md` and root `AGENTS.md` are independent project-scope
instructions and are never deployed. [claude/CLAUDE.md](claude/CLAUDE.md)
is Claude's user-scope payload; [codex/AGENTS.md](codex/AGENTS.md) is
the separate Codex user-scope payload.

Layout convention: flat top-level directories are the `~/.claude`
mirror (with `skills/` additionally shared to Codex and Copilot via
`~/.agents/skills`); `claude/` and `codex/` hold copy-deployed
per-tool payloads; `scripts/` is the shared mechanism.

## How this repo is structured

Files here are synced into tool config directories; where an edit
lands determines when it goes live:

| Repo path | Deployed to | Mechanism | Live when |
| --- | --- | --- | --- |
| `agents/`, `hooks/`, `mcp/`, `rules/`, `skills/` | `~/.claude/<same>` | directory junction (`scripts/link-claude.ps1`) | immediately — same files |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | plain copy | after `scripts/link-claude.ps1 -Force` |
| `settings.json` | `~/.claude/settings.json` | plain copy, key-level merge | after `scripts/link-claude.ps1 -Force` |
| `skills/<name>/` | `~/.agents/skills/<name>` | per-skill junction (`scripts/link-codex.ps1` or `scripts/link-copilot.ps1`) | immediately |
| `codex/AGENTS.md` | `$CODEX_HOME/AGENTS.md` | plain copy (`scripts/link-codex.ps1`) | after script run; `-Force` for drift |
| `codex/agents/*.toml` | `$CODEX_HOME/agents/*.toml` | individual plain copies (`scripts/link-codex.ps1`) | after script run; `-Force` for drift |
| `codex/prompts/*.md` | `$CODEX_HOME/prompts/*.md` | individual plain copies (`scripts/link-codex.ps1`) | after script run; `-Force` for drift |

(Claude Code doesn't read `~/.claude/mcp` itself — that junction exists
so the template-copy commands in [mcp/README.md](mcp/README.md) resolve
from a stable path. `codex/mcp/` and `codex/config-examples/` are
reference-only and never deployed.)

`scripts/link-codex.ps1` deliberately leaves `CODEX_HOME` real,
non-Git, and Codex-owned; runtime state and machine-local configuration
never flow into this repository.

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
  `uv run --with pyyaml scripts/lint-frontmatter.py rules/<name>.md`
  (pre-commit runs it too). A wrong glob has no error path — the rule
  just never loads — so the linter rejects the mistakes that silently
  narrow a pattern: a backslash separator, a leading `/`, and a bare
  `*.ext` with no `/` (which matches only repo-root files; `**/*.ext`
  matches those *and* nested ones).
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
`rules/fabric-git-serialization.md` applies to Fabric Git-synced
repos, **not** to this one.
