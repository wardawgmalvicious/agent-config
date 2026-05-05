---
name: pbir-cli
description: Use when running the pbir CLI (install via uv tool install pbir-cli) to inspect or edit local Power BI PBIR reports. Covers path syntax (Report.Report/Page.Page/Visual.Visual with required type suffixes, glob patterns, property dot-notation), verb noun groups — report / page / visual / filter / bookmark / theme / dax / fields / schema / profile / annotation / model — plus discovery verbs (ls / tree / find / cat / get / schema describe) that should run before any mutation, property get/set with glob bulk edits requiring -f, validation and publish flows, download/publish to Fabric workspaces, and batch runs. Detailed per-command flags and arguments live in references/REFERENCE.md. Invoke whenever the user mentions pbir <verb>, pbir-cli, pbir set/get/ls/add/new/rm/validate/publish, or any specific pbir subcommand.
---

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
| Discovery | `pbir ls`, `pbir tree`, `pbir find`, `pbir cat`, `pbir get` | references/REFERENCE.md § Discovery |
| Schema | `pbir schema types`, `pbir schema containers`, `pbir schema describe`, `pbir schema check`, `pbir schema upgrade` | references/REFERENCE.md § Schema |
| Property get/set | `pbir set`, `pbir get`, `pbir visuals properties`, `pbir visuals format` | references/REFERENCE.md § Property |
| Report | `pbir new report`, `pbir report rebind`, `pbir report convert`, `pbir report merge`, `pbir validate`, `pbir backup`, `pbir restore` | references/REFERENCE.md § Report |
| Pages | `pbir pages …`, `pbir add page` | references/REFERENCE.md § Pages |
| Visuals | `pbir add visual`, `pbir visuals …` | references/REFERENCE.md § Visuals |
| Conditional formatting | `pbir visuals cf …`, `pbir visuals format-field`, `pbir visuals format-state` | references/REFERENCE.md § CF |
| Filters | `pbir filters …`, `pbir add filter` | references/REFERENCE.md § Filters |
| Fields | `pbir fields …` | references/REFERENCE.md § Fields |
| Theme | `pbir theme …` | references/REFERENCE.md § Theme |
| DAX | `pbir dax measures …`, `pbir dax viscalcs …` | references/REFERENCE.md § DAX |
| Bookmarks & annotations | `pbir bookmarks …`, `pbir annotations …`, `pbir add annotation` | references/REFERENCE.md § Bookmarks |
| Connection / publish | `pbir connect`, `pbir profile`, `pbir download`, `pbir publish`, `pbir open` | references/REFERENCE.md § Connection |
| Model inspection | `pbir model …` | references/REFERENCE.md § Model |
| Removal | `pbir rm` | references/REFERENCE.md § Removal |
| Batch | `pbir batch run`, `pbir validate` | references/REFERENCE.md § Batch |

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

See references/REFERENCE.md § Discovery and references/REFERENCE.md § Schema for the full flag set.

### Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `pbir: command not found` | Not installed | `uv tool install pbir-cli` |
| Glob pattern returns nothing | Missing `-f` flag on `set` | Add `-f` for glob selectors |
| "Report not found" | Missing `.Report` type suffix | Paths require `Name.Report`, `Name.Page`, `Name.Visual` |
| `set` fails with "unknown property" | Property not discovered first | Run `pbir schema describe <type>.<container>` |
| Publish fails after local edits | Structure invalid | Run `pbir validate` before publish |
| UnicodeEncodeError on Windows | cp1252 stdout encoding | Set `PYTHONIOENCODING=utf-8` |
| Theme changes not applied per visual | Visual has inline override | `pbir visuals clear-formatting --only-containers -f` |
| `pbir download` fails | fab CLI not authenticated | Run `fab auth login` first |
| Visual overlaps existing header | Placed coordinates without measuring scaffold | Inspect the scaffolded page.json before laying out |
| `pbir new report` creates new theme each time | Default is sqlbi | Do NOT re-apply unless user requests different theme |

### See also

- [references/REFERENCE.md](references/REFERENCE.md) — full per-command flag and argument reference
- `pbir-report-workflow` — end-to-end report creation with this CLI
- `pbir-pages` — page.json structure consumed by `pbir pages …`
- `pbir-visual-json` — visual.json structure consumed by `pbir visuals …`
- `pbir-themes` — theme JSON structure consumed by `pbir theme …`
