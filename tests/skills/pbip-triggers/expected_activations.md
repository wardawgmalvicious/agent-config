# Expected activations

Skill lists measured against the payload at commit `871ebe9` and refreshed
2026-09-01, using the static glob check in [README.md](README.md).

**The `Tokens` column is a ceiling, not a toll.** A `paths:` match injects
each skill's **listing entry** — a name, plus its description where
`skillOverrides` does not collapse it — and nothing more. The figures below
are *body* size at ~3.5 chars/token: what you would pay if every skill in
the row were then **invoked**. Treat them as relative weights and as the
worst case, never as the cost of opening the file. (Corrected 2026-09-01;
this table previously read as though a match loaded the bodies.)

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
| `SampleModel.SemanticModel/.platform` | `fabric-tmdl`, `fabric-tmdl-api`, `pbip-project-structure` | 6,642 |
| `SampleModel.SemanticModel/definition.pbism` | `fabric-tmdl`, `fabric-tmdl-api`, `pbip-project-structure` | 6,642 |
| `SampleModel.SemanticModel/definition/model.tmdl` | `fabric-tmdl`, `fabric-tmdl-api` | 3,805 |
| `SampleModel.SemanticModel/definition/cultures/en-US.tmdl` | `fabric-semantic-model-ai-instructions`, `fabric-tmdl`, `fabric-tmdl-api` | 7,506 |

## Assertions that carry weight

**1. `visual.json` must not activate `pbip-project-structure`.** This is
the A1 regression test (`7eb6d9e`). Before that fix the same file pulled
four skills and ~11,923 tokens. Three skills and 9,086 is correct; four
means the over-broad `**/*.Report/**` glob is back.

**2. `.Report/.platform` activates `pbip-project-structure`, but a
`.platform` in any *other* item type must not.** A1's second half
narrowed a bare `**/.platform` — a Fabric item marker, not a PBIP one —
to the two PBIP item types. The positive half is the two rows above; the
negative half is proved in
[`../fabric-triggers/`](../fabric-triggers/expected_activations.md),
whose eleven non-PBIP `.platform` files pull no `pbip-project-structure`
between them.

**3. `control/notes.md` activates nothing.** If it does, the observation
method is wrong. Check this before believing any other row.

**4. `pbir-filters` and `pbir-visual-json` never appear alone on
`visual.json`.** All three `pbir-*` visual skills co-fire there and can't
be separated by path — that is the standing case for Workstream C2 in
`docs/handoff-briefs/execute/skill-context-cost.md`.

**5. Every `.SemanticModel` file carries `fabric-tmdl-api` as well as
`fabric-tmdl`.** Added 2026-09-01 by Workstream E, which took the skill
out of the session listing (244 tokens) in exchange for firing here. The
pair is complementary and was checked before the glob went in:
`fabric-tmdl` governs *authoring* TMDL, `fabric-tmdl-api` governs
*shipping* it — `updateDefinition` deleting any part you omit, never
sending `.platform`, base64 + LRO. The second is load-bearing exactly
while editing the parts the first one writes. `**/*.SemanticModel/**` and
not the sibling's `**/*.tmdl`, because the API operates on the whole item
definition including `definition.pbism`, which is not TMDL.

## Known gaps

The fourteen Fabric item-type skills are covered by
[`../fabric-triggers/`](../fabric-triggers/), which carries that set's own
gaps. Nothing in the Power BI half is untested.

## Refreshing this table

Token figures drift whenever a skill body changes — the Workstream B
splits moved four of them by thousands. Re-run the static check in
[README.md](README.md) and update the numbers; a changed number is
expected, a changed *skill list* is a regression.
