# Agent Config

Personal configuration for coding agents: skills, subagents, coding
rules, hooks, MCP templates, and settings. Clone it anywhere; a scoped
link script wires durable content into Claude Code, in a terminal or
VS Code, without putting any tool's runtime directory under Git.

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

Which skills have been tested, and what has changed in each since, is
derived rather than listed here:

```bash
uv run --with pyyaml scripts/skill-status.py
```

It reads the stamps `/test-skill` writes and compares each with the
skill as it stands, so its `real-use` column is where this section's
"real-use tested" fact lives. A list of four untested skills stood here
from May until 2026-09-12; by the time anyone checked, every skill on
it had been edited since, which is why it is a command now and not a
list.

## Contents

The top level splits by *audience*: a directory sits at the root when
more than one tool consumes it, and under `<tool>/` when only that tool
does. Adding a harness means adding one `<tool>/` directory, not
rearranging the root.

### Shared content

- [skills/](skills/) — 30+ skills: Fabric, Power BI / TMDL, the
  repo-general behavioral verbs (`code-review`, `commit`, `land`,
  `prune-branches`) and the `meta` group (`learn`), whose subject is the
  agent payload itself. Consumed by Claude Code, in a terminal or as
  VS Code's Claude session target. See
  [skills/README.md](skills/README.md).

The skills that maintain *this* repo — `author-skill`, `test-skill`,
`drift-audit`, `drift-handoff`, `drift-update`, `triage` — are
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
  and project (a repo's `.mcp.json`). The user template carries only
  servers measured connecting from Claude Code; the project template
  also lists documented servers not yet probed, each marked. See
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
  is the user-scope payload. They are not mirrors of each other. Root is
  the only project-scope instruction file that loads at startup, with
  [.claude/rules/](.claude/rules/) splitting off the guidance a file here
  triggers, and there is no parallel file for another tool: a root
  `AGENTS.md` was carried alongside until it went unread — Codex was
  dropped and VS Code's `chat.useAgentsMdFile` is off — and its one
  unique section, the fixture-validation procedure, now lives in root
  `CLAUDE.md`. Claude Code reads an `AGENTS.md` only where no
  `CLAUDE.md` sits on the path, so one beside root would be dead text to
  it; the route for another tool is a `CLAUDE.md` of `@AGENTS.md`
  ([agent-instructions-scoping.md](claude/rules/agent-instructions-scoping.md)),
  which pays only where people use that tool, and root here is about
  skills, hooks and deploys no other tool can use (2026-09-25).
- **Other tools** — the repo carried a Codex payload and linker until
  it went unused; see the history around `codex/` if you want it back.
  Skills use the open Agent Skills format, so any tool that reads
  `SKILL.md` can consume [skills/](skills/) directly.
- **VS Code's chat** — the **session target** picks the harness that
  runs a session, and the harness, not the model, decides what it reads.
  VS Code's hooks page lists five targets, Local, Copilot, Claude, Codex
  and Cloud, with the Chat view and the Agents window as clients of
  either host (rendered 2026-10-06).
  - **Claude** runs Claude Code's own engine, the Claude Agent SDK with
    every settings scope and Claude Code's system prompt, so it reads
    this payload through `~/.claude` as a terminal session does. A turn
    on a client repo on 2026-10-05 loaded user rules by `paths:` and ran
    the user-scope hooks, on a model billed through Copilot. It drops
    `WebSearch` and answers permission prompts through VS Code, and an
    organization can switch it off (the `Claude3PIntegration` policy).
    This is the target the payload is for.
  - **Local**, VS Code's own harness, reads Claude's formats beside
    Copilot's wherever its `chat.*Locations` settings leave them on, as
    every profile here does since 2026-10-08. The docs mark those
    settings and the harness for removal "in a future release", and
    [vscode-scoping.md](claude/rules/vscode-scoping.md) has the traps in
    them.
  - **Copilot** reads `.github/*` and `~/.copilot/*`, nothing under
    `~/.claude`, and **Codex** reads `AGENTS.md`: neither gets this
    payload. On a client repo on 2026-09-30 the Copilot target's panel
    also listed the repo's root `CLAUDE.md`, by a route not traced.

  Until 2026-10-13 a second payload, `copilot/` and the script that
  copied it, vendored skill groups and hand-made instruction ports into
  a repo's `.github` and into `~/.copilot` for the Copilot target. The Claude target left it no reader, so it was
  removed, and
  [docs/evidence/root-claude-md.md](docs/evidence/root-claude-md.md)
  names the last commit that holds it.

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

3. Using VS Code's chat? Pick the **Claude** session target, which
   reads `~/.claude` as Claude Code does, so there is nothing more to
   deploy. [Tool support](#tool-support) has what the other targets
   read.

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
