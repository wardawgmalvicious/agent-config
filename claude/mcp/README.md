# Claude Code MCP templates

Two starter configurations for Model Context Protocol (MCP) servers in Claude Code, one per shareable scope.

| File | Scope | Destination | Shared? |
| --- | --- | --- | --- |
| [.mcp.global.template.json](.mcp.global.template.json) | **User** | `~/.claude.json` (top-level `mcpServers`) | No — per-machine |
| [.mcp.project.template.json](.mcp.project.template.json) | **Project** | `<repo-root>/.mcp.json` | Yes — committed to VCS |

Claude Code supports three MCP scopes: **user** (across every project on the machine), **project** (per-repo, shared via `.mcp.json`), and **local** (per-repo, private, stored under `projects.<path>.mcpServers` inside `~/.claude.json`). These two templates cover the scopes worth sharing; local scope is per-machine by definition and has no template.

Both templates contain **only servers that actually work from Claude Code**. The Fabric-hosted endpoints at `api.fabric.microsoft.com/v1/mcp/*` do not — Microsoft's auth stack requires OAuth Dynamic Client Registration (DCR) that Claude Code doesn't support, so they fail to connect. They work from VS Code Copilot and the GitHub Copilot CLI, which use first-party client IDs, and they now live in the workspace template alone (see [.vscode/README.md](../../.vscode/README.md)). They used to be carried here as reference entries, which only produced templates whose own install instructions had to say "skip these seven." `microsoft-learn-mcp` is unaffected — different auth surface (`learn.microsoft.com/api/mcp`).

VS Code / GitHub Copilot also uses a different schema — a top-level `servers` key instead of `mcpServers`, and a workspace file at `.vscode/mcp.json`.

## What belongs at which scope

The dividing line is **not** how often you use a server; it is whether a session that has nothing to do with that workload should still pay for it. Every user-scope server loads its whole tool surface into every session on the machine, including sessions in repos where it can do nothing useful.

- **User scope** — servers that answer questions about *your work in general*: docs lookup, source control, cloud control plane. Useful in a Fabric repo, a config repo, and a scratch directory alike.
- **Project scope** — servers bound to a workload: anything needing a workspace ID, a database, a connection string, or a running desktop application. `.mcp.json` in the repo that has those things.

The Fabric and Power BI servers sit in the project template for exactly this reason. They dominate this collection by count, which makes them feel foundational, but a Power BI modeling server is inert unless Power BI Desktop is open with a model loaded, and a Fabric server is inert without a workspace. Keeping them at user scope means every session everywhere carries tools that cannot fire. This repo is the standing example: it is markdown, PowerShell, and Python, and its own [.mcp.json](../../.mcp.json) lists two servers.

---

## Global template — user scope

[.mcp.global.template.json](.mcp.global.template.json) is the set of MCP servers that should be available in **every** Claude Code session on this machine. It is not tied to any single repo.

### Prerequisites (user scope)

- **Hosted http endpoints** (`microsoft-learn-mcp`) need no local runtime.
- **Docker MCP Gateway servers** (`github-mcp`, `azure-mcp`, `dockerhub-mcp`) need [Docker Desktop](https://www.docker.com/products/docker-desktop/) **with the MCP Toolkit extension installed and the relevant gateway servers enabled**. Browse, install, and toggle gateway servers from the Docker Desktop **MCP Toolkit** view. When Docker Desktop isn't running these three fail to connect, and Claude Code reports it at session start.

Each Docker entry passes three Windows env vars (`LOCALAPPDATA`, `ProgramData`, `ProgramFiles`) so the gateway process can resolve Docker's per-user state. Replace `<USER>` with your Windows username before merging. On macOS / Linux, omit the `env` block (Docker Desktop resolves these from the OS).

### Install (user scope)

Merge the `mcpServers` object from the template into the **top level** of `~/.claude.json` (on Windows: `C:\Users\<you>\.claude.json`):

```jsonc
{
    // ...existing top-level fields...
    "mcpServers": {
        "microsoft-learn-mcp": { /* from template */ },
        "github-mcp":          { /* from template */ },
        "azure-mcp":           { /* from template */ },
        "dockerhub-mcp":       { /* from template */ }
    },
    "projects": { /* ...existing per-project local-scope entries stay here... */ }
}
```

> **Don't** place these under `projects.<path>.mcpServers` — that is **local scope** (per-project, private), not user scope.

Alternatively, use the CLI (writes to the same top-level `mcpServers` key):

```bash
claude mcp add --scope user microsoft-learn-mcp --transport http https://learn.microsoft.com/api/mcp
```

### Servers (user scope)

| Server | Runtime | Purpose |
| --- | --- | --- |
| `microsoft-learn-mcp` | http (`learn.microsoft.com/api/mcp`) | Search and fetch official Microsoft Learn / Azure docs (`microsoft_docs_search`, `microsoft_code_sample_search`, `microsoft_docs_fetch`). Zero-dependency and useful in any repo — the clearest user-scope case in the set. |
| `github-mcp` | stdio (Docker MCP Gateway → `github-official`) | GitHub repos, issues, PRs, releases, code search; uses your local gh / GitHub credentials via the gateway. |
| `azure-mcp` | stdio (Docker MCP Gateway → `azure`) | Azure control-plane: ARM resources, Key Vault, Cosmos, SQL, Storage, Monitor, Functions, Bicep, etc. |
| `dockerhub-mcp` | stdio (Docker MCP Gateway → `dockerhub`) | Docker Hub repos, tags, namespaces, search; useful for image discovery and registry housekeeping. The most droppable entry here — keep it only if you actually manage images. |

---

## Project template — project scope

[.mcp.project.template.json](.mcp.project.template.json) is the starter set for servers bound to a specific workload. Copy it to the repo root as `.mcp.json` and commit it — every collaborator who opens the repo in Claude Code gets the same MCP tools.

Treat it as a menu, not a manifest. Almost no repo wants all six: a Power BI repo wants `powerbi-modeling-mcp`, a Fabric repo wants `microsoft-fabric-mcp` and maybe `fabric-rti-mcp`, an application repo wants `sql-mcp` and `azure-devops-mcp`. Delete the rest.

### Prerequisites (project scope)

Three runtimes, needed only for the servers you keep:

- **`npx`-based stdio servers** (`powerbi-modeling-mcp`, `microsoft-fabric-mcp`, `azure-devops-mcp`) need [Node.js](https://nodejs.org/) on `PATH`. The `cmd /c npx ...` wrapper is the Windows-friendly invocation; on macOS / Linux drop `"cmd", "/c"` and invoke `npx` directly.
- **`uvx`-based stdio servers** (`fabric-rti-mcp`) need [`uv`](https://docs.astral.sh/uv/) on `PATH` — `uvx` is the Python tool-runner shipped with `uv` (the `npx` analog for PyPI-packaged tools). The server is distributed on PyPI as `microsoft-fabric-rti-mcp` and downloaded on first launch.
- **`dnx`-based stdio servers** (`fabric-data-factory-mcp`) need the [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) on `PATH` — `dnx` is the .NET tool-runner that ships with it (the `npx` analog for NuGet-packaged tools). The server is distributed via NuGet and downloaded on first launch.

`sql-mcp` additionally needs the Data API Builder CLI (`dab`) on `PATH`.

### Install (project scope)

1. Copy the template to the repo root:

    ```bash
    cp ~/.claude/mcp/.mcp.project.template.json ./.mcp.json
    ```

2. Delete the servers this repo has no use for, then replace the placeholders in what remains:

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

Pair the file with a `.claude/settings.json` in the same repo that pre-approves the specific tools you don't want prompts for. `.mcp.json` declares which servers exist; `settings.json` says which of their tools are safe to run unattended. This repo does exactly that for the two read-only Microsoft Learn tools.

### Servers (project scope)

| Server | Runtime | Purpose |
| --- | --- | --- |
| `powerbi-modeling-mcp` | stdio (`npx @microsoft/powerbi-modeling-mcp`) | Local Power BI Desktop / TOM operations — tables, measures, relationships, partitions, DAX query execution against an open model. Needs Power BI Desktop running with a model loaded. |
| `microsoft-fabric-mcp` | stdio (`npx @microsoft/fabric-mcp ... --mode all`) | Fabric core + OneLake + docs: create items, list workspaces/tables, read Fabric docs, best practices. The working Claude Code alternative to the DCR-blocked hosted Fabric Core endpoint. |
| `fabric-rti-mcp` | stdio (`uvx microsoft-fabric-rti-mcp`) | Local Real-Time Intelligence server — KQL queries against Fabric Eventhouse + ADX, Eventstream / Activator / Map management. Covers most RTI workflows without the hosted KQL endpoints, which don't connect from Claude Code. |
| `fabric-data-factory-mcp` | stdio (`dnx Microsoft.DataFactory.MCP --prerelease`) | Fabric Data Factory control plane: gateways, connections, workspaces, dataflows, pipelines, copy jobs, Apache Airflow jobs, capacities. NuGet-distributed; currently `0.x-beta` (hence `--prerelease`). |
| `sql-mcp` | stdio (`dab start --mcp-stdio`) | Data API Builder exposing the repo's Azure SQL schema as MCP tools. Uses `Active Directory Interactive` auth by default; override via the `DAB_CONNECTION_STRING` env var. |
| `azure-devops-mcp` | stdio (`npx @azure-devops/mcp`) | Azure DevOps work items, repos, pipelines scoped to the configured org + project. |

> `ASPNETCORE_URLS=http://127.0.0.1:0` forces DAB to pick a free loopback port so multiple Claude sessions or a running dev server don't collide.

---

## Customizing the templates

JSON files don't support comments, so substitution instructions live here.

### `<USER>` placeholder (global template)

[.mcp.global.template.json](.mcp.global.template.json) contains literal `<USER>` strings inside the `LOCALAPPDATA` env-var paths for the three Docker MCP Gateway servers (`github-mcp`, `azure-mcp`, `dockerhub-mcp`). Replace each occurrence with your **Windows profile name** before merging the template into `~/.claude.json`.

To see the value:

```powershell
# PowerShell
$env:USERNAME
```

```bash
# Git Bash
echo "$USER"
```

Example: if `$env:USERNAME` is `Warren`, then `C:\\Users\\<USER>\\AppData\\Local` becomes `C:\\Users\\Warren\\AppData\\Local`.

The entire `env` block (`LOCALAPPDATA`, `ProgramData`, `ProgramFiles`) is **Windows-specific** — it tells the gateway process where to find Docker Desktop's per-user state on Windows. On Linux / macOS, Docker Desktop resolves these from the OS, so omit the `env` block entirely. The `cmd /c npx ...` wrapper in the project template is likewise Windows-specific and should be replaced with a direct `npx` invocation elsewhere.

### Project-template placeholders

See the [Install (project scope)](#install-project-scope) table above.

### Workspace-template placeholders

The VS Code / Copilot workspace template has its own placeholder table in [.vscode/README.md](../../.vscode/README.md).

---

## Verifying the setup

```bash
# List every MCP server Claude Code currently sees, grouped by scope
claude mcp list

# Show details for one server (config source, status, last error)
claude mcp get <name>
```

A server appearing under the wrong scope is almost always a sign it landed in `projects.<path>.mcpServers` instead of top-level `mcpServers`.

Verifying the VS Code / Copilot side is a different set of commands — see [.vscode/README.md](../../.vscode/README.md).
