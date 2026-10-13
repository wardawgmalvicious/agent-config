# Schema evolution detail

The `ALTER COLUMN` preview conversion matrix and the `IDENTITY_INSERT` /
reseed procedure. `SKILL.md` carries the schema-evolution summary table and
the IDENTITY semantics you need before designing a key.

## `ALTER COLUMN` (Preview)

`ALTER TABLE ... ALTER COLUMN` is **in preview**. It supports **metadata-only schema evolution** — only changes that don't require validating or rewriting the underlying Parquet files (i.e. **type widening** compatible with existing stored data). Takes a **Sch-M lock** for the duration (blocks/blocked by concurrent workloads).

**Supported conversions (widening / interchange only):**

| Category | Source → Target |
|---|---|
| Integer widening | `smallint`→`int`/`bigint`; `int`→`bigint` |
| Floating-point widening | `real`→`float`; `smallint`/`int`→`float` |
| Decimal widening | `decimal(p,s)`→`decimal(p+k1, s+k2)` where k1 ≥ k2 ≥ 0; `smallint`/`int`→`decimal(10+k1, k2)` |
| Decimal / numeric interchange | `decimal(p,s)` ↔ `numeric(p,s)` |
| Float / real interchange | `float(n<25)`→`real`; `float(n)`→`float(n+m)`; `real`→`float(n)` |
| Time widening | `time`→`datetime2`; `datetime2(n)`→`datetime2(n+m)` |
| String widening | `char(n)`→`varchar(n+m)`/`char(n+m)`; `varchar(n)`→`varchar(n+m)`/`char(n+m)` |
| Binary widening | `varbinary(n)`→`varbinary(n+m)` |

**NOT supported (use the CTAS workaround):** narrowing / reducing size of the same type · `NULL`→`NOT NULL` · altering an IDENTITY column · changing collation · decreasing precision on `time`→`datetime2` · a column with manually-created stats (`DROP STATISTICS` first) · a column that is part of the data-clustering (`CLUSTER BY`) index. `time`→`datetime2` sets the date component to `1970-01-01` (Delta/Unix epoch), unlike SQL Server's `1900-01-01`.

**Cross-engine caveat:** widening surfaces as Delta **type widening** at the storage layer — external engines reading the same Delta tables must support Delta type-widening reads. To strip type widening from the schema, rebuild with CTAS.

## Declaring an IDENTITY column

```sql
CREATE TABLE dbo.DimProduct (
    ProductKey bigint IDENTITY,
    ProductName varchar(100)
);
```

## IDENTITY_INSERT and reseeding

```sql
SET IDENTITY_INSERT dbo.DimCustomer ON;
INSERT INTO dbo.DimCustomer (CustomerKey, CustomerName, Email)
VALUES (-1, 'Unknown', NULL);          -- sentinel row
SET IDENTITY_INSERT dbo.DimCustomer OFF;

DBCC CHECKIDENT('dbo.DimCustomer', RESEED);   -- required, not optional
```

- While `IDENTITY_INSERT` is `ON`: a **column list is required** on the `INSERT`, and **only one table per session** can have it on.
- **Reseed after turning it off.** `RESEED` scans used and reserved ranges across the compute nodes to work out the correct next values; skip it and you risk key collisions.
- `DBCC CHECKIDENT` supports **only `RESEED`** here — no custom reseed value, and `NORESEED` is not supported.
- `COPY INTO` has its own `IDENTITY_INSERT = 'ON'` option, and it **overrides the session-level setting**:

  ```sql
  COPY INTO dbo.Employees (EmployeeID 1, FirstName 2, LastName 3)
  FROM 'https://myaccount.blob.core.windows.net/myblobcontainer/folder1/'
  WITH (FILE_TYPE = 'CSV', IDENTITY_INSERT = 'ON');
  ```

- **`sys.identity_columns` lies here.** `seed_value` and `increment_value` are always `NULL` and never updated; `last_value` is `NULL` until the first identity insert, then flips **permanently to `-1`**. Don't read it for a high-water mark — use `MAX()` on the column.

## Microsoft Learn

- [IDENTITY columns in Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/identity)

## Supported operations and their syntax

`SKILL.md` names these; the syntax is here.

| Operation | Status | Syntax |
|---|---|---|
| Add nullable column | ✅ | `ALTER TABLE t ADD col type NULL` |
| Drop column | ✅ April 2025+ | `ALTER TABLE t DROP COLUMN col` (metadata-only) |
| Rename column | ✅ April 2025+ | `EXEC sp_rename 't.OldCol', 'NewCol', 'COLUMN'` |
| Rename table | ✅ | `EXEC sp_rename 'OldName', 'NewName'` |
| Add / drop `NONCLUSTERED NOT ENFORCED` PK / UNIQUE / FK | ✅ | `ALTER TABLE t ADD CONSTRAINT ... NONCLUSTERED NOT ENFORCED` / `DROP CONSTRAINT` |
| ALTER TABLE inside `BEGIN TRAN ... COMMIT` | ✅ April 2026+ GA | All supported ALTER TABLE variants run atomically; any failure rolls every schema change back |
