---
name: fabric-copy-job
description: "Use for Fabric Data Factory Copy job — the no-pipeline data-movement item (`CopyJob`) for many-source→many-destination ingestion. Covers copy modes (full vs incremental), watermark-based incremental (GA: ROWVERSION/datetime/int columns) vs CDC-based incremental (Preview: captures inserts/updates/deletes, SCD Type 2, Merge default), the CDC-vs-watermark rubric, switching full↔incremental via `jobMode` and resetting to full (whole job or per table; changing the incremental column forces a full reload), the JSON definition (`copyjob-content.json`, View→View JSON code, base64 getDefinition/updateDefinition — replaces all parts), REST surface + on-demand run (`?jobType=Execute` gotcha) + fabric-data-factory-mcp tools, event-driven invocation via Activator (Preview — no parameters) and Job events alerting, plus gotchas (change-retention window, net-change-only, default capture instance only, CDC+non-CDC table demotion, Lakehouse CDF undetectable) and CU pricing (full 1.5 / incremental 3 CU-hr)."
---

# Fabric Copy job (Data Factory)

Copy job is the guided, **no-pipeline** data-movement item in Fabric Data Factory: many sources → many destinations with bulk copy, incremental copy, and CDC replication. The **Copy job item is GA**; create via `+ New Item → Copy job`. Item type: **`CopyJob`**.

There is **no local file-based artifact** (unlike TMDL/PBIR) — you script Copy jobs via the REST API / MCP, or edit the JSON definition in-product. When to reach for Copy job vs alternatives: Copy job for guided source→destination movement; **Mirroring** for zero-config near-real-time DB replication; **pipeline Copy activity** when you need broader orchestration.

## Copy modes

| Mode | Behaviour | Status |
|---|---|---|
| **Full copy** | Every run copies all data source→destination (one-time or recurring snapshot). | GA |
| **Incremental — watermark** | First run = full load; later runs copy only rows past the watermark. | GA |
| **Incremental — CDC** | First run = full load; later runs replay inserts/updates/**deletes** from the source change feed. | **Preview** |

Copy job tracks the last-successful-run state itself. **A failed run doesn't advance state** — the next run resumes from the last success (no data loss, no manual watermark bookkeeping).

### Watermark vs CDC — decision rubric

| Consideration | CDC | Watermark |
|---|---|---|
| Source prerequisite | CDC enabled + connector supports it | A monotonically-increasing column |
| Detects inserts / updates | Yes / Yes | Yes / Yes (when the column changes) |
| Detects **deletes** | **Yes** | **No** |
| Typical write method | Merge or SCD Type 2 | Append or Merge |
| Source load | Reads change feed (light on high-churn tables) | Scans for rows past the watermark |

Watermark column types: **ROWVERSION, datetime, date, integer, string interpreted as datetime**. With CDC you don't pick a column — Copy job auto-detects; default **Update method = Merge**, key columns default to the source **primary key**. If a table has no CDC, Copy job falls back to watermark automatically.

## Switching full ↔ incremental / resetting

- You can **reset incremental back to full at any time** — for the **whole job or per table**. The next run does a fresh full load, then resumes incremental.
- **Editing that forces a reset**: changing a table's **incremental column** (or update method) resets that table to an initial full load on the next run. Adding/removing tables or columns is a normal edit.
- Manual **Run** works even on a scheduled job — in incremental mode it still only moves changes since the last run.

## CDC replication (Preview)

CDC connector support (per the [connectors matrix](https://learn.microsoft.com/fabric/data-factory/copy-job-connectors#cdc-replication-preview)) — the **SQL family is the most complete** (source + destination + SCD Type 2): **Azure SQL DB, Azure SQL Managed Instance, on-premises SQL Server**. Others are narrower: Oracle / Google BigQuery / SAP Datasphere Outbound = CDC **source only** (no SCD2); Fabric Warehouse = CDC **destination only**; Fabric Lakehouse table = source + destination + SCD2 (Preview). Snowflake CDC is covered by its own tutorial.

> The audit that flagged this skill said "CDC for SQL estates **GA**." As of the docs, **CDC replication is still labelled Preview** (the item and watermark-incremental are GA). Re-verify per connector before telling a client CDC is GA.

## JSON definition & editing

The definition is a base64 part, **`copyjob-content.json`**, with two sections:
- `properties` — **`jobMode`**, source/destination connection references, `policy` (e.g. `timeout`).
- `activities[]` — one object per table mapping (source/destination table, `translator` column mappings, `writeBehavior`, type conversion).

**`jobMode` is the full↔incremental switch in JSON**: `"Batch"` = full or watermark-incremental copy; `"CDC"` = change-data-capture incremental. Per-activity `writeBehavior` (`Overwrite` / `Merge`) sets append-vs-merge. So "switch a job from full to CDC" = flip `jobMode` and set `writeBehavior: "Merge"`, then `updateDefinition`.

Get the JSON from the UI via **View → View JSON code**, or over REST:
- `POST /v1/workspaces/{wsId}/copyJobs/{id}/getDefinition` → base64 `copyjob-content.json` (+ `.platform`).
- `POST /v1/workspaces/{wsId}/copyJobs/{id}/updateDefinition` — **replaces the whole definition**, so include every content part you want to keep (omitted parts are dropped). Same replace-not-merge rule as every Fabric definition API — see the **fabric-tmdl-api skill**. Unlike semantic-model definitions, the Copy job create/updateDefinition examples **do** carry a `.platform` part (item metadata); it's optional — include it only when you intend to update metadata.

## REST & MCP surface

REST base: `/v1/workspaces/{wsId}/copyJobs`. CRUD = `POST` (create, ±definition), `GET` (get/list), `PATCH` (rename/description), `POST .../getDefinition|updateDefinition`, `DELETE`.

**On-demand run gotcha**: run uses the generic jobs endpoint with **`?jobType=Execute`**, not `CopyJob`:
```
POST /v1/workspaces/{wsId}/items/{itemId}/jobs/instances?jobType=Execute   → 202 Accepted
```
(The *returned* instance object reports `jobType: "CopyJob"` — the run trigger value is still `Execute`.) Scheduling and 202/LRO polling follow the standard Fabric patterns — see the **fabric-rest-api skill**; auth/token audience — see the **fabric-auth skill**.

MCP (`fabric-data-factory-mcp`, `dnx Microsoft.DataFactory.MCP --prerelease`) covers the surface without hand-rolling REST: `create_copy_job`, `create_copy_job` (with definition) / `update_copy_job_definition`, `get_copy_job` / `get_copy_job_definition`, `list_copy_jobs`, `update_copy_job`, `run_copy_job`, `get_copy_job_run_status`, `create_copy_job_schedule`, `list_copy_job_schedules`.

## Event-driven invocation

- **Activator (Preview)**: a Fabric Activator rule can run a Copy job as its action when a condition fires. **Gotcha — Copy job actions don't accept parameters** (pipelines/notebooks/dataflows do). So Activator can *trigger* a Copy job but can't parameterize the run.
- **Job events / alerting**: `CopyJob` is a supported item type for Fabric **Job events** (`Microsoft.Fabric.ItemJobSucceeded` / `ItemJobFailed`, etc.). Route these through Real-Time hub → Activator to alert on copy-job success/failure or chain downstream work.
- **Pipeline event triggers**: wrapping the Copy job in a pipeline Copy-job activity lets you use pipeline event triggers (e.g. new files in a lake) for richer, parameterized orchestration.

## Gotchas

- **Change-retention window** must exceed the run interval — CDC retention / Oracle redo-log / Snowflake change-tracking / BigQuery change-history. If changes age out before the next run, **they're silently lost**.
- **Net change only** today (full change history "coming later"): between two runs you get the net effect, not every intermediate change.
- **Only the default capture instance** is supported — custom SQL Server CDC capture instances aren't.
- **Mixing CDC and non-CDC tables in one job demotes ALL tables to watermark-based** incremental. Split them into separate jobs to keep true CDC.
- **Fabric Lakehouse tables**: Copy job can't auto-detect whether CDF is enabled.
- **Plain (non-CDC) incremental can't capture deletes** from the source.
- **Storage destinations**: empty files are created at the destination when a run loads no data.
- **Schema drift**: with a column mapping, a new source column is ignored, but a deleted/renamed *mapped* column **fails** the run; without a mapping, new columns are ignored and deleted columns just stop syncing (existing destination data stays). Source type changes must be castable to the destination type or the run fails.
- **Auto-partitioning (Preview)** is **watermark-based only** (not CDC) and limited to specific SQL-family + Oracle/SAP HANA/Lakehouse connectors — Advanced settings toggle.

## Pricing (Capacity Units)

| Pattern | CU consumption | Granularity |
|---|---|---|
| Full copy | 1.5 CU-hours | per Copy job item |
| Incremental copy | 3 CU-hours | per Copy job item |

Billed by run **duration** × intelligent-optimization throughput. The 3 CU-hr incremental rate applies to **both** the initial full load in incremental mode **and** subsequent delta runs.

## Reference

- Microsoft Learn: [What is Copy job](https://learn.microsoft.com/fabric/data-factory/what-is-copy-job) · [Incremental copy](https://learn.microsoft.com/fabric/data-factory/incremental-copy-job) · [CDC in Copy job](https://learn.microsoft.com/fabric/data-factory/cdc-copy-job)
- Microsoft Learn: [Copy job connectors matrix](https://learn.microsoft.com/fabric/data-factory/copy-job-connectors) · [REST API capabilities](https://learn.microsoft.com/fabric/data-factory/copy-job-rest-api-capabilities) · [Copy job definition schema](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/copyjob-definition) · [Pricing](https://learn.microsoft.com/fabric/data-factory/pricing-copy-job)
- Full connector matrix, definition payload examples, and end-to-end REST workflow: [references/REFERENCE.md](references/REFERENCE.md)

## See also

- **fabric-rest-api skill** — LRO/202 polling, jobType values, scheduling, pagination for the calls above
- **fabric-auth skill** — bearer-token audience for `api.fabric.microsoft.com`
- **fabric-tmdl-api skill** — the "updateDefinition must include ALL parts" rule (applies identically here)
- **fabric-cli skill** — `fab` item CRUD / `fab api` passthrough if you'd rather script from the CLI
- **fabric-eventstream skill** / Activator — event-driven triggering and Job-events alerting
- **fabric-gotchas skill** — cross-cutting error index
