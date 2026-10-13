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

#### Custom icon from a URL

The block above is the **Rules** format style, driving a built-in icon set. The
other style, **Field value**, points at a column of image URLs and renders those
instead of a built-in icon — the way to get an arbitrary custom icon into a
table or matrix cell.

- The URL may be an **anonymously accessible web URL**, or a **OneLake file
  URL**: `https://onelake.dfs.fabric.microsoft.com/{workspace-id}/{item-id}/Files/{path-to-image}`
- Icons must be **BMP, JPG, JPEG, GIF, PNG or SVG**.
- Desktop path: field dropdown → **Conditional formatting** → **Icons** →
  **Format style** = **Field value**. *Icon layout* still controls left / right
  of the value or icon-only.

Two limits ride along when the URL is a OneLake one — Power BI loads it under
each viewer's Entra identity, so:

- Viewers need **Read** on the lakehouse item *and* OneLake **Read** on the
  folder holding the image. Access to the report does not grant it.
- **Publish to web and anonymous embed cannot use OneLake URLs at all** — they
  have no identity to authenticate with. Use an anonymously accessible web URL
  for reports headed there. See
  [Use OneLake image and map files in Power BI reports](https://learn.microsoft.com/power-bi/visuals/power-bi-onelake-files)
  for the full OneLake image-source model.

> The `visual.json` encoding for the **Field value** icon source is deliberately
> **not** given here — it was not observed against a real PBIP export, and this
> skill's property paths are only worth having when they are verified. No schema
> settles it either: on 2026-10-12 `pbir schema describe` typed `values.icon`
> only as an object, and theme schema 2.157 added nothing for it. The block above
> is the Rules style and does not carry over unchanged.

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
| URL-sourced custom icons vanish in Publish to web | The column holds OneLake URLs, which cannot authenticate anonymously | Use anonymously accessible web URLs for any report published to web or anonymously embedded |

### Reference

- Microsoft Learn: [Apply conditional table formatting in Power BI](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-table-formatting)
- Microsoft Learn: [Format by field value (color expression measures)](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-format-by-field#format-by-field-value)
- Microsoft Learn: [Tips and tricks for color formatting](https://learn.microsoft.com/power-bi/create-reports/service-tips-and-tricks-for-color-formatting)
- Comprehensive MS Learn link bundle (CF user concept / measure pattern / gradient scales / theme tokens / PBIR file format): § MS Learn link bundle, below

### MS Learn link bundle

Curated set of Microsoft Learn pages relevant to conditional formatting in Power BI — Desktop UX, the field-value / rule / gradient mechanisms, the data-bar/icon overlays, and how the Desktop choices serialize into PBIR `visual.json` (per-point `dataPoint` two-entry array, `FillRule.linearGradient2/3`, extension-measure `Schema: extension`, `dataViewWildcard.matchingOption`).

The 3 highest-leverage entry points (CF in tables/matrices, CF for fill colors via measure, FillRule color scales) are also linked in § Reference above for in-context use; this section holds the comprehensive set.

**Note on docs split:** The PBIR JSON shape (`dataPoint` two-entry array, `dataViewWildcard`, `linearGradient2/3`, extension-measure expression) is *not* documented narratively on MS Learn — the canonical machine-readable reference is the `developer.microsoft.com/json-schemas/fabric/...` schema family. The Power BI Desktop / Service pages document what user choices the JSON encodes.

#### Conditional formatting — user concept

- [Apply conditional table formatting in Power BI](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-table-formatting) — full reference for table/matrix CF: backgrounds, font color, data bars, icons (built-in sets *and* custom icons from a web or OneLake URL), web URLs. The Desktop UX corresponds to the `dataBars` / `icon` blocks the parent skill documents.
- [Conditional formatting for chart visuals](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-format-visual-titles) — color-by-rule / color-by-field / gradient color scales for chart elements. Maps to the `dataPoint` two-entry-array + `dataViewWildcard.matchingOption: 1` pattern.
- [Tips and tricks for color formatting in Power BI](https://learn.microsoft.com/power-bi/create-reports/service-tips-and-tricks-for-color-formatting) — color expressions, theme-driven colors, dynamic colors via measures.

#### Color expression measures (the `Text` extension measure pattern)

- [Use measures returning hex codes for conditional formatting](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-format-by-field#format-by-field-value) — the canonical "measure returns `'good'`/`'bad'`/`'#FF0000'`" pattern. Confirms `Text` data-type requirement that the parent skill calls out. Theme tokens `good`/`bad`/`neutral`/`minColor`/`midColor`/`maxColor` resolve to dataColors / sentiment colors from the report theme.
- [DAX SWITCH function](https://learn.microsoft.com/dax/switch-function-dax) — typical building block for the color-bucket extension measure.

#### Color scales / gradients (FillRule)

- [Apply color formatting based on field value (gradient)](https://learn.microsoft.com/power-bi/create-reports/desktop-conditional-table-formatting#color-by-color-scale) — UI surface for two-color (linearGradient2) and three-color (linearGradient3) scales.

#### Theme tokens used by `'good'`/`'bad'`/`'neutral'`

- [Create custom report themes — sentiment colors](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom#sentiment-colors) — `good` / `bad` / `neutral` / `minimum` / `maximum` / `center` semantic-color slots; what the strings the Text-typed extension measure returns resolve to.
- See [themes.md](themes.md) for full theme structure.

#### PBIR file format (where CF lives)

- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `visual.json` and `reportExtensions.json` locations the parent skill modifies.
- [Report definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — CF lives inside the `definition/` part.

### See also

- [visual-json.md](visual-json.md) — selectors, expressions, literal suffixes
- [themes.md](themes.md) — `ThemeDataColor` and theme token resolution
- [filters.md](filters.md) — same SQExpr `Comparison` / `ComparisonKind` codes used by `Conditional.Cases`
