# MCP Templates

Two starter configurations for Model Context Protocol (MCP) servers in Claude Code:

| File | Scope | Destination | Shared? |
| --- | --- | --- | --- |
| [.mcp.global.template.json](.mcp.global.template.json) | **User** | `~/.claude.json` (top-level `mcpServers`) | No — per-machine |
| [.mcp.project.template.json](.mcp.project.template.json) | **Project** | `<repo-root>/.mcp.json` | Yes — committed to VCS |

Claude Code supports three MCP scopes: **user** (across every project on the machine), **project** (per-repo, shared via `.mcp.json`), and **local** (per-repo, private, stored under `projects.<path>.mcpServers` inside `~/.claude.json`). These templates cover the first two.

---

## Global template — user scope

[.mcp.global.template.json](.mcp.global.template.json) is the set of MCP servers that should be available in **every** Claude Code session on this machine. It is not tied to any single repo.

### Installation

Merge the `mcpServers` object from the template into the **top level** of `~/.claude.json` (on Windows: `C:\Users\<you>\.claude.json`):

```jsonc
{
    // ...existing top-level fields...
    "mcpServers": {
        "powerbi-modeling-mcp": { /* from template */ },
        "powerbi-remote-mcp":   { /* from template */ },
        "microsoft-fabric-mcp": { /* from template */ },
        "azure-mcp":            { /* from template */ },
        "microsoft-learn-mcp":  { /* from template */ }
    },
    "projects": { /* ...existing per-project local-scope entries stay here... */ }
}
```

> **Don't** place these under `projects.<path>.mcpServers` — that is **local scope** (per-project, private), not user scope.

Alternatively, use the CLI (writes to the same top-level `mcpServers` key):

```bash
claude mcp add --scope user powerbi-remote-mcp --transport http https://api.fabric.microsoft.com/v1/mcp/powerbi
```

### What each server provides

| Server | Transport | Purpose |
| --- | --- | --- |
| `powerbi-modeling-mcp` | stdio (`npx @microsoft/powerbi-modeling-mcp`) | Local Power BI Desktop / TOM operations — tables, measures, relationships, partitions, DAX query execution against an open model. |
| `powerbi-remote-mcp`   | http  | Hosted Fabric service for Power BI — authenticates against `api.fabric.microsoft.com` and exposes workspace-scoped tools. |
| `microsoft-fabric-mcp` | stdio (`npx @microsoft/fabric-mcp ... --mode all`) | Fabric core + OneLake + docs: create items, list workspaces/tables, read Fabric docs, best practices. |
| `azure-mcp`            | stdio (`npx @azure/mcp`) | Azure control-plane: ARM resources, Key Vault, Cosmos, SQL, Storage, Monitor, Functions, Bicep, etc. |
| `microsoft-learn-mcp`  | http  | Search and fetch official Microsoft Learn / Azure docs (`microsoft_docs_search`, `microsoft_code_sample_search`, `microsoft_docs_fetch`). |

`cmd /c npx ...` is the Windows-friendly invocation; Claude Code launches `cmd.exe` which in turn resolves `npx` from `PATH`. On macOS / Linux drop `"cmd", "/c"` and invoke `npx` directly.

---

## Project template — project scope

[.mcp.project.template.json](.mcp.project.template.json) is the starter set for servers that only make sense inside a specific repo. Copy it to the repo root as `.mcp.json` and commit it — every collaborator who opens the repo in Claude Code will get the same MCP tools.

### Installation

1. Copy the template to the repo root:

    ```bash
    cp ~/.claude/mcp/.mcp.project.template.json ./.mcp.json
    ```

2. Replace the placeholders:

    | Placeholder | Replace with |
    | --- | --- |
    | `<ABSOLUTE_PATH_TO_REPO>` | Absolute path of the repo root (DAB needs to locate `api/dab-config.json`). |
    | `<your-sql-server>` | Azure SQL logical server name (without `.database.windows.net`). |
    | `<your-database>` | Initial catalog / database name. |
    | `<OrgName>` | Azure DevOps organization. |
    | `<ProjectName>` | Azure DevOps project. |

3. Commit `.mcp.json` to version control.

4. The **first time** Claude Code launches inside the repo it will prompt for approval before connecting to any server listed in `.mcp.json`. This is a deliberate security check — reset those choices with:

    ```bash
    claude mcp reset-project-choices
    ```

### What each server provides

| Server | Transport | Purpose |
| --- | --- | --- |
| `sql-mcp` | stdio (`dab start --mcp-stdio`) | Data API Builder exposing the repo's Azure SQL schema as MCP tools. Uses `Active Directory Interactive` auth by default; override via the `DAB_CONNECTION_STRING` env var. |
| `azure-devops-mcp` | stdio (`npx @azure-devops/mcp`) | Azure DevOps work items, repos, pipelines scoped to the configured org + project. |

> `ASPNETCORE_URLS=http://127.0.0.1:0` forces DAB to pick a free loopback port so multiple Claude sessions or a running dev server don't collide.

---

## Verifying the setup

```bash
# List every MCP server Claude Code currently sees, grouped by scope
claude mcp list

# Show details for one server (config source, status, last error)
claude mcp get <name>
```

A server appearing under the wrong scope is almost always a sign it landed in `projects.<path>.mcpServers` instead of top-level `mcpServers`.
