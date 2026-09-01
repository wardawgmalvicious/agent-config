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
`visual.json`.** All three `pbir-*` visual skills co-fire there and cannot
be separated by path. That was the standing case for merging them —
Workstream C2 of the retired `skill-context-cost.md` — and **the merge was
declined on 2026-09-01.** Do not reopen it on the co-firing alone: the
co-firing is real, and it is not the argument.

Three things killed it, two of which postdate the brief:

- **The prize is ~700 tokens, not ~9,000.** C2 was scored at the trio's
  combined *body* — the 9,086 in the `Tokens` column above. An activation
  injects the listing entry, so the real figure is three descriptions
  (2,914 chars, ~1,079 tok) against ~379 for one merged entry.
- **It saves nothing in this repo.** `skillOverrides` in
  `.claude/settings.json` collapses all three to `name-only`, so an
  activation here emits three *names*. The ~700 tokens exist only in client
  repos, which carry no overrides.
- **Merging is lossy now that `DESCRIPTION_MAX` is 1,024.** One merged
  description replaces 2,914 chars of trigger text with 1,024 — a 65% cut
  to the entire trigger mechanism, across three descriptions that barely
  overlap (literal suffixes, filter types, CF selectors). And since
  `pbir-filters` also globs `report.json` and `page.json`, the merged skill
  would fire on **82** files rather than 73, carrying visual-authoring
  guidance into page- and report-level files that have no visuals in them.

A merge also renames, and the names are load-bearing in more places than
the brief listed: `skillOverrides`, the per-skill junctions, client-repo
relinks — *and* roughly a dozen prose cross-references from other skill
bodies (`pbir-themes`, `pbir-pages`, `pbir-bookmarks`,
`pbir-report-workflow`, `fabric-gotchas`). None of those error when stale.

Reconsider only if `skillOverrides` is dropped here **and** the three
descriptions turn out to be genuinely redundant rather than merely
co-firing. The cheap alternative that keeps the trio intact is
`when_to_use`, which is near-free on a conditional skill and whose best
target is exactly this cluster.

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
