# MS Learn link bundle — Fabric Security

Curated set of Microsoft Learn pages relevant to the Fabric security model — workspace and item permissions, OneLake security (RLS/CLS/OLS), per-item authorization, workspace identity and trusted access, network security (private links, firewalls, managed VNets, managed private endpoints, conditional access), sensitivity labels and Purview integration. Load on demand when designing or troubleshooting access.

The 3 highest-leverage entry points (security overview, permission model, OneLake security overview) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

## Concept and overview

- [Security in Microsoft Fabric (overview)](https://learn.microsoft.com/fabric/security/security-overview) — top-level concept, the access / protect / recover triad, links into all other security topics. Read first.
- [Microsoft Fabric security fundamentals](https://learn.microsoft.com/fabric/security/security-fundamentals) — OneLake, workspace boundaries, item security, data in transit, encryption at rest. The conceptual primer.
- [Permission model](https://learn.microsoft.com/fabric/security/permission-model) — workspace roles, item permissions, the "Read vs ReadData vs ReadAll" distinction. Authoritative reference.
- [Microsoft Fabric end-to-end security scenario](https://learn.microsoft.com/fabric/security/security-scenario) — worked medallion (bronze/silver/gold) example showing how the layers combine in practice. Useful when designing a new workspace.

## Workspace, item, and role-based access

- [Roles in workspaces in Microsoft Fabric](https://learn.microsoft.com/fabric/fundamentals/roles-workspaces) — the Admin / Member / Contributor / Viewer matrix in detail (per-item-type capabilities, REST API behavior).
- [Share Fabric items](https://learn.microsoft.com/fabric/fundamentals/share-items) — the sharing surface for granting per-item access without workspace membership.
- [Give users access to workspaces](https://learn.microsoft.com/fabric/fundamentals/give-access-workspaces) — UI walkthrough for assigning workspace roles, including security-group based assignment.

## OneLake security (RLS / CLS / OLS at the lake layer)

- [OneLake security — get started](https://learn.microsoft.com/fabric/onelake/security/get-started-security) — the OneLake security model (newer than the SQL-only RLS/CLS), workspace-permission interaction, ReadData / ReadAll meaning under OneLake security. Required first read before defining lake-level roles.
- [OneLake security access control model](https://learn.microsoft.com/fabric/onelake/security/data-access-control-model) — folder hierarchy + role evaluation, shortcut behavior (target permissions vs listing), RLS / CLS / OLS interaction.
- [Row-level security in OneLake (preview)](https://learn.microsoft.com/fabric/onelake/security/row-level-security) — RLS rule syntax, supported operators, character limit, RLS+CLS combination caveats.
- [Column-level security in OneLake (preview)](https://learn.microsoft.com/fabric/onelake/security/column-level-security) — column hiding, single-role RLS+CLS combination requirement.
- [OneLake security for SQL analytics endpoints (preview)](https://learn.microsoft.com/fabric/onelake/security/sql-analytics-endpoint-onelake-security) — user identity vs delegated identity modes; per-object security control matrix; bypass behavior for Admin/Member/Contributor.

## Per-item authorization (SQL granular, Direct Lake)

- [Secure your Fabric Data Warehouse](https://learn.microsoft.com/fabric/data-warehouse/security) — warehouse-specific layered access model, DDM (warehouse-only), CMK (customer-managed keys). Pair with `fabric-warehouse` skill.
- [SQL granular permissions in Microsoft Fabric](https://learn.microsoft.com/fabric/data-warehouse/sql-granular-permissions) — `GRANT` / `DENY` / `REVOKE` syntax, auto-create-on-GRANT pattern, querying granted permissions via `sys.database_principals`.
- [Authorization in SQL database in Fabric](https://learn.microsoft.com/fabric/database/sql/authorization) — SQL Database item permissions and SQL-engine-level access controls (different from Warehouse).
- [Integrate Direct Lake security](https://learn.microsoft.com/fabric/fundamentals/direct-lake-security-integration) — semantic-model security on top of OneLake security, OLS / RLS interaction, the metadata-visibility caveat for Viewers with Build permission.

## Workspace identity, service principals, trusted access

- [Workspace identity](https://learn.microsoft.com/fabric/security/workspace-identity) — Fabric-managed SPN per workspace, lifecycle (deleted with the workspace), Application Administrator caveats. F SKU only.
- [Authenticate with workspace identity](https://learn.microsoft.com/fabric/security/workspace-identity-authenticate) — using workspace identity in connections, supported data sources via the connector overview.
- [Trusted workspace access](https://learn.microsoft.com/fabric/security/security-trusted-workspace-access) — accessing firewall-enabled ADLS Gen2 via workspace identity + resource instance rules. Shortcuts, pipelines, COPY INTO, semantic models, AzCopy. F SKU only; ARM templates required.
- [Enable service principal for admin APIs](https://learn.microsoft.com/fabric/admin/enable-service-principal-admin-apis) — tenant-setting requirement for SPN-driven admin and update API calls.

## Network security

- [Conditional access in Fabric](https://learn.microsoft.com/fabric/security/security-conditional-access) — Microsoft Entra Conditional Access for inbound connections (IP restrictions, MFA, location/device controls).
- [Protect inbound traffic to Fabric tenants](https://learn.microsoft.com/fabric/security/protect-inbound-traffic) — decision guide: Conditional Access vs private links vs IP firewall.
- [Private links for Fabric tenants (overview)](https://learn.microsoft.com/fabric/security/security-private-links-overview) — tenant-level private endpoint concept, traffic implications, considerations.
- [Set up tenant-level private links](https://learn.microsoft.com/fabric/security/security-private-links-use) — step-by-step configuration.
- [Workspace-level private links](https://learn.microsoft.com/fabric/security/security-workspace-level-private-links-overview) — granular per-workspace private link configuration.
- [Workspace IP firewall rules](https://learn.microsoft.com/fabric/security/security-workspace-level-firewall-overview) — IP allow lists per workspace; interaction matrix with tenant private links and public access.
- [Managed private endpoints](https://learn.microsoft.com/fabric/security/security-managed-private-endpoints-overview) — Fabric-managed private endpoints from Spark workloads to data sources.
- [Managed virtual networks](https://learn.microsoft.com/fabric/security/security-managed-vnets-fabric-overview) — per-workspace managed VNet for Spark workloads; isolation and private endpoint enablement.
- [Advanced networking tenant settings](https://learn.microsoft.com/fabric/admin/service-admin-portal-advanced-networking) — tenant admin toggles for private links, block public access, workspace-level inbound/outbound, IP firewall.

## Sensitivity labels, Purview, governance

- [Protected sensitivity labels in Fabric](https://learn.microsoft.com/fabric/governance/protected-sensitivity-labels) — Microsoft Purview Information Protection labels applied to Fabric items; label inheritance and persistence on export.
- [Microsoft Purview hub for Fabric](https://learn.microsoft.com/fabric/governance/microsoft-purview-fabric) — single-pane-of-glass for governance; audit log access, DLP integration.
- [Govern Fabric (Cloud Adoption Framework)](https://learn.microsoft.com/azure/cloud-adoption-framework/data/governance-security-baselines-fabric-data-lake-unify-data-platform) — broader CAF guidance for Fabric governance baselines.

## Troubleshooting

- [Troubleshoot restricted access in Fabric](https://learn.microsoft.com/fabric/governance/troubleshoot-restricted-access) — diagnose access denials caused by tenant policies vs workspace permissions vs item permissions. Use when "I should be able to see this but can't".
