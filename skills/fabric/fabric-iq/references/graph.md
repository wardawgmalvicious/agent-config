# Microsoft Fabric Graph (GraphModel item)

Graph in Fabric models a **labeled property graph** directly over **OneLake Delta tables** — no ETL, no data duplication. You define node/edge types and map them to columns; on save, Fabric ingests the tables and builds a read-optimized queryable graph. Query it with **GQL** (the ISO/IEC 39075 standard) via UI, REST, or NL2GQL.

**Item type name: `GraphModel`** — the `metadata.type` a Git-synced export writes into `.platform`, so the folder serializes as `<name>.GraphModel`; also the REST collection `/GraphModels` and the Catalog Search filter `Type eq 'GraphModel'`. fabric-cli knows the name only for `fab find`: its `ItemType` enum has no GraphModel entry, so `fab` cannot create or address one. New item → *Analyze and train data* → *Graph model*.

## Three things that catch people out

1. **It is NOT the KQL graph operators.** Fabric Graph (GraphModel) is a separate workload from the `make-graph` / `graph-match` / `#crp query_language=gql` story in Eventhouse/KQL (see fabric-eventhouse). Same *word* "graph", different engine, different API, different syntax surface. Don't cross-apply.
2. **GQL is read-only here.** You cannot `INSERT` / `SET` / `DELETE` graph data through GQL. Data is loaded and refreshed via **data management** (save the model = reingest from OneLake). `CREATE GRAPH` is only partially supported and `DROP GRAPH` is not in GQL — drop via the **Fabric UI or REST API** instead.
3. **No schema evolution.** Once nodes/edges/properties are modeled and data is ingested, the structure is fixed. Adding a property, changing a label, or changing a relationship type means **reingesting source data into a new model**. Plan the schema up front.

## GQL query language (ISO/IEC 39075)

GQL expresses relationships as **visual patterns** instead of joins. Roots are SQL + openCypher, but it is its own dialect — do not assume Cypher syntax (e.g. no `CREATE (n:Label)` data writes here).

```gql
MATCH (c:Customer)-[:purchases]->(o:`Order`)
RETURN c.fullName AS customer_name, count(o) AS num_orders
GROUP BY customer_name
ORDER BY num_orders DESC
LIMIT 5
```

- Backtick-quote labels that collide with keywords: `` (o:`Order`) ``.
- `||` is string concatenation: `person.firstName || ' ' || person.lastName`.
- Undirected match `-[:knows]-` is allowed in patterns, but the graph itself has **no undirected edges** — every edge is directed and has **exactly one label**.
- Comments: `--` line, `//` line, `/* */` block.

### Variable-length and shortest paths

A quantifier after an edge pattern repeats it, and `ANY SHORTEST` keeps one shortest path per source-destination pair from each input row; which of several tied paths comes back isn't deterministic ([graph patterns](https://learn.microsoft.com/fabric/graph/gql-graph-patterns), [pattern queries](https://learn.microsoft.com/fabric/graph/write-graph-pattern-queries), read 2026-10-12):

```gql
MATCH p = ANY SHORTEST
  (src:Person WHERE src.firstName = 'Alice')-[:knows]->{1,4}
  (dst:Person WHERE dst.firstName = 'Bob')
RETURN p, path_length(p) AS hopCount
```

- **Path search prefix:** `ALL`, the default, or `ANY SHORTEST`. `ALL SHORTEST`, `ANY` and the counted `SHORTEST k` searches aren't supported, so don't carry them over from the standard.
- **Path mode**, after the prefix, as in `ANY SHORTEST TRAIL`: `WALK`, the default, lets nodes and edges repeat; `TRAIL` repeats no edge; `SIMPLE` repeats no node, except that the last may be the first; `ACYCLIC` repeats no node at all. `MATCH DIFFERENT EDGES` keeps edges distinct across all of a `MATCH`'s comma-separated patterns.
- **Quantifiers:** `{n}`, `{m,n}` and `{,n}` are bounded; `{m,}`, `*` and `+` aren't. An unbounded pattern needs `TRAIL`, `SIMPLE` or `ACYCLIC`, since Graph rejects an unbounded `ALL WALK`. An unbounded `ANY SHORTEST WALK` works only for reachability between two nodes over one anonymous quantified edge, and never materializes its path: `PATH_LENGTH(p)` and `p IS NULL` are its only uses. A lower bound of `0` also matches a node to itself.
- **Where a predicate sits changes the answer.** An inline `WHERE`, inside a node or edge pattern, decides which paths are eligible before `ANY SHORTEST` picks one; a statement-level `WHERE` or a later `FILTER` drops the picked path afterwards and doesn't try a longer one. Some `ANY SHORTEST` shapes currently apply a statement-level `MATCH … WHERE` before selection, so write eligibility inline and post-filters as `FILTER` ([limitations](https://learn.microsoft.com/fabric/graph/limitations#path-predicate-placement)). Both forms side by side → [graph-reference.md](graph-reference.md) § 2.

### Graph-type DDL (defining the schema in GQL)

The graph **type** (schema) uses a compact DDL that is unlike anything in training-data Cypher. It is reference syntax, not something to run: "Graph doesn't currently accept GQL graph-type declarations directly" ([language guide](https://learn.microsoft.com/fabric/graph/gql-language-guide), read 2026-10-12), though the conformance page's `GC04` row still calls `CREATE GRAPH` with a closed graph type supported. A model's schema is set in the model editor, or in the JSON `graphType` part under § "Graph Model item-definition JSON". To read Learn's schema pages, this example matches their syntax ([graph types](https://learn.microsoft.com/fabric/graph/gql-graph-types), [schema example](https://learn.microsoft.com/fabric/graph/gql-schema-example)), so copy it rather than recall it:

```gql
-- node type with typed properties; :: is the type operator
(:Person => {
    id :: UINT64 NOT NULL,
    firstName :: STRING,
    birthday :: UINT64
}),

-- key constraint (node identity)
CONSTRAINT person_pk FOR (n:Person) REQUIRE (n.id) IS KEY,

-- inheritance with =>  (abstract base, then subtypes)
ABSTRACT (:Place => { id :: UINT64 NOT NULL, name :: STRING }),
(:City => :Place),
(:Country => :Place),

-- property extension with +=
(:Post => :Message += { language :: STRING, imageFile :: STRING }),

-- edge types: source -[:label {props}]-> destination
(:Person)-[:knows { creationDate :: ZONED DATETIME }]->(:Person),
(:Person)-[:studyAt { classYear :: UINT64 }]->(:University),

-- <: references an abstract type
(:Comment)-[:replyOf]->(<:Message)
```

Full social-network schema example + the GQL standard-conformance table (what's supported vs not) → [graph-reference.md](graph-reference.md).

## GQL Query API (REST)

Single RPC-over-HTTP endpoint, in **beta** and not recommended for production. The documented URL carries **`?beta=true`**, which is required; the older `preview=true` still works for backward compatibility, but use `beta=true` in new code:

```bash
az rest --method post \
  --resource "https://api.fabric.microsoft.com" \
  --url "https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/GraphModels/{graphModelId}/executeQuery?beta=true" \
  --headers "Content-Type=application/json" "Accept=application/json" \
  --body '{ "query": "MATCH (n:Person) WHERE n.birthday > 19800101 RETURN n.firstName, n.lastName LIMIT 100" }'
```

- **Token audience is `https://api.fabric.microsoft.com`** (`az account get-access-token --resource https://api.fabric.microsoft.com`). See fabric-auth.
- List graphs in a workspace: `GET /v1/workspaces/{workspaceId}/GraphModels`.
- **Application errors return HTTP 200**, not 4xx. You MUST inspect `status.code`, a **five-character** code: `00000` success with rows, `00001` omitted result (reserved for future DDL/DML), `01000` warning or information, `02000` no rows yet, `42000` user-correctable query error, `50000` system error. Detail is in `status.diagnostics`, where `_graphaneGqlStatus` keeps the engine's canonical GQLSTATUS (`22003` overflow and `22012` division by zero both surface as `42000`), and in chained `status.cause`. Do not assume success from HTTP 200, and don't parse `description`.
- **A still-running query is not an empty result.** A query that doesn't finish within the request returns HTTP 200, `02000`, an empty table and `result.nextPage`. Re-send the same body with `&continuationToken=<nextPage>`, percent-encoded exactly once, until `nextPage` is absent. Execution gets **20 minutes in total, continuations included**, then HTTP 408 `QueryTimeout`.
- **Responses over 64 MB are truncated**: the rows that fit come back, with a `01000` status in `additionalStatuses` (canonical `01M11`) and no `nextPage` for the rest. Narrow the query and rerun it.
- Result is a discriminated union on `result.kind` (`TABLE` with `columns`+`data`, or `NOTHING`). Values carry `gqlType`; large `INT64`/`UINT64` outside JS safe range and float `Inf`/`-Inf`/`NaN` arrive as **strings**.

Request/response schema, value-encoding table, and status-code families → [graph-reference.md](graph-reference.md).

## Graph Model item-definition JSON (automation / CI-CD)

For `createItemWithDefinition` / `getDefinition` / `updateDefinition` (see fabric-tmdl's `references/definition-api.md` for the envelope, LRO, base64, all-parts rules), a `GraphModel` definition has **four required parts**:

| Part | What it holds |
|---|---|
| `dataSources` | `DeltaTable` sources: `{ name, type:"DeltaTable", properties:{ path: "abfss://…/Tables/<T>" } }` |
| `graphDefinition` | `nodeTables` + `edgeTables` mapping source columns → graph: `propertyMappings`, and on edges `sourceNodeKeyColumns` / `destinationNodeKeyColumns`; optional `filter` (Single/Group with `and`/`or`, operators `Equal`/`Contains`/`GreaterThan`/`In`…) |
| `graphType` | `nodeTypes` (`alias`, `labels[]`, `primaryKeyProperties[]`, `properties[]`) + `edgeTypes` (`alias`, `labels[]`, `sourceNodeType.alias`, `destinationNodeType.alias`, `properties[]`) |
| `stylingConfiguration` | `modelLayout`: node `positions`, `styles` (size), `pan`, `zoomLevel` — visual only |

Note the indirection: the **graphType** declares abstract `alias`es (`Customer_nodeType`) and labels; the **graphDefinition** binds each alias to a `dataSourceName` and maps `sourceColumn → propertyName`. A composite key is expressed as multiple `primaryKeyProperties` and matching `destinationNodeKeyColumns`. Full JSON examples for all four parts → [graph-reference.md](graph-reference.md).

## Data load & refresh

- **Save = ingest.** Selecting *Save* in the model editor both persists the model and reingests OneLake data to rebuild the queryable graph. To pull fresh data without model changes, just save again.
- **Scheduled refresh**: workspace → graph item → *…* → *Schedule* → *Add schedule* (minute/hourly/daily/weekly/monthly). Not available in *My Workspace* — shared workspaces only.

## Other gotchas / limits

- **Storage floor 100 GB** provisioned (billed at OneLake Cache rate); compute billed by CPU uptime at **10 CU-seconds per second**, rounded up to the minute. Uses your existing Fabric capacity — no separate SKU.
- **Hard limits:** graph processing supports roughly **2 billion graph elements** (nodes + edges), though effective capacity varies with graph structure and property payload size — contact Microsoft Support beyond it; the **Explore** UI's path builder stops variable-length patterns at **8 hops**, a limit GQL in the code editor doesn't share; queries **time out at 20 minutes** and responses are **truncated above 64 MB**, with intermediate results capped at 128 MB. A `STRING` value holds at most **65,534 bytes**, not characters, and a `LIST` or `PATH` at most **65,534 elements** (read 2026-10-12). Learn gives no per-workspace cap on graph models (2026-10-12). See [limitations](https://learn.microsoft.com/fabric/graph/limitations).
- **NL2GQL** (natural-language → GQL via Fabric Data Agent, see [data-agent.md](data-agent/data-agent.md)) is **preview**. **openCypher** support is preview and is the KQL-graph path, not this item.
- **Set operations: `UNION` only.** `UNION ALL` and `UNION DISTINCT` are supported, including inside `NEXT` stages; `INTERSECT`, `EXCEPT` and `OTHERWISE` aren't yet. Full conformance-gap list → [limitations](https://learn.microsoft.com/fabric/graph/limitations).
- Governed by OneLake security + workspace RBAC (see fabric-security).

## Reference

- MS Learn: [Graph overview](https://learn.microsoft.com/fabric/graph/overview) · [How graph works](https://learn.microsoft.com/fabric/graph/how-graph-works) · [GQL language guide](https://learn.microsoft.com/fabric/graph/gql-language-guide) · [GQL graph patterns](https://learn.microsoft.com/fabric/graph/gql-graph-patterns) · [GQL schema example](https://learn.microsoft.com/fabric/graph/gql-schema-example) · [GQL conformance](https://learn.microsoft.com/fabric/graph/gql-conformance)
- MS Learn: [GQL Query API reference](https://learn.microsoft.com/fabric/graph/gql-query-api) · [Graph Model definition (REST)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/graph-model-definition) · [Manage and refresh data](https://learn.microsoft.com/fabric/graph/manage-data)
- Consolidated link bundle, full schema/JSON/value-encoding tables: [graph-reference.md](graph-reference.md)

## See also

- **fabric-eventhouse** — the *other* graph story: KQL `make-graph` / `graph-match` / openCypher in Eventhouse. Different engine; do not conflate.
- **fabric-tmdl**, `references/definition-api.md` — definition envelope, LRO polling, base64, "include all parts" rule (applies to GraphModel definitions too)
- **fabric-rest-api** — runtime item ID vs `.platform` logicalId, LRO 202 pattern, pagination
- **fabric-auth** — `api.fabric.microsoft.com` token audience for the query API
- [data-agent.md](data-agent/data-agent.md) — graph as a Data Agent source for NL2GQL (preview)
- **fabric-cli** — not for this item: `fab` has no `GraphModel` type and cannot create or address one (see the top of this file)
