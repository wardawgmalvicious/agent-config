---
status: open
priority: 2
needs: [desktop]
blocked-by: []
written: 2026-10-07
---

# Handoff: four Power BI Desktop probes, run in one sitting

- **Merged**: 2026-10-15, on the user's word, from four briefs that each
  waited on Desktop and nothing else, written 2026-10-07 to 2026-10-12:
  `pbir-august-formatting-properties.md`,
  `pbir-cli-writes-with-desktop-open.md`,
  `semantic-model-ai-instructions-storage.md` and
  `tmdl-space-indentation.md`. Each part below is one of them,
  re-headed; `git log --diff-filter=D -- docs/handoffs/execute/<name>.md`
  finds the commit that merged it.
- **Kind**: four probes in Power BI Desktop, then edits to
  `pbir-report-workflow`'s references (parts 1 and 2) and to
  `fabric-tmdl` (parts 3 and 4). Nothing is drafted.
- **Each part lands on its own**: the commit that lands a part's edit
  drops its section, and the last one deletes the brief.

## The sitting

Power BI Desktop 2.158.1304.0, the September 2026 release, is installed
(Everything, 2026-10-15), past the August 2026 floor parts 1 and 2 set.
One PBIP project in git serves all four, a PBIR report over a TMDL
model, such as the personal sample Fabric repo kept as a test bed,
unless its model is Direct Lake, which part 3 cannot use (below). Turn
on **Detect and reload external
PBIP changes** for parts 2 and 4, which write files outside Desktop,
and save in Desktop before each part, so `git status` shows only what
that part wrote. Keep any repo, workspace or client name out of what
lands.

## Part 1: confirm the August 2026 formatting properties in a PBIP export

- **Written**: 2026-10-07, by a `/triage` sweep, from four follow-ups of
  the 2026-09-07 `powerbi` audit: 04, 10, 13 and the JSON half of 09.
  Each reads back with
  `git show 7dd627e:docs/audits/2026-09-07/powerbi/completed/<file>`.
- **Narrowed**: 2026-10-12. Report theme schema 2.157, which `pbir`
  0.9.32, the latest, does not bundle, named all but one of the settings
  this brief held for Desktop. The names landed in
  `pbir-report-workflow`'s `visual-json.md`, § "August 2026 formatting
  properties", which says what was measured; the commit that narrowed
  this brief says how. What is left needs a PBIP saved by Desktop.
- **Kind**: a probe in Power BI Desktop, then an edit to
  `pbir-report-workflow`'s references. The follow-ups' constraint
  stands: a name comes from a schema or an export, never from a UI label.

### What only an export settles

1. **Desktop writes the 2.157 names**: `categoryAxis.outerPadding`,
   `selection.singleDate`, the slicer `dropdown` object,
   `items.expandCollapseIconColor`, the matrix `columnHeaders` +/- icons,
   and the donut's `centerValue`, `value`, `label`, `image` and
   `centerBackground`, rather than the names `pbir`'s June catalog shows
   (`background`, `valueBold`, `valueDisplayUnits` …).
2. **The suffix each number takes**, which a schema type does not
   decide: `pbir set` writes `innerPadding` as `20D`, while
   skills-for-fabric v0.3.13's examples wrote `26L`
   (`git show 79eddb3:skills/powerbi/powerbi-report-authoring/references/cartesian.md`,
   line 528).
3. **The freeze toggle**: whether **Layout** > **Freeze** > **Row
   headers** writes `rowHeaders.unfrozen`, and whether off is `true`.
4. **The Field-value icon** (09): the `values.icon` shape when the
   **Icons** format style is **Field value**, which
   `conditional-formatting.md` withholds.

### Where it runs

Set each setting on a visual of its type, save, and read the
`visual.json` diff.

### Where it lands

`skills/power-bi/pbir-report-workflow/references/`: `visual-json.md` §
"August 2026 formatting properties" drops each caveat the export
settles and corrects any name it contradicts, and
`conditional-formatting.md` gains item 4. A `references/` edit owes no
retest.

### Re-measure before acting

```bash
pbir --version              # 0.9.29 on 2026-10-12; 0.9.32 bundles the same schemas
pbir schema status          # reportThemeSchema 2.155 local, 2.157 remote on 2026-10-12
grep -n "August 2026" skills/power-bi/pbir-report-workflow/references/visual-json.md
```

## Part 2: check the pbir CLI's writes against Desktop's reload preview

- **Written**: 2026-10-12, on the user's word, from the question
  `powerbi-desktop-external-changes` left open, which its landing,
  `0b96d2f`, carried only in the commit body.
- **Kind**: a probe in Power BI Desktop, then an edit to
  `pbir-report-workflow`'s references. Nothing is drafted.

### What Learn says

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

### What is open

- **`pbir report rebind`** repoints the report at another semantic
  model, a reference Learn keeps in `definition.pbir`. Unprobed: what
  Desktop does with that write while the project is open, whether it
  ignores it, errors at the banner, or overwrites it at the next save.
- **`pbir theme set-*` and `apply-template`** change the custom theme,
  which `themes.md` keeps under `StaticResources/RegisteredResources/`
  and references from `definition/report.json`. Unprobed: whether the
  banner reloads it or Desktop still needs the restart. A write to
  `definition/report.json` also tests the reading above.

### Where it runs

Save in Desktop, run one command, read `git status` for the files it
wrote, take the banner if one shows, then save again.

### Where it lands

`skills/power-bi/pbir-report-workflow/references/`: the rebind finding
in `pbir-cli.md`'s issue table, the theme finding in `themes.md`, each
saying what the failure looks like. A `references/` edit owes no
retest.

### Re-measure before acting

```bash
grep -n "rebind" skills/power-bi/pbir-report-workflow/references/pbir-cli*.md   # pbir-cli.md:34, pbir-cli-commands.md:48 on 2026-10-12
grep -n -i "restart\|external change" skills/power-bi/pbir-report-workflow/references/themes.md   # nothing on 2026-10-12
```

## Part 3: find where a model's AI instructions serialize

- **Written**: 2026-10-07, by a `/triage` sweep, from one audit
  follow-up:
  2026-09-10 skills-for-fabric 05, in a run retired 2026-10-08
  (`git show 7dd627e:docs/audits/2026-09-10/skills-for-fabric/completed/05-add-lsdl-refresh-to-ai-instructions.md`),
  whose collision it carries. Re-measured at `4b6e108`: still open, and
  no source found since says where.
- **Kind**: an investigation, answered for the service and open for
  Power BI Desktop. Its corrected line landed on 2026-10-14 as its own
  change, as the follow-up's "Collision to resolve" section asks.

### What is open

Whether a Power BI Desktop save writes a `Copilot/` folder, and the
instructions into its `Instructions/instructions.md`. Learn's semantic
model definition article shows one in its TMDL payload example, holding
`Instructions/instructions.md` and `version.json`, `VerifiedAnswers/`,
`schema.json`, `examplePrompts.json`, `settings.json` and
`version.json`, and says nothing else of them; its definition-parts
table omits them (read 2026-10-08 and 2026-10-14). Microsoft's
`json-schemas` repo has held schemas under
`fabric/item/semanticModel/copilot/` since 2025-11-20, for
`examplePrompts`, `schema` and `settings`, the last with one property,
`indexingEnabled`. None covers `Instructions/`, and the repo's semantic
model `definitionStructure/1.0.0` names no `Copilot/` path (read
2026-10-14). No `*.SemanticModel\Copilot` folder exists on this machine
(Everything, 2026-10-14).

It matters because `fabric-tmdl` loads on such files, by its
`**/*.SemanticModel/**` glob, and its guidance names the culture file as
the instructions' home. The same example also lists
`Copilot/VerifiedAnswers/`, against `ai-instructions.md`'s "Verified
answers never travel with the model", from Learn's verified answers page
(read 2026-10-08).

### Settled for the service

In a client Fabric repo on 2026-10-07, the first portal commit after the
user set AI instructions through *Prep data for AI* in the service added
`definition/cultures/en-US.tmdl` and `ref cultureInfo en-US` in
`model.tmdl` (a note of that day, by a session there). The culture file
holds one `linguisticMetadata` JSON value, `Version` 4.2.0, whose
top-level keys are `Version`, `Language`, `Entities`, `Relationships`,
`Agents` and `CustomInstructions`, the last holding the instructions'
text.

On 2026-10-14 a read-only `getDefinition`, TMDL format, of that model in
the workspace Git-connected to that folder returned a culture file with
the same six keys, `CustomInstructions` a non-empty string, and no
`Copilot/` part. Its copies in other workspaces were not read.

So Git sync and deployment carry the instructions. On 2026-10-14
`ai-instructions.md`'s "Version control the instructions blob" bullet
replaced "It is not stored in TMDL", and `REFERENCE.md`'s `cultureInfo`
row gained the key.

### What is left

1. In a current Power BI Desktop, set an AI instruction on any model,
   and a verified answer to test that bullet too, save it as PBIP to a
   scratch folder, and look for `Copilot/`. Found: record its files, and
   whether `instructions.md` and the culture's `CustomInstructions` both
   hold the text. Not found: record that the culture file alone carries
   it from Desktop too.
2. Correct that bullet's last clause, "what writes one, and whether a
   Power BI Desktop save does, is unverified", to the finding, as its
   own change for the user: `REFERENCE.md`'s row too if the culture key
   proves one route of two, and the verified-answers bullet if
   `VerifiedAnswers/` holds one.

Desktop's side, from Learn (read 2026-10-15, "Prepare your data for AI"
and its AI-instructions page under `power-bi/create-reports/`): **Prep
data for AI** is a preview feature, under **File** > **Options and
settings** > **Options** > **Preview features**; its tabs stay disabled
until Q&A is on for the model; and Desktop offers it only on Import,
DirectQuery and local composite models, so a Direct Lake model will not
do. A verified answer is set from a visual's **...** menu, and every
update saves on the semantic model, not the report. The overview says AI
instructions and AI data schemas "save to the LSDL", the linguistic
schema, which fits the culture file's `linguisticMetadata` in the
service, though the page names no file. Copilot in Desktop needs a
sign-in and a Copilot-capable workspace; whether authoring alone does,
Learn does not say.

### Where it lands

`fabric-tmdl/references/ai-instructions.md`, and `REFERENCE.md` beside
it. Neither edit owes a retest: `skill-status.py` counts `paths:`,
`description`, `when_to_use` and a behavioural body, never
`references/`.

### Scrubbing

The 2026-10-07 note was raw: its estate's names, commit and counts stay
out, and the client repo is cited by kind. The 2026-10-14 read was of
the same estate, so its workspace names, item ids and part counts stay
out too.

### Re-measure before acting

```bash
grep -n "what writes one" skills/power-bi/fabric-tmdl/references/ai-instructions.md   # the clause to correct; landed 2026-10-14
grep -rn "CustomInstructions" skills/   # ai-instructions.md and REFERENCE.md, both since 2026-10-14
```

Re-read Learn's SemanticModel definition article too: on 2026-10-14 its
`Copilot/` example was still undescribed.

## Part 4: settle whether TMDL rejects space indentation

- **Written**: 2026-10-08, by the pass that worked prompt-audit 2026-10-08
  brief 06 with the naming brief it was sequenced behind, on the user's
  call to brief this rather than correct it in that pass.
- **Kind**: a probe in Power BI Desktop, then an edit to a platform
  skill. Nothing is drafted.

### What is open

`skills/power-bi/fabric-tmdl/SKILL.md` says "Spaces cause validation
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

### Reproducing the probe

```powershell
$base = "$env:USERPROFILE\Documents\PowerShell\Modules\SqlServer\22.4.5.1\coreclr"
Add-Type -Path "$base\Microsoft.AnalysisServices.Core.dll", "$base\Microsoft.AnalysisServices.Tabular.Json.dll", "$base\Microsoft.AnalysisServices.Tabular.dll"
[Microsoft.AnalysisServices.Tabular.TmdlSerializer]::DeserializeDatabaseFromFolder('<a definition folder>')
```

A `database.tmdl` with `compatibilityLevel: 1567` and a `model.tmdl`
with `culture: en-US` beside one `tables/*.tmdl` is enough. A bad line
throws `TmdlFormatException`, its innermost message naming the line.

### Where it runs

Re-indent one table file with spaces, then apply the external change.

### Decision after probing

- **Desktop loads it**: line 15 becomes a default, not a ban — write
  tabs, since the serializer writes them, while a space-indented file
  still loads (with the version probed) — and line 216's row goes.
- **Desktop rejects it**: both lines stand. Add Desktop's error text to
  line 216's row, and that TOM 19.96.1 alone is laxer.

`claude/rules/coding-tmdl.md` § "Copying syntax from Learn" quotes only
Learn's default and holds either way.

### Where it lands

`skills/power-bi/fabric-tmdl/SKILL.md`, a platform skill, deployed only
where a `-ClaudeDir` run linked it. A body edit owes a retest:
`uv run --with pyyaml scripts/skill-status.py --stale` says so.

### Re-measure before acting

```bash
grep -n "Spaces cause\|Spaces-for-tabs" skills/power-bi/fabric-tmdl/SKILL.md   # lines 15 and 216 on 2026-10-08, 22 and 231 on 2026-10-15
```
