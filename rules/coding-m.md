---
paths:
  - "**/*.pq"
  - "**/*.m"
  - "**/Mashup/**/Section1.m"
  - "**/definition/queries/*.tmdl"
---

# M (Power Query) Coding Conventions

Applies to M used in Power Query (Power BI Desktop, Excel, Fabric
Dataflow Gen1/Gen2, Power Query Online, PBIP `Section1.m`).

If a project-scope `.claude/rules/coding-m.md` exists, that file
supersedes this one.

> **Verification note**: Microsoft has no canonical M style guide.
> These conventions blend MS docs, the Power Query M Language Spec,
> and prevailing community practice (Chris Webb, Imke Feldmann).

## Casing

- **Built-in functions**: PascalCase by language design —
  `Table.SelectRows`, `Text.Lower`, `List.Transform`, `Date.From`.
  Don't fight it.
- **Keywords**: lowercase by language design — `let`, `in`, `each`,
  `if`, `then`, `else`, `try`, `otherwise`, `meta`, `as`, `is`.
- **Step names** (variables in a `let` block): PascalCase, action-
  oriented — `Source`, `FilteredRows`, `RemovedColumns`, `ChangedType`.
  Match Power Query UI auto-generated names where possible.
- **Custom function names**: PascalCase, prefix with `fn` —
  `fnGetCustomerById`, `fnNormalizeAddress`. Distinguishes user code
  from built-ins at a glance.
- **Parameters**: PascalCase — `SourcePath`, `LoadDate`.

## Step names with spaces

Power Query UI auto-generates step names with spaces (`#"Filtered Rows"`).
Acceptable — but when authoring by hand, prefer no-space PascalCase
(`FilteredRows`). Less escaping noise, easier to grep.

```m
// Good (hand-authored)
let
    Source = Sql.Database("server", "db"),
    OrderTable = Source{[Schema="dbo", Item="Order"]}[Data],
    FilteredRows = Table.SelectRows(OrderTable, each [OrderDate] >= #date(2024, 1, 1)),
    SelectedColumns = Table.SelectColumns(FilteredRows, {"OrderId", "OrderDate", "OrderTotal"})
in
    SelectedColumns

// Acceptable (UI-generated, with spaces)
let
    Source = Sql.Database("server", "db"),
    #"Order Table" = Source{[Schema="dbo", Item="Order"]}[Data],
    #"Filtered Rows" = Table.SelectRows(#"Order Table", each [OrderDate] >= #date(2024, 1, 1)),
    #"Selected Columns" = Table.SelectColumns(#"Filtered Rows", {"OrderId", "OrderDate", "OrderTotal"})
in
    #"Selected Columns"
```

## Indentation

- 4 spaces.
- One step per line for `let` blocks.
- Long function calls: arguments on separate lines, indented 4 spaces.

```m
// Good
let
    Source = Sql.Database("server", "db"),
    Filtered = Table.SelectRows(
        Source,
        each [OrderDate] >= #date(2024, 1, 1) and [IsCancelled] = false
    )
in
    Filtered
```

## `each` shorthand

- `each` for single-argument lambdas where the argument is implicit
  (`_`).
- `(row) => ...` explicit form when multiple args or when implicit `_`
  hurts readability.

```m
// Good (idiomatic)
Table.SelectRows(Source, each [OrderTotal] > 100)

// Acceptable (explicit, clearer for nested predicates)
Table.SelectRows(Source, (row) => row[OrderTotal] > 100 and row[Region] = "EMEA")
```

## Type ascription

- Use `as <type>` on function parameters and return types when
  authoring custom functions. Improves error messages and IntelliSense.
- Skip in trivial inline lambdas.

```m
// Good
let
    fnNormalize = (input as text) as text =>
        Text.Lower(Text.Trim(input))
in
    fnNormalize
```

## Query folding

- Foldable transformations push to source. Non-foldable break the
  fold and force local evaluation.
- Order matters: keep foldable steps (`Table.SelectRows`,
  `Table.SelectColumns`, `Table.RenameColumns`, simple type changes)
  early. Non-foldable steps (custom-function applications, complex
  `each` expressions, certain joins) push toward the end.
- View "Query Diagnostics" or check the step's right-click "View
  Native Query" — if it's grayed out, fold is broken at that step.

## Documentation

- Top-of-query comment: purpose, source(s), refresh frequency, owner.
- Step-level: comment any non-obvious transformation in plain English.

```m
/*
    Query: Customer
    Source: Fabric Lakehouse — silver.customer
    Refresh: hourly
    Owner: <name>
    Notes: Excludes test accounts (CustomerType = 'TEST').
*/
let
    Source = Lakehouse.Contents([HierarchicalNavigation = false]),
    SilverCustomer = Source{[Name="silver"]}[Data]{[Name="customer"]}[Data],
    // Test accounts use synthetic emails ending in @test.example
    ExcludedTest = Table.SelectRows(SilverCustomer, each not Text.EndsWith([Email], "@test.example"))
in
    ExcludedTest
```

## Custom functions

- Define in their own query, prefixed `fn`, with type ascription on
  all parameters and return.
- Add `meta` documentation for IntelliSense:

```m
let
    fnGetTrailing = (table as table, dateColumn as text, days as number) as table =>
        Table.SelectRows(
            table,
            each Record.Field(_, dateColumn) >= Date.AddDays(Date.From(DateTime.LocalNow()), -days)
        ),
    Documented = Value.ReplaceType(
        fnGetTrailing,
        type function (
            table as (type table) meta [Documentation.FieldCaption = "Source table"],
            dateColumn as (type text) meta [Documentation.FieldCaption = "Date column name"],
            days as (type number) meta [Documentation.FieldCaption = "Days to look back"]
        ) as table meta [
            Documentation.Name = "fnGetTrailing",
            Documentation.Description = "Filters table to rows whose dateColumn is within the last N days."
        ]
    )
in
    Documented
```

## Parameters

- Use Power Query parameters (Manage Parameters in the UI) for any
  value that varies between environments — connection strings,
  workspaces, lookback windows.
- Reference parameters by name; don't hard-code.

## Error handling

- `try ... otherwise` for expected failures (missing optional column,
  parse error on partial data).
- Don't blanket-`try` everything — masks real bugs.

```m
// Good
PrasedAmount = try Number.FromText([AmountText]) otherwise null

// Bad
SafeOperation = try DangerousStep otherwise null  // hides the actual problem
```

## Anti-patterns

- **`Table.AddColumn` chains where `Table.TransformColumns` would do**:
  multiple `AddColumn` calls force multiple table scans; one
  `TransformColumns` is one scan.
- **Hard-coded connection strings** instead of parameters.
- **Calculated columns in DAX** for transformations that belong in M.
  Push to M for query folding, smaller model, cleaner separation.
- **Custom-function-per-row in `each`** when a built-in handles it.
  `Text.Lower` is faster than `each fnLower(_)`.
- **Re-typing columns multiple times** — pick the type once, late
  enough that fold isn't broken upstream.
- **`Table.Buffer` everywhere** as a "performance fix". It materializes
  the table in memory and breaks fold below it. Use only when you've
  measured a specific repeated-scan problem.
