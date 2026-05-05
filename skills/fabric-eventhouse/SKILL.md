---
name: fabric-eventhouse
description: "Use for Microsoft Fabric Eventhouse / KQL Database. Covers connection (cluster URI via `kqlDatabases` REST, kusto.kusto.windows.net audience, az rest temp-file pattern for `|` escaping), authoring (`.create-merge` for safe schema evolution, ingestion inline / set-or-append / from storage with `;impersonate`, streaming policy enable, CSV/JSON mappings, retention/caching/partitioning/merge policies, materialized views + update policies, external tables), OneLake-availability-ON schema constraints (add/delete column ✅ April 2026+; alter-type / rename / RLS / data deletes still need toggling availability off), the per-KQL-database remote MCP server URL + http transport + read/query auth (do NOT add to global MCP template), 4-role permission model (viewer/user/ingestor/admin), KQL query patterns (time-filter-first, has vs contains, project early, materialize), string-matching speed table, and Fabric gotchas (`;impersonate`, MV stuck at 0%, dynamic vs string, == case-sensitive)."
paths:
  - "**/*.Eventhouse/**"
---

# Fabric Eventhouse / KQL Database

KQL management and query patterns specific to Fabric Eventhouse. Assumes familiarity with KQL — focus is on Fabric-specific behavior and az-rest-driven workflows.

## Connection

- **Cluster URI**: each KQL Database has a unique `queryServiceUri` of the form `https://<cluster>.kusto.fabric.microsoft.com`. Discover via Fabric REST: `GET /v1/workspaces/{wsId}/kqlDatabases` (returns `queryServiceUri` and `databaseName` per item).
- **Token audience**: `https://kusto.kusto.windows.net/.default` for all direct access.
- **Query endpoint**: `POST {clusterUri}/v1/rest/query` with body `{"db":"<dbName>", "csl":"<KQL>"}`.
- **KQL `|` breaks shell escaping** — write the JSON body to a temp file and use `--body @<file>` (bash) or `@$env:TEMP\kql_body.json` (PowerShell).

```bash
cat > /tmp/kql_body.json << 'EOF'
{"db":"MyDB","csl":"MyTable | take 10"}
EOF
az rest --method POST \
  --url "${CLUSTER_URI}/v1/rest/query" \
  --resource "https://kusto.kusto.windows.net" \
  --body @/tmp/kql_body.json \
  | jq '.Tables[0].Rows'
```

## Schema Discovery

```kql
.show tables
.show table T schema as json        // column names + types
.show table T details               // row count, extent count, size
.show functions
.show materialized-views
.show database principals           // who has what role
```

## Schema Evolution

- **`.create-merge table`** is the safe / idempotent form — adds missing columns, never drops existing. Prefer over `.create table` for repeatable deployments.
- `.alter-merge table T (NewCol: string)` — add column.
- `.rename column T.OldName to NewName` — rename.
- `.drop column T.OldCol` — irreversible; fails if column is used in materialized view or function (drop dependents first).
- `.drop table T ifexists` — guarded drop.
- **Atomic blue-green swap** via `.rename tables A=B, B=C, C=A` (single command, atomic).

### With OneLake availability ON

When OneLake availability is enabled on the database or table, the supported schema-evolution surface narrows:

| Operation | Allowed with availability ON |
|---|---|
| Add column | ✅ (April 2026+) |
| Delete column | ✅ (April 2026+) |
| Alter column type | ❌ |
| Rename table | ❌ |
| Apply Row-Level Security | ❌ |
| Delete / truncate / purge data | ❌ |

Pre-April 2026 behavior required disabling availability for *any* schema change. For unsupported ops (type change, rename, RLS, data deletes) the workaround is still: turn OneLake availability **off**, perform the change, turn it back on. Toggling off soft-deletes the OneLake mirror; toggling back on backfills.

## Ingestion

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

## Data Mappings

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

## Policies

| Policy | Purpose | Notes |
|---|---|---|
| **Retention** | Soft-delete period + recoverability | JSON body with `SoftDeletePeriod` and `Recoverability` |
| **Caching** | Hot (SSD) vs cold tier window | `.alter table T policy caching hot = 30d` |
| **Partitioning** | Hash key for extent pruning | Hash on column with `XxHash64`, `MaxPartitionCount` |
| **Merge** | Background extent merge thresholds | `RowCountUpperBoundForMerge`, `MaxExtentsToMerge` |
| **Streaming ingestion** | Enable streaming endpoint | `.alter table T policy streamingingestion enable` |

Database-level policies (`.alter database MyDB policy ...`) act as defaults; table-level overrides them. Check effective policy with `.show table T policy retention`.

## Materialized Views

```kql
.create materialized-view with (backfill=true) EventCounts on table Events {
    Events | summarize Count = count(), LastSeen = max(Timestamp) by EventType
}

// Lifecycle
.show materialized-view EventCounts statistics
.disable materialized-view EventCounts
.enable materialized-view EventCounts
.drop materialized-view EventCounts

// Query a materialized view
materialized_view("EventCounts") | where EventType == "Login"
```

**Supported aggregations**: `count()`, `sum()`, `min()`, `max()`, `dcount()`, `avg()`, `countif()`, `sumif()`, `arg_max()`, `arg_min()`, `make_set()`, `make_list()`, `percentile()`, `take_any()`.

## Stored Functions and Update Policies

```kql
// Stored function — supports docstring, folder, default param values
.create-or-alter function with (
    docstring = "Get events for a user in time range",
    folder = "Analytics"
) GetUserEvents(userId: string, lookback: timespan = 1d) {
    Events | where Timestamp > ago(lookback) and UserId == userId
}

// Update policy — automatic transform on ingestion to source table
.create-or-alter function ParseRawEvents() {
    RawEvents
    | extend Parsed = parse_json(RawData)
    | project
        Timestamp = todatetime(Parsed.timestamp),
        UserId    = tostring(Parsed.userId)
}

.alter table ParsedEvents policy update
@'[{"IsEnabled":true,"Source":"RawEvents","Query":"ParseRawEvents()","IsTransactional":true}]'
```

`IsTransactional: true` makes the source-row insert and the transform atomic — failed transform aborts both.

## External Tables (OneLake / ADLS)

```kql
.create external table ExternalSales (
    OrderDate: datetime, ProductId: string, Quantity: int, Amount: real
) kind=storage
dataformat=parquet
( h'abfss://workspace@onelake.dfs.fabric.microsoft.com/lakehouse.Lakehouse/Tables/sales;impersonate' )

external_table("ExternalSales") | where OrderDate > ago(30d) | summarize sum(Amount) by ProductId
```

## Permission Model

| Role | Query | Ingest | Admin |
|---|---|---|---|
| `viewer` | ✅ | ❌ | ❌ |
| `user` | ✅ | ❌ | ❌ |
| `ingestor` | ❌ | ✅ | ❌ |
| `admin` | ✅ | ✅ | ✅ |

```kql
.add database MyDB viewers ('aaduser=user@contoso.com')
.add database MyDB admins  ('aaduser=admin@contoso.com')
.add table T admins        ('aaduser=tableadmin@contoso.com')
```

Layered with **Fabric workspace roles** (Admin/Member/Contributor/Viewer). `restrict access` and security functions provide RLS.

## Query Patterns

| Pattern | Why |
|---|---|
| **Always filter by time first** — `where Timestamp > ago(...)` | Enables extent pruning |
| Use `has` over `contains` | `has` uses term index (fast); `contains` is substring scan (slow) |
| `project` early to drop unused columns | Reduces memory |
| `summarize` with `bin(Timestamp, 1h)` | Efficient time bucketing |
| `take 100` for exploration | Avoids full scans |
| `materialize()` reused subexpressions | Caches intermediate result |
| Avoid `*` in `project` | Explicit column list survives schema changes |

### String matching speed

| Operator | Indexed | Case-Sensitive | Speed |
|---|---|---|---|
| `==` | ✅ | Yes | Fastest |
| `=~` | ❌ partial | No | Medium |
| `has` | ✅ | No | Fast |
| `has_cs` | ✅ | Yes | Fast |
| `startswith` | partial | No | Medium |
| `contains` | ❌ | No | Slow |
| `matches regex` | ❌ | Yes | Slowest |

## Monitoring

```kql
.show queries                           // currently running
.show commands | where StartedOn > ago(1h)
.show journal                           // management ops history
.show ingestion failures | where FailedOn > ago(24h)
.show table T extents                   // per-table extent count + size
.show database datastats                // DB size, extent count, row count
```

## Cross-Database Queries

```kql
database("OtherDB").OtherTable | take 10
```

## Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `Request is invalid and cannot be processed` (401) | Wrong token audience | Use `https://kusto.kusto.windows.net/.default` |
| Query timeout | No time filter, scanning too much | Add `where Timestamp > ago(...)` |
| `has` returns unexpected results | Whole-term match, not substring | Use `contains` for substring (slower) |
| `==` misses rows | Case-sensitive on strings | Use `=~` for case-insensitive |
| `dynamic` column shows as string | Stored as string, not dynamic | Wrap with `parse_json(col)` or `todynamic()` |
| `Forbidden (403)` on management commands | Insufficient role | Need `admin` or `ingestor` database role |
| OneLake / ADLS ingest auth fails | Missing `;impersonate` on URI | Append `;impersonate` to the storage URI |
| Materialized view stuck at 0% | No new source data or backfill pending | `.show materialized-view MV statistics` |
| `.drop column` fails | Column referenced by materialized view or function | Drop dependents first |
| Streaming ingestion errors | Streaming policy not enabled | `.alter table T policy streamingingestion enable` |
| External table returns no data | Path / format / schema mismatch | Verify `abfss://` path, `dataformat=`, and column types match source |
| Retention deleting data too soon | Table-level policy overrides DB default | `.show table T policy retention` |
| `dcount()` returns approximate value | HyperLogLog by design | `dcount(col, 4)` for higher accuracy (costly), or `T \| distinct col \| count` for exact |
| `render` not showing in CLI | `render` is a client-side hint | Use Real-Time Intelligence portal or export data |

## Item definition envelope (REST)

For programmatic create/update via Fabric REST (see fabric-rest-api skill for the envelope):

| Item | Format | Required parts |
|---|---|---|
| **Eventhouse** | `JSON` | `EventhouseProperties.json` (currently empty: `{}`) |
| **KQLDatabase** | `JSON` | `DatabaseProperties.json` (+ optional `DatabaseSchema.kql`) |

`DatabaseProperties.json` schema:

```json
{
  "databaseType": "ReadWrite",
  "parentEventhouseItemId": "<eventhouse-item-id>",
  "oneLakeCachingPeriod": "P36500D",
  "oneLakeStandardStoragePeriod": "P365000D"
}
```

`DatabaseSchema.kql` is an optional KQLDatabase part — KQL management commands run at deploy time. Use to seed tables, materialized views, functions, and ingestion mappings as part of the definition (e.g. `.create-merge table MyLogs (...)` blocks).

## Remote MCP server (preview)

A hosted, HTTP-transport MCP server lets Copilot, GitHub Copilot CLI, and custom agents discover the KQL schema, generate KQL from natural language, execute queries, and sample data — without local install.

- **URL pattern**: `https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/{workspaceId}/items/{kqlDatabaseId}/kqlEndpoint` — **per KQL database**, not workspace-wide.
- **Find URL**: Fabric portal → workspace → KQL database → **Database details** > **Overview** > **Copy URI** next to **MCP Server URI**.
- **Transport**: `http`.
- **Auth**: caller needs **Read** or **Query** permission on the KQL database. Schema discovery additionally requires **Copilot in Fabric** to be enabled at the tenant; without it, the server can only execute KQL — no schema introspection, no NL→KQL.
- **Per-database scoping** means the URL is workspace+item-specific; do not put it in a global MCP template (e.g. `~/.claude/mcp/.mcp.global.template.json`). Add it to a per-project template (`~/.claude/mcp/.mcp.project.template.json` carries this entry with `<WorkspaceId>` / `<KqlDatabaseId>` placeholders) or a per-IDE config such as `.vscode/mcp.json`.

```json
{
  "mcpServers": {
    "eventhouse-remote-mcp": {
      "type": "http",
      "url": "https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/<WorkspaceId>/items/<KqlDatabaseId>/kqlEndpoint"
    }
  }
}
```

## Reference

- Microsoft Learn: [Eventhouse overview](https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse)
- Microsoft Learn: [KQL string operators (has vs contains, term index)](https://learn.microsoft.com/kusto/query/datatypes-string-operators?view=microsoft-fabric)
- Microsoft Learn: [Eventhouse OneLake availability](https://learn.microsoft.com/fabric/real-time-intelligence/event-house-onelake-availability)
- Microsoft Learn: [Get started with the remote MCP server for Eventhouse](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-remote-eventhouse)
- Comprehensive MS Learn link bundle (KQL management commands / ingestion / mappings / materialized views / update policies / monitoring / REST query API): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-auth skill — `kusto.kusto.windows.net/.default` audience details
- fabric-cli skill — `fab` CLI for Eventhouse item creation, principals, exports
- fabric-rest-api skill — `kqlDatabases` listing endpoint and pagination
