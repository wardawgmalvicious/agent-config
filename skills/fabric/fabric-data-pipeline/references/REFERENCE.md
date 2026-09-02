# Fabric Data Pipeline — reference

Long-form detail behind [`SKILL.md`](../SKILL.md). Field tables are
transcribed from the [DataPipeline definition
reference](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/datapipeline-definition);
enum values and limits were cross-checked against live Git-synced
exports on 2026-09-02.

## `DataPipelineActivityTypes` — the full enum

36 values. The ones marked **Fabric** have no Azure Data Factory
equivalent and are where an ADF-trained assumption goes wrong.

| `type` | What it does |
| --- | --- |
| `Copy` | Copies data from a source to a destination |
| `Lookup` | Retrieves data for use in later activities |
| `GetMetadata` | Retrieves metadata from a data source |
| `Delete` | Deletes data from a data source |
| `Script` | Executes custom scripts (PowerShell, Python, …) |
| `SqlServerStoredProcedure` | Executes a stored procedure in SQL Server |
| `KustoQueryLanguage` | Executes a KQL query on Azure Data Explorer |
| `IfCondition` | Branches on a conditional expression |
| `Switch` | Branches on a switch expression |
| `ForEach` | Iterates a collection |
| `Until` | Repeats until a condition is met |
| `Filter` | Filters an array on a condition |
| `Wait` | Pauses execution for a duration |
| `Fail` | Explicitly fails the pipeline with a message and error code |
| `SetVariable` | Sets an existing variable |
| `AppendVariable` | Appends to an existing array variable |
| `ExecutePipeline` | Executes another pipeline as a nested activity |
| `InvokePipeline` | **Deprecated** — use `ExecutePipeline` |
| `TridentNotebook` | **Fabric.** Executes a Fabric (Trident) notebook |
| `SparkJobDefinition` | **Fabric.** Executes a Spark job definition |
| `InvokeCopyJob` | **Fabric.** Invokes a Copy Job item |
| `RefreshDataFlow` | **Fabric.** Refreshes a dataflow |
| `PBISemanticModelRefresh` | **Fabric.** Refreshes a Power BI semantic model |
| `DatabricksNotebook` | Databricks notebook / Spark JAR / Spark Python |
| `AzureHDInsight` | Hive, Pig, MapReduce, Streaming or Spark on HDInsight |
| `AzureMLExecutePipeline` | Azure ML batch execution / update resource / pipeline |
| `AzureFunction` | Executes an Azure Function |
| `Custom` | Azure Batch — a custom command |
| `ExecuteSSISPackage` | Executes an SSIS package |
| `DataLakeAnalyticsScope` | Runs a Scope script on Data Lake Analytics |
| `WebActivity` | HTTP request to an external service |
| `WebHook` | Calls a webhook and waits for a callback |
| `Office365Email` | Sends mail via Office 365 |
| `Email` | Sends an email notification |
| `MicrosoftTeams` | Posts to Microsoft Teams |
| `Teams` | Posts to Teams |

## `typeProperties` — the Fabric-specific activities

Only these five are transcribed. Copy activity internals
(`CopySource`, `CopySink`, `CopyTranslator`, `TypeConversionSettings`,
`StagingSettings`, `DatasetSettings`) and per-connector properties are
**not covered by this skill** — go to the definition reference.

### `TridentNotebook`

| Field | Type | Required |
| --- | --- | --- |
| `notebookId` | String | yes |
| `workspaceId` | String | yes |
| `parameters` | Object | no |
| `sessionTag` | String | no |

`parameters` entries are doubly wrapped — an outer `{value, type}` where
the inner `value` is itself an Expression object:

```json
"parameters": { "DRY_RUN": {
  "value": { "value": "@pipeline().parameters.DryRun", "type": "Expression" },
  "type": "bool" } }
```

A parameter the notebook does not declare is ignored; a declared
parameter left unset takes the notebook's own default. `sessionTag`
shares one Spark session across activities carrying the same tag, which
removes per-activity session start-up cost.

`externalReferences` is optional here.

### `ExecutePipeline`

| Field | Type | Required |
| --- | --- | --- |
| `pipeline` | `PipelineReference` | yes |
| `parameters` | Object | no |
| `waitOnCompletion` | Boolean | no — **default `true`** |

`PipelineReference` is `{ "referenceName": "<pipeline name>", "type":
"PipelineReference" }`. `policy` is marked **required** on this activity.

### `InvokePipeline` (deprecated)

| Field | Type | Required |
| --- | --- | --- |
| `workspaceId` | String | no |
| `pipelineId` | String | no |
| `operationType` | String | no — `InvokeFabricPipeline` in practice |
| `parameters` | Object | no |
| `waitOnCompletion` | Boolean | no — **default `false`** |

`externalReferences` is **required** here. The GUID pair is what makes
this form parameterizable from a Variable Library item reference:

```json
"pipelineId":  { "value": "@pipeline().libraryVariables.ItemRefChild.itemId",      "type": "Expression" },
"workspaceId": { "value": "@pipeline().libraryVariables.ItemRefChild.workspaceId", "type": "Expression" }
```

`ExecutePipeline` has no equivalent — it binds by name. That is the
substance of the migration, not the type string.

### `SqlServerStoredProcedure`

| Field | Type | Required |
| --- | --- | --- |
| `storedProcedureName` | String | yes |
| `database` | String | no |
| `storedProcedureParameters` | Object | no |

Accepts `externalReferences`, `linkedService` and `connectionSettings`.

### `PBISemanticModelRefresh`

| Field | Type | Required |
| --- | --- | --- |
| `groupId` | String | no — workspace ID |
| `workspaceId` | String | no |
| `datasetId` | String | no |
| `method` | String | no |
| `type` | String | no — refresh type |
| `commitMode` | String | no |
| `maxParallelism` | Integer | no |
| `retryCount` | Integer | no |
| `objects` | Array | no — table/partition scope |
| `waitOnCompletion` | Boolean | no — **default `false`** |
| `operationType` | String | no |
| `inputs` | `LogicAppsActivityInput` | no |

`externalReferences` is **required** — a Power BI connection.

`objects` scopes the refresh to named tables or partitions instead of
the whole model, and takes an expression, so the set can be computed
upstream:

```json
"objects": { "value": "@activity('FilterChangedTables').output.Value", "type": "Expression" }
```

`commitMode: "Transactional"` makes the refresh all-or-nothing.
`retryCount` here is the *refresh's* retry, distinct from
`policy.retry`, which retries the activity.

## Activity `policy`

| Field | Type | Default | Range |
| --- | --- | --- | --- |
| `timeout` | String / Expression | 7 days when absent; portal writes `0.12:00:00` | max 7 days |
| `retry` | Integer / Expression | 0 in schema, 1 in the portal | 1–1000 |
| `retryIntervalInSeconds` | Integer | 30 | 30–86400 |
| `secureInput` | Boolean | false | — |
| `secureOutput` | Boolean | false | — |
| `retryConditions` | Expression | none — retries on all failures | preview |

`timeout` pattern: `((\d+).)?(\d\d):(\d\d):(\d\d)`, i.e. `D.HH:MM:SS`.

**Retry interval types.** The portal offers Fixed (default — the same
wait every attempt) and Increasing Delay (exponential back-off: each
retry waits a random interval from a range that doubles per attempt,
bounded by a configured maximum). The randomization is deliberate — it
stops concurrent pipeline retries from colliding on the same upstream
system.

**`retryConditions` matching fields** are error message, failure type
(user vs system error) and error code, combined with And/Or. The common
case is `Error code contains 429` for rate limiting. Supported on Copy,
Notebook, Dataflow and Stored procedure activities only.

## `.schedules` — full schema

Declared `$schema`:
`https://developer.microsoft.com/json-schemas/fabric/gitIntegration/schedules/1.0.0/schema.json`

Top level is `{ "schedules": [ … ] }`. Each entry:

| Field | Notes |
| --- | --- |
| `enabled` | Boolean. Survives deployment — a disabled schedule promotes disabled |
| `jobType` | `"Execute"` for pipelines. The schema declares **no enum**, so treat this as observed rather than validated |
| `configuration` | Below; `type` is the only schema-required field |
| `parameters` | Array. Values passed to the pipeline at trigger time |

`configuration` fields, by `type`:

| Field | `Cron` | `Daily` | `Weekly` | `Monthly` |
| --- | --- | --- | --- | --- |
| `startDateTime` | ✓ | ✓ | ✓ | ✓ |
| `endDateTime` | ✓ | ✓ | ✓ | ✓ |
| `localTimeZoneId` | ✓ | ✓ | ✓ | ✓ |
| `interval` (minutes) | ✓ | — | — | — |
| `times[]` (`hh:mm`, ≤ 100) | — | ✓ | ✓ | ✓ |
| `weekdays[]` (≤ 7) | — | — | ✓ | — |
| `recurrence` | — | — | — | ✓ |
| `occurrence` | — | — | — | ✓ |

`occurrence` is `{ occurrenceType (required), dayOfMonth, weekIndex,
WeekDay }` — note the capitalized `WeekDay`.

The schema marks only `configuration.type` required; the portal requires
both `startDateTime` and `endDateTime` and offers no open-ended option.

### Worked examples

```json
{ "enabled": true, "jobType": "Execute", "configuration": {
    "type": "Cron", "interval": 15,
    "startDateTime": "2026-01-01T00:00:00", "endDateTime": "9999-12-31T23:59:00",
    "localTimeZoneId": "Eastern Standard Time" } }
```

```json
{ "enabled": true, "jobType": "Execute", "configuration": {
    "type": "Daily", "times": [ "01:00" ],
    "startDateTime": "2026-01-01T00:00:00", "endDateTime": "9999-12-31T23:59:00",
    "localTimeZoneId": "Eastern Standard Time" } }
```

```json
{ "enabled": true, "jobType": "Execute", "configuration": {
    "type": "Weekly", "times": [ "06:00" ],
    "weekdays": [ "Monday", "Tuesday", "Wednesday", "Thursday", "Friday" ],
    "startDateTime": "2026-01-01T00:00:00", "endDateTime": "9999-12-31T23:59:00",
    "localTimeZoneId": "Eastern Standard Time" } }
```

```json
{ "enabled": true, "jobType": "Execute", "configuration": {
    "type": "Monthly", "times": [ "00:15" ], "recurrence": 1,
    "occurrence": { "occurrenceType": "DayOfMonth", "dayOfMonth": 1 },
    "startDateTime": "2026-08-01T00:00:00", "endDateTime": "9999-12-31T23:59:00",
    "localTimeZoneId": "Eastern Standard Time" } }
```

**Interval-based schedules (preview)** are a separate portal option, not
one of the four types above. Selecting one adds `Window start time` and
`Window end time` to the pipeline's expression builder under **Trigger
parameters**.

## Microsoft Learn links

### Definition and activities

- [DataPipeline definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/datapipeline-definition) — schema of record for every field above
- [Activity overview](https://learn.microsoft.com/fabric/data-factory/activity-overview) — general settings, the 120-activity cap, deactivation semantics
- [Activity retries](https://learn.microsoft.com/fabric/data-factory/activity-retries) — retry counts, interval types, preview retry conditions
- [Debug pipelines in Microsoft Fabric](https://learn.microsoft.com/fabric/data-factory/how-to-debug-pipelines-in-microsoft-fabric) — the iterative deactivate-and-reactivate workflow

### Scheduling

- [Job scheduler in Microsoft Fabric](https://learn.microsoft.com/fabric/fundamentals/job-scheduler) — `.schedules` in CI/CD, scheduler auto-disable, the uncommitted-on-enable note
- [Run, schedule, or use events to trigger a pipeline](https://learn.microsoft.com/fabric/data-factory/pipeline-runs) — mandatory start/end dates, the 20-schedule cap, interval-based schedules
- [Fabric CI/CD concepts and best practices](https://learn.microsoft.com/fabric/fundamentals/understand-best-practices-fabric-cicd) — `.schedules` as part of a data-orchestration strategy

### CI/CD

- [CI/CD for pipelines in Data Factory](https://learn.microsoft.com/fabric/data-factory/cicd-pipelines) — the known-limitations list (dataflow rebinding, OAuth connectors, workspace variables)
- [Variable library integration with pipelines](https://learn.microsoft.com/fabric/data-factory/variable-library-integration-with-data-pipelines) — the `libraryVariables` consumer side; property access for connection and item references

### Error handling

- [Errors and conditional execution](https://learn.microsoft.com/azure/data-factory/tutorial-pipeline-failure-error-handling) — Try-Catch / Do-If-Else patterns and the four conditional paths. Authored for ADF, applies unchanged
- [Fail activity](https://learn.microsoft.com/fabric/data-factory/fail-activity) — deliberate failure with a message and error code
