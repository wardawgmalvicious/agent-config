# Roles for Azure access

Read 2026-10-17 from Learn's built-in roles pages,
`learn.microsoft.com/azure/role-based-access-control/built-in-roles/`,
unless a line names another page.

## Control plane and data plane

"Data plane actions are specified in the `DataActions` and
`NotDataActions` properties. By adding these data properties, the
separation between control plane and data plane is maintained." (Role
definitions.)

**Contributor** holds `Actions` `*`, no `DataActions`, and these eleven
`NotActions`:

```text
Microsoft.Authorization/*/Delete
Microsoft.Authorization/*/Write
Microsoft.Authorization/elevateAccess/Action
Microsoft.Blueprint/blueprintAssignments/write
Microsoft.Blueprint/blueprintAssignments/delete
Microsoft.Compute/galleries/share/action
Microsoft.Purview/consents/write
Microsoft.Purview/consents/delete
Microsoft.Resources/deploymentStacks/manageDenySetting/action
Microsoft.Subscription/cancel/action
Microsoft.Subscription/enable/action
```

Copy the list from the privileged built-in roles page: Learn's role
definitions page and its `az role definition list` example show older,
shorter lists. Anything not in `NotActions` is in Contributor's `*`,
which is how it holds the federated-credential write and `listKeys`.

## Data-plane roles

### Key Vault

Each data role's description ends "Only works for key vaults that use
the 'Azure role-based access control' permission model."

| Role | Grants |
| --- | --- |
| Key Vault Secrets User | "Read secret contents": `secrets/getSecret/action`, `secrets/readMetadata/action` |
| Key Vault Secrets Officer | "Perform any action on the secrets of a key vault, except manage permissions": `secrets/*` |
| Key Vault Reader | metadata only: "Cannot read sensitive values such as secret contents or key material" |
| Key Vault Contributor | control plane only: "does not allow you to access secrets, keys, or certificates" |
| Key Vault Data Access Administrator | assigns the Key Vault data roles only, by a built-in condition; cannot change the permission model |

### Storage

| Role | Grants |
| --- | --- |
| Storage Table Data Reader | "Allows for read access to Azure Storage tables and entities": `tables/entities/read` |
| Storage Table Data Contributor | read, write and delete: `entities/read`, `write`, `delete`, `add/action`, `update/action` |
| Storage Blob Data Reader | read blobs |
| Storage Blob Data Contributor | read and write blobs |

Table operations themselves (read, write, delete a table) sit in
`Actions`, and entity operations in `DataActions`, all under
`Microsoft.Storage/storageAccounts/tableServices/`.

### Container Registry

| Registry mode | Pull | Push | Delete |
| --- | --- | --- | --- |
| RBAC Registry Permissions | AcrPull | AcrPush | AcrDelete |
| RBAC Registry + ABAC Repository Permissions (`rbac-abac`) | Container Registry Repository Reader, plus Catalog Lister to list | Container Registry Repository Writer | Container Registry Repository Contributor |

- AcrPull and AcrPush hold `registries/pull/read` and
  `registries/push/write` as `Actions`, with no `DataActions`, so
  Contributor's `*` covers them in RBAC-only mode.
- In ABAC mode the legacy roles "aren't honored", and Owner,
  Contributor and Reader "grant only control plane permissions to
  create, update, and delete the registry itself".
- An ABAC-enabled role assigned without a condition is registry-wide;
  Catalog Lister "doesn't support ABAC conditions".
- Migrating: keep the registry in RBAC-only mode, assign the equivalent
  ABAC-enabled roles, switch, verify, then remove the legacy
  assignments (ABAC repository permissions page).
- "ABAC-enabled mode (`rbac-abac`) will become the default role
  assignment permissions mode for Azure Container Registry in the
  future."

## Who holds which write

| Permission | Held by | Note |
| --- | --- | --- |
| `Microsoft.Authorization/roleAssignments/write` | Owner, User Access Administrator, Role Based Access Control Administrator | unconstrained, RBAC Administrator can "Assign themselves or others the Owner role" |
| `Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/write` | Managed Identity Contributor; Contributor and Owner through `*` | Managed Identity Operator holds read and `assign/action` only |
| `Microsoft.Storage/storageAccounts/listkeys/action` | Owner, Contributor, Storage Account Contributor, Storage Account Key Operator Service Role, Virtual Machine Contributor | User Access Administrator "permits a security principal to assign any permissions to themselves and others" |
| `<namespace>/register/action` | Contributor and Owner, held on the subscription | |
| A Key Vault's permission model | unrestricted `roleAssignments/write`: Owner, or User Access Administrator with `Microsoft.KeyVault/vaults/write` | Key Vault Data Access Administrator cannot |

Role Based Access Control Administrator also reads "resources of all
types, except secrets" (delegation overview). The storage-key holders
come from the storage authorization resource-provider page and the
account-keys page.

## Key Vault permission models

- **`enableRbacAuthorization`**: `true` is RBAC; `false` or `null` is
  access policies. "Vaults where `enableRbacAuthorization` is `null`
  (from older API versions) continue using access policies."
- **The RBAC default applies only on create**, with API version
  `2026-02-01` or later. Control-plane API versions before it retire on
  2027-02-27; Azure CLI 2.90.0 and Azure PowerShell 16.3.0 support the
  new one.
- **Switching to RBAC** "invalidates all access policies permissions.
  It can cause outages when equivalent Azure roles aren't assigned."
- **An ARM redeploy of an access-policy vault** "deletes any access
  policy in Key Vault and replaces them with access policy in ARM
  template" (access-issue troubleshooting).
- Learn's Key Vault security page: "Legacy access policies have known
  security vulnerabilities and lack support for Privileged Identity
  Management (PIM). Don't use them for critical data and workloads."

## Pages

- Built-in roles, privileged, security, storage, containers, identity:
  `learn.microsoft.com/azure/role-based-access-control/built-in-roles/`
- Role definitions:
  https://learn.microsoft.com/azure/role-based-access-control/role-definitions
- Delegating role assignment management:
  https://learn.microsoft.com/azure/role-based-access-control/delegate-role-assignments-overview
- Container Registry ABAC repository permissions:
  https://learn.microsoft.com/azure/container-registry/container-registry-rbac-abac-repository-permissions
- Storage management roles and keys:
  https://learn.microsoft.com/azure/storage/common/authorization-resource-provider
- Key Vault RBAC guide and default model:
  https://learn.microsoft.com/azure/key-vault/general/rbac-guide and
  https://learn.microsoft.com/azure/key-vault/general/access-control-default
