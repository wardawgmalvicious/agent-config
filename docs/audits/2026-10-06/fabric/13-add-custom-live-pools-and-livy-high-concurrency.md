# Handoff: add custom live pools and Livy high concurrency

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 15
- **Kind**: additive documentation in two Spark skills, plus one
  naming correction. Content only.
- **Target**: `skills/fabric/fabric-spark/SKILL.md` (lines 112, 146–154),
  `skills/fabric/fabric-spark-monitoring/SKILL.md` (lines 49, 156–158)

## The problem

Two Spark features went GA in this window, and neither skill describes
them:

- **Custom live pools.** `fabric-spark` lists three pool choices and
  omits these, which are portal-managed and notebooks-only.
- **High concurrency for the Livy API.** `fabric-spark-monitoring`
  describes high-concurrency sessions only in their notebook form. The
  Livy-API form names its sessions differently and packs them
  differently, so a reader searching the monitoring hub with the
  skill's pattern will not find them.

## Evidence

**What's New rows**, GA, September 2026, added by `9eda27f8`
(2026-10-02):

- "Custom Live Pools (Generally Available)", which pairs the base
  preview row "Custom Live Pools for Fabric Data Engineering (Preview)".
  That base row's wording was edited on 2026-09-02 by `6724b585`.
- "Fabric Livy API high concurrency (Generally Available)", which pairs
  the base preview row "High Concurrency Support for the Fabric Livy
  API (Preview)".
- "Delegated Custom Live Pool management (Preview)", also new in this
  window.

**Learn** (agent-measured, 2026-10-06):

- https://learn.microsoft.com/en-us/fabric/data-engineering/custom-live-pools-overview
  - "Custom live pools can't be managed via environment public APIs or
    CI/CD pipelines."
  - "Spark job definitions (batch jobs) aren't supported in the current
    release of custom live pools."
- https://learn.microsoft.com/en-us/fabric/data-engineering/high-concurrency-livy
  - "HC jobs appear in the monitoring hub with the name
    `HC_<LakehouseName>_<LivySessionId>`."
  - Sessions are packed "up to five REPLs per Livy session", grouped by
    `sessionTag`.

**The skills** (agent-measured):

- `fabric-spark/SKILL.md:112` — "**Pool selection** via
  `executionData.configuration`: `useStarterPool: true` (dev/shared),
  `useWorkspacePool: true` (prod), or a custom pool name". The
  Environment section at `:146-154` doesn't mention live pools either.
- `fabric-spark-monitoring/SKILL.md:49` — "`HC_<NotebookName>_<livyId>`
  prefix marks a high-concurrency session"
- `fabric-spark-monitoring/SKILL.md:156-158` — "≤ 5 notebooks".

## What to change

1. **`fabric-spark`, pool selection and Environment sections.** Add
   custom live pools. They work for notebooks only and are managed in
   the portal only (not through the Environment APIs or CI/CD). Spark
   job definitions can't use them. Delegated management is preview.
2. **`fabric-spark-monitoring:49` and `:156-158`.** Add Livy-API high
   concurrency as a second mode beside the notebook one: REPL-level,
   grouped by `sessionTag`, named
   `HC_<LakehouseName>_<LivySessionId>`, at most five REPLs per
   session.

## Constraint on the fix

- Add the Livy form; don't replace the notebook form.
  `HC_<NotebookName>_…` may still be correct for notebook high
  concurrency, and the audit did not re-check it.
- Out of scope: the audit also flagged a new pipeline route for
  refreshing a SQL analytics endpoint against `fabric-spark/SKILL.md:61`.
  That finding is not in this brief's action.

## Verification

1. `grep -n -i "live pool\|useStarterPool\|useWorkspacePool" skills/fabric/fabric-spark/SKILL.md`
   — the custom live pool option is present, with its limits.
2. `grep -n "HC_" skills/fabric/fabric-spark-monitoring/SKILL.md` — both
   naming patterns are present, each attributed to its own mode.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-spark/SKILL.md`
   and the same for `skills/fabric/fabric-spark-monitoring/SKILL.md`.
4. `pre-commit run --all-files`

## Provenance

Found by the warehouse/Spark mapping subagent during the 2026-10-06
`/drift-audit` run against `fabric` (floor 2026-09-01). The Learn quotes
above are the agent's own; the audit session did not re-check them.
