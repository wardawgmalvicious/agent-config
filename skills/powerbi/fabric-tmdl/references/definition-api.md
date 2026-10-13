# Semantic Model Definition API rules

- **Two audiences**: Fabric API (`api.fabric.microsoft.com`) for CRUD on definitions; Power BI API (`analysis.windows.net/powerbi/api`) for refresh, data sources, permissions
- **`updateDefinition` must include ALL parts** — modified AND unmodified. The API replaces the entire definition; omitting parts deletes them.
- **Never include `.platform`** in `updateDefinition` payloads — it is Git integration metadata and causes errors. Bulk Import is the exception: its parts carry each item's `.platform`
- **Base64-encode all TMDL content** in definition payloads
- **`getDefinition` is a POST** (not GET) — requires `--body '{}'`
- **Poll LRO to completion** — `createItemWithDefinition`, `getDefinition` and `updateDefinition` can each answer `202` instead of `200` (a create, `201`); branch on the status code, as fabric-rest-api says

## Required TMDL Parts

| Part Path | Content |
|---|---|
| `definition.pbism` | Semantic model connection settings (JSON) |
| `definition/database.tmdl` | `database` declaration + `compatibilityLevel: 1702` |
| `definition/model.tmdl` | Model properties + `ref` declarations for tables/roles/etc. |
| `definition/tables/<TableName>.tmdl` | Per-table: measures, columns, partitions |

`database.tmdl` starts with the `database` object declaration, not bare properties: a bare `compatibilityLevel:` fails with `InvalidLineType: Property!`.

## model.tmdl Required Properties

```tmdl
model Model
	culture: en-US
	defaultPowerBIDataSourceVersion: powerBI_V3
	discourageImplicitMeasures
```

`defaultPowerBIDataSourceVersion: powerBI_V3` is required for Import-mode models. Without it: `Import from JSON supported for V3 models only`.

## Direct Lake Configuration

- ALL partitions must use `EntityPartitionSource` — no M/Power Query
- A named expression pointing to the Lakehouse/Warehouse must be defined before tables:

  ```tmdl
  expression DL_Lakehouse =
  		let
  			Source = AzureStorage.DataLake("https://onelake.dfs.fabric.microsoft.com/<WorkspaceId>/<LakehouseId>", [HierarchicalNavigation=true])
  		in
  			Source
  ```

- Each table partition references the expression:

  ```tmdl
  partition Sales = entity
  	mode: directLake
  	source
  		entityName: Sales
  		schemaName: dbo
  		expressionSource: DL_Lakehouse
  ```

- `dataType: binary` columns are NOT supported in Direct Lake
- Columns map directly via `sourceColumn` — no transforms
- **Calculated columns / tables (April 2026 preview)**: Direct Lake on **OneLake** now supports unmaterialized calculated columns (and calculated tables that reference them). Direct Lake on **SQL** still does not. User-context-aware DAX (`USERCULTURE`, `USERPRINCIPALNAME`, `CUSTOMDATA`, etc.) requires `expressionContext: userContext` on the column. Authorable in **Power BI Desktop and web modeling**, without changing storage mode. See [REFERENCE.md](REFERENCE.md) for the storage-mode × Expression-Context support matrix.

## Reference

- Microsoft Learn: [Item definition overview (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview)
- Microsoft Learn: [SemanticModel definition envelope](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition)
- Microsoft Learn: [Develop Direct Lake semantic models (TMDL partition mode)](https://learn.microsoft.com/fabric/fundamentals/direct-lake-develop)
- Comprehensive MS Learn link bundle (definition envelope / REST CRUD / TMDL language / required parts / Direct Lake configuration / refresh APIs): [§ MS Learn link bundle](#ms-learn-link-bundle), below

## MS Learn link bundle

Curated set of Microsoft Learn pages relevant to the Fabric Semantic Model Definition API — `createItemWithDefinition`, `getDefinition`, `updateDefinition`, the TMDL/TMSL definition envelope, and the Direct Lake partition configuration this file highlights.

The 3 highest-leverage entry points (Item Definition overview, Semantic Model definition envelope, Direct Lake develop/manage) are also linked in § Reference above for in-context use; this section holds the comprehensive set.

**Note on docs split:** The Fabric REST + definition envelope lives under `learn.microsoft.com/rest/api/fabric/`. TMDL language semantics and TOM/AMO authoring live under `learn.microsoft.com/analysis-services/tmdl/`. The Direct Lake concepts live under `learn.microsoft.com/fabric/fundamentals/direct-lake-*`. All three branches are linked.

### Definition envelope and REST API

- [Item definition overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview) — concept: definition-based vs non-definition APIs (Get / Update / Create with Definition), the `.platform` part rules, the `?updateMetadata=true` requirement to *modify* `.platform` via Update Item Definition. Confirms platform file is *only* respected on Update if the URL parameter is set.
- [SemanticModel definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition) — full part list (`definition/` for TMDL, `model.bim` for TMSL — mutually exclusive; `definition.pbism` settings; `diagramLayout.json` optional) plus the `definition.pbism` schema example (`version: "5.0"`, `qnaEnabled` setting).
- [Get Item Definition (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/core/items/get-item-definition) — POST-with-empty-body endpoint; LRO behavior; returns base64 parts.
- [Update Item Definition (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/core/items/update-item-definition) — REPLACES entire definition (omitted parts are deleted); `?updateMetadata=true` flag for `.platform`.
- [Create Item with Definition (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/core/items/create-item) — combined POST that creates the item and seeds its definition in one LRO.
- [Bulk Import Item Definitions](https://learn.microsoft.com/rest/api/fabric/core/items/bulk-import-item-definitions) / Bulk Export — GA (September 2026); multi-item versions for migration scenarios. Bulk import takes SemanticModel parts, and `.platform` parts with them.
- [Long-running operations (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/articles/long-running-operation) — 202 → poll `/operations/{id}` → `/result` pattern for all three definition APIs.

### Two audiences (Fabric API for definitions vs Power BI API for refresh)

- [Microsoft Fabric REST API — overview](https://learn.microsoft.com/rest/api/fabric/articles/) — `api.fabric.microsoft.com` audience.
- [Power BI REST API — refresh dataset](https://learn.microsoft.com/rest/api/power-bi/datasets/refresh-dataset) — `analysis.windows.net/powerbi/api` audience for refresh.
- [Power BI REST API — datasources / data source bindings](https://learn.microsoft.com/rest/api/power-bi/datasets/get-datasources) — Power BI audience for data-source operations.
- See `fabric-rest-api`'s `references/auth.md` for the full token-audience table and `az login` flow.

### TMDL language reference

- [TMDL overview](https://learn.microsoft.com/analysis-services/tmdl/tmdl-overview) — language semantics: tabs-only indentation, sections, default property syntax, multi-line expressions with the indented-block rule, the triple-backtick literal block, `///` for descriptions.
- [Get started with TMDL](https://learn.microsoft.com/analysis-services/tmdl/tmdl-how-to) — `TmdlSerializer` API: read TMDL into a TOM model and write back. The C#/PowerShell entry point.
- [TMDL scripts](https://learn.microsoft.com/analysis-services/tmdl/tmdl-scripts) — `createOrReplace` command verb syntax for partial-model deployment.
- [TMDL VS Code extension](https://marketplace.visualstudio.com/items?itemName=analysis-services.TMDL) — syntax highlighting + IntelliSense.
- See `fabric-tmdl`'s [SKILL.md](../SKILL.md) for the in-house authoring rules.

### Required parts in detail

- [TMSL Database object reference](https://learn.microsoft.com/analysis-services/tmsl/database-object-tmsl) — the `database` object whose declaration `database.tmdl` MUST start with (the "InvalidLineType: Property!" rule above).
- [`compatibilityLevel` property](https://learn.microsoft.com/analysis-services/tabular-models/compatibility-level-for-tabular-models-in-analysis-services) — 1604 minimum for Direct Lake, 1702+ for DAXLib, 1604+ for Calendar Column Groups. Required in `database.tmdl`.
- [Power BI Desktop project semantic model folder](https://learn.microsoft.com/power-bi/developer/projects/projects-dataset) — folder layout reference (`definition/`, `model.bim`, `definition.pbism`, `diagramLayout.json`, `.platform`). The same structure the REST API expects.
- [`definition.pbism` schema](https://github.com/microsoft/json-schemas/tree/main/fabric/item/semanticModel/definitionProperties) — version → format mapping (1.0 = TMSL only, 4.0+ = TMSL or TMDL, current = 5.0).

### Direct Lake partition configuration

- [Direct Lake overview](https://learn.microsoft.com/fabric/fundamentals/direct-lake-overview) — concept: framing, Direct Lake on SQL vs OneLake, comparison vs Import/DirectQuery (hybrid tables and model table partitions unsupported in **both** DL modes; calculated columns/tables unsupported on DL on **SQL** but supported on DL on **OneLake** — User Context only, preview, unmaterialized).
- [Develop Direct Lake semantic models](https://learn.microsoft.com/fabric/fundamentals/direct-lake-develop) — TMDL-level details: `compatibilityLevel >= 1604`, `mode: directLake` partition property, the shared expression that points to the data source. Direct Lake on OneLake uses `AzureStorage.DataLake(...)`; Direct Lake on SQL uses `Sql.Database(...)` or `OneLake.SqlAnalytics()`.
- [Direct Lake in Power BI Desktop — migrate Direct Lake on SQL → OneLake](https://learn.microsoft.com/fabric/fundamentals/direct-lake-power-bi-desktop#migrate-direct-lake-on-sql-semantic-models-to-direct-lake-on-onelake) — exact TMDL edits to swap the source expression: `Sql.Database(...)` → `AzureStorage.DataLake("https://onelake.dfs.fabric.microsoft.com/<wsId>/<lakehouseId>")`. Also documents the `schemaName` removal for non-schema lakehouses.
- [How Direct Lake works (framing, automatic updates, fallback)](https://learn.microsoft.com/fabric/fundamentals/direct-lake-how-it-works) — what a "refresh" actually does for a Direct Lake model.
- [Manage Direct Lake semantic models](https://learn.microsoft.com/fabric/fundamentals/direct-lake-manage) — post-publication tasks (cloud connection, fixed identity for RLS, fallback behavior).
- [Direct Lake fixed identity](https://learn.microsoft.com/fabric/fundamentals/direct-lake-fixed-identity) — required for RLS in production.
- [Integrate Direct Lake security (OLS / RLS)](https://learn.microsoft.com/fabric/fundamentals/direct-lake-security-integration) — what's supported when.

### Refresh operations (Power BI audience, complementary to definition APIs)

- [Refresh datasets (Power BI REST)](https://learn.microsoft.com/rest/api/power-bi/datasets/refresh-dataset) — kick off a refresh after `updateDefinition`.
- [Get refresh history](https://learn.microsoft.com/rest/api/power-bi/datasets/get-refresh-history) — poll status.
- [Refresh policy / incremental refresh](https://learn.microsoft.com/power-bi/connect-data/incremental-refresh-overview) — for Import partitions.
- [Process operations via XMLA endpoint](https://learn.microsoft.com/power-bi/enterprise/service-premium-connect-tools) — alternative refresh path via XMLA (Power BI audience).

## See also

- fabric-tmdl's [SKILL.md](../SKILL.md) — TMDL authoring rules at the file level
- fabric-rest-api skill — LRO polling pattern, runtime item ID vs logicalId, the 201-or-202 create pattern; Fabric vs Power BI audience selection in its `references/auth.md`; `fab export` / `fab import`, which wrap these APIs, in its `references/cli.md`
