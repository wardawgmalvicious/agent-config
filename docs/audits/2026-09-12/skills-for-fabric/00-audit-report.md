# Drift audit — skills-for-fabric, 2026-09-12

## Audit window

- Floor: 2026-08-20 (resolved from: date). Run as brief 06's deferred step 4 — the known-answer floor.
- Fetch path: github-mcp, by the entry's own strategy — one `CHANGELOG.md` patch per commit, isolated with `get_commit` file pagination (`perPage: 1, page: N`); the base file fetched **to disk over raw HTTPS** (never entered context — only `grep` counts did); vendored drift narrowed by blob/tree SHA before any patch was read. No whole-file HEAD read (D-1). Tree-SHA check run (D-3). `microsoft_docs_search` used from inside `allowed-tools` (D-8).
- Sources audited: skills-for-fabric — skipped: fabric, powerbi, vscode-agent, fabric-iq-ontology, claude-code (not in `--sources`)
- skills-for-fabric: 5 commits in window — prior `a5e82199` (2026-08-13, last commit touching the path before the floor; 44,935 bytes, sections `[Unreleased]`, 0.3.12 … 0.3.0) → head `358d4d87` (2026-09-10T14:37Z). main tip is `24cc0d29`.
  - `358d4d87` (2026-09-10 14:37Z) — web edit removing the `[Unreleased]` heading v0.3.16 re-added, `CHANGELOG.md` +0/−2, only file; patch read
  - `f1802196` (2026-09-10 14:27Z) — Release v0.3.16 branch commit, 46 files, `CHANGELOG.md` +15/−0 at position 4; also read: `mcp-setup/README.md` (+76/−150), both vendored `apm.yml` (+19 each), and the three `references/` one-liners under `sqldw-cli` and `dataflows-cli`
  - `65902bae` (2026-09-04 13:13Z) — Release v0.3.15, `CHANGELOG.md` +17/−0 at position 10; patch read
  - `99de3299` (2026-08-26 10:27Z) — Release v0.3.14, `CHANGELOG.md` +27/−0 at position 6; patch read
  - `22cafc90` (2026-08-20 08:34Z) — Release v0.3.13, `CHANGELOG.md` +18/−1 at position 3 (the −1 is `[Unreleased]`); patch read
- Vendored pair, bounded at `65902bae` (the known answer): both path checks since `2026-08-20T13:22:57Z` return `[]`; the four `powerbi-report-*` tree SHAs are identical at `b8d541c` and `65902bae` (`d160d140`, `b9fe475b`, `9b609076`, `4f847fca`). **Assertion 1 passes.**
- Vendored pair, unbounded (main): `f1802196` on both paths, and all four tree SHAs moved. Narrowed by blob SHA: `SKILL.md` (`e8dff43c` authoring, `316b1500` design), `references/` and design's `assets/` are byte-identical at `b8d541c` and main. The **only** delta is a new generated `apm.yml` in each directory (587 / 538 bytes). So the local vendored content is current through v0.3.16 by construction.
- Known-answer assertion 2, stable form: the 2026-09-10 report's clause-1 set was 13 names; 12 of them have 1–8 mentions in the base at `a5e82199` (introduced in 0.3.11/0.3.12, outside this window's sections), so this window's expected set is `{onelake-catalog-govern-cli}` minus the counterpart table. The name has 0 base mentions and none in 0.3.13/0.3.14, so clause 1 fires lexically; the table holds `fabric-catalog-governance`, so it lands in No-op. Expected ∅ candidates; observed ∅ candidates. **Passes, and proves the table was consulted.**
- Known-answer assertion 3: `databricks-migration` has 4 base mentions; its three 0.3.14 `### Added` bullets went to (d). **Passes.** The six retired names 0.3.14 cites (`spark-authoring-cli`, `eventstream-authoring-cli`, `eventhouse-consumption-cli`, `sqldb-*-cli`) all have 2–5 base mentions — no lexical false positive on a retired name.
- Price: 31 github-mcp calls (7 `list_commits`, 8 directory/file listings, 5 stats, 11 isolated patches), 1 raw HTTPS base fetch, 4 Learn searches and 1 WebFetch for drills.

## Drift / gap candidates (existing artifacts)

- **fabric-eventhouse** — hosted MCPs reachable from local Claude Code _(skills-for-fabric)_
  - Specific change: [remote-mcp.md:15](skills/fabric/fabric-eventhouse/references/remote-mcp.md#L15) says "Claude Code cannot connect to it. Every `api.fabric.microsoft.com/v1/mcp/*` endpoint requires OAuth Dynamic Client Registration that Claude Code doesn't support". Upstream 0.3.16 ships three hosted servers for local Claude Code with a `headersHelper` running `az account get-access-token --resource https://api.fabric.microsoft.com`, and Claude Code's own docs confirm the field: the helper must print a JSON object of headers, runs fresh on every connection, re-runs once on a 401/403, times out at 10 s, overrides static `headers`, and needs workspace trust at project scope. The same page documents `--client-id` / `--client-secret` for servers without DCR. The claim is falsified on two independent grounds; whether the Eventhouse `kqlEndpoint` accepts a raw Azure CLI bearer is not shown by Learn (only the data-agent endpoint documents `AzureCliCredential` for the `https://api.fabric.microsoft.com/.default` scope).
  - Reference: https://code.claude.com/docs/en/mcp#use-dynamic-headers-for-custom-authentication ; https://learn.microsoft.com/fabric/data-science/data-agent-mcp-server
  - Proposed action: minor edit, after a live probe
- **powerbi-report-authoring** — upstream adds `apm.yml` (0.3.16) _(skills-for-fabric)_
  - Specific change: the only change on the vendored path since `b8d541c`. A generated manifest (`# Generated by build/gen_apm_manifests.py`) declaring an MCP dependency on the **stdio** `powerbi-modeling-mcp` (`npx -y @microsoft/powerbi-modeling-mcp@latest --start`) — the same server [.mcp.project.template.json](claude/mcp/.mcp.project.template.json) already carries. The Local vendoring note records "v0.3.13, commit `b8d541c`".
  - Reference: none on Learn; upstream `f1802196` page 34
  - Proposed action: flag — decide whether "vendored verbatim" includes a packaging manifest Claude Code never reads, then update the vendoring note's currency line either way
- **powerbi-report-design** — upstream adds `apm.yml` (0.3.16) _(skills-for-fabric)_
  - Specific change: as above (page 35, identical dependency block).
  - Reference: none on Learn
  - Proposed action: flag — same decision, one artifact
- **fabric-cli** — `fab api` POST examples carry no `Content-Type` header _(skills-for-fabric)_
  - Specific change: upstream 0.3.13 (`activator-cli`) reports a create call failing with `UnsupportedMediaType` until `--headers "Content-Type=application/json"` was added. [SKILL.md:139](skills/fabric/fabric-cli/SKILL.md#L139) and [:155](skills/fabric/fabric-cli/SKILL.md#L155) show `fab api -X post … -i '<json>'` with no header; Learn's own `fab api` POST example passes `-H "Content-Type=application/json"`. The header is Learn-confirmed; the error string on omission is upstream's observation only, and whether current `fab` adds the header itself is unmeasured. Reached via `fabric-activator`, which carries the other three 0.3.13 fixes by token (`displayName` / `DisplayName field is required`, `fabricItemAction` / `targetItem`, `EventFieldSelector` / `IdentityPartAttribute`) and delegates `fab api` to `fabric-cli`. `fabric-cli` is not in the registry's `artifacts` list.
  - Reference: https://learn.microsoft.com/fabric/database/sql/deploy-cli
  - Proposed action: flag — measure one `fab api -X post` without `-H` against a harmless endpoint, then minor edit

## New-skill candidates

_(none)_ — the one lexical clause-1 hit in this window, `onelake-catalog-govern-cli`, was subtracted by the counterpart table.

## MCP / tooling / CLI additions

- **Hosted Fabric MCPs from local Claude Code via `headersHelper`** — 0.3.16 _(skills-for-fabric)_
  - What's new: upstream's `plugins/fabric-skills/.claude-plugin/plugin.json` at main registers `FabricIQ` (`https://api.fabric.microsoft.com/v1/mcp/fabricaihub/integrations/m365`, static header `X-VARIANTS: Fabric.Routing.PowerBIDataExploration`), `powerbi-modeling-mcp` (`…/v1/mcp/powerbi/authoring`) and `fabric-sqlendpoint` (`…/v1/mcp/dataPlane/sqlEndpoint`), all `type: http` with `headersHelper: az account get-access-token --resource https://api.fabric.microsoft.com --query "{Authorization: join(' ', ['Bearer', accessToken])}" --output json --only-show-errors`. The rewritten `mcp-setup/README.md` says the raw `.mcp.json` files are Copilot-oriented and that "some client versions fall back to OAuth when the header command fails, producing the dynamic-registration error" — which is the symptom the local rule was built on. Token audience moved from `https://analysis.windows.net/powerbi/api` (old README) to `https://api.fabric.microsoft.com`.
  - Reference: https://code.claude.com/docs/en/mcp#use-dynamic-headers-for-custom-authentication (field confirmed); Learn confirms the `fabricaihub/integrations/m365` URL pattern with "BYO Entra app, managed OAuth" at https://learn.microsoft.com/azure/foundry/agents/how-to/tools/fabric-iq — no raw-token row for that endpoint
  - Proposed action: flag → probe one endpoint with `headersHelper` from Claude Code → then rewrite the placement rule in [claude/mcp/README.md:12](claude/mcp/README.md#L12) (and :194, :225), [.vscode/README.md:60-63](.vscode/README.md#L60-L63) and drift-audit [SKILL.md:118](.claude/skills/drift-audit/SKILL.md#L118), and decide per server between `~/.claude/mcp/.mcp.project.template.json` (workload-bound: `sqlEndpoint`, `kqlEndpoint`, reflex) and the global template (cross-workload: `core`). This supersedes brief 11's question 1 — the docs answer both the pre-registered-client route and the header route.
- **`powerbi-modeling-mcp` remote at `/v1/mcp/powerbi/authoring`** — brief 10 re-check _(skills-for-fabric)_
  - What's new: still absent from Learn on 2026-09-12 — the overview chunk lists only the remote query server at `/v1/mcp/powerbi` and the local stdio modeling server; the external-clients page documents a pre-registered Entra app for Claude Desktop and ChatGPT. Upstream now ships it in the plugin `mcpServers` and the Codex config.
  - Reference: endpoint TBD — verify before template add
  - Proposed action: flag; keep off every template; re-check next audit
- **FabricIQ semantic-model endpoint** — not in any local template _(skills-for-fabric)_
  - What's new: URL pattern is on Learn (Foundry page); the `X-VARIANTS` header is not. Not carried in `.vscode/mcp.template.json`.
  - Reference: https://learn.microsoft.com/azure/foundry/agents/how-to/tools/fabric-iq
  - Proposed action: `.vscode/mcp.template.json` candidate once the header is verified; flag
- **APM single-skill install** — 0.3.16 _(skills-for-fabric)_
  - What's new: a root `apm.yml` plus `skills/<name>/apm.yml` for every skill; `apm install microsoft/skills-for-fabric --skill <name>` installs one skill. A fourth acquisition route beside vendoring, authoring and the plugin bundle the registry says "was not evaluated".
  - Reference: none on Learn; upstream README (not fetched)
  - Proposed action: registry note in `references/sources.md`

## No-op

- 0.3.16: `sqldw-cli` and `dataflows-cli` link fixes (all three `references/` patches verified +1/−1, links only); "plugin installation compatibility with older Claude Code versions".
- 0.3.15: `onelake-catalog-govern-cli` — clause-1 hit with counterpart `fabric-catalog-governance`; `sqldw-cli` Capacity Metrics / result-set caching / correlation → brief 01, executed and cold-tested (`e59e640`); `semantic-model-authoring` Prep-for-AI → brief 05, executed (`05fb3f3`), and `fabric-tmdl-api` already covers preservation; `sqldw-cli` diagnostics wording and `bigint`; `synapse-migration`.
- 0.3.14: five `databricks-migration` bullets; description rewrite, listing budget, literal tokens, merged-away references → brief 08 (queued as its own task); `sqldb-cli` query routing → brief 09 (executed); the five routing cases, including MLV under Spark; `variable-library-cli` grammar; hosted modeling for the `fabric-skills` bundle → brief 10 (re-checked above).
- 0.3.13: `git-integration-operations-cli` formatting-only diffs → brief 04 (executed); four `activator-cli` fixes — three present in `fabric-activator` by token, the fourth is the `fabric-cli` bullet above; seven `synapse-migration` bullets.
- `358d4d87`: heading-only edit.
- Vendored pair: zero clause-2 bullets in any section; the path delta is the `apm.yml` above.

## Recommended actions

1. `claude/mcp/README.md`, `.vscode/README.md`, `.claude/skills/drift-audit/SKILL.md` § 5, `skills/fabric/fabric-eventhouse/references/remote-mcp.md` — **probe** `headersHelper` against one hosted endpoint from Claude Code, then **rewrite** the OAuth-DCR placement rule and **decide** template placement per server. Closes brief 11's research question.
2. `.claude/skills/drift-audit/references/sources.md` — **add** counterpart rows `dataflows-cli` → `fabric-dataflow` (`9153d3d`, 2026-09-12) and `deployment-pipelines-authoring-cli` → `fabric-deployment-pipelines` (`529fce7`, 2026-09-12); **retire** "Two of the four accepted candidates remain unauthored"; **record** that step 5 ran at the exact floor on 2026-09-12 and passed in the stable form; **note** the base fetch can go to disk over raw HTTPS, and the APM route.
3. `docs/audits/2026-09-10/skills-for-fabric/06-…` — **stamp** deferred step 4 as run, with this result; `07-…` — **close** its deferred verification, all four candidates are authored.
4. `skills/powerbi/powerbi-report-authoring/`, `skills/powerbi/powerbi-report-design/` — **decide** `apm.yml`; **update** each vendoring note's currency line.
5. `skills/fabric/fabric-cli` — **measure** `fab api -X post` without `-H "Content-Type=application/json"`; **add** the header to the POST examples if it fails.
6. `.vscode/mcp.template.json` — **hold** FabricIQ and `/powerbi/authoring` until verified; brief 10 stays deferred.

## Next run

Pass one of these as the prior reference next time:

- skills-for-fabric head: `358d4d87` (2026-09-10T14:37Z); last release branch commit `f1802196` (v0.3.16, 2026-09-10T14:27Z) — per the entry's floor rule, a date floor should be 2026-09-11 or later
- main tip: `24cc0d29`
- Or a single date: `2026-09-12`

A SHA from any registered source's repo, or any ISO date, is accepted.
