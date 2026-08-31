# Eventstream source connectors

Full connector surface and the DeltaFlow CDC schema mode. Summarised in
`SKILL.md`; this is the exhaustive list.

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
| **Azure Event Hubs / IoT Hub** | Native sources — no CDC layer. Event Hubs auth is **Shared Access Key** in both the basic and extended-features pivots; **workspace identity** (Entra ID) instead of shared access keys is in **preview (Aug 2026)** — announced in What's New, but not yet on the connector's Learn page, so expect the UI to lead the docs |
| **Apache Kafka / Amazon MSK / Confluent Cloud Kafka** | Kafka-protocol sources — base connector **GA (June 2026)**; SASL_SSL / SASL_PLAINTEXT / Microsoft Entra auth. Custom-CA / mTLS also **GA (July 2026)** — see below |
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
