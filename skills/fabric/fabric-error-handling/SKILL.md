---
name: fabric-error-handling
description: "Use when writing error handling in Fabric notebooks — the Tier 1 (setup, preconditions, hard-fail, raise immediately) vs Tier 2 (bulk operations, soft-fail, track per-item, print summary) convention. Covers the canonical `results = {succeeded, skipped, failed}` shape, the STRICT=False default for scheduled runs, STRICT=True for CI/orchestration, per-item metrics with a parallel per_item list, boundary rules (Tier 1 helpers may be called inside Tier 2 loops; don't wrap Tier 1 in try/except at the notebook level), and anti-patterns to avoid (silent continue, parallel bookkeeping lists)."
paths:
  - "**/*.Notebook/**"
---

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
#                   Right for scheduled runs: one bad item shouldn't stop the
#                   rest of the work, and the per-item report is enough signal.
# True  — raise RuntimeError after the summary when any item failed. Use from
#         CI / orchestration where you want the notebook exit code to reflect state.
STRICT = False
```

After the summary, `if STRICT and results["failed"]: raise RuntimeError(...)`. The default is `False` — best-effort with a clear report is what most maintenance runs want.

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
- Comprehensive MS Learn link bundle (notebook exit/runMultiple/DAG / pipeline error paths / Fail activity / Spark exception classes / workspace monitoring): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-spark skill — notebook environment the tiers apply to
- fabric-gotchas skill — cross-cutting error causes (snapshot conflict, auth, etc.)
