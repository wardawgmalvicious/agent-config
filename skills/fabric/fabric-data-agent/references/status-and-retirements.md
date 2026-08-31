# Fabric Data Agent: GA status, preview surface, retirements

Split out of the parent `fabric-data-agent` SKILL.md. Read when you need to
know whether a specific capability is production-ready, or when an older
integration has stopped working.

**Status — Generally Available as of March 2026.** The core agent (create / configure / publish / share), built-in diagnostics, and end-to-end lifecycle management via Git integration + deployment pipelines are all GA. Treat as a production surface. The following companion features are still in **preview** at GA and should be gated accordingly: the **Creator Agent** ("Build agent with AI") for AI-assisted authoring of the four configuration layers, the **MCP server endpoint** (the programmatic query surface — see [consumption-surfaces.md](consumption-surfaces.md)), consumption from **Microsoft 365 Copilot** (Agent Store), the **Fabric Data Agent Python SDK** (including programmatic `evaluate_few_shots` and ground-truth evaluation), **Microsoft Copilot Studio integration**, **Azure AI Foundry / Azure AI Agent Service integration**, and the **external Python client SDK** (interactive-browser auth pattern for embedding in custom apps).

**Retired 2026-08-26** — two integration paths no longer exist. Do not build against either:

- **Azure OpenAI Assistants API.** Data agents were historically described as "built on Azure OpenAI Assistant APIs", and the Python SDK queried them through the OpenAI Assistants API. Direct Assistants API integrations had to migrate to the **data agent MCP endpoint** before 2026-08-26. Within the SDK, the equivalent move is from the Fabric OpenAI client to the Fabric OpenAI **Responses** client (migration path opened 2026-08-11). Only *querying* code was affected — create / configure / publish are unchanged.
- **Copilot in Power BI.** The Fabric data agent integration in Copilot in Power BI retired on the same date; move those workflows to a supported surface (in-product chat, M365 Copilot, Copilot Studio, Foundry, or the MCP endpoint).

## Learn pages

- [Fabric data agent Python SDK (preview)](https://learn.microsoft.com/fabric/data-science/fabric-data-agent-sdk) — management plane; querying moved to the MCP endpoint
- [Consume a Fabric data agent from Copilot in Power BI](https://learn.microsoft.com/fabric/data-science/data-agent-copilot-powerbi) — **integration retired 2026-08-26**; page kept for reference only
