---
name: fabric-ontology
description: "Use for the Microsoft Fabric Ontology item (preview, Fabric IQ workload) — `<Name>.Ontology/` in a Git-synced repo, `.platform` type `Ontology`. Covers the definition layout (an empty `definition.json` envelope, `EntityTypes/{bigint-id}/definition.json` plus `DataBindings/{guid}.json`, `Documents`, `Overviews`, `ResourceLinks`, and `RelationshipTypes/{id}/` plus `Contextualizations`), generating an ontology from semantic models, and the old experience's Import / Direct Lake / DirectQuery matrix whose Direct Lake bindings fail silently when the lakehouse workspace has inbound public access disabled, the data-binding rules (one static binding per entity type but many time-series ones, secondary sources joined on a common column, optional string/integer keys, managed tables only, no delta column mapping), the `Decimal`-returns-null trap and its `Double` remedy, semantic enrichment, and consuming an ontology through its built-in agent, other agents or its MCP endpoint."
when_to_use: "Fires on any file under `*.Ontology/`. Owns the ontology item itself — its definition files, generation, data binding, enrichment. Defers graph mechanics and GQL to fabric-graph (ontology is built on that item), agent configuration to fabric-data-agent and fabric-operations-agent (ontology is one source among theirs), and semantic-model authoring to fabric-tmdl. Preview workload: claims here are dated, and the item is not the Fabric IQ Plan item."
paths:
  - "**/*.Ontology/**"
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Fabric Ontology (preview): the item, its definition, and its bindings

An **ontology** is Fabric IQ's shared business vocabulary: *entity types*
(`Customer`), *properties* (`email`), and *relationships*
(`Customer places Order`), bound to real OneLake data so agents and
people reason in the same terms.

**Item type name: `Ontology`** — the `metadata.type` written into
`.platform`, so a Git-synced workspace serializes it as
`<display name>.Ontology`. Git integration lists it under **"IQ (preview)
items"** alongside Plan — *not* under Data Science or Real-Time
Intelligence, which is where people look first.

Everything below is **preview**, verified against the docs on
**2026-09-02** unless a section gives a later date. Re-check before
relying on a limit; this surface moves.

**Not here, deliberately.** The ontology graph is *provided by* [Graph in
Microsoft Fabric](https://learn.microsoft.com/fabric/graph/overview) — a
separate `GraphModel` item — and is **optional and opt-in**: every
ontology has a schema graph, but its instance data is materialized only
when you opt in through **Manage graph** (`how-to-use-ontology-graph`,
checked 2026-10-07). GQL, graph-type DDL and `executeQuery` belong to
`fabric-graph`; this skill only carries the graph constraints that bite
at **ontology** time. Agent configuration belongs to `fabric-data-agent`
(conversational, ≤5 sources) and `fabric-operations-agent` (autonomous,
single-source) — ontology is one *source* for each of those.

**Old experience (legacy, retires 2027-01-31):** the graph is built
automatically, "a queryable instance graph built from your data bindings
and relationship definitions" that "follows a scheduled data refresh"
([old-experience overview](https://learn.microsoft.com/fabric/iq/ontology/old-experience/overview),
checked 2026-10-07).

## The Git definition layout

**Two formats, one per experience.** The **new ontology experience**, the
default for new items, writes its definition as **TMDL**: "flat,
item-folder-relative `.tmdl` text files plus the platform-owned
`.platform` metadata file" (Learn, checked 2026-10-06). The JSON layout
further down is the **old experience**'s, which retires on
**2027-01-31**. A folder holding `database.tmdl` is new; one holding a
root `definition.json` and `EntityTypes/` is old.

Because the new definition is TMDL, the item rides the ordinary
item-definition surface: **Git integration**, `getDefinition` /
`updateDefinition`, and **deployment pipelines** all carry these parts:

```
<Name>.Ontology/
  .platform                          # JSON; metadata.type = "Ontology", config.version = "2.0"
  database.tmdl                      # REQUIRED; compatibilityLevel 1000000
  model.tmdl                         # the tabular model and its `ref` statements
  tables/{name}.tmdl                 # a backing table: columns, a DirectLake partition, optional DAX measures
  metrics/{name}.tmdl                # one top-level metric per file
  relationships.tmdl                 # table-to-table (TOM) relationships
  expressions.tmdl                   # shared M expressions
  entities/{namespace}#{name}.tmdl   # ontology extension: an entity type and its properties
  entityRelationships.tmdl           # ontology extension: relationships between entity types
  namespaces/{namespace}.tmdl        # ontology extension; namespaces/default.tmdl is required
  rules/{rule}.tmdl                  # ontology extension: one rule per file
```

- **A two-part definition is valid on write.** Only `.platform` and
  `database.tmdl` must be sent: the service synthesizes `model.tmdl`
  (with `ref namespace default`) and `namespaces/default.tmdl` when they
  are omitted, so `getDefinition` returns at least four parts.
- **`entity`, `entityRelationship`, `rule` and `namespace` are
  ontology-only extensions** layered on the Analysis Services tabular
  model, so `tables/`, `relationships.tmdl` and `expressions.tmdl` read
  like a semantic model and the rest do not. An unqualified entity file
  such as `Sensor.tmdl` is in the default namespace.
- **Defaults are elided on read.** A property left at its default is
  accepted on write and omitted by `getDefinition`: absent means "at its
  default", not "unsupported".
- Property `dataType` is a primitive — `string`, `int64`, `double`,
  `dateTime`, `boolean` or **`decimal`** — or `Any`, `TimeSeries<T>`, or
  `complex`.

No ontology export exists on this machine, so this is Learn's layout,
not a measured one: write no TMDL the page does not show, and treat a
first local export as the ground truth.

### Old experience (legacy): the JSON layout

The old experience **retires on 2027-01-31**. The Fabric UI no longer
creates it, but the ontology APIs and CI/CD still can, so an existing
item, or one created that way, uses this layout until then. Migration is
the in-product **create a copy in the new experience**: a separate item,
so agents, dashboards and other consumers must be reconnected and rules
recreated.

Old-experience definitions are JSON. Only the first two are required:

```
<Name>.Ontology/
  .platform                              # metadata.type = "Ontology"
  definition.json                        # REQUIRED, and literally {}
  EntityTypes/{entityTypeId}/
    definition.json                      # the entity type
    DataBindings/{guid}.json             # one file per binding
    Documents/document{n}.json           # {displayText, url}
    Overviews/definition.json            # preview-page widgets
    ResourceLinks/definition.json        # links to a Power BI report
  RelationshipTypes/{relationshipTypeId}/
    definition.json                      # source/target entityTypeId
    Contextualizations/{guid}.json       # binds the relationship to a table
```

Three things about the IDs, all of which surprise people reading a diff:

- **`{entityTypeId}` is a positive 64-bit integer, not a GUID** — and it
  is a *directory name*. So is `{relationshipTypeId}`. GUID filenames
  appear one level down, for `DataBindings` and `Contextualizations`.
- **Property IDs are also bigints**, and bindings reference them by
  `targetPropertyId`. A binding file names *no* property names — only
  `sourceColumnName` → `targetPropertyId` — so a diff of a binding is
  unreadable without the entity type's `definition.json` open beside it.
- **`definition.json` at the root is an empty object.** Do not "fix" it.
  The content all lives in the subdirectories.

Property `valueType` is one of *String, Boolean, DateTime, Object,
BigInt, Double* (plus *Any* for untyped properties). **There is no
`Decimal` in this old enum** — see the trap below. Entity type and
property `name` must match `^[a-zA-Z][a-zA-Z0-9_-]{0,127}$`; note the
portal is stricter than the API here and caps custom property names at
**26** characters.

Part-by-part schemas for both formats, including every field of an
old-experience data binding and the Eventhouse variant, are in
[references/REFERENCE.md](references/REFERENCE.md).

## Generating an ontology from a semantic model

Generation creates the item, entity types from tables, properties and
their data bindings from columns, relationship types from model
relationships, and **metrics** from the model's DAX measures. The
overview adds calculated columns, and the source model stays "the owner
of the DAX expression" (both pages checked 2026-10-07). **What it does
not do** is bind time series data, review entity keys, bind
relationship types, or rename entity types and relationships to
friendly names — manual follow-ups, every time.

Generating, and querying the model through the ontology, needs both
**Read and Build** permissions on the semantic model, as binding one
does. You **cannot generate from `My workspace`** — move the semantic
model to a real workspace first (troubleshooting page, checked
2026-10-07). A second semantic model joins an existing ontology **only
through the ontology agent**, the built-in path under § "Consuming an
ontology".

**Old experience (legacy, retires 2027-01-31):** support depends
entirely on the **semantic model's storage mode**. This matrix and the
two paragraphs after it come from the old experience's generation page;
the new experience's (`how-to-generate-from-semantic-models`, checked
2026-10-07) carries no storage-mode matrix. The troubleshooting page,
checked the same day, still blames Import mode and disabled inbound
public access for a generated ontology with no data bindings, linking
that row to the old page, so whether the failure holds in the new
experience is unverified.

| | Import | Direct Lake | DirectQuery |
| --- | --- | --- | --- |
| Entity / property / relationship **definitions** | ✅ | ✅ | ✅ |
| Entity type **bindings to data** | ❌ | ✅ *conditional* | ❌ |
| Relationship type **bindings** | ❌ | ✅ *conditional* | ❌ |
| **Querying** through bindings | ❌ | ✅ (no measures or calculated columns) | ❌ |

**This is the failure worth knowing.** Direct Lake entity bindings work
*only* when the backing lakehouse sits in a workspace with **inbound
public access enabled**. When it does not, "the ontology item is created
successfully but that entity type has no data bindings." A green
checkmark and an empty ontology. Relationship bindings have their own
condition: they generate only where a **primary key is identified**.

So an Import-mode model generates a correct-looking *schema* and nothing
queryable, by design. Check the mode before blaming the data.

## The constraints that produce silent or confusing failures

- **Managed lakehouse tables only.** External tables that merely *appear*
  in a lakehouse are not supported, and the symptom is "entity type
  details shows no data" rather than an error at binding time.
- **OneLake security is enforced, not excluded.** Authoring and querying
  "respect access to bound data, including OneLake security" and
  source-enforced RLS, OLS and CLS (overview, checked 2026-10-07). The
  old rule that a lakehouse with OneLake security enabled cannot be a
  binding source was withdrawn in September 2026, and neither
  experience's binding page carries it.
- **No delta column mapping.** It is enabled *automatically* when column
  names contain `,` `;` `{}` `()` `\n` `\t` `=` **or a space**, and
  automatically on the delta tables backing **import-mode** semantic
  model tables. Symptom: the entity type details graph does not load.
- **Duplicate property names must share a type** across entity types. A
  string `ID` on one and an integer `ID` on another is what makes entity
  types go missing from a generated ontology.
- **Renaming a source table after binding breaks it.** Bindings carry
  `sourceTableName` as a string.
- **Upstream changes need a refresh.** A schema change re-ingests all
  bound data, but new, updated or deleted upstream rows leave a
  materialized graph stale until an ingestion runs: ask the ontology
  agent to update the entity type, or *Refresh now* (or schedule) the
  graph model in the workspace (`how-to-use-ontology-graph`, checked
  2026-10-07).
- **Graph projection has its own eligibility.** *Manage graph* marks an
  entity type *Ineligible* when it has no entity type key, no binding,
  more than one backing table, or data bound to a semantic model: only
  lakehouse and mirrored-database delta tables project. Binary and
  Variant properties project as String, and time-series ones as their
  base type (same page, checked 2026-10-07).
- **Three meters cost capacity** in the new experience: **Ontology
  Discovery**, 1,000 CU-seconds per definition read, one about every 20
  minutes included while the item is open, so close it when done; the
  child Graph and Eventhouse items' usage at their own rates, graph
  refreshes included; and dynamic **Ontology AI Reasoning** for the MCP
  server and the ontology agent (`resources-capacity-usage`, checked
  2026-10-07).

  **Old experience (legacy, retires 2027-01-31):** its own capacity
  page meters *Ontology Modeling* per definition-hour and AI by tokens,
  and counts graph refreshes too.

**Verify these at the lakehouse, not in TMDL.** A semantic model's TMDL
`dataType` is not the delta column type and the TMDL table name is not
the delta table name, so grepping TMDL for `decimal` or for spaced column
names produces false confidence in both directions. The check belongs on
the delta tables.

## The `Decimal` trap, and its remedy

Fabric Graph does not support `Decimal`. Generate an ontology from a
model whose tables carry `Decimal` columns and those properties return
**null on every query** — no error, just nulls. `Decimal` is the natural
money type, so this hits currency columns first.

The remedy is documented and specific: **recreate the property as
`Double` in the ontology and bind it to the source data.** That works
because *manual* binding accepts a lakehouse `decimal` column as a source
for a `double` property — the type map is wider than the generator's
output. Full source-to-property type table in
[references/REFERENCE.md](references/REFERENCE.md); the one other trap in
it is that lakehouse `decimal(p, s)` maps to **string**, not double.

## Binding data: the ordering and cardinality rules

From the binding page, checked 2026-10-07:

- **Seven source types bind**: eventhouse, KQL database, lakehouse,
  mirrored database, semantic model, SQL database and warehouse. Binding
  a **semantic model** needs both **Read and Build** permissions on it.
- **One static binding per entity type.** You cannot union static data
  from two sources into one entity type. The page's Limitations still
  say "You must use OneLake-backed sources for static data", beside a
  source list that includes semantic models, and do not reconcile the
  two.
- **Many time-series bindings per entity type**, from lakehouse *and*
  eventhouse sources together.
- **The first source is primary; each one added later is secondary**,
  related to the primary on a common column picked from each table. A
  column name present in both tables gets a **`_2`** suffix on the new
  source's default property name. The page no longer states the old
  static-first rule below, and does not say a time-series source can
  bind without a static one.
- **An entity type key is optional**, since the overview announces
  keyless entity types; when one is defined, its properties are
  `string` or `integer` only. A keyless entity type cannot be projected
  into a graph (see the constraints above).
- Time series data must be **columnar** — one row per timestamped
  observation.

**Old experience (legacy, retires 2027-01-31):** static data comes from
OneLake only and time series from OneLake or an eventhouse, bound in two
steps. **Static first**: a time-series binding needs an existing
statically bound property to contextualize against, and the static value
must **exactly match** a column in the time-series data. The key is set
while binding, with *Define entity type key*: one or more `string` or
`integer` columns, together unique
([old-experience binding page](https://learn.microsoft.com/fabric/iq/ontology/old-experience/how-to-bind-data),
checked 2026-10-07).

## Semantic enrichment is what makes agents work

Descriptions, synonyms, and key-value metadata on entity types and
properties. It is not decoration: Learn says it "improves agent answer
correctness, especially for prompts that depend on contextual
information like units of measurement, sensitivity levels, or business
definitions" (`how-to-add-metadata`, checked 2026-10-07).

Scope it honestly, because the docs do: enrichment helps the agent during
**schema exploration and reasoning**, and **query generation does not use
the metadata directly**. Only entity types support synonyms — properties
and relationship types get descriptions and key-value pairs only, and
keys must be unique within each object.

**Old experience (legacy, retires 2027-01-31):** "Data agent doesn't use
the semantic enrichment fields"
([old-experience enrichment page](https://learn.microsoft.com/fabric/iq/ontology/old-experience/how-to-add-semantic-enrichment),
checked 2026-10-07).

## Consuming an ontology

Six agent paths, detailed in [references/REFERENCE.md](references/REFERENCE.md):
the built-in **ontology agent**, a chat that authors as well as consumes,
Fabric **operations agent** (monitoring + actions), Fabric **data agent**
(conversational Q&A), **Foundry IQ** agent, **Copilot Studio** agent, and
**custom agents over the ontology MCP server**. One consumer is not an
agent: a **Real-Time Dashboard** takes an ontology as a data source
(preview), through *Add data source* → *Ontology*.

The MCP path is the one that matters outside Fabric: **an ontology is itself
an MCP server**, at

```
https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/<workspace-ID>/items/<ontology-item-ID>/ontologyEndpoint
```

Both IDs come out of the portal URL
(`.../groups/<workspace-ID>/ontologies/<ontology-item-ID>`). Note the
shape differs from the data agent's endpoint
(`/v1/mcp/workspaces/{ws}/dataagents/{id}/agent`) — `dataPlane`, `items`,
and a trailing `ontologyEndpoint`. It needs **F2+ capacity** and the
tenant settings *Users can create ontology (preview) items* and *Users
can create Fabric items*.

One known agent behaviour worth carrying: a data agent's first few
queries after creation can fail while it initializes (wait, retry). The
old aggregation workaround, adding `Support group by in GQL` to the
agent instructions, is moot: the data agent consumes the ontology as
context, then "generates a source-native SQL, KQL, or DAX query, runs the
query against that source, and presents the result" (Learn, checked
2026-10-06).

## Before you start: tenant settings

Creating the item at all requires the **Users can create ontology
(preview) items** tenant setting, and a new-experience item also requires
**Users can create Fabric items**. Failure to create a new ontology is
*most commonly* one of these and not anything about your data. Data agent
and operations agent each need their own settings on top.
