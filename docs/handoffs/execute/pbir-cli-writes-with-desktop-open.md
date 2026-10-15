---
status: open
priority: 3
needs: [desktop]
blocked-by: []
written: 2026-10-12
---

# Handoff: check the pbir CLI's writes against Desktop's reload preview

- **Written**: 2026-10-12, on the user's word, from the question
  `powerbi-desktop-external-changes` left open, which its landing,
  `0b96d2f`, carried only in the commit body.
- **Kind**: a probe in Power BI Desktop, then an edit to
  `pbir-report-workflow`'s references. Nothing is drafted.

## What Learn says

Read 2026-10-12. "Edit PBIP files outside Power BI Desktop"
(`power-bi/developer/projects/projects-external-editing`) lists four
files that can't be edited outside Desktop during the preview:
`definition.pbir`, `report.json`, `mobileState.json` and
`semanticModelDiagramLayout.json`. It gives no paths, and does not say
what Desktop does with such an edit.

"Power BI Desktop project report folder"
(`power-bi/developer/projects/projects-report`) puts all four at the
report folder's top level, where `report.json` is the PBIR-Legacy
definition, so the list most likely means that file and not PBIR's
`definition/report.json`; that reading is inferred. The same page says
a saved edit to a supported PBIR file raises the **Apply external
changes** banner, and that a changed `RegisteredResources\` file, such
as a custom theme, loads "after a Power BI Desktop restart".

## What is open

- **`pbir report rebind`** repoints the report at another semantic
  model, a reference Learn keeps in `definition.pbir`. Unprobed: what
  Desktop does with that write while the project is open, whether it
  ignores it, errors at the banner, or overwrites it at the next save.
- **`pbir theme set-*` and `apply-template`** change the custom theme,
  which `themes.md` keeps under `StaticResources/RegisteredResources/`
  and references from `definition/report.json`. Unprobed: whether the
  banner reloads it or Desktop still needs the restart. A write to
  `definition/report.json` also tests the reading above.

## Where it runs

Power BI Desktop, August 2026 release or later, with **Detect and
reload external PBIP changes** on, on a PBIR project in git, such as
the personal sample Fabric repo kept as a test bed. Save in Desktop,
run one command, read `git status` for the files it wrote, take the
banner if one shows, then save again. Keep any repo, workspace or
client name out of what lands. Desktop 2.158.1304.0, the September 2026
release, is installed (Everything, 2026-10-15).

## Where it lands

`skills/power-bi/pbir-report-workflow/references/`: the rebind finding
in `pbir-cli.md`'s issue table, the theme finding in `themes.md`, each
saying what the failure looks like. A `references/` edit owes no
retest.

## Re-measure before acting

```bash
grep -n "rebind" skills/power-bi/pbir-report-workflow/references/pbir-cli*.md   # pbir-cli.md:34, pbir-cli-commands.md:48 on 2026-10-12
grep -n -i "restart\|external change" skills/power-bi/pbir-report-workflow/references/themes.md   # nothing on 2026-10-12
```
