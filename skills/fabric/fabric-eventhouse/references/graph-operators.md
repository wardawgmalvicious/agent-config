# KQL graph operators

Graph analysis **inside the KQL engine** — distinct from the standalone Fabric
GraphModel item (GQL / ISO-39075), which is the `fabric-graph` skill.

## Graph semantics

KQL can do graph analysis **inside the KQL engine** — this is a different thing from the standalone **Fabric GraphModel** item (a separate workload using GQL / ISO-39075; see the **fabric-graph** skill). Same word "graph", different engine: here a graph is built from KQL tabular data (or a stored snapshot) and queried with KQL graph operators, not GQL.

**Transient graph** — built in-memory per query with `make-graph`, then matched. `make-graph` must be followed by a graph operator.

```kql
edges
| make-graph Source --> Destination with nodes on name   // or: with_node_id=name
| graph-match (mallory)-[attacks]->(victim)-[hasPermission]->(trent)
    where mallory.name == "Mallory" and trent.name == "Trent"
    project Attacker = mallory.name, Compromised = victim.name, System = trent.name
```

**Persistent graph** (preview) — materialize a snapshot once, query repeatedly via the `graph()` function.

```kql
.create-or-alter graph_model OrgGraph
// model is a JSON doc: "Schema" { Nodes, Edges } + "Definition" { Steps: AddNodes / AddEdges }
.make graph_snapshot OrgGraph_v1 from OrgGraph

graph("OrgGraph")                            // latest snapshot; graph("OrgGraph","OrgGraph_v1") for a specific one
| graph-match (mgr)<-[reports*1..3]-(emp)    // variable-length edges: *min..max ; <- reverses direction
    where mgr.name == "Alice"
    project employee = emp.name, levels = array_length(reports)
```

- **Operators**: `make-graph` (build transient), `graph()` (reference a persistent snapshot; `graph("M", true)` builds a transient graph from the model), `graph-match` (pattern search; supports `cycles=none`, variable-length `[e*1..n]`), `graph-shortest-paths`, `graph-to-table`, `graph-mark-components`.
- **Snapshot management**: `.make graph_snapshot`, `.show graph_snapshots`, `.drop graph_snapshot`, `.drop graph_model`. Limits: max **5,000** snapshots/DB (500 on a free virtual cluster); snapshot build capped at **1 hour**.
- **openCypher / GQL over KQL graphs** (preview): set client request properties as separate directives before the query — `#crp query_language=opencypher` (or `gql`), `#crp query_graph_reference=G()`, and `#crp query_graph_label_name=lbl` to enable labels. This is still the KQL engine, not the GraphModel item.
- `make-graph ... partitioned-by <col> ( <graphOperator> )` runs the operator per partition value (multitenant) — the partition column must exist in both edges and nodes tables.
