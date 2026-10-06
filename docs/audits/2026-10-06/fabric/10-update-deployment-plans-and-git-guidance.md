# Handoff: update deployment-plan and Git guidance

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 11 and 13
- **Kind**: three defects across one skill and one path-scoped rule, all
  verified against Learn's CI/CD pages:
  - additive API documentation (deployment plans);
  - status-label re-checks;
  - a factual update to the rule.
- **Target**: `skills/fabric/fabric-deployment-pipelines/SKILL.md`
  (lines 99, 170), `skills/fabric/fabric-deployment-pipelines/references/REFERENCE.md`
  (lines 18–19, 24), `claude/rules/fabric-git-serialization.md` (lines
  75–91)

## Context

Actions 11 and 13 share a brief because they are verified against the
same Learn CI/CD pages and touch the same workflow. The rule edit does
not depend on the skill edit; it is grouped here for verification only.

## D-1 — deployment plans are missing from the deploy API

**Symptom.** "Deployment plans (Preview)" was added by `9eda27f8`
(2026-10-02). The skill's deploy example at `SKILL.md:170` shows
`"options": { "allowCrossRegionDeployment": false },` and nothing else.
`REF:24`'s CI/CD row lists only Variable Library.

**Evidence.** Learn (agent-measured, 2026-10-06):

- `https://learn.microsoft.com/en-us/fabric/cicd/deployment-plan/deployment-plan-automation`
  — "Add a `deploymentPlan` object inside the existing `options`
  object." The call uses `?beta=true` and needs the extra scope
  `Item.Execute.All`.
- That article names the deploy scope as `Pipeline.Deploy` or
  `DeploymentPipeline.Deploy.All`; the skill's reference lists only
  `Pipeline.Deploy` (`SKILL.md:99`).
- `https://learn.microsoft.com/en-us/fabric/cicd/deployment-plan/deployment-plan-overview`
  — a plan cannot switch a Variable Library value set, and "The
  `fabric-cicd` library doesn't support deployment plans."
- `https://learn.microsoft.com/en-us/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines`
  lists "Deployment plan *(preview)*" under CI/CD items.
- The What's New row's own link did not resolve. Use the pages above.

**Fix.** Document `options.deploymentPlan` beside the existing example,
with the beta flag and extra scope. Add the second scope name at `:99`.
Add Deployment plan *(preview)* to `REF:24`, with the Variable Library
limitation.

## D-2 — two item labels may be stale

**Symptom.** `REF:18` lists "dbt Job *(preview)*" and `REF:19` lists
"Event Schema Set *(preview)*". In this window "dbt job in Fabric Data
Factory (Generally Available)" was promoted, and "Event Schema Registry
(Generally Available)" was promoted from "Schema Registry (Preview)".

**Cause.** These rows copy Learn's pipeline-support list, which can lag
an item's own GA. Item GA does not imply pipeline-support GA. `REF:26`'s
"Plan *(preview)*" still matches Learn, checked 2026-10-06.

**Fix.** Re-check both labels against the intro page's supported-items
list and copy what it says, with the date read. Flag only; don't flip on
What's New's word.

## D-3 — the Git rule predates three Git features

**Symptom.** `claude/rules/fabric-git-serialization.md`:

- `:88-91` treats a partial branch-out as an accident: "A branch-out or
  sandbox workspace commits *its* reality onto your branch —
  `shortcuts.metadata.json` 19 shortcuts → 1 … because that sandbox
  genuinely held one table."
- `:77-78` reads "Three ways that bites, all observed Sept 2026, all
  silent".
- `:75-83` warns "anything in the folder the live item does not contain
  is drift to be removed", and that hand-authored files are deleted.

**Evidence.** What's New `9eda27f8` added "Branch workspaces and
selective branching (Generally Available)" and "Compare and commit Git
changes (Generally Available)", the pair to the base preview row "Git
developer experiences (Preview)". It also added "File-level Git commit
(Preview)". Learn (agent-measured, 2026-10-06):

- `https://learn.microsoft.com/en-us/fabric/cicd/git-integration/branched-workspace`:
  - "allowing only chosen items to be included in the target workspace"
  - "When you branch out to an existing workspace, items that aren't
    saved to Git might be deleted."
- `https://learn.microsoft.com/en-us/fabric/cicd/git-integration/granular-compare`:
  - "An icon identifies each file as new, modified, or deleted."
  - "Unselected files remain uncommitted, so you can continue working on
    them and include them in a later commit."

**Fix.** Keep the measured September 2026 observations; they are dated
facts. Add the mitigations that now exist:

- Selective branching makes a partial workspace by design.
- The compare dialog shows each deletion before commit.
- File-level commit can leave a deletion uncommitted.

**Knock-on.** `commitToGit`'s `FileLevelSelective` mode is the REST side
of the same feature. Brief 11 adds it to `fabric-rest-api`; keep the
names consistent.

## Constraint on the fix

- The rule loads by `paths:` on every Fabric item folder; keep it short.
  Read `.claude/rules/editing-rules.md` before editing.
- Out of scope, in brief 20's incidental checks:
  - the network-security limits on CI/CD (deployment pipelines
    unsupported with inbound access protection);
  - per-item `validateOnly`;
  - the rule's `paths:` gaps for new item types.

## Verification

1. `grep -n -i "deploymentPlan\|Deployment plan\|DeploymentPipeline.Deploy.All" skills/fabric/fabric-deployment-pipelines/SKILL.md skills/fabric/fabric-deployment-pipelines/references/REFERENCE.md`
2. `grep -n -i "dbt Job\|Event Schema Set" skills/fabric/fabric-deployment-pipelines/references/REFERENCE.md`
   — each label matches Learn's list, with the date read.
3. `grep -n -i "selective\|compare\|file-level\|uncommitted" claude/rules/fabric-git-serialization.md`
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-deployment-pipelines/SKILL.md`
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01. The platform/CI-CD mapping subagent found D-1 and D-3. D-2's
dbt Job label was raised by the Data Factory subagent, and its Event
Schema Set label by the Real-Time Intelligence subagent. The audit
session read `REF:18-26` itself; the Learn quotes are the agents'.
