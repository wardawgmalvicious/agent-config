# Deployment pipelines — reference tables

Long-form detail for the `fabric-deployment-pipelines` skill. Everything
here was read from Microsoft Learn on **2026-09-12**; the item list and
the preview flags move, so re-check
[Supported items](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines#supported-items)
rather than trusting this copy for a go/no-go decision.

## Supported item types

Items not on this list are **not copied** to the next stage. They are
skipped rather than failing the deploy.

| Category | Items |
|---|---|
| **Data Engineering** | Environment · GraphQL · Lakehouse · Notebook · Spark Job Definition · User Data Functions |
| **Data Science** | ML experiments *(preview)* · ML models *(preview)* · Data Agents |
| **Data Factory** | Copy Job · Dataflow Gen2 · Pipeline · Mirrored database · Mount ADF · Mirrored Snowflake *(preview)* · Airflow *(preview)* · dbt Job *(preview)* · Operations Agent *(preview)* |
| **Real-Time Intelligence** | Activator · Eventhouse · Eventstream · KQL database · KQL queryset · Real-Time Dashboard · Maps · Digital twin builder *(preview)* · Event Schema Set *(preview)* · Anomaly detection *(preview)* |
| **Data Warehouse** | Warehouse · Mirrored Azure Databricks Catalog |
| **Power BI** | Dashboard *(preview)* · Dataflow *(preview)* · Org app *(preview)* · Paginated report *(preview)* · Report, based on supported semantic models *(preview)* · Semantic model originating from a .pbix and not a PUSH dataset *(preview)* |
| **Database** | SQL database · Cosmos database *(preview)* |
| **Graph** | Graph Model · Graph QuerySet |
| **CI/CD** | Variable Library |
| **Industry solutions** | Healthcare *(preview)* · HealthCare Cohort *(preview)* |
| **IQ** | Ontology *(preview)* · Plan *(preview)* |

**Two exclusions that surprise people.** PBIR-format reports are not
supported — the general limitations say so outright. And semantic models
that were never upgraded to Enhanced Metadata lost support on
**2026-02-12**.

The `ItemType` enum accepted in a deploy request body is the general
Fabric item enum and is **much wider than this list** — a type appearing
in the enum is not evidence that deployment pipelines support it.

## Permissions

Pipeline permissions and workspace permissions are granted and managed
separately. Pipeline Admin is the lowest pipeline permission and is
required for **every** deployment-pipeline operation. Microsoft 365
groups are not supported as pipeline admins.

| User | Pipeline permissions |
|---|---|
| **Pipeline admin** | View, share, edit and delete the pipeline; unassign a workspace from a stage; see workspaces tagged as assigned. **Grants nothing over workspace content.** |
| **Workspace viewer** + pipeline admin | Consume content; unassign a workspace. Without *build* permission, cannot access the semantic model or edit content |
| **Workspace contributor** + pipeline admin | Consume content; compare stages; view semantic models; unassign; **deploy items** (needs at least contributor on *both* source and target) |
| **Workspace member** + pipeline admin | The above, plus view workspace content, update semantic models, and configure semantic model rules (you must own the model) |
| **Workspace admin** + pipeline admin | The above, plus **assign** workspaces to a stage |

### Required permissions per action

| Action | Required |
|---|---|
| View the list of pipelines in the org | No license required (free user) |
| Create a pipeline | Pro, PPU or Premium license |
| Delete a pipeline | Pipeline admin |
| Add or remove a pipeline user | Pipeline admin |
| Assign a workspace to a stage | Pipeline admin **+ workspace admin** of the workspace being assigned |
| Unassign a workspace | Pipeline admin **or** workspace admin (via the Unassign Workspace API) |
| Deploy to an **empty** stage | Pipeline admin + **source** workspace contributor |
| Deploy to the next stage | Pipeline admin + workspace contributor on **both** stages; dataflows additionally need item ownership; semantic models need ownership if the tenant switch is on |
| View or set a rule | Pipeline admin + target workspace contributor/member/admin + **owner of the item** |
| Manage pipeline settings | Pipeline admin |
| View a pipeline stage | Pipeline admin + any workspace role (you see what your role grants) |
| View the list of items in a stage | Pipeline admin |
| Compare two stages | Pipeline admin + contributor/member/admin on **both** stages |
| View deployment history | Pipeline admin |

**GCC**: deploying requires at least **member** of both workspaces —
contributor is not supported there yet.

**From 2026-12-01**, a user without read-write permission on **all** items
in a workspace cannot deploy to it or assign it to certain stages, where
the workspace holds items protected by sensitivity labels with protection
policies.

### Ownership changes on deploy

| Item | Required to deploy an existing item | Ownership after first deployment | Ownership after later deployments |
|---|---|---|---|
| Semantic model | Workspace member | The deploying user | Unchanged |
| Dataflow | Dataflow owner | The deploying user | Unchanged |
| Paginated report | Workspace member | The deploying user | **The deploying user** (changes every time) |

Deploying to an empty stage creates the workspace and makes the deploying
user its **only admin**.

## Workspace assignment preconditions

A workspace appears in the assignable list only when **all** of these
hold. Anything else and it is silently absent from the dropdown.

1. You are an **admin** of the workspace.
2. The workspace is not assigned to any other deployment pipeline.
3. The workspace resides on a **Fabric capacity**.
4. You hold at least contributor (see the skill body on the
   contributor-vs-member doc inconsistency) on the workspaces in
   **adjacent** stages.
5. The workspace contains no Power BI **samples**.
6. The workspace is not a **template app** workspace and has no template
   app installed.

Assignment also fails outright when two or more items in the workspace
share a name, type **and** folder — pairing cannot resolve them.

## Deployment rules — full limitations

1. You must be the **owner** of the item to create a rule for it.
2. Rules **cannot be created in the development stage**.
3. Deleting or removing an item deletes its rules; they cannot be
   restored.
4. **Unassigning and reassigning a workspace loses that stage's rules.**
   Reconfigure them by hand afterwards.
5. If the data source or parameter a rule points at is changed or removed
   in the source stage, the rule is invalid and **deployment fails**.
6. After deploying a paginated report with a data source rule, the report
   can no longer be opened in Power BI Report Builder.
7. Rules take effect **only on the next deploy** to that stage — though a
   stage comparison made before that deploy already reflects them.
8. Unsupported entirely:
   - Data source rules for dataflows gen1 that have other dataflows as
     sources.
   - Data source rules for common data model (CDM) folders in a dataflow
     gen1.
   - Data source rules for semantic models using dataflows gen1 as a
     source.
   - Data source rules on a semantic model using Native query and
     DirectQuery together.
   - Parameter rules for paginated reports.
   - Data source rules for semantic models and dataflows gen1 on data
     sources that are **parameterized** — use a parameter rule instead.
9. Power Query Online (PQO) data source rules are unsupported for
   paginated reports; only non-PQO connection types such as direct
   connection strings can be overridden.

Data source rules can only swap a source for one of the **same type**,
and the same data source cannot be used in more than one rule. Parameter
rules used to rebind items require parameters of type `Text`.

## What a deploy copies

**Copied**, overwriting the target: data sources (rules apply) ·
parameters (rules apply) · report visuals · report pages · dashboard
tiles · model metadata · item relationships.

**Sensitivity labels** are copied only when a new item is deployed or an
existing item is deployed to an empty stage, or when the source has a
label with protection and the target does not (which prompts for
consent). Where tenant default labeling is on and the label is *not*
protected, a newly created target semantic model or dataflow gets the
**default** label rather than the source's.

**Not copied**: data · URL · ID · permissions · workspace settings · app
content and settings · personal bookmarks. And for semantic models: role
assignments · refresh schedule · data source credentials · query caching
settings · endorsement settings.

The overwrite replaces item content only — the target item's **ID, URL
and permissions are preserved**.

## Semantic model and dataflow limitations

**Semantic models**

- Models using real-time data connectivity cannot be deployed.
- DirectQuery or Composite models using variation or auto date/time
  tables are unsupported.
- If the target model uses a live connection, the source must use it too.
- Downloading a semantic model from the stage it was deployed to is not
  supported — nor is downloading a `.pbix` after deployment.
- With autobinding engaged: Native query plus DirectQuery together is
  unsupported (including proxy models), and the data source connection
  must be the **first step** in the mashup expression.
- Direct Lake models do not autobind — use a data source rule.
- A model using a **Dataflow Gen2 (CI/CD)** item as a data source cannot
  be deployed.
- **Incremental refresh** is supported and the policy travels with the
  model, but republishing changes that risk data loss fail the deploy:
  replacing an incremental-refresh model with one without it, renaming a
  table with incremental refresh, or renaming non-calculated columns in
  such a table. Adding, removing or renaming *calculated* columns is
  fine.
- **Automatic aggregations** in the target are never overwritten by a
  deploy.
- **Hybrid tables**: a clean deploy copies both the refresh policy and
  the partitions; deploying into a stage that already has partitions
  copies the **policy only** — refresh to rebuild them.

**Dataflows**

- Incremental refresh settings are not copied in Gen1.
- Deploying to an empty stage sets dataflow storage to Fabric blob
  storage even when the source workspace uses ADLS Gen2.
- Service principals are not supported for dataflows at all.
- Common data model (CDM) deployment is unsupported.
- A dataflow being refreshed during deployment **fails** the deployment,
  and comparing stages mid-refresh gives unpredictable results.
- Autobinding is not supported for Dataflows Gen2.

## Fabric API vs Power BI API

Two REST surfaces reach deployment pipelines. They are not
interchangeable.

| | Fabric Core API | Power BI API |
|---|---|---|
| Base | `api.fabric.microsoft.com/v1/deploymentPipelines` | `api.powerbi.com/v1.0/myorg/pipelines` |
| Via `fab` | default audience | `-A powerbi` |
| Dataflows | **Not supported** | Supported |
| `allowPurgeData` | Absent | Available (Power BI items only) |
| `allowTakeOver` | Absent | Available (Power BI items only) |
| `allowSkipTilesWithMissingPrerequisites` | Absent | Available (Power BI items only) |
| Manage pipeline users | Via `roleAssignments` | `Update`/`Delete pipeline user` |
| Orphaned-pipeline recovery | — | `Admin - Pipelines UpdateUserAsAdmin` |

Every limitation of deployment pipelines applies to both APIs. The Power
BI surface's request shapes were **not drilled** when this skill was
written — read its
[reference](https://learn.microsoft.com/rest/api/power-bi/pipelines)
before scripting one.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Can't see the deployment pipelines button | Needs a Fabric license, workspace admin, and pipeline admin on the pipeline the workspace is assigned to |
| Can't see the pipeline stage tag | Dev and Test tags are always visible; the **Production** tag needs pipeline access |
| Lost connections after deployment | Pairing could not be re-established (for example an item was deleted). Unassign and reassign the same workspace in the target stage — losing that stage's history and rules |
| Can't assign a workspace | Check the six preconditions above; a workspace failing any of them is simply absent from the list |
| "Workspace member permissions needed" | You lack the role on an **adjacent** stage's workspace, not the one you are assigning |
| Deployment fails on broken rules | A republished semantic model removed or renamed a parameter, or a data source rule lost its values. Fix or remove the rule, then redeploy |
| Configured rules but nothing changed | Rules apply on the **next** deploy. Deploy the model from source to target |
| Rules greyed out | You are not the item owner, or the item has no data sources / no parameters to bind |
| Data source rule won't save | The model has a function connected to a data source (unsupported), or the source is parameterized — use a parameter rule |
| "Can't start the deployment" | An incremental-refresh model changed in a way that isn't allowed. Publish the `.pbix` straight to the target, or edit the target model via XMLA |
| "Continue the deployment" | Schema-breaking change would lose target data. Continuing loses it; otherwise fix the source and redeploy |
| Visual broke after deploying a model or dataflow | Metadata only was copied. Refresh the dataflow, then the model |
| "Deploy to previous stage" disabled | Backwards deploys only target an **empty** stage, and only as a full deployment |
| First deployment failed | Missing capacity permission, missing workspace role, workspace creation disabled by the Fabric admin, or a selective deploy that omitted linked items |
| "Unsupported items" in the workspace | Check the supported-items list; unsupported items are skipped, not deployed |
| Orphaned pipeline nobody can access | A Fabric admin assigns a new owner or deletes it via `Admin - Pipelines UpdateUserAsAdmin` |
| DLP policy tip appears after deploy | DLP may have run before metadata finished arriving. Refresh the item before investigating |
