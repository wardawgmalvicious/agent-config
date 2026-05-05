---
name: fabric-security
description: "Use for the Fabric security/permission model. Covers the three layers (workspace roles Admin/Member/Contributor/Viewer, item-level Read/ReadData/ReadAll, SQL GRANT/DENY/REVOKE), Admin/Member/Contributor bypass of RLS/CLS/DDM, least-privilege pattern (Viewer + SQL GRANT), ReadData vs ReadAll distinction (SQL vs Spark/OneLake), the RLS/CLS bypass via Spark/OneLake hole, auto-create of users on GRANT (no CREATE USER), and the 40-warehouses-per-workspace token-size limit."
---

# Security model

## Permission Layers (broadest to finest)

1. **Workspace roles**: Admin, Member, Contributor, Viewer
2. **Item-level permissions**: Read, ReadData, ReadAll
3. **SQL granular permissions**: GRANT/DENY/REVOKE

## Key Principles

- Admin/Member/Contributor roles grant full data read and bypass RLS/CLS/DDM
- Use **Viewer role + SQL GRANT** for least-privilege consumer access
- Sharing an item with no extra permissions → CONNECT only (can't read tables until GRANT SELECT)
- "Read all data using SQL" (ReadData) → equivalent to `db_datareader`
- "Read all data using Apache Spark" (ReadAll) → OneLake file access, does NOT affect SQL permissions
- RLS/CLS is enforced on SQL endpoint only — users with Spark/OneLake access (ReadAll) bypass these
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

## Reference

- Microsoft Learn: [Security in Microsoft Fabric (overview)](https://learn.microsoft.com/fabric/security/security-overview)
- Microsoft Learn: [Permission model](https://learn.microsoft.com/fabric/security/permission-model)
- Microsoft Learn: [OneLake security — get started](https://learn.microsoft.com/fabric/onelake/security/get-started-security)
- Comprehensive MS Learn link bundle (concept / workspace+item / OneLake security / per-item auth / workspace identity & SPN / network security / sensitivity labels / troubleshooting): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-warehouse skill — SQL GRANT/DENY surface on Warehouse
- fabric-auth skill — token audiences for each access path
