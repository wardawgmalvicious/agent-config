---
name: pbir-themes
description: Use when authoring or editing a Power BI report theme JSON under Report.Report/StaticResources/SharedResources/BaseThemes/ or RegisteredResources/. Covers top-level theme properties (name, dataColors palette, semantic colors background/foreground/tableAccent, sentiment good/bad/neutral/minimum/maximum/center, textClasses title/label/callout/header, visualStyles), inheritance (wildcard, per-visualType, per-instance visual.json), state keys (default, hover, press, selected), theme JSON value conventions — BARE numbers never D/L suffixes, BARE hex without inner quotes, unlike visual.json — ThemeDataColor with ColorId + Percent tint, container vs chart object properties, textClasses, outspacePane styling (colors, text, backgrounds, input colors, width), filterCard targeting Available/Applied/GUID, wildcard + override patterns, clearing stale overrides via pbir visuals clear-formatting --keep-cf -f. Invoke when user edits a theme file, tweaks CY24SU10, or fixes a theme-not-applied issue.
paths:
  - "**/StaticResources/**/*.json"
  - "**/BaseThemes/*.json"
  - "**/RegisteredResources/*.json"
---

## PBIR Theme Reference

Themes define default formatting inherited by all visuals. Review the theme BEFORE editing individual visuals.

### File Locations

| Theme | Path |
|---|---|
| Base (built-in) | `Report.Report/StaticResources/SharedResources/BaseThemes/<Name>.json` |
| Custom | `Report.Report/StaticResources/RegisteredResources/<Name>.json` |

Both referenced in `report.json`:

```json
"themeCollection": {
  "baseTheme": {"name": "CY24SU10", "type": "SharedResources"},
  "customTheme": {"name": "MyTheme.json", "type": "RegisteredResources"}
}
```

### Base Themes (April 2026)

Custom themes layer on top of a base theme. Three are shipped:

| Base theme | Status | Notes |
|---|---|---|
| `Fluent 2` | Preview (Desktop only) | Modern Fluent 2 styling. New pages default to **1920x1080** (initial page stays 1280x720). Adds chart / button / slicer / small-multiples style presets. Enable via Options › Preview features › "Modern visual defaults and customize theme improvements". |
| `Classic 2026` | Default for new reports | Incremental refresh of `CY24SU10`-era defaults. |
| `Classic 2018` | Legacy compatibility | Original base theme; reports created before 2026. |

Switch via View › Themes › Customize current theme › Base theme dropdown. The Customize-theme dialog also surfaces aspect-ratio page-size presets and table/matrix style enhancements when the preview is on.

The published theme JSON schema referenced by visualStyles tracks the latest base — current is `reportThemeSchema-2.149.json` (under `microsoft/powerbi-desktop-samples` on GitHub).

### Top-Level Theme Properties

| Property | Type | Notes |
|---|---|---|
| `name` | string | Theme name |
| `dataColors` | string[] | Palette hex strings, 0-indexed (referenced by `ColorId`) |
| `background` / `foreground` / `tableAccent` | string | Semantic colors |
| `good` / `bad` / `neutral` / `minimum` / `maximum` / `center` | string | Sentiment colors |
| `textClasses` | object | `title`, `label`, `callout`, `header` → `fontSize`, `fontFace`, `color` |
| `visualStyles` | object | `[visualType][state]` formatting overrides |

### Inheritance Hierarchy (broad → specific)

1. Wildcard `visualStyles["*"]["*"]` — all visuals
2. Visual type `visualStyles["lineChart"]["*"]` — overrides wildcard for that type
3. Visual instance — `objects` / `visualContainerObjects` in `visual.json` (see `pbir-visual-json` for the `objects` vs `visualContainerObjects` split in schema 2.4.0+)

### visualStyles Structure

Two-level keys: `[visualType][state]`. Second level is a **state**, not an instance selector.

| State | Meaning |
|---|---|
| `"*"` | Default (normal rendering) — most common |
| `"hover"` | Hover state |
| `"press"` | Press/click state |
| `"selected"` | Selected state |

```json
"visualStyles": {
  "slicer": {
    "*":     {"items": [{"fontColor": {"solid": {"color": "#000000"}}}]},
    "hover": {"items": [{"fontColor": {"solid": {"color": "#118DFF"}}}]}
  }
}
```

### Theme JSON Value Conventions

| Type | Theme JSON | visual.json |
|---|---|---|
| Integer | `14` | `{"expr": {"Literal": {"Value": "14L"}}}` |
| Float | `14.5` | `"14.5D"` |
| Boolean | `true` | `"true"` |
| Hex color | `"#e03131"` (bare) | `"'#e03131'"` (inner quotes) |
| ThemeDataColor | `{"solid": {"color": {"ThemeDataColor": {"ColorId": 0, "Percent": 0}}}}` | Same shape wrapped in `expr` |

**Never use `D` / `L` suffixes in theme JSON** — bare numbers only.

### ThemeDataColor

```json
{"solid": {"color": {"ThemeDataColor": {"ColorId": 5, "Percent": 0.4}}}}
```

| Property | Notes |
|---|---|
| `ColorId` | 0-based index into `dataColors[]` |
| `Percent` | `0` = exact, `0.1`..`1.0` = lighter, `-1.0`..`-0.1` = darker |

### Container Properties (visualContainerObjects)

Place under `visualStyles["*"]["*"]` or per visual type. Arrays of property objects.

| Object | Keys |
|---|---|
| `title` | `show`, `fontSize`, `fontFamily`, `fontColor`, `alignment` |
| `subTitle` | `show`, `fontSize`, `fontFamily`, `fontColor` |
| `background` | `show`, `color`, `transparency` |
| `border` | `show`, `width`, `color`, `radius` |
| `dropShadow` | `show`, `angle`, `distance`, `blur`, `color` |
| `padding` | `top`, `bottom`, `left`, `right` |
| `divider` | `show`, `color`, `style`, `width` |
| `visualHeader` | `show` |
| `visualTooltip` | `type`, `titleFontColor` |

### Visual Object Properties (objects)

Chart-specific formatting keys placed under `visualStyles["*"]["*"]` or per visual type: `categoryAxis`, `valueAxis`, `labels`, `legend`, `dataPoint`, `plotArea`, `lineStyles`, `markers`.

### textClasses

```json
"textClasses": {
  "title":   {"fontSize": 14, "fontFace": "Segoe UI Semibold"},
  "header":  {"fontSize": 12, "fontFace": "Segoe UI Semibold"},
  "label":   {"fontSize": 11, "fontFace": "Segoe UI"},
  "callout": {"fontSize": 45, "fontFace": "DIN"}
}
```

CY24SU10 defaults: `callout` 45 DIN, `title` 12 DIN, `header` 12 Segoe UI Semibold, `label` 10 Segoe UI. All `#252423`.

### Filter Pane Styling — outspacePane (owned here)

Location: `visualStyles["*"]["*"].outspacePane`. **Theme owns every styling property of the filter pane. Visibility / expansion state is separate — see `pbir-filters` for `report.json → objects.outspacePane`.**

| Property | Type | Notes |
|---|---|---|
| `backgroundColor` | color | `{"solid": {"color": ...}}` or ThemeDataColor |
| `transparency` | integer | 0-100 (bare) |
| `border` | boolean | Show vertical separator |
| `borderColor` | color | Separator color |
| `fontFamily` | string | Triple-quoted fallback chain |
| `foregroundColor` | color | Text, icons, buttons |
| `titleSize` | integer | Points |
| `headerSize` | integer | Points |
| `searchTextSize` | integer | Points |
| `inputBoxColor` | color | Input field background |
| `checkboxAndApplyColor` | color | Apply button, checkboxes |
| `width` | integer | Pixels |

### Filter Card Styling — filterCard

Location: `visualStyles["*"]["*"].filterCard` (array). Target specific card states via `$id`.

| `$id` | Targets |
|---|---|
| `"Available"` | Unapplied filters (filter pane list) |
| `"Applied"` | Actively applied filters |
| `"<GUID>"` | Specific filter by its `name` from filterConfig |

| Property | Type |
|---|---|
| `backgroundColor` | color |
| `transparency` | integer 0-100 |
| `border` | boolean |
| `borderColor` | color |
| `fontFamily` | string |
| `foregroundColor` | color |
| `textSize` | integer |
| `inputBoxColor` | color |

**Note**: `filterCard` without `$id` can also live at `visualStyles["page"]["*"].filterCard` as a base fallback.

### Wildcard + Override Pattern

```json
{
  "visualStyles": {
    "*": {
      "*": {
        "title": [{"show": true, "fontSize": 12}]
      }
    },
    "textbox": {
      "*": {
        "title":      [{"show": false}],
        "background": [{"show": false}],
        "border":     [{"show": false}],
        "dropShadow": [{"show": false}]
      }
    }
  }
}
```

### pbir CLI

```bash
pbir theme colors "Report.Report"                    # list palette
pbir theme set-formatting "Report.Report" ...        # set properties
pbir visuals clear-formatting "Report.Report/**/*.Visual" --keep-cf -f
```

Without CLI use `jq` with temp-file pattern:

```bash
THEME=$(jq -r '.themeCollection.customTheme.name' Report.Report/definition/report.json)
THEME="Report.Report/StaticResources/RegisteredResources/$THEME"
jq '.visualStyles["*"]["*"].title[0].fontSize = 14' "$THEME" > "$THEME.tmp" && mv "$THEME.tmp" "$THEME"
jq empty "$THEME"
```

### Clearing Visual-Level Overrides (Enforce Theme)

Stale `objects` / `visualContainerObjects` in visual.json override theme defaults.

- Clear container only (safe, preserves CF): `jq 'del(.visualContainerObjects)' visual.json`
- Clear all bespoke formatting (removes CF too): `jq 'del(.objects) | del(.visualContainerObjects)' visual.json`

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `D`/`L` suffix rejected in theme | Used visual.json literal shape | Theme JSON uses bare numbers |
| Hex color rendered as literal text | Inner single quotes `"'#fff'"` in theme | Theme uses bare `"#ffffff"` |
| `id` key ignored in filterCard | Used `"id"` | Theme uses `"$id"` |
| Filter pane styling causes deploy error | Styling placed in `report.json` outspacePane | Only `visible`/`expanded` allowed in report.json — move styling to theme |
| Theme changes invisible after apply | Stale `visualContainerObjects` in visuals | Run `pbir visuals clear-formatting --keep-cf -f` |
| `ColorId` out of range | Palette has fewer entries than referenced | Check `dataColors[]` length |
| Font fallback chain broken | Not triple-quoted | `"'Segoe UI Semibold', wf_segoe-ui_semibold, helvetica, arial, sans-serif"` |
| Inheritance not applying | Put properties at wrong state key | Default state is `"*"`, not `"default"` |
| Third-level `"*"` catch-all confusing | Real themes sometimes nest another `"*"` for generic props | Treat as fallback; normal paths still work |
| `textClasses` not inheriting | Used `fontSize` as string | Must be bare integer |

### Reference

- Microsoft Learn: [Use report themes in Power BI Desktop](https://learn.microsoft.com/power-bi/create-reports/desktop-report-themes)
- Microsoft Learn: [Create custom report themes (full JSON reference)](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom)
- Microsoft Learn: [Set formatted text defaults (textClasses table)](https://learn.microsoft.com/power-bi/create-reports/report-themes-create-custom#set-formatted-text-defaults)
- Microsoft Learn: [Visual defaults / base themes (Fluent 2 preview, Classic 2026, Classic 2018)](https://learn.microsoft.com/power-bi/create-reports/power-bi-reports-visual-defaults)
- Comprehensive MS Learn link bundle (theme JSON file format / textClasses / style presets / inheritance / filter pane styling): [references/REFERENCE.md](references/REFERENCE.md)

### See also

- `pbir-visual-json` — visual.json value conventions (`D`/`L`/`M` suffixes, inner-quoted hex)
- `pbir-filters` — filter pane visibility (`visible`, `expanded`) on `report.json`
- `pbir-conditional-formatting` — `ThemeDataColor` in CF expressions
- `pbir-cli` — `pbir theme` subcommands
