# Mirroring source matrix

Which kind of mirroring each source uses, where its own limitations live, and
the per-source detail that was actually drilled.

**Scope warning.** Of the per-source limitations pages, only **Azure SQL
Database** was read in full (2026-08-30). Everything under "Per-source
detail" below is drilled; everything else is a pointer. Do not state a
per-source limit from memory — the pages disagree with each other and with
the general limits, and they lag (`snowflake-limitations` still says a
500-table cap where the general pages say 1,000).

## The matrix

Source: `learn.microsoft.com/fabric/mirroring/overview`, fetched 2026-08-30.

| Source | Kind | Limitations / considerations page |
| --- | --- | --- |
| Azure SQL Database | Database | `mirroring/azure-sql-database-limitations` |
| Azure SQL Managed Instance | Database | `mirroring/azure-sql-managed-instance-limitations` |
| SQL Server | Database | `mirroring/sql-server-limitations` |
| Fabric SQL database | Database (automatic) | `database/sql/mirroring-limitations` |
| Azure Cosmos DB | Database | `mirroring/azure-cosmos-db-limitations` |
| Azure Database for PostgreSQL | Database | `mirroring/azure-database-postgresql-limitations` |
| Azure Database for MySQL (preview) | Database | `mirroring/azure-database-mysql-limitations` |
| Google BigQuery (GA Aug 2026) | Database | `mirroring/google-bigquery-limitations` |
| Oracle | Database | `mirroring/oracle-limitations` |
| SAP | Database | `mirroring/sap-limitations` |
| SharePoint List (preview) | Database | — |
| Snowflake | Metadata | `mirroring/snowflake-limitations` |
| Azure Databricks | Metadata | `mirroring/azure-databricks-limitations` |
| Dremio catalog (preview) | Metadata | — |
| AWS Glue catalog (preview) | Metadata | `mirroring/catalog-mirroring/aws-glue` |
| Azure Monitor (preview) | Metadata | `mirroring/catalog-mirroring/azure-monitor#considerations` |
| Open mirrored database | Open | `mirroring/open-mirroring-landing-zone-format` |

**Not in this matrix, despite appearing in Fabric What's New:** Snowflake
Iceberg mirroring (July 2026) and Google Lakehouse Runtime Catalog mirroring.
Neither has a page in the mirroring overview table as of 2026-08-30 and
neither was drilled — this skill says nothing about them.

**Supported regions:** database mirroring and open mirroring are available in
all Fabric regions.

## Per-source detail

### Azure SQL Database — drilled in full

The deepest per-source page, and a fair proxy for the shape of the SQL-family
constraints. Do **not** assume it transfers verbatim to MI or SQL Server.

**Database level**

- Writable **primary** database only.
- Cannot mirror if the database has CDC enabled, has Azure Synapse Link for
  SQL, or is already mirrored in another Fabric workspace.
- Cannot mirror if **delayed transaction durability** is enabled.
- 1,000-table cap; "Mirror all data" takes the first 1,000 sorted by schema
  then table name.
- `.dacpac` deployments need `/p:DoNotAlterReplicatedObjects=False` to modify
  mirrored tables.

**Permissions**

- The connecting principal needs **ALTER ANY EXTERNAL MIRROR** — included in
  `CONTROL` and in `db_owner`.
- Creating the mirroring requires workspace **Admin** or **Member**.
- RLS, object-level permissions, and dynamic data masking are **not
  propagated** to OneLake. Neither are Purview sensitivity labels.

**Network**

- The logical server's SAMI or UAMI must be enabled and be the **primary**
  identity. UAMI support is in preview.
- Don't remove the Azure SQL Database SPN's contributor permission from the
  mirrored database item.
- **Cross-tenant mirroring is not supported** — source and Fabric workspace
  must share a tenant.

**Table level**

- A table can't be mirrored if its primary key (or clustered index, absent a
  PK) uses: computed columns, user-defined types, `geometry`, `geography`,
  `hierarchyid`, `sql_variant`, `timestamp`, `datetime2(7)`,
  `datetimeoffset(7)`, `time(7)`.
- **Delta supports only six digits of precision.** `datetime2(7)` mirrors
  with the seventh digit trimmed; `datetimeoffset(7)` loses the time zone and
  the seventh digit.
- No clustered columnstore indexes.
- LOB columns over 1 MB are truncated to 1 MB in OneLake.
- Cannot mirror tables using: temporal or ledger history tables, Always
  Encrypted, in-memory tables, graph, external tables.
- Cannot mirror a table with a `json` or `vector` column, and cannot ALTER a
  column to those types while the table is mirrored.
- Disallowed DDL on mirrored source tables: switch partition, alter primary
  key. Any other DDL change reseeds that table.
- **Primary keys stopped being required in April 2025** — but existing
  PK-less tables are not picked up automatically even with "Automatically
  mirror future tables". Stop and start replication (reseeds everything) to
  detect them; the documented workaround is creating and dropping a throwaway
  table to force a source inventory.

**Column level**

Cannot be mirrored: computed columns, `image`, `text`/`ntext`, `xml`,
`rowversion`/`timestamp`, `sql_variant`, UDTs, `geometry`, `geography`.

**Item level**

- Stopping mirroring disables it completely; starting reseeds all tables.

### AWS Glue catalog (preview) — drilled from search excerpts only

Metadata mirroring. Only the catalog structure is mirrored; Iceberg table
data stays in Amazon S3 and is reached through shortcuts.

- Connects to the **AWS Glue Iceberg REST catalog** endpoint,
  `https://glue.<Region>.amazonaws.com/iceberg`. **Warehouse** is the 12-digit
  AWS account ID. Authentication kind: **Key** (IAM access key ID + secret).
- **Delegated authorization** — all mirroring access uses the credential of
  whoever created the connection.
- Required IAM permissions: `glue:GetCatalog`, `glue:GetDatabases`,
  `glue:GetDatabase`, `glue:GetTables`, `glue:GetTable`; and `s3:GetObject`,
  `s3:GetBucketLocation`, `s3:ListBucket` on the buckets holding the Iceberg
  data.
- If **AWS Lake Formation** governs the catalog, grant that same IAM identity
  the equivalent Lake Formation permissions — otherwise the databases and
  tables simply don't appear in the selection list.
- **Automatically sync future tables** is on by default and covers database
  and table additions and deletions. Unselecting a database unselects all its
  tables; reselecting it reselects them all.
- Creates a mirrored AWS Glue catalog item plus a SQL analytics endpoint, and
  one shortcut per table. Databases with no tables aren't shown.
- Data changes propagate in seconds to several minutes.

### Azure Monitor (preview) — drilled in full

Metadata mirroring, but **connection-based rather than replication-based**.
The mirrored item points at the same Delta Parquet storage Azure Monitor
already uses. Creates an **Eventhouse** endpoint; shortcuts from Eventhouse
are the primary access path, with a Lakehouse OneLake shortcut for batch.

**Auth modes**, chosen at connection creation and **immutable**:

| Mode | When | Note |
| --- | --- | --- |
| **Workspace identity** | Same-tenant production | No dependence on a user's lifecycle |
| **Service principal** | Cross-tenant | Required when the tenants differ |
| **Organizational account (OAuth)** | Interactive, same tenant | Breaks if that user leaves the tenant |

Creating the connection needs `Microsoft.Authorization/roleAssignments/write`,
`Microsoft.OperationalInsights/workspaces/query/read`, and
`Microsoft.OperationalInsights/workspaces/read` on the Log Analytics
workspace — or Owner / User Access Administrator / RBAC Administrator. Once
it exists, other users reuse it with **Fabric workspace access only**.

**Security caveat worth stating out loud.** Azure RBAC on the Log Analytics
workspace and Fabric permissions on the mirrored item are independent systems
with no identity correlation. A user denied a table in Azure can read it
through the mirrored item. Log Analytics row- and column-level security does
not carry through, and during preview **all** tables in the connected
workspace are exposed regardless of table-level protection. Treat the
mirrored item as a new attack surface with its own access review.

**Preview constraints**

- ~**500 tables** per mirrored item (soft). Split large workspaces across
  several items.
- **No historical backfill** — new data only.
- Read-only; no write-back.
- Tables take about **15 minutes** to appear; the item appears immediately.
- Missing system columns: `_ResourceId`, `_SubscriptionId`, `Type`.
- **Purging takes two operations** — the Log Analytics data purge API *and*
  the Lake Data Purge API. Purging one does not purge the other.
- Cross-region reads work but may incur egress.

**Cost**: no duplicated storage. Azure Monitor bills ingestion, retention,
and its own query compute; Fabric bills Eventhouse/Spark/semantic-model
compute. Queries through the Eventhouse or Lakehouse shortcut consume Fabric
capacity instead of Azure Monitor query compute — use the Eventhouse endpoint
for exploration and a shortcut for ongoing queries.

Microsoft ships an onboarding skill for this in the Skills for Fabric repo:
`azmon-mirroredcatalogs-operations-cli`.

### Snowflake — pointer only, one drilled note

Metadata mirroring. Its limitations page still states a **500**-table cap
where the general pages say 1,000, and it records that native tables only are
supported (external, transient, temporary, and dynamic tables are not) and
that Snowflake auth is username/password or Entra SSO. **Mirroring views**,
the paid preview extended capability, is currently Snowflake-only.
