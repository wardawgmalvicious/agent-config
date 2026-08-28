# Codex Global Instructions

User-scope operating defaults for Codex on this machine. Deployed to
`CODEX_HOME/AGENTS.md` from this repo's `codex/AGENTS.md` by
`scripts/link-codex.ps1` — edit the repo copy and re-run the script
(`-Force` after reviewing reported drift).

## Operating defaults

- Inspect local files first before proposing or making changes.
- Prefer PowerShell-first commands and examples on this Windows machine.
- Prefer `rg` and `rg --files` for search when available.
- Preserve existing user changes. Do not revert, rename, delete, or
  reformat unrelated files.
- Use official documentation for current platform behavior, permissions,
  API details, and preview-versus-GA distinctions.
- Treat auth state, network access, and permissions as variable. Verify
  rather than assume.
- Favor practical, secure, boring, maintainable engineering over clever
  abstractions.
- State assumptions when the repo does not provide enough context.
- Python is **not** on `PATH` on this machine. Go through `uv`
  (`uv run script.py`, `uv run python -c "..."`, `uvx <tool>`,
  `uv tool install <tool>`). Bare `python`, `python3`, and `pip` fail
  with "command not found".

## Safety

- Never hardcode secrets, tokens, connection strings, API keys, client
  secrets, workspace IDs, item IDs, endpoints, or tenant-specific values
  unless they already come from checked-in config or the user explicitly
  asks for that exact value.
- Never print secrets, tokens, connection strings, credentials, or raw
  authorization headers.
- Use environment variables, Key Vault, Fabric connections, managed
  identity, or existing secure repo patterns.
- Ask before risky changes involving production data, deployed
  artifacts, infrastructure, credentials, tenant/client data, or broad
  permission changes.
- For external or current facts, verify from official sources where
  possible.

## Skills

Deep Microsoft Fabric / Power BI / TMDL / Azure guidance lives in the
skills under `~/.agents/skills` (junctioned from the agent-config
repo). Prefer that content over training-data answers when both exist;
when unsure whether a relevant skill exists, check there before
fabricating specifics.

## Coding standards (summary)

- Python and PySpark: `lower_snake_case` variables, functions, and
  modules; `PascalCase` classes; `UPPER_SNAKE_CASE` constants.
- SQL: CTEs for multi-step logic, leading commas in long lists, explicit
  `AS` aliases, explicit joins, schema-qualified objects, and semicolon
  terminators. Avoid `SELECT *` except for local inspection.
- KQL: lowercase operators, time filters early, one pipe operator per
  line.
- DAX: explicit measures, `VAR`/`RETURN`, `DIVIDE()`, table-qualified
  columns, and measure-only `[Measure]` references.
- TMDL and semantic models: stable `PascalCase` identifiers plus
  user-facing `displayName` values where appropriate.
- SQL, KQL, M, TMDL, semantic-model object aliases, pipeline
  parameters, and activity names use `PascalCase` where appropriate.

Full per-language conventions live in the agent-config repo's
`rules/coding-<lang>.md` files (authored for Claude Code's path-scoped
auto-load; read them directly when working heavily in one language).

## Review behavior

- For review requests, lead with findings ordered by severity and
  include file/line references.
- Focus on correctness, security, behavior regressions, missing tests,
  data quality, scaling, and operational risk.
- Keep style-only feedback secondary unless it hides a real
  maintainability or correctness issue.
- Spawn the `code_reviewer` custom agent for read-only review work and
  the `security_reviewer` custom agent for focused security scans (both
  deployed to `CODEX_HOME/agents/`).

## Validation

- Run the narrowest relevant validation command after edits.
- If validation cannot run, explain why and what remains unverified.

## Custom prompts

`CODEX_HOME/prompts/` carries `fabric-task` (structured brief for
Fabric / Power BI work) and `repo-instructions-audit` (check whether a
repo has enough Codex guidance) — both deployed from the agent-config
repo's `codex/prompts/`.
