# Copy job — reference

Full connector matrix, definition payload examples, and the end-to-end REST workflow. The tight operational summary is in [../SKILL.md](../SKILL.md).

## Status summary (verify before quoting to a client)

| Capability | Status |
|---|---|
| Copy job item (`CopyJob`) | GA |
| Full copy / watermark-based incremental | GA |
| CDC replication (`jobMode: "CDC"`) | **Preview** |
| Auto-partitioning | **Preview** |
| Activator invocation of a Copy job | **Preview** |
| Fabric Lakehouse table as CDC source/dest | **Preview** |

The drift audit that spawned this skill said "CDC for SQL estates GA." The connectors doc page still titles the section **"CDC Replication (Preview)."** Treat CDC as Preview until the connectors page and per-connector tutorial titles drop the label.

## CDC connector matrix (Preview)

| Connector | CDC Source | CDC Destination | SCD Type 2 |
|---|---|---|---|
| Azure SQL DB | ✅ | ✅ | ✅ |
| Azure SQL Managed Instance | ✅ | ✅ | ✅ |
| On-premises SQL Server | ✅ | ✅ | ✅ |
| Fabric Lakehouse table (Preview) | ✅ | ✅ | ✅ |
| Fabric Data Warehouse | ❌ | ✅ | ❌ |
| Oracle (Preview) | ✅ | ❌ | ❌ |
| Google BigQuery (Preview) | ✅ | ❌ | ❌ |
| SAP Datasphere Outbound (ADLS Gen2) | ✅ | ❌ | ❌ |
| Snowflake | ✅ (own tutorial) | — | — |

**SQL family = the only full-loop CDC path** (source + destination + SCD2). Everything else is source-only or destination-only.

## Watermark / incremental notes

- Watermark column types: **ROWVERSION, datetime, date, integer, string interpreted as datetime**.
- The **ODBC connector with native incremental copy** works only for the Microsoft SQL family: Amazon RDS for SQL Server, Azure SQL DB, Azure SQL MI, Azure Synapse (SQL Pool), Fabric Warehouse, on-prem SQL Server.
- **Auto-partitioning (Preview)** — watermark-based only (both initial full + incremental). Supported on: Amazon RDS for SQL Server, Azure SQL DB, Azure Synapse (SQL Pool), Fabric Data Warehouse, SQL DB in Fabric, SQL Server, Azure SQL MI, Oracle, SAP HANA, Fabric Lakehouse tables. Advanced settings toggle.
- File-based incremental uses the file **last-modified timestamp** as the watermark.

## Definition — `copyjob-content.json`

Minimal skeleton (before base64):

```json
{
  "properties": {
    "jobMode": "Batch",
    "source": {
      "type": "AzureSqlDatabase",
      "connectionSettings": {
        "type": "AzureSqlDatabase",
        "typeProperties": { "database": "salesdb" },
        "externalReferences": { "connection": "<source-connectionId>" }
      }
    },
    "destination": {
      "type": "LakehouseTable",
      "connectionSettings": {
        "type": "Lakehouse",
        "typeProperties": {
          "workspaceId": "<workspace-guid>",
          "artifactId": "<lakehouse-guid>",
          "rootFolder": "Tables"
        }
      }
    },
    "policy": { "timeout": "0.12:00:00" }
  },
  "activities": [
    {
      "id": "<activity-guid>",
      "properties": {
        "source": { "datasetSettings": { "schema": "dbo", "table": "Customers" } },
        "destination": {
          "writeBehavior": "Overwrite",
          "datasetSettings": { "table": "Customers" }
        }
      }
    }
  ]
}
```

- **`jobMode`**: `"Batch"` (full / watermark incremental) or `"CDC"`.
- **`writeBehavior`** (per activity destination): `"Overwrite"` (full), `"Merge"` (CDC / upsert), append is the default.
- **Column mapping** (optional) goes in `activities[].properties.translator` (`type: "TabularTranslator"`, `mappings[]` with `source`/`destination` `name`/`type`/`physicalType`) plus `typeConversionSettings` (`allowDataTruncation`, `treatBooleanAsNumber`).
- To flip a job to CDC: set `properties.jobMode = "CDC"` and each activity's `destination.writeBehavior = "Merge"`.

## Create / update wrapper payload

`updateDefinition` **replaces** the definition — send every content part you want to keep.

```json
{
  "displayName": "CopyJob 1",
  "description": "A Copy job description.",
  "definition": {
    "parts": [
      { "path": "copyjob-content.json", "payload": "<base64>", "payloadType": "InlineBase64" },
      { "path": ".platform",           "payload": "<base64>", "payloadType": "InlineBase64" }
    ]
  }
}
```

## REST endpoints (base `https://api.fabric.microsoft.com`)

| Operation | Method + path |
|---|---|
| Create (empty) | `POST /v1/workspaces/{wsId}/copyJobs` |
| Create (with definition) | `POST /v1/workspaces/{wsId}/copyJobs` (+ `definition`) |
| Get | `GET /v1/workspaces/{wsId}/copyJobs/{id}` |
| Get definition | `POST /v1/workspaces/{wsId}/copyJobs/{id}/getDefinition` |
| List | `GET /v1/workspaces/{wsId}/copyJobs` |
| Update props | `PATCH /v1/workspaces/{wsId}/copyJobs/{id}` |
| Update definition | `POST /v1/workspaces/{wsId}/copyJobs/{id}/updateDefinition` |
| Delete | `DELETE /v1/workspaces/{wsId}/copyJobs/{id}` |
| **Run on demand** | `POST /v1/workspaces/{wsId}/items/{id}/jobs/instances?jobType=Execute` → 202 |
| Get run instance | `GET /v1/workspaces/{wsId}/copyJobs/{id}/jobs/instances/{jobInstanceId}` |
| Cancel run | `POST /v1/workspaces/{wsId}/copyJobs/{id}/jobs/instances/{jobInstanceId}/cancel` |
| Create schedule | `POST /v1/workspaces/{wsId}/items/{id}/jobs/{jobType}/schedules` |

**Run trigger = `jobType=Execute`** (gotcha). The *returned* instance object reports `jobType: "CopyJob"`, `invokeType: "Manual"`, `status`, `startTimeUtc`, `endTimeUtc`, `failureReason`.

Schedule payload (Cron, minute interval):
```json
{
  "enabled": true,
  "configuration": {
    "startDateTime": "2025-07-01T08:00:00",
    "endDateTime": "2025-12-31T23:59:00",
    "localTimeZoneId": "Central Standard Time",
    "type": "Cron",
    "interval": 60
  }
}
```
Manage/disable an existing schedule via the Job Scheduler **Update Item Schedule** API (`"enabled": false`). A single Copy job can hold **multiple schedules**.

## End-to-end REST workflow

1. **Get token** — Entra token for `api.fabric.microsoft.com`, scopes `Workspace.ReadWrite.All`, `Item.ReadWrite.All` (SPN supported). See fabric-auth skill.
2. **Create connections** — `POST /v1/connections` for source + destination; save each `id`.
3. **Create Copy job with definition** — reference those connection IDs in `externalReferences.connection`; base64 the `copyjob-content.json`.
4. **Enable a schedule** — `POST .../jobs/{jobType}/schedules` with `"enabled": true`, or run once via `jobType=Execute`.

## fabric-data-factory-mcp tools

`dnx Microsoft.DataFactory.MCP --prerelease` (0.x beta). Copy-job surface:

| Tool | Purpose |
|---|---|
| `create_copy_job` | Create item (± definition) |
| `update_copy_job` | Update name/description |
| `get_copy_job` | Read item props |
| `get_copy_job_definition` | Read `copyjob-content.json` |
| `update_copy_job_definition` | Replace definition |
| `list_copy_jobs` | Enumerate in workspace |
| `run_copy_job` | On-demand run |
| `get_copy_job_run_status` | Poll a run |
| `create_copy_job_schedule` | Add a schedule |
| `list_copy_job_schedules` | Enumerate schedules |

## Requirements & limits

- Workspace must be on a **supported Fabric capacity** for CRUD on a Copy job (non-Power-BI item).
- SPN auth supported for connections and API calls.
- CDC known limits: **net change only** (no full change history yet); **default capture instance only**; mixing CDC + non-CDC tables in one job **demotes all to watermark**; Lakehouse CDF-enabled state not auto-detected.

## Source docs

- [What is Copy job](https://learn.microsoft.com/fabric/data-factory/what-is-copy-job)
- [Learn how to create a Copy job](https://learn.microsoft.com/fabric/data-factory/create-copy-job)
- [Incremental copy in Copy job](https://learn.microsoft.com/fabric/data-factory/incremental-copy-job)
- [CDC in Copy job](https://learn.microsoft.com/fabric/data-factory/cdc-copy-job) (+ per-connector: azure-sql-database, oracle, snowflake, bigquery)
- [Connectors for Copy job](https://learn.microsoft.com/fabric/data-factory/copy-job-connectors)
- [REST API capabilities](https://learn.microsoft.com/fabric/data-factory/copy-job-rest-api-capabilities)
- [Copy job definition schema](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/copyjob-definition)
- [Copy job pricing](https://learn.microsoft.com/fabric/data-factory/pricing-copy-job)
- [Trigger Fabric items (Activator)](https://learn.microsoft.com/fabric/real-time-intelligence/data-activator/activator-trigger-fabric-items)
