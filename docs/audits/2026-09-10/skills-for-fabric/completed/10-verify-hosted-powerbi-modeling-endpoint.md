# Handoff: verify the hosted Power BI modeling MCP endpoint before adding it

- **Audit run**: 2026-09-10
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-06` (diff base `912e06e0`) → head `65902bae`
  (2026-09-04)
- **Covers recommended actions**: 10 (first half)
- **Kind**: **research gate**, then at most one template entry. No
  template change unless Learn documents the endpoint.
- **Target** (if confirmed): `.vscode/mcp.template.json`,
  `.vscode/README.md`

## The problem

Upstream now points its `fabric-skills` bundle at a hosted Power BI
*modeling* MCP endpoint. Learn documents only the hosted *query* server,
which the VS Code template already carries. Adding an endpoint on the
strength of another team's config file would be inventing a transport.

## Evidence

Upstream, `CHANGELOG.md` `[0.3.14]` (`99de3299`), Changed, verbatim:

> **`semantic-model-authoring`** -- enable the `fabric-skills` bundle to
> use the hosted Power BI modeling service for semantic model authoring,
> while the `powerbi-authoring` bundle continues to support the local
> modeling server.

Upstream's root `.mcp.json` at `65902bae`, that entry verbatim:

```json
"powerbi-modeling-mcp": {
  "type": "http",
  "url": "https://api.fabric.microsoft.com/v1/mcp/powerbi/authoring",
  "tools": [
    "*"
  ]
}
```

Learn, searched 2026-09-10:

- [Overview of the Power BI MCP servers](https://learn.microsoft.com/power-bi/developer/mcp/mcp-servers-overview)
  — two servers. The remote one is Fabric-hosted, Streamable HTTP, with
  query tools; the local one is `stdio`, with metadata read/write tools.
- [Get started with remote Power BI MCP server](https://learn.microsoft.com/power-bi/developer/mcp/remote-mcp-server-get-started)
  — documents `https://api.fabric.microsoft.com/v1/mcp/powerbi`.
- No Learn result for `/v1/mcp/powerbi/authoring`.

This repo:

- `.vscode/mcp.template.json` lines 3–6 — `powerbi-remote-mcp` at
  `https://api.fabric.microsoft.com/v1/mcp/powerbi`, the documented query
  server.
- `claude/mcp/.mcp.project.template.json` lines 10–17 — the local
  `powerbi-modeling-mcp`, via `npx @microsoft/powerbi-modeling-mcp@latest`.

## What to do

1. Search Learn again — `microsoft_docs_search` for "remote Power BI
   modeling MCP authoring endpoint" — and check the overview page's
   server table for a third row.
2. If it is documented, add one entry to `.vscode/mcp.template.json`
   with Learn's name and URL, and a matching row in `.vscode/README.md`.
   Placement follows the current rule — Fabric-hosted `/v1/mcp/*`
   endpoints go in the VS Code template only — unless brief 11 has
   changed that rule by then.
3. If it is not documented, change nothing. Optionally record "not on
   Learn as of <date>" in `.vscode/README.md`.

## Constraint on the fix

- Do not carry over upstream's `"tools": ["*"]`. Upstream's own 0.3.11
  fix says Claude Code rejects a per-server `tools` key, and it is a
  Copilot CLI allow-list in any case. VS Code's `servers` schema is a
  different format again.
- Do not rename or repoint the existing `powerbi-remote-mcp` entry. It
  is the documented query server — a different thing.

## Verification

1. `jq . .vscode/mcp.template.json` parses.
2. The URL in the template matches Learn character for character.
3. `pre-commit run --all-files`

## Sequencing note

Split from brief 11 although one report action covers both. This is a
documentation check gating one template line; 11 is a capability
question about Claude Code that could change a placement rule across
three files. Different verification, different blast radius.

## Provenance

First `/drift-audit --sources skills-for-fabric` run, 2026-09-10, from a
0.3.14 bullet. The endpoint URL comes from upstream's config file, not
from documentation, which is why the report marked it "endpoint TBD —
verify before template add".

## Execution log

- **Executed**: 2026-09-11 — applied; the gate closed, so nothing changed
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in the session)
- **Files changed**: none
- **Verification**: the gate ran first. The brief's
  `microsoft_docs_search` query returned no Learn result for
  `/v1/mcp/powerbi/authoring`. The re-fetched overview page still lists
  exactly two servers: the remote query server at `/v1/mcp/powerbi` and
  the local `stdio` modeling server. There is no third row. The endpoint
  is therefore **not on Learn as of 2026-09-11**, and per "What to do"
  step 3 nothing changed. Steps 1 and 2 were run against the unchanged
  template: `jq` parses, and `powerbi-remote-mcp`'s URL matches Learn's
  exactly. Step 5 runs once at the end of the run.
- **Deferred**: re-check on a later audit. The endpoint is live in
  upstream's `.mcp.json`, so Learn may catch up. Brief 11 was escalated,
  not applied, so the placement rule this brief defers to is unchanged.
- **Deviations**: the optional dated "not on Learn" line in
  `.vscode/README.md` was not added. A README note about an endpoint the
  template does not carry would confuse more than it records, and this
  stamp holds the dated result.
