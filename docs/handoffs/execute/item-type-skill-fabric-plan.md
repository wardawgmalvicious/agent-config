# Handoff: does the Fabric IQ Plan workload need a skill?

- **Written**: 2026-09-02, after fetching the two
  `learn.microsoft.com/fabric/iq/plan/` links that prompted
  the [`fabric-semantic-model-audit`](../../../skills/fabric/fabric-semantic-model-audit/SKILL.md) work and
  finding they were about something else entirely.
- **Kind**: coverage decision, then possibly `/author-skill`.
- **Status**: **deferred 2026-09-03 — step 0 was answered *no*.** The
  recommendation below is unchanged *on the merits*: the content is real,
  uncovered and unguessable. What was unresolved was whether Plan is
  **used** here, and today it is not. This brief is alive and on disk on
  purpose — that is not an oversight to tidy up.
- **Run in**: a fresh session, and **not before step 0 is *re*-answered.**
  The 2026-09-03 "no" is a snapshot of one day, not a standing verdict;
  re-measure rather than reading it off this line.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## Why this brief exists: a premise correction

Two Microsoft Learn links were offered as *semantic modelling best
practice* and *time intelligence best practice*. Both were fetched on
2026-09-02. **Neither is general modelling guidance.** Both are
documentation for the **Fabric IQ Plan** workload — a planning product
with its own item type, its own grid, and its own vocabulary.

| Link | What it actually covers |
| --- | --- |
| `.../plan/resources/best-practices/semantic-modeling` | How to shape a semantic model so it drives a **planning grid**: dimension-driven rather than fact-driven row visibility, Scenario modelled as a dimension, validity tables, weight matrices, PowerTable, Blend. Ten named planning cases. |
| `.../plan/resources/best-practices/time-intelligence` | **Label-format parsing.** Which member values Plan's automatic time intelligence recognises (`Q1`, `FY25`, `W53`, `2025-02-01`) and which it silently drops (`Sept`, `WK1`, `Q5`, `2025-2026`, `First Half`). Nothing to do with DAX time intelligence. |

Anyone reading the first title and expecting star-schema guidance gets
planning-grid guidance instead. That misread is the reason to write this
down: the correction is cheap now and expensive after a skill has been
drafted against the wrong premise.

The genuine modelling-audit content shipped separately as
[`fabric-semantic-model-audit`](../../../skills/fabric/fabric-semantic-model-audit/SKILL.md),
drilled against different sources.

## Step 0 — the gating question

**Is Plan in use, or planned, in any repo worked on here?**

Everything else in this brief is contingent on that. Unlike the ontology
brief — where a payload inconsistency already exists because
`fabric-data-agent` names ontology as a source with nothing behind it —
there is no internal pressure here at all. `grep -rni "powertable\|fabric
iq plan"` over `skills/`, `claude/` and `tests/` returns nothing, and
`C:\Repos\ACME\fabric-acme` contains no Plan item (confirmed 2026-09-02).

**That grep no longer returns nothing, and the next reader must not
misread the hits.** As of 2026-09-03 03:19 (`9ccbace`, ~1.5 h *after*
this brief's first step 0 answer was committed) it returns five, all from
`tests/skills/fabric-semantic-model-audit/`: the audit fixture *is*
Microsoft's Plan sample `.pbix`, and `expected_findings.md` describes
validity tables and PowerTable by name. Those are **carve-out** assets —
they exist to prove the audit skill *stands down* on a planning model,
which is step 3's discharged work. They are payload pressure pushing the
same way as the `fabric-ontology` clause, not the wave-12 pattern of a
promise with nothing behind it. Note also what the fixture is not: a
`.SemanticModel`, so no `paths:` glob on a Plan item would ever fire on
it, and step 1 stays as unresolved-by-need as before.

A "no" at step 0 is a clean **defer**, not a rejection: the content stays
true, the brief stays on disk, and nothing is lost by waiting. A "yes"
makes this the most concretely useful of the three briefs written today,
because the time-intelligence half is a lookup table you cannot reason
your way to.

Do not skip to step 1 on the strength of the docs being interesting.

**Answered 2026-09-03 01:40: no — defer.** The evidence was re-measured
that day rather than taken from the 2026-09-02 line above: no `*.Plan`
folder in `fabric-acme`, `fabric-acme-legacy`, `edgebridge` or
`internal-tooling`, and the payload's only mention of Plan was, *at that
hour*, the clause in `fabric-ontology`'s `when_to_use` disambiguating
that item **from** this one. That
single reference is worth reading correctly, because it is the *mirror
image* of the ontology case that justified wave 12: there,
`fabric-data-agent` promised a source the payload did not have, and the
inconsistency pulled the work in. Here the one internal mention exists to
push work **away** from Plan. It is evidence against, not a loose thread.

**Re-answered the same day, later: still no.** The queue row says to
re-run step 0 rather than trust it, so it was re-run rather than read
off. Repo side is unchanged and was measured wider than before — a
full-depth `find` for `*.Plan` across all of `C:\Repos\ACME` (including
`fabric-acme.worktrees`) and `internal-tooling` returns **zero**, against a
live suffix inventory of `DataPipeline`, `Eventhouse`, `EventSchemaSet`,
`Eventstream`, `KQLDashboard`, `KQLQueryset`, `Lakehouse`, `Notebook`,
`OperationsAgent`, `Report`, `SemanticModel`, `VariableLibrary` and
`Warehouse`. Payload side is what moved, and the step 0 paragraph above
now carries the correction: the mention count went 1 → 6, and all five
new ones are the audit skill's carve-out fixtures. **A count is not a
direction** — that is the whole lesson of this re-run, and it is why the
step 0 grep is now a trap rather than a measurement. Every one of the new
hits argues the same way the old one did.

Steps 1 and 2 are therefore **unexecuted** — no suffix was guessed, no
glob was written, and no skill was drafted. **Step 3 is the exception**:
its `fabric-semantic-model-audit` carve-out was split off and landed the
same day, because it was never gated on step 0. See that step for why.

## The gap, if step 0 says yes

**Plan is a Git-supported item.**
[Git integration → Supported items](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration#supported-items)
lists **Plan** under "IQ (preview) items", next to Ontology. So it
serialises into a Git-synced repo and is a candidate for a `paths:`-scoped
skill on the same footing as every other item type in the payload.

Nothing in the payload globs the **item**, and nothing fixtures it. It is
mentioned — six times as of 2026-09-03, per step 0 — but every mention is
either a disambiguation clause or a carve-out fixture built from a
planning *semantic model*, which is a `.SemanticModel` folder and not a
Plan item at all.

## Step 1 — verify the folder suffix

Same blocker, same reason, as wave 12's ontology brief (now spent — see
the queue row). **Resolve it the way that one was**: the REST
item-management **definition** page for the item type states the
`.platform` `metadata.type` outright, in the base64 payload of its
definition example — for ontology,
[Ontology definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-definition)
decoded to `"type": "Ontology"`, and the Git folder is
`{display name}.{type}`. The equivalent
[Plan definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/plan-definition)
page exists and is the place to look. That beats hunting for a real
workspace, and it settles the `definition/` layout in the same fetch.
**Do not assume `.Plan`** — and note the specific hazard here: the ACME
semantic model already contains a table literally named `Plan`
(`Analytics/ACME_SM_Operation.SemanticModel/definition/tables/Plan.tmdl`),
which is unrelated. A glob written on a guess would be both wrong and
plausible-looking in a grep.

Resolve from a workspace containing a real Plan item, or from the Fabric
REST item-types list, before writing anything path-scoped.

## Step 2 — the content, and whether it is one skill or two

The two halves are different *kinds* of thing, and that is the structural
decision.

### Half A — planning model patterns (a pattern catalogue)

The doc's own framing: conventional models let the **fact table** decide
which rows appear, which works for reporting and breaks for planning,
because planning must represent futures that have no transactions yet —
a product launch, a new territory, a discontinued line that should stop
appearing.

The replacement is to state row existence as data:

- **Dimension tables** carrying parent keys, so valid combinations derive
  from the model.
- **Validity tables** with an `IsValid` flag, for combinations that
  relationships cannot settle.
- **Scenario as a dimension** — `ScenarioKey`, `IsForecast`, `OpenFrom`,
  `OpenUntil` — replacing per-scenario measure sets. The doc's own
  arithmetic: 10 measures × 4 scenarios = 40 measures, and a fifth
  scenario makes 50.
- **Date tables spanning the planning horizon**, not the transaction
  history, with fiscal fields for 4-4-5 / 4-5-4 / 5-4-4 patterns.
- **Weight matrices** brought in through **Blend** as a measure rather
  than a relationship.
- **PowerTable** as the maintenance surface, so business users change
  planning windows and valid combinations without touching the model.

Ten named cases in four groups (managed combinations, editability,
history-derived rows, time-varying validity), with a companion
[sample .pbix](https://github.com/microsoft/fabric-samples/blob/main/docs-samples/iq/plan/semantic-modeling-sample.pbix).

One architectural constraint worth surfacing to `SKILL.md` rather than
burying: the approach is **built and validated on Direct Lake over
OneLake**, and PowerTable depends on the planning data existing as
OneLake tables in the first place. That is a prerequisite, not a
preference.

### Half B — automatic time-intelligence detection (a format reference)

Mechanical and unguessable, which is exactly what a skill is for:

- **Detection precedence**: explicit mapping → field name → field values.
- **Field-name keywords**: Year, Yr, Half Year, Half, Quarter, Qtr,
  Month, Week, Day.
- **Accepted formats per level**, including `FY 2025` / `FY25`, `Qtr_1`,
  `Week 53`, ISO days only (`2025-02-01`).
- **Rejected, silently** — the member is dropped from the hierarchy:
  `Sept` (only `Sep` or `September`), `WK1` (use `W1`), `First Half`
  (use `H1`), `Q5`, `Week 54`, `2025-2026` and any range, `01/02/2025`,
  `Feb 1, 2025`, and mixed formats within one level.
- **14 valid hierarchy orderings enumerated**, and five invalid ones
  (`Quarter → Year`, `Day → Month`, `Week → Month`, …).
- The sharpest gotcha: **a Day level directly under Quarter or Half Year
  — with no Month between — counts days from the start of that parent
  period.** Wrong numbers, no error.

**Recommendation: one skill, with half B in `references/`.** They share a
trigger (you are building a Plan model), and half B is a lookup consulted
mid-task rather than read through — which is precisely the
`references/` contract. Splitting them would create two skills that
always fire together, and the queue has already settled that permanent
co-firing is not an argument for merging *or* for splitting (wave 4,
workstream C) — but it does mean the split would buy nothing.

### Not drilled

The Plan overview, the PowerTable and Blend how-tos, the item's
definition/serialisation format, and the remaining
`plan/resources/best-practices/` pages. Only the two linked pages were
fetched. The definition format is the significant omission and is
required before any `paths:` work.

## Step 3 — overlap

Lighter than the other two briefs, but not nil:

- **`coding-tmdl.md`** and **`fabric-tmdl`** both glob `**/*.tmdl` and
  will co-load with anything touching the planning semantic model. Half
  A's date-table and dimension guidance must not restate their
  conventions — cite and move on.
- [`fabric-semantic-model-audit`](../../../skills/fabric/fabric-semantic-model-audit/SKILL.md)
  — now shipped — needs to know that a *planning* model is legitimately
  shaped differently from a reporting one. **Done 2026-09-03, and no
  longer this brief's work**: its "what an audit must not flag" section
  now excludes planning models, and check 1 in `references/REFERENCE.md`
  carries the pointer at the point of use. This step was the one hard
  dependency between the two and it is **discharged**, deliberately ahead
  of step 0's defer, because it turned out not to be gated on anything
  here — it needed the documented shape of a planning model, not a folder
  suffix or a Plan item. What the guard has not had is a real planning
  model to be tested against; that limitation is recorded in the audit
  skill's own §9 rather than here.

## Validation, if it proceeds

- Fixture + `expected_activations.md` rows +
  `./scripts/test-activation.ps1 -Set fabric`, all blocked on step 1.
  `-StaticOnly` first.
- Real-use validation is the weak point and should be honest about it: no
  Plan item exists here today. If step 0 resolved to "yes, upcoming", the
  sample `.pbix` is the only available exercise, and a skill validated
  only against a sample should say so in the brief that replaces this one.
- Preview churn is high — a preview workload inside a preview product.
  Date every claim and register the Plan doc set with `/drift-audit` in
  the same pass.
- Body cap ~2,700–3,100 tokens; half B goes to `references/` per step 2.
- Lint, `pre-commit run --all-files`, `/commit`.

## If the answer turns out to be no

Most likely outcome, and it is a **defer** rather than a decline — so
this is the one brief of the three that should *not* be deleted on a
"no". Record the step 0 answer and the date in the queue row, leave the
file, and revisit when a Plan item appears. Delete it only if the
workload is abandoned upstream or the user rules it out outright, and
record which of those it was.

It *was* the outcome, on 2026-09-03, and this procedure is what was
followed — so treat this section as the standing instruction for the
**next** answer, not as an open question. It stays in the conditional on
purpose: step 0 can be asked again, and a later "yes" does not make these
paragraphs stale.
