---
name: fabric-ontology
description: "Use for the Microsoft Fabric Ontology item (preview, Fabric IQ workload) — `<Name>.Ontology/` in a Git-synced repo, `.platform` type `Ontology`. Covers the definition layout (an empty `definition.json` envelope, `EntityTypes/{bigint-id}/definition.json` plus `DataBindings/{guid}.json`, `Documents`, `Overviews`, `ResourceLinks`, and `RelationshipTypes/{id}/` plus `Contextualizations`), generating an ontology from a semantic model and the Import / Direct Lake / DirectQuery support matrix whose Direct Lake bindings fail silently when the backing lakehouse workspace has inbound public access disabled, the data-binding rules (one static binding per entity type but many time-series ones, static before time-series, entity keys string/integer only, managed tables only, no OneLake security, no delta column mapping), the `Decimal`-returns-null trap and its `Double` remedy, semantic enrichment, and consuming an ontology from the five agent paths including its own MCP endpoint."
when_to_use: "Fires on any file under `*.Ontology/`. Owns the ontology item itself — its definition files, generation, data binding, enrichment. Defers graph mechanics and GQL to fabric-graph (ontology is built on that item), agent configuration to fabric-data-agent and fabric-operations-agent (ontology is one source among theirs), and semantic-model authoring to fabric-tmdl. Preview workload: claims here are dated, and the item is not the Fabric IQ Plan item."
paths:
  - "**/*.Ontology/**"
model: inherit
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
**2026-09-02**. Re-check before relying on a limit; this surface moves.

**Not here, deliberately.** The ontology graph is *provided by* [Graph in
Microsoft Fabric](https://learn.microsoft.com/fabric/graph/overview) — a
separate `GraphModel` item. GQL, graph-type DDL and `executeQuery` belong
to `fabric-graph`; this skill only carries the graph constraints that bite
at **ontology** time. Agent configuration belongs to `fabric-data-agent`
(conversational, ≤5 sources) and `fabric-operations-agent` (autonomous,
single-source) — ontology is one *source* for each of those.

## The Git definition layout

Ontology definitions are JSON. Only the first two are required:

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
`Decimal`** — see the trap below. Entity type and property `name` must
match `^[a-zA-Z][a-zA-Z0-9_-]{0,127}$`; note the portal is stricter than
the API here and caps custom property names at **26** characters.

Full part-by-part schemas, including every field of a data binding and
the Eventhouse variant, are in
[references/REFERENCE.md](references/REFERENCE.md).

## Generating an ontology from a semantic model

Generation creates the item, entity types from tables, static properties
from columns, and relationship types from model relationships. **What it
does not do** is bind time series data, review entity keys, or bind
relationship types — all three are manual follow-ups, every time.

Support depends entirely on the **semantic model's storage mode**:

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

You also **cannot generate from `My workspace`** — move the semantic
model to a real workspace first.

## The constraints that produce silent or confusing failures

- **Managed lakehouse tables only.** External tables that merely *appear*
  in a lakehouse are not supported, and the symptom is "entity type
  details shows no data" rather than an error at binding time.
- **No OneLake security on the source lakehouse.** A lakehouse with it
  enabled does not appear in the data-source picker at all — it looks
  like a permissions problem and is not.
- **No delta column mapping.** It is enabled *automatically* when column
  names contain `,` `;` `{}` `()` `\n` `\t` `=` **or a space**, and
  automatically on the delta tables backing **import-mode** semantic
  model tables. Symptom: the entity type details graph does not load.
- **Duplicate property names must share a type** across entity types. A
  string `ID` on one and an integer `ID` on another is what makes entity
  types go missing from a generated ontology.
- **Renaming a source table after binding breaks it.** Bindings carry
  `sourceTableName` as a string.
- **Refresh is manual.** New rows upstream are invisible until the graph
  model is refreshed; a refresh *schedule* on the child Graph item is
  what shows up as capacity usage.

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

- **One static binding per entity type.** You cannot union static data
  from two sources into one entity type. Static sources must be
  OneLake-backed.
- **Many time-series bindings per entity type**, from lakehouse *and*
  eventhouse sources together.
- **Static first.** A time-series binding needs an existing statically
  bound property to contextualize against, and the static value must
  **exactly match** a column in the time-series data.
- **Entity type keys are `string` or `integer` only.** One or more
  columns, together unique.
- Time series data must be **columnar** — one row per timestamped
  observation.

## Semantic enrichment is what makes agents work

Descriptions, synonyms, and key-value metadata on entity types and
properties. It is not decoration: the documented example is a data agent
that cannot answer "which ice cream shops sold the most frozen desserts?"
until `Products` gains the synonym `frozen desserts`.

Scope it honestly, because the docs do: enrichment helps the agent during
**schema exploration and reasoning**, and **query generation does not use
the metadata directly**. Only entity types support synonyms — properties
and relationship types get descriptions and key-value pairs only, and
keys must be unique within each object.

## Consuming an ontology

Five paths, detailed in [references/REFERENCE.md](references/REFERENCE.md):
Fabric **operations agent** (monitoring + actions), Fabric **data agent**
(conversational Q&A), **Foundry IQ** agent, **Copilot Studio** agent, and
**custom agents over the ontology MCP server**.

The last is the one that matters outside Fabric: **an ontology is itself
an MCP server**, at

```
https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/<workspace-ID>/items/<ontology-item-ID>/ontologyEndpoint
```

Both IDs come out of the portal URL
(`.../groups/<workspace-ID>/ontologies/<ontology-item-ID>`). Note the
shape differs from the data agent's endpoint
(`/v1/mcp/workspaces/{ws}/dataagents/{id}/agent`) — `dataPlane`, `items`,
and a trailing `ontologyEndpoint`. It needs **F2+ capacity** and the
*Ontology item (preview)* tenant setting.

Two known agent behaviours worth carrying: a data agent's first few
queries after creation can fail while it initializes (wait, retry), and
aggregation is a known gap — add `Support group by in GQL` to the agent
instructions.

## Before you start: tenant settings

Creating the item at all requires the **Ontology item (preview)** tenant
setting. Failure to create a new ontology is *most commonly* this and not
anything about your data. Data agent and operations agent each need their
own settings on top.
