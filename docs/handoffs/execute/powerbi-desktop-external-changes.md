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
- **Kind**: an edit to two `powerbi` skills from Learn, which a session
  can make alone, and one check left for a Desktop session. Nothing is
  drafted.

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

- `skills/powerbi/powerbi-report-authoring/references/powerbi-desktop.md`
  runs the loop, `powerbi-desktop reload --pid`, and its theme-cache
  workaround (lines 106–108 on 2026-10-07) renames a theme file and
  updates its registration in `report.json`. Learn's list names that
  file. Whether the limit binds the bridge's `file.reload/v1` or only
  the banner, Learn does not say; "close and reopen Desktop", the
  workaround's other half, is safe either way.
- `skills/powerbi/pbip-project-structure/SKILL.md:215`, § Gotchas, says
  to take the apply prompt. It shows only with the preview on.
- 06's own question, whether the prompt blocks or races a scripted
  reload, is narrower now: the prompt is opt-in, and Learn calls it a
  banner. How it behaves under automation is still empirical.

## Where it lands

The two files above, each owing a retest (`skill-status.py --stale`).
06's constraint holds: no caveat on behaviour Learn does not state.

## Not checked

- **The Desktop check**: Desktop running with a PBIP open, the preview
  on, the bridge CLI installed
  (`npm install -g @microsoft/powerbi-desktop-bridge-cli@latest`, as
  `powerbi-desktop.md:32` gives it; not installed here on 2026-10-07).
  Then edit a PBIR file, leave the banner up, run `reload`, and record
  the build. 06's decision tree says what each outcome changes.
- The Desktop build now installed; 2.157.1354.0 was recorded on
  2026-09-08.

## Re-measure before acting

```bash
grep -n "report.json" skills/powerbi/powerbi-report-authoring/references/powerbi-desktop.md   # line 108 on 2026-10-07
grep -n -i "prompt" skills/powerbi/pbip-project-structure/SKILL.md                              # line 215
npm ls -g --depth=0 | grep -i powerbi                                                           # nothing on 2026-10-07
```
