# Expected activations

Measured 2026-08-31 against the payload at commit `871ebe9`, using the
static glob check in [README.md](README.md). Token figures are body size
at ~3.5 chars/token — relative weights, not billing figures.

| Fixture file | Activates | Tokens |
| --- | --- | --- |
| `control/notes.md` | *(none)* | 0 |
| `SampleReport.pbip` | `pbip-project-structure` | 2,837 |
| `SampleReport.Report/.platform` | `pbip-project-structure` | 2,837 |
| `SampleReport.Report/definition.pbir` | `pbip-project-structure` | 2,837 |
| `SampleReport.Report/definition/report.json` | `pbir-filters` | 3,301 |
| `SampleReport.Report/definition/reportExtensions.json` | `pbir-conditional-formatting` | 2,696 |
| `SampleReport.Report/definition/pages/pages.json` | `pbir-pages` | 2,991 |
| `…/pages/Page1/page.json` | `pbir-filters`, `pbir-pages` | 6,292 |
| `…/pages/Page1/bookmarks/bookmarks.json` | `pbir-bookmarks` | 2,097 |
| `…/pages/Page1/bookmarks/Bookmark1.bookmark.json` | `pbir-bookmarks` | 2,097 |
| **`…/pages/Page1/visuals/Visual1/visual.json`** | `pbir-conditional-formatting`, `pbir-filters`, `pbir-visual-json` | **9,086** |
| `SampleReport.Report/StaticResources/RegisteredResources/theme.json` | `pbir-themes` | 2,913 |
| `SampleModel.SemanticModel/.platform` | `fabric-tmdl`, `pbip-project-structure` | 5,596 |
| `SampleModel.SemanticModel/definition.pbism` | `fabric-tmdl`, `pbip-project-structure` | 5,596 |
| `SampleModel.SemanticModel/definition/model.tmdl` | `fabric-tmdl` | 2,759 |
| `SampleModel.SemanticModel/definition/cultures/en-US.tmdl` | `fabric-semantic-model-ai-instructions`, `fabric-tmdl` | 6,460 |

## Assertions that carry weight

**1. `visual.json` must not activate `pbip-project-structure`.** This is
the A1 regression test (`7eb6d9e`). Before that fix the same file pulled
four skills and ~11,923 tokens. Three skills and 9,086 is correct; four
means the over-broad `**/*.Report/**` glob is back.

**2. `.Report/.platform` activates `pbip-project-structure`, but a
`.platform` in any *other* item type must not.** A1's second half
narrowed a bare `**/.platform` — a Fabric item marker, not a PBIP one —
to the two PBIP item types. This fixture has no Notebook or Eventstream
to prove the negative; add one before trusting that half.

**3. `control/notes.md` activates nothing.** If it does, the observation
method is wrong. Check this before believing any other row.

**4. `pbir-filters` and `pbir-visual-json` never appear alone on
`visual.json`.** All three `pbir-*` visual skills co-fire there and can't
be separated by path — that is the standing case for Workstream C2 in
`docs/handoff-briefs/execute/skill-context-cost.md`.

## Known gaps

- **Nine conditional skills are untested here** — `fabric-eventstream`,
  `fabric-eventhouse`, `fabric-warehouse`, `fabric-spark`,
  `fabric-error-handling`, `fabric-variable-library`,
  `fabric-realtime-dashboard`, `fabric-data-agent`, `fabric-graph`,
  `fabric-database`. Each keys off a Fabric item-type folder and needs
  its own fixture tree.
- **`fabric-spark` and `fabric-error-handling` have identical globs**, so
  a Notebook fixture would activate both and could not distinguish them.
  That is the point of C1, not a fixture defect.
- **No negative fixture for the `.platform` narrowing** (assertion 2).

## Refreshing this table

Token figures drift whenever a skill body changes — the Workstream B
splits moved four of them by thousands. Re-run the static check in
[README.md](README.md) and update the numbers; a changed number is
expected, a changed *skill list* is a regression.
