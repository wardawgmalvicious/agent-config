---
paths:
  - "**/*.sql"
---

# T-SQL Coding Conventions

Applies to T-SQL targeting SQL Server, Azure SQL, Fabric Warehouse,
and Synapse dedicated/serverless SQL pools.

If a project-scope `.claude/rules/coding-tsql.md` exists, that file
supersedes this one.

## Casing

- **Keywords**: UPPERCASE — `SELECT`, `FROM`, `INNER JOIN`, `WHERE`,
  `GROUP BY`, `ORDER BY`, `WITH`, `AS`, `IS NULL`, `CASE`/`WHEN`/`END`.
- **Built-in functions**: UPPERCASE — `SUM()`, `COUNT()`, `COALESCE()`,
  `ISNULL()`, `CAST()`, `CONVERT()`.
- **Identifiers** (tables, columns, schemas, parameters, variables,
  indexes, constraints, procs, functions): PascalCase.
- **Aliases**: PascalCase, descriptive, not single letters except for
  the most local scope (single-statement queries with no ambiguity).

## Identifier quoting

- Don't bracket identifiers unless required (reserved word, special
  character, leading digit).
- Schema-qualify every object: `dbo.Customer`, never bare `Customer`.

```sql
-- Good
SELECT c.CustomerId FROM dbo.Customer AS c;

-- Bad (unnecessary brackets, no schema)
SELECT [c].[CustomerId] FROM [Customer] [c];
```

## Aliasing

- `AS` required for table and column aliases. Improves grep-ability.
- Aliases describe role, not just abbreviate.

```sql
-- Good
FROM dbo.OrderLine AS line
JOIN dbo.Product AS prod ON prod.ProductId = line.ProductId

-- Bad
FROM dbo.OrderLine ol, dbo.Product p WHERE p.ProductId = ol.ProductId
```

## JOINs

- Always explicit: `INNER JOIN`, `LEFT JOIN`, `FULL OUTER JOIN`. Never
  comma-join with `WHERE` filtering — that's pre-ANSI and obscures
  semantics.
- `ON` clause indented under the `JOIN`.
- One join per line.

```sql
-- Good
FROM dbo.Customer AS cust
INNER JOIN dbo.Order AS ord
    ON ord.CustomerId = cust.CustomerId
LEFT JOIN dbo.OrderLine AS line
    ON line.OrderId = ord.OrderId

-- Bad (implicit join, mixes filter + join logic)
FROM dbo.Customer cust, dbo.Order ord
WHERE ord.CustomerId = cust.CustomerId
```

## Leading commas

Per repo convention. Leading comma on each column line in `SELECT`,
`GROUP BY`, `ORDER BY`. Indent so the comma aligns left of the
column.

```sql
-- Good
SELECT
      cust.CustomerId
    , cust.CustomerName
    , SUM(ord.OrderTotal) AS TotalSpend
FROM dbo.Customer AS cust
INNER JOIN dbo.Order AS ord
    ON ord.CustomerId = cust.CustomerId
GROUP BY
      cust.CustomerId
    , cust.CustomerName;
```

Trade-off: commenting out the first column requires moving the comma.
Acceptable; the readability win on long column lists outweighs it.

## CTEs over subqueries

- Use CTEs (`WITH`) for any non-trivial multi-step logic.
- One CTE per logical step. Name describes the step's purpose.
- Avoid nested derived tables when a CTE chain reads cleaner.

```sql
-- Good
WITH ActiveCustomer AS (
    SELECT
          CustomerId
        , CustomerName
    FROM dbo.Customer
    WHERE IsActive = 1
)
, RecentOrder AS (
    SELECT
          CustomerId
        , SUM(OrderTotal) AS TotalSpend
    FROM dbo.Order
    WHERE OrderDate >= DATEADD(MONTH, -12, GETDATE())
    GROUP BY CustomerId
)
SELECT
      cust.CustomerName
    , ord.TotalSpend
FROM ActiveCustomer AS cust
INNER JOIN RecentOrder AS ord
    ON ord.CustomerId = cust.CustomerId;
```

## NULL handling

- Always `IS NULL` / `IS NOT NULL`. Never `= NULL`.
- Prefer `COALESCE()` over `ISNULL()` — ANSI-standard, multi-arg, type
  precedence is more predictable.

## Statement terminators

- Semicolon-terminate every statement. Required before any CTE; treat
  it as universally required to avoid the gotcha.

## Object naming

- **Tables**: `PascalCase`, singular (`Customer`, not `Customers`).
- **Columns**: `PascalCase`. Use full words — `CustomerId`, not `CustId`.
- **Primary key**: `<TableName>Id`. Foreign keys mirror the PK name in
  the referencing table.
- **Stored procedures**: `usp_<Verb><Noun>` — `usp_GetActiveCustomer`.
  Avoid `sp_` prefix (collides with system-prefix lookup behavior).
- **Functions**: `ufn_<Verb><Noun>` or `fn_<Verb><Noun>` per repo
  convention.
- **Indexes**: `IX_<Table>_<Columns>` for non-unique, `UX_` for unique,
  `PK_<Table>` for primary key, `FK_<Table>_<RefTable>` for foreign key.
- **Variables**: `@PascalCase` — `@StartDate`, `@CustomerId`.
- **Parameters**: `@PascalCase`, mirror column name where it represents
  a column value.

## SELECT *

Forbidden in production code, views, stored procs. Acceptable for
ad-hoc exploration only. List columns explicitly so schema changes are
visible in PRs.

## Comments

- `--` for single-line and end-of-line.
- `/* ... */` for multi-line block, especially proc/function headers.
- Explain *why*, not *what*. Code shows what.

```sql
/*
  Procedure: usp_GetActiveCustomer
  Purpose:   Returns customers with at least one order in the trailing
             12 months. Used by the segmentation pipeline.
  Author:    <name>
  Created:   2026-04-25
*/
CREATE PROCEDURE dbo.usp_GetActiveCustomer
AS
BEGIN
    SET NOCOUNT ON;
    -- Trailing 12 months matches the marketing definition of "active",
    -- not the finance definition (calendar year).
    ...
END
```

## Stored procedure conventions

- `SET NOCOUNT ON;` as first statement to suppress rowcount messages.
- Explicit transaction handling (`BEGIN TRAN`/`COMMIT`/`ROLLBACK`) with
  `TRY`/`CATCH` for any multi-statement write.
- Avoid output parameters when a result set or return value will do.

## Fabric Warehouse string operators and functions

Fabric Warehouse and the SQL analytics endpoint (also SQL Server 2025,
Azure SQL DB/MI on the 2025 update policy) add ANSI string operators and
fuzzy-match/Unicode functions. As of mid-2026 these are **Preview** —
gate production use, and don't assume portability to Synapse dedicated
SQL pools or pre-2025 SQL Server.

### `||` and `||=` concatenation

- `||` is the ANSI concatenation operator; `||=` is its compound-assignment
  form (`SET @s ||= 'x'`). Prefer over `+` in new Warehouse code for
  portability and predictable NULL handling.
- Key semantic difference: `||` **always** yields `NULL` if any operand is
  `NULL` (ANSI behavior) and ignores `SET CONCAT_NULL_YIELDS_NULL`. `+`
  honors that setting. Don't mix `||` and `+` in one expression expecting
  uniform NULL behavior.
- Same 8,000-byte truncation rule as `+`: if the result exceeds 8,000
  bytes and no operand is a large-value type (`VARCHAR(MAX)`/`NVARCHAR(MAX)`),
  the result truncates. Cast one operand to `MAX` to avoid it.
- `CAST`/`CONVERT` still required to concatenate non-character types
  (numeric, date, binary-plus-space).

```sql
-- Good (ANSI, NULL-safe semantics explicit)
SELECT cust.LastName || ', ' || cust.FirstName AS FullName
FROM dbo.Customer AS cust;
```

### Fuzzy string matching

Damerau-Levenshtein and Jaro-Winkler, as distance and similarity pairs.
Inputs can't be `VARCHAR(MAX)`/`NVARCHAR(MAX)`. `NULL` input yields `NULL`.

- `EDIT_DISTANCE(a, b [, max_distance])` → `INT`. Number of edits; `0` =
  identical. Optional `max_distance` caps (and short-circuits) the compute.
- `EDIT_DISTANCE_SIMILARITY(a, b)` → similarity score (higher = closer).
- `JARO_WINKLER_DISTANCE(a, b)` → `FLOAT`. `0` = identical (it's a distance).
- `JARO_WINKLER_SIMILARITY(a, b)` → `INT` `0`–`100`, `100` = identical.

Note the inversion: for the distance functions lower is closer; for the
similarity functions higher is closer. There is **no** function named
`LEVENSHTEIN` or `JARO_WINKLER` — use the names above.

```sql
-- Fuzzy-join on near-matching names
SELECT s.SupplierName, m.MasterName
FROM dbo.StagingSupplier AS s
INNER JOIN dbo.MasterSupplier AS m
    ON JARO_WINKLER_SIMILARITY(s.SupplierName, m.MasterName) >= 90;
```

### `UNISTR`

`UNISTR('...' [, 'escape_char'])` builds Unicode string literals from
escape sequences: `\xxxx` (UTF-16 code point) or `\+xxxxxx` (Unicode code
point). More flexible than `NCHAR` — handles multiple code points and
literal text in one call. For `CHAR`/`VARCHAR` input the collation must be
UTF-8; supply a custom escape char when `\` is inconvenient.

```sql
SELECT UNISTR(N'Hello! \D83D\DE00');   -- Hello! 😃
```

## Time travel — `OPTION (FOR TIMESTAMP AS OF ...)`

Fabric Warehouse and SQL analytics endpoint (Preview) query prior data
versions at the statement level via the `OPTION` clause. Format is
`yyyy-MM-ddTHH:mm:ss[.fff]`, **UTC only**.

- Bounded by the warehouse data-retention period (default 30 days,
  configurable); the SQL analytics endpoint is bounded by Delta VACUUM
  retention.
- The hint applies to the **entire** statement — all joined Warehouse
  tables resolve to the same timestamp. Declare it once per `SELECT`.
- Read-only for the time-traveled data, but works as the source of
  `INSERT INTO ... SELECT`, `CREATE TABLE AS SELECT` (CTAS), and
  `SELECT INTO`. It does not affect session-scoped `#temp` tables.
- Returns the *latest* table schema; a query referencing columns that
  didn't exist at that timestamp fails.
- The timestamp must be deterministic — a variable can't be passed
  directly. Use `sp_executesql` (or a stored proc) to inject a strongly
  typed `DATETIME`, formatting with `CONVERT(..., 126)`.

```sql
-- Query a table as of a past point in time (UTC)
SELECT *
FROM dbo.DimCustomer
OPTION (FOR TIMESTAMP AS OF '2026-06-18T19:55:13.853');
```

## Anti-patterns

- `NOLOCK` / `READ UNCOMMITTED` as a "performance fix". Masks real
  contention; produces dirty reads. Investigate the actual lock
  contention before reaching for it.
- Implicit type conversion in `WHERE` clauses (e.g., comparing `NVARCHAR`
  to `INT`) — kills index usage. Cast literals to match column type.
- Cursor loops where set-based logic works.
- Scalar UDFs in `WHERE` or `SELECT` of large queries — historically
  forces row-by-row evaluation. SQL Server 2019+ inlining helps but
  isn't universal; profile before relying on it.
