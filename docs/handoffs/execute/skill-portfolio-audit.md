# Handoff: a skill-portfolio audit skill

- **Written**: 2026-09-10, when the skill was scoped and deferred in the
  same session.
- **Kind**: one project-scope skill in `.claude/skills/`.
- **Status**: **deferred 2026-09-10 — not declined.** Every part of it
  found a cheaper home; see below. Depends on
  [skill-overlap-script.md](skill-overlap-script.md), which it would
  wrap.
- **Run in**: this repo.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## What it would have been

A skill that, before a skill is authored or updated, checks for similar
skills — here and in outside repos — and that, run across the whole
set, recommends consolidating and deprecating skills.

## Why it is deferred: each part has a cheaper home

| Part | Home |
| --- | --- |
| Similar skills here, before authoring or updating | `author-skill` §2 and `learn` Step 4, calling the script in [skill-overlap-script.md](skill-overlap-script.md) |
| Similar skills in outside repos | one `drift-audit` source, `skills-for-fabric` |
| Repos the payload does not cover | `payload-coverage.py` |
| Consolidate and deprecate, across the set | the script's output, read with `skill-telemetry.py`'s `verdict()` rubric |

**The outside-repo scope collapsed to one repo.** A GitHub code search
on 2026-09-10 returned ~2,800 `SKILL.md` files mentioning "Microsoft
Fabric" outside Microsoft's orgs, overwhelmingly aggregators re-hosting
the same few skills. Only a handful of repos authored their own, and
`microsoft/skills-for-fabric` is the one authoritative origin — which is
also where both vendored `powerbi-report-*` skills came from. A single
named repo is a registry entry, not a search skill: it is now the
`skills-for-fabric` source in `drift-audit`'s registry, whose runs
surface upstream's new skills as candidates. Searching wider would spend
most of its effort filtering out copies, and it carries a risk the
single repo does not. A third-party skill is instructions an agent
executes with your permissions, so vendoring one is running a stranger's
prompt.

**The cross-set judgment is small enough to print with the output.**
That is the argument `skill-telemetry.py`'s docstring made when a
companion skill for it was declined on 2026-09-03, and it holds for the
pairwise signals too: the rubric fits in a legend.

## Listing cost is not the reason, this time

The 2026-09-03 decline also rested on listing cost — another
unconditional skill in every session's listing. The 2026-09-09 scope
split removed that cost: a skill in `.claude/skills/` lists only in
sessions in this repo. **So don't re-open this on "the listing cost is
gone" alone.** That was never this deferral's reason; the script
carrying the judgment is.

## Re-open when

- A script run produces a finding its printed legend cannot explain —
  the same condition `skill-telemetry.py` carries.
- Reading the output becomes the work: the ranked pair list outgrows a
  single read.
- A second **authoritative** outside catalog appears, worth checking
  alongside `skills-for-fabric`. An aggregator or a community mirror does
  not count.

Delete this brief if the script is abandoned, and record why in the
commit that deletes it.
