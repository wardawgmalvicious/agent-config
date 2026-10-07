# Handoff: rewrite the MLV optimal-refresh tables

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 2
- **Kind**: partial rewrite of two tables in one skill that now state
  the opposite of Learn, a CREATE-grammar addition, a GA-date flag on
  the `description`, and an overdue scheduled re-check. A
  `description` edit changes the skill's trigger, so it needs a retest.
- **Target**: `skills/fabric/fabric-mlv/SKILL.md` (lines 3, 20–21,
  27–37, 111–129)

## The problem

`fabric-mlv` says three things force a full refresh of a materialized
lake view: a source with updates or deletes, any aggregate, and
`GROUP BY`. Learn now says aggregates and `GROUP BY` refresh
incrementally under stated conditions, and updates and deletes refresh
incrementally when the view declares a `REFRESH_HINT`. A reader
designing a medallion layer from the skill would avoid patterns that
now refresh incrementally, and would never declare the hint.

The `description` also dates Spark SQL MLV GA to March 2026, which
disagrees with the What's New page, and the skill's own scheduled
Runtime 2.0 re-check fell due in late September.

## Evidence

**What's New.** "Optimal refresh for materialized lake view updates and
deletes (Preview)" was added by `80a24c9b` (2026-09-29).
"Materialized lake views (Generally Available)" was added to the GA
table with month September 2026 by `9eda27f8` (2026-10-02).

**The skill as of 2026-10-06** (read in the audit session):

- `SKILL.md:116` — "| **Incremental** | New commits + query uses only
  the supported-construct subset + all sources have CDF enabled +
  append-only |"
- `SKILL.md:117` — "| **Full** | Source has updates/deletes,
  unsupported constructs, non-Delta source, or PySpark-defined MLV |"
- `SKILL.md:125` — "| `SELECT` aggregates (`SUM`, `COUNT`, `AVG`,
  `MIN`, `MAX`, `STDDEV`) | Full refresh |"
- `SKILL.md:126` — "| `GROUP BY`, `DISTINCT`, window functions | Full
  refresh |"
- `SKILL.md:3` (description) — "`CREATE MATERIALIZED LAKE VIEW` Spark
  SQL (GA March 2026) + still-preview `@fmlv.materialized_lake_view`
  PySpark decorator"
- `SKILL.md:20` — Runtime 1.3 prerequisite, with "Re-check the
  prerequisite then" against Runtime 2.0 becoming the default in late
  September 2026.
- `SKILL.md:21` — "**Region** — not available in South Central US (as
  of 2026-04)."

**Learn, checked in the audit session on 2026-10-06** —
https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/refresh-materialized-lake-view,
"SQL constructs supported by incremental refresh", the `GROUP BY /
aggregates` row, verbatim:

> Supported. Use of **Aggregates** (`AVG()`, `STDDEV()`, and others)
> requires that every source table is partitioned and that partition
> column is included in the `GROUP BY` clause of the MLV query - this
> requirement lets Fabric incrementally recompute only the affected
> partitions. **`SUM()`, `MIN()`, `MAX()`, and `COUNT()` (without
> DISTINCT)** are a **special case**: they support incremental refresh
> without the partitioning requirement. Mixing other aggregate functions
> with `SUM()`, `COUNT()`, `MIN()`, and `MAX()` in the same query (for
> example, `SELECT SUM(amount), AVG(price) ...`) requires the
> partitioning condition for the whole query; otherwise, Fabric falls
> back to full refresh. `GROUP BY` columns must appear in the `SELECT`
> list.

The same table keeps `DISTINCT` and window functions unsupported ("…
`DISTINCT` and window functions aren't supported."). The same page, on
data patterns:

> For non-append data, such as deletes or updates, incremental refresh
> is supported only when the materialized lake view uses a refresh hint
> that identifies row identity. Otherwise, the engine falls back to full
> refresh.

It also says a full refresh is chosen "when the source dataset is small
enough that a full recompute is faster than incremental processing".

https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/optimal-refresh-handling-deletes-updates
(preview) defines the clause as
`REFRESH_HINT <hint_name> UNIQUE (<column1> [, <column2>, ...])`. It
states "Fabric doesn't validate uniqueness at runtime", and lists two
limitations: a source schema change between refreshes forces a full
refresh, and non-unique declared columns "might result in data
inconsistencies without any error or warning". The page gives a
duplicate check (`GROUP BY <cols> HAVING COUNT(*) > 1`) and a `NULL`-key
check to run before declaring the hint.

**GA date.** The PySpark page,
https://learn.microsoft.com/en-us/fabric/data-engineering/materialized-lake-views/create-materialized-lake-view-pyspark,
says "PySpark-based materialized lake views are currently in preview",
which matches the skill. Nothing found in the audit states a GA month
for Spark SQL MLVs other than the What's New row.

**Runtime and region** (agent-measured, 2026-10-06): the get-started
page still names "Fabric Runtime 1.3", while the MLV notebook-utilities
page says MLVs are "supported in Spark 4.1". The South Central US
exclusion is gone from the overview page.

## What to change

1. **Strategy table, lines 113–117.** Incremental no longer requires
   append-only sources: updates and deletes qualify with a refresh hint.
   Add the "small source, full is cheaper" reason to Full.
2. **"What blocks incremental refresh", lines 121–129.** Aggregates and
   `GROUP BY` move from "Full refresh" to supported, with the partition
   rule and the `SUM`/`MIN`/`MAX`/`COUNT` exemption. `DISTINCT` and
   window functions stay on the full-refresh side.
3. **CREATE grammar, lines 27–37.** Add `REFRESH_HINT … UNIQUE (…)`,
   marked preview, with the no-runtime-validation warning.
4. **Description, line 3.** Flag only: reconcile "GA March 2026" with
   What's New's September 2026. Do not pick a month without a Learn
   statement; recording both, dated, is acceptable.
5. **Lines 20–21.** Run the scheduled Runtime 2.0 re-check and record
   the result with its date, and drop or re-date the region exclusion.

## Constraint on the fix

- `REFRESH_HINT` is preview. Say so wherever it appears.
- Keep the PySpark rule ("PySpark always full-refresh") unless Learn
  says otherwise; nothing in this window changed it.
- Out of scope: the mapping agent noted surface the skill does not
  cover (`USING OneLake_Files`, `notebookutils.lakehouse.refreshMlv`
  (preview), a Refresh MLV pipeline activity (preview)). Those are
  additions the audit did not recommend; leave them.

## Verification

1. `grep -n "Full refresh\|REFRESH_HINT\|GA March\|Runtime 1.3\|South Central" skills/fabric/fabric-mlv/SKILL.md`
   — aggregates and `GROUP BY` are no longer listed as full-refresh
   triggers, and `REFRESH_HINT` appears marked preview.
2. Re-open both Learn pages above and confirm the quoted rows still
   read as quoted.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-mlv/SKILL.md`
4. If line 3 changed: `uv run --with pyyaml scripts/skill-status.py --stale`
   names `fabric-mlv`; retest its activation per `/test-skill`, or stamp
   the retest as owed.
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01, by the warehouse/Spark mapping subagent. The audit session
then checked the refresh pages itself. The aggregate rule may have
changed on Learn before this window; the window's
updates-and-deletes row is what surfaced it, and the skill is wrong
either way.

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: `skills/fabric/fabric-mlv/SKILL.md`
- **Verification**: steps 1–3 passed; step 4 did not apply, as line 3
  is unchanged; step 5 runs once at the end of the run. Step 1:
  aggregates and `GROUP BY` now read as incremental (`SUM`/`MIN`/
  `MAX`/`COUNT`) or conditional on partitioned sources, never as a
  full-refresh trigger; `REFRESH_HINT` appears four times, each marked
  preview; South Central is gone; `GA March` survives only at line 3,
  per item 4. Step 2: both Learn pages re-opened 2026-10-06; the
  `GROUP BY / aggregates` row, the non-append quote, the
  small-source full-refresh reason, the `REFRESH_HINT` grammar, "Fabric
  doesn't validate uniqueness at runtime" and both limitations read as
  quoted. Step 3: lint clean.
- **Item 5, the re-check, 2026-10-06**: the get-started page still
  names "Fabric Runtime 1.3"; Learn's runtime page still says "By
  default, all new workspaces currently use Runtime 1.3", lists 1.3
  as EOSA and 2.0 as GA, so the late-September default switch had not
  happened. The MLV notebook-utilities page (preview) says it is
  "supported in Spark 4.1", the one 2.0 signal; it is left out of the
  skill, as the brief puts that API out of scope. The region bullet
  was dropped: neither the MLV overview nor the South Central US row
  of Fabric's region-availability page lists MLVs as unavailable.
- **Deferred**: item 4, flag only. The description is exactly 1,024
  characters, the `DESCRIPTION_MAX` cap, so recording both months
  there would cut other trigger text; `GA March 2026` stays until a
  Learn page states the month. It came from `0424c18` (2026-05-18),
  whose message cites no source. Adjacent, not fixed:
  `references/REFERENCE.md:3` carries the same `GA March 2026`, and
  `references/REFERENCE.md:52` still says 2.0 is the "planned default
  … in late September 2026", which the re-check above overtook.
  Behavioural confirmation needs a fresh session:
  `/test-skill fabric-mlv` with this brief.
- **Deviations**: one. The "Limitations and gotchas" row "Optimal
  refresh always picks Full" (now line 290), outside the named lines,
  listed aggregates as an unsupported construct. Step 1 requires that
  aggregates are no longer listed as full-refresh triggers anywhere in
  the file, and the brief's own Learn row is the evidence, so the
  parenthetical now names only an aggregate other than
  `SUM`/`MIN`/`MAX`/`COUNT` over unpartitioned sources.
- **Needs**: the next fabric drift audit — a Learn statement of the
  Spark SQL MLV GA month, to settle `SKILL.md:3` and
  `references/REFERENCE.md:3`; the `REFERENCE.md:52` fix under
  Deferred needs nothing and can land first.
- **Needs**: the next fabric drift audit — a Learn statement of the
  Spark SQL MLV GA month, to settle `SKILL.md:3` and
  `references/REFERENCE.md:3`. The `REFERENCE.md:52` fix landed
  2026-10-06: Runtime 2.0 is still opt-in, quoting the runtime page's
  "By default, all new workspaces currently use Runtime 1.3".
