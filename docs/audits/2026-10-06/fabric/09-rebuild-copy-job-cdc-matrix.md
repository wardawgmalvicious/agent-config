# Handoff: rebuild the Copy job CDC matrix

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 10
- **Kind**: partial rewrite of one reference matrix, two status flags
  held against Learn, and two minor edits in one skill. Content; the
  Activator label sits in the `description`, so that edit needs a
  retest.
- **Target**: `skills/fabric/fabric-copy-job/SKILL.md` (lines 3, 47,
  49, 77, 78, 85), `skills/fabric/fabric-copy-job/references/REFERENCE.md`
  (lines 11, 13, 16, 18–32)

## The problem

The Copy job page in What's New moved CDC, SCD Type 2 and several CDC
sources to GA, but Learn's Copy job pages still say preview. The skill
already has a rule for this case, at `REF:16`: hold the preview label
until Learn drops it. That rule still applies.

Separately from status, the skill's CDC source matrix no longer matches
Learn's. Fabric Data Warehouse now supports SCD Type 2, three sources
show full support, and two rows are new. Two smaller items moved too:
Copy job has a workspace-monitoring table, and the Activator action is
GA.

## Evidence

**What's New rows, all added by `9eda27f8` (2026-10-02), GA, September
2026:**

- "Copy job CDC", pairing the base preview row "Copy job support for
  change data capture (CDC) (Preview)".
- "Copy job SCD Type 2", pairing "Extended SCD Type 2 support in Copy
  job for Fabric Data Warehouse (Preview)".
- "Snowflake read-only CDC".
- "Oracle CDC initial-load improvements".
- "SQL CDC custom capture names".
- "Copy job workspace monitoring", pairing "Workspace Monitoring for
  Copy job (Preview)".
- "Activator Fabric-item actions".

**Learn** (agent-measured, 2026-10-06):

- `https://learn.microsoft.com/en-us/fabric/data-factory/cdc-copy-job`:
  - "SCD Type 2 in Copy job is currently in preview. When you do CDC
    replication from Oracle sources, SCD Type 2 isn't supported yet."
  - "Custom capture instances aren't supported; only the default
    capture instance is supported."
  - The page's served matrix: Fabric Data Warehouse supports SCD Type
    2; Oracle, BigQuery and Snowflake show yes in all three columns;
    there are two new rows.
- The connectors page still heads its section "## CDC Replication
  (Preview)".
- The Snowflake and Oracle tutorials are still titled "(Preview)".
- `https://learn.microsoft.com/en-us/fabric/data-factory/copy-job-workspace-monitoring`
  — "Copy job produces the **CopyJobActivityRunDetailsLogs** monitoring
  table".
- `https://learn.microsoft.com/en-us/fabric/real-time-intelligence/data-activator/activator-trigger-fabric-items`
  lists Copy jobs without a preview label. Its section "## Pass
  parameter values to Fabric items (Preview)" says "Copy jobs don't
  accept parameters."

**The skill** (agent-measured):

- `SKILL.md:49` — "**CDC replication is still labelled Preview**"
- `REF:16` — the rule to hold the preview label until Learn drops it.
- `REF:26` — "| Fabric Data Warehouse | ❌ | ✅ | ❌ |"
- `REF:27` — "| Oracle (Preview) | ✅ | ❌ | ❌ |"
- `REF:30` — "| Snowflake | ✅ (own tutorial) | — | — |"
- `SKILL.md:85` — "**Only the default capture instance** is supported —
  custom SQL Server CDC capture instances aren't."
- `SKILL.md:78` — "**Job events / alerting**: `CopyJob` is a supported
  item type for Fabric **Job events**"
- `SKILL.md:3`, `:77`, `REF:13` — "**Activator (Preview)**: a Fabric
  Activator rule can run a Copy job as its action"

## What to change

1. **Matrix, `REF:18-32`.** Re-read the matrix on the `cdc-copy-job`
   page and transcribe it, with the date read. The agent did not record
   the two new rows' names, so take them from the page.
2. **Status, `SKILL.md:47, 49`.** Keep "labelled Preview", and add a
   dated note that What's New lists CDC and SCD Type 2 as GA (September
   2026) while Learn does not.
3. **Capture instances, `SKILL.md:85`.** Keep the claim, because Learn
   still states it. Add a dated note that What's New lists "SQL CDC
   custom capture names" as GA. Flip it only when Learn does.
4. **Workspace monitoring, `SKILL.md:78`.** Add the
   `CopyJobActivityRunDetailsLogs` table beside Job events.
5. **Activator, `SKILL.md:3, 77` and `REF:13`.** Drop "(Preview)" from
   the action. Keep "Copy jobs don't accept parameters".

## Constraint on the fix

- `REF:16`'s rule governs: status follows Learn, not What's New. Both
  sources are dated here so the next reader can see the conflict.
- Out of scope:
  - The audit also flagged custom staging, audit columns and Copy job
    ↔ Eventstream integration (`SKILL.md:55`). That flag is not in this
    brief's action.
  - The `writeBehavior: "Merge"` vs `"Upsert"` discrepancy is in brief
    20's incidental checks.

## Verification

1. `grep -n -i "preview\|capture instance\|CopyJobActivityRunDetailsLogs" skills/fabric/fabric-copy-job/SKILL.md skills/fabric/fabric-copy-job/references/REFERENCE.md`
   — the Activator action carries no "(Preview)". CDC and SCD Type 2
   keep it, each with a dated What's New note.
2. Diff the rebuilt matrix against the `cdc-copy-job` page row by row.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-copy-job/SKILL.md`
4. If line 3 changed: `uv run --with pyyaml scripts/skill-status.py --stale`
   and retest, or stamp the retest as owed.
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01, by the Data Factory mapping subagent. The agent noted that
Learn's index may lag What's New on several Data Factory pages, which is
why the status items are flags and not flips.
