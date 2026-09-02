# Expected activations

Skill lists measured against the payload at commit `a5b9a02` and refreshed
2026-09-01, using the static glob check in [README.md](README.md).

**The `Tokens` column is a ceiling, not a toll.** A `paths:` match injects
each skill's **listing entry** — a name, plus its description where
`skillOverrides` does not collapse it — and nothing more. The figures below
are *body* size at ~3.5 chars/token: what you would pay if every skill in
the row were then **invoked**. Treat them as relative weights and as the
worst case, never as the cost of opening the file. (Corrected 2026-09-01;
this table previously read as though a match loaded the bodies.)

Shapes are modelled on `C:\Repos\ACME\fabric-acme`, except `GraphModel`,
`SQLDatabase` and `DataAgent`, which are modelled on the public Git-synced
exports pinned in the README. No fixture here rests on an unverified shape.

**This table lists skills only.** Rules in `claude/rules/` have `paths:`
globs of their own and load on the same files — `fabric-git-serialization`
matches every item folder here, and `coding-tsql`, `coding-python`,
`coding-kql` and `coding-expressions` match individual files. So *(none)*
in the middle column means "no skill", **not** "nothing loads". See
"Rules load here too" below; it is the difference between a real gap and
an apparent one.

| Fixture file | Activates (skills) | Tokens |
| --- | --- | --- |
| `control/notes.md` | *(none)* | 0 |
| `SampleEH.Eventhouse/.platform` | `fabric-eventhouse` | 2,952 |
| `SampleEH.Eventhouse/EventhouseProperties.json` | `fabric-eventhouse` | 2,952 |
| `SampleEH.Eventhouse/.children/SampleKDB.KQLDatabase/.platform` | `fabric-eventhouse` | 2,952 |
| `…/.children/SampleKDB.KQLDatabase/DatabaseProperties.json` | `fabric-eventhouse` | 2,952 |
| `…/.children/SampleKDB.KQLDatabase/DatabaseSchema.kql` | `fabric-eventhouse` | 2,952 |
| `…/.children/SampleKDB.KQLDatabase/EmbeddedRealTimeQueryset.json` | `fabric-eventhouse` | 2,952 |
| `SampleES.Eventstream/.platform` | `fabric-eventstream` | 2,810 |
| `SampleES.Eventstream/eventstream.json` | `fabric-eventstream` | 2,810 |
| `SampleES.Eventstream/eventstreamProperties.json` | `fabric-eventstream` | 2,810 |
| `SampleDash.KQLDashboard/.platform` | `fabric-realtime-dashboard` | 1,839 |
| `SampleDash.KQLDashboard/RealTimeDashboard.json` | `fabric-realtime-dashboard` | 1,839 |
| **`SampleNB.Notebook/.platform`** | `fabric-error-handling`, `fabric-spark`, `fabric-spark-monitoring` | **6,448** |
| `SampleNB.Notebook/notebook-content.py` | `fabric-error-handling`, `fabric-spark`, `fabric-spark-monitoring` | 6,448 |
| `SampleNB.Notebook/notebook-settings.json` | `fabric-error-handling`, `fabric-spark`, `fabric-spark-monitoring` | 6,448 |
| `SampleSparkNB.Notebook/.platform` | `fabric-error-handling`, `fabric-spark`, `fabric-spark-monitoring` | 6,448 |
| `SampleSparkNB.Notebook/notebook-content.sql` | `fabric-error-handling`, `fabric-spark`, `fabric-spark-monitoring` | 6,448 |
| `SampleVL.VariableLibrary/.platform` | `fabric-variable-library` | 2,693 |
| `SampleVL.VariableLibrary/settings.json` | `fabric-variable-library` | 2,693 |
| `SampleVL.VariableLibrary/variables.json` | `fabric-variable-library` | 2,693 |
| `SampleVL.VariableLibrary/valueSets/ENV-3P.json` | `fabric-variable-library` | 2,693 |
| `SampleWH.Warehouse/.platform` | *(none)* | 0 |
| `SampleWH.Warehouse/SampleWH.sqlproj` | *(none)* | 0 |
| `SampleWH.Warehouse/ingest/Tables/Control.sql` | `fabric-warehouse`, `fabric-warehouse-monitoring` | 4,171 |
| `SampleWH.Warehouse/ingest/Views/vw_LatestRun.sql` | `fabric-warehouse`, `fabric-warehouse-monitoring` | 4,171 |
| `SampleSQL.SQLDatabase/.platform` | *(none)* | 0 |
| `SampleSQL.SQLDatabase/.gitignore` | *(none)* | 0 |
| `SampleSQL.SQLDatabase/SampleSQL.sqlproj` | *(none)* | 0 |
| `SampleSQL.SQLDatabase/dbo/Tables/Customer.sql` | `fabric-database` | 608 |
| `SampleGraph.GraphModel/.platform` | `fabric-graph` | 2,662 |
| `SampleGraph.GraphModel/dataSources.json` | `fabric-graph` | 2,662 |
| `SampleGraph.GraphModel/graphDefinition.json` | `fabric-graph` | 2,662 |
| `SampleGraph.GraphModel/graphSettings.json` | `fabric-graph` | 2,662 |
| `SampleGraph.GraphModel/graphType.json` | `fabric-graph` | 2,662 |
| `SampleGraph.GraphModel/stylingConfiguration.json` | `fabric-graph` | 2,662 |
| `SampleAgent.DataAgent/.platform` | `fabric-data-agent` | 3,071 |
| `SampleAgent.DataAgent/Files/Config/data_agent.json` | `fabric-data-agent` | 3,071 |
| `SampleAgent.DataAgent/Files/Config/publish_info.json` | `fabric-data-agent` | 3,071 |
| `…/Files/Config/draft/stage_config.json` | `fabric-data-agent` | 3,071 |
| `…/draft/sql-database-SampleSQL/datasource.json` | `fabric-data-agent` | 3,071 |
| `…/draft/sql-database-SampleSQL/fewshots.json` | `fabric-data-agent` | 3,071 |
| `…/Files/Config/published/stage_config.json` | `fabric-data-agent` | 3,071 |
| `…/published/sql-database-SampleSQL/datasource.json` | `fabric-data-agent` | 3,071 |
| `…/published/sql-database-SampleSQL/fewshots.json` | `fabric-data-agent` | 3,071 |
| `SampleMD.MirroredDatabase/.platform` | `fabric-mirroring` | 4,659 |
| `SampleMD.MirroredDatabase/mirroring.json` | `fabric-mirroring` | 4,659 |
| `SampleCJ.CopyJob/.platform` | `fabric-copy-job` | 2,776 |
| `SampleCJ.CopyJob/copyjob-content.json` | `fabric-copy-job` | 2,776 |
| `SamplePL.DataPipeline/.platform` | `fabric-data-pipeline` | 3,141 |
| `SamplePL.DataPipeline/pipeline-content.json` | `fabric-data-pipeline` | 3,141 |
| `SamplePL.DataPipeline/.schedules` | `fabric-data-pipeline` | 3,141 |
| `SampleLH.Lakehouse/.platform` | *(none)* | 0 |
| `SampleLH.Lakehouse/lakehouse.metadata.json` | *(none)* | 0 |
| `SampleLH.Lakehouse/alm.settings.json` | *(none)* | 0 |
| `SampleLH.Lakehouse/shortcuts.metadata.json` | *(none)* | 0 |
| `SampleQS.KQLQueryset/.platform` | *(none)* | 0 |
| `SampleQS.KQLQueryset/RealTimeQueryset.json` | *(none)* | 0 |

Together with `../pbip-triggers/`, all **25** conditional skills in the
payload are now covered — 10 there, 15 here.

## Assertions that carry weight

**1. `SampleNB.Notebook/.platform` must not activate
`pbip-project-structure`.** This is the other half of the A1 regression
(`7eb6d9e`) and the reason this fixture set exists at all — the
`pbip-triggers` set could not prove it, because proving it needs a
`.platform` in a *non*-PBIP item type. `pbip-project-structure` used to
glob a bare `**/.platform`, which is a Fabric item marker rather than a
PBIP one; in a client repo that matched 31 files across Notebooks,
Eventstreams, Lakehouses and Warehouses. Two skills on this file is
correct. Three means the bare glob is back.

Every other `.platform` here is a second witness to the same fix.

**2. A Warehouse activates nothing until you open a `.sql` file.**
`fabric-warehouse` and `fabric-warehouse-monitoring` both glob
`**/*.Warehouse/**/*.sql`, so `.platform`, `.gitignore` and `.sqlproj` get
no guidance. Same for `fabric-database`.

`fabric-warehouse-monitoring` deliberately matches the *narrow* sibling
glob rather than the `**/*.Warehouse/**` proposed for it in Workstream E.
Every section it carries — query labels, the `queryinsights` views, live
DMVs, statistics, SQLEP metadata sync — is SQL you write, so the item
marker and the `.sqlproj` are files it has nothing to say about. The two
warehouse skills are complementary on the files they share:
`fabric-warehouse` governs authoring the object, `-monitoring` governs
observing it afterwards.
This is the glob as written, deliberately narrow — recorded here so a later
widening is a visible decision rather than a silent one, and so the zero
rows are not read as a fixture defect.

What that glob does **not** do is require a directory between the item
folder and the `.sql` file. `**` matches *zero* or more segments, so
`Foo.SQLDatabase/Bar.sql` matches `**/*.SQLDatabase/**/*.sql` just as
`Foo.SQLDatabase/dbo/Tables/Bar.sql` does — verified with the same wcmatch
call the static check uses. A flat SQL project would still activate. This
is written down because the opposite was believed for a while and filed as
a live bug risk; it is not one.

**3. Three skills glob `**/*.Notebook/**` and no path can select one.**
`fabric-spark`, `fabric-error-handling` and — since 2026-09-01 —
`fabric-spark-monitoring`. This fixture is the measurement behind that,
and it was the standing case for merging the first two — Workstream C1 of
the retired `skill-context-cost.md`. **The merge was declined on
2026-09-01**, on the same reasoning that killed C2 (recorded in full at
[`../pbip-triggers/`](../pbip-triggers/expected_activations.md), assertion
4) plus one argument specific to this pair.

The arithmetic is worse here than for C2: the two descriptions are 1,479
chars (~548 tok) against ~379 for a merged entry, so the ceiling is **~169
tokens** — and zero in this repo, where `skillOverrides` collapses both to
`name-only`. Against that, `DESCRIPTION_MAX` of 1,024 forces a 31% cut to
the combined trigger text, and the rename touches `skillOverrides`, the
junctions, client-repo relinks and the prose cross-references in
`fabric-gotchas`, `fabric-mlv` and `fabric-spark-monitoring`.

The specific argument: **co-firing is not sameness.** `fabric-spark` is
Fabric product surface — ABFS URIs, `notebookutils.runtime.context`,
`enableSchemas` immutability, REST upload quirks. `fabric-error-handling`
is *this repo's own convention* — the Tier 1 / Tier 2 split and the
canonical `results` shape. They share a glob because both live in
notebooks, not because they are one topic. Keeping them apart is what lets
the convention be revised without touching product documentation, and
lets either one be re-scoped later without dragging the other along.

Reconsider only if the two bodies start duplicating each other's content.
Permanent co-activation on its own is not sufficient and never was.

The third one was added deliberately, reversing the "probably a bad trade"
the brief recorded against it. That verdict priced an activation at the
skill's *body* (~2,030 tokens on every Notebook touch). It is not: a
`paths:` match emits a `skill_listing` attachment carrying the skill's
listing entry, and the body loads only if the skill is then invoked. So
the real trade is 239 description tokens in *every* session against the
same entry in *Notebook-touching* sessions only — which is the trade the
whole workstream is built on.

`**/*.Notebook/**` only, though the skill's description also covers
`sparkJobDefinitions`. Widening it to `**/*.SparkJobDefinition/**` needs
that item type verified against a real export and a fixture added in the
same commit; ACME has none, and neither does this set.

**4. A Lakehouse activates nothing, on all four files.** All four zeros
are **deliberate**, and each was tried against a real candidate before
being left empty — this is the most-examined *(none)* block in either
fixture set.

- `.platform` and `lakehouse.metadata.json` carry no procedure at all.
- `alm.settings.json` was considered for a `fabric-cicd` glob and
  declined: that skill documents the *Python library*, not the portal's
  Git-sync control surface, and it is cross-cutting enough that making it
  conditional would cost more reach than the 367 listing tokens it saves.
- `shortcuts.metadata.json` was given a `fabric-variable-library` glob on
  2026-09-01 and **reverted the same day.** A shortcut target *can* bind
  to a variable through the `$(/**/Lib/Var)` form, and ACME's happen to,
  but that is a choice the author made rather than what a shortcuts file
  is. Most shortcuts carry a plain `workspaceId`/`itemId` pair, so the
  glob pulled the skill into every Lakehouse whether or not any variable
  was involved — the same over-broad shape A1 had to narrow out of
  `pbip-project-structure`. The discriminator is `$(...)` *inside* the
  file, and no glob can see it.

This fixture is the regression: `sample_holidays` uses the VL form and
`sample_static` does not, so a glob that cannot tell them apart is visible
here. The syntax stays documented in `fabric-variable-library`'s body,
reachable from a `.VariableLibrary` folder and by `/fabric-variable-library`.

**A Lakehouse therefore has no skill, and that is the finding**, not a gap
waiting to be filled — a Git-synced Lakehouse is four files and no data.

**5. `control/notes.md` activates nothing.** If it does, the observation
method is wrong. Check this before believing any other row.

**6. All three DataPipeline files activate `fabric-data-pipeline`, and only
`pipeline-content.json` also pulls a rule.** These three rows read *(none)*
until 2026-09-02; the skill's single `**/*.DataPipeline/**` glob is
item-scoped and reaches all three, while `coding-expressions` globs
`**/*.DataPipeline/pipeline-content.json` and reaches exactly one. That
split is the point of having three fixtures rather than one — an
item-scoped skill and a file-scoped rule on the same item, where widening
the rule's glob to the folder would be visible here.

`.schedules` is a **dotfile**, and the static check only sees it because
`activation-expect.py` sets `wcmatch`'s `DOTGLOB`. A glob implementation
without it would silently score this row zero and read as a broken skill
glob. Same trap as every `.platform` row, but worth naming once.

The fixture composes two verified shapes rather than copying one file: the
`Weekly` block is `ACME_PL_Orchestration.DataPipeline/.schedules` in
`fabric-acme`, and the `Cron` block — `interval: 15`, which is **minutes**,
not a crontab expression — is from `fabric-acme-legacy`. Both are real; the
pairing is not. `endDateTime` is mandatory in both, which is why the
`Weekly` block carries the far-future `9999-12-31` workaround and the
`Cron` block carries a deliberately expired one.

## Rules load here too

Extend the static check to `claude/rules/*.md` (same snippet, second glob
set) and the picture changes. Measured 2026-08-31:

| Fixture file | Rules |
| --- | --- |
| every item file except `control/notes.md` | `fabric-git-serialization` |
| `SampleNB.Notebook/notebook-content.py` | + `coding-python` |
| `…/SampleKDB.KQLDatabase/DatabaseSchema.kql` | + `coding-kql` |
| `…/SampleKDB.KQLDatabase/EmbeddedRealTimeQueryset.json` | + `coding-kql` |
| `SampleQS.KQLQueryset/RealTimeQueryset.json` | + `coding-kql` |
| `SampleDash.KQLDashboard/RealTimeDashboard.json` | + `coding-kql` |
| `SamplePL.DataPipeline/pipeline-content.json` | + `coding-expressions` |
| `SampleWH.Warehouse/**/*.sql`, `SampleSQL.SQLDatabase/**/*.sql` | + `coding-tsql` |
| `SampleSparkNB.Notebook/notebook-content.sql` | + `coding-sparksql`, `coding-tsql` |

Re-measured 2026-08-31 after the glob fixes landed (brief
`rule-glob-gaps.md`, since spent and deleted — git history is the
archive). All
three findings that run produced are now closed:

- `fabric-git-serialization` was missing `**/*.GraphModel/**`, so the five
  GraphModel definition parts got **no rule at all**. Added, along with
  `**/*.UserDataFunction/**` and `**/*.ApacheAirflowJob/**` — both
  confirmed as real `metadata.type` values against public exports.
- `coding-sparksql` globbed `**/notebooks/**/*.sql`, a directory shape
  Fabric never emits, so a Spark SQL notebook silently got **T-SQL**
  conventions from `coding-tsql`'s bare `**/*.sql`. `SampleSparkNB` is
  the regression fixture for the fix.

- `coding-kql` globbed `**/*.kql` and `**/*.csl` only, so it reached
  `DatabaseSchema.kql` — schema DDL — and **not one written query** in any
  item type. Every RTI query surface stores KQL as a string inside JSON.
  Closed by adding three narrow item-specific globs
  (`**/*.KQLQueryset/RealTimeQueryset.json`,
  `**/*.KQLDatabase/EmbeddedRealTimeQueryset.json`,
  `**/*.KQLDashboard/RealTimeDashboard.json`) rather than a broad
  `**/*RealTime*.json`, which is the shape that caused A1. The three rows
  above are the regression fixtures. Deliberately a *rule* fix and not a
  new KQLQueryset skill — see "Fabric item types with no skill at all".

### `coding-kql` on a KQLDashboard co-loads with a skill

`SampleDash.KQLDashboard/RealTimeDashboard.json` is the one file here
carrying both a rule and a skill for the same content. Checked before the
glob went in: `fabric-realtime-dashboard` governs *wiring* — `queryRef`/
`queryId` identity, the tile grid, `visualOptions` — and touches KQL only
at the display edge ("emit currency/percent as strings", because tiles have
no per-tile number formats). `coding-kql` governs casing and pipe layout.
Complementary, not contradictory. If either grows into the other's
territory, this is the pair to re-check.

### The `coding-sparksql` + `coding-tsql` overlap is expected

Both rules matching `notebook-content.sql` is **not** a bug to fix by
narrowing a glob. Fabric emits that one file name for two dialects, and
the discriminator — `kernel_info.name` in the `-- META` header — lives
*inside* the file where no glob can reach it:

| `kernel_info.name` | Cell `language` | Dialect | Rule that wins |
| --- | --- | --- | --- |
| `synapse_pyspark` | `sparksql` | Spark SQL | `coding-sparksql` |
| `sqldatawarehouse` | `sql` | T-SQL on a Warehouse | `coding-tsql` |

Both shapes are confirmed against public Git-synced exports
(`edkreuk/FMD_FRAMEWORK` @ `ebe97d4`, `LanreAdetola/wwi_fabric_dw` @
`493bea1`). Each rule carries a precedence section naming the other, so
the co-load resolves in prose. There is deliberately **no** second
fixture for the `sqldatawarehouse` variant: it is glob-identical to this
one, so it would test nothing the static check can see.

**Whenever you judge a *(none)* row, run the rules pass too.** A skill gap
and a total gap are different problems.

## Fabric item types with no skill at all

One fixture below is a real Fabric item type that the payload has no
skill for: `KQLQueryset`. That is the *current* truth rather than a
target, and it is common in `fabric-acme`.

`DataPipeline` was the other, and is **no longer** one: `fabric-data-pipeline`
landed 2026-09-02, taking the "yes" its brief recommended
(`docs/handoff-briefs/execute/item-type-skill-datapipeline.md`). Its three
rows above are the assertion that changed — see assertion 6.

`Lakehouse` is **decided: no skill**, 2026-09-01, and its brief is spent.
A Git-synced Lakehouse is four files and no data — tables, files and the
SQL analytics endpoint never reach Git — so a "Lakehouse skill" would
describe things no agent sees in the repo. The one genuinely uncovered
thing was the *shortcut* payload, and it went to the skill that already
owns the syntax: `fabric-variable-library` now globs
`shortcuts.metadata.json`. Reconsider only if Lakehouse gains a procedure
that is neither shortcut nor ALM.

`KQLQueryset` is **decided: no skill**, 2026-08-31, and its brief is
spent. There is no KQLQueryset procedure — no ordering, no refusal
conditions, no lifecycle. What the file needs is KQL authoring
conventions, which already existed and were correct; only the glob failed
to reach it. A skill would
have duplicated a rule. Reconsider only if a genuine procedure appears —
queryset-to-dashboard promotion, or cross-environment `dataSources`
rebinding — and even then that content belongs in `fabric-cicd` or
`fabric-eventhouse` before it justifies a new skill.

`KQLQueryset` and `Lakehouse` are kept as fixtures regardless, because they
are the natural negative controls — a glob that starts matching them is
over-broad.

## Known gaps

- **No `Environment`, `Reflex`, `MirroredDatabase`, `CopyJob` or
  `SparkJobDefinition` fixture.** None has a conditional skill today.
  Several were candidates for a `paths:` glob under Workstream E of the
  retired `skill-context-cost.md`, which closed 2026-09-01 having written
  five globs; these item types were not among them because no export
  confirmed a fixture. Add the fixture *with* the glob, in the same commit.
- **`fabric-git-serialization`'s item-type list is only partly verified.**
  Carried forward from `rule-glob-gaps.md` when that brief was deleted:
  three names (`GraphModel`, `UserDataFunction`, `ApacheAirflowJob`) were
  confirmed against real Git-synced exports and added, and `Dataflow` was
  checked and is **correct** — 246 public exports use `<name>.Dataflow`,
  while `DataflowGen2` is a portal name that never reaches Git. The rest
  of the list was never re-verified, and nothing keeps it current as
  Fabric ships item types. A full pass is cheap: one `filename:.platform`
  code search per candidate name. A missing entry here means an item type
  gets **no rule at all**, which is how the `GraphModel` gap was found.

## Refreshing this table

Token figures drift whenever a skill body changes. Re-run the static
check in [README.md](README.md) and update the numbers; a changed number
is expected, a changed *skill list* is a regression.
