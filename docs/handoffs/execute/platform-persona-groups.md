---
status: open
priority: 3
needs: []
blocked-by: [platform-skill-portfolio.md, fabric-deploy-skill.md, notebook-skills-into-fabric-spark.md, pbir-skills-into-pbir-report-workflow.md, ai-instructions-into-fabric-tmdl.md, iq-skills-into-fabric-iq.md]
written: 2026-10-09
---

# Handoff: split the platform skill groups by persona

- **Written**: 2026-10-09, as Part 3 of
  [platform-skill-portfolio.md](platform-skill-portfolio.md), moved here
  on the user's word the same day, so that it runs last and that brief
  can land with its Part 1. The user adopted the persona draft on
  2026-10-09. Measured at `122910a`.
- **Kind**: a restructure, done by hand: a `git mv` per skill into new
  group folders, the scripts and lists that name the groups, and every
  client repo relinked. No skill's name or content changes.
- **Last, after the folds**: run then, the split moves about 24 skills
  rather than 42, the fold briefs run with the paths they were written
  for, and the test harness's group names change once, at the end.

## Why

A persona, in this repo's mechanics, is a skill group: a client repo
links only the groups it names (`link-claude.ps1 -SkillGroups`), so it
can leave out the work it does not do. The listing gain comes from
always-listed skills alone, since a skill with a glob lists nothing until
a matching file is read. Both client repos hold items for every group
but `fabric-ai`, whose skills all carry globs (2026-10-08), so the split
changes neither repo's listing yet: its value is the next repo with
narrower work, and nothing is lost by running it last.

## The groups

The adopted draft, for the 24 skills expected once the folds have
landed, before the second wave merges `fabric-auth`, `fabric-cli` and
`fabric-gotchas` into `fabric-rest-api`:

| Group | Skills |
| --- | --- |
| `fabric-core`, any Fabric repo | `fabric-auth`, `fabric-cli`, `fabric-rest-api`, `fabric-gotchas`, `fabric-security`, `fabric-variable-library`, `fabric-catalog-governance`, `fabric-deploy` |
| `fabric-engineering` | `fabric-spark`, `fabric-data-pipeline`, `fabric-dataflow`, `fabric-warehouse`, `fabric-warehouse-monitoring`, `fabric-database` |
| `fabric-realtime` | `fabric-eventhouse`, `fabric-eventstream`, `fabric-activator`, `fabric-realtime-dashboard`, `fabric-event-schema-set` |
| `fabric-ai` | `fabric-iq` |
| `powerbi` | `pbir-report-workflow`, `pbip-project-structure`, `fabric-tmdl`, `fabric-semantic-model-audit` |

- **Recompute it** from `ls skills/fabric skills/powerbi` when this
  runs: each skill goes to the group of the job it serves, and a skill
  a later fold will remove goes with its router.
- **Skill names keep their prefixes**; only folders move.

## Which groups a client repo links

The user's call, per repo, at the relink. By folder suffix on
2026-10-08, the main client repo holds Notebook (14), KQLDatabase (2),
DataPipeline (2), Warehouse, VariableLibrary, SemanticModel, Report,
Lakehouse, KQLDashboard, Eventhouse and DeploymentPlan; the sandbox repo
holds UserDataFunction (2), SQLDatabase (2), Warehouse, SemanticModel,
Report, Plan, Lakehouse, EventSchemaSet, DataPipeline and
CosmosDBDatabase. Each holds engineering, real-time and Power BI work
and no Fabric IQ item; the user's own work is engineering and Power BI.

## What the split owes

Counted 2026-10-09, before the folds; re-count when this runs.

- a `git mv` per skill;
- `PLATFORM_GROUPS` in `scripts/lint-skill-overrides.py:64`;
- `PROBE_GROUPS` and the set map in `scripts/activation-expect.py`
  (lines 52 and 60), and the deploy at `scripts/test-activation.ps1:144`,
  each naming `fabric` and `powerbi`;
- the examples at `scripts/link-claude.ps1:182` and in
  `scripts/copy-copilot.ps1`, the latter retiring with the Copilot
  payload;
- the group lists in `skills/README.md` and root `CLAUDE.md`
  § "Commands";
- 19 files outside `skills/` naming a path under `skills/fabric/`, and 8
  under `skills/powerbi/`;
- every client repo relinked with its new groups, which prunes the
  junctions the move leaves dangling, as `fabric-deploy-skill.md`
  § "The rename trap" says of a relink.

No link between skills breaks: the nine relative links that left a
skill's `references/` folder on 2026-10-09 all point back into the same
skill. Check the links the folds added the same way.

## Verify

1. `pre-commit run --all-files`, which runs `lint-skill-overrides`
   against the new `PLATFORM_GROUPS`.
2. `./scripts/test-activation.ps1 -Set fabric -StaticOnly` and
   `-Set pbip -StaticOnly`, then each set's real path, since the harness
   deploys by group name.
3. After the default deploy, root `CLAUDE.md`'s check, the `ls` of
   `~/.claude/skills` piped through `grep` for the platform prefixes,
   prints nothing: no new group reached user scope.
4. Each client repo's `.claude/skills` lists its groups' skills and no
   others.

## Re-measure before acting

- Which folds have landed. The second wave's `fabric-rest-api` merge,
  which had no brief on 2026-10-09, can land before or after this: it
  stays inside `fabric-core`.
- The grep counts above.
- The junction count and item types per client repo, from the main
  checkout before the worktree, whose guard refuses a `find` naming
  `.git`. It prints suffix counts alone, so no item is named:

```bash
for d in /c/Repos/*/*/.claude/skills; do case "$d" in */Personal/*) continue;; esac; r="${d%/.claude/skills}"; ls "$d" | wc -l; find "$r" -path "$r/.git" -prune -o -type d -name '*.*' -print | sed -n 's/.*\.\([A-Z][A-Za-z]*\)$/\1/p' | sort | uniq -c | tr '\n' ' '; echo; done
```

## Scrubbing

Client repos are named by kind, and their items by type alone; no
workspace, item or tenant is named.
