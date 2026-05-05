---
name: pbip-project-structure
description: Use when working with PBIP (Power BI Project) folders — the text-based developer format that replaces binary .pbix. Covers folder layout (.SemanticModel/, .Report/, definition/, StaticResources/), entry-point files (.pbip, .pbir, .pbism, .platform), byPath vs byConnection (thick vs thin report), .pbism version 4.2 / TMDL signalling, PBIX-to-PBIP extraction (OPC ZIP, UTF-16LE vs UTF-8 internals), forking a project with new logicalId GUIDs, the rename cascade across TMDL/PBIR/DAX/bookmark/reportExtensions locations, and git hygiene (UTF-8 no BOM, CRLF, 260-char path limit, gitignoring diagramLayout.json). Invoke when user mentions .pbip, .pbir, .pbism, .platform, logicalId, PBIP conversion, forking a report, or setting up a Power BI repo for source control.
paths:
  - "**/*.pbip"
  - "**/*.pbir"
  - "**/*.pbism"
  - "**/.platform"
  - "**/*.Report/**"
  - "**/*.SemanticModel/**"
---

## PBIP Project Structure

Power BI Project (PBIP) is the text-based developer format for Power BI. Replaces the `.pbix` binary with a folder of UTF-8 text files (TMDL for semantic models, PBIR JSON for reports).

### Folder Layout

```
<ProjectName>/
+-- <Name>.pbip                              # Optional entry point
+-- .gitignore                               # Auto-generated
+-- <Name>.SemanticModel/
|   +-- .pbi/
|   |   +-- localSettings.json               # Gitignored
|   |   +-- cache.abf                        # Data cache, gitignored
|   |   +-- unappliedChanges.json            # Pending PQ changes
|   +-- definition.pbism                     # SM entry point
|   +-- definition/                          # TMDL files
|   +-- model.bim                            # TMSL legacy (mutually exclusive)
|   +-- diagramLayout.json
|   +-- DAXQueries/                          # .dax query view tabs
|   +-- TMDLScripts/                         # .tmdl script view tabs
|   +-- .platform                            # Fabric identity
+-- <Name>.Report/
    +-- .pbi/localSettings.json              # Gitignored
    +-- definition.pbir                      # Report entry point
    +-- definition/                          # PBIR JSON files
    +-- report.json                          # PBIR-Legacy (legacy alt)
    +-- mobileState.json                     # No external edit
    +-- semanticModelDiagramLayout.json      # Diagram node positions
    +-- CustomVisuals/                       # Private .pbiviz metadata
    +-- StaticResources/RegisteredResources/ # Themes, images
    +-- DAXQueries/                          # Report-level .dax files
    +-- .platform
```

### Entry-Point Files

| File | Purpose |
|---|---|
| `.pbip` | Project entry point. Optional — `definition.pbir` can be opened directly |
| `.pbir` | Report entry point. Points at semantic model via `byPath` or `byConnection` |
| `.pbism` | Semantic model entry point. `version: "4.2"` for TMDL |
| `.platform` | Fabric identity per item: `displayName`, `type`, `logicalId` |
| `version.json` | Inside `definition/` — PBIR schema version (`"2.0.0"`) |

### .pbip

```json
{
  "version": "1.0",
  "artifacts": [{ "report": { "path": "MyReport.Report" } }],
  "settings": { "enableAutoRecovery": true }
}
```

### .platform

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json",
  "metadata": { "type": "Report", "displayName": "MyReport" },
  "config": { "version": "2.0", "logicalId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890" }
}
```

- `logicalId` is the Fabric identity — never change on an existing deployed item
- When forking a project, `logicalId` MUST be regenerated to a new GUID
- `type` values: `Report`, `SemanticModel`

### definition.pbir — byPath (Thick Project)

Report + model bundled in same project folder.

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json",
  "version": "4.0",
  "datasetReference": {
    "byPath": { "path": "../MyModel.SemanticModel" }
  }
}
```

### definition.pbir — byConnection (Thin Report)

Report connects to a remote published semantic model. Preferred for managed/shared BI.

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json",
  "version": "4.0",
  "datasetReference": {
    "byConnection": {
      "connectionString": "Data Source=powerbi://api.powerbi.com/v1.0/myorg/WorkspaceName;Initial Catalog=ModelName"
    }
  }
}
```

For Fabric REST API deployments, use the id form: `"connectionString": "semanticmodelid=[SemanticModelId]"`.

**Do NOT use the legacy six-property form** (`pbiServiceModelId`, `pbiModelVirtualServerName`, etc.) for new reports.

### definition.pbism

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/semanticModel/definitionProperties/1.0.0/schema.json",
  "version": "4.2",
  "settings": {}
}
```

| `version` | Supported Format |
|---|---|
| `1.0` | TMSL only (`model.bim`) |
| `4.0+` | TMSL or TMDL (`definition/` folder) |

### PBIX vs PBIP

| Aspect | PBIX | PBIP |
|---|---|---|
| Format | Single binary ZIP | Folder of text files |
| Source control | Not diff-friendly | Git-ready |
| External editing | Not supported | VS Code, pbir CLI, scripts |
| Cached data | Embedded | `cache.abf` gitignored |
| Conversion | File → Save As → PBIP in Desktop | File → Save As → PBIX in Desktop |

### PBIX Extraction

A `.pbix` is a ZIP (OPC) archive. Thick PBIX contains a `DataModel` binary (opaque ABF); thin PBIX has a `Connections` file instead. Modern PBIX stores reports in `Report/definition/` (PBIR); legacy PBIX uses a monolithic `Report/Layout` (UTF-16LE).

| PBIX Internal File | Encoding |
|---|---|
| `Version`, `Settings`, `Metadata`, `Report/Layout` | UTF-16LE |
| `Connections`, `Report/definition/*` | UTF-8 |
| `[Content_Types].xml` | UTF-8 with BOM |
| `DataModel`, `SecurityBindings` | Binary |

```python
import zipfile
with zipfile.ZipFile("MyReport.pbix") as z:
    z.extractall("MyReport_extracted")
# Detect type
is_thick = Path("MyReport_extracted/DataModel").exists()
is_modern = Path("MyReport_extracted/Report/definition/report.json").exists()
```

Assembling a PBIP from an extracted thin PBIX: copy `Report/definition/` into `<Name>.Report/definition/`, generate `definition.pbir` with `byConnection`, generate `.platform` with a new `logicalId` GUID.

Thick PBIX cannot be converted programmatically — the `DataModel` binary is opaque. Use PBI Desktop File → Save As.

### Forking a Project

1. Copy the entire project folder, rename the root
2. Rename `.Report/` and `.SemanticModel/` subfolders
3. Update `.pbip` → `artifacts[].report.path`
4. Update `.pbir` → `datasetReference.byPath.path` (if byPath)
5. Update each `.platform` (Report and SemanticModel separately) → set the appropriate `displayName` and regenerate a NEW unique `logicalId` per file (the two `.platform` files get different GUIDs)

### Rename Cascade

Renaming a table, measure, or column requires updates in every location that references it. Missing one causes broken visuals or DAX errors.

| Location | What to Update |
|---|---|
| TMDL table/measure/column declaration | The `<type> Name` line |
| TMDL partition name | Matches table name |
| `model.tmdl` | `ref table Name` + `PBI_QueryOrder` annotation |
| `relationships.tmdl` | `fromColumn:` / `toColumn:` table prefix |
| All DAX expressions | Both `Table[` and `'Table'[` forms |
| visual.json query projections | `SourceRef.Entity`, `queryRef` |
| visual.json filter/sort/CF blocks | Nested `SourceRef.Entity`, `From[].Entity` |
| page.json filterConfig | `From[].Entity` |
| Bookmark JSONs | `filter.From[].Entity`, `expression.*.SourceRef.Entity`, `highlight.dataMap` keys |
| SparklineData metadata | Compact string `SparklineData(Table.Measure_[...])` |
| `reportExtensions.json` | Top-level `entities[].name` AND nested `references.measures[].entity` |
| Culture `.tmdl` linguistic metadata | `ConceptualEntity`, `ConceptualProperty` |
| `semanticModelDiagramLayout.json` | `nodeIndex` |
| DAX query files | Both `.SemanticModel/DAXQueries/` and `.Report/DAXQueries/` |

**Commonly missed**: `sortDefinition` blocks, SparklineData compact strings, bookmark `highlight.dataMap` keys, the second DAX query location, `references.measures[].entity` nested inside `reportExtensions.json`.

### Git-Friendly Organization

- Set `core.autocrlf` or add `* text=auto` to `.gitattributes` — PBI Desktop writes CRLF
- UTF-8 without BOM for all files — a BOM prefix causes parse errors
- Keep the root path short — 260-char Windows path limit; page/visual GUID folders can exceed it
- Rename PBIR GUID folders (`0c32c81b...`) to human names (`Overview`, `lineChart_Sales`) for better diffs. Folder names are freely renamable; `page.json` / `visual.json` filenames and internal `name` properties must NOT change
- Multiple `.Report/` and `.SemanticModel/` folders can coexist in one project
- Fabric Git Integration only processes `definition.pbir` — other `.pbir` files are ignored but can coexist

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| Parse error on open | File saved with UTF-8 BOM | Re-save as UTF-8 without BOM |
| 260-char path error on Git clone | Deep GUID folder nesting | Shorten root path; rename GUID folders |
| PBI Desktop ignores external edits | Stale in-memory state | Close and reopen Desktop |
| Broken visual after table rename | Missed cascade location | Grep for old name across `.json`, `.tmdl`, `.dax` (both DAXQueries folders) |
| Empty `reportExtensions.json` crashes Desktop | `"entities": []` is invalid | Delete the file instead of leaving empty |
| Forked project shows as same Fabric item | `logicalId` not regenerated | New GUID per `.platform` on fork |
| Thick PBIX cannot be converted to PBIP via script | `DataModel` binary is opaque | Use File → Save As in PBI Desktop |
| Merge conflicts in `diagramLayout.json` | Auto-generated per user | Treat as binary or add to `.gitignore` |

### Reference

- Microsoft Learn: [Power BI Desktop project (PBIP) overview](https://learn.microsoft.com/power-bi/developer/projects/projects-overview)
- Microsoft Learn: [Power BI Desktop project — semantic model folder](https://learn.microsoft.com/power-bi/developer/projects/projects-dataset)
- Microsoft Learn: [Introduction to Fabric Git integration](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration)
- Comprehensive MS Learn link bundle (PBIP docs / entry-point file shapes / Direct Lake live editing / Fabric Git / REST envelope / TMDL): [references/REFERENCE.md](references/REFERENCE.md)

### See also

- `pbir-cli` — pbir CLI command reference
- `pbir-report-workflow` — report creation workflow
- `pbir-pages` — page JSON structure
- `fabric-tmdl` — TMDL authoring rules
