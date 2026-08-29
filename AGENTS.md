# Repository Guidelines

## Project Structure & Module Organization

This is an agent-configuration repository, not an application; it has no
runtime or build artifact. Add reusable guidance under
`skills/<name>/SKILL.md`, with supporting detail in `references/`, `scripts/`,
or `assets/`. The top level splits by audience: a directory sits at the
root when more than one tool consumes it (`skills/`, `mcp/`) and under
`<tool>/` when only that tool does. Everything Claude Code reads is under
`claude/` — path-scoped language conventions in `claude/rules/`, subagents
in `claude/agents/`, lifecycle hooks in `claude/hooks/`, plus user-scope
`claude/CLAUDE.md` and `claude/settings.json`. GitHub Copilot consumes that
same payload through its own VS Code settings and so has no payload directory
of its own. Maintenance and linking utilities are in `scripts/`, while MCP
templates and handoff guidance are in `mcp/` and `docs/`. Manual behavioral
fixtures live under `tests/skills/` and `tests/agents/`.

## Setup, Lint, and Development Commands

- `scripts/bootstrap-pre-commit` — from Git Bash, install pre-commit with
  `uv`, wire the Git hook, and validate the repository.
- `pre-commit run --all-files` — run frontmatter validation and gitleaks.
- `pre-commit run lint-skills` or `pre-commit run lint-rules` — run one
  local validator while iterating.
- `uv run --with pyyaml scripts/lint-frontmatter.py skills/commit/SKILL.md`
  — lint one file directly.
- `./scripts/link-claude.ps1` and `./scripts/link-copilot.ps1` — verify
  tool-specific wiring. The Copilot linker manages only the shared skill
  junctions; everything else reaches Copilot through the `~/.claude`
  paths the Claude linker creates, enabled via VS Code's
  `chat.*Locations` settings.

## Coding Style & Naming Conventions

Follow the applicable `claude/rules/coding-<language>.md`. Python,
PowerShell, and Bash use four-space indentation and an approximately
100-column soft limit. PowerShell functions use approved `Verb-Noun` names;
Python uses `lower_snake_case` and type hints. Name skills with lowercase
kebab-case (`fabric-auth`, `code-review`) and rules as
`coding-<language>.md`. Keep YAML frontmatter valid and concise; move long
skill detail into `references/`. Respect `.gitattributes`: PowerShell/batch
files use CRLF, while shell scripts use LF.

## Testing Guidelines

There is no automated test suite or coverage percentage. After changing a
skill, rule, agent, or enforcement hook, follow the relevant procedure in
`tests/skills/code-review/README.md` or
`tests/agents/security-reviewer/README.md`. Run tests in a fresh agent session,
compare results with `expected_findings.md`, exercise the documented invocation
and refusal modes, and confirm fixtures remain unmodified with `git status`.

## Commit & Pull Request Guidelines

Use Conventional Commits, for example `feat(rules): add KQL conventions` or
`docs: clarify setup`. Keep the summary imperative and lowercase, make each
commit one logical change, and explain motivation or non-obvious decisions in
the body. Pull requests should describe intent, list affected paths and
validation performed, link relevant issues, and pass pre-commit CI. Screenshots
are only useful for visual/report assets. Never commit credentials, runtime
logs, agent memory, or `settings.local.json`; report vulnerabilities through
`SECURITY.md`.
