## PBIR visual.json Reference

Path: `Report.Report/definition/pages/{PageName}/visuals/{VisualName}/visual.json`

### Top-Level Structure

| Property | Type | Required | Notes |
|---|---|---|---|
| `$schema` | string | yes | `.../visualContainer/<version>/schema.json`; copy the version from another visual.json in the same report |
| `name` | string | yes | Stable visual ID — referenced by bookmarks, interactions |
| `position` | object | yes | `x`, `y`, `z`, `width`, `height`, `tabOrder` |
| `visual` | object | one of | Regular visual — mutually exclusive with `visualGroup` |
| `visualGroup` | object | one of | Group container |
| `parentGroupName` | string | no | Set on children of a `visualGroup` |
| `filterConfig` | object | no | Visual-scoped filters — sibling of `visual`, NOT nested |
| `isHidden` | boolean | no | Root-level. The saved visibility; the visual still processes data. A bookmark toggles its own `display.mode` instead ([bookmarks.md](bookmarks.md)) |

### position

```json
{"x": 100, "y": 50, "z": 1000, "width": 400, "height": 300, "tabOrder": 0}
```

`z` layer order: higher = front. Common values `0, 1000, 2000, 3000, 5000, 8000, 15000`.

### visual Object

| Property | Notes |
|---|---|
| `visualType` | See visual type table below |
| `query.queryState` | Role → projections map |
| `query.sortDefinition` | `sort[]` + `isDefaultSort` |
| `objects` | Visual-specific formatting (axes, legend, dataPoint, labels, lineStyles) |
| `visualContainerObjects` | Container formatting (title, subTitle, background, border, dropShadow, padding, divider, visualHeader, visualTooltip) |
| `drillFilterOtherVisuals` | boolean |
| `syncGroup` | Slicer cross-page sync: `groupName`, `fieldChanges`, `filterChanges` |
| `expansionStates` | pivotTable row/column expansion |

**Critical**: `objects` vs `visualContainerObjects` are distinct in schema 2.4.0+. Container properties in `objects` fail silently. `visualContainerObjects` at root errors.

### Expression Literal Suffixes

All formatting values inside `visual.json` use `{"expr": {"Literal": {"Value": "..."}}}` wrappers. Theme JSON uses bare values.

| Type | Example | Notes |
|---|---|---|
| String | `"'smooth'"` | Inner single quotes required |
| Double | `"14D"` | Font sizes, percentages, most numerics |
| Integer | `"14L"` | Pixel counts, enum values, `labelPrecision` |
| Decimal | `"2.4M"` | Money/decimal precision |
| Boolean | `"true"` | Lowercase, no quotes, no suffix |
| DateTime | `"datetime'2024-01-15T00:00:00.0000000'"` | Closing `'` required |
| Hex color | `"'#FF0000'"` | Inner single quotes; 6-digit RGB or 8-digit ARGB |
| Null | `"null"` | Lowercase, no quotes |

Non-literal expressions:

| Type | Shape |
|---|---|
| Theme color | `{"expr": {"ThemeDataColor": {"ColorId": 0, "Percent": 0}}}` |
| Extension measure | `{"expr": {"Measure": {"Expression": {"SourceRef": {"Schema": "extension", "Entity": "_Formatting"}}, "Property": "Color"}}}` |

**Gotchas**: `transparency` uses `D` normally but `L` inside `dropShadow`. `labelPrecision` always `L`, `labelDisplayUnits` always `D`. String escaping: single quotes doubled (`"'O''Brien'"`). Font fallback chains: `"'''Segoe UI Semibold'', helvetica, sans-serif'"`.
(Yes — three single quotes. The outer pair wraps the SQExpr string literal; the inner pair escapes the space-containing font name. Not a typo.)

### Field Reference Patterns

| Pattern | Shape |
|---|---|
| Column | `{"Column": {"Expression": {"SourceRef": {"Entity": "Table"}}, "Property": "Col"}}` |
| Measure (model) | `{"Measure": {"Expression": {"SourceRef": {"Entity": "Table"}}, "Property": "M"}}` |
| Measure (extension) | `{"Measure": {"Expression": {"SourceRef": {"Schema": "extension", "Entity": "_Fmt"}}, "Property": "M"}}` |
| Aggregation | `{"Aggregation": {"Expression": {"Column": {...}}, "Function": 0}}` |
| Hierarchy level | `{"HierarchyLevel": {"Expression": {"Hierarchy": {...}}, "Level": "Level"}}` |
| SparklineData | `{"SparklineData": {"Measure": {...}, "Groupings": [{"Column": {...}}]}}` |

`QueryAggregateFunction`: `0`=Sum, `1`=Avg, `2`=DistinctCount, `3`=Min, `4`=Max, `5`=Count, `6`=Median, `7`=StdDev, `8`=Var

**Filter SourceRef gotcha**: inside filter `Where` conditions, SourceRef uses `"Source": "alias"` (from `From`), NOT `"Entity"`. Query projections use `"Entity"`.

### Visual Types and Query Roles

| visualType | Roles |
|---|---|
| `card` | Values |
| `cardVisual` (new card) | Data |
| `tableEx` | Values |
| `pivotTable` | Rows, Columns, Values |
| `slicer` / `advancedSlicerVisual` | Values |
| `pieChart` / `donutChart` | Category, Y |
| `lineChart` | Category, Y, Y2 (combo) |
| `areaChart` / `stackedAreaChart` | Category, Y, Series |
| `barChart` / `clusteredBarChart` / `hundredPercentStackedBarChart` | Category, Y |
| `columnChart` / `clusteredColumnChart` / `hundredPercentStackedColumnChart` | Category, Y |
| `lineClusteredColumnComboChart` / `lineStackedColumnComboChart` | Category, Y, Y2 |
| `ribbonChart` / `waterfallChart` | Category, Y |
| `scatterChart` | Category, X, Y, Size, Tooltips |
| `gauge` | Y, TargetValue |
| `kpi` | Indicator, Goal, TrendLine |
| `textbox` | none (uses `objects.general.paragraphs`) |
| `shape` / `actionButton` / `image` | none |
| `scriptVisual` / `pythonVisual` | Values |
| `PBI_CV_<GUID>` | varies (custom visuals) |
| `deneb<GUID>` | dataset |

### Projection Properties

| Property | Notes |
|---|---|
| `queryRef` | `Table.Field` — internal reference |
| `nativeQueryRef` | Display label |
| `displayName` | Optional override |
| `active` | Boolean — hierarchy level expanded |

Visual calculations (`NativeVisualCalculation`) always have `queryRef: "select"`.

### sortDefinition

```json
"sortDefinition": {
  "sort": [{
    "field": {"Measure": {"Expression": {"SourceRef": {"Entity": "Sales"}}, "Property": "Revenue"}},
    "direction": "Descending"
  }],
  "isDefaultSort": true
}
```

### Slicer Default Selected Values

Store in `objects.general.properties.filter` — NOT `filterConfig`. `filterConfig` filters data going *into* the slicer; `objects.general.properties.filter` pre-selects values.

### Hiding Visuals and Fields

- Hide whole visual: `"isHidden": true` at root (outside `visual`).
- Hide fields from display: omit from `queryState` — still referenceable by extension measures / filters.

### Visual Groups

```json
{
  "name": "kpi_group",
  "position": {"x": 0, "y": 0, "z": 0, "width": 800, "height": 400},
  "visualGroup": {
    "displayName": "KPI Section",
    "groupMode": "ScaleMode",
    "objects": {"background": [...], "general": [...], "lockAspect": [...]}
  }
}
```

`groupMode`: `ScaleMode` (scale contents) or `ScrollMode`. Children set `parentGroupName`. Group objects limited to `background`, `general`, `lockAspect`.

### Table / Matrix Column Widths

```json
"columnWidth": [{
  "properties": {"value": {"expr": {"Literal": {"Value": "215D"}}}},
  "selector": {"metadata": "Orders.Order Lines"}
}]
```

### mobile.json

Optional sibling file at `visuals/{VisualName}/mobile.json`. Mirrors `visual.json` position fields with mobile coordinates. Typically authored via Desktop.

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| Container props silently ignored | Placed in `objects` instead of `visualContainerObjects` | Move title/border/background/dropShadow/padding to `visualContainerObjects` |
| Root-level error on `visualContainerObjects` | Placed at `visual.json` root instead of inside `visual` | Nest under `visual` (container objects still live inside `visual`) |
| `filterConfig` ignored | Nested inside `visual` | Must be sibling of `visual` at root of visual.json |
| Slicer default values don't stick | Stored in `filterConfig` | Use `objects.general.properties.filter` |
| `transparency` parse error in dropShadow | Used `D` suffix | Use `L` inside `dropShadow` |
| String literal unterminated | Missing closing single quote on `datetime'...'` | Always close datetime literals with `'` |
| Filter Where condition broken | Used `SourceRef.Entity` instead of `SourceRef.Source` | Reference the alias from `From[]` |
| Font fallback chain broken | Single-level quotes | Triple-quote primary font: `"'''Segoe UI Semibold'', sans-serif'"` |
| `labelPrecision` rejected | Used `D` suffix | Always `L` |
| `labelDisplayUnits` rejected | Used `L` suffix | Always `D` |
| Sparkline formatting ignored | `selector.metadata` doesn't match projection `queryRef` | Copy exact `SparklineData(...)` queryRef into selector |
| `visual` and `visualGroup` both present | Mutually exclusive | Pick one per visual.json |

### Card, slicer and narrative visuals (verified April 2026)

| Visual | Behaviour | Authoring impact |
|---|---|---|
| `cardVisual` / `slicer` (button-slicer / list-slicer modes) | Multicard layout exposes a **Fixed size** toggle (exact pixel dimensions). Mutually exclusive with **Fit to space** (renamed from `Autogrid`). | Property names not yet documented as a JSON-schema keys — verify in a saved visual.json before authoring. Existing reports with `Autogrid` formatting will surface under `Fit to space` in the Format pane. |
| `cardVisual` | Theme JSON keys `paddingUniform` (default 12) and `backgroundTransparency` documented under `cardVisual` style preset. Category headers participate in Edit interactions; Multi-category layout `Autogrid` capped at 4 rows (toggle off for more). | When clearing legacy padding, write `"paddingUniform": 0`. Theme schema URL is `reportThemeSchema-2.149.json`. |
| `narrativeVisual` (smart narrative) | Defaults to **Copilot mode** for users with a Copilot license. Character limit raised to **10,000**. | Narrative visual.json content beyond 10,000 chars should now load; treat default-mode probes carefully — un-licensed users still land in classic mode. |

### August 2026 formatting properties

Power BI's August 2026 release added the formatting settings below. Their
names come from Microsoft's report theme schema 2.157
([`reportThemeSchema-2.157.json`](https://github.com/microsoft/powerbi-desktop-samples/blob/main/Report%20Theme%20JSON%20Schema/reportThemeSchema-2.157.json)),
whose `visualStyles` use the object and property names that a
`visual.json` `objects` block does. No PBIP export has yet shown Desktop
writing them, so check a name against one saved report before relying on
it. Labels are the format pane's, as Learn and the schema's titles give
them.

`pbir set` refused every name tried that is new in 2.157, on 0.9.29 and
0.9.32 alike, while 0.9.29 took every one its bundled theme schema,
2.155, already had. Write the new ones into `visual.json` by hand
([pbir-cli.md](pbir-cli.md), Gotchas). 0.9.29's `pbir validate` passes
them; with `--semantic` it warns on the `dropdown` and `centerBackground`
objects, and lists as info the new properties its catalog lacks.

Types are the schema's, and a fill is a `solid.color` object, as in
[conditional-formatting.md](conditional-formatting.md). A type does not
settle a number's literal suffix: the schema types `labelDisplayUnits` as
an integer, yet it takes `D` (Gotchas, above). Which suffix Desktop
writes for these is open.

#### Matrix (`pivotTable`)

| Format pane | Property | Type |
| --- | --- | --- |
| Row headers > +/- icons | `rowHeaders.showExpandCollapseButtons` | boolean |
| Row headers > +/- icons > Color | `rowHeaders.expandCollapseButtonsColor` | fill |
| Row headers > +/- icons > Expand/collapse icon size | `rowHeaders.expandCollapseButtonsSize` | number, 8–60 |
| Column headers > +/- icons | the same three on `columnHeaders`, new in 2.157 | as for rows |
| Row or Column headers > Options > Auto expand | `autoExpand` on `rowHeaders` or `columnHeaders` | boolean |

**Layout** > **Freeze** > **Row headers**, the default freeze state, has
no property the schema ties to it. The one candidate is
`rowHeaders.unfrozen`, a boolean in the theme schema since 2.149 or
earlier and untitled there. `pbir`'s own gloss, "Allow row headers to
scroll horizontally instead of staying frozen/pinned", would make `true`
the toggle turned off. It is unconfirmed until an export shows it.

#### Bar, column and line charts

Learn puts the first three under **Layout** in the **Columns**, **Bars**
or **Lines** section.

| Format pane | Property | Carried by | Type |
| --- | --- | --- | --- |
| Outer padding | `categoryAxis.outerPadding`, new in 2.157 | every bar, column, line, area, combo, ribbon, scatter and waterfall type | integer, percent |
| Space between categories | `categoryAxis.innerPadding` | the same, less line and area | integer, percent |
| Space between series | `layout.stackedGapSize` | stacked and 100% stacked bar and column, ribbon, line and stacked column | number |
| Space between series | `layout.clusteredGapSize` | clustered bar and column, line and clustered column | number |
| Overlap series | `layout.clusteredGapOverlaps` | the three clustered types | boolean |
| Flip overlap | `layout.clusteredGapOverlapReverse` | the three clustered types | boolean |

The schema titles `outerPadding` "Space at edges". The two "Space
between" labels replaced Category spacing and Series spacing; the
properties, in the schema since 2.149, kept their names.

#### Slicer (`slicer`)

| Format pane | Property | Type |
| --- | --- | --- |
| Slicer settings > Options > Style | `data.mode` | string, below |
| Slicer settings > Selection controls > Single date | `selection.singleDate`, new in 2.157 | boolean |
| Dropdown > Border color | `dropdown.borderColor`, new in 2.157, as is all of `dropdown` | fill |
| Dropdown > Rounded corners | `dropdown.borderRadius`, or `borderIndividualCorners` with `borderTopLeftCorner` and its three siblings | integer; boolean, integers |
| Dropdown > Open icon | `dropdown.iconColor`, `iconTransparency`, `iconSize` | fill, number, number 8–60 |
| Dropdown > Accent bar | `dropdown.accentBarColor`, `accentBarPosition`, `accentBarTransparency`, `accentBarWidth` | fill; `'Left'`, `'Right'`, `'Bottom'` or `'Top'`; number; number |
| Hierarchy > Icon color | `items.expandCollapseIconColor`, new in 2.157 | fill |
| Hierarchy > Icon | `items.expandCollapseToggleType` | integer: `0` Chevron, `1` Plus/minus, `2` Caret |
| Selection icon > Color | `selectionIcon.color` | fill |

`data.mode` takes the style, the schema's title in brackets where it
differs: `'Dropdown'`, `'VerticalList'` (Vertical list),
`'HorizontalList'` (Tile), `'Basic'` (List), `'Between'`, `'Before'`,
`'After'`, `'Single'` (Single Value), `'Relative'` (Relative Date),
`'RelativeTime'` (Relative Time) and `'RelativeDatePicker'` (Date
Picker). `'Single'` is not the Single date toggle. 2.157 names no
property for the Date picker's **Anchor** or **Offset**. Learn puts the
Dropdown section on the Dropdown style alone, and Hierarchy and Selection
icon on Dropdown and Vertical list.

#### Donut chart (`donutChart`)

**Center value** is `centerValue.show`, a boolean. Its format is in four
objects that came with it in 2.157:

| Format pane | Object | Properties |
| --- | --- | --- |
| Value | `value` | `show`, `value`, `labelDisplayUnits`, `labelPrecision`, `showBlankAs`, `fontFamily`, `fontSize`, `fontColor`, `bold`, `italic`, `underline`, `textWrap` |
| Label | `label` | `show`, `text`, `position`, `gap`, `fontFamily`, `fontSize`, `fontColor`, `bold`, `italic`, `underline`, `textWrap` |
| Image | `image` | `show`, `image`, `altText`, `position`, `size`, `gap`, `transparency` |
| Background | `centerBackground` | `show`, `fillColor`, `image`, `fit`, `imageTransparency`, `padding`, `transparency` |

On `label` and `image`, `position` is `'Top'` (above the value) or
`'Bottom'`; `fit` is `'Fit'`, `'Stretch'` or `'Fill'`; `gap`, `size` and
`padding` are integers. How Learn's custom measure, **Value** >
**Field**, is written is not shown.

`pbir schema describe` shows other names for these, from version 0.1.1 of
Microsoft's visual capabilities catalog, published 2026-06-12, which
`pbir` bundles and notes may lag the product: a `background` object
holding the centre's fill, image and padding, and `valueBold`,
`valueFontColor`, `valueDisplayUnits`, `valuePrecision` and the like on
`value`. Theme schema 2.157 has none of these, its `background` being
the container's `color`, `show` and `transparency`. Write 2.157's names.

Sources, read 2026-10-12: the theme schema above, and Learn's
[matrix format settings](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-matrix-visual-format-settings),
[x-axis and y-axis](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-customize-x-axis-and-y-axis),
[slicer visual](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-slicer-visual)
and
[pie and donut chart](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-pie-donut-chart)
pages.

### Reference

- Microsoft Learn: [Visualizations overview in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualizations-overview)
- Microsoft Learn: [Visualization types in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-types-for-reports-and-q-and-a)
- Microsoft Learn: [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report)
- Microsoft Learn: [Card visual — Fixed size, Fit to space, theme keys](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-card)
- Microsoft Learn: [Smart narrative visual](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-smart-narrative)
- Comprehensive MS Learn link bundle (visual catalog → visualType / per-visual articles / visualGroup / custom visuals / PBIR file format): § MS Learn link bundle, below

### MS Learn link bundle

Curated set of Microsoft Learn pages relevant to the per-visual JSON in PBIR — the canonical "what visualType X needs" reference (visual catalog), per-visual-type formatting docs, the visualGroup concept, and the PBIR file structure that holds `visual.json`.

The 3 highest-leverage entry points (visualizations overview, build-a-report intro, PBIR project file layout) are also linked in § Reference above for in-context use; this section holds the comprehensive set.

**Note on docs split:** The PBIR `visual.json` JSON internals (top-level `name`/`position`/`visual`/`visualGroup`/`filterConfig`, expression-literal suffix grammar with `D`/`L`/`M`/`'string'`/`datetime'...'`, `objects` vs `visualContainerObjects` split in schema 2.4.0+, `dataViewWildcard` selectors, `SourceRef.Source` vs `Entity` rule) are *not* documented narratively on MS Learn — the canonical machine-readable reference is at `developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/...`. The Power BI visual catalog and per-visual-type articles document what each `visualType` does and which roles it expects.

#### Visual catalog (mapping `visualType` → user-facing concept)

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

#### Cross-visual interactions

- [Change how visuals interact in a Power BI report](https://learn.microsoft.com/power-bi/create-reports/service-reports-visual-interactions) — `NoFilter` / `Filter` / `Highlight` (matches the `visualInteractions` array on `page.json`).

#### Custom visuals (`PBI_CV_<GUID>` / `deneb<GUID>`)

- [Power BI custom visuals overview](https://learn.microsoft.com/power-bi/developer/visuals/power-bi-custom-visuals) — what `PBI_CV_<GUID>` represents.
- [Deneb / Vega-Lite custom visual](https://learn.microsoft.com/power-bi/visuals/power-bi-deneb-visual) — Deneb-specific visualType pattern.

#### Conditional formatting touch points

- [Apply conditional table formatting in Power BI](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-table-formatting) — see [conditional-formatting.md](conditional-formatting.md) for full coverage.

#### Field references (Column / Measure / Aggregation / HierarchyLevel)

- [DAX measure vs calculated column](https://learn.microsoft.com/dax/calculated-columns-vs-measures) — the model concepts the JSON references.
- [Hierarchy in Power BI semantic models](https://learn.microsoft.com/power-bi/transform-model/desktop-create-and-manage-relationships) — what `HierarchyLevel` references.

#### PBIR file format (where visual.json lives)

- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `definition/pages/<page>/visuals/<visual>/visual.json` location, folder rename rules.
- [Report definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — definition envelope and the canonical JSON-schema URL pattern.

### See also

- [themes.md](themes.md) — theme value conventions (bare vs wrapped literals)
- [conditional-formatting.md](conditional-formatting.md) — CF patterns inside visual.json `objects`
- [filters.md](filters.md) — filter body shape and `SourceRef.Source` rule
- [bookmarks.md](bookmarks.md) — bookmarks reference the visual's root-level `name`
- [pages.md](pages.md) — `page.json` / `pages.json` and `visualInteractions` reference
