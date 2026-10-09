---
status: deferred
priority: 2
needs: []
blocked-by: []
reopen-when: a client repo other than the Git-sync sandbox holds a Plan item
written: 2026-09-02
---

# Handoff: does the Fabric IQ Plan workload need a skill?

- **Written**: 2026-09-02, after fetching the two
  `learn.microsoft.com/fabric/iq/plan/` links that prompted
  the [`fabric-semantic-model-audit`](../../../skills/fabric/fabric-semantic-model-audit/SKILL.md) work and
  finding they were about something else entirely.
- **Kind**: coverage decision, answered yes on 2026-09-30. Since
  2026-10-09 the expected home is a reference under `fabric-iq` rather
  than a skill of its own: Learn lists Planning among the IQ workload's
  items, and [iq-skills-into-fabric-iq.md](iq-skills-into-fabric-iq.md)
  builds that skill. Confirm the shape with the user on reopening.
- **2026-10-09**: [platform-skill-portfolio.md](platform-skill-portfolio.md)
  holds new platform skills back until client work holds their items.
  The only Plan item on this machine sits in the sandbox repo
  (2026-10-08).
- **Step 0**: answered *no* on 2026-09-03 and *yes* on 2026-09-30, when a
  Plan item appeared in a client sample repo on this machine, this
  brief's reopen trigger. The recommendation below was unchanged *on the
  merits* throughout: the content is real, uncovered and unguessable.
- **Run in**: a fresh session, after re-measuring the sample item from
  the main checkout (§ Re-measure before acting), since a worktree's
  guard refuses git in another repo.
- **Audit 2026-10-06**: What's New renamed the GA row "Planning" to "Plan" and added "Native Planning Engine (Preview)" ([report](../../audits/2026-10-06/fabric/00-audit-report.md)).

## Why this brief exists: a premise correction

Two Microsoft Learn links were offered as *semantic modelling best
practice* and *time intelligence best practice*. Both were fetched on
2026-09-02. **Neither is general modelling guidance.** Both are
documentation for the **Fabric IQ Plan** workload — a planning product
with its own item type, its own grid, and its own vocabulary.

| Link | What it actually covers |
| --- | --- |
| `.../plan/resources/best-practices/semantic-modeling` | How to shape a semantic model so it drives a **planning grid**: dimension-driven rather than fact-driven row visibility, Scenario modelled as a dimension, validity tables, weight matrices, PowerTable, Blend. Ten named planning cases. |
| `.../plan/resources/best-practices/time-intelligence` | **Label-format parsing.** Which member values Plan's automatic time intelligence recognises (`Q1`, `FY25`, `W53`, `2025-02-01`) and which it silently drops (`Sept`, `WK1`, `Q5`, `2025-2026`, `First Half`). Nothing to do with DAX time intelligence. |

Anyone reading the first title and expecting star-schema guidance gets
planning-grid guidance instead. That misread is the reason to write this
down: the correction is cheap now and expensive after a skill has been
drafted against the wrong premise.

The genuine modelling-audit content shipped separately as
[`fabric-semantic-model-audit`](../../../skills/fabric/fabric-semantic-model-audit/SKILL.md),
drilled against different sources.

## Step 0 — the gating question

**Is Plan in use, or planned, in any repo worked on here?**

Everything else in this brief is contingent on that. Unlike the ontology
brief — where a payload inconsistency already exists because
`fabric-data-agent` names ontology as a source with nothing behind it —
there is no internal pressure here at all. `grep -rni "powertable\|fabric
iq plan"` over `skills/`, `claude/` and `tests/` returns nothing, and
the reference Fabric repo contains no Plan item (confirmed 2026-09-02).

**That grep no longer returns nothing, and the next reader must not
misread the hits.** As of 2026-09-03 03:19 (`9ccbace`, ~1.5 h *after*
this brief's first step 0 answer was committed) it returns five, all from
`tests/skills/fabric-semantic-model-audit/`: the audit fixture *is*
Microsoft's Plan sample `.pbix`, and `expected_findings.md` describes
validity tables and PowerTable by name. Those are **carve-out** assets —
they exist to prove the audit skill *stands down* on a planning model,
which is step 3's discharged work. They are payload pressure pushing the
same way as the `fabric-ontology` clause, not the wave-12 pattern of a
promise with nothing behind it. Note also what the fixture is not: a
`.SemanticModel`, so no `paths:` glob on a Plan item would ever fire on
it, and step 1 stays as unresolved-by-need as before.

A "no" at step 0 is a clean **defer**, not a rejection: the content stays
true, the brief stays on disk, and nothing is lost by waiting. A "yes"
makes this the most concretely useful of the three briefs written today,
because the time-intelligence half is a lookup table you cannot reason
your way to.

Do not skip to step 1 on the strength of the docs being interesting.

**Answered 2026-09-03 01:40: no — defer.** The evidence was re-measured
that day rather than taken from the 2026-09-02 line above: no `*.Plan`
folder in any of the four work repos, and the payload's only mention of
Plan was, *at that hour*, the clause in `fabric-ontology`'s
`when_to_use` disambiguating that item **from** this one. That single
reference is worth reading correctly, because it is the *mirror
image* of the ontology case that justified wave 12: there,
`fabric-data-agent` promised a source the payload did not have, and the
inconsistency pulled the work in. Here the one internal mention exists to
push work **away** from Plan. It is evidence against, not a loose thread.

**Re-answered the same day, later: still no.** The queue row says to
re-run step 0 rather than trust it, so it was re-run rather than read
off. Repo side is unchanged and was measured wider than before — a
full-depth `find` for `*.Plan` across every work repo (worktrees
included) returns **zero**, against a live suffix inventory of
`DataPipeline`, `Eventhouse`, `EventSchemaSet`, `Eventstream`,
`KQLDashboard`, `KQLQueryset`, `Lakehouse`, `Notebook`,
`OperationsAgent`, `Report`, `SemanticModel`, `VariableLibrary` and
`Warehouse`. Payload side is what moved, and the step 0 paragraph above
now carries the correction: the mention count went 1 → 6, and all five
new ones are the audit skill's carve-out fixtures. **A count is not a
direction** — that is the whole lesson of this re-run, and it is why the
step 0 grep is now a trap rather than a measurement. Every one of the new
hits argues the same way the old one did.

Steps 1 and 2 were then **unexecuted** — no suffix was guessed, no
glob was written, and no skill was drafted. **Step 3 is the exception**:
its `fabric-semantic-model-audit` carve-out was split off and landed the
same day, because it was never gated on step 0. See that step for why.

**Answered 2026-09-30: yes.** A client sample repo on this machine, the
Git side of a Fabric workspace that the user started that day partly to
give this brief a real item, holds one `*.Plan` folder with all three
sheet kinds: seven PowerTable sheets made from the portal's sample
dataset (AdventureWorks tables written into a Fabric SQL database in the
same workspace), one planning sheet over a Direct Lake on OneLake
semantic model built on those tables plus a date table, and one
intelligence sheet (`sheetType: REPORTING`) embedding the planning
sheet's visual. Measured by the session that built it, and re-measured
by the triage that folded this in: one `*.Plan/.platform` on the
machine, typed `Plan`. **Both halves have since been run on it**, by
the same session later that evening, in a note folded here on
2026-10-01: a planning grid with date fields on columns and a measure,
a month member spelled `Sept`, Extend Time and a data-input measure.
What they showed is under § Half B, § The item itself and § Not drilled.

## The gap, if step 0 says yes

**Plan is a Git-supported item.**
[Git integration → Supported items](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration#supported-items)
lists **Plan** under "IQ (preview) items", next to Ontology. So it
serialises into a Git-synced repo and is a candidate for a `paths:`-scoped
skill on the same footing as every other item type in the payload.

Nothing in the payload globs the **item**, and nothing fixtures it. It is
mentioned — six times as of 2026-09-03, per step 0 — but every mention is
either a disambiguation clause or a carve-out fixture built from a
planning *semantic model*, which is a `.SemanticModel` folder and not a
Plan item at all.

## Step 1 — verify the folder suffix

**Resolved 2026-09-30: the suffix is `.Plan`.** The real item's
`.platform` reads `"metadata": {"type": "Plan"}`, and its folder is
`{displayName}.Plan/`, the `{display name}.{type}` form that the
[Plan definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/plan-definition)
page and wave 12's ontology precedent both give. The glob, in
`fabric-ontology`'s form:

```yaml
paths:
  - "**/*.Plan/**"
```

The hazard this step was written for cannot fire: a work semantic
model's table named `Plan` is a file, `tables/Plan.tmdl`, and the glob
needs a directory ending `.Plan`. Run `-StaticOnly` anyway. A Plan also
auto-creates a separate item, `__fabric_plan_sys.SQLDatabase/`, which
the glob does not match, and should not (§ Step 3).

## Step 2 — the content, and whether it is one skill or two

The two halves are different *kinds* of thing, and that is the structural
decision.

### Half A — planning model patterns (a pattern catalogue)

The doc's own framing: conventional models let the **fact table** decide
which rows appear, which works for reporting and breaks for planning,
because planning must represent futures that have no transactions yet —
a product launch, a new territory, a discontinued line that should stop
appearing.

The replacement is to state row existence as data:

- **Dimension tables** carrying parent keys, so valid combinations derive
  from the model.
- **Validity tables** with an `IsValid` flag, for combinations that
  relationships cannot settle.
- **Scenario as a dimension** — `ScenarioKey`, `IsForecast`, `OpenFrom`,
  `OpenUntil` — replacing per-scenario measure sets. The doc's own
  arithmetic: 10 measures × 4 scenarios = 40 measures, and a fifth
  scenario makes 50.
- **Date tables spanning the planning horizon**, not the transaction
  history, with fiscal fields for 4-4-5 / 4-5-4 / 5-4-4 patterns. Such a
  table is often longer than its fact, and Direct Lake modelling picks a
  relationship's many side by row count, so it comes out reversed: seen
  on the sample item on 2026-09-30, and now a rule in `fabric-tmdl`
  § Direct Lake Configuration, which half A cites. Its symptom was the
  fact's grand total repeated on every year, with no error. A horizon
  table is necessary, not sufficient: the grid shows periods only where
  the measure has data, and future columns come from **Extend Time**
  (needs a data-input measure and no forecasts) or a forecast measure
  (Learn's Extend Time and P&L forecast pages, read by the note's session
  2026-09-30).
- **Weight matrices** brought in through **Blend** as a measure rather
  than a relationship.
- **PowerTable** as the maintenance surface, so business users change
  planning windows and valid combinations without touching the model.

Ten named cases in four groups (managed combinations, editability,
history-derived rows, time-varying validity), with a companion
[sample .pbix](https://github.com/microsoft/fabric-samples/blob/main/docs-samples/iq/plan/semantic-modeling-sample.pbix).

One architectural constraint worth surfacing to `SKILL.md` rather than
burying: the approach is **built and validated on Direct Lake over
OneLake**, and PowerTable depends on the planning data existing as
OneLake tables in the first place. That is a prerequisite, not a
preference. Against it, the
[planning connection page](https://learn.microsoft.com/fabric/iq/plan/planning-how-to-create-semantic-model-connection)
rates Import "Supported fully" and Direct Lake "Supported with
limitations" (fixed credentials, no SSO), as read by the note's session
on 2026-09-30 and not re-read here; the sample item's Direct Lake on
OneLake model connected without complaint. Settle the two before the
draft calls either a prerequisite.

### Half B — automatic time-intelligence detection (a format reference)

Mechanical and unguessable, which is exactly what a skill is for:

- **Detection precedence**: explicit mapping → field name → field values.
- **Field-name keywords**: Year, Yr, Half Year, Half, Quarter, Qtr,
  Month, Week, Day.
- **Accepted formats per level**, including `FY 2025` / `FY25`, `Qtr_1`,
  `Week 53`, ISO days only (`2025-02-01`).
- **Rejected, silently** — the member is dropped from the hierarchy:
  `Sept` (only `Sep` or `September`), `WK1` (use `W1`), `First Half`
  (use `H1`), `Q5`, `Week 54`, `2025-2026` and any range, `01/02/2025`,
  `Feb 1, 2025`, and mixed formats within one level.
- **On the sample item, observed 2026-09-30.** The level verdict is in
  the planning visual's `properties.json`,
  `visualState.columnDimensions[].isTimeDimension` and
  `.timeIntervalUnit` (`null` on row fields), and a text month column
  with no `sortByColumn` was recognised by its field name alone. With
  one member spelled `Sept` and column subtotals **off**, the member
  dropped silently: no Q3, no column, the visible columns adding to 547
  against the model's 554. Filtered to that quarter alone, `Sept`
  appeared as plain text. Column subtotals **on**
  (`totals_config.column_sub_total: "Right"`) bypassed parsing: `Sept`
  counted under Q3, and the months fell into the model's alphabetical
  order. So one sheet shows different numbers by a totals toggle. Under
  Extend Time, Plan generates its own period labels (`Sep`), so the
  model's `Sept` actual never lands in Plan's `Sep` period: a forecast
  beside a missing actual, no error. Fix labels at the source, and give
  every text month column a `sortByColumn`. Untested: time-intelligence
  calculations on such a level.
- **14 valid hierarchy orderings enumerated**, and five invalid ones
  (`Quarter → Year`, `Day → Month`, `Week → Month`, …).
- The sharpest gotcha: **a Day level directly under Quarter or Half Year
  — with no Month between — counts days from the start of that parent
  period.** Wrong numbers, no error.

**Recommendation: one skill, with half B in `references/`.** They share a
trigger (you are building a Plan model), and half B is a lookup consulted
mid-task rather than read through — which is precisely the
`references/` contract. Splitting them would create two skills that
always fire together, and the queue has already settled that permanent
co-firing is not an argument for merging *or* for splitting (wave 4,
workstream C) — but it does mean the split would buy nothing.

**Updated 2026-09-30:** the item's own content, below, is what a
`paths:` glob on `*.Plan/**` fires on, so it goes in `SKILL.md`. Halves A
and B serve someone building the planning model, and both fit
`references/`. Weigh that against the body cap.

### The item itself, measured 2026-09-30

Evidence is a session's portal commits in the client sample repo, all on
2026-09-30, labelled observed where seen and inferred where reasoned.
What the triage that folded this in re-measured the same evening is
marked so. Documented means the
[Plan definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/plan-definition)
page, read 2026-09-30, which gives every part as `InlineBase64` JSON.

| Part | The page says | Observed |
| --- | --- | --- |
| `.platform`, `definition.json`, `planProperties.json` | required | present |
| `connectedPlanning/infobridge.json` | optional, required with Connected Planning | present and empty from the first commit, with Connected Planning unused |
| `cube/cube.json` | optional, required with cube writeback | appeared with the first planning sheet, every array empty, no writeback configured; `definition.json` also keeps an inline `cube` object the page omits |
| `sheets/{sheetId}/sheet.json` | required | on 6 of 9 sheets, absent on PowerTable sheets never configured (re-measured) |
| `sheets/{sheetId}/commentSettings.json` | required for PLANNING and POWERTABLE | on the PLANNING and REPORTING sheets, and on 0 of 7 PowerTable sheets, which keep their comment settings in `sourceSettings.json` (re-measured). Inferred: the page means REPORTING |
| PowerTable visual: `columnConfigs.json`, `properties.json`, `source.json`, `sourceSettings.json` | required | on all 7 (re-measured) |
| PowerTable visual: `approvals.json`, `automations.json`, `forms.json` | optional | absent, none configured |
| Planning visual: `dataInput.json` | required | present once a measure is on the grid, no input column needed: one entry per measure, `measureGuid` a numeric string, `dataInputType: 6`, `measure_role: "ACMeasure"`, and `sidecarHydration*` fields of unknown use (observed 2026-09-30; absent before any measure) |
| Intelligence visual: `properties.json` | required | not applicable: the intelligence sheet has no `visuals/` folder (re-measured) |

Layout a script trips on:

- **`{sheetId}` is the sheet's `recordGuid`** in `definition.json`,
  lowercase (documented; re-measured).
- **Visual folder case follows the visual type.** The 7 PowerTable
  visual folders are uppercase while `definition.json` lists their ids
  lowercase, and the planning visual's folder is lowercase
  (re-measured). A path joined from `definition.json` misses every
  PowerTable visual on a case-sensitive filesystem.
- **An embedded visual is stored once, under its home sheet.** The
  intelligence sheet's only visual entry reuses the planning visual's id
  with `"isEmbedded": true` (re-measured), and nothing under the
  intelligence sheet's folder refers to it: its `visualGroupMap` and
  `sourceVisualsMeta` are empty.
- **A PowerTable sheet stays bare until first configured**: no
  `sheet.json`, a `properties.json` of `{"properties": {}}`, and only
  the SCD and COMMENT_SETTINGS settings. The sample made three full
  sheets and four bare ones with no edit by the user. One edit to a bare
  sheet, a column's display name and description, filled it out: a
  `sheet.json`, a `properties.json` of 341 leaves, a `dbMeta` block on
  every column, and the ROW_ADD, ROW_UPDATE and ROW_DELETE settings.
  Bare means never configured, not broken.
- `definition.json` stores no sheet order; the array order is the
  display order (inferred).

**Portal commits rewrite what nobody edited**, so a line diff of a Plan
commit is unreadable: one rename plus one sheet viewed came to 913 added
lines (observed; not re-measured). The churn:

- `source.json`: `meta.lastRowCountUpdatedAt`, in Unix seconds, and
  `meta.totalRows`, one table's going from 0 rows to 547;
- `properties.json`: `properties.properties.visualState` gaining ~90–120
  style and theme defaults (`gridStyles`, `globalStyles`, `themeColors`,
  `pagination`), plus `reportMode: "EDIT"` and `locale: "en-US"`, the
  locale presumably the editing user's, so two users in different
  locales would flip it (inferred);
- `sheet.json`: `commentary.activeBookmarkId` appearing and
  disappearing;
- `planProperties.json`: a numeric key added to `theme.appliedThemes`
  when sheets were added, its meaning unknown.

The skill should name these paths, so a reader filters them first and
diffs the JSON structurally to find the intent.

**The portal's own output fails four of its published schemas.** The
item declares 11 Plan schemas plus `.platform`'s, all under
`https://developer.microsoft.com/json-schemas/fabric/item/plan/definition/`
at `1.0.0`: draft-07, with `$ref`s to the shared
`common/connectionReference` and `common/itemReference`, all resolvable
on 2026-09-30. Validated each against its own `$schema`, refs fetched
live, 38 of 42 files pass (re-measured: the same 38 and the same four
failures), and none of the four was edited by hand. Re-run twice later
that evening on the grown item, 39 of 43 passed, the same four failing
and `dataInput.json` and the planning `properties.json` passing:

| File | Fails because |
| --- | --- |
| `connectedPlanning/infobridge.json` | `sources: []` breaks `minItems: 1`, so the portal writes a file its own schema rejects |
| `planProperties.json` | `theme.appliedThemes` is not allowed by the schema's `theme`, which sets `additionalProperties: false` |
| the intelligence sheet's `sheet.json` | `canvasStyle.background` lacks the required `fillMode`, which the other sheets carry |
| the intelligence sheet's `commentSettings.json` | its indicator, `{type: "user", color, pixel}`, needs `position` and may not carry `color`; the planning sheet's `arrow` variant passes, so the schema models one variant |

So a CI step validating Fabric definitions against their published
schemas fails an untouched Plan, the more so as sheet kinds are added.
Whether Update Item accepts these files back is untested (inferred yes,
since the service wrote them).

**Casing.** The portal writes PascalCase schema paths (`Definition`,
`PowerTable/Source`), except `cube`, and each schema that pins its
`$schema` does so with a PascalCase `const` (re-measured). Learn's "Must
be" URLs are camelCase, bar one (`Planning/ModelTemplate`). The host
serves either spelling, but a strict string compare against the page
fails: the page is wrong, the portal right.

**What each part points at** (observed by the note's session unless
marked):

- **PowerTable to table**, `source.json`. The page documents a portable
  form: a `connection` id, a `database` workspace-and-item pair, each
  optionally a Variable Library reference, a `schema` and a `tableName`.
  All 7 visuals use the legacy form instead, everything inside a
  `source` object: the connection id, the SQL endpoint host, a database
  name carrying the item GUID, schema, table, table type, creation mode
  and null variable fields, plus a `meta` block of connection, database
  and workspace names and ids and the churning row count. The schema
  allows both forms.
- **Plan to app database**, `definition.json`'s `appDBconnection`: a
  connection GUID, the same one every PowerTable uses — the tutorial's
  "Set up connection", once per Plan. On no Learn page (the key's
  presence re-measured).
- **Plan to semantic model**, `semanticModelReference`: the legacy form
  again — model and workspace ids and names, a separate cloud connection
  to the model, `sourceType: "WORKLOAD"` — plus four fields the page
  omits: an integer `artifactId` (Power BI's internal id),
  `datasetRelations`, a `recordGuid` and an `app.powerbi.com` URL. Its
  `directLakeMode` and `directQueryMode` both read `false` over a Direct
  Lake on OneLake model, so don't read them as the storage mode
  (inferred). The page marks the reference required; the schema does
  not, and a Plan with no planning sheet omits it.
- **Planning visual to model fields**, the planning `properties.json`:
  bound by name, as `Table[column]` in
  `visualState.columnDimensions[].externalKey`, each field carrying
  `isTimeDimension` and `timeIntervalUnit`, where time detection records
  its level verdict (observed 2026-09-30). Whether members parsed is not
  in git, only on screen; git records the switch that decides it,
  `totals_config.column_sub_total` (§ Half B). Measures bind by name too,
  `Table[measure]` with `columnType: "Measure"`, here from an Import-mode
  measures table inside the Direct Lake on OneLake model, which Plan read
  without complaint. Every grid field also gets a filter-pane entry in
  `properties.superFilterAssignments`; a swapped-in field's entry is
  appended last, below the measure's, out of view until scrolled. A
  filter left in the pane is saved in the definition and hides periods
  that arrive later, from Extend Time for one. Plan applies its own
  number format: `formatString: 0` shows as `184.00`.
- **Intelligence sheet to planning visual**: by `visualId` with
  `isEmbedded`, in `definition.json` only (re-measured).
- **The system database**, `__fabric_plan_sys.SQLDatabase`:
  auto-created to store plan metadata (Learn's prerequisites page), its
  `.platform` description opening `DoNotEdit` (re-measured). It holds
  one SQL schema per Plan, named for the Plan's item GUID (the Plan's
  `logicalId` is that GUID reordered), with tables for PowerTable
  approvals, audit, automations, writeback, cube jobs and InfoBridge
  queries, and a `Security/` folder of one file per principal. The schema
  name was confirmed in the portal (2026-10-01). Building a planning grid
  adds a table, `visual_di_<originEntityId>_<hash>`, with one
  `NVARCHAR(255)` `dim_<table><column>` column per grid field and
  `DECIMAL(30,10)` `measure_N` columns; a new field layout adds a new
  table, the old one stays, and a layout seen before maps back to its
  own (observed 2026-09-30). Typing a value adds
  `visual_audit_<n>_<hash>`, logging each edit with the editor's UPN:
  personal data, in rows, not in git. Source control listed that DDL only
  after the database was opened in the portal, 3 h 22 min after the
  change behind it (once, 2026-10-01), so open it before committing a
  Plan change. Where typed values live across layouts is still open.
  **Don't query it**: Learn reserves it "strictly for system operations
  and app storage" and sends readers to the writeback destination
  ([persist data](https://learn.microsoft.com/fabric/iq/plan/planning-writeback/planning-how-to-persist-data),
  read 2026-10-01). Learn its shape from its SQL project in git.

**For deployment** (inferred): only the planning visual's by-name
binding survives a move to another workspace unchanged. The PowerTable
sources and the model reference need rewriting, for example by
`fabric-cicd`'s `find_replace`; the system database's schema name is
workspace-specific by construction; and the portable forms the page
describes would avoid most of this, but the portal writes neither. **No
tool applies such a rewrite yet**: `fabric-cicd`'s `ItemType` enum, on
`main` and in v1.3.0, the copy `fab` 1.7.0 bundles, has `Ontology` and no
`Plan`, and `fab` has neither IQ type (observed in source, 2026-10-01),
while deployment pipelines and Git integration list Plan (preview). A
deployment makes its own system database (Known limitations, read
2026-10-01), so that folder in git is a record to read, not to deploy
(inferred). The same page names two renames that break a Plan: its
workspace (the item no longer opens) and its semantic model (the
connection breaks).

**Extend Time and a data-input measure, run 2026-09-30.** The data-input
measure is a second `dataInput.json` entry under
`measure_type.DataInput`: `allow_input: "ReadAndEdit"`,
`bound_to_filter_context: true`, `distribute_parent_value_to_children:
true` (top-down allocation, which split values evenly, not by actuals),
and an `on_change_formula` naming its source measure by numeric
`measureGuid` (`M_<id>`), not by name. The ids looked deterministic: a
field re-added got the same `columnDimensions[].id` (inferred: a hash of
the field key). Extend Time is `visualState.extend_time: {start_date,
end_date}`, ISO dates, in the planning `properties.json`. Typed values
survived swapping a column field, in a commit that touched only
`properties.json`. More view state joins the churn list:
`visualState.totals_config` (a user setting), `toolbar.*`, `tableState.*`,
`columnExpandCollapse`, `embeddedSuperFilter`, `layout.layout_type`,
`ruler`, and default `aggregation_config` and `ragged_hierarchy_config`
blocks.

### Not drilled

The definition format is drilled now, above. Still not:

- the Plan overview, the PowerTable and Blend how-tos, and the remaining
  `plan/resources/best-practices/` pages;
- on the item: InfoBridge / Connected Planning sources, writeback,
  scenarios, insert rows, model templates, Forecast, a populated cube,
  PowerTable approvals, automations and forms, and native intelligence
  visuals, none of which the sample uses;
- time-intelligence calculations (YTD, prior period) on a level whose
  members don't all parse;
- where typed values are stored across field layouts, which git alone
  can't settle.

The time-intelligence page still matched half B's tables on 2026-09-30,
as read by the note's session.

## Step 3 — overlap

Lighter than the other two briefs, but not nil:

- **`coding-tmdl.md`** and **`fabric-tmdl`** both glob `**/*.tmdl` and
  will co-load with anything touching the planning semantic model. Half
  A's date-table and dimension guidance must not restate their
  conventions — cite and move on.
- [`fabric-semantic-model-audit`](../../../skills/fabric/fabric-semantic-model-audit/SKILL.md)
  — now shipped — needs to know that a *planning* model is legitimately
  shaped differently from a reporting one. **Done 2026-09-03, and no
  longer this brief's work**: its "what an audit must not flag" section
  now excludes planning models, and check 1 in `references/REFERENCE.md`
  carries the pointer at the point of use. This step was the one hard
  dependency between the two and it is **discharged**, deliberately ahead
  of step 0's defer, because it turned out not to be gated on anything
  here — it needed the documented shape of a planning model, not a folder
  suffix or a Plan item. What the guard has not had is a real planning
  model to be tested against; that limitation is recorded in the audit
  skill's own §9 rather than here. A real Plan's model now sits in the
  client sample repo, but on 2026-09-30 it was a small plain star, with
  no validity table and no Scenario dimension, so it does not yet test
  the guard.
- **`fabric-database`** globs `**/*.SQLDatabase/**/*.sql`, so it fires
  on the Plan's system database. **Landed 2026-09-30**: its
  *Fabric-Specific Context* tells it to stand down there. The Plan skill
  says the same from its side.
- **`fabric-tmdl`** carries, **since 2026-09-30**, the row-count rule
  that reversed the sample's date relationship: web modelling put the
  date table, longer than the fact, on the many side (observed
  2026-09-30, fixed by hand that evening). Since 2026-10-01 it also names
  the symptom, the fact's total on every date member with no error. Half
  A cites both.
- **`fabric-ontology`**'s `when_to_use` ends "the item is not the Fabric
  IQ Plan item": point that clause at this skill once it exists.

## Validation, if it proceeds

- Fixture + `expected_activations.md` rows +
  `./scripts/test-activation.ps1 -Set fabric`, `-StaticOnly` first, no
  longer blocked now that step 1 is resolved. A glob test needs paths
  only, so a synthetic `Fixture.Plan/` does: `definition.json`,
  `.platform`, one `sheets/<guid>/visuals/<GUID>/` PowerTable set with an
  uppercase folder, and one lowercase planning visual. The real item's 43
  files are LF and carry workspace, item, connection and database
  identifiers, so genericize anything taken from them.
- Real-use validation is still the weak point, and the skill says so: a
  real item now backs the serialization content, but the modelling and
  time-label content has only Microsoft's sample `.pbix` until halves A
  and B are exercised on the sample item.
- Preview churn is high — a preview workload inside a preview product.
  Date every claim and register the Plan doc set with `/drift-audit` in
  the same pass.
- Body cap ~2,700–3,100 tokens; half B goes to `references/` per step 2.
- Lint, `pre-commit run --all-files`, `/commit`.

## If the answer turns out to be no

Most likely outcome, and it is a **defer** rather than a decline — so
this is the one brief of the three that should *not* be deleted on a
"no". Record the step 0 answer and the date in this brief, leave it
`deferred` with its `reopen-when`, and revisit when a Plan item appears.
Delete it only if the
workload is abandoned upstream or the user rules it out outright, and
record which of those it was.

It *was* the outcome, on 2026-09-03, and this procedure is what was
followed — so treat this section as the standing instruction for the
**next** answer, not as an open question. It stays in the conditional on
purpose: step 0 can be asked again, and a later "yes" does not make these
paragraphs stale.

## Re-measure before acting

- A `*.Plan/.platform` search across the repos on this machine: one, in
  a client sample repo, on 2026-09-30.
- In that repo,
  `git log --format='%h %ad %s' --date=iso -- '*.Plan/*' '*.SemanticModel/*'`:
  on 2026-09-30 the item was last committed at 20:09, the model's date
  relationship fixed at 20:38 and measures added at 20:43; the
  planning-sheet probes ran to 22:48, and the system database's DDL was
  committed at 02:10 on 2026-10-01.
- `grep -n "fabric_plan_sys" skills/fabric/fabric-database/SKILL.md` and
  `grep -n "more rows" skills/fabric/fabric-tmdl/SKILL.md`: the two
  overlap edits, landed 2026-09-30.
- The Plan definition page, before the draft calls a part required or
  optional.
