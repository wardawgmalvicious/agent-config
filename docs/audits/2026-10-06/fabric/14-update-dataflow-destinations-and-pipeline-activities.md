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

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**:
  `skills/fabric/fabric-dataflow/references/REFERENCE.md`,
  `skills/fabric/fabric-data-pipeline/SKILL.md`,
  `skills/fabric/fabric-data-pipeline/references/REFERENCE.md`
- **Verification**: steps 1–3 passed; step 4 runs once at the end of
  the run. Step 1: no Snowflake hit says preview or gateway-unsupported;
  `REF:93`, the old `:88`, is the line the constraint leaves out.
  Step 2: `3,600`, `static`, `Run conditions` and the REST enum's `36
  entries` all hit. Step 3: lint clean; no `description` changed.
- **Learn, read 2026-10-06**:
  `dataflow-gen2-data-destinations-and-managed-settings`, fetched in
  full (11 destinations, Excel as a file format, the Snowflake
  destination settings and gateway note);
  `dataflow-gen2-staged-data-options`; `activity-retries`;
  `activity-overview`; `lakehouse-maintenance-activity`;
  `refresh-sql-endpoint-activity`; `business-actions-activity`;
  `fabric-actions-activity`; `pipeline-run-conditions`; and the
  DataPipeline definition, whose `DataPipelineActivityTypes` enum still
  counts 36, none of them the four new activities. A subagent read all
  but the first, quoting verbatim. Learn's search index still serves the
  older Snowflake text, so a search-only check contradicts the edit;
  fetch the page.
- **Deferred**: no behavioural confirmation; an edited `SKILL.md` does
  not reliably reload mid-session on Windows, so a fresh session would
  exercise it. Two adjacent findings in the dataflow reference stay as
  they are: `REF:93` (was `:88`) still says "Warehouse and Snowflake
  require fixed schema", though Learn now gives new Snowflake tables
  dynamic schema under Replace, and the constraint holds that line for
  the dynamic-warehouse-schema flag; `REF:101` (was `:96`) limits
  automatic settings to "Lakehouse and Azure SQL only", where Learn adds
  Snowflake.
- **Deviations**: three. (1) The brief's dataflow line labels are off:
  the Snowflake section sat at `REF:110-113`, not `:78-81` (the
  destination list), and the Scale-tab text at `:101-103`, not
  `:110-113`. The quotes matched, so the edits went where the quotes
  were. (2) User-directed: the Snowflake section was rewritten from
  Learn, not only retitled with the gateway clause dropped, because
  Learn also contradicts its "Dynamic schema unsupported"; the user
  chose "Correct from Learn". (3) Excel went in as a file format of
  file-based destinations, not as a destination: Learn's list of 11
  destinations has no Excel, contrary to the brief's evidence.
- **Needs**: the next `fabric` audit — correct `fabric-dataflow`
  `REF:93` and `REF:101` for Snowflake, beside the destination-expression
  and dynamic-warehouse-schema flag that no brief carries (audit report
  `:181-187`).
