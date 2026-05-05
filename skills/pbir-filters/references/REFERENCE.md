# MS Learn link bundle — PBIR Filters

Curated set of Microsoft Learn pages relevant to Power BI report filters — what each `type` means in the user-facing Filters pane, the filter-pane visibility/styling split between report.json and theme, and how filters serialize as PBIR `filterConfig` objects with the SQExpr `From[]` / `Where[]` shape.

The 3 highest-leverage entry points (filter pane format, filter types, slicers concept) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** PBIR `filterConfig` JSON internals (Version 2, From[]/Where[], `SourceRef.Source` alias rule, ComparisonKind codes, RelativeDate TimeUnit codes) are *not* documented narratively on MS Learn — the canonical machine-readable reference is the JSON schema family at `developer.microsoft.com/json-schemas/fabric/...`. The Power BI Desktop / Service pages document what user choices the JSON encodes.

## User-facing concept (what the JSON encodes)

- [Format filters in Power BI reports (filter pane)](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-filter) — visibility, expand/collapse, lock/hide per filter, the report-level `outspacePane` properties the parent skill calls out.
- [Filters in Power BI Desktop reports](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-add-filter) — the three scopes (Report / Page / Visual) that map to where `filterConfig` lives.
- [Filter types overview](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-filter-types) — Basic (Categorical) / Advanced / Top N / Relative Date / Relative Time. Maps directly to the parent skill's `type` field table.
- [Use the relative date slicer / filter](https://learn.microsoft.com/power-bi/visuals/desktop-slicer-filter-date-range) — RelativeDate semantics: time units, anchor date.

## Slicers (sibling concept — slicers are visuals, not filters)

- [Slicers in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-slicers) — clarifies the parent skill's "slicers are visuals bound to categorical data" note.
- [Hierarchy slicers](https://learn.microsoft.com/power-bi/create-reports/power-bi-slicer-hierarchy-multiple-fields) — multi-field slicer; relevant when authoring slicer-as-visual.

## Filter pane visibility/expansion (`outspacePane` in report.json)

- [Format filters in Power BI reports — filter pane settings](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-filter#format-the-filters-pane-and-filter-cards) — UI surface for the `visible` / `expanded` properties. Styling lives in the theme — see `pbir-themes`.

## Drillthrough and cross-report drillthrough

- [Use drillthrough](https://learn.microsoft.com/power-bi/create-reports/desktop-drillthrough) — drillthrough page filter binding (`Column`-typed filter in `filterConfig`).
- [Cross-report drillthrough](https://learn.microsoft.com/power-bi/create-reports/desktop-drillthrough#enable-cross-report-drillthrough) — when filter state spans reports.

## Filter pane theming (cross-skill)

- [Customize the filter pane appearance via theme](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom#filter-pane-and-filter-card) — the theme keys (`outspacePane`, `filterCard`) where colors/text/widths belong. See `pbir-themes` skill.

## PBIR file format (where filters live)

- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `report.json`, `pages/<page>/page.json`, `pages/<page>/visuals/<v>/visual.json` locations of `filterConfig`.
- [Report definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — definition envelope. The `definition.pbir` file targets the semantic model that filter `Entity` references resolve against.

## See also (this repo)

- `pbir-visual-json` — visual-scope `filterConfig` placement (sibling of `visual`, not nested)
- `pbir-themes` — filter pane and filter card styling
- `pbir-bookmarks` — `byExpr` filter snapshots use the same SQExpr shape
