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

- [skills/](skills/) — 30+ skills: Fabric, Power BI / TMDL, and the two
  repo-general behavioral verbs (`code-review`, `commit`). Consumed by
  Claude Code and GitHub Copilot. See
  [skills/README.md](skills/README.md).

The skills that maintain *this* repo — `author-skill`, `test-skill`,
`learn`, `drift-audit`, `drift-handoff`, `drift-update`, `land` — are
deliberately **not** here. They live at project scope in
`.claude/skills/`, deploy nowhere, and are covered in
[CLAUDE.md](CLAUDE.md). Being payload is what `skills/` means, and they
are not payload: they can only ever act on this working tree.

### [claude/](claude/) — Claude Code payload

- [claude/agents/](claude/agents/) — 1 subagent
  ([security-reviewer](claude/agents/security-reviewer.md)).
- [claude/rules/](claude/rules/) — 10 path-scoped coding conventions
  (T-SQL, Spark SQL, Python/PySpark, PowerShell, Bash, KQL, DAX, M,
  TMDL, Fabric pipeline expressions) plus a Fabric Git-serialization
  rule; auto-load via `paths:` globs when matching files enter session
  scope.
- [claude/hooks/](claude/hooks/) — InstructionsLoaded and
  Skill-invocation loggers, a security-reviewer memory-scope guard, and
  an identity guard that stops `git commit` / `git push` from carrying
  denylisted client or account names into history.
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
  via `$HOME/.claude/...`, which the link script's deployment provides
  regardless of where the repo is cloned or how the repo side is
  arranged. Personal
  `permissions` entries live in `settings.local.json` (gitignored) —
  add your own there.

### Mechanism and supporting material

- [scripts/](scripts/) — link scripts (see [Install](#install)),
  pre-commit bootstrap, instructions-log query helper, SKILL.md
  frontmatter linter.
- [tests/](tests/) — Synthetic fixtures for validating the code-review
  skill and security-reviewer agent.
- [docs/handoffs/](docs/handoffs/) — Templates and worked
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
- **GitHub Copilot** — needs **no wiring on this machine**. The Claude
  paths are *documented defaults* on the VS Code agent surface, so
  `link-claude.ps1` alone is enough: `~/.claude/rules` for
  instructions, `~/.claude/skills` for skills, `~/.claude/agents` for
  subagents, `~/.claude/CLAUDE.md` for always-on instructions, and
  `~/.claude/settings.json` for hooks (it parses Claude Code's hook
  format). So Copilot is a second consumer of the Claude-format payload
  rather than a separate one — and `paths:` carries over intact, which
  was measured rather than assumed: on 2026-09-09 a `.sql` file open in
  a client repo loaded exactly two of the twelve rules in
  `~/.claude/rules`, the two whose globs matched.

    | Artifact | Workspace defaults | User-profile defaults |
    | --- | --- | --- |
    | Skills | `.github/skills`, `.claude/skills`, `.agents/skills` | `~/.copilot/skills`, `~/.claude/skills`, `~/.agents/skills` |
    | Instructions | `.github/instructions`, `.claude/rules` | `~/.copilot/instructions`, `~/.claude/rules` |
    | Agents | `.github/agents`, `.claude/agents` | `~/.copilot/agents`, `~/.claude/agents` |

    Checked 2026-09-09 against `microsoft/vscode-docs@main`.

    **The `chat.*Locations` settings are switchboards, not wiring.**
    `chat.agentSkillsLocations`, `chat.instructionsFilesLocations`,
    `chat.agentFilesLocations` and `chat.modeFilesLocations` are all
    marked deprecated and "only used by the Local agent" — which is easy
    to read as inert, and is not. The Local agent *is* the sidebar Chat,
    so each still governs exactly the surface you work in; the note
    scopes them away from Copilot CLI and cloud agents. Each is a
    location → boolean map over the defaults above, and the sidebar
    honours a change immediately: measured 2026-09-09 by setting
    `~/.claude/skills` false (the skills left the picker) and
    `~/.copilot/skills` true (they came back from there). So nothing
    needs enabling — but anything can be **disabled**, which is how you
    stop a skill listing twice when two roots hold it.

    **The Local agent is scheduled for removal**, which makes these
    temporary in a way "deprecated" alone does not convey. The docs say
    it about prompt files: they "continue to work with the Local agent
    for now, but the Local agent will be removed in a future release."
    Its replacement, Agent Host, "reads user-level customizations from
    harness-agnostic folders like `~/.copilot` and `~/.claude`" — so
    the payload keeps reaching Copilot without these settings at all.
    Whether Agent Host honours them is **not** stated either way, and
    their own note scopes them to the Local agent, so plan on the
    switchboard going and the discovery staying. Checked 2026-09-09.

    Three traps. `chat.instructionsFilesLocations` accepts **folders
    only** — an entry for `~/.claude/CLAUDE.md` is silently ignored,
    and because `chat.useClaudeMdFile` loads that file anyway, the dead
    setting looks like it worked. VS Code also **omits any setting left
    at its default** when it writes `settings.json`, so
    `chat.useClaudeMdFile` vanishes from the file when set to `true` and
    only appears when set to `false` — absent means on, not unset. And
    no copy into `~/.copilot/agents` or `~/.agents/skills` is needed;
    both only invite drift, and `~/.agents/skills` is shared ground —
    on this machine it holds 28 Copilot-for-Azure skills with their own
    manifest and lockfile.

    **MCP is the one thing this payload cannot carry.** Nothing reads
    `~/.claude/mcp` — not even Claude Code; it exists so the commands in
    [claude/mcp/README.md](claude/mcp/README.md) resolve from a stable
    path — and `~/.claude.json` is Claude Code's own runtime state.
    Copilot wants a workspace `.vscode/mcp.json` or
    `~/.copilot/mcp-config.json` (see
    [.vscode/README.md](.vscode/README.md)).

    **Copilot validates skill frontmatter against its own field list and
    warns rather than failing** — with one exception that does not warn
    at all. Measured 2026-09-04: an unsupported key leaves the skill
    loaded and listed, with a diagnostic naming it — unlike the claude.ai
    upload path, which hard-fails. Supported are `argument-hint`,
    `compatibility`, `context`, `description`,
    `disable-model-invocation`, `license`, `metadata`, `name` and
    `user-invocable`. **Most skills here still warn**: `paths:` on 27,
    `effort:` on 9, `allowed-tools:` on 5. So the warning is ambient, and
    adding a Claude-only field costs nothing that was not already being
    paid — but it also means a *real* frontmatter mistake is camouflaged
    by the noise.

    **The exception is `model:`, which breaks slash invocation outright.**
    An active `model:` of any value — `inherit` as much as a real model
    name — stops VS Code dispatching that skill as a slash command:
    nothing is sent, no session is created, and it presents as a hang
    rather than an error, so there is no diagnostic to trace back.
    Measured 2026-09-09 with single-variable probes, after `/commit` and
    `/code-review` both hung in a client repo while the same skills were
    auto-loading there normally. Auto-load is unaffected — it adds text
    to a request already in flight, where slash invocation builds a new
    one carrying the skill's own parameters. `model` is a supported field
    on Copilot *prompt* files, where it selects the LLM, which is the
    likeliest reason a value it cannot resolve kills dispatch. All 50
    skills here now carry `model:` commented out, and
    [lint-frontmatter.py](scripts/lint-frontmatter.py) rejects an active
    one so it cannot return silently.

    Copilot does hard-
    require one thing Claude Code never checks: a skill's **directory
    name must equal its frontmatter `name:`**. All 50 here comply, and
    `copy-copilot.ps1` verifies it before copying.

    **Copilot CLI is a different consumer with a different table.** It
    lists the same three project roots but only `~/.copilot/skills` and
    `~/.agents/skills` at personal scope — **not** `~/.claude/skills` —
    and reads instructions from `~/.copilot/copilot-instructions.md`,
    `~/.copilot/instructions/**/*.instructions.md`, plus repo-scope
    `.github/copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`,
    `.claude/CLAUDE.md` and `GEMINI.md`. `COPILOT_HOME` replaces
    `~/.copilot` throughout. So "Copilot reads it" is not one fact —
    check which Copilot. (Checked 2026-09-09 against docs.github.com.)

    `paths:` being unsupported has a consequence worth stating plainly:
    **a conditional skill is unconditional in Copilot.** All 27 load
    unconditionally there, so the conditional/unconditional listing-cost
    split that governs `when_to_use` adoption is a Claude Code fact only,
    and "free because it is conditional" does not transfer.

    **Rules are the opposite, and the pair is easy to conflate.** In
    `.claude/rules` Copilot implements `paths:` deliberately, as the
    Claude Rules format, defaulting to `**` when the key is absent — so
    a rule stays conditional there exactly as it is here, while a skill
    does not. Measured 2026-09-09: a `.sql` file open in a client repo
    loaded two of the twelve rules in `~/.claude/rules`, the two whose
    globs matched, from user scope with nothing deployed. Note which
    key each surface reads — `.github/instructions` takes `applyTo`
    instead, and an instructions file carrying **neither** is never
    applied automatically at all.

    **`~/.claude/skills` does resolve** — retested 2026-09-09, with the
    sidebar loading skills from `~/.claude/skills/<name>/SKILL.md`
    through this repo's junctions. A 2026-09-04 entry here claimed the
    opposite and was wrong; the likeliest cause is that
    `chat.agentSkillsLocations` had that root switched off, since the
    setting turns out to be a live per-location toggle rather than the
    additive allowlist it was read as. That correction also retires the
    "Copilot sees this payload at project scope only" conclusion built
    on top of it.

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

- **[copilot/](copilot/) is the one exception, and it is for other
  people.** A junction cannot be committed, so a teammate cloning a
  client repo gets nothing from the paths above.
  [copilot/instructions/](copilot/instructions/) holds eight
  `claude/rules/` bodies re-emitted as `*.instructions.md` with
  `applyTo` globs, which
  [scripts/copy-copilot.ps1](scripts/copy-copilot.ps1) vendors into a
  repo's `.github/instructions` as real files. This is the only place
  the repo carries one piece of guidance in two formats, and the reason
  is that they are genuinely different: `applyTo` is a single
  comma-separated string where `paths:` is a list, and an instructions
  file with **no** `applyTo` never auto-applies at all — so a straight
  copy would ship files that silently do nothing. That makes the port a
  translation rather than a copy, which means it is hand-written and can
  rot, so
  [scripts/lint-instructions.py](scripts/lint-instructions.py) fails a
  commit when a rule moves without its port following. This repo has
  already lost two parallel instruction payloads to exactly that drift.

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

2. Deploy into Claude Code. Copies `claude/agents`, `claude/hooks`,
   `claude/rules` and `claude/mcp` into
   `~/.claude/{agents,hooks,mcp,rules}`, and junctions the root
   `skills/` one skill at a time into `~/.claude/skills` (no elevation
   needed). Mirrors `claude/CLAUDE.md`
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
- This config is Windows-targeted (per-skill junctions, PowerShell link scripts,
  Git Bash for the shell hooks). Hook commands resolve via `$HOME` so
  they're portable across users on Windows, but Linux / macOS users
  will need to symlink manually and adjust paths — no promise it works
  elsewhere out of the box.

## Ongoing workflow

Edit files in place and commit like any other repo. **`skills/` is the
only payload that needs no deploy step** — each skill is junctioned, so
the tools read the same file. Everything else is a copy and needs a
`scripts/link-claude.ps1` re-run to reach the live payload:
`claude/agents/`, `claude/hooks/`, `claude/rules/` and `claude/mcp/`
take repo content on a plain run, while `claude/CLAUDE.md` and
`claude/settings.json` need `-Force`. The script verifies everything
and exits non-zero if any link or copy needs attention — including
after moving or renaming the repo folder, which it repairs
automatically.

Those four were junctions until 2026-09-02. The deploy step is the
point of the change: none of them is hot-reloaded, so a fresh session
was needed either way and the junction bought no immediacy, while
making every uncommitted save — and every `git switch`, `stash` and
`rebase`, including pre-commit's own stash/restore around a commit —
live for every session on the machine. Hooks were the sharp end,
because they *execute*.

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

Templates and worked examples live in [docs/handoffs/](docs/handoffs/):

- [templates/skill-handoff.md](docs/handoffs/templates/skill-handoff.md)
  — fill-in template for new skills
- [templates/subagent-handoff.md](docs/handoffs/templates/subagent-handoff.md)
  — fill-in template for new subagents
- [examples/](docs/handoffs/examples/) — reference briefs derived
  from validated artifacts

The templates are internal tooling. Consumers cherry-picking from this
repo don't need to adopt the brief pattern; the templates are included
in case the discipline is useful elsewhere.

## License & security

- License: MIT — see [LICENSE](LICENSE).
- Security: see [SECURITY.md](SECURITY.md) for reporting issues.
