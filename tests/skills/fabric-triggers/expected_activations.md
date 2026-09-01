# Expected activations

Measured 2026-08-31 against the payload at commit `ee0a8f5`, using the
static glob check in [README.md](README.md). Token figures are body size
at ~3.5 chars/token — relative weights, not billing figures.

Shapes are modelled on `C:\Repos\ACME\fabric-acme`, except the three noted
under "Fixtures built on an unverified shape" in the README.

| Fixture file | Activates | Tokens |
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
| **`SampleNB.Notebook/.platform`** | `fabric-error-handling`, `fabric-spark` | **4,418** |
| `SampleNB.Notebook/notebook-content.py` | `fabric-error-handling`, `fabric-spark` | 4,418 |
| `SampleNB.Notebook/notebook-settings.json` | `fabric-error-handling`, `fabric-spark` | 4,418 |
| `SampleVL.VariableLibrary/.platform` | `fabric-variable-library` | 2,693 |
| `SampleVL.VariableLibrary/settings.json` | `fabric-variable-library` | 2,693 |
| `SampleVL.VariableLibrary/variables.json` | `fabric-variable-library` | 2,693 |
| `SampleVL.VariableLibrary/valueSets/ENV-3P.json` | `fabric-variable-library` | 2,693 |
| `SampleWH.Warehouse/.platform` | *(none)* | 0 |
| `SampleWH.Warehouse/SampleWH.sqlproj` | *(none)* | 0 |
| `SampleWH.Warehouse/ingest/Tables/Control.sql` | `fabric-warehouse` | 2,975 |
| `SampleWH.Warehouse/ingest/Views/vw_LatestRun.sql` | `fabric-warehouse` | 2,975 |
| `SampleSQL.SQLDatabase/.platform` | *(none)* | 0 |
| `SampleSQL.SQLDatabase/SampleSQL.sqlproj` | *(none)* | 0 |
| `SampleSQL.SQLDatabase/dbo/Tables/Customer.sql` | `fabric-database` | 608 |
| `SampleGraph.GraphModel/.platform` | `fabric-graph` | 2,662 |
| `SampleGraph.GraphModel/graphmodel.json` | `fabric-graph` | 2,662 |
| `SampleAgent.DataAgent/.platform` | `fabric-data-agent` | 3,071 |
| `SampleAgent.DataAgent/SHAPE-UNKNOWN.md` | `fabric-data-agent` | 3,071 |
| `SamplePL.DataPipeline/.platform` | *(none)* | 0 |
| `SamplePL.DataPipeline/pipeline-content.json` | *(none)* | 0 |
| `SampleLH.Lakehouse/.platform` | *(none)* | 0 |
| `SampleLH.Lakehouse/lakehouse.metadata.json` | *(none)* | 0 |
| `SampleQS.KQLQueryset/.platform` | *(none)* | 0 |
| `SampleQS.KQLQueryset/RealTimeQueryset.json` | *(none)* | 0 |

Together with `../pbip-triggers/`, all **19** conditional skills in the
payload are now covered — 9 there, 10 here.

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
`fabric-warehouse` globs `**/*.Warehouse/**/*.sql`, so `.platform` and
`.sqlproj` get no guidance. Same for `fabric-database`. This is the glob
as written, deliberately narrow — recorded here so a later widening is a
visible decision rather than a silent one, and so the zero rows are not
read as a fixture defect.

**3. `fabric-spark` and `fabric-error-handling` are inseparable.** Both
glob `**/*.Notebook/**`, so every Notebook file pulls 4,418 tokens of two
skills and no path can select one. That is the standing case for
Workstream C1 in
`docs/handoff-briefs/execute/skill-context-cost.md`, and this fixture is
the measurement behind it.

**4. `control/notes.md` activates nothing.** If it does, the observation
method is wrong. Check this before believing any other row.

## Fabric item types with no skill at all

Three fixtures below are real Fabric item types that the payload does not
cover: `DataPipeline`, `Lakehouse`, `KQLQueryset`. They activate nothing,
and that is the *current* truth rather than a target. They are kept
because they are the natural negative controls — a glob that starts
matching them is over-broad — and because they make the coverage gap
visible. All three are common in `fabric-acme`.

## Known gaps

- **Three shapes are unverified** — `GraphModel`, `SQLDatabase`,
  `DataAgent`. See the README section of that name.
- **No `Environment`, `Reflex`, `MirroredDatabase`, `CopyJob` or
  `SparkJobDefinition` fixture.** None has a conditional skill today.
  Several are candidates for a `paths:` glob under Workstream E in
  `docs/handoff-briefs/execute/skill-context-cost.md`; add the fixture
  *with* the glob, in the same commit.

## Refreshing this table

Token figures drift whenever a skill body changes. Re-run the static
check in [README.md](README.md) and update the numbers; a changed number
is expected, a changed *skill list* is a regression.
