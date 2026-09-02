# Skill handoff brief: fabric-data-pipeline

Last verified: 2026-09-02

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

Personal scope, deployed by `scripts/link-claude.ps1`:

- Repo: `skills/fabric/fabric-data-pipeline/SKILL.md`
- Repo: `skills/fabric/fabric-data-pipeline/references/REFERENCE.md`
- Deployed: `~/.claude/skills/fabric-data-pipeline/SKILL.md`

The `fabric/` group directory is repo-side only and does not survive into
the deployed name. Note the deployment consequence specific to this
machine: `-SkillGroups workflow` is the standing default here, so
**`fabric` is pruned from `~/.claude/skills` and this skill will not be
live in ordinary sessions.** That is expected and is not a reason to
re-link the group. The fresh-session test below has to name
`-SkillGroups workflow,fabric` explicitly, and restore the workflow-only
prune afterwards.

## Scope

A platform reference skill for the Fabric **DataPipeline** item type as
it exists **in Git** — the three files a Git-synced pipeline serializes
to, and the parts of their JSON an agent has to get right without a
portal to validate against. Path-scoped and model-invocable: `paths:` is
the single glob `**/*.DataPipeline/**`, which reaches `.platform`,
`.schedules` and `pipeline-content.json`. Runs inline, not forked;
`disable-model-invocation: false`; `model: inherit`; `effort` left
commented so it inherits the session level, per platform-skill policy.
The skill is a **reference**, not a procedure — it describes a file
format and its traps, in the shape of `fabric-variable-library` rather
than of `commit`.

## Sources drilled

Drilled:

- [DataPipeline definition (Fabric REST item-management reference)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/datapipeline-definition)
  — the authoritative schema. Established: the two definition parts;
  `DataPipelineActivity` field list (`name`, `type`, `state`,
  `onInactiveMarkAs`, `dependsOn`, `typeProperties`, `policy`); the
  `ActivityPolicy` table with its documented defaults (timeout 7 days,
  retry 0, interval 30s / min 30 / max 86400); `ExternalReferences` being
  a single `connection` GUID; the **36-entry `DataPipelineActivityTypes`
  enum**, which is where `InvokePipeline` is marked *"deprecated, use
  ExecutePipeline"*; and per-activity `typeProperties` tables for
  `TridentNotebook`, `ExecutePipeline`, `InvokePipeline`,
  `SqlServerStoredProcedure` and `PBISemanticModelRefresh`. Also
  established two **doc gaps** recorded in Notes.
- [Activity overview](https://learn.microsoft.com/fabric/data-factory/activity-overview)
  — the **120-activities-per-pipeline** cap (inner container activities
  count); the portal's General-settings defaults (timeout 12 hours, max
  7 days, format `D.HH:MM:SS`; retry default 1); and the full
  *Deactivate an activity* semantics, including that an inactive
  activity is excluded from validation, never runs, and therefore **has
  no `error` or output fields** for downstream expressions to read.
- [Activity retries](https://learn.microsoft.com/fabric/data-factory/activity-retries)
  — retry count range 1–1000; Fixed vs Increasing Delay (exponential
  back-off) interval types; `retryConditions` is **preview**, is limited
  to Copy / Notebook / Dataflow / Stored procedure activities, matches on
  error message, failure type and error code, and — the trap — **the
  retry interval elapses before the condition is evaluated**.
- [Debug pipelines in Microsoft Fabric](https://learn.microsoft.com/fabric/data-factory/how-to-debug-pipelines-in-microsoft-fabric)
  — Fabric has no separate Debug mode; deactivation *is* the debugging
  mechanism, used as an iterative reactivate-forward workflow.
- [Job scheduler in Microsoft Fabric](https://learn.microsoft.com/fabric/fundamentals/job-scheduler)
  — schedules live in `.schedules`; **scheduler auto-disable** after
  consecutive failures (threshold varies by item, typically 10) requiring
  a manual restart; items scheduled before CI/CD was enabled show as
  uncommitted on the first `git status`; Variable Library values used in
  schedule parameters cause post-CI/CD data-sync latency.
- [Run, schedule, or use events to trigger a pipeline](https://learn.microsoft.com/fabric/data-factory/pipeline-runs)
  — **both a start and an end date are mandatory**, there is no
  open-ended schedule, and the documented workaround is a far-future end
  date; up to **20 schedules per pipeline**; interval-based schedules
  (preview) add `Window start time` / `Window end time` trigger
  parameters.
- [CI/CD for pipelines in Data Factory](https://learn.microsoft.com/fabric/data-factory/cicd-pipelines)
  — the known-limitations list, of which three are pipeline-specific and
  uncovered elsewhere in the payload: OAuth connectors (Teams, Outlook)
  need a manual per-activity sign-in after promotion; a promoted pipeline
  that invokes a dataflow still points at the **source** workspace's
  dataflow; workspace variables are unsupported by CI/CD.
- [Git integration schedules schema 1.0.0](https://developer.microsoft.com/json-schemas/fabric/gitIntegration/schedules/1.0.0/schema.json)
  — the `$schema` the real files declare. Established the
  `configuration.type` enum (`Cron`, `Daily`, `Weekly`, `Monthly`), that
  `interval` is **minutes** (so `Cron` is a fixed interval, *not* a
  crontab expression), `times` max 100, `weekdays` max 7, the monthly
  `recurrence` + `occurrence{occurrenceType, dayOfMonth, weekIndex,
  WeekDay}` shape, and that `jobType` carries **no enum** in the schema.
- **Live artifacts** — 8 `.schedules` and 30+ `pipeline-content.json`
  files across `C:/Repos/ACME/fabric-acme` and `fabric-acme-legacy`, read
  with `jq`. These are what turned several doc statements into checked
  facts rather than quoted ones: `state` is spelled `Inactive` in every
  real file (3/3) against the schema doc's `InActive`; `jobType` is
  `"Execute"` in all 11 schedule blocks; `libraryVariables` entries carry
  exactly three keys; and both the good far-future end date
  (`9999-12-31`) and two already-expired ones appear in the same repo.

Not drilled — **nothing in this skill describes any of it**:

- **Copy activity internals.** `CopySource`, `CopySink`,
  `CopyTranslator`, `TypeConversionSettings`, `StagingSettings` and
  `DatasetSettings` are the single largest part of the definition
  reference and were deliberately skipped. Copy is named in the activity
  table and nothing more. A connector-shaped question is out of scope.
- **Per-connector `typeProperties`** for anything other than the five
  Fabric-specific activities listed above — no
  `DatabricksNotebook`, `AzureFunction`, `Custom`, `ExecuteSSISPackage`,
  `AzureHDInsight`, `DataLakeAnalyticsScope`, `AzureMLExecutePipeline`,
  `Office365Email`/`Email`/`Teams`/`MicrosoftTeams`, `WebActivity`,
  `WebHook`, `Script`, `Delete`, `GetMetadata`, `KustoQueryLanguage`.
- **The job-scheduler REST API.** `fabric-rest-api` owns it and already
  carries the `jobType: Pipeline` mapping. This skill covers only the
  Git-serialized `.schedules` file.
- **Monitoring, run history, the Monitor hub**, and pipeline run
  troubleshooting symptoms.
- **Dataflow Gen2, Copy job and Airflow items** as item types — only the
  pipeline *activities* that invoke them are in scope, by name.
- **Capacity, cost and concurrency ceilings** beyond the two documented
  numbers (120 activities, 20 schedules).

## Frontmatter

```yaml
---
name: fabric-data-pipeline  # repo linter requires it; max 64 chars; lowercase/digits/hyphens
description: <see Description char count>  # gated at 1,024, the Agent Skills spec cap
disable-model-invocation: false  # ALWAYS PRESENT; repo policy: false everywhere
model: inherit  # ALWAYS PRESENT; repo policy: inherit everywhere except commit
# effort:  # ALWAYS PRESENT as a commented placeholder — platform skills inherit the session level
paths:  # glob for path-scoped auto-activation; a wrong glob has no error path
  - "**/*.DataPipeline/**"
---
```

`when_to_use` is **not** set. This is a conditional skill, so the field
is near-free in listing terms, but the single `paths:` glob already
disambiguates it completely — nothing else in the payload globs
`**/*.DataPipeline/**`, and the two rules that co-load are rules, which
do not compete for invocation. Adding it would spend characters to
disambiguate against nothing. Revisit if a second pipeline-scoped skill
ever lands.

## Description char count

- `description`: 1,006 / 1,024
- `when_to_use`: N/A — not set

## Body structure outline

1. **What Git actually holds** — the three files, one line each, and the
   glob that reaches them. Points at `fabric-git-serialization` for the
   serialization mechanics rather than restating them.
2. **The definition envelope** — `properties.{activities, parameters,
   variables, libraryVariables}`, with the note that the REST schema
   documents only `activities` and `description` while every real file
   carries the other three.
3. **Activity anatomy** — the ten keys that appear on a real activity,
   what each is for, and `dependsOn` / `dependencyConditions`.
4. **Choosing an activity type** — the Fabric-specific ones and their
   `typeProperties`, then the `InvokePipeline` → `ExecutePipeline`
   deprecation and why migrating is a rebinding rather than a rename.
   Full 36-entry enum goes to `references/`.
5. **`policy`** — the timeout default split, retry ranges, and the
   preview `retryConditions` with its interval-before-condition trap.
6. **Deactivating instead of deleting** — `state` + `onInactiveMarkAs`,
   the branch each value takes, and the missing-output-fields
   consequence.
7. **`.schedules`** — the file, the four configuration shapes, and the
   four traps (mandatory end date, `Cron` is an interval, auto-disable,
   first-commit noise).
8. **CI/CD limitations that bite pipelines specifically** — the three
   from the known-limitations list. Cross-references `fabric-cicd` for
   the parameterisation mechanics rather than repeating them.
9. **Limits** — a short table: 120 activities, 20 schedules, retry
   1–1000, interval 30–86400s, timeout max 7 days, `times` ≤ 100.
10. **Reference** — three inline Learn links plus the pointer to
    `references/REFERENCE.md`.

`references/REFERENCE.md` carries: the full 36-entry activity-type enum
with descriptions; full `typeProperties` field tables for the five
Fabric-specific activities; the complete `.schedules` schema field list
with all four configuration shapes and a worked example of each; and the
curated Learn link bundle.

## Changes from source proposal

Derived from `docs/handoff-briefs/execute/item-type-skill-datapipeline.md`
(wave 5 of the execute queue), whose recommendation was "yes, author it".
Four departures:

1. **Name.** The source brief never proposed one.
   `fabric-data-pipeline` was chosen over `fabric-datapipeline` to match
   the repo's existing hyphenation of multi-word item types
   (`fabric-copy-job`, `fabric-variable-library`), and over
   `fabric-pipeline` because "pipeline" already means deployment
   pipelines and release pipelines in `fabric-cicd`'s territory.
2. **Connection parameterisation is out, not in.** The source brief
   listed it as candidate content with the caveat "this is where the
   `fabric-cicd` overlap is most likely". The overlap is not likely, it
   is total — `fabric-cicd` line 249 already names Data Pipeline
   explicitly and prescribes `key_value_replace` on
   `externalReferences.connection`. Cited, not restated.
3. **`libraryVariables` mechanics are out.** Not anticipated by the
   source brief at all; `fabric-variable-library` already documents the
   block, its placement and its type mapping. The new skill names the
   field in the envelope and points there. See Notes — that skill is
   also wrong about it in two places, which is `/learn` work and not
   this brief's.
4. **One premise corrected.** The source brief asserts "an inactive
   activity still participates in dependency edges". That is true but
   under-specified, and one Learn page contradicts it outright. The
   accurate statement is that the *branch taken* is chosen by
   `onInactiveMarkAs`, while the activity's `error` and output fields
   never exist — so a dependency edge is honoured but any expression
   reading the skipped activity's output fails.

## Tag

`personal`

## Portability caveats

N/A — personal scope. No Claude Code-only frontmatter is used beyond
`paths:` and the always-present `model` / `disable-model-invocation`
fields; `effort` is a comment. Nothing here relies on `shell`,
`context: fork`, hooks, or fine-grained `allowed-tools`.

## Cross-reference dependencies

- `claude/rules/coding-expressions.md` — (a) already converted.
  Permanently co-loads on `pipeline-content.json` and owns WDL
  expression authoring outright.
- `claude/rules/fabric-git-serialization.md` — (a) already converted.
  Already globs `**/*.DataPipeline/**`, so it co-loads on all three
  files.
- `fabric-cicd` — (a) already converted. Owns connection rebinding and
  `parameter.yml`.
- `fabric-variable-library` — (a) already converted, but **carries two
  errors about the pipeline surface** (see Notes).
- `fabric-error-handling` — (a) already converted. Owns the
  Try-Catch / Do-If-Else pipeline patterns and the Fail activity, though
  only in its `references/REFERENCE.md`, not its body.
- `fabric-rest-api` — (a) already converted. Owns the job-scheduler REST
  surface and the `DataPipeline` → `jobType: Pipeline` mapping.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**Two doc-vs-reality gaps found while drilling, both recorded in the
skill with their date.** Neither is a guess:

- The REST definition reference spells the inactive state `InActive` in
  its `ActivityState` table. Every real file spells it `Inactive`
  (3 occurrences across ACME), as do the Azure Data Factory docs for the
  same field. Treat `Inactive` as correct.
- That reference's `DataPipelineProperties` table lists only `activities`
  and `description`. Real pipelines also carry `parameters`, `variables`
  and `libraryVariables` at the same level — all three present in both
  current ACME pipelines. The schema page is incomplete, not the files.

**The timeout default is two numbers, and both are right.** The portal
stamps an explicit `"timeout": "0.12:00:00"` on every activity it
creates, which is the 12-hour figure in the UI docs and in the schema
page's own worked example. The 7-day figure is the schema default that
applies when `policy.timeout` is **absent** — which is what a
hand-authored or programmatically generated activity gets. So omitting
the field is not "taking the default"; it is a 14x increase over what
the portal would have written.

**Out-of-scope finding for `/learn`, not for this brief.**
`fabric-variable-library`'s "Pipeline consumption" section is wrong in
two places, checked against both live files and Learn:

1. It states each `libraryVariables` entry "needs **all four**:
   `libraryName`, `libraryId`, `variableName`, `type`". Every real entry
   carries exactly three — there is no `libraryId` (36 entries across
   two ACME pipelines).
2. Its pipeline type-mapping table maps `ItemReference` → `String`. Real
   files use `Object`, and Learn's own guidance to append `.` for
   `connectionId` / `itemId` / `workspaceId` is impossible on a String.
   The table also predates the `Guid` and `Connection reference` variable
   types, which Learn now lists and it does not.

The `author-skill` contract forbids editing other skills from here, so
this is written down and handed on rather than fixed in passing.

**Fixtures are deliberately deferred.** The wave 5 source brief asks for
a `.schedules` fixture in `tests/skills/fabric-triggers/fixtures/` and
two `expected_activations.md` row changes in the same commit as the
skill. `author-skill` forbids writing test fixtures ("`tests/` is a
separate, deliberate exercise"). The contract wins; the fixture plan is
in the fresh-session test instead, and wave 5 does not close until it
runs.

## Fresh-session test

Written 2026-09-02 by `/test-skill`, which found this section referenced
twice above and missing. **Phase A is done**; Phase B below is not, and is
what closes wave 5.

### Phase A — activation contract (done, 2026-09-02)

Fixture `tests/skills/fabric-triggers/fixtures/SamplePL.DataPipeline/.schedules`
added; the item's three rows in `expected_activations.md` changed from
*(none)* to `fabric-data-pipeline`, recorded as assertion 6 there. Static
check and real-path check both pass — 57/57 fixtures, every activation
delta matched. The set now covers 15 skills to `pbip-triggers`' 10, which
is all 25 conditional skills in the payload.

### Phase B — behaviour (outstanding)

Deploy, and **restore the prune afterwards** — `-SkillGroups` prunes user
scope, which serves every session on this machine:

```powershell
./scripts/link-claude.ps1 -SkillGroups workflow,fabric
# ... run the queries below ...
./scripts/link-claude.ps1 -SkillGroups workflow
ls ~/.claude/skills    # expect the eight workflow skills and nothing else
```

Baseline first with `claude --safe-mode`, which starts with the whole
payload off. Anything it already answers correctly is the base model, not
this skill. Confirm the skill actually loaded with `/context` rather than
by asking the session — self-report is unreliable.

**Trigger queries — model-invocation (plain English).** Each targets a
fact the description carries and the base model is likely to get wrong:

1. "In a Fabric data pipeline, what timeout does an activity get if I
   don't set `policy.timeout`?" — must give **7 days** for an absent
   field and distinguish that from the portal's stamped
   `0.12:00:00` (12 hours). Getting only "12 hours" is a fail: the
   14x gap is the whole point.
2. "How do I disable one activity in a Fabric pipeline without deleting
   it?" — `state: "Inactive"` (**not** `InActive`, which is what the REST
   reference says) plus `onInactiveMarkAs`, and the consequence that the
   skipped activity has no `error` or output fields for a downstream
   expression to read.
3. "My Fabric pipeline's schedule silently stopped firing and the
   `.schedules` file looks fine." — must reach for the mandatory
   `endDateTime` having passed, and for scheduler auto-disable after
   consecutive failures.
4. "Should I use `InvokePipeline` or `ExecutePipeline`?" — `InvokePipeline`
   is deprecated, and the migration is a **rebinding** (GUID vs
   `referenceName`), not a rename.
5. "What does `interval: 15` mean in a `Cron` schedule block?" — minutes,
   not a crontab expression.

**Trigger query — slash invocation.** `/fabric-data-pipeline`. Run at
least one of the above both ways: `model:` is honoured on the slash path
and silently dropped on model-invocation, `effort:` applies on both. This
skill is `model: inherit`, so the two paths should agree — a divergence
means something other than the pin is in play.

**Scope guards — the skill must defer, not answer.** It declares three
neighbours and a deliberate omission; answering any of these itself is a
failure even if the answer is right:

- "How do I write an `@concat` expression in `pipeline-content.json`?" →
  `coding-expressions` (the rule co-loads on the same file).
- "How do I rebind the connection GUID for another workspace?" →
  `fabric-cicd`, which already prescribes `key_value_replace` on
  `externalReferences.connection`.
- "What are the `libraryVariables` entry's fields?" →
  `fabric-variable-library`. **Note** that skill is wrong here in two
  ways (see Notes above); the guard is that this skill defers, and the
  fix belongs to `/learn`.
- "How do I configure the Copy activity's source and sink?" → out of
  scope by design. Copy internals were deliberately not drilled, so a
  confident answer is a fabrication, not a bonus.

**Path activation** needs no query: reading any file under a
`*.DataPipeline/` folder is already proven by Phase A.

## Confidence

- **Structure**: H. Reference-skill shape with a `references/` split,
  directly modelled on `fabric-variable-library` and `fabric-gotchas`,
  both of which lint and deploy today.
- **Field specs**: H. Every field name, enum value, default and limit in
  the outline came from either the REST definition reference or the
  published JSON schema, and the ones that mattered were cross-checked
  against 30+ live files.
- **Body content**: M-H. The facts are solid; what is unproven is the
  *editorial* call about how much of the 36-activity surface belongs in
  the body versus `references/`. The ~3,100-token cap will decide it, and
  the first draft may need one round of moving material down.
- **Trigger behaviour**: unproven by construction — see the deployment
  note under Artifact path. `fabric` is pruned on this machine, so the
  glob cannot fire in an ordinary session here.
