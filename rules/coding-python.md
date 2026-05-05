---
paths:
  - "**/*.py"
  - "**/*.ipynb"
---

# Python / PySpark Coding Conventions

Applies to Python and PySpark across notebooks, scripts, and packages.
Notebook = Fabric or Databricks notebook.

If a project-scope `.claude/rules/coding-python.md` exists, that file
supersedes this one.

## Baseline

- PEP 8 unless overridden below.
- Line length: 100 chars (PEP 8's 79 is too tight; 120 sacrifices side-by-side
  readability).
- 4-space indent. No tabs.
- UTF-8 source files.
- Type hints on all function signatures except trivial one-liners.
  Notebook code is exempt at the cell level but encouraged for any
  function defined inside the notebook.

## Naming

- **Modules / files**: `lower_snake_case.py`.
- **Functions / methods / variables**: `lower_snake_case`.
- **Classes**: `PascalCase`.
- **Constants**: `UPPER_SNAKE_CASE`. Module-level only.
- **Private**: leading underscore (`_internal_helper`).
- **Type variables**: `PascalCase`, single capital letter for short
  generics (`T`, `K`, `V`).
- Full words always — `customer_id`, not `cust_id`.

## Imports

Three groups, separated by a blank line, alphabetized within group:

1. Standard library
2. Third-party
3. Local / project

```python
# Good
import json
from datetime import datetime, timezone

import pandas as pd
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F

from project.utils import logging_helper

# Bad (mixed, unsorted)
import pandas as pd, json
from project.utils import logging_helper
from datetime import datetime
```

- `from pyspark.sql import functions as F` is the conventional alias.
- `import pandas as pd`, `import numpy as np`, `import polars as pl` —
  standard aliases, don't reinvent.
- Avoid wildcard imports (`from x import *`) outside notebook
  exploration.

## Docstrings (Google style)

Required on every public function, method, and class. Optional on
private helpers but encouraged.

```python
def filter_recent_order(df: DataFrame, lookback_days: int = 30) -> DataFrame:
    """Filter orders to those placed within the lookback window.

    Args:
        df: Order DataFrame with an OrderDate column of type DateType.
        lookback_days: Number of days back from the current UTC date.
            Defaults to 30.

    Returns:
        DataFrame filtered to orders placed within the window. Same
        schema as the input.

    Raises:
        ValueError: If lookback_days is non-positive.
    """
    if lookback_days <= 0:
        raise ValueError("lookback_days must be positive")
    cutoff = F.date_sub(F.current_date(), lookback_days)
    return df.filter(F.col("OrderDate") >= cutoff)
```

## f-strings

Preferred for all string formatting. `.format()` only when the format
string is a separate variable (e.g., loaded from config). `%` formatting
only for legacy `logging.Logger` calls.

```python
# Good
log.info(f"Processed {row_count:,} rows in {elapsed:.2f}s")

# Bad
log.info("Processed %d rows in %.2fs" % (row_count, elapsed))
```

## Error handling

- Catch specific exceptions. `except Exception:` only at the very top
  of a script with explicit re-raise or logged exit.
- Never `except: pass`. Silent failures destroy debugability.

```python
# Good
try:
    result = json.loads(payload)
except json.JSONDecodeError as exc:
    log.error(f"Invalid JSON in payload: {exc}")
    raise

# Bad
try:
    result = json.loads(payload)
except:
    pass
```

## PySpark conventions

### DataFrame variable naming

- `df` for a single DataFrame in a short scope.
- `<noun>_df` for multiple DataFrames in scope: `customer_df`, `order_df`,
  `joined_df`. Suffix style reads better than prefix in chained calls.

### Column references

Default: `F.col("ColumnName")`. Most explicit, supports operators
(`+`, `==`, `&`), survives column names with spaces.

```python
# Good
filtered_df = order_df.filter(
    (F.col("OrderDate") >= cutoff)
    & (F.col("IsCancelled") == False)  # noqa: E712
)

# Acceptable in trivial scope
filtered_df = order_df.filter(order_df.OrderDate >= cutoff)

# Bad (mixes attribute and string access; breaks on spaces)
filtered_df = order_df.filter(order_df["Order Date"] >= cutoff)
```

### Method chaining

Long chains: backslash continuation or wrap in parens, one method per
line. Parens preferred — no trailing-backslash trap.

```python
# Good
result_df = (
    order_df
    .filter(F.col("OrderDate") >= cutoff)
    .join(customer_df, on="CustomerId", how="left")
    .groupBy("CustomerId", "CustomerName")
    .agg(F.sum("OrderTotal").alias("TotalSpend"))
    .orderBy(F.col("TotalSpend").desc())
)
```

### Lazy evaluation awareness

- DataFrame operations are lazy. `.count()`, `.collect()`, `.show()`,
  `.write` trigger execution. Don't call them inside loops unless that's
  the actual intent.
- `.collect()` pulls all rows to the driver — guard with
  `.limit(n)` or aggregate first. Never `.collect()` an unaggregated
  dataset of unknown size.

### Caching

- Cache only when the same DataFrame is reused 2+ times in a job.
- `df.cache()` is `MEMORY_AND_DISK` by default, fine for most cases.
- Always `.unpersist()` when done if the dataset is large and the job
  continues. Otherwise let job termination clean up.

### Repartition vs coalesce

- `repartition(n)` — full shuffle, increases or decreases partitions.
- `coalesce(n)` — no shuffle, only decreases. Prefer for write-time
  partition control.

### UDFs

Last resort. Native Spark functions, then `pandas_udf`, then `udf` only
when nothing else works. Plain Python `udf` serializes per row and
disables Catalyst optimization.

## Notebook conventions

- One concept per cell. Don't pack a whole pipeline into one cell.
- Markdown cell at the top with: purpose, inputs, outputs, owner.
- Notebook parameters declared at the top via `dbutils.widgets` (Databricks)
  or `notebookutils.runtime.context` parameters (Fabric). Convert to
  notebook-convention names inside:

```python
# Notebook-parameter cell (Fabric)
source_schema = "raw"           # noqa
target_schema = "silver"        # noqa
load_date = "2026-04-25"        # noqa

# Convert if pipeline passed PascalCase
source_schema = source_schema or SourceSchema  # if pipeline passes PascalCase
```

## Anti-patterns

- Mutable default arguments (`def foo(x=[]):`) — classic Python gotcha.
- Bare `except:` clauses.
- `eval()` / `exec()` on untrusted input.
- `pd.DataFrame` operations on Spark-scale data — silently slow.
- Looping over a Spark DataFrame with `.collect()` then iterating —
  defeats the point of distributed compute.
- `print()` for diagnostics in production code; use `logging`.
