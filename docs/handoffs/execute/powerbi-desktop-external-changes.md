---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-07
---

# Handoff: say what Desktop's external-change detection does to the reload loop

- **Written**: 2026-10-07, by a `/triage` sweep, from one audit
  follow-up:
  2026-09-07 powerbi 06, in a run retired 2026-10-08
  (`git show 7dd627e:docs/audits/2026-09-07/powerbi/completed/06-verify-pbip-autodetect-vs-reload-bridge.md`),
  an investigation that could not start without Desktop. Re-measured at
  `4b6e108`: Learn now documents most of what it set out to find.
- **Kind**: an edit to `pbip-project-structure` from Learn, which a
  session can make alone. Nothing is drafted. Its other half, and the
  Desktop check that half needed, lapsed on 2026-10-09 when
  [platform-skill-portfolio.md](platform-skill-portfolio.md) chose to
  archive `powerbi-report-authoring`.

## What Learn says now

Read 2026-10-07 through `microsoft-learn-mcp`: "Edit PBIP files
outside Power BI Desktop" (`power-bi/developer/projects/projects-external-editing`)
and "What is the Power BI Desktop Bridge?"
(`power-bi/developer/agentic/power-bi-desktop-bridge-overview`).

- **Detection is a preview you switch on**: Options › Preview features
  › "Detect and reload external PBIP changes", then restart, on the
  August 2026 release or later.
- **It shows a banner, not a dialog**: "Apply external changes". With
  unsaved changes in Desktop, applying warns that they will be
  overwritten.
- **The bridge is the documented route for a script**. One operation
  runs at a time; `application.state.get/v1` reports
  `hasUnsavedChanges`; `file.reload/v1` takes `reloadModelDefinition`.
  The bridge's own setting, Options › Security › Desktop Bridge, is on
  by default, and an admin can turn it off by the registry policy
  `DesktopNamedPipeBridge`.
- **Four files cannot be edited outside Desktop during the preview**:
  `definition.pbir`, `report.json`, `mobileState.json` and
  `semanticModelDiagramLayout.json`. A reload resets filters and some
  of the UI, and does not reload `cache.abf`.

## What it touches here

- `skills/powerbi/pbip-project-structure/SKILL.md:215`, § Gotchas, says
  to take the apply prompt. It shows only with the preview on.
- **Lapsed**: `powerbi-report-authoring`'s
  `references/powerbi-desktop.md` ran the scripted loop,
  `powerbi-desktop reload --pid`, and its theme-cache workaround (lines
  106–108 on 2026-10-07) edits `report.json`, which Learn's list names.
  06's own question, whether the banner blocks or races a scripted
  reload, bore on that loop alone. With the skill archived, nothing here
  scripts a reload; if it is ever re-vendored from upstream, check its
  workaround against the four-file limit then.

## Where it lands

`pbip-project-structure/SKILL.md`, owing a retest
(`skill-status.py --stale`). 06's constraint holds: no caveat on
behaviour Learn does not state.

## Not checked

Whether the four-file limit binds the `pbir` CLI's own writes to
`report.json` while Desktop holds the PBIP open with the preview on. If
it does, `pbir-report-workflow`'s references owe the caveat, once
[pbir-skills-into-pbir-report-workflow.md](pbir-skills-into-pbir-report-workflow.md)
has landed.

## Re-measure before acting

```bash
grep -n -i "prompt" skills/powerbi/pbip-project-structure/SKILL.md   # line 215 on 2026-10-07
```
