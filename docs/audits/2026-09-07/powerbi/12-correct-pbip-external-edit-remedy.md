# Handoff: correct the obsolete external-edit remedy in `pbip-project-structure`

- **Audit run**: 2026-09-07 (**second** run — see Provenance)
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 2 of **`00b-audit-report-rerun.md`**
  (not of `00-audit-report.md`; two audits of this window ran on this
  date)
- **Kind**: factual correction to committed skill prose. No behaviour
  change, no frontmatter change, **not gated on any empirical step** —
  one grep verifies it. Distinct from brief `06`; see Sequencing.
- **Target**: `skills/powerbi/pbip-project-structure/SKILL.md`

## The problem

`pbip-project-structure/SKILL.md:213` prescribes a workaround that the
August 2026 release made unnecessary:

> `| PBI Desktop ignores external edits | Stale in-memory state | Close and reopen Desktop |`

Power BI Desktop now **detects changes to PBIP project files and prompts
you to apply them with a single click**. An agent following this skill
today will tell a user to close and reopen Desktop — discarding unsaved
in-app state — to achieve something a prompt now offers in place.

This is the higher-value half of a two-part staleness. The other half,
in a different file, is already covered by brief `06`.

## Evidence

`https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview`
states it twice.

Under **Model authoring** → *Keep in mind*, verbatim:

> When you save changes to project files outside Power BI Desktop, Power
> BI Desktop detects the changes and prompts you to apply them with a
> single click. You can also open the project directly in Visual Studio
> Code by using the built-in entry point in Power BI Desktop.

And in the FAQ, verbatim:

> **Question:** Is Power BI Desktop aware of changes I make to the Power
> BI Project files from an external tool or application?
>
> **Answer:** Yes. Power BI Desktop detects changes made to project files
> and prompts you to apply them with a single click.

Restated in **Considerations and limitations**:

> Power BI Desktop detects changes you make by using other tools or
> applications and prompts you to apply them. A built-in entry point in
> Power BI Desktop opens the project directly in Visual Studio Code.

Two facts from the same page that bound the edit:

- **PBIP is still preview.** "Power BI Desktop projects is currently in
  **preview**", and saving as PBIP still requires *File > Options and
  settings > Options > Preview features > Power BI Project (.pbip) save
  option*.
- Editing project files outside Desktop is still explicitly caveated:
  changes "can cause unexpected errors, or even prevent Power BI Desktop
  from opening", and four files (`report.json`, `mobileState.json`,
  `semanticModelDiagramLayout.json`, `diagramLayout.json`) remain
  undocumented and unsupported for external editing during preview.

### Current local coverage

Two lines in one file:

- `SKILL.md:213` — the obsolete remedy quoted above.
- `SKILL.md:139` — the PBIX-vs-PBIP table row:
  `| External editing | Not supported | VS Code, pbir CLI, scripts |`
  Accurate as far as it goes; the built-in VS Code entry point is a
  natural addition here.

## What to change

One file, two lines.

1. **`SKILL.md:213`** — replace the remedy. Desktop detects external
   changes and prompts to apply them; closing and reopening is no longer
   the fix. Keep a row for the symptom rather than deleting it — if the
   prompt is dismissed or does not appear, a reader still needs
   somewhere to land.
2. **`SKILL.md:139`** — optionally note the built-in entry point that
   opens the project directly in VS Code. This is an addition, not a
   correction; the existing cell is not wrong.

## Constraint on the fix

**Do not delete the external-edit cautions while removing the stale
remedy.** The same upstream page that documents auto-detection still
warns that external edits can prevent Desktop from opening, and still
lists four files as unsupported for external editing during preview.
Those cautions are unaffected by this change and the skill should keep
them.

**Do not describe PBIP as GA.** It remains preview and still requires the
preview-features toggle. Nothing in this window changed that.

## Sequencing note

**Not the same work as brief `06`
(`06-verify-pbip-autodetect-vs-reload-bridge.md`), and neither blocks the
other.** That brief targets a different file —
`powerbi-report-authoring/references/powerbi-desktop.md` — and asks an
empirical question: does the new apply-changes prompt, being a Desktop
modal, block the `powerbi-desktop reload --pid` bridge that skill
documents? It is correctly gated on testing before any edit.

This brief is a plain prose correction in `pbip-project-structure` with
no such gate, and should not be held behind `06`'s verification. If both
are done together, `06`'s finding may add a caveat here about the prompt
being modal — but that is an enhancement, not a precondition.

## Verification

1. `grep -rn "Close and reopen Desktop" skills/powerbi --include=*.md`
   — should return nothing after the edit.
2. `grep -rniE "detects (the )?changes|prompts you to apply" skills/powerbi/pbip-project-structure --include=*.md`
   — the replacement landed.
3. `grep -rniE "preview features|\.pbip\) save option" skills/powerbi/pbip-project-structure --include=*.md`
   — confirms the preview framing survived, per Constraint.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/powerbi/pbip-project-structure/SKILL.md`
5. `pre-commit run --all-files`.

## Provenance

Found by the **second** `powerbi` drift audit run on 2026-09-07, against
the same window and head as the first.

Both runs found the same upstream change; they landed it on **different
files**. The first mapped it to `powerbi-desktop.md` and framed it as a
question about the reload bridge (brief `06`). The second mapped it to
`pbip-project-structure/SKILL.md:213`, where an explicit obsolete remedy
sits in a troubleshooting table. Neither mapping is wrong and the two
targets are both real — which is why this brief exists rather than being
folded into `06`. The `SKILL.md:213` line is named in no other brief in
this directory.
