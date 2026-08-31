# MS Learn link bundle — Fabric error handling

Curated set of Microsoft Learn pages relevant to error handling in Fabric notebooks and pipeline orchestration. The convention this skill encodes (Tier 1 hard-fail / Tier 2 soft-fail with `results = {succeeded, skipped, failed}`) is in-house — these MS Learn links cover the *primitives* the convention is built on: `notebookutils.notebook.exit()`, `runMultiple()` DAG with retries, pipeline error paths, the Fail activity, and the Job Scheduler exit-value retrieval pattern.

The 3 highest-leverage entry points (NotebookUtils notebook run/orchestration, pipeline errors and conditional execution, Fabric notebooks troubleshooting) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

## Notebook-level error mechanics

- [NotebookUtils notebook run and orchestration](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-notebook-run) — the canonical reference for `run()`, `runMultiple()`, `exit()`, `validateDAG()`. Critical rules called out: don't call `exit()` inside try/except (the call won't propagate); exit values are always strings; child notebooks must share the parent's lakehouse unless `useRootDefaultLakehouse: True`.
- [NotebookUtils (former MSSparkUtils) for Fabric — overview](https://learn.microsoft.com/fabric/data-engineering/notebook-utilities) — module index; `notebookutils.fs.help()` / `.notebook.help()` / `.credentials.help()`.
- [Microsoft Spark Utilities (MSSparkUtils) for Fabric](https://learn.microsoft.com/fabric/data-engineering/microsoft-spark-utilities) — older `mssparkutils` namespace (still works); same `exit()` semantics, useful background on REPL-per-notebook resource model that informs the Tier 2 concurrency considerations.
- [Manage and execute notebooks in Fabric with APIs (exit values from notebook runs)](https://learn.microsoft.com/fabric/data-engineering/notebook-public-api#exit-values-from-notebook-runs) — the `exitValue` field returned by Get-Item-Job-Instance. How an external orchestrator reads the success/failure signal a Tier 2 summary emits.
- [Fabric notebooks troubleshooting guide](https://learn.microsoft.com/fabric/data-science/fabric-notebooks-troubleshooting-guide) — common notebook errors (timeouts, session connectivity, Copilot Fix). Useful for understanding the runtime environment errors the Tier 1 hard-fail path will surface.

## DAG-style parallel runs (`runMultiple`)

- [`runMultiple()` failure handling](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-notebook-run#reference-run-multiple-notebooks-in-parallel) — the `RunMultipleFailedException`, the `{exitVal, exception}` result-dictionary shape per activity, the `retry` and `retryIntervalInSeconds` fields. This is the framework-level analog to the in-house `results = {succeeded, skipped, failed}` shape.
- [DAG parameter reference](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-notebook-run#dag-parameter-reference) — full per-activity field list (timeout, args, workspace, retry, dependencies). Use when the Tier 2 "for-loop with try/except" pattern outgrows a single notebook.
- [`@activity('name').exitValue()` expression](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-notebook-run#reference-exit-values-between-activities) — passing data between DAG activities via exit values.

## Pipeline-level error handling (Data Factory)

- [Errors and Conditional execution (canonical patterns)](https://learn.microsoft.com/azure/data-factory/tutorial-pipeline-failure-error-handling) — Try-Catch / Do-If-Else / Do-If-Skip-Else patterns + the four conditional paths (Upon Success, Upon Failure, Upon Completion, Upon Skip) and how they determine pipeline success. Authored for ADF but applies to Fabric Data Factory pipelines unchanged.
- [Fabric Fail activity](https://learn.microsoft.com/fabric/data-factory/fail-activity) — intentionally fail the pipeline with custom message + error code. The pipeline-level analog to `raise RuntimeError(...)` from the STRICT-mode Tier 2 epilogue.
- [Pipeline overview — best practices](https://learn.microsoft.com/fabric/data-factory/pipeline-overview#best-practices) — the "handle errors / plan for failures with retry logic and alternative processing paths" guidance Fabric officially recommends.
- [Troubleshoot pipelines for Data Factory in Fabric](https://learn.microsoft.com/fabric/data-factory/pipeline-troubleshoot-guide) — common pipeline error symptoms + causes (parameter-size limits, format/compression mismatches).
- [Debug pipelines in Microsoft Fabric (deactivate activity, iterative workflow)](https://learn.microsoft.com/fabric/data-factory/how-to-debug-pipelines-in-microsoft-fabric) — the "deactivate downstream activities, validate, reactivate" pattern useful when isolating a Tier-2 failure cause.

## Spark-side exception classes (for typed `except` clauses)

- [PySpark exceptions module (`pyspark.errors`)](https://learn.microsoft.com/azure/databricks/dev-tools/pyspark/api/pyspark.errors) — the `AnalysisException`, `IllegalArgumentException`, `ParseException`, `PySparkValueError` hierarchy. When the Tier 2 catch needs to be more specific than bare `except Exception`.
- [Delta Lake — concurrent write exceptions](https://learn.microsoft.com/azure/databricks/delta/concurrency-control) — `ConcurrentAppendException` / `ConcurrentDeleteReadException` / `ConcurrentDeleteDeleteException` / `ConcurrentTransactionException` and `MetadataChangedException`. Snapshot-conflict (24556 / 24706 in Warehouse) is the Spark-side equivalent — relevant when retry-with-backoff is the right Tier 2 response.

## Workspace monitoring (after the fact)

- [What is workspace monitoring (preview)?](https://learn.microsoft.com/fabric/fundamentals/workspace-monitoring-overview) — Eventhouse-backed cross-item logs.
- [Monitor Fabric items with item job event logs](https://learn.microsoft.com/fabric/fundamentals/item-job-event-logs) — `ItemJobEventLogs` table; the post-hoc place to see which Tier 1/Tier 2 runs failed across the workspace.

## See also (this repo)

- The Tier 1 / Tier 2 convention itself is documented in the parent SKILL.md and is *not* upstream MS Learn content — these references cover the platform primitives the convention rests on.
