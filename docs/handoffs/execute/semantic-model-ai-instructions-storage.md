---
status: open
priority: 2
needs: [user]
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
- **Kind**: an investigation, answered on 2026-10-07 for the culture
  file and open for a `Copilot/` folder, then at most one corrected
  line, which goes to the user as its own change, as the follow-up's
  "Collision to resolve" section asks.

## What is open

`skills/fabric/fabric-semantic-model-ai-instructions/SKILL.md:263` says
the AI-instructions blob "is not stored in TMDL". The skill's own glob,
`**/*.SemanticModel/definition/cultures/*.tmdl`, and Learn's "AI
instructions and AI data schemas save to the LSDL" point at a culture
file's `linguisticMetadata` (`fabric-tmdl/references/REFERENCE.md`).
The follow-up's 2026-09-12 behavioural run had the skill give both
answers in one session.

Re-measured 2026-10-07:

- line 263 is unchanged;
- a Learn search across the PBIP semantic-model folder and Prep data
  for AI pages found nothing saying where the instructions persist;
- upstream's `semantic-model-ai-readiness.md` at `65902bae`, the commit
  the audit read, tells agents not to "directly author or modify their
  persisted representation" and to preserve them through "MCP, TMDL,
  deployment, or metadata operations". That implies the model's
  metadata without naming the file. Inferred, not measured.

## Found in the culture file, 2026-10-07

That export now exists. In a client Fabric repo on 2026-10-07, the
first portal commit after the user set AI instructions through *Prep
data for AI* in the service added `definition/cultures/en-US.tmdl` and
`ref cultureInfo en-US` in `model.tmdl` (a note of that day, by a
session there). The culture file holds one `linguisticMetadata` JSON
value, `Version` 4.2.0, whose top-level keys are `Version`, `Language`,
`Entities`, `Relationships`, `Agents` and `CustomInstructions`, the last
holding the instructions' text. So Git sync and deployment carry the
instructions, and line 263 is wrong on that path. Re-measured
2026-10-08: line 263 is unchanged, and `CustomInstructions` appears
nowhere in the payload.

**Still open: a `Copilot/` folder.** Learn's semantic model definition
article, in its TMDL payload example, shows a `Copilot/` folder holding
`Instructions/instructions.md` and `version.json`, `VerifiedAnswers/`,
`schema.json`, `examplePrompts.json`, `settings.json` and `version.json`,
and says nothing else of them; its definition-parts table omits them
(read 2026-10-08). Which of the two a model writes, and when, is
unknown; the commit above used the culture file.

## What is left

1. Correct line 263, as its own change for the user. Drafted:

   > - Version control it with the model: a service edit's next portal
   >   commit wrote it into `definition/cultures/<culture>.tmdl`, as the
   >   `CustomInstructions` key of the culture's `linguisticMetadata`
   >   (observed 2026-10-07), so Git sync and deployment carry it.
   >   Learn's semantic model definition example also lists a
   >   `Copilot/Instructions/instructions.md` part, undescribed; which a
   >   model uses when is unverified.

2. Name `CustomInstructions` as the AI-instructions key in
   `fabric-tmdl/references/REFERENCE.md`'s `cultureInfo` section, beside
   its `linguisticMetadata` row.
3. Settle the `Copilot/` folder with an export whose definition holds
   one, from Desktop or the service. The personal sample Fabric repo can
   hold such a model.

## Where it lands

Line 263, or wherever `ai-instructions-into-fabric-tmdl.md` has moved
it: that brief moves the skill's body into
`fabric-tmdl/references/ai-instructions.md` unchanged and leaves this
question here. Whichever lands second re-reads the other. A skill edit
owes a retest (`skill-status.py --stale`).

## Scrubbing

The 2026-10-07 note was raw: its estate's names, commit and counts stay
out, and the client repo is cited by kind.

## Re-measure before acting

```bash
grep -rn "not stored in TMDL" skills/fabric/   # fabric-semantic-model-ai-instructions/SKILL.md:263 on 2026-10-07 and 2026-10-08
grep -rn "CustomInstructions" skills/          # nothing on 2026-10-08
```
