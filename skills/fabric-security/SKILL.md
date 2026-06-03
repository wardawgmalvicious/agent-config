---
name: fabric-security
description: "Use for the Fabric security/permission model. Covers the layers (workspace roles Admin/Member/Contributor/Viewer, item-level Read/ReadData/ReadAll, OneLake security data access roles, SQL GRANT/DENY/REVOKE), Admin/Member/Contributor bypass of RLS/CLS/DDM, least-privilege pattern (Viewer + SQL GRANT), ReadData vs ReadAll distinction (SQL vs Spark/OneLake), the mode-dependent RLS/CLS enforcement across engines (OneLake security GA May 2026 enforces in Spark/Lakehouse/Direct-Lake-on-OneLake and SQL endpoints in user's-identity mode; the old Spark/OneLake bypass survives only for SQL-defined RLS and delegated-identity-mode endpoints), auto-create of users on GRANT (no CREATE USER), and the 40-warehouses-per-workspace token-size limit."
---

# Security model

## Permission Layers (broadest to finest)

1. **Workspace roles**: Admin, Member, Contributor, Viewer
2. **Item-level permissions**: Read, ReadData, ReadAll
3. **OneLake security data access roles** (GA May 2026): lake-level RBAC — folder + row + column scopes enforced across all Fabric engines (see below)
4. **SQL granular permissions**: GRANT/DENY/REVOKE

## Key Principles

- Admin/Member/Contributor roles grant full data read and bypass RLS/CLS/DDM
- Use **Viewer role + SQL GRANT** for least-privilege consumer access
- Sharing an item with no extra permissions → CONNECT only (can't read tables until GRANT SELECT)
- "Read all data using SQL" (ReadData) → equivalent to `db_datareader`
- "Read all data using Apache Spark" (ReadAll) → OneLake file access, does NOT affect SQL permissions
- **RLS/CLS enforcement is mode-dependent** (changed by OneLake security GA, May 2026):
  - *SQL-defined* RLS/CLS (the `CREATE SECURITY POLICY` / column-GRANT surface below) is still enforced on the SQL endpoint **only** — users with Spark/OneLake access (ReadAll) bypass it. This hole is unchanged.
  - *OneLake-security-defined* RLS/CLS (lake-level data access roles) is enforced across **all Fabric engines** — Lakehouse, Spark notebooks, Direct Lake on OneLake, and SQL analytics endpoints switched to **User's identity access mode** are all GA. "Any security set applies to access from all engines in Fabric." SQL analytics endpoints left in **delegated-identity mode** do not honor OneLake security roles (they keep the old behavior). The mode is a one-time per-endpoint switch under the endpoint **Security** tab; newer SQL analytics endpoints default to user's-identity mode.
- Users auto-created on first GRANT/DENY — `CREATE USER` is not supported
- Limit warehouses + SQLEPs to ≤ 40 per workspace to avoid system token size limits

## SQL Granular Permissions

Users are auto-created on first GRANT/DENY — `CREATE USER` is not supported (and not needed).

```sql
-- Object-level
GRANT SELECT  ON dbo.FactSales TO [analyst@contoso.com];
DENY  SELECT  ON dbo.EmployeeSalary TO [analyst@contoso.com];
GRANT EXECUTE ON dbo.sp_TopProducts TO [analyst@contoso.com];
GRANT SELECT  ON SCHEMA::reporting TO [powerbi_readers@contoso.com];

-- Column-level (CLS) — column list in GRANT or DENY
GRANT SELECT ON dbo.Customers (CustomerID, CustomerName, Region) TO [viewer@contoso.com];
DENY  SELECT ON dbo.Customers (SSN, CreditCardNumber)            TO [viewer@contoso.com];
```

## Row-Level Security (RLS)

```sql
CREATE SCHEMA rls;
GO
CREATE FUNCTION rls.fn_securitypredicate(@SalesRep AS varchar(60))
RETURNS TABLE WITH SCHEMABINDING
AS RETURN SELECT 1 AS result
   WHERE @SalesRep = USER_NAME() OR USER_NAME() = 'manager@contoso.com';
GO
CREATE SECURITY POLICY dbo.SalesFilter
ADD FILTER PREDICATE rls.fn_securitypredicate(SalesRep) ON dbo.Sales
WITH (STATE = ON);
```

Test as the actual target user — owner-testing bypasses RLS.

## Dynamic Data Masking (DDM) — Warehouse only

```sql
CREATE TABLE dbo.Customers (
    CustomerID int NOT NULL,
    FullName varchar(100) MASKED WITH (FUNCTION = 'partial(1,"XXXXX",1)') NULL,
    Email    varchar(100) MASKED WITH (FUNCTION = 'email()')              NULL,
    Phone    varchar(20)  MASKED WITH (FUNCTION = 'default()')            NULL,
    SSN      varchar(11)  MASKED WITH (FUNCTION = 'partial(0,"XXX-XX-",4)') NULL
);

GRANT UNMASK ON dbo.Customers TO [finance_team@contoso.com];
```

DDM is a **viewing restriction, not encryption**. Workspace Admin / Member / Contributor see unmasked data by default — DDM only protects Viewer-role users.

## OneLake Security (GA May 2026)

Lake-level RBAC enforced **across all Fabric engines**, distinct from the SQL GRANT surface. Deny-by-default: a user in no data access role sees no data in the item.

- **Data access roles**: each role = a permission (`Read` or `ReadWrite`) + a scope (tables/folders/schemas) + Entra members. Only GRANT-type roles exist. Tables can carry row- and/or column-level security inside a role. Created/managed by Write+Reshare users (Admin/Member) via the item's OneLake security UX.
- **Supported items**: Lakehouse (`Read`, `ReadWrite`), Azure Databricks Mirrored Catalog (`Read`), Mirrored Databases (`Read`).
- **`ReadWrite` permission** (Lakehouse): lets a Viewer/Read user write to specified tables/folders (Spark notebooks, OneLake file explorer, OneLake APIs) without item create/manage rights — *not* through the Lakehouse UX. Roles with `ReadWrite` can't carry RLS/CLS.
- **Virtualized (default) role memberships**: new items ship a **`DefaultReader`** role whose members are virtualized — every user with the `ReadAll` permission is implicitly a member, so they see all data. Restrict by deleting `DefaultReader`, removing `ReadAll`, or replacing it with a custom role.
- **Gotcha — remove from DefaultReader**: after adding a user to a scoped data access role, **remove them from `DefaultReader`**, or they retain full access through it and the scoped role is moot.
- **Engine enforcement (GA)**: Lakehouse, Spark notebooks, SQL analytics endpoint in **user's-identity mode**, and Direct Lake on OneLake all apply RLS/CLS filtering. Eventhouse (RLS only) and authorized third-party engines are still preview. For *user access* (unauthorized external engines) to RLS/CLS data, the query is **blocked**, not silently filtered.
- **Admin/Member/Contributor still override**: their implicit OneLake `Write` permission overrides any OneLake security `Read` role — these roles are not constrained by data access roles (consistent with the RLS/CLS/DDM bypass above).
- Role-definition changes take ~5 min to apply; user-group membership changes ~1 hr (plus per-engine cache).

## Sensitivity Labels (REST-discoverable)

Item-level Purview labels became programmatically discoverable on the core item REST surface in March 2026 GA: `GET /v1/workspaces/{wsId}/items` and `GET /v1/workspaces/{wsId}/items/{itemId}` now include `sensitivityLabel: { "sensitivityLabelId": "<labelGuid>" }` on the `Item` object when a label is applied (field omitted on unlabeled items). Note the inner field is `sensitivityLabelId` at runtime — the MS Learn schema page calls it `id`, but the live API returns `sensitivityLabelId` (verified on 233/233 labeled items, May 2026). Any caller with the Viewer workspace role + `Workspace.Read.All` can read it — no admin elevation needed — making label-coverage audits possible without Fabric admin privileges. Only the GUID is returned; resolve to a human-readable name via Microsoft Graph `/security/informationProtection/sensitivityLabels`. Setting or removing labels still requires the existing admin APIs (`/v1/admin/labels/bulkSetLabels` / `bulkRemoveLabels` — Fabric admin role, `Tenant.ReadWrite.All`). See [[fabric-rest-api]] for the response shape.

## Reference

- Microsoft Learn: [Security in Microsoft Fabric (overview)](https://learn.microsoft.com/fabric/security/security-overview)
- Microsoft Learn: [Permission model](https://learn.microsoft.com/fabric/security/permission-model)
- Microsoft Learn: [OneLake security — get started](https://learn.microsoft.com/fabric/onelake/security/get-started-onelake-security)
- Comprehensive MS Learn link bundle (concept / workspace+item / OneLake security / per-item auth / workspace identity & SPN / network security / sensitivity labels / troubleshooting): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-warehouse skill — SQL GRANT/DENY surface on Warehouse
- fabric-auth skill — token audiences for each access path
