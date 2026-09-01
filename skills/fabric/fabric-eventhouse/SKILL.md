---
name: fabric-eventhouse
description: "Use for Microsoft Fabric Eventhouse / KQL Database. Covers connection (cluster URI via `kqlDatabases` REST, kusto.kusto.windows.net audience, az rest temp-file for `|` escaping), authoring (`.create-merge` for safe schema evolution, ingestion inline/set-or-append/from-storage `;impersonate`, streaming policy, CSV/JSON mappings, retention/caching/partitioning/merge policies, materialized views + update policies, external tables), OneLake-availability-ON constraints (add/delete column ✅ April 2026+; type/rename/RLS/deletes need availability off), per-KQL-database remote MCP server (http, read/query auth, not in global MCP template), 4-role permissions (viewer/user/ingestor/admin), KQL query patterns (time-filter-first, has vs contains, materialize), string-matching speed table, KQL graph operators (`make-graph`/`graph-match`/`graph()` snapshots, openCypher — in-engine KQL graph, NOT the GraphModel item; see fabric-graph), and Fabric gotchas (`;impersonate`, MV stuck at 0%, dynamic vs string, == case-sensitive)."
paths:
  - "**/*.Eventhouse/**"
model: inherit
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Fabric Eventhouse / KQL Database

KQL management and query patterns specific to Fabric Eventhouse. Assumes familiarity with KQL — focus is on Fabric-specific behavior and az-rest-driven workflows.

## Connection

- **Cluster URI**: each KQL Database has its own `queryServiceUri`,
  `https://<cluster>.kusto.fabric.microsoft.com`. Discover with
  `GET /v1/workspaces/{wsId}/kqlDatabases` (returns `queryServiceUri` +
  `databaseName` per item).
- **Token audience**: `https://kusto.kusto.windows.net/.default` for all direct
  access. A wrong audience surfaces as a 401 *"Request is invalid and cannot be
  processed"*, not an auth error.
- **Query endpoint**: `POST {clusterUri}/v1/rest/query`, body
  `{"db":"<dbName>", "csl":"<KQL>"}`.
- **KQL `|` breaks shell escaping** — write the JSON body to a temp file and pass
  `--body @<file>`, never inline.

Worked `az rest` invocation and the REST item-definition envelope:
[references/programmatic-access.md](references/programmatic-access.md).

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

**With OneLake availability ON the surface narrows**: adding and deleting
columns work (April 2026+), but altering a column type, renaming a table,
applying RLS, and deleting/truncating/purging data do **not** — toggle
availability off, change, toggle back on. Full matrix:
[references/onelake-availability.md](references/onelake-availability.md).

## Ingestion

| Command | Use for |
|---|---|
| `.ingest inline into table T <\|` | Small data / testing |
| `.set-or-append T <\|` | Append KQL query results |
| `.set-or-replace T <\|` | Replace table contents from a query |
| `.ingest into table T (h'abfss://...;impersonate')` | Blob / ADLS / OneLake files — **the `;impersonate` suffix is required** |

**Streaming ingestion is per-table and must be enabled first**:
`.alter table Events policy streamingingestion enable`.

> **Schema-associated Eventstream destinations** auto-create one table per schema
> named `{CloudEventType}_{CloudEventSchemaVersion}` (e.g. `Orders_v1`) — don't
> create these by hand. See `fabric-eventstream`.

Full command syntax and CSV/JSON mapping definitions:
[references/ingestion.md](references/ingestion.md).

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


## Stored Functions and Update Policies

`.create-or-alter function` takes `docstring`, `folder`, and default parameter
values — see [references/REFERENCE.md](references/REFERENCE.md). The Fabric-specific
piece is wiring one as an **update policy**, an automatic transform applied on
ingestion into the source table:

```kql
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

## Graph semantics

KQL can do graph analysis **inside the KQL engine** — `make-graph` for a
transient graph, `graph()` over a persistent snapshot, then `graph-match` /
`graph-shortest-paths`. This is **not** the standalone Fabric **GraphModel**
item, which is a separate workload using GQL / ISO-39075 (see `fabric-graph`).
Same word, different engine.

Operators, snapshot management and limits, and the openCypher/GQL-over-KQL
preview: [references/graph-operators.md](references/graph-operators.md).

## Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `Request is invalid and cannot be processed` (401) | Wrong token audience | Use `https://kusto.kusto.windows.net/.default` |
| `dynamic` column shows as string | Stored as string, not dynamic | Wrap with `parse_json(col)` or `todynamic()` |
| `Forbidden (403)` on management commands | Insufficient role | Need `admin` or `ingestor` database role |
| OneLake / ADLS ingest auth fails | Missing `;impersonate` on URI | Append `;impersonate` to the storage URI |
| Materialized view stuck at 0% | No new source data or backfill pending | `.show materialized-view MV statistics` |
| `.drop column` fails | Column referenced by materialized view or function | Drop dependents first |
| Streaming ingestion errors | Streaming policy not enabled | `.alter table T policy streamingingestion enable` |
| External table returns no data | Path / format / schema mismatch | Verify `abfss://` path, `dataformat=`, and column types match source |
| Retention deleting data too soon | Table-level policy overrides DB default | `.show table T policy retention` |
| `dcount()` returns approximate value | HyperLogLog by design | `dcount(col, 4)` for higher accuracy (costly), or `T \| distinct col \| count` for exact |

## Remote MCP server (preview)

A hosted HTTP MCP server per KQL database gives schema discovery, NL→KQL, and
query execution. **Claude Code cannot connect to it** — the
`api.fabric.microsoft.com/v1/mcp/*` endpoints require OAuth Dynamic Client
Registration it doesn't support, so it appears in config and silently fails to
connect. From Claude Code use the local `fabric-rti-mcp`
(`uvx microsoft-fabric-rti-mcp`); the hosted server's working home is
`.vscode/mcp.json` for VS Code Copilot. URL pattern, auth requirements, and the
config block: [references/remote-mcp.md](references/remote-mcp.md).

## Reference

- Microsoft Learn: [Eventhouse overview](https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse)
- Full MS Learn link bundle (KQL management commands / ingestion / mappings / materialized views / update policies / monitoring / REST query API): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-auth skill — `kusto.kusto.windows.net/.default` audience details
- fabric-cli skill — `fab` CLI for Eventhouse item creation, principals, exports
- fabric-rest-api skill — `kqlDatabases` listing endpoint and pagination
- fabric-graph skill — the *other* graph workload: the standalone Fabric **GraphModel** item (GQL / ISO-39075 over OneLake). Different engine; the KQL graph operators above do NOT apply there.
