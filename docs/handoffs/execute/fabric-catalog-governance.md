# Skill handoff brief: fabric-catalog-governance

Last verified: 2026-09-11

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

Payload, in the `fabric` group:

- Repo: `skills/fabric/fabric-catalog-governance/SKILL.md`, with
  `references/endpoints.md` and `references/REFERENCE.md` beside it.
- Deployed on this machine: **nowhere**. The `fabric` group is pruned
  from `~/.claude/skills` by design, so the new skill enters no session
  here and no linker run changes that.
- Deployed to a client repo: by group. Both routes pick up a new skill
  in the group with no change, and `copy-copilot.ps1` records it in the
  destination's `.managed-skills.json` itself.

```powershell
./scripts/link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups fabric
./scripts/copy-copilot.ps1 -CopilotDir <repo>/.github -SkillGroups fabric
```

## Scope

Audits and remediates the governance posture of a Fabric tenant through
the REST APIs — the same ground the OneLake catalog **Govern** tab
reports on, reached by API instead of the portal. That is domains and
subdomains, workspace-to-domain and workspace-to-capacity assignment,
domain roles, sensitivity-label coverage and bulk label changes, tags,
description and endorsement coverage, and item ownership. Every procedure
is split by **caller tier** — Fabric administrator (`/v1/admin/*` plus the
Power BI admin scanner API) versus data owner (the Core API, limited to
roles the caller already holds on specific workspaces, domains and
capacities) — because the tier decides which endpoints exist at all, not
just which succeed.

One skill with both halves, audit and remediation, decided with the user
2026-09-11. Audits never write. Every irreversible or broad write sits
behind a gate stated in the always-loaded body, and fixes that have no
write API are routed to the person who can act rather than improvised.

It stops at three neighbours: catalog **search** (the Explore tab —
`fab find`, `POST /v1/catalog/search`) stays with `fabric-cli` and
`fabric-rest-api`; **access** (workspace roles, item permissions,
OneLake security — the Secure tab) and the `sensitivityLabel` field
shape stay with `fabric-security`; REST mechanics (LRO polling,
pagination, 429 handling) stay with `fabric-rest-api`.

Inline, model-invocable, **not** path-scoped: governance work arrives as
API calls against a tenant, not as a file being read, so there is no
file for a glob to name.

## Sources drilled

Drilled 2026-09-11. Four subagents on Sonnet drilled one API family
each against the upstream design source, returning a verbatim Learn
quote for every claim marked confirmed or contradicted; the eight
load-bearing pages marked ◆ below were then re-fetched in the main
session and read firsthand. About 60 distinct pages in all.

- **Design source** — `microsoft/skills-for-fabric`,
  `skills/onelake-catalog-govern-cli/` at `65902bae` (v0.3.15): the
  dispatcher `SKILL.md` and all 16 reference files, read as claims to
  verify, never as instructions. At `f1802196` (v0.3.16, 2026-09-10) the
  `SKILL.md` blob and the `references/` tree SHA are identical; that
  release added only a 374-byte `apm.yml`.
- **Concepts** — Learn `fabric/governance/`: ◆`onelake-catalog-govern`
  (the three insight areas and their names; admin insights from Admin
  Monitoring Storage refreshing daily, data-owner insights on every open;
  data owner means items you *own*; blind spots — subitems, cross-tenant
  and guests, Private Link, third-party workload items),
  `onelake-catalog-overview`, `domains` (domain admin vs contributor
  powers; subdomains have no admins of their own; domain assignment does
  not affect access), `endorsement-overview` and
  `admin/endorsement-certification-enable` (who can promote, certify,
  master-data; certifiers are security groups only; the delegation
  checkbox overrides every tenant-level certification setting),
  `domain-default-sensitivity-label` (applies only on create or update of
  an unlabeled item; never overrides a manual label; not with deployment
  pipelines or Git), `tags-overview` and `tags-define` (10 per item and
  per workspace, 10,000 per tenant; several hours to appear; delete
  removes from every item; domain move keeps domain tags that cannot be
  re-applied), ◆`fundamentals/item-ownership-take-over` ("no API support
  for changing ownership of Fabric items"; not as a service principal;
  mirrored databases never), `secure-your-data`.
- **Admin read** — Learn `rest/api/fabric/admin/`: ◆`items/list-items`
  (Preview; 10,000 per page in a fixed type order; active items only;
  `creatorPrincipal` is "the item's owner"; no label, endorsement or
  domain field), `workspaces/list-workspaces`,
  `workspaces/list-workspace-access-details` (Preview),
  `domains/list-domains` (`?preview=false` required), `list-role-assignments`,
  `list-domain-workspaces`, `tenants/list-tenant-settings`,
  `list-domains-tenant-settings-overrides`; `articles/pagination`,
  `articles/throttling` (unified 200 calls per 60 s per identity; two
  distinct 429 causes); `fabric/admin/enable-service-principal-admin-apis`
  (two separate switches, read-only and update). Power BI admin:
  `workspace-info-post-workspace-info`, `-get-scan-result`,
  `-get-modified-workspaces`, `get-activity-events`,
  `get-capacities-as-admin` — each with its own limit.
- **Admin write** — Learn `rest/api/fabric/admin/`: ◆`labels/bulk-set-labels`
  (path is `/v1/admin/items/bulkSetLabels`; user only; 25 requests per
  hour, 2,000 items per request; label must be in the caller's label
  policy; per-item status; also labels autogenerated items without
  returning their IDs; `assignmentMethod` defaults to `Standard`,
  defined as automated), `labels/bulk-remove-labels`,
  ◆`domains/delete-domain` (200; only `DomainNotFound` and `UnknownError`;
  nothing on subdomains or workspaces), `create-domain`, `update-domain`,
  ◆`assign-domain-workspaces-by-ids` (overrides existing assignments
  unless a tenant setting blocks it; 200; 10 per minute),
  `-by-capacities` and `-by-principals` (202, LRO), `unassign-*`,
  `role-assignments-bulk-assign` / `-unassign`,
  `sync-role-assignments-to-subdomains`, `tags/bulk-create-tags`,
  `tenants/update-tenant-setting`; ◆`fabric/admin/service-admin-portal-domain-management-settings`
  (the override setting is on by default and the domain REST APIs
  respect it); `purview/dlp-powerbi-get-started` (DLP policies are
  defined in the Purview portal).
- **Data-owner tier** — Learn `rest/api/fabric/core/`:
  `workspaces/list-workspaces` (`roles` filter; `domainId` in the
  schema), ◆`workspaces/assign-to-domain` (domain contributor or admin
  **and** workspace admin; 200; error codes name the missing side),
  `unassign-from-domain` and `unassign-from-capacity` (workspace admin
  only), `assign-to-capacity` (202), `items/update-item` (only
  `displayName` and `description`), `tags/apply-tags` /
  `unapply-tags` (contributor; 25 per minute), `domains/list-domains` and
  `get-domain` (four fields, no `defaultLabelId`),
  `items/associate-identity(beta)` plus
  `articles/item-management/associate-item-identity`,
  `catalog/search` (Preview; excludes dashboards and dataflows),
  `job-scheduler/list-item-job-instances` (100 recent completed per
  item), `capacities/list-capacities`; Power BI
  `datasets/get-refresh-history-in-group` (needs Write on the dataset).
- **Fabric CLI docs** — `microsoft/fabric-cli` `docs/commands/` at
  `b7af89ba`, read as raw markdown fragments through github-mcp code
  search, not as whole files: every
  `fab` verb on `.domains` (`ls`, `get`, `mkdir`, `rm`, `set`, `assign`,
  `unassign`) and every `fab label` command "requires tenant-level Fabric
  Administrator privileges"; `fab label` reads label names from a local
  JSON file set with `config set local_definition_labels`.

Not drilled, and the draft must not describe any of it:

- **Any live tenant.** Every claim is documentation-derived as of
  2026-09-11. Nothing was run against Fabric from this machine.
- **Which tenant settings gate which scanner metadata.** The scan result
  schema carries labels and endorsement; the settings that populate them
  were not established. The draft names the scanner as the source and
  stops there.
- **The Power BI take-over APIs** for semantic models, reports and
  dataflows. Learn says those mechanisms exist and remain; the draft may
  say so and point, not describe.
- **The DLP read side.** Only the Govern tab's report was seen to show
  DLP evaluation; no API for it was drilled.
- **Capacity utilization.** No per-capacity CU endpoint was found; the
  draft says so, dated, rather than claiming none exists.
- **Response schemas** of admin List Domain Workspaces and List Tags, and
  the tag Update and Delete REST pages (delete behaviour came from
  `tags-define`). The master-data enablement page.
- **Label-name resolution through Graph** — `fabric-security` owns it.
- **The underlying API and identity support of `fab label`.**
- **Upstream claims marked live-verified that Learn does not state** —
  excluded, not softened: `creatorPrincipal.type` always reading `User`;
  `assignToDomain` rejecting `domainId: null` with 400; a 24-hour catalog
  search index latency; an item type named "Homeone"; a preview warning
  on the `CertifyDatasets` setting; and an override that is "silently
  skipped while reporting success" when the tenant setting is off —
  Learn says only that reassignment is then not allowed.
- **Three open questions the docs leave open:** whether the override
  setting governs Core `assignToDomain` for a domain *contributor* (Learn
  names only tenant and domain admins); whether a label bulk-set with the
  default `assignmentMethod: Standard` counts as "automatically applied"
  in the domain-default-label override table (an inference from two
  pages, kept out of the draft); and whether Associate Identity answers
  200 or 202 (its reference page lists both).

## Frontmatter

```yaml
---
name: fabric-catalog-governance  # repo linter requires it; max 64 chars; lowercase/digits/hyphens; no "anthropic"/"claude"
description: "<verbatim from Description char count below>"  # gated at 1,024, the Agent Skills spec cap
# model: inherit  # ALWAYS PRESENT, ALWAYS COMMENTED — an active model: key of any value blocks Copilot slash invocation and fails lint-frontmatter.py
# effort: max  # ALWAYS PRESENT, as a commented-out placeholder — platform skills inherit the session level
disable-model-invocation: false  # ALWAYS PRESENT; repo policy: false everywhere
---
```

No `paths:` — see Scope. No `when_to_use`: this skill is unconditional,
so its description is in the listing of every session the `fabric` group
reaches, and the listing budget is the binding constraint rather than
the per-field cap. No `allowed-tools`: it would pre-approve only, and a
governance skill has no business pre-approving tenant writes.

## Description char count

- `description`: 871 / 1,024
- `when_to_use`: N/A — not set

Measured, not estimated, from the single-line form YAML will hold. A
first draft naming the Govern tab's three areas in full measured 978 and
was cut; the area names moved to the body. Re-count after drafting per
checklist item 2.

Draft `description`:

> Audit and remediate Microsoft Fabric governance posture through the
> REST APIs — what the OneLake catalog Govern tab reports, done by API.
> Covers domains and subdomains, workspace-to-domain and
> workspace-to-capacity assignment, domain roles, sensitivity-label
> coverage and bulkSetLabels, tags, description and endorsement
> coverage, and item ownership, split by caller tier: Fabric
> administrator (/v1/admin/*, scanner API) versus data owner (Core API
> plus workspace, domain or capacity roles). Use when asked to audit
> governance, find unlabeled, undescribed or unendorsed items or
> workspaces with no domain, bulk-assign workspaces to a domain, change
> labels in bulk, or say who can fix a finding. Gates every irreversible
> write and names the fixes that have no API. For catalog search use
> fabric-cli (fab find); for workspace roles and OneLake security use
> fabric-security.

Both disambiguation targets are unconditional, so the name pointers are
reachable wherever this skill is listed.

## Body structure outline

1. **What this owns, and what it hands off.** The Govern tab's three
   areas by Learn's own names — *Manage your data estate*; *Protect,
   secure & comply*; *Discover, trust, and reuse* — done by API. The three
   neighbours from Scope, by name. Output is findings; no write without a
   separate ask.
2. **Establish the tier before anything else.** Tier is the API surface
   the caller can reach, not the job title: a domain, capacity or
   workspace admin who is not a Fabric administrator is a data owner. A
   403 on `/v1/admin/*` is the answer — report it and route; never go
   around it through another surface. Service principals: admin APIs
   accept them only behind two separate tenant switches, and bulk label
   writes reject them outright. **The domain-admin gap:** Core lists
   domains but no non-admin endpoint lists a domain's workspaces, so "my
   whole domain" has no API for a domain admin — say so first. **`fab`
   caveat:** its domain verbs and all `fab label` commands are
   tenant-admin only; a data owner reaches Core `assignToDomain` through
   `fab api`.
3. **Audit before remediate.** Same tier, audit first; an audit asked to
   write switches explicitly and says so.
4. **What to measure, by area and tier.** A compact table: check →
   admin source → data-owner source → blind spot. The load-bearing row:
   admin List Items has **no label, endorsement or domain field**, so its
   silence is not "unlabeled" — labels come from the scanner or from
   Core items' `sensitivityLabel`. The full endpoint matrix goes to
   `references/endpoints.md`.
5. **Reporting conventions.** State the denominator (active items only;
   My workspaces excluded from bulk domain assignment; data owner = items
   owned versus workspaces administered — different sets), prove
   pagination completeness (admin List Items pages in a fixed type order,
   so a truncated walk loses Power BI types first), date the freshness
   (API reads are live; admin Govern-tab insights lag up to a day), and
   flag Preview APIs. Per finding: evidence, consequence, action, who can
   act.
6. **Remediation gates.** One table, kept in the body so the gate fires
   before the write: delete domain; bulk domain assignment (override on
   by default); single-workspace domain assignment; domain role removal;
   tag delete; bulk labels (user only, 25/hour, 2,000 items, per-item
   status, autogenerated items); tenant-setting writes; capacity
   assignment (202, region rule); item identity (beta, caller only — not
   ownership); domain create/update (`?preview=false`, name ≤ 40).
7. **No write API — route to a person.** Endorsement, DLP policies,
   general item ownership, and a domain admin's default label (portal
   only). Produce who can act: the owner from `creatorPrincipal`, the
   certifier security groups, the Purview side.
8. **Constraints and false negatives.** Refresh history needs Write, so
   a Viewer's 403 is not "never refreshed"; job history caps at 100 per
   item; tags take hours to show; scanner and activity-event windows;
   per-endpoint throttles on top of the unified quota; documentation-
   derived, not exercised.

## Changes from source proposal

The source proposal is upstream's `onelake-catalog-govern-cli` as brief
07 of the 2026-09-10 `skills-for-fabric` audit quoted it, taken as
design source. Brief 07's execution log records the user choosing to
**author** rather than vendor, 2026-09-11. No upstream text is copied;
every claim was re-drilled. Departures:

- **Name** `fabric-catalog-governance`, chosen with the user 2026-09-11 —
  the house `fabric-` prefix, the job, and the surface that bounds it,
  leaving Purview, audit-log and tenant-settings names free for skills
  that do not exist yet.
- **Area names are Learn's**, not upstream's "health / protect / trust",
  so the vocabulary matches the portal a user is looking at.
- **Four mode references become two tiers in one body** plus one
  endpoint reference. Upstream's reason for keeping the gates in the
  always-loaded body — a gate buried in a large reference is read and
  skipped — is adopted unchanged.
- **The `x-ms-fabric-skill` telemetry header is dropped.** It is
  upstream's own telemetry, marked mandatory there; a locally authored
  skill has no business sending it.
- **Corrections from the drill:** the bulk-assignment gate names the
  override tenant setting and its default; the delete-domain gate does
  not claim what happens to workspaces, because Learn does not say;
  "item identity" is not ownership, and ownership change has no API; the
  admin capacities response has no `users[]`; Core List Workspaces
  already carries `domainId`, so no per-workspace Get is needed; the Core
  domain object has no `defaultLabelId` (the admin one does).
- **Additions upstream lacks:** Core unassign-from-domain and
  unassign-from-capacity need workspace admin only; `fab`'s domain and
  label verbs are tenant-admin only; Preview status on admin List Items,
  List Workspace Access Details and Catalog Search; per-endpoint limits
  and the unified quota; bulk labels' per-item status and autogenerated
  items; tag propagation lag and the domain-move tag side effect; refresh
  history needing Write; Sync Role Assignments To Subdomains.

## Tag

`publishable` — platform behavior with no client-specific logic, and no
client evidence was used.

## Portability caveats

Nothing Claude Code-only is relied on: no `context: fork`, no hooks, no
`shell: powershell`, no `allowed-tools`, no `when_to_use`. With no
`paths:` key it is unconditional in both harnesses, so its Copilot
behavior matches its Claude Code behavior. `effort` is carried commented,
and `model:` stays commented in the source because `copy-copilot.ps1`
applies no frontmatter transformation.

## Cross-reference dependencies

- **`fabric-security`** — already converted. Owns access and the
  `sensitivityLabel` field, including resolving the GUID through Graph.
  *Pending edit, not this run:* line 95 gives the bulk label path as
  `/v1/admin/labels/bulkSetLabels`; Learn's interface is
  `/v1/admin/items/bulkSetLabels`.
- **`fabric-rest-api`** — already converted. Owns LRO, pagination, 429
  handling and catalog search. *Pending edits:* line 40 carries the same
  wrong path; line 192's "Admin APIs — 200 req/hour" is a per-endpoint
  figure, not a blanket one — List Domains and tenant settings are 25 per
  minute, bulk labels 25 per hour.
- **`fabric-cli`** — already converted. Owns `fab` syntax and `fab find`.
  *Pending edit:* the Assignment and Labels tables (lines 88, 97–99)
  omit that the domain and label verbs require tenant-level Fabric
  Administrator, per the fab docs at `b7af89ba`.
- **`fabric-auth`** — already converted; token audiences.
- **`drift-audit` `references/sources.md`** — *pending edit.* Add
  `onelake-catalog-govern-cli` → `fabric-catalog-governance` to the
  counterpart table when this skill lands, or the next audit proposes it
  again. The same edit must restate the step-5 known-answer assertion,
  which expects clause 1 to *surface* `onelake-catalog-govern-cli` — true
  only while no counterpart exists.
- **`docs/handoffs/execute/README.md`** — the audit-follow-up row for
  skills-for-fabric brief 07 stays until all four accepted candidates
  are authored; this brief satisfies brief 07's verification for one of
  them.
- **`microsoft/skills-for-fabric` `onelake-catalog-govern-cli`** —
  external; design source, not a dependency.

The three payload edits above were `/learn` work and **landed
2026-09-12**, together with the `drift-audit` counterpart row; the
bullets stay as the record of what the authoring run found.
`author-skill` edits no other skill.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**Fresh-session test queries** — what `/test-skill` reads back. Run
each against a `--safe-mode` baseline; the discriminating assertions are
the ones a base model is likely to get wrong.

Should fire, with the assertion that makes it pass:

1. "Audit our Fabric tenant's governance — which workspaces have no
   domain, and how many items are unlabeled?" — establishes the tier
   first; does **not** count labels from admin List Items.
2. "I'm a domain admin but not a Fabric admin. Can I get a governance
   report for my whole domain?" — states that no non-admin endpoint lists
   a domain's workspaces.
3. "Assign these 40 workspaces to the Finance domain." — reads each
   current `domainId` and names the override tenant setting before
   writing.
4. "Apply the Confidential label to every lakehouse in these workspaces
   with our service principal." — refuses the service principal; uses
   `/v1/admin/items/bulkSetLabels`; reads per-item status.
5. "Certify these semantic models through the API." — no endorsement
   write API; routes to the certifier security groups.
6. "Delete the Marketing domain." — enumerates subdomains and assigned
   workspaces before any delete.
7. "Why does the Govern tab show different numbers from my API audit?" —
   the daily Admin Monitoring refresh, and data owner meaning items
   owned.

Should not fire — a neighbour owns each:

- "Find the Sales Revenue lakehouse across all our workspaces." →
  `fabric-cli` (`fab find`) or `fabric-rest-api`.
- "Give this group Viewer on the workspace and a OneLake security role
  on the lakehouse." → `fabric-security`.

**The spot-check caught one of the subagents' own errors.** A row marked
CONFIRMED — the override being "silently skipped while reporting
success" — rested on a quote that only says reassignment is not allowed.
Re-reading every load-bearing quote firsthand is what stopped it; keep
doing that when drilling is delegated.

**`?preview=false` outlives its own deprecation date.** Create Domain
says its non-preview form "is a release version of a preview version due
to be deprecated on March 31, 2026", and the parameter is still
documented as required on 2026-09-11. A later `/drift-audit` should
watch for it being dropped.

**The listing cost is real.** Unconditional, so this description is in
every session the `fabric` group reaches; that is the reason for 871
characters and no `when_to_use`, and the reason not to grow either.

## Confidence

- **Structure: H.** Template followed; the shape is the house
  procedure-skill pattern of `fabric-semantic-model-audit`, and the tier
  split falls out of the API surface rather than being imposed on it.
- **Field specs: M.** Frontmatter mirrors the `fabric-*` family and is
  linted, but was not re-verified at source — checklist item 1.
- **Body content: H for endpoint facts** — permissions, paths, limits and
  failure codes each rest on a fetched page, eight of them re-read
  firsthand. **M for the reporting conventions and gate wording**, which
  are procedure judgments adapted from upstream rather than documented
  contract. Nothing is exercised against a tenant, and the draft must
  say so.
