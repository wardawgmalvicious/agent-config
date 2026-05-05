---
name: pbir-visual-json
description: Use when editing visual.json inside a Power BI PBIR report's visuals/ folder. Covers top-level structure (name, position, visual vs visualGroup mutually exclusive, filterConfig sibling NOT child of visual, root-level isHidden for bookmark toggles), expression literal suffixes — string 'text', double 14D, integer 14L, decimal 2.4M, hex '#FF0000', datetime literal, null — with exceptions (transparency uses L inside dropShadow, labelPrecision L, labelDisplayUnits D, triple-quoted font fallback chains), field reference patterns (Column, Measure, Aggregation, HierarchyLevel, SparklineData), visual-type to query-role map (card, tableEx, pivotTable, slicer, lineChart, barChart, kpi, scatterChart), objects vs visualContainerObjects split, sortDefinition, slicer default values via objects.general.properties.filter, visual groups, table column widths. Invoke when user edits visual.json, sets a visual property, debugs silently-ignored container props, or writes SQExpr literals.
paths:
  - "**/visuals/**/visual.json"
---

## PBIR visual.json Reference

Path: `Report.Report/definition/pages/{PageName}/visuals/{VisualName}/visual.json`

### Top-Level Structure

| Property | Type | Required | Notes |
|---|---|---|---|
| `$schema` | string | yes | `.../visualContainer/2.7.0/schema.json` |
| `name` | string | yes | Stable visual ID — referenced by bookmarks, interactions |
| `position` | object | yes | `x`, `y`, `z`, `width`, `height`, `tabOrder` |
| `visual` | object | one of | Regular visual — mutually exclusive with `visualGroup` |
| `visualGroup` | object | one of | Group container |
| `parentGroupName` | string | no | Set on children of a `visualGroup` |
| `filterConfig` | object | no | Visual-scoped filters — sibling of `visual`, NOT nested |
| `isHidden` | boolean | no | Root-level. Visual still processes data; common for bookmark toggles |

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

### April 2026 visual changes

| Visual | Change | Authoring impact |
|---|---|---|
| `cardVisual` / `slicer` (button-slicer / list-slicer modes) | Multicard layout exposes a **Fixed size** toggle (exact pixel dimensions). Mutually exclusive with **Fit to space** (renamed from `Autogrid`). | Property names not yet documented as a JSON-schema keys — verify in a saved visual.json before authoring. Existing reports with `Autogrid` formatting will surface under `Fit to space` in the Format pane. |
| `cardVisual` | Theme JSON keys `paddingUniform` (default 12) and `backgroundTransparency` documented under `cardVisual` style preset. Category headers participate in Edit interactions; Multi-category layout `Autogrid` capped at 4 rows (toggle off for more). | When clearing legacy padding, write `"paddingUniform": 0`. Theme schema URL is `reportThemeSchema-2.149.json`. |
| `narrativeVisual` (smart narrative) | Defaults to **Copilot mode** for users with a Copilot license. Character limit raised to **10,000**. | Narrative visual.json content beyond 10,000 chars should now load; treat default-mode probes carefully — un-licensed users still land in classic mode. |

### Reference

- Microsoft Learn: [Visualizations overview in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualizations-overview)
- Microsoft Learn: [Visualization types in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-types-for-reports-and-q-and-a)
- Microsoft Learn: [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report)
- Microsoft Learn: [Card visual — Fixed size, Fit to space, theme keys](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-card)
- Microsoft Learn: [Smart narrative visual](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-smart-narrative)
- Comprehensive MS Learn link bundle (visual catalog → visualType / per-visual articles / visualGroup / custom visuals / PBIR file format): [references/REFERENCE.md](references/REFERENCE.md)

### See also

- `pbir-themes` — theme value conventions (bare vs wrapped literals)
- `pbir-conditional-formatting` — CF patterns inside visual.json `objects`
- `pbir-filters` — filter body shape and `SourceRef.Source` rule
- `pbir-bookmarks` — bookmarks reference the visual's root-level `name`
