# MS Learn link bundle — Fabric Data Warehouse

Curated set of Microsoft Learn pages relevant to designing, ingesting, querying, securing, and operating Fabric Data Warehouse. Load on demand when you need authoritative reference for a specific topic (T-SQL surface, performance, security model, source control / CI/CD, operations).

The 3 highest-leverage entry points (concept overview, performance guidelines, security model) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Scope note:** This bundle covers Fabric Warehouse only. For Fabric SQL Database (the full Azure SQL engine inside Fabric, with a different supported surface), see the `fabric-database` skill. Mirroring, Lakehouse SQL endpoint, and KQL DB live in their own sibling skills.

## Concept and overview

- [What is Fabric Data Warehouse?](https://learn.microsoft.com/fabric/data-warehouse/data-warehousing) — concept, ideal use cases, Warehouse vs SQL analytics endpoint of Lakehouse, key feature summary. Read first when orienting on the product.
- [Create a Warehouse in Microsoft Fabric](https://learn.microsoft.com/fabric/data-warehouse/create-warehouse) — provisioning a warehouse inside a workspace.

## Connect

- [Connect to Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/how-to-connect) — connection patterns: SQL editor, SSMS, Azure Data Studio, JDBC, Python notebooks via the `%%tsql` magic command. Pair with the `fabric-auth` skill for token-audience details.

## Tables, data types, schema

- [Tables in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/tables) — table structure, schema rules, naming constraints (no `/` `\`), CREATE TABLE / CTAS overview.
- [Create tables in the warehouse](https://learn.microsoft.com/fabric/data-warehouse/create-table) — step-by-step creation via SQL editor templates and prerequisites.
- [Data types in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/data-types) — supported types and the unsupported-types alternatives table. Authoritative source for the unsupported-types content the SKILL.md summarizes.

## Ingestion

- [Ingest data into the Warehouse (overview)](https://learn.microsoft.com/fabric/data-warehouse/ingest-data) — decision matrix: COPY INTO vs pipelines vs dataflows vs T-SQL ingestion. Start here when picking an ingestion pattern.
- [Ingest data using the COPY statement](https://learn.microsoft.com/fabric/data-warehouse/ingest-data-copy) — `COPY INTO` syntax, Parquet / CSV examples, ADLS Gen2 / Blob sources.
- [Ingest data using Transact-SQL](https://learn.microsoft.com/fabric/data-warehouse/ingest-data-tsql) — CTAS, `INSERT...SELECT`, `SELECT INTO` patterns; cross-warehouse three-part naming.
- [Ingest data using pipelines](https://learn.microsoft.com/fabric/data-warehouse/ingest-data-pipelines) — Copy job and Data pipeline integration. Reminder: only the **Script** activity (not the Stored Procedure activity) supports invoking warehouse stored procedures from pipelines.

## Performance and caching

- [Performance guidelines in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/guidelines-warehouse-performance) — critical reference: ingestion best practices, query patterns, cold-cache effects, string-column sizing, transaction guidance. Cite when reviewing warehouse code.
- [In-memory and disk caching](https://learn.microsoft.com/fabric/data-warehouse/caching) — automatic caching layers, transparent operation, no manual control. Useful for understanding cold-start variance.
- [Statistics in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/statistics) — automatic statistics, why multi-column manual stats aren't supported, when to refresh.
- [Use data clustering (preview)](https://learn.microsoft.com/fabric/data-warehouse/tutorial-data-clustering) — `WITH (CLUSTER BY (col1, col2, ...))` on CTAS for predicate pushdown. Tutorial format with before/after Query Insights comparison.

## Monitoring

- [Monitor Fabric Data Warehouse (overview)](https://learn.microsoft.com/fabric/data-warehouse/monitoring-overview) — entry point for Capacity Metrics app, Query activity, Query Insights, DMVs.
- [Query Insights](https://learn.microsoft.com/fabric/data-warehouse/query-insights) — `queryinsights.exec_requests_history` and friends; 30-day retention. Sample queries for top-CPU, frequent-runs, long-running, cold-start detection. Pair with the `fabric-monitoring` skill.
- [Monitor connections, sessions, requests via DMVs](https://learn.microsoft.com/fabric/data-warehouse/monitor-using-dmv) — DMV approach for live state (vs Query Insights' historical view).
- [Billing and utilization reporting](https://learn.microsoft.com/fabric/data-warehouse/usage-reporting) — Capacity Metrics app columns and how warehouse compute charges are reported.

## Security and permissions

- [Secure your Fabric Data Warehouse (overview)](https://learn.microsoft.com/fabric/data-warehouse/security) — the layered access model: Fabric workspace roles + item permissions + SQL granular permissions. Read first when designing access. Pair with the `fabric-security` skill.
- [Workspace roles in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/workspace-roles) — what Admin / Member / Contributor / Viewer can do in a warehouse specifically.
- [Share your data and manage permissions](https://learn.microsoft.com/fabric/data-warehouse/share-warehouse-manage-permissions) — sharing UI patterns, item-level Read / ReadData / ReadAll.
- [SQL granular permissions](https://learn.microsoft.com/fabric/data-warehouse/sql-granular-permissions) — `GRANT` / `DENY` / `REVOKE`, the auto-create-on-GRANT pattern, querying granted permissions via system views.
- [Row-level security (RLS)](https://learn.microsoft.com/fabric/data-warehouse/row-level-security) — predicate-based row filtering.
- [Column-level security (CLS)](https://learn.microsoft.com/fabric/data-warehouse/column-level-security) — column visibility control.
- [Dynamic data masking (DDM)](https://learn.microsoft.com/fabric/data-warehouse/dynamic-data-masking) — masking definitions and the `UNMASK` permission.
- [How to implement dynamic data masking](https://learn.microsoft.com/fabric/data-warehouse/howto-dynamic-data-masking) — step-by-step implementation.
- [Configure SQL audit logs](https://learn.microsoft.com/fabric/data-warehouse/configure-sql-audit-logs) — user-activity auditing surface.
- [Service principals for warehouses](https://learn.microsoft.com/fabric/data-warehouse/service-principals) — SPN-based programmatic access for REST-API-driven warehouse management.
- [Data encryption (customer-managed keys)](https://learn.microsoft.com/fabric/data-warehouse/encryption) — workspace-level CMK protecting OneLake data + warehouse metadata.

## Backup, restore, time travel

- [Restore in-place](https://learn.microsoft.com/fabric/data-warehouse/restore-in-place) — point-in-time restore from restore points; for accidental corruption, dev-test reset, or rollback after a failed release.
- [Time travel — query data as it existed in the past](https://learn.microsoft.com/fabric/data-warehouse/time-travel) — `OPTION (FOR TIMESTAMP AS OF ...)` syntax and rules (UTC, single per SELECT, current schema returned).
- [Clone table](https://learn.microsoft.com/fabric/data-warehouse/clone-table) — zero-copy table cloning; permission and inheritance behavior (RLS / DDM / constraints inherited).

## Source control, CI/CD, REST API

- [Development and deployment workflows](https://learn.microsoft.com/fabric/data-warehouse/development-deployment) — overview of Fabric web (with / without Git), IDE / local dev (DacFx, SSMS), deployment pipelines, external CI/CD.
- [Source control with Warehouse (preview)](https://learn.microsoft.com/fabric/data-warehouse/source-control) — Git integration setup at workspace level, deployment-pipeline integration.
- [What is Microsoft Fabric Git integration?](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration) — broader Fabric Git integration concepts that warehouse Git follows.
- [Automate Git integration via APIs](https://learn.microsoft.com/fabric/cicd/git-integration/git-automation) — REST APIs for commit / sync / branch operations.
- [Warehouse REST API reference](https://learn.microsoft.com/rest/api/fabric/warehouse/items) — Items API for warehouse CRUD, list, get-definition. Pair with the `fabric-rest-api` skill for general patterns (LRO, pagination, runtime ID vs `.platform` logicalId).
