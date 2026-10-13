# Eventstream workspace monitoring

Monitoring table dimensions and worked KQL queries. `SKILL.md` carries the
four table names, their cadence, and the republish rule.

## Workspace monitoring (preview) — KQL tables

Workspace monitoring is managed through a **monitoring item** (Workspace settings → **Monitoring**); the old **Log workspace activity** toggle, which created a monitoring Eventhouse in the workspace, is now legacy. Eventstream logging is opt-in per eventstream: turn on **Log Eventstream activity** on each one, because enabling monitoring for the workspace doesn't (Learn, 2026-10-06). Republish any Eventstream that existed *before* monitoring was enabled — pre-existing streams emit nothing until they're republished.

| Table | Cadence | What it tells you |
|---|---|---|
| `EventStreamNodeStatus` | ~6 hours | Each node's running / paused / failed state |
| `EventStreamMetrics` | 1 minute | Incoming / outgoing message counts, bytes, watermark delay, backlog |
| `EventStreamErrorMetrics` | 1 minute | Error counts by type (runtime, deserialization, conversion) |
| `EventStreamDiagnosticLogs` | As conditions occur; repeats throttled or aggregated | `Category`, `Severity`, `ErrorType`, `ErrorCode`, `IsFatal`, `Message` — the text behind an error count |

The tables share base dimensions, per Learn on 2026-10-06: `Timestamp`, `ItemId`, `ItemName`, `ItemKind` (always `Event Stream`), `WorkspaceId`, `WorkspaceName`, `CustomerTenantId`, `OperationId`, `CapacityId`. The earlier list, which the samples below were written against, named `ArtifactId` / `ArtifactName` and carried `Level`, `PremiumCapacityId`, `PlatformMonitoringCategory`, `PlatformMonitoringTableName` and `LogAnalyticsResourceId` instead. **Filter by the ID columns** — name columns can lag after rename / move.

**The samples are unmeasured against the new schema (2026-10-06).** They filter on `ArtifactId`; no workspace monitoring database was reachable to confirm what a current one carries. Run `EventStreamMetrics | getschema` first, and swap `ArtifactId` for `ItemId` if that is the column you find.

```kql
// Most-recent status per node in one Eventstream
EventStreamNodeStatus
| where ArtifactId == "<eventstream-artifact-id>"
| summarize arg_max(Timestamp, *) by NodeId
| project Timestamp, NodeName, NodeDirection, NodeType, NodeStatus
| order by NodeDirection asc

// Incoming vs outgoing in 5-minute windows
EventStreamMetrics
| where ArtifactId == "<eventstream-artifact-id>"
| where MetricsName in ("Incoming Messages", "Outgoing Messages")
| summarize TotalMessages = sum(Value)
    by TimeWindow = bin(Timestamp, 5m), MetricsName
| order by TimeWindow asc

// Recent errors grouped by type
EventStreamErrorMetrics
| where ArtifactId == "<eventstream-artifact-id>"
| where Timestamp > ago(24h) and Value > 0
| summarize TotalErrors = sum(Value)
    by TimeWindow = bin(Timestamp, 5m), MetricsName, NodeDirection
| order by TimeWindow desc
```

For ad-hoc per-node visualizations during authoring, the **Data insights** tab on the lower pane of the Eventstream editor surfaces metrics directly — works without workspace monitoring enabled but is per-node and not historical.

## Microsoft Learn

- [Workspace monitoring overview](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/fabric-workspace-monitoring)
- [Monitoring tables](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/fabric-workspace-monitoring-tables)
- [Query monitoring data](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/query-fabric-workspace-monitoring-data)
- [Known limitations](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/fabric-workspace-monitoring-known-limitations)
- [Monitor status and performance](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/monitor)
