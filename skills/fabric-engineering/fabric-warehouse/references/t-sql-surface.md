# Supported T-SQL surface and OPENROWSET

What works (as opposed to the unsupported lists in `SKILL.md`, which are the
ones that bite), plus the OPENROWSET read/ingest surface.

## Supported features

- Standard and nested CTEs
- Window functions (ROW_NUMBER, RANK, DENSE_RANK, NTILE, LAG, LEAD, aggregates OVER)
- CROSS APPLY / OUTER APPLY
- PIVOT / UNPIVOT
- FOR JSON (last operator only)
- COALESCE, NULLIF, IIF, CHOOSE
- `ROLLUP`, `CUBE`, `GROUPING SETS` and the `()` grand total in `GROUP BY` — counted among What's New's "Warehouse T-SQL enhancements" (preview, 2026-10-02), but standard T-SQL that SQL Server, Azure SQL and SQL database in Fabric support too, so not Warehouse-only
- Cross-database queries via 3-part naming (same workspace AND same region only)
- Session-scoped #temp tables (prefer distributed with `WITH (DISTRIBUTION = ROUND_ROBIN)`)

## Warehouse-only query syntax

Warehouse and SQL analytics endpoint only: Learn says SQL Server, Azure SQL Database, Managed Instance and **SQL database in Fabric** don't support these. Status is split: What's New labels them preview ("Warehouse T-SQL enhancements", "Warehouse analytical functions", 2026-10-02), while the Learn syntax pages carry no preview label (2026-10-06). Gate production use until the two agree.

- **FROM-first queries** — `FROM dbo.Customer SELECT CustomerId, CustomerName;`. The trailing `SELECT` is optional and **omitting it means `SELECT *`**; `SELECT`-first and `FROM`-first can't mix in one query block.
- **`GROUP BY ALL` / `ORDER BY ALL`** without a column list. Not SQL Server's deprecated `GROUP BY ALL <columns>`, which means something else.
- **`QUALIFY`** — filters on window-function results after they are computed (`FROM` → `WHERE` → `GROUP BY` → `HAVING` → window functions → `QUALIFY` → `ORDER BY`), so top-N per group needs no CTE or subquery. The predicate must contain a window function; `UPDATE` and `DELETE` don't accept it.
- **`MEDIAN`, `QUANTILE`** (exact) and **`APPROX_MEDIAN`, `APPROX_QUANTILE`** (approximate, cheaper on large data) — aggregate or window form, `OVER` takes `PARTITION BY` only, numeric input only, no `DISTINCT`, returns `float(53)`.

## OPENROWSET surface

- Formats: **Parquet, CSV, TSV, JSONL**
- Available on Warehouse for read AND ingest (CTAS / `INSERT...SELECT`)
- Explicit schema via `WITH (col type, ...)` clause when needed
- Wildcards and Hive-partitioned paths supported (`year=*/month=*/*.parquet`)
- Complex Parquet types (maps, lists) returned as JSON text — use `JSON_VALUE` / `OPENJSON`
- Slower than materialized tables — ingest for repeated access

## Ingestion options

- **COPY INTO** for external file ingestion — highest throughput. `FILE_TYPE`: `PARQUET` / `CSV` / `JSONL` (JSONL added April 2026). Requires Storage Blob Data Reader on ADLS or SAS in CREDENTIAL. Set `WITH (AUTO_CREATE_TABLE = 'TRUE')` to create the target table on the fly. Files ≥ 4 MB optimal.
  - **Workspace identity** is a third option (GA, August 2026): `WITH (CREDENTIAL = (IDENTITY = 'Workspace Identity'))` impersonates the workspace identity only when reading the source — Azure Blob Storage, ADLS Gen2 or OneLake — while the statement runs as, and is audited to, the executing user. Grant the workspace identity Storage Blob Data Reader on the storage (Blob, ADLS Gen2) or Contributor on the source workspace (OneLake); the user needs at least Viewer on the target warehouse's workspace and `INSERT` on the table, but not `ADMINISTER DATABASE BULK OPERATIONS`.
- **`bcp` is supported as a preview feature** for bulk load/export from the command line; the same BCP API (preview) serves client APIs such as C# `SqlBulkCopy` and Java `SQLServerBulkCopy`. The `BULK LOAD` T-SQL statement is **not** supported. `BULK INSERT` **is**, for compatibility: Warehouse maps it to `COPY INTO` behavior with classic loading options, so it carries SQL Server code over, but write new in-engine ingestion as COPY INTO / OPENROWSET (Learn, 2026-10-06; before then this file called `BULK INSERT` unsupported).

## CTAS Synapse-vs-Fabric rules

These rules differ from dedicated SQL pools (Synapse) — common gotcha when porting:

- `WITH (DISTRIBUTION = ...)` — **not supported** (distribution is engine-managed)
- `CLUSTERED COLUMNSTORE INDEX` hints — **not supported** (indexing is automatic)
- `WITH (CLUSTER BY (col1, col2, ...))` — **supported** (max 4 columns; preview)
- Explicit column definitions — **not allowed** (types inferred from SELECT)
- Variables in CTAS — **not allowed** (wrap in `sp_executesql`)
- Use explicit `CAST()` to control inferred types
