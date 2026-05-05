# Coding rules

Path-scoped coding conventions auto-loaded by Claude Code when a matching
file enters session scope.

## How they trigger

Each rule's frontmatter declares a `paths:` glob list. When a file
matching one of those globs enters Claude Code's session scope (via
Read, session-context, or an agent inspecting the working tree), the
rule is loaded into context.

The rules don't enforce style — they tell the model the conventions to
follow when generating or reviewing code in that language. Pair with
the [code-review skill](../skills/code-review/SKILL.md) for explicit
conformance checking.

## What's here

- [coding-tsql.md](coding-tsql.md) — T-SQL (SQL Server, Azure SQL,
  Fabric Warehouse, Synapse SQL pools)
- [coding-sparksql.md](coding-sparksql.md) — Spark SQL in Fabric /
  Databricks notebooks
- [coding-python.md](coding-python.md) — Python and PySpark
- [coding-kql.md](coding-kql.md) — KQL (Eventhouse, Log Analytics, ADX)
- [coding-dax.md](coding-dax.md) — DAX (Power BI / Fabric semantic
  models)
- [coding-m.md](coding-m.md) — M / Power Query
- [coding-tmdl.md](coding-tmdl.md) — TMDL semantic-model definitions
- [coding-expressions.md](coding-expressions.md) — Fabric pipeline
  expressions; idioms also apply to ADF, Synapse pipelines, Logic Apps,
  and Power Automate (Workflow Definition Language family)

## Project-scope override

If a project repo has `.claude/rules/coding-<lang>.md`, that file
supersedes the user-scope copy here for sessions inside that repo.
This is the way to deviate from defaults on a per-project basis without
forking the user-scope rule.
