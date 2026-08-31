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
| Source control (Git integration + deployment pipelines) | 🔶 Preview |
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

Source control for Fabric Warehouse is a **preview** feature — both Git integration and deployment pipelines.

- **Git integration** (workspace-level, Azure DevOps or GitHub): commit/sync warehouse objects, branch out to feature workspaces, revert, bi-directional sync; automatable via Fabric REST APIs. Warehouse appears as a supported item (preview) in the Source control panel.
- **Deployment pipelines**: promote across Dev → Test → Prod stages.
- **IDE / local**: VS Code with **DacFx** (SQL database projects) for schema management, **SSMS** for interactive dev; external CI/CD via **SQLPackage CLI**, DacFx tasks, and REST APIs.
- Use SQL database projects + Git for incremental object-level change and history; use deployment pipelines for environment promotion.
- **SQL analytics endpoint CI/CD** — separate, newer preview (Aug 2026): a SQLEP's *definition* (the schemas, views, procedures and functions you add on top of the auto-generated tables) can be managed as a **DacFx database project** in Git alongside other Fabric items, and promoted as incremental schema changes through deployment pipelines. Previously the endpoint was a deployment side-effect of its parent item, not a versioned artifact. Evidence so far is the What's New row only — there is no dedicated Learn page — so treat the mechanics as unconfirmed and check before designing a release process around it.
- **Collation-mismatch gotcha**: promoting/branching/merging when source and target warehouses were created with different collations is **not supported** — deployment may succeed but dataset collation isn't reconciled. Fix with the `dw-collation-error-update-tmsl` script in the Fabric toolbox.

## Microsoft Learn

- [Query acceleration (preview)](https://learn.microsoft.com/fabric/data-warehouse/query-acceleration)

## Snapshot-conflict retry recipe

Full mitigation list from the conflict matrix in `SKILL.md`:

> **Mitigation**: serialize writes per table; INSERT-only patterns (append then reconcile); keep transactions short; retry with TRY/CATCH around DML, increment retry count, `WAITFOR DELAY '00:00:02'` (use exponential backoff in production), `THROW` on max retries.
