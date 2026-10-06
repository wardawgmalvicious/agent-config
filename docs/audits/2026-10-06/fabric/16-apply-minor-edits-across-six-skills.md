# Handoff: apply the minor edits across six skills

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 19
- **Kind**: independent minor edits and one flag across six skills.
  Content only. Each D-section is its own task and can land alone.
- **Target**:
  - `skills/fabric/fabric-ai-functions/SKILL.md` (line 189)
  - `skills/fabric/fabric-database/SKILL.md` (lines 17–29)
  - `skills/fabric/fabric-security/SKILL.md` (lines 85, 87)
  - `skills/fabric/fabric-catalog-governance/SKILL.md` (lines 11–13,
    276–279)
  - `skills/fabric/fabric-semantic-model-audit/SKILL.md` (lines 253,
    264–266, 324)
  - `skills/fabric/fabric-semantic-model-ai-instructions/SKILL.md`
    (line 21)

## D-1 — fabric-ai-functions: the Warehouse function list

**Symptom.** `SKILL.md:189` reads "T-SQL functions `ai_summarize`,
`ai_classify`, `ai_generate_response` (see `fabric-warehouse`)". But
`fabric-warehouse` has no AI-function content, so the pointer leads
nowhere.

**Evidence.** In `91e49056`, the preview row "AI functions in Fabric
Data Warehouse (preview)" was renamed "Warehouse AI functions
(preview)". Learn,
https://learn.microsoft.com/en-us/fabric/data-warehouse/ai-functions
(agent-measured), lists seven functions, adding `AI_ANALYZE_SENTIMENT`,
`AI_EXTRACT`, `AI_TRANSLATE` and `AI_FIX_GRAMMAR`. The page also says
"`NULL ON ERROR` (default) returns `NULL` when the function can't
process a value." and "This feature is in preview."

**Fix.** List all seven functions with the `ON ERROR` clause, mark them
preview, and replace the dangling pointer with the Learn link. Nothing
for `fabric-warehouse` to absorb was recommended.

## D-2 — fabric-database: vector support

**Symptom.** The Warehouse-vs-SQL database table at `SKILL.md:17-29` has
no vector row. Its last row is "| Full-text search | Not supported |
Fully supported |".

**Evidence.** What's New `80a24c9b` added "Vector indexes and vector
search in SQL database in Fabric (Generally Available)", September 2026.
Learn, https://learn.microsoft.com/sql/sql-server/ai/vectors?view=sql-server-ver17
(agent-measured): "Vector indexes are generally available in Azure SQL
Database, SQL database in Fabric, and Azure SQL Managed Instance". The
index needs "at least 100 rows with non-`NULL` vector values". The
Warehouse T-SQL surface page lists "Vector data type and search
functions" among its limitations.

**Fix.** Add a vector row: Warehouse not supported; SQL database GA,
with the 100-row minimum for an index.

## D-3 — fabric-security: OneLake security roles

**Symptom.** `SKILL.md:85` reads "Supported items: Lakehouse (`Read`,
`ReadWrite`), Azure Databricks Mirrored Catalog (`Read`), Mirrored
Databases (`Read`)." `:87` reads "every user with the `ReadAll`
permission".

**Evidence.** What's New added "OneLake security Members and Data UX
(Generally Available)". The row itself is UX-only, but its linked pages
say more (agent-measured):

- https://learn.microsoft.com/en-us/fabric/onelake/security/create-manage-roles
  has the row "| Mirrored catalogs | Read |".
- https://learn.microsoft.com/fabric/onelake/security/data-access-control-model
  has "| Mirrored catalog | `DefaultReader` | Read | All users with Read
  permission |". So `DefaultReader` membership differs by item type.

**Fix.** Add mirrored catalogs to the supported items, and qualify the
`DefaultReader` membership by item type.

## D-4 — fabric-catalog-governance: Govern areas and table discovery

**Symptom.** `SKILL.md:11-13` reads "The OneLake catalog's **Govern**
tab reports a tenant's governance posture across three areas".
`:276-279` limits search to display name, description and workspace
name.

**Evidence.**

- **Govern.** What's New `9eda27f8` added "OneLake catalog Govern
  experience (Generally Available)". Learn,
  https://learn.microsoft.com/en-us/fabric/governance/onelake-catalog-govern:
  "Policies — define and apply governance policies across your Fabric
  estate." The three area names, the daily refresh and the Private Link
  limit still match.
- **Table discovery.** "OneLake Catalog table discovery (Preview)" adds
  search by table name and column name. The Search API reference,
  https://learn.microsoft.com/en-us/rest/api/fabric/core/catalog/search,
  still reads "This field supports searching across the display name,
  workspace display name, and description of the CatalogEntry." So the
  extension is documented only in a blog post.

**Fix.** Add Policies and the admin experiences to the Govern
description (minor edit). Add table discovery as a dated flag only, not
an edit, until the reference documents it.

## D-5 — fabric-semantic-model-audit: Plan, advanced DAX generation, M365 Copilot

**Symptoms and evidence.**

- `SKILL.md:324` reads "Plan is a preview workload." The base GA table
  dated "Planning (Generally Available)" July 2026, and `ecb721f5`
  renamed that row "Plan". Learn,
  https://learn.microsoft.com/en-us/fabric/iq/plan/overview: "Planning
  in Fabric IQ is now available worldwide as part of the Microsoft
  Fabric SKU." Note that `fabric-ontology` (`SKILL.md:21-23`) and the
  deployment-pipeline list still label Plan "(preview)". Both match
  Learn's IQ-items and pipeline lists, so leave them.
- `SKILL.md:264-266` reads "the DAX generation tool reads only model
  metadata and Prep-for-AI configuration — it **ignores data-agent-level
  instructions**". That still holds. "Advanced DAX generation for
  semantic models (Preview)" was added in `ebc6f751`. Learn,
  https://learn.microsoft.com/en-us/fabric/data-science/semantic-model-best-practices,
  adds two things. "It searches values within semantic model columns to
  generate more accurate and reliable filters" (on the preview runtime,
  with Q&A on). And "unlike other data sources, data agent doesn't
  support data source instructions or descriptions for semantic models."
- `SKILL.md:253` reads "One pass per consumer", but has no pass for
  Fabric IQ in Microsoft 365 Copilot (GA, `9eda27f8`). Learn,
  https://learn.microsoft.com/en-us/fabric/iq/connectors/microsoft-365-copilot-overview:
  "Data answering from Power BI content in Microsoft 365 Copilot Chat is
  a generally available (GA) feature of Microsoft Fabric."

**Fix.** Mark Plan GA. Add the value search and its Q&A dependency, and
the missing source-level instructions, to the DAX-generation passage.
Add the M365 Copilot consumer to the per-consumer passes.

**Knock-on.** `fabric-data-agent/references/configuration-layers.md:94`
reads "Keep the data-source-level instructions here lean to avoid
duplication." Learn contradicts that for semantic-model sources. Fix it
in the same pass if brief 07 has not, since it is the same fact.

## D-6 — fabric-semantic-model-ai-instructions: M365 Copilot consumer

**Symptom.** The consumer list at `SKILL.md:21` is missing Fabric IQ in
Microsoft 365 Copilot.

**Fix.** Add the consumer, using the same Learn quote as D-5.

## Verification

1. Per skill, `grep` the quoted line and confirm it is updated. For
   example: `grep -n "Plan is a preview" skills/fabric/fabric-semantic-model-audit/SKILL.md`
   returns nothing.
2. `uv run --with pyyaml scripts/lint-frontmatter.py` on each edited
   `SKILL.md`.
3. `pre-commit run --all-files`

## Provenance

Found during the 2026-10-06 `/drift-audit` run against `fabric` (floor
2026-09-01). D-1 and D-2 came from the warehouse/Spark mapping subagent,
D-3 and D-4 from the platform subagent, and D-5 and D-6 from the IQ
subagent. All Learn quotes are the agents' own. The six items share
nothing but their size, so split them freely at execution time.
