---
status: open
priority: 3
needs: []
blocked-by: [ai-instructions-into-fabric-tmdl.md]
written: 2026-10-12
---

# Handoff: point the KQL and DAX skills at the local-cli wrappers

- **Written**: 2026-10-12, by a session in this repo that weighed
  bundling the local-cli wrappers into skills, measured at `e9b2e6f`.
  The user chose a pointer in each of two existing skills, briefed
  together.
- **Kind**: an edit to two platform skills, each pointer drafted below.
  `fabric-tmdl`'s half waits for its fold; `fabric-eventhouse`'s does
  not, but ships with it.

## Decided: the scripts stay templates, and no new skill

The user chose pointers over both on 2026-10-12. Reopen only on new
evidence.

- **No wrapper moves into a skill's `scripts/`.** Every wrapper finds
  `.env` from its own folder, `REPO_ROOT="$SCRIPT_DIR/../.."`
  (`kql.sh:96` in the template), which `.claude/rules/editing-skills.md`
  § "Bundled scripts" rules out for a skill's script: from a skill it
  would look in the skill tree, not the client repo. People run the
  wrappers from `scripts/data/` too, and `ido.sh` probes one client's
  ERP.
- **No `fabric-query` skill.** `7240d9e` (2026-10-09): "No new platform
  skill is authored while the portfolio shrinks." It would sit in
  `fabric-core` and carry KQL and DAX guidance into repos that link
  neither persona group (`platform-persona-groups.md`), and it would be
  listed wherever that group is linked, wrappers or not: no `paths:`
  glob sees a wrapper being run.
- **The always-on part stays in each client repo's instruction file**,
  the template README's step 11, which fabric-tools was asked through
  its inbox on 2026-10-12 to shrink to an index. A pointer here reaches
  only a session already working on that item type.

## fabric-eventhouse: kql.sh

§ "Connection" teaches the raw route, lines 24–30 on 2026-10-12: the
query endpoint `POST {clusterUri}/v1/rest/query`, a temp-file body
because KQL's `|` breaks shell escaping, and a pointer to the worked
`az rest` in `references/programmatic-access.md`. Once the skill loads,
that recipe competes with `kql.sh`. Add a bullet after the `|` one:

```markdown
- **If a `scripts/data/kql.sh` wrapper is deployed in the repo** (an
  internal local-cli template), prefer it over the `az rest` recipe for
  queries and management commands: it takes KQL on `-q`, from a file
  with `-i` or on stdin with no temp file, routes a leading-dot command
  to `/v1/rest/mgmt`, and turns Kusto's error inside a 200 into stderr
  and a non-zero exit. `-l` lists the databases the repo has configured
  and `-h` prints the rest. It is an accelerator that happens to be
  present, never a dependency; item definitions still take the REST
  envelope.
```

The skill's glob, `**/*.Eventhouse/**`, already covers the KQL
databases, which Git stores under the Eventhouse's `.children/`
(`tests/skills/fabric-triggers/expected_activations.md`, lines 37–40).

## fabric-tmdl: dax.sh

Once `ai-instructions-into-fabric-tmdl.md` has landed, add a bullet to
§ "Measure & DAX Rules" (line 53 on 2026-10-12, before the fold):

```markdown
- **If a `scripts/data/dax.sh` wrapper is deployed in the repo** (an
  internal local-cli template), run a new measure against the published
  model before writing it into TMDL: `dax.sh -q 'DEFINE MEASURE …
  EVALUATE …'` returns what a report would show, after relationships
  and filter context, and its values say which `formatString` fits. It
  reads the **published** model, so a change on disk not yet deployed
  is not in it. It is an accelerator that happens to be present, never
  a dependency.
```

Names and data types come from the TMDL on disk, not from `dax.sh -s
columns`, the template README's suggestion: in a TMDL repo the files
already hold them.

## For both pointers

- **Name no personal repo.** Platform skills are linked into client
  repos, so the text says "an internal local-cli template", as
  `fabric-semantic-model-audit` does (line 56 on 2026-10-12).
- **Name only the flags the pointer uses.** Each wrapper's `-h` prints
  its own header, so the flags keep one home.

## When it lands

Add one line to `fabric-cosmos-db-skill.md`, which is deferred: the
Cosmos DB skill takes the same pointer for `scripts/data/cosmos.sh`,
the read-only reader of a live container, which refuses a
cross-partition aggregate on a container of several partition key
ranges and names `sql.sh` on the item's SQL analytics endpoint instead.
This brief is deleted on landing, so the line has to live there.

## Not in scope

- `sql.sh` and `lake.sh`: no skill teaches a competing route.
  `fabric-warehouse` names `sqlcmd` only for build failures.
- `report-png.sh`, and `dax.sh`'s audit tier: their pointers are in
  `pbir-report-workflow` and `fabric-semantic-model-audit` already.
- The vendored Copilot copies in client repos, which are not refreshed
  while the Copilot payload is retired (`copilot-payload-retirement.md`).

## Verification

```bash
grep -n 'kql\.sh' skills/*/fabric-eventhouse/SKILL.md   # a hit
grep -n 'dax\.sh' skills/*/fabric-tmdl/SKILL.md         # a hit
grep -rn 'fabric-tools' skills/                         # nothing
uv run --with pyyaml scripts/lint-frontmatter.py skills/*/fabric-eventhouse/SKILL.md skills/*/fabric-tmdl/SKILL.md
uv run --with pyyaml scripts/skill-status.py --stale    # then what it asks for
pre-commit run --all-files
```

No deploy: a platform skill reaches a client repo through a junction,
live on save.

## Re-measure before acting

```bash
ls -d skills/*/fabric-eventhouse skills/*/fabric-tmdl   # the persona split may have moved both
grep -n 'Query endpoint\|breaks shell escaping\|az rest' skills/*/fabric-eventhouse/SKILL.md   # 3, 24, 26, 29 on 2026-10-12
grep -n -- '-h|--help' C:/Repos/Personal/fabric-tools/local-cli/kql.sh C:/Repos/Personal/fabric-tools/local-cli/dax.sh   # kql.sh:228, dax.sh:101
```
