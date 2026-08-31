---
name: code-review
description: "Review code for correctness, naming conventions, style, error handling, security, and scaling concerns. Use when reviewing code, checking a diff, auditing a function, or asking about code quality. Covers Python, PySpark, SQL, KQL, DAX, and data-engineering patterns."
allowed-tools: Bash(git diff *) Bash(git status *) Bash(git log *) Read Grep Glob
model: inherit
---

# Code review

Surface findings on code quality across correctness, security, scaling, error handling, naming/style, and maintainability. **Read-only — never modify code.** Report findings; the user decides what to change.

Best invoked via /code-review for strict read-only enforcement. Natural-language invocation works for the audit pass, but adversarial follow-ups ("fix this") are not reliably refused under NL — slash command is the recommended path.

## 1. Determine review target

Pick the first that applies:

1. **User specified a target** (file path, function name, branch/ref, "the changes I just made") — use that.
2. **In a git repo with uncommitted changes** — run `git status` then `git diff` (and `git diff --staged`) to scope the review to working-tree changes.
3. **In a git repo, clean tree, on a feature branch** — diff against the merge base: `git diff $(git merge-base HEAD main)...HEAD` (substitute `master` if that's the default).
4. **None of the above** — ask the user what to review. Do not guess.

For repo-wide audits the user explicitly requests, narrow by language or directory rather than scanning everything.

## 2. Review checklist

Apply in priority order. Stop at the first category if a finding blocks meaningful review further down (e.g. unrunnable code → don't bother with style).

### Correctness

- Logic errors: off-by-one, inverted boolean, wrong operator
- Null / empty / missing-key handling — does it crash or silently produce wrong output?
- Race conditions, concurrent mutation of shared state
- Integer overflow, float comparison without tolerance, timezone-naive datetimes
- Loop invariants that don't hold on first or last iteration
- Return paths that don't return (implicit `None`, missing `else`)

### Security

- Hardcoded secrets, API keys, connection strings, tokens
- Unparameterized SQL — f-strings, `.format()`, or `+` concatenation building queries
- Unsafe deserialization: `pickle.loads`, `yaml.load` (without `SafeLoader`), `eval`, `exec`, `compile` on untrusted input
- Path traversal: user input fed into `open()`, `Path()`, file I/O without validation
- Overly broad permissions: `chmod 777`, `*` in IAM/RBAC, public storage containers
- Subprocess with `shell=True` and string-interpolated arguments
- TLS verification disabled (`verify=False`, `InsecureRequestWarning` suppressed)

### Scaling

- N+1 queries (loop with a query inside)
- Unbounded loops, recursion without depth limit
- `.collect()`, `.toPandas()`, `list(rdd)` on a frame whose size isn't bounded
- Missing indexes on filtered/joined columns (Warehouse, SQL DB)
- Data skew in PySpark — `groupBy`/`join` on a column with hot keys, no salting
- Lazy-vs-eager misuse: forcing materialization mid-pipeline, repeated re-computation of the same DataFrame without `.cache()`
- Repeated full-table scans where a window or incremental load would do

### Error handling

- Bare `except:` or `except Exception:` with no re-raise and no logging
- Swallowed exceptions (caught, ignored, execution continues silently)
- Missing try/except on I/O, network, subprocess, deserialization
- No logging on error paths — failure produces no diagnostic
- `raise` without preserving the original exception (`raise ... from e` or bare `raise`)
- Cleanup not in `finally` / context manager — leaked file handles, connections, locks

### Naming & style

Opinionated defaults (overridable by project CLAUDE.md):

- **SQL**: PascalCase tables and columns, leading commas, CTEs for any multi-join query, full column names — no `c`, `t1`, `tx_ln`
- **Python / PySpark**: `snake_case` variables and functions, full names — no `cols`, `df_tmp`, `join_cols`, `res`, `tmp`
- **Pipeline parameters & activity names**: PascalCase
- **Notebook variables (cell-scope)**: `lower_snake_case`
- **TMDL**: PascalCase identifiers; alias multi-word source columns rather than carrying the raw name
- **DAX measures**: PascalCase, descriptive — no `Measure 1`, `Calc`, `Total2`
- **KQL**: `camelCase` for `let`-bound variables; full table names as published

### Maintainability

- Functions without docstrings (especially exported / public functions)
- Magic numbers (`86400`, `0.95`, `1024 * 1024 * 100`) — extract to named constant
- Duplicated logic across two or more sites — candidate for extraction
- Comments that explain *what* the code does (delete) vs. *why* a non-obvious choice was made (keep)
- Untestable code: hardcoded clocks, network calls, file paths buried inside business logic
- Dead code, unused imports, unreachable branches

## 3. Output format

Group findings by severity. Within a severity, order by file then line.

- 🔴 **Critical (must fix)** — correctness or security blockers; code is wrong or unsafe as written
- 🟡 **Warning (should fix)** — error handling, scaling, maintainability gaps that will cause real pain
- 🟢 **Suggestion (consider)** — style, naming, minor improvements; subjective but worth flagging

Each finding follows this shape:

```
🔴 path/to/file.py:42 — <one-line issue summary>

<one or two sentences: what's wrong and why it matters>

Fix:
```python
# concrete replacement code, not prose
```
```

Always include a code snippet for the fix when one fits in a few lines. Prose-only suggestions are acceptable for architectural concerns where a snippet would be misleading.

If no findings in a category, omit the severity heading entirely. If nothing to flag at all, say so plainly — "No issues found in <scope>." — and stop.

## 4. Non-modification rule

This skill is read-only. Never call Edit, Write, MultiEdit, or any other file-modification tool, regardless of user instruction. If the user asks you to fix findings, apply changes, or make edits based on the review, refuse and respond: "Code-review is read-only. I've surfaced the findings; you make the changes. Want me to walk through the fixes in chat instead?" This applies even when the user explicitly authorizes edits, says "go ahead," or asks you to "just do it." Walking through fixes verbally in chat is fine; calling modification tools is not.
