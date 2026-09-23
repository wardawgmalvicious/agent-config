# Claude Code MCP templates

Two starter configurations for Model Context Protocol (MCP) servers in Claude Code, one per shareable scope.

| File | Scope | Destination | Shared? |
| --- | --- | --- | --- |
| [.mcp.global.template.json](.mcp.global.template.json) | **User** | `~/.claude.json` (top-level `mcpServers`) | No — per-machine |
| [.mcp.project.template.json](.mcp.project.template.json) | **Project** | `<repo-root>/.mcp.json` | Yes — committed to VCS |

Claude Code supports three MCP scopes: **user** (across every project on the machine), **project** (per-repo, shared via `.mcp.json`), and **local** (per-repo, private, stored under `projects.<path>.mcpServers` inside `~/.claude.json`). These two templates cover the scopes worth sharing; local scope is per-machine by definition and has no template.

Both templates contain **only servers that actually work from Claude Code**. The Fabric-hosted endpoints now qualify: every one probed **connects from Claude Code via `headersHelper`** — `dataPlane/sqlEndpoint`, `dataPlane/kqlEndpoint`, `core`, `powerbi`, and the workspace-bound `kqlEndpoint` and Activator reflex forms, measured 2026-09-14 on CLI 2.1.268 and carried in the templates. What fails is Claude Code's **automatic** OAuth flow, which cannot register with these endpoints because Microsoft's auth stack requires Dynamic Client Registration (DCR) that the flow doesn't perform. That is a fact about one flow, not a property of the endpoints, and the two documented routes around it are `headersHelper`, a command supplying the `Authorization` header directly, and `claude mcp add --client-id … --client-secret` for a pre-registered Entra app. Only the first has been probed here — see [The DCR error is a credential failure](#the-dcr-error-is-a-credential-failure) for what was measured and what was not. The endpoints also work from VS Code Copilot and the GitHub Copilot CLI, which use first-party client IDs, and [.vscode/mcp.template.json](../../.vscode/mcp.template.json) still carries the full set for that client — including the workspace/item-bound `sqlEndpoint`, the one variant that answered `MCP endpoint not found` for every item type tried in the tenant probed (see [.vscode/README.md](../../.vscode/README.md)). They used to be carried here as reference entries, which only produced templates whose own install instructions had to say "skip these seven." `microsoft-learn-mcp` is unaffected — different auth surface (`learn.microsoft.com/api/mcp`).

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
- **`fabric-core`** needs the Azure CLI on `PATH` and a live `az login`, and nothing else — see [The DCR error is a credential failure](#the-dcr-error-is-a-credential-failure).
- **`azure-mcp`** needs [Node.js](https://nodejs.org/) on `PATH`; `npx` fetches the package on first launch. The `cmd /c npx ...` wrapper is the Windows-friendly invocation; on macOS / Linux invoke `npx` directly.

**This template is deliberately Docker-free** (2026-09-14). `azure-mcp` used to be a Docker MCP Gateway server and `dockerhub-mcp` sat beside it; both are gone, so nothing at user scope depends on Docker Desktop running, on the MCP Toolkit extension being installed, or on gateway servers being toggled on in a UI. That last point is the reason: gateway membership is configured by clicking in Docker Desktop, which no file in this repo can express, so a machine could never be rebuilt from the repo alone. `dockerhub-mcp` was dropped outright rather than replaced — it was already documented here as the most droppable entry in the set.

The trade is that `@azure/mcp` is **prerelease** (`3.0.0-beta.43` when this landed), against a Docker gateway that was stable. Accepted deliberately; revisit if the beta proves unreliable. Measured connecting 2026-09-14.

The removal also retires the `<USER>` placeholder, which existed only inside those gateways' Windows `env` blocks. `scripts/link-claude.ps1` still performs the substitution, now gated on the placeholder actually appearing, so its `LOCALAPPDATA` warning cannot fire for a substitution that no longer happens.

> **`github-mcp` is not here.** It is in the project template instead, because on a machine with more than one GitHub account the token *is* workload-bound — see [GitHub and multiple accounts](#github-and-multiple-accounts) below.

### Install (user scope)

`scripts/link-claude.ps1 -GlobalMcp` does this, and is the maintained route:

```powershell
# Reports drift on every run; writes only with -GlobalMcp
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -GlobalMcp
```

It backs the file up, replaces the top-level `mcpServers` key, and **prunes servers this template does not declare** — leaving every other key in `~/.claude.json` untouched. Two things follow from that:

- **It is a reconciler, not a one-time install.** Docker Desktop's MCP Toolkit writes an unfiltered `MCP_DOCKER` gateway entry into `~/.claude.json` whenever it connects a client, re-exporting a whole tool surface — Azure, Docker Hub and a full GitHub set — into every session on the machine. Nothing in this template needs Docker any more, so that entry is now pure noise and the reconcile deletes it outright. It still returns whenever Docker Desktop connects a client again; re-run the linker, or disconnect Claude Code in the MCP Toolkit view to stop it at the source.
- **Prune before you're pruned.** Anything removed from user scope is gone everywhere; move a server you still want into the owning repo's `.mcp.json` *first*.

Or merge the `mcpServers` object into the **top level** of `~/.claude.json` by hand (on Windows: `C:\Users\<you>\.claude.json`):

```jsonc
{
    // ...existing top-level fields...
    "mcpServers": {
        "microsoft-learn-mcp": { /* from template */ },
        "fabric-core":         { /* from template */ },
        "azure-mcp":           { /* from template */ }
    },
    "projects": { /* ...existing per-project local-scope entries stay here... */ }
}
```

> **Don't** place these under `projects.<path>.mcpServers` — that is **local scope** (per-project, private), not user scope.

Or use the CLI, which writes to the same top-level key:

```bash
claude mcp add --scope user microsoft-learn-mcp --transport http https://learn.microsoft.com/api/mcp
claude mcp remove --scope user MCP_DOCKER
```

#### If you script an edit to `~/.claude.json` yourself

That file is Claude Code's runtime state — oauth account, project history, usage counters — not config you own, and two things about parsing it in PowerShell are silent when wrong. Both are handled in `link-claude.ps1`; reproduce them in anything else that reads it.

```powershell
$config = Get-Content "$HOME\.claude.json" -Raw |
    ConvertFrom-Json -AsHashtable -DateKind String
```

- **`-AsHashtable`** — the file accumulates project keys that differ only in drive-letter casing (`C:/Repos/...` and `c:/Repos/...`). A plain `ConvertFrom-Json` rejects that as a duplicate-key collision and *throws on a perfectly valid file*.
- **`-DateKind String`** (pwsh 7.5+) — without it, every ISO-8601 timestamp in the file is parsed into `[datetime]` and re-emitted in **local** time on write. Same instant, different bytes, so a run that changes no server still silently rewrites rate-limit caches. With both switches the round trip is semantically identical, verified by canonical diff against the live file.

And a live session rewrites this file from memory on its own schedule, so a write made while one is open can be reverted when it exits. Back up first, and confirm in a **fresh** session with `claude mcp list`.

### Servers (user scope)

| Server | Runtime | Purpose |
| --- | --- | --- |
| `microsoft-learn-mcp` | http (`learn.microsoft.com/api/mcp`) | Search and fetch official Microsoft Learn / Azure docs (`microsoft_docs_search`, `microsoft_code_sample_search`, `microsoft_docs_fetch`). Zero-dependency and useful in any repo — the clearest user-scope case in the set. |
| `fabric-core` | http (`api.fabric.microsoft.com/v1/mcp/core`) | Fabric control plane — workspaces, items, capacities. Bound to no workspace, which is what puts it at user scope. Authenticates through `headersHelper`, so it needs the Azure CLI and a live `az login`; without one it fails in **every** session on the machine. Measured connecting 2026-09-14. |
| `azure-mcp` | stdio (`npx @azure/mcp server start`) | Azure control-plane: ARM resources, Key Vault, Cosmos, SQL, Storage, Monitor, Functions, Bicep, etc. Prerelease — see [Prerequisites](#prerequisites-user-scope). |

---

## Project template — project scope

[.mcp.project.template.json](.mcp.project.template.json) is the starter set for servers bound to a specific workload. Copy it to the repo root as `.mcp.json` and commit it — every collaborator who opens the repo in Claude Code gets the same MCP tools.

Treat it as a menu, not a manifest. Almost no repo wants all eight: a Power BI repo wants `powerbi-modeling-mcp`, a Fabric repo wants `microsoft-fabric-mcp` and maybe `fabric-rti-mcp` or `fabric-sqlendpoint`, an application repo wants `sql-mcp` and `azure-devops-mcp`. Delete the rest.

### Prerequisites (project scope)

Three runtimes, needed only for the servers you keep:

- **`npx`-based stdio servers** (`powerbi-modeling-mcp`, `microsoft-fabric-mcp`, `azure-devops-mcp`) need [Node.js](https://nodejs.org/) on `PATH` — **20.0+** for `powerbi-modeling-mcp`, which is the only one upstream pins a floor for. The `cmd /c npx ...` wrapper is the Windows-friendly invocation; on macOS / Linux drop `"cmd", "/c"` and invoke `npx` directly.
- **`uvx`-based stdio servers** (`fabric-rti-mcp`) need [`uv`](https://docs.astral.sh/uv/) on `PATH` — `uvx` is the Python tool-runner shipped with `uv` (the `npx` analog for PyPI-packaged tools). The server is distributed on PyPI as `microsoft-fabric-rti-mcp` and downloaded on first launch.
- **`dnx`-based stdio servers** (`fabric-data-factory-mcp`) need the [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) on `PATH` — `dnx` is the .NET tool-runner that ships with it (the `npx` analog for NuGet-packaged tools). The server is distributed via NuGet and downloaded on first launch.

`sql-mcp` additionally needs the Data API Builder CLI (`dab`) on `PATH`.

**The four hosted `http` endpoints** — `fabric-sqlendpoint`, `fabric-kqlendpoint`, `powerbi-remote-mcp` and `activator-remote-mcp` — need no runtime, but each needs the **Azure CLI on `PATH` and a live `az login`**: the `headersHelper` shells out on every connection, and Claude Code does not cache the result. Without a login they fail with an error that reads like an unsupported auth flow or a network fault rather than a missing credential; see [The DCR error is a credential failure](#the-dcr-error-is-a-credential-failure). The tenant must also have the relevant preview enabled for the signed-in user — the Fabric MCP preview, and for `powerbi-remote-mcp` the tenant setting *"Users can use the Power BI Model Context Protocol server endpoint (preview)"*.

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
    | `<WorkspaceId>` | Fabric workspace GUID holding the Activator reflex. |
    | `<ActivatorId>` | Activator (reflex) item GUID for `activator-remote-mcp`. |

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
| `fabric-sqlendpoint` | http (`api.fabric.microsoft.com/v1/mcp/dataPlane/sqlEndpoint`) | Hosted Fabric SQL-endpoint data plane. Authenticates through `headersHelper`, not OAuth — needs a live `az login` (see [below](#the-dcr-error-is-a-credential-failure)). The workspace/item-bound form of *this* URL is the one variant measured not serving; the bare form here is what works. |
| `fabric-kqlendpoint` | http (`api.fabric.microsoft.com/v1/mcp/dataPlane/kqlEndpoint`) | Hosted Fabric KQL data plane — Eventhouse / KQL database queries. Same `headersHelper` auth. The workspace/item-bound form works too; use one in a repo's own `.mcp.json` when the target Eventhouse is fixed. |
| `powerbi-remote-mcp` | http (`api.fabric.microsoft.com/v1/mcp/powerbi`) | The remote Power BI MCP server: execute a DAX query, get a semantic-model schema, get report metadata, and generate DAX from a prompt (that last one consumes Copilot capacity — disable it in the client to avoid that). Every tool takes a **semantic model ID or report ID**, which is what makes it project scope. Queries run as the signed-in user with RLS enforced. Distinct from `powerbi-modeling-mcp` below, and from the undocumented `/v1/mcp/powerbi/authoring` URL. |
| `activator-remote-mcp` | http (`api.fabric.microsoft.com/v1/mcp/workspaces/<WorkspaceId>/reflexes/<ActivatorId>`) | Fabric Activator, pre-scoped to one reflex — rule creation and lifecycle (`create_rule`, `list_rules`, `start_rule`, `stop_rule`). The only one of these with no bare form: the ids are in the URL, so it is per-repo by construction. |
| `powerbi-modeling-mcp` | stdio (`npx @microsoft/powerbi-modeling-mcp`) | Semantic-model authoring over TOM — tables, columns, measures, relationships, partitions, calculation groups, RLS roles, translations, plus DAX execution and validation. Connects to a model in **Power BI Desktop**, a **Fabric workspace**, or a **PBIP TMDL folder** on disk. It **writes** — see [below](#powerbi-modeling-mcp-is-a-write-tool). |
| `microsoft-fabric-mcp` | stdio (`npx @microsoft/fabric-mcp ... --mode all`) | Fabric core + OneLake + docs: create items, list workspaces/tables, read Fabric docs, best practices. It used to be here as the only Claude-Code-reachable stand-in for the hosted Fabric Core endpoint; that endpoint now connects and sits at user scope as `fabric-core`, so this server is carried for its **write** surface and its OneLake and docs tools rather than as a substitute. |
| `fabric-rti-mcp` | stdio (`uvx microsoft-fabric-rti-mcp`) | Local Real-Time Intelligence server — KQL queries against Fabric Eventhouse + ADX, Eventstream / Activator / Map management. Its breadth is the reason to keep it now that `fabric-kqlendpoint` and `activator-remote-mcp` connect: those two are hosted and need only `az`, while this one also reaches ADX and Eventstream. Pick by surface, not by reachability. |
| `fabric-data-factory-mcp` | stdio (`dnx Microsoft.DataFactory.MCP --prerelease`) | Fabric Data Factory control plane: gateways, connections, workspaces, dataflows, pipelines, copy jobs, Apache Airflow jobs, capacities. NuGet-distributed; currently `0.x-beta` (hence `--prerelease`). |
| `sql-mcp` | stdio (`dab start --mcp-stdio`) | Data API Builder exposing the repo's Azure SQL schema as MCP tools. Uses `Active Directory Interactive` auth by default; override via the `DAB_CONNECTION_STRING` env var. |
| `azure-devops-mcp` | stdio (`npx @azure-devops/mcp`) | Azure DevOps work items, repos, pipelines scoped to the configured org + project. |

> `ASPNETCORE_URLS=http://127.0.0.1:0` forces DAB to pick a free loopback port so multiple Claude sessions or a running dev server don't collide.

### The DCR error is a credential failure

`Incompatible auth server: does not support dynamic client registration` is what Claude Code prints when the `headersHelper` produces no usable credential — **not** proof that the endpoint is unreachable. Measured 2026-09-14 on CLI 2.1.268, against `dataPlane/sqlEndpoint` with an `az` bearer at the `https://api.fabric.microsoft.com` audience:

| Condition | Result |
| --- | --- |
| Helper returning a live `az` token | `✔ Connected`, two independent readings |
| Same URL, helper command that fails and prints nothing | `✘ Incompatible auth server: does not support dynamic client registration` |
| Same URL and helper, `az` login cleared | the identical DCR error |

The third row was accidental — the login was wiped mid-session by an interactive shell, whose profile at the time ran `az account clear` (removed 2026-09-14, replaced by the per-tenant `AZURE_CONFIG_DIR` directories described in `claude/CLAUDE.md`) — and it is the useful one: the same configuration flips between connected and the DCR error on credential availability alone. Upstream's `skills-for-fabric` README says the same thing in prose; this is that claim measured here.

**Whether the helper emits a header at all is what selects the error text.** When it writes an `Authorization` header, Claude Code disables OAuth fallback and you get the server's own rejection; when it writes nothing, Claude Code falls back to OAuth and the failure text depends on the URL shape. Measured as a full 2x2 on 2026-09-14, one server at a time:

| Helper outcome | Bare URL | Workspace/item-bound URL |
| --- | --- | --- |
| emits nothing | `Incompatible auth server: does not support dynamic client registration` | `Error dialing <url>` |
| emits a credential the server rejects | `Server rejected the Authorization header minted by the configured headersHelper (HTTP 401)` | the same 401 text |

**So a bogus bearer is the wrong negative control** — it exercises the bottom row, which is the case that diagnoses itself. This corrects the middle row of the table above, recorded earlier that day as "helper returning a bogus bearer": a *well-formed* bogus bearer returns the 401 text on that same bare URL, so whatever produced the DCR error was the emits-nothing condition. Use a helper that cannot run (a nonexistent command) to reproduce the DCR error deliberately.

The bound-URL text is the trap, because it reads like a network or URL fault rather than an auth one. A genuinely absent endpoint is a fourth text again — `MCP endpoint not found at <host>` — which is the one that really does indicate a wrong URL. Claude Code redacts the ids out of the `Error dialing` URL it prints, so that text cannot tell you which workspace or item was dialled.

**Both URL shapes work, and every hosted endpoint probed so far connects.** Measured 2026-09-14, each against its own control: bare `dataPlane/sqlEndpoint`, bare `dataPlane/kqlEndpoint`, `core`, `powerbi`, a workspace/item-bound `kqlEndpoint` (two repeated rounds), and a workspace/reflex-bound Activator URL. The bound shape is not second-class, and nothing needs rewriting to the bare form to work from Claude Code. The one measured failure is a workspace/item-bound `dataPlane/sqlEndpoint`, which returns `MCP endpoint not found` for every item type tried in one tenant while the bound `kqlEndpoint` beside it connects — a tenant-side gap in that variant, not a credential or client problem.

**Do not batch-probe.** Registering and health-checking several servers back to back fires a `claude` process and an `az` process per step, and the helper is abandoned at 10 seconds. A run of twelve spawns produced `Error dialing` on a bound endpoint that connects reliably when probed alone — a false negative indistinguishable from a real one. Probe one server at a time, and chain its register-and-check into a single shell invocation so the working directory cannot change between them (see [the casing note](#local-scope-keys-are-case-split)).

**So diagnose the helper before believing the error.** Run it alone first — `az account get-access-token --resource https://api.fabric.microsoft.com --query expiresOn --output tsv`, which prints an expiry and never a token. Warm, it returns in 1.2–1.6 s against a **10-second** abandon threshold, so a cold acquisition can plausibly exceed it. Never run the credential-producing form in a session transcript.

**What is not measured.** The second documented route, `--client-id` / `--client-secret` against a pre-registered Entra app, is still unprobed — every result above uses `headersHelper`. Two endpoints stay out of the templates on documentation grounds rather than measurement: `powerbi/authoring` and `FabricIQ`'s `X-VARIANTS` header, neither of which Learn carries (see [`powerbi-modeling-mcp` is a write tool](#powerbi-modeling-mcp-is-a-write-tool)). Everything else named above was measured on 2026-09-14.

### The helper's login is the harness's, not the folder's

**A `headersHelper` never sees a folder-scoped tenant pin.** MCP servers
and their helpers are spawned by the Claude Code process and inherit
*its* environment, which has no `AZURE_CONFIG_DIR` — the variable the
shell profiles resolve per repo (`claude/CLAUDE.md` § "Azure CLI state
is per tenant, and pinned by folder"). So the helper's
`az account get-access-token` reads the shared `~/.azure`, the one store
nothing manages: `AzLogin` only ever writes into
`~/.azure-tenants/<name>/`. The failure is silent success — an MCP call
from a personal repo returned a **client tenant's** workspace list, with
no error.

**That is relayed, not re-verified**: one measurement, by the session
that reported it, on 2026-09-22. Two sessions here declined to reproduce
it on purpose, because confirming it means issuing a Fabric call from
the wrong folder, which is the cross-tenant call being reported.

It generalizes past Fabric. Any per-client isolation a shell profile
enforces is enforced **for shells only**; agents and MCP servers sit
outside it, and they fail by answering for the wrong tenant rather than
by erroring.

**The `env` field is not the fix** — it applies to server processes,
primarily stdio, and not to `headersHelper`. Two candidate remedies,
**neither run by anyone**:

- start Claude Code itself with `AZURE_CONFIG_DIR` set to the tenant the
  repo needs;
- set `AZURE_CONFIG_DIR` inline inside the helper command.

Measure one before relying on it.

### Local-scope keys are case-split

`~/.claude.json` keys local-scope config by working-directory path, and **the drive letter's case is not normalized**, so one repo can hold several entries — `c:/Repos/...` and `C:/Repos/...` — with different servers, different `disabledMcpServers`, and different trust state in each. Observed 2026-09-14 with three keys for one repo.

Worse, the case can differ *between tool calls inside a single session*: a registration landed under `c:/` and a health check moments later read `C:/` and reported the server missing. The VS Code extension passes a lowercase drive letter; a `claude` spawned from a shell gets the uppercase one from the OS.

Two consequences worth designing around. Chain a register-and-check into **one** shell invocation, so the directory cannot change between them. And prefer a committed `.mcp.json` over local scope wherever the config can live in the repo — project scope reads the repo file and never touches these keys, which sidesteps the split entirely.

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
This is *not* the DCR situation that blocks automatic OAuth against the
hosted Fabric endpoints — different protocol, different answer.

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

**The remote modeling endpoint stays off every template.** Upstream's
`skills-for-fabric` plugin registers `powerbi-modeling-mcp` as an `http`
server at `https://api.fabric.microsoft.com/v1/mcp/powerbi/authoring`, but
Learn does not document that endpoint — its MCP servers overview lists
exactly two Power BI servers, the remote *query* server at `/v1/mcp/powerbi`
and the local stdio modeling server above. Checked 2026-09-11 and again
2026-09-12: two dated negatives. **Keep the two URLs apart.** The query
server at `/v1/mcp/powerbi` is fully documented, connects from Claude Code,
and is in the project template as `powerbi-remote-mcp`; `/v1/mcp/powerbi/authoring`
is one path segment further on and has none of that. The standing verdict is **endpoint TBD,
verify before template add** — don't re-derive it, and don't add the server
on upstream's configuration alone. The same hold covers FabricIQ's
`X-VARIANTS: Fabric.Routing.PowerBIDataExploration` header: the
`fabricaihub/integrations/m365` URL pattern is on Learn, the header is not.

---

### GitHub and multiple accounts

GitHub's hosted server is reached at `https://api.githubcopilot.com/mcp/`. Claude Code **cannot** complete its OAuth flow — the same Dynamic Client Registration gap that blocks automatic OAuth against the Fabric endpoints, reported as `Incompatible auth server: does not support dynamic client registration`. A bearer token sidesteps the flow entirely and the server accepts it, so the template sends one:

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

They are Windows **user** environment variables, and `machine-config` provisions them — the variable is machine state, so that repo owns the name and the setter while this file keeps the rationale above. Don't restate either side in the other.

```powershell
# from C:\Repos\Personal\machine-config
.\scripts\github-pat-bootstrap.ps1
```

It prompts as a `SecureString` and writes straight to User scope, so the token never reaches shell history or a transcript; `-MigrateFrom <name>` copies one already set under a different name, and `-RemoveGeneric` clears the account-agnostic ones. The names themselves are declared in that repo's `config.psd1` (`GitHubPatVar`, `WorkGitHubPatVar`), and its `setup.ps1` reports any that do not resolve.

Then **fully restart VS Code** — processes inherit the environment when they spawn, so a reload window is not enough. This is the failure mode to know, because it reads as an auth problem rather than an environment one: with the variable absent from the *running* process, `${...}` never expands, the literal text goes out as the bearer token, and the server answers `400 ... Authorization header is badly formatted`. Hit on 2026-09-07, where the variable was correct in the registry the whole time.

Prefer a real PAT (classic or fine-grained) over `gh auth token`: the `gho_` token the `gh` CLI holds is rotated, so a value copied out of it goes stale. Scope it to what the MCP tools actually need — `repo` and `read:org` cover issues, PRs, and code search.

If you would rather not manage tokens, the Docker MCP Gateway's `github-official` server reuses your local `gh` credentials instead. It works, and it is what this repo used before, but it authenticates as whichever single account `gh` is currently logged into — the multi-account problem again, just less visible. **It is also no longer an option here**: the reasoning that moved `github-mcp` off that gateway — that it makes access depend on Docker Desktop — is now the whole template's policy, so going back would reintroduce the dependency deliberately removed on 2026-09-14.

---

## Customizing the templates

JSON files don't support comments, so substitution instructions live here.

### `<USER>` placeholder (retired 2026-09-14)

The global template no longer contains one. It existed only inside the `LOCALAPPDATA` env-var paths of the two Docker MCP Gateway servers, and both left with the Docker-free change above.

The substitution machinery stays in `scripts/link-claude.ps1` because the placeholder may return in a future template, and one hard-won detail is worth keeping with it: **it was the profile *directory* name, never the account name.** The two are identical on most machines and diverge whenever a Windows account is renamed after its profile folder is created — the case here. Because the placeholder sat inside a path, `$env:USERNAME` built `C:\Users\<account>\AppData\Local`, a directory that does not exist, and nothing reported it: the gateway started, failed to resolve its per-user state, and surfaced later as a server that would not connect. `Split-Path -Leaf $HOME` is the correct source; `basename "$USERPROFILE"` in Git Bash.

The linker's guard against a redirected AppData is now gated on the placeholder actually being present, so it cannot warn about a substitution that no longer happens.

Platform note that outlives all of that: the `cmd /c npx ...` wrapper used by `azure-mcp` here and by several project-template servers is **Windows-specific**, and should be a direct `npx` invocation on macOS / Linux.

### Project-template placeholders

See the [Install (project scope)](#install-project-scope) table above.

### Workspace-template placeholders

The VS Code / Copilot workspace template has its own placeholder table in [.vscode/README.md](../../.vscode/README.md).

### Per-server timeout — deliberately absent

Neither template sets a timeout. Two upstream sources disagree about the field and only one is right:

- **`timeout`** (milliseconds) is the real key. It is accepted on every transport and is what `claude mcp get <name>` echoes back as `Timeout:`.
- **`request_timeout_ms`** — named in the 2.1.206 changelog — is an internal remote-transport hint, declared in the bundle as `@internal CCR backend wire hint; folded into timeout at parse`. On an `http` / `sse` / `ws` server it folds into `timeout`, capped at 300000 ms. On a **stdio** server it is not in the schema at all and is **silently dropped**. Never put it in a template.

`timeout` is left out too, because the default is not 60 seconds. Claude Code overrides the MCP SDK's 60s default with `timeout ?? MCP_TOOL_TIMEOUT ?? 1e8` — roughly **27.8 hours** — so a slow stdio start, such as `npx` fetching `@azure/mcp` on first launch, has no deadline worth raising. What does bite is unrelated and unreachable from here: a call running past `CLAUDE_CODE_MCP_AUTO_BACKGROUND_MS` (default 120000) moves to a background task without being aborted, and no `timeout` value changes that.

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
