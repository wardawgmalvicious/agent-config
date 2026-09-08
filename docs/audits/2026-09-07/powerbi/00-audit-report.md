# Drift audit — powerbi, 2026-09-07

## Audit window

- **Floor:** 2026-08-01 (resolved from: ISO date argument)
- **Fetch path:** github-mcp — **degraded**: the registered repo no longer exists, so both documented paths failed and the diff was recovered from a pinned public fork (see finding 1). Strategy ended on a **two-ref on-disk diff** via raw URLs, not per-commit patches: the August release is a squash merge touching 30 files with a ~9 KB message, so `full_patch` would have pulled in 29 irrelevant files to read a 68-line change.
- **Sources audited:** `powerbi` — skipped: `fabric`, `vscode-agent`, `claude-code`, `fabric-iq-ontology` (not selected by `--sources`)
- **Power BI:** 3 commits in window — prior `f1f53694` → head `0e80b00b` (2026-08-25)
  - `369371ac` (2026-08-20) — August monthly release, `whats-new.md` +43/−25
  - `a154ef24` (2026-08-23) — Direct Lake calculated columns re-added, +1
  - `0e80b00b` (2026-08-25) — forum link fix, +1/−1

Two registry notes checked and still true: the page carries **zero** `#toc-hId-*` and zero `#post-...` anchors, so no stripping was needed; and it is confirmed a **single-month document** — July's rows were wholly replaced by August's, so on this source a removed row means "last month rolled off", *not* the preview→GA promotion the `table` shape contract assumes.

## Drift / gap candidates (existing artifacts)

- **`skills/workflow/drift-audit/references/sources.md`** — the `powerbi` source repo no longer resolves _(powerbi)_
  - Specific change: `MicrosoftDocs/powerbi-docs` returns **404 at the API, web UI, and raw endpoints, with no redirect** — a rename would 301, so it was deleted or made private (indistinguishable from outside). This kills **both** documented fetch paths at once: github-mcp *and* the WebFetch fallback, which builds `raw.githubusercontent.com` URLs from the same repo. Sibling `MicrosoftDocs/powerbi-docs-powershell` and `MicrosoftDocs/fabric-docs` are both 200, so the blast radius is this one source. The Learn page is alive and still advertises the dead repo as its `content_git_url`; authoring has always been in the private `powerbi-docs-pr`. Recovery used for this run: public forks survived and were reparented, and `jajin7/powerbi-docs` (created 2026-08-31, never modified) carries the upstream history — its HEAD for this file is `0e80b00b`, byte-identical to the SHA the live Learn page pins as its source commit.
  - Reference: `https://api.github.com/repos/MicrosoftDocs/powerbi-docs` → 404; `https://learn.microsoft.com/power-bi/fundamentals/whats-new` → 200
  - Proposed action: **partial rewrite** — record the takedown and pick a durable strategy. A named personal fork is fragile (can be deleted or edited); the two honest options are locating a recent unmodified fork at run time, or reading the Learn page via `microsoft-learn-mcp` and using the page's own month heading as the window, which is what the schema's `url` field already anticipates.

- **`pbir-themes`** — Modern visual defaults and Theme pane reached GA _(powerbi)_
  - Specific change: four separate claims in the `### Base Themes (April 2026)` block are now wrong. The table calls Fluent 2 **"Preview (Desktop only)"** — it is GA and the live page reads *"Applies to: ✅ Power BI Desktop and Power BI service"*. It says enable via **Options › Preview features › "Modern visual defaults and customize theme improvements"** — that toggle is gone. It lists `Classic 2026` as **"Default for new reports"** — the live table now calls Classic 2026 *"Previous default base theme"* and Fluent 2 *"Default base theme for new reports"*. And the switching path **"View › Themes › Customize current theme › Base theme dropdown"** moved to *View ribbon → toggle on the **Theme** pane → **Theme settings** → Base theme dropdown*. Also newly uncovered: an "Update to the latest base theme" banner with an **Update theme** button, a **Reset to default** tile, Theme pane sections for Filter pane / Filter cards, export-theme from the pane, and — from the What's New row — *"font overrides are removed from the base theme so the Text section now applies consistently across all visuals"*, which is a `textClasses` behavioural change this skill owns.
  - Reference: https://learn.microsoft.com/power-bi/create-reports/power-bi-reports-visual-defaults
  - Proposed action: **partial rewrite**

- **`pbir-pages`** — Fluent 2 is now the default, changing the effective new-report page size _(powerbi)_
  - Specific change: line 60 still labels it "The Fluent 2 **(preview)** base theme" and refers to the "Customize-theme dialog". The Common Page Sizes table frames 1280x720 as "Default 16:9 (Classic 2018 / Classic 2026)" — accurate per-theme, but misleading now that new reports start on Fluent 2, making **1920x1080** the effective default. The skill's other two claims here are confirmed correct upstream: initial page stays 1280x720, and existing pages don't auto-resize on a base-theme switch.
  - Reference: https://learn.microsoft.com/power-bi/create-reports/power-bi-reports-visual-defaults
  - Proposed action: **minor edit**

- **`powerbi-report-authoring`** (`references/image.md`) — OneLake file URLs as an image source _(powerbi)_
  - Specific change: the skill's data-bound image guidance is built entirely around `dataCategory: ImageUrl`. August adds OneLake file URLs as a source across the image visual, table/matrix cells, the card visual, button and list slicers, and custom icons in the Icons cell element, with Power BI authenticating on the viewer's behalf — plus reference-layer and shape-map files. A new upstream page covers it, and the release commit records a limitation worth carrying: **Publish to web and anonymous embed scenarios don't support OneLake file URLs.**
  - Reference: https://learn.microsoft.com/power-bi/visuals/power-bi-onelake-files
  - Proposed action: **minor edit**

- **`powerbi-report-authoring`** (`references/powerbi-desktop.md`) — native PBIP external-change detection vs the documented reload loop _(powerbi)_
  - Specific change: the skill documents a `powerbi-desktop reload --pid <pid>` bridge and advises reopening the PBIP when model changes aren't reflected. Desktop now **detects external changes to PBIP project files and prompts you to apply them with a single click**. Worth verifying rather than assuming: the skill's own error table already warns that a Desktop modal dialog can block bridge input, and an unattended apply-changes prompt is exactly that shape.
  - Reference: https://learn.microsoft.com/power-bi/developer/projects/projects-overview
  - Proposed action: **flag** — verify interaction before editing

- **`pbir-visual-json`** — a batch of new formatting-pane properties encodable in visual.json _(powerbi)_
  - Specific change: five August additions land on properties this skill catalogs — slicer **Single date** under Visual › Slicer settings › Selection controls; a slicer **Dropdown** section (border colour, rounded corners, open-icon colour/transparency, Accent bar) and a **Hierarchy** section for expand/collapse icon colours; matrix **expand/collapse on column headers** with customisable +/− icons under Column headers; a matrix **default freeze state** via the Row headers toggle under Layout › Freeze; **Outer padding** under Layout for bar, column, line, ribbon and waterfall charts; and a **donut chart centre value** with its own format/units/font/label options.
  - Reference: https://learn.microsoft.com/power-bi/visuals/power-bi-visualization-slicers
  - Proposed action: **minor edit**

- **`fabric-tmdl-api`** — internally inconsistent Direct Lake calculated-column claims _(powerbi)_
  - Specific change: `references/REFERENCE.md:43` asserts "(calculated columns/hybrid tables/partitions **all unsupported in DL**)", directly contradicting the same skill's `SKILL.md:68`, which correctly documents the April 2026 preview for Direct Lake on OneLake. August's re-announcement is what surfaced this; the staleness itself predates the window. The only genuinely new fact is the authoring surface — calculated columns can now be defined in **Power BI Desktop** as well as web modeling.
  - Reference: https://learn.microsoft.com/power-bi/transform-model/desktop-calculated-columns
  - Proposed action: **minor edit**

**Verified accurate — no action.** I drilled the calculated-columns page expecting drift and found none: `fabric-semantic-model-audit/references/REFERENCE.md:155` ("Preview, **User Context only**, unmaterialized — **cannot be used in relationships**") and `fabric-tmdl/references/REFERENCE.md:108` (DL on SQL still disallows them) both match the live support matrix exactly. August's "Direct Lake calculated columns (Preview)" row is a re-announcement, not a status change.

## New-skill candidates

- **Granular semantic model refresh in the Service** — fold into an existing skill; **not** a new skill. The Refresh button now offers **Refresh schema and data**, **Sync schema only**, and **Refresh data only**, and refresh can be run at table level. No local artifact covers it, but this is Service UI behaviour and the natural home is `fabric-semantic-model-audit` or a `fabric-gotchas` row, not a skill of its own.
  - Source: `powerbi` / Modeling

## MCP / tooling / CLI additions

- **No MCP changes in this window** — the August page announces no servers, endpoints, or transport changes. Both MCP templates are unaffected.
- **PBIP → VS Code entry point** — Power BI Desktop gains a built-in entry point that opens a PBIP project directly in Visual Studio Code.
  - Reference: https://learn.microsoft.com/power-bi/developer/projects/projects-overview
  - Proposed action: **flag** — tooling note only; no template or settings change implied

## No-op

- Copilot Summary / Narrative can read visuals hidden behind bookmarks (RLS and OLS still enforced)
- Fabric App consumers need only Read, not Build, on the underlying semantic model — no artifact covers app-distribution permissions
- Comments support for reports in org apps
- Azure Maps shape-matching performance and filtered-selection autozoom — no local artifact states the 30,000-point limit, so nothing is contradicted
- Power Query UI theming/accessibility and Dark Mode connector icon contrast
- Mobile: Rotate view in the report footer; export visual data to Excel
- SharePoint Online embedding row — reworded from July, not a new capability
- Retained from July: deprecation of the old file picker (October cutoff for Desktop ≤ March 2026)

## Recommended actions

1. **Repair `drift-audit`'s `powerbi` registry entry** — record that the public mirror is gone and choose a durable fetch strategy; until this is done, every future `/drift-audit --sources powerbi` fails on both documented paths.
2. **Partially rewrite `pbir-themes`** — retire the preview/Desktop-only framing, correct the default base theme, update the Theme pane workflow, and add the font-override change.
3. **Minor-edit `pbir-pages`** — drop the "(preview)" label and reframe the default page size.
4. **Minor-edit `powerbi-report-authoring`** (`image.md`) — add OneLake file URLs and the Publish-to-web / anonymous-embed limitation.
5. **Minor-edit `pbir-visual-json`** — add the six new formatting-pane properties.
6. **Minor-edit `fabric-tmdl-api`** — reconcile `REFERENCE.md:43` against `SKILL.md:68` and note Desktop authoring.
7. **Flag `powerbi-report-authoring`** (`powerbi-desktop.md`) — verify whether the native apply-changes prompt blocks the reload bridge.
8. **Fold granular refresh controls** into `fabric-semantic-model-audit` or `fabric-gotchas`.

## Next run

Pass one of these as the prior reference next time:

- Power BI head: `0e80b00b` (2026-08-25) — **caveat:** resolvable only through a fork, since the upstream repo is gone
- Or a single date: `2026-09-07`

A SHA from any registered source's repo, or any ISO date, is accepted.
