---
status: open
priority: 2
needs: [fabric audit brief 20 of 2026-10-06 executed]
blocked-by: []
written: 2026-10-06
---

# Handoff: fold fabric-semantic-model-ai-instructions into fabric-tmdl

- **Written**: 2026-10-06, by the session that wrote
  `fabric-deploy-skill.md`, from the user's observation that this skill
  reads as a reference document rather than a skill. Measured against
  the payload at `3c69353`.
- **Kind**: a move, done by hand, then `/test-skill fabric-tmdl`. The
  skill's body becomes `fabric-tmdl/references/ai-instructions.md`, and
  the skill goes. No content changes: nothing is drilled, and the
  storage question below stays open.
- **Independent of the deploy pilot**: this tests no router, only that
  a reference-shaped skill can live under the skill that owns its
  moment.

## Why

It owns no trigger. Its glob,
`**/*.SemanticModel/definition/cultures/*.tmdl`, sits inside both
`fabric-tmdl`'s (`**/*.tmdl`, `**/*.SemanticModel/**`) and
`fabric-tmdl-api`'s (`**/*.SemanticModel/**`), so it never activates
alone: `tests/skills/pbip-triggers/expected_activations.md:31` records
all three firing on a culture file.

- **Workstream C's "leave alone" rested on a wrong premise.** C3, in
  the retired `skill-context-cost.md` (2026-08-31), called the two
  globs disjoint, with 0 co-activations measured. At that brief's
  commit, `0cfcb74`, `fabric-tmdl` already globbed `**/*.tmdl`. Unlike
  C1 and C2, C3's call was never written into an
  `expected_activations.md`, so nothing there needs correcting; say it
  in the commit message instead.
- **Its glob may point at the wrong file.** `SKILL.md:263` says the
  blob "is not stored in TMDL", while the glob assumes the culture
  file's `linguisticMetadata`, which is where Learn's "save to the
  LSDL" would put it (`fabric-tmdl/references/REFERENCE.md:292-298`).
  `docs/audits/2026-09-10/skills-for-fabric/05-add-lsdl-refresh-to-ai-instructions.md`
  has held that open since 2026-09-11, needing a model export with AI
  instructions set, and its 2026-09-12 behavioural run had the skill
  give both answers in one session.
- **It was never reached in client work**: no activation and no
  invocation in the client Fabric repos' sessions, 2026-09-24 to
  2026-10-06.
- Folding drops one listing entry, 677 description characters, from
  every culture-file activation.

## Shape

| Today | After |
| --- | --- |
| `fabric-semantic-model-ai-instructions/SKILL.md` | `fabric-tmdl/references/ai-instructions.md`, by `git mv` |
| `fabric-semantic-model-ai-instructions/references/REFERENCE.md` | appended to that file as its link list, then removed |

- Strip the moved file's frontmatter. Drop its "See also", which
  points at "your internal tooling repo" and so at nothing, and
  re-point its link to `references/REFERENCE.md`. Change nothing else,
  line 263 included: settling it is brief 05's work.
- `fabric-tmdl`'s `description`, 490 characters, gains trigger words
  only: "AI instructions" and "Prep data for AI". Its body gains one
  pointer: to write the model's AI instructions, or edit a culture
  file's `linguisticMetadata`, read `references/ai-instructions.md`
  first.
- Whatever brief 20 D-1 does to `fabric-tmdl`'s `paths:`, the culture
  files must stay inside it. Check before editing.

## The rename trap

Change each of these in the commit that folds:

- `.claude/settings.json:47` `skillOverrides`: remove the entry.
  `lint-skill-overrides` fails until then.
- `tests/skills/pbip-triggers/expected_activations.md:31`: drop the
  skill from the culture-file row and recompute its `Tokens` cell as
  that file's README says, then run
  `./scripts/test-activation.ps1 -Set pbip -StaticOnly`.
- `tests/skills/.tested.json:191`: drop the stamp. The description
  edit makes `fabric-tmdl` stale too (`skill-status.py --stale`).
- `skills/README.md:251`: drop the bullet.
- Prose routing to the skill: `fabric-data-agent/SKILL.md:31` and
  `fabric-semantic-model-audit/SKILL.md:258` point at `fabric-tmdl`'s
  reference instead.
- The drift-audit registry's skills-for-fabric rows,
  `.claude/skills/drift-audit/references/sources.md:674` and `:689` on
  2026-10-06. `drift-registry-per-source.md` splits that file, so find
  the rows wherever they then live.
- Brief 05 stays open: append a `**Needs**:` line naming the moved
  file, with the same need, since the last line counts
  (`docs/handoffs/execute/README.md` § "Audit briefs are a second
  queue"). The rest of `docs/audits/` stays as written.
- `.claude/skills/test-skill/SKILL.md:98` and `:208` cite this skill as
  dated history: leave them.

```bash
grep -rn 'semantic-model-ai-instructions' --exclude-dir=audits --exclude-dir=.git .
```

**Client repos**: relink each repo holding the `fabric` group with
exactly the groups it already holds, as `fabric-deploy-skill.md` says;
the relink prunes the dangling junction.

## Verify

1. The static activation check passes with the new row, and
   `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-tmdl/SKILL.md`
   is clean.
2. `/test-skill fabric-tmdl`, behaviour, against a `--safe-mode`
   baseline: after a culture file is Read, ask for AI instructions for
   the model. Passes when `fabric-tmdl` is invoked, reads
   `references/ai-instructions.md`, and the answer keeps what the old
   skill carried: the 10,000-character cap, and the service refresh a
   Git or deployment-pipeline change needs, once a day for DirectQuery
   and Direct Lake, which the 2026-09-12 run confirmed.
3. `pre-commit run --all-files`.

## Re-measure before acting

- Brief 20 edits `fabric-tmdl`'s `paths:` (D-1) and this skill's Q&A
  retirement dates (D-2 row 10). Read its execution log, then re-read
  both skills: line numbers above will have moved.
- If brief 05 has been settled by then, the moved file says so: carry
  its result, not the question.
- `fabric-deploy-skill.md` edits the same shared files
  (`skillOverrides`, `skills/README.md`, `.tested.json`, the registry).
  If both run at once, the second to land rebases over the first.

## Not checked

Where the AI instructions really serialize: brief 05 owns that.

## Scrubbing

Client repos are named by kind, and no workspace, model or tenant is
named.
