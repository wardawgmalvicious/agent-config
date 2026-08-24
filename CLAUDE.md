# agent-config: repo instructions

This repo is the source for the user's agent configuration (skills,
rules, hooks, subagents, settings). Files here are synced into tool
config directories; where an edit lands determines when it goes live:

| Repo path | Deployed to | Mechanism | Live when |
| --- | --- | --- | --- |
| `agents/`, `hooks/`, `rules/`, `skills/` | `~/.claude/<same>` | directory junction (`scripts/link-claude.ps1`) | immediately — same files |
| `global/CLAUDE.md` | `~/.claude/CLAUDE.md` | plain copy | after `scripts/link-claude.ps1 -Force` |
| `settings.json` | `~/.claude/settings.json` | plain copy, key-level merge | after `scripts/link-claude.ps1 -Force` |
| `skills/<name>/` | `~/.agents/skills/<name>` | per-skill junction (`scripts/link-copilot.ps1`) | immediately |

This file (root `CLAUDE.md`) is project scope only — it is **not**
deployed anywhere and loads only in sessions inside this repo.

## Editing conventions

- **Skills** — frontmatter `description` ≤ 1024 chars; lint with
  `uv run --with pyyaml scripts/lint-skills.py skills/<name>/SKILL.md`
  (pre-commit runs it too). Long detail goes in
  `skills/<name>/references/`, not SKILL.md. Skill edits don't
  reliably reload mid-session on Windows — restart the session to
  test a changed SKILL.md.
- **Rules** — `paths:` frontmatter globs control auto-load; a rule
  fires when a matching file enters session scope. Client repos can
  override any rule with `.claude/rules/<same-name>.md`.
- **`global/CLAUDE.md`** — loaded into *every* session on this
  machine. Keep it lean: machine environment and pointers only. If
  guidance has a narrower trigger (a file type, a product area),
  prefer a path-scoped rule or a skill instead.
- Capturing a session learning into skills/rules: use `/learn`.
  Committing: use `/commit`.

## Line endings

This repo pins `* text=auto eol=lf` in `.gitattributes`. The Fabric
portal-serialization guidance in
`rules/fabric-git-serialization.md` applies to Fabric Git-synced
repos, **not** to this one.
