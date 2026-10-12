# Error handling convention (Fabric notebooks)

Two tiers. Pick the right one per block of code; don't mix them inside a single logical operation.

## Tier 1 — Setup / preconditions (hard fail)

Raise immediately. No try/except wrapping, no "best effort" semantics. Applies to:

- Auth: token acquisition, Key Vault secret fetches, connection-string pulls
- Required-config validation: missing required variables, unset placeholders that would produce invalid requests
- Target resolution where the target is a single item: resolve a workspace ID, resolve an item ID, lookup the Variable Library GUID

Tier 1 functions surface the cause in the exception message (HTTP status, what was missing, what was searched). They never swallow errors to keep the notebook running — if a precondition fails, subsequent cells will produce misleading output or worse, silent data corruption.

## Tier 2 — Bulk operations (soft fail)

Track per-item results, continue the loop, print a summary at the end. Applies to:

- Per-table maintenance (OPTIMIZE, VACUUM, TBLPROPERTIES alterations)
- Per-item enumeration (list all items, extract GUIDs, update a set of value sets)
- Per-workspace iteration

Canonical result shape — use this exact structure in every Tier 2 notebook:

```python
results = {
    "succeeded": [],   # list[str] of item names
    "skipped":   [],   # list[dict]: {"name": str, "reason": str}
    "failed":    [],   # list[dict]: {"name": str, "error": str}
}
```

Append into `succeeded` / `skipped` / `failed` inside the loop, never halt the loop on a single failure, then print a summary block at the end:

```
── Summary ───────────────────────────────────
  Succeeded: 47
  Skipped:    2
  Failed:     1
    - `dbo`.`TransactionLine`: snapshot conflict (24556) — retry
```

## STRICT flag

Every Tier 2 notebook exposes a top-level boolean in its config cell:

```python
# False (default) — print the summary and continue even if some items failed.
#                   Right for a notebook on its own schedule: one bad item shouldn't
#                   stop the rest of the work, and the per-item report is enough signal.
# True  — raise RuntimeError after the summary when any item failed. Use from a
#         pipeline, CI or other orchestration, where the run's status must reflect state.
STRICT = False
```

After the summary, `if STRICT and results["failed"]: raise RuntimeError(...)`. The default is `False` — best-effort with a clear report is what most maintenance runs want.

**A notebook a pipeline runs takes `STRICT = True`**, a nightly maintenance run included (decided 2026-10-12). The pipeline sees the notebook's outcome, not its summary, so with `False` a run whose items failed ends as a success and no failure path fires. `True` loses no coverage: the raise comes after the loop has reached every item.

## Boundaries

- A Tier 2 loop's body can call Tier 1 helpers; the try/except inside the loop catches their exceptions and routes them into `failed`.
- Do NOT wrap Tier 1 calls in try/except at the notebook level "just in case". That masks real problems and produces output that looks like success.
- Do NOT convert Tier 1 to print-based warnings for readability. Raise loudly; the summary shape is only for bulk work.

## Per-item metrics (when the canonical shape isn't enough)

Keep a parallel `per_table = []` (or `per_item = []`) list for metrics that don't fit in `{"name": str}`. Example: OPTIMIZE reports files added/removed per table. Canonical `results` still drives succeeded/skipped/failed counts; the metrics table is extra detail in the summary.

## Anti-patterns to avoid

- `print("WARNING: ...")` with no structured tracking — lost in notebook output, no way to aggregate across a large run.
- `failed_tables = []` parallel to `results = []` — duplicate bookkeeping, easy to drift out of sync. Use the canonical shape and a single source of truth.
- `try: ...; except Exception as e: print(e); continue` with no `results` entry — the loop keeps going but the failure disappears. Always append to `results["failed"]`.
- Ignoring `STRICT` for "just this one notebook" — the flag should exist everywhere Tier 2 applies, even when it's always left at `False`, because CI callers need a predictable switch.

## Reference

- Microsoft Learn: [NotebookUtils notebook run and orchestration](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-notebook-run) — `exit()`, `runMultiple()`, the don't-wrap-`exit()`-in-try/except rule
- Microsoft Learn: [Errors and Conditional execution (pipeline patterns)](https://learn.microsoft.com/azure/data-factory/tutorial-pipeline-failure-error-handling) — Try-Catch / Do-If-Else / Do-If-Skip-Else
- Microsoft Learn: [Fabric notebooks troubleshooting guide](https://learn.microsoft.com/fabric/data-science/fabric-notebooks-troubleshooting-guide)
- Comprehensive MS Learn link bundle (notebook exit/runMultiple/DAG / pipeline error paths / Fail activity / Spark exception classes / workspace monitoring): [§ MS Learn link bundle](#ms-learn-link-bundle), below

## MS Learn link bundle

Curated set of Microsoft Learn pages relevant to error handling in Fabric notebooks and pipeline orchestration. The convention this file encodes (Tier 1 hard-fail / Tier 2 soft-fail with `results = {succeeded, skipped, failed}`) is in-house — these MS Learn links cover the *primitives* the convention is built on: `notebookutils.notebook.exit()`, `runMultiple()` DAG with retries, pipeline error paths, the Fail activity, and the Job Scheduler exit-value retrieval pattern.

The 3 highest-leverage entry points (NotebookUtils notebook run/orchestration, pipeline errors and conditional execution, Fabric notebooks troubleshooting) are also linked in § Reference above; this section holds the comprehensive set.

### Notebook-level error mechanics

- [NotebookUtils notebook run and orchestration](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-notebook-run) — the canonical reference for `run()`, `runMultiple()`, `exit()`, `validateDAG()`. Critical rules called out: don't call `exit()` inside try/except (the call won't propagate); exit values are always strings; child notebooks must share the parent's lakehouse unless `useRootDefaultLakehouse: True`.
- [NotebookUtils (former MSSparkUtils) for Fabric — overview](https://learn.microsoft.com/fabric/data-engineering/notebook-utilities) — module index; `notebookutils.fs.help()` / `.notebook.help()` / `.credentials.help()`.
- [Microsoft Spark Utilities (MSSparkUtils) for Fabric](https://learn.microsoft.com/fabric/data-engineering/microsoft-spark-utilities) — older `mssparkutils` namespace (still works); same `exit()` semantics, useful background on REPL-per-notebook resource model that informs the Tier 2 concurrency considerations.
- [Manage and execute notebooks in Fabric with APIs (exit values from notebook runs)](https://learn.microsoft.com/fabric/data-engineering/notebook-public-api#exit-values-from-notebook-runs) — the `exitValue` field returned by Get-Item-Job-Instance. How an external orchestrator reads the success/failure signal a Tier 2 summary emits.
- [Fabric notebooks troubleshooting guide](https://learn.microsoft.com/fabric/data-science/fabric-notebooks-troubleshooting-guide) — common notebook errors (timeouts, session connectivity, Copilot Fix). Useful for understanding the runtime environment errors the Tier 1 hard-fail path will surface.

### DAG-style parallel runs (`runMultiple`)

- [`runMultiple()` failure handling](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-notebook-run#reference-run-multiple-notebooks-in-parallel) — the `RunMultipleFailedException`, the `{exitVal, exception}` result-dictionary shape per activity, the `retry` and `retryIntervalInSeconds` fields. This is the framework-level analog to the in-house `results = {succeeded, skipped, failed}` shape.
- [DAG parameter reference](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-notebook-run#dag-parameter-reference) — full per-activity field list (timeout, args, workspace, retry, dependencies). Use when the Tier 2 "for-loop with try/except" pattern outgrows a single notebook.
- [`@activity('name').exitValue()` expression](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-notebook-run#reference-exit-values-between-activities) — passing data between DAG activities via exit values.

### Pipeline-level error handling (Data Factory)

- [Errors and Conditional execution (canonical patterns)](https://learn.microsoft.com/azure/data-factory/tutorial-pipeline-failure-error-handling) — Try-Catch / Do-If-Else / Do-If-Skip-Else patterns + the four conditional paths (Upon Success, Upon Failure, Upon Completion, Upon Skip) and how they determine pipeline success. Authored for ADF but applies to Fabric Data Factory pipelines unchanged.
- [Fabric Fail activity](https://learn.microsoft.com/fabric/data-factory/fail-activity) — intentionally fail the pipeline with custom message + error code. The pipeline-level analog to `raise RuntimeError(...)` from the STRICT-mode Tier 2 epilogue.
- [Pipeline overview — best practices](https://learn.microsoft.com/fabric/data-factory/pipeline-overview#best-practices) — the "handle errors / plan for failures with retry logic and alternative processing paths" guidance Fabric officially recommends.
- [Troubleshoot pipelines for Data Factory in Fabric](https://learn.microsoft.com/fabric/data-factory/pipeline-troubleshoot-guide) — common pipeline error symptoms + causes (parameter-size limits, format/compression mismatches).
- [Debug pipelines in Microsoft Fabric (deactivate activity, iterative workflow)](https://learn.microsoft.com/fabric/data-factory/how-to-debug-pipelines-in-microsoft-fabric) — the "deactivate downstream activities, validate, reactivate" pattern useful when isolating a Tier-2 failure cause.

### Spark-side exception classes (for typed `except` clauses)

- [PySpark exceptions module (`pyspark.errors`)](https://learn.microsoft.com/azure/databricks/dev-tools/pyspark/api/pyspark.errors) — the `AnalysisException`, `IllegalArgumentException`, `ParseException`, `PySparkValueError` hierarchy. When the Tier 2 catch needs to be more specific than bare `except Exception`.
- [Delta Lake — concurrent write exceptions](https://learn.microsoft.com/azure/databricks/delta/concurrency-control) — `ConcurrentAppendException` / `ConcurrentDeleteReadException` / `ConcurrentDeleteDeleteException` / `ConcurrentTransactionException` and `MetadataChangedException`. Snapshot-conflict (24556 / 24706 in Warehouse) is the Spark-side equivalent — relevant when retry-with-backoff is the right Tier 2 response.

### Workspace monitoring (after the fact)

- [What is workspace monitoring (preview)?](https://learn.microsoft.com/fabric/fundamentals/workspace-monitoring-overview) — cross-item logs, managed through a **monitoring item** whose Eventhouse holds a read-only KQL database; the old *Log workspace activity* settings toggle is now legacy (Learn, 2026-10-06).
- [Monitor Fabric items with item job event logs](https://learn.microsoft.com/fabric/fundamentals/item-job-event-logs) — `ItemJobEventLogs` table; the post-hoc place to see which Tier 1/Tier 2 runs failed across the workspace.

## See also

- [SKILL.md](../SKILL.md) — notebook environment the tiers apply to
- fabric-gotchas skill — cross-cutting error causes (snapshot conflict, auth, etc.)
