# Handoff: decide which new-skill candidates to author

- **Audit run**: 2026-09-10
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-06` (diff base `912e06e0`) → head `65902bae`
  (2026-09-04)
- **Covers recommended actions**: 8
- **Kind**: **decision** — put to the user, never executed by
  `/drift-update`. Each accepted candidate becomes its own `/author-skill`
  run.

## Context

Four upstream skills in the window have no local counterpart. The audit
does not decide whether to author, vendor or ignore them. Bucket (b) is
also deliberately **not drilled**, so none of the upstream claims quoted
below are confirmed on Learn — `/author-skill` drills before it writes.

## Candidates

| Candidate | First named | New topic in window? | Local coverage, grepped 2026-09-10 |
| --- | --- | --- | --- |
| `onelake-catalog-govern-cli` | 0.3.15 | yes | no dedicated skill |
| `activator-cli` | 0.3.11 | no — merges `activator-authoring-cli` and `activator-consumption-cli`, named since 0.3.1 | Activator only as an Eventstream destination (`fabric-eventstream/references/activator-destination.md`) and `activator-remote-mcp` in `.vscode/mcp.template.json` |
| `dataflows-cli` | 0.3.11 | no — merges three `dataflows-*` skills, named since 0.3.0 | no Dataflow Gen2 skill; passing mentions in `fabric-data-pipeline` and `fabric-copy-job` |
| `deployment-pipelines-authoring-cli` | 0.3.11 | yes | one table row, `fabric-cicd/SKILL.md` line 23 |

### `onelake-catalog-govern-cli`

`CHANGELOG.md` `[0.3.15]` (`65902bae`), Added, verbatim:

> **`onelake-catalog-govern-cli`** -- audits and safely remediates
> Microsoft Fabric OneLake catalog governance across domains, workspaces,
> capacities, protection, and curation, with separate permission-aware
> modes for tenant admins and data owners.

### `activator-cli`

`[0.3.11]` (`2b3530e8`), Added, verbatim:

> **`skills/activator-cli`** -- one Activator / Reflex skill with
> authoring and consumption modes covering item and rule creation,
> sources, conditions and actions, plus read-only listing, inspection and
> `ReflexEntities.json` decoding.

`[0.3.13]` (`22cafc90`) then fixed four behaviours worth having if this
is authored — upstream's claims, unconfirmed:

- Creating an Activator item fails with `HTTP 400 DisplayName field is
  required` when `name` is sent instead of `displayName`.
- A `fabricItemAction-v1` payload carries its target in
  `payload.fabricItem` (`itemId`, `workspaceId`, `itemType`). A
  `targetItem` shape is accepted by `updateDefinition` but never resolves
  its target.
- The create request needs `Content-Type=application/json`, and inline
  JSON gets mangled by PowerShell (`UnsupportedMediaType`, then
  `InvalidInput`); write the body to a file and pass `--body "@<file>"`.
- A cloned attribute must update the `EventFieldSelector` `fieldName` as
  well as its `name`, or it silently reads the wrong column.

### `dataflows-cli`

`[0.3.11]`, Changed, verbatim:

> **`skills/dataflows-cli`** -- `dataflows-authoring-cli`,
> `dataflows-consumption-cli` and `dataflows-save-as-authoring-cli` are
> now the authoring, consumption and upgrade modes of a single
> `dataflows-cli` skill. Behaviour is unchanged; the guidance moved into
> `references/{mode}.md` and the dispatcher carries a terminal-write
> table so each mode's state-changing call stays in the always-loaded
> body.

### `deployment-pipelines-authoring-cli`

`[0.3.11]`, Added. The bullet is dense with limits, which is what makes
it a candidate. In part:

> Covers per-operation **delegated scopes** (`Pipeline.Read.All` /
> `Pipeline.ReadWrite.All` / `Workspace.ReadWrite.All`, and
> `Pipeline.Deploy` for deploy), required **permissions** (pipeline Admin
> + workspace roles), **item pairing / autobinding** repair
> (unassign->reassign with a deployment-rule-loss warning) ...

Its companion "Change-detection & deploy guidance" bullet claims:
`List stage items` returns identity and pairing but no change status;
`lastDeploymentTime` is the last deployment, not the last edit;
`getDefinition` is a long-running operation for Notebook, SemanticModel
and Report, synchronous for DataPipeline, and absent for Warehouse; one
operation per pipeline at a time (`WorkspaceMigrationOperationInProgress`,
HTTP 400); a first-deploy warm-up (`Alm_InvalidRequest_WorkloadUnavailable`,
~60–120 s); the `x-ms-operation-id` response header; a 300-item cap per
deploy; a write-only deploy `note`; and deploys copying definitions, not
data.

## Options per candidate

1. **Author** with `/author-skill` — coverage check, `fabric-` prefix,
   doc drill, a brief in `docs/handoffs/`.
2. **Vendor** upstream verbatim, as `powerbi-report-authoring` and
   `powerbi-report-design` were at v0.3.13. Read the upstream skill in
   full first: a vendored skill is instructions an agent runs with your
   permissions, first-party or not.
3. **Install** the upstream `fabric-skills` plugin bundle — the registry
   records it as a third option that "was not evaluated".
4. **Decline**, and say so in the registry entry so the next run does not
   re-propose it.

## Excluded

`eventschemaset-cli` also passed clause 1, but it is already queued as
`docs/handoffs/execute/fabric-event-schema-set.md` (`5bded54`,
2026-09-10).

## Verification

A decision recorded for each candidate: an accepted one has an
`/author-skill` brief in `docs/handoffs/` or a row in
`docs/handoffs/execute/README.md`; a declined one is noted in the
`skills-for-fabric` registry entry.

## Provenance

First `/drift-audit --sources skills-for-fabric` run, 2026-09-10. Three
of the four candidates are consolidation renames that passed clause 1 on
the new name alone. Whether renames should pass at all is D-5 in brief
06; the answer changes which of these a future run would surface.

## Execution log

- **Executed**: 2026-09-11 — escalated
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in the session)
- **Files changed**: none
- **Verification**: none run. This is a decision brief, and
  `/drift-update` does not execute those.
- **Decision**: the user accepted **all four** for `/author-skill`:
  `onelake-catalog-govern-cli`, `activator-cli`, `dataflows-cli` and
  `deployment-pipelines-authoring-cli`. Each becomes its own
  `/author-skill` run, started deliberately; none was started here.
  Brief 06's D-5 kept the lexical test, so future consolidation renames
  will keep surfacing.
- **Deferred**: this brief's verification. No accepted candidate has an
  `/author-skill` brief in `docs/handoffs/` or a row in
  `docs/handoffs/execute/README.md` yet. None of the upstream claims
  quoted above has been drilled.
- **Deviations**: none.
