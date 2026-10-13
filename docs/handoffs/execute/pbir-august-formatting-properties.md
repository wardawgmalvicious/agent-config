---
status: open
priority: 2
needs: [desktop]
blocked-by: []
written: 2026-10-07
---

# Handoff: confirm the August 2026 formatting properties in a PBIP export

- **Written**: 2026-10-07, by a `/triage` sweep, from four follow-ups of
  the 2026-09-07 `powerbi` audit: 04, 10, 13 and the JSON half of 09.
  Each reads back with
  `git show 7dd627e:docs/audits/2026-09-07/powerbi/completed/<file>`.
- **Narrowed**: 2026-10-12. Report theme schema 2.157, which `pbir`
  0.9.32, the latest, does not bundle, named all but one of the settings
  this brief held for Desktop. The names landed in
  `pbir-report-workflow`'s `visual-json.md`, § "August 2026 formatting
  properties", which says what was measured; the commit that narrowed
  this brief says how. What is left needs a PBIP saved by Desktop.
- **Kind**: a probe in Power BI Desktop, then an edit to
  `pbir-report-workflow`'s references. The follow-ups' constraint
  stands: a name comes from a schema or an export, never from a UI label.

## What only an export settles

1. **Desktop writes the 2.157 names**: `categoryAxis.outerPadding`,
   `selection.singleDate`, the slicer `dropdown` object,
   `items.expandCollapseIconColor`, the matrix `columnHeaders` +/- icons,
   and the donut's `centerValue`, `value`, `label`, `image` and
   `centerBackground`, rather than the names `pbir`'s June catalog shows
   (`background`, `valueBold`, `valueDisplayUnits` …).
2. **The suffix each number takes**, which a schema type does not
   decide: `pbir set` writes `innerPadding` as `20D`, while
   skills-for-fabric v0.3.13's examples wrote `26L`
   (`git show 79eddb3:skills/powerbi/powerbi-report-authoring/references/cartesian.md`,
   line 528).
3. **The freeze toggle**: whether **Layout** > **Freeze** > **Row
   headers** writes `rowHeaders.unfrozen`, and whether off is `true`.
4. **The Field-value icon** (09): the `values.icon` shape when the
   **Icons** format style is **Field value**, which
   `conditional-formatting.md` withholds.

## Where it runs

Power BI Desktop, August 2026 release or later, on a PBIR project in
git. Set each setting on a visual of its type, save, and read the
`visual.json` diff.
[pbir-cli-writes-with-desktop-open.md](pbir-cli-writes-with-desktop-open.md)
needs the same setup, so one sitting can serve both. Keep any repo,
workspace or client name out of what lands.

## Where it lands

`skills/powerbi/pbir-report-workflow/references/`: `visual-json.md` §
"August 2026 formatting properties" drops each caveat the export
settles and corrects any name it contradicts, and
`conditional-formatting.md` gains item 4. A `references/` edit owes no
retest.

## Re-measure before acting

```bash
pbir --version              # 0.9.29 on 2026-10-12; 0.9.32 bundles the same schemas
pbir schema status          # reportThemeSchema 2.155 local, 2.157 remote on 2026-10-12
grep -n "August 2026" skills/powerbi/pbir-report-workflow/references/visual-json.md
```
