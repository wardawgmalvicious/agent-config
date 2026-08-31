# Remote MCP server (preview)

Hosted HTTP MCP server for NL-to-KQL and schema discovery. **Claude Code
cannot connect to it** — see below; its working home is `.vscode/mcp.json`.

## Remote MCP server (preview)

A hosted, HTTP-transport MCP server lets Copilot, GitHub Copilot CLI, and custom agents discover the KQL schema, generate KQL from natural language, execute queries, and sample data — without local install.

- **URL pattern**: `https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/{workspaceId}/items/{kqlDatabaseId}/kqlEndpoint` — **per KQL database**, not workspace-wide.
- **Find URL**: Fabric portal → workspace → KQL database → **Database details** > **Overview** > **Copy URI** next to **MCP Server URI**.
- **Transport**: `http`.
- **Auth**: caller needs **Read** or **Query** permission on the KQL database. Schema discovery additionally requires **Copilot in Fabric** to be enabled at the tenant; without it, the server can only execute KQL — no schema introspection, no NL→KQL.
- **Per-database scoping** means the URL is workspace+item-specific, so it never belongs in a user-scope MCP config.
- **Claude Code cannot connect to it.** Every `api.fabric.microsoft.com/v1/mcp/*` endpoint requires OAuth Dynamic Client Registration that Claude Code doesn't support; the server appears in the config and then fails to connect. Neither Claude template carries it. Its working home is `.vscode/mcp.json` for VS Code Copilot / GitHub Copilot CLI, which use first-party client IDs — the agent-config repo ships `.vscode/mcp.template.json` with this entry and its `<WorkspaceId>` / `<KqlDatabaseId>` placeholders. From Claude Code, use the local `fabric-rti-mcp` (`uvx microsoft-fabric-rti-mcp`) instead; it covers KQL query and Eventhouse management without the hosted endpoint.

```json
{
  "mcpServers": {
    "eventhouse-remote-mcp": {
      "type": "http",
      "url": "https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/<WorkspaceId>/items/<KqlDatabaseId>/kqlEndpoint"
    }
  }
}
```

## Microsoft Learn

- [Get started with the remote MCP server for Eventhouse](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-remote-eventhouse)
