# Agent Config

Personal configuration for coding agents: skills, subagents, coding
rules, hooks, MCP templates, and settings. Clone it anywhere; scoped
link scripts wire durable content into Claude Code and GitHub Copilot
without putting any tool's runtime directory under Git.

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

The top level splits by *audience*: a directory sits at the root when
more than one tool consumes it, and under `<tool>/` when only that tool
does. Adding a harness means adding one `<tool>/` directory, not
rearranging the root.

### Shared content

- [skills/](skills/) — 30+ skills: Fabric, Power BI / TMDL, and
  behavioral (code-review, drift-audit). Consumed by Claude Code and
  GitHub Copilot. See [skills/README.md](skills/README.md).
- [mcp/](mcp/) — Starter templates for global (user-scope) and project-
  scope Claude Code MCP server configs, plus a workspace-scope template
  for VS Code / GitHub Copilot.

### [claude/](claude/) — Claude Code payload

- [claude/agents/](claude/agents/) — 1 subagent
  ([security-reviewer](claude/agents/security-reviewer.md)).
- [claude/rules/](claude/rules/) — 10 path-scoped coding conventions
  (T-SQL, Spark SQL, Python/PySpark, PowerShell, Bash, KQL, DAX, M,
  TMDL, Fabric pipeline expressions) plus a Fabric Git-serialization
  rule; auto-load via `paths:` globs when matching files enter session
  scope.
- [claude/hooks/](claude/hooks/) — InstructionsLoaded and
  Skill-invocation loggers, and a security-reviewer memory-scope guard.
- [claude/CLAUDE.md](claude/CLAUDE.md) — User-scope instructions
  loaded in every session (machine environment, pointers to rules).
  Deployed to `~/.claude/CLAUDE.md` by the Claude link script.
- [claude/settings.json](claude/settings.json) — Claude Code settings
  (hook registry, enabled plugins, effort level, update channel).
  Deployed to `~/.claude/settings.json` by the link script, which
  compares it at the key level — runtime keys Claude Code writes to the
  live copy (like the model pin) stay untracked. Hook commands resolve
  via `$HOME/.claude/...`, which the junctions provide regardless of
  where the repo is cloned or how the repo side is arranged. Personal
  `permissions` entries live in `settings.local.json` (gitignored) —
  add your own there.

### Mechanism and supporting material

- [scripts/](scripts/) — link scripts (see [Install](#install)),
  pre-commit bootstrap, instructions-log query helper, SKILL.md
  frontmatter linter.
- [tests/](tests/) — Synthetic fixtures for validating the code-review
  skill and security-reviewer agent.
- [docs/handoff-briefs/](docs/handoff-briefs/) — Templates and worked
  examples for the brief-before-draft pattern (see
  [Handoff discipline](#handoff-discipline)).
- [CLAUDE.md](CLAUDE.md) — Project-scope instructions for working on
  this repo (sync model, authoring conventions). Not deployed; loads
  only in sessions inside this repo.
- [AGENTS.md](AGENTS.md) — Concise, independent contributor guide for
  this repo. It is project-scoped and is never deployed to user scope.
- [.github/copilot-instructions.md](.github/copilot-instructions.md) —
  Repository-wide custom instructions for GitHub Copilot (architecture,
  build/lint/test, conventions).
- [LICENSE](LICENSE) — MIT.
- [SECURITY.md](SECURITY.md) — security-issue reporting policy.
- [.gitignore](.gitignore) — runtime state, plugin install, secrets.
- [.pre-commit-config.yaml](.pre-commit-config.yaml) and [.gitleaks.toml](.gitleaks.toml)
  — pre-commit framework config (gitleaks and the SKILL.md / rules
  frontmatter linter at [scripts/lint-frontmatter.py](scripts/lint-frontmatter.py)).

## Tool support

The repo is structured so agnostic content and tool-specific wiring
stay separable:

- **Portable content** — [skills/](skills/) (the Agent Skills format is
  an open spec other tools are adopting), [claude/rules/](claude/rules/)
  bodies, [docs/](docs/), [tests/](tests/), and the MCP templates (MCP
  is cross-tool; only the config file shape differs per tool).
- **Claude Code-specific** — everything under [claude/](claude/):
  [settings.json](claude/settings.json), the hook event wiring in
  [claude/hooks/](claude/hooks/), the subagent frontmatter in
  [claude/agents/](claude/agents/), and the `paths:` auto-load
  frontmatter on rules (GitHub Copilot's `.instructions.md` `applyTo:`
  globs are the direct analog). Note the split: a rule's *body* is
  portable prose, but the file as it sits on disk is a Claude artifact,
  which is why it lives under `claude/`.
- **Instruction files are independent.** Root [AGENTS.md](AGENTS.md)
  is repository-scoped and is never deployed, and is not a mirror of
  root [CLAUDE.md](CLAUDE.md) or [claude/CLAUDE.md](claude/CLAUDE.md).
- **Other tools** — the repo carried a Codex payload and linker until
  it went unused; see the history around `codex/` if you want it back.
  Skills use the open Agent Skills format, so any tool that reads
  `SKILL.md` can consume [skills/](skills/) directly.
- **GitHub Copilot** — consumes most of this repo with no extra
  wiring. The VS Code agent surface reads Claude's user-scope paths as
  harness-agnostic defaults: `~/.claude/rules` for instructions,
  `~/.claude/CLAUDE.md` for always-on instructions,
  `~/.claude/settings.json` for hooks (it parses Claude Code's hook
  format), and `~/.claude/skills` for personal skills — all of which
  `link-claude.ps1` already populates. That is why there is no
  `copilot/` payload directory: Copilot is a second consumer of the
  Claude-format payload, not a separate one. Which paths are live is a
  settings decision — enable them under `chat.instructionsFilesLocations`,
  `chat.hookFilesLocations`, and `chat.agentFilesLocations`
  (`"~/.claude/agents": true` is what makes subagents work; a copy into
  `~/.copilot/agents` is *not* needed and only invites drift).
  [scripts/link-copilot.ps1](scripts/link-copilot.ps1) covers the one
  artifact that cannot be handled by settings: skills, into the shared
  `~/.agents/skills`, because `chat.agentSkillsLocations` leaves
  `~/.claude/skills` off and that directory holds other providers'
  skills. MCP is a workspace `.vscode/mcp.json` (see
  [mcp/README.md](mcp/README.md)).

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
   needed) at `~/.claude/{agents,hooks,mcp,rules,skills}`, sourced from
   `claude/agents`, `claude/hooks`, `claude/rules`, and the root
   `mcp/` and `skills/`. Mirrors `claude/CLAUDE.md`
   (→ `~/.claude/CLAUDE.md`) and `claude/settings.json` as plain copies.
   **Back up first if you already have a `~/.claude`** — the
   script refuses to replace real directories or drifted files without
   `-Force`, but review its warnings before forcing anything.

    ```powershell
    ./scripts/link-claude.ps1
    ```

3. Link skills into `~/.agents/skills` for GitHub Copilot, one
   junction per skill alongside any skills other providers have
   installed there. Skills are the only artifact needing this;
   everything else reaches Copilot through the `~/.claude` paths step 2
   created, once enabled in VS Code settings (see
   [Tool support](#tool-support)):

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
   helpers (`instructions-log`, `lint-frontmatter.py`) are callable by name.

**Notes:**

- Plugins, credentials, sessions, memory, caches, and other runtime
  state remain in each tool's real home directory, not in this repo.
  That separation is the point of scoped linking.
- This config is Windows-targeted (junctions, PowerShell link scripts,
  Git Bash for the shell hooks). Hook commands resolve via `$HOME` so
  they're portable across users on Windows, but Linux / macOS users
  will need to symlink manually and adjust paths — no promise it works
  elsewhere out of the box.

## Ongoing workflow

Edit files in place and commit like any other repo. Changes to the
junctioned directories (`claude/agents/`, `claude/hooks/`,
`claude/rules/`, `mcp/`, `skills/`) are
live immediately — the tools read the same files. Changes to
`claude/CLAUDE.md` or `claude/settings.json` need a
`scripts/link-claude.ps1` re-run to reach the live copies (the script also verifies everything else and
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
