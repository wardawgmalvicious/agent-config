---
name: pbir-report-workflow
description: Use when scaffolding or building a new Power BI report end-to-end from a published semantic model using the pbir CLI. Covers the 10-step workflow — KPI / filter / granularity requirements, model field discovery via pbir model, pbir new report scaffold, renaming the default Page 1 instead of adding a new one, 3-30-300 visual hierarchy for three viewing distances (glance / scan / investigate), layout math with margin/gap constants (always inspect the scaffolded page first), row-by-row visual placement with explicit coordinates, explicit sort after bind, report vs page filters, extension-measure conditional formatting with theme tokens like good/bad, time-granularity inference from the active date filter, pbir validate + publish. Invoke when user says 'build a report', 'scaffold a dashboard', or 'lay out a KPI page'.
---

## PBIR Report Workflow

End-to-end workflow for building Power BI reports from a published semantic model using `pbir` CLI. Requires the model to already exist in a Fabric/Power BI workspace.

### Workflow Steps

1. Gather requirements (KPIs, filters, granularity, audience)
2. Discover model fields and data types
3. Create project folder + scaffold report
4. Rename default page (do not add a new one)
5. **Measure the scaffold** (existing visuals, theme, canvas size) before computing layout
6. Plan layout arithmetic from the measured scaffold
7. Add visuals row-by-row with explicit coordinates
8. Bind fields and set sort direction explicitly
9. Add report-level and page-level filters
10. Apply bespoke formatting only when theme is insufficient
11. Validate, then publish

### Rules

- Visuals must NOT overlap
- Favor theme changes over per-visual overrides
- Favor extension measures (`_Fmt`) with theme tokens (`good`/`bad`) for conditional formatting
- Always create reports inside a named project folder
- Run `pbir validate` after every mutation
- Use PascalCase for project / report / page / visual names
- Edit PBIR JSON directly via Claude Code or `pbir set` — do NOT use Tabular Editor
- Do NOT add `PBI_*` annotations manually

### Step 1 — Requirements & Model Discovery

```bash
pbir model                                                               # List reports + models
pbir model "Sales.Report" -d                                             # Model definition
pbir model "Sales.Report" -d -t Sales                                    # Filter to table
pbir model "Sales.Report" -q "EVALUATE VALUES('Date'[Year])"             # Query for filter values
```

Ask the user (via `AskUserQuestion`) to confirm:

- Which KPIs to surface (measures + targets)
- Trend granularity (daily / weekly / monthly / quarterly)
- Categorical breakdowns
- Detail table/matrix hierarchies
- Report-level vs page-level filters

### Step 2 — Scaffold Report

```bash
mkdir -p SalesDashboard && cd SalesDashboard
pbir new report "Sales.Report" -c "MyWorkspace/Sales.SemanticModel"
pbir pages rename "Sales.Report/Page 1.Page" "Overview"
pbir pages active-page "Sales.Report" "Overview"
```

Resulting layout:

```
SalesDashboard/
  Sales.pbip
  Sales.Report/
    definition.pbir
    definition/
      version.json
      report.json
      pages/
        pages.json
        Overview/
          page.json
          visuals/Title.Visual/visual.json
    StaticResources/
```

### Step 3 — Measure the Scaffold Before Laying Out

`pbir new report` produces a default page with some combination of a pre-placed title textbox, a baked-in theme, and canvas defaults. Exact coordinates, theme name, and visual positions depend on the CLI version and the chosen `--from-template`. Before planning anything, read the actual scaffold instead of assuming:

```bash
pbir cat "Sales.Report/Overview.Page"                                    # Full page.json (width, height, displayOption)
pbir ls  "Sales.Report/Overview.Page"                                    # Existing visuals on the page
pbir tree "Sales.Report" -v                                              # Every visual + bindings
pbir cat "Sales.Report/theme"                                            # Active theme name + palette
```

From the output, record:

1. Canvas `width` / `height` from `page.json` (often `1280 x 720` but templates may override).
2. Every existing visual's `position.x`, `position.y`, `position.width`, `position.height`. For bulk reads use `jq '.position' <path>/visual.json` across the `visuals/` folder.
3. The tallest `y + height` among existing visuals — the first safe `y` for a new row you add.
4. Active base and custom theme names — so you don't accidentally re-apply a default over meaningful styling.

All subsequent coordinates should be derived from those measured values, not hardcoded from this doc.

### Step 4 — Layout Math (3-30-300)

Every layout starts from four constants: `(page_width, page_height, margin, gap)`.

**Example (1280 x 720 canvas with `margin=24`, `gap=16`):**

```
usable_width  = page_width  - (2 * margin) = 1232
usable_height = page_height - (2 * margin) = 672
3 equal columns = (usable_width - 2*gap) / 3 = 400
2 equal columns = (usable_width - gap) / 2 = 608
```

Substitute your measured `page_width` / `page_height` — do not hardcode 1280/720.

**3-30-300 visual hierarchy** — design for three viewing distances:

| Distance | View | Payload |
|---|---|---|
| 3 seconds | Glance | Headline KPIs + target delta |
| 30 seconds | Scan | Trend direction + top-1 breakdown |
| 300 seconds | Investigate | Detail table with hierarchies + conditional formatting |

**Standard 3-row composition** — compute each row from the measured scaffold:

| Row | Content |
|---|---|
| Top region | Existing title / header visuals already in the scaffold |
| Row 1 | 3 KPI visuals side-by-side |
| Row 2 | Line chart + bar chart (2 columns) |
| Row 3 | Full-width `tableEx` detail |

Row heights, the gap between rows, and `y` offsets all come from the measured scaffold plus your chosen `margin` / `gap`. Verify the total fits inside `page_height` before placing any visual.

### Step 5 — Add Visuals (Coordinates Explicit)

The coordinates below are **illustrative** — computed from a measured 1280x720 scaffold with a ~90 px header region, `margin=24`, `gap=16`. Substitute values from your actual measurement before running these commands.

```bash
# Row 1: KPIs
pbir add visual kpi "Sales.Report/Overview.Page" --title "Revenue" \
  -d "Indicator:Invoices.Turnover" -d "Goal:Invoices.Turnover 1YP" \
  -d "TrendLine:Date.Calendar Month (ie Jan)" \
  --x 24 --y 120 --width 400 --height 140

pbir add visual kpi "Sales.Report/Overview.Page" --title "OrderLines" \
  -d "Indicator:Orders.Order Lines" -d "Goal:Orders.Order Lines 1YP" \
  --x 440 --y 120 --width 400 --height 140

pbir add visual kpi "Sales.Report/Overview.Page" --title "MarginPct" \
  -d "Indicator:Invoices.Selling Margin (%)" -d "Goal:Invoices.Selling Margin (%) 1YP" \
  --x 856 --y 120 --width 400 --height 140

# Row 2: Trend + Breakdown
pbir add visual lineChart "Sales.Report/Overview.Page" --title "MonthlyTrend" \
  --x 24 --y 276 --width 608 --height 208
pbir visuals bind "Sales.Report/Overview.Page/MonthlyTrend.Visual" \
  -a "Category:Date.Calendar Month (ie Jan)" -a "Y:Invoices.Turnover"

pbir add visual barChart "Sales.Report/Overview.Page" --title "ByRegion" \
  -d "Category:Regions.Territory" -d "Y:Invoices.Turnover" \
  --x 648 --y 276 --width 608 --height 208

# Row 3: Detail
pbir add visual tableEx "Sales.Report/Overview.Page" --title "DetailByAccount" \
  --x 24 --y 500 --width 1232 --height 196
pbir visuals bind "Sales.Report/Overview.Page/DetailByAccount.Visual" \
  -a "Values:Customers.Key Account Name" -a "Values:Invoices.Turnover" -a "Values:Orders.Order Lines"
```

### Step 6 — Spacing Sanity-Check

After placing visuals, verify the arithmetic yourself:

```
left_margin + usable_width + right_margin == page_width
top_region + Σ(row_heights) + (n-1) * gap + bottom_margin == page_height
```

If either equation fails, adjust before saving. `pbir tree "Sales.Report" -v` lists every visual's position in one command.

### Step 7 — Sort, Filters, Theme Overrides

```bash
# Charts auto-sort descending by first measure. Set explicitly after bind.
pbir visuals sort "Sales.Report/Overview.Page/ByRegion.Visual" \
  -f "Invoices.Turnover" -d Descending

# Report-level filters (apply to all pages)
pbir add filter Date Year     -r "Sales.Report" --values 2025
pbir add filter Geography Region -r "Sales.Report"

# Page-level filters
pbir add filter Products Category -p "Sales.Report/Overview.Page"
```

### Step 8 — Title Hierarchy

Distribute meaning across the title hierarchy — never say the same thing twice.

| Level | Content |
|---|---|
| Page title (textbox) | The subject — `"OrderLines"` |
| Visual titles | The differentiator — `"byKeyAccount"`, `"MonthlyTrend"` |
| Subtitles | Hide — almost always redundant |

```bash
pbir visuals subtitle "Sales.Report/Overview.Page/MonthlyTrend.Visual" --no-show
```

Hide axis titles when the axis is self-evident (month names on x-axis). Hide category labels on cards when the visual title describes the metric.

### Step 9 — Conditional Formatting via Extension Measures

Prefer extension measures returning theme tokens (`"good"`, `"bad"`) over hex strings so the theme can be rebranded centrally.

```bash
pbir dax measures add "Sales.Report" -t _Fmt -n "RevenueStatusColor" \
  -e 'IF([Turnover] >= [Turnover 1YP], "good", "bad")' --data-type Text

pbir visuals cf "Sales.Report/Overview.Page/ByRegion.Visual" \
  --measure "dataPoint.fill _Fmt.RevenueStatusColor"
```

### Step 10 — Inferring Time Granularity from Filter Context

| Active Filter | Trend Granularity | Date Column |
|---|---|---|
| Year (e.g., 2025) | Monthly | `Date.Calendar Month (ie Jan)` |
| Quarter | Monthly or Weekly | `Date.Calendar Month (ie Jan)` / `Date.Calendar Week EU` |
| Month | Daily or Weekly | `Date.Date` / `Date.Calendar Week EU` |
| No date filter | Monthly or Quarterly | `Date.Calendar Month Year` / `Date.Calendar Quarter Year` |

Default to monthly when unsure.

### Step 11 — Validate, Publish, Open

```bash
pbir validate "Sales.Report"
pbir tree     "Sales.Report" -v
pbir publish  "Sales.Report" "MyWorkspace.Workspace/Sales.Report" -o     # Publish + open
pbir open     "Sales.Report"                                             # Local in Desktop
```

### Common Page Sizes

| Type | Width x Height | Use Case |
|---|---|---|
| Default (16:9) | 1280 x 720 | Screen dashboards |
| Large (16:9) | 1920 x 1080 | High-density executive dashboards |
| Letter portrait | 816 x 1056 | Print/PDF reports |
| Tooltip | 320 x 240 | Hover tooltip pages |
| Custom tall | 1280 x 2400 | Scrollable operational pages |

### KPI Target Measures

Use prior-year measures as targets when available. Add via TMDL if missing:

```tmdl
measure 'Turnover 1YP' = CALCULATE([Turnover], DATEADD('Date'[Date], -1, YEAR))
```

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| Visual overlaps existing scaffold element | Placed `y` before measuring scaffold | Run `pbir ls` + inspect `position` of every pre-existing visual first |
| Extra blank page on report open | `pbir add page` called instead of rename | `pbir pages rename "Page 1.Page" "Overview"` |
| Charts show wrong sort order | Default auto-sort not set after bind | `pbir visuals sort -f ... -d Descending` |
| Theme overridden by visual formatting | Inline formatting applied | `pbir visuals clear-formatting --only-containers -f` |
| Publish 401 | Wrong Fabric token audience | `az account get-access-token --resource https://api.fabric.microsoft.com` |
| Page doesn't fit canvas | `displayOption` set to integer | Must be string: `"FitToPage"` etc. |
| Extension measure CF not rendering | `references.measures` missing a dep | Every measure used in DAX must appear in `references.measures` |
| Trend chart has wrong granularity | Granularity not matched to filter | Consult granularity table |
| Right margin looks off | Layout math not verified | Print spacing verification (left + usable + right = width) |

### Reference

- Microsoft Learn: [Power BI reports overview](https://learn.microsoft.com/power-bi/create-reports/power-bi-reports-overview)
- Microsoft Learn: [Tips for designing a great Power BI report](https://learn.microsoft.com/power-bi/guidance/report-design-tips)
- Microsoft Learn: [Design reports for accessibility](https://learn.microsoft.com/power-bi/create-reports/desktop-accessibility-creating-reports)
- Comprehensive MS Learn link bundle (design principles / layout / field discovery / filters / CF / publish / time-granularity): [references/REFERENCE.md](references/REFERENCE.md)

### See also

- `pbip-project-structure` — project file layout
- `pbir-cli` — CLI command reference
- `pbir-pages` — page JSON structure
- `fabric-tmdl` — TMDL measure authoring
