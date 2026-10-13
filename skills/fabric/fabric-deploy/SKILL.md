---
name: fabric-deploy
description: "Use when deploying, promoting or releasing Microsoft Fabric or Power BI items between workspaces — dev → test → prod, CI/CD — by any route: the fabric-cicd Python library (`FabricWorkspace`, `publish_all_items`, `parameter.yml`, `config.yml`), `fab deploy`, Git integration's Update From Git, or a deployment pipeline, scripted or run from Azure DevOps or GitHub Actions. Picks the route, checks the identity, shows the plan and stops before writing to a later stage, then verifies the deploy."
when_to_use: "Use when asked to deploy, promote or release a workspace or its items, set up a release pipeline for one, create a deployment pipeline or assign a workspace to a stage, or debug a deploy: a 403 that is a missing pipeline role rather than a workspace role, an item duplicated instead of overwritten, a report that lost its semantic model, rules that didn't apply, a parameter.yml value not substituted, or a greyed-out deploy-to-previous-stage button."
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Deploying Fabric content

A deploy moves item definitions from a source, a Git branch or a
workspace, into a target workspace. Four routes do it, each with its own
reference; this file picks one and wraps it in the steps every route
shares. Take them in order: a wrong route invalidates every step after
it.

## 1. Pick the route

| Source of truth | Route | Learn's option | Read |
| --- | --- | --- | --- |
| Git, one branch pushed to each stage by a script or CI | the fabric-cicd Python library | 2 | [fabric-cicd.md](references/fabric-cicd.md) |
| Git, the same in one command | `fab deploy --config`, which wraps the library and reads its `config.yml` and `parameter.yml` | 2 | `fabric-rest-api`'s `references/cli.md` § Workspace Deployment, then [fabric-cicd.md](references/fabric-cicd.md) |
| Git, a branch per stage, each stage's workspace connected | Git integration's Update From Git | 1 | `fabric-rest-api` § Git Integration APIs |
| The workspace: dev promoted to test and prod in the service | deployment pipelines | 3 | [deployment-pipelines.md](references/deployment-pipelines.md) |

Learn's option 2 also names the Bulk Import Item Definitions API, which
the library calls under `enable_bulk_publish`; Learn's
[tutorial](https://learn.microsoft.com/fabric/cicd/tutorial-bulkapi-cicd)
calls it directly.

**Never deploy into one workspace by both routes.** The library makes
its target match the repository, overwriting whatever a pipeline
promoted, and an item a Git route adds to a pipeline stage is not paired
with its source
([deployment-pipelines.md](references/deployment-pipelines.md) § Item
pairing and autobinding). Git on the first stage with pipelines onward is
not a mix: it is option 3, whose source of truth Learn gives as "Fabric
workspace (Git only through dev)" (read 2026-10-09). Decision guide:
[Choose the best Fabric CI/CD workflow](https://learn.microsoft.com/fabric/cicd/manage-deployment).

## 2. Preflight, every route

**Identity.** Name the identity the deploy will run as, and check:

- a workspace role on the target: Contributor or above for the library
  and `fab deploy`, Admin for `enable_hard_delete`;
- for a service principal, on any route, the tenant setting *Service
  principals can call Fabric public APIs* (older Learn pages: *can use
  Fabric APIs*);
- for Update From Git, the caller's own Git credentials;
- for a deployment pipeline, a second permission system on top of the
  workspace roles, pipeline Admin, and on a delegated token the
  deploy-only scope, `Pipeline.Deploy` or `DeploymentPipeline.Deploy.All`
  ([deployment-pipelines.md](references/deployment-pipelines.md) §
  Permissions, § Delegated scopes).

**What can move.** Each route carries its own set of item types: the
library's caveats are in [fabric-cicd.md](references/fabric-cicd.md) §
Item-type caveats, and a pipeline skips whatever is missing from
[deployment-pipelines-tables.md](references/deployment-pipelines-tables.md)
§ Supported item types. Four caveats cross routes, and each lives here:

- **Deployment plans** (preview): the fabric-cicd library doesn't support
  them; attach one through Update From Git, Deploy Stage Content or Bulk
  Import instead (Learn, 2026-10-06). The pipeline call's shape is in
  [deployment-pipelines.md](references/deployment-pipelines.md) §
  Deploying.
- **OneLake image URLs**: deployment pipelines don't rewrite them. A
  report whose visuals source images from OneLake carries the workspace
  GUID in each URL, so a promoted copy keeps loading them from the source
  workspace, and nothing fails or warns until access to that workspace is
  revoked or it is deleted:

  ```http
  https://onelake.dfs.fabric.microsoft.com/<workspace-guid>/<item-guid>/Files/<path>/<file-name>
  ```

  Upstream's remedies are deployment-pipeline parameters or a rewrite
  after deployment. Whether `parameter.yml`'s `find_replace` reaches a
  report definition for this is unverified, and whether Git integration,
  `fab deploy` or the library rewrite these URLs is undocumented, which is
  not "no"
  ([Learn](https://learn.microsoft.com/power-bi/visuals/power-bi-onelake-files)).
- **PBIR reports**: item 9 of Learn's general limitations lists them as
  unsupported in deployment pipelines, yet a PBIR-stored report has
  deployed to Test and Prod and redeployed in production use, per the
  pipeline's own records (2026-08-25/26). Treat item 9 as a claim to test,
  not a blocker, and don't stop the `pbir-*` workflow on it; the evidence
  is in
  [deployment-pipelines-tables.md](references/deployment-pipelines-tables.md)
  § Supported item types.
- **Direct Lake semantic models** are the one model type a pipeline
  doesn't autobind: deployed with its lakehouse, the target model still
  points at the source stage's lakehouse until a rule rebinds it, and
  which rule depends on the flavour
  ([deployment-pipelines.md](references/deployment-pipelines.md) § Item
  pairing and autobinding).

## 3. Plan, then stop

Before this session itself runs any of these, show what will change and
wait for the user's yes, as `land` stops before `main`:

- a write to any stage past the first, test and prod above all;
- an orphan delete: `unpublish_all_orphan_items`, a `config.yml` whose
  missing `unpublish` block unpublishes orphans by default, or
  `enable_hard_delete`, which bypasses the recycle bin;
- a backward deploy, or an unassign, which destroys the stage's
  deployment history and its rules for good.

"Deploy it to prod" names a target, not what changes there, so it is not
the yes. Writing a CI pipeline file, or a script for the user to run,
deploys nothing and needs no stop.

What to show, by route:

- **Library or `fab deploy`**: every run is a full deploy, so list the
  item types and folders in scope, whether orphans go, and any
  `enable_*_unpublish` flag that lets a data-bearing item be deleted.
- **Update From Git**: the `changes[]` from Get Status. A body of just
  the two hashes applies or refuses and never overwrites; say so if the
  plan adds `allowOverrideItems` or a `conflictResolution`, which do.
- **Deployment pipelines**: no API compares stages before a deploy, so
  list the stage items with their pairing. An unpaired item lands as a
  new copy, a selective deploy deletes nothing in the target, and an
  empty target stage gets a new workspace whose only admin is the
  deploying identity.

## 4. Run

Read the route's reference, from the table in step 1, before its first
call: request shapes, flags and limits are not repeated here. On a
pipeline,
[deployment-pipelines-tables.md](references/deployment-pipelines-tables.md)
adds the supported items, the full permission tables and the rule
limitations.

## 5. Verify

A deploy moves metadata, not data, on every route. After one:

1. Read the operation's result. A pipeline deploy that failed keeps its
   error on one step of `executionPlan.steps[]`, and the steps after it
   stay `NotStarted`, not deployed
   ([deployment-pipelines.md](references/deployment-pipelines.md) §
   Deploying).
2. Refresh in the target, each dataflow before the semantic models that
   read it.
3. Check pairing and bindings: on a pipeline, each item's pairing through
   List stage items; on any route, each report bound to the target's
   semantic model and each Direct Lake model reading the target's
   lakehouse.
4. Name what the deploy did not carry. On a pipeline that includes a
   semantic model's refresh schedule, credentials and role assignments
   ([deployment-pipelines-tables.md](references/deployment-pipelines-tables.md)
   § What a deploy copies).

## 6. When it fails

| Symptom | Cause, and where the fix is |
| --- | --- |
| 403 from a pipeline call | Say which system is missing: pipeline Admin, a workspace role on both stages, or `Pipeline.Deploy` on a delegated token. [deployment-pipelines.md](references/deployment-pipelines.md) § Permissions, § Delegated scopes |
| 401 or "credential required" from the library | Since v1.0 it needs an explicit `token_credential`. [fabric-cicd.md](references/fabric-cicd.md) § Troubleshooting |
| An item duplicated instead of overwritten | Pairing. [deployment-pipelines.md](references/deployment-pipelines.md) § Item pairing and autobinding |
| A report that lost its semantic model | Autobinding, in the same section |
| Rules that didn't apply | Rules apply on the next deploy. [deployment-pipelines.md](references/deployment-pipelines.md) § Deployment rules |
| A `parameter.yml` value not substituted | [fabric-cicd.md](references/fabric-cicd.md) § Troubleshooting |
| An orphan lakehouse or warehouse not deleted | On purpose, behind a flag. [fabric-cicd.md](references/fabric-cicd.md) § Feature flags |
| Deploy to the previous stage greyed out | [deployment-pipelines.md](references/deployment-pipelines.md) § Limits and gotchas |
| A 404 from `fab api` on a pipeline path | The audience. [deployment-pipelines.md](references/deployment-pipelines.md) § Through `fab` |
| Update From Git refuses to start | `fabric-rest-api` § Git Integration APIs |
| Anything else on a pipeline | [deployment-pipelines-tables.md](references/deployment-pipelines-tables.md) § Troubleshooting |

## See also

- `fabric-rest-api` — long-running operations, Git integration, and the
  definition APIs every route sits on; `fab api` mechanics and the
  `fab deploy` flags in its `references/cli.md`; token audiences and
  service principal setup in its `references/auth.md`
- `fabric-variable-library` — value sets, the other way to vary config
  per stage
- A Data Factory pipeline's activities are `fabric-data-pipeline`'s, a
  different thing from a deployment pipeline despite the name
