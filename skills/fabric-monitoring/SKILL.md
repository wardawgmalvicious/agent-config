---
name: fabric-monitoring
description: "Use for monitoring Fabric Warehouse queries — OPTION (LABEL = '...') for tracking, the queryinsights schema (exec_requests_history, exec_sessions_history, long_running_queries, frequently_run_queries), 30-day retention, 15-minute appearance lag, and the `Invalid object name` gotcha on newly-created warehouses."
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

## Result Set Caching (Preview)

`result_cache_hit` field in `exec_requests_history`: `1` = cache hit, `0` = miss, **negative values** = reason caching was skipped. Non-deterministic functions (`GETDATE()`, `NEWID()`) prevent caching. Cache auto-invalidates when underlying data changes.

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
