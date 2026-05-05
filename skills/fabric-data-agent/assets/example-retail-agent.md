# Worked example: Retail Data Agent

A complete configuration for one Fabric Data Agent over a retail/commerce data estate — POS lakehouse (`SalesLakehouse`), finance warehouse (`FinanceWarehouse`), and a customer semantic model (`CustomerModel`). Replace names and domain-specific terms with your own; the structure (agent-level blob → per-source description → per-source instructions → example query) is the reusable part. For the rationale behind each layer and what belongs where, see the parent `fabric-data-agent` skill.

---

**Agent instructions blob:**

```md
## Objective
Help users analyze retail sales performance, customer behavior, and financial
results across regions, channels, and product categories.

## Data sources
- `SalesLakehouse` — transactional POS and e-commerce data.
- `FinanceWarehouse` — monthly aggregated financial data.
- `CustomerModel` — Power BI semantic model with segmentation and loyalty.
- Prefer `CustomerModel` for customer-facing attributes; only drop to
  `SalesLakehouse` when the user asks for transaction-level detail.

## Key terminology
- `GMV` = Gross Merchandise Value (before returns and discounts).
- `NMV` = Net Merchandise Value (after returns, before discounts).
- `Active customer` = at least one purchase in the last 90 days.
- Fiscal year starts 1 February. Q1 = Feb-Apr.

## Response guidelines
- Default to concise prose summaries. Use tables only for "list" or "break
  down" requests.
- Include currency codes on all currency values.
- If a question is ambiguous about gross vs. net, ask one clarifying question.

## Handling common topics
- Financial performance (revenue, margin, budget): use `FinanceWarehouse`.
- Product and channel performance: use `SalesLakehouse`.
- Customer segmentation and loyalty: use `CustomerModel`.
- "Top N" without a metric: default to NMV.
```

**Data source description for `SalesLakehouse`:**

```text
All retail POS and e-commerce transactions since 2021, at line-item grain.
Use for questions about units sold, store performance, channel mix, returns,
or product sell-through. Do not use for aggregated financials — use
FinanceWarehouse instead.
```

**Data source instructions for `SalesLakehouse`:**

```md
## General knowledge
POS + e-commerce transactions. Wholesale orders are NOT here — those live in
the B2B warehouse. Data refreshes nightly; expect a 24-hour lag.

## Table descriptions
- `sales_fact` — one row per line item. Columns: store_id, product_id,
  customer_id, sale_date, quantity, unit_price, discount_amount, channel,
  return_flag.
- `product_dim` — catalog. Columns: product_id, category, subcategory, brand,
  launch_date, is_active.
- `store_dim` — stores. Columns: store_id, region, country, store_format.
- `date_dim` — calendar with fiscal mapping. Join on `sale_date`.

## When asked about
- Returns: filter `return_flag = 1`. Returns are separate rows, NOT negative
  quantities.
- Channel mix: use `sales_fact.channel` ('store' or 'online').
- New products: filter `product_dim.launch_date` to the last 90 days.
- Discontinued products: exclude `is_active = 0` from current assortment
  questions.
- Regional analysis: join via `store_dim.region`.
```

**Example query on `SalesLakehouse`:**

```sql
-- Q: Net sales by region for fiscal Q3 this year
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
