# Agent Config

Personal configuration for coding agents: skills, subagents, coding
rules, hooks, MCP templates, and settings. Clone it anywhere; link
scripts wire it into each tool's config directory — Claude Code via
`~/.claude`, GitHub Copilot via `~/.agents`.

## What this is

This repo is the live agent configuration of a data professional
working day-to-day in Microsoft Fabric, Azure, and Power BI. It holds
skills, a subagent, path-scoped coding rules, hooks, MCP templates, a
pre-commit linter, and fixture tests — the same files my agents load
when I open a session. Cherry-pick what's useful; the contents track
active Microsoft data-platform work, so expect drift as the platform
moves.

The repo started life as a Claude Code config cloned directly into
`~/.claude`. It now lives outside any tool's config directory and is
linked in per tool, which keeps runtime state out of the working tree
and lets the same skill content serve more than one agent. The
*content* is still Claude-flavored — see
[Tool support](#tool-support) for what each tool consumes.

## Status

Active personal configuration. The repo is browseable and cherry-pickable
— take what's useful, adapt freely. **No support, no semver, no
backward-compatibility commitment.** Things move; what worked yesterday
may have been rewritten. Skills and rules track Microsoft Fabric / Power
BI / Azure conventions, which themselves drift; verify against current
docs before relying on any specific guidance.

If you find this useful, that's the goal. If you find a bug, an issue
report is welcome but not guaranteed a response. Personal config first,
public artifact second — see [Tags](#tags) for per-artifact
reuse-readiness.

## Tags

Each artifact in this repo carries one of three reuse-readiness tags:

- **personal** — Default. In this repo because I use it; not validated
  for general reuse. Treat as reference, not a recommendation.
- **publishable** — Real-use validated AND content-reviewed for general
  reuse.
- **client-only** — Reserved for client-scoped artifacts; by design
  these don't live in this repo.

**All artifacts are currently `personal`.** The taxonomy is documented
for future use as individual artifacts validate through real-use and
earn promotion. Promoting to `publishable` is per-artifact and
requires content review, not just a tag flip.

The following four skills haven't been real-use tested yet — extra
unproven, even by `personal` standards:

- [fabric-eventhouse](skills/fabric-eventhouse/)
- [fabric-eventstream](skills/fabric-eventstream/)
- [fabric-mlv](skills/fabric-mlv/)
- [fabric-variable-library](skills/fabric-variable-library/)

## Contents

- [skills/](skills/) — 30+ skills: Fabric, Power BI / TMDL, and
  behavioral (code-review, drift-audit). See [skills/README.md](skills/README.md).
- [agents/](agents/) — 1 subagent ([security-reviewer](agents/security-reviewer.md)).
- [rules/](rules/) — 10 path-scoped coding conventions (T-SQL, Spark SQL,
  Python/PySpark, PowerShell, Bash, KQL, DAX, M, TMDL, Fabric pipeline
  expressions) plus a Fabric Git-serialization rule; auto-load via
  `paths:` globs when matching files enter session scope.
- [hooks/](hooks/) — InstructionsLoaded logger and a security-reviewer
  memory-scope guard.
- [mcp/](mcp/) — Starter templates for global (user-scope) and project-
  scope Claude Code MCP server configs, plus a workspace-scope template
  for VS Code / GitHub Copilot.
- [scripts/](scripts/) — link scripts (see [Install](#install)),
  pre-commit bootstrap, instructions-log query helper, SKILL.md
  frontmatter linter.
- [tests/](tests/) — Synthetic fixtures for validating the code-review
  skill and security-reviewer agent.
- [docs/handoff-briefs/](docs/handoff-briefs/) — Templates and worked
  examples for the brief-before-draft pattern (see
  [Handoff discipline](#handoff-discipline)).
- [global/CLAUDE.md](global/CLAUDE.md) — User-scope instructions
  loaded in every session (machine environment, pointers to rules).
  Deployed to `~/.claude/CLAUDE.md` by the link script. On an
  `AGENTS.md`-based tool, copy it to wherever that tool reads a
  personal, cross-repo instructions file — it is machine-specific (a
  hardcoded clone path, a `uv`-only Python setup), so adapt it rather
  than taking it verbatim.
- [CLAUDE.md](CLAUDE.md) — Project-scope instructions for working on
  this repo (sync model, authoring conventions). Not deployed; loads
  only in sessions inside this repo.
- [.github/copilot-instructions.md](.github/copilot-instructions.md) —
  Repository-wide custom instructions for GitHub Copilot (architecture,
  build/lint/test, conventions).
- [settings.json](settings.json) — Claude Code settings (hook registry,
  enabled plugins, effort level, update channel). Deployed to
  `~/.claude/settings.json` by the link script, which compares it at
  the key level — runtime keys Claude Code writes to the live copy
  (like the model pin) stay untracked. Hook commands resolve via
  `$HOME/.claude/...`, which the junctions provide regardless of where
  the repo is cloned. Personal `permissions` entries live in
  `settings.local.json` (gitignored) — add your own there.
- [LICENSE](LICENSE) — MIT.
- [SECURITY.md](SECURITY.md) — security-issue reporting policy.
- [.gitignore](.gitignore) — runtime state, plugin install, secrets.
- [.pre-commit-config.yaml](.pre-commit-config.yaml) and [.gitleaks.toml](.gitleaks.toml)
  — pre-commit framework config (gitleaks + the SKILL.md frontmatter
  linter at [scripts/lint-skills.py](scripts/lint-skills.py)).

## Tool support

The repo is structured so agnostic content and tool-specific wiring
stay separable:

- **Portable content** — [skills/](skills/) (the Agent Skills format is
  an open spec other tools are adopting), [rules/](rules/) bodies,
  [docs/](docs/), [tests/](tests/), and the MCP templates (MCP is
  cross-tool; only the config file shape differs per tool).
- **Claude Code-specific** — [settings.json](settings.json), the hook
  event wiring in [hooks/](hooks/), the subagent frontmatter in
  [agents/](agents/), and the `paths:` auto-load frontmatter on rules
  (GitHub Copilot's `.instructions.md` `applyTo:` globs are the direct
  analog).
- **No `AGENTS.md` mirrors — deliberately.** GitHub Copilot (CLI, VS
  Code, cloud agent) already treats a `CLAUDE.md` as equivalent to
  `AGENTS.md` for its "Agent instructions" tier, so the filename buys
  nothing there. For every other tool, both instruction files here need
  editing before they'd serve anyone else anyway: root
  [CLAUDE.md](CLAUDE.md) describes working *on* this repo, and
  [global/CLAUDE.md](global/CLAUDE.md) hardcodes a clone path and this
  machine's Python setup. A tool that wants `AGENTS.md` by name is one
  `cp` away, and the copy has to be adapted regardless — so hand-synced
  twins bought nothing but drift. Copy either file and make it yours.
- **GitHub Copilot** — consumes the skills via per-skill links into
  `~/.agents/skills` (see [scripts/link-copilot.ps1](scripts/link-copilot.ps1)),
  plus a workspace `.vscode/mcp.json` for MCP servers (see
  [mcp/README.md](mcp/README.md)). Rules, hooks, and settings are not
  wired into Copilot.

"Agnostic" here means *structured so other tools can consume it* — the
content is written for and validated with Claude Code first.

## Install

> **Cherry-picking?** Browse this repo on GitHub and copy individual
> files into your own agent config. No install needed. The numbered
> steps below wire up the whole thing.

1. Clone anywhere (the link scripts resolve the repo location from
   their own path):

    ```bash
    # HTTPS (default — works for any GitHub user)
    git clone https://github.com/wardawgmalvicious/agent-config.git

    # SSH (requires GitHub SSH keys configured)
    git clone git@github.com:wardawgmalvicious/agent-config.git
    ```

2. Link into Claude Code. Creates directory junctions (no elevation
   needed) for `agents/`, `hooks/`, `mcp/`, `rules/`, and `skills/`
   under `~/.claude`, and mirrors `global/CLAUDE.md` (→ `~/.claude/CLAUDE.md`)
   and `settings.json` as plain copies. **Back up first if you already have a `~/.claude`** — the
   script refuses to replace real directories or drifted files without
   `-Force`, but review its warnings before forcing anything.

    ```powershell
    ./scripts/link-claude.ps1
    ```

3. (Optional) Link skills into GitHub Copilot's `~/.agents/skills`,
   one junction per skill, alongside any skills other providers have
   installed there:

    ```powershell
    ./scripts/link-copilot.ps1
    ```

4. Bootstrap pre-commit hooks (installs `pre-commit` via `uv` and runs
   it once across all files). **Requires
   [uv](https://docs.astral.sh/uv/) on PATH.** Skip this step if you
   only intend to read, not commit.

    ```bash
    cd agent-config && scripts/bootstrap-pre-commit
    ```

5. (Optional) Add the repo's `scripts/` directory to `PATH` so the
   helpers (`instructions-log`, `lint-skills.py`) are callable by name.

**Notes:**

- Plugins, agent memory, and Claude Code runtime state live in
  `~/.claude`, not in this repo — nothing to gitignore away, nothing
  to leak into commits. That separation is the point of linking
  instead of cloning into the config directory.
- This config is Windows-targeted (junctions, PowerShell link scripts,
  Git Bash for the shell hooks). Hook commands resolve via `$HOME` so
  they're portable across users on Windows, but Linux / macOS users
  will need to symlink manually and adjust paths — no promise it works
  elsewhere out of the box.

## Ongoing workflow

Edit files in place and commit like any other repo. Changes to the
junctioned directories (`agents/`, `hooks/`, `mcp/`, `rules/`,
`skills/`) are
live immediately — the tools read the same files. Changes to
`global/CLAUDE.md` or `settings.json` need a `scripts/link-claude.ps1`
re-run to reach the live copies (the script also verifies everything else and
exits non-zero if any link or mirror needs attention — including after
moving or renaming the repo folder, which it repairs automatically).

Skill edits don't reliably take effect mid-session under Git Bash on
Windows — restart the Claude Code session after editing a SKILL.md to
be safe.

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
