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
- Cross-database queries via 3-part naming (same workspace AND same region only)
- Session-scoped #temp tables (prefer distributed with `WITH (DISTRIBUTION = ROUND_ROBIN)`)

## OPENROWSET surface

- Formats: **Parquet, CSV, TSV, JSONL**
- Available on Warehouse for read AND ingest (CTAS / `INSERT...SELECT`)
- Explicit schema via `WITH (col type, ...)` clause when needed
- Wildcards and Hive-partitioned paths supported (`year=*/month=*/*.parquet`)
- Complex Parquet types (maps, lists) returned as JSON text — use `JSON_VALUE` / `OPENJSON`
- Slower than materialized tables — ingest for repeated access

## Ingestion options

- **COPY INTO** for external file ingestion — highest throughput. `FILE_TYPE`:
- **`bcp` is preview**; the `BULK LOAD` / `BULK INSERT` T-SQL statements are

## CTAS Synapse-vs-Fabric rules

These rules differ from dedicated SQL pools (Synapse) — common gotcha when porting:

- `WITH (DISTRIBUTION = ...)` — **not supported** (distribution is engine-managed)
- `CLUSTERED COLUMNSTORE INDEX` hints — **not supported** (indexing is automatic)
- `WITH (CLUSTER BY (col1, col2, ...))` — **supported** (max 4 columns; preview)
- Explicit column definitions — **not allowed** (types inferred from SELECT)
- Variables in CTAS — **not allowed** (wrap in `sp_executesql`)
- Use explicit `CAST()` to control inferred types
