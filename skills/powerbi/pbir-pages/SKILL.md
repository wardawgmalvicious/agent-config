---
name: pbir-pages
description: Use when authoring or editing page.json / pages.json inside a Power BI PBIR report's definition/pages/ folder. Covers top-level page properties (name hex GUID vs displayName, displayOption as STRING not integer, width/height, type Default vs Tooltip, visibility AlwaysVisible vs HiddenInViewMode, verticalAlignment/horizontalAlignment), pages.json pageOrder + activePageName, canvas background vs outspace wallpaper distinction, visualInteractions NoFilter/Filter/Highlight overrides, page-level filterConfig, tooltip pages (section references the NAME guid not displayName), drillthrough pages with Column-typed filter, page folder renaming rules (folder freely renamable; page.json filename and internal name stay fixed), literal value encoding (D/L suffixes). Invoke when user edits a page, adds a tooltip or drillthrough page, configures cross-visual interactions, or changes page background.
paths:
  - "**/pages/**/page.json"
  - "**/pages/pages.json"
---

## PBIR Page JSON Reference

Page-level JSON for reports in PBIR format. Each page lives in `definition/pages/<PageName>/page.json`. Page order and the active page are tracked in `definition/pages/pages.json`.

Schema: `https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/2.0.0/schema.json`

### Top-Level Properties

| Property | Type | Notes |
|---|---|---|
| `name` | string | Page GUID identifier. Referenced from `pages.json` and `visualTooltip.section`. Do NOT change after creation |
| `displayName` | string | User-visible name shown in page tab |
| `displayOption` | string | `"FitToPage"`, `"FitToWidth"`, or `"ActualSize"` — MUST be string, NOT integer |
| `width` | number | Page width in pixels |
| `height` | number | Page height in pixels |
| `type` | string | `"Default"` or `"Tooltip"` |
| `visibility` | string | `"AlwaysVisible"` or `"HiddenInViewMode"` |
| `verticalAlignment` | string | `"Top"`, `"Middle"` (default), `"Bottom"` |
| `horizontalAlignment` | string | `"Left"`, `"Center"` (default), `"Right"` |
| `filterConfig` | object | Page-level filters (also used for drillthrough binding) |
| `visualInteractions` | array | Cross-visual interaction overrides |
| `pageBinding` | object | Q&A parameter bindings |
| `objects` | object | Page-level formatting (background, outspace, displayArea, etc.) |

### Minimal Page

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/page/2.0.0/schema.json",
  "name": "77e770be04c64c0c6938",
  "displayName": "Overview",
  "displayOption": "FitToPage",
  "width": 1280,
  "height": 720
}
```

### Common Page Sizes

| Type | Width x Height |
|---|---|
| Default 16:9 (Classic 2018 / Classic 2026 base theme) | 1280 x 720 |
| Default 16:9 (Fluent 2 base theme, new pages) | 1920 x 1080 |
| Large 16:9 | 1920 x 1080 |
| Letter portrait | 816 x 1056 |
| Tooltip | 320 x 240 |

The Fluent 2 (preview) base theme bumps new-page default to 1920x1080. Initial page in a report stays 1280x720; existing pages don't auto-resize when switching base themes. Customize-theme dialog also surfaces aspect-ratio presets for common page sizes. See `pbir-themes` for base-theme switching.

### pages.json

Page order and active page:

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/pagesMetadata/1.0.0/schema.json",
  "pageOrder": ["77e770be04c64c0c6938", "da2e63ebeb2179a994f1"],
  "activePageName": "77e770be04c64c0c6938"
}
```

### Canvas Alignment

`verticalAlignment` and `horizontalAlignment` control canvas position when the viewport differs from the canvas size. Most relevant with `displayOption: "ActualSize"`.

### Background (Canvas)

The canvas is the area where visuals sit. It is NOT the wallpaper behind it (that is `outspace`).

**Visual hierarchy (bottom to top):** `outspace` (wallpaper) -> `background` (canvas) -> visuals.

```json
"objects": {
  "background": [{
    "properties": {
      "color":        { "solid": { "color": { "expr": { "Literal": { "Value": "'#FFFFFF'" } } } } },
      "transparency": { "expr": { "Literal": { "Value": "0D" } } }
    }
  }]
}
```

Transparency values: `"0D"` opaque, `"50D"` semi, `"100D"` fully transparent (shows wallpaper).

### Wallpaper (outspace)

The area behind and around the canvas.

```json
"objects": {
  "outspace": [{
    "properties": {
      "color": { "solid": { "color": { "expr": { "Literal": { "Value": "'#2B579A'" } } } } }
    }
  }]
}
```

### outspacePane (Filter Pane) — NOT on page.json

`outspacePane` is **report-level**, never page-level. Do not place it in `page.json`. Responsibility is split:

- **Visibility and expansion state** (`visible`, `expanded`) live in `report.json → objects.outspacePane` — see `pbir-filters`.
- **Styling** (colors, text, backgrounds, input colors, width) lives in the custom theme at `visualStyles["*"]["*"].outspacePane` — see `pbir-themes`.

### Visual Interactions

Override default cross-filtering between visuals on a page. Set on `page.json`:

```json
"visualInteractions": [
  { "source": "slicer_region", "target": "chart_trend", "type": "NoFilter" }
]
```

| `type` | Effect |
|---|---|
| `"NoFilter"` | Disable cross-filter from source to target |
| `"Filter"` | Filter target when source selected |
| `"Highlight"` | Highlight selection (default for charts) |

`source` and `target` are the `name` values from each visual's `visual.json`.

### Page-Level Filters

```json
"filterConfig": {
  "filters": [{
    "name": "filter-guid",
    "field": {
      "Column": {
        "Expression": { "SourceRef": { "Entity": "Products" } },
        "Property":   "Category"
      }
    },
    "type": "Categorical",
    "howCreated": "User"
  }]
}
```

Same structure as report-level filters in `report.json`. Slicer visuals are NOT filters — they are regular visuals bound to categorical data.

### Tooltip Pages

Small hidden pages shown as rich tooltips when a visual is hovered.

**Setup on page.json:**

```json
{
  "name": "tooltip_revenue_id",
  "displayName": "RevenueTooltip",
  "displayOption": "ActualSize",
  "width": 320,
  "height": 240,
  "type": "Tooltip",
  "visibility": "HiddenInViewMode"
}
```

- `type: "Tooltip"` — marks the page
- `visibility: "HiddenInViewMode"` — hides from page tabs
- `displayOption: "ActualSize"` — tooltip pages don't scale
- Common sizes: `320x240` (default), `400x120` (wide/compact)

**Opt-in from a visual** (in the visual's `visualContainerObjects`):

```json
"visualContainerObjects": {
  "visualTooltip": [{
    "properties": {
      "show":    { "expr": { "Literal": { "Value": "true" } } },
      "type":    { "expr": { "Literal": { "Value": "'ReportPage'" } } },
      "section": { "expr": { "Literal": { "Value": "'tooltip_revenue_id'" } } }
    }
  }]
}
```

- `type` values: `"'ReportPage'"` (use tooltip page), `"'Default'"` (auto default tooltip)
- `section` — the `name` GUID from the tooltip page's `page.json`, NOT its `displayName`
- Disable tooltips per visual: `"show"` set to `"false"`

`visualHeaderTooltip` styles the tooltip over header icons (separate from the hover tooltip) — same pattern, slightly different properties.

### Drillthrough Pages

A regular page (`type: "Default"`) with a drillthrough filter in `filterConfig`. Users right-click a value on another page and navigate in with the filter applied.

```json
{
  "name": "drillthrough_customer_id",
  "displayName": "CustomerDetails",
  "displayOption": "FitToPage",
  "width": 1920,
  "height": 1080,
  "filterConfig": {
    "filters": [{
      "name": "drillthrough_filter_id",
      "field": {
        "Column": {
          "Expression": { "SourceRef": { "Entity": "Customers" } },
          "Property":   "Customer Name"
        }
      },
      "type": "Categorical",
      "howCreated": "User"
    }]
  }
}
```

- Any field can be a drillthrough target. Hidden the page from tabs via `visibility: "HiddenInViewMode"` if it is drillthrough-only
- Add a back-button visual (`actionButton`) so users can return

### Page Formatting Objects

| Object | Purpose |
|---|---|
| `background` | Canvas background (color, transparency, image) |
| `outspace` | Wallpaper behind the canvas |
| `outspacePane` | Filter pane state — **set on `report.json` only** (see cross-ref above) |
| `displayArea` | Format the display area |
| `filterCard` | Individual filter card styling within filter pane |
| `pageInformation` | Page metadata for export |
| `pageRefresh` | Page-level automatic refresh |
| `pageSize` | Page size overrides |
| `personalizeVisual` | Personalization settings |

### Page Folder Naming

- PBI Desktop generates folder names as 20-char hex (e.g. `0c32c81bce347402001e/`)
- Rename freely to PascalCase (e.g. `Overview/`) for better diffs and readability
- Desktop-generated folders may contain spaces — prefer letters, digits, underscores, hyphens in human-authored names
- `page.json` filename and the internal `name` property MUST remain unchanged

### Literal Value Encoding

All formatting property values are wrapped in expression literals:

| Type | Encoding |
|---|---|
| String | Single quotes inside double quotes: `"'#FF0000'"` |
| Number | Integer/decimal with `D` suffix: `"0D"`, `"50D"`, `"12D"` |
| Boolean | `"true"` or `"false"` |

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `displayOption: 1` rejected | Must be a string | Use `"FitToPage"` / `"FitToWidth"` / `"ActualSize"` |
| Tooltip page not appearing on hover | `section` used displayName not `name` GUID | Use the `name` value from tooltip page's `page.json` |
| Background color not applying | Missing `"D"` suffix on transparency | `"0D"` not `"0"` |
| Wallpaper change affects canvas instead | Used `background` object | Wallpaper is `outspace`, canvas is `background` |
| Filter pane settings ignored on page | `outspacePane` placed on page.json | Move visibility/expanded to `report.json`; move styling to theme |
| Drillthrough not offered on right-click | Page missing filter in `filterConfig` | Add `Column`-typed filter with drillthrough field |
| Page renamed but visual tooltips broken | Folder renamed AND `name` property changed | Only rename the folder — keep `name` GUID |
| Visual interactions don't match | `source`/`target` used `displayName` | Use visual `name` (file-internal ID) |
| Tooltip page appears in page tabs | Missing `visibility: "HiddenInViewMode"` | Add visibility property |
| Canvas background image not showing | Image not registered in resources | Register via `StaticResources/RegisteredResources/` |

### Reference

- Microsoft Learn: [Customize page sizes and dimensions in Power BI](https://learn.microsoft.com/power-bi/create-reports/power-bi-report-page-size)
- Microsoft Learn: [Create tooltips based on report pages](https://learn.microsoft.com/power-bi/create-reports/desktop-tooltips)
- Microsoft Learn: [Use drillthrough in Power BI reports](https://learn.microsoft.com/power-bi/create-reports/desktop-drillthrough)
- Comprehensive MS Learn link bundle (page sizes / canvas vs wallpaper / tooltip / drillthrough / visual interactions / PBIR file format): [references/REFERENCE.md](references/REFERENCE.md)

### See also

- `pbip-project-structure` — project file layout
- `pbir-cli` — `pbir pages` / `pbir visuals` commands
- `pbir-report-workflow` — layout math and workflow
- `pbir-filters` — outspacePane visibility/expansion on report.json
- `pbir-themes` — outspacePane theme styling
