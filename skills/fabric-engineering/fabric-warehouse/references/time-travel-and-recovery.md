# Time travel, snapshots, and recovery

Three different mechanisms with three different retention windows. `SKILL.md`
carries the `OPTION (FOR TIMESTAMP AS OF ...)` query syntax; this file covers
the SQL analytics endpoint variant, named snapshots, and item recovery.

## SQL analytics endpoint time travel (preview)

Time travel extended to the **SQL analytics endpoint** in June 2026 (preview) — same `OPTION (FOR TIMESTAMP AS OF '...')` read-only `SELECT` syntax, UTC, `yyyy-MM-ddTHH:mm:ss[.fff]` (max 3 fractional digits). Distinct from the Warehouse behavior above:

- **Gated on New metadata sync.** Only enabled for SQLEPs **created with [New metadata sync (preview)](https://learn.microsoft.com/fabric/data-engineering/sql-analytics-endpoint-metadata-sync#new-metadata-sync-preview)** turned on (Workspace settings → Warehouse). Endpoints on legacy metadata sync don't get time travel.
- **Retention is NOT the Warehouse 1–120 day window.** For a Lakehouse SQL analytics endpoint the time-travel window is governed **per table by Delta VACUUM retention** (`delta.logRetentionDuration`, default 30 days; VACUUM keeps unreferenced files 7 days by default) — controlled through Lakehouse table maintenance, not warehouse `data-retention`. Aggressive VACUUM shortens how far back you can travel even if a version still shows in table history.
- **Read-only only** — no DML time-travel variants (SQLEP has no DML anyway).
- Same CLS / RLS / DDM enforcement, single-hint-per-`SELECT`, current-schema, and view limitations as Warehouse.
- Works in stored procedures via `sp_executesql`.

## Warehouse Snapshots (GA)

- Named, read-only, point-in-time views of the entire warehouse.
- **Created via REST API or portal — not T-SQL.**
- Query as `SnapshotName.dbo.Table` via 3-part naming.
- Up to 30 days retention; zero-copy (reference existing Parquet files); atomically refreshable to a new point in time.
- Use cases: financial close (lock KPIs), audit comparisons, stable Power BI reporting during ETL, data recovery.

## Dropped warehouse recovery (GA July 2026)

A **dropped** warehouse is recoverable from the **workspace Recycle bin** — a different mechanism from time travel, and worth keeping straight:

| | Time travel | Warehouse Snapshots | Recycle bin recovery |
|---|---|---|---|
| Recovers | a past state of tables in a **live** warehouse | a named point-in-time view of a live warehouse | the **whole deleted item** |
| Window | **1–120 days**, default 30 (warehouse `data-retention`) | up to 30 days | **7–90 days**, default 7 (**Item Recovery** tenant setting) |
| Set by | warehouse setting | snapshot definition | tenant admin |

- Restores table schemas, data, snapshots, permissions, views, and stored procedures — the item comes back with its properties and permissions intact.
- **Workspace Contributor** or above can restore; **Workspace Admin** is needed to permanently delete during the window.
- Portal: workspace → **Recycle bin** → select → **Restore**. REST: `POST /v1/workspaces/{workspaceId}/recoverableItems/{itemId}/recover` (`DELETE` on the same path purges it).
- With the **Item Recovery** tenant setting **off**, deleting an item retains nothing.
- Recovery **fails if a new item now has the same name** in that workspace — rename the new one, then retry.
- After a permanent delete, OneLake holds the data 7 more days but nothing can restore it.

## Microsoft Learn

- [Recover or permanently delete items](https://learn.microsoft.com/fabric/admin/item-recovery)
