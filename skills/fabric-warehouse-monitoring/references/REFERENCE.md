# MS Learn link bundle — Fabric monitoring & diagnostics

Curated set of Microsoft Learn pages relevant to monitoring Fabric Warehouse / SQL analytics endpoint queries and the broader workspace monitoring surface (Eventhouse-backed logs for pipelines, semantic models, GraphQL, mirrored DBs).

The 3 highest-leverage entry points (Monitor Fabric DW overview, Query Insights, Query Activity) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Scope note:** This skill focuses on Warehouse / SQL endpoint monitoring (`queryinsights` schema + DMVs) plus capacity-level visibility. Item-level workspace monitoring (Eventhouse, semantic models) is included for cross-reference but is covered more deeply in `fabric-eventhouse` and the workspace-monitoring docs.

## Warehouse / SQL endpoint monitoring (primary)

- [Monitor Fabric Data Warehouse (overview)](https://learn.microsoft.com/fabric/data-warehouse/monitoring-overview) — entry point: Capacity Metrics app, Query activity, Query insights, DMVs. Read first.
- [Query insights in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/query-insights) — 30-day retention, query-shape aggregation via `query_hash`, why system queries are excluded, full view list (`exec_requests_history`, `exec_sessions_history`, `long_running_queries`, `frequently_run_queries`, `sql_pool_insights`).
- [Monitor your running and completed T-SQL queries using Query activity](https://learn.microsoft.com/fabric/data-warehouse/query-activity) — UI surface over the queryinsights views; per-column reference for Long-running and Frequently-run insights. Also documents the 15-minute appearance lag and the `Invalid object name queryinsights.exec_requests_history` workaround.
- [Use query labels in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/query-label) — `OPTION (LABEL = '...')` syntax + canonical example queries that filter `queryinsights.*` by `label`.
- [Monitor connections, sessions, and requests using DMVs](https://learn.microsoft.com/fabric/data-warehouse/monitor-using-dmv) — `sys.dm_exec_connections` / `_sessions` / `_requests` access model, `KILL '<session>'`, role-based visibility (Admin sees all; non-admins see own).

## queryinsights views — per-view T-SQL reference

- [queryinsights.exec_requests_history (Transact-SQL)](https://learn.microsoft.com/sql/relational-databases/system-views/queryinsights-exec-requests-history-transact-sql?view=fabric) — every column: `distributed_statement_id`, `query_hash`, `label`, `command`, timing, CPU, data scanned (memory/disk/remote), `result_cache_hit` (negative codes for skip reasons).
- [queryinsights.exec_sessions_history (Transact-SQL)](https://learn.microsoft.com/sql/relational-databases/system-views/queryinsights-exec-sessions-history-transact-sql?view=fabric) — completed-session log, login info.
- [queryinsights.long_running_queries (Transact-SQL)](https://learn.microsoft.com/sql/relational-databases/system-views/queryinsights-long-running-queries-transact-sql?view=fabric) — aggregate by `query_hash`, median vs last-run elapsed time.
- [queryinsights.frequently_run_queries (Transact-SQL)](https://learn.microsoft.com/sql/relational-databases/system-views/queryinsights-frequently-run-queries-transact-sql?view=fabric) — recurring patterns by run count.
- [queryinsights.sql_pool_insights (Transact-SQL)](https://learn.microsoft.com/sql/relational-databases/system-views/queryinsights-sql-pool-insights-transact-sql?view=fabric) — per-pool (SELECT vs NON SELECT) resource %, capacity, `is_pool_under_pressure` event log.

## Performance guidance

- [Performance guidelines in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/guidelines-warehouse-performance) — pairs the query-metadata views with tuning recommendations. Useful when interpreting `data_scanned_remote_storage_mb` or `allocated_cpu_time_ms` outliers.
- [Statistics in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/statistics) — auto-stats limitations and when manual `UPDATE STATISTICS` recovers from the rolled-back-large-INSERT skew the SKILL.md gotcha mentions.
- [Result set caching in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/result-set-caching) — what makes queries cache-eligible, why `GETDATE()` / `NEWID()` block caching, the negative `result_cache_hit` codes.

## Capacity-level monitoring (throttling, overage)

- [Microsoft Fabric Capacity Metrics app (overview)](https://learn.microsoft.com/fabric/enterprise/metrics-app) — install + page tour: Health, Compute, Storage, Timepoint. Capacity-admin tool, complements the per-query `queryinsights` views.
- [The Fabric throttling policy](https://learn.microsoft.com/fabric/enterprise/throttling) — overage/carryforward/burndown model, the four policies (overage protection / interactive delay / interactive rejection / background rejection), `CapacityLimitExceeded` error.
- [Smoothing and throttling in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/compute-capacity-smoothing-throttling) — Warehouse-specific throttling: SQL error code `24801` from SSMS / VS Code MSSQL when capacity rejects.
- [How to: Observe Fabric Data Warehouse utilization trends](https://learn.microsoft.com/fabric/data-warehouse/how-to-observe-utilization) — drill from Metrics app `Operation Id` → `dist_statement_id` in `sys.dm_exec_requests` and `distributed_statement_id` in `queryinsights.exec_requests_history` for end-to-end traceability.
- [Troubleshooting: Diagnose and resolve "capacity limit exceeded" errors](https://learn.microsoft.com/fabric/enterprise/capacity-planning-troubleshoot-errors) — staged decision tree for capacity admins.
- [Troubleshooting: Determine source of report slowness](https://learn.microsoft.com/fabric/enterprise/capacity-planning-troubleshoot-throttling) — companion guide for report-slowness root cause.

## Workspace monitoring (cross-item, Eventhouse-backed)

- [What is workspace monitoring (preview)?](https://learn.microsoft.com/fabric/fundamentals/workspace-monitoring-overview) — read-only Eventhouse / KQL database per workspace. Source of truth for cross-item logs.
- [Enable workspace monitoring in Microsoft Fabric](https://learn.microsoft.com/fabric/data-factory/workspace-monitoring) — toggle in Workspace Settings → Monitoring; auto-creates the monitoring Eventhouse.
- [Monitor Fabric items with item job event logs](https://learn.microsoft.com/fabric/fundamentals/item-job-event-logs) — `ItemJobEventLogs` schema; supported item/job-type matrix (Notebook, Pipeline, Lakehouse, Warehouse SqlAnalyticsEndpoint, etc.).
- [Semantic model operations](https://learn.microsoft.com/fabric/enterprise/powerbi/semantic-model-operations) — column reference for the Analysis Services event log surfaced via workspace monitoring (`ApplicationContext`, `XmlaSessionId`, `ReplicaId`, `ExecutionMetrics`).
- [Eventhouse monitoring](https://learn.microsoft.com/fabric/real-time-intelligence/monitor-eventhouse) — Metrics / Command logs / Data operation logs / Ingestion results / Query logs tables. Detail also covered in `fabric-eventhouse`.
- [Visualize your workspace monitoring in a Real-Time dashboard or Power BI report](https://learn.microsoft.com/fabric/fundamentals/sample-gallery-workspace-monitoring) — built-in templates for Eventhouse + Semantic Model dashboards.
