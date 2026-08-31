---
name: fabric-realtime-dashboard
description: "Use for Microsoft Fabric Real-Time Dashboards (KQLDashboard item) — authoring or editing RealTimeDashboard.json by hand or via Git: file anatomy (queries[] holds all KQL text; tiles reference it by queryRef.queryId; baseQueries are {id, variableName, queryId} wired through usedVariables), load-time validation (every queryId referenced exactly once, RFC-4122 UUIDs, identity preservation — changing ids = delete+recreate on sync, misleading 'baseQueryId' error = malformed queryId), the 24-column tile grid, visual types (card, multistat, bar, column, table, map, kpi) and visualOptions, the kpi gauge's static-only min/max/reference lines, autoRefresh intervals, display-edge formatting in KQL (no per-tile number formats — emit currency/percent as strings), the live JSON Schema at dataexplorer.azure.com/static/d/schema/{v}/dashboard.json, and the missing image-export REST API. Invoke on mentions of Real-Time Dashboard, RTDB, KQL dashboard, dashboard tiles/base queries, or RealTimeDashboard.json."
paths:
  - "**/*.KQLDashboard/**"
---

# Fabric Real-Time Dashboard (KQLDashboard)

Hand-authoring and Git-editing the `RealTimeDashboard.json` definition. The
portal load endpoint validates beyond JSON Schema conformance — most of what
breaks a hand-authored dashboard is in the wiring rules below, not the syntax.
Facts verified against a live dashboard (schema_version 81, Aug 2026) and
[Real-time dashboard - Git integration](https://learn.microsoft.com/fabric/real-time-intelligence/git-real-time-dashboard).

## File anatomy

Item folder: `<Name>.KQLDashboard/` with `.platform` + `RealTimeDashboard.json`
(portal may name it `RealTimeDashboard-N.json`). Top-level keys:
`schema_version`, `flavor` (`"RTDashboard_Regular"`), `autoRefresh`, `tiles`,
`baseQueries`, `parameters`, `dataSources`, `pages`, `queries`, `embeddedApps`
(+ portal-managed `$schema`/`id`/`eTag`/`title`, which a Git-created shell may
omit — leave them however the portal wrote them).

All KQL text lives in `queries[]`; everything else points at it:

- `queries[]` — `{id, dataSource: {kind: "inline", dataSourceId}, text, usedVariables}`
- `tiles[]` — `{id, queryRef: {kind: "query", queryId} | {kind: "baseQuery", baseQueryId}, title, visualType, pageId, layout, visualOptions}`
- `baseQueries[]` — `{id, variableName, queryId}`; the text is the referenced
  query object. Variable names must start with `_`. A tile query that uses one
  references the variable in its KQL text **and** lists it in `usedVariables`.
  Base queries must each be a single tabular expression (they are wrapped as
  `let _name = (<text>);`) — no scalar lambdas, no internal `let` statements.
- `parameters[]` — `kind: "duration"` exposes two variables via
  `beginVariableName` / `endVariableName` (commonly `_startTime` / `_endTime`).
- `dataSources[]` — `kind: "kusto-trident"` with `databaseArtifactId` (the
  KQLDatabase item id) for Fabric-native sources.

## Load-time validation rules

- **Every `queryId` referenced exactly once**, counted across
  `tiles[].queryRef.queryId`, `baseQueries[].queryId`, and
  `parameters[].dataSource.queryRef.queryId`. Duplicating a tile means
  duplicating its query with a fresh id too.
- **Every `id` is an RFC-4122 UUID**, unique within its category. Readable
  pseudo-ids are rejected. For deterministic scripted edits use
  `uuid.uuid5(namespace, label)`.
- **Misleading error**: `/tiles/N/queryRef ... must have required property
  'baseQueryId'` almost always means a malformed `queryRef.queryId` — the
  schema's `oneOf` fails the `query` branch and reports the `baseQuery`
  branch's complaints instead. Fix the UUID and the cascade clears.
- **Identity preservation**: never change existing `id`s (top-level, tile,
  page, query, dataSource, parameter), `pageId`, `queryRef.queryId`,
  `dataSource.dataSourceId`, parameter `variableName`s, or `.platform`
  `logicalId`. A changed identifier is treated as delete + recreate on the
  next *Update from Git*, losing pinned references and share targets.

## Layout

24-column grid. `layout: {x, y, width, height}` in grid units; `x + width <=
24`. Typical: stat cards 4–6 wide × 4 tall, charts 8–12 wide × 7–9 tall.

## Visuals

`visualType` is a free string in the schema — the UI interprets it. Working
values: `card` (single stat), `multistat`, `bar`, `column`, `table`, `map`,
`kpi`, `markdownCard` (plus line/area/pie/scatter/anomalychart/funnel/
heatmap/plotly). Options live in the flat `visualOptions` bag, prefixed per
visual (`multiStat__labelColumn`, `map__latitudeColumn`, `kpi__valueColumn`,
generic `xColumn`/`yColumns`/`hideLegend`/…). Minimal or empty
`visualOptions: {}` is valid — column inference handles the simple cases.

- **multistat**: rows = stats; `multiStat__labelColumn` / `multiStat__valueColumn`,
  `multiStat__displayOrientation`, `multiStat__slot: {width, height}` (inner
  grid of stat slots).
- **kpi** (gauge/bar/donut/number via `kpi__visualType`): `kpi__minValue`,
  `kpi__maxValue`, and `kpi__referenceLines` take **static numbers only** — a
  dynamic (query-computed) target cannot be bound. For "actual vs computed
  target" use a multistat or fold the comparison into the query.
- `card` and `multistat` render **string** values fine — the basis of the
  display-edge formatting pattern below.

## Formatting at the display edge

There are no per-tile number-format options (only the kpi visual has
`kpi__valueFormat`). Currency / percent presentation is done in KQL by
emitting formatted strings — see [references/REFERENCE.md](references/REFERENCE.md)
for a validated `money()` lambda (`"$1,234,567.89"`, rounding carry,
negatives). KQL has no `format_number()` and RE2 regex has no lookahead, so
comma grouping must be hand-rolled. Numeric axes (bar/column y-columns) must
stay numeric — put the unit in the tile title and column name
(`['Order Value ($)']`) instead. Related KQL pitfalls (`round()` returns
`real`, `toint()` nulls on decimal strings): `rules/coding-kql.md`.

## Auto refresh

`"autoRefresh": {"enabled": true, "defaultInterval": "5m", "minInterval": "30s"}`
— intervals from the enum `1s|10s|30s|1m|5m|15m|30m|1h|2h|1d`. `minInterval`
caps what viewers may select.

## Live JSON Schema

`https://dataexplorer.azure.com/static/d/schema/{schema_version}/dashboard.json`
plus sibling `tile.json`, `query.json`, `baseQuery.json`, `parameter.json`.
The `$schema` URL embedded in Microsoft's own sample files
(`pbiadx.powerbi.com/static/d/schema/...`) returns 404 — swap the host.

## What does not exist

- **No image/render REST API.** The Power BI `exportToFile` API does not
  cover KQL dashboards; the RTDB REST surface is item CRUD + the JSON
  definition, and the portal's "export" is the JSON file. Visual verification
  means a browser (screenshot or automation with an authenticated session);
  data-level verification means running the tile queries directly against the
  cluster.
- No cross-tile dynamic references — a tile query sees base queries and
  parameter variables, nothing from other tiles.

## Editing workflow

Round-trip options: Git sync (*Update from Git*), or portal **Manage →
Replace with file** for immediate feedback. Test tile queries before shipping
by composing them exactly as the dashboard does: prepend
`let <variableName> = (<base query text>);` for each entry in
`usedVariables`, then run against the database. Serialization is CRLF with
**no final newline** (JSON item part) — see `rules/fabric-git-serialization.md`.
