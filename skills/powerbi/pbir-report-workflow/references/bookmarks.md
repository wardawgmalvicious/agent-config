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

> **`display.mode: "hidden"` does not hide a visual from Copilot.** In the Power
> BI **service**, Copilot Summary and the Copilot Narrative visual read visuals
> that are hidden by default and revealed by a **display-only** report bookmark
> — the `options.suppressData: true` shape below. Copilot reads them in place,
> so bookmark state is unchanged and RLS/OLS stay enforced. This is a
> *disclosure-surface* change rather than a permissions bypass: content an
> author may have assumed was excluded from generated narrative text is not.
>
> Two upstream qualifiers, both encodable here: the bookmark must be
> **display-only** (no data/filter state), and it must be **reachable via a
> bookmark button or navigator** — "bookmarks without a user-facing affordance
> are excluded", so an unwired bookmark is not read. Personal bookmarks and
> visuals on hidden pages are excluded too. Source:
> [Summarize a report with Copilot](https://learn.microsoft.com/power-bi/explore-reports/copilot-pane-summarize-content),
> drilled 2026-09-08.

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
- Comprehensive MS Learn link bundle (user concept / button wiring / PBIR file format / REST round-trip): § MS Learn link bundle, below

### MS Learn link bundle

Curated set of Microsoft Learn pages relevant to Power BI bookmarks — both the user-facing Desktop UX (which determines what the JSON shape encodes) and the PBIR project file structure that holds the persisted bookmark JSON.

The 3 highest-leverage entry points (bookmarks user concept, Power BI Project semantic-model/report folder layout, button → bookmark wiring) are also linked in § Reference above for in-context use; this section holds the comprehensive set.

**Note on docs split:** PBIR JSON internals (`bookmarks.json`, `<id>.bookmark.json`, `explorationState`, `byExpr` filter snapshot shape) are *not* documented in narrative form on MS Learn — the canonical machine-readable reference is the JSON schema published at `developer.microsoft.com/json-schemas/fabric/...`. The Power BI Desktop / Service user-facing pages document what the JSON encodes from the user perspective.

#### User-facing concept (what the JSON encodes)

- [Create report bookmarks in Power BI to share insights and build stories](https://learn.microsoft.com/power-bi/create-reports/desktop-bookmarks) — bookmarks pane, what's captured (filters, slicers, page state, visual visibility), bookmark groups, the show/hide UX. Maps to `explorationState` + per-visual `display.mode`.
- [Selection pane and visibility](https://learn.microsoft.com/power-bi/create-reports/desktop-bookmarks#visibility-using-the-selection-pane) — the user surface for the `display.mode: hidden|visible` mechanism the parent skill documents.
- [Bookmarks in the Power BI service](https://learn.microsoft.com/power-bi/explore-reports/end-user-bookmarks) — personal vs report bookmarks (only report bookmarks live as PBIR JSON).

#### Wiring bookmarks to buttons (the `visualLink` action)

- [Create and configure buttons in Power BI reports](https://learn.microsoft.com/power-bi/create-reports/desktop-buttons) — full button-action reference, including the `Bookmark` action that PBIR persists as `visualLink`.
- [Create page and bookmark navigators](https://learn.microsoft.com/power-bi/create-reports/button-navigators) — auto-generated bookmark navigator that creates a button per bookmark.
- [Identify and use buttons in the Power BI service](https://learn.microsoft.com/power-bi/explore-reports/end-user-buttons) — viewer-side behavior of the action.

#### PBIR file format (where bookmarks live)

- [Power BI Desktop project (PBIP) overview](https://learn.microsoft.com/power-bi/developer/projects/projects-overview) — top-level explanation of the PBIP folder.
- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `definition/bookmarks/` folder, file naming conventions, how Desktop generates 20-char hex IDs.
- [Report definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — the `definition/` part the bookmark folder belongs to. The schema URL pattern `developer.microsoft.com/json-schemas/fabric/item/report/...` is documented here.

#### Programmatic / REST

- [Report items REST API](https://learn.microsoft.com/rest/api/fabric/report/items) — the Fabric REST endpoints that round-trip the bookmark JSON via `getDefinition` / `updateDefinition`. See `fabric-rest-api` skill.

### See also

- [visual-json.md](visual-json.md) — visual `name` IDs targeted by bookmarks and button actions
- [filters.md](filters.md) — `byExpr` uses the same SQExpr / SourceRef.Source shape
- [themes.md](themes.md) — `objects.merge` overrides resolve against the theme baseline
