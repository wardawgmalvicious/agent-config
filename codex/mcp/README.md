# Codex MCP notes

Codex stores MCP servers in `config.toml` under `[mcp_servers.<name>]` —
a TOML surface, unlike Claude Code's JSON (`mcpServers`) and VS Code /
Copilot's JSON (`servers`). The server catalog itself is cross-tool:
see [mcp/README.md](../../mcp/README.md) for what each server does,
its runtime prerequisites, and the Fabric-hosted endpoint caveats.

Locations:

- User scope: `~/.codex/config.toml` (or `$CODEX_HOME/config.toml`)
- Project scope: `<repo-root>/.codex/config.toml`, loaded only for
  trusted projects

`config.toml` is machine-local and home-owned by design —
`scripts/link-codex.ps1` never deploys it. Copy only the server blocks
you need from [codex-mcp.example.toml](codex-mcp.example.toml) into the
active file.

## Safety

- Do not put bearer tokens or API keys directly in TOML.
- Use `env_vars` for local stdio servers and `bearer_token_env_var` for
  HTTP servers.
- Keep project MCP config free of machine-specific absolute paths
  unless the project intentionally requires them.
- Prefer `enabled = false` in examples that require unavailable tools
  or tenant-specific setup.
- Check whether a server can perform destructive actions before
  enabling broad tool access.

## Common commands

```powershell
codex mcp --help
codex mcp list
codex mcp get <server-name>
codex mcp add <server-name> -- <stdio-server-command>
codex mcp login <server-name>
```
