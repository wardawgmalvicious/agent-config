# MS Learn link bundle — Fabric gotchas & troubleshooting

Curated set of Microsoft Learn pages that back the cross-cutting error/gotcha index in this skill. Organized by error class, each entry pairs the gotcha with the canonical Microsoft documentation that explains the underlying constraint and (where relevant) the fix.

The 3 highest-leverage entry points (Warehouse troubleshooting, T-SQL surface area limitations, transactions / write-write conflicts) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Use pattern:** when you hit a specific gotcha listed in the parent SKILL.md table, jump directly to the matching link below for the deep dive.

## Authentication and authorization (401 / 403 / 404)

- [Microsoft Entra authentication for Fabric SQL](https://learn.microsoft.com/fabric/data-warehouse/entra-id-authentication) — confirms SQL auth is unsupported; explains the Entra-only model. Companion to the 401 token-audience gotcha.
- [Workspace roles in Fabric](https://learn.microsoft.com/fabric/fundamentals/roles-workspaces) — Admin / Member / Contributor / Viewer responsibility matrix. Background for the 403-on-Power-BI-API-as-Viewer gotcha.
- [Item-level permissions (Read / ReadData / ReadAll / Share / Write)](https://learn.microsoft.com/fabric/security/permission-model) — the layer underneath workspace roles; relevant when 404 EntityNotFound is actually a permission issue.
- See `fabric-auth` skill for the full token audience table and `az login` flow variants.

## Runtime ID vs `.platform` `logicalId` (`PowerBIEntityNotFound`)

- [Fabric Items REST API: list / get](https://learn.microsoft.com/rest/api/fabric/core/items) — endpoint that returns the **runtime** item ID needed by pipeline / Variable Library / `getDefinition` / `updateDefinition` calls.
- [Item definition overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview) — explains the `.platform` part and its `logicalId` field, which is *separate* from the runtime ID.
- See `fabric-rest-api` skill for the canonical rules.

## TDS connection (Warehouse / SQL endpoint / SQL Database)

- [Connect to Fabric SQL endpoint or warehouse with SQL Server Management Studio](https://learn.microsoft.com/fabric/data-warehouse/connectivity) — connection-string fields, `Initial Catalog = <item display name>` (NOT FQDN), `Encrypt=Yes`, port 1433.
- [Connectivity in Fabric Data Warehouse — networking and firewall](https://learn.microsoft.com/fabric/data-warehouse/connectivity) — what to allow through outbound firewall (`*.datawarehouse.fabric.microsoft.com`, `*-pbidedicated.windows.net`).
- See `fabric-auth` skill for the TDS connection essentials table (MARS unsupported, etc.).

## Snapshot conflicts (24556 / 24706) and transactions

- [Transactions in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/transactions) — full description of write-write conflicts, snapshot isolation enforcement (any explicit `SET TRANSACTION ISOLATION LEVEL` is silently ignored), table-level locking, the "first to commit wins" rule, MERGE-still-conflicts caveat.
- [Troubleshoot the Warehouse — write-write or update conflicts](https://learn.microsoft.com/fabric/data-warehouse/troubleshoot-fabric-data-warehouse) — the canonical 24556 / 24706 reference + what to collect before contacting support (workspace ID, statement ID, distributed request ID).
- [Retry pattern (Azure Architecture Center)](https://learn.microsoft.com/azure/architecture/patterns/retry) — exponential-backoff guidance the Fabric DW docs explicitly recommend for transient conflicts.

## Warehouse T-SQL surface limitations (`nvarchar` / `datetime` / `MERGE` / `ALTER COLUMN` / etc.)

- [T-SQL surface area in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/tsql-surface-area) — authoritative list of unsupported commands (CREATE USER, FOR XML, SET ROWCOUNT, materialized views, triggers, recursive queries, etc.). The supported-`ALTER TABLE` subset is explicit (ADD nullable column / DROP COLUMN / NOT ENFORCED constraints — nothing else); the supported variants can run inside `BEGIN TRAN ... COMMIT` (April 2026 GA, see `fabric-warehouse` Transactions section). `COPY INTO` `FILE_TYPE` accepts `PARQUET` / `CSV` / `JSONL` (JSONL added April 2026).
- [Data types in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/data-types) — the unsupported-types table with alternatives: `nvarchar` → `varchar` (UTF-8 collation), `datetime`/`smalldatetime` → `datetime2`, `money` → `decimal`, `image` → `varbinary`, `xml` → no equivalent, `json` → `varchar`, `geography`/`geometry` → varchar/varbinary with WKT/WKB.
- [Tables in Fabric Data Warehouse — limitations](https://learn.microsoft.com/fabric/data-warehouse/tables) — no computed columns, indexed views, partitioned tables, sequences, sparse columns, synonyms, triggers, unique indexes, UDTs, external tables; 1024-column limit; >750k objects disable metadata caching.
- [Fabric Migration Assistant for Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/migration-assistant) — workaround table (SQL auth → Entra, column-level encryption → DDM, scalar UDFs → inlineable only, identity columns differ).
- See `fabric-database` for which restrictions DON'T apply when the engine is Fabric SQL Database.

## COPY INTO authentication

- [Ingest data into your Warehouse using the COPY statement](https://learn.microsoft.com/fabric/data-warehouse/ingest-data-copy) — auth options (Storage Blob Data Reader on ADLS, SAS in CREDENTIAL, Storage account key) and common error patterns.

## TMDL validation (tabs vs spaces, `///` comments)

- [TMDL overview](https://learn.microsoft.com/analysis-services/tmdl/tmdl-overview) — language reference; tabs-only indentation, `///` for descriptions, `//` not supported.
- See `fabric-tmdl` skill for authoring rules and the common-mistake table.

## REST update-definition pitfalls (parts deletion, jobType)

- [Update item definition (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/core/items/update-item-definition) — confirms the API REPLACES the entire definition; omitting parts deletes them. The `?updateMetadata=true` flag for `.platform` updates.
- [Run on demand item job (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/core/job-scheduler/run-on-demand-item-job) — required `jobType` values: `RunNotebook`, `Pipeline`, `SparkJob`, `Refresh`, `TableMaintenance`. `DefaultJob` is *not* a valid value despite appearing in some examples.
- See `fabric-rest-api` skill for the LRO polling pattern.

## sqlcmd version / ODBC / connectivity

- [Install sqlcmd (Go version)](https://learn.microsoft.com/sql/tools/sqlcmd/sqlcmd-utility) — the modern cross-platform `sqlcmd` (`winget install sqlcmd`); the legacy ODBC version (`/opt/mssql-tools/`) is incompatible with Fabric's TDS endpoint configuration.
- [Connect with the mssql VS Code extension](https://learn.microsoft.com/sql/tools/visual-studio-code/mssql-extensions) — Entra-aware client.

## Lakehouse SQL endpoint slowness (small files)

- [Delta Lake table optimization and V-Order](https://learn.microsoft.com/fabric/data-engineering/delta-optimization-and-v-order) — OPTIMIZE + V-Order; the canonical fix for the small-file problem the gotcha calls out.
- [Run Delta table maintenance in Lakehouse](https://learn.microsoft.com/fabric/data-engineering/lakehouse-table-maintenance) — UI walkthrough for OPTIMIZE / VACUUM / Z-ORDER.

## Notebook upload `400 exceptionCulprit:1` (cell `source` shape)

- [Notebook item definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/notebook-definition) — the cell-source must be array-of-strings for both code and markdown cells; bare-string source is rejected.
- See `fabric-spark` skill for the canonical .ipynb-shape rules.

## Cross-database query restrictions

- [Tutorial: Cross-warehouse query in Fabric](https://learn.microsoft.com/fabric/data-warehouse/tutorial-sql-cross-warehouse-query-editor) — three-part naming, same-workspace and same-region requirement.

## Notebook collaboration / Spark errors

- [Fabric notebooks troubleshooting guide](https://learn.microsoft.com/fabric/data-science/fabric-notebooks-troubleshooting-guide) — collaboration conflicts, "Excessive query complexity" (Catalyst plan size), session timeout / connectivity errors. Includes the Fix-with-Copilot flow.

## Capacity throttling errors (`CapacityLimitExceeded`)

- [Smoothing and throttling in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/compute-capacity-smoothing-throttling) — SQL error code `24801` from SSMS / mssql VS Code when capacity rejects.
- [The Fabric throttling policy](https://learn.microsoft.com/fabric/enterprise/throttling) — full overage / carryforward / burndown model. See `fabric-monitoring` for the Capacity Metrics App reference.

## OneLake auth

- [OneLake security overview](https://learn.microsoft.com/fabric/onelake/security/get-started-security) — ABFS access, `Storage Blob Data Reader/Contributor` requirement, the `https://storage.azure.com/.default` audience requirement (NOT `datalake.azure.net`).
