---
name: fabric-iq
description: "Use for Microsoft Fabric IQ items: an ontology (`.Ontology`: entity types, properties, relationships, data binding, semantic enrichment), a graph model (`.GraphModel`: GQL over a labeled property graph), a data agent (`.DataAgent`: natural-language Q&A over Fabric data) or an operations agent (`.OperationsAgent`: watches live data and acts on it). Picks the item, then reads its reference."
paths:
  - "**/*.DataAgent/**"
  - "**/*.GraphModel/**"
  - "**/*.Ontology/**"
  - "**/*.OperationsAgent/**"
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Fabric IQ items

Learn's IQ workload holds six items ("What is Fabric IQ?", read
2026-10-12). Four have a reference here, in the table below; Power BI
semantic models are `fabric-tmdl`'s, and Plan has none. Each reference
holds the depth, and this file picks the item and carries only what
crosses items. Take the steps in order: the wrong item sends every later
step to the wrong file.

## 1. Pick the item

By the job asked for, or by the folder of the file in hand:

| The job | Folder | Read |
| --- | --- | --- |
| A shared business vocabulary bound to data: entity types, properties, relationships | `<name>.Ontology/` | [ontology.md](references/ontology.md) |
| GQL over a labeled property graph built from OneLake tables | `<name>.GraphModel/` | [graph.md](references/graph.md) |
| Natural-language Q&A over a domain's data, read-only, asked by a user | `<name>.DataAgent/` | [data-agent.md](references/data-agent/data-agent.md) |
| Watching live data and acting on it, unattended | `<name>.OperationsAgent/` | [operations-agent.md](references/operations-agent.md) |

[operations-agent.md](references/operations-agent.md) § 7 sets the two
agents side by side. Near these items, and not them:

- KQL's graph operators in an Eventhouse (`make-graph`, `graph-match`):
  `fabric-eventhouse`, a different engine from the GraphModel.
- Rule-based alerting with no LLM: `fabric-activator`.
- The semantic model an ontology is generated from, or a data agent
  queries: `fabric-tmdl`.

## 2. What crosses items

- **An ontology grounds both agents.** A data agent takes one as a
  source, with known issues of its own
  ([data-agent.md](references/data-agent/data-agent.md) § What a Data
  Agent is). An operations agent takes one as its single source, in the
  agent's own workspace
  ([operations-agent-reference.md](references/operations-agent-reference.md)
  § Data source constraints). Model the ontology in ontology.md, and
  configure each agent in its own file.
- **An ontology can generate a graph**: a child `GraphModel`, made only
  on opt-in through *Manage graph*, and only from eligible entity types
  ([ontology.md](references/ontology.md), its opening and § The
  constraints that produce silent or confusing failures). GQL itself is
  [graph.md](references/graph.md)'s.
- **Two MCP endpoints, two shapes.** An ontology is an MCP server
  ([ontology.md](references/ontology.md) § Consuming an ontology), and so
  is a published data agent
  ([data-agent.md](references/data-agent/data-agent.md) § Consumption
  surfaces). The URLs differ in shape, so neither is built from the
  other.
- **Each item has its own tenant settings**; check them first when an
  item won't create. The ontology's are in
  [ontology.md](references/ontology.md) § Before you start, and, with
  both agents', in
  [ontology-reference.md](references/ontology-reference.md) § 7. The data
  agent's are on the Learn page its § Reference links, and the
  operations agent's in
  [operations-agent-reference.md](references/operations-agent-reference.md)
  § Runtime, identity and availability. graph.md names none.

## 3. Read the item's reference first

Read the file step 1 names before answering or editing: limits,
definition shapes and preview status live there, dated. Each sends its
long detail one file further:
[ontology-reference.md](references/ontology-reference.md),
[graph-reference.md](references/graph-reference.md),
[operations-agent-reference.md](references/operations-agent-reference.md),
and the data agent's own [references/](references/data-agent/references/)
and [assets/](references/data-agent/assets/). A task that spans items, an
ontology-grounded agent for one, reads each item's file.
