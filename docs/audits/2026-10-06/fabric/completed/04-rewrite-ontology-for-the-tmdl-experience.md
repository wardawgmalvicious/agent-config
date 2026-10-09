# Handoff: rewrite fabric-ontology for the TMDL experience

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 4
- **Kind**: partial rewrite of a skill whose premise changed: ontology
  definitions are now TMDL, not JSON. Also one naming correction, then a
  follow-up `/drift-audit` run of the source registered for this skill.
  A `description` edit, if any, needs a retest.
- **Target**: `skills/fabric/fabric-ontology/SKILL.md` (lines 38, 68–69,
  84–101, 178, 197–200, 204), `skills/fabric/fabric-ontology/references/REFERENCE.md`
  (lines 10, 149)

## The problem

`fabric-ontology` says an ontology definition is JSON, and only JSON.
Since the new ontology experience became the default for new items, an
ontology's definition is TMDL: flat `.tmdl` files plus `.platform`. The
JSON format survives only as the "old experience", which retires on
2027-01-31. Anything the skill says about the definition layout now
describes the legacy format.

The skill was written entirely from documentation, with no local
sample, so Learn is its only ground truth. The `fabric-iq-ontology`
registry source exists for exactly this reason. The root Learn pages it
fetches now describe the new experience, and the pages the skill was
built on moved under `old-experience/`.

## Evidence

**What's New.** "Ontology new experience (preview)" was added by
`80a24c9b` (2026-09-29) and deleted by the restructure `9eda27f8`
(2026-10-02), so it is absent from the live page. "Ontology as
Real-Time Dashboard source (Preview)", "Ontology as data-agent context
(Preview)" and "Fabric IQ MCP Server (Generally Available)" were added
by `9eda27f8`.

**Learn, checked in the audit session on 2026-10-06** —
https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-definition,
titled "Ontology definition (TMDL/new experience)":

> A new experience ontology expresses its definition as **TMSL / TMDL**
> (the Analysis Services tabular-model format, plus ontology-only
> extensions) instead of the old experience's entity-type JSON. Because
> the definition is TMDL, the item plugs into the platform's
> item-definition ALM surface — **Git integration**, the Public API
> `getDefinition` / `updateDefinition`, and **Deployment Pipelines**.

> New experience ontology items support the **TMDL** format (Tabular
> Model Definition Language). The parts are flat, item-folder-relative
> `.tmdl` text files plus the platform-owned `.platform` metadata file.

The page documents a `tables/{name}.tmdl` part whose measures carry DAX
expressions. The JSON layout the skill describes now lives at
`.../definitions/ontology-old-definition`: `definition.json`,
`.platform`, `EntityTypes/{ID}/…` and `RelationshipTypes/{ID}/…`.

https://learn.microsoft.com/fabric/iq/ontology/overview:

> The new ontology experience is the default experience for new ontology
> items.

> You can't create new instances of the old ontology experience through
> the ontology interface in Fabric. It's still possible to create
> instances of the old experience by using the ontology APIs and CI/CD.

> The old experience of ontology retires on Jan 31, 2027.

Migration is a copy into a new item: agents, dashboards and other
integrations must be reconnected, and rules recreated. The old docs now
sit under `/fabric/iq/ontology/old-experience/`.

**Further facts, agent-measured on 2026-10-06:**

- Tenant settings:
  https://learn.microsoft.com/en-us/fabric/iq/ontology/overview-tenant-settings
  — "This setting is **required** to create ontology (preview) items
  with the new experience: *Users can create Fabric items*."
  `SKILL.md:204` names only the ontology setting.
- The new definition lists a `decimal` type; `SKILL.md:68-69` says
  "There is no `Decimal`".
- `concepts-generate` lost the storage-mode matrix that `SKILL.md:84-101`
  is built on.
- Real-Time Dashboards consume ontologies:
  https://learn.microsoft.com/en-us/fabric/real-time-intelligence/dashboard-supported-data-sources
  — "To connect, select **Add data source** > **Ontology**".
- `SKILL.md:197-200` carries the "Support group by in GQL" instruction
  workaround that brief 07 retires for `fabric-data-agent`. Learn's
  data-agent ontology page: "It then generates a source-native SQL, KQL,
  or DAX query, runs the query against that source, and presents the
  result."

**The Fabric IQ MCP name.** `REF:149` says "Copilot Studio reaches
ontology through the **Fabric IQ MCP (preview)** tool". The GA Fabric
IQ MCP server is a different server, for Power BI reports and semantic
models. https://learn.microsoft.com/en-us/fabric/iq/connectors/fabric-iq-mcp,
checked in the audit session: "It doesn't currently support Fabric
ontologies or data agents." The Copilot Studio how-to still says
"select **Fabric IQ MCP (Preview)**".

**Skill text** (agent-measured): `SKILL.md:38` "Ontology definitions are
JSON. Only the first two are required:"; `REF:10` "Ontology items
support the **JSON** format only."; `SKILL.md:178` "Five paths".

## What to change

1. Make the TMDL definition the primary layout: parts, `.platform`,
   `tables/{name}.tmdl`, and what Git, `getDefinition`/`updateDefinition`
   and deployment pipelines carry. Quote Learn's definition page; do not
   compose TMDL syntax the page does not show.
2. Keep the JSON layout as a clearly marked legacy section with the
   2027-01-31 retirement date. Existing items, and items created through
   the API, still use it until then.
3. `SKILL.md:68-69` — `decimal` exists in the new definition.
4. `SKILL.md:84-101` — re-derive the storage-mode guidance from the
   current pages, or mark it legacy if it described the old experience.
5. `SKILL.md:204` — add *Users can create Fabric items* for the new
   experience.
6. `SKILL.md:197-200` — retire the GQL group-by workaround in the same
   terms as brief 07.
7. Real-Time Dashboards as a consumer, wherever the skill lists them.
8. `REF:149` — separate the GA Fabric IQ MCP (Power BI) from the
   Copilot Studio ontology tool that shares the name.
9. Then run `/drift-audit --sources fabric-iq-ontology` with the floor at
   that source's last run, or at 2026-09-02 (its registration) if it has
   none. Record its findings as their own audit directory.

## Constraint on the fix

- No ontology item exists in any repo on this machine (registry note,
  re-measured 2026-09-09). Do not invent TMDL that Learn does not show:
  a first local export is the ground truth for layout.
- The registry entry's retirement rule still applies after this rewrite:
  a sample retires the layout half of that source, not the source.

## Sequencing note

Run this before brief 20, which narrows the `**/*.tmdl` activation
globs. An ontology's `.tmdl` parts are what make those globs collide,
and this brief establishes the folder layout that brief relies on.
Brief 07 rewrites the same GQL group-by paragraph in `fabric-data-agent`;
keep the two in agreement.

## Verification

1. `grep -n -i "json\|decimal\|tmdl\|old experience\|2027" skills/fabric/fabric-ontology/SKILL.md skills/fabric/fabric-ontology/references/REFERENCE.md`
   — no hit still says JSON is the only format, and the retirement date
   appears.
2. `grep -n "Fabric IQ MCP" skills/fabric/fabric-ontology/references/REFERENCE.md`
   — the Power BI server and the Copilot Studio tool are distinguished.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-ontology/SKILL.md`
4. If the `description` changed: `uv run --with pyyaml scripts/skill-status.py --stale`,
   then retest per `/test-skill` or stamp the retest as owed.
5. The `fabric-iq-ontology` audit has run, and its directory exists under
   `docs/audits/`.
6. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01, by the IQ mapping subagent. The audit session checked the
TMDL definition and the retirement date itself. The decisive row was
transient: added on 2026-09-29 and deleted on 2026-10-02, so a plain
base-to-head diff would have missed it. The `fabric-iq-ontology` source
was not selected for this run, so the page-level diff it would produce
does not exist yet.

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: `skills/fabric/fabric-ontology/SKILL.md`,
  `skills/fabric/fabric-ontology/references/REFERENCE.md`
- **Verification**: steps 1–3 and 5 passed; step 4 did not apply, as
  the `description` is unchanged; step 6 runs once at the end of the
  run. Step 1: JSON is called the only format solely inside the
  old-experience sections, and 2027-01-31 appears in both files. Step
  2: `REFERENCE.md:198-204` separates the Copilot Studio ontology tool
  from the GA Fabric IQ MCP server. Step 3: lint clean. Step 5:
  `docs/audits/2026-10-06/fabric-iq-ontology/` exists; an earlier
  session ran that audit today (`631fbee`), floor 2026-09-02, as item
  9 asks, so item 9 needed no run here.
- **Sources, re-opened 2026-10-06**: the TMDL definition page (parts
  table, the synthesized `model.tmdl` and `namespaces/default.tmdl`,
  elided defaults, `decimal` among the property `dataType`
  primitives); the ontology overview (default experience, 2027-01-31,
  copy-to-migrate); the tenant-settings page; the old-experience
  `concepts-generate` page, which holds the storage-mode matrix, and
  the new `how-to-generate-from-semantic-models` page, which has none,
  so item 4 marked the matrix legacy rather than re-deriving it; the
  Fabric IQ MCP page and the Copilot Studio how-to; the Real-Time
  Dashboard data-source pages; and the data-agent ontology page for
  item 6's quote. Every TMDL fact written is on the definition page.
- **Deferred**: the `description` still describes only the JSON
  layout. It was left alone because the brief did not target line 3 and
  the `fabric-iq-ontology` briefs 03 and 07 already edit it and share
  its retest. Learn's data-agent ontology page now carries an
  outage warning: a data agent may not be able to add a new-experience
  ontology. That belongs to brief 07 and `fabric-iq-ontology` brief 10,
  not here. Behavioural confirmation needs a fresh session:
  `/test-skill fabric-ontology` with this brief.
- **Deviations**: four, each so the new text does not contradict what
  it sits beside. (1) Both files' opening "verified on 2026-09-02"
  line gained "unless a section gives a later date". (2) Item 7: a
  Real-Time Dashboard is a consumer but not an agent, so "Five paths"
  became "Five agent paths" with the dashboard named after them. The
  `description`'s "five agent paths" therefore stays true, and "The
  last" became "The MCP path" so its referent survives. (3)
  `REFERENCE.md` §1's five JSON subsections went from `###` to `####`
  under the new legacy subsection, keeping §2–§8 numbered as the
  `fabric-iq-ontology` briefs cite them. (4) Item 5 added the second
  setting at `SKILL.md`'s tenant-settings paragraph only; renaming the
  first is `fabric-iq-ontology` brief 02's.
- **Needs**: the `fabric-iq-ontology` pass — its briefs 03 and 07
  edit the `description`; fold the TMDL layout in there and retest
  once.
- **Needs**: a fresh session, after the `fabric-iq-ontology` pass
  lands — fold the TMDL layout into the `description`, then run the
  one `/test-skill fabric-ontology` retest that pass's `description`
  edits share. This replaces the line above, which counted on that
  pass for two follow-ups none of its briefs lists. Its briefs 03, 04,
  05 and 07 edit the `description` without folding the layout in, and
  quote its current text, so folding it in first could stop them at
  the staleness gate. Its brief 10 does not list the data-agent outage
  warning the Deferred line gives it; that is now on `fabric/07`'s
  last Needs line.
- **Closed**: 2026-10-08 — landed by /triage:
  `skills/fabric/fabric-ontology/SKILL.md` § `description`, which now
  names the TMDL parts first and the JSON layout as the old
  experience's, retiring 2027-01-31. The one retest it shares with the
  `fabric-iq-ontology` pass, `/test-skill fabric-ontology`, is covered
  by `skill-status.py --stale`, which lists the skill as
  `untested-behaviour`.
