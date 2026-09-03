# Skill handoff brief: fabric-semantic-model-audit

Last verified: 2026-09-02

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

`skills/fabric/fabric-semantic-model-audit/SKILL.md`, plus
`references/REFERENCE.md`. Deploys by junction to
`~/.claude/skills/fabric-semantic-model-audit/`. The `fabric/` group
directory is not optional — the pre-commit hook matches
`^skills/[^/]+/[^/]+/SKILL\.md$` and Claude Code discovers skills exactly
one level under the skills root.

Note this group is **pruned from user scope on this machine**
(`-SkillGroups workflow`), so authoring it changes no session's payload
until the prune is lifted. That is what makes it safe to author on a
branch, and it is also why `/test-skill` has to deploy it deliberately.

**A mid-run reading of `~/.claude/skills` is not the standing state.**
On 2026-09-02 a concurrent session counted 37 junctions there — the 8
workflow skills plus all 29 `fabric-*` — and recorded here that the
machine runs `-SkillGroups workflow,fabric` and that the prune "is not
in effect". It was reading `/test-skill` Phase B, which deploys
`workflow,fabric` deliberately and restores the prune when it finishes.
The count was 8 before that run and 8 after. Take the standing state
from root `CLAUDE.md` plus a `link-claude.ps1` run, never from an `ls`
that may have landed inside another session's test window — and note
that the inference drawn from it inverted too: because the fabric group
*is* pruned, authoring this skill changed no session's payload at any
point.

## Scope

A **review procedure over an existing semantic model** — the first thing
in the payload that is not authoring guidance. It takes a finished model
and reports on four dimensions: star-schema shape, relationship health,
memory and query cost, and downstream readiness (report, AI-instructions
blob, data agent, ontology). Inline, model-invocable and `/`-invocable,
**no `paths:` glob**. An audit is a discrete act you ask for; a glob on
`**/*.SemanticModel/**` would co-load it with `fabric-tmdl`,
`fabric-tmdl-api` and `coding-tmdl.md` on every one-line measure edit.
Design and performance are deliberately **one skill**, because a single
finding is routinely both.

## Sources drilled

Drilled 2026-09-02, all first-party unless noted:

- [`power-bi/transform-model/desktop-relationships-understand`](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-relationships-understand)
  — cardinality types; cross-filter direction and the bi-directional
  performance/ambiguity warning; active vs. inactive and the
  "generally, we recommend defining active relationships whenever
  possible… role-playing dimension tables should be duplicated"
  remediation; **regular vs. limited** as an *inferred* property;
  table expansion, `LEFT OUTER JOIN` semantics and blank virtual rows;
  the exact sentence **"Inactive relationships are also expanded, even
  when the relationship isn't used by a calculation"**; ambiguity
  resolution by priority tier and weight; the four-step performance
  ordering; `DateTime`-column key mismatch; disconnected tables as
  legitimate; Assume referential integrity as DirectQuery-only with
  silent understatement.
- [`power-bi/guidance/star-schema`](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema)
  — dimension/fact classification is **determined by relationship
  cardinality, not a table property**; the snowflake trade-off with its
  four named costs including "it's not possible to create a hierarchy
  that comprises columns from more than one table"; role-playing
  dimensions and the duplicate-the-table technique with its stated cost;
  SCD 1/2; junk, degenerate and factless fact tables; the
  "part science and part art" hedge; the degenerate-dimension carve-out
  ("an exception to the formerly introduced rule").
- [`fabric/data-science/semantic-model-best-practices`](https://learn.microsoft.com/en-us/fabric/data-science/semantic-model-best-practices)
  — the "Common pitfalls to avoid" list, including **"Not using star
  schema"** stated as a defect in as many words; the governance point
  that the DAX generation tool **ignores data-agent-level instructions**
  and reads only model metadata + Prep for AI; the recommended
  implementation workflow.
- [`power-bi/transform-model/service-notebooks`](https://learn.microsoft.com/en-us/power-bi/transform-model/service-notebooks)
  — BPA 60+ rules in five categories; Memory Analyzer object list; the
  three entry points; build permission + Fabric capacity + contributor;
  **"Notebooks fail to run if the semantic model name ends with a
  whitespace."**
- `sempy.fabric` API reference — exact signatures for `run_model_bpa`
  and `model_memory_analyzer`, the `return_dataframe` / `export`
  parameters, the memory analyzer's six dict keys, and the **ReadWrite**
  requirement stated on both (they go through TOM). Also
  `list_datasets` / `list_tables` / `list_measures` / `read_table`,
  which go over **XMLA** and need XMLA read-only enabled — a *second,
  different* permission gate from the TOM one.
- [`fabric/data-science/semantic-link-overview`](https://learn.microsoft.com/fabric/data-science/semantic-link-overview)
  — **"Use of semantic link is supported only in Microsoft Fabric"**;
  in the default runtime from Fabric Runtime 1.2 (Spark 3.4) up.
- [`fabric/fundamentals/direct-lake-understand-storage`](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-understand-storage)
  — **the source of this brief's biggest correction.** Join indexes are
  generated **at query time** for the tables a DAX query touches, not
  at refresh; cold/semiwarm/warm/hot residency; join indexes are evicted
  under memory pressure; V-Order, segment size, cardinality and
  destructive Delta update patterns as the actual Direct Lake
  performance levers.
- [`fabric/fundamentals/direct-lake-overview`](https://learn.microsoft.com/fabric/fundamentals/direct-lake-overview)
  (considerations and limitations, storage-mode comparison) — calculated
  tables **preview on Direct Lake on OneLake, unsupported on Direct Lake
  on SQL**; **"Adding multiple tables from the same data source table"
  is not supported in Desktop or web modeling**; one-side columns must
  be unique or queries fail; related columns must have matching types;
  **web modeling issues no validation queries for Direct Lake
  cardinality or cross-filter selections**.
- [`power-bi/transform-model/desktop-calculated-columns`](https://learn.microsoft.com/power-bi/transform-model/desktop-calculated-columns)
  — Direct Lake on OneLake calculated columns are User Context only,
  unmaterialized, and **"can't be used in relationships."**
- [`microsoft/fabric-toolbox` → `Semantic Model Data Agent Checklist.md`](https://github.com/microsoft/fabric-toolbox/blob/main/samples/data_agent_checklist_notebooks/Semantic%20Model%20Data%20Agent%20Checklist.md)
  — the brief's flagged must-read. Verdict: its **Semantic Model
  Optimization** section is a usable general check list and is folded
  into `references/`; the other four sections are data-agent
  configuration and defer to `fabric-data-agent`. Two items it has that
  no Learn page in this set states: **report-scoped measures are not
  accessible to the Data Agent** (move them into the model), and
  **row label** on dimension tables.
- Repo bytes: `claude/rules/coding-tmdl.md`, `skills/fabric/fabric-tmdl`,
  `skills/powerbi/pbid-tom-live`, `skills/powerbi/pbir-report-workflow`
  (the `scripts/data/` citation idiom at line 289),
  `internal-tooling/local-cli/dax.sh` (header caveats and the four `-s`
  projections, read verbatim rather than quoted from the prior brief).
- Reference model: `ACME_SM_Operation.SemanticModel` `definition/`,
  re-measured rather than taken from the prior brief. See
  [Notes](#notes) — the figures reproduce and one conclusion does not.

Not drilled, deliberately:

- The four relationship drill-throughs (`relationships-active-inactive`,
  `relationships-bidirectional-filtering`, `relationships-many-to-many`,
  `relationships-one-to-one`). Each is a whole article behind a link
  followed above; the parent page's summary of each is what the skill
  encodes. **These are the obvious next pass** if a dimension needs more
  depth.
- `import-modeling-data-reduction`. Nothing in the skill describes
  import-side data-reduction technique.
- The Tabular Editor BPA rule set as published, and the
  `Data Agent Utilities.ipynb` notebook. The skill names BPA's five
  categories and rule count from the Learn page; it does **not**
  enumerate rules, and says so.
- `delta-optimization-and-v-order` and `table-maintenance-optimization`.
  Direct Lake Delta-side tuning is named as the lever and pointed at,
  not encoded — that is lakehouse work, not model work.
- Power BI MCP servers (`powerbi-modeling-mcp` and the remote one). See
  [Cross-reference dependencies](#cross-reference-dependencies) — this
  is the deliberate spin-off, not part of the skill.
- **A dead end, carried forward from the source brief so it is not
  retried**: the Fabric Community notebook-gallery post on BPA +
  VertiPaq Analyzer returns HTTP 403 to `WebFetch`. Its subject is
  `semantic-link-labs`, whose functions are first-party documented
  above. Nothing was lost.

## Frontmatter

```yaml
---
name: fabric-semantic-model-audit  # repo linter requires it; max 64 chars; lowercase/digits/hyphens
description: <see draft — trigger vocabulary plus three disambiguations>  # gated at 1,024
disable-model-invocation: false  # ALWAYS PRESENT; repo policy: false everywhere
model: inherit  # ALWAYS PRESENT; repo policy: inherit everywhere except commit
# effort: max   # ALWAYS PRESENT as value or commented placeholder; commented = inherits session level. Repo policy: commented on platform skills
---
```

No `paths:` — see [Scope](#scope). No `when_to_use`: this lands in the
**unconditional** skills whose descriptions sit permanently in the
listing, which is exactly where the field is *not* near-free.
[when-to-use-adoption.md](when-to-use-adoption.md) owns that call for the
unconditional half; adding it here would pre-empt it. No `allowed-tools`
— the skill reads files and may shell out to a repo's own wrapper script,
both of which the session already governs.

## Description char count

- `description`: 964 / 1,024
- `when_to_use`: N/A — not set (see Frontmatter)

## Body structure outline

`SKILL.md` — procedure, tensions, and the tier table:

1. **What this is** — a review of a finished model, not authoring.
   One-line boundary against `fabric-tmdl` / `coding-tmdl.md` /
   `code-review`.
2. **Establish storage mode first.** The gate on everything downstream;
   getting it wrong is the skill's main way of producing a confidently
   wrong answer.
3. **Three evidence tiers** — table: offline TMDL / `dax.sh` `INFO.VIEW`
   / Fabric notebook. Explicitly *not* a fallback chain. Carries the
   conditional-accelerator idiom for `scripts/data/dax.sh` and the
   `pbid-tom-live` hand-off for local Desktop models.
4. **Dimension 1 — shape**, and the flatten tension with a citation on
   each side, plus the sanctioned exceptions (degenerate, junk,
   disconnected) an audit must not flag.
5. **Dimension 2 — relationship health.** The checks in detection order,
   each with its remediation and the remediation's stated cost.
6. **Dimension 3 — memory and query cost**, split by storage mode.
7. **Dimension 4 — downstream readiness.** One short paragraph per
   consumer, each deferring to the skill that owns it.
8. **Reporting the findings** — per-finding shape, and the
   part-science-part-art hedge.
9. **Constraints** — the permission false-negatives, the storage-mode
   trap, and what this skill does not do.

`references/REFERENCE.md` — the long tail:

- The check catalogue as a table (check, tier, evidence, remediation).
- `INFO.VIEW` invocations and the four `dax.sh -s` projections verbatim.
- `sempy.fabric` signatures, permission gates, and the notebook entry
  points.
- The star-schema pattern vocabulary (surrogate/snowflake/role-playing/
  SCD/junk/degenerate/factless) as definitions with remediations.
- The Direct Lake constraint table relevant to remediation.
- The `fabric-toolbox` checklist's optimization section, mapped to
  dimensions.

## Changes from source proposal

Derived from
[skill-semantic-model-audit.md](skill-semantic-model-audit.md) (wave 13).
Departures, all from drilling done in this run:

1. **The headline fusion argument is narrowed to import mode.** The
   source brief generalized "inactive relationships are also expanded"
   into a claim about the reference model. That sentence is on an
   article headed *"This article targets import data modelers"*, and
   Direct Lake's own page says join indexes are built **when a query
   needs them**. The fusion of design and performance survives — it just
   rests on two mechanisms instead of one, and the skill says which
   applies where. Whether Direct Lake pre-builds join indexes for
   *inactive* relationships is **not documented**; the skill says that
   rather than guessing.
2. **The reference model's role-playing dimension is `Customer`, not
   `DimDate`.** See [Notes](#notes). The source brief's `DimDate`
   conclusion is a false positive, and it becomes the worked example of
   the counting rule that avoids it.
3. **A fourth tool tier exists** — `pbid-tom-live` and the VertiPaq
   DMVs. The source brief said the notebook tier is "the only path to
   column-level memory and cardinality"; that is true for Direct Lake
   and false for import models on a machine with Power BI Desktop. The
   skill defers rather than duplicating.
4. **The `fabric-toolbox` checklist was read** (the source brief flagged
   it as must-read-before-drafting and left it undrilled). It is
   partly curation, partly out of scope — recorded above.
5. **Helper notebook: confirmed not shipped in v1**, on the source
   brief's own reasoning plus one addition — Microsoft ships the stock
   notebooks from three entry points, so the marginal value is low and
   the artifact class is new to this repo.
6. **Direct Lake makes the recommended remediation materially harder**,
   which the source brief did not carry: duplicating a role-playing
   dimension runs into "adding multiple tables from the same data source
   table" being unsupported in Desktop and web modeling, calculated
   tables being preview-only on OneLake and absent on SQL, and Direct
   Lake calculated columns being unusable in relationships. An audit
   that prescribes the import-mode fix to a Direct Lake model is wrong.

## Tag

`personal`

## Portability caveats

N/A — personal scope. Nothing Claude-Code-only is relied on: no
`context: fork`, no hooks, no `allowed-tools`, no `paths:`, and `effort`
is left commented.

## Cross-reference dependencies

- `fabric-ontology` — (a) already exists. **Cite, do not restate**: the
  generation-constraint matrix is its "Generating an ontology from a
  semantic model" section and `references/REFERENCE.md` §5. Wave 12
  discharged this dependency.
- `fabric-data-agent` — (a) exists. Owns agent configuration; this skill
  keeps only the model-shape consequences.
- `fabric-semantic-model-ai-instructions` — (a) exists. Owns the
  10,000-char Copilot blob, which is a different artifact from the model.
- `fabric-tmdl`, `claude/rules/coding-tmdl.md` — (a) exist. Own
  authoring. **One live tension, flagged not fixed**: `fabric-tmdl`
  line 60 reads "`isActive: false` for role-playing dimensions; use
  `USERELATIONSHIP()` in DAX", which is the pattern Microsoft's
  relationships page recommends *against* by default. This skill will
  flag models built to that advice. `/author-skill` forbids editing
  another skill, so this is raised as a follow-up, not resolved here.
- `pbid-tom-live` — (a) exists. Owns local Desktop TOM/ADOMD scripting
  and the VertiPaq DMVs. Not usable for Direct Lake or thin reports.
- `code-review` — (a) exists. Diff-scoped; this is corpus-scoped.
- `scripts/data/dax.sh` — (c) external. A **conditional** accelerator
  present only where the internal-tooling local-cli template is deployed.
  Cite it the way
  [`pbir-report-workflow/SKILL.md:289`](../../../skills/powerbi/pbir-report-workflow/SKILL.md#L289)
  does — "if a wrapper is deployed in the repo, prefer it" — never as a
  dependency. Skills load at user scope in repos that have no
  `scripts/data/`.
- Power BI MCP template for `claude/mcp/` — (b) **deliberate spin-off,
  not part of this skill.** Different artifact, directory and deployment
  path. If it lands, this skill gains one conditional sentence pointing
  at it.

## Claude Code's post-draft checklist

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**The reference model was re-measured, not trusted.** Every headline
figure in the source brief reproduces exactly: 17 tables (16
`directLake`, 1 `import`), 26 relationships, **7** `isActive: false`,
**0** `crossFilteringBehavior`, 141 KB, and exactly **four** tables on
both sides — `Customer`, `CustomerOrder`, `Invoice`, `Item`.

**One conclusion does not, and it is the more useful outcome.** The
source brief read "`DimDate` is on the to-side of four relationships"
as a role-playing dimension implemented against Microsoft's advice.
Resolving the four shows three different fact tables:

| From | To | Active |
| --- | --- | --- |
| `CustomerOrder.CustomerOrderDate` | `DimDate.Date` | yes |
| `Invoice.InvoiceDate` | `DimDate.Date` | yes |
| `Job.JobScheduleStartDate` | `DimDate.Date` | yes |
| `Job.JobScheduleEndDate` | `DimDate.Date` | **no** |

Three of the four are one active relationship per fact table, which is a
shared date dimension working exactly as intended. Only `Job` reaches
`DimDate` twice. **The counting rule is per (fact table, dimension
table) pair, not per dimension** — count a dimension's total inbound
relationships and every shared date table in existence looks defective.
This is the skill's headline false-positive guard.

The real role-playing dimension is **`Customer`**, which the source brief
did not identify: `Invoice` and `CustomerOrder` each reach
`Customer.CustomerId` twice, on `AnalysisCustomerId` (active) and
`AnalysisShipToId` (inactive) — bill-to and ship-to, the textbook case.

**And the sharper finding is reachability.** The model contains exactly
**one** `USERELATIONSHIP` call, in `_MeasuresTable.tmdl:341`, on
`Invoice[AnalysisShipToId]` → `Customer[CustomerId]`. So **6 of the 7
inactive relationships have no measure that can ever activate them.**
That is a stronger and more actionable finding than the count alone, it
is computable entirely offline, and it is storage-mode independent.

Two smaller offline observations worth carrying as checks: the model
declares **no** `fromCardinality`/`toCardinality` and **no** `isKey`
anywhere, so every relationship sits on TMDL defaults — and per the
Direct Lake limitations page, web modeling issues no validation queries
for Direct Lake cardinality selections, so those defaults were never
checked against data. `DimDate` does carry `dataCategory: Time`.

**Revised acceptance test for `/test-skill`**, replacing the source
brief's: a passing run must independently reach (1) the four both-sides
tables, (2) 7 inactive relationships of which **6 are unreachable**,
(3) `Customer` as the role-playing dimension, and (4) **must not**
report `DimDate` as one.

## Confidence

- **Structure and frontmatter — H.** Follows `fabric-ontology` and
  `fabric-data-pipeline` exactly; the no-`paths:` call is the source
  brief's, reconfirmed against the co-load argument.
- **Body content — H for design and relationships, M for Direct Lake
  memory.** The design half is dense first-party citation. The Direct
  Lake half rests on one page that describes join-index construction for
  *queries* and is silent on inactive relationships specifically; the
  skill states that silence rather than resolving it.
- **Notebook tier — M, and unexercised.** Signatures and permission
  gates are from the API reference, but semantic link has no local entry
  point, so **nothing in that section can be validated from this
  machine.** It must ship marked documented-but-unexercised.
