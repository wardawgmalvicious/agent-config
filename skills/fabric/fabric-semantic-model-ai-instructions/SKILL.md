---
name: fabric-semantic-model-ai-instructions
description: "Use when configuring AI instructions on a Power BI semantic model — the 10,000-character blob attached via `Prep data for AI` → `Add AI instructions` in Desktop or the service. Applies everywhere Copilot uses the model (reports, Q&A, Copilot pane). Covers what belongs in the blob (business context, terminology, date rules, default tables/measures, relationship navigation, hard rules, disambiguation) vs. what does NOT (per-column synonyms, descriptions, format strings, persona/tone, Q&A pairs). Includes prompt-engineering patterns, the 8,000-char target to leave iteration headroom, limitations (no deterministic enforcement, not visible to users, no per-persona scoping)."
paths:
  - "**/*.SemanticModel/definition/cultures/*.tmdl"
model: inherit
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Configuring Power BI Semantic Model AI Instructions

A practical, reusable guide for configuring AI instructions on a semantic model. Use this template across projects — the example domain (retail / sales) is illustrative; replace it with your own without changing the structure.

---

## What semantic model AI instructions are

A single text blob (up to 10,000 characters) attached directly to the semantic model. It provides context, business logic, and guidance that Copilot uses when interpreting user questions against the model.

It applies **wherever the model is consumed by Copilot** — Power BI reports, Q&A visuals, the Copilot pane, and any downstream surface that uses this model. Not just a single surface.

---

## When you use this vs. Data Agent instructions

- **Semantic Model AI Instructions** — guidance attached to one semantic model. No multi-source routing, no conversational flow. Applies to every Copilot interaction with this model.
- **Data Agent** — a separate conversational interface with multi-source routing, few-shot example queries, and conversational response formatting.

See the fabric-data-agent skill for data agent specifics.

---

## Setup process

Authoring is now available in **both** Power BI Desktop and the Power BI service. Consumption happens everywhere Copilot exists.

1. Open the semantic model in Power BI Desktop, or select the model in the Power BI service.
2. On the **Home** ribbon, click **Prep data for AI**.
3. If the tabs are disabled, enable **Power BI Q&A** on the model first.
4. Go to the **Add AI instructions** tab.
5. Paste or author the instructions.
6. Click **Apply**.
7. Test using the Copilot pane with the **Answers questions about the data** skill selected.
8. Publish or save the model. Instructions take effect everywhere Copilot uses this model.

Notes:

- Each time you edit instructions during testing, close and reopen the Copilot pane to pick up the changes.
- End users cannot see or disable these instructions.

---

## What belongs in the instructions blob

The blob is unstructured, but grouping by theme with markdown-style headers improves LLM interpretation. Recommended sections, each with a short inline example.

### Business context

One or two sentences on what the company does, what the model covers, and the primary grain. Sets the persona for Copilot.

```md
## Business context
You're a BI analyst for a multi-region retail business covering both physical
stores and an e-commerce channel. This model reports on sales performance,
product mix, and store productivity at line-item grain, refreshed nightly.
Focus responses on revenue, margin, and sell-through unless the user asks
something else explicitly.
```

### Terminology and synonyms

Cross-cutting business terms, acronyms, and aliases that appear in user questions but not in the model schema. Per-column synonyms do NOT go here — those belong on the column in TMDL.

```md
## Terminology
- `GMV` = Gross Merchandise Value (before returns and discounts).
- `NMV` = Net Merchandise Value (after returns, before discounts).
- `AOV` = Average Order Value.
- When users say "comp sales" or "like-for-like", they mean comparable-store
  sales (stores open more than 12 months).
- "Sell-through" = units sold / units received for the same period.
```

### Date and time rules

Fiscal calendar, default date columns, period definitions, reporting cadence.

```md
## Date and time rules
- Fiscal year starts 1 February. Fiscal Q1 = Feb-Apr.
- When the user asks about "this year" without qualification, assume fiscal
  year, not calendar year.
- Default date column for any trend analysis is `'Date'[Date]`. Do NOT use
  `'Sales'[OrderDate]` — it doesn't include returns.
- "Month-to-date" and "year-to-date" should use the DAX time-intelligence
  measures already on the model (`[Sales MTD]`, `[Sales YTD]`), not ad-hoc
  calculations.
```

### Default tables and measures

Which table or measure to prefer for which question type. This is the highest-leverage section — one good rule here prevents dozens of wrong queries.

```md
## Default tables and measures
- For any revenue question, use `[Net Sales]` unless the user explicitly asks
  for gross. `[Net Sales]` already excludes returns and discounts.
- For unit questions, use `[Units Sold]`, which excludes returns. Use
  `[Units Returned]` separately if the user asks about returns.
- For customer counts, use `[Active Customers]` (last 90 days) by default.
  Use `[Total Customers]` only when the user asks for all-time.
- For any margin analysis, join through the `'Cost'` table, not `'Sales'`.
```

### Relationship navigation rules

Which relationship path to take when multiple exist between the same pair of tables.

```md
## Relationship navigation
- `'Sales'` to `'Date'` has two relationships. The active one uses
  `SaleDate`. Use the inactive one (`OrderDate`) via `USERELATIONSHIP` ONLY
  when the user explicitly says "ordered on" or "order date".
- When joining `'Sales'` to `'Product'`, always go via `ProductKey`, never
  via `ProductName` — names aren't unique.
```

### Hard business rules and exclusions

Rules that override literal interpretation of the data.

```md
## Hard rules
- Always exclude internal test transactions: filter `'Sales'[IsTest] = FALSE`.
- Exclude staff-purchase transactions from customer analysis but include them
  in sales totals.
- Store 9999 is a warehouse consolidation store, not a real store. Exclude
  it from any store-level comparison.
- Discontinued products (`'Product'[IsActive] = FALSE`) should be excluded
  from "current assortment" questions but kept in historical analysis.
```

### Disambiguation

Field or term clashes inside the model that a natural-language question can't resolve on its own.

```md
## Disambiguation
- The model has two columns called "Region": `'Store'[Region]` (geography)
  and `'Customer'[Region]` (customer billing region). Default to
  `'Store'[Region]` unless the question clearly involves the customer.
- "Category" exists on both `'Product'` and `'Campaign'`. Default to
  `'Product'[Category]`.
- When a user says "price", default to `'Sales'[UnitPrice]`, not
  `'Product'[ListPrice]`.
```

---

## What does NOT belong here

- **Per-column synonyms and aliases** — these belong in TMDL as synonyms on the column. Duplicating them in the blob wastes characters and creates drift.
- **Column and measure descriptions** — these belong in the TMDL description property on the column or measure.
- **Format strings** (currency, percent, text-format IDs) — these belong on the column or measure format property.
- **Response formatting, tone, or persona instructions** — Microsoft explicitly states AI instructions are not intended for persona-specific or non-data output modifications.
- **Conversational or multi-turn flows** (e.g., "if the user asks X, first ask Y") — the semantic model has no agent-like conversation loop.
- **SQL or DAX query syntax hints** — Copilot traverses the model directly; it doesn't write queries the way a data agent does.
- **Verified-answer-style Q&A pairs** — use the dedicated Verified Answers feature instead.

Rule of thumb: if it's about a specific field or measure, it belongs on the field or measure. The blob is for **cross-cutting** guidance.

---

## Prompt engineering best practices

Microsoft's guidance for writing effective instructions, each with an illustration of the pattern.

### Be explicit and specific

Assume zero prior knowledge of the business.

```md
Weak:   You're a BI analyst who is detail-oriented.
Strong: You're a BI analyst for a multi-region retail business. Responses
        should focus on revenue performance, margin, and store productivity.
        Assume fiscal-year reporting unless the user specifies otherwise.
```

### Use examples in parentheses to clarify intent

```md
For product-specific sales, use `[Product Sales]` (example of product:
"Wireless Headphones", "Leather Wallet", "Running Shoes"). Filter on the
`'Product'[ProductName]` column.
```

### Avoid ambiguity

Explicitly state what to do AND what not to do.

```md
For `[Active Customer Count]`, use the `[Monthly Active Customers]` measure.
Do NOT filter on the `'Customer'` table directly — that misses customers
who have only placed orders in the `'Orders'` table.
```

### Group related instructions under headers

Use markdown `##` sections (business context, terminology, date rules, routing, etc.). Grouping helps the LLM locate relevant rules when interpreting a question.

### Break complex rules into steps

```md
When handling top-customer questions:
  1. First aggregate `[Net Sales]` by `'Customer'[CustomerKey]`.
  2. Then filter to customers active in the last 12 months.
  3. Then return the top 10 by `[Net Sales]` descending.
```

### Keep instructions focused

Conflicts and complexity confuse the LLM. If two rules contradict, the model hedges or picks arbitrarily.

### Iterate

Order and wording affect outputs — expect to tune. Rebuild the Copilot pane between edits. Keep a regression question bank (below) to catch drift.

---

## The 10,000-character budget

Hard limit. Plan for it.

- Target ≤ 8,000 characters. Leave headroom for iteration and future additions.
- If you're near the limit, audit for:
  - Per-column metadata that should be in TMDL
  - Duplicated rules (same thing said in two sections)
  - Verbose prose where a short imperative would do
  - Content that would be better served by Verified Answers

---

## Limitations to be aware of

- **No guaranteed adherence.** Instructions are LLM-interpreted. There is no deterministic enforcement. If a rule must be enforced (e.g., hiding sensitive columns, row-level security), use the correct mechanism — not the instructions blob.
- **End users cannot see the instructions.** No transparency to consumers. Do not put governance disclaimers or audit text here expecting it to be visible.
- **Not respected in all Copilot paths in Desktop.** AI instructions may be ignored when creating report pages, getting page suggestions, or generating dataset summaries unless the skill picker is set to **Create new report pages**.
- **No per-persona or per-mode rules.** Instructions cannot be scoped to specific users, groups, or view/edit modes.
- **No report-level instructions.** Instructions are attached at the model level only.
- **No upload from file in Desktop.** Currently, instructions must be pasted into the dialog.
- **Visual modifications and theming are out of scope.** Instructions don't affect report visuals.
- **Cannot disable or deprioritize other Copilot features.** Instructions influence how existing capabilities respond; they don't turn capabilities on or off.

---

## Testing and maintenance

- Maintain a **regression question bank** (50–100 representative questions with approved answers).
- Re-run the bank after any material change to the instructions or the model.
- Track accuracy over time. Investigate any degradation immediately.
- Version control the blob in your repo. It is not stored in TMDL — treat it as a separate first-class artifact.
- Assign ownership: who approves changes, who maintains descriptions, who signs off on new rules.

---

## Key differences from Data Agent instructions

- **Structure** — semantic model is one unstructured blob; data agent has four configuration layers (agent, data source, description, example queries).
- **Multi-source** — semantic model applies to exactly one model; data agent routes across up to 5 sources.
- **Example queries / few-shot** — not available on the semantic model; dedicated feature on the data agent (but not on semantic-model data sources within the agent).
- **Response formatting and conversational behavior** — explicitly out of scope for the semantic model; configurable on the data agent.
- **Character limit** — semantic model is capped at 10,000; data agent has no single documented hard cap.
- **Consumption surface** — semantic model instructions apply everywhere Copilot uses the model (reports, Q&A, Copilot chat, downstream consumers); data agent instructions apply only within the agent chat.
- **Visibility to end users** — neither is visible to end users in the UI.

---

## Reference

- Microsoft Learn: [Prepare your data for AI: AI instructions](https://learn.microsoft.com/en-us/power-bi/create-reports/copilot-prepare-data-ai-instructions)
- Microsoft Learn: [Prep data for AI overview](https://learn.microsoft.com/en-us/power-bi/create-reports/copilot-prepare-data-ai)
- Microsoft Learn: [Verified answers](https://learn.microsoft.com/en-us/power-bi/create-reports/copilot-prepare-data-ai-verified-answers)
- Comprehensive MS Learn link bundle (overview / instructions / verified answers / Q&A linguistic schema / tutorials): [references/REFERENCE.md](references/REFERENCE.md)

---

## See also

- For a starting-point AI-instructions example, see your internal tooling repo.

---

Last updated: 2026-04-20
