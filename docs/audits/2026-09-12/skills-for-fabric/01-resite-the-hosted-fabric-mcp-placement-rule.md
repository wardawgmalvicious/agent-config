# Handoff: re-site the hosted Fabric MCP placement rule

- **Audit run**: 2026-09-12
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-20` (diff base `a5e82199`) → head `358d4d87`
  (2026-09-10T14:37Z)
- **Covers recommended actions**: 1 and 6
- **Kind**: an **investigation** that gates a prose correction in four
  files and a template decision. The prose half rests on documentation
  alone; the template half needs a live probe against a Fabric tenant,
  which is **not pre-approved** — `/drift-update` must hand D-2 and D-3
  back rather than run them. Supersedes question 1 of the 2026-09-10
  brief 11.
- **Target**: `claude/mcp/README.md` (lines 12, 194, 225),
  `.vscode/README.md` (lines 60–65),
  `.claude/skills/drift-audit/SKILL.md` (line 118),
  `skills/fabric/fabric-eventhouse/references/remote-mcp.md` (line 15),
  and — gated — `claude/mcp/.mcp.project.template.json`,
  `claude/mcp/.mcp.global.template.json`, `.vscode/mcp.template.json`

## Context

Four files in this repo state, as settled fact, that the Fabric-hosted
MCP endpoints at `api.fabric.microsoft.com/v1/mcp/*` **cannot** work
from Claude Code, because Microsoft's auth stack requires OAuth Dynamic
Client Registration and Claude Code does not support it. That rule is
load-bearing: it is why neither Claude template carries those servers,
why `.vscode/mcp.template.json` exists at all, and it is a placement
test inside `/drift-audit` itself.

The absolute form of the claim is false. Claude Code's own MCP
documentation carries two mechanisms that route around DCR, and
upstream now ships a working configuration built on one of them. What
is **not** established is the positive claim — that any specific
endpoint does connect from Claude Code on this machine. Separating
those two is the whole job here: the first is a documentation
correction, the second needs a measurement.

## Evidence

**Upstream ships hosted MCPs for local Claude Code.** `v0.3.16`
(`f1802196`, 2026-09-10T14:27Z) rewrote `mcp-setup/README.md` (+76/−150)
and retitled it *"Fabric MCP setup for local Claude Code and Codex"*.
`plugins/fabric-skills/.claude-plugin/plugin.json` at `main`
(`24cc0d29`) registers three `type: http` servers, each with the same
`headersHelper`:

| Server | URL |
| --- | --- |
| `FabricIQ` | `https://api.fabric.microsoft.com/v1/mcp/fabricaihub/integrations/m365` |
| `powerbi-modeling-mcp` | `https://api.fabric.microsoft.com/v1/mcp/powerbi/authoring` |
| `fabric-sqlendpoint` | `https://api.fabric.microsoft.com/v1/mcp/dataPlane/sqlEndpoint` |

The helper, verbatim from that file:

```text
az account get-access-token --resource https://api.fabric.microsoft.com --query "{Authorization: join(' ', ['Bearer', accessToken])}" --output json --only-show-errors
```

`FabricIQ` additionally carries a static header
`X-VARIANTS: Fabric.Routing.PowerBIDataExploration`. The token audience
moved from `https://analysis.windows.net/powerbi/api` (the old README)
to `https://api.fabric.microsoft.com`.

The rewritten README also names the exact symptom this repo's rule was
built on, verbatim:

> Some client versions fall back to OAuth when the header command fails,
> producing the dynamic-registration error. Check Azure sign-in and older
> registrations before repeating OAuth login.

So the DCR error is reachable from a *failed helper*, not only from an
unsupported flow — which makes the error's presence weak evidence for
the rule it produced here.

**Claude Code documents the field.** Fetched 2026-09-12 from
`https://code.claude.com/docs/en/mcp#use-dynamic-headers-for-custom-authentication`:

- `headersHelper` is a supported key on an `http` server.
- "The command must write a JSON object of string key-value pairs to
  stdout."
- "Claude Code runs the helper fresh on each connection, at session
  start and on reconnect" and "doesn't cache the result".
- On a tool call returning `401` or `403` it re-runs the helper,
  reconnects, and retries the call **once**.
- The command runs in a shell and is abandoned after **10 seconds**.
- "Dynamic headers override any static `headers` with the same name."
- At project and local scope the helper runs only after the workspace
  trust dialog is accepted.

The same page documents the second, independent route for servers
without DCR:

```bash
claude mcp add --transport http \
  --client-id your-client-id --client-secret --callback-port 8080 \
  my-server https://mcp.example.com/mcp
```

introduced as "Some MCP servers don't support automatic OAuth setup via
Dynamic Client Registration".

**Learn documents the pre-registered-app route for the remote Power BI
server**, which is what brief 11 was sent to check:
`https://learn.microsoft.com/power-bi/developer/mcp/remote-mcp-server-external-clients`
gives the Entra app-registration steps and a Claude Desktop walkthrough
using `https://api.fabric.microsoft.com/v1/mcp/powerbi` plus an OAuth
client ID. It names Claude **Desktop**, not Claude Code, and its
failure checklist is redirect-URI match, delegated permissions, and the
tenant setting *"Users can use the Power BI Model Context Protocol
server endpoint (preview)"*.

**What Learn does not establish.** No Learn page shows an Azure CLI
bearer being accepted by the `kqlEndpoint` or `sqlEndpoint` data-plane
endpoints. The one Fabric MCP endpoint Learn documents that way is the
**data agent** server — `https://learn.microsoft.com/fabric/data-science/data-agent-mcp-server`
shows `AzureCliCredential` against the `https://api.fabric.microsoft.com/.default`
scope. The Fabric IQ table at
`https://learn.microsoft.com/azure/foundry/agents/how-to/tools/fabric-iq`
confirms the `fabricaihub/integrations/m365` URL pattern and lists its
supported authentication as "BYO Entra app, managed OAuth" — with a
raw user or service-principal token listed for the **data agent** row
only. The `X-VARIANTS` header appears on no Learn page.

**The prior brief's file list was incomplete.** The 2026-09-10 brief 11
execution log names three files carrying the rule. A grep on 2026-09-12
found a fourth, plus two further lines in one of the three:

| File | Line | Text |
| --- | --- | --- |
| `claude/mcp/README.md` | 12 | "The Fabric-hosted endpoints … do not — Microsoft's auth stack requires OAuth Dynamic Client Registration (DCR) that Claude Code doesn't support, so they fail to connect." |
| `claude/mcp/README.md` | 194 | "This is *not* the DCR situation that blocks the hosted Fabric endpoints" |
| `claude/mcp/README.md` | 225 | "the same Dynamic Client Registration gap that blocks the Fabric endpoints" |
| `.vscode/README.md` | 60–65 | "the starter set for the Fabric-hosted MCP endpoints that fail with OAuth Dynamic Client Registration (DCR) errors from Claude Code" |
| `.claude/skills/drift-audit/SKILL.md` | 118 | "The Fabric-hosted `api.fabric.microsoft.com/v1/mcp/*` endpoints do not (OAuth DCR unsupported) and belong only in the VS Code workspace template" |
| `skills/fabric/fabric-eventhouse/references/remote-mcp.md` | 15 | "**Claude Code cannot connect to it.** Every `api.fabric.microsoft.com/v1/mcp/*` endpoint requires OAuth Dynamic Client Registration that Claude Code doesn't support" |

Find the targets by grep, not from this table or brief 11's list —
the count has already been wrong once.

## D-1 — the claim is stated as absolute and is not

**Symptom.** All six lines above assert impossibility. Two documented
mechanisms contradict that without any probe: `headersHelper`, which
supplies the `Authorization` header directly and leaves OAuth out of
the exchange, and `--client-id` / `--client-secret`, which is Claude
Code's documented answer for a server that lacks DCR.

**Cause.** The rule generalized one observed failure — a DCR error on
connect — into a property of the endpoints. Upstream's README says that
same error is also what a *failed header helper* produces, so the
observation never distinguished "unsupported flow" from "no usable
credential at the time".

**Fix.** Correct all six lines to what is actually established: these
endpoints do not connect through Claude Code's **automatic** OAuth
flow, and two documented routes exist that have not been measured here.
Keep the placement consequence for now — the templates stay as they are
until D-2 runs — but stop justifying it with an impossibility claim.

**Constraint.** Do **not** write that the endpoints work. Nothing in
this audit connected to one. The defensible statement is the negative
one plus the two named routes, each marked unmeasured and dated.

**Constraint, line 225.** That line is about GitHub's hosted server at
`api.githubcopilot.com/mcp/`, not a Fabric endpoint. Only its
cross-reference to the Fabric premise is in scope. Whether Claude Code
can now reach GitHub's server is a separate question on separate
evidence; do not rewrite that claim here.

## D-2 — the positive claim needs a probe, which is not pre-approved

**Symptom.** Nothing in this audit or in Learn shows any
`api.fabric.microsoft.com/v1/mcp/*` endpoint connecting from Claude
Code. Every template and placement decision downstream of D-1 depends
on that fact, and it is unmeasured.

**Fix.** Put the probe to the user before running it. It authenticates
against a live Fabric tenant under their identity, so it is their call.
Proposed shape, one endpoint only:

1. `az account show` first — do not assume a login either way. Both
   shell profiles skip `az account clear` when `CLAUDECODE` is set, so
   an existing `az login` survives across tool calls.
2. Check the helper alone before wiring it up:
   `az account get-access-token --resource https://api.fabric.microsoft.com --query expiresOn --output tsv`.
   Never run the full credential-producing form in chat — upstream's
   README says so explicitly, and its output is a bearer token.
3. Register `fabric-sqlendpoint` at **local** scope with the
   `headersHelper` from the Evidence block, then read `/mcp` for the
   connection state. Local scope keeps it out of every committed file
   while the question is open.
4. Record the outcome per endpoint, dated. A connect failure is as
   useful as a success and is what keeps D-1's wording honest.

**Known failure modes to record rather than retry blindly.** The helper
is abandoned at 10 seconds, and a cold `az` token acquisition can
exceed that. A `401`/`403` gets exactly one automatic retry. And a
helper that fails can itself surface as the DCR error, which is the
confusion D-1 exists to fix.

## D-3 — template placement, per server, gated on D-2

**Symptom.** If an endpoint connects, the placement question this repo
already has an answer shape for becomes live, and `/drift-audit`'s
own Phase 2 rule (SKILL.md line 118) currently forecloses it.

**Fix.** Decide per server, by the existing two-step test in that
rule — does it work from Claude Code, and is it workload-bound? —
not by transport:

| Server | Bound to | Template if it connects |
| --- | --- | --- |
| `fabric-sqlendpoint`, `kqlEndpoint`, reflex/Activator | a workspace or item id | `claude/mcp/.mcp.project.template.json` |
| `core` | nothing | `claude/mcp/.mcp.global.template.json` |

Leave `.vscode/mcp.template.json` in place either way: VS Code Copilot
reaches these servers by its own first-party client ID, and that is
unaffected by anything here.

**Knock-on.** A global-template change needs
`./scripts/link-claude.ps1 -SkillGroups workflow,social -GlobalMcp` to
reach `~/.claude.json`, which is off by default even under `-Force`.
Do not run it as a side effect of a template edit.

## D-4 — what must not be added (action 6)

**Symptom.** Two of upstream's three servers rest on facts Learn does
not carry, and a template add would encode them.

**Fix.** Hold both, whatever D-2 returns:

- `powerbi-modeling-mcp` at `/v1/mcp/powerbi/authoring` — re-checked
  2026-09-12 and still absent from Learn. The overview page lists
  exactly two Power BI servers, the remote query server at
  `/v1/mcp/powerbi` and the local stdio modeling server. This is the
  same gate the 2026-09-10 brief 10 closed on 2026-09-11; it stays
  deferred, and this is its second dated negative.
- `FabricIQ`'s `X-VARIANTS: Fabric.Routing.PowerBIDataExploration` —
  the URL pattern is on Learn, the header is not. The endpoint is not
  carried in `.vscode/mcp.template.json` either; adding it is a
  candidate only once the header is documented.

`endpoint TBD — verify before template add` is the standing verdict for
both. Record the negative with its date rather than leaving the check
to be re-derived.

## Verification

All four steps presume the user has approved D-2. If they have not,
D-1's prose correction can land alone — it needs steps 1, 4 and 5 only.

1. `grep -rn -i -E 'Dynamic Client Registration|DCR' --include='*.md' --include='*.json' . | grep -v docs/audits`
   — every surviving hit is either corrected per D-1 or is the GitHub
   line 225 cross-reference, reworded. No hit may still assert that a
   Fabric endpoint cannot work from Claude Code.
2. The probe's own result, recorded per endpoint with its date, in
   `claude/mcp/README.md`. A failure is a result.
3. `jq -e . claude/mcp/.mcp.project.template.json claude/mcp/.mcp.global.template.json .vscode/mcp.template.json`
   — all three still parse, whether or not any server was added.
4. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`
   — the line 118 edit is body-only, but the skill's `description`
   promises what it covers; confirm it still lints.
5. `pre-commit run --all-files`.

## Sequencing note

Do not bundle this with brief 02. That brief edits the same skill's
`references/sources.md` and is a content repair verified by grep; this
one is gated on a live probe against a tenant and may end up changing
nothing. Different verification, different risk. They do touch the same
skill directory, so whichever runs second should re-read the file it
edits first.

## Provenance

Surfaced by the 2026-09-12 `/drift-audit` run against
`skills-for-fabric`, floor 2026-08-20 — the known-answer window that
the 2026-09-10 brief 06 deferred. The finding was not what that run was
looking for: `v0.3.16` landed after the previous audit, and its
`mcp-setup/README.md` rewrite is what exposed the rule. The two Claude
Code mechanisms were then read from first-party docs rather than
inferred from upstream's configuration, which is why D-1 stands without
the probe. The 2026-09-10 brief 11 asked this same question and was
escalated rather than answered; its three-file list was measured short
here.
