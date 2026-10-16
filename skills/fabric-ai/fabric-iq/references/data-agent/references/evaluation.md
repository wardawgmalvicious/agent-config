# Fabric Data Agent: evaluating an agent

Split out of [data-agent.md](../data-agent.md), which keeps the summary.
Two routes ask an agent a set of questions and judge each reply, and
they suit different jobs:

| | Learn's `evaluate_data_agent` | This skill's `data-agent-eval.py` |
| --- | --- | --- |
| Runs | in a Fabric notebook | on a workstation, by `uv run` |
| Expected answer | a literal, written once | a DAX query, run at ask time |
| Judge | an LLM critic | the reply's figures, matched by rule |
| The agent's DAX | in its step records | beside each reply |
| Results | a lakehouse table | a JSON file per run |
| Suits | a scheduled regression that keeps history | the loop between instruction edits |

A literal answer for "last month" goes stale with the data, a wrong
answer is diagnosed from its DAX, which a critic's verdict does not
show, and a notebook and a lakehouse are a lot to stand up for a
five-minute check. The script answers those three; the notebook route
still fits a regression run on a schedule, its history in a lakehouse.

## The script

`data-agent-eval.py` sits in this skill's `scripts/`, at the path
`SKILL.md` § 3 names, beside `data-agent-settings.py`, which changes the
draft and publishes it. Each script's docstring is its usage, and
[authoring-workflow.md § Testing an edit before it ships, by script](authoring-workflow.md#testing-an-edit-before-it-ships-by-script)
runs the two as one loop.

It asks each question in a cases file, YAML, JSON or the SDK's CSV of
`question` and `expected_answer`, by one of two routes:

- `--route responses`, the default: the SDK's Responses client, asking
  the published agent (`--stage production`, the default) or the draft
  (`--stage sandbox`), and keeping the question as the agent rewrote it
  and the DAX it ran.
- `--route mcp`: the published agent's MCP endpoint, what consumers get,
  with no trace.

Each case's `dax` runs against the semantic model the agent reads,
through Power BI's `executeQueries`, and every cell it returns must
appear in the reply: a number to the precision the reply writes it in,
so `$4.8 million` states 4,812,345.67 while `1,000` does not state
1,234; a date in a common form; text as whole words, ignoring case. A
case passes with every value found, fails with one missing, goes to
review with nothing to check, and errors when the question or a query
fails. `show` prints a results file whole, and `regrade` grades its
stored replies again without asking. It exits 1 on any failure or
error, 2 on a bad argument.

Three choices the script makes, and why:

- **The truth runs just before and just after each question**, and the
  refresh history is not read: Learn's Direct Lake overview says the
  refresh history's Direct Lake tab lists failures, while successful
  framing operations "aren't typically listed" unless the refresh status
  changes, and automatic updates frame whenever Delta data changes (read
  2026-10-16). A case whose two runs differ is marked moved, and passes
  against either.
- **Only the reply's text is graded**, never its result files, since the
  text is what a person reads: a figure that sits only in
  `result_0.csv` counts as missing.
- **Every truth cell is checked**, so a truth query returns the figures,
  plus a label only where the reply must name it. A month goes in as its
  first date, which matches "February 2024", "Feb 2024" and "2024-02",
  rather than a `MonthYear` label the agent may word its own way.

Its limits, as written on 2026-10-15:

- `fabric-data-agent-sdk` is pinned `==0.1.33a0`, a pre-release whose
  names still move: bump it deliberately, then rerun one live case.
- Both scripts sign in through `AzureCliCredential` alone, so
  `AZURE_CONFIG_DIR` picks the tenant. The MCP endpoint accepts a
  service principal too ([authentication.md](authentication.md)); the
  scripts do not.
- `TODAY()` in a truth query is the service's date, in UTC. Where the
  model has a measure for its own local today, use that.
- The first `uv run` installs about 117 packages, since the SDK brings
  `sempy` with it.

Both routes ran in one client estate on 2026-10-15, as did
`data-agent-settings.py`'s reads and dry runs. Its `set` and `publish`
have not run in this form, though the same calls ran from an earlier
session's scripts. `tests/scripts/data-agent-eval/` checks the usage
refusals and the grader offline.

## Learn's route: `evaluate_data_agent`

Learn's
[Evaluate your data agent (preview)](https://learn.microsoft.com/fabric/data-science/evaluate-data-agent)
runs `evaluate_data_agent` in a notebook, over a DataFrame or a CSV of
`question` and `expected_answer`, against an agent published to the
stage evaluated, then reads the run back with `get_evaluation_summary`
and `get_evaluation_details` (read 2026-10-16). A `critic_prompt`
replaces the built-in judge, and must hold the `{query}`,
`{expected_answer}` and `{actual_answer}` placeholders.

Read from the installed 0.1.33a0 source on 2026-10-15, and not run:

- It defaults to `FabricOpenAIResponses`, so it outlives the Assistants
  API's retirement on 2026-08-26
  ([status-and-retirements.md](status-and-retirements.md)).
- It takes `output_format` (`delta_table`, `delta`, `json`, `csv`,
  `parquet`) and `output_path`: an `abfss://` URI, which needs no
  attached lakehouse, or `Tables/<schema>/<table>` on a schema-enabled
  lakehouse whose schema already exists. With neither, on Spark, a
  schema-enabled lakehouse gets `eval_result.<table_name>`. Pass
  `output_path` rather than saving the output again.
- It takes `num_query_repeats` (default 1) and `max_workers` (default
  5).
- Its step records keep the generated `sql` and `dax`.
- `report.py` reads fixed columns: `evaluation_judgement`, the verdict,
  `actual_answer`, `expected_answer` and `thread_url`.

Whether it runs outside Fabric is untested: its storage code branches on
Spark or a Fabric Python notebook.
