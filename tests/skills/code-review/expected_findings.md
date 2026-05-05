# code-review skill — expected findings

Per-fixture cheat sheets used to validate the skill's review output.
Severity rubric matches the skill body: 🔴 Critical / 🟡 Warning /
🟢 Suggestion.

Use after each fixture's validation run to diff actual skill output
against expected findings. Calibration drift on severity is
observation-worthy, not a hard fail.

Line numbers reference the fixture as currently committed. If a
fixture has been modified during a prior validation run (e.g., an
Edit was accepted), restore from git history before re-running.

---

## python_fixture.py

Six-category fixture covering Correctness, Security, Scaling, Error
handling, Naming/style, Maintainability.

🔴 Critical:

- `python_fixture.py:5` — `API_KEY` hardcoded credential. (Security)
- `python_fixture.py:17` — f-string SQL injection in `query`. (Security)

🟡 Warning:

- `python_fixture.py:15` — Off-by-one: `range(len(customer_ids) - 1)`
  drops last element. (Correctness)
- `python_fixture.py:15-19` — N+1 query pattern: per-customer
  `spark.sql` in loop. (Scaling)
- `python_fixture.py:21` — `.toPandas()` on unioned Spark DataFrame.
  (Scaling)
- `python_fixture.py:33-34` — Bare `except: pass` swallows all
  exceptions in `fetch_pricing`. (Error handling)
- `python_fixture.py:25` — Missing docstring on `fetch_pricing`.
  (Maintainability)
- `python_fixture.py:30` — Magic number `86400` for timeout.
  (Maintainability)

🟢 Suggestion:

- `python_fixture.py:9` — `cols` → `columns`. (Naming)
- `python_fixture.py:10` — `df_tmp` → descriptive name like
  `combined_order_df`. (Naming)
- `python_fixture.py:16` — `customerId` should be `customer_id`
  (snake_case in Python). (Naming)
- `python_fixture.py:8,25` — Missing type hints on function
  signatures. (Maintainability per coding-python.md)

Note: `load_config_file` (lines 37-43) is intentionally clean — narrow
`OSError` catch, documented `None` return in the docstring. Acts as a
negative control. Skill should NOT flag it; if it does, that's
calibration drift to record.

**Fixture provenance**: this function was modified once during a
prior validation run (the original had `except:` bare-catch and no
docstring; the patch tightened it to `except OSError:` plus a
docstring documenting the `None` return path). The current state is
the canonical fixture — the modification was deliberate and fixed
the cheat sheet's line numbers (the 1-line docstring addition
pushed lines below it down by 1, which is reflected in the line
references above). If line numbers drift again, restore from git
history rather than updating the cheat sheet.

Coverage: Correctness ✓ Security ✓ Scaling ✓ Error handling ✓
Naming/style ✓ Maintainability ✓.

---

## pyspark_fixture.py

PySpark-specific style and scaling fixture. Correctness/Security/
Error-handling intentionally absent — covered by `python_fixture.py`.

🔴 Critical:

- `pyspark_fixture.py:10` — `.collect()` on unaggregated full-scan
  result, then row iteration. Defeats distributed compute. (Scaling)

🟡 Warning:

- `pyspark_fixture.py:22` — `.toPandas()` after a join + groupBy
  without filter pushdown — driver OOM risk. (Scaling)
- `pyspark_fixture.py:7` — Attribute-style column access with
  space-containing name (`OrderDf["Order Date"]`) — works but
  inconsistent with `F.col()` convention. (Naming/style per
  coding-python.md)

🟢 Suggestion:

- `pyspark_fixture.py:5` — `Aggregate_Customer_Spend` should be
  `aggregate_customer_spend` (PascalCase function name violates
  snake_case). (Naming)
- `pyspark_fixture.py:6` — `OrderDf` should be `order_df` (PascalCase
  variable). (Naming)
- `pyspark_fixture.py:7,9` — `df_tmp`, `cust_df` non-descriptive;
  `df_tmp` violates "full names always" rule. (Naming)
- `pyspark_fixture.py:12,14` — `Result` is PascalCase variable.
  (Naming)
- `pyspark_fixture.py:5,18` — Missing type hints, missing docstring on
  both functions. (Maintainability)
- `pyspark_fixture.py:19-21` — Long method chain on one line; should
  wrap one method per line in parens. (Style per coding-python.md)

Coverage: Scaling ✓ Naming/style ✓ Maintainability ✓.

---

## tsql_fixture.sql

T-SQL rule co-load + style/correctness fixture.

🔴 Critical:

- `tsql_fixture.sql:1` — `SELECT *` in production-shaped statement.
  (Per coding-tsql.md anti-pattern)
- `tsql_fixture.sql:2` — Implicit/comma join (`FROM Customer c, [Order]
  o`) instead of explicit `INNER JOIN`. Pre-ANSI; obscures join
  semantics. (Style/correctness)

🟡 Warning:

- `tsql_fixture.sql:2` — No schema qualification on `Customer` (bare).
  (Style per coding-tsql.md)
- `tsql_fixture.sql:2,11` — Bracket quoting `[Order]` only required
  because of reserved word; bracket quoting elsewhere is anti-pattern.
  (Style)
- `tsql_fixture.sql:7-14` — Lowercase keywords (`select`, `from`,
  `join`, `where`, `group by`, `having`). Should be UPPERCASE. (Style)
- `tsql_fixture.sql:7-14` — Trailing-comma style. Repo convention is
  leading commas. (Style)
- `tsql_fixture.sql:11` — `join` without explicit `INNER` keyword.
  (Style)
- `tsql_fixture.sql:5,14` — No semicolon terminators. (Style —
  universally required)
- `tsql_fixture.sql:8` — `total_spend` alias without `AS` keyword.
  (Style)

🟢 Suggestion:

- `tsql_fixture.sql:3,4` — `customer_id`, `order_date`, `order_total`
  snake_case where convention is PascalCase for new objects.
  Acceptable if inherited from source. (Naming — context-dependent)
- `tsql_fixture.sql:1-14` — Two unrelated queries in same file; second
  statement should use CTEs. (Maintainability)

Coverage: Style ✓ Naming ✓ Maintainability ✓ — T-SQL rule co-load.

---

## notebooks/sparksql_fixture.sql

Spark SQL rule co-load + T-SQL syntax bleed-through fixture.
Critical co-load check: `/context` should show `coding-sparksql.md`
loaded for this file (not `coding-tsql.md`). If T-SQL rule loads
instead, path-glob discrimination failed.

🔴 Critical:

- `notebooks/sparksql_fixture.sql:1` — `SELECT TOP 10` is T-SQL syntax;
  Spark SQL uses `LIMIT n`. Will fail to parse. (Correctness per
  coding-sparksql.md)
- `notebooks/sparksql_fixture.sql:4` — `DATEADD(day, -30, GETDATE())`
  is T-SQL signature; Spark uses `DATE_SUB(CURRENT_DATE(), 30)` or
  `DATE_ADD()` with different argument order. (Correctness)
- `notebooks/sparksql_fixture.sql:2,10` — Bracket quoting `[Order]` is
  T-SQL only; Spark SQL requires backticks `` `Order` ``. Will fail to
  parse. (Correctness)

🟡 Warning:

- `notebooks/sparksql_fixture.sql:1` — `SELECT *` over wide Delta
  table; wastes I/O. (Scaling per coding-sparksql.md)
- `notebooks/sparksql_fixture.sql:2,3,10` — Bare table names without
  three-part naming (`<catalog>.<schema>.<table>`). Relies on session
  state. (Style)
- `notebooks/sparksql_fixture.sql:11` — `LOWER(Region) = 'emea'`
  disables predicate pushdown. (Performance per coding-sparksql.md)
- `notebooks/sparksql_fixture.sql:8` — Trailing-comma style; repo
  convention is leading commas. (Style)

🟢 Suggestion:

- `notebooks/sparksql_fixture.sql:5,12` — No semicolon terminators.
  (Style)

Coverage: Spark SQL rule co-load ✓ T-SQL syntax bleed-through ✓.

---

## pipeline/pipeline_fixture.json

Pipeline expression rule co-load + naming/null-safety fixture.
Loaded rule: `coding-expressions.md` (covers all WDL contexts —
Fabric pipelines, ADF/Synapse, Logic Apps, Power Automate).

🔴 Critical:

- `pipeline/pipeline_fixture.json:36` — `@Concat(...)` PascalCase;
  built-in functions are camelCase by language definition (`concat`).
  Will fail to resolve. (Correctness per coding-expressions.md)

🟡 Warning:

- `pipeline/pipeline_fixture.json:13,23,31` — Activity names contain
  spaces (`"Lookup Config"`, `"Set BatchSize"`, `"Copy Customer"`).
  Breaks `activity('Name')` references silently. Should be
  `LookupConfig`, `SetBatchSize`, `CopyCustomer`. (Style)
- `pipeline/pipeline_fixture.json:5` — Parameter `sourceSchema` is
  camelCase. Should be `SourceSchema`. Same for `targetSchema`.
  (Naming)
- `pipeline/pipeline_fixture.json:9` — Variable `row_count` is
  snake_case. Should be `RowCount`. (Naming)
- `pipeline/pipeline_fixture.json:27` — `@activity('Lookup
  Config').output.firstRow.BatchSize` — null-unsafe; if Lookup returns
  no rows, `firstRow` is null and the property reference fails the
  activity. Should `coalesce()` or `if(empty(...))` guard. (Null
  safety)
- `pipeline/pipeline_fixture.json:44` — `dependencyConditions:
  ["Completion"]` papers over Lookup failure. Should be `["Succeeded"]`
  unless cleanup intent is explicit. (Anti-pattern)

🟢 Suggestion:

- `pipeline/pipeline_fixture.json:2` — Pipeline name has spaces;
  should be PascalCase. (Style)
- `pipeline/pipeline_fixture.json:18` — `sqlReaderQuery` hardcodes
  `dbo.Config` and `'load_customer'`; should be parameterized.
  (Anti-pattern: hard-coded values)
- `pipeline/pipeline_fixture.json:40` — `tableOption: autoCreate`
  without specifying schema; implicit dependency on source schema.
  (Maintainability)

Coverage: Expression-rule co-load ✓ naming convention enforcement ✓
null safety ✓ dependency conditions ✓.

---

## tmdl_fixture.tmdl

TMDL identifier-with-display-alias pattern + format-string discipline
fixture.

🔴 Critical:

- `tmdl_fixture.tmdl:1` — Table identifier `transaction_line` is
  snake_case. Should be `TransactionLine` with `displayName:
  "Transaction Line"` alias. (Naming per coding-tmdl.md)
- `tmdl_fixture.tmdl:4` — Column `transaction_date` is snake_case.
  Should be `TransactionDate` with `displayName: "Transaction Date"`.
  (Naming)
- `tmdl_fixture.tmdl:16` — Measure `totalSales` is camelCase. Should
  be `TotalSales` with `displayName: "Total Sales"`. (Naming)
- `tmdl_fixture.tmdl:18` — Measure `margin` is lowercase. Should be
  `Margin` with `displayName: "Margin"`. (Naming)

🟡 Warning:

- `tmdl_fixture.tmdl:14` — `summarizeBy: sum` on `CustomerId` (column
  declared at line 12). IDs should never auto-aggregate. Should be
  `summarizeBy: none`. (Anti-pattern)
- `tmdl_fixture.tmdl:4-6` — `transaction_date` missing `formatString`.
  Dates should have explicit `formatString: "yyyy-mm-dd"`. (Style)
- `tmdl_fixture.tmdl:8-10` — `OrderTotal` missing `formatString`.
  Currency columns should have `"$#,##0.00;-$#,##0.00"`. (Style)
- `tmdl_fixture.tmdl:12-14` — `CustomerId` missing `isHidden: true` if
  surrogate key not meant for direct user consumption. (Style —
  context-dependent)
- `tmdl_fixture.tmdl:16,18` — Both measures missing `displayName`
  aliases. (Naming)
- `tmdl_fixture.tmdl:16,18` — Both measures missing `description`.
  (Per coding-tmdl.md)

🟢 Suggestion:

- `tmdl_fixture.tmdl:16` — `totalSales` measure missing
  `formatString`. (Style)
- `tmdl_fixture.tmdl:1` — Measures inline in fact table instead of
  dedicated `_Measures` table. (Style per coding-tmdl.md)

Coverage: TMDL rule co-load ✓ identifier-with-display-alias ✓ format
string discipline ✓ summarizeBy on IDs ✓.

---

## dax_fixture.dax

DAX function casing + table-qualification + DIVIDE + VAR/RETURN
decomposition fixture.

🔴 Critical:

- `dax_fixture.dax:1` — `sumx` lowercase; functions should be
  UPPERCASE (`SUMX`). (Style per coding-dax.md)
- `dax_fixture.dax:1` — Bare column references `[Quantity]`,
  `[Unit Price]`; should be table-qualified: `'Transaction
  Line'[Quantity]`. (Style — measure-vs-column ambiguity)
- `dax_fixture.dax:3` — `/` divide operator without `DIVIDE()`. Will
  return infinity or error on `[Revenue] = 0`. The IF guard is the
  workaround for missing DIVIDE. (Anti-pattern)

🟡 Warning:

- `dax_fixture.dax:5-9` — `CALCULATE([Total Sales],
  SAMEPERIODLASTYEAR(...))` evaluated twice instead of decomposed into
  `VAR`/`RETURN`. (Performance + style)
- `dax_fixture.dax:11-15` — Nested `IF` four levels deep. Should be
  `SWITCH(TRUE(), ...)`. (Anti-pattern)
- `dax_fixture.dax:1` — Single-line measure for non-trivial logic;
  should be multi-line with function args on separate lines. (Style)

🟢 Suggestion:

- `dax_fixture.dax:1,3,5,11` — Measure names use spaces (`Total
  Sales`, `Margin Pct`, `Sales YoY %`, `Customer Tier`). DAX measure
  names with spaces are legal; in TMDL context, identifier should be
  PascalCase with display alias. Skill should flag if reviewing in
  TMDL context, accept if reviewing standalone DAX. (Style —
  context-dependent)

Coverage: DAX rule co-load ✓ function casing ✓ table-qualified column
refs ✓ DIVIDE over `/` ✓ VAR/RETURN decomposition ✓ IF→SWITCH ✓.

---

## kql_fixture.kql

KQL lowercase-keyword + time-filter-first + tolower-anti-pattern
fixture.

🔴 Critical:

- `kql_fixture.kql:2-6` — Operators uppercased (`SUMMARIZE`, `WHERE`,
  `WHERE`, `ORDER BY`, `TAKE`). KQL convention is **lowercase**.
  (Style per coding-kql.md — explicit anti-pattern, "do not uppercase
  like T-SQL")
- `kql_fixture.kql:9` — `TOLOWER(...)` uppercase function name; KQL
  functions are lowercase (`tolower`). (Style)
- `kql_fixture.kql:2-4` — `summarize` (line 2) before `where
  TimeGenerated` (line 4); filters AFTER aggregation force full table
  scan. Time filter should be FIRST clause. (Performance per
  coding-kql.md)

🟡 Warning:

- `kql_fixture.kql:9` — `TOLOWER(UserPrincipalName) ==
  "admin@contoso.com"` disables index acceleration on indexed string
  column. Should use `=~` (case-insensitive equality). (Per
  coding-kql.md anti-pattern)
- `kql_fixture.kql:1-6` — No `let`-bound time window or threshold
  (`7d`, `5`); magic numbers scattered through query. Should extract
  to top-of-query `let` block. (Style)
- `kql_fixture.kql:8-11` — Time filter missing entirely on
  `SigninLogs` — telemetry table without time bound is full-history
  scan. (Performance — possibly 🔴 depending on skill calibration)

🟢 Suggestion:

- `kql_fixture.kql:6` — `TAKE 100` after `ORDER BY` is the right
  order, but uppercase syntax. (Style)
- `kql_fixture.kql:4` — `7d` literal embedded directly in `ago()`;
  consider `let LookbackWindow = 7d;`. (Style)

Coverage: KQL rule co-load ✓ lowercase keyword discipline ✓ clause
order / time-filter-first ✓ `tolower` anti-pattern ✓.
