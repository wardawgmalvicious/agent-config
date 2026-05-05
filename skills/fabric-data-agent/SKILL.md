---
name: fabric-data-agent
description: "Use when configuring Microsoft Fabric Data Agents — the conversational Q&A interface built on Azure OpenAI Assistant APIs over Lakehouse/Warehouse/KQL/Semantic Model/Ontology/Microsoft Graph (up to 5 sources per agent). Covers the four configuration layers (agent instructions, data source instructions, data source descriptions for routing, example queries up to 100 per source), when to use vs semantic-model AI instructions, the governance precedence chain (organizational → role-based → developer → user intent), best practices (scope instructions to the right layer, iterate against real questions, version control alongside data platform code), and key limitations (read-only, structured data only, English only, 25-row/25-column response cap, no example queries on semantic model sources)."
paths:
  - "**/*.DataAgent/**"
---

# Configuring Fabric Data Agents

A practical, reusable guide for configuring a Fabric Data Agent so it returns accurate, contextually relevant answers. Use this template across projects — replace the example domain (retail / sales / logistics) with your own without changing the structure.

---

## What a Data Agent is

A Fabric Data Agent is a conversational Q&A interface built on Azure OpenAI Assistant APIs. It accepts natural-language questions, routes them to the right data source, generates a query (SQL / DAX / KQL / Microsoft Graph), validates it, executes it read-only, and returns a human-readable answer.

Supported data sources: **Lakehouse, Warehouse, KQL Database, Power BI Semantic Model, Ontology, Microsoft Graph**. A single agent supports up to **5 data sources in any combination**.

Read-only by design — it never generates create/update/delete queries.

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
- Comprehensive MS Learn link bundle (create / consume / Foundry / governance): [references/REFERENCE.md](references/REFERENCE.md)

---

Last updated: 2026-04-20
