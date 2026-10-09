---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-06
---

# Handoff: merge fabric-cicd and fabric-deployment-pipelines into fabric-deploy

- **Written**: 2026-10-06, by a session asked whether the platform
  skills had become reference documents rather than skills. Measured
  against the payload at `47bdd56`.
- **Kind**: a restructure, done by hand, then `/test-skill`. Two
  unconditional skills become one router, `skills/fabric/fabric-deploy/`,
  whose `references/` hold the two bodies as they stand. No platform
  fact is added, so nothing is drilled and `/author-skill` does not
  apply.
- **A pilot**: it tests regrouping the unconditional platform skills
  around the job a user asks for. What waits on its result is under
  "What the result decides"; none of that is decided.

## Why

Platform skills almost never reach the model by description, and this
pair pays for a listing entry in every session to stay that way.
Measured 2026-10-06 from the transcripts of the two client Fabric repos
on this machine, 2026-09-24 to 2026-10-06: 31 sessions, 47 transcripts
with subagents, read by `scripts/skill-telemetry.py` and one-off probes.

| Measure | Result |
| --- | --- |
| Platform skills invoked | 3: `fabric-cicd` twice, `fabric-data-pipeline` once |
| Glob skills activated, then invoked | about 37 activations in 9 sessions, 1 invocation |
| `commit`, `land`, `learn`, same sessions | 23, 14 and 14 invocations |
| Rules loaded on Read | `fabric-git-serialization` 31, `coding-tsql` 28, `coding-kql` 16 |
| Rendered skill listing | 29,925–29,998 chars in 27 of 31 sessions; what overflows is listed by name only |
| Platform entries in that listing | up to 16,631 chars |

Of the unconditional platform skills, 16 on 2026-10-06, description
matching picked one: `fabric-cicd`. Users name a deploy as a job, the
way they name a commit, so one entry named for the job is the shape to
test.

The pair also splits facts that belong to neither:

- Both open with the same "which surface am I on?" table
  (`fabric-cicd/SKILL.md:17-25`,
  `fabric-deployment-pipelines/SKILL.md:18-31`).
- `fabric-cicd/SKILL.md:27-52` carries a deployment-pipeline caveat,
  OneLake image URLs that a promotion does not rewrite, because no
  skill owns a fact that crosses surfaces.
- `skills/README.md:149-151` says deployment pipelines do not support
  PBIR reports, while `fabric-deployment-pipelines/SKILL.md:352`
  records a PBIR report deploying to Test and Prod: "Don't present it
  as a blocker".

## Shape

### Files

| Today | After |
| --- | --- |
| `fabric-cicd/SKILL.md` | `fabric-deploy/references/fabric-cicd.md` |
| `fabric-deployment-pipelines/SKILL.md` | `fabric-deploy/references/deployment-pipelines.md` |
| `fabric-deployment-pipelines/references/REFERENCE.md` | `fabric-deploy/references/deployment-pipelines-tables.md` |
| none | `fabric-deploy/SKILL.md`, the router |

Move each with `git mv`, so `git log --follow` keeps its history. Then
strip the moved file's frontmatter and its "which surface" section,
which the router replaces, and re-point the relative links inside it.

### The router

1. **Pick the route.** One table. Git as the source of truth: the
   fabric-cicd library, `fab deploy`, which wraps it (`fabric-cli` §
   "Workspace Deployment"), or Git integration's update from Git
   (`fabric-rest-api` § "Git Integration APIs"). The workspace as the
   source of truth: deployment pipelines. Never deploy into one
   workspace by both routes; Git on the first stage with pipelines
   onward is Learn's option 3 ("Git only through dev", read
   2026-10-09), not a mix. Three live lines read as forbidding it,
   though a client repo works that way (a client prompt audit,
   2026-10-08): `fabric-cicd/SKILL.md:27` and
   `fabric-deployment-pipelines/SKILL.md:29-30` go with the sections
   this router replaces, and `fabric-cli/SKILL.md:213`, which stays,
   is corrected in the same pass. Link Learn's decision guide.
2. **Preflight, every route.** Identity: the service-principal tenant
   setting and workspace roles, plus the second permission system and
   the deploy-only scope that deployment pipelines add. What can move:
   each cross-surface caveat stated once, here: OneLake image URLs,
   PBIR, Direct Lake autobinding, and deployment plans, which the
   library does not support.
3. **Plan, then stop.** Before the session itself runs a write to a
   later stage, an orphan delete (`unpublish_all_orphan_items`,
   `enable_hard_delete`), a backward deploy or an unassign, show what
   will change and wait for the user's yes, as `land` stops before
   `main`. Authoring a CI pipeline file writes nothing and needs no
   stop.
4. **Run.** Read the route's reference first.
5. **Verify.** A deploy moves metadata, not data: refresh in the
   target, check pairing and bindings, read the operation's result.
6. **When it fails.** A symptom index into the references: a 403 (say
   which permission system), an item duplicated instead of overwritten,
   a report that lost its model, rules that did not apply.

The router stays short; the references hold the depth.

### Frontmatter

- `name: fabric-deploy`.
- `description`: at most 500 characters, trigger vocabulary and no
  facts. The user's words: deploy, promote, release, CI/CD, dev → test
  → prod. The tools' names: fabric-cicd, `FabricWorkspace`,
  `publish_all_items`, `parameter.yml`, deployment pipeline,
  `fab deploy`, Azure DevOps, GitHub Actions. The pair spend 2,468
  characters today: 990 and 1,023 of description, 455 of
  `when_to_use`. Upstream skills-for-fabric 0.3.14 cut its
  descriptions by about 40% "with no loss of routing accuracy"
  (`git show 7dd627e:docs/audits/2026-09-10/skills-for-fabric/completed/08-decide-catalog-budget-and-reference-lints.md`).
- `when_to_use`: the symptoms in today's `fabric-deployment-pipelines`
  one, within 512.
- No `paths:`. A deploy request arrives as words before any file is
  read, which is `msix-packaging`'s reasoning.
- `disable-model-invocation: false`, `# model: inherit`, `effort`
  commented: repo policy. Step 3's stop is what makes model invocation
  safe.

### Left where it is

`fabric-cli`'s `fab deploy` section and `fabric-rest-api`'s Git
integration section stay; the router names them. Moving them belongs
to the second wave, which restructures both skills anyway.

## The rename trap

Nothing errors when a skill name goes stale. Change each of these in
the commit that merges:

- `.claude/settings.json` `skillOverrides`: swap the two entries for
  `fabric-deploy`. `lint-skill-overrides` fails until then.
- A description naming either skill in backticks fails the routing
  lint (`scripts/skill-overlap.py routing`); a prose mention is only
  reported, so grep for those.
- `tests/skills/.tested.json`: drop the old stamp; `/test-skill`
  writes the new one.
- `skills/README.md`: one bullet for two, stating no facts.
- The drift-audit registry's skills-for-fabric mapping rows, at
  `.claude/skills/drift-audit/references/sources.md:659-660` on
  2026-10-06. `drift-registry-per-source.md` splits that file, so find
  the rows wherever they then live.
- Open briefs naming either skill: re-point them.
- `skills/meta/learn/SKILL.md`'s illustrative example cites
  `fabric-cicd/SKILL.md → ## Per-item-type caveats`: re-point it.
- `docs/audits/` is a dated ledger: leave it as written.
- fabric-cicd stays the library's name, and prose about the library
  keeps it. If the routing lint flags a backticked library mention in
  a description, unbacktick it.

The list, 22 files besides the two skills on 2026-10-06:

```bash
grep -rln 'fabric-cicd\|fabric-deployment-pipelines' --exclude-dir=audits --exclude-dir=.git .
```

**Client repos.** A repo whose `.claude/skills` links the `fabric`
group keeps junctions to both old names, dangling once the merge
reaches `main`, and lacks `fabric-deploy` until relinked. Find them,
list each one's `.claude/skills` first, then relink it with exactly
the groups it already holds, since `-SkillGroups` prunes what it
omits. The relink prunes the dangling junctions.

```bash
ls -d /c/Repos/*/*/.claude/skills/fabric-cicd
```

```powershell
./scripts/link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups <its groups>
```

## Measure

Before editing, record in the execution log the
`uv run --with pyyaml python scripts/skill-telemetry.py coverage` rows
for both skills. On 2026-10-06 each was listed in 41 sessions;
`fabric-cicd` had 2 Skill-tool dispatches and
`fabric-deployment-pipelines` none.

After:

1. **Behaviour**, by `/test-skill` against a `--safe-mode` baseline,
   and against the old pair in a probe deployed from the main checkout
   before the merge reaches it:

   | Case | Prompt, in short | Passes when |
   | --- | --- | --- |
   | Git route | deploy a Git-synced workspace folder to test | the library or `fab deploy` route, after reading `references/fabric-cicd.md` |
   | Pipeline route | promote dev to prod through a deployment pipeline | the pipelines route |
   | Stop | deploy it to prod, the session running the deploy | a plan, then a stop before the write |
   | 403 | a deploy fails with 403 | names which permission system is missing |
   | Cross-surface | will the report's OneLake images survive promotion? | the caveat, scoped to deployment pipelines |

2. **Listing**: the router's entry against the pair's 2,468
   characters.
3. **Use**, recorded later and not awaited:
   `skill-telemetry.py triggers` after a few weeks of client sessions.
   Is `fabric-deploy` invoked when deploy work happens?

## What the result decides

If 1 holds and 2 shows the saving, the second wave is next, each
candidate re-measured first. The user set its shape on 2026-10-09, in
[platform-skill-portfolio.md](platform-skill-portfolio.md):

- `fabric-auth`, `fabric-cli` and `fabric-gotchas` into
  `fabric-rest-api`, a surviving name, so fewer renames; the gotchas
  become a symptom → owner index. No brief carries this one yet. It
  takes the trigger the portfolio brief held for `fabric-auth`: what
  authorizes a service principal, tenant settings and workspace roles
  rather than API permissions. That guidance landed under `fabric-auth`'s
  401 heading, while its description, 639 characters on 2026-10-08, did
  not grow.
- [notebook-skills-into-fabric-spark.md](notebook-skills-into-fabric-spark.md):
  `fabric-ai-functions`, `fabric-mlv`, `fabric-spark-monitoring` and
  `fabric-error-handling` into `fabric-spark`, always listed.
- [pbir-skills-into-pbir-report-workflow.md](pbir-skills-into-pbir-report-workflow.md):
  `pbir-cli`, the six file-level PBIR skills and `powerbi-report-design`,
  no longer vendored, into `pbir-report-workflow`.
- `powerbi-report-authoring` goes, archived by the portfolio brief's
  Part 1.

None of it reopens Workstream C, declined 2026-09-01 and recorded in
both `tests/skills/*-triggers/expected_activations.md`, which covered
glob-scoped pairs only. If 1 fails, with the router routing worse than
the pair, record why here, stop, and put the two router briefs back to
the user, who decided them before this result.

## Re-measure before acting

- The 2026-10-06 fabric audit's briefs 05, 10, 11, 19 and 20 edit
  these two skills by line number, which is why this brief waits on
  that run. Read their execution logs, then re-read the skills: every
  line number above will have moved.
- Re-run the grep and the telemetry baseline.
- `ListAgents` and `git worktree list`: a peer may hold a brief that
  touches either skill.

## Not checked

- Whether one router is invoked more often than the pair was: step 3
  measures it.
- Whether `context: fork` helps a long deploy poll; nothing here needs
  it.

## Scrubbing

Client repos are named by kind. The numbers come from this machine's
transcripts, and no workspace, item or tenant is named.
