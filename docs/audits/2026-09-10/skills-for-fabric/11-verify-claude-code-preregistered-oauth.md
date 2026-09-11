# Handoff: check whether a pre-registered OAuth client lets Claude Code reach Fabric-hosted MCP servers

- **Audit run**: 2026-09-10
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-06` (diff base `912e06e0`) → head `65902bae`
  (2026-09-04)
- **Covers recommended actions**: 10 (second half)
- **Kind**: **research, then a decision.** A yes would change the MCP
  placement rule in one skill and two READMEs. A live probe needs an
  Entra app registration in a real tenant, which is the user's call.
- **Target** (only after the decision):
  `.claude/skills/drift-audit/SKILL.md` line 118,
  `claude/mcp/README.md` line 12, `.vscode/README.md` lines 58–64

## The problem

This repo's MCP placement rests on one claim: Fabric-hosted
`api.fabric.microsoft.com/v1/mcp/*` servers do not work from Claude Code
because Microsoft's auth requires OAuth Dynamic Client Registration
(DCR), which Claude Code does not support. Learn now documents a route
that needs no DCR — register your own Entra app and give its client ID
to the MCP client. Learn names Claude Desktop, not Claude Code, so it
does not settle whether Claude Code can use the same route.

## Evidence

The claim as it stands, verbatim:

- `.claude/skills/drift-audit/SKILL.md` line 118 (Phase 2, MCP match):

  > The Fabric-hosted `api.fabric.microsoft.com/v1/mcp/*` endpoints do
  > not (OAuth DCR unsupported) and belong only in the VS Code workspace
  > template, `.vscode/mcp.template.json` in the agent-config repo.

- `claude/mcp/README.md` line 12:

  > The Fabric-hosted endpoints at `api.fabric.microsoft.com/v1/mcp/*`
  > do not — Microsoft's auth stack requires OAuth Dynamic Client
  > Registration (DCR) that Claude Code doesn't support, so they fail to
  > connect. They work from VS Code Copilot and the GitHub Copilot CLI,
  > which use first-party client IDs, ...

- `.vscode/README.md` lines 60–63:

  > ... the Fabric-hosted MCP endpoints that fail with OAuth Dynamic
  > Client Registration (DCR) errors from Claude Code but work fine from
  > VS Code Copilot / GitHub Copilot CLI, which use first-party client
  > IDs.

Learn, fetched 2026-09-10 —
[Register the remote Power BI MCP server with external MCP clients (preview)](https://learn.microsoft.com/power-bi/developer/mcp/remote-mcp-server-external-clients):

- Register an Entra app and add a redirect URI of type **Public
  client/native (mobile & desktop)**. For Claude Desktop that URI is
  `https://claude.ai/api/mcp/auth_callback`.
- Grant delegated **Power BI Service** permissions: `Dataset.Read.All`,
  `MLModel.Execute.All`, `Workspace.Read.All`.
- In Claude Desktop: **Settings > Connectors > Add custom connector**,
  with **Remote MCP server URL**
  `https://api.fabric.microsoft.com/v1/mcp/powerbi` and **OAuth Client
  ID** set to the app's Application (client) ID.
- The tenant setting "Users can use the Power BI Model Context Protocol
  server endpoint (preview)" must be enabled.

## What to find out

1. Whether Claude Code's MCP configuration accepts a pre-registered OAuth
   client ID for a remote HTTP server, and what redirect URI it uses. Get
   the answer from Claude Code's own documentation
   (`code.claude.com/docs/en/mcp`) or the `claude-code-guide` agent, and
   from the `claude-code` changelog, a registered drift-audit source. Do
   not assume Claude Desktop's behaviour carries over.
2. If yes, whether the same route reaches the other Fabric-hosted
   endpoints (`/v1/mcp/core` and the `dataPlane` ones) or only Power
   BI's. Learn's page covers Power BI only.
3. Only then, and only with the user's go-ahead: a live probe — an app
   registration in a tenant the user chooses, one server, one cold
   session.

## Decision — put it back to the user

- Claude Code supports it: rewrite the placement rule in all three
  files, and decide whether any Fabric-hosted server moves into a Claude
  template.
- It does not: add a dated line to `claude/mcp/README.md` saying the
  pre-registered route was checked and why it does not apply, so the
  next reader of that Learn page does not reopen the question.

## Constraint on the fix

- Learn names Claude Desktop, and Claude Desktop is not Claude Code.
  Nothing here establishes Claude Code support.
- No tenant name, app registration, client ID or account name goes into
  a committed file or commit message — organization identifiers never
  do (`claude/CLAUDE.md`, "Identity leaks through file content too").

## Verification

1. The answer to question 1 is cited to a Claude Code docs page or a
   changelog version.
2. If the rule changed:
   `grep -n 'DCR' .claude/skills/drift-audit/SKILL.md claude/mcp/README.md .vscode/README.md`
   — every hit agrees with the new answer.
3. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`
4. If anything under `claude/mcp/` changed:
   `./scripts/link-claude.ps1 -SkillGroups workflow` from `pwsh` — the
   directory deploys by copy and is not live until this runs.
5. `pre-commit run --all-files`

## Sequencing note

Split from brief 10; see the note there. If this brief lands first and
changes the rule, brief 10's placement step follows the new rule.

## Provenance

First `/drift-audit --sources skills-for-fabric` run, 2026-09-10. The
Learn page surfaced while drilling the hosted modeling endpoint, not
from an upstream bullet. It bears on a premise of the audit skill
itself, which is why the report raised it.

## Execution log

- **Executed**: 2026-09-11 — escalated
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in the session)
- **Files changed**: none
- **Verification**: none run. This is a research-then-decision brief,
  and `/drift-update` does not execute those.
- **Decision**: **queue the docs research** as a separate task. It
  answers question 1 — whether Claude Code accepts a pre-registered
  OAuth client ID for a remote HTTP server, and with what redirect URI —
  from Claude Code's own docs or changelog, then brings any change to
  the placement rule back to the user. A live probe is **not**
  pre-approved.
- **Deferred**: questions 1–3 and the decision. The three files that
  state the rule are unchanged: `.claude/skills/drift-audit/SKILL.md`
  line 118, `claude/mcp/README.md` line 12, and `.vscode/README.md`
  lines 60–63.
- **Deviations**: none.
