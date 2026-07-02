# Fabric AI Functions — Reference

Deep reference for `fabric-ai-functions`. Read the SKILL.md first; come here for the full
config-parameter tables, multimodal helpers, and the MS Learn link bundle.

## Contents

- [pandas configuration parameters](#pandas-configuration-parameters)
- [PySpark configuration parameters](#pyspark-configuration-parameters)
- [Progress bar modes (pandas)](#progress-bar-modes-pandas)
- [Multimodal helpers](#multimodal-helpers)
- [ai.stats fields](#aistats-fields)
- [Custom endpoint recipes](#custom-endpoint-recipes)
- [MS Learn link bundle](#ms-learn-link-bundle)

## pandas configuration parameters

Set on `aifunc.Conf` / `aifunc.default_conf` (global for the session) or pass a per-call `conf=`.

| Parameter | Description | Default |
|---|---|---|
| `model_deployment_name` | Chat model deployment powering the functions | `gpt-5-mini` |
| `reasoning_effort` | GPT-5-series reasoning budget: `aifunc.NOT_GIVEN` or `minimal`/`low`/`medium`/`high` | `low` |
| `seed` | Fix the model seed for reproducible runs (default picks a random seed per row) | `aifunc.NOT_GIVEN` |
| `temperature` | 0.0–1.0 randomness. **GPT-5-series supports only the model default** — setting it is ignored | `aifunc.NOT_GIVEN` |
| `top_p` | 0–1 nucleus sampling; lower = more deterministic | `aifunc.NOT_GIVEN` |
| `timeout` | Seconds before a function raises a timeout; default no timeout | `None` |
| `verbosity` | GPT-5-series output length: `aifunc.NOT_GIVEN` or `low`/`medium`/`high` | `aifunc.NOT_GIVEN` |
| `progress_bar_mode` | `basic` / `stats` / `disable` (replaces deprecated `use_progress_bar`) | `basic` |
| `concurrency` | Max rows processed in parallel; raise if capacity allows | `200` |

Override globally vs per-call:

```python
# global for all calls this session
aifunc.default_conf.model_deployment_name = "gpt-5.1"
aifunc.default_conf.verbosity = "low"
aifunc.default_conf.reasoning_effort = "medium"
aifunc.default_conf.temperature = aifunc.NOT_GIVEN
aifunc.default_conf.top_p = aifunc.NOT_GIVEN

# per single call — only ai.translate changes reasoning_effort here
custom = aifunc.Conf(reasoning_effort="high")
df["t"] = df["text"].ai.translate("french", conf=custom)
```

## PySpark configuration parameters

Set via `OpenAIDefaults` methods on `aifunc.default_conf` (`set_*` / `get_*` / `reset_*`). When passed
**per function call**, use camelCase without the `set_` prefix — e.g. `set_deployment_name("gpt-5.1")`
becomes `deploymentName="gpt-5.1"`.

| Parameter | Description | Default | Scope |
|---|---|---|---|
| `api_type` | `responses` (default) or `chat_completions` (for non-OpenAI Foundry models) | `responses` | global + per-call |
| `concurrency` | Max rows in parallel; up to 1000; **per Spark worker**; per-call only | `200` | per-call |
| `deployment_name` | Chat model deployment; can point to Azure OpenAI / Foundry deployment | `gpt-5-mini` | global + per-call |
| `embedding_deployment_name` | Embedding deployment for `ai.embed` / `ai.similarity` | `text-embedding-ada-002` | global |
| `reasoning_effort` | `None` or `minimal`/`low`/`medium`/`high` | `low` | global + per-call |
| `subscription_key` | API key for a custom LLM resource | N/A | global + per-call |
| `temperature` | 0.0–1.0; GPT-5-series supports only model default | `None` | global + per-call |
| `top_p` | 0–1 nucleus sampling | `None` | global + per-call |
| `URL` | Endpoint of a custom LLM resource | N/A | global + per-call |
| `verbosity` | `None` or `low`/`medium`/`high` | `None` | global + per-call |

```python
# configure a reasoning model globally
aifunc.default_conf.set_deployment_name("gpt-5.1")
aifunc.default_conf.set_reasoning_effort("medium")
aifunc.default_conf.set_verbosity("low")

# inspect current values
print(aifunc.default_conf.get_deployment_name())
print(aifunc.default_conf.get_URL())

# reset back to the built-in Fabric endpoint
aifunc.default_conf.reset_deployment_name()
aifunc.default_conf.reset_URL()
aifunc.default_conf.reset_subscription_key()

# per-call concurrency
df.ai.fix_grammar(input_col="text", output_col="corrections", concurrency=200)
```

## Progress bar modes (pandas)

`aifunc.default_conf.progress_bar_mode = "stats"` (or `"basic"` / `"disable"`).

- `basic` (default) — completion %, count, elapsed, speed: `ai.extract: 100%|██████| 1000/1000 [00:10<00:00, 22.1it/s]`
- `stats` — adds live token counts and CU-hour estimate; in-flight values show `->` projections, e.g. `cached=150k->250k, in=800k->1.21M, out=68k->101k, CU-h=3.60->5.33`
- `disable` — no output

For PySpark, use `df.ai.stats` on the result DataFrame instead of a progress bar.

## Multimodal helpers

Set `column_type="path"` (pandas) or `input_col_type` / `col_types="path"` (PySpark) to feed file
paths instead of literal text. Supported types: JPG/JPEG, PNG, static GIF, WebP, PDF, MD, TXT, CSV,
TSV, JSON, XML, PY and other text files.

| Helper | Purpose |
|---|---|
| `aifunc.load` | Ingest files from a folder into a structured table (accepts a prompt or schema) |
| `aifunc.list_file_paths` | Enumerate file URLs/paths from a folder for use as function input |
| `ai.infer_schema` | Infer an extraction schema from file contents for use with `ai.extract` |

See MS Learn: *Use multimodal input with AI Functions*
(`https://learn.microsoft.com/fabric/data-science/ai-functions/multimodal-overview`).

## ai.stats fields

| Field | Meaning |
|---|---|
| `num_successful` | rows processed successfully |
| `num_exceptions` | rows that raised an exception (`aifunc.ExceptionResult`) |
| `num_unevaluated` | rows skipped after an earlier exception (`aifunc.NotEvaluatedResult`) |
| `num_harmful` | rows blocked by the content filter (`aifunc.FilterResult`) |
| `cached_tokens` | cached input tokens |
| `input_tokens` / `output_tokens` | token totals |
| `reasoning_tokens` | reasoning tokens (reasoning models) |
| `model` | deployment name used |

Capacity-limited rows appear as `aifunc.CapacityExceededResult`. In pandas, `aifunc.split_results`
separates successes from non-results for inspection and retry.

## Custom endpoint recipes

Azure OpenAI resource:

```python
aifunc.default_conf.set_URL("https://<resource>.openai.azure.com/")
aifunc.default_conf.set_subscription_key("<API_KEY>")
```

Foundry (non-OpenAI) model — must support Chat Completions + `response_format` JSON schema; embeddings
(`ai.embed`, `ai.similarity`) are **not** supported here:

```python
aifunc.default_conf.set_URL("https://<resource>.services.ai.azure.com")
aifunc.default_conf.set_subscription_key("<API_KEY>")
aifunc.default_conf.set_deployment_name("grok-4-fast-non-reasoning")
aifunc.default_conf.set_api_type("chat_completions")   # required for non-OpenAI
```

## MS Learn link bundle

- Overview — AI Functions: Transform data at scale with AI: https://learn.microsoft.com/fabric/data-science/ai-functions/overview
- Customize with pandas: https://learn.microsoft.com/fabric/data-science/ai-functions/pandas/configuration
- Customize with PySpark: https://learn.microsoft.com/fabric/data-science/ai-functions/pyspark/configuration
- Billing for AI Functions: https://learn.microsoft.com/fabric/data-science/ai-functions/billing
- Use multimodal input: https://learn.microsoft.com/fabric/data-science/ai-functions/multimodal-overview
- Use Azure OpenAI in Fabric with AI Functions: https://learn.microsoft.com/fabric/data-science/ai-services/how-to-use-openai-ai-functions
- Foundry Tools in Fabric (billing/consumption context): https://learn.microsoft.com/fabric/data-science/ai-services/ai-services-overview
- Per-function pandas docs: https://learn.microsoft.com/fabric/data-science/ai-functions/pandas/ (analyze-sentiment, classify, embed, extract, fix-grammar, generate-response, similarity, summarize, translate)
- Per-function PySpark docs: https://learn.microsoft.com/fabric/data-science/ai-functions/pyspark/ (same set)
- AI Functions in Warehouse/SQL (`ai_*` T-SQL): https://learn.microsoft.com/fabric/data-warehouse/ai-functions
- AI Prompt in Dataflow Gen2: https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-ai-functions
- Fabric Runtime 1.3: https://learn.microsoft.com/fabric/data-engineering/runtime-1-3
- Starter notebooks: https://aka.ms/fabric-aifunctions-starter-notebooks
- Eval notebooks: https://aka.ms/fabric-aifunctions-eval-notebooks
