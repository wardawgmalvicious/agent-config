---
name: fabric-warehouse
description: "Use for T-SQL against Fabric Warehouse (NOT Fabric SQL Database — see fabric-database). Covers unsupported types (nvarchar/datetime/money/xml/tinyint/hierarchyid), unsupported features (FOR XML, recursive CTEs, triggers, CREATE USER, cursors), MERGE (GA Jan 2026), ALTER COLUMN (preview), schema evolution (ADD nullable / DROP COLUMN / sp_rename, IDENTITY GA Aug 2026 (bigint, RESEED), transactional ALTER TABLE GA April 2026, CTAS workaround), PK/UNIQUE/FK NONCLUSTERED+NOT ENFORCED only, 8060-byte row limit, CTAS Synapse-vs-Fabric rules (no DISTRIBUTION/CCI/variables), COPY INTO with AUTO_CREATE_TABLE + bcp (preview), OPENROWSET surface, snapshot-only isolation (24556/24706 retry), DDL in transactions (Sch-M blocks reads), Time Travel (UTC, single per SELECT; SQLEP preview) + Warehouse Snapshots (GA, REST/portal), sp_get_table_health_metrics (SQLEP), GPU query acceleration (preview), Recycle-bin recovery, source control/CI-CD (preview, incl. SQLEP), pipeline calls via Script activity (NOT Stored Procedure)."
paths:
  - "**/*.Warehouse/**/*.sql"
---

# Fabric Warehouse T-SQL surface area

**Note**: This skill applies to Fabric Warehouse only — the distributed Synapse-engine warehouse. Fabric SQL Database uses the full Azure SQL Database engine and does NOT have these restrictions. See the fabric-database skill.

## Unsupported Data Types — Use These Alternatives

| Unsupported Type | Use Instead | Notes |
|---|---|---|
| `nvarchar` / `nchar` | `varchar` / `char` | UTF-8 collation handles Unicode |
| `money` / `smallmoney` | `decimal(19,4)` | |
| `datetime` / `smalldatetime` | `datetime2(6)` | |
| `datetimeoffset` | `datetime2(6)` | Timezone offset is lost |
| `xml` | `varchar(max)` | XML functions lost |
| `ntext` / `text` | `varchar(max)` | |
| `image` | `varbinary(max)` | |
| `tinyint` | `smallint` | |
| `geometry` / `geography` | `varbinary` (WKB) or `varchar` (WKT) | Cast as needed |
| `sql_variant` | No equivalent | |
| `hierarchyid` | No equivalent | |

## Unsupported T-SQL Features

- `FOR XML` — use `FOR JSON` instead (and only as last operator, not in subqueries)
- Recursive CTEs
- `SET ROWCOUNT` / `SET TRANSACTION ISOLATION LEVEL`
- Materialized views
- Triggers
- **Cursors** — replace with `WHILE` + `ROW_NUMBER()`. Row-by-row is slow on a distributed engine; prefer set-based whenever possible.
- `CREATE USER` — users auto-created on GRANT/DENY
- Multi-column manual statistics
- `PREDICT`
- Schema/table names with `/` or `\`
- MARS (Multiple Active Result Sets) — remove from connection strings

## Supported Features

- Standard and nested CTEs
- Window functions (ROW_NUMBER, RANK, DENSE_RANK, NTILE, LAG, LEAD, aggregates OVER)
- CROSS APPLY / OUTER APPLY
- PIVOT / UNPIVOT
- FOR JSON (last operator only)
- COALESCE, NULLIF, IIF, CHOOSE
- Cross-database queries via 3-part naming (same workspace AND same region only)
- Session-scoped #temp tables (prefer distributed with `WITH (DISTRIBUTION = ROUND_ROBIN)`)

## Table Constraints and Limits

- **8,060-byte row limit** (error 511 / 611 on violation)
- **128-char limit** on table/column names
- **1,024-column max** per table
- No default value constraints; no computed columns (use views)
- **PK / UNIQUE / FK supported only as `NONCLUSTERED + NOT ENFORCED`** — metadata-only; the engine does not enforce them at DML time. They serve as optimizer hints, and Power BI uses FK relationships for automatic relationship detection.
- `DEFAULT` / `CHECK` not supported
- `NOT NULL` only via `CREATE TABLE` (cannot be added via `ALTER TABLE`)

## Schema Evolution

| Operation | Status | Syntax |
|---|---|---|
| Add nullable column | ✅ | `ALTER TABLE t ADD col type NULL` |
| Drop column | ✅ April 2025+ | `ALTER TABLE t DROP COLUMN col` (metadata-only) |
| Rename column | ✅ April 2025+ | `EXEC sp_rename 't.OldCol', 'NewCol', 'COLUMN'` |
| Rename table | ✅ | `EXEC sp_rename 'OldName', 'NewName'` |
| Add / drop `NONCLUSTERED NOT ENFORCED` PK / UNIQUE / FK | ✅ | `ALTER TABLE t ADD CONSTRAINT ... NONCLUSTERED NOT ENFORCED` / `DROP CONSTRAINT` |
| ALTER TABLE inside `BEGIN TRAN ... COMMIT` | ✅ April 2026+ GA | All supported ALTER TABLE variants run atomically; any failure rolls every schema change back |
| `ALTER COLUMN` — **widen** type (metadata-only) | 🔶 Preview | `ALTER TABLE t ALTER COLUMN col wider_type`. Metadata-only type-widening only (see subsection below). No narrowing, no `NULL`→`NOT NULL`. |
| `ALTER COLUMN` — narrow type / `NULL`→`NOT NULL` / retype IDENTITY / change collation | ❌ | Not supported even in preview. CTAS workaround: create new table with desired schema, `DROP TABLE`, `sp_rename`, re-add constraints/security |

CTAS workaround **destroys time-travel history and security (GRANT/DENY)** on the original table — re-apply security after the swap.

### `ALTER COLUMN` (Preview)

`ALTER TABLE ... ALTER COLUMN` is **in preview**. It supports **metadata-only schema evolution** — only changes that don't require validating or rewriting the underlying Parquet files (i.e. **type widening** compatible with existing stored data). Takes a **Sch-M lock** for the duration (blocks/blocked by concurrent workloads).

**Supported conversions (widening / interchange only):**

| Category | Source → Target |
|---|---|
| Integer widening | `smallint`→`int`/`bigint`; `int`→`bigint` |
| Floating-point widening | `real`→`float`; `smallint`/`int`→`float` |
| Decimal widening | `decimal(p,s)`→`decimal(p+k1, s+k2)` where k1 ≥ k2 ≥ 0; `smallint`/`int`→`decimal(10+k1, k2)` |
| Decimal / numeric interchange | `decimal(p,s)` ↔ `numeric(p,s)` |
| Float / real interchange | `float(n<25)`→`real`; `float(n)`→`float(n+m)`; `real`→`float(n)` |
| Time widening | `time`→`datetime2`; `datetime2(n)`→`datetime2(n+m)` |
| String widening | `char(n)`→`varchar(n+m)`/`char(n+m)`; `varchar(n)`→`varchar(n+m)`/`char(n+m)` |
| Binary widening | `varbinary(n)`→`varbinary(n+m)` |

**NOT supported (use the CTAS workaround):** narrowing / reducing size of the same type · `NULL`→`NOT NULL` · altering an IDENTITY column · changing collation · decreasing precision on `time`→`datetime2` · a column with manually-created stats (`DROP STATISTICS` first) · a column that is part of the data-clustering (`CLUSTER BY`) index. `time`→`datetime2` sets the date component to `1970-01-01` (Delta/Unix epoch), unlike SQL Server's `1900-01-01`.

**Cross-engine caveat:** widening surfaces as Delta **type widening** at the storage layer — external engines reading the same Delta tables must support Delta type-widening reads. To strip type widening from the schema, rebuild with CTAS.

## IDENTITY Columns

**GA August 2026.**

```sql
CREATE TABLE dbo.DimProduct (
    ProductKey bigint IDENTITY,
    ProductName varchar(100)
);
```

- Data type must be `bigint` — anything else errors. Cannot be added to an existing table via `ALTER TABLE` — use CTAS or `SELECT ... INTO`. The identity column doesn't have to be first in the table definition.
- **No custom seed or increment.** The system manages values internally and always produces positive integers.
- **Values are unique but not sequential, and gaps are normal.** The cause is the distributed engine, *not* rolled-back transactions: `IDENTITY` scales range allocation out across compute nodes to keep load parallel, so two ingestion tasks — even sequential, even both successful — get non-contiguous ranges. Uniqueness holds for the life of the table as long as `IDENTITY_INSERT` isn't used; a used value is never reissued. Surrogate keys only — never treat the value as an ordering or a row count.
- CTAS / `SELECT ... INTO` preserve the IDENTITY property on the target column.

### IDENTITY_INSERT and reseeding

```sql
SET IDENTITY_INSERT dbo.DimCustomer ON;
INSERT INTO dbo.DimCustomer (CustomerKey, CustomerName, Email)
VALUES (-1, 'Unknown', NULL);          -- sentinel row
SET IDENTITY_INSERT dbo.DimCustomer OFF;

DBCC CHECKIDENT('dbo.DimCustomer', RESEED);   -- required, not optional
```

- While `IDENTITY_INSERT` is `ON`: a **column list is required** on the `INSERT`, and **only one table per session** can have it on.
- **Reseed after turning it off.** `RESEED` scans used and reserved ranges across the compute nodes to work out the correct next values; skip it and you risk key collisions.
- `DBCC CHECKIDENT` supports **only `RESEED`** here — no custom reseed value, and `NORESEED` is not supported.
- `COPY INTO` has its own `IDENTITY_INSERT = 'ON'` option, and it **overrides the session-level setting**:

  ```sql
  COPY INTO dbo.Employees (EmployeeID 1, FirstName 2, LastName 3)
  FROM 'https://myaccount.blob.core.windows.net/myblobcontainer/folder1/'
  WITH (FILE_TYPE = 'CSV', IDENTITY_INSERT = 'ON');
  ```

- **`sys.identity_columns` lies here.** `seed_value` and `increment_value` are always `NULL` and never updated; `last_value` is `NULL` until the first identity insert, then flips **permanently to `-1`**. Don't read it for a high-water mark — use `MAX()` on the column.

## Capability Matrix

| Capability | Warehouse |
|---|---|
| CREATE / ALTER / DROP base tables | ✅ |
| INSERT / UPDATE / DELETE / MERGE | ✅ (MERGE **GA Jan 2026**) |
| COPY INTO, OPENROWSET (read + ingest) | ✅ |
| `bcp` bulk copy utility | 🔶 Preview (`BULK LOAD` / `BULK INSERT` T-SQL not supported) |
| Transactions | ✅ (snapshot isolation only) |
| `IDENTITY` columns (`bigint` only) | ✅ (**GA Aug 2026**) |
| Time travel (`OPTION (FOR TIMESTAMP AS OF ...)`) | ✅ (1–120 day **table-history** retention, default 30) |
| Dropped-warehouse recovery (workspace Recycle bin) | ✅ (GA July 2026 — 7–90 day **item** retention, default 7; different window from time travel) |
| GPU query acceleration | 🔶 Limited preview (registration form; workspace-level toggle) |
| Time travel on **SQL analytics endpoint** | 🔶 Preview (June 2026 — New metadata sync only) |
| Warehouse Snapshots | ✅ (GA — created via REST API / portal, not T-SQL) |
| `sys.sp_get_table_health_metrics` (SQLEP, Lakehouse tables) | ✅ (GA June 2026) |
| Source control (Git integration + deployment pipelines) | 🔶 Preview |
| CREATE VIEW / FUNCTION / PROCEDURE / SCHEMA | ✅ |
| TRUNCATE TABLE | ✅ |
| `ALTER COLUMN` | 🔶 Preview |
| Cursors | ❌ |
| `DEFAULT` / `CHECK`; enforced FK / PK / UNIQUE | ❌ |

## Warehouse Authoring Rules

- **MERGE is GA (January 2026)** — single-statement conditional INSERT/UPDATE/DELETE. Takes an Intent Exclusive (`IX`) lock like other DML, but under snapshot isolation a MERGE **conflicts with any concurrent DML on the same table** (even append-only MERGE) — serialize writes or fall back to DELETE + INSERT where concurrency is high.
- **ALTER COLUMN is in preview** and **widening-only** (metadata-only, no Parquet rewrite): widen ints/floats/decimals/strings/binary/time, or `decimal`↔`numeric`. It **cannot** narrow, tighten `NULL`→`NOT NULL`, retype IDENTITY, or change collation — use the CTAS + sp_rename workaround for those (see [ALTER COLUMN (Preview)](#alter-column-preview)).
- **Snapshot isolation only** — write-write conflicts are detected at the table level. Serialize writes to the same table.
- **CTAS over CREATE TABLE + INSERT** — parallel, single-operation, better performance.
- **TRUNCATE TABLE over DELETE FROM** (without WHERE) — faster, preserves time-travel history.
- **INSERT...SELECT over singleton INSERT...VALUES** at scale — singletons create tiny Parquet files. Remediate existing fragmentation: `CREATE TABLE T_Clean AS SELECT * FROM T; DROP TABLE T; EXEC sp_rename 'T_Clean', 'T';`
- **Transactions**: keep short to reduce conflict window. Error 24556 / 24706 = snapshot conflict → serialize and retry with exponential backoff.
- **COPY INTO** for external file ingestion — highest throughput. `FILE_TYPE`: `PARQUET` / `CSV` / `JSONL` (JSONL added April 2026). Requires Storage Blob Data Reader on ADLS or SAS in CREDENTIAL. Set `WITH (AUTO_CREATE_TABLE = 'TRUE')` to create the target table on the fly. Files ≥ 4 MB optimal.
- **`bcp` is supported as a preview feature** for bulk load/export from the command line. The `BULK LOAD` and `BULK INSERT` T-SQL statements are **not** supported — use COPY INTO / OPENROWSET for in-engine ingestion instead.

### CTAS Synapse-vs-Fabric rules

These rules differ from dedicated SQL pools (Synapse) — common gotcha when porting:

- `WITH (DISTRIBUTION = ...)` — **not supported** (distribution is engine-managed)
- `CLUSTERED COLUMNSTORE INDEX` hints — **not supported** (indexing is automatic)
- `WITH (CLUSTER BY (col1, col2, ...))` — **supported** (max 4 columns; preview)
- Explicit column definitions — **not allowed** (types inferred from SELECT)
- Variables in CTAS — **not allowed** (wrap in `sp_executesql`)
- Use explicit `CAST()` to control inferred types

### OPENROWSET surface

- Formats: **Parquet, CSV, TSV, JSONL**
- Available on Warehouse for read AND ingest (CTAS / `INSERT...SELECT`)
- Explicit schema via `WITH (col type, ...)` clause when needed
- Wildcards and Hive-partitioned paths supported (`year=*/month=*/*.parquet`)
- Complex Parquet types (maps, lists) returned as JSON text — use `JSON_VALUE` / `OPENJSON`
- Slower than materialized tables — ingest for repeated access

## Snapshot Isolation Conflict Matrix

| Scenario | Outcome |
|---|---|
| INSERT vs INSERT (same table) | Usually safe (appends new Parquet files) |
| UPDATE / DELETE vs UPDATE / DELETE | First committer wins; others fail with error 24556 / 24706 |
| MERGE vs any DML | Always conflicts (even append-only MERGE) |
| DML vs background compaction | Compaction can trigger conflict if it commits first |

**Mitigation**: serialize writes per table; INSERT-only patterns (append then reconcile); keep transactions short; retry with TRY/CATCH around DML, increment retry count, `WAITFOR DELAY '00:00:02'` (use exponential backoff in production), `THROW` on max retries.

## Transactions

- ACID via **snapshot isolation exclusively** (`SET TRANSACTION ISOLATION LEVEL` is ignored).
- DDL **is** allowed inside transactions: `CREATE TABLE`, `DROP TABLE`, `TRUNCATE TABLE`, `CTAS`, `sp_rename`, supported `ALTER TABLE` variants (add nullable column / drop column / add or drop `NONCLUSTERED NOT ENFORCED` PK / UNIQUE / FK), multiple `ALTER TABLE` statements, and `ALTER TABLE` on distributed temporary tables. **GA April 2026** — any failure rolls every schema change back atomically.
- Cross-database transactions supported within the same workspace.
- Rollbacks are fast — metadata-only revert to previous Parquet versions.
- **DDL takes Sch-M (Schema-Modification) lock** at the table level — blocks concurrent DML and SELECT, including queries against `sys.tables` / `sys.objects`. Schedule schema-change transactions during maintenance windows; use `sys.dm_tran_locks` to inspect contention.
- **Not supported**: savepoints, named transactions, distributed transactions, nested transactions.

```sql
-- Atomic multi-step schema migration (April 2026 GA)
BEGIN TRAN;
ALTER TABLE dbo.FactSales ADD UnitCostUSD decimal(19,4) NULL;
ALTER TABLE dbo.FactSales DROP COLUMN LegacyCost;
COMMIT;
```

## Time Travel and Warehouse Snapshots

### `OPTION (FOR TIMESTAMP AS OF ...)`

```sql
SELECT * FROM dbo.FactSales
OPTION (FOR TIMESTAMP AS OF '2026-03-01T08:00:00.000');
```

- 30 calendar days of history retained (Delta Lake versioning), no extra cost.
- Timestamp must be **UTC**.
- Appears **once** per SELECT — all tables see the same point in time.
- **Cannot** be used in `CREATE VIEW` definitions (but you can query views with it).
- Returns the **current schema** — dropped columns won't appear in time-travel results.
- Drop + recreate resets history.
- **DML time travel** (`INSERT...SELECT`, CTAS, `SELECT INTO` carrying the hint) is **Warehouse-only**.

### SQL analytics endpoint time travel (preview)

Time travel extended to the **SQL analytics endpoint** in June 2026 (preview) — same `OPTION (FOR TIMESTAMP AS OF '...')` read-only `SELECT` syntax, UTC, `yyyy-MM-ddTHH:mm:ss[.fff]` (max 3 fractional digits). Distinct from the Warehouse behavior above:

- **Gated on New metadata sync.** Only enabled for SQLEPs **created with [New metadata sync (preview)](https://learn.microsoft.com/fabric/data-engineering/sql-analytics-endpoint-metadata-sync#new-metadata-sync-preview)** turned on (Workspace settings → Warehouse). Endpoints on legacy metadata sync don't get time travel.
- **Retention is NOT the Warehouse 1–120 day window.** For a Lakehouse SQL analytics endpoint the time-travel window is governed **per table by Delta VACUUM retention** (`delta.logRetentionDuration`, default 30 days; VACUUM keeps unreferenced files 7 days by default) — controlled through Lakehouse table maintenance, not warehouse `data-retention`. Aggressive VACUUM shortens how far back you can travel even if a version still shows in table history.
- **Read-only only** — no DML time-travel variants (SQLEP has no DML anyway).
- Same CLS / RLS / DDM enforcement, single-hint-per-`SELECT`, current-schema, and view limitations as Warehouse.
- Works in stored procedures via `sp_executesql`.

### Warehouse Snapshots (GA)

- Named, read-only, point-in-time views of the entire warehouse.
- **Created via REST API or portal — not T-SQL.**
- Query as `SnapshotName.dbo.Table` via 3-part naming.
- Up to 30 days retention; zero-copy (reference existing Parquet files); atomically refreshable to a new point in time.
- Use cases: financial close (lock KPIs), audit comparisons, stable Power BI reporting during ETL, data recovery.

### Dropped warehouse recovery (GA July 2026)

A **dropped** warehouse is recoverable from the **workspace Recycle bin** — a different mechanism from time travel, and worth keeping straight:

| | Time travel | Warehouse Snapshots | Recycle bin recovery |
|---|---|---|---|
| Recovers | a past state of tables in a **live** warehouse | a named point-in-time view of a live warehouse | the **whole deleted item** |
| Window | **1–120 days**, default 30 (warehouse `data-retention`) | up to 30 days | **7–90 days**, default 7 (**Item Recovery** tenant setting) |
| Set by | warehouse setting | snapshot definition | tenant admin |

- Restores table schemas, data, snapshots, permissions, views, and stored procedures — the item comes back with its properties and permissions intact.
- **Workspace Contributor** or above can restore; **Workspace Admin** is needed to permanently delete during the window.
- Portal: workspace → **Recycle bin** → select → **Restore**. REST: `POST /v1/workspaces/{workspaceId}/recoverableItems/{itemId}/recover` (`DELETE` on the same path purges it).
- With the **Item Recovery** tenant setting **off**, deleting an item retains nothing.
- Recovery **fails if a new item now has the same name** in that workspace — rename the new one, then retry.
- After a permanent delete, OneLake holds the data 7 more days but nothing can restore it.

## Table Health Metrics — `sys.sp_get_table_health_metrics` (GA June 2026)

Built-in system stored procedure that returns file-level storage health for a **Lakehouse Delta table**, exposed on the **SQL analytics endpoint** (read-only). Use it to drive *check-then-act* maintenance — run `OPTIMIZE` only when the table actually needs it, instead of on a blind schedule.

```sql
EXEC sys.sp_get_table_health_metrics @table_name = 'dbo.FactSales';
-- positional form also works:
EXEC sys.sp_get_table_health_metrics 'sales.SalesOrderFacts';
```

- `@table_name` is **nvarchar(256)**, required, `schema.table` (schema optional for `dbo`).
- Caller needs at least **VIEW DEFINITION** on the target table.
- Returns a **single row**: `PotentialAnomalyType` + `PotentialAnomalyDescription`, snapshot/checkpoint versions, summary counts (`PhysicalRowCount`, `DeletedRowCount`, `FileCount`, `FileSizeInBytes`), and histogram bins for file row-count, deleted-row-count, and file-size distribution.
- **`PotentialAnomalyType` codes** (one per run — highest severity only; re-run after maintenance to surface the next): `0` None · `1` Invalid file statistics · `2` Many deleted rows · `3` Many small files · `4` No recent checkpoint.
- Healthy DW-target layout: most files in `FileRowCount[1M,10M)` (~2M rows/file) and `FileSize[1GiB,16GiB)` (~1.2 GB/file). Concentration in small bins ⇒ small-file problem ⇒ `OPTIMIZE`.
- File-metadata inspection only (no rowgroup analysis). Empty tables return all-zero histograms with `PotentialAnomalyType = 0`.
- SQLEP is read-only — you **can't** run `OPTIMIZE` from it. Trigger the actual compaction from Spark / Lakehouse / a pipeline notebook.

**Pipeline pattern**: call it from a **Script activity** (not the Stored Procedure activity — only Script exposes the structured JSON result set for a downstream **If Condition** on `PotentialAnomalyType > 0`), then branch into a notebook that runs `OPTIMIZE`. Note before `VACUUM`: removing old files permanently shortens the time-travel window.

## Query Acceleration — GPU (Preview)

GPU co-processing for eligible T-SQL. No query rewrites, no schema changes, no data movement — Fabric splits the plan and offloads eligible operators (scans, joins, aggregations) to a GPU engine sitting alongside the CPUs in the same compute node.

**The blast radius is the workspace, not the item.** The toggle lives in **Workspace settings → Fabric Warehouse → Query Acceleration**, and once on it applies to **every warehouse and SQL analytics endpoint in that workspace**. Toggling it either way **cancels every query currently running in the workspace** — do it in a quiet window.

- **Limited preview** — access is granted per tenant via a [registration form](https://aka.ms/GPU-FabricDW), first-come first-served, and the capacity must sit in a supported region (East US, East US 2, South Central US, South East Asia, Germany West Central at time of writing).
- **Billed on a separate, higher-rate CU meter.** Once enabled, *all* queries in the workspace bill through it — not just accelerated ones.
- **Eligibility is per query, and two things commonly disqualify one**: `nvarchar` (limited support — prefer `varchar(8000)`, which you want in Fabric Warehouse anyway) and case-insensitive collations (prefer the default binary/CS collation). Write operations never accelerate; read-heavy scans/joins/aggregations over up to ~1 TB benefit most, especially under concurrency.
- **Verify rather than assume it applied**: `queryinsights.exec_requests_history.is_accelerated` (1/0), `number_of_accelerated_runs` in `long_running_queries` and `frequently_run_queries`, the **Query Acceleration** column in portal Query history, or the **Query Acceleration** operator in an SSMS graphical plan. `is_accelerated = 0` means either disabled *or* ineligible — the column doesn't distinguish them.

## Source Control and CI/CD (Preview)

Source control for Fabric Warehouse is a **preview** feature — both Git integration and deployment pipelines.

- **Git integration** (workspace-level, Azure DevOps or GitHub): commit/sync warehouse objects, branch out to feature workspaces, revert, bi-directional sync; automatable via Fabric REST APIs. Warehouse appears as a supported item (preview) in the Source control panel.
- **Deployment pipelines**: promote across Dev → Test → Prod stages.
- **IDE / local**: VS Code with **DacFx** (SQL database projects) for schema management, **SSMS** for interactive dev; external CI/CD via **SQLPackage CLI**, DacFx tasks, and REST APIs.
- Use SQL database projects + Git for incremental object-level change and history; use deployment pipelines for environment promotion.
- **SQL analytics endpoint CI/CD** — separate, newer preview (Aug 2026): a SQLEP's *definition* (the schemas, views, procedures and functions you add on top of the auto-generated tables) can be managed as a **DacFx database project** in Git alongside other Fabric items, and promoted as incremental schema changes through deployment pipelines. Previously the endpoint was a deployment side-effect of its parent item, not a versioned artifact. Evidence so far is the What's New row only — there is no dedicated Learn page — so treat the mechanics as unconfirmed and check before designing a release process around it.
- **Collation-mismatch gotcha**: promoting/branching/merging when source and target warehouses were created with different collations is **not supported** — deployment may succeed but dataset collation isn't reconciled. Fix with the `dw-collation-error-update-tmsl` script in the Fabric toolbox.

## Default Collation

`Latin1_General_100_BIN2_UTF8` — case-sensitive, binary. Case-insensitive alternative: `Latin1_General_100_CI_AS_KS_WS_SC_UTF8`. Use explicit `COLLATE` in comparisons if case-insensitive is needed.

## Pipeline Integration

- **Use the Script activity** (with a Warehouse connection) to invoke Warehouse stored procedures from Fabric Data Pipelines.
- **The Stored Procedure activity does NOT support Fabric Warehouse** — it only supports Azure SQL / SQL MI. Common pitfall when wiring up DW from pipelines.

## Reference

- Microsoft Learn: [What is Fabric Data Warehouse?](https://learn.microsoft.com/fabric/data-warehouse/data-warehousing)
- Microsoft Learn: [Performance guidelines](https://learn.microsoft.com/fabric/data-warehouse/guidelines-warehouse-performance)
- Microsoft Learn: [Secure your Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/security)
- Microsoft Learn: [IDENTITY columns in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/identity)
- Microsoft Learn: [Query acceleration (preview)](https://learn.microsoft.com/fabric/data-warehouse/query-acceleration)
- Microsoft Learn: [Recover or permanently delete items](https://learn.microsoft.com/fabric/admin/item-recovery)
- Comprehensive MS Learn link bundle (concept / connect / tables / ingestion / performance / monitoring / security / backup-restore / source control & CI/CD): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-database skill — full Azure SQL engine inside Fabric, none of these restrictions apply
- fabric-warehouse-monitoring skill — Query Insights, query labels, DMVs, KILL, Result Set Caching, statistics
- fabric-security skill — GRANT/DENY/RLS/CLS/DDM SQL syntax for Warehouse
- fabric-auth skill — TDS connection essentials (port 1433, Initial Catalog vs FQDN, Encrypt=Yes)
- fabric-gotchas skill — cross-cutting error index
