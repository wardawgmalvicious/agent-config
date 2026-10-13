# `fabric-tmdl` — behaviour cases

`fabric-tmdl` took in `fabric-semantic-model-ai-instructions` and
`fabric-tmdl-api` on 2026-10-12, as `references/ai-instructions.md` and
`references/definition-api.md`, since neither glob ever fired without
its own. It keeps `**/*.SemanticModel/**`, so it is listed only once a
model file is read; its activation contract is the semantic-model rows
of [`../pbip-triggers/`](../pbip-triggers/expected_activations.md).
These two cases test that a model Read reaches each reference and that
the answer keeps what the old skill carried.

## The cases

| Case | Passes when |
| --- | --- |
| `ai` | after the culture-file Read, `fabric-tmdl` is invoked and reads `ai-instructions.md`; the answer keeps the 10,000-character cap, and the service refresh a Git or deployment-pipeline change needs, once a day on Direct Lake |
| `api` | after the `model.tmdl` Read, it reads `definition-api.md`; the answer keeps that `updateDefinition` sends every part, and that the Fabric API serves definitions and the Power BI API refresh |

The prompts, verbatim:

```text
ai: Read SampleModel.SemanticModel/definition/cultures/en-US.tmdl. I want Copilot to answer questions about this semantic model better, so write the AI instructions for the model. Tell me where they go, how long they can be, and how a change to them reaches production: the model is Git-synced in Fabric and promoted to test and prod through a deployment pipeline, and it runs in Direct Lake.

api: Read SampleModel.SemanticModel/definition/model.tmdl. I changed the 'Total Sales' measure in this file and want to push the change to the published model in our Fabric workspace from a script, through the REST API rather than Git sync, then refresh the model. Give me the exact calls, start to finish.
```

Both read the pbip set's
[`SampleModel.SemanticModel`](../pbip-triggers/fixtures/SampleModel.SemanticModel/).

## Running them

Build a probe outside this repo, since `.claude/settings.json` here
collapses every platform description to `name-only`:

- `payload/.claude/skills/`: a copy of every folder in `skills/powerbi/`
  and the Fabric groups, `skills/fabric-*/`, one `skills/fabric/` holding
  this skill too when this ran.
- `baseline/`: no `.claude/`, run with `--safe-mode`.
- `SampleModel.SemanticModel/` at each arm's root.

Run each case in each arm from that arm's directory, with
`CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1`, as
[`../fabric-deploy/README.md`](../fabric-deploy/README.md) does and for
its reasons:

```powershell
claude -p '<prompt>' --output-format stream-json --verbose --tools Skill,Read --strict-mcp-config --model claude-opus-5-5 --effort xhigh --max-budget-usd 3
```

Add `--safe-mode` on the baseline. There is no slash arm: the skill is
conditional, and the fold changed no `model:` pin.

Read the `init` record for `tools` (2 on every arm) and
`slash_commands`, which must drop on the baseline and lose every Fabric
skill; the `commands_changed` record after the fixture Read, which
witnesses the activation; then the `Skill` and `Read` calls, and the
first `result`.

## Result, 2026-10-12

Both cases pass. One run per arm, on 2.1.293, Opus 5.5 at `xhigh`,
against the fold's second commit, which the arms read as `729e0ab` in
the brief's worktree before its rebase:

| Case | Payload | Baseline |
| --- | --- | --- |
| `ai` | pass: the culture Read, `Skill` `fabric-tmdl`, then `ai-instructions.md`; 10,000 characters with 8,000 as the target; a refresh in each stage after a Git or pipeline change, and Direct Lake picking it up only once a day | partial: 10,000 characters unaided; "instructions are metadata, so they don't need a data refresh", the claim the skill corrects |
| `api` | pass: `fabric-rest-api` then `fabric-tmdl` invoked, `definition-api.md` read; every part sent, `.platform` left out, Fabric tokens for the definition and Power BI tokens for the refresh | pass, unaided: the replace-everything rule, `.platform` left out, and the two audiences |

`init` gave `tools` 2 on every arm, and `slash_commands` 80 on the
payload, nine unconditional Fabric skills among them and `fabric-tmdl`
absent, against 58 on the baseline, with none. On each payload arm a
`commands_changed` record followed the model Read, before any `Skill`
call.

`api` does not separate: the base model knows the definition rules
this reference carries, so that case witnesses routing only. `ai`
separates on the refresh.

**Seen in the run**, neither fixed here:

- `ai` repeated the reference's "not stored in TMDL" and said it could
  not name the file. The culture file holds the instructions in a
  Git-synced model, observed 2026-10-07; correcting that line is
  [`semantic-model-ai-instructions-storage.md`](../../../docs/handoffs/execute/semantic-model-ai-instructions-storage.md)'s
  work. The baseline guessed a `Copilot/` folder beside `definition/`,
  the other shape that brief holds open.
- `api` flagged that `fabric-rest-api` gives
  `PATCH /v1/workspaces/{wsId}/items/{itemId}/definition`. Learn's
  Update Item Definition is
  `POST /v1/workspaces/{workspaceId}/items/{itemId}/updateDefinition`
  (read 2026-10-12), so that skill's line was wrong: fixed the same day.

**Activation**: `test-activation.ps1 -Set pbip` on the same commit read
16 of 16 fixtures and matched every activation delta, skills and rules.

**Listing**: on a model file the listing now carries `fabric-tmdl`'s
621 description characters, against 1,148 for it and `fabric-tmdl-api`
before the fold; on a culture file, against 1,825 with the
AI-instructions skill too.

**Cost**: payload arms $1.90, baseline arms $0.66.

**What the run cannot show**: variance, with one run per arm; how the
two old skills would have answered, since no arm held them; and the
client repos' listing, which runs to its cap, while this probe lists
the Fabric group alone.

## Not yet measured

Use in client work. After a few weeks of client sessions, run
`uv run --with pyyaml python scripts/skill-telemetry.py triggers`: does
a semantic-model session that touches AI instructions or the Definition
API invoke `fabric-tmdl` and read the reference? Neither old skill was
invoked in client sessions from 2026-09-24 to 2026-10-08. Discount this
run's two payload sessions, each of which reached `fabric-tmdl`.
