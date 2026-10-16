---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-15
---

# Handoff: debugging a data agent over a semantic model starts from its DAX

- **Written**: 2026-10-15, from one inbox note of 2026-10-15 by a
  session in a client Fabric estate, testing a data agent over one
  Direct Lake semantic model through its MCP endpoint and the Python
  SDK's Responses client. Re-measured against the payload at `f8abbed`:
  nothing names the Responses client, the settings calls or the runtime
  flag. The same note's correction on verified answers landed on
  2026-10-15 in `data-agent.md` and `configuration-layers.md`.
- **Kind**: an edit to fabric-iq's data agent references and one gotchas
  row. Nothing is drafted. `data-agent-eval-scripts.md` waits on it for
  the reference text its scripts point beside.

## 1. The DAX, by the Responses client

An MCP answer carries text, and on the preview runtime an embedded CSV,
but no DAX. The Python SDK (`fabric-data-agent-sdk`, preview; the note's
session ran 0.1.33a0) returns it:

```python
from fabric.dataagent.client import FabricOpenAIResponses
client = FabricOpenAIResponses(agent_id, workspace_id, ai_skill_stage="production", credential=AzureCliCredential())
response = client.responses.create(input=question)
```

`production` asks the published agent and `sandbox` the draft, and
`response.output` holds every step:

- a `function_call` named `trace.analyze_semantic_model`, whose
  `arguments.query` is the question as the agent rewrote it for the DAX
  step;
- on the preview runtime, `askPBI.tool.execute`, whose `arguments.code`
  is the DAX, inside a code fence tagged `dax`;
- on the standard runtime, `analyze.database.nl2code`, which writes DAX
  variations, then `analyze.database.execute`, whose `arguments.code` is
  the DAX run;
- `function_call_output` items, the result the model saw: the preview
  tool's begins "The dataset contains N rows", and the standard tool's
  can begin "Note: This result is incomplete. The query matched at least
  1001 rows, but only the first 200 are included here.";
- a final `message`, the reply.

It runs outside a notebook with an Azure CLI credential, so
`AZURE_CONFIG_DIR` picks the tenant. Each call runs the agent anew:
asked the same question minutes apart, it and the MCP endpoint named
different lowest months. Reproduced on 2026-10-15 by the note's session,
four runs, two per runtime.

**A correction to the note**, which calls the trace the only route to
the DAX: Learn's semantic model best practices page, step 7 of its
recommended workflow, has the author review the DAX of each response in
the agent's own step panel (read 2026-10-15). The Responses trace is the
scripted route, and the one a script can grade.

`references/status-and-retirements.md`'s SDK line says querying moved
to the MCP endpoint; the Responses client still queries, and it is the
one that shows the DAX.

## 2. The settings, by REST

Under `https://api.fabric.microsoft.com/v1/workspaces/{ws}/dataAgents/{id}/`,
with a Fabric token, by the note's session on 2026-10-15, six publishes
each read back from both stages:

- `GET staging/settings` (the draft) and `GET settings` (published)
  return `{aiInstructions, experimental}`;
- `PATCH staging/settings` takes `{"aiInstructions": …}` or
  `{"experimental": {…}}`, and keeps whatever it is not sent;
- `POST staging/publish` takes `{"publishedDescription": …}` and
  publishes the draft.

`experimental.enableExperimentalFeatures` `true` is the **preview
runtime**. Set `false`, it is the **standard runtime**, and both GETs
then **omit the key**, returning `{"codeInterpreterEnabled": true}`
alone, so read a missing key as false: a check written `is False` failed
the note's own script. The published agent keeps the runtime it was
published with, which Learn's data agent runtime page agrees with (read
2026-10-15), and Git shows the item modified until someone commits it
from the workspace. Learn's REST reference lists no call for a data
agent's instructions or runtime (read 2026-10-15 by the note's session).

Unverified: Learn's sample switches with
`update_configuration(enable_preview_features=True)`, while the note's
read of the 0.1.33a0 source recorded `update_configuration` as legacy
and `update_settings(ai_instructions, experimental)` as the public
route; check the installed SDK before naming either. Unmeasured: whether
the PATCH merges inside `experimental` or replaces it whole.

## 3. Agent instructions reach the DAX through the rewritten question

Learn says data-agent-level instructions are not passed to the DAX
generation tool (the best practices page, step 8). The note's session
found them shaping the question the orchestrator rewrites before it
calls that tool, for better and for worse. Each fault below showed in
one or two of twelve answers and was gone the round after its fix, one
round each, on 2026-10-15:

- **A scope line is read as all the model holds.** A line listing the
  model's measures drew refusals of questions by item, that the model
  held no items, one in 4.3 s with no query. Naming the breakdowns too,
  by date, item, customer and the like, and adding "Query the model
  before saying it cannot answer a question" ended them.
- **The agent works out relative dates itself.** "This year" became a
  range from the previous year's 1 January, and "last month" a month
  seven months off. The fix: "Never work out a date yourself: pass a
  period such as this year or last month to the query as written, ask it
  to return the dates it covers, and name the period from those." The
  rewritten question then asked for last month's figure and the date
  range covered, and the DAX took the period from the model's own today
  measure.
- **On the standard runtime, asking for the dates can bring back empty
  rows.** Its DAX set the dates as never-blank `SUMMARIZECOLUMNS`
  columns, so a breakdown returned every calendar month and every item
  ever ordered, and the answers read an empty month at $0 as the lowest.
  The preview runtime's DAX made them measures guarded by
  `IF(NOT ISBLANK(…))` and kept no empty row. `claude/rules/coding-dax.md`
  § Anti-patterns carries the `IGNORE` fix since 2026-10-15.
- **On the preview runtime, no instruction removes the result-file
  line.** Its query tool's output tells the model always to include the
  filename, so answers end "File(s) result_0.json were generated as a
  result of the query." even under "never mention a result file", which
  did stop the answers naming it anywhere else. MCP answers on preview
  also embed `file:///result_0.csv`: the line ended 11 of 12 preview
  answers and 0 of 12 standard ones, with 13 embedded CSVs against 0.

So for a semantic model source, use the agent instructions to shape the
question the DAX tool receives, with periods passed as relative,
breakdowns named and a query before any refusal; keep business logic in
the model's AI instructions; and re-read the DAX after any change, since
one line can help on one runtime and hurt on the other. The runtimes
differ for semantic models as well as SQL: Learn's best practices page
§ Advanced DAX generation (preview) makes it a preview-runtime tool, and
its search of column values needs the model's Q&A setting, which retires
in December 2026 (the note's reading, not re-read here).

## Where it lands

All under `skills/fabric-ai/fabric-iq/references/data-agent/` unless
named:

- **1**: a bullet in `references/consumption-surfaces.md` beside the MCP
  endpoint, and the SDK line in `references/status-and-retirements.md`.
- **2**: a section in `references/authoring-workflow.md` after § "Where
  each layer lands in a Git-synced repo"; one clause in `data-agent.md`'s
  runtime paragraph, under § The four configuration layers; and a row in
  `skills/fabric-core/fabric-rest-api/references/gotchas.md`. Its
  symptom: a data agent's settings show no `enableExperimentalFeatures`
  after a runtime switch. Its cause: the API omits the key once false,
  the standard runtime. Its owner: fabric-iq's `authoring-workflow.md`.
- **3**: a paragraph on semantic model sources in
  `references/configuration-layers.md` § 1. Agent instructions, after
  the blob; a pitfall bullet in `data-agent.md` § Common pitfalls
  pointing there; the result-file line in `consumption-surfaces.md`'s
  MCP bullet; the runtime difference in `data-agent.md`'s runtime
  paragraph.
- A pointer in `skills/power-bi/fabric-tmdl/references/ai-instructions.md`
  § "When you use this vs. Data Agent instructions" to `data-agent.md`'s
  verified-answers caveat, for a reader who starts there.

Every file is under `references/`, so none owes a retest.

## Not checked

Nothing here was re-run: every measurement needs the tenant and the
agent. The SDK's source can be read offline, through
`uv run --with fabric-data-agent-sdk==0.1.33a0`, for the
`update_configuration` question.

## Scrubbing

The note was raw: the estate's item, table and measure names and its
figures. Here the instruction lines keep the note's wording minus its
names, the faults are described without the data, and the estate is
cited by kind.

## Re-measure before acting

```bash
grep -rn -E 'FabricOpenAIResponses|staging/settings|enableExperimentalFeatures' skills/   # nothing on 2026-10-15
grep -n 'querying moved' skills/fabric-ai/fabric-iq/references/data-agent/references/status-and-retirements.md
grep -n 'did not in one test' skills/fabric-ai/fabric-iq/references/data-agent/references/configuration-layers.md   # landed 2026-10-15
```
