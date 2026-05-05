---
name: pbir-conditional-formatting
description: Use when adding conditional formatting to a Power BI visual — per-point bar/column colors, diverging gradients, line segment colors, marker transparency, data bars, conditional icons. Three approaches — measure-based (extension measure dataType Text returning theme tokens good/bad/neutral/minColor/midColor/maxColor), FillRule linearGradient2/linearGradient3, rule-based Conditional.Cases. Plus dataViewWildcard selector with matchingOption 1 for per-point, required two-entry array pattern for dataPoint/lineStyles/error, extension measures attaching to EXISTING semantic-model entities via reportExtensions.json, Schema extension on report-level measures, line segment limits (single-series only, segmentGradient affects strokeColor only), marker color/shape/size NOT CF-able (use transparency), ComparisonKind codes 0-4, ScopedEval + AllRolesRef for global min/max. Invoke when user colors bars by a measure, fixes same-color-on-all-points, adds a gradient, data bars, or conditional icons.
paths:
  - "**/visuals/**/visual.json"
  - "**/definition/reportExtensions.json"
---

## PBIR Conditional Formatting Reference

Three approaches: measure-based (flexible), `FillRule` gradients (no DAX), and rule-based `Conditional` (UI-generated).

### Approach Matrix

| Approach | Best For | Pros | Cons |
|---|---|---|---|
| Measure-based | Custom logic, theme colors | Full DAX, readable | Requires extension measure |
| `linearGradient2` / `linearGradient3` | Color scales | No DAX | Gradients only |
| `Conditional.Cases` | UI-portable rules | Power BI UI round-trips | Verbose |

### Supported Properties

Not every property accepts measure expressions. These do:

`fill`, `borderColor`, `defaultColor`, `fontColor`, `color`, `backgroundColor`, `lineColor`, `markerColor`, `strokeColor`, `text`, `titleText`, `fontSize`, `strokeWidth`, `weight`, `transparency`, `radius`, `url`, `good`, `bad`, `neutral`, `target`, `icon`

Everything else is literal-only or `ThemeDataColor`.

### dataViewWildcard Selector

The key to per-point formatting.

| `matchingOption` | Behavior |
|---|---|
| `0` | Identities + totals (series-level) |
| `1` | Per data point (most common for CF) |
| `2` | Totals only |

```json
"selector": {"data": [{"dataViewWildcard": {"matchingOption": 1}}]}
```

Wrong for per-point: `"selector": {"metadata": "Sales.Revenue"}` — evaluates once per series.

### Two-Entry Array Pattern (Required)

`dataPoint`, `lineStyles`, `error` require a two-entry array: base entry + conditional entry.

```json
"dataPoint": [
  {"properties": {}},
  {
    "properties": {
      "fill": {"solid": {"color": {"expr": {"Measure": {
        "Expression": {"SourceRef": {"Schema": "extension", "Entity": "_Formatting"}},
        "Property": "Bar Color"
      }}}}}
    },
    "selector": {"data": [{"dataViewWildcard": {"matchingOption": 1}}]}
  }
]
```

### Extension Measure (for color CF)

Defined in `Report.Report/definition/reportExtensions.json`. **`dataType` MUST be `"Text"`** for color measures. Must attach to an EXISTING entity from the model.

```json
{
  "name": "extension",
  "entities": [{
    "name": "_Formatting",
    "measures": [{
      "name": "Bar Color",
      "dataType": "Text",
      "expression": "SWITCH(TRUE(), [Value]<10, \"bad\", [Value]<50, \"neutral\", \"good\")"
    }]
  }]
}
```

Theme color names returned by measures: `"bad"`, `"good"`, `"neutral"`, `"minColor"`, `"midColor"`, `"maxColor"`.

### Measure Reference in CF Expressions

```json
{"expr": {"Measure": {
  "Expression": {"SourceRef": {"Schema": "extension", "Entity": "_Formatting"}},
  "Property": "Bar Color"
}}}
```

`"Schema": "extension"` is required for report-level extension measures. Omit for model measures.

### Pattern — Bar / Column Fill

```json
"dataPoint": [
  {"properties": {}},
  {
    "properties": {
      "fill": {"solid": {"color": {"expr": {"Measure": {
        "Expression": {"SourceRef": {"Schema": "extension", "Entity": "_Formatting"}},
        "Property": "Bar Color"
      }}}}}
    },
    "selector": {"data": [{"dataViewWildcard": {"matchingOption": 1}}]}
  }
]
```

### Pattern — linearGradient2 (Two-Color)

Data-driven (scale to observed range):

```json
{"FillRule": {"linearGradient2": {
  "min": {"color": {"Literal": {"Value": "'minColor'"}}},
  "max": {"color": {"Literal": {"Value": "'maxColor'"}}},
  "nullColoringStrategy": {"strategy": {"Literal": {"Value": "'asZero'"}}}
}}}
```

Explicit bounds (fixed thresholds):

```json
{"FillRule": {"linearGradient2": {
  "min": {"color": {"Literal": {"Value": "'minColor'"}}, "value": {"Literal": {"Value": "0D"}}},
  "max": {"color": {"Literal": {"Value": "'maxColor'"}}, "value": {"Literal": {"Value": "1D"}}},
  "nullColoringStrategy": {"strategy": {"Literal": {"Value": "'asZero'"}}, "color": {"Literal": {"Value": "'#FFFFFF'"}}}
}}}
```

### Pattern — linearGradient3 (Diverging)

```json
{"FillRule": {"linearGradient3": {
  "min": {"color": {"Literal": {"Value": "'minColor'"}}, "value": {"Literal": {"Value": "-1D"}}},
  "mid": {"color": {"Literal": {"Value": "'neutral'"}}, "value": {"Literal": {"Value": "0D"}}},
  "max": {"color": {"Literal": {"Value": "'maxColor'"}}, "value": {"Literal": {"Value": "1D"}}},
  "nullColoringStrategy": {"strategy": {"Literal": {"Value": "'asZero'"}}}
}}}
```

### Pattern — Line Segment Colors (Single-Series Only)

Multi-series line charts cannot use segment coloring. Measure must return hex.

```json
"lineStyles": [
  {"properties": {"segmentGradient": {"expr": {"Literal": {"Value": "true"}}}}},
  {
    "properties": {
      "strokeColor": {"solid": {"color": {"expr": {"Measure": {
        "Expression": {"SourceRef": {"Schema": "extension", "Entity": "_Formatting"}},
        "Property": "Line Color"
      }}}}}
    },
    "selector": {"data": [{"dataViewWildcard": {"matchingOption": 1}}]}
  }
]
```

`segmentGradient` only affects `strokeColor`. It does NOT work with `lineStyle`, `strokeWidth`, or `markerFill`.

### Pattern — Axis Label Colors

No selector needed.

```json
"categoryAxis": [{
  "properties": {
    "labelColor": {"solid": {"color": {"expr": {"Measure": {
      "Expression": {"SourceRef": {"Schema": "extension", "Entity": "_Formatting"}},
      "Property": "Axis Color"
    }}}}}
  }
}]
```

### Pattern — Marker Transparency (0-100)

Marker color / shape / size do NOT support CF. Transparency does.

```json
"markers": [
  {"properties": {"borderShow": {"expr": {"Literal": {"Value": "false"}}}}},
  {
    "properties": {
      "transparency": {"expr": {"Measure": {
        "Expression": {"SourceRef": {"Schema": "extension", "Entity": "_Measures"}},
        "Property": "Marker Opacity"
      }}}
    },
    "selector": {"data": [{"dataViewWildcard": {"matchingOption": 1}}]}
  }
]
```

### Pattern — Rule-Based Conditional

```json
{"expr": {"Conditional": {"Cases": [
  {"Condition": {...}, "Value": {"Literal": {"Value": "'#FF0000'"}}},
  {"Condition": {...}, "Value": {"Literal": {"Value": "'#00FF00'"}}}
]}}}
```

Cases evaluated in order; first match wins.

### ComparisonKind Codes

| Value | Operator |
|---|---|
| `0` | Equal |
| `1` | Greater than |
| `2` | Greater than or equal |
| `3` | Less than or equal |
| `4` | Less than |

### Logical Wrappers

```json
{"And": {"Left": {...}, "Right": {...}}}
{"Or":  {"Left": {...}, "Right": {...}}}
{"Not": {"Expression": {...}}}
```

### ScopedEval + AllRolesRef (Global Context)

Removes filter context for global min/max:

```json
{"ScopedEval": {"Expression": {"Measure": {...}}, "Scope": [{"AllRolesRef": {}}]}}
```

### Data Bars (table/matrix columns)

```json
"dataBars": {
  "positiveColor": {"solid": {"color": {"expr": {"Literal": {"Value": "'#E1EBF2'"}}}}},
  "negativeColor": {"solid": {"color": {"expr": {"Literal": {"Value": "'#E5B97D'"}}}}},
  "axisColor":     {"solid": {"color": {"expr": {"Literal": {"Value": "'#FFFFFF'"}}}}},
  "reverseDirection": {"expr": {"Literal": {"Value": "false"}}},
  "hideText":         {"expr": {"Literal": {"Value": "false"}}}
}
```

### Conditional Icons

```json
"icon": {
  "kind": "Icon",
  "layout": {"expr": {"Literal": {"Value": "'IconOnly'"}}},
  "value": {"expr": {"Conditional": {"Cases": [
    {"Condition": {"Comparison": {"ComparisonKind": 4, "Left": {"Measure": {...}}, "Right": {"Literal": {"Value": "0D"}}}},
     "Value": {"Literal": {"Value": "'SymbolMedium'"}}}
  ]}}}
}
```

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| All points get same color | `metadata` selector used | Switch to `dataViewWildcard` with `matchingOption: 1` |
| CF works intermittently | Single-entry array with selector | Use two-entry array pattern |
| Measure rejected as color | `dataType` not `"Text"` in reportExtensions.json | Set `"dataType": "Text"` |
| Extension measure not found | Created new entity in reportExtensions.json | Entities must already exist in the semantic model |
| Line segment colors don't work | Chart has multiple series in Y/Y2 | Segment coloring requires a single series |
| Marker color CF ignored | Marker fill/shape/size don't support CF | Use `transparency` instead |
| `segmentGradient` + strokeWidth silently fails | Only `strokeColor` is supported | Don't combine |
| `reportExtensions.json` deserialization fails | Empty `entities: []` | Delete the file entirely when no extension measures exist |
| `title` / `legend` selector ignored | These objects don't accept selectors | Apply globally (no selector) |
| Gradient midpoint shifts unexpectedly | Data-driven bounds when fixed needed | Switch to explicit bounds form with `value` on min/mid/max |
| `AllRolesRef` scope wrong place | Nested incorrectly | `ScopedEval.Scope: [{"AllRolesRef": {}}]` at the outer wrapper |

### Reference

- Microsoft Learn: [Apply conditional table formatting in Power BI](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-table-formatting)
- Microsoft Learn: [Format by field value (color expression measures)](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-format-by-field#format-by-field-value)
- Microsoft Learn: [Tips and tricks for color formatting](https://learn.microsoft.com/power-bi/create-reports/service-tips-and-tricks-for-color-formatting)
- Comprehensive MS Learn link bundle (CF user concept / measure pattern / gradient scales / theme tokens / PBIR file format): [references/REFERENCE.md](references/REFERENCE.md)

### See also

- `pbir-visual-json` — selectors, expressions, literal suffixes
- `pbir-themes` — `ThemeDataColor` and theme token resolution
