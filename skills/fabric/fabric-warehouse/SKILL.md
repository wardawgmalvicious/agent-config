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

## Table Constraints and Limits

- **8,060-byte row limit** (error 511 / 611 on violation)
- **128-char limit** on table/column names
- **1,024-column max** per table
- No default value constraints; no computed columns (use views)
- **PK / UNIQUE / FK supported only as `NONCLUSTERED + NOT ENFORCED`** — metadata-only; the engine does not enforce them at DML time. They serve as optimizer hints, and Power BI uses FK relationships for automatic relationship detection.
- `DEFAULT` / `CHECK` not supported
- `NOT NULL` only via `CREATE TABLE` (cannot be added via `ALTER TABLE`)

## Schema Evolution

Adding a nullable column, dropping a column, and `sp_rename` on a column or
table all work (April 2025+), as does adding/dropping `NONCLUSTERED NOT
ENFORCED` constraints. What constrains you:

| Operation | Status | Syntax |
|---|---|---|
| ALTER TABLE inside `BEGIN TRAN ... COMMIT` | ✅ April 2026+ GA | All supported ALTER TABLE variants run atomically; any failure rolls every schema change back |
| `ALTER COLUMN` — **widen** type (metadata-only) | 🔶 Preview | `ALTER TABLE t ALTER COLUMN col wider_type`. Metadata-only type-widening only (see subsection below). No narrowing, no `NULL`→`NOT NULL`. |
| `ALTER COLUMN` — narrow type / `NULL`→`NOT NULL` / retype IDENTITY / change collation | ❌ | Not supported even in preview. CTAS workaround: create new table with desired schema, `DROP TABLE`, `sp_rename`, re-add constraints/security |

CTAS workaround **destroys time-travel history and security (GRANT/DENY)** on the original table — re-apply security after the swap.

The `ALTER COLUMN` preview conversion matrix (what widening is actually allowed,
and the Delta type-widening consequence for external readers) is in
[references/schema-evolution.md](references/schema-evolution.md).

## IDENTITY Columns

**GA August 2026.**

- Must be `bigint`; anything else errors. **Cannot be added to an existing table
  via `ALTER TABLE`** — use CTAS or `SELECT ... INTO` (both preserve the IDENTITY
  property on the target). It need not be the first column in the definition.
- **No custom seed or increment.** The system manages values and always produces
  positive integers.
- **Values are unique but not sequential — gaps are normal and expected.** The
  distributed engine allocates ranges per compute node, so even two sequential,
  successful ingestion tasks get non-contiguous ranges. Surrogate keys only:
  never read the value as an ordering or a row count. A used value is never
  reissued unless `IDENTITY_INSERT` is involved.
- **`sys.identity_columns` lies here** — `seed_value` / `increment_value` are
  always `NULL`, and `last_value` flips permanently to `-1` after the first
  identity insert. Use `MAX()` for a high-water mark.

Declaration syntax, and inserting explicit values (`SET IDENTITY_INSERT` plus a
mandatory `DBCC CHECKIDENT(..., RESEED)`):
[references/schema-evolution.md](references/schema-evolution.md).

## Warehouse Authoring Rules

- **Snapshot isolation only** — write-write conflicts are detected at the table
  level. Serialize writes to the same table.
- **MERGE is GA (January 2026)** — it takes an Intent Exclusive (`IX`) lock like
  other DML, but under snapshot isolation it **conflicts with any concurrent DML
  on the same table**, even append-only.
  Serialize writes, or fall back to DELETE + INSERT where concurrency is high.
- **CTAS over CREATE TABLE + INSERT** — parallel, single-operation, faster. It
  differs from Synapse dedicated pools: no `DISTRIBUTION` or columnstore hints
  (both engine-managed), no explicit column definitions, no variables;
  `WITH (CLUSTER BY (...))` *is* supported. Full porting delta in
  [references/t-sql-surface.md](references/t-sql-surface.md).
- **TRUNCATE TABLE over DELETE FROM** (without WHERE) — faster, and preserves
  time-travel history.
- **INSERT...SELECT over singleton INSERT...VALUES** at scale — singletons
  create tiny Parquet files. Remediate existing fragmentation with
  `CREATE TABLE T_Clean AS SELECT * FROM T; DROP TABLE T; EXEC sp_rename 'T_Clean', 'T';`
- **Keep transactions short** to shrink the conflict window. Error 24556 / 24706
  = snapshot conflict → serialize and retry with exponential backoff.
  `PARQUET` / `CSV` / `JSONL` (JSONL April 2026). Needs Storage Blob Data Reader
  on ADLS or a SAS in CREDENTIAL; `WITH (AUTO_CREATE_TABLE = 'TRUE')` creates the
  target. Files ≥ 4 MB optimal.
- **Ingestion**: `COPY INTO` for external files (highest throughput), `OPENROWSET`
  in-engine. `bcp` is preview; `BULK LOAD` / `BULK INSERT` are **not supported**.
  Options and file-size guidance: [references/t-sql-surface.md](references/t-sql-surface.md).

## Snapshot Isolation Conflict Matrix

| Scenario | Outcome |
|---|---|
| INSERT vs INSERT (same table) | Usually safe (appends new Parquet files) |
| UPDATE / DELETE vs UPDATE / DELETE | First committer wins; others fail with error 24556 / 24706 |
| MERGE vs any DML | Always conflicts (even append-only MERGE) |
| DML vs background compaction | Compaction can trigger conflict if it commits first |

**Mitigation**: serialize writes per table, or use INSERT-only patterns (append then reconcile). Retry with TRY/CATCH around the DML and exponential backoff.

## Transactions

- ACID via **snapshot isolation exclusively** (`SET TRANSACTION ISOLATION LEVEL`
  is ignored).
- **DDL is allowed inside transactions** — `CREATE` / `DROP` / `TRUNCATE TABLE`,
  CTAS, `sp_rename`, and every supported `ALTER TABLE` variant (including on
  distributed temp tables, and several in one transaction). **GA April 2026**: any failure rolls every schema change
  back atomically.
- **DDL takes a Sch-M lock** at table level, blocking concurrent DML *and*
  SELECT — including queries against `sys.tables` / `sys.objects`. Schedule
  schema changes for maintenance windows; inspect contention with
  `sys.dm_tran_locks`.
- Cross-database transactions work within a workspace; rollbacks are fast
  (metadata-only).
- **Not supported**: savepoints, named transactions, distributed transactions,
  nested transactions.

```sql
-- Atomic multi-step schema migration (April 2026 GA)
BEGIN TRAN;
ALTER TABLE dbo.FactSales ADD UnitCostUSD decimal(19,4) NULL;
ALTER TABLE dbo.FactSales DROP COLUMN LegacyCost;
COMMIT;
```

## Time Travel



```sql
SELECT * FROM dbo.FactSales
OPTION (FOR TIMESTAMP AS OF '2026-03-01T08:00:00.000');
```

- 30 calendar days of history retained (Delta Lake versioning), no extra cost.
- Timestamp must be **UTC**.
- Appears **once** per SELECT — all tables see the same point in time.
- **Cannot** be used in `CREATE VIEW` definitions (you can query views with it).
- Returns the **current schema** — dropped columns won't appear. Drop + recreate
  resets history.
- **DML time travel** (the hint on `INSERT...SELECT` / CTAS / `SELECT INTO`) is
  **Warehouse-only**.

Named **Warehouse Snapshots**, **SQL analytics endpoint** time travel (preview,
different retention rules), and **dropped-warehouse recovery** via the workspace
Recycle bin are three separate mechanisms with three different windows — see
[references/time-travel-and-recovery.md](references/time-travel-and-recovery.md).

## Default Collation


`Latin1_General_100_BIN2_UTF8` — case-sensitive, binary. Case-insensitive alternative: `Latin1_General_100_CI_AS_KS_WS_SC_UTF8`. Use explicit `COLLATE` in comparisons if case-insensitive is needed.

## Pipeline Integration

- **Use the Script activity** (with a Warehouse connection) to invoke Warehouse stored procedures from Fabric Data Pipelines.
- **The Stored Procedure activity does NOT support Fabric Warehouse** — it only supports Azure SQL / SQL MI. Common pitfall when wiring up DW from pipelines.

## Beyond T-SQL authoring

- **Table maintenance** — check-then-act `OPTIMIZE` via
  `sys.sp_get_table_health_metrics`:
  [references/table-health-metrics.md](references/table-health-metrics.md).
- **Feature/GA matrix, GPU query acceleration, source control and CI/CD** —
  [references/platform-features.md](references/platform-features.md). Query
  Acceleration is a *workspace*-wide toggle on a higher billing meter that
  cancels running queries when flipped.

## Reference

- Microsoft Learn: [What is Fabric Data Warehouse?](https://learn.microsoft.com/fabric/data-warehouse/data-warehousing)
- Full MS Learn link bundle (concept / connect / tables / ingestion / performance / monitoring / security / backup-restore / CI-CD): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-database skill — full Azure SQL engine inside Fabric, none of these restrictions apply
- fabric-warehouse-monitoring skill — Query Insights, query labels, DMVs, KILL, Result Set Caching, statistics
- fabric-security skill — GRANT/DENY/RLS/CLS/DDM SQL syntax for Warehouse
- fabric-auth skill — TDS connection essentials (port 1433, Initial Catalog vs FQDN, Encrypt=Yes)
- fabric-gotchas skill — cross-cutting error index
