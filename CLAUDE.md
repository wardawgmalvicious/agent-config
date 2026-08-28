# agent-config: repo instructions

This repo is the source for the user's coding-agent configuration
(skills, a subagent, coding rules, hooks, MCP server templates,
settings) — see [README.md](README.md) for the full picture. It's
written to be cherry-picked by any agentic tool, not only the ones the
user personally runs day to day (Claude Code and GitHub Copilot).

This file describes conventions for working *on* this repo itself, not
its deployed content; [global/CLAUDE.md](global/CLAUDE.md) is the
machine-wide instructions payload. Neither has an `AGENTS.md` mirror —
a tool that wants that filename copies and adapts one of these, which
is work a hand-synced twin never saved anyone.

## How this repo is structured

Files here are synced into tool config directories; where an edit
lands determines when it goes live:

| Repo path | Deployed to | Mechanism | Live when |
| --- | --- | --- | --- |
| `agents/`, `hooks/`, `mcp/`, `rules/`, `skills/` | `~/.claude/<same>` | directory junction (`scripts/link-claude.ps1`) | immediately — same files |
| `global/CLAUDE.md` | `~/.claude/CLAUDE.md` | plain copy | after `scripts/link-claude.ps1 -Force` |
| `settings.json` | `~/.claude/settings.json` | plain copy, key-level merge | after `scripts/link-claude.ps1 -Force` |
| `skills/<name>/` | `~/.agents/skills/<name>` | per-skill junction (`scripts/link-copilot.ps1`) | immediately |

(Claude Code doesn't read `~/.claude/mcp` itself — that junction exists
so the template-copy commands in [mcp/README.md](mcp/README.md) resolve
from a stable path.)

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
- **`global/CLAUDE.md`** — loaded into *every* session on this
  machine. Keep it lean: machine environment and pointers only. If
  guidance has a narrower trigger (a file type, a product area),
  prefer a path-scoped rule or a skill instead. After editing it,
  re-run `scripts/link-claude.ps1 -Force` to push it to
  `~/.claude/CLAUDE.md`.
- Capturing a session learning into skills/rules: use `/learn`.
  Committing: use `/commit`.

## Line endings

This repo pins `* text=auto eol=lf` in `.gitattributes`. The Fabric
portal-serialization guidance in
`rules/fabric-git-serialization.md` applies to Fabric Git-synced
repos, **not** to this one.
