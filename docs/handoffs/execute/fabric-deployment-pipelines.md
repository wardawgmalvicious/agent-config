# Skill handoff brief: fabric-deployment-pipelines

Last verified: 2026-09-12

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

`skills/fabric/fabric-deployment-pipelines/SKILL.md`, plus
`skills/fabric/fabric-deployment-pipelines/references/REFERENCE.md`.

Payload, `fabric` group. It acts on the user's Fabric estate, not on this
repo, so it is not a `.claude/skills/` candidate. On this machine the
`fabric` group is **pruned from user scope** by the documented
workflow-only linker run, so this skill deploys nowhere here and enters
no session's payload — that is by design, not a missing step. It reaches
a client repo through
`link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups fabric`
or `copy-copilot.ps1 -SkillGroups fabric`.

## Scope

One skill covering the **service-side** deployment-pipelines surface end
to end: pipeline and stage lifecycle, workspace assignment, the deploy
long-running operation, the two independent permission systems and the
per-operation delegated scopes, item pairing and autobinding, deployment
rules, and the limits that bite. Inline execution (no `context: fork`),
model-invocable, and **unconditional — no `paths:` glob**, because
deployment-pipeline work arrives as words ("promote dev to test") rather
than as a file being opened; there is no on-disk artifact for this
feature the way a `.pbir` or a `.tmdl` file exists for its neighbours.

The user settled the boundary on 2026-09-12: **this skill owns the
surface.** It carries the full REST surface including the
`fab api -A powerbi` invocations, accepting a short-lived duplication
with `fabric-cli`'s "Deployment Pipelines (Power BI service-side)"
section. See Notes for the follow-up that removes the duplication.

Deliberately **not** covered: Git-driven deployment (`fabric-cicd`,
`fab deploy`) beyond a disambiguation table; Data Factory data pipelines;
Git integration APIs; the item-definition `getDefinition` contract.

## Sources drilled

All sources are public Microsoft documentation and one public Microsoft
GitHub repo. No client estate was consulted, so there is no observed
evidence to cite by kind.

Drilled:

- `learn.microsoft.com/fabric/cicd/deployment-pipelines/understand-the-deployment-process`
  — fetched in full. Established the permissions model (two independent
  systems; pipeline Admin is the lowest pipeline permission and is
  required for *all* operations), the permissions table, the
  required-permissions-per-action table, granted permissions and
  ownership changes, autobinding within and across pipelines (including
  that "same pipeline stage" means the numeric index rather than the
  display name, and that both pipelines must have equal stage counts),
  the copied and not-copied property lists, folder behaviour, and the
  general, semantic-model and dataflow limitation lists — which is where
  **"PBIR reports aren't supported"** and the 300-item cap come from.
- `learn.microsoft.com/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines`
  — fetched in full. The supported-item-type list by category with
  preview flags, 2–10 stages with the count and names permanent after
  creation, item pairing, and the 2026-02-12 retirement of support for
  semantic models not upgraded to Enhanced Metadata.
- `learn.microsoft.com/fabric/cicd/deployment-pipelines/pipeline-automation-fabric`
  — fetched in full. The 17 Fabric REST functions, the LRO integration
  and the 24-hour window on Get Operation Result, and the API-specific
  limitations: **Dataflows are not supported by the Fabric API** (use the
  Power BI API), and `allowPurgeData` / `allowTakeOver` /
  `allowSkipTilesWithMissingPrerequisites` exist only in the Power BI API.
- `rest/api/fabric/core/deployment-pipelines/deploy-stage-content`
  — fetched in full. `Pipeline.Deploy` as the required scope, "Maximum
  300 deployed items per request", the `202` response headers
  (`Location`, `x-ms-operation-id`, `deployment-id`, `Retry-After`), the
  `DeployRequest` shape, `createdWorkspaceDetails`, the `note` capped at
  1024 characters, `allowCrossRegionDeployment` as the only
  `DeploymentOptions` field, and the `ItemPreDeploymentDiffState` enum.
- `rest/api/fabric/core/deployment-pipelines/list-deployment-pipeline-stage-items`
  — fetched in full. The exact response schema, which carries **no change
  status**; `lastDeploymentTime` documented as "The last deployment date
  and time of the Fabric item"; and that `sourceItemId` and
  `targetItemId` appear only when the caller has contributor access to
  *that* stage's workspace.
- `rest/api/fabric/core/deployment-pipelines/assign-workspace-to-stage`
  — fetched in full. Scopes `Pipeline.ReadWrite.All` **and**
  `Workspace.ReadWrite.All`; admin on both the pipeline and the
  workspace; and "This operation will fail if there's an active
  deployment operation".
- `rest/api/fabric/core/deployment-pipelines/get-deployment-pipeline-operation`
  — fetched in full. The execution plan with per-item
  `preDeploymentDiffState`, and a sample response that **returns the
  deploy note** — which is what disproves the upstream claim below.
- `learn.microsoft.com/fabric/cicd/deployment-pipelines/create-rules`
  — via search, three chunks, including the full item and rule-type
  matrix and the complete considerations-and-limitations list. Rules are
  portal-configured; you must own the item; rules cannot be created in
  the development stage; unassign loses them.
- `learn.microsoft.com/fabric/cicd/deployment-pipelines/assign-pipeline`
  — via search, five chunks. Workspace assignment preconditions, the
  unassign warning, and the item-pairing tables including the folder
  tie-breaker and the duplicate-name failure.
- `learn.microsoft.com/fabric/cicd/troubleshoot-cicd` — via search, five
  chunks. "Lost connections after deployment" and its unassign and
  reassign repair, broken-rule failures, the *continue the deployment*
  schema-breaking-change message, backward deploy being **full-deployment
  only**, orphaned-pipeline recovery via
  `Admin - Pipelines UpdateUserAsAdmin`, and the first-deployment failure
  table.
- `github.com/microsoft/skills-for-fabric`,
  `skills/deployment-pipelines-authoring-cli/SKILL.md` (blob
  `7024db8d`, tree `24cc0d29`) — read in full, as the audit candidate
  this run acts on. Used only as a **claim list to verify**, never as
  content to lift.

Not drilled:

- **The Power BI `/pipelines` REST surface in detail.** Its existence,
  its role as the only route for Dataflows, and the three deploy options
  the Fabric API lacks are established from the Fabric automation page;
  the Power BI reference pages themselves (`deployall`,
  `selectivedeploy`, pipeline users, request bodies) were not fetched.
  Nothing in this skill describes their request shapes.
- **The `getDefinition` per-item-type contract** upstream leans on for
  change detection (a long-running operation for Notebook, SemanticModel
  and Report; synchronous for DataPipeline; absent for Warehouse). That
  belongs to `fabric-rest-api` and `fabric-tmdl-api`; this skill says
  change detection requires diffing definitions and points there rather
  than specifying the contract.
- **The per-item-type deployment pages** — each supported item type has
  its own Learn page describing what that type does and does not carry
  across a deploy. Only the Lakehouse, Notebook and Direct Lake
  specifics that surfaced in the pages above are encoded.
- **The new Deployment Pipeline UI (preview)** and
  `deployment-pipelines-new-ui`. The skill is API-first; UI steps are
  referenced by link only.
- **Azure DevOps and GitHub Actions wiring** for deployment pipelines,
  and the Power BI automation-tools Azure DevOps extension.
- **Deployment history** (`deployment-history`) as a page.
- **`fab` CLI native verbs.** `fabric-cli` records that none exist and
  that `fab api -A powerbi` is the route; that was not re-verified
  against the `fab` docs this run.
- The upstream skill's own `references/` (`supported-item-types.md`,
  `diff_item_definitions.py`, `COMMON-CLI.md`, `COMMON-CORE.md`).

### Upstream claims checked against Learn

The audit that authorised this run quoted the upstream bullet **without
drilling it** and said so. Verifying it was therefore the first job.

| Upstream claim | Verdict |
| --- | --- |
| `Pipeline.Deploy` for deploy; `Pipeline.Read.All` or `ReadWrite.All` for reads; plus `Workspace.ReadWrite.All` to assign | Confirmed, on each operation's own reference page |
| Maximum 300 items per deploy | Confirmed twice — the REST page and the process page |
| `lastDeploymentTime` is the last *deployment*, not the last edit | Confirmed by the field description |
| `List stage items` returns identity and pairing but no change status | Confirmed by the response schema |
| `x-ms-operation-id` response header | Confirmed in the `202` headers |
| Deploys copy definitions, not data | Confirmed |
| Pipeline Admin needed for every operation, plus workspace roles | Confirmed |
| Unassign then reassign is the only pairing repair, and loses rules | Confirmed — troubleshooting page plus rules limitation 4 |
| Backward deploy only to an empty target stage | Confirmed — **and Learn adds that backward deploys are full-deployment only**, which upstream omits |
| A deploy `note` is **write-only** | **Wrong.** `Get deployment pipeline operation` returns it; the sample response carries `"note": {"content": "Sample note"}` |
| One operation per pipeline at a time, error `WorkspaceMigrationOperationInProgress` HTTP 400 | **Behaviour** confirmed for assign ("will fail if there's an active deployment operation"); the **error code** is not on Learn |
| First-deploy warm-up, `Alm_InvalidRequest_WorkloadUnavailable`, roughly 60–120 s | Not on Learn |
| Duplicate pipeline name, `Alm_InvalidRequest_DuplicateAlmPipelineName` | Not on Learn |

The three unverified rows are plausible field observations. Per this
repo's rule they go in marked as unverified with a date, or not at all —
see Body structure outline step 10.

## Frontmatter

```yaml
---
name: fabric-deployment-pipelines  # repo linter requires it; lowercase/digits/hyphens; max 64 chars
description: {{see Description char count}}  # gated at 1,024, the Agent Skills spec cap
when_to_use: {{see Description char count}}  # gated separately at 512, the Claude-Code-only remainder
disable-model-invocation: false  # ALWAYS PRESENT; repo policy is false everywhere
# model: inherit  # ALWAYS PRESENT, ALWAYS COMMENTED — an active model: key blocks Copilot slash dispatch and fails lint
# effort: medium  # commented placeholder = inherit the session level; repo policy for platform skills
---
```

`when_to_use` **is** set — the trigger surface is wide (promotion verbs,
REST endpoints, permission errors, portal symptoms) and this field is the
non-portable half of the listing budget, so spending it costs nothing the
skill still had.

No `paths:`, deliberately — see Scope. That also keeps
`/fabric-deployment-pipelines` working as a slash command, which a glob
would disable until a matching file were Read.

`effort` stays commented, matching every other platform skill: these
auto-trigger alongside the user's real work, so a pin here would govern
that turn rather than a discrete skill run.

## Description char count

To be filled by the post-draft re-count, against `DESCRIPTION_MAX` 1,024
and `WHEN_TO_USE_MAX` 512.

- `description`: {{N}} / 1,024
- `when_to_use`: {{N}} / 512

## Body structure outline

1. **Which surface am I on?** A three-row table separating service-side
   deployment pipelines (the workspace is the source of truth) from
   `fabric-cicd` and `fab deploy` (Git is), with the standing rule not to
   mix them on the same workspaces. First, because picking the wrong
   surface invalidates everything after it.
2. **Concepts** — 2 to 10 stages, count and names permanent after
   creation; one workspace per stage and one stage per workspace;
   adjacent-stage deploys; backward deploys empty-target **and
   full-only**.
3. **Permissions: two independent systems.** Pipeline Admin is the
   lowest pipeline permission and is required for every operation; the
   workspace role is separate and is what actually gates content. The
   403-disambiguation rule lives here.
4. **Delegated scopes**, per operation — the table, with the point that
   `Pipeline.Deploy` is its own scope and `Pipeline.ReadWrite.All` alone
   gets a 403 on deploy.
5. **The REST surface** — an endpoint table under
   `https://api.fabric.microsoft.com/v1/deploymentPipelines`, plus the
   `fab api -A powerbi` equivalents this skill now owns.
6. **Deploying** — the `DeployRequest` shape, selective versus full,
   `createdWorkspaceDetails` when the target stage is empty, the
   long-running-operation handshake (`202`, then `x-ms-operation-id`,
   then poll `/v1/operations/{id}`), the 300-item cap,
   `allowCrossRegionDeployment`, and the note that a **selective deploy
   does not propagate deletions**.
7. **Item pairing and autobinding** — how pairing is established, the
   name, type and folder tie-breaker, why duplicates fail, that renaming
   does not unpair, and the unassign-and-reassign repair with its
   rules-and-history loss warning. Autobinding across pipelines keyed to
   stage *index*, and Direct Lake not rebinding.
8. **Change detection** — there is no pre-deploy compare API; what
   `List stage items` does and does not carry; that per-item diff state
   exists only *after* the fact, in the operation execution plan; and
   that real change detection means diffing definitions (a pointer, not
   a specification).
9. **Deployment rules** — portal-only, no REST API. The item and
   rule-type matrix, must own the item, cannot be created in the
   development stage, and take effect only on the next deploy.
10. **Limits and gotchas** — a table. PBIR reports unsupported; the
    Enhanced Metadata retirement; what a deploy does not copy (data,
    permissions, refresh schedules, credentials); gateway mapping not
    automatic on first deploy; first-deploy name collisions; circular
    dependencies; the Fabric-versus-Power-BI API gaps; GCC needing
    member rather than contributor. The three unverified upstream
    observations go here **marked unverified with the date**, or are
    dropped.
11. **Reference** — links, and the pointer to `references/REFERENCE.md`.
12. **See also** — `fabric-cicd`, `fabric-cli`, `fabric-rest-api`,
    `fabric-auth`, `fabric-variable-library`, and the `pbir-*` family for
    the PBIR consequence.

`references/REFERENCE.md` takes: the full supported-item-type list by
category with preview flags, the full permissions and
required-permissions-per-action tables, the complete rules matrix and its
limitation list, the full copied and not-copied lists, the Fabric versus
Power BI API difference list, and the troubleshooting table.

## Changes from source proposal

Derives from
[docs/audits/2026-09-10/skills-for-fabric/07-decide-new-skill-candidates.md](../../audits/2026-09-10/skills-for-fabric/07-decide-new-skill-candidates.md),
whose execution log records the user accepting all four candidates for
`/author-skill` on 2026-09-11. Departures from that input:

- **Renamed** from upstream's `deployment-pipelines-authoring-cli` to
  `fabric-deployment-pipelines`. The `-cli` suffix and the authoring and
  consumption mode split are upstream's conventions; this repo namespaces
  platform skills by product prefix. Matches how the three sibling
  candidates landed (`fabric-catalog-governance`, `fabric-activator`,
  `fabric-dataflow`).
- **Not vendored.** Option 2 in that brief was to take upstream verbatim.
  Authoring was chosen, and the drill then found one upstream claim wrong
  and three undocumented — which is the argument for having drilled.
- **Scope widened past "authoring".** Upstream's name implies the
  authoring half; this skill also carries change detection, the
  permissions model and the limits, because splitting them would leave
  two half-matching descriptions for one domain.

## Tag

`personal`

## Portability caveats

`when_to_use` is a Claude Code extension: GitHub Copilot warns on it and
ignores it, so a vendored copy triggers on `description` alone. That is
tolerable here — the description carries the primary vocabulary and the
disambiguation clause on its own.

No `paths:`, no `context: fork`, no hooks and no `allowed-tools`, so the
usual conditional-skill portability trap — a `paths:` skill loading
unconditionally under Copilot — does not apply to this one.

## Cross-reference dependencies

- `fabric-cicd` — (a) already converted. The counterpart Git-driven
  surface; its table row already points here in substance.
- `fabric-cli` — (a) already converted. Currently duplicates this
  skill's `fab api -A powerbi` section; see Notes.
- `fabric-rest-api` — (a) already converted. The long-running-operation
  and definition-API patterns change detection needs.
- `fabric-auth` — (a) already converted. Token audience and service
  principal setup behind the scopes table.
- `fabric-variable-library` — (a) already converted. A supported item
  type whose value-set semantics interact with staged environments.
- `pbir-*` family — (a) already converted. Reached only as a
  consequence: PBIR reports are unsupported by deployment pipelines.
- `microsoft/skills-for-fabric` `deployment-pipelines-authoring-cli` —
  (c) external. Verified against, not depended on.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**Follow-up, deliberately not done in this run.** `/author-skill` forbids
editing another skill, so `fabric-cli`'s "Deployment Pipelines (Power BI
service-side)" section still carries the `fab api -A powerbi` calls this
skill now owns. Reducing it to a two-line pointer is a `/learn` edit, and
should happen once this skill has passed `/test-skill`. Until then the
duplication is known and intended, not drift.

**The trigger-collision risk is real and named.** `fabric-data-pipeline`
is one word away and describes a completely different thing — a Data
Factory orchestration item. The description carries an explicit
disambiguation clause for that reason, and it is the first thing a
behavioural test should probe: "deploy my data pipeline to production" is
exactly the sentence that could route either way.

**The PBIR finding is the most valuable thing drilled.** This repo has
ten `pbir-*` and `pbip-*` skills built on PBIR report serialization, and
deployment pipelines do not support PBIR reports. Nothing in the payload
said so before this run.

## Confidence

- **Structure**: H. Mirrors the three sibling platform skills authored
  from the same audit, and the body-and-reference split follows the same
  rule as `fabric-cli`.
- **Field specs**: H. Every frontmatter decision follows a stated repo
  policy; the two character counts are machine-checked before hand-off.
- **Body content**: H for everything traced to a fetched page — the
  scopes, caps, headers, schemas, permissions and limitation lists were
  all read firsthand rather than summarised. M for the three upstream
  observations Learn does not document, which is why they are marked
  unverified rather than stated, and M for the Power BI API surface,
  which is described only by the differences the Fabric page enumerates.
