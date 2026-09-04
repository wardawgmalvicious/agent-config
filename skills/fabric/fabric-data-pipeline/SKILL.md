---
name: fabric-data-pipeline
description: "Use for Microsoft Fabric Data Pipeline item definitions in Git — `pipeline-content.json`, `.platform`, `.schedules`. Covers the envelope (`properties.activities`, plus the `parameters`, `variables` and `libraryVariables` the REST schema omits), `dependsOn` conditions, the activity-type enum and Fabric-specific `typeProperties` (`TridentNotebook`, `PBISemanticModelRefresh`, `SqlServerStoredProcedure`, `ExecutePipeline`), `InvokePipeline` deprecated for `ExecutePipeline` and the GUID-vs-`referenceName` rebinding that migration forces, activity `policy` (the portal's 12-hour timeout vs the 7-day default when absent; preview `retryConditions`, whose interval elapses before the condition is tested), deactivation via `state: Inactive` + `onInactiveMarkAs`, the 120-activity cap, and `.schedules` — `jobType: Execute`, Cron/Daily/Weekly/Monthly where Cron is an interval in minutes, the mandatory end date that silently expires a schedule, and scheduler auto-disable after consecutive failures."
disable-model-invocation: false
model: inherit
# effort:  # inherits the session level
paths:
  - "**/*.DataPipeline/**"
---

# Fabric Data Pipeline definitions

Covers the **Git-serialized** form of a DataPipeline item — the JSON an
agent edits when there is no portal to validate against.

**Not here, deliberately:** expression syntax (`@concat`, `coalesce`,
the ForEach variable race) belongs to the `coding-expressions` rule,
which globs the same file and always co-loads. Connection rebinding
across environments belongs to `fabric-cicd`. The `libraryVariables`
block's own mechanics belong to `fabric-variable-library`. Copy activity
source/sink/dataset internals are not covered at all.

## 1. What Git holds

| File | Required | What it is |
| --- | --- | --- |
| `pipeline-content.json` | yes | The pipeline: activities, parameters, variables |
| `.platform` | no | Item metadata — `displayName`, `logicalId` |
| `.schedules` | no | Job-scheduler triggers, one file per item |

Serialization mechanics (EOF newlines, CRLF/LF, `.gitattributes`) are in
the `fabric-git-serialization` rule, which globs this folder too.

## 2. The definition envelope

```json
{ "properties": {
    "activities": [ ... ],
    "parameters":       { "DryRun": { "type": "bool", "defaultValue": false } },
    "variables":        { "ChangedEntities": { "type": "Array", "defaultValue": [] } },
    "libraryVariables": { "EnvSuffix": { "type": "String",
        "variableName": "EnvironmentSuffix", "libraryName": "MyVarLib" } }
} }
```

**The REST schema page documents only `activities` and `description`.**
Every real pipeline also carries `parameters`, `variables` and
`libraryVariables` at that level. The page is incomplete — do not
"correct" a file by deleting them (verified against live exports
2026-09-02).

- `parameters` — set at trigger time, immutable during the run.
- `variables` — mutable, **pipeline-scoped, not iteration-scoped**.
- `libraryVariables` — Variable Library bindings; see
  `fabric-variable-library`. Read with
  `@pipeline().libraryVariables.<alias>`, and for the advanced types
  append `.connectionId`, `.itemId` or `.workspaceId`.

## 3. Activity anatomy

```json
{ "name": "IngestSource", "type": "TridentNotebook",
  "description": "…", "state": "Inactive", "onInactiveMarkAs": "Succeeded",
  "dependsOn": [ { "activity": "LookupConfig",
                   "dependencyConditions": [ "Succeeded" ] } ],
  "policy": { "timeout": "0.02:00:00", "retry": 1 },
  "typeProperties": { ... },
  "externalReferences": { "connection": "<guid or expression>" } }
```

`name` and `type` are required; `typeProperties` is required and its
shape is type-specific. `dependencyConditions` are `Succeeded`,
`Failed`, `Skipped`, `Completed` — an activity with several `dependsOn`
entries waits for **all** of them.

`externalReferences.connection` is a single connection GUID. It is not
source-controlled meaningfully across workspaces — parameterize it
(`fabric-cicd`) or bind it to a Variable Library connection reference.

## 4. Activity types

The enum has 36 entries; the full table is in
[references/REFERENCE.md](references/REFERENCE.md). The Fabric-specific
ones and their required `typeProperties`:

| `type` | Required `typeProperties` | Notes |
| --- | --- | --- |
| `TridentNotebook` | `notebookId`, `workspaceId` | `parameters`, `sessionTag` optional; a `sessionTag` shares one Spark session across activities |
| `ExecutePipeline` | `pipeline` (`PipelineReference`) | `waitOnCompletion` defaults **true** |
| `InvokePipeline` | — | **Deprecated.** `workspaceId` + `pipelineId`; `waitOnCompletion` defaults **false** |
| `SqlServerStoredProcedure` | `storedProcedureName` | `database`, `storedProcedureParameters` optional |
| `PBISemanticModelRefresh` | — | `groupId` + `datasetId`; `objects` scopes to partitions; `commitMode`, `maxParallelism` |
| `InvokeCopyJob` | — | Runs a Copy Job item |
| `RefreshDataFlow` | — | See the CI/CD trap in §8 |

**`InvokePipeline` is deprecated in favour of `ExecutePipeline`, and
migrating is a rebinding, not a rename.** Three things change together:

- `InvokePipeline` targets a child by **GUID pair** (`workspaceId` +
  `pipelineId`), which is what makes it parameterizable from a Variable
  Library item reference. `ExecutePipeline` targets by
  `pipeline.referenceName` — a **name**, with no workspace GUID.
- `waitOnCompletion` flips default: **false** on `InvokePipeline`,
  **true** on `ExecutePipeline`. Set it explicitly either way; a
  fire-and-forget orchestrator silently becomes blocking, or the
  reverse.
- Cross-workspace invocation is expressible in the GUID form and not in
  the name form.

So do not bulk-rewrite `InvokePipeline` activities. Set
`waitOnCompletion` explicitly and confirm the child resolves.

## 5. `policy`

```json
"policy": { "timeout": "0.02:00:00", "retry": 1, "retryIntervalInSeconds": 60,
            "secureInput": false, "secureOutput": false }
```

`timeout` is `D.HH:MM:SS`. **Two different defaults apply and both are
correct.** The portal stamps an explicit `"0.12:00:00"` (12 hours) on
every activity it creates. Omit `policy.timeout` entirely — as
hand-written or generated JSON does — and the schema default is **7
days**. Omitting the field is not "taking the default"; it is a 14x
increase over what the portal writes. Set it explicitly.

- `retry` — portal default 1, schema default 0, range 1–1000.
- `retryIntervalInSeconds` — default 30, **min 30, max 86400**.
- `secureInput` / `secureOutput` — keep values out of monitoring logs.
  Set on any activity handling secrets or connection strings.

**`retryConditions` is preview and has a trap.** It gates retries on
error message, failure type or error code, so a retry is not spent on an
error that will never resolve:

```json
"retryConditions": { "type": "Expression",
  "value": "@equals(activity('Ingest').Error.FailureType, 'SystemError')" }
```

- Supported on **Copy, Notebook, Dataflow and Stored procedure**
  activities only. On any other type it is silently inert.
- **The retry interval elapses before the condition is evaluated.** A
  1-hour interval with a condition that does not match still costs the
  full hour before the run moves on. Keep intervals short where a
  condition is in play.
- With no `retryConditions`, the activity retries on **every** failure.

## 6. Deactivate rather than delete

Fabric has no separate debug mode — deactivation *is* the debugging
mechanism, and Microsoft recommends it over deletion for preserving
structure.

```json
"state": "Inactive", "onInactiveMarkAs": "Succeeded"
```

| `onInactiveMarkAs` | Branch that runs |
| --- | --- |
| `Succeeded` (default) | `UponSuccess`, `UponCompletion` |
| `Failed` | `UponFailure`, `UponCompletion` |
| `Skipped` | `UponSkip` |

The dependency edge **is** honoured — the value above chooses which
branch fires. What does not exist is the activity's output: an inactive
activity never runs, so it has **no `Error` field and no output
fields**, and any downstream expression reading
`activity('Skipped').output…` fails. Deactivating one activity can break
an expression two steps away.

An inactive activity is also excluded from validation, which is what
makes it usable as a placeholder before its connections exist.

**Spelling:** real files use `"state": "Inactive"`. The REST schema page
writes `InActive` in its `ActivityState` table; that is a doc typo —
`Inactive` is what the portal emits and reads (checked against live
exports, 2026-09-02).

## 7. `.schedules`

Creating a schedule in the portal writes this file into the item
definition, so schedules deploy with the pipeline.

```json
{ "$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/schedules/1.0.0/schema.json",
  "schedules": [ { "enabled": true, "jobType": "Execute",
    "configuration": { "type": "Weekly",
      "startDateTime": "2026-08-17T00:00:00",
      "endDateTime": "9999-12-31T23:59:00",
      "localTimeZoneId": "Eastern Standard Time",
      "times": [ "06:00" ],
      "weekdays": [ "Monday", "Tuesday" ] } } ] }
```

`jobType` is `"Execute"` for a pipeline. **This is a different enum from
the run-on-demand REST API**, where a pipeline is `jobType: Pipeline`
(see `fabric-rest-api`). Do not copy one into the other.

`configuration.type` is `Cron`, `Daily`, `Weekly` or `Monthly`:

| Type | Fields |
| --- | --- |
| `Cron` | `interval` — **minutes**, not a cron expression |
| `Daily` | `times[]` (`hh:mm`, ≤ 100) |
| `Weekly` | `times[]` + `weekdays[]` |
| `Monthly` | `times[]`, `recurrence`, `occurrence{occurrenceType, dayOfMonth \| weekIndex + WeekDay}` |

Four traps:

- **`endDateTime` is mandatory and there is no open-ended schedule.** A
  schedule silently stops firing at its end date with no error and no
  alert. Use a far-future sentinel — `9999-12-31T23:59:00`. Treat any
  end date within a few years as a bug.
- **`Cron` means a fixed interval in minutes.** It accepts no crontab
  expression. Anything calendar-shaped needs `Daily`/`Weekly`/`Monthly`.
- **The scheduler auto-disables after consecutive failures** (threshold
  varies by item, typically 10) and must be restarted by hand. A
  pipeline that "stopped running" after a bad week is this, not a
  schedule that was deleted.
- **First commit after enabling CI/CD is noisy.** Every item that
  already had a schedule shows as uncommitted. Review rather than
  bulk-committing.

Also: max **20 schedules** per pipeline; `enabled: false` is a real
state that survives deployment, so a disabled schedule promotes as
disabled.

## 8. CI/CD limitations specific to pipelines

Parameterisation and `parameter.yml` are `fabric-cicd`'s. These three
are pipeline-shaped and bite after promotion:

- **A promoted pipeline that invokes a dataflow still points at the
  source workspace's dataflow.** Dataflows are unsupported in deployment
  pipelines, and the reference is not rebound. Verify after every
  promotion.
- **Teams and Outlook activities need a manual sign-in per activity** in
  each target workspace — OAuth connections do not deploy.
- **Workspace variables are unsupported by CI/CD.**

## 9. Limits

| Limit | Value |
| --- | --- |
| Activities per pipeline | 120, inner container activities included |
| Schedules per pipeline | 20 |
| `retry` | 1–1000 |
| `retryIntervalInSeconds` | 30–86400 |
| `timeout` | max 7 days |
| `times[]` per schedule | 100 |

## Reference

- [DataPipeline definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/datapipeline-definition) — the authoritative schema
- [Activity overview](https://learn.microsoft.com/fabric/data-factory/activity-overview) — general settings, deactivation, the 120 cap
- [Activity retries](https://learn.microsoft.com/fabric/data-factory/activity-retries) — retry conditions and interval types
- Full activity-type enum, per-activity `typeProperties` tables, the
  complete `.schedules` schema and worked examples of all four
  configuration shapes: [references/REFERENCE.md](references/REFERENCE.md)
