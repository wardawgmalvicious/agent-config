# Drift audit — fabric, 2026-10-16

## Audit window

- Floor: per source (resolved from: ledger); `fabric` read as `--sources fabric`
  - fabric: `7ff5f2b3` (2026-10-02) from `docs/audits/2026-10-06/fabric/` — the source's own repo, so it is the diff base directly
- Fetch path: clone (blobless, whole; `fabric-docs` 52 MB, git 2.55, in the session scratchpad)
- Sources audited: fabric — skipped: claude-code, fabric-iq-ontology, powerbi, skills-for-fabric, vscode-agent (narrowed by the argument)
- Microsoft Fabric (incl. RTI): 3 landings in window — prior `7ff5f2b3` (2026-10-02) → head `0cbcc6f71` (2026-10-15)
  - `0cbcc6f71` (2026-10-15) — sync merge PR #3428, carries `411863121` (2026-10-15) "Document trusted resources for Azure event delivery (#16720)", `whats-new.md` +1/-1. That commit's other six files are outside this source's path: `real-time-hub/private-links-real-time-events.md` (+90), `security/security-private-links-overview.md`, `security/security-workspace-level-private-links-support.md`, `security/security-inbound-overview.md`, a Real-Time hub include.
  - `986bfb9c9` (2026-10-03) — sync merge PR #3394; carries nothing past the base (it carried `7ff5f2b3` itself); its version is byte-identical to the base; not walked.
  - `d76beb99f` (2026-10-02) — sync merge PR #3393, the restructure landing; the base is not its ancestor and its version (147,292 bytes) predates the base's (147,892): nothing past the base; not walked. Both carry-nothing landings are the case the registry entry predicts for a base that is a carried commit.
  - Table walk: base and head keyed on disk — 303 keys each (197 preview rows, 105 GA rows), key sets identical. 0 added, 0 transient, 0 promoted, 0 removed; 1 row modified in place. Files: `~\AppData\Local\Temp\claude\c--Repos-Personal-agent-config\bcc283d7-1c06-408b-93cd-5a82061b53f7\scratchpad\work\`

## Drift / gap candidates (existing artifacts)

- **fabric-security** — Resource Instance Rules for OneLake Network Security for Azure Services (Generally Available), July 2026 _(fabric)_
  - Specific change: the row itself only retitled its Learn link ("Resource Instance rules for Inbound access" → "Manage workspace inbound access with Resource Instance Rules", same page). The landing's carried commit is the signal: Learn's private-links pages now say Azure event delivery (Azure Blob Storage events via Event Grid) under tenant private links with **Block Public Internet Access** is blocked "by default", not "entirely", and is restored by adding the Event Grid system topic to the workspace's Resource Instance Rules when topic and workspace share an Entra tenant (read from the clone, 2026-10-15). `references/REFERENCE.md` § Network security lists neither the OneLake inbound Resource Instance Rules page nor the Real-Time hub private-links page; `REFERENCE.md:39` covers only the outbound direction (trusted workspace access to ADLS Gen2). No existing line is contradicted.
  - Reference: https://learn.microsoft.com/fabric/onelake/onelake-manage-inbound-access-trusted-resources and https://learn.microsoft.com/fabric/real-time-hub/private-links-real-time-events
  - Proposed action: flag

## New-skill candidates

_(none)_

## MCP / tooling / CLI additions

_(none)_

## No-op

- The What's New row's own change is link text only.
- `fabric-activator` names Azure Blob Storage events as a source (`SKILL.md:178`, `:312`) and says nothing about networking; nothing invalidated.

## Owed re-checks

- **`2026-10-06/fabric/02-rewrite-mlv-optimal-refresh-tables.md`** — owed to the next `fabric` drift audit, by its `**Needs**:` line at `:203`
  - Owes: a Learn statement of the Spark SQL MLV GA month, to settle the skill's "GA March 2026".
  - Outcome: not in this window — Learn's MLV overview and Spark SQL reference (read 2026-10-16) still carry no GA month, only "PySpark authoring (Preview)"; this source's GA row still says September 2026, unchanged in the window. The claim has moved: `fabric-mlv` is folded into `fabric-spark`, whose `SKILL.md:3` no longer dates GA; `references/mlv.md:307` still says "(GA March 2026)".
  - Leaves open: the same line, now pointing at `fabric-spark/references/mlv.md:307`.
- **`2026-10-06/fabric/03-rewrite-graph-gql-support-and-query-api.md`** — owed to the next `fabric` drift audit, by its line at `:222`
  - Owes: whether Learn documents incremental graph updates (item 5).
  - Outcome: not in this window — Learn's manage-data page still says "every save refreshes your graph data" and design-graph-schema "Graph currently doesn't support schema evolution" (2026-10-16); no graph row changed in the window. The claims now sit at `fabric-iq/references/graph.md:11` and `:115`, and `graph-reference.md:196`, and still match Learn.
  - Leaves open: the same line, pointing at `fabric-iq`.
- **`2026-10-06/fabric/11-relabel-bulk-definition-apis-and-scope-bypath.md`** — owed to the next `fabric` drift audit, by its line at `:233`
  - Owes: D-7, whether the Catalog Search API documents table and column search before `fab find`'s line changes.
  - Outcome: not in this window — the REST reference (2026-10-16) still scopes `search` to "display name, workspace display name, and description", with `CatalogEntryType` only `FabricItem` and `Workspace`; the "OneLake Catalog table discovery (Preview)" row is unchanged in the window. The `fab find` line is now `fabric-rest-api/references/cli.md:54`, three fields, correct as is.
  - Leaves open: the same line, pointing at `fabric-rest-api`.
- **`2026-10-06/fabric/14-update-dataflow-destinations-and-pipeline-activities.md`** — owed to the next `fabric` drift audit, by its line at `:198`
  - Owes: what Learn still leaves undocumented — dynamic warehouse schema, and how a destination expression serializes into `mashup.pq`.
  - Outcome: not in this window — the destinations page (2026-10-16) still says "When loading data into the warehouse, only fixed schema is supported", and the dynamic expression editor page shows tokens in the UI only ("isn't a general-purpose Power Query M expression editor"); neither preview row changed in the window. `fabric-dataflow` `REF:93-98` and `SKILL.md:273-282` stand.
  - Leaves open: the same line.
- **`2026-10-08/prompt-audit/02-point-drift-audit-at-the-repo-skill-trees.md`** — owed to the next `/drift-audit` of `fabric` or `powerbi`, by its line at `:153`
  - Owes: step 6's skill-match reading on a real diff — map a change to an existing platform skill as a skill match.
  - Outcome: passed — the Glob of `skills/*/*/SKILL.md` (32) and `.claude/skills/*/SKILL.md` (6) ran, and the one real entry grepped to `fabric-security/references/REFERENCE.md:39` and `fabric-deploy/references/deployment-pipelines-tables.md:116,123`, both pruned platform skills reached through the repo tree.
  - Leaves open: nothing.
- **`2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`** — owed to the next `/drift-audit` run, by its line at `:135`
  - Owes: the behavioural check — § 1's slash-free `Glob` lists the registry; and, only on a WebFetch fallback, § 4b's completeness check.
  - Outcome: passed for § 1 — `Glob` pattern `*.md` under the sources directory returned all six entries. The § 4b half: not in this window — this run took the clone path, so no fallback ran.
  - Leaves open: the § 4b half, for a run that falls back to WebFetch.

## Recommended actions

1. `fabric-security` — flag: `references/REFERENCE.md` § Network security lacks the OneLake inbound Resource Instance Rules page and the Real-Time hub private-links page, revised 2026-10-15; decide whether the bundle should carry them.
2. Stamp each log under Owed re-checks: four `fabric` lines carry forward with their artifacts' new locations, `prompt-audit/02` closes, `claude-code/11` keeps its § 4b half.

## Next run

Pass one of these as the prior reference next time:

- Microsoft Fabric (incl. RTI) head: `0cbcc6f71` (2026-10-15) — a first-parent landing, so the next run lists no carry-nothing merges
- Or a single date: `2026-10-16`

A SHA from any registered source's repo, or any ISO date, is accepted.
