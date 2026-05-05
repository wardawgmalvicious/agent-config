# Skills

Skills are markdown files Claude Code auto-discovers from this directory.
Each `SKILL.md` has YAML frontmatter with a `description` the model uses
to decide when to invoke the skill.

## How they trigger

- **Model-invoked.** The description in each `SKILL.md` frontmatter
  tells the model when the skill is relevant. The model invokes it
  automatically when context matches.
- **User-invoked.** `/<skill-name>` in the prompt invokes a skill
  directly when Claude Code surfaces it as a slash command.
- **Path-scoped.** Some skills only auto-trigger when a particular
  file pattern is in scope (set via `paths:` in frontmatter).

See each `SKILL.md` for its specific triggering conditions.

## Behavioral (cross-domain)

- [code-review/](code-review/) — review code for quality, naming,
  error handling, security, and scaling. Multi-language: Python,
  PySpark, T-SQL, Spark SQL, KQL, DAX, TMDL, Fabric pipeline
  expressions.
- [drift-audit/](drift-audit/) — audit Microsoft monthly feature blogs
  / release notes for skill staleness, drift in existing skills, new-
  skill candidates, and MCP/tooling additions. Findings only — no edits.

## Microsoft Fabric platform (18)

- [fabric-auth/](fabric-auth/) — token audiences for Fabric REST,
  Power BI REST, OneLake, Warehouse SQL, KQL, XMLA, Azure ARM. Includes
  `az login` and `az account get-access-token` patterns for 401 debugging.
- [fabric-rest-api/](fabric-rest-api/) — Fabric REST patterns:
  pagination with `continuationToken`, long-running operations (202 +
  Location + polling), `jobType` values, item definitions, `?updateMetadata`.
- [fabric-cli/](fabric-cli/) — `fab` CLI: filesystem-style access over
  Fabric + Power BI REST. Path syntax, navigation, item CRUD, ACLs,
  capacity/domain, jobs, `fab api` REST passthrough.
- [fabric-warehouse/](fabric-warehouse/) — Fabric Warehouse T-SQL,
  unsupported types, MERGE constraints, COPY INTO auth.
- [fabric-database/](fabric-database/) — Fabric SQL database.
- [fabric-eventhouse/](fabric-eventhouse/) — Fabric Eventhouse + KQL.
- [fabric-eventstream/](fabric-eventstream/) — Fabric Eventstream.
- [fabric-mlv/](fabric-mlv/) — Materialized Lake Views: `CREATE
  MATERIALIZED LAKE VIEW` Spark SQL + the preview `@fmlv` PySpark
  decorator. Refresh modes, CDF prerequisite, lineage scheduling.
- [fabric-spark/](fabric-spark/) — Fabric Spark patterns.
- [fabric-monitoring/](fabric-monitoring/) — Warehouse query monitoring:
  `OPTION (LABEL = ...)`, `queryinsights` schema, retention windows.
- [fabric-security/](fabric-security/) — workspace roles, item-level
  permissions, SQL GRANT/DENY/REVOKE, RLS/CLS bypass via Spark/OneLake.
- [fabric-tmdl/](fabric-tmdl/) — TMDL semantic-model authoring.
- [fabric-tmdl-api/](fabric-tmdl-api/) — Semantic Model Definition API
  (createItemWithDefinition, getDefinition, updateDefinition); the
  two-audience rule, definition envelope, Direct Lake partitions.
- [fabric-semantic-model-ai-instructions/](fabric-semantic-model-ai-instructions/)
  — Copilot semantic model AI-instructions authoring.
- [fabric-data-agent/](fabric-data-agent/) — Fabric Copilot data agent.
- [fabric-variable-library/](fabric-variable-library/) — variable
  libraries.
- [fabric-error-handling/](fabric-error-handling/) — error-handling
  conventions across Fabric components.
- [fabric-gotchas/](fabric-gotchas/) — common 401/403/404 failures,
  PowerBIEntityNotFound, snapshot conflicts, plus a MUST/PREFER/AVOID
  best-practices summary.

## Power BI Desktop / Reports (10)

- [pbid-tom-live/](pbid-tom-live/) — script an open Power BI Desktop
  model via its localhost `msmdsrv` Analysis Services proxy: TOM for
  metadata, ADOMD.NET for DAX, VertiPaq DMVs, EVALUATEANDLOG, Server
  Timings, DAXLib UDF packages.
- [pbip-project-structure/](pbip-project-structure/) — PBIP folder
  layout.
- [pbir-cli/](pbir-cli/) — `pbir` CLI for inspecting and editing
  PBIR reports (verb/noun groups: report, page, visual, filter,
  bookmark, theme, dax, fields, schema, etc.).
- [pbir-report-workflow/](pbir-report-workflow/) — 10-step end-to-end
  report build: KPI/filter/granularity requirements, model field
  discovery, scaffold, 3-30-300 visual hierarchy, layout math, sort,
  filters, conditional formatting, validation, publish.
- [pbir-pages/](pbir-pages/) — pages.
- [pbir-bookmarks/](pbir-bookmarks/) — bookmarks.
- [pbir-filters/](pbir-filters/) — report and page filters.
- [pbir-themes/](pbir-themes/) — themes.
- [pbir-conditional-formatting/](pbir-conditional-formatting/) —
  conditional formatting for visuals.
- [pbir-visual-json/](pbir-visual-json/) — visual JSON structure.
