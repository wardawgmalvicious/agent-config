# Errors: what each one means

Learn's descriptions, read 2026-10-17. Learn's error-code index warns
that "Apps that take a dependency on text or error code numbers will be
broken over time": match on the code, and expect the wording to drift.

## 401 against 403

- Key Vault's REST codes: "401 means that the request is
  unauthenticated for Key Vault." "HTTP 403 means that the request was
  authenticated (it knows the requesting identity) but the identity does
  not have permission to access the requested resource." That page
  names only access policies and the firewall as 403 causes; on an RBAC
  vault, a missing data role is the third.
- Azure RBAC troubleshooting: a role change not yet detected can show
  "Status: 401 (Unauthorized)", so a fresh grant can look like an
  authentication failure for up to 10 minutes.

## Key Vault

| Code | Means |
| --- | --- |
| `Forbidden`, `ForbiddenByRbac` | RBAC vault, no data role: "Caller is not authorized to perform action on resource. If role assignments, deny assignments or role definitions changed recently, please observe propagation time." Learn shows this text in its ABAC conditions how-to |
| `AccessDenied` | access-policy vault: "You may be missing permissions in access policy to do that operation." |
| `ForbiddenByFirewall` | "Client address isn't authorized and caller isn't a trusted service." |

## Storage

| Code | Means |
| --- | --- |
| `AuthorizationPermissionMismatch` | "This request isn't authorized to perform this operation using this permission": no data role, or a SAS missing the permission |
| `KeyBasedAuthenticationNotPermitted` | "Key based authentication is not permitted on this storage account": Shared Key is disallowed, so authenticate with Entra |
| `AuthorizationFailure` | "This request isn't authorized to perform this operation": public access disabled, or IP, virtual network or firewall rules |

## Container Registry

| Symptom | Means |
| --- | --- |
| `UNAUTHORIZED` "token validation failed" on a managed identity pull | the registry refuses ARM-audience tokens: `az acr config authentication-as-arm update -r <registry> --status enabled` |
| `insufficient_scope: authorization failed` on push | no push role for the registry's mode: AcrPush, or Container Registry Repository Writer under ABAC |
| Pulls fail right after a switch to ABAC mode | clients holding credentials cached under RBAC-only mode, "until those clients refresh, which can take from minutes to hours" |

## Resource Manager deploys

- **A role assignment without the write**, in Learn's Azure Developer
  CLI FAQ: "Authorization failed for template resource '<guid>' of type
  'Microsoft.Authorization/roleAssignments'. The client '...' with
  object id '<guid>' does not have permission to perform action
  'Microsoft.Authorization/roleAssignments/write' at scope
  '<resourceId>'." The FAQ adds: "This is common when your user account
  has `Contributor` access but not `Owner` or `User Access
  Administrator` access."
- **`MissingSubscriptionRegistration`**: "The subscription is not
  registered to use namespace {resource-provider-namespace}". A
  template registers only the providers it defines; a supporting
  provider outside it, "monitoring or security resources" among Learn's
  examples, needs registering by hand.
- **A new identity's role assignment in the same template** can fail
  while the identity replicates; `principalType: 'ServicePrincipal'` on
  the assignment avoids it (role assignments with templates). The Bicep
  rule that loads with `*.bicep` covers it.

## Microsoft Entra: AADSTS codes

From Learn's error-code index unless the row says otherwise.

| Code | Learn's description |
| --- | --- |
| AADSTS7000215 | "Invalid client secret is provided." |
| AADSTS7000222 | "InvalidClientSecretExpiredKeysProvided - The provided client secret keys are expired." |
| AADSTS700016 | "The application wasn't found in the directory/tenant": a wrong app ID or tenant |
| AADSTS500011 | "The resource principal named {name} wasn't found in the tenant named {tenant}": the requested resource, not the caller |
| AADSTS90002 | "InvalidTenantName - The tenant name wasn't found in the data store." |
| AADSTS70011 | "InvalidScope - The scope requested by the app is invalid." |
| AADSTS65001 | "DelegationDoesNotExist - The user or administrator hasn't consented to use the application" |
| AADSTS70001 | "UnauthorizedClient - The application is disabled." |
| AADSTS53003 | "BlockedByConditionalAccess - Access has been blocked by Conditional Access policies." |
| AADSTS90014 | "MissingRequiredField - This error code might appear in various cases when an expected field isn't present in the credential." |
| AADSTS70021 | "No matching federated identity record found for presented assertion": also while a new federated credential propagates (federation considerations page) |
| AADSTS700211 | "No matching federated identity record found for presented assertion issuer": no credential, or the issuer is wrong (Azure DevOps workload identity troubleshooting) |
| AADSTS700213 | "No matching federated identity record found for presented assertion subject": no credential, or the subject is wrong; the newer text adds that "matching is done using a case-sensitive comparison" (breaking-changes page) |
| AADSTS700024 | "Client assertion is not within its valid time range": an expired assertion or a skewed clock (Microsoft.Identity.Web) |
| AADSTS70025 | "Client application has no configured federated identity credentials" (Azure DevOps) |
| AADSTS700223 | workload identity federation "is constrained or disabled on the Microsoft Entra tenant" (Azure DevOps) |

The federation codes are not on Learn's index page. Upstream's
`entra-app-registration` table labels AADSTS50020 "Invalid tenant",
AADSTS70000 "Grant declined" and AADSTS90072 "Consent needed"; Learn
describes them as UserUnauthorized (an external account not in the
tenant), InvalidGrant (an invalid refresh token) and
PassThroughUserMfaError.

## Pages

- Error-code index:
  https://learn.microsoft.com/entra/identity-platform/reference-error-codes
- Federation considerations:
  https://learn.microsoft.com/entra/workload-id/workload-identity-federation-considerations
- Azure DevOps workload identity troubleshooting:
  https://learn.microsoft.com/azure/devops/pipelines/release/troubleshoot-workload-identity
- Key Vault REST and common error codes:
  https://learn.microsoft.com/azure/key-vault/general/rest-error-codes and
  https://learn.microsoft.com/azure/key-vault/general/common-error-codes
- Blob Storage 403 troubleshooting:
  https://learn.microsoft.com/troubleshoot/azure/azure-storage/blobs/authentication/storage-troubleshoot-403-errors
- Azure RBAC troubleshooting:
  https://learn.microsoft.com/azure/role-based-access-control/troubleshooting
- Resource provider registration errors:
  https://learn.microsoft.com/azure/azure-resource-manager/troubleshooting/error-register-resource-provider
