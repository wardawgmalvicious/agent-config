# Fabric Spark monitoring — log and resource-usage APIs

The log and `resourceUsage` endpoints that sit alongside the Spark
History Server routes in the parent
[SKILL.md](../SKILL.md). Same auth, same base URL, same path
parameters — these are literal siblings of `/jobs` under
`.../applications/{appId}/`.

**Provenance:** doc-verified 2026-08-30 against Microsoft Learn
([livy-log](https://learn.microsoft.com/fabric/data-engineering/livy-log),
[driver-log](https://learn.microsoft.com/fabric/data-engineering/driver-log),
[executor-log](https://learn.microsoft.com/fabric/data-engineering/executor-log),
[resource-usage-apis](https://learn.microsoft.com/fabric/data-engineering/resource-usage-apis)).
**Not exercised live** — unlike the SHS routes in SKILL.md, which were
run on 2026-08-17. Verify response shapes before depending on them.

## Common route shape

```
GET https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}
      /{notebooks|sparkJobDefinitions|lakehouses}/{itemId}
      /livySessions/{livyId}
      /applications/{appId}[/{attemptId}]
      /{logs?type=…|resourceUsage}
```

| Parameter | Required | Notes |
|---|---|---|
| `workspaceId`, `itemId`, `livyId` | yes | UUIDs |
| `appId` | yes | YARN form, `application_1704417105000_0001` |
| `attemptId` | no | int; omitted means the **last** attempt |

## Auth and scopes

Same delegated token as the parent skill. Required scopes are
`Item.Read.All` / `Item.ReadWrite.All`, **or** the group matching the
item type that launched the application:

- `Notebook.Read.All` / `Notebook.ReadWrite.All`
- `SparkJobDefinition.Read.All` / `SparkJobDefinition.ReadWrite.All`
- `Lakehouse.Read.All` / `Lakehouse.ReadWrite.All`

The caller also needs read permission on the item itself. User,
service principal and managed identity are all supported.

## Log APIs

All four log kinds share one endpoint, discriminated by `type=`. Add
`meta=true` for metadata; omit it for content.

| Log | `type=` | `attemptId` form | Required query params (content) |
|---|---|---|---|
| Livy | `livy` | **none** | — |
| Driver, single file | `driver` | yes | `fileName` |
| Driver, rolling | `rollingdriver` | yes | — (metadata only) |
| Executor | `executor` | metadata only | `containerId`, `fileName` |

### Livy log — the `applications/none` quirk

The Livy log is session-scoped, not application-scoped, so it takes
the literal string `none` where every other route takes an `appId`:

```
GET .../livySessions/{livyId}/applications/none/logs?type=livy&meta=true
GET .../livySessions/{livyId}/applications/none/logs?type=livy
```

There is no `attemptId` form. Returns a `FileMeta`
(`fileName`, `length`, `lastModified`, `creationTime`, `metaData`).

### Driver logs

```
GET .../applications/{appId}/logs?type=driver&meta=true&fileName=stderr
GET .../applications/{appId}/logs?type=driver&fileName=stderr
GET .../applications/{appId}/logs?type=rollingdriver&meta=true
```

Content params: `containerId` (omit if unknown), `isDownload`,
`isPartial`, `offset`, `size` (default 1 MB).

Rolling-log metadata params: `filenamePrefix` (`stdout` or `stderr`),
`offset` (0–20,000), `maxResults` (1–3,000, default 3,000).

**`offset` only works while the application is still running.** Once
it stops, the parameter is silently ignored — use `rollingdriver`
instead. This is the trap most likely to waste time: the request
succeeds and returns the wrong slice.

Returns a single `ContainerLogMeta` object — `containerId`, `nodeId`,
and a `containerLogMeta` holding one `FileMeta` or a list of them.

### Executor logs

```
GET .../applications/{appId}/logs?type=executor&meta=true
GET .../applications/{appId}/logs?type=executor&containerId={cid}&fileName=stdout
```

Metadata params: `containerId`, `filenamePrefix`, `offset`,
`maxResults`. Content requires **both** `containerId` and `fileName`;
optional `size` (default 1 MB).

Returns a **list** of `ContainerLogMeta` — one per executor container
— where the driver route returns a single object. Iterate accordingly.

### Field-name inconsistency trap

The documented samples do not agree on file-metadata field names
across log kinds:

| Route | Size field | Timestamp field | Timestamp format |
|---|---|---|---|
| Livy, driver | `length` | `lastModified` | `2025-03-05T12:31:31.000GMT` |
| Executor | `fileSize` (string) | `lastModifiedTime` | `Fri Aug 23 04:56:14 +0000 2024` |

Parse per route rather than writing one shared deserializer. Note the
executor timestamp is not the `GMT`-suffixed ISO form the rest of this
surface uses — the `strptime` recipe in SKILL.md does not apply to it.

## Resource-usage APIs

The quantitative complement to the five-phase attribution recipe in
SKILL.md: where that recipe infers idle time by subtraction, this
endpoint reports it directly.

### Timeline

```
GET .../applications/{appId}/resourceUsage
GET .../applications/{appId}/resourceUsage?jobGroup=&jobLimit=&executorLimit=&executorJobLimit=&start=&end=
```

`start` / `end` are epoch milliseconds. `jobGroup` repeats for
multiple groups (`?jobGroup=1&jobGroup=2`).

Top-level `ResourceUsageInfo` fields:

| Field | Why it matters |
|---|---|
| `coreEfficiency` | Overall executor-core utilisation, 0–1. The single best one-number verdict on whether a run was compute-bound or idle. |
| `idleTime` | Milliseconds the application sat idle |
| `duration` | Total application duration, milliseconds |
| `capacityExceeded` | `true` once the 10,000-task limit is hit — **and then every array in `data` is empty** |

`data` holds parallel arrays indexed by `timestamps`: `allocatedCores`,
`idleCores`, `runningCores`, plus `executors`, `jobs` and
`executorJobs` as nested tuple arrays (`[executorId, coreCount,
taskCount]`, `[jobId, taskCount]`).

### Snapshot

```
GET .../applications/{appId}/resourceUsage/{timestamp}
```

Returns the time point closest to `{timestamp}`, same fields
unwrapped to scalars rather than arrays.

## Gotchas

- **`capacityExceeded: true` empties the payload.** A 200 with a
  populated header and no `data` is this, not a bug. Applications
  above 10,000 tasks cannot be profiled this way.
- **`resourceUsage` 404 is ambiguous** — it means either an ID
  mismatch between item / application / Livy session, *or* that the
  run is too young for data to exist yet. Retry before assuming the
  IDs are wrong.
- **`resourceUsage` 400** means `start` is greater than `end`.
- **Epoch-millis vs GMT strings.** `resourceUsage` timestamps are
  `long` epoch milliseconds; the SHS job timestamps are `GMT`-suffixed
  ISO strings. Joining the two surfaces requires converting one.
- **`isPartial` / `isPartials`** flag that a `*Limit` parameter
  truncated the response — check it before treating a timeline as
  complete.
