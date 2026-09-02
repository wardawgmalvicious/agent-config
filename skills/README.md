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

Naming convention: behavioral skills are named as the verb you invoke
(`/commit`, `/learn`); platform skills carry a `fabric-` / `pbir-` /
`pbid-` namespace prefix. `powerbi-*` skills are vendored from
[microsoft/skills-for-fabric](https://github.com/microsoft/skills-for-fabric)
and keep Microsoft's upstream naming so re-sync diffs and their
internal cross-references stay intact.

- [author-skill/](workflow/author-skill/) — author a new skill for this repo end
  to end: coverage check, name and namespace, doc drilling, a filled
  handoff brief in [docs/handoffs/](../docs/handoffs/), then
  the `SKILL.md` draft and the post-draft checks. Ends at a linted draft
  plus a fresh-session test plan — no fixtures, no commit. Deliberately
  overlaps the loaded `skill-creator` and `plugin-dev:skill-development`
  plugin skills, which know the Agent Skills format but not this repo's
  naming rules, `references/` split, lint command, or brief-before-draft
  discipline. Named for the verb you invoke, like the rest of this
  section, and kept distinct from `skill-creator` in trigger matching.
- [code-review/](workflow/code-review/) — review code for quality, naming,
  error handling, security, and scaling. Multi-language: Python,
  PySpark, T-SQL, Spark SQL, KQL, DAX, TMDL, Fabric pipeline
  expressions.
- [commit/](workflow/commit/) — turn working-tree changes into logical,
  self-consistent commits: splitting rules, conventional-commit
  messages with motivation in the body, explicit-path staging,
  never-push/amend rails, Fabric Git-synced repo checks.
- [drift-audit/](workflow/drift-audit/) — audit registered upstream docs sources
  for skill staleness, drift in existing skills, new-skill candidates,
  and MCP/tooling additions. Findings only — no edits. Sources are a
  registry ([references/sources.md](workflow/drift-audit/references/sources.md)),
  not a hardcoded list — Fabric and Power BI What's New today, and
  widening the audit to another domain is an entry there plus a
  validated run. Named for the job, not the target: it audits rules,
  `CLAUDE.md`, and the MCP templates too, so `skill-audit` would name a
  quarter of its scope and would collide with a plausible future skill
  that actually audits skill quality.
- [drift-handoff/](workflow/drift-handoff/) — the write half of `/drift-audit`:
  turn its report into `docs/audits/<date>/<source-id>/`, holding
  the report verbatim plus one brief per recommended action, grouped by
  shared verification steps. Split from `drift-audit` so the turn doing
  the analysis has no write capability; runs inline because it reads the
  report out of the current conversation. Only recommended actions
  become briefs — everything else stays conversational.
- [drift-update/](workflow/drift-update/) — the third turn: execute the briefs
  `/drift-handoff` left on disk. Walks them in numbered order with a
  checkpoint each — confirm the quoted evidence still exists, apply,
  run the brief's own verification, stamp an execution log — and stops
  on the first failure. Briefs whose `Kind` is a decision rather than
  an edit are escalated, never executed. Reads briefs from disk and
  never from the conversation, which is what keeps `drift-handoff`'s
  cold-read contract honest: a brief that can't be executed without
  opening the audit report is reported as a brief-format defect.
- [learn/](workflow/learn/) — "learn!": capture a session learning into the
  skill / rule / CLAUDE.md that should have covered it. Auto-detects
  which guidance was in use, checks existing coverage, verifies against
  docs, proposes a diff for approval, hands off to `/commit`.
- [test-skill/](workflow/test-skill/) — the second half of
  `/author-skill`: write a drafted skill's trigger fixtures, update the
  `expected_activations.md` contract, run the static and real-path
  activation tests, then check behaviour in a cold session against a
  `--safe-mode` baseline. Named as the verb you invoke, and paired with
  `author-skill` deliberately — that skill stops at a linted draft and
  writes no fixtures, so nothing validated a new skill until this one
  existed. Reads the handoff brief from disk rather than from session
  context, so it runs cold like `/drift-update` instead of depending on
  the authoring run. Skills only; subagents and hooks keep the manual
  procedure in [tests/](../tests/).

## Microsoft Fabric platform (26)

- [fabric-auth/](fabric/fabric-auth/) — token audiences for Fabric REST,
  Power BI REST, OneLake, Warehouse SQL, KQL, XMLA, Azure ARM. Includes
  `az login` and `az account get-access-token` patterns for 401 debugging.
- [fabric-rest-api/](fabric/fabric-rest-api/) — Fabric REST patterns:
  pagination with `continuationToken`, long-running operations (202 +
  Location + polling), `jobType` values, item definitions, `?updateMetadata`.
- [fabric-cli/](fabric/fabric-cli/) — `fab` CLI: filesystem-style access over
  Fabric + Power BI REST. Path syntax, navigation, item CRUD, ACLs,
  capacity/domain, jobs, `fab api` REST passthrough.
- [fabric-cicd/](fabric/fabric-cicd/) — the fabric-cicd Python deployment
  library: `FabricWorkspace` / `publish_all_items`, `parameter.yml`
  substitution model, `config.yml` deploys, feature flags, ADO /
  GitHub Actions wiring.
- [fabric-data-pipeline/](fabric/fabric-data-pipeline/) — DataPipeline item
  as Git serializes it: the `pipeline-content.json` envelope, activity
  anatomy and `policy`, the activity-type enum including the
  `InvokePipeline` → `ExecutePipeline` deprecation, deactivation via
  `state` + `onInactiveMarkAs`, and the `.schedules` job-scheduler file
  nothing else in the payload reaches. Named for the item type rather
  than `fabric-pipeline` because "pipeline" already means deployment and
  release pipelines in `fabric-cicd`'s territory. Expression syntax stays
  in the `coding-expressions` rule, which co-loads on the same file.
- [fabric-copy-job/](fabric/fabric-copy-job/) — Copy job item: full vs
  incremental modes, watermark vs CDC incremental, JSON definition,
  REST + on-demand runs, Activator invocation.
- [fabric-mirroring/](fabric/fabric-mirroring/) — Mirroring: the three kinds
  (database replication, metadata-over-shortcuts, open mirroring's landing
  zone), which kind each source uses, the `MirroredDatabase` REST surface,
  and the limits. Named for the capability rather than the item because
  metadata mirroring creates a mirrored *catalog*, not a mirrored database.
  The boundary against `fabric-copy-job` — both are pitched as "no
  pipeline" — is drawn in its description.
- [fabric-warehouse/](fabric/fabric-warehouse/) — Fabric Warehouse T-SQL,
  unsupported types, MERGE constraints, COPY INTO auth.
- [fabric-database/](fabric/fabric-database/) — Fabric SQL database.
- [fabric-eventhouse/](fabric/fabric-eventhouse/) — Fabric Eventhouse + KQL.
- [fabric-eventstream/](fabric/fabric-eventstream/) — Fabric Eventstream.
- [fabric-realtime-dashboard/](fabric/fabric-realtime-dashboard/) — Real-Time
  Dashboard (KQLDashboard) JSON authoring: baseQueries wiring,
  load-time validation rules, 24-column grid, visual options,
  display-edge formatting in KQL.
- [fabric-graph/](fabric/fabric-graph/) — GraphModel item: GQL queries and
  graph-type DDL over OneLake Delta tables, executeQuery REST API.
- [fabric-mlv/](fabric/fabric-mlv/) — Materialized Lake Views: `CREATE
  MATERIALIZED LAKE VIEW` Spark SQL + the preview `@fmlv` PySpark
  decorator. Refresh modes, CDF prerequisite, lineage scheduling.
- [fabric-spark/](fabric/fabric-spark/) — Fabric Spark patterns.
- [fabric-warehouse-monitoring/](fabric/fabric-warehouse-monitoring/) —
  Warehouse query monitoring: `OPTION (LABEL = ...)`, `queryinsights`
  schema, retention windows.
- [fabric-spark-monitoring/](fabric/fabric-spark-monitoring/) — Spark runtime
  diagnostics via the monitoring REST APIs: Livy session listings,
  Spark History Server mirror, five-phase wall-clock attribution,
  high-concurrency session reuse verification.
- [fabric-security/](fabric/fabric-security/) — workspace roles, item-level
  permissions, SQL GRANT/DENY/REVOKE, RLS/CLS bypass via Spark/OneLake.
- [fabric-tmdl/](fabric/fabric-tmdl/) — TMDL semantic-model authoring.
- [fabric-tmdl-api/](fabric/fabric-tmdl-api/) — Semantic Model Definition API
  (createItemWithDefinition, getDefinition, updateDefinition); the
  two-audience rule, definition envelope, Direct Lake partitions.
- [fabric-semantic-model-ai-instructions/](fabric/fabric-semantic-model-ai-instructions/)
  — Copilot semantic model AI-instructions authoring.
- [fabric-data-agent/](fabric/fabric-data-agent/) — Fabric Copilot data agent.
- [fabric-ai-functions/](fabric/fabric-ai-functions/) — `ai.*` LLM functions
  on pandas/PySpark DataFrames in notebooks: import paths, config
  objects, custom endpoints, billing meters.
- [fabric-variable-library/](fabric/fabric-variable-library/) — variable
  libraries.
- [fabric-error-handling/](fabric/fabric-error-handling/) — error-handling
  conventions across Fabric components.
- [fabric-gotchas/](fabric/fabric-gotchas/) — common 401/403/404 failures,
  PowerBIEntityNotFound, snapshot conflicts, plus a MUST/PREFER/AVOID
  best-practices summary.

## Power BI Desktop / Reports (12)

- [pbid-tom-live/](powerbi/pbid-tom-live/) — script an open Power BI Desktop
  model via its localhost `msmdsrv` Analysis Services proxy: TOM for
  metadata, ADOMD.NET for DAX, VertiPaq DMVs, EVALUATEANDLOG, Server
  Timings, DAXLib UDF packages.
- [pbip-project-structure/](powerbi/pbip-project-structure/) — PBIP folder
  layout.
- [pbir-cli/](powerbi/pbir-cli/) — `pbir` CLI for inspecting and editing
  PBIR reports (verb/noun groups: report, page, visual, filter,
  bookmark, theme, dax, fields, schema, etc.).
- [pbir-report-workflow/](powerbi/pbir-report-workflow/) — end-to-end
  report build: KPI/filter/granularity requirements, model field
  discovery, scaffold, 3-30-300 visual hierarchy, layout math, sort,
  filters, conditional formatting, validation, publish, then
  service-side visual verification via the `exportToFile` PNG API.
- [powerbi-report-authoring/](powerbi/powerbi-report-authoring/) — **vendored**
  from [microsoft/skills-for-fabric](https://github.com/microsoft/skills-for-fabric)
  (v0.3.13, MIT): PBIR mechanics with the `powerbi-report-author`
  CLI (offline validate, visual-role/formatting catalogs), ~50-row
  anti-pattern table, deep per-visual-type references. Desktop Bridge
  sections present but skipped locally — see its vendoring note.
- [powerbi-report-design/](powerbi/powerbi-report-design/) — **vendored**
  from microsoft/skills-for-fabric (v0.3.13, MIT): report design
  system — tone catalog, 5 page archetypes, chart selection, visual
  cookbook, WCAG accessibility, anti-patterns, Design Brief YAML
  contract, curated base theme JSON.
- [pbir-pages/](powerbi/pbir-pages/) — pages.
- [pbir-bookmarks/](powerbi/pbir-bookmarks/) — bookmarks.
- [pbir-filters/](powerbi/pbir-filters/) — report and page filters.
- [pbir-themes/](powerbi/pbir-themes/) — themes.
- [pbir-conditional-formatting/](powerbi/pbir-conditional-formatting/) —
  conditional formatting for visuals.
- [pbir-visual-json/](powerbi/pbir-visual-json/) — visual JSON structure.
