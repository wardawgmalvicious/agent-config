# Fabric Data Agent: consumption surfaces in full

Split out of the parent `fabric-data-agent` SKILL.md, which carries the
summary table. This file holds the prerequisites, endpoint anatomy, and
compliance caveats per surface.

Beyond in-product chat (GA), a published data agent can be consumed from several surfaces — every surviving one is **preview**; one retired on 2026-08-26:

- **Microsoft 365 Copilot (Agent Store) — preview.** At publish time, choose **Publish to Agent Store** to make the agent available in M365 Copilot. Users chat with it directly or `@`-mention it from the main Copilot chat in Teams, share it via link (1:1, group, or channel), and use the **code interpreter** to visualize results. Requires a paid **F2+** (or P1+ with Fabric enabled) capacity, an **M365 Copilot license** (or Office 365 commercial subscription) plus per-user licenses, the **cross-geo processing and cross-geo storing for AI** tenant settings enabled, and the agent + Copilot on the **same tenant / same account**. The publish **description** becomes the `description_for_model` that steers the M365 orchestrator — you can instruct it to return the agent's output as-is, but the orchestrator still reasons over the grounding data, so some rephrasing is inevitable. RLS/CLS and underlying-source access are fully enforced per the calling user. **Compliance note:** responses may leave Fabric's compliance boundary / geographic region and be processed or stored under M365's data-handling policies.
- **MCP server endpoint — preview.** The programmatic query surface, and the replacement for the retired Assistants API path. A published agent exposes **exactly one MCP tool**: send a question, get a grounded answer. Endpoint (streamable HTTP):

  ```http
  https://api.fabric.microsoft.com/v1/mcp/workspaces/{WorkspaceId}/dataagents/{DataAgentId}/agent
  ```

  Copy it from **Settings → Model Context Protocol** on the published agent (that tab also gives the tool name, tool description, and a downloadable `mcp.json`), or build it from the two IDs. **It only works after publish** — an unpublished agent returns an error even with a correct URL. Any MCP client works provided it speaks MCP over streamable HTTP and attaches a Fabric bearer token; a plain REST call that skips the `initialize` → `tools/list` → `tools/call` flow will not. Don't hard-code the tool name or its argument — discover them from `tools/list` and the tool's input schema. The **publish description becomes the tool description** the server advertises, so it is what an orchestrator reads to decide whether to call the agent: write it for that audience. Same compliance caveat as M365 Copilot — responses may leave Fabric's compliance boundary and be handled under the MCP client's policies.
- **Copilot Studio / Azure AI Foundry (Agent Service) — preview.** Identity passthrough (On-Behalf-Of); see [authentication.md](authentication.md). Foundry now connects through MCP.
- ~~**Copilot in Power BI**~~ — **retired 2026-08-26.** Was: add the agent via **Add items for better results → Data agents**, or let Copilot search rank it alongside semantic models and reports. If you have an existing wiring here, it is gone; move it to one of the surfaces above. (The Learn page still stands and still reads as preview — the retirement is announced through the Fabric What's New / Fabric Updates blog, so trust the date, not the page.)

## Learn pages

- [Consume Fabric data agent in Microsoft 365 Copilot (preview)](https://learn.microsoft.com/fabric/data-science/data-agent-microsoft-365-copilot)
- [Data agent as a Model Context Protocol server (preview)](https://learn.microsoft.com/fabric/data-science/data-agent-mcp-server)
