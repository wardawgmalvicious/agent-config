# Fabric Dataflow Gen2 — reference

Detail split out of `SKILL.md`. Everything here is from Microsoft Learn,
read 2026-09-12. Where a claim is not on a Learn page it says so.

## 1. Definition part schemas

### `queryMetadata.json` — top level

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `formatVersion` | string | **yes** | Only `202502` is allowed |
| `name` | string | **yes** | The mashup name |
| `computeEngineSettings` | object | no | `allowFastCopy` (default true), `maxConcurrency` |
| `queryGroups` | array | no | `id`, `name`, `description`, `parentId`, `order` |
| `documentLocale` | string | no | BCP-47 |
| `gatewayObjectId` | string | no | |
| `queriesMetadata` | object | no | Keyed by query name |
| `connections` | array | no | `path`, `kind`, `connectionId` |
| `fastCombine` | bool | no | default **false** |
| `allowNativeQueries` | bool | no | default **true** |
| `skipAutomaticTypeAndHeaderDetection` | bool | no | default **false** |
| `parametric` | bool | no | default **false**; public parameters mode |

### `queriesMetadata` entries

| Field | Required | Notes |
| --- | --- | --- |
| `queryId` | yes | |
| `queryName` | yes | Matches the key |
| `queryGroupId` | no | |
| `isHidden` | no | default false |
| `loadEnabled` | no | default **true** |

`loadEnabled: true` is the default, so it can be absent on read-back.

### `.mdf` — Mapping Data Flow transform

`name` and `properties`, where `properties.type` is `MappingDataFlow` and
`properties.typeProperties` carries `sources[]`, `sinks[]`,
`transformations[]` and the required `scriptLines[]`. Sources and sinks
each take a `name` and optional `externalReferences.connection`.

MDF transforms use Spark-backed compute. Pricing is being finalized and
they are **not currently billed**.

## 2. Public parameter types

From `discover-dataflow-parameters`. Each carries `name`, `type`,
`isRequired`, `description` and `defaultValue`.

| Type | Format of the value |
| --- | --- |
| `String` | — |
| `Integer` | int64 |
| `Number` | double |
| `Boolean` | — |
| `Date` | `yyyy-MM-dd` |
| `DateTime` | `yyyy-MM-ddTHH:mm:ss.xxxZ` |
| `DateTimeZone` | `yyyy-MM-ddTHH:mm:sszzz` |
| `Time` | `HH:mm:ss` |
| `Duration` | `P5DT14H35M30S` |

The endpoint paginates with `continuationToken`. A non-parametric
dataflow returns `DataflowNotParametricError`.

**Overriding at run time** uses `type: "Automatic"` in the execute
payload. The reference notes `Automatic` explicitly for Date,
DateTimeZone, Duration and Time.

**Required parameters must be supplied**, or the run fails. Optional ones
fall back to their current value. In the pipeline Dataflow activity,
required parameters carry an asterisk and cannot be removed from the
grid.

## 3. Data destinations

Supported destinations: Azure SQL databases, Azure Data Explorer
(Kusto), Azure Data Lake Gen2, Fabric Lakehouse tables, Fabric Lakehouse
files, Fabric Warehouse, Fabric KQL database, Fabric SQL database,
SharePoint files, Snowflake, PostgreSQL.

- **Only tabular queries** can take a destination — functions and lists
  cannot.
- **Lakehouse alone supports both files and tables.**
- **KQL and Azure Data Explorer do not support `replace`** as an update
  method; most others support append and replace.
- **Warehouse and Snowflake require fixed schema.**
- **Warehouse writes require staging** and only into the same workspace
  as the dataflow.
- **A new table that you later delete is recreated** on the next
  refresh. An *existing* table is never recreated — delete it and the
  dataflow stops writing.
- **Automatic settings** mean replace + managed mapping + drop-and-
  recreate on every refresh, which removes relationships or measures
  added to the table. Available for Lakehouse and Azure SQL only.
- **Schema options apply only to `replace`.** With dynamic schema a
  mismatch drops and recreates the table; with fixed schema a mismatched
  query fails the publish.
- **Destination queries are named** `<query>_DataDestination`.
- **V-Order** has two separate controls — one on the destination, one on
  the staging Lakehouse under the Scale tab. Preview, default true,
  roughly 10% read improvement, recommended for Direct Lake.
- **Vacuum conflicts with incremental refresh** — turn vacuuming off
  when incremental refresh is in use. Default retention is seven days
  and going below that risks time-travel breakage.
- **SQL analytics endpoint metadata sync** defaults true; disable it
  when a large delta-log backlog is inflating refresh times.

### Snowflake destination (preview) limitations

Dynamic schema unsupported; default destination only works for new
tables; gateway unsupported, cloud only.

### Type support

Not every type survives every destination. Fabric Warehouse rejects
`Currency`; `DateTimeZone` is unsupported on Lakehouse, Warehouse and
Snowflake; `Time` is unsupported on ADX, Lakehouse and Warehouse.
`Action`, `Any`, `Binary`, `Function`, `None`, `Null`, `Type` and
`Structured` are unsupported everywhere. Remap currency and percentage
to decimal when mapping to an existing column.

Column nullability defaults to allowing nulls in all destination
columns. A non-nullable collision surfaces as `E104100 … We can't insert
null data into a non-nullable column`.

## 4. Incremental refresh

**Supported destinations**: Fabric Lakehouse, Fabric Warehouse, Azure SQL
Database. Others need a second query reading the staged data.

### Hard requirements

- The query must **fully fold**. A green folding indicator at authoring
  time can still fail validation later — `Table.SelectRows` is the named
  example.
- **Default destination configuration is not supported**; define the
  destination explicitly in query settings.
- The destination must use a **fixed schema**.
- The only supported update method is **`replace`**.
- Set the destination **before** the first incremental run, or it holds
  only the changed data.

**Mechanics.** Data is bucketed by a DateTime, Date or DateTimeZone
column. Each bucket is deleted then reinserted; data outside the bucket
range is untouched, including history older than the first bucket.
"Extract data from the past" takes days, weeks, months, quarters or
years. Filters and parameters are added automatically as the last query
step — unlike Gen1, where you supplied them.

**Caps**: 50 buckets per query, 150 per dataflow, and at most 10
concurrent bucket evaluations against a Lakehouse.

**Lakehouse caveats**: other writers such as Spark can interfere;
`OPTIMIZE` and `REORG TABLE` are unsupported on tables using incremental
refresh; a gateway needs at least the May 2025 release (3000.270);
switching a table with overlapping existing data from non-incremental to
incremental is unsupported, because the whole Delta table would have to
be rewritten.

Staged data outside the bucket range is not guaranteed to remain
available. A query with incremental refresh enabled shows a blue triangle
on its icon.

## 5. Fast copy

**Thresholds** — CSV or Parquet of at least **100 MB** in ADLS Gen2 or
Blob storage; **5 million rows or more** for databases. *Require fast
copy* bypasses the threshold and fails fast instead of waiting for a
timeout.

**Connectors**: ADLS Gen2, Blob storage, Azure SQL DB, Lakehouse,
PostgreSQL, on-premises SQL Server, Warehouse, Oracle, Snowflake, SQL
database in Fabric.

**Transformations on file sources** are limited to combine files, select
columns, change type, rename and remove column. For SQL sources anything
inside the native query is fine.

**Output**: Lakehouse only, directly. For anything else, stage the query
and reference it from a later query.

**Other limits**: fixed schema unsupported, schema-based destination
unsupported, on-premises gateway 3000.214.2 or newer. Enabling *Navigate
using full hierarchy* may stop fast copy working, and needs gateway
3000.310 with a gateway.

Check whether it was used via the **Engine** column in refresh history.
Step diagnostics colour steps: yellow potentially supported, red not
supported.

## 6. Monitoring

### Refresh history

Shows up to **50 refreshes or six months**, whichever comes first;
OneLake retains **250 refreshes or six months**. Detailed logs come from
the Power Query mashup engine, appear minutes after a refresh and last
**28 days**. Downloading them needs at least the **Viewer** role;
gateway-refreshed dataflows additionally need *Admin consent for gateway
diagnostics* enabled on the gateway.

Per-refresh fields include status, type, start and end, duration,
Request ID, Session ID and Dataflow ID. The **Tables** section lists
entities being loaded into staging. Activity statistics report endpoints
contacted, bytes and rows read and written — some connectors report rows
and some bytes.

### Workspace monitoring

Covers **CI/CD dataflows only**. Enabling *Log workspace activity*
creates an eventhouse plus a read-only KQL database. Records land in
`ItemJobEventLogs` with `ItemKind == "DataFlow"`.

Two job types: `Refresh` and `Publish`. **Each operation writes an
`InProgress` record and a terminal `Completed` or `Failed` record sharing
one `JobInstanceId`** — filter on the terminal status or deduplicate, or
counts double.

```kql
ItemJobEventLogs
| where ItemKind == "DataFlow" and JobType == "Refresh" and JobStatus == "Failed"
| order by Timestamp desc
| project Timestamp, ItemName, WorkspaceName, JobStartTime, JobEndTime, JobStatus
```

Useful columns: `JobInvokeType` (`Manual` or `Scheduled`), `JobStatus`,
`DurationMs`, `ExecutingPrincipalId` / `Type`, `JobDefinitionObjectId`
(the scheduler that fired it), `JobScheduleTime`, `JobStartTime`,
`JobEndTime`.

## 7. Upgrade Wizard — Needs Attention reasons

Statuses are *Ready to migrate*, *Needs Attention* and *Upgrade
unavailable*. The assessment checks the dataflow itself, not its
consumers, and does not detect every limitation.

| Reason | What to do |
| --- | --- |
| DirectQuery consumers | Move downstream models to Import or Direct Lake |
| Bring Your Own Lake (ADLS Gen2) | Configure an ADLS Gen2 destination on the upgraded item |
| Incremental refresh | Settings are not carried over; configure a supporting destination, then reconfigure |
| Linked entities | Cascading refresh is unsupported; trigger downstream refreshes with a pipeline or schedule |
| Referenced by linked entities | Open and save the referencing dataflows; move them off the legacy connector |
| Unsupported characters in the name | Wizard strips them; rename first to control the result. Only letters, numbers, whitespace and `( ) [ ] { } + - = _ #` are allowed |
| Name already in use | Wizard prefixes *Migrated* |
| **More than 50 enabled queries** | **Must be reduced before upgrading** |

DirectQuery and linked-entity reasons are detection signals rather than
proof — confirm real consumers via lineage first. A dataflow can sit on
both sides of a linked-entity relationship.

Other documented limits: historic data is not carried over; refresh is
blocked during the upgrade; a failed upgrade cannot be retried for 24
hours; outbound access protection cannot be enabled on the workspace for
30 days; GCC is unsupported; and workspace Viewers cannot consume tables
from an upgraded dataflow.

### `saveAsNativeArtifact` (preview, Power BI REST)

```text
POST https://api.powerbi.com/v1.0/myorg/groups/{groupId}/dataflows/{gen1DataflowId}/saveAsNativeArtifact
```

Body: `displayName` (≤200), `description` (≤4000), `includeSchedule`,
`targetWorkspaceId`. Omitting `displayName` generates one with a
`_copy1` style suffix; omitting `targetWorkspaceId` uses the source
workspace. A copied schedule arrives **disabled**.

Returns `200` with `artifactMetadata` **even when parts failed** —
inspect `errors` for `FailedToCopySchedule`, `SetDataflowOriginFailed`
or `ConnectionsUpdateFailed`.

### Save As known limitations

Scheduled refresh settings are not copied by Gen2 Save As; incremental
refresh settings are not copied by Gen1 Save As. CDM folders, BYOL,
Compute Engine, DirectQuery, AI Insights and endorsements have no Gen2
equivalent and are not copied.

## 8. Cost formulas

```text
# CI/CD standard compute, per query
StandardComputeCapacityConsumptionInCUSeconds =
    if(QueryDurationInSeconds < 600,
       QueryDurationInSeconds * 12,
       (QueryDurationInSeconds - 600) * 1.5 + 600 * 12)

# non-CI/CD standard compute
StandardComputeCapacityConsumptionInCUSeconds = QueryDurationInSeconds * 16

# high scale (staging enabled)
HighScaleComputeCapacityConsumptionInCUSeconds = QueryDurationInSeconds * 6

# fast copy — duration is aggregate core time, not wall clock
FastCopyComputeCapacityConsumptionInCUSeconds = QueryDurationInSeconds * 1.5
```

Pricing applies to F2 and above, not to trial capacities. The VNET data
gateway is a separate additive meter at **4 CU**, billed on uptime, so
the total is the dataflow charge plus the gateway charge.

**Partitioned compute changes the arithmetic**: each partition is its own
unit of work and charges are the sum over every partition, so parallelism
shortens wall clock without reducing CU. That page was not drilled — read
it before advising on partitioned workloads.

## 9. Git integration and deployment pipelines

Dataflow Gen2 appears in the supported-item lists for **both** Git
integration and deployment pipelines, under Data Factory, with no
preview marker. The Power BI **Dataflow** (Gen1) item is listed
separately and is marked preview in the deployment-pipelines list.

Unsupported items in a connected workspace are ignored rather than
deleted — visible in the source-control panel but not committable.

## 10. Not drilled

Nothing in this skill describes these, and the omissions are deliberate:

- `executeQuery` and its Arrow IPC response — no Learn page found.
- `gatewayClusterDatasources`, the internal Power BI v2.0 endpoint that
  resolves `ClusterId`. Undocumented by its own description.
- Connection and gateway CRUD (`/v1/connections*`, `/v1/gateways`).
- The Power BI Gen1 read surface used for bulk migration assessment —
  `upstreamDataflows`, `transactions`, `datasources`, admin listings.
- `dataflow-gen2-partitioned-compute` and
  `dataflow-gen2-cost-performance-benchmarks`.
- MDF transform authoring, the connector catalogue, Copilot, and the
  Power Query editor click-path.
- **No live tenant was used.** Every claim here is documentation rather
  than observation.
