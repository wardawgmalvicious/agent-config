# MS Learn link bundle — PBIR Pages

Curated set of Microsoft Learn pages relevant to Power BI report pages — page sizes, types (Default/Tooltip), visibility, the canvas vs wallpaper distinction, tooltip pages, drillthrough pages, and visual interactions. Plus the PBIR file structure where `page.json` and `pages.json` live.

The 3 highest-leverage entry points (page customization, tooltip pages, drillthrough) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** PBIR `page.json` JSON internals (string-typed `displayOption`, the `objects.background` vs `objects.outspace` distinction, `visualInteractions` shape, the page `name` GUID rule) are *not* documented narratively on MS Learn — the canonical machine-readable reference is at `developer.microsoft.com/json-schemas/fabric/item/report/definition/page/...`. The Power BI Desktop pages document what user choices the JSON encodes.

## User-facing concept (what the JSON encodes)

- [Customize page sizes and dimensions in Power BI](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-page-size) — page sizes (16:9, Letter, Tooltip), `width`/`height` properties, the `displayOption` (FitToPage / FitToWidth / ActualSize) UX.
- [Hide pages in Power BI](https://learn.microsoft.com/power-bi/create-reports/power-bi-hide-report-pages) — corresponds to `visibility: HiddenInViewMode`.

## Canvas background and wallpaper

- [Customize the wallpaper in Power BI reports](https://learn.microsoft.com/power-bi/create-reports/desktop-wallpaper) — the user surface for the `outspace` object (wallpaper *behind* the canvas) and how it differs from `background` (canvas itself). Maps directly to the parent skill's hierarchy explanation.
- [Format report page background](https://learn.microsoft.com/power-bi/create-reports/desktop-report-themes#format-report-page-background) — canvas-side `background` color/transparency.

## Tooltip pages

- [Create tooltips based on report pages](https://learn.microsoft.com/power-bi/create-reports/desktop-tooltips) — `type: Tooltip`, `visibility: HiddenInViewMode`, the per-visual `visualTooltip` opt-in (`type: 'ReportPage'`, `section: '<page name GUID>'`). Confirms the parent skill's "section uses GUID, not displayName" gotcha.

## Drillthrough pages

- [Use drillthrough in Power BI reports](https://learn.microsoft.com/power-bi/create-reports/desktop-drillthrough) — `Column`-typed filter in `filterConfig`, page hidden via `HiddenInViewMode`, optional back-button.
- [Add drillthrough buttons](https://learn.microsoft.com/power-bi/create-reports/desktop-drillthrough#add-a-drillthrough-button) — buttons that navigate to a drillthrough page.
- [Cross-report drillthrough](https://learn.microsoft.com/power-bi/create-reports/desktop-drillthrough#enable-cross-report-drillthrough) — drillthrough across reports.

## Visual interactions (`visualInteractions`)

- [Change how visuals interact in a Power BI report](https://learn.microsoft.com/power-bi/create-reports/service-reports-visual-interactions) — the user UX for `NoFilter` / `Filter` / `Highlight`. The `source`/`target` reference visual `name` IDs (file-internal, not displayName).

## Page-level filters

- [Filters in Power BI Desktop reports](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-add-filter) — page filterConfig is the same shape as report and visual filterConfig. See `pbir-filters`.

## Filter pane (cross-skill clarification — NOT page-level)

- [Format filters in Power BI reports](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-filter) — clarifies `outspacePane` is **report-level** in PBIR, never page-level. Visibility/expansion in `report.json`; styling in theme.

## PBIR file format (where pages live)

- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `definition/pages/<PageName>/page.json` + `definition/pages/pages.json` (pageOrder + activePageName).
- [Report definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — schema URL pattern documenting the full `developer.microsoft.com/json-schemas/fabric/item/report/...` namespace.

## See also (this repo)

- `pbip-project-structure` — full project file layout, the page folder rename rule
- `pbir-cli` — `pbir pages` / `pbir visuals` discovery commands
- `pbir-filters` — page-level filter syntax + outspacePane visibility on report.json
- `pbir-themes` — outspacePane styling
- `pbir-visual-json` — visual `name` IDs referenced by `visualInteractions`
