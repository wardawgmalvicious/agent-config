# Handoff: update dataflow destinations and pipeline activities

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 16
- **Kind**: minor edits for Dataflow destinations and pipeline retry
  backoff, plus two flags (new activities, run conditions), across two
  Data Factory skills. Content only.
- **Target**: `skills/fabric/fabric-dataflow/references/REFERENCE.md`
  (lines 78–81, 110–113), `skills/fabric/fabric-data-pipeline/SKILL.md`
  (lines 72–74, 82), `skills/fabric/fabric-data-pipeline/references/REFERENCE.md`
  (lines 11, 171–176)

## The problem

Five facts in these two skills are out of date:

- `fabric-dataflow` still calls the Snowflake destination preview and
  says it doesn't work through a gateway.
- It also lacks the new Excel destination and the "Optimized copy to
  Lakehouse" staging option.
- `fabric-data-pipeline` describes retry backoff without its limits.
- Its activity enum predates four new activities.
- It knows nothing of pipeline-level run conditions.

## Evidence

**What's New rows.** All were added by `9eda27f8` (2026-10-02). The GA
rows are dated September 2026.

- "New Dataflow destinations (Generally Available)"
- "Optimized Dataflow copy to lakehouse (Generally Available)"
- "Pipeline retry backoff (Generally Available)"
- "Lakehouse maintenance activity (Generally Available)"
- "Refresh SQL analytics endpoint activity (Preview)"
- "Business Actions activity (Preview)"
- "Fabric Actions activity (Preview)"
- "Pipeline-level dependencies (Preview)"

The base preview row "Lakehouse utility suite (Preview)" split between
the maintenance activity and the endpoint-refresh activity.

**Learn** (agent-measured, 2026-10-06). All pages are under
`https://learn.microsoft.com/en-us/fabric/data-factory/`.

- `dataflow-gen2-data-destinations-and-managed-settings`: "To use
  Snowflake as a data destination through an on-premises data gateway,
  install the latest version of the gateway." The page also lists an
  Excel destination.
- `dataflow-gen2-staged-data-options`: "**Optimized copy to Lakehouse**
  — Use a faster path to write staged data to a Fabric Lakehouse data
  destination." It is off by default.
- `activity-retries`: "Retry interval fields don't support dynamic
  expressions. Values must be static integers." The default maximum
  interval is 3,600 seconds.
- `activity-overview` lists all four new activities.
- `lakehouse-maintenance-activity`: "doesn't support maintenance on
  Lakehouses with schemas enabled yet."
- `business-actions-activity`: "The business action activity is in
  preview."
- `fabric-actions-activity`: "Fabric actions is in preview."
- `pipeline-run-conditions`: "Run conditions define when a Fabric
  pipeline can start." It is preview, offers Custom, Data availability
  and Window coverage conditions, and doesn't document how they
  serialize to Git.

**The skills** (agent-measured):

- `fabric-dataflow/references/REFERENCE.md:78-81`: "### Snowflake
  destination (preview) limitations … gateway unsupported, cloud only."
  The Scale-tab text is at `:110-113`.
- `fabric-data-pipeline/references/REFERENCE.md:171-176`: "Increasing
  Delay (exponential back-off: each retry waits a random interval from
  a range that doubles per attempt, bounded by a configured maximum)."
- `fabric-data-pipeline/SKILL.md:82`: "The enum has 36 entries; the full
  table is in". The agent also noted that Learn's activity list has
  Approval and Refresh materialized lake view activities beyond the
  REST enum.
- `fabric-data-pipeline/SKILL.md:72-74`: "`dependencyConditions` are
  `Succeeded`, `Failed`, `Skipped`, `Completed` — an activity with
  several `dependsOn` entries waits for **all** of them."

## What to change

1. **Snowflake destination** (`fabric-dataflow` REF:78-81). The
   destination is GA and works through the latest on-premises gateway.
   Retitle the section and drop "gateway unsupported".
2. **New destination and staging option** (`fabric-dataflow`). Add the
   Excel destination. Add "Optimized copy to Lakehouse" (off by default)
   to the Scale-tab text at `:110-113`.
3. **Retry backoff** (`fabric-data-pipeline` REF:171-176). Add the
   3,600-second default maximum, and state that retry intervals must be
   static integers.
4. **New activities, flag only** (`fabric-data-pipeline/SKILL.md:82`).
   Note the four activities and their status. Note that their JSON
   `type` strings are undocumented and that the maintenance activity
   excludes schema-enabled lakehouses. Keep "36 entries" as the REST
   enum count, and say so.
5. **Run conditions, flag only** (`fabric-data-pipeline/SKILL.md:72-74`).
   Add one line saying a pipeline-level layer now exists (preview) and
   that its Git serialization is undocumented.

## Constraint on the fix

- Do not write a JSON `type` string for any new activity. None is
  documented, and a guessed one breaks a definition silently.
- Out of scope, because neither is in this brief's action:
  - the destination-expression and dynamic-warehouse-schema flag on
    `fabric-dataflow/SKILL.md:263-267` and REF:88;
  - the same run-conditions flag on `claude/rules/coding-expressions.md`.
- The workspace-monitoring text in `fabric-dataflow` REF:212-214 belongs
  to brief 12.

## Verification

1. `grep -n -i "snowflake\|excel\|optimized copy" skills/fabric/fabric-dataflow/references/REFERENCE.md`:
   no hit still says the Snowflake destination is preview or
   gateway-unsupported.
2. `grep -n -i "3600\|3,600\|static\|run condition\|36 entries" skills/fabric/fabric-data-pipeline/SKILL.md skills/fabric/fabric-data-pipeline/references/REFERENCE.md`
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-data-pipeline/SKILL.md`
4. `pre-commit run --all-files`

## Provenance

Found by the Data Factory mapping subagent during the 2026-10-06
`/drift-audit` run against `fabric` (floor 2026-09-01). The Learn quotes
are the agent's own. The agent noted that Learn's Data Factory index may
lag What's New, which is why the activities and run conditions are flags
rather than edits.
