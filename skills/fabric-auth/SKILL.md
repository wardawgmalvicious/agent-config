---
name: fabric-auth
description: "Use when authenticating to Microsoft Fabric APIs — getting 401 Unauthorized errors, choosing token audience/scope for Fabric REST, Power BI REST, OneLake, Warehouse/SQL, KQL, XMLA, or Azure ARM, or running `az login` / `az account get-access-token` / `az rest` for Fabric. Covers the full token-audience table, the OneLake-only `storage.azure.com/.default` requirement, `az login` flow variants (--allow-no-subscriptions, --use-device-code, SPN cert, managed identity), `az rest --resource` requirement (Fabric URL is not a built-in Azure endpoint), JWT decoding for 401 debugging, and why using the wrong audience is the #1 cause of 401s."
---

# Fabric authentication & token audiences

All Fabric operations require Microsoft Entra ID OAuth 2.0 bearer tokens. **Using the wrong audience is the #1 cause of 401 errors.**

| Access Target | Token Audience / Scope |
|---|---|
| **Fabric REST API** | `https://api.fabric.microsoft.com/.default` |
| **Power BI REST API** (refresh, data sources, permissions, DAX) | `https://analysis.windows.net/powerbi/api/.default` |
| **OneLake** (DFS/Blob) | `https://storage.azure.com/.default` |
| **Warehouse / SQL Endpoint / SQL Database** (TDS) | `https://database.windows.net/.default` |
| **KQL / Kusto** | `https://kusto.kusto.windows.net/.default` |
| **XMLA Endpoint** | `https://analysis.windows.net/powerbi/api/.default` |
| **Azure Resource Management** | `https://management.azure.com/.default` |

```bash
az login
az account get-access-token --resource https://api.fabric.microsoft.com    # Fabric REST
az account get-access-token --resource https://database.windows.net        # SQL / TDS
az account get-access-token --resource https://analysis.windows.net/powerbi/api  # Power BI
```

**Critical**: OneLake ONLY accepts `https://storage.azure.com/.default` — using `https://datalake.azure.net/` will fail.

## `az login` flow variants

```bash
az login --allow-no-subscriptions --tenant <tid>     # Fabric tenant with no Azure subscription
az login --use-device-code --tenant <tid>            # headless / SSH / no-browser
az login --service-principal -u <appId> -p <secret> --tenant <tid>           # CI/CD with SPN secret
az login --service-principal -u <appId> --certificate /path/cert.pem --tenant <tid>   # SPN cert (preferred — no secret to rotate)
az login --identity                                  # system-assigned managed identity
az login --identity --username <clientId>            # user-assigned managed identity
```

Without `--allow-no-subscriptions`, Fabric-only tenants (no Azure subscription attached) get a confusing "No subscriptions found" error before any Fabric call runs.

## `az rest --resource` requirement

`api.fabric.microsoft.com` is not a built-in Azure cloud endpoint, so `az rest` cannot derive the audience from the URL. Always pass `--resource`:

```bash
az rest --method get \
  --resource "https://api.fabric.microsoft.com" \
  --url "https://api.fabric.microsoft.com/v1/workspaces"
```

Without `--resource`, you get `"Can't derive appropriate Azure AD resource from --url"` — the single most common `az rest` Fabric error.

## Decoding a token to debug 401s

When you get an unexpected 401, decode the JWT to see what audience the token actually has:

```bash
TOKEN=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv)
echo "$TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq .
```

Compare the `aud` claim against the table above. Other useful claims: `exp` (Unix expiry), `oid` (principal object ID), `tid` (tenant ID).

## TDS connection essentials (Warehouse / SQL Database)

When connecting via `sqlcmd`, ODBC drivers, or any TDS client:

| Parameter | Value |
|---|---|
| **Port** | 1433 (TCP, must be open outbound) |
| **`Initial Catalog` / `Database`** | Item display name (NOT the FQDN) |
| **Authentication** | Microsoft Entra ID only — SQL auth is not supported |
| **Encryption** | `Encrypt=Yes` required |
| **Token audience** | `https://database.windows.net/.default` |
| **MARS** | Not supported — remove `MultipleActiveResultSets` from connection strings (or set to `false`) |

**Gotcha**: `Login failed... database not found` usually means the connection string passed the FQDN as `Initial Catalog` instead of the workspace item display name. Allow `*.datawarehouse.fabric.microsoft.com` and `*-pbidedicated.windows.net` through any outbound firewall.

## Reference

- Microsoft Learn: [Authenticate to Azure using Azure CLI](https://learn.microsoft.com/cli/azure/authenticate-azure-cli)
- Microsoft Learn: [MSAL overview](https://learn.microsoft.com/entra/msal/overview)
- Microsoft Learn: [Microsoft Entra authentication for Fabric SQL](https://learn.microsoft.com/fabric/data-warehouse/entra-id-authentication)
- Comprehensive MS Learn link bundle (concept / Fabric REST auth / Azure CLI / OAuth flows / MSAL by language / SPN & managed identity / scopes & claims / Fabric-specific): [references/REFERENCE.md](references/REFERENCE.md)
