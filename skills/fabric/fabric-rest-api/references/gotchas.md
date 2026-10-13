# Common gotchas & troubleshooting

An index from a symptom to its fix. Where another reference or skill
owns the fix, the row names that owner instead of restating it: read the
owner before acting. A fix with no other home stays in its row.

| Symptom | Cause | Fix, or its owner |
| --- | --- | --- |
| `401 Unauthorized` | Wrong token audience | [auth.md](auth.md): its audience table, then *Decoding a token to debug 401s* |
| `401` or `403` as a service principal whose token has the right audience, its app registration holding API permissions | Fabric authorizes a service principal by tenant settings and a workspace role or item permission; API permissions play no part | [auth.md](auth.md), *Decoding a token to debug 401s* |
| `Can't derive appropriate Azure AD resource from --url` from `az rest` | No `--resource` on a Fabric URL | [auth.md](auth.md), *`az rest --resource` requirement* |
| "No subscriptions found" at `az login`, before any Fabric call | A Fabric-only tenant, with no Azure subscription | [auth.md](auth.md), *`az login` flow variants* |
| `[AuthenticationFailed] Failed to get access token` from `fab` with `az` signed in, or `both_fab_and_onelake_tokens_required` | `fab` never reads the Azure CLI login, and its environment tokens come in a pair | [cli.md](cli.md), *Authentication* |
| `fab` hangs, or fails `Found xterm-256color, while expecting a Windows console` / `No Windows console found`; `InvalidPath` on export | A confirmation prompt with no console; an output folder that does not exist | [cli.md](cli.md), *Gotchas* |
| `403 Forbidden` on Power BI API | User has Viewer role | Refresh/data sources/permissions APIs require Contributor+. Stop retrying — it's permissions. |
| `401 PowerBINotAuthorizedException` from `executeQueries` as a service principal, with its tenant settings on and a workspace role | Service principals aren't supported on a model with RLS or SSO, whatever the setting, and a Direct Lake model uses SSO by default (documented; observed 2026-10-07, cause inferred) | Query as a user, or bind the model to a fixed-identity connection with SSO off, a security decision. See [[fabric-semantic-model-audit]] |
| `404 EntityNotFound` on getDefinition | Insufficient permissions masquerading as 404 | Check workspace role first; don't retry with different URLs |
| HTTP `411`, an HTML page titled *Length Required*, with no `errorCode` | A POST with no body and no `Content-Length`, as `curl -X POST` sends it: the front end refuses it before Fabric sees it (`getDefinition`; `git/disconnect`, 2026-10-12) | Send `-H 'Content-Length: 0'` or a `'{}'` body. See [the skill's body](../SKILL.md) — *Definition APIs* |
| `400 OperationHasNoResult` from `GET /v1/operations/{id}/result` after `Succeeded` | The operation has no result | [The skill's body](../SKILL.md), *Long-Running Operations (LRO)* |
| `az rest` prints nothing and exits 0 on `getDefinition`, a definition update or a create | A `202` it cannot show, its `Location` unseen | [The skill's body](../SKILL.md), *Long-Running Operations (LRO)* |
| `PowerBIEntityNotFound` / `EntityNotFound` from pipeline, Variable Library, or REST call | A `.platform` `logicalId` used where the runtime item ID belongs | [The skill's body](../SKILL.md), *Item IDs: Runtime vs logicalId* |
| `Login failed... database not found` | Wrong Initial Catalog | Use item display name, not FQDN ([auth.md](auth.md), *TDS connection essentials*). Verify workspace role. Connections with no Initial Catalog now land deterministically on `master` (drill-verified) — confirm with `SELECT DB_NAME()` and switch with `USE [<item display name>]` instead of reconnecting. |
| Error 24556/24706 snapshot conflict | Concurrent writes to same table | `fabric-warehouse`, *Snapshot Isolation Conflict Matrix*; its `references/platform-features.md` holds the retry recipe |
| `nvarchar` / `datetime` / `money` errors | Unsupported types in Fabric Warehouse | `fabric-warehouse`, *Unsupported Data Types*; `fabric-database` when the engine is SQL Database, which supports them |
| COPY INTO auth error | Missing Storage Blob Data Reader on ADLS | `fabric-warehouse`'s `references/t-sql-surface.md`, *Ingestion options* |
| MERGE failures in production | MERGE conflicts with any concurrent DML on the same table | `fabric-warehouse`, *Warehouse Authoring Rules*; `fabric-database` when the engine is SQL Database, which supports MERGE |
| ALTER COLUMN fails | Fabric Warehouse runs only a metadata-only widening, in preview | `fabric-warehouse`, *Schema Evolution*; `fabric-database` when the engine is SQL Database, which supports `ALTER COLUMN` |
| Table empty after Git sync of a DDL change (warehouse definition **1.0**) | Sync rebuilt the table, even for a nullable `ADD COLUMN`. A 2.0 warehouse refuses instead — next row | `fabric-warehouse`, *Schema Evolution* |
| Git sync or pipeline deploy fails `DataLoss: The column [s].[t].[c] is being dropped` + `Msg 50000 ... Rows were detected. The schema update is terminating` (definition **2.0**, preview) | DacFx runs with `BlockOnPossibleDataLoss = true`, not configurable. The generated guard is `IF EXISTS (SELECT TOP 1 1 FROM [s].[t])`, so any row in the table trips it — an all-NULL dropped column doesn't help | Capture what you need, then `ALTER TABLE s.t DROP COLUMN c` on the live warehouse, the target stage's for a pipeline, **before** syncing or deploying, so the plan carries no drop. See fabric-warehouse — *Schema Evolution* (observed on a Git sync, Sept 2026, and on a deployment-pipeline deploy, 2026-10-07; documented for pipelines) |
| TMDL validation error | Spaces instead of tabs, or `//` comments | `fabric-tmdl`, *Gotchas* |
| Parts missing after updateDefinition | Only modified parts sent | Must include ALL parts in every update |
| `DefaultJob` in job execution | Wrong jobType | [The skill's body](../SKILL.md), *Job Execution* |
| `429 Too Many Requests` carrying `RequestBlocked` or `CapacityLimitExceeded` | Your own request rate, or an overloaded capacity, which a retry does not help | [The skill's body](../SKILL.md), *Rate Limiting* |
| `FeatureNotAvailable` creating a Lakehouse, Warehouse, notebook or Spark job definition | The workspace has no capacity | [The skill's body](../SKILL.md), *Capacity* |
| `sqlcmd` not found or ODBC errors | Wrong sqlcmd version | Use Go version: `winget install sqlcmd` (not ODBC `/opt/mssql-tools/` version) |
| Slow / stale Lakehouse SQLEP queries | Small-file problem, or metadata-sync lag on newly-landed data | `fabric-spark`, *Lakehouse Table Maintenance*, and its metadata-sync preview's DMV and targeted refresh |
| Query Insights empty | Views not yet generated after creation | Wait ~2 minutes |
| OneLake 401 | Wrong storage audience | [auth.md](auth.md), its audience table |
| TDS connection timeout | Port 1433 blocked | [auth.md](auth.md), *TDS connection essentials* |
| Cross-database query fails | Items in different regions or workspaces | `fabric-warehouse`'s `references/t-sql-surface.md` |
| Notebook upload `400 exceptionCulprit:1` | Cell `source` is a bare string, not an array | `fabric-spark`, *Notebook REST API / UI Upload* |
| `CloudEventPropertyMissingException: ...type is missing` when publishing to a schema-associated Eventstream custom endpoint | Attributes sent in the JSON body / structured mode | `fabric-eventstream`, *Producing to a schema-associated custom endpoint* |
| `InvalidContent (first issue: ValueMismatch)` syncing Git → workspace | Variable Library value-set override names a nonexistent variable (rename not propagated to `valueSets/*.json`) or an empty `value` | `fabric-variable-library`, *Git-sync validation (`InvalidContent`)* |
| Deployment-rule dropdowns greyed out for a Direct Lake semantic model | DL on OneLake doesn't support data source rules; no M parameters exist yet for parameter rules (also requires item ownership) | `fabric-deploy`'s `references/deployment-pipelines.md`, *Item pairing and autobinding*; the M parameters are `fabric-tmdl`'s *Direct Lake Configuration* |
| `This query contains transformations that can't be used for DirectQuery` refreshing a Direct Lake model | A false alarm: the model page's **schema-and-data** ribbon refresh re-evaluates a parameterized source's M | `fabric-tmdl`, *Gotchas* |
| `Failed to resolve name '<Table>'. It is not a valid table, variable, or function name.` querying a Direct Lake model that arrived by Git sync, and `INFO.VIEW.TABLES()` empty, though `getDefinition` holds every table | Its tables are unprocessed until a first refresh | `fabric-tmdl`, *Direct Lake Configuration* |
| Semantic model refresh accepted (`202`), then `Failed` within a second, every object *Failed*: `The specified table '<T>' not found in the target model.` | The `objects` list names a table the model lacks | `fabric-data-pipeline`'s `references/REFERENCE.md`, *`PBISemanticModelRefresh`* |
| Report getDefinition returns a single `report.json` (`"format": "PBIR-Legacy"`) | Report never migrated to the enhanced PBIR folder format; PBIR file tooling can't process legacy | Request `GET .../getDefinition?format=PBIR` explicitly; if it still comes back legacy, upgrade the report (open + save as PBIP in Desktop, or rebuild) before file-level editing |
| `MissingDefinitionParts` on report create/updateDefinition | Part `path` values built with Windows backslashes | Part paths must use forward slashes (`definition/pages/.../visual.json`) — build them explicitly, never from `os.path` / `Join-Path` output |
| Report publishes fine but every visual is empty | Local `byPath` dataset reference pushed as-is, or PBIR field bindings name tables/columns that don't exist in the target model | Rebind `definition.pbir` to `byConnection` (`"connectionString": "semanticmodelid=<runtime-id>"`) before a single-item REST publish, as [the skill's body](../SKILL.md) *Definition APIs* says — Learn's Bulk Import example does send `byPath` to a model in the same request, unmeasured here; diff TMDL table/column names against the PBIR visual bindings to find mismatches |
| `Error loading dashboard / /tiles/N/queryRef ... must have required property 'baseQueryId'` | Malformed `queryRef.queryId` UUID — the schema's `oneOf` fails the query branch and reports the baseQuery branch instead | `fabric-realtime-dashboard`, *Load-time validation rules* |
| `Current tile size (12, 5) is smaller than the minimum supported tile size (15, 3)` in one Real-Time Dashboard tile, the rest fine. The portal prints two spaces before the second pair, so search on `minimum supported tile size` | A `multistat` tile smaller than its slot grid | `fabric-realtime-dashboard`, *Visuals* |
| `"LibraryManagementError": "An upgrade to the base Spark Python environment has been detected. Please republish the environment.\|UserError"`, or `warning: 1 deprecation (since 2.13.0); for details, enable :setting -deprecation or :replay -deprecation` with `Source: SparkCoreService` — on notebook or SJD execution | Fabric **Runtime 2.0**'s Python upgrade broke the environment item's python / wheel libraries | Republish the environment **empty-first**: remove all libraries → publish → re-add all libraries → publish again. See the Runtime 2.0 note below |
| Top-N visuals render empty AND the service report editor freezes on save-edits (report otherwise renders fine) | Hand-authored PBIR TopN filter with the subquery inlined in `In.Table`, or a bare `VisualTopN` condition, which passes schema validation and `pbir validate` | `pbir-report-workflow`, `references/filters.md` *TopN* |
| `520` / `Internal service error` / `"@permanent": false` from a Kusto admin command, with client advice to retry after backoff | A state check reported through the generic internal-error envelope — the envelope's own metadata and retry advice are wrong. Commonly `.rename tables` against tables with OneLake availability on | Read the **nested** `@message` before believing `@permanent`: *"Tables cannot be renamed as at least one table has mirroring policy enabled."* The command fails atomically, so treat it as a clean no-op and fix the state. Not the cold-table `520` below, which really is transient. See [[fabric-eventhouse]] — *Schema Evolution* |
| New column lands empty after a `.create-merge`, no error, success response with matching record count | Streaming ingestion is writing the cached schema | `fabric-eventhouse`, *Ingestion* |
| `InvalidShortcutPayloadBatchErrors`, "Target path doesn't exist" on a Lakehouse git sync | A OneLake shortcut names a target table that does not exist — this fails the **entire** Lakehouse update, not just that shortcut | Add a shortcut only after its target exists. Don't let a generator emit shortcuts from a declaration list: a contract can legitimately declare a table before it is created, and the shortcut file is where that gap becomes an outage. See the `fabric-git-serialization` rule |
| `SQL71501 ... unresolved reference ... [dbo].[SYSNAME]` failing a whole warehouse import on branch-out | Uppercase built-in type name under a case-sensitive model collation — DacFx resolves it as a missing UDT. The engine stores built-in type names lowercase, so uppercase in a repo file is always a divergence from the live object | Write built-in type names lowercase (`sysname`). It executes fine over sqlcmd, so it only surfaces at the DacFx build — which runs on branch-out and new-workspace-from-repo, not on ordinary syncs. See `coding-tsql` — *Casing* |
| `Incorrect syntax near '.'` importing a warehouse, from a generated `CREATE SCHEMA .sharedqueries;` | A workspace still on warehouse definition **1.0** read a `.sharedqueries` folder as a schema. Under **2.0** (preview) that folder at the project root is the documented home of every shared query — not a stray, and deleting it on a 2.0 warehouse deletes real queries | Upgrade the workspace (**Apply system updates** in Source control; every warehouse in it at once) so it understands the folder. Only where the workspace must stay on 1.0: remove the folder from that branch, recovering the scripts from git. Keep hand-authored `.sql` out of `*.Warehouse` folders either way — see [[fabric-warehouse]] — *Warehouse Authoring Rules* |
| `MSB4019`, missing `NuGet.Build.Tasks.Pack.targets`, building a warehouse `.sqlproj`; or a Git commit/update failing on `IDENTITY` / `CLUSTER BY` syntax | Stale `Microsoft.Build.Sql` SDK pin (`0.1.x`) in a repo committed before the warehouse moved to definition 2.0, itself preview (which pins `2.3.0-preview.1`). Not a migration-window blip — it recurs on every path that builds from the repo with no warehouse to sync from: new workspace ← existing repo, branch-out, restoring a deleted warehouse, or syncing from git right after the upgrade | Where the warehouse exists and is healthy, commit workspace → git first (*option A*) — **but it must already be on 2.0**, or the commit writes 1.0 back and the next sync fails identically. Otherwise edit the `.sqlproj` SDK version to the current NuGet release and commit (*option B*). An export or diff never rewrites the file |
| `Invalid folder path` ("Connection failed. Make sure the Git folder exists…") connecting a workspace to a new branch, with no **Create and sync** offered | The branch's only commit is empty (`git commit --allow-empty`), so its root is the empty tree (`git ls-tree <branch>` prints nothing) and Fabric finds no Git folder there. Not among the troubleshooting page's causes (observed once on GitHub, 2026-09-30; mechanism inferred from GitHub's `git/trees/<branch>` returning 404 on that commit) | Start the branch with a commit holding one file at its root, then connect: a lone `README.md` worked. Not a file in a subfolder: a Git folder with subdirectories but no item folder can't be connected either (troubleshooting page). Never create a branch Fabric will connect to with `--allow-empty`. Unverified: whether the root takes `/` or a blank folder field |
| `Git_HeadNotSynced` ("Workspace not synced to the branch head") on every portal commit, and no **Update all** in the Source control pane | The connected branch's head is a **merge commit** (inferred: observed once on GitHub, Git folder `/`, 2026-09-30). A push that changes no item folder is not the cause: single-parent docs-only commits leave `workspaceHead` ≠ `remoteCommitHash` with `changes` empty and no **Update all**, yet the next portal commit lands on top (observed 2026-09-30 and 2026-10-01), and so did one after four single-parent commits with no net item change. Commits stay disabled until the workspace updates (troubleshooting page) | `POST …/git/updateFromGit` with only `workspaceHead` and `remoteCommitHash` from `git/status`, then commit. Why that body cannot overwrite, the credentials it needs and how to poll it: [the skill's body](../SKILL.md) — *Git Integration APIs* |
| `WorkspaceHeadMismatch` from `git/updateFromGit`, or `WorkspaceAlreadyConnectedToGit` from `git/connect` | A `workspaceHead` that is not the service's; a connected workspace, where a branch move is a reconnect | [The skill's body](../SKILL.md), *Git Integration APIs* |
| A script filtering `git/status` `changes[]` on documented item type names skips items, without a word | `git/status` types items outside its documented enum | [The skill's body](../SKILL.md), *Git Integration APIs* |
| Deployment pipeline reports success, but a table dropped in source is still present in the target | `DropObjectsNotInSource = false` is fixed for warehouse deploys, and a skipped drop-table doesn't fail the run — the target silently drifts from source control | Drop it by hand on the target, accept the drift, or designate a post-deployment script (preview) that runs on every deploy — Learn's uses are cleanup and recreating objects, not table drops specifically, so test it and keep it idempotent. Check *Compare* after any deploy that removed an object; the green tick doesn't cover drops |
| A `404` from `fab api` on a deployment-pipeline path, reading like a missing feature | The wrong audience for that surface | `fabric-deploy`'s `references/deployment-pipelines.md`, *Through `fab`* |

> **Runtime 2.0 environment republish (Aug 2026):** the Python 3.13 upgrade in Fabric Runtime 2.0 breaks **environment items carrying python and wheel libraries**. The remedy is not idempotent-looking and not guessable: **remove all libraries → publish → re-add all libraries → publish again.** Republishing without emptying it first does not recreate the environment against the new Python. Nothing warns you before the switch, and once Runtime 2.0 is the default for new workspaces and environment items, a new item lands on it without opting in: planned for **late September 2026**, though Learn's runtime page still named 1.3 the default on 2026-10-09. See [[fabric-spark]] — `references/mlv.md` and `references/ai-functions.md` — for the runtime-version prerequisites either side of it.

---

## Best Practices Summary

### MUST

- Verify workspace has capacity before creating items (`capacityId` in workspace response)
- Use parameterized notebooks and pipelines — no hardcoded workspace/item IDs
- Use Delta Lake format for all Lakehouse tables
- Include time filters in KQL queries
- Label queries with `OPTION (LABEL = ...)` for tracking
- Always specify database name in SQL connections (`-d` flag or Initial Catalog)
- Use Entra ID auth everywhere — SQL auth not supported in Fabric

### PREFER

- Medallion architecture (Bronze/Silver/Gold) for data organization
- REST APIs for programmatic management over portal clicks
- Incremental processing over full refreshes
- CTAS over CREATE TABLE + INSERT for large transforms
- COPY INTO for external file ingestion
- DELETE + INSERT over MERGE for production upserts
- Distributed #temp tables (`ROUND_ROBIN`) over non-distributed
- `EXISTS` over `IN` for large subqueries
- `UNION ALL` over `UNION` when duplicates are acceptable
- Integer keys over string keys for relationships

### AVOID

- Hardcoded workspace/item IDs — discover via REST API
- Confusing `.platform` `logicalId` with runtime item ID — they are NOT interchangeable; runtime references need the portal/API ID. For a **portal-created** item the two are the same 16 bytes reversed, so you can derive one offline — deriving is fine, substituting still fails
- `SELECT *` without LIMIT on large tables
- Long-running transactions (increases conflict window)
- Singleton `INSERT...VALUES` at scale (creates tiny Parquet files)
- `DROP TABLE IF EXISTS` + `CREATE TABLE` to refresh (loses time-travel history) — use TRUNCATE + INSERT
- `IFERROR` in DAX (performance degradation)
- `FOR XML` (use `FOR JSON` instead)
- Manual `lineageTag` or `PBI_*` annotations in TMDL
- Unbounded streaming queries
- MARS in connection strings

## Reference

- Microsoft Learn: [Troubleshoot the Warehouse (canonical error/cause/fix)](https://learn.microsoft.com/fabric/data-warehouse/troubleshoot-fabric-data-warehouse)
- Microsoft Learn: [T-SQL surface area in Fabric Data Warehouse (unsupported commands)](https://learn.microsoft.com/fabric/data-warehouse/tsql-surface-area)
- Microsoft Learn: [Transactions in Fabric Data Warehouse (24556/24706 write-write conflicts)](https://learn.microsoft.com/fabric/data-warehouse/transactions)
- Comprehensive MS Learn link bundle (per-error-class deep-dive index — auth/IDs/TDS/snapshot/T-SQL/COPY/REST/Lakehouse SQLEP/notebook/throttling/OneLake): [gotchas-links.md](gotchas-links.md)

## See also

- [auth.md](auth.md) — token audience table (for 401 diagnosis)
- [The skill's body](../SKILL.md) — logicalId vs runtime ID detail
- fabric-warehouse skill — Warehouse-specific type and feature restrictions
- fabric-database skill — what's different when it's SQL Database (most restrictions don't apply)
- fabric-spark skill — notebook upload array-of-strings requirement
- fabric-realtime-dashboard skill — RealTimeDashboard.json wiring and validation rules
