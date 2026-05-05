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
