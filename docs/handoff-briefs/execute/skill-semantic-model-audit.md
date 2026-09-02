# Handoff: a semantic-model audit skill

- **Written**: 2026-09-02, from a coverage question raised against
  `C:\Repos\ACME\fabric-acme\Analytics\ACME_SM_Operation.SemanticModel` and
  the Fabric IQ ontology docs. **Revised the same day** after drilling
  the Power BI relationship/star-schema guidance and the semantic-link
  notebook surface — see [Revision note](#revision-note).
- **Kind**: coverage decision, then `/author-skill`.
- **Status**: open. **Recommendation: yes, author it** — as
  `fabric-semantic-model-audit`, a *review procedure over an existing
  model*, explicitly not a second set of authoring conventions.
- **Run in**: a fresh session. Start with `/author-skill` once steps 1
  and 2 resolve.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.
- **Siblings**: [item-type-skill-ontology.md](item-type-skill-ontology.md)
  owns the Ontology *item*; this skill consumes its generation
  constraints as one audit dimension. Author ontology first if you are
  doing both — the constraint matrix is drilled there.

## Revision note

The first draft of this brief listed the Power BI star-schema and
relationship guidance as **"not yet drilled"** and named performance as
an open question. Both are now drilled. Three things changed as a
result, and they are the reason to re-read rather than skim:

1. **Performance is not a separate skill.** The evidence is in
   [step 2](#step-2--performance-is-the-same-skill-not-a-second-one), and
   it is a mechanical argument, not a taste one.
2. **The flatten tension now has a citation on each side**, including
   Microsoft stating the anti-flatten case in as many words.
3. **A major source was missing entirely** —
   `fabric/data-science/semantic-model-best-practices`, which is close to
   a ready-made checklist for one of the audit's dimensions.

## The gap

Everything in the payload that touches a semantic model is **authoring**
guidance — applied while you type, against the line you are typing. There
is no procedure for standing back from a finished model and reporting on
its shape.

| What exists | Glob | What it is |
| --- | --- | --- |
| `claude/rules/coding-tmdl.md` | `**/*.tmdl` | Conventions. Its entire modelling content is a "Relationships" section of four bullets — the first is the whole line **"Star schema by default."** — plus four anti-patterns. |
| `fabric-tmdl` | `**/*.tmdl`, `**/*.SemanticModel/**` | TMDL syntax, measure patterns, RLS, calculation groups. |
| `fabric-tmdl-api` | `**/*.SemanticModel/**` | The definition REST API. Deployment, not design. |
| `fabric-semantic-model-ai-instructions` | `**/definition/cultures/*.tmdl` | A *different artifact* — the 10,000-char Copilot blob. Not the model. |
| `code-review` | (unconditional) | Diff-scoped. Reviews a change, not a corpus. |

"Star schema by default" is correct and it is not a skill. It does not say
how to tell a snowflake from a star in a 17-table model, what the
remediation costs, or when flattening is the *wrong* call.

## The evidence

`Analytics/ACME_SM_Operation.SemanticModel` — read from `definition/` on
2026-09-02:

| Measure | Value |
| --- | --- |
| Tables | 17 (16 `mode: directLake`, 1 `mode: import` — `_MeasuresTable`) |
| Columns | 231 |
| Relationships | 26 |
| Inactive (`isActive: false`) | **7 of 26 (27%)** |
| Bidirectional (`crossFilteringBehavior`) | 0 — clean on that axis |
| Definition size | 141 KB |

**Four tables sit on both sides of a relationship** — `Customer`,
`CustomerOrder`, `Invoice`, `Item` each appear as a `fromColumn` owner
*and* a `toColumn` owner. A clean star has facts only on the from-side
and dimensions only on the to-side. Four tables on both sides is a
snowflake chain, stated in the data rather than inferred.

`DimDate` is on the to-side of **four** relationships. Combined with the
7 inactive ones, that is a role-playing date dimension implemented the
way [step 2](#the-single-finding-that-fuses-them) says Microsoft
recommends against.

## Step 1 — settle the two design calls before drafting

**(a) Name.** Repo convention splits behaviour from platform: behavioral
cross-domain skills are the verb you invoke (`commit`, `learn`,
`code-review`, `drift-audit`), platform skills carry a `fabric-` /
`pbir-` / `pbid-` prefix. This one is both.

**Recommend `fabric-semantic-model-audit`, in `skills/fabric/`.** The
domain prefix makes it findable next to the other `fabric-*` model
skills, and `drift-audit` already holds the bare `-audit` verb slot.

**(b) `paths:` — recommend NOT setting one.** A glob on
`**/*.SemanticModel/**` would fire on every TMDL read, co-loading with
`fabric-tmdl`, `fabric-tmdl-api` and `coding-tmdl.md`, so a one-line
measure edit would pull in an audit procedure it has no use for. An audit
is a **discrete act you ask for**. Model-invoked and `/`-invocable,
unconditional. This moves the 24/20 conditional split recorded in
[when-to-use-adoption.md](when-to-use-adoption.md) to 24/21 and puts this
skill where `when_to_use` is *not* near-free.

## Step 2 — performance is the same skill, not a second one

The question raised was whether *semantic model performance* deserves its
own skill. **It does not, and the argument is mechanical.**

### The single finding that fuses them

From
[Model relationships in Power BI Desktop](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-relationships-understand),
on table expansion:

> **Inactive relationships are also expanded, even when the relationship
> isn't used by a calculation.**

For import models, Power BI builds an indexed column-to-column data
structure **for every regular relationship at refresh time**. So the ACME
model's 7 inactive relationships carry a memory cost whether or not any
measure ever calls `USERELATIONSHIP` on them.

That is one finding that is simultaneously a **design** finding (7
unexplained inactive relationships) and a **performance** finding (7
relationship indexes built at every refresh). A skill split down the
design/performance line would have to report it twice or arbitrarily pick
a side. Fuse them instead.

The same page supplies the remediation and it is not the obvious one:

> Generally, we recommend defining active relationships whenever
> possible. **Using only active relationships means that role-playing
> dimension tables should be duplicated in your model.**

And the star-schema guidance agrees, calling per-role duplicated date
tables the "common Power BI modeling technique", with the cost stated
plainly: "duplication of the date dimension table resulting in an
increased model storage size... Because dimension tables typically store
fewer rows relative to fact tables, it's rarely a concern."

So for `DimDate` reached four ways: the recommended fix is **`Date`,
`Ship Date`, `Delivery Date` tables each with one active relationship**,
not seven inactive relationships plus `USERELATIONSHIP` measures. That is
a concrete, citable remediation the audit should be able to produce, with
its cost named.

### The split that *is* real: where the tool runs

Not design vs. performance — **local vs. Fabric-notebook**. This is the
axis the skill must be organised around.

| Tier | Tools | Gets you |
| --- | --- | --- |
| **Offline, no capacity** | TMDL on disk (`definition/**`) | Shape, relationships, cardinality declarations, measure text. Every figure in [The evidence](#the-evidence) came from here with `grep`. Works in CI. |
| **Local, needs auth** | `scripts/data/dax.sh -s tables\|columns\|measures\|relationships` (`INFO.VIEW.*`) | The *live* model — post-binding, post-calculated-column. See [step 4](#step-4--the-shell-scripts-and-the-idiom-for-citing-them). |
| **Fabric notebook ONLY** | semantic link (`sempy.fabric`) | `run_model_bpa()` and `model_memory_analyzer()`. See below. |

**Semantic link cannot run locally.** "Use of semantic link is supported
only in Microsoft Fabric" — which independently confirms the note already
in `dax.sh`'s own header explaining why it is a curl+jq script and not a
SemPy wrapper. The draft must not present these as interchangeable.

What the notebook tier adds, and nothing else in the payload can reach:

- **`sempy.fabric.run_model_bpa()`** — Best Practice Analyzer, **60+
  rules** in five categories: Performance, DAX Expressions, Error
  Prevention, Maintenance, Formatting. Returns a pandas DataFrame with
  `return_dataframe=True`.
- **`sempy.fabric.model_memory_analyzer()`** — VertiPaq statistics.
  Returns a dict of DataFrames keyed `Model Summary`, `Tables`,
  `Partitions`, `Columns`, `Relationships`, `Hierarchies`. This is the
  only path to **column-level memory and cardinality**, which is where
  the real performance findings live.

Both are in `sempy.fabric` — **built into Fabric Runtime 1.2 (Spark 3.4)
and above**, no `%pip install`. `semantic-link-labs` (`import sempy_labs
as labs`) is the *extension* library and is where `get_measure_dependencies`
and `measure_dependency_tree` live; it is also Fabric-notebook-only.

Three hard constraints to carry into the body:

1. **BPA and the memory analyzer both require ReadWrite permission on
   the model** — they go through TOM. That is *stricter* than the
   `INFO.VIEW` read path, and it is a different failure than
   `INFO.VIEW`'s silent blanking of `[Expression]`. Two tools, two
   distinct permission false-negatives; the draft must name both.
2. Notebook creation needs **Fabric capacity** plus contributor on the
   workspace, and **build** permission on the model.
3. **"Notebooks fail to run if the semantic model name ends with a
   whitespace."** Documented, absurd, and exactly the kind of thing a
   skill exists to carry.

### Open question for the drafting session: a helper notebook

The suggestion that this tier "could use more helper scripts" is right in
spirit but **cannot be a shell script** — semantic link has no local
entry point. It would be a `.ipynb` deployed into a Fabric workspace.

That is a new artifact class for this repo: skills today ship
`SKILL.md` + `references/` and nothing executable. Before assuming it,
weigh that Microsoft already ships the notebooks — the Power BI service
offers ready-made BPA and Memory Analyzer notebooks from three entry
points (model **Home** ribbon, the **Model health** dropdown, and the
OneLake catalog `...` menu), and `fabric-toolbox` ships a
[Data Agent Utilities notebook](https://github.com/microsoft/fabric-toolbox/tree/main/samples/data_agent_checklist_notebooks).

**Recommend: document the entry points and the function calls in
`references/`, and do not ship a notebook in v1.** Revisit only if
real use shows the stock notebooks falling short. Record whichever way it
goes.

## Step 3 — the audit dimensions

Now backed by drilled sources rather than a guess list.

### Shape, and the flatten tension

**This is the skill's headline, and both halves are now citable.**
"Flatten" names two opposite operations:

- **Snowflake → star: do it.**
  [Star schema guidance](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema):
  "Generally, the benefits of a single model table outweigh the benefits
  of multiple model tables." Four named costs of keeping the snowflake —
  more tables loaded (storage *and* performance), longer filter
  propagation chains, a cluttered Data pane, and **"it's not possible to
  create a hierarchy that comprises columns from more than one table."**
- **Star → one wide table: don't.** Microsoft states this directly in
  [Semantic model best practices for data agent](https://learn.microsoft.com/en-us/fabric/data-science/semantic-model-best-practices),
  under Common pitfalls: *"**Not using star schema:** Semantic models
  that use flat, denormalized tables or pivoted data structures make DAX
  less efficient and harder to write correctly. DAX is optimized for star
  schema with clear fact and dimension tables. Unpivot wide tables into
  normalized structures."* And ontology generation derives **entity types
  from tables** and **relationship types from relationships**, so a
  single wide table generates one entity type with no relationships.

Note the star-schema doc's own hedge, worth carrying so the skill does
not read as dogma: *"optimal model design is part science and part art.
Sometimes you can break with good guidance when it makes sense to do
so."* And it names the sanctioned exceptions itself — **degenerate
dimensions** (an order number living on the fact table is *"an exception
to the formerly introduced rule that you shouldn't mix table types"*) and
**junk dimensions**. An audit that flags those as defects is wrong.

The star-schema page also supplies the vocabulary the findings should be
phrased in, each with a defined remediation: surrogate keys, snowflake
dimensions, role-playing dimensions, SCD Type 1/2, junk dimensions,
degenerate dimensions, factless fact tables (bridging tables for
many-to-many).

### Relationship health

From the relationships page, in rough order of what an audit can
actually detect:

- **Inactive relationships** — expanded regardless (above). Finding:
  inactive relationships with no `USERELATIONSHIP` measure justifying
  them.
- **Bidirectional filters** — "can impact negatively on performance" and
  can create ambiguous paths. ACME is clean here.
- **Regular vs. limited relationships.** *Limited* means no guaranteed
  "one" side: many-to-many cardinality, or cross-source-group in a
  composite model. Limited relationships get **no data structures built**,
  join with `INNER JOIN` semantics, **no blank virtual rows for
  referential-integrity violations**, and `RELATED` stops working. This
  is inferred, not a settable property, which makes it exactly the sort
  of thing a human misses and an audit should compute.
- **The documented performance ordering**, fastest to slowest — worth
  reproducing verbatim: one-to-many intra source group → many-to-many via
  an intermediary table with at least one bi-directional relationship →
  many-to-many cardinality → cross source group.
- **One-to-one cardinality** — "likely represents a suboptimal model
  design because of the storage of redundant data."
- **`DateTime` relationship columns** — the engine only has `DateTime`;
  `Date` is a formatting construct, so a time component still counts and
  keys silently fail to match. Fix in Power Query, not the Modeling tab.
- **Disconnected tables** — legitimate (what-if parameters), so an audit
  must not flag them blindly.
- **Assume referential integrity** — DirectQuery only; when data
  integrity is actually compromised the `INNER JOIN` *silently
  understates* results.

### Performance / memory

Notebook tier. `model_memory_analyzer()` for column-level memory and
cardinality; `run_model_bpa()`'s Performance and DAX Expressions
categories. The data-agent page names the specific targets: *"incorrect
data types, unnecessary columns, high cardinality columns, and
inefficient DAX patterns."*

### Downstream readiness

One section per consumer, deferring hard to the skills that already own
each:

- **Report** — the classic case.
- **AI instructions blob** — defer to
  `fabric-semantic-model-ai-instructions`.
- **Data agent** — `semantic-model-best-practices` is close to a
  ready-made checklist here, and its **"Common pitfalls to avoid"** list
  maps almost one-to-one onto audit findings: hidden fields breaking
  verified answers, helper/duplicate/overlapping measures, non-descriptive
  naming (`TR_AMT`, `DIM_GEO_01`), implicit measures, ambiguous date
  fields. Note the sharp governance point it makes — **the DAX generation
  tool reads only the model's metadata and Prep-for-AI configuration and
  *ignores* data-agent-level instructions**, so model-specific guidance
  put on the agent is silently dead. Defer agent configuration itself to
  `fabric-data-agent`; keep the *model-shape* consequences here.
- **Ontology** — defer the constraint matrix to the ontology skill; carry
  only the model-shape consequences.

### Sources — drilled and not

**Drilled 2026-09-02**: `power-bi/guidance/star-schema` (dimension/fact
classification, snowflake trade-off, role-playing dimensions, SCD, junk /
degenerate / factless);
`power-bi/transform-model/desktop-relationships-understand` (cardinality,
cross-filter, regular vs. limited, table expansion, ambiguity resolution
by priority and weight, performance ordering);
`fabric/data-science/semantic-link-overview` (Fabric-only constraint,
SemPy vs. Spark connector, `FabricDataFrame`);
`power-bi/transform-model/service-notebooks` (BPA 60+ rules / 5
categories, Memory Analyzer, entry points, permissions);
`fabric/data-science/semantic-model-best-practices` (pitfalls list,
implementation workflow, Prep-for-AI precedence);
`sempy.fabric` API reference (exact signatures and the ReadWrite
requirement).

**Not drilled, deliberately**: the guidance drill-throughs
(`relationships-active-inactive`, `relationships-bidirectional-filtering`,
`relationships-many-to-many`, `relationships-one-to-one`) — each is a
whole article behind a link followed above, and they are the obvious next
pass if the body needs more depth on any one dimension. Also not drilled:
`import-modeling-data-reduction`, the Direct Lake guidance, the Tabular
Editor BPA rule set as published, and the `fabric-toolbox` checklist and
utilities notebook. **The `fabric-toolbox` checklist should be read
before drafting** — it may already contain the check list this skill
needs, which would change the body from invention to curation.

**A dead end, recorded so it is not retried**: the Fabric Community
notebook-gallery post on BPA + VertiPaq Analyzer returns **HTTP 403** to
`WebFetch`. The library it is about is `semantic-link-labs`, reachable
via `raw.githubusercontent.com`, and the underlying functions are
first-party documented above. Nothing was lost.

## Step 4 — the shell scripts, and the idiom for citing them

**Yes, a skill can carry script guidance — but only as a conditional
accelerator, never as a dependency.**

The established form is
[`pbir-report-workflow/SKILL.md:289`](../../../skills/powerbi/pbir-report-workflow/SKILL.md#L289):

> If a `scripts/data/report-png.sh` wrapper is deployed in the repo
> (internal-tooling local-cli template), prefer it over raw curl.

That shape is load-bearing. Skills deploy to `~/.claude/skills` at **user
scope** and serve every session on this machine, including repos with no
`scripts/data/`. A skill that says "run `dax.sh`" unconditionally is
broken in most places it loads. `claude/rules/coding-bash.md` already
covers *writing* those scripts, so the rule owns authoring and the skill
owns invocation.

`dax.sh -s` gives four canned `INFO.VIEW` projections —
`tables` (name, storage mode, hidden, data category, calc-table DAX,
description), `columns` (excluding `DataCategory = "RowNumber"`),
`measures` (including `[Expression]`), `relationships`.

Three caveats, all already in `dax.sh`'s header:

1. **`INFO.VIEW.*` blanks `[Expression]` for users without write
   permission.** Empty formulas mean read-only access, **not** an empty
   model. The single most likely way this skill produces a confidently
   wrong answer.
2. **The executeQueries reference says INFO functions are unsupported.
   That is stale** — verified working against a Direct Lake model.
3. **One `EVALUATE` per call**, 100,000 rows / 15 MB, 120 req/min. Four
   calls for a full metadata sweep, not one.

Present TMDL-on-disk as the default, `dax.sh` as the upgrade, and the
notebook tier as a separate capability — not a fallback chain.

## Step 5 — a spin-off that is not this skill

Two **Power BI MCP servers** exist —
[`powerbi-modeling-mcp`](https://github.com/microsoft/powerbi-modeling-mcp)
(local, VS Code) and a remote one, both documented at
`power-bi/developer/mcp/`. The data-agent page recommends the local one
for bulk renaming of non-descriptive objects with LLM review.

This repo already ships MCP templates in `claude/mcp/` in Claude's
`mcpServers` schema. **A Power BI MCP template is plausibly worth adding
and it is not part of this skill** — different artifact, different
directory, different deployment path. Raise it separately rather than
letting it widen this brief; if it lands, the skill gains one conditional
sentence pointing at it, exactly like the `dax.sh` idiom above.

## Validation

- **No fixture work if step 1(b) holds.** An unconditional skill has no
  `paths:` contract, so `tests/skills/fabric-triggers/` is untouched. If a
  glob is set after all, fixture + `expected_activations.md` row +
  `-Set fabric` all become required in the same commit.
- Real-use validation against `ACME_SM_Operation.SemanticModel`. The audit
  must independently reach the four both-sides tables, the 7 inactive
  relationships, and the `DimDate` role-playing finding. Those are the
  known answers; a run that misses them has failed.
- The notebook tier **cannot be validated from this machine** — no local
  entry point. Either validate it in a Fabric workspace or state plainly
  in the resulting brief that the section is documented-but-unexercised.
  Do not let it pass silently as tested.
- Listing budget: this lands in the ~20 unconditional skills whose
  descriptions sit permanently in context. Keep `description` tight.
- Body cap ~2,700–3,100 tokens. This brief now carries more drilled
  material than that will hold, so plan the split up front:
  `references/` takes the check catalogue, the `INFO.VIEW` and `sempy`
  invocations, and the star-schema pattern vocabulary. `SKILL.md` keeps
  the procedure, the flatten tension, and the tool-tier table.
- Lint, `pre-commit run --all-files`, `/commit`.

## If the answer turns out to be no

Weaker than it was — three first-party sources now say things no rule in
this repo says. The residual "no" is that the useful part is a longer
modelling section in `coding-tmdl.md`. Against that: an audit is a
procedure with steps, tiered evidence-gathering and permission
false-negatives, and a `paths:` rule that auto-loads a procedure on every
measure edit is the co-load problem from step 1(b) wearing a different
hat. Record the reasoning in the commit that deletes this brief.
