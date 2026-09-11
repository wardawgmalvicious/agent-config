---
name: fabric-warehouse-monitoring
description: "Use for monitoring Fabric Warehouse queries — OPTION (LABEL = '...') for tracking, the queryinsights schema (exec_requests_history, exec_sessions_history, long_running_queries, frequently_run_queries), 30-day retention, 15-minute appearance lag, the `Invalid object name` gotcha on newly-created warehouses, and diagnosing slow/stale Lakehouse SQLEP reads under the new metadata-sync preview (`sys.dm_db_external_tables_log_status`, `sp_dw_refresh_ext_table`)."
paths:
  - "**/*.Warehouse/**/*.sql"
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Monitoring & diagnostics

## Query Labels

```sql
SELECT ... FROM ...
OPTION (LABEL = 'PROJECT_Module_Description');
```

Labels appear in `queryinsights.exec_requests_history.label`. Use for tracking, filtering, and performance analysis.

## Query Insights (30-day retention)

| View | Purpose |
|---|---|
| `queryinsights.exec_requests_history` | Every completed query: status, duration, CPU, data scanned |
| `queryinsights.exec_sessions_history` | Session history: login info, times |
| `queryinsights.long_running_queries` | Aggregated: median vs last-run time |
| `queryinsights.frequently_run_queries` | Run counts, execution times for recurring patterns |

**Gotcha**: Data appears with up to 15 minutes delay. After creating a new warehouse, views may return "Invalid object name" — wait ~2 minutes.

## Top Expensive Queries

```sql
SELECT TOP 10
    distributed_statement_id, query_hash, label,
    total_elapsed_time_ms, allocated_cpu_time_ms,
    data_scanned_remote_storage_mb, result_cache_hit
FROM queryinsights.exec_requests_history
ORDER BY allocated_cpu_time_ms DESC;
```

Aggregate by `query_hash` over the last 7 days to find recurring expensive patterns.

To find the queries behind a Capacity Metrics billing interval, correlate by time, not by ID: the Metrics app's **Operation Id** no longer maps to `distributed_statement_id` (Learn, confirmed 2026-09-11). Take the interval's **Start** and **End** from the app's Background operations table, then select the requests that overlapped it:

```sql
DECLARE @Start_Time DATETIME2(0) = '2026-08-04 8:00:00'
        ,@End_Time DATETIME2(0) = '2026-08-04 9:00:00'

SELECT [database_name],
       sql_pool_name,
       distributed_statement_id,
       login_name,
       allocated_cpu_time_ms / 1000.0 AS vcore_seconds
FROM queryinsights.exec_requests_history
WHERE start_time < @End_Time
AND end_time > @Start_Time;
```

## DMVs (Live State)

| DMV | Shows | Min Role |
|---|---|---|
| `sys.dm_exec_connections` | Active connections (session_id, client_address) | Admin only |
| `sys.dm_exec_sessions` | Authenticated sessions (login_name, login_time, status) | All roles (own sessions) |
| `sys.dm_exec_requests` | Active requests (command, start_time, total_elapsed_time) | All roles (own requests) |

```sql
-- Find long-running queries
SELECT request_id, session_id, command, start_time, total_elapsed_time, status
FROM sys.dm_exec_requests
WHERE status = 'running'
ORDER BY total_elapsed_time DESC;

-- Identify the user
SELECT login_name FROM sys.dm_exec_sessions WHERE session_id = <id>;

-- Kill a runaway query (Admin only)
KILL '<session_id>';
```

## SQL Endpoint Metadata Sync (new sync — Preview, May 2026)

Diagnose slow/stale Lakehouse SQLEP reads when queries return data older than what has landed. On endpoints created under the **new metadata-sync preview** (opt-in, new endpoints only):

```sql
-- Inspect per-table sync freshness and blocked state
SELECT last_update_time_utc, latest_log_version, latest_checkpoint_version, is_blocked
FROM sys.dm_db_external_tables_log_status;   -- is_blocked: 1 = last update blocked, 0 = succeeded

-- Force a targeted refresh of one table's data (data-only changes)
EXEC sys.sp_dw_refresh_ext_table 'dbo.<table>';
```

Schema changes (add/drop tables or columns, type changes) need the full-item Refresh SQL endpoint metadata REST API instead. Full preview note — enablement, architecture, limitations — lives in the **fabric-spark skill**; the slow-SQLEP gotcha cross-references it in the **fabric-gotchas skill**.

## Result Set Caching (currently disabled)

**Disabled in Fabric Data Warehouse and the SQL analytics endpoint as of 2026-09-11, per Learn** — see the [known issue](https://aka.ms/fabricdwrscki). Don't recommend it as a tuning step while that stands. The feature is disabled, not retired, so the rules below apply again when it returns.

`result_cache_hit` field in `exec_requests_history`: `2` = cache hit, `1` = the query created the cache, `0` = not applicable for cache creation or use. Learn documents only these three values. Non-deterministic functions (`GETDATE()`, `NEWID()`) prevent caching. Cache auto-invalidates when underlying data changes.

## Statistics

Auto-maintained for single-column histograms, average column length, and table cardinality. Manual `CREATE STATISTICS` / `UPDATE STATISTICS` available.

**Gotcha**: After a rolled-back transaction containing a large INSERT, auto-generated statistics can be inaccurate. Run `UPDATE STATISTICS` manually on affected columns to recover.

## Reference

- Microsoft Learn: [Monitor Fabric Data Warehouse (overview)](https://learn.microsoft.com/fabric/data-warehouse/monitoring-overview)
- Microsoft Learn: [Query insights in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/query-insights)
- Microsoft Learn: [Use query labels in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/query-label)
- Comprehensive MS Learn link bundle (per-view T-SQL refs / DMVs / capacity throttling / workspace monitoring): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-warehouse skill — T-SQL authoring rules for the queries you're monitoring
- fabric-gotchas skill — cross-cutting error index
