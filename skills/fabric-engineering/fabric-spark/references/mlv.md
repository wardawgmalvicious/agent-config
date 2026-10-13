# Fabric Materialized Lake Views (MLV)

Declarative SQL/PySpark transformations that persist as Delta tables in a schema-enabled lakehouse. Fabric handles refresh strategy, dependency order, and data quality enforcement so you don't write notebook orchestration.

## When to use vs not

Use MLVs for medallion bronze→silver→gold pipelines, frequently-queried aggregates, declarative data quality, and reporting datasets that need automatic refresh. Skip them for one-off queries, sub-second streaming (use Real-Time Intelligence), or transformations that need ML inference / external API calls / non-SQL Python (use a regular Spark notebook).

## Prerequisites

- **Schema-enabled lakehouse** — required. `enableSchemas` is immutable per lakehouse; you can't retrofit it.
- **Fabric Runtime 1.3** — earlier runtimes can't author MLVs. Upstream still names 1.3 exactly (re-checked 2026-10-06), and **has not** extended the prerequisite to **Runtime 2.0** (GA Aug 2026 — Spark 4.1, Delta Lake 4.2, Python 3.13), so treat 2.0 as unverified for MLV authoring rather than assumed. 2.0 was planned to become the default for new workspaces and environment items in late September 2026, but as of 2026-10-06 Learn's runtime page still says new workspaces use 1.3, now marked end of support announced. When the default does move, a new workspace stops defaulting to a runtime MLVs are documented against: re-check the prerequisite then.
- **CDF on source tables** — required for incremental refresh: `ALTER TABLE bronze.x SET TBLPROPERTIES (delta.enableChangeDataFeed = true)`. Without it, optimal refresh degrades to skip-or-full only.

## Spark SQL — CREATE

```sql
CREATE [OR REPLACE] MATERIALIZED LAKE VIEW [IF NOT EXISTS]
  [workspace.lakehouse.schema].MLV_Identifier
[(
    CONSTRAINT name1 CHECK (expr1) [ON MISMATCH DROP | FAIL],
    CONSTRAINT name2 CHECK (expr2) [ON MISMATCH DROP | FAIL]
)]
[(
    REFRESH_HINT hint_name UNIQUE (col1 [, col2, ...])   -- preview
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
| `REFRESH_HINT … UNIQUE (…)` | **Preview.** Declares the output columns that uniquely identify a row, so source updates and deletes can refresh incrementally instead of in full |
| `PARTITIONED BY` | Improves filtered-read performance |
| `TBLPROPERTIES` | Set `delta.enableChangeDataFeed=true` here to enable CDF on the MLV itself for downstream MLVs |

**`REFRESH_HINT` (preview) is trusted, not checked.** Fabric doesn't validate uniqueness at runtime: declared columns that aren't unique can leave the view inconsistent, with no error or warning. Before declaring one, check the candidate key for duplicates (`SELECT <cols>, COUNT(*) FROM <view> GROUP BY <cols> HAVING COUNT(*) > 1`) and for `NULL`s, and check again whenever the definition or an upstream source changes. A source schema change between refreshes forces a full refresh.

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
| **Incremental** | New commits + query uses only the supported-construct subset + all sources have CDF enabled + either append-only sources, or updates/deletes with a `REFRESH_HINT` declaring row identity (preview) |
| **Full** | Updates/deletes with no refresh hint, unsupported constructs, non-Delta source, PySpark-defined MLV, or a source small enough that a full recompute is faster than incremental |

Toggle: lakehouse → **Materialized lake views** → **Manage** → **Optimal refresh**. Off = every scheduled run does a full rebuild. A **schedule can override it** under its own **Advanced settings**; per-schedule settings beat lakehouse defaults, which beat system defaults.

### What blocks incremental refresh

| Construct | Behavior |
|---|---|
| `GROUP BY` / aggregates: `SUM`, `MIN`, `MAX`, `COUNT` (without `DISTINCT`) | Incremental, with no partitioning requirement |
| `GROUP BY` / aggregates: any other (`AVG`, `STDDEV`, …), including one mixed with the four above | Incremental only if every source table is partitioned and its partition column is in the `GROUP BY`; otherwise full refresh |
| `DISTINCT`, window functions | Full refresh |
| Non-deterministic funcs (`rand()`, `uuid()`, `current_timestamp()`) | Full refresh |
| `INNER JOIN`, `LEFT OUTER`, `LEFT SEMI`, `UNION ALL` | Incremental — but `LEFT` joins fall back to full if the right-side table changes |
| Subqueries / `EXISTS` | Full refresh if any referenced table changes |
| `WITH` (CTE) | Incremental if every clause inside is supported |
| Source is non-Delta table | Always full refresh |

`GROUP BY` columns must appear in the `SELECT` list.

Unsupported constructs **don't block creation** — they just downgrade to full refresh. Audit MLVs whose runs always show as Full when you expected Incremental.

## Lineage and scheduling

When an MLV references another MLV or table, Fabric builds a dependency DAG (the **lineage view**). A schedule runs its scope in dependency order — you don't write orchestration. Multiple schedules can coexist on one lakehouse and **each runs independently**, so give separate lineages their own cadence rather than forcing everything onto one.

UI path: lakehouse → **Materialized lake views** → **Manage** → **Manage schedules** → **New schedule**. Each schedule takes a name, an optional description, and a scope: **Refresh all materialized lake views** or **Refresh selected materialized lake view(s)** (any level of the lineage; selected views get a dashed border in the graph).

### Refresh type

| Type | Detail |
|---|---|
| **Time-based** | Repeat by minute / hourly / daily / weekly / monthly, one or more time slots, start date, end date, time zone. |
| **Event-triggered** (**Preview**) | Fires on an event instead of a clock. Event source type is **Job events** (Fabric Notebook or ADF pipeline completion) or **OneLake events** (ingestion into OneLake); then pick the event type and configure the source. |

Use event-triggered when source arrival is unpredictable — a fixed cadence either wastes compute on no-op runs or lags the data.

**Event-triggered gotchas.** Only OneLake events and Notebook / Pipeline job events are supported as sources. **Private Link is out of preview scope.** The mechanism depends on an auto-created **"FMLV Refresh" Notebook and Activator** pair in the workspace — they look like stray auto-generated items and they are load-bearing. Modifying or deleting them can silently stop event-triggered refreshes.

### Advanced settings

| Setting | Detail | Default |
|---|---|---|
| **Spark environment** | Any Spark environment you have access to **within the same capacity**, including one in a different workspace. Changes apply on the next refresh. Lose access to it and you lose the **Schedule** and **Run** actions; delete it and the dropdown errors until you pick an accessible one. | Workspace default |
| **Optimal refresh** | Per-schedule override of the lakehouse toggle. | On |

Priority order: per-schedule → lakehouse-level → system defaults.

### Cross-lakehouse: Extended lineage

MLV chains **can** span lakehouses, and workspaces. Turn on the **Extended lineage** toggle in the schedule configuration and a tree of every upstream lakehouse discovered through lineage appears; check the ones to include. **Leaving all of them unselected includes every lakehouse in the extended lineage** — the permissive default, not a no-op. The current lakehouse is always included implicitly.

Fabric refreshes upstream views first, then downstream, across every included lakehouse; independent branches run in parallel; Recent runs shows a **single** run entry for the whole thing. So a Bronze → Silver → Gold flow across three lakehouses is one schedule defined in Gold, not three coordinated ones.

Ad-hoc equivalent: **Run** on the lineage toolbar → **On demand lineage refresh**, then pick an execution mode — *Refresh without dependant lineage* (selected views only), *Refresh with dependant lineage* (plus upstream within the current lakehouse), or *Refresh with extended lineage* (plus upstream lakehouses, same tree).

| Requirement | Detail |
|---|---|
| View an upstream lakehouse | `ReadAll` on it. With OneLake-based permissions enabled: `Read` on the required tables/MLVs. |
| Include a lakehouse in the refresh | `ReadWrite` on it. With OneLake-based permissions enabled: `ReadWrite` on the required MLVs. |
| Spark environment | Any you can access within the same capacity. |
| Inaccessible dependencies | Show as **faulted nodes**. **Any faulted node blocks the whole lineage refresh** — it won't run at all. |
| Maximum run duration | 24 hours, same as a standard run. |

### Run behavior

A run **fails if it exceeds 24 hours**. If a refresh starts while another is still in progress, **Fabric skips the later one** — it is not queued. A schedule that "didn't run" is usually this.

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

### Scoping a refresh — MLV execution definitions

Without `executionData`, the on-demand refresh and a schedule created over REST refresh the whole lineage. An **MLV execution definition** is a saved selection — which MLVs, which upstream lakehouses, the refresh mode and the Spark environment — that a run or a schedule can be scoped to instead.

```http
# Execution definition CRUD
POST   /v1/workspaces/{ws}/lakehouses/{lh}/mlvexecutiondefinitions        → 201 Created, Location
GET    /v1/workspaces/{ws}/lakehouses/{lh}/mlvexecutiondefinitions        → 200
GET    /v1/workspaces/{ws}/lakehouses/{lh}/mlvexecutiondefinitions/{id}   → 200
PATCH  /v1/workspaces/{ws}/lakehouses/{lh}/mlvexecutiondefinitions/{id}   → 200
DELETE /v1/workspaces/{ws}/lakehouses/{lh}/mlvexecutiondefinitions/{id}   → 200
```

Create body, from Learn's sample:

```json
{
  "displayName": "Gold Chain – Sales",
  "description": "Nightly refresh for the Sales gold-layer views",
  "settings": {
    "environment": { "referenceType": "ById", "itemId": "<ENVIRONMENT_ID>", "workspaceId": "<ENVIRONMENT_WORKSPACE_ID>" },
    "refreshMode": "Optimal"
  },
  "currentLakehouseExecutionContext": {
    "mode": "Selected",
    "selectedMlvs": ["dbo.gold_sales_summary", "dbo.gold_sales_daily"]
  },
  "extendedLineageExecutionContext": { "mode": "All" }
}
```

`refreshMode` is `Optimal` or `Full`. Each execution context takes a `mode` of `All` or `Selected` — `selectedMlvs` for the current lakehouse, `selectedLakehouses` (`referenceType` / `itemId` / `workspaceId`) for extended lineage.

To scope a run, send `executionData` with the on-demand refresh (`POST .../jobs/RefreshMaterializedLakeViews/instances` → `202 Accepted`, `Location`, `Retry-After: 60`), or with a schedule create (`POST .../schedules` → `201`) or update (`PATCH .../schedules/{id}` → `200`), where it sits beside `enabled` and `configuration`:

```json
{ "executionData": { "mlvExecutionDefinitionId": "<mlvExecutionDefinitionId>" } }
```

Two behaviours a caller won't guess:

- **PATCH merges.** Only the fields in the body are updated; omitted fields keep their existing values.
- **Deleting a definition deletes its schedules.** Any schedule linked to it is removed with it.

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
| Optimal refresh always picks Full | Unsupported construct (window / non-deterministic / non-Delta source, or an aggregate other than `SUM`/`MIN`/`MAX`/`COUNT` over unpartitioned sources) or no CDF on source | Check the supported-construct table; enable CDF; restructure SELECT |
| Incremental refresh skips changes from a LEFT join's right side | Right-side change triggers full refresh by design | Expected; or rewrite as INNER if right side is fully populated |
| PySpark MLV refresh fails after notebook edit | Decorator changed but notebook wasn't re-run | Re-execute every cell once after editing; refresh re-uses the latest cell contents |
| PySpark MLV stops refreshing | Defining notebook deleted | The notebook is load-bearing for PySpark MLVs — don't delete it |
| `@fmlv.materialized_lake_view(name=view_name)` errors | Variables not allowed in decorator args | Hardcode every parameter as a literal |
| MLV name with `.` rejected | Periods reserved for `workspace.lakehouse.schema.name` qualification | Use `_` or another separator |
| Two MLVs in one PySpark cell — only one registers | One decorator per cell limit | Split into separate cells |
| Run shows as `Canceled` in Monitor hub but `Skipped` in lineage | Monitor hub maps Skipped → Canceled | Trust the lineage view's status |
| Data quality report fails to generate | Workspace/lakehouse name has spaces or special characters | Rename, or generate the report against a clean-named lakehouse |
| Data quality report missing rows | DirectQuery 1M-row cap on non-premium | Use premium capacity, or recreate the report after pruning history |
| Cross-lakehouse MLV chain doesn't refresh | A cross-lakehouse chain refreshes only through **Extended lineage**; a plain schedule stops at the current lakehouse | Turn on Extended lineage; `ReadAll` to see an upstream lakehouse, `ReadWrite` to include it |
| Cross-lakehouse refresh won't start at all | A faulted node in the lineage graph — an upstream dependency you can't access | Grant `ReadAll`/`Read` on it, or drop that lakehouse from the schedule's scope |
| Scheduled refresh appears not to have run | Another refresh was in progress; Fabric **skips** the later run rather than queueing it | Space schedules beyond the longest run, or consolidate into one schedule |
| Long-running refresh dies around the day mark | Hard **24-hour** cap on a run, standard or cross-lakehouse | Split the lineage across schedules, or fix what makes the run take a day |
| Event-triggered refreshes silently stopped | The auto-created **"FMLV Refresh" Notebook / Activator** items were edited or deleted | Don't touch them; recreate the event-triggered schedule to regenerate |

## Reference

- Microsoft Learn: [What are materialized lake views in Microsoft Fabric?](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/overview-materialized-lake-view)
- Microsoft Learn: [Spark SQL reference for materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/create-materialized-lake-view)
- Microsoft Learn: [Optimal refresh for materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/refresh-materialized-lake-view)
- Comprehensive MS Learn link bundle (concept / SQL ref / PySpark fmlv / optimal refresh / lineage / scheduling REST / monitoring / data quality report / lakehouse schemas + Runtime 1.3 prereqs): [§ MS Learn link bundle](#ms-learn-link-bundle), below

## MS Learn link bundle

Curated set of Microsoft Learn pages relevant to Microsoft Fabric Materialized Lake Views (MLVs) — the declarative `CREATE MATERIALIZED LAKE VIEW` Spark SQL surface (GA March 2026), the still-preview `@fmlv.materialized_lake_view` PySpark decorator, optimal refresh (skip / incremental / full) and the CDF prerequisite, lineage-driven scheduling, the `RefreshMaterializedLakeViews` REST API, the auto-generated data quality report, and the lakehouse-schemas + Runtime 1.3 prerequisites.

The 3 highest-leverage entry points (concept overview, Spark SQL reference, optimal refresh) are also linked in § Reference above; this section holds the comprehensive set.

**Note on coverage:** MLVs are documented thoroughly under `learn.microsoft.com/fabric/data-engineering/materialized-lake-views/`. This file's value-add over the docs is the consolidated gotchas table (PySpark notebook organization rules, `spark.conf.set` ignored on refresh, names lowercased, the supported-construct table for incremental fallback, the Skipped-vs-Canceled status display mismatch).

### Concept and when to use

- [What are materialized lake views in Microsoft Fabric?](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/overview-materialized-lake-view) — start here. Concept, lifecycle (create / refresh / query / monitor), authoring options, when MLVs fit vs when to use Spark notebooks or Real-Time Intelligence instead. The South Central US region exclusion lives here.
- [Get started with materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/get-started-with-materialized-lake-views) — the prerequisites: workspace on Fabric capacity, **schema-enabled lakehouse**, **Runtime 1.3**.
- [Tutorial: Implement medallion architecture with materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/tutorial) — end-to-end bronze → silver → gold walkthrough.
- [Use materialized lake views for medallion architecture (OneLake guidance)](https://learn.microsoft.com/fabric/onelake/onelake-medallion-lakehouse-architecture#use-materialized-lake-views-for-medallion-architecture) — where MLVs fit in the broader medallion / data-mesh story.

### Spark SQL reference

- [Spark SQL reference for materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/create-materialized-lake-view) — `CREATE [OR REPLACE] [IF NOT EXISTS]`, `CONSTRAINT ... CHECK ... ON MISMATCH DROP|FAIL`, `PARTITIONED BY`, `TBLPROPERTIES`, `SHOW MATERIALIZED LAKE VIEWS`, `SHOW CREATE`, `ALTER ... RENAME` (only RENAME, no definition update), `DROP`, plus the Spark-SQL limitations (no DML, no time-travel, no UDFs, no temp views as sources, no all-uppercase schemas, session-level `spark.conf.set` ignored on refresh).

### PySpark (`fmlv` — preview)

- [PySpark reference for materialized lake views (Preview)](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/create-materialized-lake-view-pyspark) — `import fmlv`, the `@fmlv.materialized_lake_view` decorator, `@fmlv.check`, the SQL-vs-PySpark decision flowchart, the notebook organization rules (one decorator per cell, helpers above, hardcoded literals only, don't delete the defining notebook), and the PySpark-only limitations (always full refresh, lineage-schedule-only, no variables in decorator, periods reserved in names).

### Optimal refresh (skip / incremental / full)

- [Optimal refresh for materialized lake views in a lakehouse](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/refresh-materialized-lake-view) — the optimal-refresh decision engine, the supported-SQL-constructs table (which constructs allow incremental vs force full), the CDF (`delta.enableChangeDataFeed=true`) prerequisite for incremental, `REFRESH MATERIALIZED LAKE VIEW ... FULL`, the manage-toggle to disable optimal refresh, and the explicit "PySpark-defined MLVs always use full refresh" / "non-Delta sources always use full refresh" carveouts.
- [Use Delta Lake change data feed (Databricks docs — referenced from MS Learn)](https://learn.microsoft.com/azure/databricks/delta/delta-change-data-feed) — the underlying CDF mechanism the MLV optimal-refresh engine reads.

### Lineage and scheduling

- [Manage Fabric materialized lake views lineage](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/view-lineage) — the lineage view, dependency graph, custom Spark environment, the auto-refresh-every-2-minutes UI behavior, the deleted-environment fallback.
- [Schedule a materialized lake view refresh](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/schedule-lineage-run) — the **Manage schedules** pane and independent per-schedule runs, refresh scope (all vs selected views), **Time-based vs Event-triggered (Preview)** refresh types (Job events / OneLake events, the Private-Link exclusion, the load-bearing auto-created "FMLV Refresh" Notebook + Activator), Advanced settings (per-schedule Spark environment across the same capacity, per-schedule Optimal refresh, the schedule → lakehouse → system priority order), **Extended lineage** for cross-lakehouse and cross-workspace chains (lakehouse tree, unselected-means-all default, upstream-first ordering with parallel branches, single Recent-runs entry, `ReadAll`/`ReadWrite` permissions, faulted nodes blocking the run), the **On demand lineage refresh** execution modes, and the 24-hour run cap plus the skip-if-already-running behavior.
- [Recent runs of materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/run-history) — the **last 25 runs OR last 7 days, whichever comes first** retention rule, the run-state semantics (In progress / Success / Failed / Skipped / Canceled), the "child views auto-marked Skipped if parent fails" behavior.
- [Monitor materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/monitor-materialized-lake-views) — Monitor hub for `RefreshMaterializedLakeViews` job-type runs, sort/filter/search, view-detail and cancel actions, the `MLV_LakehouseName_JobInstanceID` activity-name pattern.

### REST API (job scheduler — `RefreshMaterializedLakeViews`)

- [Manage and refresh materialized lake views in Fabric with APIs](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/materialized-lake-views-public-api) — every endpoint (Create / Get / List / Update / Delete schedule, Run on-demand, List / Get / Cancel job instances) with `{jobType}=RefreshMaterializedLakeViews`, the schedule-limits-per-lakehouse caveat, the Skipped-vs-Canceled status mismatch between Monitoring hub and lineage view.
- [Lakehouse — Materialized Lake Views (REST reference)](https://learn.microsoft.com/rest/api/fabric/lakehouse/materialized-lake-views) — the five MLV execution definition operations (Create / List / Get / Update / Delete on `mlvexecutiondefinitions`), whose id scopes an on-demand refresh or a schedule through `executionData.mlvExecutionDefinitionId`.
- [Job scheduler — Run On Demand Item Job](https://learn.microsoft.com/rest/api/fabric/core/job-scheduler/run-on-demand-item-job?tabs=HTTP) — the underlying generic on-demand endpoint the MLV API binds to.
- [Job scheduler — Create Item Schedule](https://learn.microsoft.com/rest/api/fabric/core/job-scheduler/create-item-schedule?tabs=HTTP) — the underlying generic schedule CRUD.
- [Job scheduler — Get Item Job Instance](https://learn.microsoft.com/rest/api/fabric/core/job-scheduler/get-item-job-instance?tabs=HTTP) — for polling a returned `Location` header to completion.

### Data quality report

- [Data quality report for materialized lake views](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/data-quality-reports) — the auto-generated Power BI report (Overview + MLV Detail pages), the violations-vs-drops semantics (drops ≤ violations), the **DirectQuery 1M-row cap on non-premium**, the workspace/lakehouse-name-with-special-characters generation failure, and the `Read` / `ReadData` SQL-analytics-endpoint permission required for recipients.

### Lakehouse prerequisites

- [Lakehouse schemas (Public preview)](https://learn.microsoft.com/fabric/data-engineering/lakehouse-schemas) — the `enableSchemas` toggle that's required for MLVs and is **immutable per lakehouse** (you can't add schemas to an existing non-schema lakehouse without recreating).
- [Fabric Runtime 1.3](https://learn.microsoft.com/fabric/data-engineering/runtime-1-3) — the runtime version MLV authoring requires. The MLV get-started page still names 1.3 exactly as of 2026-08-29.
- [Fabric Runtime 2.0 (GA Aug 2026)](https://learn.microsoft.com/fabric/data-engineering/runtime-2-0) — Spark 4.1 / Delta Lake 4.2 / Python 3.13 / Java 21 / Scala 2.13 / R 4.5.2 / Azure Linux 3.0. **Not** currently named in the MLV prerequisites, and still opt-in: it was planned to become the default for new workspaces and environment items in late September 2026, but Learn's runtime page still says "By default, all new workspaces currently use Runtime 1.3" (2026-10-06). Also carries the environment-republish breaking change indexed in `fabric-rest-api`'s `references/gotchas.md`.
- [Spark views in lakehouses](https://learn.microsoft.com/fabric/data-engineering/lakehouse-spark-views) — the lightweight (non-persisted) alternative for cases where you don't need MLV materialization.

### Delta Lake (the storage layer MLVs persist into)

- [What is Delta Lake?](https://learn.microsoft.com/azure/databricks/delta/) — the table format MLVs persist as. CDF, partitioning, table properties.
- [Delta Lake table properties reference](https://learn.microsoft.com/azure/databricks/delta/table-properties) — for `TBLPROPERTIES` keys you can set on an MLV (`delta.enableChangeDataFeed`, `delta.minReaderVersion`, etc.).

### Comparison points

- [Materialized views in KQL (Eventhouse)](https://learn.microsoft.com/kusto/management/materialized-views/materialized-view-overview?view=microsoft-fabric) — the analogous KQL feature in Eventhouse; not the same engine, similar concept. Useful when a user is choosing between Lakehouse + MLV and Eventhouse + KQL MV.
- [Schedule refreshes in Databricks SQL (`SCHEDULE` / `TRIGGER ON UPDATE`)](https://learn.microsoft.com/azure/databricks/ldp/dbsql/schedule-refreshes) — the Databricks materialized-view counterpart. Fabric's MLVs do not currently support a SQL-clause-level `SCHEDULE` — schedules are separate objects on the lakehouse, scoped to all views, selected views, or (with Extended lineage) upstream lakehouses.

## See also

- [SKILL.md](../SKILL.md) — PySpark in Fabric notebooks (the broader Spark surface; MLVs are one consumer); covers the no-external-HTTP rule and `abfss://` URI shape relevant to MLV `SELECT` sources
- `fabric-eventhouse` — KQL materialized views (different engine, similar concept)
- [error-handling.md](error-handling.md) — notebook/pipeline error patterns; useful when wrapping MLV refresh in a larger flow
- `fabric-warehouse-monitoring` — Warehouse `queryinsights` + DMVs; workspace-monitoring and Capacity Metrics links in its references bundle
- `fabric-rest-api` — generic LRO / 202 Accepted polling pattern used by the MLV on-demand endpoint
- `pbip-project-structure` — `.Lakehouse/` folder placement when MLV-bearing lakehouses live in a PBIP repo
