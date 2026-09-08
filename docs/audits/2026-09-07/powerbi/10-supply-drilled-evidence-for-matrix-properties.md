# Handoff: supply drilled upstream evidence for brief `04`'s matrix and axis items

- **Audit run**: 2026-09-07 (**second** run — see Provenance)
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 9 of **`00b-audit-report-rerun.md`**
  (not of `00-audit-report.md`; two audits of this window ran on this
  date)
- **Kind**: **evidence supplement to brief `04`, not an independent
  edit.** It partially discharges `04`'s empirical step for one item,
  hardens it for another, and corrects one detail. Execute it *inside*
  `04`, not as separate work.
- **Target**: `skills/powerbi/pbir-visual-json/` — via brief
  `04-catalog-new-visual-formatting-properties.md`

## Context

Brief `04` catalogs six August formatting capabilities for
`pbir-visual-json` and closes with an explicit limitation:

> The audit did not drill the individual visual doc pages for these
> items — the Evidence is the What's New rows plus the release commit
> message. That is enough to establish the settings exist and where they
> sit in the UI, and deliberately not enough to write JSON property
> names, which is what the Constraint section exists to enforce.

The second audit run **did** drill two of those pages — the matrix visual
page and the x/y-axis page. This brief carries what they yielded so brief
`04`'s executor starts from drilled evidence rather than repeating the
fetch. It changes `04`'s scope in three ways, below.

## Evidence

### E-1 — one published property name, from the embedded Authoring SDK

`https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-visualization-matrix-visual`,
under **Auto-expand row and column headers**, verbatim:

> In [embedded scenarios](../developer/embedded/embedded-analytics-power-bi),
> you can use the Authoring SDK to set the `autoExpand` property on the
> `rowHeaders` and `columnHeaders` objects so a matrix opens with its
> rows and columns auto-expanded by default.

This is the **only** property name any page drilled in this run spells
out. Read the Constraint below before using it — it is not automatically
the PBIR `visual.json` name.

### E-2 — brief `04`'s item 3 is narrower than the page

`04` records `+/- icons` customization under **Column headers** only. The
page states it for both:

> To customize the color and size of the +/- icons on the row or column
> headers, use the **Row headers** > **+/- icons** or **Column headers**
> > **+/- icons** settings in the format pane.

It also documents a capability `04` does not carry at all — an
**Auto expand** toggle, in the format pane, under both header objects:

> Report authors also control auto-expand behavior directly in the format
> pane. Under **Column headers** > **Options** and **Row headers** >
> **Options**, toggle the **Auto expand** setting on or off.

with a stated use case: columns or rows that change dynamically, e.g.
personalize-visuals or field parameters. Separately, for consumers:

> When report consumers open a matrix visual in [Explore], the columns
> and rows added to the visual are auto-expanded by default.

### E-3 — brief `04`'s item 4 confirmed verbatim, plus the default

The freeze item is confirmed exactly as `04` states it, and the page adds
the pre-existing default and the transient escape hatch:

> By default, row headers are frozen, which ensures they stay visible
> when you scroll horizontally.

> To change the default freeze state for report consumers, turn the
> **Row headers** toggle on or off under **Layout** > **Freeze** in the
> format pane. When the toggle is off, the row headers hide as the
> matrix scrolls.

> Report consumers can also right-click a matrix and select **Freeze row
> headers** or **Unfreeze row headers**. This right-click option is
> transient and applies only to the current viewing session.

### E-4 — the axis page publishes no property name, hardening `04`'s item 5

`https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-visualization-customize-x-axis-and-y-axis`,
under **Customize category and series layout**, confirms all three
settings and their location — the **Layout** group inside the
**Columns** / **Bars** / **Lines** section — and the renames `04` sourced
from the commit message:

> - **Outer padding**: Space between the edges of the plot area and the
>   first and last categories. Set this value to **0%** to remove the
>   padding along the edges of the visual.
> - **Space between categories**: Space between each category or cluster.
> - **Space between series**: Space between bars or columns within each
>   cluster.

It also scopes overlap, which `04` does not record:

> For bar and column charts, enable **Overlap series** …

**It names no JSON property for any of them.** So `04`'s Constraint
stands unchanged for item 5: the PBIP round-trip is still the only route.
Note that `skills/powerbi/powerbi-report-authoring/references/cartesian.md`
and `skills/powerbi/powerbi-report-design/assets/base.json` already encode
`innerPadding` literals, which is the closest existing analogue and a
sensible place to start looking in an export.

## Constraint on the fix

**`autoExpand` is an embedded Authoring SDK name, not a confirmed PBIR
`visual.json` name.** The Authoring SDK object model and the PBIR schema
are related but not guaranteed identical, and the page says "embedded
scenarios" explicitly. Treat E-1 as a strong hint that shortens the
search in the PBIP export — **not** as a licence to write it into the
skill unverified. That would be exactly the invention brief `04`'s
Constraint exists to prevent, and this brief must not be read as relaxing
it.

Everything in E-2, E-3 and E-4 is a **UI path and behaviour**, which is
safe to document as such. Only the JSON encoding needs the export.

## What this changes in brief `04`

1. **Item 3** — widen from column headers to **both** row and column
   headers, and add the format-pane **Auto expand** toggle under
   `… > Options` for each. Optionally note the Explore default.
2. **Item 4** — no change needed; confirmed verbatim. Consider adding
   that frozen is the pre-existing default and that right-click remains
   transient.
3. **Item 5** — no relaxation. Add the **Overlap series** bar/column
   scoping and the confirmed **Layout** grouping; the property name still
   requires the export.
4. **New candidate name** to look for in the export: `autoExpand` on
   `rowHeaders` / `columnHeaders`.

## Verification

Brief `04`'s verification is authoritative and unchanged. Additionally:

1. `grep -rniE "autoExpand|auto.expand" skills/powerbi --include=*.md`
   — if `autoExpand` appears, confirm the surrounding text says whether
   it was verified in a PBIP export or is labelled as the embedded SDK
   name. An unqualified appearance is a defect.
2. `grep -rniE "overlap series|space between series" skills/powerbi --include=*.md`
   — the axis additions landed with the new names.
3. `pre-commit run --all-files`.

## Provenance

Found by the **second** `powerbi` drift audit run on 2026-09-07, against
the same window and head as the first.

The two runs differ only in drill depth, not in findings: the first
sourced these items from the What's New rows plus the release commit
message and said so; the second spent two `microsoft-learn-mcp` fetches
on the matrix and axis pages. That is why this is an evidence supplement
rather than a competing brief — it does not contradict `04`, it feeds it.

The most useful result is arguably the **negative** one in E-4: drilling
the axis page and finding no property name converts `04`'s Constraint
from a precaution into a measured fact for that item.

## Execution log

- **Executed**: 2026-09-08 — deferred with brief `04` (no independent edit)
- **Session**: fresh
- **Files changed**: none
- **Why nothing was written**: the **Kind** is explicit — this is *"an evidence
  supplement to brief `04`, not an independent edit … Execute it inside `04`,
  not as separate work."* Brief `04` is blocked on a Power BI Desktop PBIP
  round-trip that an agent shell cannot perform (see `04`'s execution log for
  what was tried, including the finding that `pbir` 0.9.7's bundled schema
  predates this release and carries none of the six). With `04` unexecuted,
  there is nothing for this brief to execute *inside*, and its own instruction
  forbids doing the work separately. No edit was made to
  `skills/powerbi/pbir-visual-json/`.
- **Verification**: this brief's two additional greps ran as baselines. Step 3
  runs once at the end of the brief set.
  1. `grep -rniE "autoExpand|auto.expand" skills/powerbi` — **no hits**. The
     defect this check guards against (an unqualified `autoExpand` written into
     a skill as though it were a confirmed PBIR name) does not exist in the
     tree, and this run did not introduce it. The Constraint was observed:
     `autoExpand` is an embedded Authoring SDK name and was treated as a search
     hint only.
  2. `grep -rniE "overlap series|space between series" skills/powerbi` — no
     hits, so the axis additions have not landed and the new setting names are
     nowhere yet. Re-run after `04` executes.
  - E-4's pointer was confirmed as a real starting place: `innerPadding`
    literals do exist today at `cartesian.md:528`, `cartesian.md:1033`, and
    three times in `powerbi-report-design/assets/base.json` (96, 123, 152). A
    future export search for the Outer padding property should start beside
    them.
- **Deferred — the whole brief, jointly with `04` and with `09`'s JSON half.**
  All three want the same single Desktop session. When it happens, this brief's
  E-1 through E-4 are the drilled evidence to start from, so the matrix and
  axis pages need not be fetched again; its **What this changes in brief `04`**
  section is the amended scope for items 3, 4 and 5.
- **Deviations**: none.
