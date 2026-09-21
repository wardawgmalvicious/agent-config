# Warehouse platform features

Feature/GA status, GPU query acceleration, and source control — workspace and
tenant-level concerns rather than things that change the T-SQL you write.

## Capability matrix

| Capability | Warehouse |
|---|---|
| CREATE / ALTER / DROP base tables | ✅ |
| INSERT / UPDATE / DELETE / MERGE | ✅ (MERGE **GA Jan 2026**) |
| COPY INTO, OPENROWSET (read + ingest) | ✅ |
| `bcp` bulk copy utility | 🔶 Preview (`BULK LOAD` / `BULK INSERT` T-SQL not supported) |
| Transactions | ✅ (snapshot isolation only) |
| `IDENTITY` columns (`bigint` only) | ✅ (**GA Aug 2026**) |
| Time travel (`OPTION (FOR TIMESTAMP AS OF ...)`) | ✅ (1–120 day **table-history** retention, default 30) |
| Dropped-warehouse recovery (workspace Recycle bin) | ✅ (GA July 2026 — 7–90 day **item** retention, default 7; different window from time travel) |
| GPU query acceleration | 🔶 Limited preview (registration form; workspace-level toggle) |
| Time travel on **SQL analytics endpoint** | 🔶 Preview (June 2026 — New metadata sync only) |
| Warehouse Snapshots | ✅ (GA — created via REST API / portal, not T-SQL) |
| `sys.sp_get_table_health_metrics` (SQLEP, Lakehouse tables) | ✅ (GA June 2026) |
| Source control (Git integration + deployment pipelines) | 🔶 Preview (item definition **2.0**, Aug 2026) |
| CREATE VIEW / FUNCTION / PROCEDURE / SCHEMA | ✅ |
| TRUNCATE TABLE | ✅ |
| `ALTER COLUMN` | 🔶 Preview |
| Cursors | ❌ |
| `DEFAULT` / `CHECK`; enforced FK / PK / UNIQUE | ❌ |

## Query Acceleration — GPU (Preview)

GPU co-processing for eligible T-SQL. No query rewrites, no schema changes, no data movement — Fabric splits the plan and offloads eligible operators (scans, joins, aggregations) to a GPU engine sitting alongside the CPUs in the same compute node.

**The blast radius is the workspace, not the item.** The toggle lives in **Workspace settings → Fabric Warehouse → Query Acceleration**, and once on it applies to **every warehouse and SQL analytics endpoint in that workspace**. Toggling it either way **cancels every query currently running in the workspace** — do it in a quiet window.

- **Limited preview** — access is granted per tenant via a [registration form](https://aka.ms/GPU-FabricDW), first-come first-served, and the capacity must sit in a supported region (East US, East US 2, South Central US, South East Asia, Germany West Central at time of writing).
- **Billed on a separate, higher-rate CU meter.** Once enabled, *all* queries in the workspace bill through it — not just accelerated ones.
- **Eligibility is per query, and two things commonly disqualify one**: `nvarchar` (limited support — prefer `varchar(8000)`, which you want in Fabric Warehouse anyway) and case-insensitive collations (prefer the default binary/CS collation). Write operations never accelerate; read-heavy scans/joins/aggregations over up to ~1 TB benefit most, especially under concurrency.
- **Verify rather than assume it applied**: `queryinsights.exec_requests_history.is_accelerated` (1/0), `number_of_accelerated_runs` in `long_running_queries` and `frequently_run_queries`, the **Query Acceleration** column in portal Query history, or the **Query Acceleration** operator in an SSMS graphical plan. `is_accelerated = 0` means either disabled *or* ineligible — the column doesn't distinguish them.

## Source Control and CI/CD (Preview)

Source control for Fabric Warehouse is a **preview** feature — both Git integration and deployment pipelines. Since **August 2026** it runs on **warehouse item definition 2.0** ("Warehouse CI/CD 2.0"): DacFx-based incremental extraction and deployment in place of whole-definition replacement.

- **Git integration** (workspace-level, Azure DevOps or GitHub): commit/sync warehouse objects, branch out to feature workspaces, revert, bi-directional sync; automatable via Fabric REST APIs. Warehouse appears as a supported item (preview) in the Source control panel.
- **Deployment pipelines**: promote across Dev → Test → Prod stages.
- **IDE / local**: VS Code with **DacFx** (SQL database projects) for schema management, **SSMS** for interactive dev; external CI/CD via **SQLPackage CLI**, DacFx tasks, and REST APIs.
- Use SQL database projects + Git for incremental object-level change and history; use deployment pipelines for environment promotion.
- **SQL analytics endpoint CI/CD** — separate, newer preview (Aug 2026): a SQLEP's *definition* (the schemas, views, procedures and functions you add on top of the auto-generated tables) can be managed as a **DacFx database project** in Git alongside other Fabric items, and promoted as incremental schema changes through deployment pipelines. Previously the endpoint was a deployment side-effect of its parent item, not a versioned artifact. Evidence so far is the What's New row only — there is no dedicated Learn page — so treat the mechanics as unconfirmed and check before designing a release process around it.
- **Collation-mismatch gotcha**: promoting/branching/merging when source and target warehouses were created with different collations is **not supported** — deployment may succeed but dataset collation isn't reconciled. Four scenarios are named: pipeline promotion, branch-out, branch switch, and cross-workspace merge — each can succeed at the Git level with the dataset collation left wrong. Fix with the `dw-collation-error-update-tmsl` script in the Fabric toolbox.

### Definition 2.0 and the upgrade

`config.version` in the warehouse's `.platform` says which version it is on.
2.0 (`Microsoft.Build.Sql` SDK `2.3.0-preview.1`) moves shared queries to a
`.sharedqueries` folder at the project root, stops tracking `XMLA.json`, adds
a project-level `.gitignore` and system references to the `.sqlproj`, and
re-extracts every object definition (constraints, `IDENTITY`, `CLUSTER BY`)
— so the upgrade commit is large and the ones after it are small.

Fabric never applies it for you; a **System update available** banner appears
in Source control.

1. **Commit every pending change first.** Otherwise the upgrade lands in the
   same commit as your work and cannot be reverted separately.
2. **Apply system updates.** It upgrades **every warehouse in the workspace
   at once** — there is no per-item selection.
3. Review each warehouse's diff (the `.sqlproj` SDK version is the tell) and
   commit.

### What a sync or deploy actually does — the fixed DacFx settings

| Setting | Consequence |
|---|---|
| `BlockOnPossibleDataLoss = true` | Any change that would drop or truncate user data **fails** the sync/deploy. Apply the destructive statement live, then sync — `SKILL.md` *Schema Evolution* |
| `DropObjectsNotInSource = false` | An object deleted from source is **not** dropped in the target, and the deploy still reports **success**. Check *Compare* after any deploy that removed an object |
| `IncludeTransactionalScripts = false` | The generated script is non-transactional — a multi-statement schema change can stop half-way, unlike the same T-SQL run by hand inside `BEGIN TRAN` |
| `ExcludeObjectTypes = Logins, Users, Permissions` | Security never deploys; migrate GRANT/DENY/RLS separately |
| `GenerateSmartDefaults = true` | Tightening a column (`NULL`→`NOT NULL`, new column with a default) gets baseline values populated rather than failing |
| `ScriptDatabaseOptions = false` | `ALTER DATABASE ... SET` is never scripted — so a `data-retention` change does not travel through source control (inferred: retention is an `ALTER DATABASE` option) |

### Build-time failures that pass `sqlcmd`

Commit, update-from-Git, branch-out and new-workspace-from-repo all run a
DacFx **build** of the project, and the build validates references the engine
never checks. Each of these runs fine interactively and fails only there:

- **Three-part reference to the warehouse's own object** (`[ThisWarehouse].[dbo].[T]` from inside ThisWarehouse) — treated as external; the object ends up defined twice. Two-part names for self-references; three-part only for a genuinely different warehouse.
- **Unqualified column where an object references two or more tables in another warehouse** — the build cannot bind it even when only one of those tables has the column. Alias-qualify every column in cross-warehouse statements.
- **Same schema name spelled with different capitalisation** across cross-warehouse references, on a **case-insensitive** collation only — the build emits one `CREATE SCHEMA` per spelling. Fabric's default `Latin1_General_100_BIN2_UTF8` is case-sensitive and unaffected; check `<ModelCollation>` in the `.sqlproj` (`CI` = affected).
- **`SQL71501 ... [dbo].[V].[Col] or [dbo].[V].[alias]::[Col]`** — the `::` candidate marks a known product bug in validation, not a real ambiguity, and aliasing does not clear it. First rule out a genuinely missing object elsewhere in the same run; then, in order: replace `SELECT *` in CTEs and derived tables with explicit column lists, split the view so each ambiguous source is its own view, stop joining `OPENROWSET(BULK ...)` to another dynamically shaped source in one statement.
- **Uppercase built-in type name** (`SYSNAME`) — see `coding-tsql` *Casing*.
- **Changing a column that has `IDENTITY`** — commit/update fails until `IDENTITY_INSERT` is enabled for the table.
- **Stale `.sqlproj` SDK pin** — see `fabric-gotchas`, the `MSB4019` row.
- **Cyclic references between warehouse items** — fail branch-out and Git→workspace sync.
- **A Dataflow Gen2 with a warehouse output destination** — creates a `DataflowsStagingWarehouse` item in the repo that blocks commit and update.

### What extraction silently drops

- An explicit `COLLATE` equal to the warehouse default is **not written to Git** and never shows as a difference — only a column whose collation differs from the default keeps its clause.
- `XMLA.json` (the default semantic model's metadata) — excluded from every commit and update.
- Security objects — permissions need their own export and migration path.
- Commit granularity is the warehouse **item**, never the object; SQL analytics endpoints have no version control of their own (separate preview, above).

## Microsoft Learn

- [Query acceleration (preview)](https://learn.microsoft.com/fabric/data-warehouse/query-acceleration)
- [Git integration for Fabric warehouse development](https://learn.microsoft.com/fabric/data-warehouse/git-integration) — DacFx incremental extraction, and the authoritative *Limitations in Git integration* list.
- [How to use Git integration for warehouse development](https://learn.microsoft.com/fabric/data-warehouse/how-to-git-integration) — the commit / branch / sync walkthrough, and local development against the database project.
- [Troubleshoot Git integration](https://learn.microsoft.com/fabric/data-warehouse/troubleshoot-git-integration) — every build-time failure above, each with before/after SQL.
- [Upgrade the system file version of a warehouse](https://learn.microsoft.com/fabric/data-warehouse/upgrade-warehouse) — the *Apply system updates* procedure.
- [Release notes for the warehouse system file](https://learn.microsoft.com/fabric/data-warehouse/warehouse-system-file-version-history) — what each definition version changed; 2.0 is the current one.
- [Deploy a warehouse using pipelines](https://learn.microsoft.com/fabric/data-warehouse/deploy-pipelines) — the fixed DacFx deployment settings and the drop-table limitation.
- [Develop warehouse projects in Visual Studio Code](https://learn.microsoft.com/fabric/data-warehouse/develop-warehouse-project) — local publish, where `BlockOnPossibleDataLoss` and `DropObjectsNotInSource` *are* yours to set.

## Snapshot-conflict retry recipe

Full mitigation list from the conflict matrix in `SKILL.md`:

> **Mitigation**: serialize writes per table; INSERT-only patterns (append then reconcile); keep transactions short; retry with TRY/CATCH around DML, increment retry count, `WAITFOR DELAY '00:00:02'` (use exponential backoff in production), `THROW` on max retries.
