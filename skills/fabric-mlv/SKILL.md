---
name: fabric-mlv
description: "Use for Fabric Materialized Lake Views (MLVs) — `CREATE MATERIALIZED LAKE VIEW` Spark SQL + preview `@fmlv.materialized_lake_view` PySpark decorator on a schema-enabled lakehouse (Runtime 1.3). Covers CREATE / SHOW / ALTER RENAME / DROP / REFRESH FULL syntax, `CONSTRAINT ... CHECK ... ON MISMATCH DROP|FAIL` data quality rules, partitioning + TBLPROPERTIES, optimal refresh (skip / incremental / full) and CDF prerequisite, the supported-SQL-constructs table for incremental-vs-full fallback, lineage-driven dependency ordering, `RefreshMaterializedLakeViews` REST job-type (schedule + on-demand), run history (25 runs / 7 days; Success / Failed / Skipped / Canceled), data quality report, and gotchas: no ALTER definition only RENAME, no DML / UDF / temp views / time-travel, all-uppercase schemas rejected, names lowercased, `spark.conf.set` ignored on refresh, PySpark always full-refresh + lineage-schedule-only + no variables in `@fmlv` args, deleting defining notebook breaks PySpark refresh."
---

# Fabric Materialized Lake Views (MLV)

Declarative SQL/PySpark transformations that persist as Delta tables in a schema-enabled lakehouse. Fabric handles refresh strategy, dependency order, and data quality enforcement so you don't write notebook orchestration.

## When to use vs not

Use MLVs for medallion bronze→silver→gold pipelines, frequently-queried aggregates, declarative data quality, and reporting datasets that need automatic refresh. Skip them for one-off queries, sub-second streaming (use Real-Time Intelligence), or transformations that need ML inference / external API calls / non-SQL Python (use a regular Spark notebook).

## Prerequisites

- **Schema-enabled lakehouse** — required. `enableSchemas` is immutable per lakehouse; you can't retrofit it.
- **Fabric Runtime 1.3** — earlier runtimes can't author MLVs.
- **Region** — not available in South Central US (as of 2026-04).
- **CDF on source tables** — required for incremental refresh: `ALTER TABLE bronze.x SET TBLPROPERTIES (delta.enableChangeDataFeed = true)`. Without it, optimal refresh degrades to skip-or-full only.

## Spark SQL — CREATE

```sql
CREATE [OR REPLACE] MATERIALIZED LAKE VIEW [IF NOT EXISTS]
  [workspace.lakehouse.schema].MLV_Identifier
[(
    CONSTRAINT name1 CHECK (expr1) [ON MISMATCH DROP | FAIL],
    CONSTRAINT name2 CHECK (expr2) [ON MISMATCH DROP | FAIL]
)]
[PARTITIONED BY (col1, col2, ...)]
[COMMENT "..."]
[TBLPROPERTIES ("k1"="v1", ...)]
AS select_statement
```

| Clause | Notes |
|---|---|
| `OR REPLACE` | Mutually exclusive with `IF NOT EXISTS` |
| `CONSTRAINT ... CHECK` | Multiple allowed. Only deterministic built-ins permitted |
| `ON MISMATCH DROP` | Silently drops violating rows. Each row dropped at most once even if it violates multiple constraints |
| `ON MISMATCH FAIL` | Default. Stops the refresh with an error |
| `PARTITIONED BY` | Improves filtered-read performance |
| `TBLPROPERTIES` | Set `delta.enableChangeDataFeed=true` here to enable CDF on the MLV itself for downstream MLVs |

Workspace names with spaces require backtick-quoting: `` `My Workspace`.lakehouse.schema.view_name ``.

```sql
CREATE OR REPLACE MATERIALIZED LAKE VIEW silver.cleaned_orders
( CONSTRAINT valid_qty CHECK (quantity > 0) ON MISMATCH DROP )
PARTITIONED BY (category)
TBLPROPERTIES (delta.enableChangeDataFeed=true)
AS SELECT p.productID, p.category, o.orderDate, o.quantity, o.totalAmount
FROM bronze.products p INNER JOIN bronze.orders o ON p.productID = o.productID;
```

## Spark SQL — manage

```sql
SHOW MATERIALIZED LAKE VIEWS IN silver;
SHOW CREATE MATERIALIZED LAKE VIEW silver.cleaned_orders;
ALTER MATERIALIZED LAKE VIEW silver.cleaned_orders RENAME TO silver.cleaned_orders_v2;
DROP MATERIALIZED LAKE VIEW silver.cleaned_orders;
REFRESH MATERIALIZED LAKE VIEW silver.cleaned_orders FULL;
```

You **cannot `ALTER` the definition** — only `RENAME`. To change `SELECT`, constraints, or partitioning: drop and recreate (or `CREATE OR REPLACE`).

## PySpark (`fmlv` — preview)

Use when transformations need UDFs, external Python libraries, or reusable helper functions that are awkward in SQL.

```python
import fmlv
from pyspark.sql import functions as F

@fmlv.materialized_lake_view(
    name="LH1.silver.customer_enriched",
    partition_cols=["year", "city"],
    table_properties={"delta.enableChangeDataFeed": "true"},
    replace=True
)
@fmlv.check("nonnull_sales", "sales IS NOT NULL", "drop")
def customer_enriched():
    df = spark.read.table("LH2.bronze.customer_bronze")
    return df.withColumn("sales_in_usd", F.col("sales") * 1.0)
```

### Notebook organization rules (PySpark only)

- **One `@fmlv` decorator per cell** — multiple per cell is unsupported.
- Helper functions go in cells **above** the `@fmlv` cell.
- The defining notebook **must not be deleted** — scheduled refresh re-executes its cells. Deletion silently breaks every MLV defined there.
- After editing the decorator, **re-run the notebook** to register the change. Otherwise the next refresh executes the new code with stale registration metadata and may fail.
- **No variables in `@fmlv` arguments** — all parameters must be hardcoded literals. `name=view_name` will not work.
- Only `%%pyspark` and `%%sql` magics, and only at the top of a cell.
- Don't mix MLV definitions with unrelated code in the same notebook.

### PySpark trade-offs vs SQL

| Capability | Spark SQL | PySpark (`fmlv`) |
|---|---|---|
| Optimal (incremental) refresh | ✅ | ❌ — always full refresh or skip |
| On-demand refresh from notebook | ✅ (`REFRESH ... FULL`) | ❌ — lineage-schedule only |
| Rename via SQL | ✅ (`ALTER ... RENAME`) | ❌ — drop+recreate, or rename in lakehouse explorer |

## Optimal refresh

Optimal refresh is on by default. Per-run, Fabric picks one of three strategies based on Delta commits on source tables:

| Strategy | When |
|---|---|
| **Skip** | No new Delta commits on any source table |
| **Incremental** | New commits + query uses only the supported-construct subset + all sources have CDF enabled + append-only |
| **Full** | Source has updates/deletes, unsupported constructs, non-Delta source, or PySpark-defined MLV |

Toggle: lakehouse → **Materialized lake views** → **Manage** → **Optimal refresh**. Off = every scheduled run does a full rebuild.

### What blocks incremental refresh

| Construct | Behavior |
|---|---|
| `SELECT` aggregates (`SUM`, `COUNT`, `AVG`, `MIN`, `MAX`, `STDDEV`) | Full refresh |
| `GROUP BY`, `DISTINCT`, window functions | Full refresh |
| Non-deterministic funcs (`rand()`, `uuid()`, `current_timestamp()`) | Full refresh |
| `INNER JOIN`, `LEFT OUTER`, `LEFT SEMI`, `UNION ALL` | Incremental — but `LEFT` joins fall back to full if the right-side table changes |
| Subqueries / `EXISTS` | Full refresh if any referenced table changes |
| `WITH` (CTE) | Incremental if every clause inside is supported |
| Source is non-Delta table | Always full refresh |

Unsupported constructs **don't block creation** — they just downgrade to full refresh. Audit MLVs whose runs always show as Full when you expected Incremental.

## Lineage and scheduling

When an MLV references another MLV or table, Fabric builds a dependency DAG (the **lineage view**). A single schedule runs the whole DAG in the right order — you don't write orchestration. Currently **one active schedule per lineage** per lakehouse.

UI path: lakehouse → **Materialized lake views** → **Manage** → **Schedule** → **New schedule**.

Run history retention: **last 25 runs OR last 7 days, whichever comes first**.

| Run state | Meaning |
|---|---|
| `In progress` | Currently running |
| `Success` | All views in DAG refreshed |
| `Failed` | At least one view failed; downstream children auto-marked `Skipped` |
| `Skipped` | Same view already refreshing in another active run |
| `Canceled` | Manually canceled from Monitor hub |

Note: Monitor hub may show a `Skipped` MLV run as `Canceled` — they're the same thing in the lineage view.

## REST API (job scheduler)

`{jobType}` is `RefreshMaterializedLakeViews` for every MLV endpoint.

```http
# On-demand refresh of the entire lineage
POST /v1/workspaces/{ws}/lakehouses/{lh}/jobs/RefreshMaterializedLakeViews/instances
→ 202 Accepted, Location: .../jobs/instances/{jobInstanceId}

# Schedule CRUD
POST   /v1/workspaces/{ws}/lakehouses/{lh}/jobs/RefreshMaterializedLakeViews/schedules
GET    /v1/workspaces/{ws}/lakehouses/{lh}/jobs/RefreshMaterializedLakeViews/schedules
GET    /v1/workspaces/{ws}/lakehouses/{lh}/jobs/RefreshMaterializedLakeViews/schedules/{id}
PATCH  /v1/workspaces/{ws}/lakehouses/{lh}/jobs/RefreshMaterializedLakeViews/schedules/{id}
DELETE /v1/workspaces/{ws}/lakehouses/{lh}/jobs/RefreshMaterializedLakeViews/schedules/{id}

# Job instance status / cancel
GET  /v1/workspaces/{ws}/lakehouses/{lh}/jobs/RefreshMaterializedLakeViews/instances
GET  /v1/workspaces/{ws}/lakehouses/{lh}/jobs/instances/{jobInstanceId}
POST /v1/workspaces/{ws}/lakehouses/{lh}/jobs/instances/{jobInstanceId}/cancel
```

Polling pattern: take `Location` from the 202, poll the `Get Item Job Instance` endpoint until `status` ≠ `InProgress`. Job-scheduler limits cap schedules-per-lakehouse and visible historical instances.

## Data quality report

Auto-generated Power BI report tracking `CHECK` violations and `DROP` counts. Lakehouse → **Manage materialized lake views** → **Data quality report** → **Generate report**.

- Two pages: **Overview** (last 7 days, top MLVs/constraints) and **MLV Detail** (filterable by `SchemaName` / `MLVName` / `RelativeDate`).
- Built on DirectQuery — capped at **1M rows per query** on non-premium capacity.
- Workspace/lakehouse names with special characters or spaces can fail report generation.
- Recipients need at least `Read` or `ReadData` on the SQL analytics endpoint.
- Violations ≥ drops (one row only ever dropped once even if it violates multiple constraints).

## Limitations and gotchas

| Issue | Cause | Fix |
|---|---|---|
| MLV name unexpectedly lowercased | Names are case-insensitive, normalized to lowercase | Reference as lowercase everywhere; don't rely on `MyView` resolving distinct from `myview` |
| `ALTER` to change SELECT fails | Only `RENAME` is supported via `ALTER` | Drop + recreate, or `CREATE OR REPLACE` |
| `INSERT/UPDATE/DELETE` rejected | MLV is populated only by its `SELECT` | Modify the source table or rewrite the `SELECT` |
| Time-travel in definition rejected | `VERSION AS OF` / `TIMESTAMP AS OF` not allowed | Materialize the historical snapshot to a regular table first |
| UDF / temp view in definition rejected | Not supported in `CREATE MATERIALIZED LAKE VIEW` | Rewrite without UDFs, or switch to PySpark `fmlv` |
| Schema name `MYSCHEMA` rejected | All-uppercase schema names not supported | Use mixed-case or lowercase schema names |
| `spark.conf.set(...)` doesn't apply on refresh | Session-level Spark properties are dropped on scheduled refresh | Set lakehouse- or workspace-level properties instead |
| Optimal refresh always picks Full | Unsupported construct (aggregates / window / non-deterministic / non-Delta source) or no CDF on source | Check the supported-construct table; enable CDF; restructure SELECT |
| Incremental refresh skips changes from a LEFT join's right side | Right-side change triggers full refresh by design | Expected; or rewrite as INNER if right side is fully populated |
| PySpark MLV refresh fails after notebook edit | Decorator changed but notebook wasn't re-run | Re-execute every cell once after editing; refresh re-uses the latest cell contents |
| PySpark MLV stops refreshing | Defining notebook deleted | The notebook is load-bearing for PySpark MLVs — don't delete it |
| `@fmlv.materialized_lake_view(name=view_name)` errors | Variables not allowed in decorator args | Hardcode every parameter as a literal |
| MLV name with `.` rejected | Periods reserved for `workspace.lakehouse.schema.name` qualification | Use `_` or another separator |
| Two MLVs in one PySpark cell — only one registers | One decorator per cell limit | Split into separate cells |
| Run shows as `Canceled` in Monitor hub but `Skipped` in lineage | Monitor hub maps Skipped → Canceled | Trust the lineage view's status |
| Data quality report fails to generate | Workspace/lakehouse name has spaces or special characters | Rename, or generate the report against a clean-named lakehouse |
| Data quality report missing rows | DirectQuery 1M-row cap on non-premium | Use premium capacity, or recreate the report after pruning history |
| Cross-lakehouse MLV chain doesn't work | Cross-lakehouse lineage and execution not supported | Keep MLV chains within a single lakehouse |

## Reference

- Microsoft Learn: [What are materialized lake views in Microsoft Fabric?](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/overview-materialized-lake-view)
- Microsoft Learn: [Spark SQL reference for materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/create-materialized-lake-view)
- Microsoft Learn: [Optimal refresh for materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/refresh-materialized-lake-view)
- Comprehensive MS Learn link bundle (concept / SQL ref / PySpark fmlv / optimal refresh / lineage / scheduling REST / monitoring / data quality report / lakehouse schemas + Runtime 1.3 prereqs): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- `fabric-spark` — PySpark in Fabric notebooks (the broader Spark surface; MLVs are one consumer)
- `fabric-eventhouse` — KQL materialized views (different engine, similar concept)
- `fabric-error-handling` — notebook/pipeline error patterns; useful when wrapping MLV refresh in a larger flow
- `fabric-monitoring` — Monitor hub and Workspace monitoring
- `pbip-project-structure` — `.Lakehouse/` folder placement when MLV-bearing lakehouses live in a PBIP repo
