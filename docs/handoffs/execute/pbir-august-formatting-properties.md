---
status: open
priority: 2
needs: []
blocked-by: [pbir-skills-into-pbir-report-workflow.md]
written: 2026-10-07
---

# Handoff: encode the August 2026 formatting settings in the PBIR guidance

- **Written**: 2026-10-07, by a `/triage` sweep, from four audit
  follow-ups of the 2026-09-07 `powerbi` run, retired 2026-10-08: 04,
  10 and 13, and the deferred JSON half of 09, which a plain `applied`
  stamp kept out of every view. Each reads back with
  `git show 7dd627e:docs/audits/2026-09-07/powerbi/completed/<file>`,
  the files being `04-catalog-new-visual-formatting-properties.md`,
  `10-supply-drilled-evidence-for-matrix-properties.md`,
  `13-propagate-new-formatting-to-authoring-skills.md` and
  `09-add-url-sourced-custom-icons.md`. Re-measured at
  `4b6e108`: `pbir`'s schema now names part of what all four waited on
  a Desktop round-trip for.
- **Kind**: an edit to `pbir-report-workflow`'s references, from the
  schema where it names a property and from a PBIP export where it does
  not. Nothing is drafted. The follow-ups hold the evidence, the UI
  paths and the constraint; this brief holds what is still open.
- **Re-aimed**: 2026-10-09. It targeted four skills, each with one
  lifetime invocation or none, so it waited on
  [platform-skill-portfolio.md](platform-skill-portfolio.md). Three of
  them fold into `pbir-report-workflow` and the fourth is archived, so
  it waits for the fold.

## What the schema names now

Measured 2026-10-07 with `pbir schema describe --json` on `pbir` 0.9.29
(local schemas visualConfiguration 2.3.0, visualContainer 2.9.0,
formattingObjectDefinitions 1.5.0). On 2026-09-08, `pbir` 0.9.7 had
none of the first three rows.

| Setting | Follow-up | In the schema |
| --- | --- | --- |
| Matrix +/- icons, row and column headers | 04 item 3, 10 E-2 | `pivotTable.rowHeaders` and `.columnHeaders`: `showExpandCollapseButtons`, `expandCollapseButtonsColor`, `expandCollapseButtonsSize` |
| Matrix auto-expand | 10 E-1 and E-2 | `autoExpand` on both, "While editing, automatically expands…" |
| Donut centre value | 04 item 6 | `donutChart.centerValue.show`; which of `value`, `label`, `image` and `background` carry its format is not shown |
| Slicer Selection icon section | 13 D-2 | `slicer.selectionIcon.color` |
| Slicer Date picker style | 13 D-2 | `slicer.data.mode` lists `RelativeDatePicker` and `Single` beside the older values |
| Space between categories | 13 D-1 | `columnChart.categoryAxis.innerPadding`, "Space between categories (inner padding)" |
| Space between series | 13 D-1 | `columnChart.layout.stackedGapSize`, "Space between series"; `clusteredColumnChart.layout.clusteredGapSize` |
| Overlap series | 10 E-4 | `clusteredColumnChart.layout.clusteredGapOverlaps` is the likely one, unconfirmed |

`powerbi-report-authoring`'s `cartesian.md` showed `clusteredGapSize`
and `stackedGapSize` under `layout` on 2026-10-07, so 13's D-1 is a
label mapping, not a new property. That skill is archived, so the
mapping goes where the properties do.

## What still needs an export

Absent from that schema on 2026-10-07:

- the **Single date** toggle (04 item 1; `slicer.selection` still holds
  only `selectAllCheckboxEnabled`, `singleSelect`, `strictSingleSelect`);
- the slicer **Dropdown** and **Hierarchy** sections (04 item 2);
- the matrix **default freeze state** (04 item 4);
- **Outer padding** (04 item 5, 13 D-1);
- the single-date row in `slicers.md`'s sizing table, which only a
  render gives (13 D-2);
- the Field-value icon source in `visual.json` (09).

Newer schemas exist: `pbir schema status` showed visualConfiguration
2.7.0 and visualContainer 2.12.0 remote, and `pbir` 0.9.32 is out.
Fetch or upgrade before deciding any of these needs Desktop.

## Where it lands

In `skills/powerbi/pbir-report-workflow/references/`, once
[pbir-skills-into-pbir-report-workflow.md](pbir-skills-into-pbir-report-workflow.md)
has folded the PBIR skills there:

- `visual-json.md`, from `pbir-visual-json`: every property above, and
  the axis names and slicer encodings that were to go to
  `powerbi-report-authoring`'s `cartesian.md` and `slicers.md`, the
  skill `platform-skill-portfolio.md` Part 1 archives.
- `design/assets/base.json`, from `powerbi-report-design`: only if an
  asset change is justified; 13's constraint prefers omission.
- `conditional-formatting.md`: the Field-value icon.

`pbir-report-workflow` owes a retest, which `skill-status.py --stale`
names. The follow-ups' constraint still binds: a property name comes
from the schema or an export, never from a UI label, and one that
cannot be observed is left out.

## Not checked

- Whether Desktop writes these properties as the schema names them: a
  schema says what is valid, an export what Desktop writes.
- `pbir validate` on a report using any of them.

## Re-measure before acting

```bash
pbir --version                                     # 0.9.29 on 2026-10-07
pbir schema status                                 # visualContainer 2.9.0 local, 2.12.0 remote
pbir schema describe pivotTable columnHeaders --json
grep -rn -iE "autoExpand|showExpandCollapseButtons|centerValue|RelativeDatePicker" skills/powerbi/   # none on 2026-10-07
```
