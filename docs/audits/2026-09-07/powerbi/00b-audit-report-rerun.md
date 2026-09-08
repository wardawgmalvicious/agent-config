# Drift audit — powerbi, 2026-09-07 (second run)

## Audit window

- **Floor:** 2026-08-01 (resolved from: explicit ISO date argument)
- **Fetch path:** registry-defined override for `powerbi` — Learn `git_commit_id` → verified fork → `github-mcp`, then a **two-ref file diff** after the § 4a step-5 escape hatch (see note below)
- **Sources audited:** `powerbi` — skipped: `fabric`, `vscode-agent`, `claude-code`, `fabric-iq-ontology` (narrowed by `--sources`)
- **Power BI What's New:** 3 commits in window — prior `443eb78f` → head `0e80b00b` (2026-08-25)

Three notes on how this run resolved, since the `powerbi` entry is young:

**The fork route held on a second window.** Learn's `git_commit_id` gave `0e80b00bf4b83809178cdce6b055171e9e0c9604`. Anchoring the search at the floor (`created:>=2026-08-01`) returned 7 repos; the exact-name rule dropped both `powerbi-docs-powershell` hits (the substring trap the registry warns about, and it fired twice this run). Two independent forks — `jajin7` and `bsnyder9` — agreed on the SHA, so the redundancy the registry claims is real. `jajin7` was taken. HEAD's commit date (2026-08-25T16:26Z) also reconciles with Learn's `updated_at` (17:13Z), a second confirmation the mirror is clean.

**The escape hatch was needed, and the commit count was the wrong proxy.** 3 commits is well under the ">5" line that selects per-commit patches, but sizing first showed `369371ac` is a squashed monthly release merge — 624 additions / 298 deletions across many files, with a ~10 KB commit message alone. Pulling `full_patch` would have dragged the whole release in to read one page. Switched to a two-ref diff on the single path per § 4a step 5.

**Anchor stripping:** the registry's 2026-08-29 observation still holds — this page carries zero `#post-...` anchors, and its one community-blog link is unanchored. Nothing needed stripping.

**Shape note:** the single-month rule applied exactly as the registry predicts. July's page carried 19 rows, August's carries 23; **16 rows rolled off** and are *not* GA promotions. One genuine preview→GA transition is visible precisely because both months sit inside this window (modern visual defaults), and it is reported as such below.

## Drift / gap candidates (existing artifacts)

- **`skills/powerbi/pbir-themes`** — Modern visual defaults + Theme pane reach GA _(powerbi)_
  - Specific change: `SKILL.md:34-44` states `Fluent 2` is **"Preview (Desktop only)"** and `Classic 2026` is **"Default for new reports"**. Both are now wrong: Fluent 2 is the default base theme for new reports in **Desktop *and* the service**, and Classic 2026 is documented as "previous default". The enablement instruction — *Options › Preview features › "Modern visual defaults and customize theme improvements"* — describes a toggle that no longer exists. The switching path also moved: the skill's *View › Themes › Customize current theme › Base theme dropdown* is now **View ribbon › toggle on the Theme pane › Theme settings › Base theme**.
  - Reference: https://learn.microsoft.com/en-us/power-bi/create-reports/power-bi-reports-visual-defaults
  - Proposed action: partial rewrite (status table, enablement path, and the line 44 navigation sentence)

- **`skills/powerbi/pbir-themes`** — Theme pane replaces the Customize-theme dialog _(powerbi)_
  - Specific change: theme customization is now a pane with fixed sections — **Theme settings, Colors, Text, Visual properties, Page, Filter pane, Filter cards** — and import/export/remove live under Theme settings rather than a dialog. New "Update to the latest base theme" flow (banner + **Update theme**), plus a **Reset to default** tile whose scope is documented (removes custom theme, does *not* touch per-visual formatting). The whats-new row adds that **font overrides were removed from the base theme**, so the Text section now applies consistently across visuals — relevant to the skill's `textClasses` guidance.
  - Reference: https://learn.microsoft.com/en-us/power-bi/create-reports/power-bi-reports-visual-defaults
  - Proposed action: partial rewrite

- **`skills/powerbi/pbir-pages`** — Fluent 2 page-size note carries a stale preview label and an unsupported carve-out _(powerbi)_
  - Specific change: `SKILL.md:54-60` labels the theme "Fluent 2 (preview)" and asserts *"Initial page in a report stays 1280x720"*. The GA doc says only that **existing reports and existing pages** don't change size, and that new reports use Fluent 2 by default — it carries no initial-page exception. The 1920x1080 new-page default itself is confirmed.
  - Reference: https://learn.microsoft.com/en-us/power-bi/create-reports/power-bi-reports-visual-defaults
  - Proposed action: minor edit — drop "(preview)"; re-verify the initial-page claim against a real new report before keeping it

- **`skills/powerbi/pbip-project-structure`** — documented workaround is now obsolete _(powerbi)_
  - Specific change: `SKILL.md:213` prescribes *"PBI Desktop ignores external edits → Stale in-memory state → **Close and reopen Desktop**"*. Power BI Desktop now **detects changes to project files and prompts to apply them with a single click**, stated twice on the page (Model authoring, and the FAQ). The PBIX/PBIP table at `SKILL.md:139` can also note the **built-in entry point that opens the project directly in VS Code**. PBIP itself remains **preview** and still requires the *Power BI Project (.pbip) save option* preview toggle.
  - Reference: https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview
  - Proposed action: minor edit (correct the remedy; add the VS Code entry point)

- **`skills/powerbi/powerbi-report-authoring` (`references/image.md`)** — OneLake file URLs as an image source _(powerbi)_
  - Specific change: `image.md` currently covers only `dataCategory: ImageUrl` plus local-file/web-URL sources. OneLake files are now a first-class source across image visual, card visual (image / callout image / category-header background), table–matrix–slicer–multi-row card, Azure Maps marker layers (**SVG only**), and shape-map custom maps (TopoJSON/GeoJSON). URL form is `https://onelake.dfs.fabric.microsoft.com/<workspace-guid>/<item-guid>/Files/<path>/<file-name>`; Power BI loads it under **each viewer's Entra identity**, so viewers need Read on the lakehouse item *and* OneLake Read on the folder. Two limits worth carrying: **Publish to web and anonymous embed can't use OneLake URLs at all**, and supported formats are BMP/JPG/JPEG/GIF/PNG/SVG.
  - Reference: https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-onelake-files
  - Proposed action: partial rewrite of the image-source section

- **`skills/powerbi/pbir-conditional-formatting`** — custom icons from a URL _(powerbi)_
  - Specific change: conditional formatting now supports a **custom icon from a URL**, including OneLake image URLs, via an image-URL column in the Icons cell element — a source the skill's `icon` block coverage doesn't mention.
  - Reference: https://learn.microsoft.com/en-us/power-bi/create-reports/desktop-conditional-table-formatting#use-a-custom-icon-from-a-url
  - Proposed action: minor edit

- **`skills/fabric/fabric-cicd`** — deployment pipelines don't rewrite OneLake image URLs _(powerbi)_
  - Specific change: a report deployed to a new stage **keeps referencing files in the original workspace**; the fix is parameters or a post-deployment URL update. This is a stage-promotion correctness trap and the skill already owns the deployment-pipeline vs Git-deploy decision at `SKILL.md:23-25`, but carries nothing about unrewritten asset URLs.
  - Reference: https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-onelake-files
  - Proposed action: minor edit (add to the pipeline caveats)

- **`skills/powerbi/powerbi-report-authoring` (`references/cartesian.md`)** — new Outer padding, renamed spacing settings _(powerbi)_
  - Specific change: **Outer padding** is a new setting under **Layout** for column, bar, clustered, line, ribbon and waterfall charts — space between the plot-area edges and the first/last category; **Outer padding + Space between categories both at 0%** fills the plot area. *Category spacing* and *Series spacing* were renamed **Space between categories** / **Space between series**, and **Overlap series** is scoped to bar and column charts. `cartesian.md` and `powerbi-report-design/assets/base.json` both encode `innerPadding` literals.
  - Reference: https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-visualization-customize-x-axis-and-y-axis
  - Proposed action: flag — the Learn page is UI-facing and names **no** JSON property for Outer padding; confirm the PBIR/theme property name against a real export before encoding it

- **`skills/powerbi/pbir-visual-json`** — matrix header and freeze properties _(powerbi)_
  - Specific change: matrix coverage here is limited to column widths (`SKILL.md:165`). Now documented: **+/- icons on column headers as well as rows** (format pane, `Row headers` / `Column headers` › `+/- icons`), an **Auto expand** toggle under each `› Options`, and — the persistence-relevant one — the **default freeze state for row headers** set via `Layout › Freeze › Row headers` and **saved with the report** (right-click freeze stays transient/per-session). The embedded Authoring SDK exposes this as an `autoExpand` property on the `rowHeaders` and `columnHeaders` objects, which is the only property name Learn actually spells out.
  - Reference: https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-visualization-matrix-visual
  - Proposed action: minor edit

- **`skills/powerbi/powerbi-report-authoring` (`references/slicers.md`)** — Date picker GA plus new formatting sections _(powerbi)_
  - Specific change: Date picker is GA, with a new **Single date** setting under `Visual › Slicer settings › Selection controls` that restricts the slicer to one date and also constrains the relative options; selections can be cleared from a header icon. New **Dropdown** section (border color, rounded corners, open-icon color/transparency, Accent bar) and a new **Hierarchy** section (expand/collapse icon colors). `slicers.md` documents `'Between'` / `'Relative'` modes and sizing but no single-date mode.
  - Reference: https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-visualization-slicers
  - Proposed action: flag — the detail lives on `power-bi-visualization-slicer-visual`, not the overview I drilled; confirm the mode/property encoding there before editing

- **`skills/powerbi/pbir-bookmarks`** — Copilot now reads visuals hidden by bookmarks _(powerbi)_
  - Specific change: Copilot Summary and the Copilot Narrative visual now read visuals **hidden by default and revealed by a display-only bookmark** (RLS/OLS still enforced). The skill treats per-visual `display.mode: hidden` as the visibility toggle; that state no longer implies the visual is excluded from AI summarization, which matters for the hide-and-reveal bookmark patterns it documents.
  - Reference: https://learn.microsoft.com/en-us/power-bi/explore-reports/copilot-pane-summarize-content
  - Proposed action: flag (one-line caveat)

- **`skills/fabric/fabric-tmdl-api`** — Direct Lake calculated columns gain a web-modeling surface _(powerbi)_
  - Specific change: additive only. I drilled the support matrix and it is **unchanged** — Direct Lake on OneLake is still *User Context only, unmaterialized (preview), unusable in relationships*, and Direct Lake on SQL still N/A, exactly as `fabric-tmdl-api/SKILL.md:68` and `fabric-semantic-model-audit/references/REFERENCE.md:155` already state. The only delta is the whats-new row's claim that columns can now be defined **in web modeling** as well as Desktop, which the Desktop-scoped doc page doesn't cover.
  - Reference: https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-calculated-columns
  - Proposed action: flag — low priority; existing claims are accurate, so this is a one-line surface addition at most

## New-skill candidates

- **Granular semantic model refresh controls** — likely **not** a skill; no artifact covers it and none obviously should. The **Refresh** button now offers *Refresh schema and data*, *Sync schema only*, and *Refresh data only*, with table-level refresh. It's a service-UI capability with no authoring or file surface, which is what this repo's skills are built around. Recorded so a later run doesn't rediscover it as novel.
  - Source: powerbi / Modeling

## MCP / tooling / CLI additions

- **`pbir` CLI → Power BI Desktop round-trip** — no CLI change, but the external-edit loop the CLI sits in got shorter: Desktop now detects project-file changes and prompts to apply, rather than requiring a restart. `pbir-report-workflow` guidance around `pbir open` is worth re-reading against that.
  - Reference: https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview
  - Proposed action: flag — no template change
- **No MCP changes in window.** No server, transport, endpoint or authentication change appeared in this source; both MCP templates are untouched by this audit.

## No-op

- Azure Maps reference-layer shape-matching performance (no configuration change)
- Azure Maps filtered-selection reload and autozoom past the 30,000-point limit
- Power Query UI theming/contrast improvements; connector icons get a white background in Dark Mode
- Mobile: **Rotate view** button in the report footer
- Mobile: export visual data to Excel (iOS/Android)
- Comments on report pages and visuals in org apps
- Fabric Apps consumers need only Read (not Build) on the underlying semantic model — real permission-model change, but no artifact covers Fabric Apps consumption
- Third-party custom visuals; SharePoint Online embedding (both carried from July, substance unchanged)
- Deprecation of the old file picker (carried from July, unchanged)
- 16 July rows rolled off the single-month page — month rollover, **not** GA promotions

## Recommended actions

1. Rewrite the base-theme status table and enablement/navigation paths in **`pbir-themes`** — highest-confidence drift; the skill names a preview toggle that no longer exists.
2. Correct the obsolete "Close and reopen Desktop" remedy in **`pbip-project-structure`** and add the VS Code entry point.
3. Extend **`powerbi-report-authoring/references/image.md`** with the OneLake image-source model, URL format, viewer-permission requirement, and the publish-to-web exclusion.
4. Add the deployment-pipeline URL-rewriting caveat to **`fabric-cicd`**.
5. Drop the "(preview)" label in **`pbir-pages`** and re-verify the "initial page stays 1280x720" carve-out against a real new report.
6. Add the custom-icon-from-URL source to **`pbir-conditional-formatting`**.
7. Verify the Outer-padding JSON property name against a real export, then update **`cartesian.md`** and **`powerbi-report-design/assets/base.json`**.
8. Drill `power-bi-visualization-slicer-visual`, then update **`slicers.md`** for Date picker GA and the Single date setting.
9. Add matrix column-header `autoExpand` and the persisted row-header freeze default to **`pbir-visual-json`**.
10. Add a one-line Copilot-reads-hidden-visuals caveat to **`pbir-bookmarks`**.

## Next run

Pass one of these as the prior reference next time:

- Power BI What's New head: `0e80b00bf4b83809178cdce6b055171e9e0c9604` (2026-08-25)
- Or a single date: `2026-09-07`

A SHA from any registered source's repo, or any ISO date, is accepted.

---

## Post-report note — not part of the report format

Retained here because it would otherwise be lost with the transcript, and
it bears on the registry entry that brief `01` repaired earlier the same
day. Clearly separated so the report above stays verbatim.

Two things worth folding into `skills/workflow/drift-audit/references/sources.md`
when it is next touched:

- The fork route **worked a second time**, on a second window, run
  literally against the hardened rule rather than improvised. The
  exact-name guard earned its place — it fired twice in this run,
  dropping both `powerbi-docs-powershell` hits. Two independent forks
  (`jajin7`, `bsnyder9`) agreed on the Learn `git_commit_id`, so the
  redundancy the entry claims is real rather than theoretical.
- The entry's implied "3 commits → per-commit patches" reading is
  **misleading for this source**. Power BI's monthly publish arrives as a
  squashed release merge, so the in-window commit count is a poor proxy
  for patch size and the § 4a step-5 escape hatch is the *normal* path
  here, not the exception. Sizing with `detail: "stats"` before pulling
  any patch is what the entry should say.
