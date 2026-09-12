---
name: fabric-deployment-pipelines
description: "Use for Fabric / Power BI service-side deployment pipelines — the workspace-is-source-of-truth ALM surface promoting content stage to stage (dev → test → prod) via the Core REST API `/v1/deploymentPipelines` or `fab api`. Covers pipeline/stage lifecycle (2–10 stages, permanent once created), workspace assign/unassign, Deploy Stage Content as an LRO (202 + `x-ms-operation-id`, 300-item cap), per-operation delegated scopes (`Pipeline.Read.All`/`Pipeline.ReadWrite.All`, `Workspace.ReadWrite.All` to assign, `Pipeline.Deploy` — its own scope — to deploy), the two-permission model of pipeline Admin plus a workspace role on both stages, item pairing and its folder tie-breaker, autobinding across pipelines, portal-only deployment rules, and the limits that bite: PBIR reports unsupported, backward deploys empty-target and full-only, Direct Lake not rebinding, unassign destroying history and rules. For Git-driven deploys use fabric-cicd or `fab deploy`; for Data Factory orchestration items, fabric-data-pipeline."
when_to_use: "Use when promoting Fabric or Power BI content between deployment pipeline stages, creating a pipeline or assigning a workspace to a stage, automating a deploy from Azure DevOps or GitHub Actions, or debugging one — a 403 that is a missing pipeline role rather than a workspace role, a deploy that duplicated an item instead of overwriting it, a report that lost its semantic model, rules that didn't apply, or a greyed-out deploy-to-previous-stage button."
disable-model-invocation: false
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
---

# Fabric deployment pipelines (service-side)

The **service-side** ALM surface: a pipeline of ordered stages, each
holding one workspace, promoting content from one stage to the next. The
**workspace is the source of truth** — no local code, no repository.
Driven from the portal, or from the Fabric Core REST API under
`https://api.fabric.microsoft.com/v1/deploymentPipelines`.

## Which surface am I on?

Three different things deploy Fabric content. Pick first — getting this
wrong invalidates everything after it.

| Surface | Source of truth | Use when |
|---|---|---|
| **Deployment pipelines** (this skill) | The **workspace** | Promoting a dev workspace to test/prod inside the service; stage-to-stage, nothing on disk |
| `fabric-cicd` (Python library) | **Git** | Scripted deploys from a repo checkout; `publish_all_items`, `parameter.yml` |
| `fab deploy --config` | **Git** | One-command CLI wrapper over the same library |

**Don't mix Git-driven deploys and service-side pipelines on the same
workspaces.** Decision guide:
[Choose the best Fabric CI/CD workflow](https://learn.microsoft.com/fabric/cicd/manage-deployment).

## Concepts

- A pipeline has **2 to 10 stages** (default 3). **The number of stages
  and their names are permanent** once the pipeline is created — only a
  stage's *public* flag can change afterwards.
- Each stage holds **at most one workspace**, and a workspace can be
  assigned to **at most one** pipeline stage, tenant-wide.
- Deploys run between **adjacent** stages, in either direction.
- **Backward deploys** (prod → test) work **only when the target stage is
  empty**, and support **full deployment only** — selective deployment is
  not available backwards.
- A deploy copies **metadata, not data**. Semantic models and dataflows
  arrive empty; refresh in the target stage afterwards.

## Permissions: two independent systems

Pipeline permissions and workspace permissions are **granted and managed
separately, and you generally need both**. This is the single most common
source of a confusing 403.

- A pipeline has exactly **one** permission: **Admin**. It is the *lowest*
  deployment-pipeline permission and is **required for every
  deployment-pipeline operation** — there is no viewer-level pipeline role.
- Pipeline access alone grants **nothing** over workspace content. A
  pipeline admin with no workspace role can see and share the pipeline,
  but cannot view its content or deploy.
- To **deploy**: pipeline Admin **and** at least Contributor on **both**
  the source and target workspaces.
- To **assign** a workspace: pipeline Admin **and** workspace **Admin** of
  the workspace being assigned.
- **GCC**: deploying requires at least **Member** of both workspaces;
  contributor is not supported there.

**On a 403, say which of the two is missing.** "You need pipeline access"
and "you need a workspace role" send the user to different people; a bare
"permission denied" sends them nowhere.

**A documented inconsistency worth knowing when assigning.** Two Learn
pages disagree on the adjacent-stage requirement:
[assign-pipeline](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/assign-pipeline#considerations-and-limitations)
says you need at least workspace **contributor** on the workspaces in
adjacent stages, while
[troubleshoot-cicd](https://learn.microsoft.com/fabric/cicd/troubleshoot-cicd#error-message-workspace-member-permissions-needed)
titles the same failure *"workspace member permissions needed"* and says
**member**. The error text says member; ask for member when the
contributor grant doesn't clear it.

Full permissions and per-action tables:
[references/REFERENCE.md](references/REFERENCE.md).

## Delegated scopes

Scopes are **per operation** — provision a service principal with least
privilege.

| Operation | Required delegated scope |
|---|---|
| List / Get pipelines, stages, stage items, operations | `Pipeline.Read.All` **or** `Pipeline.ReadWrite.All` |
| Create / Update / Delete pipeline, Update stage, role assignments | `Pipeline.ReadWrite.All` |
| Assign / Unassign workspace | `Pipeline.ReadWrite.All` **and** `Workspace.ReadWrite.All` |
| **Deploy stage content** | **`Pipeline.Deploy`** |

**Deploy has its own scope.** An app holding only
`Pipeline.ReadWrite.All` can create pipelines and assign workspaces and
still cannot deploy.

**Service principals and managed identities** are supported on the read
and assign operations. On **deploy** they are supported *"only when all
the items involved in the operation support service principals"* — so one
unsupported item type in the stage fails the whole deploy for an SPN.
Dataflows never support service principals.

## The REST surface

Base: `https://api.fabric.microsoft.com/v1`.

| Operation | Method + path |
|---|---|
| List pipelines | `GET /deploymentPipelines` |
| Create pipeline | `POST /deploymentPipelines` |
| Get / Update / Delete pipeline | `GET\|PATCH\|DELETE /deploymentPipelines/{id}` |
| List / Get stages | `GET /deploymentPipelines/{id}/stages[/{stageId}]` |
| Update stage | `PATCH /deploymentPipelines/{id}/stages/{stageId}` |
| **List stage items** | `GET /deploymentPipelines/{id}/stages/{stageId}/items` |
| **Assign workspace** | `POST /deploymentPipelines/{id}/stages/{stageId}/assignWorkspace` |
| Unassign workspace | `POST /deploymentPipelines/{id}/stages/{stageId}/unassignWorkspace` |
| **Deploy stage content** (LRO) | `POST /deploymentPipelines/{id}/deploy` |
| List / Get operations | `GET /deploymentPipelines/{id}/operations[/{operationId}]` |
| Role assignments | `GET\|POST\|DELETE /deploymentPipelines/{id}/roleAssignments[/{principalId}]` |

The **bold** rows were read from their own reference pages (2026-09-12).
The rest are named in Learn's
[API function list](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/pipeline-automation-fabric#deployment-pipelines-api-functions)
and follow the same path shape — check the per-operation reference before
scripting one.

**Never guess IDs.** Resolve pipeline, stage and workspace IDs by listing
and filtering on `displayName`.

### Through `fab`

There are no native `fab` verbs for deployment pipelines — use `fab api`.
**Mind the audience: the two surfaces are different APIs.**

```bash
# Fabric Core surface (this skill) — DEFAULT audience, no -A flag
fab api "deploymentPipelines"
fab api "deploymentPipelines/$PIPELINE_ID/stages"
fab api "deploymentPipelines/$PIPELINE_ID/stages/$STAGE_ID/items"
fab api -X post "deploymentPipelines/$PIPELINE_ID/stages/$STAGE_ID/assignWorkspace" \
  -i '{"workspaceId":"<ws>"}'

# Older Power BI pipelines surface — REQUIRES -A powerbi
fab api -A powerbi pipelines                    # user pipelines
fab api -A powerbi admin/pipelines              # tenant-wide (admin)
```

Reaching a `deploymentPipelines` path with `-A powerbi`, or a `pipelines`
path without it, is a 404 that reads like a missing feature.

## Deploying

```jsonc
{
  "sourceStageId": "<uuid>",          // required
  "targetStageId": "<uuid>",          // required
  "items": [                          // omit to deploy ALL supported items
    { "sourceItemId": "<uuid>", "itemType": "SemanticModel" },
    { "sourceItemId": "<uuid>", "itemType": "Report" }
  ],
  "note": "Promote reviewed model + report",   // max 1024 chars
  "options": { "allowCrossRegionDeployment": false },
  "createdWorkspaceDetails": {        // REQUIRED when target stage is empty
    "name": "Sales — Test",
    "capacityId": "<uuid>"            // defaults to the source stage capacity
  }
}
```

Write the body to a file rather than inlining it — a multi-line inline
JSON body is mangled on Windows shells.

**It is a long-running operation.** The call returns **`202 Accepted`**
with the operation ID in the **`x-ms-operation-id` response header**
(alongside `Location`, `deployment-id` and `Retry-After`) — *not* in the
body. Poll `GET /v1/operations/{operationId}` until the state is terminal.
For **24 hours** after completion the extended result is available from
Get Operation Result.

`az rest` does not surface response headers cleanly; use `curl -i` or
`requests` to capture the header, then poll.

Constraints:

- **Maximum 300 deployed items per request.** Batch larger promotions.
- **A selective deploy does not propagate deletions.** An item removed
  from the source stage is not removed from the target. Use a full deploy
  (omit `items`), or delete the target item by hand — and say so before
  promoting.
- Deploying to an empty target stage **creates a workspace**, and the
  deploying user becomes its **only admin** and the owner of cloned
  semantic models.
- `allowPurgeData`, `allowTakeOver` and
  `allowSkipTilesWithMissingPrerequisites` **do not exist** in the Fabric
  API — they are Power BI API only, and work only for Power BI items.
- **Dataflows are not supported by the Fabric deployment API at all**; use
  the Power BI `/pipelines` API for those.

## Item pairing and autobinding

**Pairing** is the link between an item and its clone in the adjacent
stage. It is what makes a deploy *overwrite* rather than *duplicate*.
There is **no API to set pairing** — it is established automatically, two
ways:

1. **On deploy** — an unpaired item deployed to the next stage is copied
   and paired (a *clean deploy*).
2. **On workspace assignment** — Fabric attempts to pair by **item name**,
   **item type**, and **folder location as a tie-breaker** when a stage
   holds duplicates.

Consequences that bite:

- Two items with the **same name, type and folder** in a workspace:
  **pairing fails and the assignment fails.** Rename or move one.
- Same name and type in **different folders**: deployment succeeds but the
  item is **not paired** — so it silently duplicates forever after.
- **Renaming does not unpair.** Paired items can legitimately have
  different names.
- Items added to a workspace **after** assignment are **not** auto-paired,
  so identical items can sit unpaired in adjacent stages.
- Observe current pairing through `sourceItemId` / `targetItemId` on
  `List stage items` — but each appears **only if the caller has
  contributor access to that stage's workspace**, so a thin result can
  mean missing permission rather than missing pairing.

**Autobinding** keeps dependencies connected (a report to its semantic
model). Within a pipeline, a deploy binds to the dependency in the
*target* stage if it is there, and **fails** if the dependency is neither
deployed with it nor already present — use *Select related*.

Across pipelines, items bind when they are in **the same pipeline stage**,
which means **the same numeric stage index, not the same display name**.
Stages in matching positions bind even when named differently, and two
stages sharing a name do not bind when their positions differ. Both
pipelines must have **the same number of stages**.

**Direct Lake semantic models do not autobind.** Deploy a Direct Lake
model and its lakehouse together and the target model still points at the
**source** stage's lakehouse. Bind it with a data source rule. Every other
model type binds to the paired item normally.

### Repairing a broken pairing

The only supported repair is to **unassign the workspace from the stage
and reassign it**, then redeploy.

**Warn before doing it.** Unassigning **permanently destroys that stage's
deployment history and every deployment rule configured on it**, and
reassigning does not bring them back. Rules are portal-only with no API to
read or recreate them, so **ask whether the stage has rules first** and
have the user record them before you proceed.

## Change detection

**There is no pre-deploy compare API.** The portal's Compare view is
server-side and not exposed.

`List stage items` returns identity and pairing only — `itemId`,
`itemDisplayName`, `itemType`, `sourceItemId`, `targetItemId`,
`lastDeploymentTime`. It carries **no change status**, and
`lastDeploymentTime` is *"the last deployment date and time of the Fabric
item"* — the last **deployment**, not the last **edit**. It cannot tell
you whether anything changed since.

Per-item diff state **does** exist, but only **after the fact**: `Get
deployment pipeline operation` returns an execution plan whose steps each
carry `preDeploymentDiffState` (`New` / `Different` / `NoDifference`),
plus a `preDeploymentDiffInformation` summary. Useful for auditing what a
deploy did; useless for deciding what to deploy.

So "deploy only what changed" means diffing item **definitions** yourself
— see the `fabric-rest-api` skill for the `getDefinition` contract, which
differs by item type. Two traps:

- **Deployment auto-rebinds embedded references** in the target (pipeline
  `notebookId`/`workspaceId`, report-to-model id, Direct Lake
  server/database). A paired target's definition therefore differs from
  its source even when nothing was edited — naive hashing reports false
  "changed". Normalize those fields before comparing.
- Do the comparison **in a script** and surface only the change list.
  Dumping two full definitions per item into context costs far more than
  the answer is worth.

## Deployment rules

Rules re-point content per stage — a production semantic model to a
production database, without editing the model.

**Rules are configured in the portal. There is no REST API to create, read
or recreate them.** Do not claim otherwise, and do not script around them.

| Item | Data source rule | Parameter rule | Default lakehouse rule |
|---|---|---|---|
| Dataflow gen1 | yes | yes | — |
| Semantic model | yes | yes | — |
| Paginated report | yes | — | — |
| Mirrored database | yes | — | — |
| Notebook | — | — | yes |

- You must be the **owner of the item** to set a rule for it, on top of
  pipeline Admin and a target-workspace role.
- **Rules cannot be created in the development stage** — they are defined
  on the *target*.
- **Rules take effect only on the next deploy to that stage.** Configure,
  then redeploy; until then the target keeps the old value and the item
  shows as *different*.
- Data source rules only swap a source for one of the **same type**, and
  the same data source cannot appear in two rules.
- If the data source or parameter a rule points at is changed or removed
  in the source stage, the rule becomes invalid and **deployment fails**.
- Deleting an item deletes its rules irrecoverably, and so does
  unassigning the workspace.

Full limitation list: [references/REFERENCE.md](references/REFERENCE.md).

## Limits and gotchas

| Symptom / limit | Detail |
|---|---|
| **PBIR reports aren't supported** | Stated flatly in the general limitations. A report in the enhanced report format does not deploy through a pipeline — this is the surface where the `pbir-*` workflow stops |
| Semantic models need Enhanced Metadata | Since **2026-02-12**, deployment pipelines retired support for semantic models not upgraded to Enhanced Metadata |
| First deploy of a Power BI item fails | Another item in the target stage has the same name *and* type. Rename one |
| Deployment fails on dependencies | Circular or self dependencies fail the whole deploy |
| Assignment fails during a deploy | Assign "will fail if there's an active deployment operation" — poll the current operation to a terminal state first |
| Gateway not mapped after first deploy | The target item's gateway is **not** auto-mapped to its data source. Configure it once by hand in item settings; later deploys leave it alone |
| Data is missing after deploy | Expected — metadata only. Refresh the dataflow first, then the semantic model |
| *"Continue the deployment"* message | A schema-breaking change (for example an int column becoming a string) would lose data in the target. Continuing loses it; the alternative is fixing the source and redeploying |
| Backward deploy button greyed out | You can only deploy backwards into an **empty** stage — and only as a full deployment |
| Not copied by a deploy | Data, URL, ID, permissions, workspace settings, app content, personal bookmarks; and for semantic models: role assignments, refresh schedule, data source credentials, query caching, endorsement |
| Orphaned pipeline (owner left) | A Fabric admin adds an owner or deletes it via the `Admin - Pipelines UpdateUserAsAdmin` API. Until then nobody can unassign its workspaces |
| Dataflow refreshing during deploy | The deployment fails. Comparing stages during a refresh gives unpredictable results |

**Unverified, from upstream's skill rather than Learn (noted
2026-09-12).** Plausible field observations, documented nowhere on Learn —
treat as leads, not facts: a second concurrent operation failing with
`WorkspaceMigrationOperationInProgress` (HTTP 400); a first deploy after
assignment failing with `Alm_InvalidRequest_WorkloadUnavailable` for
~60–120 s while workloads warm up; and a duplicate pipeline `displayName`
failing with `Alm_InvalidRequest_DuplicateAlmPipelineName`, implying names
are unique tenant-wide.

## Reference

- Microsoft Learn:
  [Introduction to deployment pipelines](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines)
  · [The deployment pipelines process](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/understand-the-deployment-process)
  · [Assign a workspace](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/assign-pipeline)
  · [Create deployment rules](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/create-rules)
  · [Troubleshoot lifecycle management](https://learn.microsoft.com/fabric/cicd/troubleshoot-cicd)
- Automation:
  [Fabric APIs](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/pipeline-automation-fabric)
  · [Power BI APIs](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/pipeline-automation)
  · [REST reference](https://learn.microsoft.com/rest/api/fabric/core/deployment-pipelines)
- PowerShell samples:
  [`microsoft/fabric-samples` features-samples/fabric-apis](https://github.com/microsoft/fabric-samples/blob/main/features-samples/fabric-apis/DeploymentPipelines-DeployAll.ps1)
  — deploy all, selective deploy, assign-and-deploy
- Supported item types, full permissions tables, the complete rules
  limitation list, and the Fabric-vs-Power BI API differences:
  [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-cicd skill — the Git-driven counterpart: `publish_all_items`,
  `parameter.yml`, feature flags
- fabric-cli skill — `fab api` mechanics, and `fab deploy` for the
  Git-driven path
- fabric-rest-api skill — long-running-operation polling and the
  `getDefinition` contract change detection needs
- fabric-auth skill — token audiences and service principal setup behind
  the scopes table
- fabric-variable-library skill — a supported item type whose value sets
  are the other way to vary config per stage
- **Not** fabric-data-pipeline — that is the Data Factory orchestration
  item, unrelated to this despite the name
