# Handoff: add the ontology agent as a consumption path

- **Audit run**: 2026-10-06
- **Source**: `fabric-iq-ontology`
- **Window**: floor `2026-09-02` (diff base `f78e4a0e`, 2026-08-31) →
  head `135b0dc1` (2026-10-05)
- **Covers recommended actions**: 7
- **Kind**: additive documentation in one skill, its reference table and
  its trigger `description`. The `description` edit needs an activation
  retest.
- **Target**: `skills/fabric/fabric-ontology/SKILL.md` (line 3; lines
  178–181), `skills/fabric/fabric-ontology/references/REFERENCE.md`
  (§3, lines 130–147)

## The problem

`fabric-ontology` lists five ways to consume an ontology, in its body
and in its trigger `description`. Learn now lists the built-in
ontology agent first: a chat inside the item that creates, improves and
queries the ontology. Its behaviour is documented mainly on the
troubleshooting page, and none of it is in the skill.

## Evidence

`concepts-agent-integration.md`, base `f78e4a0e` → head `135b0dc1`
(`80a24c9`, +16/−6). The lead-in changed from "The following agents
currently support ontology as a source:" to:

> Ontology has a built-in ontology agent. You can also set up other
> agents to use ontology as a source:

A new first row in the comparison table:

```text
| **Ontology agent** | Chat interface inside ontology | Creating, improving, and testing queries on your ontology | Ontology users |
```

And a new section:

> The agent can help you create an ontology and import data from
> semantic models, and operate your ontology. The agent can describe
> the ontology, query the data behind it by using Data Analysis
> Expressions (DAX), Kusto Query Language (KQL), SQL, or Graph Query
> Language (GQL), and improve it as your sources evolve.

The overview at head: "Changes follow a proposal-first model so users
can review them before applying them."

`resources-troubleshooting.md` at head, § "Troubleshoot the ontology
agent", new in this window:

- **Identity and reach.** "The agent uses your identity to read
  workspace data." "Confirm that the source is in the ontology
  workspace or available there through a shortcut. The agent only
  discovers items in the workspace where the ontology is located."
- **Roles.** "Viewers can explain and query an existing ontology, but
  creating the first definition, improving the ontology, and applying
  changes require Contributor or higher permissions."
- **Modes.** "You might be in **Plan mode**, which prevents the agent
  from making changes. Switch the chat to **Act mode** and ask again."
  "If you have Viewer access, the service blocks write operations even
  when you select Act mode."
- **Uploads.** "Each file must be no larger than 5 MB." "A conversation
  can contain up to 10 attached files." "The filename must be 60
  characters or fewer and can't contain path separators, `..`, or
  control characters." "Files are scoped to the current conversation."
- **Queries.** "For Graph Query Language (GQL), the agent uses ISO GQL
  rather than openCypher."
- **Edits.** "Patches preserve stable identifiers (IDs) and minimize
  the scope of changes." A rewrite "can break downstream queries that
  depend on stable entity or relationship IDs."
- **State.** "During preview, conversation state exists only in your
  current browser session, so refreshing the page clears the chat and
  any in-progress draft. Changes already applied in Act mode remain
  part of the ontology item."

The agent's own page, `how-to-use-ontology-agent.md` (16,300 bytes at
head, added by `80a24c9`), was not fetched.

## What to change

1. **`SKILL.md:178–181`**, § "Consuming an ontology":

   > Five paths, detailed in [references/REFERENCE.md](references/REFERENCE.md):
   > Fabric **operations agent** (monitoring + actions), Fabric **data agent**
   > (conversational Q&A), **Foundry IQ** agent, **Copilot Studio** agent, and
   > **custom agents over the ontology MCP server**.

   Add the ontology agent, and say it is built in: it authors as well
   as consumes.
2. **`REFERENCE.md:134–140`**, §3's table — add the row, verbatim from
   Learn.
3. **`REFERENCE.md` §3** — a short subsection with the behaviours
   above: identity and workspace-scoped discovery, Viewer against
   Contributor, Plan and Act, the upload limits, ISO GQL, patches over
   rewrites, browser-session state.
4. **`SKILL.md:3`**, the `description`: "consuming an ontology from the
   five agent paths including its own MCP endpoint". The count
   changes.

## Constraint on the fix

- Count the paths after `fabric/04` item 7 lands. It adds Real-Time
  Dashboards as a consumer "wherever the skill lists them", so the
  number in the body and the `description` may come to seven, not
  six. Dropping the number from both is the alternative, and removes
  the coupling.
- Quote the agent's limits as Learn states them, dated: the agent is
  preview, and its own page was not drilled.
- The `description` has little room: a longer phrase there is paid for
  elsewhere in it. Brief 03's constraint has the measured budget.

## Sequencing note

Run after `fabric/04` in `docs/audits/2026-10-06/fabric/`, for the
count. Brief 05 cross-references this brief for the agent's role in
multi-model generation. The `description` retest is shared with brief
03; see its sequencing note.

## Verification

1. `grep -n -i "five\|six\|seven\|ontology agent" skills/fabric/fabric-ontology/SKILL.md skills/fabric/fabric-ontology/references/REFERENCE.md`
   — where a count remains, it matches the list, in both the body and
   the `description`.
2. Re-open https://learn.microsoft.com/fabric/iq/ontology/concepts-agent-integration
   and confirm the row.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-ontology/SKILL.md`
4. `uv run --with pyyaml scripts/skill-status.py --stale`, then retest
   per `/test-skill` or record it as owed.
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against
`fabric-iq-ontology`, floor 2026-09-02. Every quote above comes from
the on-disk diff of the integration, overview and troubleshooting
pages at pinned SHAs in the audit session.

## Execution log

- **Executed**: 2026-10-07 — applied with deferrals
- **Session**: fresh
- **Files changed**: `skills/fabric/fabric-ontology/SKILL.md`,
  `skills/fabric/fabric-ontology/references/REFERENCE.md`
- **Verification**: step 1 — the body's "Six agent paths" and
  `REFERENCE.md` §3's heading each match a six-item list; the
  `description` keeps no count; the other hits ("Seven source types",
  "five more source types", §8's "five-part tutorial") count nothing
  here. Step 2: `concepts-agent-integration` was fetched live
  (2026-10-07) and the row is verbatim. Step 3: the frontmatter lints.
  Step 4: `--stale` lists `fabric-ontology`; the retest is owed. Step 5,
  `pre-commit run --all-files`, runs once at the end of the pass.
- **Deferred**: the `description` retest that briefs 03, 04, 05 and
  this one share; this is the last of them.
- **Deviations**: at the staleness gate the quote's first line read
  "Five agent paths", not "Five paths": `fabric/04` item 7 had
  inserted "agent", the change this brief's constraint and sequencing
  note anticipate, while its other three lines and the `description`
  quote were verbatim, so the run went on. The count stays in the body
  and `REFERENCE.md` §3's heading, each beside its list, and left the
  `description`, which now reads "consuming an ontology through its
  built-in agent, other agents or its MCP endpoint": 979 of 1,024
  characters. Item 3's subsection, "The built-in ontology agent", sits
  before "The MCP endpoint" and also carries the integration page's
  summary of what the agent does; its limits are quoted from the
  troubleshooting page, fetched live the same day.
- **Needs**: a fresh session — after this pass lands and `fabric/04`'s
  last Needs line folds the TMDL layout into the `description`, the one
  `/test-skill fabric-ontology` retest every `description` edit here
  shares.
