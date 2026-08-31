# MS Learn link bundle — PBIR Report Workflow

Curated set of Microsoft Learn pages relevant to building Power BI reports end-to-end — design guidance (3-30-300 hierarchy is in-house, but the underlying visual-design and accessibility principles map to MS Learn), the workflow this skill encodes (model field discovery → scaffold → page rename → row-by-row layout → bind + sort + filters → CF → validate + publish), and the canonical pbir CLI / publish path.

The 3 highest-leverage entry points (Power BI reports overview, design-effective-reports guide, design for accessibility) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** The pbir CLI per-command reference lives in `pbir-cli/references/REFERENCE.md` (already maintained). The PBIR JSON shape per artifact lives in the `pbir-visual-json` / `pbir-pages` / `pbir-filters` / `pbir-bookmarks` / `pbir-themes` skills. This bundle covers the upstream MS Learn content for the *design and workflow* aspects.

## Report-design principles

- [Power BI reports overview](https://learn.microsoft.com/power-bi/create-reports/power-bi-reports-overview) — entry point covering pages, visuals, filters, bookmarks, themes, slicers — the surface this workflow assembles.
- [Tips for designing a great Power BI report](https://learn.microsoft.com/power-bi/guidance/report-design-tips) — Power BI–specific design guidance: hierarchy, white space, typography, colors. Pairs with the in-house 3-30-300 viewing-distance hierarchy.
- [Design effective reports overview](https://learn.microsoft.com/power-bi/guidance/report-design) — the "report planning" framework Microsoft recommends.
- [Design reports for accessibility](https://learn.microsoft.com/power-bi/create-reports/desktop-accessibility-creating-reports) — color/contrast, tab order, alt text, screen reader. Use when the audience requires accessibility compliance.

## Layout, canvas, and page

- [Customize page sizes and dimensions in Power BI](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-page-size) — base values for the parent skill's "measure the scaffold first" rule. Default 1280x720 (16:9), Letter 816x1056, etc.
- [Group visuals in a report](https://learn.microsoft.com/power-bi/create-reports/desktop-grouping-visuals) — `visualGroup` for related visuals.

## Field discovery and DAX query view

- [Use DAX query view](https://learn.microsoft.com/power-bi/transform-model/dax-query-view) — `EVALUATE` queries against the model that `pbir model -q "..."` wraps. Useful for confirming distinct categorical values before adding a slicer.
- [Performance Analyzer](https://learn.microsoft.com/power-bi/create-reports/performance-analyzer) — when the laid-out page is slow.

## Visual selection and binding

- [Visualizations overview in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualizations-overview) — full visual catalog.
- [Visualization types in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-types-for-reports-and-q-and-a) — picking the right `visualType` per role (KPI, trend, breakdown, detail).
- [Get started formatting visuals](https://learn.microsoft.com/power-bi/visuals/service-getting-started-with-color-formatting-and-axis-properties) — formatting precedence (per-visual > theme).

## Filters and slicers

- [Filters in Power BI Desktop reports](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-add-filter) — add filters at report / page / visual scope.
- [Slicers in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-slicers) — slicers as visuals (NOT filters).

## Conditional formatting + theme tokens

- [Apply conditional table formatting in Power BI](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-table-formatting) — see `pbir-conditional-formatting` for the PBIR-side implementation.
- [Create custom report themes](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom) — `good`/`bad`/`neutral` sentiment colors that the workflow's extension-measure pattern returns.

## Publish to Fabric / Power BI workspace

- [Power BI Desktop project (PBIP) overview](https://learn.microsoft.com/power-bi/developer/projects/projects-overview) — what gets uploaded.
- [Fabric Git integration](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration) — Git → Fabric workspace deployment, the typical destination for a `pbir publish`.
- [Report items REST API (Fabric)](https://learn.microsoft.com/rest/api/fabric/report/items) — programmatic deploy alternative to `pbir publish`.

## Time-granularity and dates (relevant to step 7 trend visuals)

- [Auto date/time in Power BI Desktop](https://learn.microsoft.com/power-bi/transform-model/desktop-auto-date-time) — implicit date hierarchy used when no explicit date table.
- [Use the relative date slicer / filter](https://learn.microsoft.com/power-bi/visuals/desktop-slicer-filter-date-range) — RelativeDate + DateSpan / DateAdd time-unit semantics; the parent skill's "infer granularity from the active date filter" rule.

## See also (this repo)

- `pbir-cli` — full CLI command reference
- `pbir-pages` — page JSON structure (canvas, tooltip, drillthrough)
- `pbir-visual-json` — per-visual JSON shape
- `pbir-filters` — filterConfig at all three scopes
- `pbir-themes` — theme JSON file format
- `pbir-conditional-formatting` — measure-driven CF + theme tokens
- `pbip-project-structure` — full project file layout
