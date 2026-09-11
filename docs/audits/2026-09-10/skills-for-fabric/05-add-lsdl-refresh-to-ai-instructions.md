# Handoff: add the Git-deploy refresh requirement to fabric-semantic-model-ai-instructions

- **Audit run**: 2026-09-10
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-06` (diff base `912e06e0`) → head `65902bae`
  (2026-09-04)
- **Covers recommended actions**: 6
- **Kind**: content addition to a platform skill, from Microsoft Learn —
  with one adjacent claim the fixer must resolve or escalate first.
- **Target**:
  `skills/fabric/fabric-semantic-model-ai-instructions/SKILL.md`

## The problem

AI instructions and AI data schemas are saved to the semantic model's
linguistic schema (LSDL). When that schema changes through Git or a
deployment pipeline, the change does not take effect until the model is
refreshed in the service — and for DirectQuery and Direct Lake models,
that sync happens at most once a day. The skill never says so, which
makes an instructions change shipped by Git sync look as if it silently
failed.

## Evidence

Upstream trigger — `microsoft/skills-for-fabric` `CHANGELOG.md`,
`[0.3.15] - 2026-09-04` (release commit `65902bae`), under Fixed,
verbatim:

> **`semantic-model-authoring`** -- preserves existing Prep data for AI
> configuration during unrelated semantic model edits and uses the Power
> BI modeling MCP for read-only metadata discovery when available.

The audit found the *preservation* half already covered here:
`fabric-tmdl-api/SKILL.md` line 14 requires `updateDefinition` to carry
every part — "omitting parts deletes them". Drilling the bullet surfaced
the refresh requirement.

Learn —
[Prepare your data for AI to improve Copilot results](https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai),
Considerations and limitations, verbatim (fetched 2026-09-10):

> 11. AI instructions and AI data schemas save to the LSDL and you can
>     edit them as needed.

> 13. When you make LSDL or tooling edits through Git or deployment
>     pipelines, take note of the following requirements:
>     - **Import models**: You must refresh the model in the Power BI
>       service to sync the LSDL or tooling changes after deployment.
>     - **DirectQuery models**: You must refresh the model in the Power
>       BI service to sync the LSDL or tooling changes after deployment,
>       but only once a day.
>     - **Direct Lake models**: You must refresh the model in the Power
>       BI service to sync the LSDL or tooling changes after deployment,
>       but only once a day.

## Collision to resolve before editing

`## Testing and maintenance` (line 257) contains, verbatim:

> Version control the blob in your repo. It is not stored in TMDL —
> treat it as a separate first-class artifact.

That line appears to conflict with the evidence above. Learn says the
instructions save to the LSDL. In a PBIP or Git export the linguistic
schema is serialized as `linguisticMetadata` in
`definition/cultures/<culture>.tmdl` — see
`skills/fabric/fabric-tmdl/references/REFERENCE.md` lines 292–302. And
this skill's own `paths:` glob targets exactly those files:
`**/*.SemanticModel/definition/cultures/*.tmdl`.

**The audit did not assess this line, and it is not one of the report's
recommended actions.** Check a real export's `cultures/*.tmdl` for the
instructions text before deciding anything. If the line is wrong, put
the correction back to the user as its own change rather than folding it
into this one. What must not happen is the refresh fact landing directly
beneath an unresolved "not stored in TMDL": the section would then
assert both that Git carries the instructions and that it does not.

## What to change

Add the refresh requirement to `SKILL.md`. `## Testing and maintenance`
(line 257) fits, since that is where versioning the blob is discussed;
`## Limitations to be aware of` (line 244) also works. State: changes to
AI instructions or AI data schemas that arrive by Git sync or deployment
pipeline need a service refresh to take effect, and DirectQuery and
Direct Lake models sync them only once a day.

## Verification

1. `grep -niE 'refresh|LSDL|once a day' skills/fabric/fabric-semantic-model-ai-instructions/SKILL.md`
   — the requirement is present.
2. `grep -n 'not stored in TMDL' skills/fabric/fabric-semantic-model-ai-instructions/SKILL.md`
   — either gone, with the user's agreement, or still present with the
   collision escalated. It must not sit beside the new text unaddressed.
3. Re-fetch the Learn page and confirm items 11 and 13.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-semantic-model-ai-instructions/SKILL.md`
5. `pre-commit run --all-files`

## Sequencing note

Kept apart from briefs 02 and 03 although all three add a Learn fact to
a skill: this one targets a different skill and page, and it carries the
collision above, which needs a user decision the other two do not.

## Provenance

First `/drift-audit --sources skills-for-fabric` run, 2026-09-10. The
refresh requirement surfaced while drilling a 0.3.15
`semantic-model-authoring` bullet whose own claim was already covered.
The collision was noticed while writing this brief, not during the
audit.
