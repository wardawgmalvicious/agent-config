---
name: fabric-ai-functions
description: "Use for Microsoft Fabric AI Functions (Data Science) — one-line LLM transformations on pandas and PySpark DataFrames in Fabric notebooks: `ai.analyze_sentiment`, `ai.classify`, `ai.extract`, `ai.embed`, `ai.summarize`, `ai.translate`, `ai.fix_grammar`, `ai.generate_response`, `ai.similarity`. Covers the two import paths (`synapse.ml.aifunc` pandas single-node vs `synapse.ml.spark.aifunc` PySpark distributed), pandas Series-accessor vs PySpark `df.ai` DataFrame-accessor shapes, GA defaults (`gpt-5-mini` + `reasoning_effort=low`, `openai` no longer required), pandas `aifunc.Conf` vs PySpark `OpenAIDefaults` config (concurrency, temperature/top_p/verbosity/seed), `gpt-5.1` opt-in and gpt-4.1→gpt-5.1 migration, custom Azure OpenAI/Foundry endpoints, `ExtractLabel` schema extract, PySpark chaining, `ai.stats` + Exception/Filter/CapacityExceeded results, multimodal `column_type=path`, prerequisites (F2+, Runtime 1.3+, Copilot tenant switch), and Copilot-&-AI billing. Also in SQL/Warehouse and Dataflow Gen2."
---

# Fabric AI Functions

One-line, LLM-powered transformations applied to whole pandas or PySpark DataFrames in Fabric notebooks. Fabric handles the model endpoint, auth, request orchestration, batching, and retries — you call a DataFrame method and get an enriched column back. Nine prebuilt functions cover sentiment, classification, extraction, embeddings, grammar, custom prompts, similarity, summarization, and translation.

## When to use vs not

Use AI Functions to enrich, classify, extract, summarize, translate, or embed **tabular data at scale** — thousands to millions of rows — with minimal code, letting Fabric manage concurrency (200 rows in parallel by default) and the built-in endpoint. This is the fastest path to apply an LLM across a column.

Skip them when you need **low-level control** over a single prompt/response, custom orchestration, function-calling loops, or a conversational agent — use the [Azure OpenAI Python SDK](https://learn.microsoft.com/fabric/data-science/ai-services/how-to-use-openai-python-sdk) or [SynapseML](https://learn.microsoft.com/fabric/data-science/ai-services/how-to-use-openai-synapse-ml) instead. For a governed natural-language-to-data experience over your semantic models/lakehouses, that's a Data Agent (`fabric-data-agent`), not AI Functions.

## Prerequisites

- **Paid capacity** — F2 or higher, or any P edition. Not available on trial/Free.
- **Fabric Runtime 1.3+** — earlier runtimes can't run AI Functions.
- **Tenant switch** — an admin must enable *Copilot and other features powered by Azure OpenAI*. Depending on region you may also need the **cross-geo processing** tenant setting (the built-in endpoint isn't in every region).
- Prompts, input data, and outputs are **not logged or stored** by AI Functions.

## Setup — imports differ by engine

The single most common mistake is the import path. It is **not** the same for the two engines, and the API shapes differ too (see next section).

| Engine | Import | Runs |
|---|---|---|
| pandas | `import synapse.ml.aifunc as aifunc` | single node (driver) |
| PySpark | `import synapse.ml.spark.aifunc as aifunc` | distributed across the Spark cluster |

```python
# pandas
import synapse.ml.aifunc as aifunc
import pandas as pd

# PySpark  (SparkSession `spark` is pre-provisioned)
import synapse.ml.spark.aifunc as aifunc
```

Choose **PySpark for large-scale** datasets (work distributes across workers); pandas runs on a single node and is fine for smaller frames or ad-hoc work.

### Dependencies

| Runtime | What to install |
|---|---|
| pandas on the **Python** runtime | `synapseml_internal` + `synapseml_core` wheels (`https://aka.ms/fabric-aifunctions-whl`, `https://aka.ms/fabric-synapseml-core-whl`) |
| pandas on the **PySpark** runtime | nothing for most usage |
| PySpark on the **PySpark** runtime | nothing |

As of GA, the **`openai` package is no longer a required dependency** — install `openai>=1.99.5` *only* if you need SDK-native client behavior or Pydantic `response_format` examples. Keep it out of the install to stay lightweight.

## The nine functions

| Function | Does | pandas (Series accessor) | PySpark (`df.ai`, keyword args) |
|---|---|---|---|
| `ai.analyze_sentiment` | positive/negative/mixed/neutral (or custom labels) | `df["c"].ai.analyze_sentiment()` | `df.ai.analyze_sentiment(input_col="c", output_col="s")` |
| `ai.classify` | categorize into your labels | `df["c"].ai.classify("a","b","other")` | `df.ai.classify(labels=["a","b"], input_col="c", output_col="cat")` |
| `ai.embed` | vector embeddings | `df["c"].ai.embed()` | `df.ai.embed(input_col="c", output_col="e")` |
| `ai.extract` | pull fields/entities into new columns | `df["c"].ai.extract("name","city")` | `df.ai.extract(labels=["name","city"], input_col="c")` |
| `ai.fix_grammar` | correct spelling/grammar/punctuation | `df["c"].ai.fix_grammar()` | `df.ai.fix_grammar(input_col="c", output_col="fixed")` |
| `ai.generate_response` | custom prompt over row data | `df.ai.generate_response("<prompt>")` | `df.ai.generate_response(prompt="…", output_col="r")` |
| `ai.similarity` | semantic similarity, -1…1 | `df["a"].ai.similarity(df["b"])` | `df.ai.similarity(input_col="a", other_col="b", output_col="sim")` |
| `ai.summarize` | summarize text/columns/row/files | `df["c"].ai.summarize()` | `df.ai.summarize(input_col="c", output_col="sum")` |
| `ai.translate` | translate to a language | `df["c"].ai.translate("spanish")` | `df.ai.translate(to_lang="spanish", input_col="c", output_col="t")` |

### API-shape gotcha (pandas vs PySpark)

They look similar but aren't interchangeable:

- **pandas** attaches `.ai` to a **Series** and returns a **Series** you assign back (`df["out"] = df["in"].ai.classify(...)`). `ai.extract` returns a **new DataFrame** of the extracted columns.
- **PySpark** attaches `.ai` to the **DataFrame**, takes `input_col`/`output_col` keyword args, and returns a **new DataFrame** with the output column appended.

```python
# pandas — Series in, Series out
df["sentiment"] = df["reviews"].ai.analyze_sentiment()

# PySpark — DataFrame in, DataFrame out
result = df.ai.analyze_sentiment(input_col="reviews", output_col="sentiment")
```

### Structured extraction & responses

- `ai.extract` accepts `ExtractLabel` for **typed, schema-driven** output — JSON Schema with typed fields, enums, arrays, nested objects, nullable/required properties, and `additionalProperties=false`. You can author a Pydantic model and convert it to JSON Schema.
- `ai.generate_response` accepts `response_format` for structured output (JSON object, JSON Schema, or Pydantic model).

### Chaining (PySpark)

PySpark results keep the `df.ai` accessor bound to the new schema, so transformations chain without materializing intermediates:

```python
output = (df
    .ai.summarize(input_col="review_text", output_col="summary")
    .ai.classify(labels=["service","cleanliness","location","other"],
                 input_col="summary", output_col="category"))
```

## Configuration

Defaults: model **`gpt-5-mini`**, **`reasoning_effort="low"`**, `temperature` unset (GPT-5-series accepts only the model default — setting it is ignored), embeddings via `text-embedding-ada-002`, concurrency **200**. This changed at GA — pandas/PySpark Python functions previously defaulted to the GPT-4 series.

The config **objects differ by engine** — don't copy pandas config into a PySpark notebook:

**pandas** — set attributes on `aifunc.Conf` / `aifunc.default_conf`, or pass a per-call `conf=`:

```python
aifunc.default_conf.model_deployment_name = "gpt-5.1"
aifunc.default_conf.reasoning_effort = "medium"      # minimal|low|medium|high
aifunc.default_conf.verbosity = "low"                # low|medium|high
aifunc.default_conf.progress_bar_mode = "stats"      # basic|stats|disable
```

**PySpark** — use `OpenAIDefaults` via `set_*` / `get_*` / `reset_*`; per-call params are **camelCase without the `set_` prefix**:

```python
aifunc.default_conf.set_deployment_name("gpt-5.1")
aifunc.default_conf.set_reasoning_effort("medium")
# per-call override:
df.ai.translate(to_lang="spanish", input_col="text", output_col="out",
                deploymentName="gpt-5.1", concurrency=200)
```

Key params (full table in [references/REFERENCE.md](references/REFERENCE.md)): `deployment_name`/`model_deployment_name`, `reasoning_effort`, `verbosity`, `seed` (pandas — reproducibility), `temperature`, `top_p`, `timeout` (pandas), `concurrency` (PySpark: per-call only, per worker, up to 1000), `api_type` (PySpark: `responses` default, set `chat_completions` for non-OpenAI Foundry models), `embedding_deployment_name`, `URL` + `subscription_key` (custom endpoints).

### Model migration

The **GPT-4.1 series is being retired.** If you pinned pipelines:

| Pinned to | Migrate to |
|---|---|
| `gpt-4.1` | `gpt-5.1` |
| `gpt-4.1-mini` | `gpt-5-mini` (the new default) |

For higher-quality/complex transformations, opt into `gpt-5.1` and/or raise `reasoning_effort`. AI Functions in Warehouse/SQL and Dataflow Gen2 receive the same model upgrade by end of June 2026.

### Custom Azure OpenAI / Foundry endpoints

Point at your own resource with `set_URL` + `set_subscription_key` (PySpark) or the pandas equivalents. Foundry (non-OpenAI) models — Qwen, Grok, Llama, Mistral, Kimi — require `api_type="chat_completions"` and must support `response_format` with JSON schema. **`ai.embed` and `ai.similarity` are not supported on Foundry resources** (embeddings need the OpenAI-compatible endpoint). Reset to the built-in endpoint with `reset_URL()` / `reset_subscription_key()`.

## Usage stats & error handling

`ai.stats` reports per-run metrics — pandas: on the returned Series/DataFrame; PySpark: `df.ai.stats` on the result. Fields include `num_successful`, `num_exceptions`, `num_unevaluated`, `num_harmful`, `cached_tokens`, `input_tokens`, `output_tokens`, `reasoning_tokens`, `model`.

Non-successful rows surface as **typed sentinels**, not silent nulls:

| Sentinel | Meaning |
|---|---|
| `aifunc.ExceptionResult` | row raised an exception |
| `aifunc.NotEvaluatedResult` | skipped because an earlier exception halted evaluation |
| `aifunc.FilterResult` | blocked by the Azure OpenAI content filter |
| `aifunc.CapacityExceededResult` | hit a capacity limit — retry after capacity frees up |

In pandas, `aifunc.split_results` separates successful outputs from non-results so you can inspect and retry the failures. During execution, `progress_bar_mode="stats"` shows live token counts and CU-hour estimates.

## Multimodal input

Most functions accept file paths (images, PDFs, text) instead of literal text: `column_type="path"` in pandas, or `input_col_type`/`col_types="path"` in PySpark. Supported: JPG/PNG/GIF/WebP, PDF, MD/TXT/CSV/TSV/JSON/XML/PY. Helpers: `aifunc.load` (ingest a folder to a table), `aifunc.list_file_paths` (enumerate URLs/paths), `ai.infer_schema` (derive an extraction schema from file contents for `ai.extract`).

## Billing

AI Functions bill against the **Copilot and AI** meter on your capacity — **separate from the Spark meter** that covers the notebook/cluster compute. A PySpark `ai.classify` over millions of rows therefore shows up as two line items: notebook compute (Spark meter) + model token usage (AI Functions on the Copilot-&-AI meter). From 2026-03-17 the Capacity Metrics app reports **AI Functions** and **AI Services** as separate operations (reporting change only; rates unchanged). See `fabric-monitoring` for the metrics app.

## Gotchas

| Symptom | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError` / `.ai` accessor missing | wrong import for the engine | pandas → `synapse.ml.aifunc`; PySpark → `synapse.ml.spark.aifunc` |
| pandas config keys rejected in PySpark (or vice-versa) | different config objects | pandas: `aifunc.Conf`/`default_conf` attrs; PySpark: `OpenAIDefaults` `set_*` |
| `temperature` has no effect | GPT-5-series accepts only the model default | omit it; steer with `reasoning_effort` / `verbosity` instead |
| per-call PySpark param ignored | wrong casing | per-call args are camelCase w/o `set_` (`deploymentName`, not `set_deployment_name`) |
| `ai.embed`/`ai.similarity` fail on a custom endpoint | Foundry resource | embeddings need the OpenAI-compatible endpoint; keep the built-in for embed/similarity |
| results are `ExceptionResult`/`CapacityExceededResult` objects | per-row failure / capacity limit | check `ai.stats`; use `aifunc.split_results` (pandas) and retry |
| function errors on trial capacity | needs F2+/P | move to a paid capacity |
| pipeline broke after model upgrade | pinned to retiring `gpt-4.1*` | migrate `gpt-4.1`→`gpt-5.1`, `gpt-4.1-mini`→`gpt-5-mini` |
| unexpectedly high AI cost | model token usage on Copilot-&-AI meter, not Spark | monitor the AI Functions op in Capacity Metrics; lower `reasoning_effort`, batch fewer rows |

## Other surfaces (brief)

Same capability, different engines — not covered in depth here:

- **Warehouse / SQL analytics endpoint** — T-SQL functions `ai_summarize`, `ai_classify`, `ai_generate_response` (see `fabric-warehouse`).
- **Dataflow Gen2** — the *AI Prompt* transform adds AI-generated columns in Power Query.

## Reference

- Microsoft Learn: [AI Functions: Transform data at scale with AI (overview)](https://learn.microsoft.com/fabric/data-science/ai-functions/overview)
- Microsoft Learn: [Customize AI Functions with pandas](https://learn.microsoft.com/fabric/data-science/ai-functions/pandas/configuration) · [with PySpark](https://learn.microsoft.com/fabric/data-science/ai-functions/pyspark/configuration)
- Microsoft Learn: [Billing for AI Functions](https://learn.microsoft.com/fabric/data-science/ai-functions/billing)
- Starter notebooks: `https://aka.ms/fabric-aifunctions-starter-notebooks` · Eval notebooks: `https://aka.ms/fabric-aifunctions-eval-notebooks`
- Full config-parameter tables, multimodal helpers, and the complete MS Learn link bundle: [references/REFERENCE.md](references/REFERENCE.md)

## See also

- `fabric-spark` — the broader PySpark-in-Fabric surface; AI Functions are one consumer of it
- `fabric-data-agent` — governed NL-to-data over semantic models/lakehouses (different tool, different job)
- `fabric-warehouse` — the T-SQL `ai_*` scalar functions
- `fabric-monitoring` — Capacity Metrics app and the Copilot-&-AI meter
- `coding-python` rule — conventions for the pandas/PySpark you'll write around these calls
