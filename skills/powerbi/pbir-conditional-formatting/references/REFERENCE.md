# MS Learn link bundle — PBIR Conditional Formatting

Curated set of Microsoft Learn pages relevant to conditional formatting in Power BI — Desktop UX, the field-value / rule / gradient mechanisms, the data-bar/icon overlays, and how the Desktop choices serialize into PBIR `visual.json` (per-point `dataPoint` two-entry array, `FillRule.linearGradient2/3`, extension-measure `Schema: extension`, `dataViewWildcard.matchingOption`).

The 3 highest-leverage entry points (CF in tables/matrices, CF for fill colors via measure, FillRule color scales) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** The PBIR JSON shape (`dataPoint` two-entry array, `dataViewWildcard`, `linearGradient2/3`, extension-measure expression) is *not* documented narratively on MS Learn — the canonical machine-readable reference is the `developer.microsoft.com/json-schemas/fabric/...` schema family. The Power BI Desktop / Service pages document what user choices the JSON encodes.

## Conditional formatting — user concept

- [Apply conditional table formatting in Power BI](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-table-formatting) — full reference for table/matrix CF: backgrounds, font color, data bars, icons, web URLs. The Desktop UX corresponds to the `dataBars` / `icon` blocks the parent skill documents.
- [Conditional formatting for chart visuals](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-format-visual-titles) — color-by-rule / color-by-field / gradient color scales for chart elements. Maps to the `dataPoint` two-entry-array + `dataViewWildcard.matchingOption: 1` pattern.
- [Tips and tricks for color formatting in Power BI](https://learn.microsoft.com/power-bi/create-reports/service-tips-and-tricks-for-color-formatting) — color expressions, theme-driven colors, dynamic colors via measures.

## Color expression measures (the `Text` extension measure pattern)

- [Use measures returning hex codes for conditional formatting](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-format-by-field#format-by-field-value) — the canonical "measure returns `'good'`/`'bad'`/`'#FF0000'`" pattern. Confirms `Text` data-type requirement that the parent skill calls out. Theme tokens `good`/`bad`/`neutral`/`minColor`/`midColor`/`maxColor` resolve to dataColors / sentiment colors from the report theme.
- [DAX SWITCH function](https://learn.microsoft.com/dax/switch-function-dax) — typical building block for the color-bucket extension measure.

## Color scales / gradients (FillRule)

- [Apply color formatting based on field value (gradient)](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-table-formatting#color-by-color-scale) — UI surface for two-color (linearGradient2) and three-color (linearGradient3) scales.

## Theme tokens used by `'good'`/`'bad'`/`'neutral'`

- [Create custom report themes — sentiment colors](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom#sentiment-colors) — `good` / `bad` / `neutral` / `minimum` / `maximum` / `center` semantic-color slots; what the strings the Text-typed extension measure returns resolve to.
- See `pbir-themes` skill for full theme structure.

## PBIR file format (where CF lives)

- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `visual.json` and `reportExtensions.json` locations the parent skill modifies.
- [Report definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — CF lives inside the `definition/` part.

## See also (this repo)

- `pbir-visual-json` — `objects` vs `visualContainerObjects` split, expression literal suffixes
- `pbir-themes` — theme tokens (`good`/`bad`/`minColor`/`maxColor`) the measure can return
- `pbir-filters` — same SQExpr `Comparison` / `ComparisonKind` codes used by `Conditional.Cases`
