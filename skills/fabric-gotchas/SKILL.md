---
name: fabric-gotchas
description: "Use when troubleshooting Microsoft Fabric — common errors: 401 (wrong token audience), 403 on Power BI API (Viewer role), 404 EntityNotFound on getDefinition (permissions masquerading), PowerBIEntityNotFound from pipeline/Variable Library (logicalId vs runtime ID confusion), Login failed (wrong Initial Catalog), 24556/24706 snapshot conflict, nvarchar/datetime/money errors (Warehouse unsupported types), COPY INTO auth, MERGE/ALTER COLUMN failures, TMDL validation (tabs vs spaces, /// comments), DefaultJob jobType mistake, sqlcmd version, slow SQLEP (small files), notebook `400 exceptionCulprit:1` (bare-string cell source), plus the MUST/PREFER/AVOID best-practices summary."
---

# Common gotchas & troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| `401 Unauthorized` | Wrong token audience | Check audience table in fabric-auth skill; verify `aud` claim at jwt.ms |
| `403 Forbidden` on Power BI API | User has Viewer role | Refresh/data sources/permissions APIs require Contributor+. Stop retrying — it's permissions. |
| `404 EntityNotFound` on getDefinition | Insufficient permissions masquerading as 404 | Check workspace role first; don't retry with different URLs |
| `PowerBIEntityNotFound` / `EntityNotFound` from pipeline, Variable Library, or REST call | Used `.platform` `logicalId` instead of runtime item ID | Fetch runtime ID from Fabric portal URL or `GET /v1/workspaces/{wsId}/items`. See fabric-rest-api skill (Item IDs section) |
| `Login failed... database not found` | Wrong Initial Catalog | Use item display name, not FQDN. Verify workspace role. |
| Error 24556/24706 snapshot conflict | Concurrent writes to same table | Serialize writes; retry with backoff |
| `nvarchar` / `datetime` / `money` errors | Unsupported types in Fabric Warehouse | Use `varchar`, `datetime2(6)`, `decimal(19,4)` (Warehouse only — fabric-database skill supports these) |
| COPY INTO auth error | Missing Storage Blob Data Reader on ADLS | Grant role or use SAS in CREDENTIAL |
| MERGE failures in production | Preview feature with table-level conflict detection | Use DELETE + INSERT pattern instead (Warehouse only — fabric-database skill supports MERGE) |
| ALTER COLUMN fails | Not supported in Fabric Warehouse | Use CTAS + sp_rename workaround (Warehouse only — fabric-database skill supports ALTER COLUMN) |
| TMDL validation error | Spaces instead of tabs, or `//` comments | Use literal tabs; use `///` for descriptions |
| Parts missing after updateDefinition | Only modified parts sent | Must include ALL parts in every update |
| `DefaultJob` in job execution | Wrong jobType | Use type-specific values: `RunNotebook`, `Pipeline`, `SparkJob`, `Refresh` |
| `sqlcmd` not found or ODBC errors | Wrong sqlcmd version | Use Go version: `winget install sqlcmd` (not ODBC `/opt/mssql-tools/` version) |
| Slow Lakehouse SQLEP queries | Small-file problem | Run OPTIMIZE and VACUUM via Spark |
| Query Insights empty | Views not yet generated after creation | Wait ~2 minutes |
| OneLake 401 | Wrong storage audience | Must use `https://storage.azure.com/.default` exactly |
| TDS connection timeout | Port 1433 blocked | Open outbound TCP 1433; allow `*.datawarehouse.fabric.microsoft.com` |
| Cross-database query fails | Items in different regions or workspaces | All items must share same workspace AND region |
| Notebook upload `400 exceptionCulprit:1` | Cell `source` is a bare string, not an array | Convert every cell's `source` to array-of-strings form (`["line\n", "line\n", "last"]`). Applies to markdown and code cells. |

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
