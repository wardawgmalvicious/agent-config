---
name: azure-access
description: "Use when giving an Azure identity access to a resource, or finding why one is refused. Picks the identity first: a user-assigned managed identity for anything in Azure, a federated credential for GitHub Actions or other outside workloads, an app registration last. Then the role on the right plane, since Contributor and Owner carry no DataActions: Key Vault Secrets User, Storage Table and Blob Data roles, AcrPull, or Container Registry Repository Reader in ABAC mode. Covers who may assign roles (Owner, User Access Administrator, Role Based Access Control Administrator, PIM activation first), resource provider registration, propagation and the managed identity token cache, the AZURE_CLIENT_ID that azure/login and Azure Identity read as different identities, escalation through federated credentials, listKeys and Key Vault access policies, and credential expiry. Errors: 401, 403, AuthorizationPermissionMismatch, ForbiddenByRbac, MissingSubscriptionRegistration, AADSTS70021, AADSTS700213, AADSTS7000222."
when_to_use: "Use when asked to grant or check an Azure role, set up a managed identity or a GitHub OIDC federated credential, or explain why a deploy, a container app or a pipeline gets 401, 403 or Forbidden from Azure, why Contributor cannot read a secret or a table row, why a role assignment fails mid-deploy, or which app secrets and Key Vault secrets expire soon. Not for Fabric workspace roles or OneLake permissions, which Azure RBAC does not govern, nor for sign-in policy for people."
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Azure access: give X access to Y, and find why X is refused

Most Azure access failures come down to four things: the wrong
identity is calling, its role sits on the wrong plane, the role was
never assigned because whoever deployed could not assign roles, or the
change has not reached the caller yet. This skill walks them in that
order, for an identity calling Key Vault, Storage or Container Registry
from a deploy pipeline or a running app.

**Dated, and drilled from Microsoft Learn and `az` 2.90.0 on
2026-10-17.** No command here was run against a tenant; a line marked
*unverified* says what was not checked.

**Not here.** Fabric workspace roles and OneLake permissions, which
Azure RBAC does not govern. The Container Apps runtime: ingress,
probes, revisions. Bicep syntax and its green-build traps,
`principalType` among them, belong to the rule that loads with
`*.bicep`; GitHub's half of OIDC, the subject each trigger puts in the
token, to the rule that loads with `.github/workflows/*.yml`. Sign-in
policy for people: Conditional Access and MFA. Data roles for Cosmos
DB, Service Bus, SQL and other services were not drilled.

Detail lives in `references/`: `roles.md` (the data-plane roles per
service, Contributor's exclusions, who holds which write, both
permission models), `errors.md` (401 and 403 codes by service, deploy
errors, AADSTS codes in Learn's words) and `credentials.md` (credential
types, lifetimes, Key Vault's expiry semantics). Each cites the Learn
page behind its claims.

## 1. Pin the tenant, then name the caller

**Pin the tenant before any `az` call**, as `~/.claude/CLAUDE.md` §
"Azure CLI state is per tenant, and pinned by folder" says: an unpinned
shell answers from whatever tenant the shared config last held, and
every listing below then describes the wrong directory.

**Every identity has two IDs, and each command wants one.** A managed
identity or service principal has a client (application) ID and a
principal (object) ID. Role assignments take the principal ID:
`--assignee-object-id` is "The assignee's object ID (also known as
principal ID)", and skips the Microsoft Graph lookup `--assignee` makes.
`azure/login`'s `client-id`, `AZURE_CLIENT_ID` and the SDKs' `client_id`
take the client ID.

```bash
az identity show -g <rg> -n <identity> --query "{clientId:clientId, principalId:principalId}" -o json
```

**Name who actually called** before reading any role: the `azure/login`
step's log for a pipeline, the credential the app builds (§6) for an
app, `az account show` for a person. A 403 diagnosed against the wrong
principal ends with roles granted to an identity that was never in the
request.

## 2. Choose the identity

Best first; take the first that fits.

1. **A user-assigned managed identity, for anything running in Azure.**
   Learn: "User-assigned managed identities are more efficient in a
   broader range of scenarios than system-assigned managed identities."
   It exists before the resource, so its roles can be assigned first,
   which a system-assigned identity's cannot: "role assignments can't be
   created in advance. This sequence can cause failures while deploying
   infrastructure if the user creating the resource doesn't also have
   access to create role assignments." Container Apps' image-pull page
   agrees: "When possible, you should use a user-assigned managed
   identity to pull images." Use system-assigned only where the
   permissions must go with the resource, or an audit must name the
   resource rather than the identity.
2. **A federated credential, for anything outside Azure**: GitHub
   Actions, another cloud, a cluster elsewhere. It goes on a
   user-assigned identity or an app registration: "Configuring a
   federated identity credential on a system-assigned managed identity
   isn't supported." Each rule below fails silently:
   - **Issuer, subject and audience match exactly and
     case-sensitively.** For GitHub the issuer is
     `https://token.actions.githubusercontent.com` and the audience
     `api://AzureADTokenExchange`, exactly one; the subject is whatever
     the job's token carries, which depends on its trigger.
   - **A wrong subject saves without error.** The credential "is
     created successfully without error. The error does not become
     apparent until the token exchange fails", as `AADSTS700213` for the
     subject or `AADSTS700211` for the issuer.
   - **A new credential needs time to propagate.** A token request
     minutes later can fail `AADSTS70021`; wait, and retry.
   - **At most 20 per identity.** Several created under one identity in
     parallel fail with HTTP 409: chain them with `dependsOn` in a
     template.
   - **No wildcards**, except in the preview flexible credentials, for
     GitHub, GitLab and Terraform Cloud tokens only. Learn says the CLI
     has no explicit support for them, yet `az` 2.90.0 shows a preview
     `--claims-matching-expression-value` on `az identity
     federated-credential create` (2026-10-17).
3. **An app registration with a certificate**, when neither fits, and a
   secret last: "Client secrets are less secure than certificate or
   federated credentials and therefore should not be used in production
   environments." `references/credentials.md` has Learn's ranking and
   the lifetimes.

**Admin consent is not the app owner's to give.** Tenant-wide consent
takes Privileged Role Administrator for any API, or Cloud Application,
Application or AI Administrator for any API except Microsoft Graph app
roles. Application Developer can register apps and update those it owns,
and consents only on its own behalf. Where the user holds Application
Developer, a consent request goes to the organization's identity team.

**A Fabric service principal needs no API permissions**: Fabric
authorizes it by tenant setting, security group and workspace role. In a
repo that also links `fabric-core`, `fabric-rest-api`'s
`references/auth.md` has the detail.

## 3. Pick the role on its plane

**Contributor and Owner manage resources, and read no Key Vault or
Storage data.** Azure RBAC keeps the control plane in a role's
`Actions` and the data plane in its `DataActions`. Contributor holds
`Actions: *` and no `DataActions`, so a Contributor's token gets no
secret value from Key Vault and no blob or table entity from Storage.
Container Registry differs: its legacy roles hold pull and push as
`Actions`, which `*` covers, until the registry runs ABAC mode, where
Owner, Contributor and Reader "grant only control plane permissions".
Grant the data role for the operation, at the resource:

| The caller needs to | Grant | Not |
| --- | --- | --- |
| Read a Key Vault secret's value | Key Vault Secrets User | Key Vault Reader, metadata only |
| Create, update or delete secrets | Key Vault Secrets Officer | Key Vault Contributor, control plane only |
| Read table entities | Storage Table Data Reader | Reader or Contributor |
| Write table entities | Storage Table Data Contributor | Storage Account Contributor |
| Read or write blobs | Storage Blob Data Reader or Contributor | Contributor |
| Pull images, RBAC-only registry | AcrPull | Contributor, which works but over-grants |
| Pull images, ABAC-enabled registry | Container Registry Repository Reader | AcrPull, not honored |
| Push images, ABAC-enabled registry | Container Registry Repository Writer | AcrPush, not honored |

**Check the permission model before the role.** Two services keep a
second model beside plain RBAC, and a correct role does nothing under
the other one:

- **Key Vault**: `enableRbacAuthorization` `true` is RBAC; `false` or
  `null` is access policies, under which the Key Vault roles do nothing.
  RBAC became the default only for vaults created with API version
  `2026-02-01` or later, "This default applies only to create
  operations", so a template pinned to an older API version still
  creates an access-policy vault.

  ```bash
  az keyvault list -g <rg> --query "[].{name:name, rbacEnabled:properties.enableRbacAuthorization}" -o table
  ```

- **Container Registry**: in ABAC mode, `rbac-abac`, "Legacy ACR roles
  such as `AcrPull`, `AcrPush`, and `AcrDelete` are not honored", and
  Owner, Contributor and Reader grant the control plane only.

  ```bash
  az acr show -n <registry> -g <rg> --query roleAssignmentMode -o tsv
  ```

**Image pull by managed identity has a switch on the registry.** "Your
Azure Container Registry must allow ARM audience tokens for
authentication in order to use managed identity to pull images";
without it, pulls fail `UNAUTHORIZED` "token validation failed". Check
with `az acr config authentication-as-arm show -r <registry>`.

**Scope the role to the resource**, the vault, account or registry,
not the resource group: a group-scope grant reaches every vault and
account the group will ever hold. Learn's Key Vault guidance is "a vault
per application per environment ... with roles assigned at the key vault
scope".

## 4. Who can grant it

**Assigning a role takes `Microsoft.Authorization/roleAssignments/write`**,
which Owner, User Access Administrator and Role Based Access Control
Administrator hold. Contributor's `NotActions` exclude
`Microsoft.Authorization/*/Write`, "Create roles, role assignments,
policy assignments...". So a template holding role assignments, deployed
as Contributor, creates its resources and then fails at the first role
assignment, with an authorization error naming
`Microsoft.Authorization/roleAssignments/write` (a client repo,
2026-09-25). Deploy as a principal holding the write, or split the role
assignments into a deployment such a principal runs.

**Role Based Access Control Administrator without conditions is close to
Owner.** Learn lists it as able to "Assign themselves or others the
Owner role". Delegate it with conditions limiting which roles and which
principals it may assign; Key Vault Data Access Administrator is the
built-in example, constrained to the Key Vault roles.

**Under PIM, activate first.** "If users are eligible for a role, then
they must activate the role assignment before using the role." An
eligible Owner deploying unactivated deploys as whatever is active, and
fails as above. After activating, sign out and back in, since Resource
Manager caches (§7 step 5).

**Registering a resource provider is a subscription-level act.** It
takes the provider's `/register/action`, which Contributor and Owner
include, held on the subscription: the request path is
`/subscriptions/{subscriptionId}/providers/{resourceProviderNamespace}/register`.
A template registers the providers it defines when the deployer can,
and a deploy identity with Contributor on one resource group cannot, so
the first deploy of a new resource type fails
`MissingSubscriptionRegistration` (a client repo, 2026-09-29). Learn
offers no template resource type for registering, so register once,
outside the template, as someone with rights on the subscription:

```bash
az provider register --namespace <namespace> --wait
```

## 5. What Contributor also grants

**Contributor on a resource group reaches further than its resources.**
Check each route before granting it on a group that holds identities,
vaults, storage or anything that runs code:

- **Code on a resource runs as its identities.** Learn: "if a user has
  access to install or execute code on this resource, then the user has
  access to all the identities assigned/associated to the Azure
  resource", and one who can assign the identity "can assign it to a
  different Azure resource and have access to all the permissions
  available to the managed identity". A Contributor can do both.
- **A federated credential on a user-assigned identity in the group.**
  `Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/write`
  falls inside Contributor's `*`, and none of its `NotActions` excludes
  it; a federated credential lets the issuer and subject it names get
  tokens as the identity. So a Contributor there can make the identity
  trust a workload of its own and act with every role the identity
  holds. Learn states both premises, not the conclusion, so this is
  derived; a client repo's Key Vault decision record reached it too.
- **An access-policy vault.** "With the Access Policy permission model,
  users with the `Contributor`, `Key Vault Contributor`, or any role
  that includes `Microsoft.KeyVault/vaults/write` permissions can grant
  themselves data plane access by configuring a Key Vault access
  policy."
- **`listKeys` on a storage account.** Owner, Contributor and Storage
  Account Contributor "do not provide access to the table data within
  that account via Microsoft Entra ID. However, if a role includes
  Microsoft.Storage/storageAccounts/listKeys/action, then a user to whom
  that role is assigned can access data in the storage account via
  Shared Key authorization". Close it with `allowSharedKeyAccess:
  false`; while the property is unset, Shared Key is allowed.

So keep an identity whose roles matter in a resource group where only
its owners hold Contributor. The Entra side has the same shape:
Application and Cloud Application Administrator "can add credentials to
an application, and use those credentials to impersonate the
application's identity".

## 6. One variable, two identities: `AZURE_CLIENT_ID`

**The same name means the deploy identity in a workflow and the app's
identity in its container.**

- **In GitHub Actions**, `azure/login`'s `client-id`, usually fed from
  `secrets.AZURE_CLIENT_ID`, is the identity the workflow deploys as,
  copied "from your Microsoft Entra application or user-assigned managed
  identity".
- **In the app**, Azure Identity reads the variable itself.
  `DefaultAzureCredential`'s `managed_identity_client_id` "Defaults to
  the value of the environment variable AZURE_CLIENT_ID, if any. If not
  specified, a system-assigned identity will be used." Its first link,
  `EnvironmentCredential`, reads the same variable as an app
  registration's ID when a secret or certificate variable sits beside
  it.
- **A standalone `ManagedIdentityCredential` reads no variable**: it
  "defaults to using a system-assigned identity", so with only a
  user-assigned identity attached it asks for one that may not exist.
  Pass `client_id`.
- **Two user-assigned identities on one resource** make an unnamed
  request fail: "Multiple user assigned identities exist, please specify
  the clientId / resourceId of the identity in the token request". Learn
  recommends naming the identity "even if only one user assigned managed
  identity currently exists".

So a template or workflow that copies its own `AZURE_CLIENT_ID` into
the container's environment points the app at the deploy identity.
Keep two names in the template, such as `deployClientId` and
`workerClientId`, and set the container's `AZURE_CLIENT_ID` from the
user-assigned identity's `clientId`. In production, construct the
specific credential: "Specifying this exact type of credential prevents
other available credentials from being picked up unexpectedly."

## 7. Triage a 401 or 403

Each step rules out a class of cause before the next one costs
anything.

1. **Read the code, not the status.** A 401 means the service had no
   token it accepts: the wrong tenant or audience, an expired secret
   (`AADSTS7000222`), a federated credential matching nothing
   (`AADSTS700213`, `AADSTS700211`, `AADSTS70021`), or a registry
   refusing ARM-audience tokens. A 403 means it knew the caller and
   refused it: no data role (`AuthorizationPermissionMismatch` from
   Storage; `Forbidden` or `ForbiddenByRbac` from Key Vault, or
   `AccessDenied` under access policies), Shared Key disabled
   (`KeyBasedAuthenticationNotPermitted`), or the network. Learn's RBAC
   troubleshooting adds that a role change not yet seen can show as
   `Status: 401 (Unauthorized)`. `references/errors.md` has each code.
2. **Name the caller** (§1), and for an app the credential it built
   (§6).
3. **List what the caller holds at the target, inherited included.**
   Learn's own registry troubleshooting runs:

   ```bash
   az role assignment list --assignee <principalId> --scope <resourceId> --include-inherited -o table
   ```

   `--include-inherited` defaults off, and without it a role granted on
   the resource group or the subscription is missing from the list;
   without `--scope`, "only assignments scoped to subscription will be
   displayed". Add `--include-groups` for a role held through a group,
   and use `--assignee-object-id` in place of `--assignee` where Graph
   is out of reach; whether the two combine was not checked
   (*unverified*, `az` 2.90.0, 2026-10-17). Upstream's live role check
   passes neither flag.
4. **Check the plane and the model** (§3): a data role for this
   operation, on a vault in RBAC mode or a registry in the mode the role
   belongs to, with Shared Key allowed if the caller signs with keys.
5. **Check the clock.** Learn gives "up to 10 minutes" for a role
   change in its RBAC troubleshooting, "up to 30 minutes" on the Storage
   authorization pages, and hours at management-group scope for roles
   with `DataActions`. A person refreshes by signing out and in. A
   managed identity cannot: its tokens are cached "per resource URI for
   around 24 hours", "it isn't possible to force a managed identity's
   token to be refreshed before its expiry", and a change to its group
   membership "can take several hours". So grant a managed identity its
   roles directly, not through a group, and before the resource using it
   starts.
6. **Network last.** A firewall, a private endpoint or disabled public
   access also returns 403, with its own code: `AuthorizationFailure`
   from Storage, `ForbiddenByFirewall` from Key Vault.

## 8. Credential expiry

**App secrets and certificates expire on Entra's clock; list both
kinds.** `az ad app credential list` shows passwords unless given
`--cert`:

```bash
az ad app credential list --id <appId> --query "[].{name:displayName, ends:endDateTime}" -o table
az ad app credential list --id <appId> --cert --query "[].{name:displayName, ends:endDateTime}" -o table
```

Graph documents `endDateTime` as "always in UTC time". A secret lives
at most 24 months, and Learn recommends under 12. Federated credentials
carry no expiry; `az ad app federated-credential list --id <appId>`
lists them. A managed identity needs no rotation by anyone.

**Never run `az ad app credential reset` without `--append`.** "By
default, this command clears all passwords and keys, and let graph
service generate a password credential": every other consumer of the
app's secrets and certificates loses access at once. Upstream's
`entra-app-registration` troubleshooting suggests the bare form for an
invalid secret.

**A Key Vault secret's `exp` breaks nothing by itself.** It is
optional and "for informational purposes only", and "A secret's get
operation works for not-yet-valid and expired secrets". What breaks is
the credential stored inside, an app secret expiring in Entra, so audit
that at its source, above. The vault's own dates still serve as a
reminder, and Event Grid's `Microsoft.KeyVault.SecretNearExpiry` fires
30 days before one:

```bash
az keyvault secret list --vault-name <vault> --query "[].{name:name, expires:attributes.expires}" -o table   # field names unverified against az output, 2026-10-17
```

## 9. Constraints

- **Read before you grant.** List the caller's roles (§7 step 3) before
  assigning anything; a role already held at a parent scope needs no
  copy.
- **Never clear a 403 with Owner, User Access Administrator or
  Contributor.** Grant the data role for the operation, on the resource.
- **Never switch a permission model under a running workload before
  the equivalent roles exist.** Key Vault: "Setting the Azure RBAC
  permission model invalidates all access policies permissions. It can
  cause outages when equivalent Azure roles aren't assigned." Container
  Registry: assign the ABAC-enabled roles first, since the switch drops
  the legacy ones, and it "briefly disrupts clients that cached
  credentials under RBAC-only mode until those clients refresh, which
  can take from minutes to hours".
- **Never reset an app credential without `--append`** (§8).
- **Never route around admin consent.** Where the user cannot grant it,
  it goes to the identity team (§2).
- **Pin the tenant before any `az` call** (§1).

Seeded from `microsoft/azure-skills` at `cf79ce8` (2026-10-16),
MIT-licensed ([LICENSE.upstream](references/LICENSE.upstream)):
`entra-app-registration` 1.2.1, `azure-validate` 1.2.3, `azure-deploy`
1.2.2 and `azure-compliance` 1.2.3, rewritten against Learn, which
corrected them where this skill says so.
