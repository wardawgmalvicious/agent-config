# Handoff: rewrite the graph-refresh and capacity claims

- **Audit run**: 2026-10-06
- **Source**: `fabric-iq-ontology`
- **Window**: floor `2026-09-02` (diff base `f78e4a0e`, 2026-08-31) →
  head `135b0dc1` (2026-10-05)
- **Covers recommended actions**: 6
- **Kind**: doc lookup, then a partial rewrite of three claims about
  the ontology graph. The audit did not fetch the two pages that hold
  the answer, so apply only what they establish.
- **Target**: `skills/fabric/fabric-ontology/SKILL.md` (lines 28–34,
  123–125), `skills/fabric/fabric-ontology/references/REFERENCE.md`
  (line 239)

## The problem

`fabric-ontology` treats the ontology graph as always present:
provided by a child Graph item, refreshed by hand or on a schedule,
and the thing that shows up as capacity usage. The new overview says
graph execution is optional and opt-in, and calls the
always-materialized graph "the earlier framing". The two pages that
hold the new mechanics, `how-to-use-ontology-graph.md` and
`resources-capacity-usage.md`, were not fetched by the audit, so the
replacement text is not yet known.

## Evidence

`overview.md` at head `135b0dc1`, § "Optional graph execution", added
by `80a24c9` (2026-09-29):

> **Graph in Microsoft Fabric is an optional execution layer** for
> scenarios in which the relationship path itself is important, such
> as multihop traversal, dependency analysis, reachability, or
> shortest-path questions. Routine lookups, aggregations, metrics, and
> fresh time-series questions can continue to use their source
> systems.

> An ontology-derived schema graph doesn't load instance data by
> default. When you need graph execution, you can opt in to
> materializing the relevant data. This data materialization replaces
> the earlier framing that presented every ontology as having an
> automatically materialized instance graph.

The base overview said the opposite: "The *ontology graph* is a
queryable instance graph built from your data bindings and
relationship definitions, provided within ontology by Graph in
Microsoft Fabric", and "Each node or edge keeps data source lineage and
follows a scheduled data refresh."

`includes/refresh-graph-model.md`, base then head:

> Any updates in upstream data sources (like new rows) need to be
> manually refreshed before they're visible in the ontology item. For
> more information, see refresh the graph model
> (`../how-to-view-entity-type-details.md#refresh-the-graph-model`).

> To see updates from upstream data sources, such as new rows, you
> need to manually refresh the ontology item. For more information, see
> refresh the graph model
> (`../how-to-use-ontology-graph.md#refresh-the-graph-model`).

`resources-troubleshooting.md` at head still blames the child item's
schedule for the capacity error, now linking the new page:

```text
| The canvas and entity type list don't load and you see a message that *Your organization's Fabric compute capacity has exceeded its limits*. | Refreshes of ontology (preview)'s underlying [Graph in Microsoft Fabric](../../graph/overview.md) child item contribute to your capacity usage. If you set a graph refresh schedule and capacity usage becomes too high, reduce or disable the graph item schedule in your workspace. For more information, see [Refresh the graph model](how-to-use-ontology-graph.md#refresh-the-graph-model). |
```

**Not fetched by the audit:**

| Page at head | Bytes | In-window history |
| --- | --- | --- |
| `how-to-use-ontology-graph.md` | 14,293 | added by `80a24c9`, +168 |
| `resources-capacity-usage.md` | 9,992 | `80a24c9` +23/−60; `8e5fefb` "Expand ontology billing and capacity usage guidance" +103/−6; `1f0f572` +1/−1; `d8cbefe` +2/−2; `0ac0f42` +1/−1 |

## What to change

Fetch both pages first, with `microsoft_docs_fetch`:
https://learn.microsoft.com/fabric/iq/ontology/how-to-use-ontology-graph
and https://learn.microsoft.com/fabric/iq/ontology/resources-capacity-usage.
Then:

1. **`SKILL.md:28–30`**, "Not here, deliberately":

   > **Not here, deliberately.** The ontology graph is *provided by* [Graph in
   > Microsoft Fabric](https://learn.microsoft.com/fabric/graph/overview) — a
   > separate `GraphModel` item.

   Make the graph optional and opt-in, as the overview does. Keep the
   deferral to `fabric-graph` in lines 30–34.
2. **`SKILL.md:123–125`**:

   > - **Refresh is manual.** New rows upstream are invisible until the graph
   >   model is refreshed; a refresh *schedule* on the child Graph item is
   >   what shows up as capacity usage.

   The include still says refresh is manual, but now of "the ontology
   item". Restate what refresh applies to, and what costs capacity,
   from the two pages.
3. **`REFERENCE.md:239`**, §6:

   ```text
   | Canvas won't load, *capacity exceeded* | The child Graph item's refresh schedule. Reduce or disable it. |
   ```

   The troubleshooting page still says this. Keep it unless the
   capacity page contradicts it.

## Constraint on the fix

- Apply only what the two pages establish. Where a page does not
  settle a claim, leave the claim, add a dated note that the overview
  reframes the graph as optional, and name the page that was read.
- Out of scope: what opt-in materialization means for `fabric-graph`.
  The audit routed that to the user by hand rather than to an action,
  and `fabric/03` in `docs/audits/2026-10-06/fabric/` is rewriting
  that skill.

## Sequencing note

Run after brief 01. Brief 08 refreshes REFERENCE §8, whose undrilled
list names `resources-capacity-usage`; once this brief has run, 08
records that page as drilled.

## Verification

1. The execution log names both pages as fetched in the executing
   session.
2. `grep -n -i "graph item\|refresh\|capacity\|GraphModel" skills/fabric/fabric-ontology/SKILL.md skills/fabric/fabric-ontology/references/REFERENCE.md`
   — every hit agrees with the two pages or the overview.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-ontology/SKILL.md`
4. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against
`fabric-iq-ontology`, floor 2026-09-02. The overview, include and
troubleshooting quotes come from the on-disk diff at pinned SHAs. The
two pages in the table were listed with their sizes and commit stats,
but not fetched, which is why this brief starts with a lookup.

## Execution log

- **Executed**: 2026-10-07 — applied with deferrals
- **Session**: fresh
- **Files changed**: `skills/fabric/fabric-ontology/SKILL.md`
- **Verification**: step 1 — both pages were fetched live in this
  session (2026-10-07): `how-to-use-ontology-graph` and
  `resources-capacity-usage`, with the overview and, for brief 01's
  answer, `old-experience/overview` and
  `old-experience/resources-capacity-usage`. Step 2: every hit agrees
  with them, bar `REFERENCE.md` §8's undrilled list, which still names
  `resources-capacity-usage` and the old refresh page; brief 08 D-4
  rewrites §8 after this brief, per the sequencing note. Step 3: the
  frontmatter lints. Step 4, `pre-commit run --all-files`, runs once at
  the end of the pass.
- **Deferred**: an adjacent finding, not fixed here. The graph page's
  Limitations, in no section of the skill: an entity needs an entity
  type key to be projected, only lakehouse and mirrored-database delta
  tables project, entities bound to a semantic model or with several
  backing tables are ineligible, and Binary and Variant become String.
  The first qualifies brief 04's "An entity type key is optional".
- **Deviations**: item 3 left `REFERENCE.md` §6's capacity row as it
  was: the troubleshooting page, checked live, still says it, and the
  capacity page meters graph usage as the child item's, which agrees.
  Per brief 01's option 4, two dated legacy paragraphs were added, each
  sourced to the old-experience page that states it: the old graph is
  built automatically, and old capacity meters differently. The
  refresh bullet became two, refresh and capacity.
- **Needs**: a fresh session — an edit, by `/learn` or a brief, that
  adds the graph page's projection limitations to the skill and says
  graph projection needs the key the binding section calls optional.
- **Closed**: 2026-10-07 — by `/learn`, in the session that ran the
  pass: `fabric-ontology`'s constraints section gained a graph
  projection eligibility bullet, and its binding section now says a
  keyless entity type cannot be projected, both from the graph page
  fetched live that day.
