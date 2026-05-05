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
