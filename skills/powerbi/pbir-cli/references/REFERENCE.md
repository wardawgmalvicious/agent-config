# pbir CLI — Full Command Reference

Per-command flag and argument detail. See `SKILL.md` for the verb index and discovery quickstart.

## Discovery

```bash
pbir ls                                        # All reports with counts
pbir ls --tree                                 # Tree view
pbir ls "Sales.Report"                         # Pages, filters, theme
pbir ls "Sales.Report/Overview.Page"           # Visuals on page
pbir tree "Sales.Report" -v                    # Tree with field bindings
pbir find "**/*.Visual" --count                # Count visuals
pbir find "**/card*.Visual" --json             # Glob + JSON
pbir cat "Sales.Report/Overview.Page"          # Raw page JSON
pbir cat "Sales.Report/theme"                  # Theme JSON
```

## Schema Discovery

Run BEFORE setting properties — `pbir set` on an undiscovered property returns "unknown property".

```bash
pbir schema types                              # List visual types
pbir schema containers card                    # Containers for a visual type
pbir schema describe card.title                # Properties, types, ranges
pbir schema check "Sales.Report"               # File schema versions
pbir schema upgrade "Sales.Report"             # Upgrade to latest
```

## Property get/set

```bash
pbir get "Sales.Report/Overview.Page/Revenue.Visual"
pbir set "Sales.Report/Overview.Page/Revenue.Visual.title.text" --value "Revenue"
pbir set "Sales.Report/**/*.Visual.title.show" --value true -f           # Glob bulk (requires -f)
pbir set "path" --json '{"title":{"show":true,"text":"Sales"}}'          # JSON input
pbir visuals properties "path/Visual.Visual"                             # Tree of all properties
pbir visuals format   "path/Visual.Visual"                               # Merged theme + visual
```

## Report Management

```bash
pbir new report "Sales.Report" -c "Workspace/Sales.SemanticModel"
pbir new report "Sales.Report" --from-template my-dashboard
pbir new report --list-templates
pbir report rebind   "Sales.Report" "Workspace/NewModel.SemanticModel"
pbir report convert  "Sales.Report" -F pbix                              # or -F pbip
pbir report merge    "A.Report" "B.Report" -o "Combined.Report"
pbir report merge-to-thick  "Thin.Report" "Model.SemanticModel"
pbir report split-pages     "Sales.Report" -o ./split
pbir report split-from-thick "Thick" --target "Workspace/Model"
pbir report clear-diagram   "Sales.Report"
pbir validate "Sales.Report"
pbir backup   "Sales.Report"
pbir restore  "Sales.Report"
```

## Pages

```bash
pbir add page    "Sales.Report/Detail.Page" -n "Detail"
pbir add page    "Sales.Report/Dash.Page"  --from-template executive-dashboard
pbir pages rename "Sales.Report/Page 1.Page" "Overview"
pbir pages move   "Sales.Report/Detail.Page" --to 1
pbir pages resize "Sales.Report/Overview.Page" --width 1920 --height 1080
pbir pages type   "Sales.Report/Tooltip.Page" --type tooltip              # 16:9 | 4:3 | letter | tooltip | custom
pbir pages display "Sales.Report/Overview.Page" -o FitToWidth             # FitToPage | FitToWidth | ActualSize
pbir pages hide    "Sales.Report/Hidden.Page"
pbir pages hide    "Sales.Report/Hidden.Page" --show                      # Unhide
pbir pages background "path" --color "#F0F8FF"
pbir pages background "path" --image bg.png
pbir pages wallpaper  "path" --color "#2B579A"
pbir pages active-page "Sales.Report" "Overview"
pbir pages interactions "Sales.Report/Overview.Page"
pbir pages json         "Sales.Report/Overview.Page"
```

## Visuals

### Creation

```bash
pbir add visual --list                                                   # All 50+ types with roles
pbir add visual kpi "Sales.Report/Overview.Page" --title "Revenue" \
  -d "Indicator:Invoices.Turnover" -d "Goal:Invoices.Turnover 1YP" \
  --x 24 --y 88 --width 400 --height 160
pbir add visual lineChart "Sales.Report/Overview.Page" --title "Trend" --width 608 --height 220
pbir add visual "Sales.Report/Page.Page" --from-json visuals.json        # Bulk from JSON array
pbir add title    "Sales.Report/Overview.Page" "Sales Dashboard"
pbir add subtitle "Sales.Report/Overview.Page" "Q4 2025"
```

### Position and Layout

```bash
pbir visuals position "path/Visual.Visual" --x 100 --y 50 --width 400 --height 300
pbir visuals resize   "path/Visual.Visual" --width 400 --height 300
pbir visuals align    "Sales.Report/Overview.Page" left V1 V2 V3
pbir visuals align    "Sales.Report/Overview.Page" distribute-horizontal V1 V2 V3
pbir visuals z-order  "path/Visual.Visual"
pbir visuals snap     "path/Visual.Visual"
pbir visuals mobile   "path/Visual.Visual"
pbir visuals group    "Sales.Report/Overview.Page"
```

### Container Formatting

```bash
pbir visuals title      "path/V.Visual" --text "Title" --show --fontSize 14 --bold
pbir visuals subtitle   "path/V.Visual" --no-show
pbir visuals background "path/V.Visual" --color "#FFFFFF" --transparency 0
pbir visuals border     "path/V.Visual" --show --color "#E0E0E0" --radius 8 --width 1
pbir visuals shadow     "path/V.Visual" --show
pbir visuals padding    "path/V.Visual" --top 10 --bottom 10 --left 10 --right 10
pbir visuals header     "path/V.Visual" --show
pbir visuals tooltip    "path/V.Visual"
pbir visuals hide       "path/V.Visual"
pbir visuals hide       "path/V.Visual" --show
pbir visuals clear-formatting "Sales.Report/**/*.Visual" --only-containers -f   # Safe reset
pbir visuals clear-formatting "path/V.Visual" --dry-run                         # Preview
```

### Chart Formatting

```bash
pbir visuals legend "path/V.Visual" --show --position Right
pbir visuals axis   "path/V.Visual" --axis category --show --title "Category"
pbir visuals axis   "path/V.Visual" --axis value    --show --title "Amount"
pbir visuals labels "path/V.Visual" --show --fontSize 10
pbir visuals sort   "path/V.Visual" -f "Sales.Revenue" -d Descending
pbir visuals sort   "path/V.Visual" --remove
```

### Data Binding

```bash
pbir visuals bind "path/V.Visual" --show                                 # Current bindings
pbir visuals bind "path/V.Visual" --list-roles
pbir visuals bind "path/V.Visual" -a "Values:Sales.Revenue"              # Add
pbir visuals bind "path/V.Visual" -a "Category:Products.Category" -t Column
pbir visuals bind "path/V.Visual" -r "Values:Sales.Revenue"              # Remove
pbir visuals bind "path/V.Visual" -c "Values"                            # Clear role
```

## Conditional Formatting

```bash
pbir visuals cf "path/V.Visual"                                                   # List all CF
pbir visuals cf "path/V.Visual" --measure "labels.color _Fmt.StatusColor"
pbir visuals cf "path/V.Visual" --measure "dataPoint.fill _Fmt.BarColor"
pbir visuals cf "path/V.Visual" --info   labels.color
pbir visuals cf "path/V.Visual" --remove labels.color
pbir visuals cf "path/V.Visual" --has-cf dataPoint
pbir visuals cf "path/V.Visual" --set-color "dataPoint.fill min=bad max=good"
pbir visuals cf "path/V.Visual" --theme-colors "dataPoint.fill"                   # Hex to theme tokens
pbir visuals cf "path/V.Visual" --to-measure dataPoint.fill                       # Convert to ext measure
pbir visuals format-field "path/V.Visual" values fontColor -f "Sales.Revenue" -v "#118DFF"
pbir visuals format-state "path/V.Visual" labels fontColor -s hover -v "#E3F2FD"
```

## Filters

```bash
pbir filters list    "Sales.Report"
pbir add filter Date Year       -r "Sales.Report" --values 2025          # Report level
pbir add filter Products Category -p "Sales.Report/Detail.Page"          # Page level
pbir add filter Date Date       -r "Sales.Report" --type RelativeDate
pbir filters set   "Sales.Report/Date.Year.Filter" --values "2024,2025"
pbir filters clear "Sales.Report/Date.Year.Filter"
pbir filters hide  "Sales.Report/F.Filter"
pbir filters lock  "Sales.Report/F.Filter"
pbir filters pane-hide     "Sales.Report"
pbir filters pane-collapse "Sales.Report"
pbir filters pane-set      "Sales.Report" --width 320
```

## Fields

```bash
pbir fields list    "Sales.Report"
pbir fields find    "Revenue" "Sales.Report"
pbir fields replace "Sales.Report" --from "Sales.Revenue" --to "Finance.Revenue"
pbir fields clear   "Sales.Report/Overview.Page" -f
pbir fields add     "path/V.Visual" Values Sales.Revenue
```

## Theme

```bash
pbir theme colors       "Sales.Report"                                   # Palette + usage audit
pbir theme text-classes "Sales.Report"
pbir theme fonts        "Sales.Report"
pbir theme validate     "Sales.Report"
pbir theme diff         "A.Report" "B.Report"
pbir theme set-colors       "Sales.Report" --good "#00B050" --bad "#FF0000"
pbir theme set-text-classes "Sales.Report" title --font-size 18
pbir theme set-formatting   "Sales.Report" "card.*.title.fontSize" --value 14
pbir theme push-visual      "path/V.Visual"                              # Promote to theme
pbir theme serialize "Sales.Report" -o Custom.Theme                      # Extract editable files
pbir theme build     "Custom.Theme"                                      # Rebuild after edits
pbir theme list-templates
pbir theme apply-template "Sales.Report" sqlbi
```

## DAX (Extension Measures & Visual Calculations)

```bash
pbir dax measures list "Sales.Report"
pbir dax measures add  "Sales.Report" -t _Measures -n "YoY Growth" \
  -e 'DIVIDE([Sales]-[PY Sales],[PY Sales])' --data-type Double
pbir dax measures add  "Sales.Report" -t _Fmt -n "StatusColor" \
  -e 'IF([Sales]>[Target],"good","bad")' --data-type Text
pbir dax measures rename "Sales.Report" "OldName" "NewName"
pbir dax viscalcs add  "Sales.Report/Overview.Page/Trend.Visual" \
  -n "Running Total" -e "RUNNINGSUM([Revenue])"
```

## Bookmarks & Annotations

```bash
pbir bookmarks list   "Sales.Report"
pbir bookmarks rename "Sales.Report" "OldName" "NewName"
pbir bookmarks data   "Sales.Report" "Name" --off                        # Don't capture filters
pbir annotations list "Sales.Report"
pbir add annotation   "Sales.Report" --name version --value "1.0"
```

## Connection, Download, Publish

```bash
pbir connect "Sales.Report"                                              # Local
pbir connect MyWorkspace MyReport                                        # Remote
pbir connect --clear
pbir profile save dev --description "Dev workspace"
pbir download "Workspace.Workspace"                                      # List remote reports
pbir download "Workspace.Workspace/Report.Report" -o ./output -F pbip
pbir publish  "Sales.Report" "Workspace.Workspace/Sales.Report"
pbir publish  "Sales.Report" "Workspace.Workspace/Sales.Report" -o       # Publish + open
pbir open     "Sales.Report"                                             # Local in Desktop
```

## Model Inspection

```bash
pbir model                                                               # List all reports + models
pbir model "Sales.Report" -d                                             # Model definition
pbir model "Sales.Report" -d -t Sales                                    # Filter to table
pbir model "Sales.Report" -d -v                                          # Full TMDL
pbir model "Sales.Report" -q "EVALUATE VALUES('Sales'[Region])"
pbir model "Sales.Report" -q "EVALUATE 'Sales'" -F json
```

## Removal

```bash
pbir rm "Sales.Report/Overview.Page" -f                                  # Page
pbir rm "Sales.Report/Overview.Page/Revenue.Visual" -f                   # Visual
pbir rm "Sales.Report/filter:Date Year" -f
pbir rm "Sales.Report/bookmark:Snapshot" -f
pbir rm "Sales.Report" --measures -f                                     # All ext measures
pbir rm "Sales.Report" --theme -f
pbir rm "Sales.Report" --all -f                                          # Filters + bookmarks + annotations
```

## Batch & Validate

```bash
pbir batch run batch.yaml                                                # Declarative multi-step
pbir validate "Sales.Report"
```
