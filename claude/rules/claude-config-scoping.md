---
paths:
  - "**/.mcp.json"
  - "**/.claude/settings.json"
  - "**/.claude/settings.local.json"
  - "**/.claude.json"
  - "**/.vscode/mcp.json"
---

# Claude Code configuration: what belongs where

Applies when editing an MCP server list or a Claude Code settings file.
These are hand-edited JSON with no schema warning worth relying on, and
the recurring question is not *what* to set but *which file* — the same
server or permission is correct in one scope and a machine-wide tax in
another.

If a project-scope `.claude/rules/claude-config-scoping.md` exists, that
file supersedes this one. For server-by-server detail — runtimes,
prerequisites, placeholders — see `~/.claude/mcp/README.md`; this rule
covers placement and the silent failures around it.

## The scope table

| File | Committed? | Reaches | Put here |
| --- | --- | --- | --- |
| `~/.claude/settings.json` | no — machine-local | every session on the machine | model and effort defaults, `permissions.defaultMode`, hooks that must run everywhere |
| `~/.claude.json` → top-level `mcpServers` | no | every session on the machine | **user-scope** MCP servers only |
| `~/.claude.json` → `projects.<path>.mcpServers` | no | one repo, this machine | **local-scope** servers: private, unshared |
| `<repo>/.mcp.json` | yes | everyone who clones | servers bound to this repo's workload |
| `<repo>/.claude/settings.json` | yes | everyone who clones | permissions for this repo's tools, repo-scoped hooks |
| `<repo>/.claude/settings.local.json` | no — gitignore it | you, in this repo | personal overrides and approvals |
| `<repo>/.vscode/mcp.json` | yes | VS Code / Copilot only | the same servers in **Copilot's** schema |

Two of those pairs are easy to conflate and neither mistake is reported.
Putting a user-scope server under `projects.<path>.mcpServers` makes it
local scope — present in one repo instead of all of them. And VS Code
uses a top-level **`servers`** key where Claude Code uses `mcpServers`,
so a block copied between the two files parses fine and exposes nothing.

## The MCP scope test

The dividing line is **not** how often you use a server. It is whether a
session that has nothing to do with that workload should still pay for
it: every user-scope server loads its whole tool surface into every
session on the machine, including ones where it cannot fire.

- **User scope** — answers questions about your work in general: docs
  lookup, cloud control plane. Useful in any repo and in a scratch
  directory.
- **Project scope** — anything needing a workspace ID, a database, a
  connection string, or a running desktop application. It belongs in the
  repo that has those things.

`.mcp.json` declares which servers *exist*; `settings.json` says which of
their tools may run **unattended**. Keep that split — a permission entry
in the file that declares the server reads as a scope the server does not
have.

## `~/.claude.json` is runtime state, not payload

It sits beside `~/.claude`, not inside it, and holds the oauth account,
project history and usage counters alongside the `mcpServers` key. Treat
it as a file you reconcile one key of, never one you regenerate.

- **A live session rewrites it from memory on its own schedule**, so an
  edit made while a session is open can be silently reverted when that
  session exits. Back up first and confirm in a **fresh** session with
  `claude mcp list`.
- **Parsing it in PowerShell needs two switches, both silent when
  omitted.** `ConvertFrom-Json -AsHashtable -DateKind String`.
  `-AsHashtable` because the file accumulates project keys differing only
  in drive-letter case, which a plain `ConvertFrom-Json` rejects as a
  duplicate key — throwing on a perfectly valid file. `-DateKind String`
  (pwsh 7.5+) because otherwise every ISO-8601 timestamp is parsed to
  `[datetime]` and re-emitted in **local** time, so a run that changes no
  server still rewrites the file.
- **Docker Desktop re-adds an `MCP_DOCKER` entry** whenever its MCP
  Toolkit connects a client. It carries no `--servers` filter, so it
  re-exports the entire gateway — every tool from every enabled gateway
  server, a second time — into every session. Expect it back after a
  Docker Desktop update.

## Gotchas

- **`timeout` is the real key; `request_timeout_ms` is not.** The latter
  is an internal remote-transport hint: it folds into `timeout` on
  `http`/`sse`/`ws`, and on a **stdio** server it is not in the schema at
  all and is dropped without a word.
- **Never write a token into either file.** Reference an environment
  variable — `"Authorization": "Bearer ${SOME_PAT_VAR}"` — and give each
  account its own variable name. Do **not** define a bare generic
  fallback: an undefined variable fails loudly at session start, while a
  default silently authenticates as the wrong account and the mistake
  surfaces later, attributed to the wrong identity. Same reasoning as
  `user.useConfigOnly` in a two-identity git setup.
- **Env vars are inherited at process spawn.** After setting one, fully
  restart the editor — a reload window is not enough. With the variable
  absent from the *running* process, `${...}` never expands and the
  literal text is sent as the bearer token, which comes back as
  `400 ... Authorization header is badly formatted` and reads as an auth
  problem rather than an environment one.
- **JSON has no comments, so the rationale has to live somewhere else.**
  Keep it in a README beside the file rather than in a key nothing reads.
  A placeholder in a committed template needs its substitution documented
  or it ships as a literal.
- **A first launch prompts for approval** of every server in a repo's
  `.mcp.json`. That is a deliberate security check, not a bug to design
  around; reset the answers with `claude mcp reset-project-choices`.
