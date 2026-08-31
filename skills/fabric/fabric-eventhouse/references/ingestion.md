# Ingestion and data mappings

Full `.ingest` / `.set-or-append` / `.set-or-replace` command forms and the
CSV/JSON mapping syntax. `SKILL.md` carries which command to reach for and the
streaming-policy prerequisite.

## Ingestion commands

```kql
// Inline (small data / testing)
.ingest inline into table Events <|
2026-04-27T10:00:00Z,Login,user1,{},0.5

// Append KQL query results
.set-or-append Events <|
    OtherTable | where Timestamp > ago(1d)

// Replace table contents with KQL query results
.set-or-replace Events <| StagingEvents | where IsValid == true

// From Blob / ADLS / OneLake (note `;impersonate` on the URI)
.ingest into table Events (
    h'abfss://workspace@onelake.dfs.fabric.microsoft.com/lakehouse.Lakehouse/Files/events.parquet;impersonate'
) with (format="parquet")
```

**Streaming ingestion** must be enabled per-table first:

```kql
.alter table Events policy streamingingestion enable
```

> **Schema-associated Eventstream destinations** auto-create one table per schema named `{CloudEventType}_{CloudEventSchemaVersion}` (e.g. `Orders_v1`) — you don't create these by hand. The producer's `cloudEvents:type` and `dataschema` version drive the table name; see `fabric-eventstream` → *Producing to a schema-associated custom endpoint*.

## Data mappings

```kql
// CSV — by ordinal
.create table Events ingestion csv mapping "EventsCsvMapping"
'[{"column":"Timestamp","datatype":"datetime","ordinal":0},
  {"column":"EventType","datatype":"string","ordinal":1}]'

// JSON — by JSONPath
.create table Events ingestion json mapping "EventsJsonMapping"
'[{"column":"Timestamp","path":"$.timestamp","datatype":"datetime"},
  {"column":"EventType","path":"$.eventType","datatype":"string"}]'

.show table Events ingestion csv mappings
.show table Events ingestion json mappings
```
