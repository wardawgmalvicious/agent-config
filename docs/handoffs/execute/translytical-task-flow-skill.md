---
status: deferred
priority: 3
needs: []
blocked-by: []
reopen-when: the sandbox report probe has captured a data function button's PBIR, with slicer, field and measure bindings
written: 2026-10-01
---

# Handoff: translytical task flows may need a skill of their own

- **Written**: 2026-10-01, from an inbox note of 2026-10-01 by a session
  in a client Fabric Git-sync sandbox repo, which proposed it at the
  user's suggestion. Re-measured against the payload at `4f473d2`: no
  `translytical`, `DataFunction` or `visualLink` hit under `skills/`.
- **Kind**: a decision, then `/author-skill`. Deferred until the probe
  below has run, since the button's serialization is the part nothing
  here has seen.

## Why a second skill

Requests for write-back from a report rarely name a UDF, and the
[UDF skill](fabric-user-data-functions-skill.md)'s description is
already crowded by disambiguating Spark and DAX UDFs. The pattern spans
four items: the function, the data store, the semantic model (storage
mode decides when a write shows) and the report's button and slicers. It
has its own docs: the overview, the button page, two tutorials, the
in-report alerts pattern, and the SQL database and Cosmos DB task-flow
pages. The UDF skill keeps the function's contract for Power BI: a `str`
return, `UserThrownError`, Execute permission, the invocation context.
This one takes the report side.

## What is known

- **The button pins its function** (documented, translytical overview,
  confirmed 2026-10-01): it stores a workspace, function set and data
  function, and stays pinned after a deploy or move. Landed in
  `fabric-deployment-pipelines` § Limits on 2026-10-01.
- **Power BI lists only functions that return `str`**, shows the string,
  and shows "Something went wrong" on failure; Desktop can't trigger the
  action until published; a defaulted parameter may stay unmapped
  (documented, search excerpts, 2026-09-30).
- **GA since March 2026** (Desktop 2.152.882.0), with optional
  parameters and numeric input slicers from May 2026 (search excerpts);
  the buttons page's "preview" sentence is stale.
- **One open tension**: the buttons page says an action can't take a
  numeric measure as a field's value, while the data function button
  page offers a `SELECTEDVALUE` measure for passing an id.
- **Upstream's PBIR shape**, documented in `microsoft/skills-for-fabric`
  `skills/powerbi-report-cli/references/authoring/button-part-02.md`
  (commit `6c11ad5`, read 2026-09-30) and never observed here: a
  `visualLink` of `type: 'DataFunction'`, a `dataFunction` object of
  `kind: "ItemLocation"` whose `byReference` holds the UDF's `itemId` and
  `workspaceId` as literal GUIDs, and `metadata.dataFunction` caching the
  function name, `autoRefresh` and a `parameters[]` copy with each
  binding (`type: "SlicerParameter"`). Field and measure bindings take
  another `type` upstream doesn't show; a missing reference validates
  and leaves the button disabled at runtime.

**Corrected at triage**: the note expected a re-sync of the vendored
`powerbi-report-authoring` to bring that reference in. The reference
lives in upstream's `powerbi-report-cli`, not in the vendored pair
(`powerbi-report-authoring`, `powerbi-report-design`, vendored at
`v0.3.13`), so a re-sync would not. Whether `powerbi-report-cli` is a
rename of the vendored skill wasn't checked; the `skills-for-fabric`
drift source would settle it.

## The probe this waits on

In the sandbox workspace: a write function on the UDF item, a table for
it in the SQL database, that table in the Direct Lake model, and a
report button. It should capture the button's PBIR with slicer, field and
measure bindings, test the measure tension, time how soon a write shows
through Direct Lake on OneLake (a row reached the database's OneLake
replica in 17 s once, 2026-10-01), show what the report does with a
`UserThrownError`, and show whose identity `executing_user` carries when
a report calls.

## Where it lands

A new `skills/fabric/` or `skills/powerbi/` skill, the group being part
of the decision, or a reference beside the vendored report skill if
upstream's file is vendored instead.

## Not checked

The data function button page and both tutorials beyond search
excerpts; whether upstream's `powerbi-report-cli` is vendorable as is.

## Re-measure before acting

- `grep -rni "translytical\|DataFunction" skills/`: nothing on
  2026-10-01 but the deployment-pipelines row and the UDF brief.
- `list_commits` on upstream `skills/powerbi-report-cli` and the vendored
  pair's paths, per the drift registry's vendored-files procedure.
