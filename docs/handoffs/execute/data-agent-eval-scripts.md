---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-15
---

# Handoff: data agent evaluation scripts for fabric-iq

- **Written**: 2026-10-15, from one inbox note of 2026-10-15 by a
  session in a client Fabric estate, with three files beside it.
  Re-measured against the payload at `f8abbed`: fabric-iq has no
  `scripts/` folder, and nothing names `evaluate_data_agent`.
- **Kind**: an edit that adds two scripts, a test suite and the lines
  that point at them. The scripts are written; nothing in the payload is
  drafted.

## The files, and where they wait

`~/handoff-inbox/agent-config/2026-10-15-data-agent-eval-scripts/`,
kept with its note, `2026-10-15-data-agent-eval-scripts.md`, until this
brief lands, since they exist nowhere else. Each script's docstring is
its usage. sha256 on 2026-10-15, first 12 digits:

| File | sha256 | Home |
| --- | --- | --- |
| `data-agent-eval.py` | `b8c2ae6f117e` | `skills/fabric-ai/fabric-iq/scripts/` |
| `data-agent-settings.py` | `45728b3dd1da` | the same |
| `test-data-agent-eval.sh` | `c55641df7a3b` | `tests/scripts/data-agent-eval/` |

- **`data-agent-eval.py`** asks an agent each question in a cases file
  (YAML, JSON, or the evaluation SDK's CSV) and grades the reply against
  the model's own figures: each case's DAX runs through Power BI's
  `executeQueries` just before and just after its question, and every
  cell it returns must appear in the reply, numbers to the precision the
  reply writes them in, dates in common forms, text as whole words
  ignoring case. Two routes: the Responses client, published or draft,
  with the rewritten question and the DAX; and the published agent's
  MCP endpoint, what consumers get, with no trace. `show` prints a
  results file; `regrade` grades the stored replies again without
  asking. Self-contained by PEP 723 metadata, with
  `fabric-data-agent-sdk==0.1.33a0` pinned.
- **`data-agent-settings.py`** reads both stages (the runtime, an
  instructions fingerprint, whether draft and published differ, the
  published description), saves the draft's instructions to a file,
  sets the draft's instructions or runtime, and publishes keeping the
  current description; each write reads back what it wrote.
- **`test-data-agent-eval.sh`** follows `tests/scripts/never-prompted/`'s
  shape: six usage refusals that must exit 2 before any sign-in, and 34
  grader cases through `regrade` on a fixture, each id's first word the
  verdict owed. `DATA_AGENT_EVAL` points it at another copy.

## Why a script beside Learn's route

Learn's *Evaluate your data agent (preview)* runs the SDK's
`evaluate_data_agent` in a Fabric notebook, with literal expected
answers, an LLM critic and results in a lakehouse. For the authoring
loop it misses three things: an expected answer for "last month" goes
stale with the data; a wrong answer is diagnosed from its DAX, which the
critic's verdict does not show; and it needs a notebook and a lakehouse
for a five-minute check between instruction edits. The script computes
each expected answer from the model at ask time and grades
deterministically. Three choices the reference text should keep:

- **Truth runs before and after each question**, and the refresh history
  is not read: Learn's Direct Lake overview says successful framing
  operations "aren't typically listed". A case whose two runs differ is
  marked moved and passes against either.
- **Only the reply's text is graded**, not its result files, since the
  text is what a person reads.
- **Every truth cell is checked**, so a truth query returns the figures,
  plus a label only where the reply must name it; a month goes in as its
  first date, which matches "February 2024".

The loop: `show --save draft.txt`, edit, `set --instructions draft.txt`,
`run … --stage sandbox`, `publish`, then `run … --route mcp`.

The in-Fabric route still fits a scheduled regression that keeps its
history in a lakehouse. From the installed 0.1.33a0 source, read on
2026-10-15 by the note's session and not run: `evaluate_data_agent`
defaults to `FabricOpenAIResponses`, so it outlives the Assistants API's
retirement on 2026-08-26 (the date on Learn's Python-client page). It
takes `output_format` (`delta_table`, `delta`, `json`, `csv`,
`parquet`) and `output_path`, an `abfss://` URI or
`Tables/<schema>/<table>` on a schema-enabled lakehouse whose schema
exists; with neither, on Spark, it writes `eval_result.<table_name>`
there. It takes `num_query_repeats` (default 1) and `max_workers`
(default 5); its step records keep the generated `sql` and `dax`; and
`report.py` reads `evaluation_judgement`, `actual_answer`,
`expected_answer` and `thread_url`. A `critic_prompt` needs the
`{query}`, `{expected_answer}` and `{actual_answer}` placeholders
(Learn). Whether it runs outside Fabric is untested.

## The decision: where the scripts live

The user chose `skills/fabric-ai/fabric-iq/scripts/` on 2026-10-16, the
home `.claude/rules/editing-skills.md` § "Bundled scripts" gives a
deployed skill's scripts, over `references/data-agent/scripts/`, which
they had asked the note's session for. The `data-agent-` prefix keeps
them apart from any later ontology or graph scripts.

## Spelling the path in a per-project group

That rule has `SKILL.md` name a script `${CLAUDE_SKILL_DIR}/scripts/<file>`
and a `references/` file spell `~/.claude/skills/<name>/scripts/<file>`.
The Fabric groups are not deployed at user scope, as root `CLAUDE.md`'s
`ls ~/.claude/skills | grep` check asserts: client repos hold them as
project-scope junctions, where that `~` path does not exist. So name the
scripts in `fabric-iq/SKILL.md` by `${CLAUDE_SKILL_DIR}`, and have
`references/` point at that line. The rule's measurement of the
substitution (2.1.293, 2026-10-12) does not say which scope it covered:
probe it at project scope before relying on it, then give the rule a
clause on per-project groups.

## Where it lands

- The three files at the decided homes, the suite under
  `tests/scripts/data-agent-eval/`.
- `fabric-iq/SKILL.md`: one line naming both scripts, where it routes to
  the data agent reference.
- `references/data-agent/references/authoring-workflow.md`: the loop,
  beside § Settings and publish, by REST;
  `consumption-surfaces.md`: the two routes, a line each; and
  `data-agent.md`, or a short evaluation file beside it: the two
  evaluation routes side by side.
- `.claude/rules/editing-skills.md` § "Bundled scripts": the clause.

A `SKILL.md` line owes `/test-skill fabric-iq`, from a probe copy.

## Not checked

- The write paths: `set` and `publish` have not run in this form,
  though the same calls ran from the note's session's earlier scripts.
- Whether `PATCH staging/settings` merges inside `experimental`; `set`
  sends the draft's other flags along either way.
- The suite, here: the note's session passed 43 and failed 0, and found
  Ruff clean under the payload's `ruff.toml`. Re-run both.

## Open points from the note

- The SDK is pinned to a pre-release: bump it deliberately, and rerun
  one live case after.
- The MCP endpoint accepts a service principal (Learn), but both scripts
  sign in through `AzureCliCredential` only.
- The docstring's example uses `TODAY()`, which is UTC in the service; a
  model with a local today measure should use that in its cases.

## Scrubbing

The three files were checked on 2026-10-15 for GUIDs, client prefixes
and tenant names and hold none; the note says the test's figures are
made up. The note's own verification lines are raw, with agent,
workspace and model IDs, a model name and figures, and are not carried.
Once this lands, the note and its folder are deleted on the user's yes.

## Re-measure before acting

```bash
sha256sum ~/handoff-inbox/agent-config/2026-10-15-data-agent-eval-scripts/*   # against the table above
ls skills/fabric-ai/fabric-iq/                                                   # no scripts/ on 2026-10-15
bash ~/handoff-inbox/agent-config/2026-10-15-data-agent-eval-scripts/test-data-agent-eval.sh | tail -n 1
```
