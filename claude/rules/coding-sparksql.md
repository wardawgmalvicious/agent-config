---
paths:
  - "**/notebooks/**/*.sql"
  - "**/lakehouse/**/*.sql"
  - "**/spark/**/*.sql"
---

# Spark SQL Coding Conventions

Applies to Spark SQL in Fabric Lakehouse, Databricks SQL, and `%%sql`
or `spark.sql()` blocks in notebooks.

If a project-scope `.claude/rules/coding-sparksql.md` exists, that
file supersedes this one.

## Casing

- **Keywords**: UPPERCASE — same as T-SQL for consistency. (Lowercase
  is also valid Spark style; pick one and hold the line. This rule
  goes UPPERCASE.)
- **Built-in functions**: UPPERCASE — `SUM()`, `COALESCE()`, `EXPLODE()`.
- **Identifiers**: PascalCase for new tables/views/columns you create.
  Respect existing casing on ingested tables — don't rename source
  columns to fit the convention.

## Identifier quoting

- Backticks (` `` `), not brackets. Brackets are T-SQL only.
- Quote only when required: reserved word, special character, leading
  digit, embedded space.

```sql
-- Good
SELECT cust.CustomerId
FROM lakehouse.silver.Customer AS cust;

-- Required quoting (snake_case source column)
SELECT line.`order_date`
FROM lakehouse.bronze.order_line AS line;

-- Bad (T-SQL brackets, doesn't parse)
SELECT [CustomerId] FROM Customer
```

## Three-part naming

Always qualify: `<catalog>.<schema>.<table>` or `<lakehouse>.<schema>.<table>`.
Bare table names rely on `USE CATALOG` / `USE SCHEMA` state, which
breaks on copy-paste.

## Lakehouse-specific table types

- **Managed Delta tables**: default for Lakehouse work.
- **External tables**: only when the data lives outside the Lakehouse
  managed area (mounted ADLS, etc.). Document the location in a
  comment.
- **Views**: `vw_<Purpose>` prefix optional. Avoid views over views
  more than 2 layers deep — query plans get hard to reason about.

## Layout

Same conventions as T-SQL: leading comma, one clause per line, CTE for
multi-step logic, `ON` indented under `JOIN`.

```sql
-- Good
WITH RecentOrder AS (
    SELECT
          CustomerId
        , SUM(OrderTotal) AS TotalSpend
    FROM lakehouse.silver.Order
    WHERE OrderDate >= DATE_SUB(CURRENT_DATE(), 365)
    GROUP BY CustomerId
)
SELECT
      cust.CustomerName
    , ord.TotalSpend
FROM lakehouse.silver.Customer AS cust
INNER JOIN RecentOrder AS ord
    ON ord.CustomerId = cust.CustomerId
ORDER BY ord.TotalSpend DESC;
```

## Performance

- Filter pushdown: `WHERE` on partition columns first. Spark prunes
  partitions before reading.
- Avoid `SELECT *` when reading wide Parquet/Delta tables. Column
  pruning saves real I/O.
- `BROADCAST` hint for small dimension joins (typically <100MB):
  `JOIN /*+ BROADCAST(dim) */ dim ON ...`.
- Use Z-ORDER on Delta tables for high-selectivity columns queried
  frequently. `OPTIMIZE table ZORDER BY (col)`.
- `EXPLAIN` (or `EXPLAIN FORMATTED`) before optimizing — confirm the
  plan before throwing hints at the wall.

## NULL handling

- `IS NULL` / `IS NOT NULL`.
- `COALESCE()` for fallbacks.
- `<=>` operator for null-safe equality (Spark SQL extension):

```sql
-- Null-safe equality: matches when both are NULL
SELECT a.id FROM a INNER JOIN b ON a.key <=> b.key;
```

## Comments

- `--` single-line / end-of-line.
- `/* ... */` block.
- Explain *why*, especially around BROADCAST hints, ZORDER decisions,
  and any deviation from default partitioning.

## Spark SQL vs T-SQL gotchas

- No `TOP n` — use `LIMIT n`.
- No procedural SQL — no variables (`DECLARE`), no `IF`/`WHILE`,
  no stored procs. Wrap procedural logic in PySpark.
- `DATEADD`/`DATEDIFF` argument order differs. Use `DATE_ADD()`,
  `DATE_SUB()`, `DATEDIFF()` (Spark) and verify against docs.
- `STRING` not `NVARCHAR`. `BIGINT` not `INT`.
- `CAST(x AS TYPE)` — no `CONVERT()`.

## Anti-patterns

- `SELECT *` over wide Delta tables — wastes I/O.
- Reading the same table multiple times in a single notebook without
  caching when the optimizer won't deduplicate (e.g., across separate
  `spark.sql()` calls).
- Cross-joining without realizing it (forgotten `ON`, or `WHERE`-only
  filter pre-ANSI style).
- UDF in `WHERE` clause — pushdown disabled, full scan.
