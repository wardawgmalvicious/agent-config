---
paths:
  - "**/*.SemanticModel/**/*.tmdl"
  - "**/definition/**/model.bim"
---

# TMDL Coding Conventions

Applies to TMDL (Tabular Model Definition Language) files inside a
`*.SemanticModel` folder: Fabric Semantic Models, Power BI Project
(PBIP) format, and Tabular Editor TMDL output saved into one. A
`.tmdl` file elsewhere, such as an ontology's parts, doesn't load this
rule (2026-10-06).

If a project-scope `.claude/rules/coding-tmdl.md` exists, that file
supersedes this one.

> **Verification note**: some style conventions below
> are community-driven (SQLBI, MS Fabric community) rather than from a
> canonical Microsoft style guide. Treat as opinionated defaults.

## Copying syntax from Learn

**`microsoft_docs_fetch` deletes each newline followed by a tab inside
a code fence**, joining every tab-indented line onto the line above.
The TMDL overview's `database Sales`, then a tab-indented
`compatibilityLevel: 1567`, comes back as one line:
`database SalescompatibilityLevel: 1567`. Space-indented lines survive,
so a block can look half right. The page's HTML keeps the bytes:
`curl -s` it and read the `lang-tmdl` `<pre><code>` block, unescaping
`&lt;`, `&gt;`, `&amp;` and `&quot;` (two Learn pages, 2026-10-07).

TMDL indents with one tab per level by default, and indentation that
breaks its rules is a parsing error (TMDL overview, read 2026-10-08).
This file's examples indent with tabs too: copy them as they stand.

## What TMDL rejects

TMDL takes TOM's properties, in its own syntax, and nothing else, and
one line it cannot read stops the whole model loading. A property TOM
lacks, such as `displayName:`, fails with `Unsupported property -
displayName is not a supported property in the current context!`; a
`#` or `//` line, which TMDL does not read as a comment, fails with
`Unexpected line type: Other!` (TOM 19.96.1's `TmdlSerializer`, probed
2026-10-08).

## Naming

Pattern: **name each object as a report reader sees it**, with spaces
and proper case, and keep the source's own name in `sourceColumn`, as
the TMDL overview does: `column 'Product Key'` over
`sourceColumn: ProductKey` (read 2026-10-08). There is no second,
display name to alias: TOM's `Column` and `Measure` have no such
property, and a `displayName:` line fails the model (§ "What TMDL
rejects"). The name is what visuals show and what DAX references:
`'Transaction Line'[Order Total]`.

Applies to tables, columns, measures, hierarchies and their levels,
roles, perspectives, and calculation groups and items. A hidden column
no reader sees, such as a surrogate key, can keep its source name.
Enclose a name in single quotes when it holds a space, `.`, `=`, `:` or
`'`, and double a `'` inside one (TMDL overview).

Good: the names a reader sees, the source's names in `sourceColumn`:

```tmdl
table 'Transaction Line'

	column 'Transaction Date'
		dataType: dateTime
		formatString: "yyyy-mm-dd"
		sourceColumn: TransactionDate
		summarizeBy: none

	column 'Order Total'
		dataType: decimal
		formatString: "$#,##0.00;-$#,##0.00"
		sourceColumn: OrderTotal
		summarizeBy: sum

	measure 'Total Sales' = SUM('Transaction Line'[Order Total])
		formatString: "$#,##0.00"
```

Bad: the source's names carried through, which every visual then shows
as they are:

```tmdl
table transaction_line

	column transaction_date
		dataType: dateTime
		sourceColumn: transaction_date

	column OrderTotal
		dataType: decimal
		sourceColumn: OrderTotal
```

## Measure organization

- **Dedicated measure tables**: `_Measures` (or one per subject area:
  `_Sales Measures`, `_Finance Measures`). Hidden tables that hold
  measures only — no rows.
- **Display folders**: group related measures within the table.
  `displayFolder: YTD\Sales` — a backslash nests one folder in another.

Good: measures grouped by subject in a hidden table:

```tmdl
table '_Sales Measures'
	isHidden: true

	measure 'Total Sales' = SUM('Transaction Line'[Order Total])
		displayFolder: "Core"
		formatString: "$#,##0.00"

	measure 'Total Sales YTD' = TOTALYTD([Total Sales], 'Date'[Date])
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
- An inactive relationship can carry no description: TOM's
  relationship has no `Description`, and a `///` above one fails the
  model with `Property 'description' is unknown` (probed 2026-10-08).
  Say when it is activated in the `///` description of each measure
  that calls `USERELATIONSHIP` on it.

## Descriptions

Describe tables, columns and measures with `///` lines directly above
the declaration, with no blank line between (TMDL overview, read
2026-10-08). They show in tooltips inside Power BI Desktop and Tabular
Editor, and matter most to self-service consumers. TMDL never writes a
description as `description:`, and that line fails the model like any
property it does not know (§ "What TMDL rejects").

```tmdl
/// One row per order line, from bronze.transaction_line.
table 'Transaction Line'

	/// Sum of order totals across all transactions. Excludes refunds.
	measure 'Total Sales' = SUM('Transaction Line'[Order Total])
		formatString: "$#,##0.00"
```

## Calculation groups

- One calculation group per axis of analysis (`Time Intelligence`,
  `Currency`, `Scenario`). A model can hold several; keep them few,
  because precedence between them gets complex.
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
