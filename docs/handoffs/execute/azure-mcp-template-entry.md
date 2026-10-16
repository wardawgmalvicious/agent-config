---
status: open
priority: 3
needs: [user]
blocked-by: []
written: 2026-10-15
---

# Handoff: pin `azure-mcp`'s credential, and maybe its version, in the project template

- **Written**: 2026-10-15, from one inbox note of 2026-10-13 by a
  session in a client repo that runs a Python worker on Azure Container
  Apps. Re-measured against the payload at `f8abbed`, where the template
  entry is unchanged: `@azure/mcp@latest`, no `env`, no `timeout`.
- **Kind**: a decision, the user's, since it changes an MCP config,
  `claude/mcp/.mcp.project.template.json`; then that edit and its README
  row. Nothing is drafted.

## What the origin repo runs

Its `.mcp.json` entry on 2026-10-13, uncommitted then:

```json
{
    "azure-mcp": {
        "type": "stdio",
        "command": "cmd",
        "args": ["/c", "npx", "-y", "@azure/mcp@3.0.0", "server", "start"],
        "env": { "AZURE_TOKEN_CREDENTIALS": "AzureCliCredential" },
        "timeout": 600000
    }
}
```

A session started after the edit connected, and its `subscription_list`
answered in the tenant `az account show` reported for the shared
`~/.azure`. That shows the entry starts and signs in, not which
credential answered: a VS Code Azure sign-in to the same account would
look the same.

## The three choices

- **`env.AZURE_TOKEN_CREDENTIALS` set to `AzureCliCredential`** narrows
  an Azure.Identity chain to the CLI login (Learn, "Credential chains in
  the Azure Identity library for .NET": single names from 1.15.0,
  compared case-insensitively), and Learn's SRE Agent MCP server page
  sets it to pin Azure MCP Server's credential. Without it, the chain on
  Learn's Azure MCP Server get-started pages puts a VS Code sign-in
  ahead of `az login`. `claude/rules/coding-csharp.md` already names the
  variable for .NET.
- **`@azure/mcp@3.0.0` against `@latest`.** `@latest` became `3.0.0`,
  the first stable release, at 2026-10-12 22:37 UTC (`npm view`, re-run
  2026-10-15), so it runs a stable build now anyway. A pinned spec gets
  its own npx install: the first `npx -y @azure/mcp@3.0.0` took 13 s
  although `@latest` had put the same version in the cache, so a pin
  pays that once per bump.
- **`timeout: 600000`** caps every call at ten minutes, and sets the
  idle cutoff to the same value, under the 30-minute stdio default
  (`claude/mcp/README.md` § "Per-server timeout", since 2026-10-15). It
  caps; it never extends.

One left out: `AZURE_CONFIG_DIR` in `env` would pin the tenant too, a
third candidate beside the two § "The helper's login is the harness's,
not the folder's" lists as run by no one, open to stdio servers only. It
needs a per-user path, VS Code reads `.mcp.json` too and expands no
`${VAR}`, and whether Claude Code's stripping of credential-like
variables reaches a project stdio server's environment is untested.

## Testing an edit

**An edited entry does not reach the session that made it**: that
session's server kept running the pre-edit `@latest` command line beside
a fresh session's pinned one (2026-10-13). Test from a new session;
whether `/mcp`'s reconnect picks up an edit was not tried.

## Where it lands

The template's `azure-mcp` entry, and its row in `claude/mcp/README.md`
§ "Azure and SQL", which a triage corrected for `@latest` on 2026-10-15.
Both deploy with `./scripts/link-claude.ps1 -SkillGroups
workflow,social,meta`. A repo that copied the template keeps its own
`.mcp.json` until it is changed there.

## Not checked

- Whether the credential pin keeps a VS Code sign-in out: the fresh
  session's answer fits either credential.
- `${USERPROFILE}` expansion in an `env` value.

## Scrubbing

The note was genericized at source, with no tenant, account or
subscription; its repo is cited by kind.

## Re-measure before acting

```bash
grep -n -A12 '"azure-mcp"' claude/mcp/.mcp.project.template.json   # @latest, no env, no timeout on 2026-10-15
npm view @azure/mcp dist-tags                                     # latest: '3.0.0' on 2026-10-15
```
