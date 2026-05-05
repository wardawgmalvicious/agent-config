# MS Learn link bundle — Fabric SQL Database

Curated set of Microsoft Learn pages relevant to Fabric SQL Database — the Azure SQL Database engine hosted inside a Fabric workspace. Covers concept and overview, create/connect/deploy, supported feature matrix vs Azure SQL Database, security and authorization, OneLake replication / SQL analytics endpoint, backup, source control and SqlPackage CI/CD, GraphQL, and billing.

The 3 highest-leverage entry points (overview, feature comparison vs Azure SQL DB, limitations) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Scope note:** This bundle covers Fabric SQL Database only. For Fabric Warehouse (the distributed Synapse-engine warehouse with a different supported feature set), see the `fabric-warehouse` skill.

## Concept and overview

- [SQL database in Fabric (overview)](https://learn.microsoft.com/fabric/database/sql/overview) — concept, OneLake auto-mirroring, source-control integration, GraphQL, capacity management, elastic-pool equivalent. Read first.
- [Features comparison: Azure SQL Database vs Fabric SQL database](https://learn.microsoft.com/fabric/database/sql/feature-comparison-sql-database-fabric) — side-by-side delta. Critical reference for porting Azure SQL code or assessing Fabric SQL fit.
- [FAQ for Fabric SQL database](https://learn.microsoft.com/fabric/database/sql/faq) — quick answers to common architecture / tier / pricing questions.
- [Decision guide: Choose a SQL database in Fabric](https://learn.microsoft.com/fabric/database/sql/decision-guide) — Fabric SQL DB vs Warehouse vs Cosmos DB in Fabric vs Mirrored DB. When to pick each.

## Create, connect, deploy

- [Create a SQL database in the Fabric portal](https://learn.microsoft.com/fabric/database/sql/create) — UI walkthrough.
- [Connect to your Fabric SQL database](https://learn.microsoft.com/fabric/database/sql/connect) — connection patterns: SQL editor, SSMS, ADS, MSSQL VS Code extension.
- [Create a SQL database via REST API](https://learn.microsoft.com/fabric/database/sql/deploy-rest-api) — PowerShell 5.1 and 7.4 worked examples for SQL database CRUD via the Items API. Pair with `fabric-rest-api`.
- [Create a SQL database via Fabric CLI](https://learn.microsoft.com/fabric/database/sql/deploy-cli) — `fab` CLI alternative for programmatic SQL DB creation. Pair with `fabric-cli`.

## Limitations and supported features

- [Limitations in SQL database in Microsoft Fabric](https://learn.microsoft.com/fabric/database/sql/limitations) — comprehensive feature matrix vs Azure SQL Database. Per-feature support: BACKUP, CDC (no), CREATE LOGIN (no — Entra principals only), TDE (no — service-managed encryption only), Always Encrypted (no), Application roles (no), Ledger (no), Resource pools (no). Authoritative source for "does X work in Fabric SQL DB?".

## OneLake replication and SQL analytics endpoint

- [SQL analytics endpoint for Fabric SQL database](https://learn.microsoft.com/fabric/database/sql/sql-analytics-endpoint) — read-only T-SQL surface over the auto-mirrored Delta tables.
- [SQL database in Fabric (SQL Server docs)](https://learn.microsoft.com/sql/sql-server/fabric-database/sql-database-in-fabric) — the Microsoft SQL Server docs perspective; covers the change-feed schema, system objects (`changefeed.*`) you should not modify, mirroring relationship.

## Security and authentication

- [Security overview for SQL database in Fabric](https://learn.microsoft.com/fabric/database/sql/security-overview) — layered model entry point.
- [Microsoft Entra authentication](https://learn.microsoft.com/fabric/database/sql/authentication) — Fabric SQL DB requires Entra (no SQL auth, no Windows logins). User vs service-principal auth.
- [Authorization in SQL database in Fabric](https://learn.microsoft.com/fabric/database/sql/authorization) — Fabric workspace roles + item permissions (Read / ReadData / ReadAll / Share / Write) + SQL granular permissions.
- [Configure SQL access controls](https://learn.microsoft.com/fabric/database/sql/configure-sql-access-controls) — managing database-level roles in the Fabric portal vs T-SQL.
- [Auditing for SQL database in Fabric](https://learn.microsoft.com/fabric/database/sql/auditing) — audit log surface, OneLake destination (`{workspace_id}/{artifact_id}/Audit/sqldbauditlogs/`), `sys.fn_get_audit_file_v2` query path, configuration scenarios and predicate filters.
- [Protect databases with Purview protection policies](https://learn.microsoft.com/fabric/database/sql/protect-databases-with-protection-policies) — sensitivity-label-driven access policies on Fabric SQL DB.

## Backup and restore

- [Automatic backups in SQL database in Fabric](https://learn.microsoft.com/fabric/database/sql/backup) — system-initiated backups, 7-day retention (zone-redundant, no LTR), portal-only restore, same-workspace point-in-time restore only.

## Source control, SqlPackage, CI/CD

- [SQL database source control integration in Fabric](https://learn.microsoft.com/fabric/database/sql/source-control) — Git integration, automatic SQL project generation in the repo, commit/update flow, branching with workspace mapping, post-deployment scripts. Tutorial format.
- [SqlPackage with SQL database in Fabric](https://learn.microsoft.com/fabric/database/sql/sqlpackage) — `.dacpac` extract / publish workflow against Fabric SQL DB; cross-platform CLI.
- [SQL projects automation (CI/CD)](https://learn.microsoft.com/sql/tools/sql-database-projects/sql-projects-automation) — `dotnet build` of `.sqlproj` → `.dacpac` → SqlPackage publish. Build-once-deploy-many pipelines, `Script` action for plan review before apply.

## GraphQL API

- [Create a GraphQL API for SQL database](https://learn.microsoft.com/fabric/database/sql/graphql-api) — Fabric portal walkthrough for exposing SQL DB tables/views/procs via GraphQL.

## Billing and capacity

- [Billing and utilization reporting for SQL database](https://learn.microsoft.com/fabric/database/sql/usage-reporting) — Capacity Metrics app columns specific to SQL DB.
