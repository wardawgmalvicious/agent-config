---
name: pbir-filters
description: Use when authoring filter bodies in a Power BI PBIR report at report.json, page.json, or visual.json filterConfig.filters. Covers scopes (Report, Page, Visual — visual filter is sibling of `visual` NOT nested), filter types (Categorical, Advanced, TopN, VisualTopN, RelativeDate, RelativeTime, Tuple), filter body shape (Version 2, From[] aliases, Where[] using SourceRef.Source NEVER Entity), Categorical In / inverted Not-In with isInvertedSelectionMode, empty-default forms, Advanced Comparison with ComparisonKind 0-4, Between inclusive ranges, RelativeDate DateSpan/DateAdd with TimeUnit codes, TopN VisualTopN, And/Or/Not, doubled single quotes for strings, integer L / double D / datetime literal suffixes, hide/lock/single-select, filter-pane visible+expanded at report level (styling lives in theme). Invoke when user adds a filter, fixes a silently-ignored filter, builds a rolling-date window, or toggles filter-pane visibility.
paths:
  - "**/report.json"
  - "**/pages/**/page.json"
  - "**/visuals/**/visual.json"
---

## PBIR Filters Reference

### Filter Scopes

| Scope | Location | Applies To |
|---|---|---|
| Report | `report.json` → `filterConfig.filters[]` | All pages and visuals |
| Page | `page.json` → `filterConfig.filters[]` | All visuals on the page |
| Visual | `visual.json` → `filterConfig.filters[]` | That visual only (sibling of `visual`, not nested) |

### Filter Types

| `type` | Description | Use Case |
|---|---|---|
| `Categorical` | In / NotIn list | Year, category, brand (most common) |
| `Advanced` | Comparison on measures or columns | Measure > threshold, ranges |
| `TopN` | Top/bottom N by measure | Top 10 customers |
| `VisualTopN` | Visual-level TopN | Auto-applied by some visuals |
| `RelativeDate` | Rolling date window | Last N days/months/years |
| `RelativeTime` | Rolling time window | Last N hours/minutes |
| `Tuple` | Multi-column composite | Rare |

### Filter Object Properties

| Property | Type | Notes |
|---|---|---|
| `name` | string | 20-char hex unique ID |
| `displayName` | string | Optional pane label |
| `field` | object | Column or Measure reference (query projection syntax) |
| `type` | string | See table above |
| `filter` | object | Where clause — optional when no defaults |
| `isHiddenInViewMode` | boolean | Hide from pane in reading view |
| `isLockedInViewMode` | boolean | Visible but not editable |
| `howCreated` | string | `"User"` for user-created |
| `ordinal` | integer | Display order (optional) |
| `objects` | object | `requireSingleSelect`, `isInvertedSelectionMode` |

### filter Body Shape

```json
"filter": {
  "Version": 2,
  "From": [{"Name": "e", "Entity": "Exchange Rate", "Type": 0}],
  "Where": [{"Condition": {...}}]
}
```

**Where clause rules**:
- `From[]` defines aliases
- Conditions reference alias via `"SourceRef": {"Source": "e"}` — NOT `Entity`
- String values: inner single quotes, doubled for escape: `"'O''Brien'"`
- Integer values: `L` suffix (`"2022L"`); datetimes: `"datetime'2024-01-01T00:00:00.0000000'"`
- Each value is wrapped in its own array: `[[{val1}], [{val2}]]`

### Categorical — In (Multi-Select Default)

```json
{
  "name": "d3f20cea05c37b47123a",
  "field": {"Column": {"Expression": {"SourceRef": {"Entity": "Exchange Rate"}}, "Property": "From Currency"}},
  "type": "Categorical",
  "filter": {
    "Version": 2,
    "From": [{"Name": "e", "Entity": "Exchange Rate", "Type": 0}],
    "Where": [{"Condition": {"In": {
      "Expressions": [{"Column": {"Expression": {"SourceRef": {"Source": "e"}}, "Property": "From Currency"}}],
      "Values": [
        [{"Literal": {"Value": "'EUR'"}}],
        [{"Literal": {"Value": "'USD'"}}]
      ]
    }}}]
  }
}
```

### Categorical — Inverted (Not In)

Wrap `In` with `Not` AND set `isInvertedSelectionMode: true`.

```json
"Where": [{"Condition": {"Not": {"Expression": {"In": {
  "Expressions": [{"Column": {"Expression": {"SourceRef": {"Source": "b"}}, "Property": "Brand"}}],
  "Values": [[{"Literal": {"Value": "'ASAN'"}}]]
}}}}}],
```

```json
"objects": {"general": [{"properties": {
  "isInvertedSelectionMode": {"expr": {"Literal": {"Value": "true"}}}
}}]}
```

### No Default (Empty Filter)

Omit `filter` entirely, OR include with empty `Where`:

```json
"filter": {"Version": 2, "From": [{"Name": "d", "Entity": "Date", "Type": 0}], "Where": []}
```

### Advanced — Comparison

```json
{
  "name": "1c9a23490ebe5441b781",
  "field": {"Measure": {"Expression": {"SourceRef": {"Entity": "Budget"}}, "Property": "Budget vs. Turnover (%)"}},
  "type": "Advanced",
  "filter": {
    "Version": 2,
    "From": [{"Name": "d", "Entity": "Budget", "Type": 0}],
    "Where": [{"Condition": {"Comparison": {
      "ComparisonKind": 1,
      "Left": {"Measure": {"Expression": {"SourceRef": {"Source": "d"}}, "Property": "Budget vs. Turnover (%)"}},
      "Right": {"Literal": {"Value": "0D"}}
    }}}]
  }
}
```

### ComparisonKind Codes

`0`=Equal, `1`=GreaterThan, `2`=GreaterThanOrEqual, `3`=LessThanOrEqual, `4`=LessThan.

### Between (Range, Inclusive)

```json
"Where": [{"Condition": {"Between": {
  "Expression": {"Column": {"Expression": {"SourceRef": {"Source": "d"}}, "Property": "Date"}},
  "LowerBound": {"Literal": {"Value": "datetime'2024-01-01T00:00:00.0000000'"}},
  "UpperBound": {"Literal": {"Value": "datetime'2024-12-31T00:00:00.0000000'"}}
}}}]
```

### RelativeDate — DateSpan / DateAdd

TimeUnit codes: `0`=Day, `1`=Week, `2`=Month, `3`=Year, `4`=Decade, `5`=Second, `6`=Minute, `7`=Hour.

Current period start:

```json
"Right": {"DateSpan": {"Expression": {"Now": {}}, "TimeUnit": 2}}
```

3 months ago from start of current month:

```json
"Right": {"DateAdd": {
  "Expression": {"DateSpan": {"Expression": {"Now": {}}, "TimeUnit": 2}},
  "TimeUnit": 2,
  "Amount": -3
}}
```

`RelativeTime` uses the same shape with TimeUnit `5`/`6`/`7`.

### TopN

```json
"type": "TopN",
"filter": {
  "Version": 2,
  "From": [{"Name": "c", "Entity": "Customers", "Type": 0}],
  "Where": [{"Condition": {"VisualTopN": {
    "Expression": {"Column": {"Expression": {"SourceRef": {"Source": "c"}}, "Property": "Customer Name"}},
    "Count": {"Literal": {"Value": "10L"}},
    "OrderBy": {"Measure": {"Expression": {"SourceRef": {"Entity": "Sales"}}, "Property": "Revenue"}},
    "IsAscending": false
  }}}]
}
```

`IsAscending: false` = Top N. `true` = Bottom N.

### Compound — And / Or

```json
"Condition": {"And": {
  "Left":  {"Comparison": {"ComparisonKind": 2, "Left": {...}, "Right": {...}}},
  "Right": {"Comparison": {"ComparisonKind": 3, "Left": {...}, "Right": {...}}}
}}
```

### Condition Reference

| Condition | Description |
|---|---|
| `In` | Value in list |
| `Not` → `In` | Value NOT in list |
| `Comparison` | Single comparison |
| `Between` | Inclusive range |
| `And` / `Or` | Compound |
| `Not` | Negation wrapper |
| `Contains` | String contains |
| `StartsWith` | String prefix |
| `DateSpan` | Relative period |
| `DateAdd` | Offset date expression |
| `VisualTopN` | Top/bottom N |
| `Now` | Current datetime — inside DateSpan/DateAdd |

### Contains / StartsWith — Minimal Shape

```json
"Where": [{"Condition": {"Contains": {
  "Left":  {"Column": {"Expression": {"SourceRef": {"Source": "c"}}, "Property": "Customer Name"}},
  "Right": {"Literal": {"Value": "'Acme'"}}
}}}]
```

`StartsWith` uses the same shape — swap `Contains` for `StartsWith`.

### Hide / Lock / Single-Select

| Option | Effect |
|---|---|
| `isHiddenInViewMode: true` | Hidden from filter pane in reading view |
| `isLockedInViewMode: true` | Visible but not editable |
| `objects.general.properties.requireSingleSelect` | Force exactly one value |

Common combinations:

| Use Case | Hidden | Locked | SingleSelect |
|---|---|---|---|
| Hidden background filter | true | true | – |
| Locked parameter | false | true | true |
| Normal multi-select | false | false | false |
| Visible single-select | false | false | true |

Never hide visual-level filters — confuses users. Only hide report/page filters with justification.

### Filter Pane Visibility — outspacePane on report.json (owned here)

Only `visible` and `expanded` live at `report.json → objects.outspacePane`. **All styling (colors, text, backgrounds, input box, width) belongs in the theme — see `pbir-themes`.**

```json
"objects": {"outspacePane": [{"properties": {
  "visible":  {"expr": {"Literal": {"Value": "true"}}},
  "expanded": {"expr": {"Literal": {"Value": "false"}}}
}}]}
```

### Discovering Filter Values

```bash
pbir model "Report.Report" -d                                                   # dump model
pbir model "Report.Report" -d -t Date                                           # single table
pbir model "Report.Report" -q "EVALUATE DISTINCT('Date'[Calendar Year (ie 2021)])"
```

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| Filter silently ignored | `SourceRef.Entity` in `Where` instead of `SourceRef.Source` | Reference alias defined in `From[]` |
| Filter values not selected | Values not double-wrapped | Each value is its own array: `[[{v1}], [{v2}]]` |
| Deploy error on report filter pane styling | Styling in `report.json` outspacePane | Move to theme `visualStyles["*"]["*"].outspacePane` |
| Inverted filter still shows selected values | Missing `isInvertedSelectionMode: true` | Set it alongside the `Not`→`In` Where |
| `RelativeDate` rolling window off by one | Missing `DateAdd` offset | Wrap `DateSpan` in `DateAdd` with negative `Amount` |
| String literal with apostrophe fails | Unescaped single quote | Double it: `"'O''Brien'"` |
| Integer filter value rejected | Used `D` suffix | Integers use `L` |
| DateTime filter rejected | Missing trailing `'` | `"datetime'YYYY-MM-DDTHH:MM:SS.0000000'"` |
| `filterConfig` in wrong place on visual | Nested inside `visual` | Sibling of `visual` at root of visual.json |
| Empty-filter default values appear | Previous `Where` clause present | Use `"Where": []` or omit `filter` entirely |
| Visual filter hidden causes UX confusion | `isHiddenInViewMode` on visual scope | Don't hide visual-level filters |

### Reference

- Microsoft Learn: [Format filters in Power BI reports (filter pane)](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-filter)
- Microsoft Learn: [Filter types overview](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-filter-types)
- Microsoft Learn: [Slicers in Power BI](https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-slicers)
- Comprehensive MS Learn link bundle (filter scopes / types / pane visibility / drillthrough / theme styling / PBIR file format): [references/REFERENCE.md](references/REFERENCE.md)

### See also

- `pbir-visual-json` — visual.json `filterConfig` placement (sibling of `visual`)
- `pbir-themes` — filter pane and filter card styling
- `pbir-bookmarks` — `byExpr` filter snapshots (same SQExpr shape)
