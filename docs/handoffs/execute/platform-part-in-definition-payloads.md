---
status: open
priority: 3
needs: [tenant]
blocked-by: []
written: 2026-10-09
---

# Handoff: settle when a definition payload may carry .platform

- **Written**: 2026-10-09, from one inbox note of 2026-10-08, the
  platform half of a prompt audit run against Claude Opus 5.5 by a
  session in a client Fabric repo, which flagged this without a hunk.
  Re-measured against the payload at `38ab77b`, which changed nothing
  here.
- **Kind**: a probe on a tenant, then edits to three platform skills.
  Nothing is drafted.

## What is open

Learn's item definition overview says Create Item honors a `.platform`
part, as bulk import does, Get Item Definition always returns one, and
Update Item Definition accepts one only with `?updateMetadata=true`
(read 2026-10-09). The Notebook, KQL Database, Environment and Ontology
definition pages say the same. The SemanticModel definition page lists
no `.platform` part and states no exception.

The payload disagrees with itself:

- `fabric-cli` says never to include `.platform` in a direct
  definition call (`SKILL.md:270` on 2026-10-09), and its
  troubleshooting row says `.platform` breaks REST definition calls,
  being "Git metadata, not a part" (`:366`). Learn calls it a part, and
  `fabric-rest-api` (`SKILL.md:139-141`), `fabric-spark` (`:104-105`)
  and `fabric-activator` (`:163-165`) say an update without the flag
  ignores it.
- `fabric-tmdl-api` says never to include it in a semantic model's
  `updateDefinition`, since it "causes errors" (`SKILL.md:15`, and its
  description). The claim dates from the skill's first commit,
  `419ac5e` (2026-05-05), and cites nothing.
- `fabric-dataflow` § 6 holds both as true, each for its own item type,
  and says not to reconcile them (`9153d3d`, 2026-09-12). Learn's
  general rule makes the semantic-model exception the claim to test.

## Where it runs

A tenant, on a test semantic model: `updateDefinition` with every part,
plus a `.platform` whose `displayName` differs from the model's, once
without the flag and once with `?updateMetadata=true`. Record each
status, any error text, and whether the name changed.

## Decision after probing

- **Both calls succeed and the second renames the model**:
  `fabric-tmdl-api`'s "never" becomes "only with
  `?updateMetadata=true`, to change the name or description",
  `fabric-cli`'s two lines say the same for every item type, and
  `fabric-dataflow` § 6 drops the divergence it records.
- **The semantic model rejects the part**: `fabric-tmdl-api` keeps its
  rule, with the error text, and `fabric-cli`'s two lines narrow to
  semantic models, since other item types take the part.

## Where it lands

`skills/fabric/fabric-cli/SKILL.md`, two lines; `fabric-dataflow` § 6;
and `fabric-tmdl-api`'s line 15 and description, which
[ai-instructions-into-fabric-tmdl.md](ai-instructions-into-fabric-tmdl.md)
moves into `fabric-tmdl/references/definition-api.md`, so edit them
wherever they are by then. A body edit owes a retest:
`uv run --with pyyaml scripts/skill-status.py --stale` says so.

## Not checked

The tenant probe itself. Learn was read on 2026-10-09, the payload at
`38ab77b`.

## Scrubbing

The note came from a session in a client repo. No workspace, item or
tenant is named.

## Re-measure before acting

```bash
grep -rn 'updateMetadata\|\.platform`' skills/fabric/fabric-cli/SKILL.md skills/fabric/fabric-tmdl-api/SKILL.md skills/fabric/fabric-dataflow/SKILL.md skills/fabric/fabric-rest-api/SKILL.md skills/fabric/fabric-spark/SKILL.md
```
