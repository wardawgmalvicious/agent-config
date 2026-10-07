# Handoff: apply the Real-Time Intelligence edits and flags

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 17
- **Kind**: minor edits and flags across four Real-Time Intelligence
  skills. Each skill is independent of the others. Content only. Treat
  each D-section as its own task.
- **Target**: `skills/fabric/fabric-eventhouse/` (`SKILL.md` lines 200;
  `references/REFERENCE.md` lines 29, 75), `skills/fabric/fabric-activator/SKILL.md`
  (lines 273–274, 338, 350), `skills/fabric/fabric-realtime-dashboard/SKILL.md`
  (lines 28, 39, 55, 79–82, 95–97), `skills/fabric/fabric-event-schema-set/SKILL.md`
  (lines 335–336)

## Context

All four skills cover Real-Time Intelligence. One subagent drilled every
entry against Learn, and all quotes below are its own (2026-10-06); the
audit session did not re-check them. Two items are edits (D-1, D-4).
The rest are flags, where Learn either contradicts itself or doesn't
document the new behaviour.

## D-1 — Eventhouse: update policies and monitoring logs

**Symptom.** `fabric-eventhouse/references/REFERENCE.md:29` lists
query-acceleration limitations: "query limitations (no cross-eventhouse,
no external data, no plugins)". `REF:75` names five log tables: "Metrics
/ Command logs / Data operation logs / Ingestion results / Query logs
tables."

**Evidence.** Two What's New preview rows were added by `9eda27f8`:
"Update policies on accelerated shortcuts (Preview)" and "Eventhouse
workspace-monitoring logs (Preview)". The Kusto page
https://learn.microsoft.com/kusto/management/update-policy?view=microsoft-fabric
says: "Update policy over external delta tables (preview)… the `Source`
of an update policy can be an external table, provided that:… The
external table has a query acceleration policy enabled." However,
https://learn.microsoft.com/fabric/real-time-intelligence/query-acceleration-overview
still says "update policies aren't supported". The monitoring page
https://learn.microsoft.com/en-us/fabric/real-time-intelligence/monitor-eventhouse
adds capacity throttling logs, sub-optimal size logs and scale-out event
logs.

**Fix.** Add the preview update-policy source, citing the Kusto page,
and note that the query-acceleration overview still disagrees. Add the
three log tables to `REF:75`.

## D-2 — Eventhouse: granular shortcut-database sharing (flag)

**Symptom.** The access model at `fabric-eventhouse/SKILL.md:200` has no
shortcut-database sharing.

**Evidence.** What's New `9eda27f8` added "Granular shortcut-database
sharing (Generally Available)". Learn,
https://learn.microsoft.com/fabric/onelake/onelake-shortcuts: "you can
choose to include all subitems from the source database or select
specific subitems to share".

**Fix.** Flag only. Add one line if it fits the access-model section.

## D-3 — Activator: Teams channels (flag)

**Symptom.** `fabric-activator/SKILL.md:273-274` says Teams "**channels
are not supported at all**, private channels included".

**Evidence.** What's New `91e49056` added "Fabric Activator integration
with warehouse SQL queries (Preview)". Its Learn page,
https://learn.microsoft.com/en-us/fabric/real-time-intelligence/data-activator/set-alerts-warehouse-sql-query,
says "If you selected the **Channel post** option, select a **team** and
a **channel**." But `activator-limitations` still says "Teams channels
aren't currently supported."

**Fix.** Flag only. Learn contradicts itself, so record both pages with
the date; don't flip the claim. `SKILL.md:178` already lists the
warehouse source, so the source itself needs no edit.

## D-4 — Activator: stateful conditions

**Symptom.** `fabric-activator/SKILL.md:338` says "Use `BECOMES` /
`INCREASES` / `DECREASES`"; `:350` repeats the same three.

**Evidence.** What's New `9eda27f8` added "Activator stateful conditions
(Generally Available)". Learn,
https://learn.microsoft.com/en-us/fabric/real-time-intelligence/data-activator/activator-rules-overview:
"stateful expressions like `BECOMES`, `DECREASES`, `INCREASES`, `EXIT
RANGE`, or absence of data (heartbeat)".

**Fix.** Add `EXIT RANGE` and absence of data (heartbeat).

## D-5 — Real-Time Dashboard: four flags

**Symptom and evidence**, in the order of the What's New rows:

- **"Fabric Maps in Real-Time Dashboards (Preview)"** (added `ecb721f5`).
  Learn,
  https://learn.microsoft.com/fabric/real-time-intelligence/dashboard-real-time-create:
  "a Fabric Maps tile embeds a pre-authored, multi-layer map item as-is";
  "the dashboard references it by item ID". A Maps tile has no query,
  which breaks the skill's rules at `SKILL.md:28` ("All KQL text lives
  in `queries[]`; everything else points at it") and `:55` ("Every
  `queryId` referenced exactly once"). The tile's JSON shape is
  undocumented.
- **"Ontology as Real-Time Dashboard source (Preview)"** (added
  `9eda27f8`). Learn,
  https://learn.microsoft.com/en-us/fabric/real-time-intelligence/dashboard-supported-data-sources,
  lists Eventhouse, Ontology, Azure Data Explorer, Application Insights
  and Log Analytics as sources. `SKILL.md:39` documents only
  `kind: "kusto-trident"`. The `dataSources[].kind` value for a non-KQL
  source has not been checked against a real dashboard.
- **"Richer Real-Time Dashboard visuals (Generally Available)"** (added
  `9eda27f8`). Learn,
  https://learn.microsoft.com/en-us/fabric/real-time-intelligence/dashboard-visuals-customize,
  lists reference lines on Anomaly chart, Area chart, Bar chart, Column
  chart, KPI, Multi Stat, Scatter chart and Time chart. That doesn't
  settle `SKILL.md:95-97` ("`kpi__referenceLines` take **static numbers
  only**").
- **"Real-Time Dashboard AI custom visual builder (Preview)"** (added
  `9eda27f8`). Drill failed: the entry's fwlink (LinkId=2379610) lands
  on "Generate Real-Time dashboards with Copilot", and search found no
  custom-visual page. `SKILL.md:79-82` holds the visual-type list.

**Fix.** Flag only. Add a dated note for each beside the line it
qualifies. Don't invent JSON for the Maps tile or the ontology data
source.

## D-6 — Event Schema Set: registry GA (flag)

**Symptom.** `fabric-event-schema-set/SKILL.md:335-336` lists business
events (`eventTypeCategory` `BusinessEventType`) as untested. The skill
makes no status claim that needs flipping.

**Evidence.** What's New `9eda27f8` added "Event Schema Registry
(Generally Available)", which pairs the base preview row "Schema
Registry (Preview)". Learn,
https://learn.microsoft.com/en-us/fabric/real-time-intelligence/schema-sets/schema-registry-overview:

- "Schema Registry also manages any schemas that you create as part of
  Business Events."
- "These roles use a deny-by-default model."
- "Role in schema-aware Eventstreams (Preview)".

**Fix.** Flag only. Record the GA and the Business Events link beside
the untested-business-events note.

## Constraint on the fix

- The Event Schema Set skill has open checks in another repo's inbox,
  sent there on 2026-10-01. Don't resolve "untested" from documentation
  alone.
- Out of scope: the mapping agent also noted that Learn headlines
  Activator's parameter passing as "(Preview)", which the skill doesn't
  label. That note was not in the audit report.

## Verification

1. `grep -n -i "update polic\|throttling\|scale-out" skills/fabric/fabric-eventhouse/references/REFERENCE.md`
2. `grep -n "EXIT RANGE\|heartbeat" skills/fabric/fabric-activator/SKILL.md`
3. Each D-2, D-3, D-5 and D-6 flag appears as a dated note beside the
   line it qualifies.
4. `uv run --with pyyaml scripts/lint-frontmatter.py` on each edited
   `SKILL.md`.
5. `pre-commit run --all-files`

## Provenance

Found by the Real-Time Intelligence mapping subagent during the
2026-10-06 `/drift-audit` run against `fabric` (floor 2026-09-01). Learn
contradicts itself on update policies (D-1) and on Teams channels
(D-3); both flags exist to preserve that disagreement rather than pick
a side.

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: `skills/fabric/fabric-eventhouse/SKILL.md`,
  `skills/fabric/fabric-eventhouse/references/REFERENCE.md`,
  `skills/fabric/fabric-activator/SKILL.md`,
  `skills/fabric/fabric-realtime-dashboard/SKILL.md`,
  `skills/fabric/fabric-event-schema-set/SKILL.md`
- **Verification**: steps 1–4 passed; step 5 runs once at the end of
  the run. Step 1: `update polic` hits `REF:29`, and `throttling` and
  `scale-out` hit `REF:75`. Step 2: `EXIT RANGE` and `heartbeat` hit
  `SKILL.md:342,356,358`. Step 3: D-2 sits after the access-model line;
  D-3 closes the recipients paragraph; D-5's four notes close the
  `dataSources[]` bullet, follow the `queryId` rule, follow the visual
  list and close the `kpi` bullet; D-6 closes the untested-edge bullet.
  Each is dated. Step 4: lint clean on all four; no `description`
  changed.
- **Learn, read 2026-10-06**: a subagent fetched every page the brief
  cites, quoting verbatim: the Kusto `update-policy` page (Fabric view),
  `query-acceleration-overview`, `monitor-eventhouse`,
  `onelake-shortcuts`, `set-alerts-warehouse-sql-query`,
  `activator-limitations`, `activator-rules-overview`,
  `dashboard-real-time-create`, `dashboard-supported-data-sources`,
  `dashboard-visuals-customize`, `schema-registry-overview`, and What's
  New for the status rows. Every quote in the brief matched. Sixteen
  searches found no page for the AI custom visual builder.
- **Deferred**: no behavioural confirmation; an edited `SKILL.md` does
  not reliably reload mid-session on Windows, so a fresh session would
  exercise it. One adjacent finding: `fabric-eventhouse` `REF:29`'s "no
  external data" misses a GA exception, July 2026 per What's New. An
  update policy query can read an accelerated external table through
  `external_table()` when its `Hot` period covers all data
  (`Hot` >= 100 years). D-1 added only the preview `Source` change.
- **Deviations**: one, in D-4. `:350` doesn't repeat the three
  operators, as the brief says; it reads "Prefer stateful operators"
  and has done so since before the audit. The full stateful list went
  there. `:338`, a fix for alert spam, gained `EXIT RANGE` only, since
  absence of data is no cure for spam; its heartbeat rule already sat at
  `:352`.
- **Needs**: the next `fabric` audit — `fabric-eventhouse` `REF:29`'s
  missing GA exception for accelerated external tables in update policy
  queries.
