# Copilot instructions for this repo

## What this is

A personal AI coding-agent configuration repo: skills, a subagent,
path-scoped coding rules, hooks, MCP server templates, and settings —
primarily for Claude Code, secondarily for GitHub Copilot. **It is not
an application** — there is no runtime, no build, no server to run.
Content focuses on Microsoft Fabric, Power BI/TMDL, and Azure.

Every artifact carries a reuse-readiness tag: `personal` (works for
the author, not vetted for reuse), `publishable` (real-use validated +
content-reviewed), or `client-only` (by design, never actually present
in this repo). **All current artifacts are tagged `personal`** — treat
content as reference, not a hardened recommendation, and expect drift
as the Fabric/Power BI/Azure platforms move.

## Architecture: deployment is by junction, not by copy

This repo is cloned somewhere arbitrary and then *linked* into each
tool's real config directory — it is not cloned directly into
`~/.claude`:

- [scripts/link-claude.ps1](../scripts/link-claude.ps1) creates directory
  junctions for `agents/`, `hooks/`, `mcp/`, `rules/`, `skills/` under
  `~/.claude` (Claude Code doesn't read `~/.claude/mcp` itself — that
  junction gives the template-copy commands in
  [mcp/README.md](../mcp/README.md) a stable path), and mirrors [global/CLAUDE.md](../global/CLAUDE.md) →
  `~/.claude/CLAUDE.md` plus [settings.json](../settings.json) as
  plain-copy files (`settings.json` is compared key-by-key, since
  Claude Code writes runtime keys like the model pin into the live
  copy). Root [CLAUDE.md](../CLAUDE.md) is a different, never-deployed
  file — see Key conventions below. Editing a file inside a junctioned
  directory takes effect immediately; editing `global/CLAUDE.md` or
  `settings.json` needs a script re-run to reach the live copy.
- [scripts/link-copilot.ps1](../scripts/link-copilot.ps1) junctions each
  skill *individually* into `~/.agents/skills`, because that directory
  is shared with other providers' skills (e.g. Copilot for Azure) and
  can't be junctioned wholesale.
- Both scripts are idempotent, resolve the repo location from their own
  path (so moving/renaming the clone self-heals), and refuse to
  overwrite a real directory or drifted mirror file without `-Force`.

This split also defines what's portable vs. tool-specific:
[skills/](../skills), rule *bodies*, [docs/](../docs), [tests/](../tests),
and the [mcp/](../mcp) templates are agnostic; `settings.json`, the hook
event wiring in [hooks/](../hooks), and subagent frontmatter in
[agents/](../agents) are Claude Code-specific. GitHub Copilot consumes `skills/` (per-skill links into
`~/.agents/skills`) and, for MCP, a workspace `.vscode/mcp.json` — see
[mcp/README.md](../mcp/README.md). Rules, hooks, and `settings.json`
are not wired into Copilot.

## How the pieces trigger

- **Skills** (`skills/<name>/SKILL.md`) trigger three ways:
  model-invoked (the frontmatter `description` is the *entire* trigger
  mechanism — the model matches context against it), user-invoked
  (`/<name>`), or path-scoped (a `paths:` glob in frontmatter, e.g. the
  Fabric-gotchas-adjacent skills). Naming convention: behavioral,
  cross-domain skills are named as the verb you invoke (`commit`,
  `learn`, `code-review`, `drift-audit`); platform skills carry a
  `fabric-`, `pbir-`, or `pbid-` namespace prefix. See
  [skills/README.md](../skills/README.md) for the full catalog.
- **Rules** (`rules/coding-<lang>.md`, plus
  [fabric-git-serialization.md](../rules/fabric-git-serialization.md))
  auto-load by a `paths:` glob when a matching file enters session
  scope — they have no `name` or `description`, only `paths:`. A
  project repo can override any one with its own
  `.claude/rules/<same-name>.md`.
- **Hooks** (`hooks/*.sh`) fire on events registered in
  [settings.json](../settings.json):
  [log-instructions-loaded.sh](../hooks/log-instructions-loaded.sh) on
  `InstructionsLoaded` (pure observability, appends JSONL to
  `~/.claude/logs/instructions-loaded.log`, queried via
  [scripts/instructions-log](../scripts/instructions-log));
  [log-skill-invocations.sh](../hooks/log-skill-invocations.sh) on
  `PostToolUse` matched `Skill` (pure observability, appends JSONL to
  `~/.claude/logs/skills-invoked.log` — skills load through the Skill
  tool, which `InstructionsLoaded` never sees); and
  [security-reviewer-memory-scope.sh](../hooks/security-reviewer-memory-scope.sh)
  on `PreToolUse` matched `Edit|Write` — reads `agent_type` from the
  hook's stdin JSON and, only when it's `security-reviewer`, blocks
  (exit 2) any Edit/Write whose `file_path` falls outside
  `~/.claude/agent-memory/security-reviewer/`. Hook commands are
  hardcoded to `$HOME/.claude/...`; this only resolves correctly
  because the link script junctions this repo there — don't rewrite
  them to be repo-relative.
- The [security-reviewer](../agents/security-reviewer.md) subagent is
  scoped by an explicit tool allowlist (`Read, Grep, Glob, Bash`) plus
  the hook above. It reports findings only, never edits code, and has a
  required memory-hygiene protocol: read `MEMORY.md` before scanning,
  update it after, self-attest the update in its closing summary.

## Build, lint, and test

No build step. Lint and validation:

- **SKILL.md frontmatter lint** —
  [scripts/lint-skills.py](../scripts/lint-skills.py) checks `name`
  (lowercase/digits/hyphens, ≤64 chars, must not contain `claude` or
  `anthropic`), `description` (required, ≤1024 chars — this is the
  trigger text, so put trigger phrases here, not in the body), `paths:`
  (must be a YAML list, not a string), body length (≤500 lines — push
  long reference material to a skill's `references/` subdirectory),
  UTF-8 with no BOM. Python isn't guaranteed on PATH; run it via `uv`:

  ```powershell
  # single file
  uv run --with pyyaml scripts/lint-skills.py skills/commit/SKILL.md

  # whole repo — PowerShell does NOT glob-expand args for external
  # commands, so `skills/*/SKILL.md` passes through literally and
  # fails with "not a file". Expand explicitly first:
  $files = Get-ChildItem skills -Filter SKILL.md -Recurse | % FullName
  uv run --with pyyaml scripts/lint-skills.py @files
  ```

- **Secret scan** — [gitleaks](https://github.com/gitleaks/gitleaks),
  config at [.gitleaks.toml](../.gitleaks.toml) (`tests/` and `docs/` are
  allowlisted — fixtures intentionally contain fake credential-shaped
  strings).
- Both run through [pre-commit](https://pre-commit.com/)
  ([.pre-commit-config.yaml](../.pre-commit-config.yaml)). Fresh clone:
  `scripts/bootstrap-pre-commit` (requires `uv` on PATH; installs
  pre-commit, wires `.git/hooks/pre-commit`, runs once repo-wide).
  Re-run everything: `pre-commit run --all-files`. Run one hook:
  `pre-commit run lint-skills` or `pre-commit run gitleaks`. CI
  ([.github/workflows/pre-commit.yml](../.github/workflows/pre-commit.yml))
  runs the same config on every push/PR to `main`.
- **No automated test suite.** [tests/](../tests) holds synthetic
  fixtures validated *manually* against the `code-review` skill and the
  `security-reviewer` agent — see
  [tests/skills/code-review/README.md](../tests/skills/code-review/README.md)
  and
  [tests/agents/security-reviewer/README.md](../tests/agents/security-reviewer/README.md)
  for the exact procedure. To validate a single fixture: open a session
  in the fixtures directory and invoke the skill/agent against just
  that file (e.g. `/code-review review fixtures/python_fixture.py`),
  then diff findings against that test's `expected_findings.md` cheat
  sheet. The code-review skill fixtures are checked under four
  invocation modes (slash review, NL review, slash adversarial "fix
  this", NL adversarial) — a pass requires all four. Re-run after
  editing the relevant `SKILL.md` or a rule it consumes, and confirm
  `git status` is clean afterward (fixtures are read-only by contract).

## Key conventions

- **Commit discipline** (see [skills/commit/SKILL.md](../skills/commit/SKILL.md),
  matches actual history): Conventional Commits subject
  (`type: imperative summary`, lowercase after the colon; types in
  order of frequency here are `docs, feat, refactor, fix, chore`), body
  explains motivation/why rather than restating the diff, one logical
  change per commit, explicit-path staging only (never `git add -A` /
  `git add .`), renames via `git mv`, never push/amend/rebase/
  `--no-verify` unless explicitly asked.
- **New skills/subagents with non-trivial behavioral contracts**
  (refusal patterns, severity rubrics, scope-enforced read-only or
  destructive guards) go through the brief-before-draft pattern in
  [docs/handoff-briefs/](../docs/handoff-briefs) rather than being
  drafted directly; pure-reference skills skip this and go straight to
  real-use validation.
- **Folding a session discovery back into this repo** goes through the
  [learn](../skills/learn/SKILL.md) skill, not ad hoc edits: it maps the
  learning to the right destination (the owning skill's `SKILL.md`,
  `fabric-gotchas` for cross-cutting symptoms, a
  `rules/coding-<lang>.md`, or `CLAUDE.md`), requires checking for
  existing coverage first, requires external verification (docs or a
  reproduction) before encoding a claim, always proposes a diff for
  approval instead of editing silently, and hands off committing to the
  `commit` skill.
- **Root `CLAUDE.md` vs. `global/CLAUDE.md` — don't confuse the two.**
  Root [CLAUDE.md](../CLAUDE.md) is project-scope: a sync-model table
  (which repo path deploys where, by what mechanism, and when it goes
  live) plus editing conventions for *this repo's own* skills/rules/
  CLAUDE.md content. It is never deployed anywhere and only loads in
  sessions opened inside this repo. [global/CLAUDE.md](../global/CLAUDE.md)
  is the deployment payload — loaded into *every* Claude Code session
  on the machine regardless of repo, mirrored to `~/.claude/CLAUDE.md`
  by [scripts/link-claude.ps1](../scripts/link-claude.ps1) — and is
  kept lean (environment notes, pointers to rules/skills) by design.
  The Fabric portal-serialization guidance formerly inline in
  `CLAUDE.md` now lives in its own path-scoped rule,
  [rules/fabric-git-serialization.md](../rules/fabric-git-serialization.md)
  (triggered by `.platform` / `*.{ItemType}` folder globs), describing
  conventions for editing *other* Fabric Git-synced repos, not this
  one — this repo's own [.gitattributes](../.gitattributes) pins
  `* text=auto eol=lf` and the rule explicitly disclaims itself here.
- **`global/CLAUDE.md`/`global/AGENTS.md` is a deliberately-duplicated
  pair, not a pointer relationship.** GitHub Copilot's docs list
  `AGENTS.md`/`CLAUDE.md`/`GEMINI.md` as interchangeable "Agent
  instructions" — Copilot CLI, VS Code, and the cloud agent already
  read this repo's `CLAUDE.md` files for that tier, so Copilot alone
  wouldn't need `AGENTS.md` at all. It exists anyway, as a full content
  mirror, so non-Microsoft agent tools (Codex, Jules, OpenCode) that
  look for that filename specifically and don't know the `CLAUDE.md`
  convention get the same guidance — this repo's explicit goal is to be
  cherry-picked by any agentic tool. **When editing either member of
  the pair, mirror the change into its counterpart** — nothing
  automates this sync; see the reminders in
  [global/AGENTS.md](../global/AGENTS.md) and the `learn` skill's
  destination table ([skills/learn/SKILL.md](../skills/learn/SKILL.md)).
  Root [CLAUDE.md](../CLAUDE.md) has no `AGENTS.md` twin — it describes
  working *on* this repo, not portable payload.
- **Three MCP templates, two tools, two schemas** — see
  [mcp/README.md](../mcp/README.md). Claude Code reads a `mcpServers`
  key (`~/.claude.json` user scope, or project-scope `<repo>/.mcp.json`);
  VS Code / GitHub Copilot reads a `servers` key instead
  (`.vscode/mcp.json`, workspace scope). Several Fabric-hosted endpoints
  (`powerbi-remote-mcp`, `fabric-core-remote-mcp`, `kql-global-mcp`,
  `warehouse-global-mcp`, and the item-scoped `eventhouse-remote-mcp` /
  `warehouse-remote-mcp` / `activator-remote-mcp`) error with an OAuth
  Dynamic Client Registration (DCR) issue from Claude Code specifically
  — they only work from the VS Code / GitHub Copilot side, which is why
  they're placed in `.vscode-mcp.template.json` rather than the
  Claude-oriented templates. A Copilot CLI / Agent Host session doesn't
  read `.vscode/mcp.json` directly either — VS Code forwards it
  automatically, except servers needing `${input:...}` interactive
  variables.
- Gitignored/personal-only paths referenced in docs but absent from a
  fresh clone: `docs/project-instructions/` (personal Claude Desktop
  project instructions), `settings.local.json`, `agent-memory/`,
  `logs/` — don't be surprised when they don't exist.
