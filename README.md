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

- [fabric-eventhouse](skills/fabric/fabric-eventhouse/)
- [fabric-eventstream](skills/fabric/fabric-eventstream/)
- [fabric-mlv](skills/fabric/fabric-mlv/)
- [fabric-variable-library](skills/fabric/fabric-variable-library/)

## Contents

The top level splits by *audience*: a directory sits at the root when
more than one tool consumes it, and under `<tool>/` when only that tool
does. Adding a harness means adding one `<tool>/` directory, not
rearranging the root.

### Shared content

- [skills/](skills/) — 30+ skills: Fabric, Power BI / TMDL, and
  behavioral (code-review, drift-audit). Consumed by Claude Code and
  GitHub Copilot. See [skills/README.md](skills/README.md).

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
- [claude/mcp/](claude/mcp/) — MCP server templates in Claude's
  `mcpServers` schema, one per shareable scope: user (`~/.claude.json`)
  and project (a repo's `.mcp.json`). Both carry only servers that
  actually connect from Claude Code. See
  [claude/mcp/README.md](claude/mcp/README.md) for which scope a server
  belongs in — the test is whether it is bound to a workload, not how
  often you use it.
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
  bodies, [docs/](docs/), and [tests/](tests/). The MCP templates are
  the edge case: the protocol is cross-tool but the config schemas are
  not, so each template lives with the payload whose schema it is
  written in.
- **Claude Code-specific** — everything under [claude/](claude/):
  [settings.json](claude/settings.json), the hook event wiring in
  [claude/hooks/](claude/hooks/), the subagent frontmatter in
  [claude/agents/](claude/agents/), and the `paths:` auto-load
  frontmatter on rules (GitHub Copilot's `.instructions.md` `applyTo:`
  globs are the direct analog). Note the split: a rule's *body* is
  portable prose, but the file as it sits on disk is a Claude artifact,
  which is why it lives under `claude/`.
- **One instruction file per scope.** Root [CLAUDE.md](CLAUDE.md) is
  project scope and never deployed; [claude/CLAUDE.md](claude/CLAUDE.md)
  is the user-scope payload. They are not mirrors of each other. A root
  `AGENTS.md` was carried alongside them until it went unread — Codex
  was dropped and VS Code's `chat.useAgentsMdFile` is off — and its one
  unique section, the fixture-validation procedure, now lives in root
  `CLAUDE.md`. Reinstate it from history if a tool that reads
  `AGENTS.md` comes back; the content is not Claude-specific.
- **Other tools** — the repo carried a Codex payload and linker until
  it went unused; see the history around `codex/` if you want it back.
  Skills use the open Agent Skills format, so any tool that reads
  `SKILL.md` can consume [skills/](skills/) directly.
- **GitHub Copilot** — consumes this repo with **almost no wiring and
  no linker of its own**. The VS Code agent surface reads Claude's
  user-scope paths directly: `~/.claude/rules` for instructions,
  `~/.claude/skills` for personal skills, `~/.claude/settings.json` for
  hooks (it parses Claude Code's hook format), `~/.claude/CLAUDE.md` for
  always-on instructions, and `~/.claude/agents` for subagents once
  `chat.agentFilesLocations` points at it — all of which
  `link-claude.ps1` already populates. That is why there is no
  `copilot/` payload directory: Copilot is a second consumer of the
  Claude-format payload, not a separate one. The rest is a settings
  decision:

    ```jsonc
    // Checked 2026-08-29 against microsoft/vscode-docs@28f76f5f.
    // Only the agents entry is load-bearing: ~/.claude/agents is not a
    // documented default (VS Code's user-profile default is
    // ~/.copilot/agents). The other three ~/.claude paths are already
    // documented defaults, so listing them is belt-and-braces.
    "chat.instructionsFilesLocations": { "~/.claude/rules": true },
    "chat.agentFilesLocations":        { "~/.claude/agents": true },
    "chat.agentSkillsLocations":       { "~/.claude/skills": true },
    "chat.hookFilesLocations":         { "~/.claude/settings.json": true },
    // chat.useClaudeMdFile governs ~/.claude/CLAUDE.md and already
    // defaults to true — no entry needed.
    ```

    Three traps. `chat.instructionsFilesLocations` accepts **folders
    only** — an entry for `~/.claude/CLAUDE.md` is silently ignored,
    and because `chat.useClaudeMdFile` loads that file anyway, the dead
    setting looks like it worked. VS Code also **omits any setting left
    at its default** when it writes `settings.json`, so
    `chat.useClaudeMdFile` vanishes from the file when set to `true` and
    only appears when set to `false` — absent means on, not unset. And
    no copy into `~/.copilot/agents` or `~/.agents/skills` is needed;
    both only invite drift. MCP is a workspace `.vscode/mcp.json` (see
    [.vscode/README.md](.vscode/README.md)).

    Copilot parses the Claude hook format, not its semantics. Matchers
    are read and **ignored**, so a matcher-scoped hook fires on every
    tool call; tool input properties are camelCase
    (`tool_input.filePath`, not `tool_input.file_path`); and tool names
    differ (`create_file`, `replace_string_in_file`). The
    `security-reviewer` write guard is matcher-scoped, so under Copilot
    it runs far wider than it does under Claude Code.

    Sessions on **Agent Host** read user-level instructions and agents
    from harness-agnostic folders (`~/.copilot/instructions`,
    `~/.claude/rules`, `~/.copilot/agents`) instead of VS Code profile
    user data — the change that removed the "or your user data"
    fallback from both location tables in mid-2026.

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
   `claude/agents`, `claude/hooks`, `claude/rules`, `claude/mcp`, and
   the root `skills/`. Mirrors `claude/CLAUDE.md`
   (→ `~/.claude/CLAUDE.md`) and `claude/settings.json` as plain copies.
   **Back up first if you already have a `~/.claude`** — the
   script refuses to replace real directories or drifted files without
   `-Force`, but review its warnings before forcing anything.

    ```powershell
    ./scripts/link-claude.ps1
    ```

3. Using GitHub Copilot too? There is nothing to link and, as of
   2026-08-29, little to enable — most of the `~/.claude` paths step 2
   created are already VS Code defaults. `~/.claude/agents` is the
   exception and needs an explicit entry; see
   [Tool support](#tool-support) for the block to paste.

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
`claude/rules/`, `claude/mcp/`, `skills/`) need no deploy step — the
tools read the same files. Changes to
`claude/CLAUDE.md` or `claude/settings.json` need a
`scripts/link-claude.ps1` re-run to reach the live copies (the script also verifies everything else and
exits non-zero if any link or mirror needs attention — including after
moving or renaming the repo folder, which it repairs automatically).

Needing no deploy step is not the same as being picked up by a running
session, and the two differ by payload type. **Skills hot-reload**:
Claude Code watches skill directories and re-reads them in-session,
and that works through these junctions — verified on 2.1.251 for skill
add, skill removal, and `skillOverrides` (upstream fixed in-session
skill reload in 2.1.216; this file previously said the opposite).
Editing a `description` in place is the one case not confirmed here,
and a `description` *is* the trigger, so restart before trusting a
changed trigger. **Subagents, commands, and rules are not watched** —
restart after editing those.

One caveat that only bites during a repo reorganization: moving a
payload directory leaves `~/.claude/<name>` pointing at the vacated
path until `scripts/link-claude.ps1` runs again. Files are simply
absent in that window, and a hook that cannot be found **fails open**
rather than blocking — so re-link before relying on an enforcement
hook again. This is not hypothetical: the `claude/` regrouping produced
exactly four such failures before the re-link.

## Handoff discipline

Skills and subagents in this repo are authored via a brief-before-draft
pattern: a structured handoff brief — frontmatter specs, body outline,
portability caveats, post-draft validation steps — is written and
settled before any artifact is drafted from it.

Which surface writes the brief is not part of the pattern. It was
originally split across two, a chat session proposing structure and
Claude Code drafting from it, because only the latter had filesystem
access and only the former could drill sources at length. Claude Code
does both now, and the two steps routinely happen in one session. What
survives the collapse is the artifact: the brief is the record of what
was decided and what was deliberately left out, and the excluded set is
what bounds the draft.

The pattern earns its place when an artifact has non-trivial behavioral
contracts — refusal patterns, severity rubrics, scope-enforced read-only
or destructive guards. For pure reference skills (canonical-answer
content), the pattern is overkill; real-use validation suffices.

Templates and worked examples live in [docs/handoff-briefs/](docs/handoff-briefs/):

- [templates/skill-handoff.md](docs/handoff-briefs/templates/skill-handoff.md)
  — fill-in template for new skills
- [templates/subagent-handoff.md](docs/handoff-briefs/templates/subagent-handoff.md)
  — fill-in template for new subagents
- [examples/](docs/handoff-briefs/examples/) — reference briefs derived
  from validated artifacts

The templates are internal tooling. Consumers cherry-picking from this
repo don't need to adopt the brief pattern; the templates are included
in case the discipline is useful elsewhere.

## License & security

- License: MIT — see [LICENSE](LICENSE).
- Security: see [SECURITY.md](SECURITY.md) for reporting issues.
