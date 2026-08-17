---
name: fabric-spark-monitoring
description: "Use for diagnosing Fabric Spark performance through the monitoring REST APIs — listing Livy sessions (/workspaces/{ws}/spark/livySessions with queuedDuration/runningDuration, HC_ session naming), pulling the Spark History Server mirror (.../notebooks/{nb}/livySessions/{livy}/applications/{appId}/jobs) for job timelines and gap analysis, attributing notebook wall-clock to queue/boot/work/teardown phases, and verifying high-concurrency session reuse (sessionSource created vs reused)."
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
GET /workspaces/{workspaceId}/spark/livySessions?maxResults=N     # workspace-wide
GET /workspaces/{workspaceId}/notebooks/{notebookId}/livySessions # per-item
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

```
GET .../notebooks/{nbId}/livySessions/{livyId}/applications/{appId}       # attempt start/end
GET .../notebooks/{nbId}/livySessions/{livyId}/applications/{appId}/jobs  # SHS jobs array
```

The jobs array mirrors the Spark History Server: `jobId`, `name`,
`description`, `submissionTime`, `completionTime`. The `description`
embeds the originating notebook statement — that is how jobs map back
to cells.

**404 trap:** `.../livySessions/{livyId}/applications` without an
`{appId}` returns 404 — there is no "list applications" form. Get
`sparkApplicationId` from the session listing first.

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

## Unverified adjacent surface

Presumed to exist but **not exercised** (as of 2026-08-17) — verify
before use:

- SHS sub-endpoints beyond `/jobs`: `/stages`, `/executors`, `/sql`
- Item scoping via `sparkJobDefinitions/{id}/livySessions` (the
  Spark-job-definition analogue of the notebook-scoped routes)

## See also

- **fabric-warehouse-monitoring** skill — Warehouse-side counterpart
  (`queryinsights`, query labels, DMVs)
- **fabric-rest-api** skill — generic auth, LRO, pagination, item-ID
  patterns
- **fabric-spark** skill — notebook authoring, session configuration,
  high-concurrency setup
- **fabric-auth** skill — token audiences and 401 debugging
