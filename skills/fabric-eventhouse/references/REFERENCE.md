# MS Learn link bundle — Fabric Eventhouse / KQL Database

Curated set of Microsoft Learn pages relevant to Fabric Eventhouse and KQL Databases — KQL management commands, ingestion, mapping, materialized views, update policies, OneLake availability, monitoring, and the underlying Kusto query reference.

The 3 highest-leverage entry points (Eventhouse overview, KQL string-operator best practices, OneLake availability) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** The product is documented in two places. Fabric-specific concepts (Eventhouse item, OneLake mirroring, workspace integration, REST API) live under `learn.microsoft.com/fabric/real-time-intelligence/`. The KQL language and management-command reference is shared with Azure Data Explorer and lives under `learn.microsoft.com/kusto/`. Both are linked below.

## Concept and getting started

- [Eventhouse overview](https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse) — what an Eventhouse is, when to use it, KQL Database vs database shortcut, OneLake availability hook. Read first.
- [Create an eventhouse](https://learn.microsoft.com/fabric/real-time-intelligence/create-eventhouse) — portal walkthrough; auto-creates a child KQL database with the same name.
- [Create a KQL database](https://learn.microsoft.com/fabric/real-time-intelligence/create-database) — standard vs follower (shortcut) database.
- [Manage and monitor a database](https://learn.microsoft.com/fabric/real-time-intelligence/manage-monitor-database) — main page sections (ribbon, explorer, main view, details).
- [Real-Time Intelligence tutorial — set up Eventhouse](https://learn.microsoft.com/fabric/real-time-intelligence/tutorial-1-resources) — start of the canonical end-to-end tutorial; useful baseline.

## Programmatic deployment (REST + Fabric API)

- [Deploy an eventhouse using Fabric APIs](https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse-deploy-with-fabric-api) — definition envelope (`DatabaseProperties.json`, `DatabaseSchema.kql` base64-encoded), Fabric Create-KQL-Database API, LRO polling, falling back to Kusto management API for table-level operations the Fabric API doesn't expose.
- [KQL Database item definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/kql-database-definition) — required parts, schema script semantics.
- [Create KQL Database (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/kqldatabase/items/create-kql-database) — endpoint reference.
- [Get Eventhouse (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/eventhouse/items/get-eventhouse) — returns `queryServiceUri` for direct KQL endpoint access.

## KQL management commands (authoring & schema)

- [.create-merge table](https://learn.microsoft.com/kusto/management/create-merge-table-command?view=microsoft-fabric) — idempotent table creation/extension. Preferred form for repeatable deployments.
- [.alter table](https://learn.microsoft.com/kusto/management/alter-table-command?view=microsoft-fabric) — schema and policy modification entry point.
- [.create function / .create-or-alter function](https://learn.microsoft.com/kusto/management/create-function?view=microsoft-fabric) — stored functions: docstring, folder, default param values.
- [.alter table policy update (Update policy)](https://learn.microsoft.com/kusto/management/update-policy?view=microsoft-fabric) — automatic transform on ingestion; `IsTransactional`, query limitations (no cross-eventhouse, no external data, no plugins), the streaming-ingestion-vs-join interaction.
- [Update policy use cases](https://learn.microsoft.com/kusto/management/update-policy-use-cases?view=microsoft-fabric) — common transform patterns (parse, lookup, project).
- [.update table command](https://learn.microsoft.com/kusto/management/update-table-command?view=microsoft-fabric) — explicit row update; covers when to use update vs materialized view vs update policy.

## Materialized views

- [Materialized views overview](https://learn.microsoft.com/kusto/management/materialized-views/materialized-view-overview?view=microsoft-fabric) — concept, materialization process, the `materialized_view()` function for materialized-only reads.
- [.create materialized-view](https://learn.microsoft.com/kusto/management/materialized-views/materialized-view-create?view=microsoft-fabric) — supported aggregations, `backfill=true` semantics, lookback period, the recommendation to push enrichment to update policies.
- [Materialized view use cases](https://learn.microsoft.com/kusto/management/materialized-views/materialized-view-use-cases?view=microsoft-fabric) — vs update policies decision guide.
- [Materialized views limitations and known issues](https://learn.microsoft.com/kusto/management/materialized-views/materialized-views-limitations?view=microsoft-fabric) — source-table requirements (IngestionTime policy enabled, no RestrictedViewAccess), `lookback` + `mv-expand` interaction, `setNewIngestionTime` requirement when moving extents.

## Ingestion

- [.ingest into command](https://learn.microsoft.com/kusto/management/data-ingestion/ingest-into-command?view=microsoft-fabric) — pull ingestion from storage URIs; `async` flag, return columns (ExtentId, ItemLoaded, OperationId).
- [.set / .set-or-append / .set-or-replace](https://learn.microsoft.com/kusto/management/data-ingestion/ingest-from-query?view=microsoft-fabric) — ingest from a KQL query result.
- [.ingest inline](https://learn.microsoft.com/kusto/management/data-ingestion/ingest-inline?view=microsoft-fabric) — small-data / testing pattern.
- [Streaming ingestion overview](https://learn.microsoft.com/kusto/management/streaming-ingestion-policy?view=microsoft-fabric) — must enable `policy streamingingestion` per-table before low-latency endpoints accept data.
- [Data mappings overview](https://learn.microsoft.com/kusto/management/mappings?view=microsoft-fabric) — identity mapping, precreated mappings, table-vs-database scope priority.
- [JSON mapping](https://learn.microsoft.com/kusto/management/json-mapping?view=microsoft-fabric) / [CSV mapping](https://learn.microsoft.com/kusto/management/csv-mapping?view=microsoft-fabric) / [Parquet mapping](https://learn.microsoft.com/kusto/management/parquet-mapping?view=microsoft-fabric) / [AVRO mapping](https://learn.microsoft.com/kusto/management/avro-mapping?view=microsoft-fabric) — per-format mapping reference. Parquet page also includes the source-type → KQL-type conversion matrix.

## OneLake availability and external tables

- [Eventhouse OneLake availability](https://learn.microsoft.com/fabric/real-time-intelligence/event-house-onelake-availability) — turn-on at DB or table level, mirroring policy, `TargetLatencyInMinutes` (5 min – 3 hr), why short latency produces small files, partitioning the delta output.
- [Mirroring policy command reference](https://learn.microsoft.com/kusto/management/mirroring-policy?view=microsoft-fabric) — `.alter-merge table policy mirroring` syntax.
- [.show table mirroring operations](https://learn.microsoft.com/kusto/management/show-table-mirroring-operations-command?view=microsoft-fabric) — monitor data latency to OneLake.
- [OneLake shortcuts](https://learn.microsoft.com/fabric/onelake/onelake-shortcuts) — KQL-database shortcut behavior: shortcuts appear in `Shortcuts` folder, queried via `external_table()`.
- [External tables overview (Kusto)](https://learn.microsoft.com/kusto/query/schema-entities/external-tables?view=microsoft-fabric) — declaring storage-backed external tables (ADLS, OneLake `abfss://...;impersonate`).

## Permissions and security

- [Kusto role-based access control](https://learn.microsoft.com/kusto/access-control/role-based-access-control?view=microsoft-fabric) — viewer / user / ingestor / admin at database and table scope.
- [.add database/table principals](https://learn.microsoft.com/kusto/management/add-database-principals?view=microsoft-fabric) — granting roles via management commands.
- [Row-level security](https://learn.microsoft.com/kusto/management/row-level-security-policy?view=microsoft-fabric) — RLS function pattern, materialized-view interaction.
- [Restricted view access policy](https://learn.microsoft.com/kusto/management/restricted-view-access-policy?view=microsoft-fabric) — table-level visibility lockdown.

## KQL query reference (depth)

- [KQL quick reference](https://learn.microsoft.com/kusto/query/kql-quick-reference?view=microsoft-fabric) — operator/function index. Bookmark.
- [String operators](https://learn.microsoft.com/kusto/query/datatypes-string-operators?view=microsoft-fabric) — what is a "term", why `has` is faster than `contains`, the `_cs` case-sensitive variants.
- [Query best practices](https://learn.microsoft.com/kusto/query/best-practices?view=microsoft-fabric) — the canonical rules: filter by time first, project early, prefer `==` over `=~`, prefer `has` over `contains`, prefer case-sensitive operators.
- [materialize() function](https://learn.microsoft.com/kusto/query/materialize-function?view=microsoft-fabric) — caching reused subexpressions in a single query.
- [external_table() function](https://learn.microsoft.com/kusto/query/external-table-function?view=microsoft-fabric) — querying external/shortcut tables.
- [database() function (cross-database)](https://learn.microsoft.com/kusto/query/database-function?view=microsoft-fabric) — `database("OtherDB").Table` syntax.

## Monitoring (Eventhouse-specific)

- [Eventhouse monitoring](https://learn.microsoft.com/fabric/real-time-intelligence/monitor-eventhouse) — Metrics / Command logs / Data operation logs / Ingestion results / Query logs tables. Built-in dashboard templates.
- [Command logs](https://learn.microsoft.com/fabric/real-time-intelligence/monitor-logs-command) — `.show commands` style audit feed via workspace monitoring.
- [Query logs](https://learn.microsoft.com/fabric/real-time-intelligence/monitor-logs-query) — completed-query log table.
- [Ingestion results logs](https://learn.microsoft.com/fabric/real-time-intelligence/monitor-logs-ingestion-results) — per-batch ingestion success/failure feed.
- [Metrics](https://learn.microsoft.com/fabric/real-time-intelligence/monitor-metrics) — capacity / health metrics for the Eventhouse.

## REST / programmatic query endpoints

- [Kusto query REST API](https://learn.microsoft.com/kusto/api/rest/request?view=microsoft-fabric) — `POST {clusterUri}/v1/rest/query` body shape (`{"db": ..., "csl": ...}`), response Tables/Rows shape. Reference for the `az rest` temp-file pattern in the parent skill.
- [Storage connection strings (Kusto)](https://learn.microsoft.com/kusto/api/connection-strings/storage-connection-strings?view=microsoft-fabric) — `;impersonate`, `;managed_identity=...` URI suffixes for ADLS / OneLake ingestion.
