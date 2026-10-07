# Handoff: update the data agent's consumption surfaces

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 7
- **Kind**: partial rewrite of a status table and one workaround
  paragraph, plus minor edits across the skill's references. Content;
  status claims about where and how an agent can be consumed.
- **Target**: `skills/fabric/fabric-data-agent/SKILL.md` (lines 21, 23,
  40, 42, 46, 69, 74, 75, 115, 117), and under `references/`:
  `consumption-surfaces.md` (9, 10, 17, 23), `authentication.md` (10,
  11)

## The problem

`fabric-data-agent` says every consumption surface beyond in-product
chat is preview, and that Copilot Studio rejects service principals. In
this window:

- The Copilot Studio tool path went GA, running as **User** or
  **Maker**.
- The MCP endpoint lost its preview label and gained long-running tasks.
- Answering from Power BI content in Microsoft 365 Copilot went GA.
- In-product visuals went GA.
- Two preview configuration controls appeared: topics and a runtime
  selector.

The skill's GQL group-by workaround also rests on a premise Learn no
longer supports.

## Evidence

**What's New rows.**

- "Fabric Data Agent integration with Microsoft Copilot Studio
  (Generally Available)", August 2026, promoted from the preview table.
- "Data-agent MCP tasks (Generally Available)".
- "Fabric data agent visualizations (Generally Available)", pairing the
  base preview row "Fabric data agent enhanced visualizations
  (Preview)".
- "Data agents return up to 1,000 rows (Preview)".
- "Data agent topics (Preview)".
- "Data agent runtime model upgrade (Preview)".
- "Fabric IQ in Microsoft 365 Copilot (Generally Available)".
- "Ontology as data-agent context (Preview)".
- The transient "Graph in Microsoft Fabric: GQL enhancements" (added by
  `80a24c9b`, deleted by `9eda27f8`).

**Learn** (agent-measured unless marked, 2026-10-06; all under
`https://learn.microsoft.com/en-us/fabric/`):

- `data-science/data-agent-microsoft-copilot-studio-tool`:
  - "This article covers the tool-based experience. In earlier releases,
    you added a Fabric data agent from the **Agents** category as a
    connected agent."
  - "**Maker** | The credentials of the person who set up the Copilot
    Studio agent."
  - The connected-agent page, `data-agent-microsoft-copilot-studio`, is
    still titled "(preview)".
- `data-science/data-agent-mcp-server` (checked in the audit session):
  - "For these cases, the data agent MCP server supports tasks."
  - "Tasks follow the `io.modelcontextprotocol/tasks` extension … Your
    client asks for the result with `tasks/get` … your client sends
    `tasks/cancel`."
  - "Clients that support the tasks extension get a task. For every
    other client, nothing changes."
  - The page title carries no "(preview)".
- `data-science/data-agent-visuals` — "Visuals currently support up to
  200 rows of data."
- `data-science/concept-data-agent` still says "At present, responses
  are capped at a maximum of 25 rows and 25 columns." The 1,000-row
  row's `aka.ms` link redirects to the visuals page, so that row is
  unconfirmed.
- `data-science/data-agent-topics` — "Topics are in preview and are
  available only for SQL data sources on the preview runtime."
- `data-science/data-agent-runtime` — "Runtime selection doesn't control
  which model the data agent uses."
- `iq/connectors/microsoft-365-copilot-overview`:
  - "Data answering from Power BI content in Microsoft 365 Copilot Chat
    is a generally available (GA) feature of Microsoft Fabric."
  - "Fabric data agents and ontologies can't answer questions in Copilot
    Chat without an explicitly published Microsoft 365 agent."
- `data-science/data-agent-ontology-sources` — "It then generates a
  source-native SQL, KQL, or DAX query, runs the query against that
  source, and presents the result."
- `graph/gql-language-guide` — "Use `GROUP BY` to group rows by shared
  values and compute aggregate functions within each group."
- `iq/ontology/how-to-create-data-agent` — "Due to a current known
  issue, data agent doesn't work with an ontology that uses semantic
  models for binding."

**The skill** (agent-measured):

- `SKILL.md:21` — "**aggregation is a known gap** — add the instruction
  `Support group by in GQL` to the agent's instructions"
- `SKILL.md:42` — "| **Foundry / Copilot Studio** (preview) | End user,
  On-Behalf-Of — **SPN not supported** | n/a |"; the same claim at
  `:23`, `:75`, `authentication.md:11` and
  `consumption-surfaces.md:17`
- `SKILL.md:40` — "| **MCP server endpoint** (preview) |"; also `:74`,
  `consumption-surfaces.md:10` ("**MCP server endpoint — preview.**"),
  `:23`, `authentication.md:10`
- `SKILL.md:115` — "agent responses are capped at 25 rows and 25
  columns"
- `SKILL.md:46` — "## The four configuration layers"; `SKILL.md:117` —
  "**LLM is fixed**: you can't change the underlying LLM."
- `SKILL.md:69` — "Beyond in-product chat (GA), every surviving surface
  is preview:"

## What to change

1. **Copilot Studio** — `SKILL.md:42, 23, 75`, `authentication.md:11`,
   `consumption-surfaces.md:17`. Split the row: the tool-based path
   (Fabric IQ Data MCP) is GA with User or Maker identity; the
   connected-agent path stays preview. Re-check "SPN not supported"
   against the tool page before keeping it.
2. **GQL group-by paragraph** — `SKILL.md:21`. Ontology is consumed as
   context and the agent generates source-native queries, so the
   instruction workaround is moot. Add the semantic-model-binding known
   issue.
3. **MCP endpoint** — `SKILL.md:40, 74`, `consumption-surfaces.md:10,
   23`, `authentication.md:10`. Drop "preview" and document tasks.
4. **M365 Copilot** — `SKILL.md:69`. Answering from Power BI content is
   GA; data agents and ontologies there still need a published
   Microsoft 365 agent.
5. **Visuals** — add them, with the 200-row limit. Keep the 25×25
   response cap at `SKILL.md:115`, and flag the 1,000-row preview as
   unconfirmed.
6. **Configuration** — `SKILL.md:46, 117`. Add topics and schema
   descriptions (SQL sources, preview runtime) and the standard/preview
   runtime selector; "LLM is fixed" still holds.

## Constraint on the fix

- Do not claim Claude Code can use MCP tasks. Whether it supports the
  `io.modelcontextprotocol/tasks` extension is unmeasured.
- Out of scope:
  - The audit flagged "Data agent feedback in Microsoft 365 Copilot"
    and "Fabric IQ data-agent and ontology answers" with a failed drill.
    That flag is not in this brief's action.
  - The source-control-status and 15,000-character instruction-limit
    discrepancies belong to brief 20's incidental checks.
  - `references/configuration-layers.md:94` is contradicted for
    semantic models; brief 16 carries that knock-on.

## Sequencing note

Brief 04 retires the same GQL group-by workaround in `fabric-ontology`
(`SKILL.md:197-200`). Keep the two descriptions consistent; whichever
runs second reads the first one's text.

## Verification

1. `grep -rn -i "preview\|SPN not supported\|Support group by in GQL\|25 rows" skills/fabric/fabric-data-agent`
   — every surviving "preview" names a surface Learn still marks
   preview, and the group-by instruction is gone or explicitly legacy.
2. Re-open the Copilot Studio tool page and the MCP server page, and
   confirm the quoted text.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-data-agent/SKILL.md`
4. If the `description` changed: `uv run --with pyyaml scripts/skill-status.py --stale`
   and retest, or stamp the retest as owed.
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01, by the IQ mapping subagent. The audit session itself checked
the MCP-tasks text on Learn. The remaining quotes are the agent's.

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: `skills/fabric/fabric-data-agent/SKILL.md`, and
  under its `references/`: `consumption-surfaces.md`,
  `authentication.md`, `status-and-retirements.md`
- **Verification**: steps 1–4 ran; step 5 runs once at the end of the
  run. Step 1: every surviving "preview" names a surface Learn still
  marks preview: the connected-agent path, M365 Copilot (Agent Store),
  the Python SDK, Foundry, SPN auth, the Creator Agent, topics and the
  preview runtime. "SPN not supported" survives only on the
  connected-agent/Foundry row; the group-by instruction survives only
  as the retired workaround; "25 rows" is kept per item 5. Step 2:
  the Copilot Studio tool page and the MCP server page were re-opened
  on 2026-10-06 and read as quoted. Step 3: lint clean, after the
  `description` was brought back under 1,024 (see Deviations). Step
  4: the `description` changed, so the routing retest is owed below.
- **Learn, re-read 2026-10-06**: the tool page (Fabric IQ Data MCP,
  User or Maker, no service-principal mode named, no preview label);
  the connected-agent page and the M365 Copilot data-agent page, both
  still "This feature is in preview"; the Fabric IQ M365 overview (GA
  for Power BI content; data agents need a published M365 agent);
  visuals (200 rows); topics and schema object descriptions (preview,
  SQL sources on the preview runtime only); the runtime page ("Runtime
  selection doesn't control which model"); and the semantic-model
  binding known issue.
- **Deferred**: the routing retest the `description` edit owes. Also
  noted, not acted on: Learn's ontology troubleshooting page still
  prescribes `Support group by in GQL`, against the data-agent page's
  source-native queries. The skill follows the brief and brief 04,
  which retired the workaround in the same words. The data-agent
  ontology page now warns of an ongoing outage: an ontology in the new
  experience may not be addable. That is `fabric-iq-ontology` brief
  10's, which adds the data agent's ontology known issues.
- **Deviations**: four. (1) Two lines outside the named ones still
  called the MCP endpoint and Copilot Studio preview, and step 1
  covers them: `consumption-surfaces.md:7` and
  `status-and-retirements.md:7`. Both were corrected. (2) The
  `description` was exactly 1,024 characters, so naming the GA
  surfaces there failed lint at 1,068. It now just drops "MCP
  endpoint" from its preview list, narrows "Copilot Studio" to its
  connected agent, and shortens "Azure AI Foundry" to "Foundry", ending
  at 1,010. (3) Item 1: the tool page names User and Maker and no
  service-principal mode, so the tool's rows say so rather than "SPN
  not supported", which stays on the connected-agent/Foundry rows. (4)
  The tool page was added to `consumption-surfaces.md`'s Learn list.
- **Needs**: a fresh session — `/test-skill fabric-data-agent`, the
  routing retest the `description` edit owes.
- **Needs**: a fresh session — `/test-skill fabric-data-agent`, the
  routing retest the `description` edit owes; and the outage warning,
  if Learn's data-agent ontology page still carries it, added to the
  ontology paragraph at `SKILL.md:21` once the `fabric-iq-ontology`
  pass has landed its brief 10, which edits that paragraph. The
  Deferred line above gives the warning to brief 10, which does not
  list it.
