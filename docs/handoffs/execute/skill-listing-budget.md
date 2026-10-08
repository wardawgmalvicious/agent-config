---
status: open
priority: 2
needs: [user]
blocked-by: []
written: 2026-10-07
---

# Handoff: measure the skill listing against Claude Code's budget

- **Written**: 2026-10-07, by a `/triage` sweep, from one audit
  follow-up:
  [2026-09-10 skills-for-fabric 08](../../audits/2026-09-10/skills-for-fabric/completed/08-decide-catalog-budget-and-reference-lints.md),
  whose reference lint shipped on 2026-09-15 as `lint-skill-routing`
  and whose listing-budget half the user queued on 2026-09-11.
  Re-measured at `4b6e108`: Claude Code now documents the budget.
- **Kind**: a measurement with `/doctor`, then a decision of the
  user's, since every remedy is a settings change or a description cut.
- **Priority**: 2 as drafted, and 1 if the measurement shows a client
  repo over budget, since that would be live on this machine.

## The budget is documented

Read 2026-10-07: the skills page, § "Skill descriptions are cut short",
and the settings reference, `skillListingBudgetFraction`.

- **The listing is capped at a share of the context window**:
  `skillListingBudgetFraction`, default `0.01`, which "reserves 1% of
  the context window".
- **Past the cap, descriptions go, least-used first**: Claude Code
  "keeps every skill's name but drops the descriptions of the
  least-used skills, so Claude can still invoke those skills but is
  less likely to choose one on its own".
- **`/doctor` measures it**, with the biggest contributors, and the
  Skills row of `/context` shows the size after the budget (2.1.196 on).
- **The remedies**: raise the fraction, set `"name-only"` in
  `skillOverrides`, or trim the text; `skillListingMaxDescChars`,
  default 1536, still caps each entry.

That answers the follow-up's first open question, and the second in
part: the catalog to measure is each deployment's.

## The catalog, measured here

`description` plus `when_to_use`, each entry capped at 1,536
characters, on 2026-10-07:

| Group | Skills | Characters |
| --- | --- | --- |
| `fabric` | 34 | 32,741 |
| `powerbi` | 12 | 11,130 |
| `workflow` | 6 | 5,984 |
| `windows` | 1 | 1,385 |
| `meta` | 1 | 1,263 |
| `social` | 1 | 1,155 |
| `.claude/skills` (this repo only) | 6 | 6,488 |

A client repo with `fabric` and `powerbi` deployed, plus user scope,
lists about 52,000 characters before Claude Code's own skills. The cap
is a share of the context window, not a character count, so whether
that overflows is `/doctor`'s answer, not this table's. This repo
already collapses its platform skills to `"name-only"`, for reasons of
its own (root `CLAUDE.md`).

## What to do

1. Run `/doctor` in a client repo holding the `fabric` group, and here.
   Record the listing's cost and whether descriptions are dropped.
2. Put the remedies to the user: a higher fraction costs context every
   turn; `"name-only"` for rarely used platform skills; shorter
   descriptions, as upstream cut its own by about 40% "with no loss of
   routing accuracy" (the follow-up's evidence); or a ratchet lint like
   upstream's catalog-total check.

A settings change is never landed from a brief without the user's yes,
and one in `claude/settings.json` deploys with
`./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`.

## Re-measure before acting

The table, per group, from the repo root (it printed the rows above on
2026-10-07):

```bash
python3.13 - <<'EOF'
import re, glob, collections, pathlib
tot, cnt = collections.Counter(), collections.Counter()
for p in glob.glob('skills/*/*/SKILL.md') + glob.glob('.claude/skills/*/SKILL.md'):
    t = open(p, encoding='utf-8').read()
    n = sum(len((re.search(rf'^{k}: "(.*)"\s*$', t, re.M) or re.search(rf'^{k}: (.*)$', t, re.M) or [None, ''])[1]) for k in ('description', 'when_to_use'))
    parts = pathlib.Path(p).parts
    g = parts[1] if parts[0] == 'skills' else '.claude/skills'
    tot[g] += min(n, 1536); cnt[g] += 1
for g in sorted(tot): print(g, cnt[g], tot[g])
EOF
```
