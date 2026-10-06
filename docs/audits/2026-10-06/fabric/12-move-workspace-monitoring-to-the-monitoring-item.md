# Handoff: move workspace monitoring to the monitoring item

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 14
- **Kind**: factual correction of one cross-cutting fact in three skills.
  Content only; one grep verifies all three.
- **Target**: `skills/fabric/fabric-dataflow/references/REFERENCE.md`
  (lines 212–214), `skills/fabric/fabric-mirroring/SKILL.md` (lines
  315–317), `skills/fabric/fabric-error-handling/references/REFERENCE.md`
  (line 36)

## The problem

Three skills describe workspace monitoring as a workspace-settings
toggle, *Log workspace activity*, that creates an Eventhouse. Workspace
monitoring is now managed through a **monitoring item**, and Learn
files that toggle under "Legacy". Each skill sends its reader to a
setup path Learn now calls legacy.

## Evidence

**What's New.** "Updated workspace monitoring experience (Preview)" was
added to the page's platform section by `80a24c9b` (2026-09-29) and
deleted by the restructure `9eda27f8` (2026-10-02), so it is absent from
the live page.

**Learn** (agent-measured by three subagents independently,
2026-10-06):
`https://learn.microsoft.com/en-us/fabric/fundamentals/workspace-monitoring-overview`:

> You manage workspace monitoring through a **monitoring item**.

> The monitoring item also contains an activator, Operations Agent, and
> items related to monitoring for other experiences you opt into.

The page has a "Legacy workspace monitoring" section for the old
settings toggle, and lists Warehouse query execution logs as a source.

**The skills** (agent-measured):

- `fabric-dataflow/references/REFERENCE.md:212-214` — "Enabling *Log
  workspace activity* creates an eventhouse plus a read-only KQL
  database."
- `fabric-mirroring/SKILL.md:315-317` — describes the same legacy
  toggle.
- `fabric-error-handling/references/REFERENCE.md:36` — "— Eventhouse-backed
  cross-item logs."

## What to change

In each of the three places, describe the monitoring item as the current
way to manage workspace monitoring and mark the settings toggle as
legacy. Keep anything workload-specific: the Dataflow and Mirroring
table names stay unless Learn renamed them, which this audit did not
check.

## Sequencing note

The same fact lands in brief 01 (`fabric-warehouse-monitoring`,
`REF:42-43`) and brief 06 (`fabric-eventstream`, which also changes its
table list). Use the same wording in all three briefs. Whichever runs
second reads the text the first one wrote.

## Constraint on the fix

- Don't claim the legacy toggle is gone. Learn keeps it as a documented
  legacy path.
- `fabric-operations-agent` was flagged for the Operations Agent the
  monitoring item embeds, but that flag is not in this brief's action.

## Verification

1. `grep -rn -i "Log workspace activity\|monitoring Eventhouse\|Eventhouse-backed" skills/fabric`
   — every hit outside briefs 01 and 06's targets is either rewritten
   or explicitly marked legacy.
2. Re-open the workspace-monitoring overview and confirm the quoted
   sentence.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-mirroring/SKILL.md`
4. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01. Three mapping subagents (Data Factory, warehouse/Spark, and
platform/CI-CD) found it independently in their own skills. The source
row was transient: added on 2026-09-29 and deleted on 2026-10-02.
