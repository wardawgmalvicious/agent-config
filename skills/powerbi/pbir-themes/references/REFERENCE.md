# MS Learn link bundle — PBIR Themes

Curated set of Microsoft Learn pages relevant to Power BI report themes — the JSON file format itself, the dataColors palette, sentiment colors, textClasses, visualStyles by visual type and state, the inheritance model, and how the file lives inside a PBIR project under `StaticResources/`.

The 3 highest-leverage entry points (use report themes / create custom themes / report theme JSON file format) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** The Power BI report theme JSON format is *one of the better-documented* PBIR-adjacent surfaces on MS Learn. The custom-themes article documents the file format directly; the parent skill adds the PBIR-specific bits (where the file lives in the project, how `visualStyles` overlays with `visual.json` `objects`/`visualContainerObjects`, the bare-numbers-no-D-suffix difference vs visual.json).

## Theme JSON file format (canonical)

- [Use report themes in Power BI Desktop](https://learn.microsoft.com/power-bi/create-reports/desktop-report-themes) — apply / browse themes, the base-theme vs custom-theme inheritance the parent skill documents.
- [Create custom report themes in Power BI Desktop](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom) — full theme JSON reference: dataColors, sentiment colors (good/bad/neutral/minimum/maximum/center), structural colors (background/foreground/tableAccent/firstLevelElements/secondLevelElements), textClasses (title/header/label/callout + size variants), visualStyles, style presets.
- [Power BI Embedded — Apply Report Themes (Report Theme Object)](https://learn.microsoft.com/javascript/api/overview/powerbi/apply-report-themes) — the JS Embedded API surface that consumes the same theme JSON object; useful as a complete property reference.

## Style presets (CY24SU10+ style swatches)

- [Create style presets in custom themes](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom#create-style-presets-in-custom-themes) — preset-per-visual-type pattern; how the Style dropdown surfaces in the visual format pane after import.

## Text classes

- [Set formatted text defaults](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom#set-formatted-text-defaults) — the canonical text-class table (title / largeTitle / header / label / semiboldLabel / largeLabel / smallLabel / lightLabel / boldLabel / largeLightLabel / smallLightLabel / callout) with default font / size / color and which visual elements consume each. Critical when the parent skill's `textClasses` overrides need to match the right class.

## Inheritance and the visualStyles wildcard

- [Use report themes — how the report uses themes](https://learn.microsoft.com/power-bi/create-reports/desktop-report-themes#understand-how-the-report-uses-themes) — base theme vs custom theme vs per-visual override. Maps to the parent skill's `visualStyles["*"]["*"]` → `visualStyles[type][state]` → per-visual `objects` chain.
- [Customize report colors and mode showcase (Embedded sample)](https://learn.microsoft.com/javascript/api/overview/powerbi/showcase-themes) — Light/Dark mode patterns with theme objects.

## PBIR file format (where themes live)

- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `StaticResources/SharedResources/BaseThemes/` (built-in) vs `StaticResources/RegisteredResources/` (custom), and how `report.json → themeCollection` references both.
- [Report definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — theme files round-trip via the `definition/` part.

## Filter pane styling (cross-skill — owned by theme)

- [Customize the filter pane via theme](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom#filter-pane-and-filter-card) — the theme keys (`outspacePane`, `filterCard`) where filter-pane colors/text/widths live (per the parent skill's split: `outspacePane` *visibility* on report.json, *styling* in theme).

## See also (this repo)

- `pbir-visual-json` — `objects` vs `visualContainerObjects` split that themes overlay
- `pbir-conditional-formatting` — `'good'`/`'bad'`/`'neutral'`/`'minColor'`/`'midColor'`/`'maxColor'` tokens that resolve from theme sentiment colors
- `pbir-filters` — the filter-pane visibility/expansion side that lives on `report.json`
