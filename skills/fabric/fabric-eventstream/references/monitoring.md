# Eventstream workspace monitoring

Monitoring table dimensions and worked KQL queries. `SKILL.md` carries the
three table names, their cadence, and the republish rule.

## Workspace monitoring (preview) — KQL tables

Enable workspace monitoring (Workspace settings → **Monitoring** → **Log workspace activity**) and Fabric auto-creates a monitoring Eventhouse with three Eventstream-specific tables. Republish any Eventstream that existed *before* monitoring was enabled — pre-existing streams emit nothing until they're republished.

| Table | Cadence | What it tells you |
|---|---|---|
| `EventStreamNodeStatus` | ~6 hours | Each node's running / paused / failed state |
| `EventStreamMetrics` | 1 minute | Incoming / outgoing message counts, bytes, watermark delay, backlog |
| `EventStreamErrorMetrics` | 1 minute | Error counts by type (runtime, deserialization, conversion) |

All three tables share base dimensions: `Timestamp`, `ArtifactId`, `ArtifactName`, `WorkspaceId`, `WorkspaceName`, `CustomerTenantId`, `Level`, `OperationId`, `PremiumCapacityId`, `PlatformMonitoringCategory`, `PlatformMonitoringTableName`, `LogAnalyticsResourceId`. **Filter by `ArtifactId` / `WorkspaceId`** — name columns can lag after rename / move.

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
