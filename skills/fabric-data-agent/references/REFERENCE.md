# MS Learn link bundle — Fabric Data Agent

Curated set of Microsoft Learn pages relevant to creating, configuring, consuming, and governing Fabric Data Agents. Load on demand when you need authoritative reference for a specific layer (configuration, consumption pattern, governance setting, or troubleshooting).

The three highest-leverage entry points (concept, configurations, tenant settings) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

## Concept and overview

- [Fabric data agent — concept](https://learn.microsoft.com/fabric/data-science/concept-data-agent) — what a data agent is, what it does, where it sits architecturally. Read first for new users.

## Create and configure

- [Create a Fabric data agent](https://learn.microsoft.com/fabric/data-science/how-to-create-data-agent) — UI walkthrough for creating an agent, attaching data sources, end-to-end flow. Includes the security/governance section (Purview policies, semantic-model permission rules, cross-tenant data via OneLake shares).
- [Data agent configurations](https://learn.microsoft.com/fabric/data-science/data-agent-configurations) — the four configuration layers (agent instructions, data source instructions, descriptions, example queries) covered in detail. Microsoft's reference for the structured authoring model this skill describes.

## Consumption — programmatic and external

- [Consume a Fabric data agent with the Python client SDK (preview)](https://learn.microsoft.com/fabric/data-science/consume-data-agent-python) — interactive-browser auth + Python SDK pattern for embedding the agent in custom apps. Use when building external clients or automation around an agent.
- [Consume Fabric data agent from Microsoft Foundry Services (preview)](https://learn.microsoft.com/fabric/data-science/data-agent-foundry) — wiring the agent into an Azure AI Agent (Foundry). Workspace ID + artifact ID setup, On-Behalf-Of identity passthrough, both UI and SDK paths.
- [Use the Microsoft Fabric data agent (Foundry — REST)](https://learn.microsoft.com/azure/foundry/agents/how-to/tools/fabric) — REST patterns for Foundry agent integration. Includes the troubleshooting table (artifact-ID errors, `unauthorized`, `configuration not found`, query timeout, empty results, etc.) — useful first stop when an integration breaks.
- [Use the Microsoft Fabric data agent (Foundry classic — REST)](https://learn.microsoft.com/azure/foundry-classic/agents/how-to/tools-classic/fabric) — older Foundry-classic REST path with `2025-05-15-preview` API version. Reach for this only if you're on the classic Foundry surface.

## Governance and tenant settings

- [Fabric data agent tenant settings](https://learn.microsoft.com/fabric/data-science/data-agent-tenant-settings) — admin tenant switches (cross-geo processing/storing for AI), SKU and capacity prerequisites (F2+ or P1+), feature enablement. Check before assuming an agent will run in a given tenant or workspace region.
