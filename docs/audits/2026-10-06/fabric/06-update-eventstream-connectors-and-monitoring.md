# Handoff: update Eventstream connectors and monitoring

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 6
- **Kind**: partial rewrite of two claims in one skill (MQTT and mTLS,
  monitoring tables) plus status relabels and two additions in its
  references. Content; the monitoring rewrite touches KQL samples.
- **Target**: `skills/fabric/fabric-eventstream/SKILL.md` (lines 24,
  33–40, 61, 74–76, 85, 178), and under `references/`:
  `source-connectors.md` (16, 18, 24, 25), `kafka-mtls.md` (3–8),
  `activator-destination.md` (3), `monitoring.md` (16–36)

## The problem

Five parts of `fabric-eventstream` are behind:

- The skill says custom CA / mTLS works only for Kafka-family sources.
  MQTT now has its own TLS/mTLS settings, and MQTT is GA, not preview.
- The Activator destination is GA, not preview.
- Several connectors moved to GA and two new ones exist.
- Eventstream monitoring now has four tables, with different column
  names, and is opted into per eventstream rather than through a
  workspace toggle. KQL written from the skill's samples filters on a
  column Learn no longer lists.
- Two preview additions are missing: a custom connector and
  reference-data enrichment.

## Evidence

**What's New rows.**

- Added by `91e49056` (2026-09-09): "Eventstream MQTT connector
  (Generally Available)" and "Activator rules in Eventstream (Generally
  Available)", both August 2026; and "Reference data enrichment in
  Eventstream (Preview)".
- Added by `9eda27f8` (2026-10-02): "New Eventstream connectors
  (Generally Available)", September 2026; and "Eventstream processing
  logs (Preview)" and "Eventstream custom connector (Preview)". The base
  preview rows "Real-Time Intelligence Cribl source (Preview)" and
  "Solace PubSub+ Connector" are gone; they pair with the GA row.
- "Stream Mirrored Database change feeds into Eventstreams (Preview)"
  was dropped by `9eda27f8` and restored by the merge `7ff5f2b3`.

**Learn** (agent-measured, 2026-10-06; all under
`https://learn.microsoft.com/en-us/fabric/real-time-intelligence/event-streams/`):

- `add-source-mqtt` — "If your MQTT broker requires mTLS, expand
  **TLS/mTLS settings** and configure the following options as needed."
- `add-destination-activator` — "The **Rules** pane provides
  consolidated visibility for all rules in the linked Activator item
  for this Eventstream". The page carries no preview tag.
- `add-source-cribl` — "The Cribl source currently doesn't support CI/CD
  features, including **Git Integration** and **Deployment Pipeline**."
  The MongoDB page says the same.
- `add-source-sap-datasphere` — "creates an eventstream source and a
  Kafka endpoint".
- `add-manage-eventstream-sources` still lists "Mirrored Database Change
  Feed (preview)". `/fabric/mirroring/extended-capabilities` still says
  "Delta change data feed (preview)".
- `fabric-workspace-monitoring` — "Eventstream monitoring provides four
  tables in the workspace monitoring database."
  - It adds `EventStreamDiagnosticLogs`, and lists `ItemId` / `ItemName`
    columns, not `ArtifactId`.
  - "**Log Eventstream activity** is enabled for each eventstream.
    Enabling workspace monitoring for the workspace doesn't
    automatically enable activity logging for eventstreams."
- `/fabric/fundamentals/workspace-monitoring-overview` — "You manage
  workspace monitoring through a **monitoring item**." It labels the
  **Log workspace activity** setting "Legacy".
- `add-custom-stream-connector` — "use a custom stream connector to
  upload a Kafka Connect source connector plugin"; "Sources on private
  networks, including virtual networks and on-premises networks, aren't
  supported."
- `enrich-events-with-reference-data` — "select **Add source** >
  **Reference data sources**."; "Eventstream uses Delta tables stored in
  Microsoft Fabric Lakehouse as the reference dataset."

**The skill** (agent-measured):

- `SKILL.md:40` "MQTT (preview)"; `source-connectors.md:25` "**MQTT
  (preview)**"
- `SKILL.md:38` "Custom CA / mTLS GA July 2026 — Kafka-family only";
  `kafka-mtls.md:3-4` "Applies to the Kafka-protocol sources only";
  `kafka-mtls.md:8` "Don't read GA as having widened the connector set."
- `SKILL.md:61` "## Activator destination (preview)";
  `activator-destination.md:3` "Preview."
- `SKILL.md:35-36, 39` and `source-connectors.md:16, 18, 24` — "MongoDB
  (preview)", "Mirrored Database (preview, April 2026)", "Solace
  PubSub+". There are no Cribl or SAP Datasphere rows.
- `SKILL.md:74-76` — "**Log workspace activity** auto-creates a
  monitoring Eventhouse with three Eventstream tables"; `SKILL.md:85` and
  `monitoring.md:16, 21, 28, 36` filter on `ArtifactId`; `SKILL.md:178`
  — "full diagnostic logs are planned".
- `SKILL.md:24` — "**Transformations** = inline filter / aggregate /
  GroupBy / Manage Fields / SQL."

## What to change

1. **MQTT and mTLS** — `SKILL.md:38, 40`, `source-connectors.md:25` and
   `kafka-mtls.md:3-8`. MQTT is GA and has TLS/mTLS settings, so the
   "Kafka-family only" scope no longer holds as stated. Keep what the
   mTLS reference says about Kafka sources; it was measured. Narrow its
   exclusivity claim.
2. **Activator destination** — `SKILL.md:61` and
   `activator-destination.md:3`: GA.
3. **Connectors** — `SKILL.md:35-39` and `source-connectors.md`:
   - MongoDB and Solace PubSub+ are GA.
   - Add Cribl and SAP Datasphere, with the Cribl/MongoDB CI/CD
     limitation.
   - **Hold** the Mirrored Database row as preview while Learn's
     source list still says so.
4. **Monitoring** — `SKILL.md:74-76, 85, 178` and `monitoring.md`:
   - four tables, including `EventStreamDiagnosticLogs`;
   - per-eventstream opt-in;
   - the monitoring item replacing the legacy toggle;
   - `ItemId` / `ItemName` columns.
5. **Additions** — a custom connector row in the sources table (preview,
   no private-network sources) and a reference-data source node in the
   transformations line (preview, Lakehouse Delta tables).

## Constraint on the fix

- Confirm the column names against a live workspace monitoring database
  before rewriting the KQL in `monitoring.md`. If none is reachable,
  change the prose, mark the samples unmeasured against the new schema,
  and date that.
- The workspace-monitoring fact also lands in brief 01
  (`fabric-warehouse-monitoring`) and brief 12 (three Data Factory and
  error-handling skills). Keep the wording consistent across them.

## Verification

1. `grep -rn -i "MQTT\|Kafka-family\|Kafka-protocol\|Activator destination (preview)\|ArtifactId\|three Eventstream tables" skills/fabric/fabric-eventstream`
   — no hit still says MQTT or the Activator destination is preview,
   or that mTLS is Kafka-only, and every `ArtifactId` that survives was
   checked.
2. `grep -rn -i "Mirrored Database" skills/fabric/fabric-eventstream`
   — still marked preview, with a dated note.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-eventstream/SKILL.md`
4. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01, by the Real-Time Intelligence mapping subagent, which read
every page quoted above. The audit session did not re-check them. The
Mirrored Database hold exists because What's New and Learn disagree,
and Learn is the source the skill transcribes.

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: `skills/fabric/fabric-eventstream/SKILL.md`, and
  under its `references/`: `source-connectors.md`, `kafka-mtls.md`,
  `activator-destination.md`, `monitoring.md`
- **Verification**: steps 1–3 passed; step 4 runs once at the end of
  the run. Step 1: no hit calls MQTT or the Activator destination
  preview, and none calls mTLS Kafka-only. Each surviving
  `ArtifactId` was checked: two are dated history, one is the
  instruction to swap it, and three are the samples the constraint
  keeps, marked unmeasured. Step 2: the Mirrored Database rows in
  `SKILL.md` and `source-connectors.md` stay preview, each with the
  dated What's New/Learn disagreement. Step 3: lint clean.
- **Learn, re-read 2026-10-06** (the audit session had not): Eventstream
  workspace monitoring (four tables, `ItemId`/`ItemName`/`ItemKind`,
  per-eventstream **Log Eventstream activity**); `add-source-mqtt` (no
  preview text, its own **TLS/mTLS settings**);
  `add-destination-activator` (no preview text, the Rules-pane
  sentence as quoted); Cribl's and MongoDB CDC's CI/CD limitation;
  `add-custom-stream-connector` (preview, source plugins only, no
  private-network sources); `enrich-events-with-reference-data`
  (preview, Lakehouse Delta tables); and the source list in
  `add-manage-eventstream-sources`.
- **Deferred**: the constraint's live check. No workspace monitoring
  database was reachable, so the prose changed and the three KQL
  samples in `monitoring.md` still filter on `ArtifactId`, marked
  unmeasured against the new schema with a `getschema` step. Adjacent,
  not fixed: the gotcha "Monitoring tables don't appear after enabling"
  (`SKILL.md:174`) still prescribes the legacy toggle, where the
  per-eventstream opt-in is now the likelier cause; the `description`
  names three tables, not four. Learn's monitoring page itself still
  opens by saying workspace monitoring "automatically creates an
  eventhouse in your workspace", so it is only partly updated.
  Behavioural confirmation, including the routing retest the
  `description` edit owes, needs a fresh session.
- **Deviations**: three. (1) MQTT: the brief makes it GA, but Learn's
  source list still reads "MQTT (preview)". That is the same
  disagreement the brief holds Mirrored Database for. Its own page
  carries no preview text and What's New dates GA to August 2026, so
  MQTT was written as GA, with the list's label recorded and dated
  beside it in both files. (2) Step 1's grep covers the `description`,
  so its "filter by ArtifactId not name" became "filter by ID not
  name". (3) The custom connector went into `source-connectors.md` as
  well as the `SKILL.md` sources table, since that file is the
  exhaustive list. The gotcha naming `ArtifactName`/`ArtifactId`
  (`SKILL.md:183`) was renamed to the `Item*` columns, for step 1's
  check.
- **Needs**: tenant, a fresh session — a workspace monitoring database
  with Eventstream logging on, to confirm `ItemId` against `ArtifactId`
  and rewrite the three samples; then `/test-skill fabric-eventstream`
  for the routing retest.
