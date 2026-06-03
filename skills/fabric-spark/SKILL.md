---
name: fabric-spark
description: "Use for PySpark / Spark in Microsoft Fabric notebooks. Covers the no-external-HTTP constraint (land data in Files/ first), abfss:// URI format for OneLake (GUIDs not names), `notebookutils.runtime.context` for identity lookups vs `spark.conf.*` for session tuning, mssparkutils, lakehouse `enableSchemas` immutability and cross-lakehouse 3-part names, table maintenance (OPTIMIZE/VACUUM/V-Order) impact on SQL Endpoint, Delta Lake default, REST notebook upload quirks (bare-string source `400 exceptionCulprit:1`, `metadata.dependencies.lakehouse` for default-lakehouse binding, 411 on empty-body getDefinition, `/result` LRO suffix, `?updateMetadata=true` requires `.platform`), notebook-execution gotchas (`defaultLakehouse` needs id+name, never retry POST), and in-notebook auto-restart via `%%configure retriableOptions { enabled, maxAttempt }` (April 2026, for pipeline-driven runs)."
paths:
  - "**/*.Notebook/**"
---

# Spark / PySpark in Fabric

## Key Constraints

- Fabric Spark cannot access arbitrary external HTTP/HTTPS URLs — land data in lakehouse `Files/` first (via pipeline Copy activity, OneLake API, or curl)
- Use `abfss://` URI format for OneLake paths in Spark: `abfss://{workspace}@onelake.dfs.fabric.microsoft.com/{item}.Lakehouse/{path}`
- Use workspace GUIDs (not names) in ABFS URIs — spaces are not allowed
- `mssparkutils` for Fabric-specific notebook operations (credentials, secrets, file management)
- Use Delta Lake format for all Lakehouse tables

## Runtime Context vs Spark Session Config

Two different things that are often confused:

| Need | API |
|---|---|
| Workspace / item identity (workspace ID + name, notebook ID + name, default lakehouse ID + name, userId) | `notebookutils.runtime.context["currentWorkspaceId"]` (etc.) — a dict, documented public API, works in pure-Python notebooks |
| Spark session tuning (shuffle partitions, AQE, Delta settings, case sensitivity) | `spark.conf.set(...)` / `spark.conf.get(...)` |

`spark.conf.get("trident.workspace.id")` also returns the workspace ID but is internal Spark conf, not documented surface, and is unavailable in pure-Python notebooks. Prefer `notebookutils.runtime.context` for identity lookups; reserve `spark.conf.*` for session tuning.

## Lakehouse Setup

- **`enableSchemas` is set at lakehouse creation time only** — cannot be retrofitted. Without it the lakehouse only has the default `dbo` schema and you must recreate to gain named schemas. Set via `creationPayload: { "enableSchemas": true }` on `POST /workspaces/{ws}/items` (see fabric-rest-api skill).
- Schemas use lowercase names by convention (`bronze`/`silver`/`gold` for medallion). `DROP SCHEMA <name> CASCADE` removes the schema with all its tables.
- **Cross-lakehouse Spark SQL** uses 3-part names: `lakehouse.schema.table` for same-workspace, `workspace.lakehouse.schema.table` for cross-workspace. Verify access permissions on each lakehouse.
- Lakehouse delete cascades irreversibly: SQL Endpoint deleted, all OneLake data permanently removed, shortcuts pointing in become inaccessible, dependent notebooks fail at runtime.
- **Shortcuts as definition payload**: when authoring a Lakehouse via REST, `shortcuts.metadata.json` is an array of `{name, path, target}` objects. Supported `target.type` values: `OneLake`, `AdlsGen2`, `AmazonS3`, `GoogleCloudStorage`, `S3Compatible`, `Dataverse`. Each target type has its own connection properties (see fabric-rest-api skill).

## Lakehouse Table Maintenance (impacts SQL Endpoint performance)

- Run `OPTIMIZE` regularly to compact small files (target 128 MB – 1 GB per file)
- Run `VACUUM` to remove unreferenced files
- V-Order write optimization is default — do not disable
- Avoid high-cardinality partition columns; aim for partitions ≥ 1 GB
- SQL Endpoint metadata sync lag is normally < 1 minute but increases with: many lakehouses per workspace, small-file fragmentation, large ETL volume, or SQLEP idle > 15 min (this describes the legacy background sync)

### New SQL analytics endpoint metadata sync (PREVIEW, May 2026)

Opt-in faster sync that keeps data queryable within seconds of landing. **Preview** — and applies to **NEW SQL analytics endpoints only**: existing endpoints in the workspace stay on the legacy sync above.

- **Enable**: Workspace settings → Warehouse → New metadata sync (preview). Only endpoints created *after* enabling get the new sync.
- **Architecture**: external-tables-based Delta-log parsing with decoupled schema-vs-data change detection (schema changes and data changes refresh separately), plus a periodic background refresh and on-demand refresh when a read query hits stale data.
- **New DMV** `sys.dm_db_external_tables_log_status` — `last_update_time_utc`, `latest_log_version`, `latest_checkpoint_version`, `is_blocked` (`1` = last update blocked, `0` = succeeded).
- **Targeted manual refresh** (new-sync endpoints only, for data-only changes):

  ```sql
  EXEC sys.sp_dw_refresh_ext_table 'dbo.<table>';
  ```

  For schema changes (add/drop tables or columns, type changes) use the full-item Refresh SQL endpoint metadata REST API instead.
- **Limitations**: no support for multi-part checkpoint (a deprecated Delta feature — tables containing them fail to update); cannot be enabled when the workspace uses workspace private link.

## Notebook REST API / UI Upload

When creating notebooks via REST API, every code cell must include `"outputs": []` and `"execution_count": null`.

**Cell `source` must be an array of strings, not a bare string.** nbformat permits either, but Fabric's UI upload (`createArtifact`) and the REST definition APIs reject the bare-string form with a generic `400 exceptionCulprit:1` that gives no clue which field is wrong. Split on `\n` and append `\n` to every line except the last — the standard nbformat convention:

```json
"source": ["line one\n", "line two\n", "last line"]
```

Not:

```json
"source": "line one\nline two\nlast line"
```

Applies to every cell in the notebook, markdown and code. A single bare-string source anywhere in the file fails the whole upload.

**Default lakehouse binding** uses `metadata.dependencies.lakehouse` in the notebook content — auto-mounts at runtime so `spark.read.table("schema.table")` resolves without 3-part naming:

```json
{
  "metadata": {
    "dependencies": {
      "lakehouse": {
        "default_lakehouse": "<lakehouse-id>",
        "default_lakehouse_workspace_id": "<workspace-id>",
        "default_lakehouse_name": "<lakehouse-name>"
      }
    }
  }
}
```

One default lakehouse per notebook. Additional lakehouses are reachable via 3-part names (see Lakehouse Setup).

### Definition API gotchas

- `getDefinition` is a POST, not GET — empty body returns **HTTP 411 Length Required**. Always send `'{}'` as the body.
- After 202 + `Location` header, poll `GET {Location}` until `Succeeded`, then call **`GET {Location}/result`** (note the `/result` suffix) to retrieve the actual content. Without `/result` the operation reports `Succeeded` but returns no payload.
- `updateDefinition?updateMetadata=true` requires a `.platform` part in `definition.parts`; the flag without `.platform` returns 400. For content-only updates omit the flag entirely.
- Conversely, **omitting `?updateMetadata=true` silently ignores any `.platform` part** in your payload — `displayName`/`description` won't update.

## Notebook execution via REST

`POST /v1/workspaces/{ws}/items/{itemId}/jobs/instances?jobType=RunNotebook` (see fabric-rest-api skill for the full jobType table).

- **`defaultLakehouse` requires both `id` AND `name`** in the execution config. Supplying only `id` returns 400 — common cause of "DefaultLakehouse: missing name" errors.
- **Pool selection** via `executionData.configuration`: `useStarterPool: true` (dev/shared), `useWorkspacePool: true` (prod), or a custom pool name (high-memory/GPU). Starter pool falls back when the workspace pool is at capacity.
- **Job states**: `NotStarted → Running → Completed | Failed | Cancelled`. Poll `GET {Location}` from the 202 response, or `GET .../jobs/instances/{jobInstanceId}` if you captured the ID.
- **Never retry POST after a network/timeout error.** Query `GET .../jobs/instances` filtered to the last 5 minutes first; if a recent run exists, monitor that. Retrying creates duplicate runs and burns CUs.
- Job stuck in `NotStarted` longer than ~2 minutes usually means pool warm-up or capacity SKU contention, not a notebook bug.

### In-notebook auto-restart (`%%configure retriableOptions`)

For pipeline-driven notebook runs, the notebook itself can opt into automatic restart after system failures using `%%configure` (April 2026):

```python
%%configure
{
  "retriableOptions": {
    "enabled": true,
    "maxAttempt": 3
  }
}
```

`enabled` is the on/off switch; `maxAttempt` (singular) caps total attempts. Place it as the first cell, same as any other `%%configure`. This complements — does **not** replace — the pipeline activity-level retry; configure one layer or the other to avoid stacking retries that multiply CU consumption.

Distinct from the "never retry POST" rule above: that rule applies to **external orchestrators** submitting jobs via REST; `retriableOptions` is evaluated **inside** Fabric's notebook runtime. New feature — verify the schema against current Microsoft Learn before relying on it in production.

## Other Spark item definitions

### SparkJobDefinition

| Format | Required parts |
|---|---|
| `SparkJobDefinitionV1` | `SparkJobDefinitionV1.json` |
| `SparkJobDefinitionV2` | `SparkJobDefinitionV1.json` (yes — the file name still says V1 in V2 format), plus `Main/<file>` and optional `Libs/<file>` |

V2 only accepts `.py` and `.R` files in `Main/` and `Libs/` — **JAR files are not supported in V2 parts**. The JSON schema includes `executableFile`, `defaultLakehouseArtifactId`, `mainClass`, `additionalLakehouseIds`, `commandLineArguments`, `additionalLibraryUris`, `language`, `environmentArtifactId`.

### Environment

Default format (omit `format` or set to `null`). Key parts:

| Part Path | Content |
|---|---|
| `Libraries/PublicLibraries/environment.yml` | Conda / pip dependencies |
| `Setting/Sparkcompute.yml` | Pool config: `driver_cores`, `driver_memory`, `executor_cores`, `executor_memory`, `dynamic_executor_allocation` (`min_executors` / `max_executors`), `runtime_version` |
| `Libraries/CustomLibraries/<name>.{jar\|py\|whl\|tar.gz}` | Custom user uploads — JAR + Python + wheel + R archive all supported here (unlike SparkJobDefinition V2 `Main`/`Libs`) |

## Reference

- Microsoft Learn: [What is a lakehouse in Microsoft Fabric?](https://learn.microsoft.com/fabric/data-engineering/lakehouse-overview)
- Microsoft Learn: [Apache Spark compute in Microsoft Fabric](https://learn.microsoft.com/fabric/data-engineering/spark-compute)
- Microsoft Learn: [NotebookUtils (formerly MSSparkUtils) for Fabric](https://learn.microsoft.com/fabric/data-engineering/notebook-utilities)
- Comprehensive MS Learn link bundle (concept / notebooks / lakehouse / performance / SJD / environments / runtime / best practices): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-rest-api skill — notebook definition upload API and LRO pattern
- fabric-error-handling skill — Tier 1/2 convention for notebook code
- fabric-monitoring skill — Query Insights for SQLEP queries against lakehouse tables
