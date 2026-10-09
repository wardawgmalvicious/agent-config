---
status: open
priority: 1
needs: []
blocked-by: []
written: 2026-10-08
---

# Handoff: archive four platform skills

- **Written**: 2026-10-08, on the user's decision to slim the platform
  skills: retire what goes unused, consolidate, and split the `fabric`
  group into personas. It folded in `skill-listing-budget.md`, from the
  listing-budget half of 2026-09-10 `skills-for-fabric` brief 08.
- **Decided**: 2026-10-09, by the user, part by part, as below. What
  they decided on, the usage table and a client repo's `/doctor` and
  `/skill-doctor` numbers, reads back with
  `git show 0d8efb7:docs/handoffs/execute/platform-skill-portfolio.md`;
  the commit that rewrote this brief has the reasoning.
- **Kind**: one edit left here, in this brief's worktree: Part 1
  archives four skills. Part 2 went to briefs of its own, and Part 3 to
  [platform-persona-groups.md](platform-persona-groups.md), which runs
  last.
- **Priority 1**: Part 1 closes the listing overflow still live in the
  sandbox repo (§ Evidence).

## Evidence, re-measured 2026-10-08

- **The rendered listing**, read from each client repo's newest
  sessions: the initial `skill_listing` attachment, its `content`
  length, and its entries with no description. The main client repo
  stood at 27,560 characters with every description kept, since
  `0778339` hid the synced claude.ai skills and that repo set four
  platform skills `"off"` in its own `.claude/settings.local.json`. The
  sandbox repo stood at 29,678, with `powerbi-report-authoring` cut to
  its name. Sessions that overflowed measured 29,883 to 29,998.
  `skill-telemetry.py listing` prints only each project's maximum,
  29,998 for both, so it cannot show the change.
- **Use**: none of the four skills Part 1 archives was invoked in its
  lifetime (`~/.claude.json` `skillUsage`), or read in client work
  outside one sweep of 35 skills by a client prompt audit (client
  transcripts, 2026-09-24 to 2026-10-08).
- **Items**: both client repos link all 46 platform skills, `fabric`
  and `powerbi`, and neither holds a CopyJob or MirroredDatabase item.
  [platform-persona-groups.md](platform-persona-groups.md) lists what
  each does hold.
- **A correction**: this brief's listing measure used to count a folded
  `>-` description as 2 characters, giving `powerbi` 11,130 where a YAML
  parse gives 12,528. § Re-measure uses the parse.

## Part 1: archive four skills

| Skill | Listed | Why it goes |
| --- | --- | --- |
| `fabric-copy-job` | by glob | no CopyJob item in either client repo |
| `fabric-mirroring` | by glob | no MirroredDatabase item in either |
| `pbid-tom-live` | always, 904 characters | never used; the main repo had turned it off |
| `powerbi-report-authoring` | always, 727 | vendored, on two CLIs the client repo lacks; the PBIR family covers its ground |

`fabric-rest-api` and `fabric-realtime-dashboard` stay, the first as
the hub 23 skills route to and the second because the main repo holds
a KQL dashboard. The other candidates fold, under Part 2.

- **Archiving is `git rm -r skills/<group>/<name>`**, git history the
  archive, as for briefs and retired audit runs.
- **Record each in `skills/README.md`**, as the user chose: one line
  saying what it covered and how to restore it,
  `git checkout <sha> -- skills/<group>/<name>`, where `<sha>` is a
  commit on `main` that holds it, such as the worktree's base. A branch
  commit's SHA dies at the landing's rebase. `powerbi-report-authoring`
  can instead be re-vendored from upstream, which brings a current copy.
- **The rename trap**, in the archive commit, counted 2026-10-09 with
  `docs/audits/` left as written:
  - `.claude/settings.json` `skillOverrides`: the four entries go;
    `lint-skill-overrides` fails until then.
  - `tests/skills/fabric-triggers/expected_activations.md`: the
    `fabric-copy-job` and `fabric-mirroring` rows, then
    `./scripts/test-activation.ps1 -Set fabric -StaticOnly`.
  - `tests/skills/.tested.json`: those two skills' stamps.
  - Other skills' mentions, re-pointed or dropped: `fabric-dataflow`
    names `fabric-copy-job` and `fabric-mirroring`, which name each
    other; `fabric-semantic-model-audit` and `pbip-project-structure`
    name `pbid-tom-live`; `pbir-conditional-formatting`, `pbir-filters`
    and `powerbi-report-design` name `powerbi-report-authoring`. A name
    backticked in a description fails `scripts/skill-overlap.py routing`.
  - The drift registry: `powerbi-report-authoring`'s vendoring check in
    `.claude/skills/drift-audit/references/sources/skills-for-fabric.md`,
    and any counterpart row naming the four.
  - Open briefs naming them; `fabric-cosmos-db-skill.md` cites
    `fabric-mirroring`'s native-item line.
  - Dated history stays: `scripts/skill-overlap.py:300-302` and the
    `fabric-mirroring` story in
    `docs/handoffs/examples/author-skill.example.md`.
    `docs/handoffs/templates/skill-handoff.md:60` cites
    `powerbi-report-authoring` as the `metadata:` precedent: name
    another.

  ```bash
  grep -rnE 'fabric-copy-job|fabric-mirroring|pbid-tom-live|powerbi-report-authoring' --exclude-dir=audits --exclude-dir=.git .
  ```

- **Client repos**: relink each with exactly the groups it holds, both
  `fabric,powerbi` on 2026-10-08, which prunes the dangling junctions;
  `fabric-deploy-skill.md` § "The rename trap" has the commands. The
  main repo's `"off"` entries for `pbid-tom-live` and
  `powerbi-report-authoring` then name nothing, which is harmless and
  that repo's to tidy.

## Part 2: four folds, each its own brief

| Brief | Into | Folds | Waits for |
| --- | --- | --- | --- |
| [notebook-skills-into-fabric-spark.md](notebook-skills-into-fabric-spark.md) | `fabric-spark`, then always listed | `fabric-spark-monitoring`, `fabric-error-handling`, `fabric-mlv`, `fabric-ai-functions` | the pilot |
| [pbir-skills-into-pbir-report-workflow.md](pbir-skills-into-pbir-report-workflow.md) | `pbir-report-workflow` | `pbir-cli`, the six file-level PBIR skills, `powerbi-report-design` de-vendored | the pilot |
| [iq-skills-into-fabric-iq.md](iq-skills-into-fabric-iq.md) | a new `fabric-iq` | `fabric-data-agent`, `fabric-graph`, `fabric-ontology`, `fabric-operations-agent` | nothing |
| [ai-instructions-into-fabric-tmdl.md](ai-instructions-into-fabric-tmdl.md) | `fabric-tmdl` | `fabric-semantic-model-ai-instructions` and now `fabric-tmdl-api` | nothing |

The pilot is [fabric-deploy-skill.md](fabric-deploy-skill.md), which
tests the router shape once before the two routers copy it. The
`fabric-auth` trigger this brief held went to that pilot's second wave,
where `fabric-auth` merges into `fabric-rest-api`, and the three edits
it held for `fabric-data-agent` and `fabric-graph` went to the
`fabric-iq` fold, since those skills stay as references.

## Part 3: moved to its own brief

The persona split, adopted on 2026-10-09, is
[platform-persona-groups.md](platform-persona-groups.md), blocked by
this brief and by every fold, so that it runs last: then it moves about
24 skills rather than 42, and the folds run with the paths they were
written for.

## New platform skills wait for client work

The user decided on 2026-10-09 that no new platform skill is authored
while the portfolio shrinks, until client work uses its item. The
Git-sync sandbox repo, which holds most of these items as a test bed,
does not count. Deferred on that trigger:

- [fabric-cosmos-db-skill.md](fabric-cosmos-db-skill.md),
  [fabric-user-data-functions-skill.md](fabric-user-data-functions-skill.md)
  and [item-type-skill-fabric-plan.md](item-type-skill-fabric-plan.md),
  the last expected to land as a `fabric-iq` reference;
- [translytical-task-flow-skill.md](translytical-task-flow-skill.md),
  on top of its own probe;
- [fabric-new-skill-candidates.md](fabric-new-skill-candidates.md):
  Business Events, the dbt job and Fabric Maps, accepted on 2026-10-06
  and carried by no brief until then.

[copilot-chat-power-bi-skill.md](copilot-chat-power-bi-skill.md) waits
for the `fabric-iq` fold instead. Its route has no item, and its client
need is already on record, from 2026-10-07.

## The inbox note that waited on Part 1

The platform half of a prompt audit run in a client Fabric repo on
2026-10-08 waits in the inbox as `2026-10-08-prompt-audit-platform.md`,
with the whole audit as `2026-10-08-prompt-audit.patch`, on the user's
word that day (`566973a`). Its hunks touch 31 platform skills, 11 of
the 15 former candidates among them (counted 2026-10-09). Part 1 is
decided, so `/triage` can take it when the user says: drop the hunks
of the four skills archived, and apply a folding skill's hunks to its
file as it stands, which the fold then moves.

## Re-measure before acting

From the main checkout, before entering the worktree, whose guard
refuses a `find` naming `.git`:

```bash
uv run --with pyyaml python scripts/skill-telemetry.py coverage   # 306 sessions on 2026-10-08; the four: none invoked, none in skillUsage
for d in /c/Repos/*/*/.claude/skills; do case "$d" in */Personal/*) continue;; esac; r="${d%/.claude/skills}"; ls "$d" | wc -l; find "$r" -path "$r/.git" -prune -o -type d -name '*.*' -print | sed -n 's/.*\.\([A-Z][A-Za-z]*\)$/\1/p' | sort | uniq -c | tr '\n' ' '; echo; done   # junction count, then item types by suffix: no item named
```

The listing text per group, `description` plus `when_to_use` by YAML
parse, each entry capped at 1,536 characters. On 2026-10-08 it printed
`fabric` 34 skills 32,771, `powerbi` 12 12,528, `workflow` 6 5,984,
`windows` 1 1,385, `meta` 1 1,263, `social` 1 1,155, and
`.claude/skills` 6 6,505:

```bash
uv run --no-project --with pyyaml python - <<'EOF'
import collections, glob, yaml
tot, cnt = collections.Counter(), collections.Counter()
for p in glob.glob('skills/*/*/SKILL.md') + glob.glob('.claude/skills/*/SKILL.md'):
    p = p.replace(chr(92), '/')
    meta = yaml.safe_load(open(p, encoding='utf-8').read().split('---', 2)[1])
    n = sum(len(str(meta.get(k) or '')) for k in ('description', 'when_to_use'))
    g = p.split('/')[1] if p.startswith('skills/') else '.claude/skills'
    tot[g] += min(n, 1536); cnt[g] += 1
for g in sorted(tot): print(g, cnt[g], tot[g])
EOF
```

## Scrubbing

Client repos are named by kind, and their items by type alone; no
workspace, item or tenant is named.
