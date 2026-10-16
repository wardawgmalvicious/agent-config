# Fabric Data Agent: authoring workflow and best practices

Split out of [data-agent.md](../data-agent.md), which keeps the pitfalls
table. This file is the positive-form guidance: how to run the authoring loop
and operate an agent once it is live.

## Best practices

- **Scope each instruction to the right layer.** Source-specific guidance in the top-level blob creates noise. Generic business context duplicated across every data source blob creates drift.
- **Keep layers focused and non-contradictory.** Conflicts between layers cause the LLM to hedge or hallucinate.
- **Iterate against real questions.** Write, test, observe failures, adjust. Don't assume a single pass is sufficient.
- **Version control the instructions** alongside the rest of the data platform code. Treat them as first-class artifacts — use Git integration on the Fabric workspace to track changes.
- **Use example queries aggressively** on lakehouse/warehouse/KQL sources. They are the single most effective configuration mechanism for query accuracy.
- **Maintain a regression question bank.** When instructions change, re-run the bank and check for accuracy drift.
- **Use deployment pipelines** to promote agent changes through dev/test/prod.
- **Establish operational oversight.** Monitor interactions via built-in diagnostics, set up logging and audit, and review instructions periodically as data or business rules change.

## Key differences from Semantic Model AI Instructions

- **Structure** — data agent has 4 configuration layers; semantic model has one unstructured text blob.
- **Multi-source** — data agent routes across up to 5 sources; semantic model instructions apply to exactly one model.
- **Example queries / few-shot** — data agent supports them on lakehouse/warehouse/KQL sources (not on semantic model sources); semantic model instructions don't support few-shot.
- **Response formatting and conversational behavior** — configurable in the data agent; explicitly out of scope for semantic model instructions.
- **Character limit** — semantic model is capped at 10,000 characters; the data agent's own instructions at 15,000 (Learn, 2026-10-06). No limit is documented for data-source instructions.
- **Consumption surface** — data agent instructions apply only in the agent chat; semantic model instructions apply everywhere Copilot uses the model (reports, Q&A, Copilot chat).

## Where each layer lands in a Git-synced repo

Verified 2026-08-31 against real `.DataAgent` exports (`microsoft/unified-data-foundation-with-fabric-solution-accelerator`, `Azure-Samples/agentic-app-with-fabric`) and the [source-control doc](https://learn.microsoft.com/fabric/data-science/data-agent-source-control). The item folder serializes as `<display name>.DataAgent` — `metadata.type` is `DataAgent`, **not** the legacy `AISkill` the portal still uses in its `/aiskills/` URL:

```text
<name>.DataAgent/
├── .platform                                     metadata.type = "DataAgent"
└── Files/Config/
    ├── data_agent.json                           $schema only
    ├── publish_info.json                         publishing description
    ├── draft/                                    what you are editing
    │   ├── stage_config.json                     layer 1 — aiInstructions
    │   └── <prefix>-<source name>/
    │       ├── datasource.json                   layers 2 + 3 — dataSourceInstructions,
    │       │                                     displayName, elements (schema map)
    │       └── fewshots.json                     layer 4 — id / question / query
    └── published/                                mirrors draft/; written by Publish
```

Consequences worth knowing before you diff or edit one of these:

- **The four configuration layers are four files**, so a PR review can read a
  changed instruction directly. `stage_config.json` is the agent instructions;
  everything per-source lives under the data source folder.
- **Data source folder names are prefixed by source type** —
  `lakehouse-tables-`, `warehouse-tables-`, `semantic-model-`, `kusto-`,
  `ontology-`, `sql-database-` — followed by the source's display name.
  Renaming a source renames its folder.
- **Never hand-edit `published/`.** It is regenerated from `draft/` on Publish;
  edits there are lost and make the two stages disagree in the meantime.
- **`elements` in `datasource.json` is the schema selection**, table and column
  entries each carrying `is_selected`. Column-level selection is not honoured:
  if a table is selected all its columns are included, and if it is not, none
  are — regardless of the column flags. Review table flags, ignore column ones.
- A semantic model source has **no** `fewshots.json`; it does not support
  example queries.

## Settings and publish, by REST

The agent instructions and the runtime of each stage can be read and set
without the portal, under
`https://api.fabric.microsoft.com/v1/workspaces/{ws}/dataAgents/{id}/`
with a Fabric token. Measured in one client estate on 2026-10-15, six
publishes each read back from both stages:

| Call | Does |
| --- | --- |
| `GET staging/settings` | returns the draft's `{aiInstructions, experimental}` |
| `GET settings` | returns the published agent's, in the same shape |
| `PATCH staging/settings` | takes `{"aiInstructions": …}` or `{"experimental": {…}}`, and keeps whatever it is not sent |
| `POST staging/publish` | takes `{"publishedDescription": …}` and publishes the draft |

Of the four, Learn's REST reference documents only the publish, as
*Publish Data Agent*, in preview (read 2026-10-16).
The SDK's `get_settings`, `update_settings(ai_instructions,
experimental)` and `publish_staging(description)` call these four
(0.1.33a0 source, read 2026-10-16).

**`experimental.enableExperimentalFeatures` is the runtime**: `true` is
the preview runtime. Set `false`, it is the standard runtime, and both
GETs then **omit the key**, `experimental` holding
`{"codeInterpreterEnabled": true}` alone. Read a missing key as false: a
check written `is False` misread the standard runtime. Whether the PATCH
merges inside `experimental` or replaces it whole is unmeasured, so a
switch sends back the `experimental` it read, one key changed.

**A switch reaches consumers only on the next publish.** The published
agent keeps the runtime it was published with, as Learn's data agent
runtime page says (read 2026-10-16), and Git shows the item modified
until someone commits it from the workspace: each stage's
`stage_config.json` carries `experimental`.

Learn's runtime page switches with
`update_configuration(enable_preview_features=True)`. The 0.1.33a0
source marks `update_configuration` deprecated, a legacy workload-host
call that emits a `FutureWarning` naming `update_settings()`, and names
its parameter `enable_preview_runtime`, renamed from
`enable_experimental_features` in 0.1.24a0: Learn's keyword is neither.
Use `update_settings` or the PATCH (source read 2026-10-16, not run).
