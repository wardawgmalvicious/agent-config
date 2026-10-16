# Fabric Data Agent: consumption surfaces in full

Split out of [data-agent.md](../data-agent.md), which carries the
summary table. This file holds the prerequisites, endpoint anatomy, and
compliance caveats per surface.

Beyond in-product chat (GA), a published data agent can be consumed from several surfaces. The MCP endpoint and Copilot Studio's tool path are GA; the rest are **preview**; one retired on 2026-08-26:

- **Microsoft 365 Copilot (Agent Store) — preview.** At publish time, choose **Publish to Agent Store** to make the agent available in M365 Copilot. Users chat with it directly or `@`-mention it from the main Copilot chat in Teams, share it via link (1:1, group, or channel), and use the **code interpreter** to visualize results. Requires a paid **F2+** (or P1+ with Fabric enabled) capacity, an **M365 Copilot license** (or Office 365 commercial subscription) plus per-user licenses, the **cross-geo processing and cross-geo storing for AI** tenant settings enabled, and the agent + Copilot on the **same tenant / same account**. The publish **description** becomes the `description_for_model` that steers the M365 orchestrator — you can instruct it to return the agent's output as-is, but the orchestrator still reasons over the grounding data, so some rephrasing is inevitable. RLS/CLS and underlying-source access are fully enforced per the calling user. **Compliance note:** responses may leave Fabric's compliance boundary / geographic region and be processed or stored under M365's data-handling policies. Separately, answering from **Power BI content** in Microsoft 365 Copilot Chat (Fabric IQ) is **GA**; it does not cover data agents, which answer there only through an explicitly published Microsoft 365 agent, this path (Learn, 2026-10-06).
- **MCP server endpoint — GA.** The programmatic query surface, and the replacement for the retired Assistants API path. A published agent exposes **exactly one MCP tool**: send a question, get a grounded answer. Endpoint (streamable HTTP):

  ```http
  https://api.fabric.microsoft.com/v1/mcp/workspaces/{WorkspaceId}/dataagents/{DataAgentId}/agent
  ```

  Copy it from **Settings → Model Context Protocol** on the published agent (that tab also gives the tool name, tool description, and a downloadable `mcp.json`), or build it from the two IDs. **It only works after publish** — an unpublished agent returns an error even with a correct URL. Any MCP client works provided it speaks MCP over streamable HTTP and attaches a Fabric bearer token; a plain REST call that skips the `initialize` → `tools/list` → `tools/call` flow will not. Don't hard-code the tool name or its argument — discover them from `tools/list` and the tool's input schema. The **publish description becomes the tool description** the server advertises, so it is what an orchestrator reads to decide whether to call the agent: write it for that audience. Same compliance caveat as M365 Copilot — responses may leave Fabric's compliance boundary and be handled under the MCP client's policies.

  **Long-running questions become MCP tasks.** A question that outlives the connection returns a task identifier instead of the answer, following the `io.modelcontextprotocol/tasks` extension: the client polls with `tasks/get` until the work finishes, and stops it with `tasks/cancel`, which isn't instant. Only clients that support the extension get a task; for every other client nothing changes, and the answer comes back on the same connection. Whether a given client supports the extension is the client's to say — check it rather than assume.

  **An answer carries text, never the query**: for the DAX, use the
  Responses client below. On the preview runtime an answer also embeds
  its result as `file:///result_0.csv`, and ends "File(s) result_0.json
  were generated as a result of the query.", a line no instruction
  removes: the query tool's output tells the model always to name the
  file, and "never mention a result file" kept the name out of the rest
  of each answer but not that line. In one client estate on 2026-10-15
  the line ended 11 of 12 preview answers and none of 12 standard ones,
  and the preview answers embedded 13 CSVs, the standard ones none. So
  only the client, or the standard runtime, keeps it from a reader.
- **Python SDK's Responses client — preview.** `FabricOpenAIResponses`,
  in `fabric-data-agent-sdk`, asks the agent through the OpenAI
  Responses API and returns every step it took, so it is the scripted
  route to an answer's DAX. Learn's own route is the agent's step panel,
  where its semantic model best practices have the author review the DAX
  of each response (step 7, read 2026-10-16); this one a script can
  grade.

  ```python
  from azure.identity import AzureCliCredential
  from fabric.dataagent.client import FabricOpenAIResponses

  client = FabricOpenAIResponses(agent_id, workspace_id, ai_skill_stage="production", credential=AzureCliCredential())
  response = client.responses.create(input=question)
  ```

  `ai_skill_stage="production"` asks the published agent and `sandbox`
  the draft, and **`sandbox` is the default** (0.1.33a0 source, read
  2026-10-16), so a call that omits it tests the draft. An explicit
  `credential` needs the workspace passed too. With the Azure CLI
  credential it runs outside a notebook, and `AZURE_CONFIG_DIR` picks
  the tenant. `response.output` holds the steps, as seen on 0.1.33a0 in
  one client estate on 2026-10-15:

  - a `function_call` named `trace.analyze_semantic_model`, whose
    `arguments.query` is the question as the agent rewrote it for the
    DAX step;
  - on the preview runtime, `askPBI.tool.execute`, whose
    `arguments.code` is the DAX, inside a code fence tagged `dax`;
  - on the standard runtime, `analyze.database.nl2code`, which writes
    DAX variations, then `analyze.database.execute`, whose
    `arguments.code` is the DAX run;
  - `function_call_output` items, the result the model saw: the preview
    tool's begins "The dataset contains N rows", and the standard
    tool's can begin "Note: This result is incomplete. The query matched
    at least 1001 rows, but only the first 200 are included here.";
  - a final `message`, the reply.

  **Each call runs the agent anew.** Asked the same question minutes
  apart, this client and the MCP endpoint named different months as the
  lowest (four runs, two per runtime, 2026-10-15): grade a run, not a
  question.
- **Copilot Studio tool — GA.** In a Copilot Studio agent built on the GitHub Copilot harness, add the **Fabric IQ Data MCP** tool, pick a published data agent from the OneLake catalog, write the description the orchestrator routes on, and set the auth mode: **User** or **Maker** (see [authentication.md](authentication.md)). Repeat per data agent.
- **Copilot Studio connected agent / Azure AI Foundry (Agent Service) — preview.** The earlier path, adding the data agent from the **Agents** category as a connected agent. Identity passthrough (On-Behalf-Of); see [authentication.md](authentication.md). Foundry now connects through MCP.
- ~~**Copilot in Power BI**~~ — **retired 2026-08-26.** Was: add the agent via **Add items for better results → Data agents**, or let Copilot search rank it alongside semantic models and reports. If you have an existing wiring here, it is gone; move it to one of the surfaces above. (The Learn page still stands and still reads as preview — the retirement is announced through the Fabric What's New / Fabric Updates blog, so trust the date, not the page.)

## Learn pages

- [Consume Fabric data agent in Microsoft 365 Copilot (preview)](https://learn.microsoft.com/fabric/data-science/data-agent-microsoft-365-copilot)
- [Data agent as Model Context Protocol server](https://learn.microsoft.com/fabric/data-science/data-agent-mcp-server)
- [Add a Fabric data agent as a tool in Microsoft Copilot Studio](https://learn.microsoft.com/fabric/data-science/data-agent-microsoft-copilot-studio-tool)
