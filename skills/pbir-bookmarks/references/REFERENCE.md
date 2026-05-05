# MS Learn link bundle — PBIR Bookmarks

Curated set of Microsoft Learn pages relevant to Power BI bookmarks — both the user-facing Desktop UX (which determines what the JSON shape encodes) and the PBIR project file structure that holds the persisted bookmark JSON.

The 3 highest-leverage entry points (bookmarks user concept, Power BI Project semantic-model/report folder layout, button → bookmark wiring) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** PBIR JSON internals (`bookmarks.json`, `<id>.bookmark.json`, `explorationState`, `byExpr` filter snapshot shape) are *not* documented in narrative form on MS Learn — the canonical machine-readable reference is the JSON schema published at `developer.microsoft.com/json-schemas/fabric/...`. The Power BI Desktop / Service user-facing pages document what the JSON encodes from the user perspective.

## User-facing concept (what the JSON encodes)

- [Create report bookmarks in Power BI to share insights and build stories](https://learn.microsoft.com/power-bi/create-reports/desktop-bookmarks) — bookmarks pane, what's captured (filters, slicers, page state, visual visibility), bookmark groups, the show/hide UX. Maps to `explorationState` + per-visual `display.mode`.
- [Selection pane and visibility](https://learn.microsoft.com/power-bi/create-reports/desktop-bookmarks#visibility-using-the-selection-pane) — the user surface for the `display.mode: hidden|visible` mechanism the parent skill documents.
- [Bookmarks in the Power BI service](https://learn.microsoft.com/power-bi/explore-reports/end-user-bookmarks) — personal vs report bookmarks (only report bookmarks live as PBIR JSON).

## Wiring bookmarks to buttons (the `visualLink` action)

- [Create and configure buttons in Power BI reports](https://learn.microsoft.com/power-bi/create-reports/desktop-buttons) — full button-action reference, including the `Bookmark` action that PBIR persists as `visualLink`.
- [Create page and bookmark navigators](https://learn.microsoft.com/power-bi/create-reports/button-navigators) — auto-generated bookmark navigator that creates a button per bookmark.
- [Identify and use buttons in the Power BI service](https://learn.microsoft.com/power-bi/explore-reports/end-user-buttons) — viewer-side behavior of the action.

## PBIR file format (where bookmarks live)

- [Power BI Desktop project (PBIP) overview](https://learn.microsoft.com/power-bi/developer/projects/projects-overview) — top-level explanation of the PBIP folder.
- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `definition/bookmarks/` folder, file naming conventions, how Desktop generates 20-char hex IDs.
- [Report definition (Fabric REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — the `definition/` part the bookmark folder belongs to. The schema URL pattern `developer.microsoft.com/json-schemas/fabric/item/report/...` is documented here.

## Programmatic / REST

- [Report items REST API](https://learn.microsoft.com/rest/api/fabric/report/items) — the Fabric REST endpoints that round-trip the bookmark JSON via `getDefinition` / `updateDefinition`. See `fabric-rest-api` skill.

## See also (this repo)

- `pbir-visual-json` — visual `name` IDs that bookmarks target via `targetVisualNames`
- `pbir-filters` — `byExpr` snapshot uses the same SQExpr / `SourceRef.Source` shape
- `pbir-themes` — `objects.merge` overrides resolve against the theme baseline
