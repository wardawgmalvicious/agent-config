# Configuring Power BI Semantic Model AI Instructions

A practical, reusable guide for configuring AI instructions on a semantic model. Use this template across projects — the example domain (retail / sales) is illustrative; replace it with your own without changing the structure.

---

## What semantic model AI instructions are

A single text blob (up to 10,000 characters) attached directly to the semantic model. It provides context, business logic, and guidance that Copilot uses when interpreting user questions against the model.

It applies **wherever the model is consumed by Copilot** — Power BI reports, Q&A visuals, the Copilot pane, and any downstream surface that uses this model. Not just a single surface. Microsoft 365 Copilot Chat now answers from the model too: "Data answering from Power BI content in Microsoft 365 Copilot Chat is a generally available (GA) feature of Microsoft Fabric." Learn says Prep-data-for-AI features reach "everywhere that Copilot in Power BI is available" but not whether that includes Copilot Chat, so don't promise these instructions apply there (2026-10-06).

Who reaches the model through Copilot is a model setting of its own, on
by default: *Allow any person with only read permissions to use AI (for
example, Copilot, Microsoft's MCP tools) on this model and its related
reports*. It covers the report pane, standalone Copilot and apps, M365
Copilot Chat and Cowork, data agents and Microsoft's remote MCP tools.
Turned off, an experience spanning several models also drops the model
and its reports from search for every user, and a model built on
another doesn't inherit it
([Use Copilot with semantic models](https://learn.microsoft.com/power-bi/create-reports/copilot-semantic-models),
read 2026-10-08).

### Reaching the model from Microsoft 365 Copilot Chat

Fabric IQ answers there from a report and the model beneath it, as the
asking user, under their RLS and OLS
([Fabric IQ in Microsoft 365 Copilot Chat](https://learn.microsoft.com/fabric/iq/connectors/microsoft-365-copilot-overview),
read 2026-10-15). Who can ask the model there turns on four things:

- **The reader**: a Microsoft 365 Copilot Premium licence, and
  permission and licensed access to the report and the model, but no
  access to Copilot in Fabric. A model in a workspace on an Embedded
  capacity, A or EM SKUs, is not supported, nor a region where Power BI
  is the only Fabric workload; Pro, PPU, Premium and Fabric capacities
  are.
- **Three tenant settings.** The Microsoft 365 admin center's *Fabric
  data in Microsoft Copilot*, on by default, admits no users, all users
  or specific groups; the overview calls it *Fabric data available in
  M365 Copilot*. The Fabric admin portal's *Share Fabric data with your
  Microsoft 365 services* sends Power BI metadata to Microsoft 365 for
  Copilot search and the attachment menu, is on by default where the
  two tenants share a geography, and takes up to 24 hours to change;
  off, a reader can still paste a link or name the report. Outside the
  United States and the European Union, *Data sent to Azure OpenAI can
  be processed outside your capacity's geographic region, compliance
  boundary, or national cloud instance* must be on.
- **The model's Copilot access setting**, above.
- **Sensitivity labels**: a conversation takes the most restrictive
  label among the content it used, what it creates inherits that, and a
  DLP policy can keep a label's content from Copilot altogether.

Search sees a report's name, description, page names, chart titles and
the names of the columns and measures it uses. The metadata page lists
no semantic model among what that setting sends, and a report a reader
reaches only by an org-wide link is not found
([Share data with your Microsoft 365 services](https://learn.microsoft.com/fabric/admin/admin-share-power-bi-metadata-microsoft-365-services),
read 2026-10-15). By that table, a model's columns and measures reach
search only where a report uses them.

A reader points Copilot at content by pasting the report's address-bar
URL, since share links are not supported, by attaching it under **+** >
**Other**, or by naming it. A model is not in the attachment menu, but
its pasted URL answers from the model alone, with no visuals to ground
the answer. A report in an org app takes attachment or its name, not a
pasted link; paginated reports, dashboards and top-level apps are
unsupported; and a data agent or ontology answers only through a
published Microsoft 365 agent, which the fabric-iq skill's data agent
reference covers. Answers reflect the last successful refresh.

The Copilot Chat page mentions no AI instructions, AI data schema or
verified answers, so the caveat above stands. Learn's Cowork page claims
verified answers and schema selection for Cowork, a Frontier surface,
and the metadata page still calls Copilot Chat's Power BI answers
Frontier, against the overview's GA (both read 2026-10-15).

---

## When you use this vs. Data Agent instructions

- **Semantic Model AI Instructions** — guidance attached to one semantic model. No multi-source routing, no conversational flow. Applies to every Copilot interaction with this model.
- **Data Agent** — a separate conversational interface with multi-source routing, few-shot example queries, and conversational response formatting.

See the fabric-iq skill's data agent reference for data agent specifics.
A data agent over this model takes no example queries, and verified
answers, which Learn says steer its DAX, did not in one test: the caveat
is in that skill's `references/data-agent/data-agent.md`, § The four
configuration layers.

---

## Setup process

Authoring is now available in **both** Power BI Desktop and the Power BI service. Consumption happens everywhere Copilot exists.

1. Open the semantic model in Power BI Desktop, or select the model in the Power BI service.
2. On the **Home** ribbon, click **Prep data for AI**.
3. If the tabs are disabled, enable **Power BI Q&A** on the model first. Q&A itself is retiring: February 2027 on every Q&A page and in Microsoft's extension notice, December 2026 on `semantic-model-best-practices` (both read 2026-10-06).
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
- **Column and measure descriptions** — these belong on the column or measure itself, as `///` lines above it in TMDL (`fabric-tmdl`).
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
- **Changes arriving by Git or a deployment pipeline need a service refresh.** AI instructions and AI data schemas save to the model's linguistic schema (LSDL). An LSDL change that arrives through Git sync or a deployment pipeline takes effect only after the model is refreshed in the Power BI service, and DirectQuery and Direct Lake models sync it only once a day ([Prep data for AI](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai), Considerations and limitations; confirmed 2026-09-11). Until that refresh, a shipped instructions change looks as if it silently failed.
- **Verified answers never travel with the model.** They are stored in
  it, yet Git integration, REST APIs and deployment pipelines don't
  support them, so each stage needs its own, made by hand, and Copilot
  returns none while Fabric IQ is on. Hidden fields and visuals with
  report measures break them
  ([Verified answers](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai-verified-answers),
  Considerations and limitations, read 2026-10-08).

---

## Testing and maintenance

- Maintain a **regression question bank** (50–100 representative questions with approved answers).
- Re-run the bank after any material change to the instructions or the model.
- Track accuracy over time. Investigate any degradation immediately.
- Version control the instructions blob with the model: a service
  edit's next portal commit wrote it into
  `definition/cultures/<culture>.tmdl`, as the `CustomInstructions` key
  of the culture's `linguisticMetadata` (observed 2026-10-07), so Git
  sync and deployment carry it, and `getDefinition` returned it there
  too, with no `Copilot/` part (2026-10-14). Learn's semantic model
  definition example also lists a `Copilot/Instructions/instructions.md`
  part, undescribed; what writes one, and whether a Power BI Desktop
  save does, is unverified
  ([SemanticModel definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition),
  read 2026-10-14).
- Assign ownership: who approves changes, who maintains descriptions, who signs off on new rules.

---

## Key differences from Data Agent instructions

- **Structure** — semantic model is one unstructured blob; data agent has four configuration layers (agent, data source, description, example queries).
- **Multi-source** — semantic model applies to exactly one model; data agent routes across up to 5 sources.
- **Example queries / few-shot** — not available on the semantic model; dedicated feature on the data agent (but not on semantic-model data sources within the agent).
- **Response formatting and conversational behavior** — explicitly out of scope for the semantic model; configurable on the data agent.
- **Character limit** — semantic model is capped at 10,000; data agent has no single documented hard cap.
- **Consumption surface** — semantic model instructions apply everywhere Copilot uses the model (reports, Q&A, the Copilot pane, downstream consumers; Microsoft 365 Copilot Chat unconfirmed, as above); data agent instructions apply only within the agent chat.
- **Visibility to end users** — neither is visible to end users in the UI.

---

## Reference

- Microsoft Learn: [Prepare your data for AI: AI instructions](https://learn.microsoft.com/en-us/power-bi/create-reports/copilot-prepare-data-ai-instructions)
- Microsoft Learn: [Prep data for AI overview](https://learn.microsoft.com/en-us/power-bi/create-reports/copilot-prepare-data-ai)
- Microsoft Learn: [Verified answers](https://learn.microsoft.com/en-us/power-bi/create-reports/copilot-prepare-data-ai-verified-answers)
- Comprehensive MS Learn link bundle (overview / instructions / verified answers / Q&A linguistic schema / tutorials): [§ MS Learn link bundle](#ms-learn-link-bundle), below

---

## MS Learn link bundle

Curated set of Microsoft Learn pages relevant to authoring AI instructions on a Power BI semantic model and the broader "Prep data for AI" surface. Load on demand when you need authoritative reference for a specific feature (instructions blob, verified answers, AI data schema, linguistic schema / Q&A).

The three highest-leverage entry points (instructions, prep-for-AI overview, verified answers) are also linked in § Reference above for in-context use; this section holds the comprehensive set.

### Overview and feature catalog

- [Prepare your data for AI (overview)](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai) — the four "Prep data for AI" features (AI data schemas, verified answers, AI instructions, descriptions) and where each is authored (Desktop vs service).
- [Prep data for AI — FAQ](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai-faq) — Microsoft's compact summary of which feature does what. Useful as an at-a-glance refresher when triaging where a particular concern belongs.

### AI instructions blob (the 10K-character text attached to the model)

- [Prepare your data for AI: AI instructions](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai-instructions) — authoritative reference for the AI instructions feature: what it is, how to author, where it applies, limitations. Microsoft's primary doc for the surface this file covers.

### Companion features (often paired with AI instructions)

- [Prepare your data for AI: Verified answers](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai-verified-answers) — the visual + trigger-phrase mechanism. Use Verified Answers instead of stuffing Q&A pairs into the AI instructions blob.
- [Prepare your data for AI: AI data schemas](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai-data-schema) — selecting a subset of the model schema for Copilot consumption. Distinct from the instructions blob and from per-column hide flags.

### Tutorial and best-practice walkthroughs

- [Tutorial: Prepare semantic model for AI](https://learn.microsoft.com/power-bi/create-reports/tutorial-copilot-power-bi-prepare-model) — end-to-end tutorial: simplify schema, add verified answers, write AI instructions, mark as Prepped for AI. Good hands-on starting point.
- [Use Copilot with semantic models (developer guidance)](https://learn.microsoft.com/power-bi/create-reports/copilot-semantic-models) — broader guidance for building Copilot-friendly models: naming conventions, descriptions, linguistic schema, DAX query view tips. Covers the whole authoring surface this file is one part of.
- [Ask Copilot for data from your model](https://learn.microsoft.com/power-bi/create-reports/copilot-ask-data-question) — consumer-facing perspective on how Copilot uses the model when answering questions. Useful for understanding what your authoring is in service of.

### Microsoft 365 Copilot Chat

- [Fabric IQ in Microsoft 365 Copilot Chat](https://learn.microsoft.com/fabric/iq/connectors/microsoft-365-copilot-overview) — the reader's licence, the three tenant settings, and what Copilot Chat can and can't answer from.
- [Share data with your Microsoft 365 services](https://learn.microsoft.com/fabric/admin/admin-share-power-bi-metadata-microsoft-365-services) — the metadata Fabric sends to Microsoft 365 for search and attachment, property by property.
- [Use Power BI data in Microsoft Copilot](https://learn.microsoft.com/microsoft-365/copilot/copilot-powerbi-copilot-chat) — the Microsoft 365 admin center side: who may use Fabric data in Copilot.

### Linguistic schema (Q&A — overlaps with but is distinct from AI instructions)

- [Q&A best practices](https://learn.microsoft.com/power-bi/natural-language/q-and-a-best-practices) — naming, synonyms, relationships. Per-column synonyms belong in TMDL `synonyms`, not in the AI instructions blob — this page explains the right home.
- [Enable Q&A and Q&A data sources](https://learn.microsoft.com/power-bi/natural-language/q-and-a-data-sources) — turning Q&A on for the model (prerequisite for the "Prep data for AI" tabs to be enabled in Desktop and service). Its banner dates Q&A's retirement February 2027; `semantic-model-best-practices` still says December 2026 (2026-10-06).
- [Intro to Q&A tooling](https://learn.microsoft.com/power-bi/natural-language/q-and-a-tooling-intro) — the Q&A setup window where synonyms and linguistic relationships live, with Copilot-suggested options.
