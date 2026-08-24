# agent-config: repo instructions

This repo is the source for the author's coding-agent configuration
(skills, a subagent, coding rules, hooks, MCP server templates,
settings) — see [README.md](README.md) for the full picture. It's
written to be cherry-picked by any agentic tool, not only the ones the
author personally runs day to day (Claude Code and GitHub Copilot).

This file mirrors root [CLAUDE.md](CLAUDE.md) — both describe
conventions for working *on* this repo itself, not its deployed
content, for readers whose tool looks for `AGENTS.md` rather than
`CLAUDE.md`. [global/AGENTS.md](global/AGENTS.md) similarly mirrors
[global/CLAUDE.md](global/CLAUDE.md) — the portable, machine-wide
instructions payload. **Keep each pair in sync by hand** — editing one
without the other is how these drift.

## How this repo is structured

Files here are synced into tool config directories; where an edit
lands determines when it goes live. The deployment mechanism below
(directory junctions into `~/.claude`, key-level `settings.json`
merges) is Claude Code's own tooling — see
[scripts/link-claude.ps1](scripts/link-claude.ps1) for the mechanics.
If you're cherry-picking content for a different tool, ignore the
deployment column and copy the [skills/](skills/), [rules/](rules/),
[agents/](agents/), or [hooks/](hooks/) content you want directly into
wherever your tool reads config from.

| Repo path | Deployed to | Mechanism | Live when |
| --- | --- | --- | --- |
| `agents/`, `hooks/`, `mcp/`, `rules/`, `skills/` | `~/.claude/<same>` | directory junction (`scripts/link-claude.ps1`) | immediately — same files |
| `global/CLAUDE.md` | `~/.claude/CLAUDE.md` | plain copy | after `scripts/link-claude.ps1 -Force` |
| `settings.json` | `~/.claude/settings.json` | plain copy, key-level merge | after `scripts/link-claude.ps1 -Force` |
| `skills/<name>/` | `~/.agents/skills/<name>` | per-skill junction (`scripts/link-copilot.ps1`) | immediately |

(Claude Code doesn't read `~/.claude/mcp` itself — that junction exists
so the template-copy commands in [mcp/README.md](mcp/README.md) resolve
from a stable path.)

This file (root `AGENTS.md`, like root `CLAUDE.md`) is project scope
only — it is **not** deployed anywhere and is read directly by any
`AGENTS.md`-aware tool working inside this repo.

## Editing conventions

- **Skills** — frontmatter `description` ≤ 1024 chars; lint with
  `uv run --with pyyaml scripts/lint-skills.py skills/<name>/SKILL.md`
  (pre-commit runs it too). Long detail goes in
  `skills/<name>/references/`, not `SKILL.md`. Skill edits don't
  reliably reload mid-session on Windows — restart the session to
  test a changed `SKILL.md`.
- **Rules** — `paths:` frontmatter globs control auto-load in tools
  that support it (Claude Code natively; GitHub Copilot's
  `.instructions.md` `applyTo:` globs are the direct analog). A client
  repo can override any rule with its own
  `.claude/rules/<same-name>.md`.
- **The global pair (`global/CLAUDE.md` / `global/AGENTS.md`)** — meant
  to be loaded into *every* session on the author's machine, regardless
  of repo. Keep both lean: machine environment and pointers only. If
  guidance has a narrower trigger (a file type, a product area), prefer
  a path-scoped rule or a skill instead. After editing
  `global/CLAUDE.md`, re-run `scripts/link-claude.ps1 -Force` to push
  it to `~/.claude/CLAUDE.md` — and mirror every edit across both
  members of the pair.
- Capturing a session learning into skills/rules: use the `learn`
  skill. Committing: use the `commit` skill.

## Line endings

This repo pins `* text=auto eol=lf` in `.gitattributes`. The Fabric
portal-serialization guidance in
`rules/fabric-git-serialization.md` applies to Fabric Git-synced
repos, **not** to this one.
