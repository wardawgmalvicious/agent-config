# Handoff: propagate the new August formatting settings into the authoring skills

- **Audit run**: 2026-09-07 (**second** run — see Provenance)
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 7 and 8 of
  **`00b-audit-report-rerun.md`** (not of `00-audit-report.md`; two
  audits of this window ran on this date)
- **Kind**: content addition to skills that carry **example JSON and
  shipped asset files**, so a wrong property name ships as a broken
  artifact rather than as prose. Gated: each defect must be established
  empirically first. The authoring-side counterpart to brief `04`.
- **Target**: `skills/powerbi/powerbi-report-authoring/references/cartesian.md`,
  `skills/powerbi/powerbi-report-authoring/references/slicers.md`,
  `skills/powerbi/powerbi-report-design/assets/base.json`

## Context

Brief `04` catalogs six August formatting settings for
**`pbir-visual-json`**. Two of those settings also land on files in
`powerbi-report-authoring` and `powerbi-report-design`, which brief `04`
does not name and which no other brief in this directory names either.

The distinction matters because of what these files are. `pbir-visual-json`
documents property paths as reference prose. `cartesian.md` and
`slicers.md` carry **worked example JSON** that agents copy, and
`base.json` is a **shipped theme asset** applied to real reports. A
property name that is merely absent from `pbir-visual-json` costs a
lookup; a wrong one written into `base.json` produces reports that
silently drop formatting.

## D-1 — axis spacing: new setting plus two renames

**Symptom.** `cartesian.md` and `base.json` encode `innerPadding`
literals and know nothing of the August axis layout changes.

**Evidence.** From
`https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-visualization-customize-x-axis-and-y-axis`,
under **Customize category and series layout** → **Spacing options**,
these three sit together under **Layout** in the **Columns** / **Bars** /
**Lines** section, for column, bar, clustered, line, ribbon and waterfall
charts:

> - **Outer padding**: Space between the edges of the plot area and the
>   first and last categories. Set this value to **0%** to remove the
>   padding along the edges of the visual.
> - **Space between categories**: Space between each category or cluster.
> - **Space between series**: Space between bars or columns within each
>   cluster.

**Outer padding** is new. **Space between categories** and **Space
between series** are renames of *Category spacing* and *Series spacing*
(the rename is recorded in release commit `369371ac`, not in the What's
New row). The page also scopes overlap:

> For bar and column charts, enable **Overlap series** …

**Current local state.** `innerPadding` literals appear at
`cartesian.md:528` and `cartesian.md:1033`, and at four places in
`base.json` (lines 96, 123, 152, 179), plus
`powerbi-report-design/references/visual-cookbook.md:107` and `:117`.

**Fix.** Once the property name is established (see Constraint), document
Outer padding in `cartesian.md` and decide whether `base.json` should set
it. Update any prose using the retired *Category spacing* / *Series
spacing* labels.

**Open question.** Whether `innerPadding` is the existing JSON name for
what the UI now calls *Space between categories* — plausible, and
**not established by this audit**. Confirm in an export before writing
any mapping between UI label and property.

**Knock-on.** If `base.json` gains a property, every report built from
`powerbi-report-design`'s asset inherits it. Treat an asset change as
higher-risk than a docs change and justify it explicitly.

## D-2 — slicer: Date picker GA, Single date, new format sections

**Symptom.** `slicers.md` documents slicer modes and sizing —
`'Between'`, `'Relative'`, dropdown heights — with no single-date mode
and none of the August formatting sections.

**Evidence.** From `whats-new.md` at head `0e80b00b`, the *Date picker
for Slicer visual (Generally Available)* row:

> A new **Single date** setting under **Visual** > **Slicer settings** >
> **Selection controls** restricts the slicer to one date at a time.
> Selections can also be cleared from a header icon.

and the *Slicer visual dropdown border color…* row:

> A new **Dropdown** section in the Visual formatting pane adds controls
> for dropdown border color, rounded corners, and open icon color and
> transparency, plus an **Accent bar** option. A new **Hierarchy**
> section lets you color the expand and collapse icons for hierarchy
> slicers.

The overview page
`https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-visualization-slicers`
**was** drilled and confirms Date picker as a setting of the Slicer
visual with relative selections that roll forward, but **carries none of
the new controls** — it is an overview. It also notes List slicer is
still **preview**, which is worth not contradicting.

**Fix.** Drill
`https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-visualization-slicer-visual`
— the detail page, which neither audit run opened — then document the
Single date mode and the Dropdown / Hierarchy sections in `slicers.md`.

**Open question.** Whether *Single date* is a new value of the existing
mode field that `slicers.md` documents (alongside `'Between'`,
`'Before'`, `'After'`, `'Relative'`) or a separate boolean under slicer
settings. The UI wording — "a setting under Selection controls" —
suggests the latter, but that is inference, not evidence.

**Knock-on.** `slicers.md:155` and `:167` give pixel heights per slicer
mode. A single-date mode plausibly has its own height; if so the sizing
table needs a row, and that can only come from a real render.

## Constraint on the fix

**Same rule as brief `04`, and it binds harder here.** Every quote above
is a formatting-pane UI label. Neither drilled page publishes a JSON
property name for any of these settings — that is a measured result, not
an assumption, and it is why brief `04`'s empirical step exists.

Derive each property from a PBIP export before writing it: author a
report in Power BI Desktop exercising the setting, save as PBIP, read the
resulting `visual.json`. `pbir` (`pbir-cli`) is installed globally on
this machine.

**If a property cannot be observed, document the capability and its UI
path and omit the JSON.** For `base.json` specifically, prefer omission —
a shipped theme asset is the worst place to guess.

## Sequencing note

**Execute in the same Desktop session as brief `04`, after it.** `04`
establishes the property names for `pbir-visual-json`; this applies the
same names to the authoring and design skills. Doing this first would
mean deriving the same properties twice.

Brief `09` (`09-add-url-sourced-custom-icons.md`) needs the same round
trip. All three — `04`, `09`, and this — are best done in one sitting.

D-2 additionally needs one doc fetch that `04` does not
(`power-bi-visualization-slicer-visual`), and that fetch can happen
independently of any Desktop access.

## Verification

1. `grep -rniE "outer padding|space between categor|space between series" skills/powerbi --include=*.md`
   — additions landed and use the **new** names.
2. `grep -rn "Category spacing\|Series spacing" skills/powerbi --include=*.md`
   — retired labels are gone or explicitly marked as former names.
3. `grep -rniE "single date" skills/powerbi --include=*.md`
   — D-2 landed.
4. Any property written into `cartesian.md`, `slicers.md` or `base.json`
   must be traceable to a PBIP export, not to this brief. Record the
   Desktop build used.
5. If `base.json` changed: `pbir validate <report-path>` on a report
   using the asset, and state in the commit why an asset change was
   justified.
6. `pre-commit run --all-files`.

## Provenance

Found by the **second** `powerbi` drift audit run on 2026-09-07, against
the same window and head as the first.

Both runs found these settings; they differed on **which artifacts own
them**. The first mapped all six to `pbir-visual-json` (brief `04`). The
second additionally mapped the axis and slicer items onto the authoring
and design skills that carry example JSON and a shipped theme asset.
Neither mapping is wrong — `pbir-visual-json` genuinely owns the
encoding — but the three files named here appear in no other brief in
this directory, and `base.json` is the one artifact in the set where a
wrong guess ships rather than merely misinforms.

The negative result is worth carrying forward: the axis page was drilled
and publishes **no** property name, which converts brief `04`'s
Constraint from a precaution into a measured fact for that item. See
brief `10` for the full drilled evidence.
