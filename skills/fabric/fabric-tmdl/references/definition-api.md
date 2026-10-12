# Semantic Model Definition API rules

- **Two audiences**: Fabric API (`api.fabric.microsoft.com`) for CRUD on definitions; Power BI API (`analysis.windows.net/powerbi/api`) for refresh, data sources, permissions
- **`updateDefinition` must include ALL parts** — modified AND unmodified. The API replaces the entire definition; omitting parts deletes them.
- **Never include `.platform`** in `updateDefinition` payloads — it is Git integration metadata and causes errors. Bulk Import is the exception: its parts carry each item's `.platform`
- **Base64-encode all TMDL content** in definition payloads
- **`getDefinition` is a POST** (not GET) — requires `--body '{}'`
- **Poll LRO to completion** — `createItemWithDefinition`, `getDefinition` and `updateDefinition` can each answer `202` instead of `200` (a create, `201`); branch on the status code, as fabric-rest-api says

## Required TMDL Parts

| Part Path | Content |
|---|---|
| `definition.pbism` | Semantic model connection settings (JSON) |
| `definition/database.tmdl` | `database` declaration + `compatibilityLevel: 1702` |
| `definition/model.tmdl` | Model properties + `ref` declarations for tables/roles/etc. |
| `definition/tables/<TableName>.tmdl` | Per-table: measures, columns, partitions |

`database.tmdl` starts with the `database` object declaration, not bare properties: a bare `compatibilityLevel:` fails with `InvalidLineType: Property!`.

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
- **Calculated columns / tables (April 2026 preview)**: Direct Lake on **OneLake** now supports unmaterialized calculated columns (and calculated tables that reference them). Direct Lake on **SQL** still does not. User-context-aware DAX (`USERCULTURE`, `USERPRINCIPALNAME`, `CUSTOMDATA`, etc.) requires `expressionContext: userContext` on the column. Authorable in **Power BI Desktop and web modeling**, without changing storage mode. See [REFERENCE.md](REFERENCE.md) for the storage-mode × Expression-Context support matrix.

## Reference

- Microsoft Learn: [Item definition overview (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview)
- Microsoft Learn: [SemanticModel definition envelope](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition)
- Microsoft Learn: [Develop Direct Lake semantic models (TMDL partition mode)](https://learn.microsoft.com/fabric/fundamentals/direct-lake-develop)
- Comprehensive MS Learn link bundle (definition envelope / REST CRUD / TMDL language / required parts / Direct Lake configuration / refresh APIs): [definition-api-links.md](definition-api-links.md)

## See also

- fabric-rest-api skill — LRO polling pattern, runtime item ID vs logicalId
- fabric-auth skill — Fabric vs Power BI audience selection
- fabric-cli skill — `fab export` / `fab import` wrap these APIs
