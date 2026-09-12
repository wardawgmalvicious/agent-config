---
name: fabric-dataflow
description: "Use for the Fabric Dataflow Gen2 item (`Dataflow`): the `.Dataflow` folder's three definition parts — `mashup.pq` carrying `section Section1` and its `[StagingDefinition]` attribute, `queryMetadata.json` whose `formatVersion` accepts only `202502`, and `<name>.mdf` Mapping Data Flow transforms. Covers the typed `/dataflows` REST namespace and its permission split — List needs only viewer, but `getDefinition` needs read AND write; the execute job (`/jobs/execute/instances`, `Dataflow.Execute.All`, user identity only) and its `executeOption`, which defaults to `SkipApplyChanges` so a run silently skips unpublished edits; just-in-time publish and the February 2026 rule that a failed publish now fails the refresh; public parameters via `discover-dataflow-parameters`; variable libraries and relative references for CI/CD; and Gen1 upgrade — Save As versus the irreversible in-place Upgrade Wizard, the 50-query cap, and the legacy `PowerBI.Dataflows` connector that stops reading an upgraded dataflow."
when_to_use: "Fires on any file under `*.Dataflow/`, so `mashup.pq`, `queryMetadata.json` and `.platform` all match; `coding-m` and `fabric-git-serialization` co-load on the first two, and M style conventions are `coding-m`'s. The definition, REST surface, CI/CD patterns and upgrade routes, not the editor click-path. `fabric-rest-api`, `fabric-cli`, `fabric-cicd` and `fabric-variable-library` are reachable by name; for a pipeline's Dataflow activity open the `.DataPipeline` folder instead."
paths:
  - "**/*.Dataflow/**"
# model: inherit  # any model: value blocks Copilot slash invocation
# effort:  # inherits the session level
disable-model-invocation: false
---

# Fabric Dataflow Gen2 (the `Dataflow` item)

Dataflow Gen2 is the Power Query item in Fabric Data Factory: a low-code
transformation surface that ingests, reshapes and loads data without
code. This skill covers the item as **Git and REST see it** — the files
on disk, the API that writes them, and the limits that decide whether a
design works.

**The product name and the item type differ, and both are load-bearing.**
Everything a user types says *Dataflow Gen2*; the `.platform` file, the
`ItemType` enum and the REST namespace all say **`Dataflow`**. The Git
folder is `<display name>.Dataflow`.

**"Gen2" no longer implies a choice.** Since April 2026 the option to
create a Dataflow Gen2 *without* CI/CD and Git support is gone, and every
new item is created with it. Items created before that keep working, and
the docs still split behaviour by which kind you have — so when a page
says "applies to Dataflow Gen2 with CI/CD support", that is now the
default case and the non-CI/CD case is legacy.

## 1. What is on disk

| File | Required | Contents |
| --- | --- | --- |
| `mashup.pq` | yes | The Power Query document — every query, as M |
| `queryMetadata.json` | yes | Query options: load flags, groups, connections, compute settings |
| `<name>.mdf` | no | A Mapping Data Flow transform; there can be several |
| `.platform` | — | Item metadata — `displayName`, `logicalId` |

Serialization mechanics — EOF newlines, CRLF/LF, `.gitattributes` — are
in the `fabric-git-serialization` rule, which globs this folder too. M
style conventions are the `coding-m` rule's, which globs `mashup.pq`.
Neither is restated here.

## 2. `queryMetadata.json`

```json
{ "formatVersion": "202502", "name": "SampleDataflowGen",
  "computeEngineSettings": { "allowFastCopy": true, "maxConcurrency": 1 },
  "queriesMetadata": { "publicholidays": {
      "queryId": "…", "queryName": "publicholidays", "loadEnabled": true } },
  "connections": [ { "path": "Lakehouse", "kind": "Lakehouse",
      "connectionId": "{\"ClusterId\":\"…\",\"DatasourceId\":\"…\"}" } ] }
```

- **`formatVersion` accepts exactly one value, `202502`.** The docs say
  so outright. Treat any other value as a broken file.
- **`name` is the mashup name** and `queriesMetadata` is keyed by query
  name, with the key repeated inside as `queryName`.
- **Defaults that bite**: `loadEnabled`, `allowNativeQueries` and
  `allowFastCopy` all default **true**; `fastCombine`, `isHidden`,
  `skipAutomaticTypeAndHeaderDetection` and `parametric` default false.
- **`parametric`** is the flag behind public parameters mode (§8), and
  **`maxConcurrency`** caps concurrent evaluations for the whole item.

Full field table: [references/REFERENCE.md](references/REFERENCE.md).

## 3. `mashup.pq`

```m
[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared publicholidays =
let  Source = Lakehouse.Contents([]),
  #"Navigation 1" = Source{[workspaceId = "…"]}[Data],
  #"Changed column type" = Table.TransformColumnTypes(…)
in  #"Changed column type";
[ItemType = "MDF"]
shared #"MDF transform" = "___ExternalResource-Placeholder___";
```

Three things carry meaning beyond ordinary M:

- **The leading `[StagingDefinition = [Kind = "FastCopy"]]` attribute**
  sits above `section Section1;` and declares the staging kind.
- **Each query is a `shared` member** of `Section1`. Names with spaces
  take the `#"…"` form, as M requires.
- **An `[ItemType = "MDF"]` member is a placeholder, not a query.** Its
  value is the literal `"___ExternalResource-Placeholder___"`, and the
  real content lives in the matching `<name>.mdf` part. Removing the
  `.mdf` part without removing this member leaves a dangling reference.

An `.mdf` part is JSON: `properties.type` is `MappingDataFlow`, and
`typeProperties` carries `sources`, `sinks`, `transformations` and the
`scriptLines` array that holds the actual flow script. MDF transforms run
on Spark-backed compute and are **preview and not currently billed**.

## 4. The composite `connectionId`, and the gap underneath it

`connections[].connectionId` is **not a GUID**. It is a JSON object
serialized into a string:

```json
"connectionId": "{\"ClusterId\":\"b1b1…\",\"DatasourceId\":\"c2c2…\"}"
```

`path` and `kind` beside it identify the connector. `kind` is the **M
connector kind**, which is not the same spelling as a REST connection's
`connectionDetails.type`.

**No documented Fabric endpoint returns `ClusterId`.** The definition
format requires the value; the public REST surface does not hand it to
you. That is a real gap rather than a lookup this skill has omitted —
the only route known to work is an internal, undocumented Power BI v2.0
endpoint, which this skill does not use and does not recommend.

The practical consequence: **authoring a *bound* dataflow purely through
the definition API is not a supported path.** Create or bind connections
in the portal, then read the definition back to see the composite value.
An empty or absent `connections` array is not necessarily broken — a
query whose source is inline (`#table(…)`) has no external connection.

## 5. REST — the typed `/dataflows` namespace

```text
GET  /v1/workspaces/{wsId}/dataflows                       list
POST /v1/workspaces/{wsId}/dataflows                       create (±definition)
POST /v1/workspaces/{wsId}/dataflows/{id}/getDefinition    read definition
POST /v1/workspaces/{wsId}/dataflows/{id}/updateDefinition write definition
GET  /v1/workspaces/{wsId}/dataflows/{id}/parameters       discover parameters
POST /v1/workspaces/{wsId}/dataflows/{id}/jobs/execute/instances   run
```

**Permissions are not uniform, and the split is the thing to know:**

| Operation | Workspace role | Delegated scope | Service principal |
| --- | --- | --- | --- |
| List | **viewer** | `Workspace.Read.All` | yes |
| Create | **contributor** | `Dataflow.ReadWrite.All` | yes |
| `getDefinition` | — read **and write** | `Dataflow.ReadWrite.All` | yes |
| `updateDefinition` | — read **and write** | `Dataflow.ReadWrite.All` | yes |
| Discover parameters | — read | `Dataflow.Read.All` | yes |
| Execute | **member** | `Dataflow.Execute.All` | **no** |

**There is no read-only route to a definition.** `getDefinition` requires
write permission even though it only reads — the same shape
`fabric-activator` documents for `/reflexes`. Someone auditing
definitions across a tenant needs write access to every item they read.

Both definition calls support long-running operations and can answer
`202` with `Location`, `x-ms-operation-id` and `Retry-After` instead of
`200`. Create can answer `201` or `202`. Branch on the status code; see
the **fabric-rest-api skill** for the polling pattern.

**A generic route exists too** — `/v1/workspaces/{wsId}/items/{itemId}`
and `/items/{itemId}/getDefinition` — and the Dataflow public-APIs
article documents the item surface that way. One documented quirk: when
the type is not specified, the API returns the CI/CD flavour.

## 6. `updateDefinition` replaces everything — and takes `.platform`

The house-wide rule applies: **`updateDefinition` replaces the entire
definition, so send every part you want to keep.** Omitted parts are
dropped. See the **fabric-tmdl-api skill**, which owns this rule.

**Then the divergence worth the space.** `fabric-tmdl-api` says never
include `.platform` in a semantic-model definition payload. For a
Dataflow the documented sample does the opposite: it sends `.platform`
alongside the other parts, with `?updateMetadata=True`. Both statements
are correct for their own item type. Do not reconcile them into one rule.

`?updateMetadata` and the `.platform` part require each other — without
the flag a `.platform` part is ignored, and the flag without one returns
400. That pairing is `fabric-rest-api`'s.

Every part is base64 with `payloadType: "InlineBase64"`. A malformed body
returns `CorruptedPayload`.

## 7. Running one — three spellings, one operation

This is where most confusion starts, because the same run is documented
three ways:

| Form | Shape |
| --- | --- |
| Typed | `POST /v1/workspaces/{ws}/dataflows/{id}/jobs/execute/instances` |
| Generic, current | `POST /v1/workspaces/{ws}/items/{id}/jobs/{jobType}/instances` |
| Generic, legacy | `POST /v1/workspaces/{ws}/items/{id}/jobs/instances?jobType=…` |

The job type moved **from a query parameter into the path**; the query
form still works for backward compatibility. The typed route spells the
job `execute`, while the public-APIs article documents `Refresh` and
`Publish` on the generic route — and `ItemJobEventLogs` records exactly
those two, `Refresh` for a refresh and `Publish` for a just-in-time
publish. All three describe the same machinery.

Every form answers `202` with `Location` and `Retry-After`. Poll the job
instance at `/items/{id}/jobs/instances/{jobInstanceId}`; cancel at
`…/cancel`.

**`executeOption` decides whether your unpublished edits run, and the
docs disagree about its default.** The API reference marks
`SkipApplyChanges` as the default value; the CI/CD article reads as
though `ApplyChangesIfNeeded` is. **So pass it explicitly** — that is
correct under either reading, and it is the difference between running
what you just saved and running the last published version.

```json
{ "executionData": { "executeOption": "ApplyChangesIfNeeded",
    "parameters": [ { "parameterName": "OrderKey", "type": "Automatic", "value": 25 } ] } }
```

**Service principals cannot execute a dataflow.** The execute API
supports user identities only, and the public-APIs article lists service
principal authentication as unsupported outright. An unattended refresh
has to be driven another way — a pipeline Dataflow activity, or a
schedule.

## 8. Save, publish, refresh

- **Save auto-publishes.** In a CI/CD dataflow the save operation
  publishes; there is no separate publish button to forget.
- **Validation is a zero-row evaluation** that checks query schemas
  without returning rows. If a schema cannot be determined within **10
  minutes**, it fails, and the last saved version is used for refreshes.
  A separate documented limit puts validation and publish at **10 minutes
  per query**.
- **Just-in-time publish**: a save makes changes available to the next
  refresh, which attempts a publish if needed.
- **A failed publish now fails the refresh.** For any dataflow last saved
  **after 1 February 2026**, a publish failure fails the run rather than
  silently falling back to the last good version — deliberately, so
  nobody unknowingly runs an outdated dataflow.
- **After a Git sync or a deployment**, open and save the dataflow, or
  call the publish job. Without that the changes do not reach a refresh.
- **A successful publish starts an on-demand refresh** by itself.

## 9. What the definition API cannot do

Five documented limitations, and the first decides architectures:

1. **A data destination cannot be authored through the definition API.**
   Add it in the portal. A dataflow defined purely through the API can
   stage and transform but never persists to a destination.
2. **Service principal authentication is not supported.**
3. **`Get Item` and `List Item Access Details`** do not return correct
   information when filtered on the dataflow item type.
4. **An untyped call returns the CI/CD item.**
5. **Run APIs can be invoked but the run never succeeds** — stated as a
   current limitation on the public-APIs page.

Read 1 and 5 together before designing an API-first workflow.

## 10. CI/CD — three patterns, one constraint they share

| Pattern | Binds by | Needs |
| --- | --- | --- |
| Public parameters | values passed per run | a caller — REST or a pipeline activity |
| Variable libraries | workspace-scoped variables | a library in the **same** workspace |
| Relative references | item **name** in the current workspace | matching names per environment |

**Connections are statically bound under all three.** Dataflow Gen2 does
not support dynamic reconfiguration of data source connections, so a
server or database named in a connection cannot be swapped by a variable
or a parameter. Deployment rules do not help — they modify some item
properties but not connections or mashup logic.

Two more constraints worth knowing before choosing:

- **Variables work only inside `mashup.pq`**, only for basic types
  (`boolean`, `datetime`, `guid`, `integer`, `number`, `string`), and
  lineage views do not show the link between a dataflow and the library
  it reads.
- **Public parameters block scheduling.** A dataflow with required
  parameters cannot be scheduled or manually triggered through Fabric,
  and the mode is incompatible with incremental refresh.

References are absolute by default. Git integration is recommended on the
first stage only; later stages can deploy without it.

## 11. Gen1 → Gen2: two routes, one of them one-way

| | Save As | Upgrade Wizard (preview) |
| --- | --- | --- |
| Original | **kept** | **replaced** |
| Item ID | new | **same** |
| Reversible | n/a — original survives | **no** |
| Schedule | copied only with `includeSchedule` | preserved |

**The wizard is in-place and irreversible.** It replaces the Gen1 item
with a Gen2 (CI/CD) item of the same ID and name. To keep the original,
use Save As instead. Three further gates:

- **You must own the dataflow**, or the wizard reports *Upgrade
  unavailable*. Take over ownership first.
- **More than 50 enabled queries blocks it** — that one must be fixed
  before upgrading, unlike the other Needs-Attention reasons.
- **A failed upgrade cannot be retried for 24 hours**, and the upgraded
  item is soft-deleted for up to 30 days, during which outbound access
  protection cannot be enabled on the workspace.

**Afterwards, in order**: refresh each upgraded dataflow — it holds no
data until you do — then open and save every downstream dataflow that
reads it, which rebinds it.

**The legacy connector stops working, and it does not look like it.**
`PowerBI.Dataflows` cannot read a Gen2 (CI/CD) item; consumers must move
to `PowerPlatform.Dataflows`, which adds a `Workspaces` navigation step
and needs fresh credentials. An import-mode consumer keeps showing its
existing data until its next refresh, so nothing appears broken at first.
DirectQuery consumers need a storage-mode change as well, since
DirectQuery is unsupported against Gen2.

For bulk migration, Save As has a **preview** Power BI REST call,
`saveAsNativeArtifact`, which returns 200 **even when parts fail** —
check the `errors` array rather than the status code. Body fields and
error codes: [references/REFERENCE.md](references/REFERENCE.md).

## 12. Limits that decide designs

| Limit | Value |
| --- | --- |
| Refreshes per rolling 24 h | **300** CI/CD · **150** non-CI/CD |
| Scheduled refresh slots | 48 per day |
| Single query evaluation | 8 hours |
| Whole refresh | 24 hours |
| Staged or destination queries | **50 per dataflow** |
| Validation / publish | 10 minutes per query |
| Gateway versions supported | last **six** releases |
| OAuth2 refresh through a gateway | **1 hour** |

**The 50-query cap counts only queries that write** — staged, or with a
destination. Functions, helper queries and unstaged intermediate queries
do not count.

**Bursts throttle separately from the daily cap.** 300 refreshes spread
over 24 hours is fine; 300 in 60 seconds is rejected.

**A consistently failing schedule gets paused** and the owner emailed —
at 100% failure over 72 hours across at least 6 refreshes, or over 168
hours across at least 5.

## 13. Cost

| Engine | Rate |
| --- | --- |
| Standard compute, CI/CD | **12 CU/s** to 10 min, then **1.5 CU/s** |
| Standard compute, non-CI/CD | **16 CU/s** throughout |
| High-scale (staging enabled) | 6 CU/s |
| Fast copy (data movement) | 1.5 CU/s |
| MDF transforms (preview) | not currently billed |

**A non-CI/CD dataflow is not the cheaper one.** It pays a flat 16 CU per
second while a CI/CD item drops to 1.5 after ten minutes, so the gap
widens with query length.

**Fast copy bills aggregate core time, not wall clock** — the total
across every core the copy used. A copy that finishes in seconds can
still bill meaningfully, because the speed came from spreading work over
cores that are each billed.

## 14. Gotchas

- **`The key didn't match any rows in the table` usually means nothing is
  wrong with your data.** Downstream items reading a dataflow through the
  Dataflows connector go through an internal API that times out
  intermittently, and this is how it surfaces. The documented fix is to
  give the dataflow a Lakehouse or Warehouse destination and point
  consumers at that instead, bypassing the API.
- **Two staging traps, both time-based.** A refresh failing with
  *insufficient permissions for accessing staging artifacts* means
  whoever created the workspace's **first** dataflow has not signed in
  for 90 days or has left; they must sign in. Separately, staging items
  untouched for 90 days need re-authentication, done by creating a new
  dataflow in the workspace.
- **Viewer cannot consume.** Reading dataflow data through the connector
  needs Admin, Member or Contributor. Viewer is enough to *see* the item
  and to download refresh logs, not to read its tables.
- **Delta has no case sensitivity**, so `MyColumn` and `mycolumn` are
  legal in M and collide as duplicate columns at a Lakehouse destination.
- **Lakehouse destinations reject** spaces and special characters in
  column or table names, and duration and binary columns.
- **Guest users are unsupported** for sources and destinations.
- **One gateway query makes every query use it.** If a single query is
  configured for a gateway, all queries in that dataflow use it.
- **Staging items are not yours to manage.** `DataflowsStagingLakehouse`
  and `DataflowsStagingWarehouse` are internal. They are hidden in shared
  workspaces but visible in *My Workspace* — do not rename or delete
  them.

## 15. Ownership

Dataflows are **carved out of** Fabric's generic item take-over feature —
the take-ownership article says both dataflow generations keep their own
pre-existing mechanisms — and there is no API for changing item
ownership at all. After taking over a Gen2 (CI/CD) item, repair its
connections through **Manage Connections → Edit Connection**.

## Reference

- Learn: [What is Dataflow Gen2](https://learn.microsoft.com/fabric/data-factory/dataflows-gen2-overview) ·
  [CI/CD and Git integration](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-cicd-and-git-integration) ·
  [Public APIs](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-public-apis) ·
  [Refresh](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-refresh) ·
  [Pricing](https://learn.microsoft.com/fabric/data-factory/pricing-dataflows-gen2)
- Learn: [Dataflow definition schema](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/dataflow-definition) ·
  [Run On Demand Execute](https://learn.microsoft.com/rest/api/fabric/dataflow/background-jobs/run-on-demand-execute) ·
  [Discover parameters](https://learn.microsoft.com/rest/api/fabric/dataflow/items/discover-dataflow-parameters)
- Learn: [Upgrade Wizard](https://learn.microsoft.com/fabric/data-factory/migrate-to-dataflow-gen2-using-upgrade-wizard) ·
  [Save As](https://learn.microsoft.com/fabric/data-factory/migrate-to-dataflow-gen2-using-save-as) ·
  [Data Factory limitations](https://learn.microsoft.com/fabric/data-factory/data-factory-limitations#data-factory-dataflow-gen2-limitations)
- Parameter types and formats, the destination support and data-type
  matrices, incremental refresh, fast copy, monitoring schemas, the
  wizard's Needs-Attention table and the worked cost formulas:
  [references/REFERENCE.md](references/REFERENCE.md)

## See also

- **coding-m rule** — M style; co-loads on `mashup.pq`
- **fabric-git-serialization rule** — line endings and EOF newlines;
  globs this folder
- **fabric-rest-api skill** — LRO polling, `?updateMetadata`,
  pagination, rate limits
- **fabric-tmdl-api skill** — the "include ALL parts" rule this item shares
- **fabric-cicd skill** — deploying a dataflow between workspaces
- **fabric-variable-library skill** — the library this reads from
- **fabric-cli skill** — `fab` filesystem commands over the item
- **fabric-copy-job** / **fabric-mirroring skills** — ingestion without
  Power Query
- **fabric-gotchas skill** — cross-product error index
