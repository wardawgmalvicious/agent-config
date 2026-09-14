# Remote MCP server (preview)

Hosted HTTP MCP server for NL-to-KQL and schema discovery. **It connects from
Claude Code** through a `headersHelper` supplying an `az` bearer — measured
2026-09-14 — and from VS Code Copilot. Only the *automatic* OAuth flow fails.

## Remote MCP server (preview)

A hosted, HTTP-transport MCP server lets Copilot, GitHub Copilot CLI, and custom agents discover the KQL schema, generate KQL from natural language, execute queries, and sample data — without local install.

- **URL pattern**: `https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/{workspaceId}/items/{kqlDatabaseId}/kqlEndpoint` — **per KQL database**, not workspace-wide.
- **Find URL**: Fabric portal → workspace → KQL database → **Database details** > **Overview** > **Copy URI** next to **MCP Server URI**.
- **Transport**: `http`.
- **Auth**: caller needs **Read** or **Query** permission on the KQL database. Schema discovery additionally requires **Copilot in Fabric** to be enabled at the tenant; without it, the server can only execute KQL — no schema introspection, no NL→KQL.
- **Per-database scoping** means the URL is workspace+item-specific, so it never belongs in a user-scope MCP config.
- **It connects from Claude Code via `headersHelper`, and only the automatic OAuth flow fails.** That flow registers via OAuth Dynamic Client Registration, which Microsoft's auth server doesn't support, so a server configured without a helper appears in the config and then fails with `Incompatible auth server: does not support dynamic client registration`. Two documented routes sidestep DCR — a `headersHelper` command supplying the `Authorization` header (upstream's `skills-for-fabric` ships one, audience `https://api.fabric.microsoft.com`) and `claude mcp add --client-id … --client-secret` for a pre-registered Entra app. The first is **measured working against this exact workspace/item-bound `kqlEndpoint` shape** — 2026-09-14, CLI 2.1.268, two rounds against a no-credential control — as well as against the bare `dataPlane/kqlEndpoint` and `dataPlane/sqlEndpoint` siblings. Learn still documents no Azure CLI bearer for `kqlEndpoint`; this is a local measurement, not a documented contract. **The error text differs by URL shape**: on this bound form a helper that yields no credential prints `Error dialing <url>`, not the DCR error, which reads like a network fault and is an auth one. The bare sibling is in the Claude project template as `fabric-kqlendpoint`; this bound form is left to a repo's own `.mcp.json`, since the ids are per-repo — the agent-config repo also ships `.vscode/mcp.template.json` with this entry and its `<WorkspaceId>` / `<KqlDatabaseId>` placeholders for VS Code Copilot. The local `fabric-rti-mcp` (`uvx microsoft-fabric-rti-mcp`) is still worth preferring where you want breadth rather than reachability: it also covers ADX and Eventstream.

For Claude Code, in the repo's own `.mcp.json`. The `headersHelper` is the
load-bearing line — without it the server is configured, connects to nothing,
and reports `Error dialing <url>`:

```json
{
  "mcpServers": {
    "eventhouse-remote-mcp": {
      "type": "http",
      "url": "https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/<WorkspaceId>/items/<KqlDatabaseId>/kqlEndpoint",
      "headersHelper": "az account get-access-token --resource https://api.fabric.microsoft.com --query \"{Authorization: join(' ', ['Bearer', accessToken])}\" --output json --only-show-errors"
    }
  }
}
```

For VS Code Copilot, the same entry in `.vscode/mcp.json` under a top-level
`servers` key and with no helper — that client authenticates with its own
first-party client ID.

## Microsoft Learn

- [Get started with the remote MCP server for Eventhouse](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-remote-eventhouse)
