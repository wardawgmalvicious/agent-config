---
status: open
priority: 1
needs: [user]
blocked-by: []
written: 2026-10-08
---

# Handoff: decide which platform skills stay, merge or go, and how a client repo picks them

- **Written**: 2026-10-08, on the user's decision to slim the platform
  skills: retire what goes unused, consolidate, and split the `fabric`
  group into personas. It folds in `skill-listing-budget.md`, written
  2026-10-07 by a `/triage` sweep from the listing-budget half of
  2026-09-10 `skills-for-fabric` brief 08
  (`git show 7dd627e:docs/audits/2026-09-10/skills-for-fabric/completed/08-decide-catalog-budget-and-reference-lints.md`).
  Measured at `bde833c`.
- **Kind**: a decision of the user's, in three parts, each then an edit
  for a later session. Nothing is drafted.
- **Priority 1**: the listing overflow it addresses is live in client
  repos, measured below.

## Why: two costs

**Listing space, live.** In the transcripts of the two client Fabric
repos, 2026-09-24 to 2026-10-06, the rendered skill listing sat at
29,925–29,998 characters in 27 of 31 sessions, and what overflowed was
listed by name only; platform entries took up to 16,631 characters of
it (`fabric-deploy-skill.md` § "Why", measured 2026-10-06). The
2026-10-07 sweep missed that measurement and called the overflow
unmeasured: corrected here. Claude Code documents the cap (skills page
§ "Skill descriptions are cut short", and the settings reference, read
2026-10-07):

- `skillListingBudgetFraction`, default `0.01`, "reserves 1% of the
  context window" for the listing;
- past it, Claude Code "keeps every skill's name but drops the
  descriptions of the least-used skills, so Claude can still invoke
  those skills but is less likely to choose one on its own";
- `/doctor` reports the listing's cost and biggest contributors, and the
  Skills row of `/context` its size after the cap (2.1.196 on);
- the remedies: raise the fraction, set `"name-only"` in
  `skillOverrides`, or cut the text; `skillListingMaxDescChars`,
  default 1536, caps each entry whatever the budget.

Only an always-listed skill, one without `paths:`, costs listing space
in every session: 16 of the platform skills.

**Upkeep.** Every skill is something `/drift-audit` maps Fabric's
changes onto: the 2026-10-06 `fabric` run wrote 21 briefs. On
2026-10-07 two of the edits a sweep landed went to `pbir-themes` and
`pbir-pages`, which have never been invoked.

## Usage

`uv run --with pyyaml python scripts/skill-telemetry.py coverage`, run
2026-10-07 over the 275 sessions on disk (2026-09-24 to 2026-10-07),
and `~/.claude.json` `skillUsage`, a lifetime count that `/test-skill`
runs inflate. Invoked counts slash commands and Skill-tool dispatches.

| Skill | Always listed | Invoked, two weeks | Lifetime |
| --- | --- | --- | --- |
| `fabric-activator` | | 0 | 2 |
| `fabric-ai-functions` | yes | 0 | 0 |
| `fabric-auth` | yes | 0 | 5 |
| `fabric-catalog-governance` | yes | 0 | 8 |
| `fabric-cicd` | yes | 2 | 3 |
| `fabric-cli` | yes | 0 | 6 |
| `fabric-copy-job` | | 0 | 0 |
| `fabric-data-agent` | | 0 | 0 |
| `fabric-data-pipeline` | | 1 | 3 |
| `fabric-database` | | 0 | 2 |
| `fabric-dataflow` | | 0 | 2 |
| `fabric-deployment-pipelines` | yes | 0 | 5 |
| `fabric-error-handling` | | 0 | 1 |
| `fabric-event-schema-set` | | 2 | 3 |
| `fabric-eventhouse` | | 0 | 1 |
| `fabric-eventstream` | | 0 | 6 |
| `fabric-gotchas` | yes | 3 | 6 |
| `fabric-graph` | | 0 | 0 |
| `fabric-mirroring` | | 0 | 0 |
| `fabric-mlv` | yes | 0 | 6 |
| `fabric-ontology` | | 0 | 1 |
| `fabric-operations-agent` | | 0 | 1 |
| `fabric-realtime-dashboard` | | 0 | 0 |
| `fabric-rest-api` | yes | 0 | 0 |
| `fabric-security` | yes | 0 | 1 |
| `fabric-semantic-model-ai-instructions` | | 1 | 2 |
| `fabric-semantic-model-audit` | yes | 0 | 6 |
| `fabric-spark` | | 0 | 1 |
| `fabric-spark-monitoring` | | 0 | 0 |
| `fabric-tmdl` | | 0 | 1 |
| `fabric-tmdl-api` | | 0 | 0 |
| `fabric-variable-library` | | 0 | 1 |
| `fabric-warehouse` | | 0 | 2 |
| `fabric-warehouse-monitoring` | | 0 | 1 |
| `pbid-tom-live` | yes | 0 | 0 |
| `pbip-project-structure` | | 0 | 2 |
| `pbir-bookmarks` | | 0 | 0 |
| `pbir-cli` | yes | 0 | 2 |
| `pbir-conditional-formatting` | | 0 | 0 |
| `pbir-filters` | | 0 | 6 |
| `pbir-pages` | | 0 | 0 |
| `pbir-report-workflow` | yes | 3 | 2 |
| `pbir-themes` | | 0 | 0 |
| `pbir-visual-json` | | 0 | 1 |
| `powerbi-report-authoring` | yes | 0 | 0 |
| `powerbi-report-design` | yes | 0 | 1 |

For contrast, `commit` was invoked 194 times in the same two weeks.
**Zero is a question, not a verdict**: the script's own rule is that "a
rare-but-critical skill is doing its job", and two weeks is short. The
lifetime column is the longer view.

## The client repo's numbers

Sent 2026-10-08, at the user's direction, by two sessions in a client
Fabric repo, from `/doctor` and `/skill-doctor`; cited here by kind.

- **The listing is over its cap there.** `/doctor` put it at about 9.9k
  estimated tokens: the 16 always-listed platform skills about 3.7k,
  user-scope skills 2.1k, the 14 skills synced from claude.ai 2.4k, and
  Claude Code's own 1.6k. Shown by name only, with no description: all
  14 synced skills, `init`, `security-review` and `pbid-tom-live`. That
  fits the documented drop of the least-used, though why
  `pbid-tom-live` went and the other never-used skills did not is not
  explained.
- **`/skill-doctor` adds recency**, which the lifetime column lacks. Of
  the 16 always-listed, only `fabric-gotchas` and
  `pbir-report-workflow` (last used a day before), `fabric-cicd` (7
  days) and `fabric-cli` (12) show use in the last fortnight;
  `pbir-report-workflow` drew 33.7m tokens and `fabric-gotchas` 12.6m
  over seven days. The last uses of `fabric-catalog-governance`,
  `fabric-mlv`, `fabric-deployment-pipelines` and
  `fabric-semantic-model-audit` fall within a day of their authoring or
  test stamps, so those counts are most likely tests. Never used:
  `fabric-ai-functions`, `fabric-rest-api`, `pbid-tom-live` and
  `powerbi-report-authoring`, whose two CLIs are not installed there.
- **Four are already off in that repo.** Its `/doctor` session set
  `skillOverrides` to `"off"` in the repo's own gitignored
  `.claude/settings.local.json` for `fabric-ai-functions`,
  `pbid-tom-live`, `powerbi-report-authoring` and
  `powerbi-report-design`, and kept `fabric-rest-api`. That holds in
  that repo alone; archiving here removes a skill everywhere.
- **The synced skills are hidden in Claude Code since 2026-10-08**, by
  user-scope `skillOverrides` in `claude/settings.json` (`0778339`,
  deployed), so in every repo. Of the 13 synced to this machine, those
  that cannot work here or repeat a local skill are `"off"`, the four
  office skills `"user-invocable-only"`, and `deep-research` stays
  listed; the file says which is which, the commit why. Both syncs stay
  on, as the user left them on 2026-10-07 (2026-10-06 `claude-code`
  brief 03, D-2): `syncClaudeAiSkills: false`, read from user or local
  settings and never a repository's, drops all 13, and turning one off
  on claude.ai, the only route the relay knew, drops it there too, where
  `personal-init` and `project-init` are meant to run. Cold probes on
  2.1.293: an override reaches a synced skill by its short name or its
  `anthropic-skills:` name, and two scopes' blocks merge rather than
  replace. What the client repo's listing holds since is unmeasured.
- **`skillOverrides` takes four values**: `"on"`, `"name-only"`,
  `"user-invocable-only"`, where Claude does not see the skill but
  `/name` still works, and `"off"` (settings reference). The third fits
  a skill only ever typed by name.
- **Probe sessions inflate every count here.** 23 of the 50 most recent
  transcripts were probe sessions in this repo's scratchpad, so the
  session and invocation counts above include probes and test runs.

Not sent: which groups that repo links, which Part 3 needs.

## Part 1: archive

The candidates are the 15 skills never invoked in their lifetime:
`fabric-ai-functions`, `fabric-copy-job`, `fabric-data-agent`,
`fabric-graph`, `fabric-mirroring`, `fabric-realtime-dashboard`,
`fabric-rest-api`, `fabric-spark-monitoring`, `fabric-tmdl-api`,
`pbid-tom-live`, `pbir-bookmarks`, `pbir-conditional-formatting`,
`pbir-pages`, `pbir-themes` and `powerbi-report-authoring`. Each takes
the user's yes or no; the rest of the table can join on the same terms.

- **Archiving is `git rm -r skills/<group>/<name>`**, git history the
  archive, as for briefs and retired audit runs; a skill comes back with
  `git checkout <sha>^ -- skills/<group>/<name>`. Recording each in
  `skills/README.md`, with the commit that last held it, is the user's
  call.
- **The rename trap applies** to each, in the commit that archives it:
  `.claude/settings.json` `skillOverrides`, the
  `tests/skills/*-triggers/expected_activations.md` rows, the
  `tests/skills/.tested.json` stamp, `skills/README.md`, other skills'
  routing mentions, `.claude/skills/drift-audit/references/sources/`
  counterpart rows, and each client repo's junctions, relinked with the
  groups it holds. `fabric-deploy-skill.md` § "The rename trap" is the
  worked list.
- **`powerbi-report-authoring` and `powerbi-report-design` are
  vendored** from upstream `skills-for-fabric`, so dropping either also
  drops its vendoring check in that source's registry entry.

## Part 2: consolidate what is always listed

`fabric-deploy-skill.md` is the pilot, merging `fabric-cicd` and
`fabric-deployment-pipelines` into one router, and its "What the result
decides" lists the second wave; `ai-instructions-into-fabric-tmdl.md`
folds another. Part 1 goes first: whatever it archives leaves the
second wave.

## Part 3: personas as groups

A persona, in this repo's mechanics, is a skill group. A client repo
links only the groups it names (`link-claude.ps1 -SkillGroups`), so
splitting `fabric`'s 34 skills lets each repo list only its work's. A
draft, for the user to reshape, after Part 1:

| Group | Skills |
| --- | --- |
| `fabric-core`, any Fabric repo | `fabric-auth`, `fabric-cli`, `fabric-rest-api`, `fabric-gotchas`, `fabric-error-handling`, `fabric-security`, `fabric-variable-library`, `fabric-catalog-governance`, `fabric-cicd`, `fabric-deployment-pipelines` |
| `fabric-engineering` | `fabric-spark`, `fabric-spark-monitoring`, `fabric-data-pipeline`, `fabric-dataflow`, `fabric-copy-job`, `fabric-mirroring`, `fabric-mlv`, `fabric-ai-functions`, `fabric-warehouse`, `fabric-warehouse-monitoring`, `fabric-database` |
| `fabric-realtime` | `fabric-eventhouse`, `fabric-eventstream`, `fabric-activator`, `fabric-realtime-dashboard`, `fabric-event-schema-set` |
| `fabric-ai` | `fabric-data-agent`, `fabric-ontology`, `fabric-graph`, `fabric-operations-agent` |
| `powerbi`, gaining the semantic-model skills | today's 12, plus `fabric-tmdl`, `fabric-tmdl-api`, `fabric-semantic-model-audit`, `fabric-semantic-model-ai-instructions` |

The user's work is engineering and Power BI, so a repo would link
`fabric-core` with `fabric-engineering`, `powerbi`, or both, and the
real-time and AI groups only where that work is. Skill names keep their
prefixes; only folders move. What a split owes: `git mv` per skill,
`PLATFORM_GROUPS` in `scripts/lint-skill-overrides.py`, the group lists
in `skills/README.md` and root `CLAUDE.md` § "Commands", the activation
test sets, and every client repo relinked.

## Briefs this decision governs

- `pbir-august-formatting-properties.md`, blocked by this brief: each
  of its four target skills has one lifetime invocation or none.
- `powerbi-desktop-external-changes.md` edits a reference of
  `powerbi-report-authoring`, a Part 1 candidate.
- `semantic-model-ai-instructions-storage.md` targets a skill that
  `ai-instructions-into-fabric-tmdl.md` folds.
- The new-skill briefs, `fabric-cosmos-db-skill.md`,
  `fabric-user-data-functions-skill.md`, `item-type-skill-fabric-plan.md`,
  `translytical-task-flow-skill.md` and `copilot-chat-power-bi-skill.md`:
  whether a new platform skill is authored while the portfolio shrinks
  is part of this decision.
- Three new skills that no brief carries, accepted for `/author-skill`
  on 2026-10-06, before this decision: Business Events, the dbt job and
  Fabric Maps. Their evidence is in the 2026-10-06 `fabric` audit's
  [brief 19](../../audits/2026-10-06/fabric/completed/19-decide-new-skill-candidates.md),
  and whether to author them is the new-skill briefs' question.

## Held for this decision

`/triage` left these here on 2026-10-08: two edits from a client note of
2026-10-07, and two from the 2026-10-06 `fabric` audit's follow-ups,
each citing its audit brief.

- **Part 1**: `fabric-data-agent` names the service-principal tenant
  setting by its old title, *Service principals can use Fabric APIs*, at
  `SKILL.md:45` and `references/authentication.md:15`. The admin portal
  now titles it *Service principals can call Fabric public APIs*, as the
  other skills say since that triage, while Learn's own data agent page
  keeps the old one. Correct both if the skill stays.
- **Part 1**: `fabric-data-agent`'s ontology paragraph (`SKILL.md:21`)
  says nothing of the outage that Learn's data-agent ontology page still
  warned of on 2026-10-08: a data agent may fail to add an ontology in
  the new experience (known issue 1987). Add it, dated, if the skill
  stays and the page still warns
  ([brief 07](../../audits/2026-10-06/fabric/completed/07-update-data-agent-consumption-surfaces.md)).
- **Part 1**: `fabric-graph` still carries four claims that its audit
  brief put out of scope as unverified, to be raised separately, which
  nobody did: the source formats, the create and update timeout, and the
  per-workspace cap and unsupported return types, at
  `references/REFERENCE.md:408-418` on 2026-10-08, and the graph-type
  DDL example in `SKILL.md`. Re-measured on 2026-10-08, the timeout
  claim fails: Learn's graph performance page says "The 20-minute Query
  API timeout doesn't apply to refresh jobs." Verify the rest, and
  correct what fails, if the skill stays. The claims and what the audit
  read are in the Constraint of
  [brief 03](../../audits/2026-10-06/fabric/03-rewrite-graph-gql-support-and-query-api.md),
  which stays open on its own re-check.
- **Part 2**: a trigger for what authorizes a service principal, tenant
  settings and workspace roles rather than API permissions, in
  `fabric-auth`'s `description`, 639 characters on 2026-10-08. The
  guidance landed under its 401 heading; the trigger would grow an
  always-listed entry.

## Re-measure before acting

```bash
uv run --with pyyaml python scripts/skill-telemetry.py coverage   # 275 sessions, 2026-09-24 to 2026-10-07, on 2026-10-07
```

The listing text per group, `description` plus `when_to_use`, each
entry capped at 1,536 characters; on 2026-10-07 it printed `fabric` 34
skills 32,741, `powerbi` 12 skills 11,130, `workflow` 6 skills 5,984,
`windows` 1,385, `meta` 1,263, `social` 1,155, and `.claude/skills` 6
skills 6,488:

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
