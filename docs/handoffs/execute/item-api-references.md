---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-17
---

# Handoff: a definition, REST and MCP reference per Fabric item type

- **Written**: 2026-10-17, from the user's question whether each Fabric
  and Power BI skill should carry its items' definition shape, REST
  calls and MCP endpoint in references of their own, with Learn as the
  fallback. Measured against the payload at `4735b6b`.
- **Kind**: a pilot on one item, a stop for the user's review of its
  shape, then the same edit across the platform skills that own items.

## Why it is worth doing

Sessions in one client repo reach for this material constantly: of its
53 transcripts, 30 touch `getDefinition` or `updateDefinition`, 109
Learn REST pages were fetched, and the same definition queries recur
across sessions, up to 14 times for one, a KQL database's
`creationPayload` (2026-10-17; a resumed session may count twice). Each
lookup costs a search, a fetch and a turn, for a fact that changes
weekly at most.

**Learn is not the complete fallback for REST.**
[microsoft/fabric-rest-api-specs](https://github.com/microsoft/fabric-rest-api-specs)
holds one folder per item type, each a `swagger.json`, a
`definitions.json` and an `examples/` directory, and Learn's REST
reference is rendered from it, partly: the `dataAgent` swagger has
carried 31 operations since `49e5f16a` (2026-06-23), the staging and
published settings, data sources, schema elements, few-shots, publish
and reset, while Learn's Data Agent *Items* group lists 8 (both read
2026-10-17). `fabric-iq` measured four of the 23 by hand in a tenant on
2026-10-15, and `authoring-workflow.md` § "Settings and publish, by REST"
records that Learn documents only the publish. The spec repo commits
weekly ("Updating swagger files"; last 2026-10-13), so it doubles as a
drift source.

**Learn's definition index is incomplete too.** The item definition
overview (read 2026-10-17) lists Dataflow and KQL Dashboard twice and
omits pages that exist, Data Agent and Plan among them: enumerate from
the spec folders and search Learn per item, never from that list.

## The contract for each file

Two files per item type, in the skill that owns the item, each only
where it earns its place:

- **`<item>-api.md`**, where the item has a multi-part definition,
  operations beyond the generic set, or a measured delta. An item with
  one part, the seven generic operations and nothing measured gets a row
  in its skill's table instead.
  1. A header: the REST `type` string, the Git folder suffix, the Learn
     definition page, the spec folder, and the spec SHA and date read.
  2. Definition: the `format` values and a parts table (path, required,
     what it holds). Link Learn's property tables; never transcribe
     them. One minimal payload only where Learn's example is wrong or
     missing.
  3. **Git is not the live definition**: what `getDefinition` returns
     that the Git folder does not, as `fabric-rest-api` § "Definition
     APIs" records for reports, `.platform` and KQL databases.
  4. REST: item-specific operations only (method, path tail, what it
     does, long-running or not, on Learn or only in the spec, measured
     or not). Generic CRUD, definitions, jobs and LRO stay in
     `fabric-rest-api`.
  5. Measured deltas, each dated, and the fallback order: this file,
     then the spec's swagger and examples, then Learn.
- **`<item>-mcp.md`**, where Learn's
  [Fabric MCP servers list](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/fabric-mcp-servers-list)
  names a server for the item: hosting, endpoint template, identity and
  token scope, status, prerequisites and tenant settings, tool names as
  last seen with a date, and the rule to discover them by `tools/list`.
  How this machine wires a server stays in `claude/mcp/README.md`.

An existing file already doing one of these jobs keeps its name, since
filenames are link targets: `fabric-tmdl`'s `definition-api.md`,
`fabric-activator`'s `rest-and-errors.md` and `reflex-entities.md`,
`fabric-eventhouse`'s `programmatic-access.md` and `remote-mcp.md`,
`fabric-event-schema-set`'s `editing-from-git.md`. Each `SKILL.md`
points at its files from one *Read first* table, as `fabric-rest-api`'s
does, and links across skills by skill name, never by path: the
junctions flatten the group folders.

`fabric-rest-api`'s support matrix (§ "Definition APIs") becomes an
index, item type to owning skill, once each row's formats and parts
have a home: one fact, one home.

## Phase 1: the pilot, `fabric-iq`'s data agent

1. `references/data-agent/references/data-agent-api.md` from the spec's
   `dataAgent` folder and Learn's Data Agent definition page. Reconcile
   the folder prefixes `authoring-workflow.md` § "Where each layer
   lands" took from exports (`lakehouse-tables-`, `semantic-model-`,
   `ontology-` …) with the page's `type` enum (`lakehouse_tables`,
   `data_warehouse`, `semantic_model` …, no `ontology`): a folder
   prefix and a JSON value may both be right.
2. `data-agent-mcp.md`, taking the endpoint block and the three
   conditions from `data-agent.md` § "Consumption surfaces" and the MCP
   rows of `consumption-surfaces.md` and `authentication.md`; each
   keeps a one-line pointer.
3. `authoring-workflow.md` § "Settings and publish, by REST" keeps the
   measured behaviour and points at the new file for the operation list.
4. **Stop and show the user the two files** before any other skill.

## Phase 2: every other skill that owns items

One commit per skill. Order by the evidence above: `fabric-eventhouse`
(KQL database), `pbir-report-workflow` (Report), `fabric-variable-library`,
`fabric-tmdl` (SemanticModel, three MCP servers), `fabric-spark`
(Notebook, SparkJobDefinition, Environment, Lakehouse),
`fabric-data-pipeline`, `fabric-dataflow`, `fabric-warehouse`
(Warehouse, SQL endpoint; its MCP server has no home today),
`fabric-activator` (its § 8 moves out), `fabric-eventstream`,
`fabric-event-schema-set`, `fabric-realtime-dashboard`, `fabric-database`
(SQLDatabase), then `fabric-iq`'s ontology, graph model, graph queryset
and operations agent (its MCP server has no home today).
`fabric-rest-api` takes the Fabric Core and local Fabric MCP servers.

Out of scope: item types no skill owns, among them CopyJob, dbt job,
Airflow, GraphQL API, the mirrored types, ML model, Map, paginated
report, and the three with deferred skill briefs (Plan, Cosmos DB, User
Data Functions). The index row links the spec and Learn for each.

## Phase 3: keep them current

A `scripts/spec-ops.py` that, given a spec folder and two SHAs, lists
the operations added and removed, and with `--table` prints a phase 2
REST table, so no session transcribes a swagger by hand; its negative
cases in `tests/scripts/spec-ops/`. Whether `/drift-audit` registers the
spec repo as a source, or a session runs the script against each file's
recorded SHA, is the executor's call: the registry's shapes are
`table`, `prose` and `changelog`, none of them a swagger.

## Cost

About 25 `-api.md` and 10 `-mcp.md` files across 15 skills. The script
writes the REST tables; the judgment is in moving each skill's measured
deltas, not in Learn's content, so phase 2 suits a Sonnet subagent per
skill with the main session reviewing each diff. Every body edit owes a
retest, which `skill-status.py --stale` will list; no `description`
changes, so no activation retest.

## Re-measure before acting

```bash
git clone --depth 1 https://github.com/microsoft/fabric-rest-api-specs <scratch>/specs
grep -c '"operationId"' <scratch>/specs/dataAgent/swagger.json   # 31 on 2026-10-17
grep -n "documents only the publish" skills/fabric-ai/fabric-iq/references/data-agent/references/authoring-workflow.md
```

Then Learn's Data Agent *Items* group: if it lists the staging
operations, the spec-ahead-of-Learn argument weakens, though the
transcript evidence stands.

## Scrubbing

The usage figures come from one client repo's transcripts, counted
without reading their content into this file. No workspace, item,
tenant or client is named.
