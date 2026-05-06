# Claude Config

Personal Claude Code configuration: skills, agents, coding rules, hooks,
MCP templates, and settings. This repo IS ~/.claude/ — clone or sync it
into your home directory; edit in place, commit, push.

## What this is

This repo is the live `~/.claude/` of a data professional working day-to-day
in Microsoft Fabric, Azure, and Power BI. It holds skills, a subagent,
path-scoped coding rules, hooks, MCP templates, a pre-commit linter, and
fixture tests — the same files Claude Code loads when I open a session.
Cherry-pick what's useful; the contents track active Microsoft data-
platform work, so expect drift as the platform moves.

## Status

Active personal configuration. The repo is browseable and cherry-pickable
— take what's useful, adapt freely. **No support, no semver, no
backward-compatibility commitment.** Things move; what worked yesterday
may have been rewritten. Skills and rules track Microsoft Fabric / Power
BI / Azure conventions, which themselves drift; verify against current
docs before relying on any specific guidance.

If you find this useful, that's the goal. If you find a bug, an issue
report is welcome but not guaranteed a response. Personal config first,
public artifact second.

## Contents

- [skills/](skills/) — 30 skills: 18 Fabric, 10 Power BI / TMDL, 2
  behavioral (code-review, drift-audit). See [skills/README.md](skills/README.md).
- [agents/](agents/) — 1 subagent ([security-reviewer](agents/security-reviewer.md)).
- [rules/](rules/) — 8 path-scoped coding conventions (T-SQL, Spark SQL,
  Python/PySpark, KQL, DAX, M, TMDL, Fabric pipeline expressions);
  auto-load via `paths:` globs when matching files enter session scope.
- [hooks/](hooks/) — InstructionsLoaded logger and a security-reviewer
  memory-scope guard.
- [mcp/](mcp/) — Starter templates for global (user-scope) and project-
  scope MCP server configs.
- [scripts/](scripts/) — pre-commit bootstrap, instructions-log query
  helper, SKILL.md frontmatter linter.
- [tests/](tests/) — Synthetic fixtures for validating the code-review
  skill and security-reviewer agent.
- [docs/handoff-briefs/](docs/handoff-briefs/) — Templates and worked
  examples for the brief-before-draft pattern (see
  [Handoff discipline](#handoff-discipline)).
- [CLAUDE.md](CLAUDE.md) — Personal-scope instructions; pointer to
  per-language rules.
- [settings.json](settings.json) — Claude Code settings (enabled
  plugins, hook registry, effort level, update channel). Hook commands
  resolve via `$HOME/.claude/...` so they're portable across users, but
  assume this repo is cloned at `~/.claude/`. Personal `permissions`
  entries live in `settings.local.json` (gitignored) — add your own
  there.
- [LICENSE](LICENSE) — MIT.
- [SECURITY.md](SECURITY.md) — security-issue reporting policy.
- [.gitignore](.gitignore) — runtime state, plugin install, secrets.
- [.pre-commit-config.yaml](.pre-commit-config.yaml) and [.gitleaks.toml](.gitleaks.toml)
  — pre-commit framework config (gitleaks + the SKILL.md frontmatter
  linter at [scripts/lint-skills.py](scripts/lint-skills.py)).

## Install

> **Cherry-picking?** Browse this repo on GitHub and copy individual
> files into your existing `~/.claude/`. No install needed. The
> numbered steps below are for cloning the whole thing.

<!-- -->

> **Back up first.** Cloning into `~/.claude/` overwrites any existing
> Claude Code configuration in your home directory. If you already have
> a `~/.claude/`, either move it aside (`mv ~/.claude ~/.claude.bak`)
> or clone this repo elsewhere and cherry-pick the pieces you want into
> your existing `~/.claude/`.

1. Clone into `~/.claude/`:

    ```bash
    # HTTPS (default — works for any GitHub user)
    git clone https://github.com/wardawgmalvicious/claude-config.git ~/.claude

    # SSH (requires GitHub SSH keys configured)
    git clone git@github.com:wardawgmalvicious/claude-config.git ~/.claude
    ```

2. Bootstrap pre-commit hooks (installs `pre-commit` via `uv` and runs
   it once across all files). **Requires
   [uv](https://docs.astral.sh/uv/) on PATH.** Skip this step if you
   only intend to read, not commit.

    ```bash
    cd ~/.claude && scripts/bootstrap-pre-commit
    ```

3. Add `~/.claude/scripts` to `PATH` so the helpers (`instructions-log`,
   `lint-skills.py`, `bootstrap-pre-commit`) are callable by name.

    Git Bash (`~/.bashrc`):

    ```bash
    export PATH="$HOME/.claude/scripts:$PATH"
    ```

    PowerShell (`$PROFILE`):

    ```powershell
    $env:PATH = "$HOME\.claude\scripts;$env:PATH"
    ```

**Notes:**

- Plugins, agent memory, runtime state (sessions, projects, todos,
  caches, file history), and secrets are gitignored — see
  [.gitignore](.gitignore). After cloning, plugins reinstall from
  scratch and any MCP servers requiring auth will need to reauth on
  first use.
- This config is Windows-targeted (Git Bash + the PowerShell tool in
  Claude Code). Hook commands resolve via `$HOME` so they're portable
  across users on Windows, but Linux / macOS users will need path
  adjustments — paths, shell shebangs, and the MCP `LOCALAPPDATA` env
  block all assume Windows. No promise it works elsewhere out of the
  box.

## Ongoing workflow

Edit files in place. This repo IS ~/.claude/. git add / commit / push
like any other repo. Skill edits don't reliably take effect mid-session
under Git Bash on Windows — restart the Claude Code session after
editing a SKILL.md to be safe.

## Handoff discipline

Skills and subagents in this repo are authored via a brief-before-draft
pattern: a chat-Claude session produces a structured handoff brief
covering frontmatter specs, body outline, portability caveats, and
post-draft validation steps; Claude Code then drafts the artifact from
the brief. The two surfaces specialize — chat-Claude has more context
and is better at structural proposal; Claude Code has filesystem access
and is better at drafting + iterating.

The pattern earns its place when an artifact has non-trivial behavioral
contracts — refusal patterns, severity rubrics, scope-enforced read-only
or destructive guards. For pure reference skills (canonical-answer
content), the pattern is overkill; real-use validation suffices.

Templates and worked examples live in [docs/handoff-briefs/](docs/handoff-briefs/):

- [skill-handoff-template.md](docs/handoff-briefs/skill-handoff-template.md)
  — fill-in template for new skills
- [subagent-handoff-template.md](docs/handoff-briefs/subagent-handoff-template.md)
  — fill-in template for new subagents
- [examples/](docs/handoff-briefs/examples/) — reference briefs derived
  from validated artifacts

The templates are internal tooling. Consumers cherry-picking from this
repo don't need to adopt the brief pattern; the templates are included
in case the discipline is useful elsewhere.

## License & security

- License: MIT — see [LICENSE](LICENSE).
- Security: see [SECURITY.md](SECURITY.md) for reporting issues.
