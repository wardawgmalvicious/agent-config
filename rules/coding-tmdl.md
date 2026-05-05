---
paths:
  - "**/*.tmdl"
  - "**/SemanticModel/**/*.tmd"
  - "**/definition/**/model.bim"
---

# TMDL Coding Conventions

Applies to TMDL (Tabular Model Definition Language) files in
Fabric Semantic Models, Power BI Project (PBIP) format, and
Tabular Editor TMDL output.

If a project-scope `.claude/rules/coding-tmdl.md` exists, that file
supersedes this one.

> **Verification note**: TMDL is newer; some style conventions below
> are community-driven (SQLBI, MS Fabric community) rather than from a
> canonical Microsoft style guide. Treat as opinionated defaults.

## Naming and aliasing

Pattern: **PascalCase identifier, aliased display name with spaces.**

Applies to:

- **Tables**: `TransactionLine` ↔ `"Transaction Line"`
- **Columns**: `OrderTotal` ↔ `"Order Total"`
- **Measures**: `TotalSalesYtd` ↔ `"Total Sales YTD"`
- **Hierarchies**: `Geography` ↔ `"Geography"` (single-word OK)
- **Hierarchy levels**: `CountryCode` ↔ `"Country"` (display can drop
  `Code` suffix if context is clear)
- **Roles**: `RegionalManager` ↔ `"Regional Manager"`
- **Perspectives**: `FinanceCore` ↔ `"Finance — Core"`
- **Calculation groups / items**: same pattern.

```tmdl
# Good
table TransactionLine
    lineageTag: <guid>

    column TransactionDate
        displayName: "Transaction Date"
        dataType: dateTime
        formatString: "yyyy-mm-dd"
        summarizeBy: none

    column OrderTotal
        displayName: "Order Total"
        dataType: decimal
        formatString: "$#,##0.00;-$#,##0.00"
        summarizeBy: sum

    measure TotalSales = SUM('Transaction Line'[Order Total])
        displayName: "Total Sales"
        formatString: "$#,##0.00"

# Bad (no display alias, snake_case identifier)
table transaction_line
    column transaction_date
    column order_total
```

## Why both forms

- **Identifier (PascalCase)**: stable reference for DAX, M, lineage,
  and version-control diffs. No spaces means no escaping in DAX.
- **Display (with spaces)**: end-user-facing. Spaces and proper case
  read naturally in visuals.

DAX always references display names: `'Transaction Line'[Order Total]`.
You write the identifier in TMDL but DAX consumes the display.

## Measure organization

- **Dedicated measure tables**: `_Measures` (or one per subject area:
  `_Sales Measures`, `_Finance Measures`). Hidden tables that hold
  measures only — no rows.
- **Display folders**: group related measures within the table.
  `displayFolder: "YTD\\Sales"` — backslash creates nested folders.

```tmdl
# Good — measures organized by subject
table '_Sales Measures'
    isHidden: true

    measure TotalSales = SUM('Transaction Line'[Order Total])
        displayName: "Total Sales"
        displayFolder: "Core"
        formatString: "$#,##0.00"

    measure TotalSalesYtd = TOTALYTD([Total Sales], 'Date'[Date])
        displayName: "Total Sales YTD"
        displayFolder: "YTD"
        formatString: "$#,##0.00"
```

## Format strings

- Set explicit `formatString` on every measure and every numeric or
  date column. Implicit formatting drifts.
- Currency: `"$#,##0.00;-$#,##0.00"` (negative variant explicit).
- Percent: `"0.00%"`.
- Integer counts: `"#,##0"`.
- Dates: `"yyyy-mm-dd"` for display, `"yyyy-mm-ddThh:nn:ss"` for
  datetime.

## Column properties

- `summarizeBy: none` for any column not meant to aggregate (IDs,
  codes, status flags). Prevents accidental `Sum of CustomerId` in
  visuals.
- `isHidden: true` for technical columns (surrogate keys, lineage
  tags, audit columns).
- `dataCategory:` set for geography (`Country`, `City`,
  `WebUrl`, `ImageUrl`) — enables map visuals and image handling.
- `sortByColumn:` for display columns that should sort by a hidden
  numeric (e.g., `Month Name` sorted by `Month Number`).

## Relationships

- Star schema by default.
- Single direction unless bi-directional has a specific, documented
  reason.
- Inactive relationships need a comment explaining when they're
  activated (`USERELATIONSHIP` in measures).

## Descriptions

Use the `description` property on tables, columns, and measures. Shows
in tooltips inside Power BI Desktop and Tabular Editor. Critical for
self-service consumers.

```tmdl
measure TotalSales = SUM('Transaction Line'[Order Total])
    displayName: "Total Sales"
    description: "Sum of order totals across all transactions. Excludes refunds. Source: bronze.transaction_line."
    formatString: "$#,##0.00"
```

## Calculation groups

- One calculation group per axis of analysis (`Time Intelligence`,
  `Currency`, `Scenario`). Power BI supports multiple per model
  (recent feature) — use sparingly; precedence rules get complex.
- Calculation item ordinals: explicit, evenly spaced
  (`ordinal: 10`, `20`, `30`) so insertions are easy.

## Anti-patterns

- Using DAX-calculated columns where a Power Query (M) transformation
  belongs. Calculated columns recompute at refresh, bloat the model,
  and break query folding upstream.
- Implicit measures (drag a column into Values without an explicit
  measure). Hard to govern, name, format consistently.
- Bidirectional relationships "just to make it work" — usually masks
  a model design problem (missing bridge table, wrong grain).
- Naming columns and measures the same thing. Disambiguating
  `'Table'[Sales]` vs `[Sales]` everywhere becomes painful.
