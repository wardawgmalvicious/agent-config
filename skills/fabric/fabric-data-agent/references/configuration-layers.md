# Fabric Data Agent: the four configuration layers in full

Split out of the parent `fabric-data-agent` SKILL.md, which carries the
summary table and the hard limits. This file holds Microsoft's recommended
structure for each layer plus worked examples. A second, end-to-end example
covering all four layers for one agent is in
[../assets/example-retail-agent.md](../assets/example-retail-agent.md).

Data agents use a layered instruction architecture. Each layer has a specific job — don't conflate them.

## 1. Agent instructions (top-level)

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

## 2. Data source instructions (per-source)

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

## 3. Data source descriptions

**Data source routing is GA as of August 2026** — the agent selects the most relevant lakehouse / warehouse / semantic model / KQL database per question, using schema metadata, source descriptions, example queries, and routing rules. Everything you write in this layer feeds that decision.

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

## 4. Example queries (few-shot)

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
