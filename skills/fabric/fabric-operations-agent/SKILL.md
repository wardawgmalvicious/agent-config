---
name: fabric-operations-agent
description: "Use for the Microsoft Fabric Operations Agent item (preview) — `<Name>.OperationsAgent/` + `Configurations.json` — the autonomous LLM agent that queries one Eventhouse/KQL database or Ontology every 5 minutes, messages Teams, and can run a pipeline or notebook under its creator's delegated identity. Covers the draft-07 definition schema (`configuration`/`playbook`/`shouldRun` all required, `dataSource.type` KustoDatabase|Ontology, `action.kind` FabricJobAction|PowerAutomateAction with `connection` required iff the first, Recipient|TeamsChannel `messageDestination`, `identity.sponsor`), the ALM traps (Git integration lists it under Data Factory not RTI; `shouldRun: true` deploys a running 0.46 CU-hour/hour meter; `dataSources` accepts a `$(/ws/lib/var)` reference the variable-library docs omit; `jobArtifactId` is the target's byte-reversed `logicalId`), serializer artifacts (absent `playbook`, duplicate `kind` key, parameter values in `description`), state vs transition conditions, and `fab` reach."
when_to_use: "Fires on any file under `*.OperationsAgent/`. Not the same item as a Data Agent (fabric-data-agent): that one is read-only, user-initiated, conversational, up to 5 sources; this one is autonomous, single-source, unattended, and takes write actions. Data Factory's 'operations agent for pipelines' is a template that generates this same item, not a second type. For authoring the KQL database it monitors see fabric-eventhouse; for deterministic non-LLM alerting, that is Activator."
paths:
  - "**/*.OperationsAgent/**"
model: inherit
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Fabric Operations Agent: the definition file and its ALM consequences

Everything below was verified **2026-09-02**. The item, its Git
integration, its deployment-pipeline support and Investigator insights
are all **preview** — re-check dated claims before relying on them.

This skill is about the *file*. The portal click-path is documented and
not repeated here; what is not documented is what `Configurations.json`
means once it is committed.

## 1. Item identity

| Fact | Value |
| --- | --- |
| `.platform` `metadata.type` | `OperationsAgent` |
| Folder | `<Name>.OperationsAgent/` |
| Definition part | `Configurations.json` — **plural, capital C**, not `<name>.json` |
| Schema | `https://developer.microsoft.com/json-schemas/fabric/item/operationsAgents/definition/1.0.0/schema.json` |

Two files per item and nothing else.

**The REST docs do not list this item type.** [Item definition
overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview)
enumerates ~30 types under *Definition Details for Supported Item Types*
and Operations Agent is not among them. That is not evidence of "no item
definition" — the schema above is live and returns 200. Same pattern as
`fabric-realtime-dashboard` and `fabric-graph`: a hand-editable
definition whose contract lives at a schema URL rather than in the API
reference.

**One item type, two front doors.** Real-Time Intelligence documents the
general item; Data Factory documents [Operations Agent for
Pipelines](https://learn.microsoft.com/fabric/data-factory/operations-agent-for-pipelines),
which is a *preconfigured generation path* from the pipeline canvas
ribbon — its own step 4 says you select **Open Agent Configuration** to
"view your operations agent item", and step 5 shows the same
Save/Start/Stop ribbon. There is also an ontology-grounded front door in
[IQ](https://learn.microsoft.com/fabric/iq/ontology/how-to-create-operations-agent).
All three write this same `Configurations.json`.

## 2. The ALM listing trap

**Look for its Git story under *Data Factory*, not Real-Time
Intelligence.** [Git integration → Supported
items](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration#supported-items)
carries **Operations Agent *(preview)*** in the *Data Factory items*
group, linking to the pipeline page. The Real-Time Intelligence group
lists ten items and **not** this one. Deployment pipelines files it the
same way.

Reasoning "it is an RTI item, so its Git story is on the RTI Git page"
finds nothing and concludes it is unsupported. It is supported, in both,
and both say preview.

## 3. The definition schema

JSON Schema **draft-07**. Root is `additionalProperties: false` and all
three keys are **required**:

| Key | Type | Notes |
| --- | --- | --- |
| `configuration` | object | required sub-keys `instructions`, `dataSources`, `actions`; optional `messageDestination`, `identity` |
| `playbook` | object | required at root, but the schema gives it **no inner shape** (`{"type": "object"}`) |
| `shouldRun` | boolean | the serialized Start/Stop toggle — see §5 |

`identity` accepts **only** `sponsor`. The schema notes that
server-generated identity fields are read-only and excluded, which is why
the Entra Agent ID never appears in Git.

Every enum is closed:

- **`dataSource.type`** ∈ `KustoDatabase`, `Ontology`. Requires `id`,
  `type`, `workspaceId`.
- **`action.kind`** ∈ `PowerAutomateAction`, `FabricJobAction`, with a
  draft-07 `if/then`: **`connection` is required iff `kind` is
  `FabricJobAction`**. An action also requires `id`, `displayName` and
  `description`.
- **`messageDestination`** is a `oneOf` discriminated on `kind` —
  `Recipient` {`kind`, `recipient` (a UPN)} or `TeamsChannel` {`kind`,
  `teamId`, `channelId`}. Both `additionalProperties: false`.
- **`fabricItemConnection`** requires `jobArtifactId`, `jobWorkspaceId`,
  `itemType`, `jobType`, optionally `subItemId`, and is
  `additionalProperties: false`. The first two are `format: uuid`.

`parameter` is `{name, description}` — `name` required,
`additionalProperties: false`, and **no value field**. See §6.

## 4. What survives a cross-workspace deployment

This is the section to read before parameterising anything, and it is
where the intuitive answer is wrong.

**Item references in this file are logicalIds, not runtime IDs — but in
two different encodings.**

- **`dataSource.id` is the source item's `.platform` `logicalId`,
  character for character.** Open the monitored KQL database's
  `.platform` and you will find the same string.
- **`jobArtifactId` is the target item's `logicalId` with its 16 bytes
  reversed.** Reversing is an involution, so it round-trips:

  ```python
  import uuid
  rev = lambda g: str(uuid.UUID(bytes_le=uuid.UUID(g).bytes_le[::-1]))

  # synthetic illustration
  rev("7c4d1e88-93af-4b02-9d61-2fa50c7e3b14")
  # -> '0c7e3b14-2fa5-9d61-4b02-93af7c4d1e88'   the .platform logicalId form
  ```

  This is also why a `logicalId` so often has a version nibble that is
  not `4` — a reversed v4 GUID does not look like a v4 GUID. The
  encoding is systematic rather than a property of this item type: 79
  reversals with zero failures, across two Git-synced repos (74 of 76)
  and ~20 unrelated public repos and tenants, where every id is a valid
  v4 in exactly one of the two forms. *Measured 2026-09-02, widened
  2026-09-03.*

  **The reversed form is the runtime item ID — confirmed 2026-09-03**
  against `GET /v1/workspaces/{ws}/items` over 19 workspaces. Of the
  local `logicalId`s whose reversal resolved to anything, **21 of 21**
  hit a real item carrying the **same `displayName` and `type`**. No
  reversal landed on a different item, and no raw `logicalId` was itself
  an item ID. The remaining 16 were absent from every visible workspace,
  so they neither confirm nor refute.

  **The precondition matters more than the rule.** This holds for items
  **created in the portal**. An item authored *git-first* — committed as
  files, then synced into the workspace — carries a fresh client-side v4
  that encodes nothing, and reversing it yields a GUID that is not an
  item ID at all. Classifying by whether an item's oldest commit is a
  Fabric portal sync separated the two forms **76 of 76 with no
  cross-cases** in the source repos. Neither git-first item resolved
  against the API, so that half is consistent but untested.

  **Do not conclude that `logicalId` and the runtime item ID are
  interchangeable.** They are still different strings and substituting
  one for the other still fails — see `fabric-gotchas` on
  `PowerBIEntityNotFound`. What the confirmation buys is the *derivation*
  — reverse it yourself, offline — not a licence to paste one where the
  other belongs.

- **`jobWorkspaceId` is a plain workspace ID.** Workspaces have no
  logicalId, so this is the one value in the file that genuinely does not
  travel between environments. Rebind it with `find_replace` in
  `fabric-cicd`'s `parameter.yml`, or a deployment rule.

**The parameterisation asymmetry is a schema fact, not a portability
one.** `configuration.dataSources` maps an alias to **either** a
dataSource object **or** a variable-reference string:

```json
"pattern": "^\\$\\(/[^/]+/[^/]+/[^/]+\\)$"
```

described as *"Reference to a variable in a Fabric variable library, in
the form `$(/<WorkspaceName>/<LibraryName>/<VariableName>)`"*. Nothing
equivalent exists on `fabricItemConnection`, which is
`additionalProperties: false`. So a data source can be swapped per
environment through a variable library and an action target cannot.

**Two caveats on that, both dated 2026-09-02.** The [variable library
supported-items
list](https://learn.microsoft.com/fabric/cicd/variable-library/variable-library-overview#supported-items)
names seven consumers — Pipeline, lakehouse shortcut, Notebook, Dataflow
Gen 2, Copy job, User data functions, Plan — and **Operations Agent is
not one of them**. The schema permits the string; nobody has confirmed
the *service* resolves it. **Round-trip it before relying on it**, and if
it does not resolve, that is the finding worth recording.

## 5. `shouldRun` is deployed running state, and running costs money

`shouldRun` is the Start/Stop toggle, it lives in the definition, and
therefore **Git sync and deployment pipelines carry it**. Deploy a
workspace whose agents were left started and they start in the target.

Per [capacity and
billing](https://learn.microsoft.com/fabric/real-time-intelligence/operations-agent-billing):

- **`Operations agent compute` — 0.46 CU-hours per hour**, continuously,
  per running agent. Not per firing, not per alert. Per hour, while
  `shouldRun` is `true`.
- Reasoning meters bill on top per condition met, and monitored data
  sits in OneLake for **30 days**. Full table in the reference file.
- It is all **background usage**, throttled only after the capacity is
  over its limits for 24 hours — at which point background tasks are
  rejected and **the agent's processing halts**. A silent stop.

**Check `shouldRun` in every diff.** A `true` merged to `main` is a
standing meter in whatever workspace syncs it.

## 6. Serializer artifacts that are not corruption

**A committed `Configurations.json` does not validate against its own
schema.** There are two independent reasons, and the first applies to
*every* such file:

- **The `$schema` key is itself a violation.** The root declares exactly
  `configuration`, `playbook` and `shouldRun` with
  `additionalProperties: false`, and `$schema` is not among them — yet
  Fabric writes `$schema` as the file's first key. So the document
  Fabric emits is rejected by the document Fabric publishes to describe
  it. *Checked against the live schema with `jsonschema` 2026-09-02.*
- **`playbook` may be absent** even though it is `required`. Observed on
  an agent created but never given *Generate Playbook*, so the portal
  probably omits it until one is generated — but `required` may simply
  not be enforced on write. **Single sample; determine which.**

**So do not put a bare schema validation in CI** and read its failure as
corruption. Strip `$schema` before validating, and decide separately
what an absent `playbook` means for you.

The rest are from that same single agent. Treat them as observations,
not contracts, and reproduce against a configured agent before depending
on any of them. *Observed 2026-09-02.*
- **`messageDestination` can carry a duplicate `"kind"` key.** Harmless
  on parse (last wins) and not a post-parse schema violation, but the
  file is non-canonical and it is a diff-noise and idempotency risk on
  round-trip.
- **An action parameter has no value field, and what `description`
  actually does is unresolved.** `parameter` is `{name, description}`
  with `additionalProperties: false` — there is nowhere to put a value.
  Yet in the sample every `name` matches a parameter on the target
  pipeline and every `description` is that parameter's `defaultValue`
  rendered as a string (`{"name": "DryRun", "description": "false"}`,
  `{"name": "LocalTimeZoneId", "description": "Eastern Standard
  Time"}`).

  **That observation does not discriminate between the two readings**,
  because both predict it: either `description` *is* the value slot and
  the portal seeded it from the target's defaults, or it is prose that
  guides the **LLM** in choosing a value at invocation time and the
  portal seeded it from the same place. The docs lean to the second —
  parameters are "passed when it invokes the action", and the approver
  is told to "adjust any action parameters if needed" in Teams, which is
  a runtime affordance rather than a file one.

  **So do not hand-edit a `description` expecting it to pin a value.**
  Resolve it first by running the action and reading what the target
  actually received. *Unresolved as of 2026-09-02.*
- **`dataSources[].workspaceId` may be all-zeros**
  (`00000000-0000-0000-0000-000000000000`) while `id` is a real
  identifier. Reads as a "current workspace" sentinel; unconfirmed.

## 7. Which agent item do I want

| | Operations Agent | Data Agent (`fabric-data-agent`) |
| --- | --- | --- |
| Initiation | autonomous, every 5 minutes | user-initiated, conversational |
| Sources | **exactly one** | up to 5 |
| Writes | **yes** — runs pipelines, notebooks, flows | never, read-only |
| Identity | creator's delegated (OBO) + an Entra Agent ID | caller's |

**Activator** is the third option and is not an LLM — use it for
deterministic rule-based alerting. It also appears *inside* this item: a
`PowerAutomateAction` stores its connection in an Activator item.

**The agent runs as its creator, permanently.** Approving a
recommendation executes the action **with the creator's permissions**,
and changing the message recipient does *not* change whose credentials
are used — while recipients need only **write** on the agent item. A
shared-recipient agent is a privilege-escalation surface; name it in
review.

## 8. Tooling reach

`fab` **1.7.0** knows `OperationsAgent` in
`fabric_cli/commands/find/type_supported.yaml`, but the name is **absent
from the `ItemType` enum** in `fabric_cli/core/fab_types.py`. So
`fab find` can locate one and `fab` cannot create or address it — the
same split `fabric-graph` documents for `GraphModel`.

## 9. Constraints

- **Everything here is preview** — the item, its Git integration, its
  deployment-pipeline support, and Investigator insights. Two doc trees
  describing one item is itself a sign the surface has not settled.
  Register nothing as GA.
- **Don't hand-craft the item folder.** Create it in the portal and
  commit what Fabric writes; hand-edit `Configurations.json` afterwards.
- **Don't validate a committed file against the schema in CI** as-is. It
  will fail on the `$schema` key Fabric wrote, and may fail again on an
  absent `playbook` (§6).
- **Don't rely on the variable reference in `dataSources`** until it has
  been round-tripped — the schema permits it and the docs do not
  acknowledge it (§4).
- **Choose the Eventhouse or ontology against the agent's limits**, not
  after. Regular tables only, ontology in the same workspace, no `AND`
  conditions on an ontology — none is workaroundable later, and all are
  in the reference file.
- **Check availability before promising it.** Not on trial capacities,
  Azure public cloud only with two US regions excluded, no sovereign
  clouds, not in CMK-encrypted workspaces, English only. Exact list in
  the reference file.

Behavioural detail — the eight state/transition conditions, instruction
authoring shape, the full billing table, availability and region
exclusions, Investigator insights, and the three action-configuration
paths — is in [references/REFERENCE.md](references/REFERENCE.md).
