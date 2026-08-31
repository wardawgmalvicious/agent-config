# `sys.sp_get_table_health_metrics` (GA June 2026)

Check-then-act maintenance for Lakehouse Delta tables via the SQL analytics
endpoint. Not a T-SQL authoring concern — read this when building a
maintenance pipeline.

## Table Health Metrics

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
