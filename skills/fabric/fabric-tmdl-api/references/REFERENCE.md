# MS Learn link bundle — Fabric Semantic Model Definition API

Curated set of Microsoft Learn pages relevant to the Fabric Semantic Model Definition API — `createItemWithDefinition`, `getDefinition`, `updateDefinition`, the TMDL/TMSL definition envelope, and the Direct Lake partition configuration the parent skill highlights.

The 3 highest-leverage entry points (Item Definition overview, Semantic Model definition envelope, Direct Lake develop/manage) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** The Fabric REST + definition envelope lives under `learn.microsoft.com/rest/api/fabric/`. TMDL language semantics and TOM/AMO authoring live under `learn.microsoft.com/analysis-services/tmdl/`. The Direct Lake concepts live under `learn.microsoft.com/fabric/fundamentals/direct-lake-*`. All three branches are linked.

## Definition envelope and REST API

- [Item definition overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview) — concept: definition-based vs non-definition APIs (Get / Update / Create with Definition), the `.platform` part rules, the `?updateMetadata=true` requirement to *modify* `.platform` via Update Item Definition. Confirms platform file is *only* respected on Update if the URL parameter is set.
- [SemanticModel definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition) — full part list (`definition/` for TMDL, `model.bim` for TMSL — mutually exclusive; `definition.pbism` settings; `diagramLayout.json` optional) plus the `definition.pbism` schema example (`version: "5.0"`, `qnaEnabled` setting).
- [Get Item Definition (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/core/items/get-item-definition) — POST-with-empty-body endpoint; LRO behavior; returns base64 parts.
- [Update Item Definition (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/core/items/update-item-definition) — REPLACES entire definition (omitted parts are deleted); `?updateMetadata=true` flag for `.platform`.
- [Create Item with Definition (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/core/items/create-item) — combined POST that creates the item and seeds its definition in one LRO.
- [Bulk Import / Bulk Export Item Definitions (beta)](https://learn.microsoft.com/rest/api/fabric/core/items/bulk-import-item-definitions%28beta%29) — multi-item versions for migration scenarios.
- [Long-running operations (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/articles/long-running-operation) — 202 → poll `/operations/{id}` → `/result` pattern for all three definition APIs.

## Two audiences (Fabric API for definitions vs Power BI API for refresh)

- [Microsoft Fabric REST API — overview](https://learn.microsoft.com/rest/api/fabric/articles/) — `api.fabric.microsoft.com` audience.
- [Power BI REST API — refresh dataset](https://learn.microsoft.com/rest/api/power-bi/datasets/refresh-dataset) — `analysis.windows.net/powerbi/api` audience for refresh.
- [Power BI REST API — datasources / data source bindings](https://learn.microsoft.com/rest/api/power-bi/datasets/get-datasources) — Power BI audience for data-source operations.
- See `fabric-auth` skill for the full token-audience table and `az login` flow.

## TMDL language reference

- [TMDL overview](https://learn.microsoft.com/analysis-services/tmdl/tmdl-overview) — language semantics: tabs-only indentation, sections, default property syntax, multi-line expressions with the indented-block rule, the triple-backtick literal block, `///` for descriptions.
- [Get started with TMDL](https://learn.microsoft.com/analysis-services/tmdl/tmdl-how-to) — `TmdlSerializer` API: read TMDL into a TOM model and write back. The C#/PowerShell entry point.
- [TMDL scripts](https://learn.microsoft.com/analysis-services/tmdl/tmdl-scripts) — `createOrReplace` command verb syntax for partial-model deployment.
- [TMDL VS Code extension](https://marketplace.visualstudio.com/items?itemName=analysis-services.TMDL) — syntax highlighting + IntelliSense.
- See `fabric-tmdl` skill for the in-house authoring rules.

## Required parts in detail

- [TMSL Database object reference](https://learn.microsoft.com/analysis-services/tmsl/database-object-tmsl) — the `database` object whose declaration `database.tmdl` MUST start with (parent skill's "InvalidLineType: Property!" gotcha).
- [`compatibilityLevel` property](https://learn.microsoft.com/analysis-services/tabular-models/compatibility-level-for-tabular-models-in-analysis-services) — 1604 minimum for Direct Lake, 1702+ for DAXLib, 1604+ for Calendar Column Groups. Required in `database.tmdl`.
- [Power BI Desktop project semantic model folder](https://learn.microsoft.com/power-bi/developer/projects/projects-dataset) — folder layout reference (`definition/`, `model.bim`, `definition.pbism`, `diagramLayout.json`, `.platform`). The same structure the REST API expects.
- [`definition.pbism` schema](https://github.com/microsoft/json-schemas/tree/main/fabric/item/semanticModel/definitionProperties) — version → format mapping (1.0 = TMSL only, 4.0+ = TMSL or TMDL, current = 5.0).

## Direct Lake partition configuration

- [Direct Lake overview](https://learn.microsoft.com/fabric/fundamentals/direct-lake-overview) — concept: framing, Direct Lake on SQL vs OneLake, comparison vs Import/DirectQuery (calculated columns/hybrid tables/partitions all unsupported in DL).
- [Develop Direct Lake semantic models](https://learn.microsoft.com/fabric/fundamentals/direct-lake-develop) — TMDL-level details: `compatibilityLevel >= 1604`, `mode: directLake` partition property, the shared expression that points to the data source. Direct Lake on OneLake uses `AzureStorage.DataLake(...)`; Direct Lake on SQL uses `Sql.Database(...)` or `OneLake.SqlAnalytics()`.
- [Direct Lake in Power BI Desktop — migrate Direct Lake on SQL → OneLake](https://learn.microsoft.com/fabric/fundamentals/direct-lake-power-bi-desktop#migrate-direct-lake-on-sql-semantic-models-to-direct-lake-on-onelake) — exact TMDL edits to swap the source expression: `Sql.Database(...)` → `AzureStorage.DataLake("https://onelake.dfs.fabric.microsoft.com/<wsId>/<lakehouseId>")`. Also documents the `schemaName` removal for non-schema lakehouses.
- [How Direct Lake works (framing, automatic updates, fallback)](https://learn.microsoft.com/fabric/fundamentals/direct-lake-how-it-works) — what a "refresh" actually does for a Direct Lake model.
- [Manage Direct Lake semantic models](https://learn.microsoft.com/fabric/fundamentals/direct-lake-manage) — post-publication tasks (cloud connection, fixed identity for RLS, fallback behavior).
- [Direct Lake fixed identity](https://learn.microsoft.com/fabric/fundamentals/direct-lake-fixed-identity) — required for RLS in production.
- [Integrate Direct Lake security (OLS / RLS)](https://learn.microsoft.com/fabric/fundamentals/direct-lake-security-integration) — what's supported when.

## Refresh operations (Power BI audience, complementary to definition APIs)

- [Refresh datasets (Power BI REST)](https://learn.microsoft.com/rest/api/power-bi/datasets/refresh-dataset) — kick off a refresh after `updateDefinition`.
- [Get refresh history](https://learn.microsoft.com/rest/api/power-bi/datasets/get-refresh-history) — poll status.
- [Refresh policy / incremental refresh](https://learn.microsoft.com/power-bi/connect-data/incremental-refresh-overview) — for Import partitions.
- [Process operations via XMLA endpoint](https://learn.microsoft.com/power-bi/enterprise/service-premium-connect-tools) — alternative refresh path via XMLA (Power BI audience).

## Related skills in this repo

- See `fabric-tmdl` skill for TMDL authoring rules at the file level.
- See `fabric-rest-api` skill for LRO polling, runtime ID vs `.platform` `logicalId`, the 201-or-202 create pattern.
- See `fabric-cli` skill for `fab export` / `fab import` which wrap these REST endpoints.
