# Fabric item-type trigger fixtures

Minimal but structurally real Fabric Git-synced item folders, used to test
**`paths:` activation** — which conditional skills load when a given file
enters session scope.

Companion to [`../pbip-triggers/`](../pbip-triggers/), which covers the
Power BI half. Same contract, same method, disjoint skills: 9 there, 10
here, and that is all 19 conditional skills in the payload.

## Why this exists

Every other fixture set here tests what a skill *does once invoked*. These
two test whether it fires at all, which is a different contract and the one
that fails silently. **There is no observability for conditional skill
activation on this machine** — `instructions-loaded.log` records only
rules, and `skills-invoked.log` and `skillUsage` count *invocations*, while
a path-triggered skill is *loaded* and never invoked. A zero in any of them
says nothing. See [`../pbip-triggers/README.md`](../pbip-triggers/README.md)
for the full table.

This set also closes the one assertion `pbip-triggers` could not: that
`.platform` in a non-PBIP item type does **not** pull
`pbip-project-structure`.

## File layout

```text
tests/skills/fabric-triggers/fixtures/
├── SampleEH.Eventhouse/            .platform, EventhouseProperties.json
│   └── .children/SampleKDB.KQLDatabase/
│                                   .platform, DatabaseProperties.json,
│                                   DatabaseSchema.kql,
│                                   EmbeddedRealTimeQueryset.json
├── SampleES.Eventstream/           .platform, eventstream.json,
│                                   eventstreamProperties.json
├── SampleDash.KQLDashboard/        .platform, RealTimeDashboard.json
├── SampleNB.Notebook/              .platform, notebook-content.py,
│                                   notebook-settings.json
├── SampleVL.VariableLibrary/       .platform, settings.json, variables.json,
│                                   valueSets/ENV-3P.json
├── SampleWH.Warehouse/             .platform, SampleWH.sqlproj,
│                                   ingest/Tables/Control.sql,
│                                   ingest/Views/vw_LatestRun.sql
├── SampleSQL.SQLDatabase/          .platform, .gitignore,
│                                   SampleSQL.sqlproj,
│                                   dbo/Tables/Customer.sql
├── SampleGraph.GraphModel/         .platform, dataSources.json,
│                                   graphDefinition.json, graphSettings.json,
│                                   graphType.json, stylingConfiguration.json
├── SampleAgent.DataAgent/          .platform
│   └── Files/Config/               data_agent.json, publish_info.json
│       ├── draft/                  stage_config.json,
│       │                           sql-database-SampleSQL/datasource.json,
│       │                           sql-database-SampleSQL/fewshots.json
│       └── published/              (mirrors draft/)
├── SamplePL.DataPipeline/          .platform, pipeline-content.json
├── SampleLH.Lakehouse/             .platform, lakehouse.metadata.json
├── SampleQS.KQLQueryset/           .platform, RealTimeQueryset.json
└── control/notes.md                (matches nothing — negative control)
```

The last four item types have **no skill in the payload**. They are here as
negative controls and to make that coverage gap visible — see
[expected_activations.md](expected_activations.md).

## What these fixtures are modelled on

Most shapes are taken from real item folders in `C:\Repos\ACME\fabric-acme`:
folder naming, the `.platform` schema and `metadata.type` value, the
`.children/` nesting a KQLDatabase sits in under its Eventhouse, the
`# META` comment blocks in `notebook-content.py`, the Warehouse
`ingest/{Tables,Views}/*.sql` split.

`GraphModel`, `SQLDatabase` and `DataAgent` do not exist in ACME. They are
modelled instead on **public Git-synced exports on GitHub**, pinned here so
a later reader can re-check them rather than take this file's word:

| Fixture | Modelled on | Corroborated by |
| --- | --- | --- |
| `SampleAgent.DataAgent/` | `microsoft/unified-data-foundation-with-fabric-solution-accelerator` @ `167c308`, `Azure-Samples/agentic-app-with-fabric` @ `5e48120` | the `Files/Config/{draft,published}` layout in [Source control for Fabric data agent](https://learn.microsoft.com/fabric/data-science/data-agent-source-control) |
| `SampleGraph.GraphModel/` | `frkim/NovaSteel3` @ `8a1efa7`, `rasgiza/RTI-Hackathon-Demo` @ `39eebf3` | the definition parts in the REST [Graph Model definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/graph-model-definition) reference |
| `SampleSQL.SQLDatabase/` | `microsoft/fabric-cicd` @ `sample/workspace`, `ProdataSQL/DWA` @ `Workspaces/DWA` | `<name>.SQLDatabase` and the `dbo/Tables/*.sql` layout in [SQL database source control](https://learn.microsoft.com/fabric/database/sql/source-control) |

The three `metadata.type` values were checked directly rather than assumed.
A GitHub code search for `"type": "DataAgent"` inside `.platform` files
returns 78 real exports; `"type": "GraphModel"` returns two (plus this
fixture set); `"type": "AISkill"` — the legacy name still carried in
fabric-cli's `ItemType` enum and in the portal's `/aiskills/` URL — returns
**none**. The portal name did not follow the item type into Git.

Two deliberate deviations from those sources. The real `.SQLDatabase`
`.gitignore` is the full ~480-line `dotnet new gitignore`; the fixture
carries a three-line stand-in that says so in its own header. And every
other byte is synthetic content laid on the observed structure — GUIDs
zeroed, and the one non-schema URI in the set (the `abfss://` Delta path in
`dataSources.json`) zeroed on both its workspace and item GUID.

**Contents are synthetic.** No file is copied from an export, ACME's or
GitHub's. Every GUID is `00000000-…`, every URI is a schema URL bar the one
zeroed `abfss://` path noted above, and nothing carries a workspace name,
cluster URI, or key-vault reference. Keep it that way — `tests/` is
gitleaks-allowlisted precisely because fixtures contain credential-*shaped*
strings, so the allowlist cannot catch a real one that lands here.

### Fixtures built on an unverified shape

None, as of 2026-08-31. Three of these were, until then: their folder names
came from their own skills' claims, so the fixture could only prove that
the glob and the assumed path agreed with each other — never that the
assumption was right, which is the thing that fails silently. A wrong
item-type name has no error path; the skill just never fires, in every
client repo, forever.

If you add a fixture for an item type nobody here has an export of, name it
in this section. A glob must not be allowed to vouch for itself.

## Running the test

**Cold session required.** `paths:` is frontmatter, and in-place
frontmatter hot-reload is the one case not verified on this machine — a
warm session may be reporting the pre-edit globs.

### Fast path — static, no session needed

This is the cheap regression test. It confirms the globs still resolve as
documented, and catches a broken glob without spending a session:

```bash
# uv run --with pyyaml --with wcmatch python thisfile.py
import pathlib, yaml
from wcmatch import glob as wg
F = wg.GLOBSTAR | wg.DOTGLOB          # DOTGLOB is required — .platform
skills = {}                            # and .children/ are dotted
for p in sorted(pathlib.Path('skills').glob('*/*/SKILL.md')):
    d = yaml.safe_load(p.read_text(encoding='utf-8').split('---', 2)[1])
    if d.get('paths'):
        skills[d['name']] = d['paths']
base = pathlib.Path('tests/skills/fabric-triggers/fixtures')
for f in sorted(base.rglob('*')):
    if f.is_file():
        hits = [n for n, pats in skills.items()
                if wg.globmatch(f.as_posix(), pats, flags=F)]
        print(f"{f.relative_to(base).as_posix():<66} {sorted(hits)}")
```

Compare against [expected_activations.md](expected_activations.md). Point
it at `../pbip-triggers/fixtures` to check the other half; the union of the
two runs must cover all 19 conditional skills.

**Run it a second time over `claude/rules/*.md`** — same code, swap the
`skills/*/*/SKILL.md` glob for `claude/rules/*.md` and key on `p.stem`.
Rules carry `paths:` globs too and load on these same files, so a file with
no *skill* may still pull a rule. Doing only the skills pass is how the
first version of this fixture set reported "activates nothing" for files
that load `fabric-git-serialization`.

### Real path — does the harness agree?

The static check tests the globs. It does **not** test that Claude Code
actually loads on a match. For that, in a fresh session, read one fixture
file and then ask which skills are available.

Read the listing carefully: it normally shows **unconditional skills
only**. A conditional skill appearing is the positive signal; its absence
in a session where nothing matched is correct, not a failure.

For a machine-readable capture:

```bash
claude -p "Read <fixture path> and reply ok" --model opus[1m] \
  --debug-file /tmp/trig.log
grep -iE "conditional|unique skills|via attachment|<skill-name>" /tmp/trig.log
```

Grep for the **skill name**, not only `via attachment`. The
`Sending N skills via attachment (initial)` line is emitted *before* the
Read runs, so it cannot show a file-triggered activation and reading it as
a negative result is a mistake.

Always run `control/notes.md` as well. It matches nothing, so if a
conditional skill shows up there, the observation method is broken rather
than the globs.

## Cost note

These files are inert until opened. Reading anything under
`SampleNB.Notebook/` pulls ~4,418 tokens of skill bodies — the worst
activation in this set, and two skills no path can separate. Don't leave a
fixture open while doing unrelated work.
