---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-06
---

# Handoff: fold fabric-semantic-model-ai-instructions and fabric-tmdl-api into fabric-tmdl

- **Written**: 2026-10-06, by the session that wrote
  `fabric-deploy-skill.md`, from the user's observation that this skill
  reads as a reference document rather than a skill. Measured against
  the payload at `3c69353`.
- **Widened**: 2026-10-09, by the user's decision in
  [platform-skill-portfolio.md](platform-skill-portfolio.md):
  `fabric-tmdl-api` folds here too, so `fabric-tmdl` takes one test run
  for both. Measured at `9535085`.
- **Kind**: two moves, done by hand, then `/test-skill fabric-tmdl`. The
  skills' bodies become `fabric-tmdl/references/ai-instructions.md` and
  `fabric-tmdl/references/definition-api.md`, and both skills go. No
  content changes: nothing is drilled, and the storage question below
  stays open.
- **Independent of the deploy pilot**: this tests no router, only that
  a reference-shaped skill can live under the skill that owns its
  moment.

## Why

Neither skill owns a trigger. The AI-instructions skill's glob,
`**/*.SemanticModel/definition/cultures/*.tmdl`, sits inside
`**/*.SemanticModel/**`, which `fabric-tmdl` and `fabric-tmdl-api` both
carry (2026-10-09), so it never activates alone:
`tests/skills/pbip-triggers/expected_activations.md:31` records all
three firing on a culture file.

- **`fabric-tmdl-api` rides `fabric-tmdl`'s glob exactly**, so every
  semantic-model Read lists both: 658 characters on top of 490. That
  happened in 4 client sessions, 2026-09-24 to 2026-10-08, and it was
  never invoked, nor read in client work outside one audit's sweep of
  35 skills. Ten other skills name it.

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
  [semantic-model-ai-instructions-storage.md](semantic-model-ai-instructions-storage.md)
  holds that open, needing a model export with AI instructions set. It
  waited in 2026-09-10 `skills-for-fabric` audit brief 05 from
  2026-09-11 until a `/triage` sweep carried it there on 2026-10-07,
  and that brief's 2026-09-12 behavioural run had the skill give both
  answers in one session.
- **It was never reached in client work**: no activation and no
  invocation in the client Fabric repos' sessions, 2026-09-24 to
  2026-10-06.
- Folding both drops two listing entries from a semantic-model
  activation: 677 description characters for the AI-instructions skill,
  on a culture file, and 658 for `fabric-tmdl-api`, on any model file.

## Shape

| Today | After |
| --- | --- |
| `fabric-semantic-model-ai-instructions/SKILL.md` | `fabric-tmdl/references/ai-instructions.md`, by `git mv` |
| `fabric-semantic-model-ai-instructions/references/REFERENCE.md` | appended to that file as its link list, then removed |
| `fabric-tmdl-api/SKILL.md` | `fabric-tmdl/references/definition-api.md`, by `git mv` |
| `fabric-tmdl-api/references/REFERENCE.md`, a Learn link bundle | appended to `definition-api.md`, then removed |

- Strip each moved file's frontmatter. Drop the AI-instructions file's
  "See also", which points at "your internal tooling repo" and so at
  nothing, and re-point its link to `references/REFERENCE.md`. Change
  nothing else, its line 263 included: settling it is
  `semantic-model-ai-instructions-storage.md`'s work.
- `fabric-tmdl`'s `description`, 490 characters, gains trigger words
  only: "AI instructions", "Prep data for AI", and "Definition API",
  `getDefinition`, `updateDefinition`. Its body gains two pointers: to
  write the model's AI instructions, or edit a culture file's
  `linguisticMetadata`, read `references/ai-instructions.md` first; to
  create, read or update a model's definition through the Fabric API,
  read `references/definition-api.md` first.
- Brief 20's D-1 left `fabric-tmdl`'s `paths:` at
  `**/*.SemanticModel/**` (2026-10-09), which holds the culture files.
  Keep it so.

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
- `semantic-model-ai-instructions-storage.md` names the old skill's
  line 263: re-point it to the moved file. `docs/audits/` stays as
  written.
- `.claude/skills/test-skill/SKILL.md:98` and `:208` cite this skill as
  dated history: leave them.
- **For `fabric-tmdl-api`**, counted 2026-10-09: its `skillOverrides`
  entry; its place in the `pbip-triggers` model-file rows; its
  `skills/README.md` bullet; it has no `.tested.json` stamp. Ten skills
  name it in prose: re-point each to `fabric-tmdl`, wherever its own
  fold has moved it. The registry's skills-for-fabric rows naming it
  re-point too. `tests/skills/code-review/README.md:52` lists it among
  what the TMDL fixture pulls: drop it. The 2026-09-12 measurement at
  `.claude/skills/test-skill/references/reading-a-failure.md:38` is
  dated history: leave it.

```bash
grep -rnE 'semantic-model-ai-instructions|fabric-tmdl-api' --exclude-dir=audits --exclude-dir=.git .
```

**Client repos**: relink each repo holding the `fabric` group with
exactly the groups it already holds, as `fabric-deploy-skill.md` says;
the relink prunes the two dangling junctions.

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
3. A second case, after a model file is Read: update the model's
   definition through the Fabric API. Passes when `fabric-tmdl` reads
   `references/definition-api.md`, and the answer keeps that
   `updateDefinition` sends every part, and which API serves
   definitions and which serves refresh.
4. `pre-commit run --all-files`.

## Re-measure before acting

- Brief 20 edited `fabric-tmdl`'s `paths:` (D-1) and this skill's Q&A
  retirement dates (D-2 row 10), executed 2026-10-06. Re-read all three
  skills: line numbers above will have moved.
- If `semantic-model-ai-instructions-storage.md` has landed by then,
  the moved file says so: carry its result, not the question.
- Whether `/triage` has applied the client prompt audit's hunks to any
  of the three, as `platform-skill-portfolio.md` says it may.
- `fabric-deploy-skill.md` and the other fold briefs that
  `platform-skill-portfolio.md` lists edit the same shared files
  (`skillOverrides`, `skills/README.md`, `.tested.json`, the registry).
  If two run at once, the second to land rebases over the first.

## Not checked

Where the AI instructions really serialize:
`semantic-model-ai-instructions-storage.md` owns that.

## Scrubbing

Client repos are named by kind, and no workspace, model or tenant is
named.
