---
status: open
priority: 3
needs: []
blocked-by: []
written: 2026-10-17
---

# Skill handoff brief: azure-access

Last verified: 2026-10-17

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.
>
> Guidance: The frontmatter is this brief's whole queue state: `scripts/handoff-status.py` prints the queue from it, and pre-commit's `lint-briefs` fails a commit on a brief without it or with a placeholder left in. Pick `priority` — 1 now, 2 next, 3 later — list in `needs` what a session cannot supply alone (`user` for a decision), name any brief this waits on in `blocked-by`, and state none of it in the body.

## Artifact path

Payload, in the platform group `azure`, which this skill opens:

- Repo: `skills/azure/azure-access/SKILL.md`, with
  `references/roles.md`, `references/errors.md`,
  `references/credentials.md` and `references/LICENSE.upstream`.
- Deployed: into no session here. Like `windows`, the group stays out
  of the `-SkillGroups` default and reaches a repo through
  `link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups azure`:
  the client repo running a Container Apps worker, and a Fabric repo
  that uses service principals or Key Vault, beside `fabric-core`.

## Scope

Gives an Azure identity access to a resource, and finds why one is
refused with a 401 or 403. In order: pin the tenant and name the
caller, choose the identity, pick the role on its plane, check who can
grant it and what granting Contributor also grants, keep the two
meanings of `AZURE_CLIENT_ID` apart, triage the error, and audit
credential expiry. Inline, model-invocable, with no `paths:` glob: an
access failure arrives as terminal output or words, not as a file type,
and a glob would hide the skill in the only repos that link it, the
reasoning `msix-packaging` recorded for its own group.

## Sources drilled

Drilled on 2026-10-17. Three subagents read Learn by source family and
returned a verbatim quote per claim; every quote behind a permission, a
limit, a gate or a destructive command was then re-read firsthand
through `microsoft_docs_search`, and the CLI flags through local
`--help`.

- **Managed identities.** Learn's overview and best-practice pages:
  user-assigned "more efficient in a broader range of scenarios", and a
  system-assigned identity's role assignments "can't be created in
  advance", which fails a deploy whose author cannot assign roles; the
  token cache "per resource URI for around 24 hours" with no forced
  refresh, and the advice to grant the identity directly rather than
  through a group. The FAQ: several user-assigned identities on one
  resource need a client ID in the token request.
- **Workload identity federation.** Concepts: issuer, subject and
  audience match case-sensitively. The user-assigned trust page: no
  federated credential on a system-assigned identity, exactly one
  audience, `api://AzureADTokenExchange` recommended, at most 20 per
  identity, a wrong subject saves without error, parallel creates under
  one identity fail 409. Considerations: `AADSTS70021` while a new
  credential propagates, and retry. Flexible credentials: preview,
  GitHub, GitLab and Terraform Cloud only. Error text for
  `AADSTS700211`, `AADSTS700213`, `AADSTS70025`, `AADSTS700223` from
  Azure DevOps' workload identity troubleshooting, `AADSTS700213`'s
  case-sensitive wording from the breaking-changes page, and
  `AADSTS700024` from Microsoft.Identity.Web's certificateless page.
- **Azure RBAC.** Role definitions: `Actions` against `DataActions`.
  Built-in roles: Contributor's eleven `NotActions`, among them
  `Microsoft.Authorization/*/Write`, and no `DataActions`; Owner, User
  Access Administrator, Role Based Access Control Administrator; the
  Key Vault, Storage Table and Container Registry roles; Managed
  Identity Contributor holding the federated-credential write. The
  role-assignment quickstart and Key Vault's default-model page: who
  holds `roleAssignments/write`. Delegation with conditions, and an
  unconstrained delegate able to assign Owner. Troubleshooting: up to
  10 minutes, a `401` while a change propagates, hours for
  management-group data actions. PIM: an eligible role must be
  activated.
- **Key Vault.** The RBAC guide: a Contributor can grant itself data
  access through an access policy, and switching to RBAC "invalidates
  all access policies permissions". The default-model page: RBAC is the
  default only on create with API `2026-02-01` or later, `null` keeps
  access policies, older control-plane API versions retire on
  2027-02-27, CLI 2.90.0 or later. About secrets: `exp` is
  informational and a get still works after it. Event Grid's
  `Microsoft.KeyVault.SecretNearExpiry`, 30 days ahead. REST error
  codes: 401 unauthenticated, 403 authenticated without permission; the
  common codes `AccessDenied` and `ForbiddenByFirewall`. Access-issue
  troubleshooting: an ARM redeploy replaces a vault's access policies.
- **Storage.** The Entra authorization pages for blobs, tables and
  queues: a role holding `listKeys` reads data by Shared Key, and
  assignments "may take up to 30 minutes to propagate". Preventing
  Shared Key: `allowSharedKeyAccess`, which permits Shared Key while
  `null`. 403 troubleshooting: `AuthorizationPermissionMismatch`,
  `KeyBasedAuthenticationNotPermitted`, `AuthorizationFailure`.
- **Container Registry.** ABAC repository permissions: `AcrPull`,
  `AcrPush` and `AcrDelete` are not honored in an ABAC-enabled
  registry, Owner, Contributor and Reader grant only the control plane
  there, and the role mapping. Login and pull troubleshooting: the mode
  check `az acr show --query roleAssignmentMode`. Container Apps image
  pull: prefer a user-assigned identity, and the registry must allow
  ARM-audience tokens (`az acr config authentication-as-arm show`).
- **Resource providers.** Resource providers and types:
  `/register/action` is in Contributor and Owner, and a template
  registers only the providers it defines. The registration
  troubleshooting page: `MissingSubscriptionRegistration`, fixed with
  `az provider register`; no template resource type is offered. The
  .NET reference: the request path
  `/subscriptions/{subscriptionId}/providers/{resourceProviderNamespace}/register`.
  The FinOps toolkit page: Contributor or `/register` "for the entire
  subscription".
- **Entra.** Admin consent: Privileged Role Administrator for any API;
  Cloud Application, Application or AI Administrator for all but
  Microsoft Graph app roles. Built-in roles: Application Developer
  consents only on its own behalf; Application and Cloud Application
  Administrator can add credentials to an app and impersonate it.
  Credentials: secrets at most 24 months, under 12 recommended, not for
  production; managed identity, then another platform's identity, then
  certificates, never secrets; app management policies recommend a
  180-day certificate lifetime. The error-codes page: verbatim
  descriptions of 22 codes; the federation codes are not on it.
- **Azure Identity for Python.** `DefaultAzureCredential`:
  `managed_identity_client_id` "Defaults to the value of the
  environment variable AZURE_CLIENT_ID", and `None` forces the
  system-assigned identity. `ManagedIdentityCredential` defaults to the
  system-assigned identity and reads no variable. `EnvironmentCredential`
  and `WorkloadIdentityCredential` read `AZURE_CLIENT_ID` as an app
  registration's client ID.
- **GitHub.** Learn's OIDC page for the Azure Login action: the secrets
  come from an app registration or a user-assigned identity, the job
  needs `id-token: write`, the audience defaults to
  `api://AzureADTokenExchange`. The `Azure/login` README: `client-id`
  may name either, and no `github.event` value belongs in its inputs.
- **Azure CLI 2.90.0**, local `--help`: `az role assignment list` takes
  `--assignee-object-id`, with `--include-inherited` and
  `--include-groups` off by default, and Learn's reference adds that
  without `--scope` it shows subscription-scope assignments only;
  `az ad app credential list` needs `--cert` for certificates;
  `az ad app credential reset` "clears all passwords and keys" unless
  `--append` (Learn's reference); `az identity federated-credential
  create` defaults `--audiences` and offers a preview claims-matching
  expression in place of `--subject`.
- **Upstream.** `microsoft/azure-skills` at `cf79ce8` (2026-10-16),
  through github-mcp: the root `.claude-plugin/plugin.json` (plugin
  `azure` 1.2.95: skills, `.mcp.json`, hooks), the MIT `LICENSE`, and
  `skills/azure-validate/references/role-verification.md`, identical to
  the local copy. Local copies read: `entra-app-registration` 1.2.1
  (`SKILL.md`, `references/troubleshooting.md`,
  `references/auth-best-practices.md`), `azure-validate` 1.2.3
  `role-verification.md`, `azure-deploy` 1.2.2
  `live-role-verification.md`, `azure-compliance` 1.2.3
  `azure-keyvault-expiration-audit.md`.
- **Payload.** `claude/rules/coding-ci-workflows.md` § "OIDC subject
  claims", `claude/rules/coding-bicep.md`,
  `skills/fabric-core/fabric-rest-api/references/auth.md` (no API
  permissions for a Fabric service principal), and `claude/CLAUDE.md` §
  "Azure CLI state is per tenant, and pinned by folder".
- **Client evidence**, by kind, carried from the queue brief and not
  re-measured, since that repo was not read: a client repo running a
  Python worker on Container Apps saw a role-assigning template under
  Contributor create its resources, then fail at the first role
  assignment (2026-09-25); saw `MissingSubscriptionRegistration` for a
  deploy identity holding Contributor on one resource group
  (2026-09-29); records the federated-credential escalation in its Key
  Vault decision record; and reads `AZURE_CLIENT_ID` as two identities.

Not drilled, so nothing in the skill describes it:

- The Container Apps runtime: ingress, probes, revisions, Key Vault
  references' refresh. That is `azure-container-apps-skill.md`'s,
  deferred.
- Data roles for services not in use: Cosmos DB, Service Bus, SQL,
  Event Hubs, App Configuration. Upstream's table names two, unchecked.
- Azure Policy denials and deny assignments, Conditional Access, and
  sign-in for people.
- ABAC conditions on Storage and Key Vault, beyond Container Registry's
  mode.
- Azure PowerShell and Terraform: the skill gives `az` commands only.
- The JSON field names `az keyvault secret list` prints; the draft
  marks its expiry query unverified, 2026-10-17.
- Live tenant behaviour: no call reached a tenant.
- Upstream beyond the five skills above, and the plugin's hooks and MCP
  server.

## Frontmatter

```yaml
---
name: azure-access  # directory name; lowercase, digits, hyphens; azure- is the group's prefix
description: "Use when giving an Azure identity access to a resource, or finding why one is refused. Picks the identity first: a user-assigned managed identity for anything in Azure, a federated credential for GitHub Actions or other outside workloads, an app registration last. Then the role on the right plane, since Contributor and Owner carry no DataActions: Key Vault Secrets User, Storage Table and Blob Data roles, AcrPull, or Container Registry Repository Reader in ABAC mode. Covers who may assign roles (Owner, User Access Administrator, Role Based Access Control Administrator, PIM activation first), resource provider registration, propagation and the managed identity token cache, the AZURE_CLIENT_ID that azure/login and Azure Identity read as different identities, escalation through federated credentials, listKeys and Key Vault access policies, and credential expiry. Errors: 401, 403, AuthorizationPermissionMismatch, ForbiddenByRbac, MissingSubscriptionRegistration, AADSTS70021, AADSTS700213, AADSTS7000222."  # gated at 1,024
when_to_use: "Use when asked to grant or check an Azure role, set up a managed identity or a GitHub OIDC federated credential, or explain why a deploy, a container app or a pipeline gets 401, 403 or Forbidden from Azure, why Contributor cannot read a secret or a table row, why a role assignment fails mid-deploy, or which app secrets and Key Vault secrets expire soon. Not for Fabric workspace roles or OneLake permissions, which Azure RBAC does not govern, nor for sign-in policy for people."  # gated at 512; Claude Code only
# model: inherit  # always commented under skills/
# effort: medium   # commented on platform skills: they auto-trigger beside real work
disable-model-invocation: false  # always present
---
```

## Description char count

- `description`: 1,013 / 1,024
- `when_to_use`: 479 / 512

## Body structure outline

1. Title and lead: what the skill does; dated, drilled from Learn on
   2026-10-17; **Not here**: Fabric workspace roles and OneLake,
   Container Apps runtime, Bicep syntax (the rule that loads with
   `*.bicep`), GitHub's half of OIDC (the rule that loads with
   `.github/workflows/*.yml`), people's sign-in; what each
   `references/` file holds.
2. Pin the tenant and name the caller: link `claude/CLAUDE.md`'s tenant
   section rather than restating it; principal (object) ID for a role
   assignment, client ID for the SDK and `azure/login`.
3. Choose the identity, ranked: user-assigned managed identity;
   federated credential, with its rules (user-assigned only, one
   audience, case-sensitive exact subject, 20 per identity, saves when
   wrong, propagation and retry, 409 on parallel creates, flexible
   credentials preview); app registration with a certificate, secrets
   last; admin consent's role tiers, and that it is the identity team's
   to grant; a Fabric service principal needs no API permissions.
4. Pick the role on its plane: `Actions` against `DataActions`; a short
   role table, the full one in `references/roles.md`; three routes from
   the control plane to data (`listKeys`, access-policy vaults, and an
   identity's own assignment); a registry in ABAC mode ignores the
   legacy roles, and image pull by managed identity needs ARM-audience
   tokens.
5. Who can grant it: `roleAssignments/write` holders; a Contributor
   deploy that creates resources, then fails at the first role
   assignment; Role Based Access Control Administrator near Owner
   without conditions; PIM activation; a system-assigned identity's
   ordering; resource provider registration at subscription scope, out
   of the template.
6. Escalation to check before granting Contributor: a federated
   credential on a user-assigned identity in that resource group,
   marked as derived from two documented facts; access-policy vaults;
   `listKeys`; Application and Cloud Application Administrator
   impersonating an app.
7. One variable, two identities: `AZURE_CLIENT_ID` in `azure/login`
   against Azure Identity in the container; which credentials read it;
   keep two names in the template.
8. Triage a 401 or 403, numbered: read the code, not the status; name
   the caller; list its roles at the target, inherited and through
   groups; check the plane and the mode; check the clock (10 and 30
   minutes, the managed identity cache); network last.
9. Credential expiry: app secrets and certificates with `endDateTime`;
   federated credentials carry no expiry; never `credential reset`
   without `--append`; Key Vault `exp` is informational; the near-expiry
   event.
10. Constraints: read before granting, least privilege at resource
    scope, no Owner or User Access Administrator to clear a 403, no
    permission-model or registry-mode switch without equivalent roles
    first, the tenant pin before any `az` call, client names by kind.

`references/roles.md`: the data-plane role table for Key Vault, Storage
and Container Registry, Contributor's `NotActions`, the roles holding
`roleAssignments/write` and the federated-credential write, and both
registry modes. `references/errors.md`: 401 and 403 codes by service,
the ARM deploy errors, and the AADSTS codes with Learn's text.
`references/credentials.md`: Learn's credential ranking and lifetimes,
the expiry checks, the reset trap and Key Vault's expiry semantics.
`references/LICENSE.upstream`: `microsoft/azure-skills`' MIT licence,
cited the way `pbir-report-workflow` cites `skills-for-fabric`.

## Changes from source proposal

Replaces the queue brief `azure-access-skill.md` (2026-10-15), deleted
in the same change. The user decided its question on 2026-10-17: open
the `azure` group, author `azure-access`, one skill with
`references/`. Departures, each from the drill above:

- **Who can assign roles** adds Role Based Access Control Administrator
  to Owner and User Access Administrator.
- **`az role assignment list --scope <id> --assignee-object-id <oid>`**,
  lifted from `azure-deploy`, is right but misses a role granted on the
  resource group, the subscription or a group without
  `--include-inherited` and `--include-groups`.
- **"Contributor reads no secret and no table row"** holds only for
  Entra tokens: a Contributor reads storage data through `listKeys`,
  and gives itself a vault's secrets through an access policy.
- **AcrPull and AcrPush** do nothing in an ABAC-mode registry, and
  image pull by managed identity needs ARM-audience tokens: both new.
- **The federated-credential escalation** stays, marked derived: Learn
  states its two premises, that Contributor's `*` holds the
  federated-credential write and that a federated credential issues
  tokens as the identity, but not the conclusion.
- **The exact subject match** gains case-sensitivity and the preview
  flexible credentials.
- **The AADSTS index** is rebuilt from Learn: upstream's
  `troubleshooting.md` labels `AADSTS50020` "Invalid tenant",
  `AADSTS70000` "Grant declined" and `AADSTS90072` "Consent needed",
  none of which Learn's descriptions say.
- **Upstream's fix for an invalid secret**,
  `az ad app credential reset --id $APP_ID --years 1`, clears every
  password and certificate on the app; the skill warns instead.
- **The credential comparison** follows Learn's ranking, which puts
  another platform's identity above certificates.
- **The Key Vault expiry audit** adds that `exp` is informational and an
  expired secret still reads, so the outage comes from the credential
  inside it, on Entra's clock.
- **The drift source**, if one is registered, belongs at the repo's
  top-level `skills/`, which the root plugin ships, not
  `.github/plugins/azure-skills/skills/`. None is registered, by the
  user's call of 2026-10-17: see Notes.
- **The plugin form**, unchecked in the queue brief, installs skills,
  `.mcp.json` servers and hooks.

## Tag

personal

## Portability caveats

N/A — personal scope.

## Cross-reference dependencies

- `claude/CLAUDE.md` § "Azure CLI state is per tenant, and pinned by
  folder" — (a) already converted; user scope, so it loads wherever the
  group is linked.
- `claude/rules/coding-ci-workflows.md` § "OIDC subject claims" — (a);
  pointed at by the file that loads it, `.github/workflows/*.yml`.
- `claude/rules/coding-bicep.md` — (a); pointed at by `*.bicep`.
- `skills/fabric-core/fabric-rest-api/references/auth.md` — (a);
  named only for a repo that also links `fabric-core`, since the
  Container Apps repo may not.
- `microsoft/azure-skills` — (c) external, MIT.

## Claude Code's post-draft checklist

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**Opening the group** takes more than the skill: `azure` in
`PLATFORM_GROUPS` and `azure-` in `PLATFORM_PREFIXES` in
`scripts/lint-skill-overrides.py`, an `azure-access` entry in
`.claude/settings.json`'s `skillOverrides`, and a group section in
`skills/README.md`. The prefix list is restated in the post-deploy
check of root `CLAUDE.md`, `skills/workflow/run-briefs/SKILL.md` and its
`references/landing-gate.md`, `.vscode/tasks.json`, and
`.claude/skills/author-skill/SKILL.md` and `test-skill/SKILL.md`, and
`.claude/rules/skill-overrides.md` names the groups; each gains `azure`.

**No drift source, by the user's call of 2026-10-17.** The queue brief proposed
registering `microsoft/azure-skills` beside `skills-for-fabric`, which
the user retired on 2026-10-16, a day later (`34618f8`): no vendored
skill was left to re-sync, its claims needed Learn before they counted,
and its counterpart table needed an edit on every rename. Each reason
fits this source too, since nothing here is vendored and the drill
corrected upstream where the list above says, so the user declined it.

**The worktree is `azure-access-skill`**, named after the queue brief
this one replaces, so whoever lands it pairs it with `azure-access.md`.

**Fresh-session test queries.** Should fire:

1. "My container app gets a 403 reading a Key Vault secret, but its
   identity has Contributor on the resource group. Why?"
2. "Set up GitHub Actions to deploy to Azure with OIDC through a
   user-assigned managed identity."
3. "The Bicep deploy fails: does not have permission to perform action
   'Microsoft.Authorization/roleAssignments/write'."
4. "Deploy fails with MissingSubscriptionRegistration for Microsoft.App."
5. "AADSTS700213: No matching federated identity record found for
   presented assertion subject."
6. "Which of our app registration secrets expire in the next 30 days?"
7. "The worker pulls from ACR with AcrPull and gets 401 unauthorized."

Should not fire:

1. "Give a user Contributor on a Fabric workspace."
2. "Set up Conditional Access to require MFA for admins."
3. "Add a liveness probe to the Container Apps worker."
4. "Fix the Bicep linter warning about a secure parameter."

## Confidence

- Structure: H — a platform group with one skill, the `windows`
  pattern.
- Field specs: H — counts measured, lint pending.
- Body content: M — every claim is from Learn, CLI help or upstream
  bytes read today, but no command ran against a tenant, and the
  escalation and the `AZURE_CLIENT_ID` trap are reasoned from
  documented behaviour plus one client repo's record.
