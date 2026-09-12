---
name: fabric-catalog-governance
description: "Audit and remediate Microsoft Fabric governance posture through the REST APIs — what the OneLake catalog Govern tab reports, done by API. Covers domains and subdomains, workspace-to-domain and workspace-to-capacity assignment, domain roles, sensitivity-label coverage and bulkSetLabels, tags, description and endorsement coverage, and item ownership, split by caller tier: Fabric administrator (/v1/admin/*, scanner API) versus data owner (Core API plus workspace, domain or capacity roles). Use when asked to audit governance, find unlabeled, undescribed or unendorsed items or workspaces with no domain, bulk-assign workspaces to a domain, change labels in bulk, or say who can fix a finding. Gates every irreversible write and names the fixes that have no API. For catalog search use fabric-cli (fab find); for workspace roles and OneLake security use fabric-security."
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: max   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Governing the Fabric estate

The OneLake catalog's **Govern** tab reports a tenant's governance
posture across three areas — *Manage your data estate*, *Protect, secure
& comply*, and *Discover, trust, and reuse*. This skill does the same
work through the REST APIs, where it can be counted, scheduled and
fixed in bulk.

The output is **findings**, not a rewrite. Do not write to a tenant
unless asked separately, and then only through §6.

Three neighbours own the adjacent ground:

- **Catalog search** — finding an item across workspaces — is the
  Explore tab. That is `fab find` (`fabric-cli`) and
  `POST /v1/catalog/search` (`fabric-rest-api`).
- **Access** — workspace roles, item permissions, OneLake security, and
  the shape of the `sensitivityLabel` field including resolving its GUID
  through Graph — is `fabric-security`. This skill measures label
  *coverage*; that one explains what a label does.
- **REST mechanics** — long-running operations, `continuationToken`
  pagination, `Retry-After` and 429 handling — is `fabric-rest-api`.

Everything below was drilled from Microsoft Learn on 2026-09-11 and
**none of it has been exercised against a tenant from this machine**.
Treat it as first-party documentation, not as verified practice.

## 1. Establish the caller's tier before anything else

**Tier is the API surface the caller can reach, not their job title.**
Getting this wrong wastes a whole audit: the endpoints that answer
"across the tenant" refuse everyone who is not a Fabric administrator,
and no amount of retrying changes that.

| Tier | Surface | Scope |
| --- | --- | --- |
| **Fabric administrator** | `/v1/admin/*`, Power BI admin (scanner, activity events) | The whole tenant |
| **Data owner** | Core API (`/v1/workspaces`, `/v1/items`, `/v1/domains`), Power BI per-item | Only objects the caller holds a role on |

A **domain admin, capacity admin or workspace admin who is not also a
Fabric administrator is a data owner here.** The admin endpoints say so
in as many words — "The caller must be a Fabric administrator" — and
answer `InsufficientPrivileges`, "The caller doesn't have permissions to
call the API", to everyone else.

**A 403 is the answer, not an obstacle.** Report the tier boundary and
route the finding to someone who can act (§7). Never go around it by
trying the same read through another surface.

### The domain-admin gap — say this up front

A domain admin who is not a Fabric administrator **has no API that
returns their domain's posture.** `GET /v1/admin/domains/{id}/workspaces`
requires the Fabric administrator role, and the Core API has no
equivalent: `GET /v1/domains` lists domains with only `id`,
`displayName`, `description` and `parentDomainId` — no membership, and
not even the `defaultLabelId` the admin version carries.

So a data-owner audit covers **workspaces the caller can reach**, never
"my whole domain". State that limitation before running it, rather than
producing a number that quietly means something narrower than asked.

### Service principals are a separate gate

- Admin reads and most admin writes accept a service principal or
  managed identity, but only once a tenant admin enables it. There are
  **two independent switches** — one for read-only admin APIs, one for
  the admin APIs used for updates — each limited to a named security
  group.
- **Bulk label writes reject them outright.** `bulkSetLabels` and
  `bulkRemoveLabels` support `User` only; a service principal cannot set
  a sensitivity label at all (§6).
- Item ownership takeover likewise "doesn't cover ownership takeover as
  a service principal".

### `fab` reaches the admin tier, not the data-owner one

The Fabric CLI's domain verbs — `ls`, `get`, `mkdir`, `rm`, `set`,
`assign`, `unassign` against `.domains` — and **every** `fab label`
command require tenant-level Fabric Administrator privileges, per the
CLI's own docs. `fab label` also reads label names from a local JSON
file registered with `config set local_definition_labels`.

A data owner assigning their own workspace to a domain therefore cannot
use `fab assign .domains/...`, even though the Core API would allow it.
Use the REST passthrough instead:

```bash
fab api -X post "workspaces/$WS_ID/assignToDomain" -i '{"domainId":"<id>"}'
```

See `fabric-cli` for `fab` syntax and `fabric-auth` for token audiences.

## 2. Audit before you remediate

Establish the current state first, in the caller's own tier. An audit
mode does not write, even when asked mid-run: if the answer to a finding
is a write, say so, switch deliberately, and apply §6's gate. Do not
improvise a write inside an audit.

## 3. What to measure, and where it actually comes from

The trap in this whole skill, stated once:

**`GET /v1/admin/items` carries no sensitivity label, no endorsement and
no domain.** Its item object is `id`, `type`, `name`, `description`,
`state`, `lastUpdatedDate`, `workspaceId`, `capacityId`,
`creatorPrincipal`, `defaultIdentity`, `tags` and `folderId` — nothing
else. An "unlabeled items" count taken from it is not a finding; it is
the API's silence. Labels and endorsement come from the **Power BI
scanner API**, or per item from Core `sensitivityLabel`.

| Area | Check | Fabric admin source | Data owner source |
| --- | --- | --- | --- |
| Estate | Workspaces with no domain | Admin List Workspaces — `domainId` omitted when unassigned | Core List Workspaces (`?roles=Admin`) — `domainId` is in the schema |
| Estate | Domains without admins; contributor scope | Admin List Domains + role assignments | none — see the gap in §1 |
| Estate | Capacity assignment, state, region | Admin capacities; `capacityId` per workspace | Core List Capacities — only capacities the caller administers or contributes to |
| Protect | Unlabeled items | Scanner `sensitivityLabel.labelId` (GUID only) | Core items' `sensitivityLabel` (see `fabric-security`) |
| Protect | DLP coverage | Govern tab report only — no API drilled | none |
| Trust | Missing descriptions | Admin List Items `description` | Core List Items |
| Trust | Endorsement coverage | Scanner `endorsementDetails` — absent on dashboards, which cannot be endorsed | not drilled |
| Trust | Tag coverage | Admin List Items `tags` | Core List Tags + per-item tags |
| Trust | Staleness | `lastUpdatedDate`; activity events | Job instances; refresh history |
| Trust | Ownership | `creatorPrincipal`, documented as "the item's owner" | item-level only |

Per-endpoint permissions, scopes, limits and response fields are in
[references/endpoints.md](references/endpoints.md). Read it before
writing any call.

## 4. Reporting conventions

A governance statistic with no denominator is not evidence. Every
number this skill reports carries four things.

**The denominator, and what it excludes.** Admin List Items returns
**active items only**. Bulk domain assignment "excludes *My
workspaces*", so personal workspaces are outside any domain finding.
The Govern tab excludes subitems such as tables, cross-tenant and guest
scenarios, and third-party workload items from its charts, and is
unavailable when Private Link is on.

**Pagination completeness.** Follow `continuationToken` until it is
absent or null. Admin List Items returns at most 10,000 records per page
**in a fixed type order** — Fabric items, then Datamarts, Reports,
Dashboards, SemanticModels, Apps, Dataflows — so a walk that stops early
does not lose a random sample, it loses the Power BI types at the end of
that order. Say how many pages were read.

**Freshness, and which clock.** API reads are live. The Govern tab's
admin insights come from Admin Monitoring Storage, which "refreshes
automatically every day", so "there could be gaps between the data
reflected and the actual state". A data owner's insights refresh every
time the tab opens. An API count that disagrees with the portal by less
than a day is the expected behaviour, not a bug.

**Which population.** On the Govern tab a *data owner* means **items you
own**; a data-owner API audit is usually scoped by **workspace role**.
Those are different sets. Name the one you used.

Flag **Preview** surfaces in the report: admin List Items, admin List
Workspace Access Details, and Catalog Search are each documented as
Preview and "not recommended for production use".

Per finding: the evidence (endpoint and count), the consequence, the
recommended action, **which tier can perform it**, and the effort.

## 5. Throttling shapes the plan

Limits are per endpoint and differ by an order of magnitude, so a sweep
has to be planned rather than fired:

| Endpoint | Limit |
| --- | --- |
| Admin List Items / List Workspaces / activity events / capacities | 200 per hour |
| Admin List Domains, tenant settings, domain CRUD, role assignments, tag apply | 25 per minute |
| Domain workspace assignment (by IDs, capacities, principals) | 10 per minute |
| `bulkSetLabels` / `bulkRemoveLabels` | 25 per hour, 2,000 items each |
| Scanner `postWorkspaceInfo` | 500 per hour, 16 concurrent, 1–100 workspaces per call |

On top of each, a **unified quota of 200 calls per 60-second window per
identity**; spend it all at the start of a window and nothing more
succeeds until the next one. A 429 has two distinct causes —
`RequestBlocked` (rate) and `CapacityLimitExceeded` (tenant capacity
overload) — which need different responses; honour `Retry-After` either
way (`fabric-rest-api`).

Scanner results **expire after 24 hours**, and `getModifiedWorkspaces`
accepts a `modifiedSince` between 30 minutes and 30 days ago. Neither
window is the activity-event one, which is a single UTC day per call
within the last 28 days.

## 6. Gates before irreversible writes

These sit here, in the always-loaded body, because a gate buried in a
reference file gets read and skipped. **Every row's gate must pass
before the call.**

| Write | Tier | Gate that fires first |
| --- | --- | --- |
| **Delete a domain** | admin | List subdomains (`parentDomainId`) and the assigned workspaces of the domain **and each subdomain**; name them and get explicit confirmation. The API documents no cascade block — only `DomainNotFound` and `UnknownError` — and Learn does not say what becomes of the workspaces. Do not tell the user they will simply be unassigned. |
| **Bulk-assign workspaces to a domain** | admin | Read every target's current `domainId` and present the reassignments before writing: assignment "will be overridden unless bulk reassignment is blocked by domain management tenant settings", and that setting is **enabled by default**. By-IDs is synchronous; by-capacities and by-principals are 202 + LRO. |
| **Assign or unassign one workspace** | data owner | A move is a reassignment: name the domain being left. Needs domain contributor **or** domain admin **and** workspace Admin; `InsufficientPermissionsToDomain` versus `InsufficientWorkspaceRole` tells you which is missing. Unassigning needs workspace Admin only. |
| **Remove a domain role assignment** | admin | Confirm the domain is not left without an admin, and name the principal. `EntireTenant` can only ever be a Contributor. Syncing role assignments to subdomains works for Contributors only. |
| **Delete a tag** | admin | Count the items carrying it first — deletion "is removed from all items where it was previously applied", with no undo. |
| **Bulk sensitivity-label change** | admin | Dry-run the exact item list with before and after labels, then confirm. **User only — no service principal or managed identity.** 25 requests/hour, 2,000 items each; the label must be in the caller's (or the delegated user's) label policy. The response is **per item**, not all-or-nothing: read every status, and treat `InsufficientUsageRights` and `FailedToGetUsageRights` as protected-label refusals rather than transient errors. The label also lands on linked autogenerated items, whose IDs are not returned. |
| **Write a tenant setting** | admin | Read the current value and show it beside the proposed one — the blast radius is the tenant. Enabling domain-admin delegation for certification lets domain admins override *any* tenant-level certification setting, not only enable/disable as the checkbox implies. |
| **Assign a workspace to a capacity** | data owner | Needs workspace Admin plus capacity contributor or admin. Returns **202** — do not report success from the 202; poll to a terminal state. Non-Power BI Fabric items cannot migrate across regions, and the target must be a Fabric, Fabric trial or Power BI Premium capacity. |
| **Associate an item identity** (beta) | data owner | This is **not** an ownership change. It assigns the identity to the **caller** and nothing else, needs Write on the item *and all its children*, and stops at the first child failure with details in `errorInfo`. Learn lists only Lakehouse and Eventstream as supported. |
| **Create or update a domain** | admin | `?preview=false` is required on create and update. `displayName` is capped at 40 characters and `description` at 256; a duplicate name returns `EntityConflict`. Update accepts only `displayName`, `description` and `defaultLabelId`. |

`assignmentMethod` on a label write defaults to `Standard`, which Learn
defines as "set by an automated process"; `Priviledged` (Learn's
spelling) means manual. Choose it deliberately — the two are treated
differently by default-label policies.

## 7. When there is no write API, route it to a person

Do not promise a remediation that has no API, and do not invent one.
Produce a named route instead.

- **Endorsement** — promoted, certified, master data — has **no REST
  write**. `UpdateItemRequest` accepts only `displayName` and
  `description`. Anyone with write permission on an item can promote it
  in the portal; only users a Fabric admin has specified can certify,
  and that field "accepts security groups only. You can't enter named
  users". Certification and master data must be enabled tenant-wide
  first, and enablement can be delegated per domain. So the route is:
  the certifier security group for that domain.
- **DLP policies** are defined in the Microsoft Purview portal. Route to
  the Purview compliance owner.
- **Item ownership** — "Currently, there's no API support for changing
  ownership of Fabric items." Takeover is a portal action by someone
  with read and write permission, it cascades to child items and cannot
  be done on a child directly, and mirrored databases and mirrored
  catalogs cannot change ownership at all — a broken one must be
  recreated. Semantic models, reports, dataflows and warehouses keep
  their own separate mechanisms. Route to the item's `creatorPrincipal`,
  or to a workspace admin.
- **A domain's default sensitivity label** can be set by a domain admin
  only through the portal, behind the "Domain admins can set default
  sensitivity labels for their domains (preview)" tenant setting; the
  `defaultLabelId` write on the domain object needs a Fabric admin. And
  it is **not retroactive**: it applies when a new item is created and
  saved, or when an existing *unlabeled* item is updated and saved. It
  never overrides a manually applied label, and it does not work with
  deployment pipelines or Git integration. A default label therefore
  stops the backlog growing; it does not clear it.

## 8. Constraints and false negatives

- **Admin List Items' silence is not evidence** (§3). This is the most
  likely way this skill produces a confidently wrong number.
- **A sensitivity label comes back as a GUID only.** Resolve names
  separately — `fabric-security`.
- **Refresh history needs Write on the semantic model**, so a Viewer's
  403 means "cannot see", not "never refreshed". OneDrive refresh
  history is never returned. Shared capacity allows eight scheduled or
  API-triggered refreshes a day; manual portal refreshes don't count
  toward it.
- **Job history caps at 100 recently completed runs per item**, so
  "inactive" derived from it is bounded by that ceiling.
- **A newly applied tag takes hours to appear** in the icon and in
  search, so an immediate read-back that shows nothing is not a failed
  write. Tags cap at 10 per item and 10 per workspace, counted
  independently, and 10,000 per tenant. Moving a workspace to another
  domain keeps its domain-level tags applied, but they may not be
  re-appliable there once removed.
- **Catalog Search excludes dashboards and both dataflow generations**,
  and returns only `id`, `type`, `displayName`, `description`,
  `catalogEntryType` and `hierarchy.workspace` — no label, endorsement
  or refresh state. It cannot be the basis of a coverage statistic.
- **Domain assignment is not access.** Assigning a workspace to a domain
  "doesn't affect item visibility or accessibility"; access is workspace
  role plus item permissions. All tenant users can see all domains.
- **Nothing here was measured against a tenant** (2026-09-11). Where a
  behaviour matters and Learn is silent — what a deleted domain does to
  its workspaces, whether Associate Identity answers 200 or 202 — say
  it is undocumented rather than predicting it.
