# Scripts

Helper scripts for repo maintenance and observability.

## What's here

- [bootstrap-pre-commit](bootstrap-pre-commit) — install the
  [pre-commit](https://pre-commit.com/) framework via
  [uv](https://docs.astral.sh/uv/) and wire git hooks for this repo.
  Idempotent; safe to re-run. Run on a fresh clone before committing.
- [instructions-log](instructions-log) — query the hook observability
  logs: the [InstructionsLoaded log](../claude/hooks/log-instructions-loaded.sh)
  and the [skill-invocation log](../claude/hooks/log-skill-invocations.sh),
  both pure JSONL. Subcommands: `today`, `reasons`, `paths`, `csv`
  (dump the instruction log as CSV for quick consumption), `skills`
  (count skill invocations by name), `tail`. Requires
  [jq](https://jqlang.org).
- [link-claude.ps1](link-claude.ps1) — link this repo into `~/.claude`
  so Claude Code loads its config from a clone living anywhere on disk.
  Creates directory junctions (no elevation needed) at
  `~/.claude/{agents,hooks,mcp,rules,skills}`, sourced from
  `claude/agents`, `claude/hooks`, `claude/rules`, `claude/mcp` and the
  root `skills/` — see `$LinkDirs` in the script for the mapping. Mirrors
  `claude/CLAUDE.md` (→ `~/.claude/CLAUDE.md`) and
  `claude/settings.json` as plain copies (file
  symlinks need Developer Mode; hard links break on `git pull`). The
  repo-root `CLAUDE.md` is project-scope and never deployed. `settings.json` is compared at the
  key level — Claude Code adds runtime keys (like the model pin) to
  the live copy, and those are ignored; only repo keys must match.
  Idempotent — re-run any time, including after moving or renaming
  the repo folder, or after payload moves between the root and
  `claude/` (stale junctions are re-pointed automatically, no `-Force`).
  Never overwrites a drifted mirror copy or deletes a real directory
  without `-Force`; exits 1 when anything needs attention.
- [lint-frontmatter.py](lint-frontmatter.py) — validate `SKILL.md` and
  `rules/*.md` frontmatter against repo conventions. Kind is inferred from
  the path: files under `rules/` need `paths:` and are exempt from
  `name`/`description`; everything else is linted as a skill (name regex,
  length limits, reserved words). Both get body-line cap, UTF-8/BOM, and
  glob checks. Used by the pre-commit `Validate SKILL.md frontmatter` and
  `Validate rules frontmatter` hooks; can also run manually as
  `python scripts/lint-frontmatter.py <path>...`.

There is deliberately **no `link-copilot.ps1`**. It existed to junction
skills one-by-one into the shared `~/.agents/skills`, on the premise that
`chat.agentSkillsLocations` had no entry for `~/.claude/skills` — which
was already false when it was written. That location has been documented
since at least 2026-06-26, so every artifact Copilot needs reaches it
through the `~/.claude` paths `link-claude.ps1` already creates — rules,
hooks, subagents, skills, and user-scope instructions alike. Enabling
them is a `chat.*Locations` settings decision; see the Tool support
section of the [root README](../README.md#tool-support).

## Pre-commit

Fresh-clone bootstrap:

```bash
scripts/bootstrap-pre-commit
```

That installs `pre-commit` via `uv tool install`, then runs `pre-commit install`
to wire `.git/hooks/pre-commit`. The configured hooks live in
[.pre-commit-config.yaml](../.pre-commit-config.yaml).
