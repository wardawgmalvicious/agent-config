# Fabric Data Agent: Creator Agent ("Build agent with AI") — preview

Split out of the parent `fabric-data-agent` SKILL.md. Read when authoring the
four configuration layers conversationally rather than by hand.

The **Creator Agent** is a specialized AI assistant that helps you author and refine the [four configuration layers](configuration-layers.md) instead of hand-writing them. Open it from the data agent ribbon via **Build agent with AI**; the same ribbon's **Test data agent** switches to the standard test mode. Use it to explore a connected source, discuss the questions you want answered, review recommended config changes, **Accept** them (changes apply immediately), then switch to Test mode to validate.

**Preview scope — SQL and Eventhouse sources only.** The Creator Agent does not work if the agent has any unsupported source attached. Prerequisites: an F SKU or trial capacity, the data agent tenant setting enabled, at least one supported source with the relevant tables selected, and read permission on the source (query-history exploration also needs permission to view that source's query history).

What it generates/manages: **Agent Instructions**, **Data Source Instructions**, **Data Source Descriptions**, and **Example Queries** — the same four layers, produced conversationally. It can run **read-only** queries to validate proposed joins/few-shots (writes are blocked) and reports back the result set or the error.

Recommended loop: **Explore** (schema exploration) → **Learn** (query-history exploration, when available) → **Generate** (instructions + few-shot examples) → **Validate** (execute query against real data) → **Apply** (accept, then Test mode). Repeat.

**Not covered by the Creator Agent (preview)** — you still configure these yourself: data source selection, schema selection, the data agent description used at publish time, semantic models / Power BI Prep for AI, Ontology, Graph, and unstructured data.

## Learn page

- [Creator agent for data agent (preview)](https://learn.microsoft.com/fabric/data-science/data-agent-creator-agent-overview)
