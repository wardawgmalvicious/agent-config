---
name: pbir-bookmarks
description: Use when creating, editing, or wiring Power BI PBIR bookmarks in Report.Report/definition/bookmarks/ — bookmarks.json index and individual bookmark.json files. Covers bookmark structure (name hex ID matching items[], displayName, options, explorationState), options flags (targetVisualNames, suppressDisplay, suppressActiveSection, suppressData, applyOnlyToTargetVisuals), explorationState shape (activeSection page ID, filters.byExpr, per-page sections.visualContainers.singleVisual, objects.merge for filter-pane state), per-visual display.mode hidden/visible as the ONLY correct visibility toggle (NOT root-level isHidden), byExpr entries with required expression + optional filter + howCreated (0=visual, 1=report), patterns (toggle, reset filters, guided navigation), wiring bookmarks to buttons via visualLink actions targeting the hex name. Invoke when user adds a bookmark, builds show/hide toggle buttons, or debugs 'bookmark applies but nothing changes'.
paths:
  - "**/bookmarks/bookmarks.json"
  - "**/bookmarks/*.bookmark.json"
---

## PBIR Bookmarks Reference

Bookmarks capture a snapshot of report state — active page, filter selections, visual visibility, and object overrides. Used for toggle interactivity via button `visualLink` actions.

### File Layout

```
Report.Report/definition/bookmarks/
  bookmarks.json                       # index + display order
  <hex_id>.bookmark.json               # one per bookmark
```

### bookmarks.json

```json
{
  "$schema": ".../bookmarksMetadata/1.0.0/schema.json",
  "items": [
    {"name": "958f29ad733c047ee0b8"},
    {"name": "54698b9cd0a0c57906b7"}
  ]
}
```

Order in `items[]` = order in the Bookmarks pane.

### [id].bookmark.json Top-Level

| Property | Type | Notes |
|---|---|---|
| `$schema` | string | `.../bookmark/1.4.0/schema.json` |
| `name` | string | 20-char hex; must match entry in `bookmarks.json` |
| `displayName` | string | Label shown in Bookmarks pane |
| `options` | object | Apply behavior flags |
| `explorationState` | object | The actual state snapshot |

### options

| Property | Type | Notes |
|---|---|---|
| `targetVisualNames` | string[] | Visuals affected by this bookmark (empty/omitted = all) |
| `suppressDisplay` | boolean | `true` = don't change visibility when applied; preserves current show/hide state |
| `suppressActiveSection` | boolean | Don't change the active page when applied |
| `suppressData` | boolean | Don't restore filter / slicer state |
| `applyOnlyToTargetVisuals` | boolean | Only touch visuals in `targetVisualNames` |

### explorationState

```json
"explorationState": {
  "version": "1.3",
  "activeSection": "<page_hex_id>",
  "filters": {"byExpr": [...]},
  "sections": {
    "<page_id>": {
      "visualContainers": {
        "<visual_id>": {
          "singleVisual": {
            "display": {"mode": "hidden"},
            "objects": {"merge": {...}},
            "activeProjections": {...}
          },
          "filters": {"byExpr": [...]}
        }
      }
    }
  },
  "objects": {"merge": {"outspacePane": [{"properties": {...}}]}}
}
```

| Path | Description |
|---|---|
| `version` | Bookmark schema version (e.g. `"1.3"`) |
| `activeSection` | Page ID active when bookmark applied |
| `filters.byExpr[]` | Report-level filter state snapshot |
| `sections.<page>` | Per-page overrides |
| `sections.<page>.visualContainers.<visual>` | Per-visual state |
| `objects.merge` | Report-level UI state (filter pane visible/expanded, etc.) |

### Per-Visual State (singleVisual)

| Path | Notes |
|---|---|
| `display.mode` | `"hidden"` or `"visible"` — show/hide mechanism |
| `objects.merge` | Merge these formatting properties over base visual.json |
| `activeProjections` | Active drill-down field selection |
| `filters.byExpr[]` | Visual-level filter snapshot |

Hiding / showing a visual via bookmark is driven by `display.mode`, NOT by changing the visual's root `isHidden`.

### byExpr Filter Entry

```json
{
  "name": "d3f20cea05c37b47123a",
  "type": "Categorical",
  "expression": {
    "Column": {
      "Expression": {"SourceRef": {"Entity": "Date"}},
      "Property": "Calendar Month (ie Jan)"
    }
  },
  "filter": {
    "Version": 2,
    "From": [{"Name": "e", "Entity": "Date", "Type": 0}],
    "Where": [{"Condition": {"In": {
      "Expressions": [{"Column": {"Expression": {"SourceRef": {"Source": "e"}}, "Property": "Calendar Month (ie Jan)"}}],
      "Values": [[{"Literal": {"Value": "'Jan'"}}]]
    }}}]
  },
  "howCreated": 1
}
```

| Field | Notes |
|---|---|
| `name` | Matches the `name` of the filter in `filterConfig` |
| `type` | Same types as filters: `Categorical`, `Advanced`, `TopN`, `RelativeDate`, etc. |
| `expression` | **Required** — the field the bookmark tracks |
| `filter` | **Optional** — omit when the field is tracked but has no active selection |
| `howCreated` | `0` = visual-level, `1` = report-level |

Same `SourceRef.Source` alias rule as regular filters: `Where` conditions reference the alias from `From[]`, not `Entity`.

### Common Patterns

| Pattern | How |
|---|---|
| Toggle visual visibility | Two bookmarks with opposite `singleVisual.display.mode` values; wire to buttons via `visualLink` actions |
| Reset all filters | Empty `byExpr[]` entries, or `filter.Where: []` per field |
| Guided navigation | Chain bookmarks, each setting `activeSection` + pre-set filters |
| Freeze visibility on filter-only bookmark | `options.suppressDisplay: true` |
| Freeze filter state on visibility-only bookmark | `options.suppressData: true` |
| Scope to subset of visuals | `options.targetVisualNames` + `applyOnlyToTargetVisuals: true` |

### objects.merge Example

Override title text on a single visual in a bookmark:

```json
"singleVisual": {
  "display": {"mode": "visible"},
  "objects": {"merge": {
    "title": [{"properties": {
      "text": {"expr": {"Literal": {"Value": "'Quarterly View'"}}}
    }}]
  }}
}
```

Report-level — collapse the filter pane when applied:

```json
"objects": {"merge": {
  "outspacePane": [{"properties": {
    "expanded": {"expr": {"Literal": {"Value": "false"}}}
  }}]
}}
```

### Wiring to a Button

Buttons apply a bookmark via a `visualLink` action type on the button's `onClick` in its visual.json. The action payload references the bookmark's `name` (the hex ID).

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| Bookmark not listed in pane | Missing entry in `bookmarks.json.items[]` | Add `{"name": "<hex>"}` — order here controls pane order |
| Bookmark applies but nothing changes | `suppressDisplay` and `suppressData` both true | Loosen the flags |
| Visibility toggle has no effect | Used root-level `isHidden` instead of `singleVisual.display.mode` | Use `display.mode: "hidden"` / `"visible"` in `explorationState` |
| Bookmark filter ignored | Missing `expression` on byExpr entry | `expression` is required even when `filter` is omitted |
| Filter state jitters on toggle | Inconsistent field set between bookmarks | Include the same `byExpr` entries in every bookmark that participates in the toggle |
| Wrong page opens | `activeSection` out of sync with page rename | Update `activeSection` to the new page hex ID |
| SourceRef used Entity in Where | Same gotcha as filters | Use `{"Source": "<alias>"}` |
| Button doesn't fire bookmark | Wrong bookmark name in action payload | Must match hex `name`, not `displayName` |
| Partial visual update | `targetVisualNames` includes wrong IDs | Verify visual `name` values — these are the root-level IDs, not displayNames |
| `howCreated` wrong scope | `0` vs `1` mixed up | `0` = visual-level filter, `1` = report-level filter |

### Reference

- Microsoft Learn: [Create report bookmarks in Power BI](https://learn.microsoft.com/power-bi/create-reports/desktop-bookmarks)
- Microsoft Learn: [Power BI Desktop project — report folder layout](https://learn.microsoft.com/power-bi/developer/projects/projects-report)
- Microsoft Learn: [Create and configure buttons (Bookmark action)](https://learn.microsoft.com/power-bi/create-reports/desktop-buttons)
- Comprehensive MS Learn link bundle (user concept / button wiring / PBIR file format / REST round-trip): [references/REFERENCE.md](references/REFERENCE.md)

### See also

- `pbir-visual-json` — visual `name` IDs targeted by bookmarks and button actions
- `pbir-filters` — `byExpr` uses the same SQExpr / SourceRef.Source shape
