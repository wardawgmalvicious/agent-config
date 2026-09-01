---
name: fabric-eventstream
description: "Use for Microsoft Fabric Eventstream — the streaming-ingestion item routing CDC / Event Hubs / Kafka / IoT / HTTP / MQTT events into Lakehouse, Eventhouse, Activator, or derived streams, and producing events to a schema-associated custom endpoint. Covers source connectors (Azure SQL / SQL MI / PostgreSQL / MySQL / MongoDB / Cosmos DB CDC, Mirrored DB Delta CDF preview, Event Hubs / IoT Hub / Kafka / MSK / Confluent / Kinesis / Service Bus / MQTT / HTTP / Solace), DeltaFlow analytics-ready CDC, Activator destination + `Set Alert` flow, workspace-monitoring KQL tables (`EventStreamNodeStatus`/`EventStreamMetrics`/`EventStreamErrorMetrics`), mTLS Key Vault on Kafka, Event Hubs workspace-identity auth, custom-endpoint CloudEvents producer format (binary mode, `dataschema` version routing), custom-endpoint connection anatomy (eseh* namespace, EntityPath, SAS policy), schema-registry URL anatomy, and gotchas (republish required, ~6h status lag, filter by ArtifactId not name, CloudEventPropertyMissingException)."
paths:
  - "**/*.Eventstream/**"
model: inherit
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
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

## Sources

Grouped by what you have to get right, not by vendor. Full connector table with
per-source notes: [references/source-connectors.md](references/source-connectors.md).

| Family | Connectors | The thing that bites |
|---|---|---|
| **Database CDC** | Azure SQL, SQL MI, SQL Server on VM, PostgreSQL, MySQL, MongoDB (preview), Cosmos DB | Azure SQL needs `sys.sp_cdc_enable_db`; you cannot enable Mirroring **and** Eventstream CDC on the same database |
| **Mirrored DB Delta CDF** | Mirrored Database (preview, April 2026) | Row-level CDC off a Mirrored DB's Delta Change Data Feed — opt in per database |
| **Native Azure** | Event Hubs, IoT Hub | Auth is **Shared Access Key**; workspace-identity auth is preview (Aug 2026) and the UI leads the docs |
| **Kafka protocol** | Apache Kafka, Amazon MSK, Confluent Cloud | GA June 2026. Custom CA / mTLS GA July 2026 — Kafka-family only |
| **Other cloud / broker** | Kinesis, Service Bus, Google Pub/Sub, Solace PubSub+ | Service Bus GA June 2026 |
| **Protocol / pull** | MQTT (preview), HTTP (preview), Azure Data Explorer, Real-time weather | HTTP ships predefined public feeds for testing |

**DeltaFlow** (preview) is the schema-handling mode that turns raw Debezium CDC
into a tabular shape mirroring the source table, plus an `Op` column, automatic
destination-table creation, and schema evolution. Available on **Azure SQL / SQL
MI / SQL Server on VM / PostgreSQL CDC** only; every other CDC source hands you
raw Debezium envelopes to flatten yourself.

Sources behind a firewall need [Eventstream connector VNet
injection](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/streaming-connector-private-network-support-guide).

## Destinations

| Destination | Use when |
|---|---|
| **Lakehouse** | Land events as Delta files for batch analytics |
| **Eventhouse / KQL Database** | Real-time KQL queries; pair with `fabric-eventhouse` |
| **Activator** | Rule-based alerts and automation (see below) |
| **Derived stream** | Chain a downstream Eventstream — useful for fan-out and reusable transforms |
| **Custom endpoint** | Push to an external Event Hubs / Kafka / AMQP-compatible system |

## Activator destination (preview)

Add an Activator destination, then use the **alert icon** on it to view, add,
edit, and stop/start rules without leaving Eventstream. Conditions fire **on
each event**, **on each event when** (single-field condition), or **on each
event grouped by** a field. Actions: Teams, email, webhook, Power Automate,
custom. **Republish after wiring the destination or no rule fires.**

Pane walkthrough and condition detail:
[references/activator-destination.md](references/activator-destination.md).

## Workspace monitoring (preview)

Workspace settings → **Monitoring** → **Log workspace activity** auto-creates a
monitoring Eventhouse with three Eventstream tables. **Republish any Eventstream
that existed before monitoring was enabled** — pre-existing streams emit nothing
until republished.

| Table | Cadence | What it tells you |
|---|---|---|
| `EventStreamNodeStatus` | ~6 hours | Each node's running / paused / failed state |
| `EventStreamMetrics` | 1 minute | Incoming / outgoing counts, bytes, watermark delay, backlog |
| `EventStreamErrorMetrics` | 1 minute | Error counts by type (runtime, deserialization, conversion) |

**Filter by `ArtifactId` / `WorkspaceId`, never the name columns** — those cache
at emission time and go stale after a rename or move. For live per-node numbers
during authoring, the editor's **Data insights** tab needs no monitoring setup.

Worked KQL queries and the full shared-dimension list:
[references/monitoring.md](references/monitoring.md).

## Kafka custom CA / mTLS

Kafka, Amazon MSK, and Confluent Cloud sources can take a custom CA certificate
and a client certificate from **Azure Key Vault** (GA July 2026), under the
source connection's **TLS/mTLS settings**. `SASL_SSL` needs a CA cert only when
the cluster uses a private CA; `SSL (mTLS)` needs both CA and client cert + key.

Certificates must be **PEM with LF line endings**, cert and private key
concatenated, `contentType: application/x-pem-file`, with `keySize` matching the
real key size — and whoever previews data needs Key Vault read access on them.
Full setup, the trusted-CA list, and seven failure modes:
[references/kafka-mtls.md](references/kafka-mtls.md).

## Producing to a schema-associated custom endpoint

Only relevant when pushing events *into* a custom endpoint that has an
associated schema. Two facts decide whether it works at all:

- **CloudEvents binary mode is required.** Attributes go in the Event Hub
  message's application properties as `cloudEvents:*`; the body is the payload
  JSON alone. Structured mode is silently dropped with
  `CloudEventPropertyMissingException`.
- **Schema support is a creation-time flag** — it cannot be turned on for an
  existing eventstream, and schema-enabled eventstreams don't survive deployment
  pipelines with registries intact. Plan workspaces before you build.

The wire format, the `dataschema` URI anatomy, version-bump behaviour, table
naming, and the custom-endpoint connection-string conventions are all in
[references/cloudevents-producer.md](references/cloudevents-producer.md). None
of it is on Microsoft Learn.

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
| Events pushed to a schema-associated custom endpoint are dropped | Wrong CloudEvents envelope, `dataschema` version, or per-environment registry host | See [references/cloudevents-producer.md](references/cloudevents-producer.md) — four distinct failure modes |

## Reference

Detail lives in [references/](references/) — each section above links the file
that carries its full version.

- Microsoft Learn: [Add and manage an event source](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-manage-eventstream-sources)
- Microsoft Learn: [Set alert on an Eventstream with Activator destination](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/set-alerts-event-stream)

## See also

- `fabric-eventhouse` — the natural KQL-Database pair for analytics on streamed events
- `fabric-rest-api` — Eventstream item REST endpoints, LRO polling, jobType values
- `fabric-auth` — token audience for Fabric REST against Eventstream items
- `fabric-warehouse-monitoring` — Warehouse-side query monitoring; workspace-monitoring links in its references bundle
