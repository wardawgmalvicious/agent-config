# Handoff: correct result set caching and Capacity Metrics correlation in fabric-warehouse-monitoring

- **Audit run**: 2026-09-10
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-06` (diff base `912e06e0`) → head `65902bae`
  (2026-09-04)
- **Covers recommended actions**: 1 and 2
- **Kind**: factual correction to a platform skill's prose, against
  Microsoft Learn. No trigger or frontmatter change.
- **Target**: `skills/fabric/fabric-warehouse-monitoring/SKILL.md`,
  `skills/fabric/fabric-warehouse-monitoring/references/REFERENCE.md`

## The problem

`fabric-warehouse-monitoring` makes three claims that Microsoft Learn now
contradicts:

1. It presents result set caching as a live preview feature. Learn says
   the feature is currently **disabled** in Fabric Data Warehouse and the
   SQL analytics endpoint.
2. It encodes `result_cache_hit` as `1` = hit, `0` = miss, negative = the
   reason caching was skipped. Learn encodes it as `2` = hit, `1` =
   created the cache, `0` = not applicable, and documents no negative
   values.
3. Its reference bundle says the Capacity Metrics app's `Operation Id`
   traces to `distributed_statement_id`. Learn now says it no longer
   maps, and correlates by billing-interval timestamps instead.

## Evidence

Upstream trigger — `microsoft/skills-for-fabric` `CHANGELOG.md`, section
`[0.3.15] - 2026-09-04` (release commit `65902bae`), two `sqldw-cli`
bullets, quoted in the parts that matter:

> ... treat SQL statement candidates as best-effort correlation because
> Capacity Metrics Operation Id and Query Insights
> `distributed_statement_id` are different identifiers.

> ... and stopped recommending result-set caching while the feature is
> unavailable.

Upstream is another team's skill catalog, not documentation, so neither
claim became a finding until it was confirmed on Learn. Both were, on
2026-09-10.

[Result set caching](https://learn.microsoft.com/fabric/data-warehouse/result-set-caching),
the caution at the top of the page, verbatim:

> The result set caching feature is currently disabled in Fabric Data
> Warehouse and SQL analytics endpoint. For more information, see the
> [Fabric Data Warehouse Known Issue](https://aka.ms/fabricdwrscki).

The same page, on the column, verbatim:

> - `2`: the query used the result set cache (*cache hit*)
> - `1`: the query created the result set cache
> - `0`: the query wasn't applicable for the result set cache creation or
>   usage

[How to: Observe Fabric Data Warehouse utilization trends](https://learn.microsoft.com/fabric/data-warehouse/how-to-observe-utilization),
the note in step 6, verbatim:

> The **Operation Id** shown in the Capacity Metrics app no longer maps
> to the distributed statement ID for warehouse queries. To determine
> which queries contributed to compute consumption during a billing
> interval, query the *queryinsights.exec\_requests\_history* view using
> the interval's start and end timestamps.

It is followed by this query, which is the replacement pattern:

```sql
DECLARE @Start_Time DATETIME2(0) = '2026-08-04 8:00:00'
        ,@End_Time DATETIME2(0) = '2026-08-04 9:00:00'

SELECT [database_name],
       sql_pool_name,
       distributed_statement_id,
       login_name,
       allocated_cpu_time_ms / 1000.0 AS vcore_seconds
FROM queryinsights.exec_requests_history
WHERE start_time < @End_Time
AND end_time > @Start_Time;
```

## What to change

1. **`SKILL.md` line 83** — the heading `## Result Set Caching
   (Preview)`. Replace the preview framing with the disabled state and
   the known-issue link. Keep the section: the feature is disabled, not
   retired, and its eligibility rules will matter again when it returns.
2. **`SKILL.md` line 85**, which reads:

   > `result_cache_hit` field in `exec_requests_history`: `1` = cache
   > hit, `0` = miss, **negative values** = reason caching was skipped.

   Replace the encoding with Learn's — subject to the constraint below.
3. **`references/REFERENCE.md` line 29** — the result set caching link
   annotation, which ends:

   > ... the negative `result_cache_hit` codes.

   Align it with the corrected encoding.
4. **`references/REFERENCE.md` line 36** — the utilization-trends link
   annotation, which reads:

   > drill from Metrics app `Operation Id` → `dist_statement_id` in
   > `sys.dm_exec_requests` and `distributed_statement_id` in
   > `queryinsights.exec_requests_history` for end-to-end traceability.

   Replace it with the no-longer-maps fact and the interval approach.
5. **Add the interval-overlap query** above to `SKILL.md`, so the working
   pattern lives in the body and not only in a link annotation.
   `## Query Insights (30-day retention)` or `## Top Expensive Queries`
   both fit; placement is the fixer's call.

## Constraint on the fix

- The audit drilled the result-set-caching page, **not** the T-SQL
  reference for the view:
  https://learn.microsoft.com/sql/relational-databases/system-views/queryinsights-exec-requests-history-transact-sql.
  Fetch it before writing the encoding. If it still documents negative
  values or a different mapping, record both sources in the skill rather
  than swapping one unverified encoding for another.
- "Currently disabled" is a state that will end. Date it in the text —
  "disabled as of 2026-09-10 per Learn" — so a reader can tell when it
  was last true.
- `SKILL.md` line 39's sample query selects `result_cache_hit`. The
  column still exists; leave the query alone.

## Out of scope

- Learn's sample selects `sql_pool_name`, so custom SQL pools are a real
  surface, and the skill never mentions them. The audit flagged that
  but did not promote it to a recommended action, so it is not part of
  this brief.
- `skills/fabric/fabric-warehouse/SKILL.md` line 223 lists "Result Set
  Caching" among this skill's topics under See also. That stays true
  while the section exists. Re-read it after the edit; no change is
  expected.

## Verification

1. `grep -niE 'negative values|negative .result_cache_hit|caching \(preview\)' skills/fabric/fabric-warehouse-monitoring/SKILL.md skills/fabric/fabric-warehouse-monitoring/references/REFERENCE.md`
   — no hit.
2. `grep -niE 'operation.?id' skills/fabric/fabric-warehouse-monitoring/references/REFERENCE.md`
   — every hit states that the Operation Id no longer maps.
3. Re-fetch both Learn pages and confirm the quoted text still stands.
   The disabled caution is exactly the kind of line that disappears when
   a feature returns.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-warehouse-monitoring/SKILL.md`
5. `pre-commit run --all-files`

## Provenance

Surfaced by the first `/drift-audit --sources skills-for-fabric` run on
2026-09-10, the day the source was registered, from two 0.3.15
`sqldw-cli` bullets. The encoding mismatch was not in either upstream
bullet: it surfaced while drilling the caching page. Both recommended
actions touch one skill and are checked by one verification pass, which
is why they share this brief.
