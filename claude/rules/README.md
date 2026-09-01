---
paths:
  - "claude/rules/*.md"
---

# Coding rules

Path-scoped coding conventions auto-loaded by Claude Code when a matching
file enters session scope.

This README carries a `paths:` scope of its own for one reason: a rules
file with no `paths:` loads into **every** session on the machine, and
documentation doesn't earn that. Scoped to the rules directory, it loads
exactly when the rules themselves are being worked on.

## How they trigger

Each rule's frontmatter declares a `paths:` glob list. When a file
matching one of those globs enters Claude Code's session scope (via
Read, session-context, or an agent inspecting the working tree), the
rule is loaded into context.

The rules don't enforce style — they tell the model the conventions to
follow when generating or reviewing code in that language. Pair with
the [code-review skill](../../skills/workflow/code-review/SKILL.md) for explicit
conformance checking.

## What's here

- [coding-tsql.md](coding-tsql.md) — T-SQL (SQL Server, Azure SQL,
  Fabric Warehouse, Synapse SQL pools)
- [coding-sparksql.md](coding-sparksql.md) — Spark SQL in Fabric /
  Databricks notebooks
- [coding-python.md](coding-python.md) — Python and PySpark
- [coding-powershell.md](coding-powershell.md) — PowerShell (`pwsh` 7+):
  bootstrap and automation scripts, machine-state tooling
- [coding-bash.md](coding-bash.md) — Bash (Git Bash on Windows): CLI
  wrapper scripts and Claude Code hooks
- [coding-kql.md](coding-kql.md) — KQL (Eventhouse, Log Analytics, ADX)
- [coding-dax.md](coding-dax.md) — DAX (Power BI / Fabric semantic
  models)
- [coding-m.md](coding-m.md) — M / Power Query
- [coding-tmdl.md](coding-tmdl.md) — TMDL semantic-model definitions
- [coding-expressions.md](coding-expressions.md) — Fabric pipeline
  expressions; idioms also apply to ADF, Synapse pipelines, Logic Apps,
  and Power Automate (Workflow Definition Language family)
- [fabric-git-serialization.md](fabric-git-serialization.md) — not a
  coding convention: portal serialization behavior for Fabric
  Git-synced repos (EOF newlines, mixed CRLF/LF, the auto-generated
  view header, `.gitattributes -text`). Triggers on `*.{ItemType}`
  item folders and `.platform` files.
- [vscode-scoping.md](vscode-scoping.md) — not a coding convention:
  which VS Code scope a setting belongs in (profile vs
  `.vscode/settings.json` vs `extensions.json` vs `.code-workspace`),
  and the silent failures around it — formatters naming extensions that
  are not enabled, `useDefaultFlags` linking a profile back to Default,
  globs that cannot match leading dots. Triggers on `.vscode/*.json`,
  `*.code-workspace`, and stored profile settings.

## Project-scope override

If a project repo has `.claude/rules/coding-<lang>.md`, that file
supersedes the user-scope copy here for sessions inside that repo.
This is the way to deviate from defaults on a per-project basis without
forking the user-scope rule.
