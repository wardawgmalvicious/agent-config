# Fabric Ontology (preview) — reference

Detail split out of [SKILL.md](../SKILL.md). Everything here was verified
against the Microsoft Learn docs on **2026-09-02** unless a section gives
a later date. The workload is in preview; re-check anything load-bearing.

## 1. Definition part schemas

### New experience: TMDL parts

Source: [Ontology definition (TMDL/new experience)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-definition)
(REST item-management), checked 2026-10-06. New-experience items support
the **TMDL** format: flat, item-folder-relative `.tmdl` files plus the
platform-owned `.platform`. Git integration, `getDefinition` /
`updateDefinition` and deployment pipelines all carry these parts.

| Definition part path | Type | Required | Notes |
| --- | --- | --- | --- |
| `.platform` | PlatformDetails (JSON) | yes | `metadata.type` = `Ontology`, `displayName`, `config.version` = `2.0`, `logicalId`. Platform-owned. |
| `database.tmdl` | TMDL `database` | yes | `compatibilityLevel` 1000000, the level the ontology extensions need. |
| `model.tmdl` | TMDL `model` | yes † | The tabular model and its `ref` statements, including `ref namespace default`. |
| `tables/{name}.tmdl` | TMDL `table` | no | A backing table: columns, a DirectLake `partition`, optional table-level `measure` objects carrying DAX. |
| `metrics/{name}.tmdl` | TMDL `metric` | no | One top-level metric per file, referenced from `model.tmdl` by `ref metric {name}`. |
| `relationships.tmdl` | TMDL `relationship` | no | TOM (table-to-table) relationships. |
| `expressions.tmdl` | TMDL `expression` | no | Shared M expressions, such as the DirectLake `DatabaseQuery` source. |
| `entities/{namespace}#{name}.tmdl` | TMDL `entity` | no | Ontology extension: an entity type and its `property` list. An unqualified file name such as `Sensor.tmdl` is in the default namespace. |
| `entityRelationships.tmdl` | TMDL `entityRelationship` | no | Ontology extension: each name is `<Namespace>#<EntityRelationship>`. |
| `namespaces/{namespace}.tmdl` | TMDL `namespace` | `default` only † | Ontology extension. `namespaces/default.tmdl` is required and referenced by `ref namespace default`; other namespaces are optional. |
| `rules/{rule}.tmdl` | TMDL `rule` | no | Ontology extension: one rule per file, named after the rule. |

† Required in what `getDefinition` returns, not in what a write must
send: the service synthesizes `model.tmdl` and `namespaces/default.tmdl`
when a create or update omits them, so the smallest write is `.platform`
plus `database.tmdl`.

- `getDefinition` always returns `.platform`; `updateDefinition` accepts
  it only with `updateMetadata=true`.
- File names under `entities/`, `namespaces/` and `rules/` come from the
  element's `name`, never its server-derived `displayName`.
- Defaults are elided on read: an absent property is "at its default",
  not "unsupported".
- Property `dataType`: a primitive (`string`, `int64`, `double`,
  `dateTime`, `boolean`, `decimal`), `Any`, `TimeSeries<T>`, or
  `complex` with a `complexDataType`.

#### Namespaces, inheritance, reusable properties, metrics and rules

From the same page, checked 2026-10-07. Keywords only: no local export
exists to show them in a file.

- **Namespaces.** One `namespaces/{namespace}.tmdl` per namespace, with
  an optional `lineageTag` (the reserved `default` uses the literal
  `default`), a `///` description and annotations; `model.tmdl` must
  `ref namespace default` and refs any other. An entity or entity
  relationship joins a namespace through its `<Namespace>#<Name>` file
  name, so its `namespace` is server-derived and read-only.
- **Inheritance.** An entity names its parent in `baseEntityType`
  (`<Namespace>#<Entity>`), and a property names the ancestor property
  it redefines in `redefines` (`entity`, `property`); both carry
  `overriddenMetadataFields`. `baseEntityType` and `redefines` are set
  on create and immutable, so a Git change to either deploys as a
  delete and recreate. Rolling out gradually: an import that authors
  them where the feature is off is rejected.
- **Reusable (shared) properties.** Declared once in `model.tmdl` as
  `reusableProperty {name}`: global, not namespaced, with no data type,
  only shared `description`, `synonym` and `annotation`. An entity
  property binds to one through its own `reusableProperty` field, a
  mutable binding, and inherits that metadata unless it lists the field
  in `overriddenMetadataFields`. Same rollout status as inheritance.
- **Metrics.** One `metrics/{name}.tmdl` per metric, a native Analysis
  Services TOM metric, of three kinds. Only **`explicit`** metrics, with
  their own KQL, SQL, Generic or NaturalLanguage expression (DAX is
  rejected), round-trip through `getDefinition` / `updateDefinition`.
  **`projected` and `enrichment`** metrics, the kinds that surface a DAX
  table `measure`, need a `backingMeasure` that TMDL cannot express: it
  "is lost on the TMDL round trip".
- **Rules.** One `rules/{rule}.tmdl` per rule: a `name`, in the default
  namespace; a natural-language `statement`; `ruleReferencedEntity`
  blocks, each with `propertyScope: none`, `specific` or `all` and, when
  specific, 1–10 `ruleReferencedProperty` lines; and
  `ruleReferencedRelationship` lines beside them. At most 50 of each per
  rule, and 1,000 rules per definition. `description` and `synonym`
  parse on a rule but are not re-emitted.

### Old experience (legacy): JSON parts

Retires **2027-01-31**; SKILL.md says who still meets it. Source:
[Ontology (old) definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-old-definition).
The tables below were verified on 2026-09-02, when the definition page
above still described this layout, and re-checked against the
old-definition page on 2026-10-07, which added `semanticEnrichment`.
Old-experience items support the **JSON** format only.

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

#### EntityType — `EntityTypes/{ID}/definition.json`

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
| `semanticEnrichment` | SemanticEnrichmentEntityType | no | `{ description, synonyms, customAttributes }`, the last a key-value object. |
| `properties` | EntityTypeProperty[] | no | Static properties. |
| `timeseriesProperties` | EntityTypeProperty[] | no | Time series properties. |
| `untypedProperties` | UntypedEntityTypeProperty[] | no | `valueType` is `Any`. |

`EntityTypeProperty`: `id` (BigInt), `name` (same regex), `redefines`
(pointer to a base-type property this one redefines), `baseTypeNamespaceType`,
`valueType` ∈ **String, Boolean, DateTime, Object, BigInt, Double**, and
an optional `semanticEnrichment` of `{ description, customAttributes }`.

**There is no `Decimal` in that enum**, unlike the new experience's
`dataType` above. That is the schema-level statement of the null-values
trap in SKILL.md.

The **portal** caps custom property names at **1–26 characters**
(alphanumerics, hyphens, underscores; must start and end alphanumeric)
and requires them **unique across all entity types** — stricter than the
128-character API regex above. Assume the portal limit when authoring.

#### DataBinding — `EntityTypes/{ID}/DataBindings/{guid}.json`

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

#### RelationshipType — `RelationshipTypes/{ID}/definition.json`

`{ id, namespace: "usertypes", name, namespaceType: "Custom", source, target }`
where `source` and `target` are each `{ entityTypeId }`. Directional. An
optional `semanticEnrichment` carries `{ description, customAttributes }`.

#### Contextualization — `RelationshipTypes/{ID}/Contextualizations/{guid}.json`

`{ id, dataBindingTable, sourceKeyRefBindings, targetKeyRefBindings }`.
`dataBindingTable` is the lakehouse variant above; the two
`*KeyRefBindings` arrays are `{ sourceColumnName, targetPropertyId }`
pairs naming the columns that make up each end's key. This is how a
relationship gets bound to data — the step ontology generation does *not*
do for you.

#### Overviews and ResourceLinks

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

Source: [Data binding in ontology](https://learn.microsoft.com/fabric/iq/ontology/how-to-bind-data),
checked 2026-10-07. Its type table, below, still lists **lakehouse and
eventhouse** types only, though five more source types now bind: KQL
database, mirrored database, semantic model, SQL database and warehouse.
The page gives no type map for those. Convert anything not listed here
by ETL *before* it reaches ontology.

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
`timestamp`. An entity type key is optional, since the overview
announces keyless entity types; when one is defined, it must be `string`
or `integer`.

## 3. Consuming an ontology — the six agent paths

Source: [Agent integration options](https://learn.microsoft.com/fabric/iq/ontology/concepts-agent-integration).

| Agent | Primary experience | Best for | Audience |
| --- | --- | --- | --- |
| **Ontology agent** | Chat interface inside ontology | Creating, improving, and testing queries on your ontology | Ontology users |
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

One consumer is not an agent: a **Real-Time Dashboard** takes an
ontology as a data source (preview) — *Add data source* → *Ontology*,
pick the item, *Connect* ([supported data sources](https://learn.microsoft.com/fabric/real-time-intelligence/dashboard-supported-data-sources),
checked 2026-10-06).

Copilot Studio reaches ontology through a tool listed as **Fabric IQ MCP
(preview)**: *Tools → Add a tool → Model Context Protocol*, search
*Fabric IQ Ontology*, pick it, then a connection taking **Workspace ID**
and **Ontology ID**; the tool exposes `list_ontology_entity_types` and
`search_ontology`. **It is not the GA Fabric IQ MCP server**, a different
server for Power BI reports and semantic models that "doesn't currently
support Fabric ontologies or data agents" (Learn, checked 2026-10-06).
Same name, different server: check which one a setup guide means.

### The built-in ontology agent

Preview, and its own page (`how-to-use-ontology-agent`) is not drilled:
what follows is from the integration and troubleshooting pages, checked
2026-10-07. The agent is a chat inside the item that can "create an
ontology and import data from semantic models, and operate your
ontology". It describes the ontology, queries the data behind it in DAX,
KQL, SQL or GQL, and proposes changes for review before they apply.

- **Your identity, this workspace.** "The agent uses your identity to
  read workspace data", and "only discovers items in the workspace where
  the ontology is located": a source elsewhere needs a shortcut into it.
- **Viewer reads, Contributor writes.** "Viewers can explain and query
  an existing ontology, but creating the first definition, improving the
  ontology, and applying changes require Contributor or higher
  permissions."
- **Plan mode blocks changes; Act mode applies them**, though for a
  Viewer "the service blocks write operations even when you select Act
  mode".
- **Uploads**: each file at most 5 MB, at most 10 per conversation, a
  filename of 60 characters or fewer with no path separators, `..` or
  control characters, in a text-based, PDF or image format. Files are
  scoped to the conversation.
- **GQL is ISO GQL**, "rather than openCypher".
- **Patches, not rewrites.** "Patches preserve stable identifiers (IDs)
  and minimize the scope of changes"; a rewrite "can break downstream
  queries that depend on stable entity or relationship IDs".
- **The chat lives in the browser tab.** "Refreshing the page clears the
  chat and any in-progress draft"; changes already applied in Act mode
  stay in the item.

### The MCP endpoint

```
https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/<workspace-ID>/items/<ontology-item-ID>/ontologyEndpoint
```

Both IDs are in the portal URL:
`https://app.fabric.microsoft.com/groups/<workspace-ID>/ontologies/<ontology-item-ID>`.

Prerequisites: **F2 or higher** paid Fabric capacity (or P1+ Power BI
Premium with Fabric enabled), and the tenant settings *Users can create
ontology (preview) items* and *Users can create Fabric items*. Due to a
known issue, a **service principal** can't use the ontology MCP yet
(MCP page, checked 2026-10-07).

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

Source: [Add metadata](https://learn.microsoft.com/fabric/iq/ontology/how-to-add-metadata),
checked 2026-10-07.

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

Source: [Generate an ontology from semantic models](https://learn.microsoft.com/fabric/iq/ontology/how-to-generate-from-semantic-models),
checked 2026-10-07; the legacy paragraph below comes from the
[old experience's generation page](https://learn.microsoft.com/fabric/iq/ontology/old-experience/concepts-generate).

What generation produces: the item, entity types matching the model's
tables, properties from columns with data bindings, relationship types
following the model's relationships, and **metrics** on entity types
from the model's DAX measures.

What you must then do **by hand, every time**:

1. Bind time series data — time series properties are never generated.
2. Review entity type keys and add missing ones, **especially multi-key**.
3. Bind relationship types to data (in the old experience, the
   `Contextualizations` above).
4. Rename entity types or relationships to friendly names as needed.
5. Review the whole ontology for completeness, metrics included.

**Old experience (legacy, retires 2027-01-31):** beyond the storage-mode
matrix in SKILL.md, generation inherits the ordinary Power BI service
constraints — semantic model size limits and XMLA endpoint limitations
apply. Only the old-experience page says so.

## 6. Troubleshooting map

Source: [Troubleshoot ontology (preview)](https://learn.microsoft.com/fabric/iq/ontology/resources-troubleshooting),
every row checked 2026-10-07.
Symptom → most likely cause, which is the direction you actually need:

| Symptom | Cause to check first |
| --- | --- |
| Item won't create | Tenant setting *Users can create ontology (preview) items* not enabled, or, for the new experience, *Users can create Fabric items*. |
| Generated, but **no entity types** | Semantic model unpublished, tables hidden, or no relationships defined. |
| Generated, but **some entity types missing** | Duplicate property names with mismatched types. |
| Generated, but **no data bindings** | Import mode, or Direct Lake with inbound public access disabled. |
| Queries return **null for `Decimal`** | Fabric Graph has no `Decimal`. Recreate the property as `Double` and bind it. |
| Entity type details: **`403 Forbidden`** | No access to the lakehouse holding the bound data. |
| Entity type details: **graph won't load** | Delta column mapping enabled on the underlying tables. |
| Entity type details: **no data** | External (not managed) tables, or a source table renamed after binding. |
| **No entity instances** | Source tables or column names changed; or the identity lacks data access. |
| Graph **sparse or missing data** | Entity type keys undefined, or source data not bound to them. |
| Preview page **unresponsive** | Needs **Contributor** (not Viewer) on the workspace, plus read on the data source. |
| Canvas won't load, *capacity exceeded* | The child Graph item's refresh schedule. Reduce or disable it. |
| **Migration** to the new experience fails | The old ontology has properties configured as *Defined at Binding*, or entities with composite keys. Remove them and retry. |
| **Service principal** can't use the ontology MCP | Known issue; currently unavailable. |
| A **parent entity** query returns no instances of its inheriting entities | Known issue; currently unavailable. |
| Data agent's **first queries fail** | Initialization. Wait a few minutes and retry. |
| Data agent **aggregates wrongly** | Known issue. Add `Support group by in GQL` to the agent instructions. |
| Data agent answers **vague** | Ontology not added as a knowledge source, or entity/relationship names not meaningful. |

Note the last three are data-agent-side; `fabric-data-agent` owns the rest
of that surface.

For known issues beyond these, see
[Microsoft Fabric known issues](https://support.fabric.microsoft.com/known-issues/)
and search for *ontology*, as Learn's ontology pages say.

## 7. Tenant settings

Source: [Required tenant settings](https://learn.microsoft.com/fabric/iq/ontology/overview-tenant-settings).

- **Users can create ontology (preview) items** — required to create the
  item at all.
- **Users can create Fabric items** — required to create an item with the
  new experience. Without it, creating one errors, a migration from the
  old experience included.
- **Fabric data agent tenant settings** — required to use an ontology
  with a data agent (including *Data agent item types (preview)*).
- **Fabric operations agent prerequisites** — required for that path.

## 8. Not drilled

Named so each omission stays deliberate, against the doc set's directory
on `main`, listed 2026-10-07. The split of 2026-09-29 put 11
old-experience pages under `old-experience/` and added the new
experience's beside them.

**Drilled, 2026-10-07:** `overview`, `overview-tenant-settings`,
`how-to-bind-data`, `how-to-generate-from-semantic-models`,
`how-to-use-ontology-graph`, `resources-capacity-usage`,
`concepts-agent-integration`, `how-to-add-metadata`,
`how-to-use-ontology-mcp-server` and `resources-troubleshooting`; under
`old-experience/`, `overview`, `how-to-bind-data`, `concepts-generate`,
`how-to-add-semantic-enrichment` and `resources-capacity-usage`. §1's
schemas come from the two REST item-definition pages, outside this doc
set, checked the same day.

**Not drilled, new experience:** `how-to-use-ontology-agent`,
`how-to-use-rules`, `how-to-use-metrics`, `how-to-use-namespaces`,
`how-to-use-inheritance`, `how-to-reuse-properties`,
`how-to-create-entity-types`, `how-to-create-relationship-types`,
`how-to-view-ontology-details`, `how-to-use-version-history`,
`how-to-import-export`, `how-to-share-permissions`,
`how-to-use-resource-links`, the four agent how-tos
(`how-to-create-data-agent`, `how-to-create-operations-agent`,
`how-to-create-agent-foundry-iq`, `how-to-create-agent-copilot-studio`),
`resources-glossary`, the three FAQ pages and the six-part tutorial.

**Not drilled, old experience:** `concepts-agent-integration`,
`how-to-create-entity-types`, `how-to-create-relationship-types`,
`how-to-use-resource-links`, `how-to-use-rules` and
`how-to-view-entity-type-details`.

Drill `how-to-use-ontology-agent` first: SKILL.md leans on the agent for
multi-model generation, refresh and authoring, without its own page.
Then `how-to-use-rules` and `how-to-use-metrics`: §1 says how rules and
metrics serialize, and nothing here says how they behave.
