# MS Learn link bundle — Fabric Authentication

Curated set of Microsoft Learn pages relevant to authenticating to Fabric APIs and data planes — Microsoft identity platform concepts, MSAL token-acquisition patterns, Azure CLI sign-in flows, OAuth 2.0 grant types, service principals and managed identities, and the Fabric-specific token-audience and TDS connection surface. Load on demand when designing or debugging auth flows.

The 3 highest-leverage entry points (Authenticate to Azure CLI, MSAL overview, Entra authentication for Fabric SQL) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

## Concept and overview

- [Microsoft identity platform overview](https://learn.microsoft.com/entra/identity-platform/) — authoritative entry point for the Microsoft Entra developer surface (apps, scopes, tokens, flows).
- [Microsoft Authentication Library (MSAL) overview](https://learn.microsoft.com/entra/msal/overview) — language-agnostic MSAL primer; supported platforms (.NET, Python, Node.js, Java, JS, mobile), application scenarios, token-cache and refresh handling.
- [Authentication in Microsoft Fabric (overview)](https://learn.microsoft.com/fabric/security/security-overview#authenticate) — Fabric-side framing: every Fabric request is authenticated with Microsoft Entra ID.
- [Microsoft Entra authentication as alternative to SQL authentication in Fabric](https://learn.microsoft.com/fabric/data-warehouse/entra-id-authentication) — TDS connection auth: Entra-ID-only (no SQL auth), benefits, MFA / Conditional Access integration, role assignment via Entra groups.

## Fabric REST API auth

- [Fabric API quickstart](https://learn.microsoft.com/rest/api/fabric/articles/get-started/fabric-api-quickstart) — end-to-end MSAL.NET token-acquisition + first List Workspaces call. Authoritative starting point.
- [Troubleshoot Fabric REST APIs (401 / 403 / 404 / 429)](https://learn.microsoft.com/rest/api/fabric/articles/get-started/fabric-api-troubleshooting) — `TokenExpired`, `InsufficientScopes`, `InsufficientPrivileges`, `EntityNotFound`, throttling. First stop when an auth call fails.

## Azure CLI authentication

- [`az login` reference](https://learn.microsoft.com/cli/azure/reference-index#az-login) — full parameter list including `--allow-no-subscriptions`, `--use-device-code`, `--service-principal`, `--certificate`, `--identity`, `--use-cert-sn-issuer`.
- [Authenticate to Azure using Azure CLI (overview)](https://learn.microsoft.com/cli/azure/authenticate-azure-cli) — decision guide across user / SPN / managed-identity sign-in methods.
- [Sign in with a service principal (CLI)](https://learn.microsoft.com/cli/azure/authenticate-azure-cli-service-principal) — secret and certificate variants; `read -s` and `Get-Credential` patterns to avoid printing secrets in console.
- [Service principal certificate-based auth](https://learn.microsoft.com/cli/azure/azure-cli-sp-tutorial-3) — PEM file format (PRIVATE KEY + CERTIFICATE concatenated), `az ad sp credential reset --append --cert`, Key Vault retrieval pattern.
- [Sign in with a managed identity (CLI)](https://learn.microsoft.com/cli/azure/authenticate-azure-cli-managed-identity) — system-assigned (`--identity`) and user-assigned (`--identity --username <client-id>`) flavors.
- [Use Azure REST API with Azure CLI](https://learn.microsoft.com/cli/azure/use-azure-cli-rest-command) — `az rest` patterns including the `--resource` requirement for non-built-in Azure endpoints (the source of the most common Fabric `az rest` error).

## OAuth 2.0 grant types

- [Authorization code flow](https://learn.microsoft.com/entra/identity-platform/v2-oauth2-auth-code-flow) — interactive user sign-in for web and SPA. PKCE required for SPAs.
- [Client credentials flow](https://learn.microsoft.com/entra/identity-platform/v2-oauth2-client-creds-grant-flow) — daemon / app-only flow used by service principals. The `/.default` scope idiom comes from here.
- [On-behalf-of (OBO) flow](https://learn.microsoft.com/entra/identity-platform/v2-oauth2-on-behalf-of-flow) — middle-tier service exchanging a user assertion for a downstream-API token. Used by Fabric data agent → underlying source authentication.
- [Device code flow](https://learn.microsoft.com/entra/identity-platform/v2-oauth2-device-code) — input-constrained / SSH / Cloud Shell / IoT scenarios. Same flow `az login --use-device-code` triggers.

## MSAL by language

- [MSAL Python — acquiring tokens](https://learn.microsoft.com/entra/msal/python/getting-started/acquiring-tokens) — `acquire_token_silent` → `acquire_token_for_client` / `acquire_token_on_behalf_of` / `acquire_token_interactive` patterns.
- [MSAL .NET — token acquisition overview](https://learn.microsoft.com/entra/msal/dotnet/acquiring-tokens/overview) — `IPublicClientApplication` and `IConfidentialClientApplication`, AcquireToken* methods.
- [MSAL Node — overview](https://learn.microsoft.com/entra/msal/node/) — `PublicClientApplication` and `ConfidentialClientApplication`, ADAL→MSAL migration notes.

## Service principals, managed identities, app registrations

- [App objects and service principals](https://learn.microsoft.com/entra/identity-platform/app-objects-and-service-principals) — the application object vs service principal distinction; per-tenant projection; how SPNs get created from app registrations.
- [Managed identities for Azure resources — overview](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview) — system-assigned vs user-assigned, lifecycle, when each fits.

## Scopes, consent, claims (debugging tokens)

- [Permissions and consent overview](https://learn.microsoft.com/entra/identity-platform/permissions-consent-overview) — delegated vs application permissions, user consent vs admin consent, incremental consent patterns.
- [Access token claims reference](https://learn.microsoft.com/entra/identity-platform/access-token-claims-reference) — full claim catalog including `aud`, `iss`, `exp`, `oid`, `tid`, `roles`, `scp`, `appid`. Decode-then-compare workflow for debugging 401s.

## Fabric-specific identity surfaces

- [Workspace identity](https://learn.microsoft.com/fabric/security/workspace-identity) — Fabric-managed SPN per workspace, secure inter-service auth without managing credentials. F SKU only.
- [Enable service principal for admin APIs](https://learn.microsoft.com/fabric/admin/enable-service-principal-admin-apis) — tenant-setting requirement before SPN-driven admin/update API calls work.
