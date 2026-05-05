---
name: fabric-tmdl
description: TMDL (Tabular Model Definition Language) authoring rules for Fabric and Power BI semantic models. Use when editing .tmdl files, adding measures or columns to a semantic model, defining relationships or calculation groups, working in a PBIP definition/ folder, configuring Direct Lake partitions, or debugging TMDL validation errors. Covers syntax (tabs not spaces, /// descriptions, single-quoting names), DAX measure patterns, row-level security roles, calendar groups, and common gotchas.
paths:
  - "**/*.tmdl"
  - "**/*.SemanticModel/**"
  - "**/definition/**"
---

## TMDL Authoring Rules

### Syntax Rules (MUST follow)

- **TMDL uses tab indentation** — every nesting level is exactly one tab (`\t`), NOT spaces. Spaces cause validation errors.
  - PowerShell: use `` `t ``
  - Bash: use `$'\t'` or literal tabs
- Objects declared by type + name: `table Customer`, `column ProductId`, `measure 'Total Sales'`
- Names with spaces or special chars (`.`, `=`, `:`, `'`) must be in **single quotes**: `column 'Order Date'`
- Descriptions use `///` placed ABOVE the object — do NOT use the `description` property
- `//` comments are **NOT supported** in TMDL
- Do NOT add `lineageTag` on new objects — it is auto-generated
- Multi-line DAX must be enclosed in triple backticks (` ``` `)
- Place **measures before columns** in table definitions
- `formatString` is required on every measure
- Never set `dataType` on measures — it is inferred from DAX

### Naming Conventions

- **Tables**: business-friendly, no `Fact`/`Dim` prefixes. Plural for facts (`Sales`), singular for dimensions (`Product`)
- **Columns**: readable with spaces (`Order Date`, `Unit Price`)
- **Measures**: clear patterns (`Total Sales`, `# Customers`). Time intelligence: `[measure]`, `[measure (ly)]`, `[measure (ytd)]`)

### Column Rules

| Property | Rule |
|---|---|
| `dataType` | Required. Use `int64`, `decimal`, `string`, `dateTime`, `boolean`. Avoid `double` |
| `sourceColumn` | Must match partition source column name exactly |
| `isHidden` | Set for ID columns, foreign keys, system columns |
| `summarizeBy` | `none` for non-aggregatable numerics (IDs, postal codes, year numbers) |
| `isAvailableInMdx` | `false` for hidden columns not used in sort-by or hierarchies |
| `sortByColumn` | For text needing non-alphabetical sort (month names → month number) |

### Measure & DAX Rules

- Always set `formatString` — Currency: `$#,##0.00` | Percentage: `0.00%` | Integer: `#,##0` | Decimal: `#,##0.00`
- Use `DIVIDE()` instead of `/` for safe division
- **Never** use `IFERROR` — causes performance degradation
- Prefix `VAR` names with `_`: `VAR _totalSales = ...`
- Use `displayFolder` to organize measures into logical groups
- Add `///` descriptions to explain business logic

### Relationship Rules

- `fromColumn:` = many-side (fact); `toColumn:` = one-side (dimension)
- Create relationships BEFORE measures that depend on them
- Default: `crossFilteringBehavior: oneDirection`; add `bothDirections` only when needed
- `isActive: false` for role-playing dimensions; use `USERELATIONSHIP()` in DAX
- Both sides must have matching `dataType`
- Set `isKey: true` on dimension primary key columns
- Hide foreign keys on fact tables (`isHidden: true`)
- No composite keys — use a single surrogate integer key

### Calculation Groups

```tmdl
table 'Time Intelligence'
	calculationGroup
		calculationItem Current = SELECTEDMEASURE()
		calculationItem YTD = CALCULATE(SELECTEDMEASURE(), DATESYTD('Date'[Date]))
	column 'Time Intelligence'
		dataType: string
	partition 'Partition_Time Intelligence' = calculationGroup
```

- `calculationGroup` keyword has NO name — just the keyword indented under the table
- Partition type must be `= calculationGroup` (not `= m` or `= calculated`)
- Use `formatStringDefinition` (not `formatString`) for calc items that override measure format

### Security Roles

```tmdl
role RegionalManager
	modelPermission: read
	tablePermission Sales = [Region] = "East"
```

- `modelPermission:` required — use `read` or `readRefresh`
- Assign users via Power BI REST API, not TMDL: `POST .../datasets/{id}/users` with `roles` array
- Do NOT use `INFO.ROLES()` / `INFO.ROLEMEMBERSHIPS()` via DAX — unreliable. Use the REST API.

### Annotations

- Do NOT add `PBI_*` annotations manually — they are Power BI internal metadata
- Custom annotations are fine for documentation/tooling
- Syntax: blank line before the first annotation; blank line between annotations; same indent as peer properties

```tmdl
column 'Product Name'
	dataType: string
	sourceColumn: Product Name

	annotation MyTool_Owner = analytics-team
```


---


## model.tmdl Required Properties

`model.tmdl` is the root of the `definition/` folder alongside `database.tmdl`, `expressions.tmdl`, `functions.tmdl`, `relationships.tmdl`, `roles/`, `perspectives/`, `cultures/`, and `tables/`.

```tmdl
model Model
	culture: en-US
	defaultPowerBIDataSourceVersion: powerBI_V3
	discourageImplicitMeasures
	sourceQueryCulture: en-US
	dataAccessOptions
		legacyRedirects
		returnErrorValuesAsNull
```

`defaultPowerBIDataSourceVersion: powerBI_V3` is required for Import-mode models — without it, `Import from JSON supported for V3 models only`.


---


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


---


## Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `InvalidLineType: Property!` in `database.tmdl` | Bare `compatibilityLevel:` without `database` declaration | Start the file with `database <Name>` on line 1 |
| `Import from JSON supported for V3 models only` | Missing `defaultPowerBIDataSourceVersion` | Add `powerBI_V3` to `model.tmdl` |
| Spaces-for-tabs validation errors | Editor converted tabs | Force literal tabs; configure editor not to expand |
| `//` comment ignored or invalid | Not supported | Use `///` on line above the object (descriptions only) |
| Measure has wrong inferred type | `dataType` was set manually | Remove `dataType` from measures — always inferred |
| Missing `formatString` errors | Measure without `formatString` | Always set per measure; use `formatStringDefinition` for dynamic |
| Calc item format ignored | Used `formatString` instead of `formatStringDefinition` | `formatStringDefinition` is DAX-based; only it overrides the selected measure's format |
| Broken report binding after column rename | Stale `lineageTag` left in place | Never edit `lineageTag`; let Power BI regenerate only on creation |
| Role members ignored | Authored `member` statically | Assign via Power BI REST API (`POST datasets/{id}/users`) |
| `INFO.ROLES()` returns stale/missing data | Known DAX surface unreliability | Query membership via REST API |
| Calendar name collision | Name unique per-table but not per-model | Calendar names must be globally unique across the model |
| Direct Lake partition errors | `binary` column in source | Cast away in upstream Lakehouse/Warehouse; drop the column |
| Perspective appears empty in Power BI | No `perspectiveTable` children | Add at least one table + column/measure, or `includeAll` on a table |
| `model.bim` and `definition/` both present | Forgot to delete `.bim` after TMDL conversion | Remove `model.bim`; they are mutually exclusive |
| TMDL conversion fails | Old `Microsoft.AnalysisServices.retail.amd64` | Upgrade NuGet package for `TmdlSerializer` |
| Hierarchy level references missing column | Column removed or renamed without updating level | `level.column:` must reference an existing same-table column |
| `PBI_*` annotation edits revert | Power BI rewrites on save | Do not hand-author PBI internal annotations |


---

## Additional reference

- Microsoft Learn: [TMDL language overview](https://learn.microsoft.com/analysis-services/tmdl/tmdl-overview)
- Microsoft Learn: [TMDL view in Power BI Desktop](https://learn.microsoft.com/power-bi/transform-model/desktop-tmdl-view)
- Microsoft Learn: [Power BI Desktop project semantic model folder (PBIP)](https://learn.microsoft.com/power-bi/developer/projects/projects-dataset)
- Companion [references/REFERENCE.md](references/REFERENCE.md): per-object property tables (`database`, `model`, `table`, `column`, `measure`, `relationship`, `hierarchy`, `partition`, `calculationGroup`, `role`, `perspective`, `cultureInfo`, `expression`, `function`, `dataSource`, `refreshPolicy`, `calendar`, `queryGroup`), BIM ↔ TMDL conversion procedure, enum value lists, and a comprehensive MS Learn link bundle (TMDL syntax / TMDL view / PBIP folder / calculation groups / Direct Lake / DAX / TMSL / TOM).
