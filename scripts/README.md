# Scripts

Helper scripts for repo maintenance and observability.

## What's here

- [bootstrap-pre-commit](bootstrap-pre-commit) — install the
  [pre-commit](https://pre-commit.com/) framework via
  [uv](https://docs.astral.sh/uv/) and wire git hooks for this repo.
  Idempotent; safe to re-run. Run on a fresh clone before committing.
- [instructions-log](instructions-log) — query the hook observability
  logs: the [InstructionsLoaded log](../hooks/log-instructions-loaded.sh)
  and the [skill-invocation log](../hooks/log-skill-invocations.sh),
  both pure JSONL. Subcommands: `today`, `reasons`, `paths`, `csv`
  (dump the instruction log as CSV for quick consumption), `skills`
  (count skill invocations by name), `tail`. Requires
  [jq](https://jqlang.org).
- [link-claude.ps1](link-claude.ps1) — link this repo into `~/.claude`
  so Claude Code loads its config from a clone living anywhere on disk.
  Creates directory junctions (no elevation needed) for `agents/`,
  `hooks/`, `mcp/`, `rules/`, and `skills/`, and mirrors `claude/CLAUDE.md`
  (→ `~/.claude/CLAUDE.md`) and `settings.json` as plain copies (file
  symlinks need Developer Mode; hard links break on `git pull`). The
  repo-root `CLAUDE.md` is project-scope and never deployed. `settings.json` is compared at the
  key level — Claude Code adds runtime keys (like the model pin) to
  the live copy, and those are ignored; only repo keys must match.
  Idempotent — re-run any time, including after moving or renaming
  the repo folder (stale junctions are re-pointed automatically).
  Never overwrites a drifted mirror copy or deletes a real directory
  without `-Force`; exits 1 when anything needs attention.
- [link-codex.ps1](link-codex.ps1) — wire durable Codex content without
  linking `CODEX_HOME` itself. Creates one junction per repo skill under
  shared `~/.agents/skills`; when present, copies `codex/AGENTS.md` to
  `CODEX_HOME/AGENTS.md`, `codex/agents/*.toml` to `CODEX_HOME/agents/`,
  and `codex/prompts/*.md` to `CODEX_HOME/prompts/`. Refuses a linked
  or Git-backed Codex home and never manages `config.toml`,
  credentials, sessions, caches, plugins, or `CODEX_HOME/skills`. Home-only content is preserved; `-Force`
  replaces only named collisions or drifted managed copies.
- [link-copilot.ps1](link-copilot.ps1) — link this repo's skills into
  `~/.agents/skills` for GitHub Copilot (the VS Code agents surface).
  One junction per skill, because `~/.agents/skills` is shared with
  other providers' skills (e.g. Copilot for Azure) and can't be
  junctioned wholesale. Re-points stale junctions after a repo
  move/rename, prunes broken junctions left by deleted or renamed
  skills, and never touches other providers' directories. Same
  `-Force` / exit-code semantics as `link-claude.ps1`.
- [lint-frontmatter.py](lint-frontmatter.py) — validate `SKILL.md` and
  `rules/*.md` frontmatter against repo conventions. Kind is inferred from
  the path: files under `rules/` need `paths:` and are exempt from
  `name`/`description`; everything else is linted as a skill (name regex,
  length limits, reserved words). Both get body-line cap, UTF-8/BOM, and
  glob checks. Used by the pre-commit `Validate SKILL.md frontmatter` and
  `Validate rules frontmatter` hooks; can also run manually as
  `python scripts/lint-frontmatter.py <path>...`.

## Pre-commit

Fresh-clone bootstrap:

```bash
scripts/bootstrap-pre-commit
```

That installs `pre-commit` via `uv tool install`, then runs `pre-commit install`
to wire `.git/hooks/pre-commit`. The configured hooks live in
[.pre-commit-config.yaml](../.pre-commit-config.yaml).
