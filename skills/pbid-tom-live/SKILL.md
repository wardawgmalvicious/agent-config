---
name: pbid-tom-live
description: Use for scripting an open Power BI Desktop model via its localhost msmdsrv.exe Analysis Services proxy — TOM (Microsoft.AnalysisServices.Tabular) for metadata, ADOMD.NET (AdomdConnection) for DAX. Covers PowerShell setup with retail.amd64 AMO/TOM + ADOMD NuGet DLLs, discovering the msmdsrv port (msmdsrv.port.txt / netstat), connecting via server Databases Model, SaveChanges / UndoLocalChanges, ExecuteReader for EVALUATE, DAX validation pre-save, TMSL refresh types (full / calculate / automatic / dataOnly / clearValues / defragment), VertiPaq DMVs ($SYSTEM.DISCOVER_STORAGE_TABLE_COLUMN_SEGMENTS, TMSCHEMA_*), query listener via DISCOVER_SESSIONS, EVALUATEANDLOG trace events (DAXEvaluationLog), FE-vs-SE Server Timings profiling, DAXLib UDF packages (CL 1702+), Calendar Column Groups (CL 1604+). Invoke when user mentions TOM, ADOMD, msmdsrv, VertiPaq, DMV, EVALUATEANDLOG, Server Timings, daxlib.
---

## Power BI Desktop — Live TOM / ADOMD Operations

Local Analysis Services proxy inside Power BI Desktop. Enables TOM (metadata) and ADOMD.NET (DAX query) connections from PowerShell. Does not work for thin reports, Direct Lake models, or remote XMLA endpoints. For those use a remote XMLA / Power BI REST approach — see fabric-tmdl for semantic-model authoring and fabric-tmdl-api for Fabric semantic-model definition REST call patterns (createItemWithDefinition, updateDefinition).

> **Note (April 2026)**: Direct Lake on OneLake gained calculated-column / calculated-table preview support. The local msmdsrv proxy still does not bind to Direct Lake models — author and edit those columns through the remote XMLA endpoint (or the Desktop UI) and use TOM there. Local TOM / ADOMD scripting in this skill remains scoped to Import / DirectQuery models.

### Prerequisites

| Requirement | Notes |
|---|---|
| Power BI Desktop | Open with a non-thin model loaded |
| PowerShell + `nuget` | `winget install Microsoft.NuGet` |
| `Microsoft.AnalysisServices.retail.amd64` | TOM metadata DLLs |
| `Microsoft.AnalysisServices.AdomdClient.retail.amd64` | DAX query DLLs |

Packages extract to `$env:TEMP\tom_nuget\...\lib\net45\`. Load via `Add-Type -Path`. If TOM calls fail with missing type / compatibility level errors, swap to the newer `Microsoft.AnalysisServices` (.NET 8) package.

### Discovering Running PBID Instances

Each open `.pbix`/`.pbip` spawns one `msmdsrv.exe` on a random localhost port. When multiple are running, connect to each, read `$server.Databases[0].Name`, and ask the user which to target.

| Method | Works On | Command |
|---|---|---|
| Port file (non-Store) | Desktop installer | `Get-Content "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces\*\Data\msmdsrv.port.txt"` |
| Port file (Store) | MS Store install | `Get-Content "$env:LOCALAPPDATA\Packages\Microsoft.MicrosoftPowerBIDesktop_*\LocalState\AnalysisServicesWorkspaces\*\Data\msmdsrv.port.txt"` |
| netstat | Any | Filter `netstat -ano` LISTENING rows by `(Get-Process msmdsrv).Id` |

### Connection Strings

| Target | Connection String |
|---|---|
| TOM metadata | `Data Source=localhost:<PORT>` via `Microsoft.AnalysisServices.Tabular.Server.Connect()` |
| ADOMD DAX | `Data Source=localhost:<PORT>` on `AdomdConnection` |

```powershell
$basePath = "$env:TEMP\tom_nuget\Microsoft.AnalysisServices.retail.amd64\lib\net45"
Add-Type -Path "$basePath\Microsoft.AnalysisServices.Core.dll"
Add-Type -Path "$basePath\Microsoft.AnalysisServices.Tabular.dll"

$server = New-Object Microsoft.AnalysisServices.Tabular.Server
$server.Connect("Data Source=localhost:$port")
$db = $server.Databases[0]
$model = $db.Model
```

Always `$server.Disconnect()` when done. Only `$model.SaveChanges()` persists modifications; without it edits are discarded. `Ctrl+Z` in PBI Desktop cannot undo TOM saves.

### Executing DAX via ADOMD.NET

```powershell
Add-Type -Path "$env:TEMP\tom_nuget\Microsoft.AnalysisServices.AdomdClient.retail.amd64\lib\net45\Microsoft.AnalysisServices.AdomdClient.dll"
$conn = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdConnection
$conn.ConnectionString = "Data Source=localhost:$port"
$conn.Open()

$cmd = $conn.CreateCommand()
$cmd.CommandText = "EVALUATE SUMMARIZECOLUMNS('Date'[Year], ""@Total"", [Total Sales])"
$reader = $cmd.ExecuteReader()
while ($reader.Read()) {
	for ($i = 0; $i -lt $reader.FieldCount; $i++) {
		"$($reader.GetName($i)) = $($reader.GetValue($i))"
	}
}
$reader.Close(); $conn.Close()
```

**DAX rules over ADOMD:**

- Fully-qualify columns: `'Sales'[Amount]`, never `[Amount]`
- Measures unqualified: `[Total Revenue]`
- String literals: double quotes, escape `""` inside PowerShell here-strings
- Prefer `SUMMARIZECOLUMNS` over summarize; prefer `DIVIDE`; never `IFERROR`
- Reader returns fully-qualified column names. Access by index via `GetName($i)` / `GetValue($i)` — short-name indexing silently returns blanks
- Use `ExecuteNonQuery()` for TMSL commands; `ExecuteReader()` only for `EVALUATE`

### Validating DAX Before Saving

```powershell
$testExpr = "SUM('Sales'[Amount]) / COUNTROWS('Sales')"
$cmd.CommandText = "EVALUATE ROW(""@Test"", $testExpr)"
try { $cmd.ExecuteReader().Close(); "VALID" } catch { "INVALID: $($_.Exception.Message)" }
```

For table expressions wrap in `COUNTROWS()`. For RLS filter expressions wrap in `CALCULATETABLE(ROW("@OK",1), <filter>)`.

### Refreshing the Model

Three equivalent methods:

| Method | Call | When |
|---|---|---|
| TMSL via TOM | `$server.Execute($tmsl)` | Full flexibility; error rowset |
| TOM API | `$model.Tables["X"].RequestRefresh([...]); $model.SaveChanges()` | Simplest programmatic |
| TMSL via ADOMD | `$cmd.ExecuteNonQuery()` with TMSL | When only ADOMD is loaded |

| Refresh Type | TMSL | Effect |
|---|---|---|
| `full` | `"full"` | Drop, re-query, recompress, recalc DAX |
| `calculate` | `"calculate"` | Recalc DAX only (no source hit) |
| `automatic` | `"automatic"` | Per-partition: full if never processed else calculate |
| `dataOnly` | `"dataOnly"` | Re-query, skip DAX recalc |
| `clearValues` | `"clearValues"` | Drop data without reloading |
| `defragment` | `"defragment"` | Recompress dictionaries |

Refresh dependencies: dimensions first, facts second, then a `calculate` to recompute DAX. Or issue `full` on the database and let the engine order it. Refreshes are synchronous — bump shell timeouts to 300000ms+ for large models.

### VertiPaq / Storage Engine DMVs

All run via ADOMD `$conn`.

| DMV | Use |
|---|---|
| `$SYSTEM.DISCOVER_STORAGE_TABLE_COLUMN_SEGMENTS` | Per-column `USED_SIZE`, `DICTIONARY_SIZE`, `RECORDS_COUNT`, `SEGMENT_NUMBER` |
| `$SYSTEM.DISCOVER_STORAGE_TABLE_COLUMNS` | Per-column `CARDINALITY` (distinct values) |
| `$SYSTEM.DISCOVER_SESSIONS` | Last command + `SESSION_LAST_COMMAND_ELAPSED_TIME_MS` / `CPU_TIME_MS` |
| `$SYSTEM.DISCOVER_COMMANDS` | Active commands (longer `COMMAND_TEXT` than sessions) |
| `$SYSTEM.TMSCHEMA_TABLES` / `_MEASURES` / `_COLUMNS` / `_RELATIONSHIPS` | Model metadata via SQL-like syntax |

Filter out internal tables with `WHERE LEFT(DIMENSION_NAME,1) <> '$'`. High cardinality = large dictionary = memory hotspot.

```sql
SELECT DIMENSION_NAME, SUM(USED_SIZE + DICTIONARY_SIZE) AS TotalBytes, SUM(RECORDS_COUNT) AS Rows
FROM $SYSTEM.DISCOVER_STORAGE_TABLE_COLUMN_SEGMENTS
WHERE LEFT(DIMENSION_NAME,1) <> '$'
GROUP BY DIMENSION_NAME
ORDER BY TotalBytes DESC
```

### Query Listener (Capturing Visual DAX)

Poll `$SYSTEM.DISCOVER_SESSIONS` once per second. When `SESSION_LAST_COMMAND` changes and starts with `DEFINE|EVALUATE|VAR `, record it. Timings come from `SESSION_LAST_COMMAND_ELAPSED_TIME_MS` and `SESSION_CPU_TIME_MS`.

Ignore internal traffic: `<Subscribe>`, `<ImageSave>`, `<Batch><Discover>`, `MDSCHEMA_*`, `SELECT * FROM $SYSTEM.*`.

Visual query anatomy:

| Pattern | Meaning |
|---|---|
| `SUMMARIZECOLUMNS` | Main group-by + measures |
| `__DS0FilterTable` | Slicers/page filters |
| `TOPN` wrapping SUMMARIZECOLUMNS | Visual has Top N filter |
| `IGNORE(...)` | Column in group-by but not filter |
| `__ValueFilterDM1` | Measure-based visual filter |
| `CALCULATE(...)` around a measure | Visual-level override |

Limits: `SESSION_LAST_COMMAND` is truncated for very large queries; intermediate queries between polls are missed (use 200-500ms interval for busy reports); thin-report queries are invisible.

### EVALUATEANDLOG Debugging

`EVALUATEANDLOG(<Value>, [<Label>], [<MaxRows>])` wraps a DAX expression, returns it unchanged, and emits intermediate results as a JSON trace event (`DAXEvaluationLog`, event class ID 135). PBI Desktop only; passthrough in Service / SSAS / Azure AS.

**Setup via TOM Trace API:** dot-source [scripts/setup-evaluateandlog-trace.ps1](scripts/setup-evaluateandlog-trace.ps1) — assumes a connected `$server` (see "Discovering Running PBID Instances" above) and leaves `$trace`, `$evalEvents`, and `$job` in scope for the caller. The script body is the synchronized-ArrayList pattern; the rationale, cache-clear requirement, and FE/SE timing quirks are below.

**Critical:** `Register-ObjectEvent -Action` runs in a separate runspace; `$global:` does not cross. Use a synchronized `ArrayList` via `-MessageData`.

**Always clear the VertiPaq cache** before each debug query; cached results skip EVALUATEANDLOG:

```powershell
$server.Execute('{ "clearCache": { "object": { "database": "' + $db.Name + '" } } }') | Out-Null
```

Events arrive **asynchronously**. Use a persistent trace across queries, record `$evalEvents.Count` before each call, and `Start-Sleep -Seconds 2` before reading. Some calls emit no event due to engine optimizations. `COUNTROWS(EVALUATEANDLOG(table))` is a known broken pattern.

**JSON payload fields:**

| Field | Meaning |
|---|---|
| `expression` | Wrapped expression text |
| `label` | Optional label argument |
| `inputs` | Columns affecting evaluation context |
| `data[].input` / `.output` | Per-context input/output pairs |
| `data[].rowCount` | True row count (not truncated by MaxRows) |

Cleanup: `$trace.Stop(); Unregister-Event $job.Name; $trace.Drop()`.

### Performance Profiling (FE vs SE Split)

Equivalent to DAX Studio's Server Timings. Subscribe to `QueryEnd`, `VertiPaqSEQueryEnd`, `VertiPaqSEQueryCacheMatch`.

| Event | Use | Columns |
|---|---|---|
| `QueryEnd` | Total query time | TextData, Duration, CpuTime, EventClass |
| `VertiPaqSEQueryEnd` | Per-scan SE duration | TextData, Duration, CpuTime, EventClass |
| `VertiPaqSEQueryCacheMatch` | Cache hits | **TextData + EventClass only** — adding Duration/CpuTime crashes `$trace.Update()` |

Formula Engine time = `QueryEnd.Duration - Σ VertiPaqSEQueryEnd.Duration`.

Take 6-12 samples, compare **medians** not means, discard the first cold-cache run as warm-up. If ranges overlap significantly, the delta is noise.

### DAXLib Package Patterns

daxlib.org is a registry of DAX UDF (user-defined function) packages. Requires compatibility level **1702+** — installing upgrades CL automatically and is **irreversible**; confirm with user before running on models below 1702.

| Concept | Notes |
|---|---|
| Function format | `function 'PackageId.FunctionName' = ( p1: STRING, p2: NUMERIC VAL, e: SCALAR EXPR ) => ...` |
| Parameter modes | `VAL` (eager, pre-evaluated); `EXPR` (lazy, evaluated in callee context). `EXPR` required for measure refs |
| Parameter types | `STRING`, `INT64`, `NUMERIC VAL`, `SCALAR EXPR`, `ANYVAL`, `ANYREF EXPR`, `COLUMN` |
| Tracking annotations | `DAXLIB_PackageId`, `DAXLIB_PackageVersion` on every function |
| Call syntax | `[PackageId.FunctionName](arg1, arg2, ...)` — bracket notation like a measure |
| Package tracking | Scan `$model.UserDefinedFunctions` by annotation to list/update/remove |

**CLI** (`daxlib`): `search | info | versions | functions | download` (standalone); `add | update | remove | installed` (require `--port <PORT>` and .NET 8 SDK). Updates replace all functions matched by `DAXLIB_PackageId` annotation; user-created functions are untouched.

SVG measures from `DaxLib.SVG` return `data:image/svg+xml;utf8,...`. Set the column's data category to **"Image URL"** so Power BI renders inline in Table/Matrix/Card/Multi-row Card.

### Calendar Column Groups (Compatibility Level 1604+)

Declarative date hierarchy + time intelligence mapping. A `Calendar` lives on a date table and contains one or more `CalendarColumnGroup` entries, each mapping a column to a `TimeUnit` enum. With calendars defined, `DATESYTD` / `DATESMTD` / `SAMEPERIODLASTYEAR` / `DATEADD` automatically adapt to the declared hierarchy.

| Time Unit | Purpose | Complete/Partial |
|---|---|---|
| `Year` | Complete year | complete |
| `Quarter` | Includes year context (`Q3 2024`) | complete |
| `QuarterOfYear` | Position 1-4 | partial |
| `Month` | Includes year (`January 2024`) | complete |
| `MonthOfYear` | Name/number without year | partial |
| `Week` | Includes year (`2024-W49`) | complete |
| `WeekOfYear` | Week number only | partial |
| `Date` | Specific date | complete |
| `DayOfMonth` / `DayOfWeek` / `DayOfYear` | Day positions | partial |

**Rules:**

- Calendar names must be unique across the entire **model**, not just the table
- Each calendar draws columns from one host table only
- Never repeat a time unit within the same calendar
- A column mapped to a unit in one calendar must map to the same unit in every other calendar it participates in
- Each column group has one **primary** column (sort key) + optional **associated** columns (display labels). If `Year Month` is sorted by `Year Month Number`, the Number column is primary
- Only **one** `TimeRelatedGroup` per calendar — combine `IsWeekend`, `Season`, `RelativeMonth`, etc. into it
- Week-based (ISO / 4-4-5) calendars: always pair ISO weeks with ISO year; map `Period` to the `Month` time unit

```powershell
$cal = New-Object Microsoft.AnalysisServices.Tabular.Calendar
$cal.Name = "Gregorian Calendar"
$g = New-Object Microsoft.AnalysisServices.Tabular.CalendarColumnGroup
$g.TimeUnit = [Microsoft.AnalysisServices.Tabular.TimeUnit]::Month
$g.PrimaryColumn = $dateTable.Columns["Year Month Number"]
$g.AssociatedColumns.Add($dateTable.Columns["Year Month"])
$cal.CalendarColumnGroups.Add($g)
$dateTable.Calendars.Add($cal)
$model.SaveChanges()
```

### Transactions and Rollback

`SaveChanges()` is a single atomic commit — any validation failure rolls back the whole batch. For pre-commit inspection, use `$model.UndoLocalChanges()` to discard pending modifications since the last save. There is no explicit begin/commit on the local AS proxy.

### Finding the Source File Path

TOM does not expose `.pbix`/`.pbip` path. Most reliable source is PBI Desktop's `User.zip` → `Settings.xml` → `FileHistory` entries (ordered by `lastAccessedDate`). The first entry is usually (but not guaranteed to be) the currently-open file. Confirm with user when ambiguous.

Fallbacks: non-Store install exposes path in `Get-Process PBIDesktop | Select MainWindowTitle`. `Win32_Process` `msmdsrv.exe` command line reveals the workspace path but **not** the source file.

### Reference

- Microsoft Learn: [Tabular Object Model (TOM) — introduction](https://learn.microsoft.com/analysis-services/tom/introduction-to-the-tabular-object-model-tom-in-analysis-services-amo)
- Microsoft Learn: [Install, distribute, and reference TOM (assembly split, NuGet, dependencies)](https://learn.microsoft.com/analysis-services/tom/install-distribute-and-reference-the-tabular-object-model)
- Microsoft Learn: [External tools in Power BI Desktop](https://learn.microsoft.com/power-bi/transform-model/desktop-external-tools)
- Comprehensive MS Learn link bundle (TOM/AMO/ADOMD APIs / TMSL refresh / DMVs / trace events / external-tools / compatibility levels / remote XMLA / DAXLib): [references/REFERENCE.md](references/REFERENCE.md)

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| TOM connect fails | Thin report connected to remote model; Direct Lake; no model loaded | Use remote XMLA / Power BI REST; open a real model |
| Multiple `msmdsrv` processes | Multiple PBI Desktop windows open | Enumerate all ports, read `Databases[0].Name`, ask user |
| Short-name reader returns blank | ADOMD returns qualified column names | Iterate by index; use `GetName($i)` |
| `Register-ObjectEvent` sees empty events | Action block runs in isolated runspace | Pass synchronized ArrayList via `-MessageData` |
| EVALUATEANDLOG silent | Cached results; engine optimization; known `COUNTROWS` bug | Clear cache; restructure wrapper; some calls emit nothing |
| `VertiPaqSEQueryCacheMatch` crashes trace | `Duration`/`CpuTime` columns unsupported | Add only TextData + EventClass |
| Bash eats `$env:TEMP` / `$server` | Bash interpolation before PowerShell sees it | Single-quote `-Command` or use `.ps1` with here-string |
| `TmdlSerializer` type missing | Stale `.retail.amd64` package | Upgrade NuGet package or use Fabric REST definition APIs |
| daxlib upgrade irreversible | CL 1702 forced on install | Confirm with user first; older tools won't open the model afterward |
| Refresh exceeds bash timeout | Default 120000ms too low | Set `timeout: 300000` or higher |
| Save appears lost | Forgot `$model.SaveChanges()` | Always save; no Ctrl+Z undo afterward |
| Orphaned `msmdsrv` process | Forgot `$server.Disconnect()` | Always disconnect in `finally`/cleanup |
| Calendar collision | Same time unit twice, or name not globally unique | One time unit per calendar; globally unique names |
