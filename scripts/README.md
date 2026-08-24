# Scripts

Helper scripts for repo maintenance and observability.

## What's here

- [bootstrap-pre-commit](bootstrap-pre-commit) — install the
  [pre-commit](https://pre-commit.com/) framework via
  [uv](https://docs.astral.sh/uv/) and wire git hooks for this repo.
  Idempotent; safe to re-run. Run on a fresh clone before committing.
- [instructions-log](instructions-log) — query the
  [InstructionsLoaded hook log](../hooks/log-instructions-loaded.sh).
  Subcommands: `today`, `reasons`, `paths`, `tail`. Requires
  [jq](https://jqlang.org) for the JSON-parsing subcommands.
- [link-claude.ps1](link-claude.ps1) — link this repo into `~/.claude`
  so Claude Code loads its config from a clone living anywhere on disk.
  Creates directory junctions (no elevation needed) for `agents/`,
  `hooks/`, `rules/`, and `skills/`, and mirrors `CLAUDE.md` and
  `settings.json` as plain copies (file symlinks need Developer Mode;
  hard links break on `git pull`). `settings.json` is compared at the
  key level — Claude Code adds runtime keys (like the model pin) to
  the live copy, and those are ignored; only repo keys must match.
  Idempotent — re-run any time, including after moving or renaming
  the repo folder (stale junctions are re-pointed automatically).
  Never overwrites a drifted mirror copy or deletes a real directory
  without `-Force`; exits 1 when anything needs attention.
- [lint-skills.py](lint-skills.py) — validate `SKILL.md` frontmatter
  against repo conventions (name regex, length limits, reserved words,
  body-line cap). Used by the pre-commit `Validate SKILL.md frontmatter`
  hook; can also run manually as `python scripts/lint-skills.py <path>...`.

## Pre-commit

Fresh-clone bootstrap:

```bash
scripts/bootstrap-pre-commit
```

That installs `pre-commit` via `uv tool install`, then runs `pre-commit install`
to wire `.git/hooks/pre-commit`. The configured hooks live in
[.pre-commit-config.yaml](../.pre-commit-config.yaml).
