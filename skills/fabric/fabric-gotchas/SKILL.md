---
name: fabric-gotchas
description: "Use when troubleshooting Microsoft Fabric — common errors: 401 (wrong token audience), 403 on Power BI API (Viewer role), 404 EntityNotFound (permissions masquerading), PowerBIEntityNotFound (logicalId vs runtime ID), Login failed (wrong Initial Catalog), 24556/24706 snapshot conflict, nvarchar/datetime/money errors (Warehouse unsupported types), COPY INTO auth, MERGE/ALTER COLUMN failures, TMDL validation (tabs vs spaces, /// comments), DefaultJob jobType mistake, sqlcmd version, slow SQLEP (small files), notebook `400 exceptionCulprit:1` (bare-string cell source), Variable Library `InvalidContent (ValueMismatch)` (stale override / empty value), greyed-out deployment-rule dropdowns (Direct Lake), DirectQuery-transformations refresh error, PBIR-Legacy format, MissingDefinitionParts, empty visuals after publish (byConnection rebind), empty Top-N visuals + frozen save (bad TopN filter), RTDB `baseQueryId` error, Runtime 2.0 `LibraryManagementError` (republish environment), plus MUST/PREFER/AVOID summary."
model: inherit
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Common gotchas & troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| `401 Unauthorized` | Wrong token audience | Check audience table in fabric-auth skill; verify `aud` claim at jwt.ms |
| `403 Forbidden` on Power BI API | User has Viewer role | Refresh/data sources/permissions APIs require Contributor+. Stop retrying — it's permissions. |
| `404 EntityNotFound` on getDefinition | Insufficient permissions masquerading as 404 | Check workspace role first; don't retry with different URLs |
| `PowerBIEntityNotFound` / `EntityNotFound` from pipeline, Variable Library, or REST call | Used `.platform` `logicalId` instead of runtime item ID | Fetch runtime ID from Fabric portal URL or `GET /v1/workspaces/{wsId}/items`. See fabric-rest-api skill (Item IDs section) |
| `Login failed... database not found` | Wrong Initial Catalog | Use item display name, not FQDN. Verify workspace role. Connections with no Initial Catalog now land deterministically on `master` (drill-verified) — confirm with `SELECT DB_NAME()` and switch with `USE [<item display name>]` instead of reconnecting. |
| Error 24556/24706 snapshot conflict | Concurrent writes to same table | Serialize writes; retry with backoff |
| `nvarchar` / `datetime` / `money` errors | Unsupported types in Fabric Warehouse | Use `varchar`, `datetime2(6)`, `decimal(19,4)` (Warehouse only — fabric-database skill supports these) |
| COPY INTO auth error | Missing Storage Blob Data Reader on ADLS | Grant role or use SAS in CREDENTIAL |
| MERGE failures in production | Preview feature with table-level conflict detection | Use DELETE + INSERT pattern instead (Warehouse only — fabric-database skill supports MERGE) |
| ALTER COLUMN fails | Not supported in Fabric Warehouse | Use CTAS + sp_rename workaround (Warehouse only — fabric-database skill supports ALTER COLUMN) |
| TMDL validation error | Spaces instead of tabs, or `//` comments | Use literal tabs; use `///` for descriptions |
| Parts missing after updateDefinition | Only modified parts sent | Must include ALL parts in every update |
| `DefaultJob` in job execution | Wrong jobType | Use type-specific values: `RunNotebook`, `Pipeline`, `SparkJob`, `Refresh` |
| `sqlcmd` not found or ODBC errors | Wrong sqlcmd version | Use Go version: `winget install sqlcmd` (not ODBC `/opt/mssql-tools/` version) |
| Slow / stale Lakehouse SQLEP queries | Small-file problem, or metadata-sync lag on newly-landed data | Run OPTIMIZE and VACUUM via Spark. If on the new metadata-sync preview, diagnose staleness via the DMV / targeted refresh in the note below |
| Query Insights empty | Views not yet generated after creation | Wait ~2 minutes |
| OneLake 401 | Wrong storage audience | Must use `https://storage.azure.com/.default` exactly |
| TDS connection timeout | Port 1433 blocked | Open outbound TCP 1433; allow `*.datawarehouse.fabric.microsoft.com` |
| Cross-database query fails | Items in different regions or workspaces | All items must share same workspace AND region |
| Notebook upload `400 exceptionCulprit:1` | Cell `source` is a bare string, not an array | Convert every cell's `source` to array-of-strings form (`["line\n", "line\n", "last"]`). Applies to markdown and code cells. |
| `CloudEventPropertyMissingException: ...type is missing` when publishing to a schema-associated Eventstream custom endpoint | Attributes sent in the JSON body / structured mode | Send **binary**-mode CloudEvents: `cloudEvents:`-prefixed Event Hub application properties (not body). See [[fabric-eventstream]] — *Producing to a schema-associated custom endpoint* |
| `InvalidContent (first issue: ValueMismatch)` syncing Git → workspace | Variable Library value-set override names a nonexistent variable (rename not propagated to `valueSets/*.json`) or an empty `value` | Rename in **every** value-set file; never commit `""` values — use a `FILL-ME`-style sentinel. See [[fabric-variable-library]] |
| Deployment-rule dropdowns greyed out for a Direct Lake semantic model | DL on OneLake doesn't support data source rules; no M parameters exist yet for parameter rules (also requires item ownership) | Parameterize the workspace/lakehouse GUIDs as M parameters and use **parameter rules**. See [[fabric-tmdl]] — *Direct Lake Configuration* |
| `This query contains transformations that can't be used for DirectQuery` refreshing a Direct Lake model | Parameterized source + the model page's **schema-and-data** ribbon refresh, which re-evaluates the M (any parameterized shape) | False alarm: data-only / workspace-page / scheduled / pipeline refreshes work — they only reframe. See [[fabric-tmdl]] (observed 2026-08-24, undocumented) |
| Report getDefinition returns a single `report.json` (`"format": "PBIR-Legacy"`) | Report never migrated to the enhanced PBIR folder format; PBIR file tooling can't process legacy | Request `GET .../getDefinition?format=PBIR` explicitly; if it still comes back legacy, upgrade the report (open + save as PBIP in Desktop, or rebuild) before file-level editing |
| `MissingDefinitionParts` on report create/updateDefinition | Part `path` values built with Windows backslashes | Part paths must use forward slashes (`definition/pages/.../visual.json`) — build them explicitly, never from `os.path` / `Join-Path` output |
| Report publishes fine but every visual is empty | Local `byPath` dataset reference pushed as-is, or PBIR field bindings name tables/columns that don't exist in the target model | Rebind `definition.pbir` to `byConnection` (`"connectionString": "semanticmodelid=<runtime-id>"`) before REST publish; diff TMDL table/column names against the PBIR visual bindings to find mismatches |
| `Error loading dashboard / /tiles/N/queryRef ... must have required property 'baseQueryId'` | Malformed `queryRef.queryId` UUID — the schema's `oneOf` fails the query branch and reports the baseQuery branch instead | Fix the UUID (RFC-4122, generated not hand-typed). See [[fabric-realtime-dashboard]] (docs: git-real-time-dashboard) |
| `"LibraryManagementError": "An upgrade to the base Spark Python environment has been detected. Please republish the environment.\|UserError"`, or `warning: 1 deprecation (since 2.13.0); for details, enable :setting -deprecation or :replay -deprecation` with `Source: SparkCoreService` — on notebook or SJD execution | Fabric **Runtime 2.0**'s Python upgrade broke the environment item's python / wheel libraries | Republish the environment **empty-first**: remove all libraries → publish → re-add all libraries → publish again. See the Runtime 2.0 note below |
| Top-N visuals render empty AND the service report editor freezes on save-edits (report otherwise renders fine) | Hand-authored PBIR TopN filter with the subquery inlined in `In.Table` (or a bare `VisualTopN` condition) — passes schema validation and `pbir validate`, but the engine matches nothing and the editor can't rebuild the filter card | Use the Desktop-canonical shape: subquery declared as a `From` source (`Type: 2`), referenced via `In.Table.SourceRef`. See [[pbir-filters]] — *TopN* (verified vs microsoft/BCApps, 2026-08) |

> **Runtime 2.0 environment republish (Aug 2026):** the Python 3.13 upgrade in Fabric Runtime 2.0 breaks **environment items carrying python and wheel libraries**. The remedy is not idempotent-looking and not guessable: **remove all libraries → publish → re-add all libraries → publish again.** Republishing without emptying it first does not recreate the environment against the new Python. Nothing warns you before the switch, and Runtime 2.0 is planned to become the default for new workspaces and environment items in **late September 2026**, so this stops being opt-in. See [[fabric-mlv]] and [[fabric-ai-functions]] for the runtime-version prerequisites either side of it.

 on endpoints created with the new opt-in metadata sync, target a single table with `EXEC sys.sp_dw_refresh_ext_table '<schema.table>'` and inspect last sync time / blocked state via `sys.dm_db_external_tables_log_status`. Full preview note (scope, enablement, limitations): [[fabric-spark]].

---

## Best Practices Summary

### MUST

- Verify workspace has capacity before creating items (`capacityId` in workspace response)
- Use parameterized notebooks and pipelines — no hardcoded workspace/item IDs
- Use Delta Lake format for all Lakehouse tables
- Include time filters in KQL queries
- Label queries with `OPTION (LABEL = ...)` for tracking
- Always specify database name in SQL connections (`-d` flag or Initial Catalog)
- Use Entra ID auth everywhere — SQL auth not supported in Fabric

### PREFER

- Medallion architecture (Bronze/Silver/Gold) for data organization
- REST APIs for programmatic management over portal clicks
- Incremental processing over full refreshes
- CTAS over CREATE TABLE + INSERT for large transforms
- COPY INTO for external file ingestion
- DELETE + INSERT over MERGE for production upserts
- Distributed #temp tables (`ROUND_ROBIN`) over non-distributed
- `EXISTS` over `IN` for large subqueries
- `UNION ALL` over `UNION` when duplicates are acceptable
- Integer keys over string keys for relationships

### AVOID

- Hardcoded workspace/item IDs — discover via REST API
- Confusing `.platform` `logicalId` with runtime item ID — they are NOT interchangeable; runtime references need the portal/API ID
- `SELECT *` without LIMIT on large tables
- Long-running transactions (increases conflict window)
- Singleton `INSERT...VALUES` at scale (creates tiny Parquet files)
- `DROP TABLE IF EXISTS` + `CREATE TABLE` to refresh (loses time-travel history) — use TRUNCATE + INSERT
- `IFERROR` in DAX (performance degradation)
- `FOR XML` (use `FOR JSON` instead)
- Manual `lineageTag` or `PBI_*` annotations in TMDL
- Unbounded streaming queries
- MARS in connection strings

## Reference

- Microsoft Learn: [Troubleshoot the Warehouse (canonical error/cause/fix)](https://learn.microsoft.com/fabric/data-warehouse/troubleshoot-fabric-data-warehouse)
- Microsoft Learn: [T-SQL surface area in Fabric Data Warehouse (unsupported commands)](https://learn.microsoft.com/fabric/data-warehouse/tsql-surface-area)
- Microsoft Learn: [Transactions in Fabric Data Warehouse (24556/24706 write-write conflicts)](https://learn.microsoft.com/fabric/data-warehouse/transactions)
- Comprehensive MS Learn link bundle (per-error-class deep-dive index — auth/IDs/TDS/snapshot/T-SQL/COPY/REST/Lakehouse SQLEP/notebook/throttling/OneLake): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-auth skill — token audience table (for 401 diagnosis)
- fabric-rest-api skill — logicalId vs runtime ID detail
- fabric-warehouse skill — Warehouse-specific type and feature restrictions
- fabric-database skill — what's different when it's SQL Database (most restrictions don't apply)
- fabric-spark skill — notebook upload array-of-strings requirement
- fabric-realtime-dashboard skill — RealTimeDashboard.json wiring and validation rules
