---
paths:
  - "**/*.dax"
  - "**/*.tmdl"
  - "**/*.bim"
---

# DAX Coding Conventions

Applies to DAX in measures, calculated columns, calculation groups,
and security role filters.

If a project-scope `.claude/rules/coding-dax.md` exists, that file
supersedes this one.

> Anchored on the SQLBI style guide (Marco Russo / Alberto Ferrari).
> Industry-standard reference; deviates only where noted.

## Casing

- **Functions**: UPPERCASE — `CALCULATE`, `SUMX`, `FILTER`, `VAR`,
  `RETURN`, `IF`, `SWITCH`. By convention; DAX is case-insensitive but
  consistency matters for readability.
- **Table names**: match the model identifier (PascalCase per TMDL
  rule), wrapped in single quotes when referenced:
  `'Transaction Line'`.
- **Column references**: always table-qualified — `'Customer'[CustomerId]`.
  Never bare `[CustomerId]` for columns; that's measure syntax.
- **Measure references**: `[Total Sales]` — square brackets, no table
  prefix. The lack of prefix is what distinguishes measure from
  column at a glance.

```dax
-- Good
Total Sales =
SUMX (
    'Transaction Line',
    'Transaction Line'[Quantity] * 'Transaction Line'[Unit Price]
)

-- Bad (bare column reference, lowercase function)
Total Sales =
sumx (
    [Quantity] * [Unit Price]
)
```

## Variables

- Use `VAR` / `RETURN` for any expression with more than one logical
  step. Variables are evaluated once and reused — better performance
  and readability.
- Variable names: prefix with `_` (single underscore) to distinguish
  from measure references.

```dax
-- Good
Total Sales YoY % =
VAR _SalesCurrent = [Total Sales]
VAR _SalesPrior = CALCULATE ( [Total Sales], SAMEPERIODLASTYEAR ( 'Date'[Date] ) )
VAR _Result =
    DIVIDE ( _SalesCurrent - _SalesPrior, _SalesPrior )
RETURN
    _Result

-- Bad (no variables, repeats Total Sales evaluation)
Total Sales YoY % =
DIVIDE (
    [Total Sales] - CALCULATE ( [Total Sales], SAMEPERIODLASTYEAR ( 'Date'[Date] ) ),
    CALCULATE ( [Total Sales], SAMEPERIODLASTYEAR ( 'Date'[Date] ) )
)
```

## Indentation and whitespace

- Function arguments on separate lines for any function with 2+
  arguments or any argument that's itself a non-trivial expression.
- Space before `(` after function name: `CALCULATE (` not `CALCULATE(`.
  SQLBI style; reads more like English.
- Indent function body 4 spaces.

```dax
-- Good
Sales YTD =
CALCULATE (
    [Total Sales],
    DATESYTD ( 'Date'[Date] )
)

-- Bad (single line for non-trivial logic)
Sales YTD = CALCULATE([Total Sales], DATESYTD('Date'[Date]))
```

## DIVIDE over `/`

`DIVIDE()` returns blank on divide-by-zero; `/` returns infinity or
errors out. Always `DIVIDE()`.

```dax
-- Good
Margin % = DIVIDE ( [Profit], [Revenue] )

-- Bad
Margin % = [Profit] / [Revenue]
```

## CALCULATE patterns

- `CALCULATE` modifies filter context. Understand what filters exist
  before adding more.
- Prefer `KEEPFILTERS` when intent is to layer a filter on top of
  existing ones rather than replace.
- `REMOVEFILTERS` is the modern replacement for `ALL` when used as a
  filter argument inside `CALCULATE`. Reads more clearly.

## CALCULATE vs FILTER

- `CALCULATE ( [Measure], 'Table'[Column] = "Value" )` — fast, uses
  internal optimization.
- `CALCULATE ( [Measure], FILTER ( 'Table', 'Table'[Column] = "Value" ) )` —
  iterator, slower. Only when the filter expression can't be expressed
  as a simple column predicate.

## Comments

- `//` single-line.
- `/* ... */` block. Useful for measure headers explaining
  business rules.
- Explain the *why* — what business definition this implements, what
  edge cases are handled.

```dax
/*
    Total Active Customers
    Definition: Customers with at least one non-cancelled order in
    the trailing 12 months. Matches the marketing team's "active"
    definition (calendar 12 months, not fiscal).
*/
Total Active Customers =
CALCULATE (
    DISTINCTCOUNT ( 'Order'[CustomerId] ),
    DATESINPERIOD ( 'Date'[Date], MAX ( 'Date'[Date] ), -12, MONTH ),
    'Order'[IsCancelled] = FALSE
)
```

## Anti-patterns

- **Implicit measures**: dragging a column into Values without
  explicitly defining a measure. Inconsistent formatting, no central
  governance.
- **Calculated columns where M would do**: calculated columns inflate
  model size and recalculate on refresh. Push transformation upstream
  to Power Query. **Exception**: user-context-aware columns (DAX
  `USERCULTURE` / `USERPRINCIPALNAME` / `USEROBJECTID` / `CUSTOMDATA`)
  cannot be expressed in M and are a sanctioned use case — set the
  column's `expressionContext` to `userContext`. Common pattern:
  per-user data translations on a multilingual model.
- **`ALL` everywhere**: blunt instrument. Prefer `REMOVEFILTERS` (more
  explicit) or specific `KEEPFILTERS` patterns.
- **Nested `IF`**: more than two levels deep, switch to `SWITCH`:

```dax
  -- Bad
  IF ( x = 1, "A", IF ( x = 2, "B", IF ( x = 3, "C", "D" ) ) )

  -- Good
  SWITCH ( TRUE (),
      x = 1, "A",
      x = 2, "B",
      x = 3, "C",
      "D"
  )
```

- **Bidirectional cross-filter** to "make a relationship work" —
  usually a model design issue.
- **Iterator inside iterator** without understanding row context:
  `SUMX ( T1, SUMX ( T2, ... ) )`. Profile before shipping.

## Stable object references with NAMEOF

For DAX UDFs, calculation groups, or any code generator that emits object
references, prefer `NAMEOF` over hand-typed quoted names. Renames and
display-name changes propagate without breaking string-built references.

```dax
-- Good: full qualified reference, survives renames
VAR _ColRef = NAMEOF ( 'Sales'[Order Quantity] )

-- Component / escaped controls when emitting code:
NAMEOF ( 'Sales'[Order Quantity] )                          -- 'Sales'[Order Quantity]
NAMEOF ( 'Sales'[Order Quantity], TABLE )                   -- 'Sales'
NAMEOF ( 'Sales'[Order Quantity], PARENT, MINIMALLYESCAPED ) -- Sales
NAMEOF ( 'Sales', FULL, UNESCAPED )                         -- Sales
```

- `component`: `TABLE` / `COLUMN` / `MEASURE` / `CALENDAR` / `FULL` (default) / `SELF` / `PARENT`.
- `escaped`: `ESCAPED` (default) / `UNESCAPED` / `MINIMALLYESCAPED`. `UNESCAPED` errors on fully qualified names.
- Variables and dynamic expressions are not allowed as `object` arguments.
- Not supported in DirectQuery mode for calculated columns or RLS rules.

## User-defined functions (UDFs)

GA in Power BI Desktop and the Service as of the June 2026 release
(requires database compatibility level 1702+). Package reusable DAX
logic behind the `FUNCTION` keyword; callable from measures, calculated
columns, visual calculations, and other UDFs. First-class model objects —
author in DAX query view or TMDL view, browse under the *Functions* node
in Model explorer.

```dax
DEFINE
    /// AddTax returns amount including tax at the given rate.
    /// @param {NUMERIC} amount - pre-tax amount
    /// @param {NUMERIC} rate - tax rate; defaults to 10%
    /// @returns amount grossed up by rate
    FUNCTION AddTax = (
            amount : NUMERIC,
            rate : NUMERIC = 0.1
        ) =>
        amount * ( 1 + rate )

EVALUATE
{ AddTax ( 10 ), AddTax ( 10, 0.2 ) }
-- Returns 11, 12
```

TMDL equivalent (note lowercase `function`):

```tmdl
createOrReplace
    /// AddTax returns amount including tax at the given rate.
    function AddTax = (amount : NUMERIC, rate : NUMERIC = 0.1) => amount * ( 1 + rate )
```

- **Type hints** are optional, in the form `[type] [subtype] [parameterMode]`.
  Add them to make call sites safer and more predictable; omit everything
  and a parameter defaults to `AnyVal val` (evaluated eagerly at call time).
  - *Type*: `AnyVal` / `Scalar` / `Table` / `AnyRef` / `CalendarRef` /
    `ColumnRef` / `MeasureRef` / `TableRef`.
  - *Subtype* (scalar only): `Variant` / `Int64` / `Decimal` / `Double` /
    `String` / `DateTime` / `Boolean` / `Numeric`. Specifying a subtype
    implies `Scalar`.
  - *ParameterMode*: `val` (eager — evaluated once in the caller's context
    before entering the body; inherits row **and** filter context) or
    `expr` (lazy — evaluated inside the body, so it inherits only filter
    context and can be re-evaluated under `CALCULATE`/iterators). Reference
    types must be `expr`.
- **Optional (default-valued) parameters**: append `= <DefaultExpression>`
  to make a parameter optional; the default is used when the caller omits
  the argument.
  - Unlike KQL/M, optional parameters may appear in **any** position — a
    required parameter can follow an optional one, and callers skip an
    argument with an empty slot: `AddTax ( , 0.2 )`. Arity is set by the
    position of the *rightmost required* parameter.
  - The default expression may only reference names visible where the UDF
    is **defined**, not where it's called, and cannot reference another
    optional parameter.
  - The type hint is enforced against the default only when the default is
    used; an explicit argument is checked against the hint instead.
- Use `///` doc comments above the definition (`@param` / `@returns`) — they
  surface as IntelliSense at call sites.

## Performance smells

- `CALCULATE ( ..., FILTER ( ALL ( 'Table' ), ... ) )` patterns —
  often slow. Test with DAX Studio Server Timings.
- Very large `DISTINCTCOUNT` over a high-cardinality column without
  filter context. Consider whether the visual really needs distinct
  count or whether a pre-aggregated measure would do.
- Use DAX Studio + VertiPaq Analyzer to profile real cost. Don't
  optimize on intuition.
