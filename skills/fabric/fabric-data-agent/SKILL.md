---
name: fabric-data-agent
description: "Use when configuring Microsoft Fabric Data Agents (GA March 2026) — conversational Q&A over Lakehouse / Warehouse / KQL / Semantic Model / Fabric SQL DB / Mirrored DB / Ontology / MS Graph (≤5 sources per agent), consumed in-product or via the agent's MCP endpoint (Assistants API and Copilot-in-Power-BI paths retired 2026-08-26). Covers the four configuration layers (agent instructions, data source instructions, descriptions for routing, example queries ≤100/source), when to use vs semantic-model AI instructions, governance precedence (organizational → role-based → developer → user), best practices (right-layer scoping, iteration, version control), and key limitations (read-only, structured data only, English only, 25-row/25-col response cap, no example queries on semantic models). The Creator Agent ('Build agent with AI', SQL/Eventhouse only), MCP endpoint, M365 Copilot Agent Store, Python SDK, Copilot Studio, Azure AI Foundry, and service-principal auth (not Foundry/Copilot or KQL) remain in preview."
paths:
  - "**/*.DataAgent/**"
model: inherit
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Configuring Fabric Data Agents

A practical, reusable guide for configuring a Fabric Data Agent so it returns accurate, contextually relevant answers. Use this template across projects — replace the example domain (retail / sales / logistics) with your own without changing the structure.

## What a Data Agent is

A Fabric Data Agent is a conversational Q&A interface. It accepts natural-language questions, routes them to the right data source, generates a query (SQL / DAX / KQL / Microsoft Graph), validates it, executes it read-only, and returns a human-readable answer.

Supported data sources: **Lakehouse, Warehouse, KQL Database (Eventhouse), Power BI Semantic Model, Fabric SQL Database, Mirrored Database, Ontology, Microsoft Graph**. A single agent supports up to **5 data sources in any combination**. Read-only by design — it never generates create/update/delete queries.

**Ontology as a source** is the one entry there that is a whole item type of its own — see `fabric-ontology` for modelling it, binding it to data, and its semantic enrichment, which is what makes an ontology-grounded agent answer well. Three data-agent-side behaviours belong here rather than there: an ontology source is still **preview**, the agent's first few queries after creation can fail while it initializes (wait and retry), and **aggregation is a known gap** — add the instruction `Support group by in GQL` to the agent's instructions.

**GA since March 2026** for the core surface: create / configure / publish / share, built-in diagnostics, and lifecycle management via Git integration + deployment pipelines. Everything else named in this skill as *preview* — Creator Agent, MCP endpoint, M365 Copilot, Python SDK, Copilot Studio, Foundry, SPN auth — should be gated behind an explicit decision. **Two integration paths retired 2026-08-26**: the Azure OpenAI **Assistants API** (migrate to the MCP endpoint; within the SDK, to the Fabric OpenAI **Responses** client) and **Copilot in Power BI**. Full status breakdown and migration detail:
[references/status-and-retirements.md](references/status-and-retirements.md).

## When you use this vs. Semantic Model AI Instructions

- **Data Agent** — conversational chat surface. Multi-turn interactions, multi-source routing, query orchestration, response formatting. End users interact with this directly.
- **Semantic Model AI Instructions** — guidance attached to a single semantic model. Applies wherever Copilot consumes that model (reports, Q&A, Copilot pane).

The two coexist. A data agent can use a semantic model as one of its sources, in which case both sets of instructions are in play. See the `fabric-semantic-model-ai-instructions` skill, and [references/authoring-workflow.md](references/authoring-workflow.md) for the point-by-point contrast.

## Authenticating a caller

The identity model and the token scope both change with the surface — mixing them is the usual cause of a 401.

| Surface | Identity | Token scope |
|---|---|---|
| **In-product chat** (GA) | Signed-in Entra user | none — Fabric brokers it |
| **MCP server endpoint** (preview) | User **or** service principal | `https://api.fabric.microsoft.com/.default` |
| **Published query endpoint, SPN** (preview) | Service principal, client-credentials | `https://analysis.windows.net/powerbi/api/.default` |
| **Foundry / Copilot Studio** (preview) | End user, On-Behalf-Of — **SPN not supported** | n/a |

The two `.default` scopes are **not** interchangeable; match the scope to the endpoint you are calling. SPN auth additionally needs the **Service principals can use Fabric APIs** tenant setting, workspace Member/Contributor, and **read on every attached source** — sharing the agent item alone is not enough. Managed identities and KQL-database sources are not supported under SPN. Full setup and caveats: [references/authentication.md](references/authentication.md).

## The four configuration layers

Each layer has a specific job — don't conflate them. Source-specific query logic belongs in layer 2, never in the agent-level blob.

| Layer | Scope | What goes in it |
|---|---|---|
| **1. Agent instructions** | Every source | Objective, cross-source routing rules, business-wide terminology, response guidelines |
| **2. Data source instructions** | One source | General knowledge about the source, table descriptions, "when asked about X do Y" query logic |
| **3. Data source descriptions** | One source, routing only | One or two sentences: what's in it, what it answers, **and what it isn't for** |
| **4. Example queries** | One source | Question + correct query pairs; the agent retrieves the top three most relevant per user question |

Hard limits, and the caveat that catches people:

- **5 data sources** per agent; **100 example queries** per source.
- **Example queries are not supported on Power BI semantic model sources.** The UI won't stop you in all flows, but they have no effect — rely on the model's own AI instructions, TMDL metadata, and Verified Answers instead.
- **Data source routing went GA in August 2026** and feeds on layers 2–4 plus schema metadata. A weak description ("contains sales data") makes the agent guess; always say what a source IS good for AND what it ISN'T.

One well-chosen example query can outperform paragraphs of prose instructions. Microsoft's recommended markdown structure for each layer, with worked examples: [references/configuration-layers.md](references/configuration-layers.md). A complete end-to-end configuration for one agent: [assets/example-retail-agent.md](assets/example-retail-agent.md).

To author the layers conversationally rather than by hand, the **Creator Agent** ("Build agent with AI", preview) generates and validates all four — but only on **SQL and Eventhouse sources**, and it refuses to run if any unsupported source is attached: [references/creator-agent.md](references/creator-agent.md).

## Consumption surfaces

Beyond in-product chat (GA), every surviving surface is preview:

| Surface | Notes |
|---|---|
| **M365 Copilot (Agent Store)** | **Publish to Agent Store** at publish time. Needs F2+/P1+, M365 Copilot licences, and the **cross-geo processing and storing for AI** tenant settings |
| **MCP server endpoint** | The replacement for the retired Assistants API. Exactly **one** MCP tool per agent |
| **Copilot Studio / Azure AI Foundry** | On-Behalf-Of passthrough. Foundry now connects through MCP |
| ~~Copilot in Power BI~~ | **Retired 2026-08-26** — the Learn page still reads as preview; trust the date, not the page |

MCP endpoint shape (streamable HTTP):

```http
https://api.fabric.microsoft.com/v1/mcp/workspaces/{WorkspaceId}/dataagents/{DataAgentId}/agent
```

Three things decide whether an MCP integration works. It **only responds after publish** — an unpublished agent errors even with a correct URL. The client must speak the real `initialize` → `tools/list` → `tools/call` flow, so a plain REST call fails, and the tool name and its argument should be discovered from `tools/list` rather than hard-coded. And the **publish description becomes the tool description** an orchestrator reads to decide whether to call the agent — write it for that audience, not for humans. Prerequisites, sharing model, and the compliance caveat (responses may leave Fabric's compliance boundary on the M365 and MCP surfaces): [references/consumption-surfaces.md](references/consumption-surfaces.md).

## Governance and intent precedence

When the agent decides what to do, layers override each other in this order (highest precedence first):

1. **Organizational intent** — tenant policies, Purview DLP, access restriction policies, compliance requirements. Can't be overridden.
2. **Role-based intent** — workspace governance, permission boundaries, RLS/CLS on semantic models.
3. **Developer intent** — your agent instructions, data source instructions, example queries.
4. **User intent** — the question in the chat.

If your developer instructions conflict with a higher layer (e.g., tell the agent to access a restricted column), the agent refuses or redirects. Don't try to write around policy in the instructions blob.

## Common pitfalls

- Stuffing everything into the top-level agent blob and leaving the data source blobs empty. The layers exist for a reason.
- Data source descriptions that are too generic. "Contains sales data" doesn't help routing.
- Missing example queries. Without them, the agent guesses at query structure.
- Adding example queries to a Power BI semantic model data source — they have no effect.
- Instructions referencing deprecated tables, columns, or measures. Stale instructions are worse than none — they actively mislead the agent.
- Duplicating rules across agent, data source, and semantic model layers. Pick the most specific layer and leave the others clean.
- Treating the agent-level "Response guidelines" as a place for business logic. It's for conversational behavior — tone, clarification flows, disclaimers.
- Non-English content in instructions or example queries. Data agents don't currently support non-English languages; authoring in other languages degrades quality.

The positive-form counterpart — the authoring loop, regression question banks, deployment pipelines, operational oversight — is in [references/authoring-workflow.md](references/authoring-workflow.md).

## Limitations to be aware of

Restating the caps from above: **read-only**, **5 data sources** per agent, **100 example queries** per source, **none on semantic model sources**. Beyond those:

- **Structured data only**: no `.pdf`, `.docx`, `.txt`. For lakehouse sources, only tables are queried — standalone files under `Files/` are not read unless exposed as tables.
- **Response row/column cap**: agent responses are capped at 25 rows and 25 columns to keep chat output concise. Previous chat history can influence the cap on follow-ups — start a new chat if you need a clean context.
- **English only**: no current non-English language support.
- **LLM is fixed**: you can't change the underlying LLM.
- **Same-region requirement**: a data source's workspace capacity must be in the same region as the data agent's workspace capacity. Cross-region queries fail.
- **Conversation history may not persist** across service updates, infrastructure changes, or model upgrades.
- **Purview-sensitive data**: responses may be truncated or blocked if Purview DLP or access restriction policies apply.
- **Semantic model access**: users interacting via the agent need Read permission on the model; Build and Workspace Member roles are not required. RLS/CLS still apply.

## Reference

Detail lives in [references/](references/) — each section above links the file that carries its full version.

- Microsoft Learn: [Fabric data agent concept](https://learn.microsoft.com/en-us/fabric/data-science/concept-data-agent)
- Microsoft Learn: [Data agent configurations](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-configurations)
- Microsoft Learn: [Data agent tenant settings](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-tenant-settings)
- Comprehensive MS Learn link bundle (create / consume / Foundry / governance): [references/REFERENCE.md](references/REFERENCE.md)

---

Last updated: 2026-08-31
