---
paths:
  - "**/*.kql"
  - "**/*.csl"
---

# KQL Coding Conventions

Applies to Kusto Query Language across Azure Data Explorer, Azure
Monitor / Log Analytics, Microsoft Sentinel, Defender XDR, Application
Insights, and Real-Time Intelligence in Fabric.

If a project-scope `.claude/rules/coding-kql.md` exists, that file
supersedes this one.

## Casing

- **Operators / keywords**: lowercase — `where`, `project`, `summarize`,
  `extend`, `join`, `let`, `order by`, `take`, `top`. **This is the
  KQL convention; do not uppercase like T-SQL.**
- **Functions**: lowercase — `tolower()`, `parse_json()`, `bin()`,
  `ago()`.
- **Table names**: PascalCase — matches Microsoft's first-party tables
  (`SecurityEvent`, `SigninLogs`, `AppRequests`).
- **Column names**: PascalCase — matches first-party schemas
  (`TimeGenerated`, `EventID`, `UserPrincipalName`).
- **`let` variables**: PascalCase for query-level constants
  (`StartDate`, `LookbackWindow`); `_camelCase` or `_snake_case` for
  intermediate temp values you want visually demoted.

## Pipe layout

- Pipe `|` at the **start of each line**, indented under the source
  table. One operator per line.

```kql
// Good
SecurityEvent
| where TimeGenerated > ago(1d)
| where EventID == 4625
| summarize FailedLogons = count() by Account, Computer
| order by FailedLogons desc

// Bad
SecurityEvent | where TimeGenerated > ago(1d) | where EventID == 4625 | summarize FailedLogons=count() by Account,Computer | order by FailedLogons desc
```

## Clause order (filter early, project early)

Idiomatic order: `source` → `where` (time first) → `where` (other
filters) → `extend` → `summarize` → `project` → `order by` → `take`.

- **Time filter first.** Telemetry tables are time-indexed; an early
  time filter slashes scanned data.
- **`project` early** to drop wide columns you don't need — especially
  in Sentinel where rows are wide.

```kql
// Good
SigninLogs
| where TimeGenerated > ago(7d)         // time filter first
| where ResultType != 0                 // other filters
| project TimeGenerated, UserPrincipalName, IPAddress, ResultType
| extend UserDomain = tostring(split(UserPrincipalName, "@")[1])
| summarize FailedSignins = count() by UserDomain
| order by FailedSignins desc

// Bad (filter applied after summarize wastes scan)
SigninLogs
| summarize FailedSignins = count() by UserPrincipalName
| where FailedSignins > 10
```

## `let` for parameters and reuse

- Top-of-query `let` block for time windows, thresholds, magic numbers.
- `let` an intermediate result and reuse instead of re-computing.

```kql
let LookbackWindow = 7d;
let FailureThreshold = 10;
let SuspiciousIp =
    SigninLogs
    | where TimeGenerated > ago(LookbackWindow)
    | where ResultType != 0
    | summarize Failures = count() by IPAddress
    | where Failures > FailureThreshold;
SigninLogs
| where TimeGenerated > ago(LookbackWindow)
| where IPAddress in (SuspiciousIp | project IPAddress)
| project TimeGenerated, UserPrincipalName, IPAddress, ResultType
```

## Aggregation: `summarize by` over `distinct`

- `summarize Count = count() by Col` when you need both grouping and
  aggregation.
- `distinct Col1, Col2` only when you actually want unique combinations
  with no aggregation.

## `project` vs `project-away` vs `project-keep`

- `project` — list exactly what you keep (positive list).
- `project-away` — drop named columns (negative list); useful when
  keeping most of a wide schema.
- `project-keep` — keep by pattern (`project-keep *Time*`).
- `project-rename` — rename without reprojecting all columns.

## Joins

- Specify `kind` explicitly: `kind=inner`, `kind=leftouter`,
  `kind=fullouter`, `kind=leftanti`, `kind=rightsemi`. Default
  changed historically; explicit is safe.
- Filter both sides before joining.
- Smaller table on the **left** of `join` (KQL broadcasts the left
  side). Opposite of T-SQL muscle memory.

```kql
// Good
let SmallDim =
    Identity
    | where IsAdmin == true
    | project UserPrincipalName, Department;
SmallDim
| join kind=inner (
    SigninLogs
    | where TimeGenerated > ago(1d)
    | project TimeGenerated, UserPrincipalName, ResultType
) on UserPrincipalName
```

## `materialize()` for reused subqueries

When the same `let`-bound query is referenced 2+ times in the same
query, wrap in `materialize()`:

```kql
let RecentEvent = materialize(
    SecurityEvent
    | where TimeGenerated > ago(1h)
    | where EventID in (4624, 4625, 4634)
);
RecentEvent | summarize count() by EventID;
RecentEvent | summarize count() by Account
```

## Time

- `ago(7d)`, `ago(1h)`, `ago(15m)` — preferred for relative windows.
- `bin(TimeGenerated, 1h)` — bucket times for time-series.
- `between (datetime(...) .. datetime(...))` — explicit absolute window.

## Comments

- `//` single-line.
- `/* ... */` block.
- Explain *why* — particularly around any threshold, lookback, or
  filter that encodes a business or security definition.

## Anti-patterns

- `where` after `summarize` when the filter could have run before —
  forces full scan and aggregation.
- `tolower()` inside `where` on indexed string columns — disables index
  acceleration. Use `=~` (case-insensitive equality) instead.
- `extend` of columns then never using them — bloats intermediate
  rowset.
- Joining giant tables without filtering both sides first.
- Hard-coded time windows scattered through a query — extract to a
  `let`.
