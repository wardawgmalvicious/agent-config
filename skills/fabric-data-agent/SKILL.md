---
name: fabric-data-agent
description: "Use when configuring Microsoft Fabric Data Agents (GA March 2026) — conversational Q&A built on Azure OpenAI Assistant APIs over Lakehouse / Warehouse / KQL / Semantic Model / Fabric SQL DB / Mirrored DB / Ontology / Microsoft Graph (≤5 sources per agent). Covers the four configuration layers (agent instructions, data source instructions, descriptions for routing, example queries ≤100/source), when to use vs semantic-model AI instructions, the governance precedence chain (organizational → role-based → developer → user intent), best practices (right-layer scoping, iterate on real questions, version control), and key limitations (read-only, structured data only, English only, 25-row/25-column response cap, no example queries on semantic model sources). The Creator Agent ('Build agent with AI', SQL/Eventhouse only), M365 Copilot Agent Store + Copilot-in-Power-BI, Python SDK, Copilot Studio, Azure AI Foundry / Agent Service, and service-principal auth (not Foundry/Copilot or KQL) all remain in preview."
paths:
  - "**/*.DataAgent/**"
---

# Configuring Fabric Data Agents

A practical, reusable guide for configuring a Fabric Data Agent so it returns accurate, contextually relevant answers. Use this template across projects — replace the example domain (retail / sales / logistics) with your own without changing the structure.

---

## What a Data Agent is

A Fabric Data Agent is a conversational Q&A interface built on Azure OpenAI Assistant APIs. It accepts natural-language questions, routes them to the right data source, generates a query (SQL / DAX / KQL / Microsoft Graph), validates it, executes it read-only, and returns a human-readable answer.

**Status — Generally Available as of March 2026.** The core agent (create / configure / publish / share), built-in diagnostics, and end-to-end lifecycle management via Git integration + deployment pipelines are all GA. Treat as a production surface. The following companion features are still in **preview** at GA and should be gated accordingly: the **Creator Agent** ("Build agent with AI") for AI-assisted authoring of the four configuration layers, consumption from **Microsoft 365 Copilot** (Agent Store) and **Copilot in Power BI**, the **Fabric Data Agent Python SDK** (including programmatic `evaluate_few_shots` and ground-truth evaluation), **Microsoft Copilot Studio integration**, **Azure AI Foundry / Azure AI Agent Service integration**, and the **external Python client SDK** (interactive-browser auth pattern for embedding in custom apps).

Supported data sources: **Lakehouse, Warehouse, KQL Database (Eventhouse), Power BI Semantic Model, Fabric SQL Database, Mirrored Database, Ontology, Microsoft Graph**. A single agent supports up to **5 data sources in any combination**.

Read-only by design — it never generates create/update/delete queries.

---

## Authentication modes for consuming an agent

How a caller authenticates depends on the consumption surface:

- **In-product chat (GA)** — runs under your signed-in Microsoft Entra **user** identity and your workspace/data permissions. No token or key to supply; Fabric uses a Microsoft-managed Azure OpenAI Assistant and handles auth for you.
- **Foundry / Copilot Studio integration (preview)** — identity passthrough (On-Behalf-Of): the integration runs under the **end user's** identity. Service principal auth is **not** supported on these surfaces — each end user needs access to the agent and its underlying data sources.
- **Service principal (SPN) auth — preview** — call the *published data agent query endpoint* directly from automation, background services, custom apps, and CI/CD without a signed-in user. The SPN authenticates to Entra via the **client-credentials flow**, requests a token for the Fabric resource (`https://analysis.windows.net/powerbi/api/.default`), and passes it as a bearer token. This endpoint is for asking natural-language questions only — **not** for managing or configuring the agent.

SPN setup (high level): register an app in Entra ID → enable the tenant setting **Service principals can use Fabric APIs** (Developer settings) → grant the SPN **Member** or **Contributor** on the agent's workspace → grant it **read** on every attached data source. The agent runs queries under the calling identity, so the SPN only sees data it has been granted.

SPN limitations (preview): **managed identities are not supported** (use an SPN); the SPN needs explicit read access to *every* attached source — sharing only the agent item is not enough; and SPN auth is **not yet supported for KQL database (Kusto) sources**.

---

## When you use this vs. Semantic Model AI Instructions

- **Data Agent** — conversational chat surface. Multi-turn interactions, multi-source routing, query orchestration, response formatting. End users interact with this directly.
- **Semantic Model AI Instructions** — guidance attached to a single semantic model. Applies wherever Copilot consumes that model (reports, Q&A, Copilot pane).

The two coexist. A data agent can use a semantic model as one of its sources, in which case both sets of instructions are in play. See the fabric-semantic-model-ai-instructions skill.

---

## The four configuration layers

Data agents use a layered instruction architecture. Each layer has a specific job — don't conflate them.

### 1. Agent instructions (top-level)

Applies across every data source the agent touches. Microsoft recommends the following markdown structure — author the instructions as a single blob using these headers:

```md
## Objective
Help users analyze retail sales performance and customer behavior across
regions and product categories.

## Data sources
- Use `SalesLakehouse` for product catalog, transactions, and inventory.
- Use `FinanceWarehouse` for margin, cost of goods sold, and budget.
- Use `CustomerModel` (Power BI semantic model) for segmentation, loyalty tier,
  and lifetime value.
- Prefer `CustomerModel` over `SalesLakehouse` for anything customer-facing
  (names, segments, tiers). Only drop to `SalesLakehouse` when the user asks
  for raw transaction details.

## Key terminology
- `GMV` = Gross Merchandise Value (before returns and discounts).
- `NMV` = Net Merchandise Value (after returns, before discounts).
- `AOV` = Average Order Value.
- "Active customers" = customers with at least one purchase in the last
  90 days, unless the user specifies a different window.
- Fiscal year starts 1 February. Q1 = Feb-Apr, Q2 = May-Jul, Q3 = Aug-Oct,
  Q4 = Nov-Jan.

## Response guidelines
- Default to concise summaries. Show tables only when the user asks to "list",
  "show", or "break down".
- When returning currency values, always include the currency code.
- When a result has fewer than 5 rows, describe it in prose instead of a table.
- If a question is ambiguous (e.g., "sales" — gross or net?), ask one
  clarifying question before answering.

## Handling common topics
- Questions about **financial performance** (revenue, margin, budget variance):
  route to `FinanceWarehouse` first.
- Questions about **product performance** (units sold, category mix, top
  sellers): route to `SalesLakehouse`.
- Questions about **customers** (segments, churn, loyalty): route to
  `CustomerModel`. Join to `SalesLakehouse` only if the user asks for
  transaction-level detail alongside the segmentation.
- For "top N" questions without a metric, default to ranking by NMV.
```

Keep this blob focused on cross-source routing and business-wide terminology. Source-specific query logic belongs in the data source instructions layer (below).

### 2. Data source instructions (per-source)

Applies only when the agent routes a question to that specific source. This is where source-specific query logic belongs — **not** in the agent-level blob.

Microsoft's recommended structure:

```md
## General knowledge
This lakehouse contains all POS transactions from our retail stores and our
e-commerce site. It does not contain wholesale orders — those live in the
B2B warehouse. Data is refreshed nightly; expect a 24-hour lag.

## Table descriptions
- `sales_fact`: one row per line item. Key columns: `store_id`, `product_id`,
  `customer_id`, `sale_date`, `quantity`, `unit_price`, `discount_amount`,
  `channel` ('store' or 'online'), `return_flag`.
- `product_dim`: product catalog. Key columns: `product_id`, `category`,
  `subcategory`, `brand`, `launch_date`, `is_active`.
- `store_dim`: stores. Key columns: `store_id`, `region`, `country`,
  `open_date`, `store_format` ('flagship', 'standard', 'outlet').
- `date_dim`: calendar with fiscal-year mapping. Always join on `sale_date`.

## When asked about
- **Returns**: filter `sales_fact` to `return_flag = 1`. Do NOT use negative
  quantities to identify returns — we store returns as separate rows.
- **Online vs in-store**: use `channel` on `sales_fact`. Don't infer from
  store attributes.
- **New product performance**: join `product_dim` and filter to products where
  `launch_date` is within the last 90 days.
- **Discontinued products**: `is_active = 0` on `product_dim`. Always exclude
  these from "current assortment" questions.
- **Regional comparisons**: always join through `store_dim` on `region`,
  never through a raw string in `sales_fact`.
```

For a semantic model data source, most of this content already lives in the model's AI instructions and TMDL metadata. Keep the data-source-level instructions here lean to avoid duplication.

### 3. Data source descriptions

A short summary the agent uses to **decide which source to route a question to**. One or two sentences focused on:

- What's in the source
- What questions it can answer
- What distinguishes it from other sources

Good descriptions:

```text
SalesLakehouse — All retail POS and e-commerce transactions since 2021, at
line-item grain. Use for any question about units sold, revenue at the
transaction level, store performance, channel mix, or product sell-through.

FinanceWarehouse — Monthly aggregated financial data: revenue, cost of goods
sold, operating expense, margin, budget, and variance. Use for any P&L-shaped
question or anything involving budget vs. actual.

CustomerModel — Power BI semantic model with customer segmentation, loyalty
tier, lifetime value, and churn scores. Use for any question that asks
"which customers" or "what kind of customers". Do NOT use for transaction
details — route those to SalesLakehouse.
```

Weak descriptions ("contains sales data") make the agent guess at routing. Always say what the source IS good for AND what it ISN'T.

### 4. Example queries (few-shot)

Paired question + correct query. The agent retrieves the top three most relevant examples per user question and uses them as guidance.

Up to **100 example queries per data source**. Add examples for:

- Common questions stakeholders actually ask
- Questions where the obvious query is wrong (e.g., returns stored as separate rows, not negative quantities)
- Questions with non-trivial business logic (fiscal calendar edge cases, exclusion rules, multi-fact comparisons)

Example for a lakehouse data source:

```sql
-- Q: What were total net sales for fiscal Q3 this year by region?
SELECT
     s.region
    ,SUM((f.quantity * f.unit_price) - f.discount_amount) AS net_sales
FROM sales_fact f
    JOIN store_dim s  ON f.store_id = s.store_id
    JOIN date_dim d   ON f.sale_date = d.date
WHERE d.fiscal_year = YEAR(CURRENT_DATE())
    AND d.fiscal_quarter = 3
    AND f.return_flag = 0
GROUP BY s.region
ORDER BY net_sales DESC;
```

```sql
-- Q: Which products launched in the last 90 days have sold the most units?
SELECT
     p.product_id
    ,p.category
    ,SUM(f.quantity) AS units_sold
FROM sales_fact f
    JOIN product_dim p ON f.product_id = p.product_id
WHERE p.launch_date >= DATEADD(day, -90, CURRENT_DATE())
    AND f.return_flag = 0
GROUP BY p.product_id, p.category
ORDER BY units_sold DESC;
```

One well-chosen example can outperform paragraphs of prose instructions.

**Important caveat**: example queries are **NOT currently supported for Power BI semantic model data sources**. For semantic models, rely on the model's own AI instructions, TMDL metadata, and Verified Answers instead.

---

## Creator Agent ("Build agent with AI") — preview

The **Creator Agent** is a specialized AI assistant that helps you author and refine the four configuration layers above instead of hand-writing them. Open it from the data agent ribbon via **Build agent with AI**; the same ribbon's **Test data agent** switches to the standard test mode. Use it to explore a connected source, discuss the questions you want answered, review recommended config changes, **Accept** them (changes apply immediately), then switch to Test mode to validate.

**Preview scope — SQL and Eventhouse sources only.** The Creator Agent does not work if the agent has any unsupported source attached. Prerequisites: an F SKU or trial capacity, the data agent tenant setting enabled, at least one supported source with the relevant tables selected, and read permission on the source (query-history exploration also needs permission to view that source's query history).

What it generates/manages: **Agent Instructions**, **Data Source Instructions**, **Data Source Descriptions**, and **Example Queries** — the same four layers, produced conversationally. It can run **read-only** queries to validate proposed joins/few-shots (writes are blocked) and reports back the result set or the error.

Recommended loop: **Explore** (schema exploration) → **Learn** (query-history exploration, when available) → **Generate** (instructions + few-shot examples) → **Validate** (execute query against real data) → **Apply** (accept, then Test mode). Repeat.

**Not covered by the Creator Agent (preview)** — you still configure these yourself: data source selection, schema selection, the data agent description used at publish time, semantic models / Power BI Prep for AI, Ontology, Graph, and unstructured data.

---

## Consumption surfaces

Beyond in-product chat (GA), a published data agent can be consumed from several surfaces — **all in preview** at the time of writing:

- **Microsoft 365 Copilot (Agent Store) — preview.** At publish time, choose **Publish to Agent Store** to make the agent available in M365 Copilot. Users chat with it directly or `@`-mention it from the main Copilot chat in Teams, share it via link (1:1, group, or channel), and use the **code interpreter** to visualize results. Requires a paid **F2+** (or P1+ with Fabric enabled) capacity, an **M365 Copilot license** (or Office 365 commercial subscription) plus per-user licenses, the **cross-geo processing and cross-geo storing for AI** tenant settings enabled, and the agent + Copilot on the **same tenant / same account**. The publish **description** becomes the `description_for_model` that steers the M365 orchestrator — you can instruct it to return the agent's output as-is, but the orchestrator still reasons over the grounding data, so some rephrasing is inevitable. RLS/CLS and underlying-source access are fully enforced per the calling user. **Compliance note:** responses may leave Fabric's compliance boundary / geographic region and be processed or stored under M365's data-handling policies.
- **Copilot in Power BI — preview.** Add the agent via **Add items for better results → Data agents**, or let Copilot search rank it alongside semantic models and reports. RLS/CLS enforced.
- **Copilot Studio / Azure AI Foundry (Agent Service) — preview.** Identity passthrough (On-Behalf-Of); see the authentication section above.

---

## Governance and intent precedence

When the agent decides what to do, layers override each other in this order (highest precedence first):

1. **Organizational intent** — tenant policies, Purview DLP, access restriction policies, compliance requirements. Can't be overridden.
2. **Role-based intent** — workspace governance, permission boundaries, RLS/CLS on semantic models.
3. **Developer intent** — your agent instructions, data source instructions, example queries.
4. **User intent** — the question in the chat.

If your developer instructions conflict with a higher layer (e.g., tell the agent to access a restricted column), the agent refuses or redirects. Don't try to write around policy in the instructions blob.

---

## Best practices

- **Scope each instruction to the right layer.** Source-specific guidance in the top-level blob creates noise. Generic business context duplicated across every data source blob creates drift.
- **Keep layers focused and non-contradictory.** Conflicts between layers cause the LLM to hedge or hallucinate.
- **Iterate against real questions.** Write, test, observe failures, adjust. Don't assume a single pass is sufficient.
- **Version control the instructions** alongside the rest of the data platform code. Treat them as first-class artifacts — use Git integration on the Fabric workspace to track changes.
- **Use example queries aggressively** on lakehouse/warehouse/KQL sources. They are the single most effective configuration mechanism for query accuracy.
- **Maintain a regression question bank.** When instructions change, re-run the bank and check for accuracy drift.
- **Use deployment pipelines** to promote agent changes through dev/test/prod.
- **Establish operational oversight.** Monitor interactions via built-in diagnostics, set up logging and audit, and review instructions periodically as data or business rules change.

---

## Common pitfalls

- Stuffing everything into the top-level agent blob and leaving the data source blobs empty. The layers exist for a reason.
- Data source descriptions that are too generic. "Contains sales data" doesn't help routing.
- Missing example queries. Without them, the agent guesses at query structure.
- Adding example queries to a Power BI semantic model data source (not supported — the UI won't stop you in all flows, but they have no effect).
- Instructions referencing deprecated tables, columns, or measures. Stale instructions are worse than none — they actively mislead the agent.
- Duplicating rules across agent, data source, and semantic model layers. Pick the most specific layer and leave the others clean.
- Treating the agent-level "Response guidelines" as a place for business logic. It's for conversational behavior — tone, clarification flows, disclaimers.
- Non-English content in instructions or example queries. Data agents don't currently support non-English languages; authoring in other languages degrades quality.

---

## Limitations to be aware of

- **Read-only**: generates SELECT-equivalent queries only. No create/update/delete.
- **Structured data only**: no `.pdf`, `.docx`, `.txt`. For lakehouse sources, only tables are queried — standalone files under `Files/` are not read unless exposed as tables.
- **5 data sources max per agent**.
- **100 example queries max per data source**.
- **No example queries on Power BI semantic model data sources**.
- **Response row/column cap**: agent responses are capped at 25 rows and 25 columns to keep chat output concise. Previous chat history can influence the cap on follow-ups — start a new chat if you need a clean context.
- **English only**: no current non-English language support.
- **LLM is fixed**: you can't change the underlying LLM.
- **Same-region requirement**: a data source's workspace capacity must be in the same region as the data agent's workspace capacity. Cross-region queries fail.
- **Conversation history may not persist** across service updates, infrastructure changes, or model upgrades.
- **Purview-sensitive data**: responses may be truncated or blocked if Purview DLP or access restriction policies apply.
- **Semantic model access**: users interacting via the agent need Read permission on the model; Build and Workspace Member roles are not required. RLS/CLS still apply.

---

## Full worked example

See [assets/example-retail-agent.md](assets/example-retail-agent.md) for a complete worked retail-agent example covering the agent instructions blob, per-source description, per-source instructions, and a representative SQL example query.

---

## Key differences from Semantic Model AI Instructions

- **Structure** — data agent has 4 configuration layers; semantic model has one unstructured text blob.
- **Multi-source** — data agent routes across up to 5 sources; semantic model instructions apply to exactly one model.
- **Example queries / few-shot** — data agent supports them on lakehouse/warehouse/KQL sources (not on semantic model sources); semantic model instructions don't support few-shot.
- **Response formatting and conversational behavior** — configurable in the data agent; explicitly out of scope for semantic model instructions.
- **Character limit** — semantic model is capped at 10,000 characters; data agent doesn't document a single hard limit but each layer has practical length constraints.
- **Consumption surface** — data agent instructions apply only in the agent chat; semantic model instructions apply everywhere Copilot uses the model (reports, Q&A, Copilot chat).

---

## Reference

- Microsoft Learn: [Data agent configurations](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-configurations)
- Microsoft Learn: [Fabric data agent concept](https://learn.microsoft.com/en-us/fabric/data-science/concept-data-agent)
- Microsoft Learn: [Data agent tenant settings](https://learn.microsoft.com/en-us/fabric/data-science/data-agent-tenant-settings)
- Microsoft Learn: [Use service principal authentication with Fabric data agent (preview)](https://learn.microsoft.com/fabric/data-science/data-agent-service-principal)
- Microsoft Learn: [Creator agent for data agent (preview)](https://learn.microsoft.com/fabric/data-science/data-agent-creator-agent-overview)
- Microsoft Learn: [Consume Fabric data agent in Microsoft 365 Copilot (preview)](https://learn.microsoft.com/fabric/data-science/data-agent-microsoft-365-copilot)
- Microsoft Learn: [Consume a Fabric data agent from Copilot in Power BI (preview)](https://learn.microsoft.com/fabric/data-science/data-agent-copilot-powerbi)
- Comprehensive MS Learn link bundle (create / consume / Foundry / governance): [references/REFERENCE.md](references/REFERENCE.md)

---

Last updated: 2026-07-01
