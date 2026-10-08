---
status: open
priority: 2
needs: [a model export with AI instructions set]
blocked-by: []
written: 2026-10-07
---

# Handoff: find where a model's AI instructions serialize

- **Written**: 2026-10-07, by a `/triage` sweep, from one audit
  follow-up:
  [2026-09-10 skills-for-fabric 05](../../audits/2026-09-10/skills-for-fabric/completed/05-add-lsdl-refresh-to-ai-instructions.md),
  whose collision it carries. Re-measured at `4b6e108`: still open, and
  no source found since says where.
- **Kind**: an investigation, then at most one corrected line, which
  goes to the user as its own change, as the follow-up's "Collision to
  resolve" section asks.

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

## What settles it

A model with AI instructions set, in Desktop or the service, exported
as a PBIP or by Git sync: search its `definition/cultures/*.tmdl` for
the instructions' text. Found, line 263 is wrong; not found, record
where they do live. The personal sample Fabric repo can hold such a
model.

## Where it lands

Line 263, or wherever `ai-instructions-into-fabric-tmdl.md` has moved
it: that brief moves the skill's body into
`fabric-tmdl/references/ai-instructions.md` unchanged and leaves this
question here. Whichever lands second re-reads the other. A skill edit
owes a retest (`skill-status.py --stale`).

## Re-measure before acting

```bash
grep -rn "not stored in TMDL" skills/fabric/   # fabric-semantic-model-ai-instructions/SKILL.md:263 on 2026-10-07
```
