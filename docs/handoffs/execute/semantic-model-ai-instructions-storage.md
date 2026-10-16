---
status: open
priority: 2
needs: [desktop]
blocked-by: []
written: 2026-10-07
---

# Handoff: find where a model's AI instructions serialize

- **Written**: 2026-10-07, by a `/triage` sweep, from one audit
  follow-up:
  2026-09-10 skills-for-fabric 05, in a run retired 2026-10-08
  (`git show 7dd627e:docs/audits/2026-09-10/skills-for-fabric/completed/05-add-lsdl-refresh-to-ai-instructions.md`),
  whose collision it carries. Re-measured at `4b6e108`: still open, and
  no source found since says where.
- **Kind**: an investigation, answered for the service and open for
  Power BI Desktop. Its corrected line landed on 2026-10-14 as its own
  change, as the follow-up's "Collision to resolve" section asks.

## What is open

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

## Settled for the service

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

On 2026-10-15 a session in a client Fabric estate found the same
absence for a model holding verified answers, set in the service: its
`getDefinition` gave no `Copilot/` part, and the answers could be read
only from an export (a note of that day; the definition format was not
recorded). So no definition part seen yet carries verified answers from
the service, which bears on item 1's verified-answer test.

## What is left

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

## Where it lands

`fabric-tmdl/references/ai-instructions.md`, and `REFERENCE.md` beside
it. Neither edit owes a retest: `skill-status.py` counts `paths:`,
`description`, `when_to_use` and a behavioural body, never
`references/`.

## Scrubbing

The 2026-10-07 note was raw: its estate's names, commit and counts stay
out, and the client repo is cited by kind. The 2026-10-14 read was of
the same estate, so its workspace names, item ids and part counts stay
out too.

## Re-measure before acting

```bash
grep -n "what writes one" skills/power-bi/fabric-tmdl/references/ai-instructions.md   # the clause to correct; landed 2026-10-14
grep -rn "CustomInstructions" skills/   # ai-instructions.md and REFERENCE.md, both since 2026-10-14
```

Re-read Learn's SemanticModel definition article too: on 2026-10-14 its
`Copilot/` example was still undescribed.
