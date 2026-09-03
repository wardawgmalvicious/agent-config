# Fabric Ontology (preview) — reference

Detail split out of [SKILL.md](../SKILL.md). Everything here was verified
against the Microsoft Learn docs on **2026-09-02**. The workload is in
preview; re-check anything load-bearing.

## 1. Definition part schemas

Source: [Ontology definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-definition)
(REST item-management). Ontology items support the **JSON** format only.

| Definition part path | Required | Notes |
| --- | --- | --- |
| `definition.json` | yes | `DefinitionDetails`. Literally `{}`. |
| `.platform` | yes | `metadata.type` = `Ontology`. |
| `EntityTypes/{ID}` | no | Directory. `{ID}` is a positive 64-bit integer unique across the ontology. |
| `EntityTypes/{ID}/DataBindings` | no | One JSON file per binding, named by the binding GUID. |
| `EntityTypes/{ID}/Documents` | no | `document{n}.json`. |
| `EntityTypes/{ID}/Overviews` | no | `definition.json`. |
| `EntityTypes/{ID}/ResourceLinks` | no | `definition.json`. |
| `RelationshipTypes/{ID}` | no | Directory. `definition.json` inside. |
| `RelationshipTypes/{ID}/Contextualizations` | no | One JSON file per contextualization, named by its GUID. |

Note the asymmetry: **entity and relationship type IDs are bigints used
as directory names; binding and contextualization IDs are GUIDs used as
file names.**

### EntityType — `EntityTypes/{ID}/definition.json`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | BigInt | yes | Matches the directory name. |
| `namespace` | string | yes | Allowed value: `usertypes`. |
| `baseEntityTypeId` | BigInt | no | Inheritance. |
| `name` | string | yes | `^[a-zA-Z][a-zA-Z0-9_-]{0,127}$` |
| `entityIdParts` | BigInt[] | no | Property IDs that together identify an entity — the **entity type key**. |
| `displayNamePropertyId` | BigInt | no | Friendly name in downstream experiences. |
| `namespaceType` | string | yes | Allowed value: `Custom`. |
| `visibility` | string | no | Allowed value: `Visible`. |
| `properties` | EntityTypeProperty[] | no | Static properties. |
| `timeseriesProperties` | EntityTypeProperty[] | no | Time series properties. |
| `untypedProperties` | UntypedEntityTypeProperty[] | no | `valueType` is `Any`. |

`EntityTypeProperty`: `id` (BigInt), `name` (same regex), `redefines`
(pointer to a base-type property this one redefines), `baseTypeNamespaceType`,
and `valueType` ∈ **String, Boolean, DateTime, Object, BigInt, Double**.

**There is no `Decimal` in that enum.** That is the schema-level
statement of the null-values trap in SKILL.md.

The **portal** caps custom property names at **1–26 characters**
(alphanumerics, hyphens, underscores; must start and end alphanumeric)
and requires them **unique across all entity types** — stricter than the
128-character API regex above. Assume the portal limit when authoring.

### DataBinding — `EntityTypes/{ID}/DataBindings/{guid}.json`

`{ id, dataBindingConfiguration }`, where the configuration is:

| Property | Required | Notes |
| --- | --- | --- |
| `dataBindingType` | yes | `TimeSeries` or `NonTimeSeries`. |
| `timestampColumnName` | if TimeSeries | Column holding the timestamps. |
| `propertyBindings` | no | `[{ sourceColumnName, targetPropertyId }]`. |
| `sourceTableProperties` | yes | Lakehouse or Eventhouse variant below. |

`LakehouseTableDataBindingProperties`: `sourceType: "LakehouseTable"`,
`workspaceId`, `itemId` (the lakehouse `ArtifactId`), `sourceTableName`,
optional `sourceSchema`.

`EventhouseTableDataBindingProperties`: `sourceType: "KustoTable"`,
`workspaceId`, `itemId`, `clusterUri`, `databaseName`, `sourceTableName`.
**Eventhouse sources are valid only when `dataBindingType` is
`TimeSeries`.**

Because a binding names properties only by `targetPropertyId`, reading a
binding diff requires the entity type's `definition.json` alongside it.

### RelationshipType — `RelationshipTypes/{ID}/definition.json`

`{ id, namespace: "usertypes", name, namespaceType: "Custom", source, target }`
where `source` and `target` are each `{ entityTypeId }`. Directional.

### Contextualization — `RelationshipTypes/{ID}/Contextualizations/{guid}.json`

`{ id, dataBindingTable, sourceKeyRefBindings, targetKeyRefBindings }`.
`dataBindingTable` is the lakehouse variant above; the two
`*KeyRefBindings` arrays are `{ sourceColumnName, targetPropertyId }`
pairs naming the columns that make up each end's key. This is how a
relationship gets bound to data — the step ontology generation does *not*
do for you.

### Overviews and ResourceLinks

`Overviews/definition.json` — `{ widgets, settings }`. Widget `type` ∈
`lineChart`, `barChart`, `file`, `graph`, `liveMap`; `yAxisPropertyId`
only on the two chart types. Settings `type` ∈ `fixedTime`, `customTime`;
`interval` ∈ `OneMinute`…`OneDay`; `aggregation` ∈ `Average`, `Count`,
`Maximum`, `Minimum`, `Sum`, `LastKnownValue`; `fixedTimeRange` ∈
`Last30Minutes`…`Last30Days` (fixedTime only) or `timeRange`
`{ startTime, endTime }` (customTime only).

`ResourceLinks/definition.json` — `{ resourceLinks: [{ type, workspaceId,
itemId }] }`. `type` allows **`PowerBIReport`** only, today.

`Documents/document{n}.json` — `{ displayText, url }`.

## 2. Source-to-property type mapping

Source: [Data binding in ontology](https://learn.microsoft.com/fabric/iq/ontology/how-to-bind-data).
Convert anything not listed here by ETL *before* it reaches ontology.

| Ontology property value type | Lakehouse source types | Eventhouse source types |
| --- | --- | --- |
| integer | tinyint, smallint, bigint, integer, long, short | int, long |
| boolean | boolean | bool |
| datetime | datetime, date, timestamp | datetime |
| double | double, **decimal**, float | decimal, real |
| string | char, **decimal(p, s)**, string, array, binary, binary16, byte, map, object, struct, timestampint64, timestamp_ntz | dynamic, string, guid, timespan |

Two rows to read twice. A bare lakehouse **`decimal` binds to `double`**
— which is exactly why the documented fix for the `Decimal` null trap
(recreate the property as `Double`, bind it) works. But
**`decimal(p, s)` binds to `string`**, so a precision-qualified column
silently becomes text and stops aggregating.

Timestamp columns for a time-series binding must be `datetime`, `date` or
`timestamp`. Entity type keys must be `string` or `integer`.

## 3. Consuming an ontology — the five agent paths

Source: [Agent integration options](https://learn.microsoft.com/fabric/iq/ontology/concepts-agent-integration).

| Agent | Primary experience | Best for | Audience |
| --- | --- | --- | --- |
| Fabric **operations agent** | Continuous monitoring with recommended actions | Real-time monitoring, alerting, automated actions against goals | Operations |
| Fabric **data agent** | Conversational Q&A inside Fabric | Interactive analytics over governed data with ontology context | Analysts, business users |
| **Foundry IQ** agent | Custom developer agent with tool calling | Advanced agents integrating enterprise systems | Developers |
| **Copilot Studio** agent | Low-code conversational agent | Business-friendly agents, workflow automation | Makers |
| **Custom agents via ontology MCP server** | Any MCP-compatible client | Connecting external/custom AI systems over MCP | Developers |

For the first two, configuration belongs to `fabric-operations-agent` and
`fabric-data-agent` — this skill covers the ontology side only. In
particular `fabric-operations-agent` already records that an ontology
data source there must be in the **same workspace** as the agent and does
not support `AND` conditions, which is narrower than ontology's own
limits.

Copilot Studio reaches ontology through the **Fabric IQ MCP (preview)**
tool: *Tools → Add a tool → Model Context Protocol → Fabric IQ Ontology*,
then a connection taking **Workspace ID** and **Ontology ID**.

### The MCP endpoint

```
https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/<workspace-ID>/items/<ontology-item-ID>/ontologyEndpoint
```

Both IDs are in the portal URL:
`https://app.fabric.microsoft.com/groups/<workspace-ID>/ontologies/<ontology-item-ID>`.

Prerequisites: **F2 or higher** paid Fabric capacity (or P1+ Power BI
Premium with Fabric enabled), and the *Ontology item (preview)* tenant
setting.

Wiring it into VS Code is the ordinary MCP-over-HTTP flow — `.vscode/mcp.json`,
**Add Server → HTTP**, paste the URL, name it, authenticate interactively.
Compare `claude/mcp/` in this repo for the equivalent template shape; the
ontology endpoint is a plain authenticated HTTP MCP server, so it fits
that pattern without anything Fabric-specific in the config.

**Do not confuse it with the data agent's endpoint**, which is
`https://api.fabric.microsoft.com/v1/mcp/workspaces/{WorkspaceId}/dataagents/{DataAgentId}/agent`
and only resolves once the data agent is **published**. Different path
shape, different item, different prerequisite.

## 4. Semantic enrichment

Source: [Add semantic enrichment with metadata](https://learn.microsoft.com/fabric/iq/ontology/how-to-add-semantic-enrichment).

| Object | Description | Synonyms | Key-value metadata |
| --- | --- | --- | --- |
| Entity type | ✅ | ✅ | ✅ |
| Property | ✅ | ❌ | ✅ |
| Relationship type | ✅ | ❌ | ✅ |

Metadata keys must be unique **within each object**; duplicates error.

Scope, stated by the docs: enrichment helps the agent during **schema
exploration and reasoning**, and **ontology query generation does not
directly use the metadata**. Publicly available data agent experiences
do not currently use **relationship-level** enrichment at all. So put the
effort into entity types and properties.

Practices worth keeping: lead a description with what the object *is*;
add units (`unit: celsius`, `unit: USD`) on numeric properties, since
units are the thing an agent cannot infer; add sensitivity
classifications; include abbreviations, acronyms and informal terms as
synonyms.

## 5. Generating from a semantic model — full limitations

Source: [Generating an ontology from a semantic model](https://learn.microsoft.com/fabric/iq/ontology/concepts-generate).

What generation produces: the item, entity types matching the model's
tables, static properties from columns with data bindings, and
relationship types following the model's relationships.

What you must then do **by hand, every time**:

1. Bind time series data — time series properties are never generated.
2. Review entity type keys and add missing ones, **especially multi-key**.
3. Bind relationship types to data (the `Contextualizations` above).
4. Review the whole ontology for completeness.

Beyond the storage-mode matrix in SKILL.md, generation inherits the
ordinary Power BI service constraints — semantic model size limits and
XMLA endpoint limitations apply.

## 6. Troubleshooting map

Source: [Troubleshoot ontology (preview)](https://learn.microsoft.com/fabric/iq/ontology/resources-troubleshooting).
Symptom → most likely cause, which is the direction you actually need:

| Symptom | Cause to check first |
| --- | --- |
| Item won't create | Tenant setting *Ontology item (preview)* not enabled. |
| Generated, but **no entity types** | Semantic model unpublished, tables hidden, or no relationships defined. |
| Generated, but **some entity types missing** | Duplicate property names with mismatched types. |
| Generated, but **no data bindings** | Import mode, or Direct Lake with inbound public access disabled. |
| Queries return **null for `Decimal`** | Fabric Graph has no `Decimal`. Recreate the property as `Double` and bind it. |
| Lakehouse **absent from the source picker** | OneLake security is enabled on it. |
| Entity type details: **`403 Forbidden`** | No access to the lakehouse holding the bound data. |
| Entity type details: **graph won't load** | Delta column mapping enabled on the underlying tables. |
| Entity type details: **no data** | External (not managed) tables, or a source table renamed after binding. |
| **No entity instances** | Source tables or column names changed; or the identity lacks data access. |
| Graph **sparse or missing data** | Entity type keys undefined, or source data not bound to them. |
| Preview page **unresponsive** | Needs **Contributor** (not Viewer) on the workspace, plus read on the data source. |
| Canvas won't load, *capacity exceeded* | The child Graph item's refresh schedule. Reduce or disable it. |
| Data agent's **first queries fail** | Initialization. Wait a few minutes and retry. |
| Data agent **aggregates wrongly** | Known issue. Add `Support group by in GQL` to the agent instructions. |
| Data agent answers **vague** | Ontology not added as a knowledge source, or entity/relationship names not meaningful. |

Note the last four are data-agent-side; `fabric-data-agent` owns the rest
of that surface.

## 7. Tenant settings

Source: [Required tenant settings](https://learn.microsoft.com/fabric/iq/ontology/overview-tenant-settings).

- **Ontology item (preview)** — required to create the item at all.
- **Fabric data agent tenant settings** — required to use an ontology
  with a data agent (including *Data agent item types (preview)*).
- **Fabric operations agent prerequisites** — required for that path.

## 8. Not drilled

Named so the omission stays deliberate: `how-to-create-entity-types`,
`how-to-create-relationship-types`, `how-to-use-rules`,
`how-to-use-resource-links`, `how-to-view-entity-type-details`,
`how-to-create-agent-foundry-iq`, `resources-capacity-usage`,
`resources-glossary`, and the five-part tutorial. Of these,
`how-to-use-rules` and `how-to-view-entity-type-details` (which owns the
graph-refresh mechanics referenced above) are the most likely to change
this skill's shape and should be drilled first.
