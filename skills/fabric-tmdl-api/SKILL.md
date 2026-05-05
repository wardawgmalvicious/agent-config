---
name: fabric-tmdl-api
description: "Use for the Fabric Semantic Model Definition API — createItemWithDefinition / getDefinition / updateDefinition. Covers the two-audience rule (Fabric API for definitions, Power BI API for refresh/data sources/permissions), why updateDefinition MUST include ALL parts (modified and unmodified) or they're deleted, why you NEVER include .platform in definition payloads, base64 encoding requirement, LRO polling, required TMDL parts (definition.pbism, database.tmdl, model.tmdl, tables/*.tmdl), the `database` declaration requirement in database.tmdl, and Direct Lake partition configuration (EntityPartitionSource, named expression with AzureStorage.DataLake)."
---

# Semantic Model Definition API rules

- **Two audiences**: Fabric API (`api.fabric.microsoft.com`) for CRUD on definitions; Power BI API (`analysis.windows.net/powerbi/api`) for refresh, data sources, permissions
- **`updateDefinition` must include ALL parts** — modified AND unmodified. The API replaces the entire definition; omitting parts deletes them.
- **Never include `.platform`** in `updateDefinition` payloads — it is Git integration metadata and causes errors
- **Base64-encode all TMDL content** in definition payloads
- **`getDefinition` is a POST** (not GET) — requires `--body '{}'`
- **Poll LRO to completion** — `createItemWithDefinition`, `getDefinition`, and `updateDefinition` return 202

## Required TMDL Parts

| Part Path | Content |
|---|---|
| `definition.pbism` | Semantic model connection settings (JSON) |
| `definition/database.tmdl` | `database` declaration + `compatibilityLevel: 1702` |
| `definition/model.tmdl` | Model properties + `ref` declarations for tables/roles/etc. |
| `definition/tables/<TableName>.tmdl` | Per-table: measures, columns, partitions |

**Critical**: `database.tmdl` MUST start with `database` object declaration, not bare properties. Bare `compatibilityLevel:` causes `InvalidLineType: Property!` errors.

## model.tmdl Required Properties

```tmdl
model Model
 culture: en-US
 defaultPowerBIDataSourceVersion: powerBI_V3
 discourageImplicitMeasures
```

`defaultPowerBIDataSourceVersion: powerBI_V3` is required for Import-mode models. Without it: `Import from JSON supported for V3 models only`.

## Direct Lake Configuration

- ALL partitions must use `EntityPartitionSource` — no M/Power Query
- A named expression pointing to the Lakehouse/Warehouse must be defined before tables:

  ```tmdl
  expression DL_Lakehouse =
      let
          Source = AzureStorage.DataLake("https://onelake.dfs.fabric.microsoft.com/<WorkspaceId>/<LakehouseId>", [HierarchicalNavigation=true])
      in
          Source
  ```

- Each table partition references the expression:

  ```tmdl
  partition Sales = entity
      mode: directLake
      source
          entityName: Sales
          schemaName: dbo
          expressionSource: DL_Lakehouse
  ```

- `dataType: binary` columns are NOT supported in Direct Lake
- Columns map directly via `sourceColumn` — no transforms
- **Calculated columns / tables (April 2026 preview)**: Direct Lake on **OneLake** now supports unmaterialized calculated columns (and calculated tables that reference them). Direct Lake on **SQL** still does not. User-context-aware DAX (`USERCULTURE`, `USERPRINCIPALNAME`, `CUSTOMDATA`, etc.) requires `expressionContext: userContext` on the column. See fabric-tmdl REFERENCE for the storage-mode × Expression-Context support matrix.

## Reference

- Microsoft Learn: [Item definition overview (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview)
- Microsoft Learn: [SemanticModel definition envelope](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition)
- Microsoft Learn: [Develop Direct Lake semantic models (TMDL partition mode)](https://learn.microsoft.com/fabric/fundamentals/direct-lake-develop)
- Comprehensive MS Learn link bundle (definition envelope / REST CRUD / TMDL language / required parts / Direct Lake configuration / refresh APIs): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-rest-api skill — LRO polling pattern, runtime item ID vs logicalId
- fabric-auth skill — Fabric vs Power BI audience selection
- fabric-cli skill — `fab export` / `fab import` wrap these APIs
