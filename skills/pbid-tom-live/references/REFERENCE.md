# MS Learn link bundle — pbid-tom-live (Power BI Desktop / TOM / ADOMD)

Curated set of Microsoft Learn pages relevant to scripting an open Power BI Desktop model via its localhost `msmdsrv.exe` Analysis Services proxy — TOM (metadata), ADOMD.NET (DAX), the AMO/Core/Tabular assembly split, the external-tools registration mechanism Desktop uses, and the trace events / DMVs the parent skill uses for VertiPaq profiling and EVALUATEANDLOG capture.

The 3 highest-leverage entry points (TOM intro, AMO/TOM install + assembly reference, External tools in Power BI Desktop) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on scope:** This skill targets *local* Power BI Desktop scripting (msmdsrv on localhost). For *remote* XMLA endpoint scripting in the Fabric / Power BI service (which lifts most of the limitations, e.g. supports thin reports and Direct Lake), see the Microsoft Fabric XMLA endpoint docs linked below.

## TOM and AMO (managed metadata API)

- [Tabular Object Model (TOM) — introduction](https://learn.microsoft.com/analysis-services/tom/introduction-to-the-tabular-object-model-tom-in-analysis-services-amo) — what TOM is, the `Microsoft.AnalysisServices.Tabular` namespace, why it's an extension of AMO. Compatibility level 1200+ requirement.
- [Install, distribute, and reference TOM](https://learn.microsoft.com/analysis-services/tom/install-distribute-and-reference-the-tabular-object-model) — assembly split (Core / Tabular / AMO / Json), how to reference them in PowerShell / C#, NuGet vs MSI options, dependency diagram. Pairs with the parent skill's `Add-Type` setup and the recommendation to swap to the .NET 8 package when the `.retail.amd64` package fails.
- [Connect to an existing tabular server and database](https://learn.microsoft.com/analysis-services/tom/connect-to-existing-analysis-services-tabular-server-and-database) — `Server.Connect("Data Source=...")` pattern; what auth model is in effect.
- [AMO (Analysis Management Objects)](https://learn.microsoft.com/analysis-services/amo/developing-with-analysis-management-objects-amo) — the parent library; relevant only for multidimensional or pre-1200 scenarios (rare in modern Power BI).
- [Microsoft.AnalysisServices Namespace (.NET API reference)](https://learn.microsoft.com/dotnet/api/microsoft.analysisservices) — full per-class reference.
- [Microsoft.AnalysisServices.Tabular Namespace (.NET API reference)](https://learn.microsoft.com/dotnet/api/microsoft.analysisservices.tabular) — per-class reference for `Server`, `Database`, `Model`, `Table`, `Column`, `Relationship`, `Trace`, `Calendar`, `CalendarColumnGroup`, etc. that the parent skill uses.
- [Client libraries for connecting to Analysis Services](https://learn.microsoft.com/analysis-services/client-libraries) — download links for AMO/TOM and ADOMD.NET (NuGet + MSI).

## TMSL (refresh + database scripting)

- [TMSL reference](https://learn.microsoft.com/analysis-services/tmsl/tabular-model-scripting-language-tmsl-reference) — JSON command shape consumed by `$server.Execute(...)` for refresh / clearCache / etc.
- [Refresh command (TMSL)](https://learn.microsoft.com/analysis-services/tmsl/refresh-command-tmsl) — `full` / `calculate` / `automatic` / `dataOnly` / `clearValues` / `defragment` semantics — exactly the table the parent skill documents.
- [Database object (TMSL)](https://learn.microsoft.com/analysis-services/tmsl/database-object-tmsl) — for scripting the database envelope.

## ADOMD.NET (managed DAX query API)

- [Developing with ADOMD.NET](https://learn.microsoft.com/analysis-services/adomd/developing-with-adomd-net) — `AdomdConnection`, `AdomdCommand`, reader patterns, ExecuteReader vs ExecuteNonQuery (the parent skill's "Reader for EVALUATE, NonQuery for TMSL" rule).
- [DAX EVALUATE statement](https://learn.microsoft.com/dax/dax-queries#evaluate-statement) — the verb every ADOMD `ExecuteReader` ultimately consumes.

## DMVs (VertiPaq, sessions, schema)

- [Use DMVs to monitor Analysis Services](https://learn.microsoft.com/analysis-services/instances/use-dynamic-management-views-dmvs-to-monitor-analysis-services) — overview of the `$SYSTEM.*` DMVs, query model (subset of SQL).
- [DISCOVER schema rowsets reference](https://learn.microsoft.com/analysis-services/schema-rowsets/analysis-services-schema-rowsets) — full DMV catalog. Includes `DISCOVER_STORAGE_TABLE_COLUMN_SEGMENTS`, `DISCOVER_SESSIONS`, `DISCOVER_COMMANDS`, `TMSCHEMA_*` that the parent skill uses.

## Trace events (Server Timings, EVALUATEANDLOG, Profiler)

- [Analysis Services Trace Events overview](https://learn.microsoft.com/analysis-services/trace-events/analysis-services-trace-events) — the trace event surface.
- [QueryEnd / VertiPaqSEQueryEnd / VertiPaqSEQueryCacheMatch event classes](https://learn.microsoft.com/analysis-services/trace-events/query-events-data-columns) — the FE-vs-SE split events the parent skill subscribes to.
- [SQL Server Profiler with Analysis Services](https://learn.microsoft.com/analysis-services/instances/use-sql-server-profiler-to-monitor-analysis-services) — the GUI equivalent of the in-process Trace API the parent skill drives.
- [DAX EVALUATEANDLOG function](https://learn.microsoft.com/dax/evaluateandlog-function-dax) — semantics, PBI Desktop only / passthrough elsewhere, JSON payload schema, the known `COUNTROWS()` limitation.

## Power BI Desktop external-tools mechanism

- [External tools in Power BI Desktop](https://learn.microsoft.com/power-bi/transform-model/desktop-external-tools) — what an "external tool" is, the categories (semantic modeling / data analysis / misc / custom), how Desktop registers them.
- [Register an external tool](https://learn.microsoft.com/power-bi/transform-model/desktop-external-tools-register) — `*.pbitool.json` registration, where it lives. Useful when packaging a TOM/ADOMD PowerShell script as a one-click external tool.
- [Advanced data model management (usage scenario)](https://learn.microsoft.com/power-bi/guidance/powerbi-implementation-planning-usage-scenario-advanced-data-model-management) — the user-facing rationale for why TOM/ADOMD against Desktop is a sanctioned workflow.

## Compatibility levels (1200 / 1604 / 1702)

- [Compatibility level for tabular models](https://learn.microsoft.com/analysis-services/tabular-models/compatibility-level-for-tabular-models-in-analysis-services) — full table; 1200 is the TOM minimum, 1604 is required for Calendar Column Groups, 1702 for DAXLib UDFs (the parent skill's "irreversible CL upgrade" gotcha).

## Remote XMLA endpoint (Fabric / Power BI service — for the cases pbid-tom-live can't handle)

- [Semantic model connectivity with the XMLA endpoint](https://learn.microsoft.com/fabric/enterprise/powerbi/service-premium-connect-tools) — when to use the remote XMLA endpoint instead of the local msmdsrv (thin reports, Direct Lake, headless automation).
- [TOM against Power BI semantic models](https://learn.microsoft.com/analysis-services/tom/tom-pbi-datasets) — TOM connection-string variant for `powerbi://api.powerbi.com/v1.0/myorg/<workspace>`.
- [Fabric Workspace XMLA endpoint settings](https://learn.microsoft.com/fabric/enterprise/powerbi/service-premium-connect-tools#enable-xmla-read-write) — required tenant setting for write operations.

## DAXLib (CL 1702+ UDFs)

- [DAX user-defined functions (UDFs)](https://learn.microsoft.com/dax/user-defined-functions) — syntax (`function 'PackageId.FunctionName' = (...)`, parameter modes `VAL` / `EXPR`, parameter types).
- [daxlib.org](https://daxlib.org/) — the registry the parent skill's `daxlib` CLI consumes (third-party / Microsoft-adjacent — not on learn.microsoft.com).

## See also (this repo)

- `fabric-tmdl` — TMDL authoring rules at the file level
- `fabric-tmdl-api` — Fabric REST envelope for remote semantic-model definition CRUD (the alternative to TOM when the model lives in Fabric)
- `pbip-project-structure` — local project file layout for thick PBIP models
