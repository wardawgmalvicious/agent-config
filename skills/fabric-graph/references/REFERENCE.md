# Fabric Graph (GraphModel) — Reference

All content grounded in Microsoft Learn (`learn.microsoft.com/fabric/graph/*` and the
Fabric REST item-definition docs). No speculative content.

## Table of contents

- [1. What it is](#1-what-it-is)
- [2. GQL graph-type DDL — full schema example](#2-gql-graph-type-ddl--full-schema-example)
- [3. GQL standard conformance (supported vs not)](#3-gql-standard-conformance-supported-vs-not)
- [4. GQL Query API — request/response contract](#4-gql-query-api--requestresponse-contract)
- [5. Value types & JSON encoding](#5-value-types--json-encoding)
- [6. Graph Model item-definition JSON (all four parts)](#6-graph-model-item-definition-json-all-four-parts)
- [7. Pricing / capacity / regions](#7-pricing--capacity--regions)
- [8. Source links](#8-source-links)

---

## 1. What it is

A scale-out **labeled property graph** over **OneLake** Delta tables. Nodes (vertices) and
edges (relationships) each have: an internal ID, one or more **labels** (edges have exactly
**one** label), and properties (name–value pairs). Edges are **directed**; undirected edges
are not supported. Every edge connects two valid nodes that exist in the same graph.

**Workflow (How graph works):** Graph modeling (define node types, edge types, table
mappings) → Save (ingest from lakehouse tables, build read-optimized queryable graph) →
Query authoring (Query Builder visual UI **or** Code Editor GQL) → Query execution
(GQL / NL2GQL preview / REST) → Results (visual diagrams / tabular / JSON).

Roles: data engineers model & create; analysts run low/no-code queries; business users
explore visually or via natural language; developers use the REST GQL API + Data Agent.

---

## 2. GQL graph-type DDL — full schema example

The graph **type** is the schema. `CREATE GRAPH` with a *closed* graph type is supported;
GQL graph **schema management** (`GC01`) and `DROP GRAPH` are **not** — drop via UI/REST.

Operators to know:
- `::` — type operator (`id :: UINT64 NOT NULL`)
- `=>` — node type definition / inheritance (`(:City => :Place)`)
- `+=` — extend an inherited type with extra properties
- `ABSTRACT` — abstract base type (cannot be instantiated directly)
- `<:` — reference to an abstract type in an edge endpoint
- `CONSTRAINT <name> FOR (n:T) REQUIRE (n.id) IS KEY` — node key constraint

Complete social-network graph type (from MS Learn `gql-schema-example`):

```gql
(:TagClass => { id :: UINT64 NOT NULL, name :: STRING, url :: STRING }),
CONSTRAINT tag_class_pk FOR (n:TagClass) REQUIRE (n.id) IS KEY,
(:TagClass)-[:isSubclassOf]->(:TagClass),

(:Tag => { id :: UINT64 NOT NULL, name :: STRING, url :: STRING }),
(:Tag)-[:hasType]->(:TagClass),
CONSTRAINT tag_pk FOR (n:Tag) REQUIRE (n.id) IS KEY,

ABSTRACT (:Place => { id :: UINT64 NOT NULL, name :: STRING, url :: STRING }),
(:City => :Place),
(:Country => :Place),
(:Continent => :Place),
CONSTRAINT place_pk FOR (n:Place) REQUIRE (n.id) IS KEY,
(:City)-[:isPartOf]->(:Country),
(:Country)-[:isPartOf]->(:Continent),

ABSTRACT (:Organization => { id :: UINT64 NOT NULL, name :: STRING, url :: STRING }),
(:University => :Organization),
(:Company => :Organization),
CONSTRAINT organization_pk FOR (n:Organization) REQUIRE (n.id) IS KEY,
(:University)-[:isLocatedIn]->(:City),
(:Company)-[:isLocatedIn]->(:Country),

(:Person => {
    id :: UINT64 NOT NULL,
    creationDate :: ZONED DATETIME,
    firstName :: STRING,
    lastName :: STRING,
    gender :: STRING,
    birthday :: UINT64,
    browserUsed :: STRING,
    locationIP :: STRING
}),
CONSTRAINT person_pk FOR (n:Person) REQUIRE (n.id) IS KEY,
(:Person)-[:hasInterest]->(:Tag),
(:Person)-[:isLocatedIn]->(:City),
(:Person)-[:studyAt { classYear :: UINT64 }]->(:University),
(:Person)-[:workAt { workFrom :: UINT64 }]->(:Company),
(:Person)-[:knows { creationDate :: ZONED DATETIME }]->(:Person),

(:Forum => { id :: UINT64 NOT NULL, creationDate :: ZONED DATETIME, title :: STRING }),
CONSTRAINT forum_pk FOR (n:Forum) REQUIRE (n.id) IS KEY,
(:Forum)-[:hasTag]->(:Tag),
(:Forum)-[:hasMember { creationDate :: ZONED DATETIME, joinDate :: UINT64 }]->(:Person),
(:Forum)-[:hasModerator]->(:Person),

ABSTRACT (:Message => {
    id :: UINT64 NOT NULL,
    creationDate :: ZONED DATETIME,
    browserUsed :: STRING,
    locationIP :: STRING,
    content :: STRING,
    length :: UINT64
}),
CONSTRAINT message_pk FOR (n:Message) REQUIRE (n.id) IS KEY,

(:Post => :Message += { language :: STRING, imageFile :: STRING }),
(:Person)-[:likes { creationDate :: ZONED DATETIME }]->(:Post),
(:Post)-[:hasCreator]->(:Person),
(:Post)-[:isLocatedIn]->(:Country),
(:Forum)-[:containerOf]->(:Post),

(:Comment => :Message),
(:Person)-[:likes { creationDate :: ZONED DATETIME }]->(:Comment),
(:Comment)-[:hasCreator]->(:Person),
(:Comment)-[:isLocatedIn]->(:Country),
(:Comment)-[:replyOf]->(<:Message),
(:Person)-[:likes { creationDate :: ZONED DATETIME }]->(<:Message),
(<:Message)-[:hasCreator]->(:Person),
(<:Message)-[:isLocatedIn]->(:Country),
(<:Message)-[:hasTag]->(:Tag)
```

### Example queries

```gql
-- count nodes of a label
MATCH (n:`Order`) RETURN count(n) AS num_orders

-- pattern + filter + concat
MATCH (person:Person)-[:knows]-(friend:Person)
WHERE person.birthday < 19990101 AND friend.birthday < 19990101
RETURN person.firstName || ' ' || person.lastName AS person_name,
       friend.firstName || ' ' || friend.lastName AS friend_name

-- multi-hop traversal + order/limit
MATCH (p:Person {firstName: "Annemarie"})-[:knows]->(friend)-[:likes]->(c:Comment)
RETURN c ORDER BY c.creationDate LIMIT 100
```

---

## 3. GQL standard conformance (supported vs not)

Selected rows from MS Learn `gql-conformance`. Useful to avoid generating unsupported syntax.

| Feature ID | Feature | Supported | Notes |
|---|---|---|---|
| GB01 | Long identifiers | No | |
| GB02 | `--` line comments | Yes | |
| GB03 | `//` line comments, `/* */` block comments | Yes | |
| GC01 | Graph schema management | No | |
| GC04 | Graph management (`CREATE GRAPH`) | **Partial** | `CREATE GRAPH` with a closed graph type supported. **No `DROP GRAPH`** — use Fabric UI / REST API. |
| GD01 | Updatable graphs | **No** | No GQL `INSERT`/`SET`/`DELETE`. Load/refresh via data management. |
| GD02 | Graph label set changes | No | |
| GD03/GD04 | `DELETE` statement variants | No | |

Implication: treat GQL as **query-only** against an already-ingested graph. All structural
and data changes go through the model editor (save = ingest) or the REST item-definition API.

---

## 4. GQL Query API — request/response contract

**Endpoint (single RPC over HTTP POST):**

```
POST https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/GraphModels/{GraphModelId}/executeQuery?preview=true
```

Headers: `Content-Type: application/json`, `Accept: application/json`,
`Authorization: Bearer <token>` (audience `https://api.fabric.microsoft.com`).

**Discovery:**

```bash
# workspaces
az rest --method get --resource "https://api.fabric.microsoft.com" \
  --url "https://api.fabric.microsoft.com/v1/workspaces"
# graphs in a workspace (filter with JMESPath via --query, table via -o table)
az rest --method get --resource "https://api.fabric.microsoft.com" \
  --url "https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/GraphModels"
```

**Request body:** `{ "query": "MATCH (n) RETURN n LIMIT 100" }` (only field: `query`, string, required).

**Response (HTTP 200):**

```json
{
  "status": {
    "code": "00000",
    "description": "note: successful completion",
    "diagnostics": { "OPERATION": "", "OPERATION_CODE": "0", "CURRENT_SCHEMA": "/" }
  },
  "result": { "kind": "TABLE", "columns": [ ... ], "data": [ ... ] }
}
```

**Status codes** are 6-character strings, hierarchical by prefix:

| Prefix | Meaning |
|---|---|
| `00xxxx` | Complete success |
| `01xxxx` | Success with warnings |
| `02xxxx` | Success with no data |
| `03xxxx` | Success with information |
| `04xxxx`+ | Errors / exception conditions |

- **Always check `status.code`** — do NOT infer success from HTTP 200. Transport errors
  (network/HTTP) use real 4xx/5xx; **application errors return HTTP 200** with the error in
  `status`. `status.cause` chains an underlying cause; `additionalStatuses` may list more.
- Diagnostic keys starting with `_` (e.g. `_errorLocation`) are graph-specific and their
  values are JSON-encoded GQL values.

**Result kinds** (discriminated union on `result.kind`):
- `TABLE` → `columns[]` (`name`, `gqlType`, `jsonType`), `isOrdered`, `isDistinct`, `data[]`.
- `NOTHING` → operation returned no data (e.g. catalog/data updates).

---

## 5. Value types & JSON encoding

Values follow a discriminated-union pattern `{ "gqlType": "TYPE", "value": <v> }`. In TABLE
results this is optimized: for **known-typed columns** only the raw value is serialized; for
`ANY` columns the full `{gqlType,value}` object appears per cell.

| Category | GQL types / notes |
|---|---|
| Boolean | `BOOL` → native JSON boolean |
| String | `STRING` → UTF-8 string |
| Integer | `INT64`, `UINT64` — **serialized as strings** when outside JS safe range (±9,007,199,254,740,991), e.g. `{"gqlType":"INT64","value":"9223372036854775807"}` |
| Float | `FLOAT64` (IEEE 754). Special values arrive as **strings**: `"Inf"`, `"-Inf"`, `"NaN"`, `"-0"` |
| Temporal | `ZONED DATETIME` ISO-8601, e.g. `2023-12-25T14:30:00+02:00` |
| Graph refs | `NODE` (`"node-123"`), `EDGE` (`"edge_abc#def"`) |
| Lists | `LIST<INT64>` (nullable elements), `LIST<ANY>` (each element carries type), `LIST<NULL>`, `LIST<NOTHING>` (empty) |
| Paths | `PATH` → list of node/edge refs: `["node1","edge1","node2"]` |

Client handling: expect large ints / floats / specials as strings; JSON `null` = GQL null.

---

## 6. Graph Model item-definition JSON (all four parts)

Definition parts (all `Required: true`): `dataSources`, `graphDefinition`, `graphType`,
`stylingConfiguration`. Use with Fabric core `createItemWithDefinition` / `getDefinition` /
`updateDefinition` (base64-encode parts; `updateDefinition` must include ALL parts — see
fabric-tmdl-api).

### 6a. dataSources

```json
{
  "dataSources": [
    {
      "name": "Customer_Table",
      "type": "DeltaTable",
      "properties": {
        "path": "abfss://<wsId>@onelake.dfs.fabric.microsoft.com/<lakehouseId>/Tables/Customers"
      }
    }
  ]
}
```

### 6b. graphDefinition (column → graph mapping)

`nodeTables`: each binds a `nodeTypeAlias` to a `dataSourceName` and maps
`sourceColumn → propertyName`. `edgeTables` additionally specify
`sourceNodeKeyColumns` / `destinationNodeKeyColumns` (arrays — composite keys allowed) and
an `edgeTypeAlias`. Optional `filter` selects rows.

```json
{
  "schemaVersion": "1.0.0",
  "nodeTables": [
    {
      "id": "Customer_5b6cb156",
      "nodeTypeAlias": "Customer_nodeType",
      "dataSourceName": "Customer_Table",
      "propertyMappings": [
        { "propertyName": "CustomerId", "sourceColumn": "Customer_Id" },
        { "propertyName": "FirstName",  "sourceColumn": "First_name" }
      ],
      "filter": {
        "and": [
          { "operator": "Contains", "columnName": "First_name", "value": "USA" }
        ]
      }
    }
  ],
  "edgeTables": [
    {
      "id": "CustomerPurchase_976cceac",
      "edgeTypeAlias": "CustomerPurchase_edgeType",
      "dataSourceName": "Order_Table",
      "sourceNodeKeyColumns": ["Customer_Id_FK"],
      "destinationNodeKeyColumns": ["Category_Id_FK", "Product_Id_FK"],
      "propertyMappings": [
        { "propertyName": "Quantity", "sourceColumn": "unit_price" },
        { "propertyName": "Date",     "sourceColumn": "Date" }
      ]
    }
  ]
}
```

**Filters.** `SingleFilter` = `{ operator, columnName, value }`; `GroupFilter` nests via
`filters` / `and` / `or`. Observed operators: `Equal`, `Contains`, `GreaterThan`, `In`
(`value` may be a string, number, dateTime, or an array of these). Both a top-level
`{ "and": [ ... ] }` shorthand and an explicit `{ "operator":"AND", "filters":[ ... ] }`
form appear in the MS Learn examples.

### 6c. graphType (schema)

`nodeTypes`: `alias`, `labels[]`, `primaryKeyProperties[]`, `properties[]`
(`{name,type}` where type ∈ `STRING`/`INT`/`FLOAT`/`DATETIME`/`BOOLEAN`/…).
A node can carry **multiple labels** (e.g. `["Customer","Employee"]`).
`edgeTypes`: `alias`, `labels[]`, `sourceNodeType.alias`, `destinationNodeType.alias`,
`properties[]`. Two edge types can share a label (`"PURCHASED"`) with different endpoints.

```json
{
  "schemaVersion": "1.0.0",
  "nodeTypes": [
    {
      "alias": "Product_nodeType",
      "labels": ["Product"],
      "primaryKeyProperties": ["CategoryId", "ProductId"],
      "properties": [
        { "name": "CategoryId", "type": "INT" },
        { "name": "ProductId",  "type": "STRING" },
        { "name": "Price",      "type": "FLOAT" }
      ]
    }
  ],
  "edgeTypes": [
    {
      "alias": "CustomerPurchase_edgeType",
      "labels": ["PURCHASED"],
      "sourceNodeType": { "alias": "Customer_nodeType" },
      "destinationNodeType": { "alias": "Product_nodeType" },
      "properties": [
        { "name": "Quantity", "type": "INT" },
        { "name": "Date",     "type": "DATETIME" }
      ]
    }
  ]
}
```

### 6d. stylingConfiguration (visual only)

```json
{
  "schemaVersion": "1.0.0",
  "modelLayout": {
    "positions": { "Customer_nodeType": { "x": 1, "y": 1 } },
    "styles":    { "Customer_nodeType": { "size": 30 } },
    "pan": { "x": 0, "y": 0 },
    "zoomLevel": 1
  }
}
```

---

## 7. Pricing / capacity / regions

- No separate license/SKU — consumes existing Fabric capacity (reserved or PAYG).
- Compute billed on **CPU uptime: 10 CU-seconds per second**, each uptime session rounded up
  to whole minutes. Auto-shuts down when not in use.
- Storage: minimum **100 GB** provisioned, billed at the **OneLake Cache** rate.
- Metrics App line items: *Graph general operations* (meter: Graph capacity usage CU) and
  *Graph cache storage* (meter: OneLake Cache).
- Available in 30+ regions (see overview page for the current list).

---

## 8. Source links

- Overview — https://learn.microsoft.com/fabric/graph/overview
- How graph works — https://learn.microsoft.com/fabric/graph/how-graph-works
- Graph data models (labeled property graph) — https://learn.microsoft.com/fabric/graph/graph-data-models
- Design a graph schema — https://learn.microsoft.com/fabric/graph/design-graph-schema
- GQL language guide — https://learn.microsoft.com/fabric/graph/gql-language-guide
- GQL graph types — https://learn.microsoft.com/fabric/graph/gql-graph-types
- GQL schema example — https://learn.microsoft.com/fabric/graph/gql-schema-example
- GQL conformance — https://learn.microsoft.com/fabric/graph/gql-conformance
- GQL Query API reference — https://learn.microsoft.com/fabric/graph/gql-query-api
- GQL status codes — https://learn.microsoft.com/fabric/graph/gql-reference-status-codes
- Quickstart (create first graph) — https://learn.microsoft.com/fabric/graph/quickstart
- Tutorial: query with code editor (GQL) — https://learn.microsoft.com/fabric/graph/tutorial-query-code-editor
- Tutorial: query builder — https://learn.microsoft.com/fabric/graph/tutorial-query-builder
- Manage and refresh data — https://learn.microsoft.com/fabric/graph/manage-data
- Graph Model definition (REST) — https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/graph-model-definition
- GraphModel REST items API — https://learn.microsoft.com/rest/api/fabric/graphmodel/items
- Data Agent graph source (NL2GQL, preview) — https://learn.microsoft.com/fabric/data-science/data-agent-add-datasources
