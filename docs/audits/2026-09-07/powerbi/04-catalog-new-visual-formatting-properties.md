# Handoff: catalog the new August formatting-pane properties in `pbir-visual-json`

- **Audit run**: 2026-09-07
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 5
- **Kind**: content addition to a skill that encodes JSON property
  paths. Requires an empirical mapping step before any text is written —
  see Constraint. Higher invention risk than an ordinary prose edit.
- **Target**: `skills/powerbi/pbir-visual-json/` (`SKILL.md` and/or
  `references/REFERENCE.md`)

## The problem

The August 2026 release added six formatting capabilities to visuals
that `pbir-visual-json` owns the JSON encoding for. The skill currently
documents none of them. Nothing in the skill is *wrong* — this is
uncovered surface, not drift — but an agent asked to encode any of these
today has nothing to work from and will guess at property names.

## Evidence

All six rows are from `whats-new.md` at commit `369371ac` (2026-08-20).
Quoted verbatim, because the exact UI path is what has to be mapped:

1. **Slicer — Single date.** "A new **Single date** setting under
   **Visual** > **Slicer settings** > **Selection controls** restricts
   the slicer to one date at a time. Selections can also be cleared from
   a header icon." (Row: *Date picker for Slicer visual (Generally
   Available)*.)

2. **Slicer — Dropdown and Hierarchy sections.** "A new **Dropdown**
   section in the Visual formatting pane adds controls for dropdown
   border color, rounded corners, and open icon color and transparency,
   plus an **Accent bar** option. A new **Hierarchy** section lets you
   color the expand and collapse icons for hierarchy slicers."

3. **Matrix — expand/collapse on column headers.** "Column headers in the
   matrix visual now support expand and collapse using +/- icons when
   more than one field is in the Columns field well. Icon color and size
   are customizable under **Column headers** > **+/- icons** in the
   format pane."

4. **Matrix — default freeze state.** "Report authors can set the default
   freeze state for matrix row headers using the **Row headers** toggle
   under **Layout** > **Freeze** in the format pane. This default is
   saved with the report. The right-click freeze options remain available
   for transient per-session changes."

5. **Outer padding.** "An **Outer padding** setting under **Layout**
   controls the space between the plot area edges and the first and last
   categories. Set to 0% to fill the plot area; combine with **Space
   between categories** at 0% to fully fill." Applies to bar, column,
   line, ribbon, and waterfall charts.

6. **Donut centre value.** "Donut charts can display a value in the
   center without an overlaid card. Configure value format, display
   units, font, optional labels, images, and background in the formatting
   pane. The center value updates automatically with filtering,
   cross-highlighting, drill-down, and slice selection."

The same release also renamed two existing axis settings — **Category
spacing → Space between categories** and **Series spacing → Space between
series**. That rename is visible in the release commit message rather
than in the What's New row, and it matters here because item 5 references
the new name.

### Current local coverage

`pbir-visual-json/SKILL.md:101` catalogs `pieChart` / `donutChart` field
wells only. Nothing in `skills/powerbi` mentions outer padding, single
date, matrix column expand/collapse, or a donut centre value — checked by
grep across `skills/powerbi`, `skills/fabric`, and `claude/rules` at
audit time.

## Constraint on the fix

**Every quote above is a formatting-pane UI label, not a JSON property
path.** `pbir-visual-json` documents `visual.json` encoding — property
names, object structure, and value conventions. There is no reliable
UI-label → JSON-property mapping in the upstream docs, and the audit did
**not** establish one.

So this brief must not be executed from its own Evidence alone. Derive
each property empirically before writing:

- Author a report in Power BI Desktop that exercises each setting, save
  as PBIP, and read the resulting `visual.json`. That is the only
  authoritative source for these names.
- `pbir` (the `pbir-cli` tool) is installed globally on this machine and
  is the natural way to inspect the result.

If a property cannot be observed, **leave it out**. A skill that omits a
setting costs an agent one lookup; a skill that names a property Power BI
does not recognise produces a report that fails validation or silently
drops formatting, which is far more expensive to debug. This skill's
whole value is that its property names are correct.

## Sequencing note

Do not bundle with brief `02`. That one is a pure prose correction
verified by grep; this one needs a Desktop round-trip to produce any text
at all. Different verification, different risk — and this brief may
legitimately stall waiting for a Desktop session, which should not hold
up the Fluent 2 corrections.

Note the overlap in subject: brief `02` also touches theming, and item 2
here (slicer dropdown colours) is adjacent to theme-level styling. They
remain separate because `02` corrects false status claims in
`pbir-themes` while this adds per-visual property encoding to
`pbir-visual-json` — different files, different failure modes.

## Verification

1. For each of the six items, confirm the documented property path
   against a real PBIP export — not against this brief. Record which
   Desktop build was used; the audit established a release month
   (August 2026) but no build number.
2. `pbir validate <report-path>` on a report using the newly documented
   properties, if the skill gains any example JSON.
3. `grep -rniE "outer padding|single date|space between categor" skills/powerbi --include=*.md`
   — confirms the additions landed and uses the *new* axis setting names,
   not the retired "Category spacing" / "Series spacing".
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/powerbi/pbir-visual-json/SKILL.md`
   — if the new properties are summarised into `description`, that field
   is capped at 1024 chars and the linter will name it. Long detail
   belongs in `references/`, per this repo's editing conventions.
5. `pre-commit run --all-files`.

## Provenance

Found by the 2026-09-07 `powerbi` drift audit against a 2026-08-01 floor.
These six were classified bucket (a) rather than no-op because
`pbir-visual-json` owns exactly this surface; they were grouped into one
action because they share a single verification path (a PBIP round-trip),
which is also why they are one brief rather than six.

The audit did not drill the individual visual doc pages for these items —
the Evidence is the What's New rows plus the release commit message. That
is enough to establish the settings exist and where they sit in the UI,
and deliberately not enough to write JSON property names, which is what
the Constraint section exists to enforce.

## Execution log

- **Executed**: 2026-09-08 — escalated (blocked on an empirical step this
  session cannot perform)
- **Session**: fresh
- **Files changed**: none
- **Verification**: step 3's grep ran as a baseline and confirms the coverage
  gap the brief describes is still real — the only two hits in `skills/powerbi`
  are unrelated (`card.md:167` `cardVisual…paddingUniform`, and a design-language
  phrase "Single date picker" in an `executive-summary.md` archetype table).
  Neither names a new property. Steps 1, 2 and 4 were not reachable: they
  verify text that the Constraint forbade writing.
- **Why nothing was written**: the Constraint is explicit — derive each property
  empirically, and *"if a property cannot be observed, leave it out."* None of
  the six could be observed, so all six were left out and the brief produced no
  edit. That is the guard working, not a refusal to do the work.
- **What was actually tried**, so the next run does not repeat it:
  - Power BI Desktop **is** installed here — Microsoft Store build
    **2.157.1354.0** (`Microsoft.MicrosoftPowerBIDesktop_2.157.1354.0_x64`).
    That answers the brief's request to record a build number, but authoring a
    report that exercises six formatting settings needs GUI interaction, which
    an agent shell cannot drive. No PBIP round-trip was possible.
  - `pbir` **0.9.7** is installed and its `pbir schema describe` is a genuine
    observation source, so it was tried as a substitute for the round-trip. Its
    bundled schema **predates the August 2026 release** and does not carry any
    of the six. Checked individually:

    | # | Item | What `pbir schema` shows |
    |---|---|---|
    | 1 | Slicer *Single date* | `slicer.selection` / `advancedSlicerVisual.selection` carry only `singleSelect`, `strictSingleSelect`, `selectAllCheckboxEnabled` — item selection, not a date-restricted mode. Absent. |
    | 2 | Slicer *Dropdown* / *Hierarchy* sections | No such containers on `advancedSlicerVisual`. An `accentBar` container exists but cannot be shown to be the one this row adds. Absent. |
    | 3 | Matrix column-header +/- icons | `pivotTable.columnHeaders` (16 properties) has no expand/collapse property at all; the equivalents exist only on `rowHeaders` (`showExpandCollapseButtons`, `expandCollapseButtonColor`, `expandCollapseButtonSize`, `expandCompositeHierarchies`). Absent — and this asymmetry is precisely what the release changed. |
    | 4 | Matrix default freeze state | No freeze property on `pivotTable.rowHeaders`, `columnHeaders`, `grid` or `layout`. No `autoExpand` either. Absent. |
    | 5 | Outer padding | `columnChart.categoryAxis.innerPadding` exists ("Space between categories (inner padding)"); there is no outer-padding sibling, and `columnChart.layout` / `spacing` / `plotArea` carry none. Absent. |
    | 6 | Donut centre value | `donutChart.slices` holds only `innerRadiusRatio` and `startAngle`; `donutChart.labels` has no centre-value property. Absent. |

    The schema being pre-window is itself the useful result: `pbir schema` is
    **not** a shortcut around the Desktop round-trip for anything in this
    release, and a future executor should not spend the attempt again until
    `pbir` ships a newer schema.
- **Deferred — the whole brief.** It needs either a Power BI Desktop session
  driven by a human (author the six settings, save as PBIP, read `visual.json`)
  or a `pbir` release whose bundled schema postdates 2026-08-25. Item 5's
  finding is the one with a concrete next step: the property, if it follows the
  existing convention, would sit beside `categoryAxis.innerPadding` — but that
  is a guess, and the Constraint forbids writing it.
- **Why the run continued.** The brief's own **Sequencing note** anticipates
  this: *"this brief may legitimately stall waiting for a Desktop session, which
  should not hold up the Fluent 2 corrections."* Nothing failed here — no
  command errored and no evidence contradicted the brief — so this is a block,
  not the first-failure stop condition. Later briefs were executed.
- **Deviations**: none. No property name was written from the brief's Evidence
  alone, and no example JSON was invented.
