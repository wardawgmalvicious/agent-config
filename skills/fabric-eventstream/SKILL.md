---
name: fabric-eventstream
description: "Use for Microsoft Fabric Eventstream — the streaming-ingestion item routing CDC / Event Hubs / Kafka / IoT / HTTP / MQTT events into Lakehouse, Eventhouse, Activator, or derived streams, and producing events to a schema-associated custom endpoint. Covers source connectors (Azure SQL / SQL MI / PostgreSQL / MySQL / MongoDB / Cosmos DB CDC, Mirrored DB Delta CDF preview, Event Hubs / IoT Hub / Kafka / MSK / Confluent / Kinesis / Service Bus / MQTT / HTTP / Solace), DeltaFlow analytics-ready CDC, Activator destination + `Set Alert` flow, workspace-monitoring KQL tables (`EventStreamNodeStatus`/`EventStreamMetrics`/`EventStreamErrorMetrics`), mTLS Key Vault on Kafka, custom-endpoint CloudEvents producer format (binary mode, `dataschema` version routing), custom-endpoint connection anatomy (eseh* namespace, EntityPath, SAS policy), schema-registry URL anatomy, and gotchas (republish required, ~6h status lag, filter by ArtifactId not name, CloudEventPropertyMissingException)."
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
| **Apache Kafka / Amazon MSK / Confluent Cloud Kafka** | Kafka-protocol sources — base connector **GA (June 2026)**; SASL_SSL / SASL_PLAINTEXT / Microsoft Entra auth. Custom-CA / mTLS is still preview — see below |
| **Amazon Kinesis Data Streams** | Single-shard or multi-shard |
| **Azure Service Bus** | Queue or topic subscription — **GA (June 2026)** |
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

## Producing to a schema-associated custom endpoint (CloudEvents)

This is the **producer** side — how an *external* app must format events it pushes to a custom-endpoint source. The Eventstream authoring side (adding the source, wiring destinations) is above; this section is what the sending code has to get right. Applies only when the custom endpoint has an **associated schema** (a schema group / EventDefinition set). The portal's authoritative reference is the endpoint's **Show sample code → Event Hub tab**, which emits `CloudNative.CloudEvents` SDK code.

Verified end-to-end (2026-07-07) by pushing records and reading them back via Kusto; this wire format is **not** documented on Microsoft Learn (the extended-features docs describe the UI, not the format).

### Binary content mode is required — not structured

The endpoint's Azure Stream Analytics EventHub input adapter reads CloudEvents attributes from the Event Hub message's **application properties** (CloudEvents AMQP **binary** content mode), *not* from the JSON body. Structured mode — the whole CloudEvent in the body with `ContentType=application/cloudevents+json` — is **silently ignored**: the adapter still hunts for a `type` property, doesn't find it, and drops the event with:

```
Microsoft.Streaming.AzureStreamAnalytics.Adapters.Input.EventHub.Exceptions.CloudEventPropertyMissingException: CloudEvent property type is missing.
```

### Correct per-event shape (`Azure.Messaging.EventHubs.EventData`)

- **Body** = the data payload JSON *only* (just the record fields — not a wrapped CloudEvent).
- **ContentType** = `application/json`.
- **Application properties**, each prefixed `cloudEvents:` (the CloudEvents AMQP binding convention):

| Property | Value | Notes |
|---|---|---|
| `cloudEvents:specversion` | `1.0` | |
| `cloudEvents:type` | schema name, e.g. `Orders` | **Selects the schema** — must exactly match a schema id in the associated set (**case-sensitive**) |
| `cloudEvents:source` | any non-empty URI | Value unconstrained by the schema envelope |
| `cloudEvents:id` | fresh GUID per event | CloudEvents requires `source`+`id` unique |
| `cloudEvents:dataschema` | `https://<host>.<region>.messagingcatalog.azure.net/schemagroups/<schema-set itemId>/schemas/<type>/versions/<vN>` | **Required to route to a table** — the `/versions/vN` segment supplies `{CloudEventSchemaVersion}` |

The portal sample copies the attributes generically:

```csharp
foreach (var attr in cloudEvent.GetPopulatedAttributes())
    eventData.Properties[$"cloudEvents:{attr.Key}"] = attr.Value?.ToString();
```

### Where the schema-group base URI comes from

Anatomy of the base: `https://<host>.<region>.messagingcatalog.azure.net/schemagroups/<groupId>` — the producer appends `/schemas/{type}/versions/{vN}` itself.

- **`<groupId>` = the Event Schema Set's runtime item id** (verified 2026-08-06 across three schema sets: the group GUID in each working `dataschema` equals the schema set's item id). The group half IS therefore derivable — store an ItemReference to the schema set (e.g. in a Variable Library) and use its `itemId`.
- **`<host>` (`rthprod…` label) is service-generated and per schema set** — three schema sets in one tenant + region produced three different hosts (verified 2026-08-06). It is NOT tenant- or region-stable: never share it across environments; capture it per schema set. `rth` = Real-Time hub, `prod` = service ring; the rest is an opaque scale-unit/instance label.
- The host is the **Fabric-auto-provisioned Azure Schema Registry** ("messaging catalog") endpoint. It's **not surfaced in the Fabric portal UI** except inside the custom endpoint's **Show sample code → Event Hub tab** — copy it from there (verified 2026-07-08).
- **Not present in the git-synced Eventstream definition** either: the `.Eventstream` folder (`eventstream.json`, `eventstreamProperties.json`, `.platform`) carries `schemaMode` and the `{CloudEventType}_{CloudEventSchemaVersion}` table template but **no `messagingcatalog` host** (verified 2026-07-08). The CustomEndpoint source's `properties` is `{}`.

### Two independent gates

1. **Envelope gate** — the adapter finds `type` in the application properties. Fails with `CloudEventPropertyMissingException` if attributes are in the body or not `cloudEvents:`-prefixed.
2. **Schema-validation gate** — the body fields must match the Avro schema types. All-string schemas pass easily; non-string fields (Avro `bytes` / `boolean`) reject mismatched JSON values. A failure here shows a generic *"dropped per schema registry error policy"* diagnostic (not the envelope exception).

### Destination table naming (Eventhouse)

A schema-associated eventstream → Eventhouse (processed ingestion) **auto-creates one table per schema**, named `{CloudEventType}_{CloudEventSchemaVersion}` — e.g. `Orders_v1`, `Products_v2`. The version comes from the `dataschema` `/versions/vN` segment.

### Version-bump gotcha

**Editing a schema in the set mints a new version** (it does not edit in place). The `dataschema` URI must point at the **current** version, and versions can differ across schemas in the same set (observed: `Orders` / `Customers` at `v1`, `Products` at `v2` after a `bytes`→`string` edit). Point at the wrong version → the event validates against the old version's types → dropped. (Open question: whether Fabric accepts a `latest` form in `dataschema` to avoid pinning — untested.)

Reference C# implementation: `edgebridge.core/Helpers/AzureEventHubPusher.cs` (`SendBatch` sets the `cloudEvents:*` props; `ExportToAzureEventHub` is the SDK path) and `edgebridge.core/Models/Job/JobOutput.cs` (`BuildDataSchema`).

### Custom endpoint connection anatomy (Event Hub mode)

Everything in a custom endpoint's connection string except the key follows service-generated naming conventions (verified 2026-08-06 against three real endpoints):

```
Endpoint=sb://<namespace>.servicebus.windows.net/;SharedAccessKeyName=key_<guid>;SharedAccessKey=<secret>;EntityPath=<namespace>_eh
```

- **Namespace**: `eseh<random>` (e.g. `esehexampleabcdefgh123`) — the portal labels it "Event hub name".
- **EntityPath** (the hub — `eventhub_name` in SDKs): always **`<namespace>_eh`**. Derive it; don't store it separately.
- **SAS policy name**: `key_<guid>` — not secret. Only `SharedAccessKey` is secret material.

This enables a **parts-built connection string**: namespace + key name in per-environment config (Variable Library), only the key in Key Vault, assembled at run time — see `fabric-variable-library` (blank-parameter resolution pattern). Caveat: these are observed service conventions, not documented contracts; if the `_eh` suffix ever changes, the failure mode is an Event Hubs entity-not-found at send time.

Schema support itself is a **creation-time flag**: it cannot be enabled on an existing eventstream, and schema-enabled eventstreams don't survive deployment pipelines with their registries intact — plan workspaces accordingly (e.g. one shared multi-environment workspace for the schema-enabled ingestion edge, one endpoint + schema set per environment).

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
| `CloudEventPropertyMissingException: ...type is missing` when pushing to a schema-associated custom endpoint | Attributes sent in the body / structured mode | Use CloudEvents **binary** mode: `cloudEvents:`-prefixed application properties (esp. `cloudEvents:type`), body = payload JSON only. See *Producing to a schema-associated custom endpoint* above |
| Event associates in **Data preview** but no table is written | Missing / wrong `cloudEvents:dataschema` | Set `dataschema` to the current schema version URI (`/versions/vN`) — it's what routes to a table |
| Event dropped after editing a schema | The schema edit bumped the version | Update `dataschema` `/versions/vN` to the new current version; versions can differ per schema in the same set |
| Events rejected / missing after copying producer config to another environment | Schema-registry host or group id reused across environments | Host and group are **per schema set** — capture `<host>`, `<region>`, and the schema set's itemId per environment |

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
- `fabric-warehouse-monitoring` — Warehouse-side query monitoring; workspace-monitoring links in its references bundle
