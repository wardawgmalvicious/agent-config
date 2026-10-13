# `pbir-report-workflow` — behaviour cases

`pbir-report-workflow` is the router that `pbir-cli`, the six file-level
PBIR skills and `powerbi-report-design` folded into on 2026-10-12. It
has no `paths:`, so it has no activation contract: its startup listing
entry is its whole trigger, and its body names the reference to read
before each hand edit of report JSON, since no file loads one any more.
These five cases, the fold brief's, test where it routes and what it
says.

## The cases

| Case | Passes when |
| --- | --- |
| `scaffold` | the workflow's steps, through the `pbir` CLI |
| `hand` | reads `references/pages.md` before the edit; `displayOption` as a string |
| `filter` | reads `references/filters.md` before writing the filter |
| `design` | reads `references/design/design.md` |
| `cli` | a `pbir` discovery verb, per `references/pbir-cli.md` |

The prompts, verbatim:

```text
scaffold: Our Retail semantic model is published in the Fabric workspace Analytics. Build a new Power BI report on it with the pbir CLI: one overview page with revenue, order count and margin % against last year, a monthly revenue trend, and revenue by region. Give me the exact commands and steps, start to finish.

hand: Sales.Report in this folder is a Power BI report in PBIR format. Make its Overview page fit to width. Do it by editing the page's JSON by hand, not with a CLI: show me exactly what the file should contain afterwards.

filter: Sales.Report in this folder is a Power BI report in PBIR format. Add a filter to its RevenueTrend visual so the chart shows only the last 3 complete months, on the Date[Date] column. Write it into the visual's JSON by hand: give me the exact JSON to add and where it goes.

design: Sales.Report in this folder is our sales dashboard, in PBIR format. Restyle it to our brand palette (navy #0B2545, teal #13A89E, coral #F26B5B, light grey #F4F5F7), and critique its charts: what would you change, and why? Give me the concrete changes, start to finish.

cli: We edit Sales.Report in this folder with the pbir CLI. Which command lists every visual on its Overview page, with each visual's type and position?
```

The slash arm sends `/pbir-report-workflow` followed by the `hand`
prompt.

## Running them

The fixture is [fixtures/Sales.Report/](fixtures/Sales.Report/), a PBIR
report built from the skill's own shapes rather than a Desktop export:
one `Overview` page at `FitToPage`, a line chart over `Date.Month`, a
pie over `Product Name`, a table showing `Count of order_line_id`, and a
custom theme. `scaffold` builds a new report and reads none of it.

Build a probe outside this repo, since `.claude/settings.json` here
collapses every platform description to `name-only`:

- `router/.claude/skills/`: a copy of every folder in the platform
  groups both client repos hold (`skills/fabric/` and `skills/powerbi/`
  then, split by persona on 2026-10-13), so the router's entry competes
  with every Fabric description.
- `baseline/`: no `.claude/`, run with `--safe-mode`.
- `Sales.Report/` at each arm's root.

Run each case in each arm from that arm's directory, with
`CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1`, as
[`../fabric-deploy/README.md`](../fabric-deploy/README.md) does and for
its reasons:

```powershell
claude -p '<prompt>' --output-format stream-json --verbose --tools Skill,Read --strict-mcp-config --model claude-opus-5-5 --effort xhigh --max-budget-usd 3
```

Add `--safe-mode` on the baseline. Launch the slash arm from PowerShell,
since Git Bash rewrites a leading `/`. From a script, pass the prompt
through `ProcessStartInfo.ArgumentList` rather than a shell string, and
call the script with `&`, not `pwsh -File`, which hands a
comma-separated `-Runs` list over as one string.

Read the `init` record for `tools` (2 on every arm) and
`slash_commands`; then the `Skill` and `Read` calls, and the first
`result`. The skill is unconditional, so no `Read` brings it in: a
payload arm reaches it through its listing entry or not at all.

To compare with the shape before the fold, a third arm holds that
commit's `skills/fabric/` and `skills/powerbi/`, exported with
`git archive ff87db6 skills/fabric skills/powerbi`.

## Result, 2026-10-12

The router held: it routed on all five cases, each time invoking
`pbir-report-workflow` and reading the case's reference before opening a
report file. One run per arm, on 2.1.293, Opus 5.5 at `xhigh`, against
the fold commit, which the arms read as `f221b4a` before its rebase:

| Case | Router | The old shape, at `ff87db6` | Baseline |
| --- | --- | --- | --- |
| `scaffold` | pass: `pbir-cli.md`, `pbir-cli-commands.md`, `pages.md` and `conditional-formatting.md` read; scaffold, the page-id repair after `pages rename`, a layout measured from the scaffold, explicit sorts, validate, publish | pass: `Skill pbir-report-workflow`, then `pbir-cli` | fail: named no `pbir` command, asking for its `--help` instead |
| `hand` | pass: `pages.md` read before `page.json`; `"FitToWidth"`, with a number named as rejected | pass: `pbir-pages` invoked once the `pages.json` Read activated it | pass on the edit, unaided |
| `filter` | pass: `filters.md` and `visual-json.md` read before the visual; the reverse `DateSpan`/`DateAdd` nesting flagged as failing in the service | pass: `pbir-filters` invoked once the `report.json` Read activated it; the same JSON | pass on the JSON, unaided, and no nesting warning |
| `design` | pass: `design/design.md`, `themes.md`, `brownfield.md`, `color.md` and `accessibility.md` read; the palette's contrast, good and bad mapped to sentiment colours, the textbox safeguard | pass: `Skill powerbi-report-design`, then `pbir-themes` | partial: the CLI's bundled `dataviz` skill; the same contrast ratios, no report mechanics |
| `cli` | pass: `pbir-cli.md` read; `pbir ls "Sales.Report/Overview.Page"` | pass: `Skill pbir-cli`, the same command | fail: would not name a command |

The fold's trade was that a hand edit no longer surfaces its file's
guidance by itself. In this probe the router's entry closed it: `hand`
and `filter` invoked the router from the words alone and read the file's
reference before the file. The old shape reached the same guidance only
after a `Read` activated it (`commands_changed`, then the `Skill` call),
and also invoked `pbir-cli`, which neither edit needed.

The slash arm expanded `/pbir-report-workflow` with no `Skill` call,
read `pages.md` before `page.json` and answered as the `hand` router arm
did, which witnesses the expansion. `init` gave `tools` 2 on every arm,
and `slash_commands` 81 on the router, 83 on the old shape and 58 on the
baseline, with no `pbir-report-workflow` there. `--safe-mode` keeps the
CLI's bundled skills, so the baseline's `design` arm could still invoke
`dataviz`.

**A prompt flaw**: `design` names no visual folder, and with `Read` but
no `Glob` no arm could list `visuals/`, so none critiqued a chart; each
guessed folder names, the router's from the skill's own examples. Name
the three folders in a rerun.

**Noticed, not fixed**: the router's `scaffold` arm moved model
discovery after the scaffold, since Step 1's `pbir model "Sales.Report"
-d` needs the report Step 2 creates; and it ended at `pbir publish -o`
rather than Step 12's PNG export.

**Listing**: the router's entry is 905 characters, 492 of description
and 413 of `when_to_use`, against 2,488 at startup for it, `pbir-cli`
and `powerbi-report-design` before the fold, plus 7,644 once the six
globs fired. This probe's startup listing ran to 26,360 characters and
rendered the router's entry whole.

**Cost**: router arms $3.61, old-shape arms $3.10, baseline arms $1.01,
the slash arm $0.41.

**What the run cannot show**: variance, with one run per arm; an edit
written rather than planned, since no arm had `Edit`; and the client
repos' listing, which runs to its cap, where this probe's did not.

## Not yet measured

Use in client work. After a few weeks of report sessions, run
`uv run --with pyyaml python scripts/skill-telemetry.py triggers`: is
`pbir-report-workflow` invoked before a hand edit of report JSON, as it
was here? Discount this run's own arms, which sit in this machine's
transcripts.
