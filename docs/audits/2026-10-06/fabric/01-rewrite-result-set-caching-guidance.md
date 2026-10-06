# Handoff: rewrite the result set caching guidance

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 1
- **Kind**: partial rewrite of one skill section that now gives the
  opposite of the right advice, plus two minor edits in the same skill.
  Content only; no frontmatter change expected.
- **Target**: `skills/fabric/fabric-warehouse-monitoring/SKILL.md`
  (lines 99–103), `skills/fabric/fabric-warehouse-monitoring/references/REFERENCE.md`
  (lines 5, 13, 29, 42–43)

## The problem

`fabric-warehouse-monitoring` tells its reader that result set caching
is disabled in Fabric Data Warehouse and the SQL analytics endpoint, and
not to recommend it as a tuning step. It is generally available and on
by default for every warehouse and SQL analytics endpoint. A session
following the skill today would steer a user away from a feature that is
already running on their queries, and could not explain a cache hit.

Two smaller facts in the same skill also moved: the warehouse "Query
activity" feature was renamed **Monitor** and its Learn slug changed,
and workspace monitoring is now managed through a monitoring item.

## Evidence

**What's New.** Commit `27532aaa` (2026-09-23, "RSC on by default
(#16617)") added a GA-table row, `September 2026 | Result set caching`.

**Learn, checked in the audit session on 2026-10-06** —
https://learn.microsoft.com/fabric/data-warehouse/result-set-caching:

> Result set caching is configurable at the item level, and enabled by
> default for all Fabric Warehouses and Lakehouse SQL Analytics
> Endpoints.

Check and off switches, from the same page:

```sql
SELECT name, is_result_set_caching_on
FROM sys.databases
WHERE database_id = db_id();

ALTER DATABASE <Fabric_item_name>
SET RESULT_SET_CACHING OFF;

-- per query
OPTION ( USE HINT ('DISABLE_RESULT_SET_CACHE') );
```

The page's "Qualify for result set caching" list has 15 disqualifiers.
Paraphrased in order: caching not enabled, or the query carries the
hint; not a pure `SELECT` (CTAS, `SELECT INTO`, DML); references a
system object, temp table or metadata function, or no distributed
object; no referenced table of at least 100,000 rows; references an
object outside the connected item (cross-database); inside an explicit
transaction or `WHILE` loop; a `CAST`/`CONVERT` touching `date` or
`sql_variant`; runtime constants such as `CURRENT_USER` or `GETDATE()`;
result estimated above 10,000 rows; non-deterministic built-ins, window
aggregates or ordered functions (`PARTITION BY … ORDER BY`); dynamic
data masking, row-level security or other security features; time
travel; `ORDER BY` on a column not in the output; session-level `SET`
statements with non-default values; internal cache limits reached.
Cache reuse is further blocked by a change to a referenced table, the
workspace going offline, insufficient permissions, a different
connection, different output columns or aliases, or 24 hours unused.
The page still documents `result_cache_hit` values `2`, `1` and `0` as
the skill does.

**The skill as of 2026-10-06** (read in the audit session):

- `SKILL.md:99` — `## Result Set Caching (currently disabled)`
- `SKILL.md:101` — "**Disabled in Fabric Data Warehouse and the SQL
  analytics endpoint as of 2026-09-11, per Learn** — see the [known
  issue](https://aka.ms/fabricdwrscki). Don't recommend it as a tuning
  step while that stands. The feature is disabled, not retired, so the
  rules below apply again when it returns."
- `SKILL.md:103` — "`result_cache_hit` field in
  `exec_requests_history`: `2` = cache hit, `1` = the query created the
  cache, `0` = not applicable … Non-deterministic functions
  (`GETDATE()`, `NEWID()`) prevent caching. Cache auto-invalidates when
  underlying data changes."
- `references/REFERENCE.md:29` also carries result set caching
  (agent-measured; read it before editing).

**Monitor rename.** Commit `91e49056` (2026-09-09) replaced the preview
row "Data Warehouse Monitor (Preview)" with "Monitor for Fabric Data
Warehouse (Preview)". Learn,
https://learn.microsoft.com/en-us/fabric/data-warehouse/monitor:
"Monitor was previously named "Query Activity"." and "You must be an
admin in your workspace to access the Monitor." `REF:5` and `REF:13`
link `https://learn.microsoft.com/fabric/data-warehouse/query-activity`
under the title "Monitor your running and completed T-SQL queries using
Query activity" (agent-measured). The 15-minute lag and the `Invalid
object name` gotcha at `SKILL.md:31` still stand.

**Workspace monitoring.** The row "Updated workspace monitoring
experience (Preview)" was added by `80a24c9b` (2026-09-29) and deleted
by the page restructure `9eda27f8` (2026-10-02), so it is absent from
the live page. Learn,
https://learn.microsoft.com/en-us/fabric/fundamentals/workspace-monitoring-overview:
"You manage workspace monitoring through a **monitoring item**." The
page files the old settings toggle under a "Legacy" section and lists
Warehouse query execution logs as a source. `REF:42-43` say
"read-only Eventhouse / KQL database per workspace" and "toggle in
Workspace Settings → Monitoring; auto-creates the monitoring Eventhouse";
the URL at `:43` now resolves to the pipeline-logs page
(agent-measured).

## What to change

1. **`SKILL.md` lines 99–103.** Retitle the section without "currently
   disabled". Replace the disabled paragraph with: on by default for
   every warehouse and SQL analytics endpoint; the `sys.databases`
   check; the item-level and per-query off switches. Extend the
   eligibility sentence at 103, which names only non-deterministic
   functions, to the disqualifiers above, or to the handful that bite
   most often plus a link to the list. Keep the `result_cache_hit`
   values; they match Learn.
2. **`references/REFERENCE.md:29`** — align with the rewritten section.
3. **`references/REFERENCE.md:5` and `:13`** — rename Query activity to
   Monitor, link `/fabric/data-warehouse/monitor`, and note that it is
   preview and admin-only. The same `query-activity` link appears at
   `skills/fabric/fabric-warehouse/references/REFERENCE.md:40`
   (agent-measured): it is the same stale fact, so fix it in the same
   pass.
4. **`references/REFERENCE.md:42-43`** — describe the monitoring item,
   mark the settings toggle as legacy, add Warehouse query execution
   logs as a source, and replace the URL that now lands on pipeline
   logs.

## Constraint on the fix

- Open `https://aka.ms/fabricdwrscki` before deleting the reference to
  it. If the known issue still reads as active, record both facts with
  their dates rather than choosing one: What's New and the result set
  caching page say "on by default" as of 2026-10-06.
- Do not change the `result_cache_hit` semantics; they still match.
- The workspace-monitoring fact also lands in brief 06
  (`fabric-eventstream`) and brief 12 (`fabric-dataflow`,
  `fabric-mirroring`, `fabric-error-handling`). Keep the wording
  consistent; whichever brief runs second reads the first one's text.

## Verification

1. `grep -rn -i "currently disabled\|fabricdwrscki\|RESULT_SET_CACHING" skills/fabric/fabric-warehouse-monitoring`
   — no hit still says the feature is disabled, unless it is dated
   history.
2. `grep -rn "query-activity" skills/fabric` — no hit left; each now
   links `/monitor`.
3. Re-open the result set caching page and confirm "enabled by default"
   still reads as quoted.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-warehouse-monitoring/SKILL.md`
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01, by the warehouse/Spark mapping subagent. The audit session
then checked the result set caching page itself. The skill's "disabled"
claim was dated 2026-09-11 and was overtaken twelve days later by
commit `27532aaa`, whose title states the new default outright.
