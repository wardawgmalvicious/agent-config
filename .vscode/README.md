# VS Code workspace config

The two MCP files are easy to mix up:

| File | Role |
| --- | --- |
| [mcp.json](mcp.json) | **Live.** The MCP servers VS Code / Copilot starts when *this* repo is open. |
| [mcp.template.json](mcp.template.json) | **Payload.** A starter set to copy into *other* repos as their `.vscode/mcp.json`. |

The template sits here rather than in a templates directory because this is
exactly where it deploys — copy it next to the live file and drop the
`.template` from the name.

The live file is deliberately thin. This repo is markdown, PowerShell, and
Python — it has no Fabric workspace, so it lists only Microsoft Learn. The
Fabric endpoints that used to sit here now live in the template, where they
describe repos that actually have a workspace.

The rest of the directory is ordinary workspace config, live for this repo
only:

| File | Role |
| --- | --- |
| [settings.json](settings.json) | Schema binding for `claude/settings.json`, fixture file associations, markdown link validation. |
| [tasks.json](tasks.json) | The commands from [CLAUDE.md](../CLAUDE.md#commands), in their safe form — notably `link-claude.ps1` with `-SkillGroups workflow`, never bare. |
| [extensions.json](extensions.json) | Extension recommendations matched to the file types actually in the repo. |

Everything else in `.vscode/` is gitignored; the six files above are
explicitly un-ignored in [.gitignore](../.gitignore).

Line endings are **not** configured here — [.gitattributes](../.gitattributes)
is authoritative at commit time and root [.editorconfig](../.editorconfig)
covers the editor side, so `files.eol` is deliberately absent from
[settings.json](settings.json).

## Why VS Code needs its own file at all

VS Code / GitHub Copilot uses a different MCP config surface from Claude Code:
a top-level `servers` key instead of `mcpServers`, and a **user profile**
`mcp.json` (opened via the **MCP: Open User Configuration** command, typically
populated through the Extensions view's `@mcp` gallery search rather than
hand-edited) alongside this **workspace** file. There's no template here for
the user-profile file, since it's gallery-managed rather than hand-authored.

Claude Code's own templates — user scope and project scope — are in
[claude/mcp/](../claude/mcp/README.md).

⚠ **Agent Host nuance**: a Copilot CLI / Agent Host session does not read
`.vscode/mcp.json` directly — VS Code forwards its contents to the Agent Host
automatically, *except* servers with `${input:...}` interactive variables
(which the Agent Host can't prompt for). Every server in
[mcp.template.json](mcp.template.json) is a static HTTP endpoint with no
`${input:...}` vars, so they forward fine. For servers that do need interactive
input, or for configuration that must be portable across both surfaces, use a
root-level `.mcp.json` / `.github/mcp.json` (`copilot mcp add`) or
`~/.copilot/mcp-config.json` instead — the Agent Host reads those natively.

## The template — workspace scope

[mcp.template.json](mcp.template.json) is the starter set for the Fabric-hosted
MCP endpoints that fail with OAuth Dynamic Client Registration (DCR) errors
from Claude Code but work fine from VS Code Copilot / GitHub Copilot CLI, which
use first-party client IDs. That asymmetry is the whole reason this file
exists: these servers have no working home on the Claude Code side, so they are
not carried in the Claude templates at all.

It intentionally excludes the *generic* servers (GitHub, Azure, Microsoft Docs,
the Fabric core/RTI stdio servers) — those are better installed once per
machine through VS Code's own `@mcp` Extensions gallery search at user-profile
scope than hand-authored per repo.

### Install

1. Copy the template into the target repo, from a clone of this one:

    ```bash
    mkdir -p <target>/.vscode
    cp .vscode/mcp.template.json <target>/.vscode/mcp.json
    ```

    Unlike the Claude templates, this file has no `~/.claude/...` path —
    `scripts/link-claude.ps1` junctions `claude/mcp`, not this directory, so
    copy it from the clone.

2. Drop any entries you don't need — most repos want one or two of these, not
   all seven. `powerbi-remote-mcp`, `fabric-core-remote-mcp`, `kql-global-mcp`,
   and `warehouse-global-mcp` need no placeholders and work as-is (workspace
   and item IDs are passed per tool call). The other three are pre-scoped to a
   single item and need these replaced:

    | Placeholder | Replace with |
    | --- | --- |
    | `<WorkspaceId>` | Fabric workspace ID (shared by all three pre-scoped entries). |
    | `<KqlDatabaseId>` | KQL database item ID for `eventhouse-remote-mcp`. |
    | `<WarehouseId>` | Warehouse item ID for `warehouse-remote-mcp`. |
    | `<ActivatorId>` | Activator (reflex) artifact ID for `activator-remote-mcp`. |

3. Commit the resulting `.vscode/mcp.json` — VS Code's own docs recommend
   source-controlling it specifically so a team shares one server list.

4. The **first time** VS Code starts one of these servers it shows a
   trust-confirmation dialog per server. Reset all trust decisions with the
   **MCP: Reset Trust** command from the Command Palette.

### Servers

| Server | Purpose |
| --- | --- |
| `powerbi-remote-mcp` | Hosted Fabric service for Power BI — workspace-scoped tools, IDs passed per call. |
| `fabric-core-remote-mcp` | Hosted Fabric Core MCP — natural-language workspace + item CRUD, role assignments, capacity ops. Preview as of 2026-05. |
| `kql-global-mcp` | Hosted Fabric global KQL endpoint — workspace + database IDs passed per tool call. |
| `warehouse-global-mcp` | Hosted Fabric global Warehouse SQL endpoint — workspace + item IDs passed per tool call. |
| `eventhouse-remote-mcp` | Fabric Eventhouse remote MCP pre-scoped to one KQL database via `<WorkspaceId>` / `<KqlDatabaseId>`. |
| `warehouse-remote-mcp` | Fabric Warehouse remote MCP pre-scoped to one warehouse via `<WorkspaceId>` / `<WarehouseId>`. |
| `activator-remote-mcp` | Fabric Activator remote MCP pre-scoped to one reflex via `<WorkspaceId>` / `<ActivatorId>`. Tools cover rule creation (`create_rule`, `list_rules`, `start_rule`, `stop_rule`). |

## Verifying

There's no CLI equivalent for the workspace file itself — use **MCP: List
Servers** from the Command Palette (shows status and per-server logs), or
**MCP: Reset Trust** if a server was previously declined. From the GitHub
Copilot CLI specifically:

```bash
# Servers the CLI's own user + workspace config surfaces see
# (does not include VS Code-forwarded or gallery-installed servers)
copilot mcp list
```
