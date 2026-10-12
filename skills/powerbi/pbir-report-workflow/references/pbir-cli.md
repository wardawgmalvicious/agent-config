## pbir CLI — Verb Index

Agent-first CLI for manipulating local Power BI reports in PBIR format. Install separately: `uv tool install pbir-cli`. Verify with `pbir --version`.

**Run discovery before every mutation.** `pbir schema describe <type>.<container>` is the canonical way to confirm a property exists before `pbir set`. Run `pbir validate` after every mutation.

### Path Syntax

```
Report.Report/Page.Page/Visual.Visual
```

- Type suffixes (`.Report`, `.Page`, `.Visual`) are REQUIRED
- Glob patterns: `**/*.Visual`, `**/card*.Visual`
- Property dot-notation after path: `Visual.Visual.title.fontSize`
- Reports must be local PBIR — use `pbir download` to fetch from Fabric first

### Global Flags

| Flag | Purpose |
|---|---|
| `--quiet` / `-q` | Suppress animations, tips, spinners (prefer for scripts) |
| `--debug` | Tracebacks, timing, path resolution to stderr |
| `--version` / `-V` | Show version |
| `--show-legacy` | Include legacy non-PBIR reports in listings |

### Verb–Noun Groups

| Group | Entry commands | Detail |
|---|---|---|
| Discovery | `pbir ls`, `pbir tree`, `pbir find`, `pbir cat`, `pbir get` | pbir-cli-commands.md § Discovery |
| Schema | `pbir schema types`, `pbir schema containers`, `pbir schema describe`, `pbir schema check`, `pbir schema upgrade` | pbir-cli-commands.md § Schema |
| Property get/set | `pbir set`, `pbir get`, `pbir visuals properties`, `pbir visuals format` | pbir-cli-commands.md § Property |
| Report | `pbir new report`, `pbir report rebind`, `pbir report convert`, `pbir report merge`, `pbir validate`, `pbir backup`, `pbir restore` | pbir-cli-commands.md § Report |
| Pages | `pbir pages …`, `pbir add page` | pbir-cli-commands.md § Pages |
| Visuals | `pbir add visual`, `pbir visuals …` | pbir-cli-commands.md § Visuals |
| Conditional formatting | `pbir visuals cf …`, `pbir visuals format-field`, `pbir visuals format-state` | pbir-cli-commands.md § CF |
| Filters | `pbir filters …`, `pbir add filter` | pbir-cli-commands.md § Filters |
| Fields | `pbir fields …` | pbir-cli-commands.md § Fields |
| Theme | `pbir theme …` | pbir-cli-commands.md § Theme |
| DAX | `pbir dax measures …`, `pbir dax viscalcs …` | pbir-cli-commands.md § DAX |
| Bookmarks & annotations | `pbir bookmarks …`, `pbir annotations …`, `pbir add annotation` | pbir-cli-commands.md § Bookmarks |
| Connection / publish | `pbir connect`, `pbir profile`, `pbir download`, `pbir publish`, `pbir open` | pbir-cli-commands.md § Connection |
| Model inspection | `pbir model …` | pbir-cli-commands.md § Model |
| Removal | `pbir rm` | pbir-cli-commands.md § Removal |
| Batch | `pbir batch run`, `pbir validate` | pbir-cli-commands.md § Batch |

### Discovery Quickstart

Always run these first — they tell you what already exists before you mutate anything:

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
pbir schema types                              # List visual types
pbir schema describe card.title                # Properties, types, ranges
```

See pbir-cli-commands.md § Discovery and pbir-cli-commands.md § Schema for the full flag set.

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `pbir: command not found` | Not installed | `uv tool install pbir-cli` |
| Glob pattern returns nothing | Missing `-f` flag on `set` | Add `-f` for glob selectors |
| "Report not found" | Missing `.Report` type suffix | Paths require `Name.Report`, `Name.Page`, `Name.Visual` |
| `set` fails with "unknown property" | Property not discovered first | Run `pbir schema describe <type>.<container>` |
| Publish fails after local edits | Structure invalid | Run `pbir validate` before publish |
| `pbir validate` floods `SCHEMA_DEGRADED` warnings | Declared visualContainer schema version isn't bundled with the CLI; a fallback schema was used | Cosmetic, one per file — only errors block. Note schema-valid ≠ engine-valid: verify hand-authored SQExpr shapes against Desktop-serialized reports (e.g. microsoft/BCApps); see [filters.md](filters.md) § TopN |
| UnicodeEncodeError on Windows | cp1252 stdout encoding | Set `PYTHONIOENCODING=utf-8` |
| Theme changes not applied per visual | Visual has inline override | `pbir visuals clear-formatting --only-containers -f` |
| `pbir download` fails | fab CLI not authenticated | Run `fab auth login` first |
| Visual overlaps existing header | Placed coordinates without measuring scaffold | Inspect the scaffolded page.json before laying out |
| `pbir new report` creates new theme each time | Default is sqlbi | Do NOT re-apply unless user requests different theme |
| `Got unexpected extra argument(s) (Overview)` from `pbir pages rename` | The new name is an option; the hint to quote the path misleads | `pbir pages rename "<R>.Report/<Page>.Page" --to Overview -f`, a dry run without `-f` |
| After `pages rename --to`, `page.json` `name` and `pages.json` `pageOrder` / `activePageName` keep the old id | The rename moves only the folder and `displayName` (0.9.29 and 0.9.32, 2026-10-08) | Set all three to the new folder name by hand, then `pbir validate` |
| `Role 'Fields' not valid for card. Available: Values` from `add visual -d`, after `schema describe` listed `Fields` | 0.9.29's `describe` prints roles' display names (column chart `X-axis`, `Y-axis`; table `Columns`); `-d` takes the internal ones | Use the names the error lists, or upgrade: 0.9.32 prints `Values`, `Category`, `Y` (2026-10-08) |
| `semantic_model_path must stay inside …` from `pbir validate` | `definition.pbir` `byPath` leads out of the report's parent folder, as `../../<Folder>/<Model>.SemanticModel` does; Fabric Git sync resolves it | Validate bound `byConnection`, then switch to `byPath` (0.9.29 and 0.9.32, 2026-10-08) |

### See also

- [pbir-cli-commands.md](pbir-cli-commands.md) — full per-command flag and argument reference
- `pbir-report-workflow` — end-to-end report creation with this CLI
- [pages.md](pages.md) — page.json structure consumed by `pbir pages …`
- [visual-json.md](visual-json.md) — visual.json structure consumed by `pbir visuals …`
- [themes.md](themes.md) — theme JSON structure consumed by `pbir theme …`
