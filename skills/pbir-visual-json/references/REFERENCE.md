# MS Learn link bundle — PBIR visual.json

Curated set of Microsoft Learn pages relevant to the per-visual JSON in PBIR — the canonical "what visualType X needs" reference (visual catalog), per-visual-type formatting docs, the visualGroup concept, and the PBIR file structure that holds `visual.json`.

The 3 highest-leverage entry points (visualizations overview, build-a-report intro, PBIR project file layout) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** The PBIR `visual.json` JSON internals (top-level `name`/`position`/`visual`/`visualGroup`/`filterConfig`, expression-literal suffix grammar with `D`/`L`/`M`/`'string'`/`datetime'...'`, `objects` vs `visualContainerObjects` split in schema 2.4.0+, `dataViewWildcard` selectors, `SourceRef.Source` vs `Entity` rule) are *not* documented narratively on MS Learn — the canonical machine-readable reference is at `developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/...`. The Power BI visual catalog and per-visual-type articles document what each `visualType` does and which roles it expects.

## Visual catalog (mapping `visualType` → user-facing concept)

- [Visualizations overview in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualizations-overview) — entry point to the per-visual articles. Read this when you don't know which `visualType` corresponds to a given chart.
- [Visualization types in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-types-for-reports-and-q-and-a) — full visual catalog (bar/column variants, line/area variants, pie/donut, scatter, gauge, KPI, card, table, matrix, slicer, R/Python, custom). Useful when you need to pick the right `visualType` for an authoring task.
- [Cards (new card)](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-card) and the legacy [Card visualization](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-card) — `card` (legacy) vs `cardVisual` (new).
- [Tables](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-tables) — `tableEx` semantics.
- [Matrix](https://learn.microsoft.com/power-bi/visuals/desktop-matrix-visual) — `pivotTable` semantics: rows / columns / values roles.
- [Slicers](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-slicers) and [Advanced slicer](https://learn.microsoft.com/power-bi/visuals/power-bi-advanced-slicer-visual) — `slicer` vs `advancedSlicerVisual`.
- [Line charts](https://learn.microsoft.com/power-bi/visuals/power-bi-line-charts) — `lineChart` (Y/Y2/series).
- [Combo charts](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-combo-chart) — `lineClusteredColumnComboChart` / `lineStackedColumnComboChart`.
- [Bar and column charts](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-customize-title-background-and-legend) — variants for `barChart`/`columnChart` family.
- [KPI visual](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-kpi) — `kpi` indicator/goal/trendLine roles.
- [Buttons / shapes / images](https://learn.microsoft.com/power-bi/create-reports/desktop-buttons) — `actionButton` / `shape` / `image`.
- [Group visuals](https://learn.microsoft.com/power-bi/create-reports/desktop-grouping-visuals) — `visualGroup` concept.

## Cross-visual interactions

- [Change how visuals interact in a Power BI report](https://learn.microsoft.com/power-bi/create-reports/service-reports-visual-interactions) — `NoFilter` / `Filter` / `Highlight` (matches the `visualInteractions` array on `page.json`).

## Custom visuals (`PBI_CV_<GUID>` / `deneb<GUID>`)

- [Power BI custom visuals overview](https://learn.microsoft.com/power-bi/developer/visuals/power-bi-custom-visuals) — what `PBI_CV_<GUID>` represents.
- [Deneb / Vega-Lite custom visual](https://learn.microsoft.com/power-bi/visuals/power-bi-deneb-visual) — Deneb-specific visualType pattern.

## Conditional formatting touch points

- [Apply conditional table formatting in Power BI](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-table-formatting) — see `pbir-conditional-formatting` skill for full coverage.

## Field references (Column / Measure / Aggregation / HierarchyLevel)

- [DAX measure vs calculated column](https://learn.microsoft.com/dax/calculated-columns-vs-measures) — the model concepts the JSON references.
- [Hierarchy in Power BI semantic models](https://learn.microsoft.com/power-bi/transform-model/desktop-create-and-manage-relationships) — what `HierarchyLevel` references.

## PBIR file format (where visual.json lives)

- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `definition/pages/<page>/visuals/<visual>/visual.json` location, folder rename rules.
- [Report definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — definition envelope and the canonical JSON-schema URL pattern.

## See also (this repo)

- `pbir-pages` — `page.json` / `pages.json` and `visualInteractions` reference
- `pbir-themes` — `objects` vs `visualContainerObjects` split that themes overlay
- `pbir-filters` — `filterConfig` placement (sibling of `visual`, not nested)
- `pbir-conditional-formatting` — `dataPoint` two-entry array, `dataViewWildcard.matchingOption: 1`
- `pbir-bookmarks` — visual `name` IDs targeted by `targetVisualNames`
