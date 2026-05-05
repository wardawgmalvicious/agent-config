---
name: fabric-eventstream
description: "Use for Microsoft Fabric Eventstream — the streaming-ingestion item routing CDC / Event Hubs / Kafka / IoT / HTTP / MQTT events into Lakehouse, Eventhouse, Activator, or derived streams. Covers source connectors (Azure SQL / SQL MI / SQL Server VM / PostgreSQL / MySQL / MongoDB / Cosmos DB CDC, Mirrored Database Delta CDF April 2026 preview, Event Hubs / IoT Hub / Kafka / MSK / Confluent / Kinesis / Pub-Sub / Service Bus / MQTT / HTTP / Solace), DeltaFlow CDC → analytics-ready transformation (auto-table-create + schema evolution from Debezium), Activator destination + in-Eventstream `Set Alert` flow (on each event / when / grouped by), the three workspace-monitoring KQL tables (`EventStreamNodeStatus` ~6h, `EventStreamMetrics` 1m, `EventStreamErrorMetrics` 1m) + republish-on-enable requirement, mTLS Key Vault on Kafka-family connectors, edit/publish workflow, VNet injection, gotchas (republish required, 6h status lag, filter by ArtifactId not name, CorrelationId-vs-NodeId, no log messages in preview)."
paths:
  - "**/*.Eventstream/**"
---

# Fabric Eventstream

Streaming-data ingestion item that pulls events from a wide source surface (CDC / Event Hubs / Kafka / IoT / HTTP / MQTT) and routes them into Fabric destinations (Lakehouse, Eventhouse, Activator, derived stream, custom endpoint). Authoring is graph-based: source nodes → optional transformations → destination nodes, edited then **published** to go live.

## When to use vs not

Use Eventstream when the data is **arriving as events** and needs routing or transformation before it lands. Skip it when the data is bulk / batch (use a Data Pipeline Copy activity), already in the lake (use Spark / SQL directly), or when the only consumer is a Mirrored Database in append-only mode (mirroring lands data straight in OneLake without an Eventstream).

For real-time analytics on the resulting events, pair an Eventstream with `fabric-eventhouse` (KQL Database). For real-time **rules**, pair with an Activator destination (covered below).

## Authoring model

- **Edit mode** vs **Live mode**: changes only take effect after **Publish**. New nodes added in Edit mode produce no traffic until publish.
- **Sources** = where events come from. **Transformations** = inline filter / aggregate / GroupBy / Manage Fields / SQL. **Destinations** = where events go. Each destination can have its own format (Delta / JSON / Avro) where applicable.
- **Permissions**: workspace **Contributor** or higher to author; **Viewer** can read **Data insights** monitoring on a published stream.
- **Virtual-network injection** (private-network sources): use Eventstream connector VNet injection for sources behind a firewall — see Microsoft Learn.

## Source connectors

| Source | Notes |
|---|---|
| **Azure SQL DB CDC** | Requires `sys.sp_cdc_enable_db`; do NOT also enable Mirroring on the same DB |
| **Azure SQL Managed Instance CDC** | Same shape as Azure SQL DB CDC |
| **SQL Server on VM CDC** | Public-net or VNet-injected |
| **PostgreSQL CDC** | Azure DB for PostgreSQL, Amazon RDS / Aurora PostgreSQL, GCP Cloud SQL — logical replication required |
| **MySQL DB CDC** | Azure DB for MySQL |
| **MongoDB CDC (preview)** | Specify collections to monitor; initial snapshot + tail |
| **Azure Cosmos DB CDC** | Container-level change feed |
| **Mirrored Database Delta CDF (preview, April 2026)** | New: stream row-level inserts/updates/deletes from a Mirrored Database's Delta Change Data Feed into Eventstream. Toggle via Mirrored DB config dashboard → **Delta table management** → **Enable delta change data feed**, or via `enableDeltaChangeDataFeed` in the [Mirrored DB REST API](https://learn.microsoft.com/fabric/mirroring/mirrored-database-rest-api#enable-delta-change-data-feed-for-a-mirrored-database). Connector reference: [extended capabilities](https://learn.microsoft.com/fabric/mirroring/extended-capabilities). |
| **Azure Event Hubs / IoT Hub** | Native sources — no CDC layer |
| **Apache Kafka / Amazon MSK / Confluent Cloud Kafka** | Kafka-protocol sources; mTLS support (preview) below |
| **Amazon Kinesis Data Streams** | Single-shard or multi-shard |
| **Azure Service Bus** | Queue or topic subscription |
| **Google Cloud Pub/Sub** | |
| **Solace PubSub+** | |
| **MQTT (preview)** | |
| **HTTP (preview)** | Stream from external platforms via standard HTTP requests; predefined public feeds available |
| **Real-time weather** | Fabric-hosted demo source |
| **Azure Data Explorer** | Pull from an existing ADX table |

## DeltaFlow — analytics-ready CDC events (preview)

Available on **Azure SQL CDC**, **Azure SQL MI CDC**, **SQL Server on VM CDC**, and **PostgreSQL CDC**. When the schema-handling step is set to **Analytics-ready events & auto-updated schema**, DeltaFlow transforms raw Debezium CDC events into a tabular shape mirroring the source table, enriched with:

- `Op` / change-type column: `insert` / `update` / `delete`
- Event-timestamp column

Extras you get for free:

- **Automatic destination table management** — when routing to a supported destination (e.g. an Eventhouse), tables are auto-created matching the source schema.
- **Schema evolution** — new source columns and new tables propagate to registered schemas and destination tables without manual intervention.

Without DeltaFlow you receive raw Debezium envelopes and have to flatten them yourself.

## Destinations

| Destination | Use when |
|---|---|
| **Lakehouse** | Land events as Delta files for batch analytics |
| **Eventhouse / KQL Database** | Real-time KQL queries; pair with `fabric-eventhouse` |
| **Activator** | Rule-based alerts and automation (see below) |
| **Derived stream** | Chain a downstream Eventstream — useful for fan-out and reusable transforms |
| **Custom endpoint** | Push to an external Event Hubs / Kafka / AMQP-compatible system |

## Activator destination — set alert directly in Eventstream (preview)

Configure rules in-place without leaving Eventstream. Add an Activator destination, then select the **alert icon** on it to open the **Rules** pane:

- **View** all rules linked to this Eventstream's Activator item
- **Stop / start** a rule with the toggle
- **Edit / delete** via the `…` menu
- **Add rule** at the bottom of the pane
- **Open in Activator** to manage activation history and test notifications

Rule condition shapes:

| `Check` value | When the action fires |
|---|---|
| **on each event** | Every event flowing through the stream |
| **On each event when** | Events matching a single-field condition (e.g. `No_Empty_Docs == 0`) |
| **On each event grouped by** | Same condition, evaluated per group on a chosen field (e.g. `Neighborhood`) |

Actions: Teams message, email, webhook, Power Automate, custom action.

## Workspace monitoring (preview) — KQL tables

Enable workspace monitoring (Workspace settings → **Monitoring** → **Log workspace activity**) and Fabric auto-creates a monitoring Eventhouse with three Eventstream-specific tables. Republish any Eventstream that existed *before* monitoring was enabled — pre-existing streams emit nothing until they're republished.

| Table | Cadence | What it tells you |
|---|---|---|
| `EventStreamNodeStatus` | ~6 hours | Each node's running / paused / failed state |
| `EventStreamMetrics` | 1 minute | Incoming / outgoing message counts, bytes, watermark delay, backlog |
| `EventStreamErrorMetrics` | 1 minute | Error counts by type (runtime, deserialization, conversion) |

All three tables share base dimensions: `Timestamp`, `ArtifactId`, `ArtifactName`, `WorkspaceId`, `WorkspaceName`, `CustomerTenantId`, `Level`, `OperationId`, `PremiumCapacityId`, `PlatformMonitoringCategory`, `PlatformMonitoringTableName`, `LogAnalyticsResourceId`. **Filter by `ArtifactId` / `WorkspaceId`** — name columns can lag after rename / move.

```kql
// Most-recent status per node in one Eventstream
EventStreamNodeStatus
| where ArtifactId == "<eventstream-artifact-id>"
| summarize arg_max(Timestamp, *) by NodeId
| project Timestamp, NodeName, NodeDirection, NodeType, NodeStatus
| order by NodeDirection asc

// Incoming vs outgoing in 5-minute windows
EventStreamMetrics
| where ArtifactId == "<eventstream-artifact-id>"
| where MetricsName in ("Incoming Messages", "Outgoing Messages")
| summarize TotalMessages = sum(Value)
    by TimeWindow = bin(Timestamp, 5m), MetricsName
| order by TimeWindow asc

// Recent errors grouped by type
EventStreamErrorMetrics
| where ArtifactId == "<eventstream-artifact-id>"
| where Timestamp > ago(24h) and Value > 0
| summarize TotalErrors = sum(Value)
    by TimeWindow = bin(Timestamp, 5m), MetricsName, NodeDirection
| order by TimeWindow desc
```

For ad-hoc per-node visualizations during authoring, the **Data insights** tab on the lower pane of the Eventstream editor surfaces metrics directly — works without workspace monitoring enabled but is per-node and not historical.

## Custom CA / mTLS for Kafka connectors (preview)

For Kafka, Amazon MSK, and Confluent Cloud Kafka sources, you can specify a **custom CA certificate** and a **client certificate** sourced from **Azure Key Vault** to enforce TLS / mTLS. Configured in the source connection step. Use when the broker is behind a private CA or requires client-cert auth.

## Gotchas

| Issue | Cause | Fix |
|---|---|---|
| Existing Eventstream emits no monitoring data | Stream was published before workspace monitoring was enabled | Open in editor and **Republish** — required once per pre-existing stream |
| Monitoring tables don't appear after enabling | Database refresh delay | Workspace settings → **Monitoring** → toggle off then on |
| `ArtifactName` / `WorkspaceName` show stale values | Name columns cached from emission time | Filter / join by `ArtifactId` / `WorkspaceId` only |
| `EventStreamNodeStatus` shows old status after a node failed | Status is emitted ~every 6 hours | For real-time status, use the Eventstream editor's live view |
| `CorrelationId` maps to multiple nodes | Advanced processing (e.g. SQL operator with multiple destinations) | Disambiguate using `NodeDirection` + `NodeType` together with `CorrelationId` |
| No detailed log messages in monitoring | Preview limitation — only metrics + error counts | Use the editor's runtime logs for the message text; full diagnostic logs are planned |
| Mirrored DB CDC source rejected | Can't enable Mirroring AND Eventstream CDC on same DB | Pick one — the docs explicitly call this out |
| New Activator rule doesn't fire | Eventstream wasn't republished after adding the destination | Republish the Eventstream after wiring the destination |
| Connector behind firewall fails | Source not publicly reachable | Use [Eventstream connector VNet injection](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/streaming-connector-private-network-support-guide) |
| DeltaFlow not available on a CDC source | Currently scoped to Azure SQL / SQL MI / SQL Server VM / PostgreSQL CDC | Use raw mode for other CDC sources and flatten Debezium yourself |

## Reference

- Microsoft Learn: [Add and manage an event source](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-manage-eventstream-sources)
- Microsoft Learn: [Set alert on an Eventstream with Activator destination](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/set-alerts-event-stream)
- Microsoft Learn: [Eventstream workspace monitoring overview](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/fabric-workspace-monitoring)
- Microsoft Learn: [Eventstream monitoring tables](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/fabric-workspace-monitoring-tables)
- Microsoft Learn: [Query Eventstream monitoring data](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/query-fabric-workspace-monitoring-data)
- Microsoft Learn: [Workspace monitoring known limitations](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/fabric-workspace-monitoring-known-limitations)
- Microsoft Learn: [Mirroring extended capabilities — Delta CDF](https://learn.microsoft.com/fabric/mirroring/extended-capabilities)
- Microsoft Learn: [Monitor the status and performance of an Eventstream](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/monitor)

## See also

- `fabric-eventhouse` — the natural KQL-Database pair for analytics on streamed events
- `fabric-rest-api` — Eventstream item REST endpoints, LRO polling, jobType values
- `fabric-auth` — token audience for Fabric REST against Eventstream items
- `fabric-monitoring` — Workspace monitoring, broader L1/L2 monitoring picture beyond Eventstreams
