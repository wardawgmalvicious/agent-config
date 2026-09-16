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

### Coordinating schema changes

`SKILL.md` carries the cache clear. The sequence that *eliminates* the
window rather than shrinking it, per Kusto docs: suspend streaming
ingestion → wait for outstanding requests to complete → make the schema
change → issue the clear, repeating until every returned row reports
success → resume. Note the docs' own caveat that these commands can
adversely affect streaming-ingestion performance.

## Streaming ingestion over REST

For a notebook or service with no Kusto SDK, no eventstream and no
schema registry:

```http
POST {cluster}/v1/rest/ingest/{db}/{table}?streamFormat=MultiJSON
Authorization: Bearer <Entra token>
<body: concatenated JSON objects>
```

- **Against the engine host — the same host you query.** An `ingest-`
  prefixed host is *queued* ingestion: a different API with different
  semantics. Both hosts exist and both authenticate, so a streaming
  call sent to the wrong one fails in a way that looks like anything
  but a host mistake.
- **The response does not return until the rows are committed and
  queryable** — a `200` is a durability receipt, not an
  accept-and-forget ack, which removes the need for the "did it land?"
  verification layer an Event Hubs or eventstream ack forces you to
  build. (Observed over 19 entities / 631,609 records / 64 of 64
  arrival windows, 2026-09-14; not separately doc-confirmed.)
- The response carries `ConsumedRecordsCount` — locate it **by column
  name, not position**; column order is not contractual.
- **Mapping:** the docs list `mappingName` as *required* when
  `streamFormat` is `JSON`, `MultiJSON` or `Avro`. In practice, where
  every target column is `string`, MultiJSON auto-mapped by column name
  with no mapping defined (same run as above). Treat the undocumented
  path as convenient rather than guaranteed.

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
