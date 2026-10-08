---
status: open
priority: 3
needs: [desktop]
blocked-by: []
written: 2026-10-08
---

# Handoff: settle whether TMDL rejects space indentation

- **Written**: 2026-10-08, by the pass that worked prompt-audit 2026-10-08
  brief 06 with the naming brief it was sequenced behind, on the user's
  call to brief this rather than correct it in that pass.
- **Kind**: a probe in Power BI Desktop, then an edit to a platform
  skill. Nothing is drafted.

## What is open

`skills/fabric/fabric-tmdl/SKILL.md` says "Spaces cause validation
errors" (line 15 on 2026-10-08), and its troubleshooting table blames
"Spaces-for-tabs validation errors" on an editor expanding tabs (line
216). One parser disagrees, and Learn does not settle it:

- The TMDL overview says "A TMDL document uses a default single tab
  indentation rule" and "Not following these indention rules generates
  a parsing error" (read 2026-10-08). That is a default, not a ban, and
  most of the page's own example blocks are space-indented in its HTML.
- TOM 19.96.1's `TmdlSerializer`, the SqlServer module's copy, loaded a
  table file indented with four spaces, one with two, and one mixing
  tab-indented columns with a four-space measure (probed 2026-10-08).

Not run: Power BI Desktop's **Apply external changes**, or opening the
project fresh, on a space-indented table file. Desktop ships its own,
newer TOM, and may be stricter. A Fabric Git sync is a third parser,
also unprobed.

## Reproducing the probe

```powershell
$base = "$env:USERPROFILE\Documents\PowerShell\Modules\SqlServer\22.4.5.1\coreclr"
Add-Type -Path "$base\Microsoft.AnalysisServices.Core.dll", "$base\Microsoft.AnalysisServices.Tabular.Json.dll", "$base\Microsoft.AnalysisServices.Tabular.dll"
[Microsoft.AnalysisServices.Tabular.TmdlSerializer]::DeserializeDatabaseFromFolder('<a definition folder>')
```

A `database.tmdl` with `compatibilityLevel: 1567` and a `model.tmdl`
with `culture: en-US` beside one `tables/*.tmdl` is enough. A bad line
throws `TmdlFormatException`, its innermost message naming the line.

## Where it runs

Power BI Desktop, on a PBIP project, such as the personal sample Fabric
repo kept as a test bed: re-indent one table file with spaces, then
apply the external change. Keep any repo, workspace or client name out
of what lands.

## Decision after probing

- **Desktop loads it**: line 15 becomes a default, not a ban — write
  tabs, since the serializer writes them, while a space-indented file
  still loads (with the version probed) — and line 216's row goes.
- **Desktop rejects it**: both lines stand. Add Desktop's error text to
  line 216's row, and that TOM 19.96.1 alone is laxer.

`claude/rules/coding-tmdl.md` § "Copying syntax from Learn" quotes only
Learn's default and holds either way.

## Where it lands

`skills/fabric/fabric-tmdl/SKILL.md`, a platform skill, deployed only
where a `-ClaudeDir` run linked it. A body edit owes a retest:
`uv run --with pyyaml scripts/skill-status.py --stale` says so.

## Re-measure before acting

```bash
grep -n "Spaces cause\|Spaces-for-tabs" skills/fabric/fabric-tmdl/SKILL.md   # lines 15 and 216 on 2026-10-08
```
