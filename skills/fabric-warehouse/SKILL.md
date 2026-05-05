---
name: fabric-warehouse
description: "Use for T-SQL against Fabric Warehouse (NOT Fabric SQL Database — see fabric-database). Covers unsupported types (nvarchar/datetime/money/xml/tinyint/hierarchyid) and replacements, unsupported features (FOR XML, recursive CTEs, triggers, CREATE USER, ALTER COLUMN, cursors, MERGE-preview), schema evolution (ADD nullable / DROP COLUMN / sp_rename April 2025+, IDENTITY preview, transactional ALTER TABLE GA April 2026, CTAS workaround for type changes), PK/UNIQUE/FK NONCLUSTERED+NOT ENFORCED only, 8060-byte row limit, CTAS Synapse-vs-Fabric rules (no DISTRIBUTION/CCI/explicit columns/variables), COPY INTO with AUTO_CREATE_TABLE (PARQUET/CSV/JSONL), OPENROWSET surface, snapshot-only isolation (24556/24706 retry pattern), DDL inside transactions (CREATE/DROP/TRUNCATE/CTAS/sp_rename/ALTER TABLE — Sch-M lock blocks reads), Time Travel (UTC, single per SELECT) + Warehouse Snapshots (GA, REST/portal not T-SQL), pipeline integration via Script activity (NOT Stored Procedure)."
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
| Change column type / nullability / Add NOT NULL | ❌ | CTAS workaround: create new table with desired schema, `DROP TABLE`, `sp_rename`, re-add constraints/security |

CTAS workaround **destroys time-travel history and security (GRANT/DENY)** on the original table — re-apply security after the swap.

## IDENTITY Columns (Preview)

```sql
CREATE TABLE dbo.DimProduct (
    ProductKey bigint IDENTITY,
    ProductName varchar(100)
);
```

- Data type must be `bigint`. Cannot be added via `ALTER TABLE` — use CTAS.
- Values not guaranteed sequential (gaps after rolled-back transactions). Surrogate keys only.
- `SET IDENTITY_INSERT` supported. CTAS / SELECT INTO preserve the IDENTITY property.

## Capability Matrix

| Capability | Warehouse |
|---|---|
| CREATE / ALTER / DROP base tables | ✅ |
| INSERT / UPDATE / DELETE / MERGE | ✅ (MERGE preview) |
| COPY INTO, OPENROWSET (read + ingest) | ✅ |
| Transactions | ✅ (snapshot isolation only) |
| Time travel (`OPTION (FOR TIMESTAMP AS OF ...)`) | ✅ (30-day retention) |
| Warehouse Snapshots | ✅ (GA — created via REST API / portal, not T-SQL) |
| CREATE VIEW / FUNCTION / PROCEDURE / SCHEMA | ✅ |
| TRUNCATE TABLE | ✅ |
| ALTER COLUMN | ❌ |
| Cursors | ❌ |
| `DEFAULT` / `CHECK`; enforced FK / PK / UNIQUE | ❌ |

## Warehouse Authoring Rules

- **MERGE is preview-only** with table-level conflict detection. Use DELETE + INSERT for production upserts.
- **ALTER COLUMN is not supported.** Use CTAS + sp_rename workaround for schema evolution (see Schema Evolution).
- **Snapshot isolation only** — write-write conflicts are detected at the table level. Serialize writes to the same table.
- **CTAS over CREATE TABLE + INSERT** — parallel, single-operation, better performance.
- **TRUNCATE TABLE over DELETE FROM** (without WHERE) — faster, preserves time-travel history.
- **INSERT...SELECT over singleton INSERT...VALUES** at scale — singletons create tiny Parquet files. Remediate existing fragmentation: `CREATE TABLE T_Clean AS SELECT * FROM T; DROP TABLE T; EXEC sp_rename 'T_Clean', 'T';`
- **Transactions**: keep short to reduce conflict window. Error 24556 / 24706 = snapshot conflict → serialize and retry with exponential backoff.
- **COPY INTO** for external file ingestion — highest throughput. `FILE_TYPE`: `PARQUET` / `CSV` / `JSONL` (JSONL added April 2026). Requires Storage Blob Data Reader on ADLS or SAS in CREDENTIAL. Set `WITH (AUTO_CREATE_TABLE = 'TRUE')` to create the target table on the fly. Files ≥ 4 MB optimal.

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
- Works in stored procedures via `sp_executesql`.

### Warehouse Snapshots (GA)

- Named, read-only, point-in-time views of the entire warehouse.
- **Created via REST API or portal — not T-SQL.**
- Query as `SnapshotName.dbo.Table` via 3-part naming.
- Up to 30 days retention; zero-copy (reference existing Parquet files); atomically refreshable to a new point in time.
- Use cases: financial close (lock KPIs), audit comparisons, stable Power BI reporting during ETL, data recovery.

## Default Collation

`Latin1_General_100_BIN2_UTF8` — case-sensitive, binary. Case-insensitive alternative: `Latin1_General_100_CI_AS_KS_WS_SC_UTF8`. Use explicit `COLLATE` in comparisons if case-insensitive is needed.

## Pipeline Integration

- **Use the Script activity** (with a Warehouse connection) to invoke Warehouse stored procedures from Fabric Data Pipelines.
- **The Stored Procedure activity does NOT support Fabric Warehouse** — it only supports Azure SQL / SQL MI. Common pitfall when wiring up DW from pipelines.

## Reference

- Microsoft Learn: [What is Fabric Data Warehouse?](https://learn.microsoft.com/fabric/data-warehouse/data-warehousing)
- Microsoft Learn: [Performance guidelines](https://learn.microsoft.com/fabric/data-warehouse/guidelines-warehouse-performance)
- Microsoft Learn: [Secure your Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/security)
- Comprehensive MS Learn link bundle (concept / connect / tables / ingestion / performance / monitoring / security / backup-restore / source control & CI/CD): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-database skill — full Azure SQL engine inside Fabric, none of these restrictions apply
- fabric-monitoring skill — Query Insights, query labels, DMVs, KILL, Result Set Caching, statistics
- fabric-security skill — GRANT/DENY/RLS/CLS/DDM SQL syntax for Warehouse
- fabric-auth skill — TDS connection essentials (port 1433, Initial Catalog vs FQDN, Encrypt=Yes)
- fabric-gotchas skill — cross-cutting error index
