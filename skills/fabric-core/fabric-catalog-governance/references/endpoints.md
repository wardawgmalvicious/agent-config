# Governance endpoints, by tier

Every row was drilled from Microsoft Learn on 2026-09-11 and **none was
called against a tenant**. Where Learn is silent, the row says so rather
than filling the gap.

Permissions wording is Learn's own. "Fabric administrator" means the
tenant role; a domain, capacity or workspace admin does **not** qualify
for any `/v1/admin/*` route.

## Fabric administrator tier — reads

| Operation | Method and path | Scope | SPN / MI | Limits and shape |
| --- | --- | --- | --- | --- |
| List Items | `GET /v1/admin/items` | `Tenant.Read.All` or `Tenant.ReadWrite.All` | Yes | **Preview.** 200/hour. 10,000 records per page, ordered Fabric items → Datamarts → Reports → Dashboards → SemanticModels → Apps → Dataflows. `state` supports `active` only. Optional `workspaceId`, `capacityId`, `type`, `state` |
| List Workspaces | `GET /v1/admin/workspaces` | `Tenant.Read.All` | Yes | 200/hour, 10,000 per page. Filters `type`, `state`. Returns `capacityId`; `domainId` present only when assigned |
| List Workspace Access Details | `GET /v1/admin/workspaces/{id}/users` | `Tenant.Read.All` | Yes | **Preview** |
| List Domains | `GET /v1/admin/domains?preview=false` | `Tenant.Read.All` | Yes | 25/minute. `preview=false` is required. Domain object: `id`, `displayName`, `description`, `parentDomainId`, `defaultLabelId` — unset fields are omitted, not null |
| List Domain Workspaces | `GET /v1/admin/domains/{id}/workspaces` | `Tenant.Read.All` | Yes | Response schema not drilled. **The only way to list a domain's workspaces** — there is no Core equivalent |
| List Role Assignments | `GET /v1/admin/domains/{id}/roleAssignments` | `Tenant.Read.All` | Yes | Role is `Admin` or `Contributor`; principal may be `User`, `Group`, `ServicePrincipal`, `ServicePrincipalProfile` or `EntireTenant` |
| List Tenant Settings | `GET /v1/admin/tenantsettings` | `Tenant.Read.All` | Yes | 25/minute |
| Delegated setting overrides | `GET /v1/admin/domains/delegatedTenantSettingOverrides` | `Tenant.Read.All` | Yes | Empty `value[]` when nothing is delegated |

### Power BI admin reads

| Operation | Path | Limits and shape |
| --- | --- | --- |
| Get Modified Workspaces | `GET /v1.0/myorg/admin/workspaces/modified` | 30/hour. `modifiedSince` must be between 30 minutes and 30 days ago |
| Post Workspace Info (scan) | `POST /v1.0/myorg/admin/workspaces/getInfo` | 500/hour, 16 concurrent, **1–100 workspace IDs per call** |
| Get Scan Result | `GET /v1.0/myorg/admin/workspaces/scanResult/{id}` | 500/hour; **results expire after 24 hours**. Carries `sensitivityLabel.labelId` (GUID only) and `endorsementDetails` on reports, semantic models, dataflows and datamarts — dashboards carry a label but no endorsement |
| Get Activity Events | `GET /v1.0/myorg/admin/activityevents` | 200/hour. `StartDateTime` and `EndDateTime` must be in the **same UTC day**, within the last 28 days. Admin-only — a data owner gets 403 |
| Get Capacities As Admin | `GET /v1.0/myorg/admin/capacities` | 200/hour. Fields: `admins`, `capacityUserAccessRight`, `displayName`, `id`, `region`, `sku`, `state`, `tenantKey`, `tenantKeyId`. **No `users` field** — upstream claims one; Learn documents none |

**No per-capacity utilization or CU endpoint was found** on 2026-09-11,
across Get Capacities As Admin and the throttling article. That is a
failed search, not a proof of absence — say so that way.

Which tenant settings populate which scanner metadata was **not
drilled**. Do not name one.

## Fabric administrator tier — writes

All require the Fabric administrator role and `Tenant.ReadWrite.All`.

| Operation | Method and path | SPN / MI | Limits, behaviour, failure |
| --- | --- | --- | --- |
| Create Domain | `POST /v1/admin/domains?preview=false` | Yes | 25/min. `displayName` ≤ 40 chars, `description` ≤ 256. `EntityConflict` if the name exists tenant-wide, `EntityNotFound` for a bad `parentDomainId` |
| Update Domain | `PATCH /v1/admin/domains/{id}?preview=false` | Yes | 25/min. Body accepts only `displayName`, `description`, `defaultLabelId` — no branding, image or default-domain fields |
| Delete Domain | `DELETE /v1/admin/domains/{id}` | Yes | 25/min. No `preview` parameter. Errors are only `DomainNotFound` and `UnknownError`: **no cascade block, and Learn does not document what happens to subdomains or assigned workspaces** |
| Assign workspaces by IDs | `POST /v1/admin/domains/{id}/assignWorkspaces` | Yes | **10/min.** Synchronous 200. Body `workspacesIds`. "Preexisting domain assignments will be overridden unless bulk reassignment is blocked by domain management tenant settings" |
| Assign by capacities / by principals | `POST .../assignWorkspacesByCapacities` / `...ByPrincipals` | Yes | 10/min. **202 + long-running operation** — poll `Location`, never report the 202 as done |
| Unassign by IDs / all | `POST .../unassignWorkspaces` / `.../unassignAllWorkspaces` | Yes | 25/min |
| Role assignments bulk assign / unassign | `POST .../roleAssignments/bulkAssign` / `bulkUnassign` | Yes | 25/min. `type` is plural — `"Admins"` / `"Contributors"`. Empty success body. `EntireTenant` as Admin fails with `UnsupportedPrincipalTypeForDomainAdminAssignment`; an existing assignment returns `PrincipalWithDomainRoleAssignmentAlreadyExists` rather than erroring the batch |
| Sync roles to subdomains | `POST .../roleAssignments/syncToSubdomains` | Yes | Body carries a `role` of `Admin` or `Contributor`. `SyncingAdminsToSubdomainsIsNotSupported` — only Contributor sync works, consistent with subdomains having no admins of their own |
| Bulk create tags | `POST /v1/admin/tags/bulkCreateTags` | Yes | Takes a `scope` of `Tenant` **or** `Domain` (with `domainId`) — the same endpoint creates domain-scoped tags |
| Delete a tag | Admin tags delete | Yes | Deleting "is removed from all items where it was previously applied". No undo. Exact REST page not drilled; behaviour is from the tags concept doc |
| **Bulk Set Labels** | `POST /v1/admin/items/bulkSetLabels` | **No** | **25/hour, 2,000 items per request.** User only. The label must be in the caller's — or `delegatedPrincipal`'s — label policy. `delegatedPrincipal` accepts `User` only. `assignmentMethod`: `Standard` (automated, the default) or `Priviledged` (manual, Learn's spelling). Also labels linked autogenerated items of Lakehouse, Warehouse, Datamart, SQLDatabase and MirroredDatabase, **whose IDs are not returned** |
| Bulk Remove Labels | `POST /v1/admin/items/bulkRemoveLabels` | **No** | Same limits and permissions |
| Update Tenant Setting | `POST /v1/admin/tenants/...` | Yes | 25/min |

**The label response is per item, not all-or-nothing.** Every entry in
`itemsChangeLabelStatus` carries its own status: `Succeeded`, `Failed`,
`NotFound`, `InsufficientUsageRights` (the item has a protected label and
rights are insufficient) or `FailedToGetUsageRights` (rights could not be
verified). A 200 on the request says nothing about any item.

**Note the path.** It is `/v1/admin/items/bulkSetLabels`, under *items*,
even though the Learn reference files it under Labels. `fabric-rest-api`
and `fabric-security` both carried `/v1/admin/labels/…` until
2026-09-12; a vendored copy of either predating that date still has it
wrong.

Create Domain's non-preview form is documented as "a release version of
a preview version due to be deprecated on March 31, 2026", yet
`preview=false` was still required on 2026-09-11. Expect this to change
and re-check.

## Data-owner tier — Core API

Scoped to objects the caller already holds a role on. Results are
trimmed to what the caller can access, so an empty result is not a
tenant-wide statement.

| Operation | Method and path | Permissions | Notes |
| --- | --- | --- | --- |
| List Workspaces | `GET /v1/workspaces?roles=Admin,Member,Contributor` | caller's roles | Comma-separated `roles`; all workspaces if omitted. `domainId` **is** in the schema — no per-workspace `Get` needed |
| List Domains | `GET /v1/domains` | any signed-in user | Only `id`, `displayName`, `description`, `parentDomainId`. No `defaultLabelId`, no membership |
| Assign To Domain | `POST /v1/workspaces/{id}/assignToDomain` | domain contributor **or** domain Admin, **and** workspace Admin. `Workspace.ReadWrite.All` | Synchronous 200. `InsufficientPermissionsToDomain` and `InsufficientWorkspaceRole` name which side is missing. Whether the override tenant setting also governs a *contributor* here is **not documented** |
| Unassign From Domain | `POST /v1/workspaces/{id}/unassignFromDomain` | **workspace Admin only** — no domain role at all | |
| Assign To Capacity | `POST /v1/workspaces/{id}/assignToCapacity` | capacity contributor or Admin, **and** workspace Admin | **202 Accepted** — poll. Non-Power BI Fabric items don't support cross-region migration; target must be Fabric, Fabric trial or Power BI Premium |
| Unassign From Capacity | `POST /v1/workspaces/{id}/unassignFromCapacity` | **workspace Admin only** | |
| Update Item | `PATCH /v1/workspaces/{ws}/items/{id}` | write on the item | Accepts **only** `displayName` and `description`; description ≤ 256 chars. This is why endorsement has no API |
| Apply / Unapply Tags | `POST .../items/{id}/applyTags` / `unapplyTags` | **contributor or higher** on the workspace | 25/min. Max 10 tags per item |
| List Capacities | `GET /v1/capacities` | — | "capacities the principal can access (either administrator or a contributor)" |
| List Item Job Instances | `GET .../items/{id}/jobs/instances` | `Item.Read.All` | **100 most recent completed** per item; unlimited for active |
| Catalog Search | `POST /v1/catalog/search` | caller's access | **Preview.** Excludes Dashboard and Dataflow Gen1/Gen2. Returns only `id`, `type`, `displayName`, `description`, `catalogEntryType`, `hierarchy.workspace` |
| Associate Identity | `POST .../items/{id}/identities/default/assign?beta=true` | Write on the item **and all child items** | **Beta.** Assigns to the `Caller` and nothing else. Stops at the first child failure, details in `errorInfo`. Learn lists only Lakehouse and Eventstream (the latter not when sourced from Azure or Fabric Events). Use the generic `/items/` path — the type-qualified form "may currently result in an error". Verify with `?include=defaultIdentity`. The reference lists both 200 and 202; which one it returns is **undocumented** |

### Power BI, per item

| Operation | Notes |
| --- | --- |
| Get Refresh History In Group | **Caller must have Write permission** on the semantic model. OneDrive refresh history is not returned |
| Refresh limits | Shared capacity allows eight scheduled or API-triggered refreshes per day; manual portal refreshes do not count toward it |
| Take over | Semantic models, reports and dataflows keep pre-existing ownership-change mechanisms; warehouses have their own. **Not drilled** — point at them, do not describe them |

## What has no write API at all

Confirmed on 2026-09-11:

- **Endorsement** — promoted, certified, master data. No REST field
  anywhere; `UpdateItemRequest` carries only `displayName` and
  `description`.
- **DLP policies** — "You define a DLP policy in the data loss
  prevention section of the Microsoft Purview portal."
- **Item ownership** — "Currently, there's no API support for changing
  ownership of Fabric items", and takeover does not work as a service
  principal. Mirrored Cosmos DB, SQL DB, SQL MI, Snowflake and mirrored
  databases don't support ownership change at all.
- **A tenant-admin item delete route** — none appears in any admin
  operations listing checked. Absence in the docs, not a tested 404.
