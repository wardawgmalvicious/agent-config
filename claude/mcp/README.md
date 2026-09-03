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

The Fabric and Power BI servers sit in the project template for exactly this reason. They dominate this collection by count, which makes them feel foundational, but each one is inert without the thing it binds to — a Fabric server without a workspace, and `powerbi-modeling-mcp` without a semantic model to connect to. Keeping them at user scope means every session everywhere carries tools that cannot fire. This repo is the standing example: it is markdown, PowerShell, and Python, and its own [.mcp.json](../../.mcp.json) lists two servers.

**`powerbi-modeling-mcp`'s binding is broader than "Power BI Desktop is open", and this file used to say otherwise.** Upstream names three connection targets — a model open in **Power BI Desktop**, a semantic model in a **Fabric workspace**, or the **TMDL folder inside a PBIP** on disk. The third needs no Desktop and no capacity, which is the one that matters here: it makes the server usable against a repo's committed `definition/` files. That *strengthens* the project-scope call rather than weakening it — a PBIP folder is about as workload-bound as a path gets — but the old reasoning was wrong about why.

---

## Global template — user scope

[.mcp.global.template.json](.mcp.global.template.json) is the set of MCP servers that should be available in **every** Claude Code session on this machine. It is not tied to any single repo.

### Prerequisites (user scope)

- **Hosted http endpoints** (`microsoft-learn-mcp`) need no local runtime and no credential.
- **Docker MCP Gateway servers** (`azure-mcp`, `dockerhub-mcp`) need [Docker Desktop](https://www.docker.com/products/docker-desktop/) **with the MCP Toolkit extension installed and the relevant gateway servers enabled**. Browse, install, and toggle gateway servers from the Docker Desktop **MCP Toolkit** view. When Docker Desktop isn't running these fail to connect, and Claude Code reports it at session start.

Each Docker entry passes three Windows env vars (`LOCALAPPDATA`, `ProgramData`, `ProgramFiles`) so the gateway process can resolve Docker's per-user state. Replace `<USER>` with your Windows username before merging. On macOS / Linux, omit the `env` block (Docker Desktop resolves these from the OS).

> **`github-mcp` is not here.** It is in the project template instead, because on a machine with more than one GitHub account the token *is* workload-bound — see [GitHub and multiple accounts](#github-and-multiple-accounts) below.

### Install (user scope)

Merge the `mcpServers` object from the template into the **top level** of `~/.claude.json` (on Windows: `C:\Users\<you>\.claude.json`):

```jsonc
{
    // ...existing top-level fields...
    "mcpServers": {
        "microsoft-learn-mcp": { /* from template */ },
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
| `azure-mcp` | stdio (Docker MCP Gateway → `azure`) | Azure control-plane: ARM resources, Key Vault, Cosmos, SQL, Storage, Monitor, Functions, Bicep, etc. |
| `dockerhub-mcp` | stdio (Docker MCP Gateway → `dockerhub`) | Docker Hub repos, tags, namespaces, search; useful for image discovery and registry housekeeping. The most droppable entry here — keep it only if you actually manage images. |

---

## Project template — project scope

[.mcp.project.template.json](.mcp.project.template.json) is the starter set for servers bound to a specific workload. Copy it to the repo root as `.mcp.json` and commit it — every collaborator who opens the repo in Claude Code gets the same MCP tools.

Treat it as a menu, not a manifest. Almost no repo wants all seven: a Power BI repo wants `powerbi-modeling-mcp`, a Fabric repo wants `microsoft-fabric-mcp` and maybe `fabric-rti-mcp`, an application repo wants `sql-mcp` and `azure-devops-mcp`. Delete the rest.

### Prerequisites (project scope)

Three runtimes, needed only for the servers you keep:

- **`npx`-based stdio servers** (`powerbi-modeling-mcp`, `microsoft-fabric-mcp`, `azure-devops-mcp`) need [Node.js](https://nodejs.org/) on `PATH` — **20.0+** for `powerbi-modeling-mcp`, which is the only one upstream pins a floor for. The `cmd /c npx ...` wrapper is the Windows-friendly invocation; on macOS / Linux drop `"cmd", "/c"` and invoke `npx` directly.
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
    | `<GITHUB_PAT_VAR>` | Name of the environment variable holding this repo's GitHub token — see below. Note this is a variable *name*, not the token. |

3. Commit `.mcp.json` to version control.

4. The **first time** Claude Code launches inside the repo it will prompt for approval before connecting to any server listed in `.mcp.json`. This is a deliberate security check — reset those choices with:

    ```bash
    claude mcp reset-project-choices
    ```

Pair the file with a `.claude/settings.json` in the same repo that pre-approves the specific tools you don't want prompts for. `.mcp.json` declares which servers exist; `settings.json` says which of their tools are safe to run unattended. This repo does exactly that for the two read-only Microsoft Learn tools.

### Servers (project scope)

| Server | Runtime | Purpose |
| --- | --- | --- |
| `github-mcp` | http (`api.githubcopilot.com/mcp/`) | GitHub repos, issues, PRs, releases, code search. Bearer-token auth; no local runtime, so it needs no Docker Desktop. Replace `<GITHUB_PAT_VAR>` with the env var holding the token for *this* repo's account. |
| `powerbi-modeling-mcp` | stdio (`npx @microsoft/powerbi-modeling-mcp`) | Semantic-model authoring over TOM — tables, columns, measures, relationships, partitions, calculation groups, RLS roles, translations, plus DAX execution and validation. Connects to a model in **Power BI Desktop**, a **Fabric workspace**, or a **PBIP TMDL folder** on disk. It **writes** — see [below](#powerbi-modeling-mcp-is-a-write-tool). |
| `microsoft-fabric-mcp` | stdio (`npx @microsoft/fabric-mcp ... --mode all`) | Fabric core + OneLake + docs: create items, list workspaces/tables, read Fabric docs, best practices. The working Claude Code alternative to the DCR-blocked hosted Fabric Core endpoint. |
| `fabric-rti-mcp` | stdio (`uvx microsoft-fabric-rti-mcp`) | Local Real-Time Intelligence server — KQL queries against Fabric Eventhouse + ADX, Eventstream / Activator / Map management. Covers most RTI workflows without the hosted KQL endpoints, which don't connect from Claude Code. |
| `fabric-data-factory-mcp` | stdio (`dnx Microsoft.DataFactory.MCP --prerelease`) | Fabric Data Factory control plane: gateways, connections, workspaces, dataflows, pipelines, copy jobs, Apache Airflow jobs, capacities. NuGet-distributed; currently `0.x-beta` (hence `--prerelease`). |
| `sql-mcp` | stdio (`dab start --mcp-stdio`) | Data API Builder exposing the repo's Azure SQL schema as MCP tools. Uses `Active Directory Interactive` auth by default; override via the `DAB_CONNECTION_STRING` env var. |
| `azure-devops-mcp` | stdio (`npx @azure-devops/mcp`) | Azure DevOps work items, repos, pipelines scoped to the configured org + project. |

> `ASPNETCORE_URLS=http://127.0.0.1:0` forces DAB to pick a free loopback port so multiple Claude sessions or a running dev server don't collide.

---

### `powerbi-modeling-mcp` is a write tool

Several servers here write — `microsoft-fabric-mcp` creates items,
`fabric-data-factory-mcp` is a control plane. What singles this one out is
**what it writes to and how hard that is to undo**: it edits a semantic
model in place through TOM, so a bad batch is not a resource you delete
and recreate but a model whose measures and relationships have moved.
`--readwrite` is the documented default and the template passes no flag to
change it.

**Back the model up first.** Upstream says so in a warning box, not a
footnote: an LLM driving TOM can make unintended changes, and there is no
undo. Bulk operations are the selling point and therefore also the risk —
batch renames run across hundreds of objects inside one transaction.

**Two flags change the risk profile, and neither is set here.**

| Flag | Effect |
| --- | --- |
| `--readonly` | Safe mode — blocks every write. The right default for an *audit* repo that only reads the model. |
| `--skipconfirmation` | Approves all writes with no prompt. Only with backups and a known-good operation. |

**The confirmation prompt works from Claude Code**, which was worth
checking rather than assuming — the server gates the first write and the
first query behind the [MCP elicitation
protocol](https://modelcontextprotocol.io/specification/2025-06-18/client/elicitation),
and a client that doesn't implement it would fail or hang exactly where a
`--skipconfirmation` workaround looks tempting. Claude Code **2.1.252
does** implement it: the bundle registers an `elicitation/create` request
handler with both `form` and `url` modes. So leave the confirmations on.
This is *not* the DCR situation that blocks the hosted Fabric endpoints —
different protocol, different answer.

Two access facts that are easy to attribute to the wrong layer:

- **Write permission on the semantic model is required** — read access
  is not enough, and this is a Power BI permission, not an MCP one.
- **There is no tenant admin switch for this server.** It connects over
  the **XMLA endpoint**, so the only way to block it is to disable XMLA
  — which also blocks Tabular Editor, DAX Studio, and every other
  external tool. Don't propose it as a targeted control.

For unattended use, `--authmode=serviceprincipal` plus `AZURE_CLIENT_ID`,
`AZURE_TENANT_ID` and a secret or certificate replaces the interactive
login; `PBI_MODELING_MCP_ACCESS_TOKEN` supplies a token directly.

Both Power BI MCP servers are **Public Preview**, and upstream says the
implementation may change significantly before GA. The flags, env vars and
connection targets above are read from
[`microsoft/powerbi-modeling-mcp`](https://github.com/microsoft/powerbi-modeling-mcp)'s
README, **not** from Learn — the Learn overview links out to it rather
than restating it, so a `drift-audit` run over the `powerbi` What's New
source will not see a flag rename. Verified 2026-09-03 against that
README and the Learn [MCP servers
overview](https://learn.microsoft.com/power-bi/developer/mcp/mcp-servers-overview);
re-read the repo README when the server goes GA.

---

### GitHub and multiple accounts

GitHub's hosted server is reached at `https://api.githubcopilot.com/mcp/`. Claude Code **cannot** complete its OAuth flow — the same Dynamic Client Registration gap that blocks the Fabric endpoints, reported as `Incompatible auth server: does not support dynamic client registration`. A bearer token sidesteps the flow entirely and the server accepts it, so the template sends one:

```json
"headers": { "Authorization": "Bearer ${<GITHUB_PAT_VAR>}" }
```

This entry is **project scope, not user scope**, and on a single-account machine that looks like overkill. It isn't, as soon as there are two accounts. The token decides which identity every GitHub tool call runs as, so the server becomes workload-bound by the same test the rest of this file applies — a work token is the wrong tool in a personal repo, and nothing about the failure is loud.

So give each account its own variable and let each repo name the one it needs:

| Repo location | Variable | Account |
| --- | --- | --- |
| personal repos | `GITHUB_PAT_PERSONAL` | personal |
| work repos | `GITHUB_PAT_<ORG>` | work |

**Deliberately do not define a bare `GITHUB_PAT`.** An undefined variable fails visibly at session start; a default silently authenticates as the wrong account and the mistake surfaces later, attributed to the wrong identity. This mirrors the `user.useConfigOnly = true` reasoning in a two-identity `.gitconfig`: on a machine with two identities, a wrong default is worse than no default.

Set them as Windows **user** environment variables, without putting the token into shell history:

```powershell
$t = Read-Host 'Personal GitHub PAT' -AsSecureString
[Environment]::SetEnvironmentVariable('GITHUB_PAT_PERSONAL',
    [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($t)), 'User')
```

Then **fully restart VS Code** — processes inherit the environment when they spawn, so a reload window is not enough.

Prefer a real PAT (classic or fine-grained) over `gh auth token`: the `gho_` token the `gh` CLI holds is rotated, so a value copied out of it goes stale. Scope it to what the MCP tools actually need — `repo` and `read:org` cover issues, PRs, and code search.

If you would rather not manage tokens, the Docker MCP Gateway's `github-official` server reuses your local `gh` credentials instead. It works, and it is what this repo used before, but it makes GitHub access depend on Docker Desktop and it authenticates as whichever single account `gh` is currently logged into — which is the multi-account problem again, just less visible.

---

## Customizing the templates

JSON files don't support comments, so substitution instructions live here.

### `<USER>` placeholder (global template)

[.mcp.global.template.json](.mcp.global.template.json) contains literal `<USER>` strings inside the `LOCALAPPDATA` env-var paths for the two Docker MCP Gateway servers (`azure-mcp`, `dockerhub-mcp`). Replace each occurrence with your **Windows profile name** before merging the template into `~/.claude.json`.

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

### Per-server timeout — deliberately absent

Neither template sets a timeout. Two upstream sources disagree about the field and only one is right:

- **`timeout`** (milliseconds) is the real key. It is accepted on every transport and is what `claude mcp get <name>` echoes back as `Timeout:`.
- **`request_timeout_ms`** — named in the 2.1.206 changelog — is an internal remote-transport hint, declared in the bundle as `@internal CCR backend wire hint; folded into timeout at parse`. On an `http` / `sse` / `ws` server it folds into `timeout`, capped at 300000 ms. On a **stdio** server it is not in the schema at all and is **silently dropped**. Never put it in a template.

`timeout` is left out too, because the default is not 60 seconds. Claude Code overrides the MCP SDK's 60s default with `timeout ?? MCP_TOOL_TIMEOUT ?? 1e8` — roughly **27.8 hours** — so the docker-gateway servers' container start has no deadline worth raising. What does bite is unrelated and unreachable from here: a call running past `CLAUDE_CODE_MCP_AUTO_BACKGROUND_MS` (default 120000) moves to a background task without being aborted, and no `timeout` value changes that.

Verified against Claude Code **2.1.251** (2026-08-31) by reading the shipped config schema and round-tripping a scratch `.mcp.json` through `claude mcp get`. Re-check on a major version bump.

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
