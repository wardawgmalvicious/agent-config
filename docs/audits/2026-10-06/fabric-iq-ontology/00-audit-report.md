# Drift audit — fabric-iq-ontology, 2026-10-06

## Audit window

- Floor: 2026-09-02 (resolved from: date)
- Fetch path: github-mcp — HEAD, the in-window list and the by-path diff base via `list_commits`, both directory listings via `get_file_contents` with `fields: name,size,sha`. Content strategy: **two-ref file diff** (32 commits, far past ">5"), with both refs downloaded from `raw.githubusercontent.com` at the pinned SHAs into the scratchpad and diffed on disk, so only the diffs entered context. The per-commit enumeration and file stats came from `gh api` with jq projections (same GitHub API, authenticated) because the MCP `list_commits` cannot project sub-fields of `commit` and would have returned 32 verification payloads. Phase 3 via `microsoft-learn-mcp`.
- Sources audited: fabric-iq-ontology — skipped: claude-code, fabric, powerbi, skills-for-fabric, vscode-agent (not selected by `--sources`)
- Fabric IQ ontology doc set: 32 commits in window — prior `f78e4a0e` (2026-08-31, "Standardize planning item title across Fabric documentation", the last commit touching `docs/iq/ontology/` before the floor) → head `135b0dc1` (2026-10-05). Per-commit patches were not fetched (two-ref strategy); each line carries the commit title and the files it touched under the path, with registered files in bold.
  - `135b0dc` (2026-10-05) — Document ontology RDF concept mappings (#16858): `how-to-import-export.md` +41/-2 — unregistered, not diffed
  - `9a1f0c9` (2026-10-05) — Ontology Add RTD (#16768), reverting an RTD removal: **`overview.md`** +3/-3
  - `781a9a0` (2026-10-05) — merge of main into `10-5-ontology-fixes` — listed only; the stats call returned 422 on the short SHA, and a merge's file list is main's, not the branch's
  - `a97a864` (2026-10-05) — Remove key prereq: `how-to-create-relationship-types.md` +0/-1 — unregistered, not diffed
  - `4aea681` (2026-10-05) — Update FAQ: `resources-frequently-asked-questions.yml` +2/-2 — unregistered
  - `d8cbefe` (2026-10-05) — Update billing: `resources-capacity-usage.md` +2/-2 — unregistered, not diffed
  - `1f0f572` (2026-10-01) — Billing update: `resources-capacity-usage.md` +1/-1 — unregistered, not diffed
  - `15b0269` (2026-10-01) — Update filter 2: **`overview.md`** +1/-1
  - `e79ea3c` (2026-10-01) — Update filter: **`overview.md`** +2/-2, **`resources-troubleshooting.md`** +1/-1
  - `8588cd3` (2026-10-01) — Move note: **`overview.md`** +3/-3
  - `b27934c` (2026-10-01) — Add tip box: **`overview.md`** +3/-0
  - `eac61b3` (2026-10-01) — Restructure: **`overview.md`** +7/-2
  - `a1ff6db` (2026-10-01) — Add known issues: **`overview.md`** +1/-0, **`resources-troubleshooting.md`** +2/-0
  - `12238a6` (2026-10-01) — Add troubleshooting link: **`overview.md`** +1/-0
  - `c02fe35` (2026-10-01) — Ontology add tenant settings (#16773), the tenant-setting rename across 15 files: **`overview-tenant-settings.md`** +11/-3, **`how-to-bind-data.md`** +1/-1, `how-to-generate-from-semantic-models.md` +1/-1, `how-to-use-ontology-mcp-server.md` +1/-1, 11 unregistered pages +1/-1 each
  - `8e5fefb` (2026-09-29) — [post FabCon] Expand ontology billing and capacity usage guidance (#16757): `resources-capacity-usage.md` +103/-6 — unregistered, not diffed
  - `6e9cd64` (2026-09-29) — Add tutorial detail: `tutorial-2-enrich-ontology.md` +12/-12 — unregistered
  - `7be4caf` (2026-09-29) — Remove rule line: `how-to-use-rules.md` +0/-2 — unregistered
  - `444ba38` (2026-09-29) — [post FabCon] Add SM data binding requirement, known issues (#16737): **`how-to-bind-data.md`** +5/-5, **`overview.md`** +6/-1, **`resources-troubleshooting.md`** +15/-0, `how-to-generate-from-semantic-models.md` +3/-0, `how-to-use-ontology-mcp-server.md` +3/-0, `how-to-use-ontology-agent.md` +4/-1, `old-experience/includes/old-experience-note.md` +4/-2, `tutorial-0-introduction.md` +1/-1
  - `80a24c9` (2026-09-29) — FabCon EU 2026 Release 9/28 (#16710), 780 files repo-wide; in this directory the **new-experience rewrite**: **`overview.md`** +123/-31, **`how-to-bind-data.md`** +47/-59, **`concepts-agent-integration.md`** +16/-6, **`resources-troubleshooting.md`** +61/-12, **`overview-tenant-settings.md`** +4/-2, **`concepts-generate.md`** renamed to `old-experience/concepts-generate.md` (+17/-20) with `how-to-generate-from-semantic-models.md` added (+122), `how-to-use-ontology-mcp-server.md` +7/-7, `includes/supported-property-types.md` +6/-7, `includes/refresh-graph-model.md` +1/-2; 14 pages added (`how-to-add-metadata`, `how-to-create-data-agent`, `how-to-import-export`, `how-to-reuse-properties`, `how-to-share-permissions`, `how-to-use-inheritance`, `how-to-use-metrics`, `how-to-use-namespaces`, `how-to-use-ontology-agent`, `how-to-use-ontology-graph`, `how-to-use-version-history`, `how-to-view-ontology-details`, two resources FAQs); 11 old pages copied or renamed into `old-experience/`; tutorials rewritten; ~300 media files
  - `c4a61e2` (2026-09-22) — LAA (Learn build bot, voice edits): **`how-to-bind-data.md`** +1/-1
  - `dd8ac24` (2026-09-22) — Remove outdated limit: **`how-to-bind-data.md`** +1/-1, **`resources-troubleshooting.md`** +2/-3 — the OneLake-security troubleshooting row
  - `611edf2` (2026-09-21) — Remove OLS limit: **`how-to-bind-data.md`** +1/-2
  - `118630f` (2026-09-17) — Remove data agent metrics (#16525): `how-to-add-semantic-enrichment.md` +5/-42 and four images removed — the data-agent before/after example; page since moved to `old-experience/`
  - `76e5f1a` (2026-09-15) — LAA: `how-to-add-semantic-enrichment.md` +1/-1 — unregistered
  - `5dab961` (2026-09-15) — Add data agent limitation: `how-to-add-semantic-enrichment.md` +1/-0 — unregistered
  - `a4c6543` (2026-09-11) — Update img (#16403): one tutorial image — unregistered
  - `3ff12d0` (2026-09-10) — Update capitalization: `resources-frequently-asked-questions.yml` +3/-3 — unregistered
  - `69e4e8f` (2026-09-10) — Remove preview tags for GA items: here only `resources-frequently-asked-questions.yml` +2/-2 — **no registered page touched, so no ontology GA signal**; every registered page still carries the preview banner at HEAD
  - `0ac0f42` (2026-09-09) — [SCOPED] SQL Endpoint → SQL analytics endpoint fixes (#16245), 54 files repo-wide: `how-to-create-entity-types.md` +1/-1, `resources-capacity-usage.md` +1/-1 — unregistered
  - `9fbe121` (2026-09-09) — repo sync from `repo_sync_working_branch` (#16275): **`resources-troubleshooting.md`** +1/-1
  - `170af6b` (2026-09-04) — Add known issue note: `how-to-create-relationship-types.md` +3/-0 — unregistered, not diffed
- Window diffs, base → head (all six registered files changed by blob SHA; none left undiffed): `overview.md` +138/-31 (7.7 → 16.7 KB); `concepts-generate.md` → `how-to-generate-from-semantic-models.md` +94/-40 (the old page survives at `old-experience/concepts-generate.md`, +17/-20 against base: link fixes and an old-experience banner); `how-to-bind-data.md` +49/-62; `concepts-agent-integration.md` +16/-6; `resources-troubleshooting.md` +80/-15 (7.9 → 13.8 KB); `overview-tenant-settings.md` +14/-4. Diffed **beyond** the registered `files`, because the entry names their claims as the reason it exists: `how-to-use-ontology-mcp-server.md` +10/-7, `includes/supported-property-types.md` (case-only), `includes/refresh-graph-model.md` +1/-2. Cost: ~103 KB registered + ~11 KB extras downloaded; ~94 KB of diff entered context.
- Live check: `overview-tenant-settings`, `how-to-use-ontology-mcp-server` and `how-to-add-metadata` fetched from Learn match HEAD, so the `main` content is published, not staged.

## Drift / gap candidates (existing artifacts)

- **fabric-ontology** — the doc set was rewritten for a "new experience" _(fabric-iq-ontology)_
  - Specific change: `overview.md` now documents a new ontology experience, the default for new items; the old experience "can't be created through the ontology interface" but "is still possible … using the ontology APIs and CI/CD", migrates by an in-product "create a copy in the new experience" action (consumers must be reconnected, rules and Activator alerts recreated), and **retires on Jan 31, 2027**. Old pages live on under `old-experience/` with a banner. Still preview throughout. The skill, "verified against the docs on 2026-09-02", describes the old experience in every section.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/overview
  - Proposed action: partial rewrite — but first a decision on stance (new experience primary with the old as a dated appendix until 2027-01-31, since CI/CD-created items may be either), because every bullet below depends on it
- **fabric-ontology** — tenant settings renamed and a second one required _(fabric-iq-ontology)_
  - Specific change: "Ontology item (preview)" is now **"Users can create ontology (preview) items"**, and the new experience also requires **"Users can create Fabric items"** (errors on create and on migration without it); the admin path moved to OneLake catalog › Govern › Configurations › Tenant settings. Named the old way in SKILL.md § "Before you start" and the MCP paragraph, and in REFERENCE §3, §6 (row 1) and §7. `claude/mcp/README.md` already carries the new names, so two homes now disagree.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/overview-tenant-settings
  - Proposed action: minor edit
- **fabric-ontology** — the OneLake-security exclusion was removed _(fabric-iq-ontology)_
  - Specific change: `611edf2` (2026-09-21) and `dd8ac24` (2026-09-22) dropped "do not have OneLake security enabled" from the binding prerequisites and limitations and the "Lakehouse not available as data source … OneLake security" troubleshooting row; the overview now says authoring and querying "respect access to bound data, including OneLake security and source-enforced RLS, OLS, CLS". The exclusion sits in the skill's `description` (its trigger), § "The constraints that produce silent or confusing failures", and REFERENCE §6.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/how-to-bind-data
  - Proposed action: minor edit, plus an activation retest because the `description` changes
- **fabric-ontology** — binding sources widened _(fabric-iq-ontology)_
  - Specific change: new "Supported data source types" section — eventhouse, KQL database, lakehouse, mirrored database, **semantic model** (needs Read **and Build**), SQL database, warehouse; the overview adds shortcuts, views and materialized views. The skill says "Static sources must be OneLake-backed" and time series "from lakehouse and eventhouse". The page contradicts itself: its Limitations still say "You must use OneLake-backed sources for static data."
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/how-to-bind-data
  - Proposed action: partial rewrite of § "Binding data" and the REFERENCE §2 preamble; record the contradiction rather than resolve it
- **fabric-ontology** — the binding flow and key rules changed _(fabric-iq-ontology)_
  - Specific change: the "Add static data" / "Add time series data (after binding static data)" two-visit flow is gone, with its IMPORTANT note that static must be bound first and the static value must exactly match a time-series column; the new flow adds a **secondary data source** related to the primary on a common column, suffixing duplicate column names `_2`. The "Define entity type key" and "display name property" steps are removed, the overview announces **keyless entity types** and relationships without join tables, and `how-to-create-relationship-types` had "Remove key prereq" (`a97a864`, not fetched). The one-static / many-time-series limitation survives.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/how-to-bind-data
  - Proposed action: partial rewrite of § "Binding data: the ordering and cardinality rules"
- **fabric-ontology** — generation: the storage-mode matrix moved to the old experience _(fabric-iq-ontology)_
  - Specific change: `concepts-generate.md` was renamed into `old-experience/`; its successor `how-to-generate-from-semantic-models.md` carries **no** Import / Direct Lake / DirectQuery matrix and none of the "Other limitations" (managed tables, column mapping, `Decimal`, duplicate property names, My workspace). It adds **metrics from DAX measures**, calculated columns, the Read+Build requirement, and **multiple semantic models — only through the ontology agent**. The troubleshooting page still asserts the import-mode / inbound-public-access and `Decimal` rows but links `concepts-generate.md#…`, now dangling at HEAD. SKILL.md § "Generating" and its matrix, REFERENCE §5.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/how-to-generate-from-semantic-models and https://learn.microsoft.com/fabric/iq/ontology/old-experience/concepts-generate
  - Proposed action: partial rewrite; verify whether the matrix holds for the new experience before keeping it
- **fabric-ontology** — the graph is now optional and opt-in _(fabric-iq-ontology)_
  - Specific change: overview § "Optional graph execution": "An ontology-derived schema graph doesn't load instance data by default … you can opt in to materializing … This data materialization replaces the earlier framing that presented every ontology as having an automatically materialized instance graph." The `refresh-graph-model` include now points at `how-to-use-ontology-graph`; the troubleshooting capacity row still blames the child Graph item's refresh schedule. Affects SKILL.md "Not here, deliberately", "Refresh is manual … what shows up as capacity usage", and REFERENCE §6.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/overview (drill `how-to-use-ontology-graph` in the follow-up — a new 14 KB page, not fetched)
  - Proposed action: partial rewrite
- **fabric-ontology** — a sixth consumption path: the built-in ontology agent _(fabric-iq-ontology)_
  - Specific change: `concepts-agent-integration` adds **Ontology agent** as the first table row (chat inside the item; creates, improves and tests; queries by DAX, KQL, SQL or GQL). Troubleshooting adds its behaviours: proposal-first with Plan and Act modes; runs as the user and discovers only items in the ontology's workspace or reachable by shortcut; Viewer can query and explain, Contributor+ to change; uploads capped at 5 MB per file, 10 per conversation, 60-char names; ISO GQL, not openCypher; conversation state only in the browser session during preview. SKILL.md § "Consuming" says "Five paths"; REFERENCE §3 table.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/concepts-agent-integration
  - Proposed action: minor edit
- **fabric-ontology** — semantic enrichment: page moved, cited example deleted _(fabric-iq-ontology)_
  - Specific change: `how-to-add-semantic-enrichment` moved to `old-experience/`; the successor `how-to-add-metadata` (drilled) still supports every REFERENCE §4 claim — synonyms on entity types only, keys unique per object, metadata not used in query generation, no relationship-level use by data agents. But the "ice cream shops / frozen desserts" data-agent example SKILL.md quotes was removed on 2026-09-17 (`118630f`, −42 lines, four images) and has no counterpart on the new page.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/how-to-add-metadata
  - Proposed action: minor edit — re-point §4's source, drop or replace the example
- **fabric-ontology** — new known issues for the REFERENCE §6 map _(fabric-iq-ontology)_
  - Specific change: migration to the new experience fails when the old ontology has properties "Defined at Binding" or **composite keys**; the ontology MCP server can't be accessed with a **service principal**; querying a parent entity doesn't return inheriting entities' instances; the overview now points at the Fabric known-issues site, searched for *ontology*.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/resources-troubleshooting
  - Proposed action: minor edit
- **fabric-ontology** — new modelling concepts, and the definition schema behind them _(fabric-iq-ontology)_
  - Specific change: namespaces (REFERENCE §1 allows `namespace: usertypes` only), inheritance, shared properties, metrics, natural-language rules, named version history, RDF/Turtle/OWL import and RDF/Turtle export, item sharing. These imply the REST item-definition schema moved; that page is outside this source by the entry's own note, and a Git-synced `.Ontology` created through CI/CD may now be either experience.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/overview; definition spec at https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-definition (not drilled — outside the registry)
  - Proposed action: flag — hand-check the definition page for REFERENCE §1 and the layout block in SKILL.md
- **fabric-ontology** — REFERENCE §8 "Not drilled" is stale _(fabric-iq-ontology)_
  - Specific change: `how-to-view-entity-type-details` moved to `old-experience/` (successor `how-to-view-ontology-details`); 14 new pages exist; `resources-capacity-usage` gained 103 lines of billing guidance across three commits (not fetched), which bears on the skill's "refresh schedule … shows up as capacity usage" claim.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/resources-capacity-usage (not drilled)
  - Proposed action: minor edit, with the capacity page drilled in the follow-up
- **fabric-data-agent** — two data-agent-side known issues with an ontology source _(fabric-iq-ontology)_
  - Specific change: "data agent doesn't work with an ontology that uses semantic models for binding" (known issue), and duplicate relationship names cause natural-language query errors, so names must be unique. SKILL.md line 21 carries the ontology-side behaviours (preview, first queries fail, group-by instruction) and neither of these.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/resources-troubleshooting
  - Proposed action: minor edit
- **drift-audit › `references/sources/fabric-iq-ontology.md`** — the registry entry is incomplete _(fabric-iq-ontology)_
  - Specific change: `files` names `concepts-generate.md`, now at `old-experience/` with `how-to-generate-from-semantic-models.md` as successor; the claims the entry says it exists to track live in files it omits — `includes/supported-property-types.md` (the type table; unchanged this window), `includes/refresh-graph-model.md`, `how-to-use-ontology-mcp-server.md` (the endpoint; unchanged), `how-to-add-metadata.md` (§4's source), `how-to-use-ontology-graph.md`, `resources-capacity-usage.md`; no `drill.strip` field; the "Retirement" paragraph predates the old/new split and the 2027-01-31 date; `artifacts` omits `claude/mcp/` though the project template now carries `ontology-remote-mcp`.
  - Reference: directory listings at `f78e4a0e` and `135b0dc1`
  - Proposed action: minor edit (registry)

Scanned with nothing to flag: `fabric-operations-agent` (its ontology-source limits are untouched by these pages) and `claude/rules/fabric-git-serialization.md` (its only ontology content is the `*.Ontology/**` glob).

## New-skill candidates

_(none)_

Every new capability — ontology agent, metrics, rules, namespaces, inheritance, shared properties, version history, import/export — is a facet of the one item, so each is an input to the `fabric-ontology` rewrite, not a skill. Two pointers land outside this source's `artifacts`: graph materialization (`how-to-use-ontology-graph`) touches `fabric-graph`, and ontology as a Real-Time Dashboard source touches RTI; route both by hand.

## MCP / tooling / CLI additions

- **Ontology MCP server (`…/dataPlane/workspaces/<ws>/items/<id>/ontologyEndpoint`)** — endpoint path identical at both refs (verified line-for-line; live page matches). New on the page: a known issue blocks **service-principal** access, and the prerequisites name the two renamed tenant settings. `claude/mcp/.mcp.project.template.json` already carries `ontology-remote-mcp`, and `claude/mcp/README.md` already records both the renamed settings and the service-principal issue, marked Unprobed.
  - Reference: https://learn.microsoft.com/fabric/iq/ontology/how-to-use-ontology-mcp-server
  - Proposed action: flag — no template edit; the gap is in `fabric-ontology` REFERENCE §3, covered above

## No-op

- Title case, `ms.date` and `ai-usage` frontmatter on every page
- "Fabric Graph" → "Graph in Fabric"; LAA bot voice edits (`c4a61e2`, `76e5f1a`)
- Button-label changes in the binding steps ("Add data binding" → "Add"; "Manage bindings" → "+ Add binding and properties")
- VS Code agent-mode copy and orchestrator capitalisation on the MCP page
- Data-agent setup link retargeted from tutorial-4 to `how-to-create-data-agent`
- `includes/supported-property-types.md`: case-only; the type table and key/timestamp types are unchanged
- `69e4e8f` "Remove preview tags for GA items" touched only the FAQ yml here
- SQL analytics endpoint rename sweep (`0ac0f42`), one line in two unregistered pages
- `old-experience/` copies: link-path fixes and the banner include
- Tutorials, FAQ, glossary, privacy and responsible-AI FAQs, RDF concept mappings (`135b0dc`) — unregistered, not fetched

## Recommended actions

1. **fabric-ontology SKILL.md** — decide the stance on the old/new experience split (decision, not an edit) before any rewrite below
2. **fabric-ontology** — rename the tenant settings in SKILL.md (two places) and REFERENCE §3, §6, §7
3. **fabric-ontology** — remove the OneLake-security exclusion from `description`, § constraints and REFERENCE §6; retest activation
4. **fabric-ontology** — rewrite § "Binding data": sources, primary/secondary flow, keys; reconcile with the page's own Limitations
5. **fabric-ontology** — rewrite § "Generating": metrics, calculated columns, Read+Build, multi-model via agent; re-home or verify the storage-mode matrix
6. **fabric-ontology** — rewrite the graph-refresh and capacity claims after drilling `how-to-use-ontology-graph` and `resources-capacity-usage`
7. **fabric-ontology** — add the ontology agent as the sixth path in SKILL.md and REFERENCE §3
8. **fabric-ontology** — re-point REFERENCE §4, drop the deleted example, add the §6 known issues, refresh §8
9. **fabric-ontology REFERENCE §1** — hand-check the REST definition page for namespace, inheritance, metric and rule schema changes
10. **fabric-data-agent** — add the two data-agent-side known issues
11. **drift-audit registry entry** — update `files`, add `drill.strip`, record the split and the 2027-01-31 retirement, consider `claude/mcp/` in `artifacts`

## Next run

Pass one of these as the prior reference next time:

- Fabric IQ ontology doc set head: `135b0dc1e845aa67806e89fb0a22f75879d88e55` (2026-10-05)
- Or a single date: `2026-10-06`

A SHA from any registered source's repo, or any ISO date, is accepted.
