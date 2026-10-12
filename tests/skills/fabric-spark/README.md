# `fabric-spark` — behaviour cases

`fabric-spark` is the router `fabric-spark-monitoring`,
`fabric-error-handling`, `fabric-mlv` and `fabric-ai-functions` folded
into on 2026-10-12, the second wave after the
[`fabric-deploy` pilot](../fabric-deploy/README.md). It lost its
`**/*.Notebook/**` glob in the fold, so it is always listed and has no
activation contract; these five cases test where it routes and what it
says, a request made in words among them.

## The cases

| Case | Passes when |
| --- | --- |
| `mlv` | `fabric-spark` is invoked with no file read, and reads `references/mlv.md` |
| `aifn` | reads `ai-functions.md`, and the import fits the DataFrame's engine |
| `slow` | reads `spark-monitoring.md`, and times the queue from Livy sessions |
| `errors` | after the notebook Read, reads `error-handling.md`, and writes the Tier 2 `results` shape |
| `abfss` | answers from the body alone, with no reference read |

The prompts, verbatim:

```text
mlv: Our Fabric lakehouse has a silver.orders table that a pipeline appends to every hour. I want a gold table of daily revenue per customer built from it as a materialized lake view, not a notebook we schedule ourselves, and kept up to date as silver changes. Give me the exact code and settings, start to finish.

aifn: In a Fabric notebook I have a Spark DataFrame, tickets_df, of about two million support tickets with a free-text description column. Classify each ticket as billing, outage, login or other with Fabric AI Functions, into a new category column. Give me the code, start to finish.

slow: A Fabric notebook that our pipeline runs every morning sat queued for about ten minutes before it started today, and the run took 25 minutes end to end where it usually takes 12. Why would it queue, and how do I find out where the time went? Give me the exact API calls.

errors: Read TableMaintenance.Notebook/notebook-content.py. It runs nightly from a pipeline. Add error handling to its per-table loop.

abfss: In a Fabric notebook, what abfss path do I use to read the Delta table orders in the sales schema of a lakehouse called SalesLH, in the workspace Finance Analytics?
```

`errors` reads
[fixtures/TableMaintenance.Notebook/notebook-content.py](fixtures/TableMaintenance.Notebook/notebook-content.py),
a per-table `OPTIMIZE` and `VACUUM` loop with no error handling.

## Running them

Build a probe outside this repo, since `.claude/settings.json` here
collapses every platform description to `name-only`:

- `payload/.claude/skills/`: a copy of every folder in `skills/fabric/`.
- `baseline/`: no `.claude/`, run with `--safe-mode`.
- `TableMaintenance.Notebook/` at each arm's root.

Run each case in each arm from that arm's directory, with
`CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1`, as
[`../fabric-deploy/README.md`](../fabric-deploy/README.md) does and for
its reasons:

```powershell
claude -p '<prompt>' --output-format stream-json --verbose --tools Skill,Read --strict-mcp-config --model claude-opus-5-5 --effort xhigh --max-budget-usd 3
```

Add `--safe-mode` on the baseline. The slash arm is
`/fabric-spark <mlv prompt>`, launched from PowerShell, since Git Bash
rewrites a leading `/`.

Read the `init` record for `tools` (2 on every arm) and
`slash_commands`, which must drop on the baseline and lose every Fabric
skill; then the `Skill` and `Read` calls, and the first `result`.

## Result, 2026-10-12

The router held on all five cases. One run per arm, on 2.1.293, Opus
5.5 at `xhigh`, against `7938150`, the fold's second commit, in the
brief's worktree:

| Case | Router | Baseline |
| --- | --- | --- |
| `mlv` | pass: `Skill`, then `mlv.md`, with no file read first; an event-triggered refresh on the pipeline's Job events, its "FMLV Refresh" notebook and Activator, `SUM` and `COUNT` refreshing incrementally, Runtime 1.3 exactly | partial: CDF, schemas and an hourly schedule, unaided; "MLVs don't refresh themselves when silver changes", and unsure an aggregate refreshes incrementally |
| `aifn` | pass: `ai-functions.md` and its tables read; the PySpark import, `OpenAIDefaults` `set_*` config, the Copilot and AI meter | pass on the PySpark accessor, unaided, through an import the reference doesn't give; no meter or defaults |
| `slow` | pass: `spark-monitoring.md` and its APIs read; `queuedDuration` as capacity contention, the five-phase split, `sessionSource` reuse | pass on the Livy timings and History Server routes, unaided; no phase split or session reuse |
| `errors` | pass: `error-handling.md` read; the `results` shape verbatim, `STRICT`, the summary block | partial: a per-table `try` and a final raise; neither the shape nor the flag |
| `abfss` | pass: the body alone, no reference read; the GUID, `Tables/sales/orders`, `notebookutils.runtime.context` | pass, unaided: the space in the name, and the GUID form |

Every payload arm called `Skill` on `fabric-spark` from the startup
listing before any `Read`: in `errors` that came ahead of the notebook
Read the prompt asks for. `slow` also invoked `fabric-rest-api` and
read the router's own `references/REFERENCE.md`. `init` gave `tools` 2
on every arm, and `slash_commands` 79 on the payload, `fabric-spark`
among its nine Fabric skills, against 58 on the baseline, with none.
The slash arm made no `Skill` call and read `mlv.md` straight from the
inlined body, which witnesses the expansion, and answered as the `mlv`
payload did.

**Seen in the run**: `errors` set `STRICT = True` and said why. The
convention defaults to `False` for scheduled runs and keeps `True` for
orchestration, and a notebook a pipeline runs nightly is both; with
`False`, the pipeline would report success over failed tables. Not
changed: the convention is in-house, so which default fits a
pipeline-run notebook is the user's call.

**Listing**: the router's entry is 342 characters, all description,
against the five skills' 2,040 always listed and 2,125 more on a
notebook Read.

**Cost**: router arms $2.39, baseline arms $0.87, the slash arm $0.52.

**What the run cannot show**: variance, with one run per arm; how the
five old skills would have answered, since no arm held them; and the
client repos' listing, which runs to its cap, while this probe lists
the Fabric group alone.

## Not yet measured

Use in client work. After a few weeks of client sessions, run
`uv run --with pyyaml python scripts/skill-telemetry.py triggers`: is
`fabric-spark` invoked when notebook work happens? Before the fold, on
2026-10-12, `skillUsage` counted `fabric-mlv` 6, `fabric-spark` and
`fabric-error-handling` 1 each, and the other two none. Discount this
run's own arms, which sit in this machine's transcripts too: six
payload sessions, each of which reached `fabric-spark`.
