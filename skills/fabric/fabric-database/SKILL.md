---
name: fabric-database
description: "Use when working with Fabric SQL Database — the Azure SQL Database hosted inside a Fabric workspace. Key point: this is a DIFFERENT engine from Fabric Warehouse and does NOT share its restrictions. nvarchar/datetime/money/triggers/MERGE/ALTER COLUMN/recursive CTEs/FOR XML/temporal tables/full-text search all work. Entra ID auth only (no SQL auth), token audience `database.windows.net`, tables auto-replicate to OneLake as Delta, standard .sqlproj format."
paths:
  - "**/*.SQLDatabase/**/*.sql"
---

# Fabric SQL Database

Fabric SQL Database is an Azure SQL Database hosted within a Fabric workspace. It is a **completely different engine** from Fabric Warehouse and does NOT share the Warehouse's restrictions.

## Key Differences from Fabric Warehouse

| Feature | Fabric Warehouse | Fabric SQL Database |
|---|---|---|
| Engine | Distributed Synapse DW | Azure SQL Database |
| `nvarchar`, `datetime`, `money` | Not supported | Fully supported |
| Triggers | Not supported | Fully supported |
| MERGE | Preview only | Fully supported |
| ALTER COLUMN | Not supported | Fully supported |
| Recursive CTEs | Not supported | Fully supported |
| `FOR XML` | Not supported | Fully supported |
| Transaction isolation levels | Snapshot only | All levels |
| `CREATE USER` | Not supported | Fully supported |
| Temporal tables | Not supported | Fully supported |
| Full-text search | Not supported | Fully supported |

## Fabric-Specific Context

- **Authentication**: Entra ID only — SQL auth is not supported in Fabric
- **Token audience**: `https://database.windows.net/.default` (same as Warehouse)
- **OneLake replication**: Tables automatically replicate to OneLake as Delta/Parquet
- **SQL projects**: Uses standard `.sqlproj` format for schema-as-code
- **Do NOT apply Warehouse T-SQL restrictions** to Fabric SQL Database code

## Reference

- Microsoft Learn: [SQL database in Fabric (overview)](https://learn.microsoft.com/fabric/database/sql/overview)
- Microsoft Learn: [Features comparison: Azure SQL Database vs Fabric SQL database](https://learn.microsoft.com/fabric/database/sql/feature-comparison-sql-database-fabric)
- Microsoft Learn: [Limitations in SQL database in Fabric](https://learn.microsoft.com/fabric/database/sql/limitations)
- Comprehensive MS Learn link bundle (concept / create+connect / limitations / OneLake mirroring / security / backup / source control & SqlPackage / GraphQL / billing): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-warehouse skill — the distributed DW engine with its own restrictions
- fabric-auth skill — `database.windows.net` token audience
