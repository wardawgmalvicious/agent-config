---
name: fabric-semantic-model-audit
description: "Audit an existing Power BI or Fabric semantic model and report on its shape, relationship health, memory cost and downstream readiness — a review of a finished model, not authoring guidance. Use when asked to audit, review, assess or health-check a semantic model, to judge whether one is a real star schema, to explain why a model is slow or bloated, or to investigate inactive relationships, snowflake chains, role-playing dimensions, bidirectional filters, ambiguous filter paths, limited vs. regular relationships, or high-cardinality columns. Covers the three evidence tiers — TMDL on disk with no capacity, `INFO.VIEW.*` over executeQueries, and Best Practice Analyzer / Model Memory Analyzer via `sempy.fabric` in a Fabric notebook — and the storage-mode split that makes import-mode relationship guidance wrong for Direct Lake. For authoring TMDL use fabric-tmdl; for reviewing a diff use code-review; for scripting an open Desktop model use pbid-tom-live."
model: inherit
# effort: max   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Auditing a semantic model

A **review procedure over a finished model** — stand back from it and
report on what it is, not on the line you are typing. Everything else in
the payload that touches a semantic model is authoring guidance:
`fabric-tmdl` and `coding-tmdl.md` own conventions, `fabric-tmdl-api`
owns deployment, `code-review` reviews a diff. This owns the corpus.

The output is a set of **findings**, not a rewrite. Do not edit the model
unless asked separately.

## 1. Establish storage mode before anything else

This gates every memory claim you are about to make, and getting it wrong
is this skill's main way of producing a confidently wrong answer. Read
`mode:` on each table's partition in `definition/tables/*.tmdl`:

```
grep -rh "mode:" definition/tables/*.tmdl | sort | uniq -c
```

`import`, `directLake`, `directQuery` or `dual`. Mixed modes mean a
**composite model**, which in turn means source groups — and cross
source group relationships are *limited* (§5). Direct Lake has two
forms, **on OneLake** and **on SQL analytics endpoint**, and they differ
on nearly every limitation that matters to remediation; the connection
expression in `expressions.tmdl` tells you which.

State the storage mode in the finding report header. An audit that
prescribes an import-mode fix to a Direct Lake model is wrong even when
every individual sentence in it is true.

## 2. Three tiers of evidence

**Not a fallback chain.** Each tier answers questions the others cannot,
and you should say which tier a finding came from.

| Tier | Needs | What it gets you |
| --- | --- | --- |
| **TMDL on disk** — `definition/**` | nothing | Shape, relationships, declared cardinality, measure text, storage mode. Works offline and in CI. Most of §4 and §5 come from here. |
| **Live metadata** — `INFO.VIEW.*` via executeQueries | model admin + Build; tenant setting | The model *after* binding: real storage mode, calculated columns, measure `[State]`. |
| **Fabric notebook** — `sempy.fabric` | Fabric capacity, workspace contributor, **ReadWrite** on the model | Best Practice Analyzer (60+ rules, five categories) and Model Memory Analyzer. The only path to column-level memory and cardinality *for a Direct Lake model*. |

Start at the top tier. TMDL on disk answers the highest-value questions
in this skill and costs nothing.

**If a `scripts/data/dax.sh` wrapper is deployed in the repo**
(internal-tooling local-cli template), prefer it over raw curl for the second
tier — `dax.sh -s tables|columns|measures|relationships` are four canned
`INFO.VIEW` projections. It is an accelerator that happens to be present,
never a dependency: this skill loads at user scope in repos that have no
`scripts/data/`.

**For a local import model open in Power BI Desktop**, the VertiPaq DMVs
reach column-level memory with no capacity at all — that is
`pbid-tom-live`'s surface, not this one. It does not work for Direct Lake
models or thin reports.

## 3. The shape dimension

**Table type is not a property — it is inferred from relationships.**
Per the star-schema guidance, "the 'one' side is always a dimension table
while the 'many' side is always a fact table." So classify by walking
`relationships.tmdl`, never by name or by guessing from `Dim`/`Fact`
prefixes.

**The both-sides test.** A table that owns a `fromColumn` in one
relationship and a `toColumn` in another is acting as both fact and
dimension. That is a snowflake chain stated in the data rather than
inferred, and it is the single cheapest shape signal available offline.

### "Flatten" names two opposite operations

Both directions are documented, and confusing them is the classic error.

- **Snowflake → star: do it.** "Generally, the benefits of a single
  model table outweigh the benefits of multiple model tables." The four
  named costs of keeping the snowflake are more tables loaded (storage
  *and* performance), longer filter-propagation chains, a cluttered Data
  pane, and — the one people forget — **"it's not possible to create a
  hierarchy that comprises columns from more than one table."**
- **Star → one wide table: don't.** Listed as a defect in as many words:
  *"Not using star schema: Semantic models that use flat, denormalized
  tables or pivoted data structures make DAX less efficient and harder to
  write correctly… Unpivot wide tables into normalized structures."*
  Ontology generation compounds it — entity types derive from tables and
  relationship types from relationships, so one wide table generates one
  entity type with no relationships (see `fabric-ontology`).

### What an audit must not flag

These are sanctioned by the same guidance, and reporting them as defects
is a false positive:

- **Degenerate dimensions** — an order number on the fact table is
  explicitly "an exception to the formerly introduced rule that you
  shouldn't mix table types."
- **Junk dimensions** — deliberate consolidation of small attributes.
- **Disconnected tables** — legitimate for what-if parameters and
  user input.
- **Factless fact / bridging tables** — the *recommended* way to relate
  two dimensions many-to-many.

Carry the hedge, so the report does not read as dogma: "optimal model
design is part science and part art. Sometimes you can break with good
guidance when it makes sense to do so."

## 4. Relationship health

In roughly the order an audit can actually detect them.

**Inactive relationships with nothing that can activate them.** The
highest-value offline check in this skill, and it is two greps: count
`isActive: false` in `relationships.tmdl`, then count `USERELATIONSHIP`
across the tables. An inactive relationship with no `USERELATIONSHIP`
naming its columns is **unreachable by any calculation** — it cannot
affect a single query result, and it still costs (§5). Report the
unreachable subset, not the raw inactive count.

**Role-playing dimensions — count per (fact table, dimension table)
pair, never per dimension.** A date table on the to-side of four
relationships is not evidence of anything: four *different* fact tables
each with one active date relationship is a shared date dimension
working exactly as designed. The finding is when **one** table reaches
**one** dimension more than once. Counting inbound relationships per
dimension makes every correct shared date table look defective.

Where a genuine role-play exists, the documented default is to fix it,
not to keep it: "Generally, we recommend defining active relationships
whenever possible… **Using only active relationships means that
role-playing dimension tables should be duplicated in your model.**"
The cost is named and small — "duplication of the date dimension table
resulting in an increased model storage size… Because dimension tables
typically store fewer rows relative to fact tables, it's rarely a
concern." Inactive relationships plus `USERELATIONSHIP` remain
sanctioned when there is no need to filter by two roles at once and the
measures exist. **In Direct Lake the duplication fix is much harder —
see §6 before prescribing it.**

**Bidirectional cross-filtering.** "Can impact negatively on
performance" and can create ambiguous propagation paths. Where ambiguity
exists, Power BI resolves it by priority tier first and path weight
second, and returns an error when two paths tie — so a bidirectional
relationship added "to make it work" can break a different visual later.

**Regular vs. limited.** Not a settable property — **inferred** from
cardinality and source, which is exactly why humans miss it and an audit
should compute it. A relationship is *limited* when it is many-to-many
cardinality, or crosses source groups in a composite model. Limited
relationships get **no data structures built**, join with `INNER JOIN`
semantics, add **no blank virtual rows** for referential-integrity
violations, and break `RELATED`. The absence of blank rows is the sharp
end: violations silently vanish from results instead of showing as
(Blank).

**Cardinality declarations.** TMDL omits `fromCardinality` /
`toCardinality` at the default. Absent means default, not unknown — but
note that for Direct Lake, **web modeling issues no validation queries**
for cardinality or cross-filter selections; user selections are assumed
correct. A declared cardinality in a Direct Lake model may never have
been checked against data.

**One-to-one** — "likely represents a suboptimal model design because of
the storage of redundant data."

**`DateTime` relationship columns.** The engine only has `DateTime`;
`Date` is a formatting construct. A time component still counts, so keys
silently fail to match. Fix in Power Query, not the Modeling tab.

**Assume referential integrity** — DirectQuery only. When integrity is
actually compromised the `INNER JOIN` **silently understates** results.

The documented performance ordering, fastest to slowest: one-to-many
intra source group → many-to-many via an intermediary table with at
least one bi-directional relationship → many-to-many cardinality →
cross source group.

## 5. Memory and query cost — split by storage mode

**This is where the design and performance halves fuse, and where the
mechanism differs by mode.** Do not generalise either bullet to the
other.

- **Import.** Power BI "creates a data structure for each regular
  relationship at data refresh time," and — verbatim — **"Inactive
  relationships are also expanded, even when the relationship isn't used
  by a calculation."** So an unreachable inactive relationship is
  simultaneously a design finding and a refresh-cost finding. One
  finding, two dimensions; a skill split down the design/performance
  line would have to report it twice.
- **Direct Lake.** Join indexes are built **at query time**, not at
  refresh: "If the DAX query accesses columns from multiple tables,
  Direct Lake must build join indexes according to the table
  relationships." They are memory-resident and are evicted under memory
  pressure (the semiwarm state). **Whether inactive relationships get
  join indexes built is not documented** — say so rather than assuming
  the import behaviour transfers. The design finding stands regardless;
  the refresh-cost arithmetic does not.

Direct Lake performance is dominated by Delta-side factors rather than
by the model: V-Order compression, segment size (aim for 1–16 million
rows per row group), column cardinality, and destructive update patterns
that defeat incremental framing. Name these and point at the lakehouse;
they are not model edits.

**Column-level memory and cardinality** need `model_memory_analyzer()`
in a Fabric notebook (or the VertiPaq DMVs via `pbid-tom-live`, import
models only). Nothing in the offline tier reaches them — do not estimate.

## 6. Direct Lake constrains the remediations

Before prescribing a fix, check it is available in this storage mode.

- **Duplicating a role-playing dimension** runs into "adding multiple
  tables from the same data source table" being **unsupported in Power
  BI Desktop and web modeling** (XMLA external tools can, but **Edit
  tables** and **refresh** then error).
- **Calculated tables** are preview on Direct Lake on OneLake and
  **unsupported** on Direct Lake on SQL.
- **Calculated columns** on Direct Lake on OneLake are User Context
  only and unmaterialized — and "because they don't materialize, these
  calculated columns **can't be used in relationships**." So the
  calculated-column route to a surrogate key is closed.

The realistic Direct Lake remediation is usually upstream: add the role
table to the lakehouse and bind it, rather than duplicating it in the
model.

## 7. Downstream readiness

One pass per consumer, each deferring to the skill that owns it.

- **Reports** — the classic case: hidden helper measures, implicit
  measures, missing `formatString`, no descriptions.
- **AI instructions blob** — a different artifact from the model. Defer
  to `fabric-semantic-model-ai-instructions`.
- **Data agent** — the model-shape half only: non-descriptive names
  (`TR_AMT`, `DIM_GEO_01`), duplicate or overlapping measures, helper
  measures that should be excluded, implicit measures, ambiguous date
  fields, and hidden fields that break verified answers. Two governance
  points worth stating: **report-scoped measures are invisible to the
  agent** (move them into the model), and the DAX generation tool reads
  only model metadata and Prep-for-AI configuration — it **ignores
  data-agent-level instructions**, so model-specific guidance placed on
  the agent is silently dead. Defer agent configuration to
  `fabric-data-agent`.
- **Ontology** — carry only the model-shape consequences; the generation
  constraint matrix belongs to `fabric-ontology`. Cite it, don't restate
  it.

## 8. Reporting

Per finding: **what**, **the evidence** (a `file:line` or the query that
produced it), **which dimensions it belongs to**, **the remediation and
its stated cost**, and **which tier and storage mode it rests on**.
Separate what is measured from what is inferred. A finding whose
remediation is unavailable in this storage mode is not a finding yet.

## 9. Constraints and false negatives

- **`INFO.VIEW.*` blanks `[Expression]` for users without write
  permission.** A measures listing with empty formulas means read-only
  access, **not** an empty model. This is the single most likely way
  this skill produces a confidently wrong answer.
- **BPA and the memory analyzer need ReadWrite on the model** — they go
  through TOM, which is *stricter* than the `INFO.VIEW` read path and a
  different failure mode. `list_tables` / `read_table` go over XMLA and
  need XMLA read-only enabled, a third gate again.
- **Semantic link is Fabric-only** — "Use of semantic link is supported
  only in Microsoft Fabric." There is no local entry point, which is why
  the second tier is a REST wrapper and not SemPy.
- **Notebooks fail to run if the semantic model name ends with a
  whitespace.**
- **executeQueries limits**: one `EVALUATE` per call, 100,000 rows /
  15 MB, 120 requests per minute. A full metadata sweep is four calls,
  not one.
- **The notebook tier is documented, not exercised.** As of 2026-09-02
  nothing in §2's third row has been run from this machine — it cannot
  be, without a capacity. Treat its invocations as first-party
  documentation rather than as verified-in-practice.

Long detail — the check catalogue, the `INFO.VIEW` and `sempy.fabric`
invocations, the star-schema pattern vocabulary, and the Direct Lake
constraint table — is in
[references/REFERENCE.md](references/REFERENCE.md).
