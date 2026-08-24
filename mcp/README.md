# MCP Templates

Three starter configurations for Model Context Protocol (MCP) servers, covering Claude Code and VS Code / GitHub Copilot:

| File | Scope | Tool | Destination | Shared? |
| --- | --- | --- | --- | --- |
| [.mcp.global.template.json](.mcp.global.template.json) | **User** | Claude Code | `~/.claude.json` (top-level `mcpServers`) | No — per-machine |
| [.mcp.project.template.json](.mcp.project.template.json) | **Project** | Claude Code | `<repo-root>/.mcp.json` | Yes — committed to VCS |
| [.vscode-mcp.template.json](.vscode-mcp.template.json) | **Workspace** | VS Code / GitHub Copilot | `<repo-root>/.vscode/mcp.json` | Yes — committed to VCS |

Claude Code supports three MCP scopes: **user** (across every project on the machine), **project** (per-repo, shared via `.mcp.json`), and **local** (per-repo, private, stored under `projects.<path>.mcpServers` inside `~/.claude.json`). The first two templates cover Claude Code's user and project scopes.

VS Code / GitHub Copilot uses a different config surface entirely — a **user profile** `mcp.json` (opened via the **MCP: Open User Configuration** command, typically populated through the Extensions view's `@mcp` gallery search rather than hand-edited) and a **workspace** `.vscode/mcp.json` using a top-level `servers` key instead of `mcpServers`. The third template covers that workspace scope; there's no template here for the user-profile file since it's gallery-managed, not hand-authored.

⚠ **Agent Host nuance**: a Copilot CLI / Agent Host session does not read `.vscode/mcp.json` directly — VS Code forwards its contents to the Agent Host automatically, *except* servers with `${input:...}` interactive variables (which the Agent Host can't prompt for). All servers in `.vscode-mcp.template.json` are static HTTP endpoints with no `${input:...}` vars, so they forward fine. For servers that do need interactive input, or for configuration that must be portable across both surfaces, use a root-level `.mcp.json`/`.github/mcp.json` (`copilot mcp add`) or `~/.copilot/mcp-config.json` instead — the Agent Host reads those natively.

---

## Global template — user scope

[.mcp.global.template.json](.mcp.global.template.json) is the set of MCP servers that should be available in **every** Claude Code session on this machine. It is not tied to any single repo.

### Prerequisites

Five server families ride on different runtimes:

- **`npx`-based stdio servers** (`powerbi-modeling-mcp`, `microsoft-fabric-mcp`) need [Node.js](https://nodejs.org/) on `PATH`. The `cmd /c npx ...` wrapper is the Windows-friendly invocation; on macOS / Linux drop `"cmd", "/c"` and invoke `npx` directly.
- **`uvx`-based stdio servers** (`fabric-rti-mcp`) need [`uv`](https://docs.astral.sh/uv/) on `PATH` — `uvx` is the Python tool-runner shipped with `uv` (the `npx` analog for PyPI-packaged tools). The server is distributed on PyPI as `microsoft-fabric-rti-mcp` and downloaded on first launch.
- **`dnx`-based stdio servers** (`fabric-data-factory-mcp`) need the [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) on `PATH` — `dnx` is the .NET tool-runner that ships with it (the `npx` analog for NuGet-packaged tools). The server is distributed via NuGet and downloaded on first launch.
- **Docker MCP Gateway servers** (`github-mcp`, `azure-mcp`, `dockerhub-mcp`) need [Docker Desktop](https://www.docker.com/products/docker-desktop/) **with the MCP Toolkit extension installed and the relevant gateway servers enabled**. Browse, install, and toggle gateway servers from the Docker Desktop **MCP Toolkit** view.
- **Hosted http endpoints** (`microsoft-learn-mcp` plus the Fabric-hosted `powerbi-remote-mcp` / `fabric-core-remote-mcp` / `kql-global-mcp` / `warehouse-global-mcp`, and the project-scope `eventhouse-remote-mcp` / `activator-remote-mcp`) need no local runtime. ⚠ **The Fabric-hosted ones at `api.fabric.microsoft.com/v1/mcp/*` currently error from Claude Code** — Microsoft's auth stack requires OAuth Dynamic Client Registration (DCR) that Claude Code doesn't support. They work from VS Code Copilot / GitHub Copilot CLI (first-party client IDs) — [.vscode-mcp.template.json](#vs-code--github-copilot-template--workspace-scope) is their actual working home. The global and project templates retain them as reference; the working `~/.claude.json` and project-level `.mcp.json` should omit them until either side adds support. `microsoft-learn-mcp` is unaffected — different auth surface (`learn.microsoft.com/api/mcp`).

Each Docker entry passes three Windows env vars (`LOCALAPPDATA`, `ProgramData`, `ProgramFiles`) so the gateway process can resolve Docker's per-user state. Replace `<USER>` with your Windows username before merging. On macOS / Linux, omit the `env` block (Docker Desktop resolves these from the OS).

### Install (user scope)

Merge the `mcpServers` object from the template into the **top level** of `~/.claude.json` (on Windows: `C:\Users\<you>\.claude.json`):

```jsonc
{
    // ...existing top-level fields...
    "mcpServers": {
        "powerbi-modeling-mcp":    { /* from template */ },
        "powerbi-remote-mcp":      { /* template-only — DCR-unsupported from Claude Code */ },
        "microsoft-fabric-mcp":    { /* from template */ },
        "fabric-core-remote-mcp":  { /* template-only — DCR-unsupported from Claude Code */ },
        "fabric-rti-mcp":          { /* from template */ },
        "kql-global-mcp":          { /* template-only — DCR-unsupported from Claude Code */ },
        "fabric-data-factory-mcp": { /* from template */ },
        "microsoft-learn-mcp":     { /* from template */ },
        "github-mcp":              { /* from template */ },
        "azure-mcp":               { /* from template */ },
        "dockerhub-mcp":           { /* from template */ }
    },
    "projects": { /* ...existing per-project local-scope entries stay here... */ }
}
```

> Skip the three **template-only** entries above when merging into your working `~/.claude.json` — they're retained in `.mcp.global.template.json` for reference, but produce auth errors from Claude Code (see Prerequisites for the DCR background). For Fabric-core workflows from Claude Code, use the stdio `microsoft-fabric-mcp` instead; for RTI / KQL, use the local `fabric-rti-mcp`.
>
> **Don't** place these under `projects.<path>.mcpServers` — that is **local scope** (per-project, private), not user scope.

Alternatively, use the CLI (writes to the same top-level `mcpServers` key):

```bash
claude mcp add --scope user microsoft-learn-mcp --transport http https://learn.microsoft.com/api/mcp
```

### Servers (user scope)

| Server | Runtime | Purpose |
| --- | --- | --- |
| `powerbi-modeling-mcp` | stdio (`npx @microsoft/powerbi-modeling-mcp`) | Local Power BI Desktop / TOM operations — tables, measures, relationships, partitions, DAX query execution against an open model. |
| `powerbi-remote-mcp` ⚠ | http (`api.fabric.microsoft.com/v1/mcp/powerbi`) | Hosted Fabric service for Power BI — workspace-scoped tools. **DCR-unsupported from Claude Code; works from VS Code Copilot.** |
| `microsoft-fabric-mcp` | stdio (`npx @microsoft/fabric-mcp ... --mode all`) | Fabric core + OneLake + docs: create items, list workspaces/tables, read Fabric docs, best practices. |
| `fabric-core-remote-mcp` ⚠ | http (`api.fabric.microsoft.com/v1/mcp/core`) | Hosted Fabric Core MCP — natural-language workspace + item CRUD, role assignments, capacity ops via OAuth-authenticated REST. Functional overlap with stdio `microsoft-fabric-mcp` for the core surface. **DCR-unsupported from Claude Code; works from VS Code Copilot.** Use `microsoft-fabric-mcp` instead from Claude Code. Preview as of 2026-05. |
| `fabric-rti-mcp` | stdio (`uvx microsoft-fabric-rti-mcp`) | Local Real-Time Intelligence server — KQL queries against Fabric Eventhouse + ADX, Eventstream / Activator / Map management. PyPI-distributed via `microsoft-fabric-rti-mcp`; covers most RTI workflows without needing the remote endpoints. |
| `kql-global-mcp` ⚠ | http (`api.fabric.microsoft.com/v1/mcp/dataPlane/kqlEndpoint`) | Hosted Fabric global KQL endpoint — workspace + database IDs passed per tool call rather than baked into the URL. **DCR-unsupported from Claude Code; works from VS Code Copilot.** Use `fabric-rti-mcp` instead from Claude Code. |
| `warehouse-global-mcp` ⚠ | http (`api.fabric.microsoft.com/v1/mcp/dataPlane/sqlEndpoint`) | Hosted Fabric global Warehouse SQL endpoint — workspace + item IDs passed per tool call rather than baked into the URL. **DCR-unsupported from Claude Code; works from VS Code Copilot.** No local-runtime equivalent in this template. |
| `fabric-data-factory-mcp` | stdio (`dnx Microsoft.DataFactory.MCP --prerelease`) | Fabric Data Factory control plane: gateways, connections, workspaces, dataflows, pipelines, copy jobs, Apache Airflow jobs, capacities. NuGet-distributed; currently `0.x-beta` (hence `--prerelease`). |
| `microsoft-learn-mcp` | http (`learn.microsoft.com/api/mcp`) | Search and fetch official Microsoft Learn / Azure docs (`microsoft_docs_search`, `microsoft_code_sample_search`, `microsoft_docs_fetch`). Different auth surface — DCR-unaffected. |
| `github-mcp` | stdio (Docker MCP Gateway → `github-official`) | GitHub repos, issues, PRs, releases, code search; uses your local gh / GitHub credentials via the gateway. |
| `azure-mcp` | stdio (Docker MCP Gateway → `azure`) | Azure control-plane: ARM resources, Key Vault, Cosmos, SQL, Storage, Monitor, Functions, Bicep, etc. |
| `dockerhub-mcp` | stdio (Docker MCP Gateway → `dockerhub`) | Docker Hub repos, tags, namespaces, search; useful for image discovery and registry housekeeping. |

---

## Project template — project scope

[.mcp.project.template.json](.mcp.project.template.json) is the starter set for servers that only make sense inside a specific repo. Copy it to the repo root as `.mcp.json` and commit it — every collaborator who opens the repo in Claude Code will get the same MCP tools.

### Install (project scope)

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
    | `<WorkspaceId>` | Fabric workspace ID (shared by `eventhouse-remote-mcp`, `warehouse-remote-mcp`, and `activator-remote-mcp`). |
    | `<KqlDatabaseId>` | KQL database item ID for `eventhouse-remote-mcp`. |
    | `<WarehouseId>` | Warehouse item ID for `warehouse-remote-mcp`. |
    | `<ActivatorId>` | Activator (reflex) artifact ID for `activator-remote-mcp`. |

3. Commit `.mcp.json` to version control.

4. The **first time** Claude Code launches inside the repo it will prompt for approval before connecting to any server listed in `.mcp.json`. This is a deliberate security check — reset those choices with:

    ```bash
    claude mcp reset-project-choices
    ```

### Servers (project scope)

| Server | Runtime | Purpose |
| --- | --- | --- |
| `sql-mcp` | stdio (`dab start --mcp-stdio`) | Data API Builder exposing the repo's Azure SQL schema as MCP tools. Uses `Active Directory Interactive` auth by default; override via the `DAB_CONNECTION_STRING` env var. |
| `azure-devops-mcp` | stdio (`npx @azure-devops/mcp`) | Azure DevOps work items, repos, pipelines scoped to the configured org + project. |
| `eventhouse-remote-mcp` ⚠ | http (`api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/.../items/.../kqlEndpoint`) | Fabric Eventhouse remote MCP scoped to a specific KQL database via workspace + database IDs. **DCR-unsupported from Claude Code; works from VS Code Copilot** — see [.vscode-mcp.template.json](#vs-code--github-copilot-template--workspace-scope) for the surface these actually work from. |
| `warehouse-remote-mcp` ⚠ | http (`api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/.../items/.../sqlEndpoint`) | Fabric Warehouse remote MCP scoped to a specific warehouse via workspace + warehouse IDs. **DCR-unsupported from Claude Code; works from VS Code Copilot** — same note as above. |
| `activator-remote-mcp` ⚠ | http (`api.fabric.microsoft.com/v1/mcp/workspaces/.../reflexes/...`) | Fabric Activator remote MCP scoped to a specific reflex via workspace + activator IDs. Tools cover rule creation (`create_rule`, `list_rules`, `start_rule`, `stop_rule`). **DCR-unsupported from Claude Code; works from VS Code Copilot** — same note as above. |

> `ASPNETCORE_URLS=http://127.0.0.1:0` forces DAB to pick a free loopback port so multiple Claude sessions or a running dev server don't collide.

All three ⚠-flagged rows are kept here because they're technically valid entries in `.mcp.project.template.json` (the DCR failure is Claude-Code-specific, not a bad URL) — but a Claude Code session that actually merges this file's `eventhouse-remote-mcp` / `warehouse-remote-mcp` / `activator-remote-mcp` into its `.mcp.json` will see the server fail to connect. Retained for reference; their real, working home is the VS Code template below.

---

## VS Code / GitHub Copilot template — workspace scope

[.vscode-mcp.template.json](.vscode-mcp.template.json) is the starter set for the Fabric-hosted MCP endpoints that error with OAuth Dynamic Client Registration (DCR) issues from Claude Code but work fine from VS Code Copilot / GitHub Copilot CLI (first-party client IDs). Four of its seven entries (`powerbi-remote-mcp`, `fabric-core-remote-mcp`, `kql-global-mcp`, `warehouse-global-mcp`) mirror the ⚠-flagged rows already sitting in the global template above — this file is their actual working home, since the global template's own destination (`~/.claude.json`) is exactly the surface they fail from. The other three (`eventhouse-remote-mcp`, `warehouse-remote-mcp`, `activator-remote-mcp`) are per-item-scoped variants of the same idea, mirroring the project template's three ⚠-flagged rows. It intentionally excludes the *generic* servers (GitHub, Azure, Microsoft Docs, Fabric core/RTI stdio servers) — those are better installed once per machine through VS Code's own `@mcp` Extensions gallery search (**user profile** scope) rather than hand-authored per repo.

### Install (workspace scope)

1. Copy the template to `.vscode/mcp.json` in the repo root:

    ```bash
    mkdir -p .vscode && cp ~/.claude/mcp/.vscode-mcp.template.json ./.vscode/mcp.json
    ```

2. Drop any entries you don't need for this repo — most repos only need one or two of these, not all seven. `powerbi-remote-mcp`, `fabric-core-remote-mcp`, `kql-global-mcp`, and `warehouse-global-mcp` need no placeholders and work as-is (item/workspace IDs are passed per tool call). `eventhouse-remote-mcp`, `warehouse-remote-mcp`, and `activator-remote-mcp` are pre-scoped to one item and need the placeholders below replaced:

    | Placeholder | Replace with |
    | --- | --- |
    | `<WorkspaceId>` | Fabric workspace ID (shared by all three pre-scoped entries). |
    | `<KqlDatabaseId>` | KQL database item ID for `eventhouse-remote-mcp`. |
    | `<WarehouseId>` | Warehouse item ID for `warehouse-remote-mcp`. |
    | `<ActivatorId>` | Activator (reflex) artifact ID for `activator-remote-mcp`. |

3. Commit `.vscode/mcp.json` to version control — VS Code's own docs recommend including it in source control specifically so a team shares the same server list.

4. The **first time** VS Code starts one of these servers it shows a trust-confirmation dialog per server. Reset all trust decisions with the **MCP: Reset Trust** command from the Command Palette.

### Servers (workspace scope)

| Server | Purpose |
| --- | --- |
| `powerbi-remote-mcp` | Hosted Fabric service for Power BI — workspace-scoped tools, IDs passed per call. |
| `fabric-core-remote-mcp` | Hosted Fabric Core MCP — natural-language workspace + item CRUD, role assignments, capacity ops. Preview as of 2026-05. |
| `kql-global-mcp` | Hosted Fabric global KQL endpoint — workspace + database IDs passed per tool call. |
| `warehouse-global-mcp` | Hosted Fabric global Warehouse SQL endpoint — workspace + item IDs passed per tool call. |
| `eventhouse-remote-mcp` | Fabric Eventhouse remote MCP pre-scoped to one KQL database via `<WorkspaceId>` / `<KqlDatabaseId>`. |
| `warehouse-remote-mcp` | Fabric Warehouse remote MCP pre-scoped to one warehouse via `<WorkspaceId>` / `<WarehouseId>`. |
| `activator-remote-mcp` | Fabric Activator remote MCP pre-scoped to one reflex via `<WorkspaceId>` / `<ActivatorId>`. Tools cover rule creation (`create_rule`, `list_rules`, `start_rule`, `stop_rule`). |

> ⚠ **Agent Host forwarding**: none of these servers use `${input:...}` interactive variables, so a Copilot CLI / Agent Host session picks them up via VS Code's automatic forwarding — no separate Agent-Host-side config needed. See the note at the top of this file if you add a server that *does* need interactive input.

---

## Customizing the templates

JSON files don't support comments, so substitution instructions live
here.

### `<USER>` placeholder (global template)

[.mcp.global.template.json](.mcp.global.template.json) contains literal
`<USER>` strings inside the `LOCALAPPDATA` env-var paths for the three
Docker MCP Gateway servers (`github-mcp`, `azure-mcp`, `dockerhub-mcp`).
Replace each occurrence with your **Windows profile name** before
merging the template into `~/.claude.json`.

To see the value:

```powershell
# PowerShell
$env:USERNAME
```

```bash
# Git Bash
echo "$USER"
```

Example: if `$env:USERNAME` is `Warren`, then
`C:\\Users\\<USER>\\AppData\\Local` becomes
`C:\\Users\\Warren\\AppData\\Local`.

The entire `env` block (`LOCALAPPDATA`, `ProgramData`, `ProgramFiles`)
is **Windows-specific** — it tells the gateway process where to find
Docker Desktop's per-user state on Windows. On Linux / macOS, Docker
Desktop resolves these from the OS, so omit the `env` block entirely.
The `cmd /c npx ...` wrapper for the stdio servers is also Windows-
specific and should be replaced with a direct `npx` invocation on
Linux / macOS — but the Docker gateway servers themselves still won't
run via this template without further adjustment, so don't expect to
copy `.mcp.global.template.json` verbatim outside Windows.

### Project-template placeholders

See the [Install (project scope)](#install-project-scope) table above
for the `.mcp.project.template.json` placeholders
(`<ABSOLUTE_PATH_TO_REPO>`, `<your-sql-server>`, `<your-database>`,
`<OrgName>`, `<ProjectName>`, `<WorkspaceId>`, `<KqlDatabaseId>`,
`<ActivatorId>`).

### Workspace-template placeholders

See the [Install (workspace scope)](#install-workspace-scope) table
above for the `.vscode-mcp.template.json` placeholders (`<WorkspaceId>`,
`<KqlDatabaseId>`, `<WarehouseId>`, `<ActivatorId>`) — the same four
values as the project template if the two files happen to target the
same workspace.

---

## Verifying the setup

```bash
# List every MCP server Claude Code currently sees, grouped by scope
claude mcp list

# Show details for one server (config source, status, last error)
claude mcp get <name>
```

A server appearing under the wrong scope is almost always a sign it landed in `projects.<path>.mcpServers` instead of top-level `mcpServers`.

For VS Code / GitHub Copilot, there's no CLI equivalent for the workspace file itself — use the **MCP: List Servers** command from the Command Palette (shows status and lets you view logs per server), or **MCP: Reset Trust** if a server was previously declined. From the GitHub Copilot CLI specifically:

```bash
# List servers the CLI's own user + workspace config surfaces see
# (does not include VS Code-forwarded or gallery-installed servers)
copilot mcp list
```
