---
name: fabric-spark-monitoring
description: "Use for diagnosing Fabric Spark performance through the monitoring REST APIs — listing Livy sessions (/workspaces/{ws}/spark/livySessions with queuedDuration/runningDuration, HC_ session naming), pulling the Spark History Server mirror (notebooks, sparkJobDefinitions or lakehouses → .../livySessions/{livy}/applications/{appId}/jobs, plus /stages, /executors, /sql) for job timelines and gap analysis, attributing notebook wall-clock to queue/boot/work/teardown phases, verifying high-concurrency session reuse (sessionSource created vs reused), and the sibling log and resourceUsage routes (coreEfficiency, idleTime, Livy/driver/executor logs)."
---

# Fabric Spark monitoring APIs

Attribute Fabric Spark notebook / pipeline wall-clock time using the
Spark monitoring REST surface: Livy session listings plus the embedded
Spark History Server (SHS) mirror. Every endpoint here is a GET —
read-only diagnostics, no state changes.

All endpoint shapes and field names below were exercised live on
2026-08-17. The surface is preview-era — re-verify response shapes
before building anything that depends on their stability.

## Auth & base URL

```bash
az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv
```

Delegated token. On a Fabric-only tenant (no Azure subscription) the
login itself needs `az login --allow-no-subscriptions`. Base URL is
`https://api.fabric.microsoft.com/v1`; plain `curl` with a bearer
header works from there — no SDK or MCP server required. Full token
audience table and 401 debugging: **fabric-auth** skill.

## Listing Livy sessions

```
GET /workspaces/{wsId}/spark/livySessions?maxResults=N            # workspace-wide
GET /workspaces/{wsId}/notebooks/{itemId}/livySessions            # per-item
GET /workspaces/{wsId}/sparkJobDefinitions/{itemId}/livySessions  #   "
GET /workspaces/{wsId}/lakehouses/{itemId}/livySessions           #   "
```

Field guide for the session objects:

| Field | Meaning |
|---|---|
| `sparkApplicationId` | YARN application id — required for SHS drill-down below |
| `livyId` | The Livy session id used in per-application URLs |
| `livyName` | `HC_<NotebookName>_<livyId>` prefix marks a high-concurrency session |
| `state` | Session lifecycle state |
| `origin`, `submitter`, `jobType` | Who/what launched the session |
| `submittedDateTime` / `startDateTime` / `endDateTime` | Submission vs actual start vs end |
| `queuedDuration` / `runningDuration` / `totalDuration` | Duration objects |

**`queuedDuration` is pure capacity contention** — time spent before
the Spark application existed at all. If it dominates, the problem is
capacity/queueing, not the notebook.

## Drilling into one application

All three item types work here, not just notebooks, and an optional
`{attemptId}` (int) may follow `{appId}` — omit it and the last
attempt is used.

```
GET .../{notebooks|sparkJobDefinitions|lakehouses}/{itemId}/livySessions/{livyId}/applications/{appId}[/{attemptId}]
GET .../applications/{appId}/jobs        # SHS jobs array
GET .../applications/{appId}/jobs/{id}   # one job
GET .../applications/{appId}/sql/{id}?details=false
```

The jobs array mirrors the Spark History Server: `jobId`, `name`,
`description`, `submissionTime`, `completionTime`, `status`,
`stageIds`, and the `num*Tasks` / `num*Stages` counters. The
`description` embeds the originating notebook statement — that is how
jobs map back to cells.

**`/jobs` is not the only sub-resource.** These are the open-source
Spark History Server APIs — same structure, query parameters and
contract as Spark's own monitoring REST API — so `/stages`, `/tasks`,
`/executors`, `/storage`, `/sql` and `/logs` are all served.
(Doc-verified 2026-08-30, not exercised.)

**404 trap:** exactly two OSS endpoints are withheld — `/applications`
(list all) and `/version`. That is why
`.../livySessions/{livyId}/applications` with no `{appId}` returns
404: there is no "list applications" form, by design. Get
`sparkApplicationId` from a session listing instead.

## The attribution recipe

Decompose notebook wall-clock into five phases:

1. **Queued** — `queuedDuration` from the session listing.
2. **Livy → app** — Livy `startDateTime` to the app attempt's start.
3. **Boot + non-Spark cells** — app start to first Spark job
   submission: cluster boot plus cells that never touch Spark
   (imports, pyodbc control reads, pure-Python setup).
4. **Real work** — first to last Spark job. Sum job durations and
   compute inter-job gaps; gaps are driver-side / non-Spark time
   between cells. Overlapping submission windows prove intra-notebook
   parallelism.
5. **Teardown** — last job completion to app end (snapshot/teardown).

Worked example (live run, 2026-08-17): a 6m48s notebook decomposed to
101s queue / 31s Livy→app / 107s boot + pre-cells / 73s Spark jobs
(with 17s of dead gaps) / ~75s teardown — i.e. only ~18% of wall-clock
was Spark work.

Gap analysis over the jobs array:

```python
from datetime import datetime

def ts(s):  # SHS timestamps end in literal "GMT" — strip it first
    return datetime.strptime(s.replace("GMT", ""), "%Y-%m-%dT%H:%M:%S.%f")

jobs.sort(key=lambda j: ts(j["submissionTime"]))
prev_end, gaps = None, []
for j in jobs:
    start, end = ts(j["submissionTime"]), ts(j["completionTime"])
    if prev_end is not None and (gap := (start - prev_end).total_seconds()) > 1:
        gaps.append((j["jobId"], round(gap, 1)))
    prev_end = end if prev_end is None else max(prev_end, end)
```

## Logs and resource usage

Two more sibling routes hang off `.../applications/{appId}/`:

- **`/logs?type=livy|driver|rollingdriver|executor`** — Livy,
  driver (single and rolling) and per-executor log metadata and
  content.
- **`/resourceUsage`** — `coreEfficiency`, `idleTime` and a
  per-timestamp core / executor / job timeline. It reports directly
  what the recipe above infers by subtraction, so reach for it before
  hand-rolling gap analysis.

Route table, query parameters, response fields and the traps (the
literal `applications/none` Livy-log form, `capacityExceeded`
emptying the payload, driver-log `offset` being ignored once the
application stops) are in
[references/REFERENCE.md](references/REFERENCE.md). Doc-verified
2026-08-30, not exercised.

## High-concurrency session semantics

The reuse verdict lives in the pipeline Notebook activity's run
output: `highConcurrencyModeStatus.sessionSource` — `created` (paid
the full startup cost) vs `reused` (attached to a live session).
`sessionTag` groups runs onto the same session.

Reuse eliminates phases 1–3 entirely — for small-data runs those are
the dominant cost, so reuse is usually the single biggest lever.

Reuse conditions (all must hold): same session tag, same submitting
user, same default lakehouse + compute configuration, target session
still alive, and ≤ 5 notebooks already attached to the session.

## Gotchas

- **SHS timestamps end in literal `GMT`** (e.g.
  `2026-08-17T14:03:21.117GMT`) — strip it before `strptime`; `%Z`
  will not parse it reliably.
- **Windows path split:** `curl` under Git Bash writing to `/tmp`
  produces files Windows-side Python can't see (Git Bash's `/tmp` is
  not `C:\tmp`). Write API responses to a repo-relative or scratchpad
  path instead.
- **Preview-era surface** — these monitoring APIs predate a stable GA
  contract; verify response shapes before relying on them.

## See also

- **fabric-warehouse-monitoring** skill — Warehouse-side counterpart
  (`queryinsights`, query labels, DMVs)
- **fabric-rest-api** skill — generic auth, LRO, pagination, item-ID
  patterns
- **fabric-spark** skill — notebook authoring, session configuration,
  high-concurrency setup
- **fabric-auth** skill — token audiences and 401 debugging
