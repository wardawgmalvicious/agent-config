# Handoff: does `.OperationsAgent` need a skill?

- **Written**: 2026-09-02, from a coverage question raised against the RTI
  Operations Agent docs and a live sample in `C:\Repos\ACME\fabric-acme`.
- **Kind**: coverage decision, then `/author-skill`.
- **Status**: open. **Recommendation: yes, author it** — as
  `fabric-operations-agent`, scoped to the *definition file and its ALM
  consequences*, not to the portal click-path.
- **Run in**: a fresh session. Start with `/author-skill` once step 1
  below resolves the way the evidence says it will.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The gap

`grep -rni "operations.agent" skills/ claude/ tests/` returns **one hit**
across the entire payload, and it is a spent audit note
(`docs/drift-audit/2026-08-29/fabric/00-audit-report.md:147`, "Investigator
insights in Operations Agent (Preview)" — flagged, never actioned).

There is no fixture, no glob, and no skill. The item type is not in
`fabric-git-serialization.md`'s `paths:` list either, so an
`.OperationsAgent` folder pulls in **exactly one** thing today: that rule,
via its `**/.platform` glob. The definition file itself pulls **nothing**.

| File (ACME sample) | Bytes | What loads today |
| --- | --- | --- |
| `OperationsAgent_1.OperationsAgent/.platform` | 310 | `fabric-git-serialization` (via `**/.platform` only) |
| `OperationsAgent_1.OperationsAgent/Configurations.json` | 1,683 | **nothing** |

Volume is *not* the argument here, and pretending otherwise would be
dishonest — this is 2 KB against DataPipeline's 127 KB (wave 5). The
argument is **trap density on a hand-editable file with an
undocumented-in-prose schema**, plus a live capacity meter attached to a
boolean that Git deploys. See step 3.

## Step 1 — resolve the identity question before anything else

This is the finding that shapes the whole skill, and it is not obvious
from either doc tree on its own.

**"Operations agent" appears in two Microsoft Learn workloads, and they
are the same item type.**

- **Real-Time Intelligence** — `fabric/real-time-intelligence/operations-agent`
  and its siblings (`-actions`, `-limitations`, `-billing`,
  `-transparency-note`), plus an ontology-grounded variant at
  `fabric/iq/ontology/how-to-create-operations-agent`. This is the general
  item: create, configure, rules and conditions, actions, limits.
- **Data Factory** — `fabric/data-factory/operations-agent-for-pipelines`
  (preview). A *preconfigured generation path* from the pipeline canvas
  ribbon that monitors pipeline runs. It is not a separate item type: the
  page's own step 4 says you select **Open Agent Configuration** to "view
  your operations agent item", and step 5 describes the same
  Save / Start / Stop ribbon as the RTI item.

**The trap**: the ALM support lists file it under **Data Factory**, not
RTI. Both
[Git integration → Supported items](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration#supported-items)
and
[Deployment pipelines → Supported items](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines#supported-items)
carry it as entry **3.9, "Operations Agent *(preview)*"**, under *Data
Factory items*, linking to the pipeline page — while the RTI section (4.x)
lists Activator, Eventhouse, Eventstream, KQL database, KQL queryset,
Real-Time Dashboard, Maps, Event Schema Set and Anomaly detection, and
**not** the operations agent. Anyone who reasons "it's an RTI item, so its
Git story is on the RTI Git page" finds nothing and concludes it isn't
supported. It is supported, in both, and both say preview.

**Do this first**: confirm the two doc trees describe one item type (the
`.platform` `metadata.type` is the tiebreaker — see step 3) and decide
whether the skill covers both front doors. It should; the Data Factory
path is just a template that writes the same `Configurations.json`.

## Step 2 — check the overlap before writing anything

Six things touch the neighbourhood. The skill is only worth writing if it
covers what they do not — and unlike wave 5, **none of them globs the same
file**, so there is no co-activation budget question here. The only
co-loader would be `fabric-git-serialization.md` on `.platform`, which is
one rule and already fires on every item type.

- **`fabric-data-agent`** (`**/*.DataAgent/**`) — the sharpest contrast and
  the one the skill must draw explicitly, because the names collide and the
  items do not. A Data Agent is **read-only, user-initiated, conversational,
  ≤5 data sources**, and never writes. An Operations Agent is
  **autonomous, LLM-driven, exactly one data source**, runs unattended
  every five minutes, and **can take write actions** — running a pipeline
  or notebook under the creator's delegated identity. Nothing in
  `fabric-data-agent` says any of this. Do not fold one into the other.
- **`fabric-eventhouse`** (`**/*.Eventhouse/**`) — the data source. Its
  authoring guidance is upstream of the agent (flat tables, populated
  ingestion time, column descriptions), and the Operations Agent's
  Eventhouse *limitations* — regular tables only, **no shortcut tables,
  no functions, no materialized views** — are a genuine constraint on how
  you design the Eventhouse, which the eventhouse skill has no reason to
  know. Decide whether that one fact belongs there or here; it is
  defensible either way, but write it exactly once.
- **`fabric-variable-library`** — see step 3. The definition schema
  supports variable references and the variable-library docs do not say so.
  Check whether that skill's "supported items" content needs the addition.
- **`fabric-cicd`** — the parameterisation residue (`find_replace` in
  `parameter.yml`) for the GUIDs that *cannot* take a variable reference.
  **Grep it** for whether it already generalises item-GUID rebinding; if it
  does, this skill should point at it rather than restate it.
- **`fabric-gotchas`** — already carries the `PowerBIEntityNotFound` /
  logicalId-vs-runtime-ID row. The sample's action GUIDs are runtime IDs,
  so that row applies unchanged. Point at it; don't duplicate it.
- **No Activator/Reflex skill exists.** Worth a sentence anyway: the
  Power Automate action path stores its connection *in an Activator item*,
  and the deterministic-rules-vs-LLM distinction (Activator vs Operations
  Agent) is a real "which item do I want" question. A sentence, not a
  section — and not a reason to author a second skill.

## Step 3 — the content that is genuinely uncovered

Everything in this section was **verified on 2026-09-02** unless marked
otherwise. Drill anything marked *verify* before it goes in the skill.

### 3a. The definition file, which the REST docs do not list

[Item definition overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview)
enumerates ~30 item types under *Definition Details for Supported Item
Types*. **Operations Agent is not among them** (fetched in full,
2026-09-02). The naive read is "no item definition" — and that is wrong.

The schema is live and real:

```
https://developer.microsoft.com/json-schemas/fabric/item/operationsAgents/definition/1.0.0/schema.json
```

HTTP 200, 6,940 bytes, JSON Schema **draft-07**, `"title": "Operations
Agent"`. This is the same shape as `fabric-realtime-dashboard` (schema at
`dataexplorer.azure.com`, not in the REST docs) and `fabric-graph` — a
hand-editable definition whose contract lives at a schema URL rather than
in the API reference. That is a pattern this repo already knows how to
write a skill about.

Definition part filename is **`Configurations.json`** — plural, capital C.
Not `<name>.json`, not lowercase. Item folder: `<Name>.OperationsAgent/`
with `.platform` + `Configurations.json`.

`.platform` `metadata.type` is **`OperationsAgent`** (confirmed in the ACME
sample), which settles step 1's tiebreaker and settles the folder suffix.
No wave-0-style "unverified item-type name" problem here.

Root object — `additionalProperties: false`, all three **required**:

| Key | Type | Notes |
| --- | --- | --- |
| `configuration` | object | required sub-keys: `instructions`, `dataSources`, `actions` |
| `playbook` | object | required at root, but schema gives it **no inner shape at all** (`{"type":"object"}`) |
| `shouldRun` | boolean | "Whether the agent should be running" |

`configuration.messageDestination` and `configuration.identity` are
optional. `identity` accepts **only** `sponsor` — the schema comments that
server-generated identity fields are read-only and excluded, which is why
the Entra Agent ID never appears in Git.

Enums, all closed:

- `dataSource.type` ∈ **`KustoDatabase`**, **`Ontology`** — the two source
  kinds, matching the prerequisites (eventhouse *or* ontology).
- `action.kind` ∈ **`PowerAutomateAction`**, **`FabricJobAction`**, with a
  draft-07 `if/then`: `connection` is required **iff** kind is
  `FabricJobAction`.
- `messageDestination` is a `oneOf` discriminated on `kind`:
  `Recipient` {`kind`, `recipient` (UPN)} or `TeamsChannel` {`kind`,
  `teamId`, `channelId`}. Both `additionalProperties: false`.

### 3b. The parameterisation asymmetry — the strongest single fact

`configuration.dataSources` maps an alias to **either** a dataSource object
**or** a variable reference string:

```json
"pattern": "^\\$\\(/[^/]+/[^/]+/[^/]+\\)$"
```

described in the schema as *"Reference to a variable in a Fabric variable
library, in the form `$(/<WorkspaceName>/<LibraryName>/<VariableName>)`"*.

Two things follow, and both are load-bearing:

1. **The variable-library docs do not mention this.**
   [Variable library → Supported items](https://learn.microsoft.com/fabric/cicd/variable-library/variable-library-overview#supported-items)
   lists seven consumers — Pipeline, Lakehouse shortcut, Notebook, Dataflow
   Gen 2, Copy job, User data functions, Plan — and **Operations Agent is
   not one of them** (fetched 2026-09-02). The schema says otherwise. This
   is a schema-vs-prose gap of exactly the kind this repo exists to record.
   *Verify by round-trip* before asserting it works end to end: a schema
   permitting a string is not proof the service resolves it. If it does not
   resolve, that is an even better finding — write it as the trap.
2. **`actions[].connection` cannot be parameterised.** Every field of
   `fabricItemConnection` — `jobArtifactId`, `jobWorkspaceId`, `itemType`,
   `jobType` — is a plain string with `additionalProperties: false` and no
   `variableReference` alternative, and the first two are `format: uuid`.
   So the **data source is portable across workspaces and the action target
   is not.** Cross-environment deployment of a `FabricJobAction` needs
   `find_replace` in `fabric-cicd`'s `parameter.yml`, or a deployment rule.
   Nothing in the docs says this; it falls out of the schema.

The ACME sample demonstrates the unportable half exactly — a hardcoded
`jobWorkspaceId` and `jobArtifactId` pointing at an Orchestration pipeline
in one specific workspace.

### 3c. `shouldRun` is deployed running state, and running costs money

`shouldRun` is the serialized Start/Stop toggle. It is in the definition,
so **Git sync and deployment pipelines carry it**. Deploy a workspace whose
agents were left started and they start in the target.

Against
[Operations agent capacity and billing](https://learn.microsoft.com/fabric/real-time-intelligence/operations-agent-billing):

- **`Operations agent compute` — 0.46 CU-hours per hour**, continuously,
  per running agent. Not per firing. Not per alert. Per hour, while
  `shouldRun` is true.
- **`Investigation agent reasoning`** — 400 CU-seconds / 1,000 input
  tokens, 40 cached, 1,600 CUs / 1,000 output tokens, on top, each time a
  condition is met.
- Monitored data is retained in Fabric for **30 days**, billed as OneLake
  storage.
- All of it is **background usage**, so it is throttled only after the
  capacity is over its limits for 24 hours — at which point background
  tasks are rejected and *the agent's processing halts*. Silent stop.

The ACME sample carries `"shouldRun": false`. A skill that says nothing else
should at minimum say: **check `shouldRun` in every diff**, and know that a
`true` merged to `main` is a standing meter in whatever workspace syncs it.

### 3d. Serialization observations from the sample — *verify each*

These come from one item (`C:\Repos\ACME\fabric-acme\RealTime\OperationsAgent_1.OperationsAgent`,
an agent created but never given **Generate Playbook** — its `instructions`
is `""`). Treat them as leads, not facts, and reproduce against a
configured agent before encoding:

- **`playbook` is absent from the file**, though the schema marks it
  required at root. Either the portal omits it until the playbook is
  generated, or `additionalProperties: false` + `required` is not enforced
  on write. Determine which. If the portal really does emit a
  schema-invalid file for an unconfigured agent, that is a gotcha worth its
  own line — a validator in CI would reject a legitimately-committed item.
- **`messageDestination` contains `"kind": "Recipient"` twice** — a
  literal duplicate JSON key. Harmless on parse (last wins) and not a
  schema violation post-parse, but it is a serializer artifact, it makes
  the file non-canonical, and it is a diff-noise / idempotency risk on
  round-trip. Check whether it reproduces on a fresh export.
- **Action parameter *values* ride in `description`.** The schema's
  `parameter` is `{name, description}`, `additionalProperties: false`, with
  **no value field** — yet the sample's five parameters read
  `{"name": "DryRun", "description": "false"}`,
  `{"name": "EndHourLocal", "description": "20"}`,
  `{"name": "LocalTimeZoneId", "description": "Eastern Standard Time"}`.
  Either the description *is* the value passed to the job, or these are
  descriptions that happen to look like values and the real binding is
  elsewhere. **This is the single most important thing to resolve** — it
  determines whether hand-editing a parameter is safe. Confirm against the
  target pipeline's parameter list.
- **`dataSources[].workspaceId` is all-zeros**
  (`00000000-0000-0000-0000-000000000000`) while its `id` is a real GUID.
  Likely a "current workspace" sentinel; confirm.
- **Two ID families in one file.** The `dataSource.id` and the `.platform`
  `logicalId` both have a non-RFC-4122 version nibble (`…-a7dd-…`,
  `…-b5f8-…`), the shape Fabric logicalIds take; the action's
  `jobArtifactId` / `jobWorkspaceId` are conventional v4-shaped runtime
  IDs. If that holds, the file references its **data source by logicalId**
  (Git-portable) and its **action target by runtime ID** (not portable) —
  which would explain 3b's asymmetry and ties straight into
  `fabric-gotchas`' logicalId row. Verify before stating it; the nibble is
  suggestive, not proof.

**Redact before committing anything.** The sample's `messageDestination`
carries a real work UPN. Do not copy it into the brief-derived skill, the
fixture, or an example. `docs/` and `tests/` are gitleaks-allowlisted, so
nothing will stop you.

### 3e. Behaviour and limits worth encoding

From the RTI docs, all verified 2026-09-02. Compress hard — this is the
part most likely to bloat `SKILL.md`, and most of it belongs in
`references/`.

- **Conditions are state or transition, and the distinction is the whole
  game.** State conditions (`Is above`, `Is below`, `Is`) are met on
  *every* five-minute evaluation while the value holds, so they re-signal
  indefinitely. Transition conditions (`Crosses above`, `Crosses below`,
  `Enters range`, `Exits range`, `Becomes`) fire once per crossing,
  including from null. Choosing `Is above` where you meant `Crosses above`
  is how an agent floods a Teams channel. Eight conditions, cleanly split —
  a small table earns its place.
- **Five-minute query cadence** when active; **operations expire after
  three days** and cannot then be approved.
- **One data source per agent**, full stop.
- **Delegated identity, permanently the creator's.** The agent runs OBO as
  whoever created it; approving a recommendation executes the action *with
  the creator's permissions*, and changing the message recipient does
  **not** change whose credentials are used. Each agent also gets its own
  Microsoft Entra Agent ID (a service principal) so actions attribute to
  the agent rather than a user session. This is the security paragraph, and
  it is the reason a shared-recipient agent is a privilege-escalation
  surface worth naming.
- **Ontology sources are more limited than Kusto ones**: same workspace
  required, entities need a static identifier property, only basic property
  values (no avg/min/max), and **no `AND` conditions**.
- **Eventhouse sources**: regular tables only — no shortcuts, functions or
  materialized views; flatten nested JSON; populate ingestion time (the
  agent defaults to it for recency and deltas); quote column names
  containing underscores or hyphens in rules.
- **Instruction authoring** has a documented shape worth reproducing: split
  *Operational Instructions* from *Semantic Instructions*, one rule per
  line, higher-priority rules first (position affects LLM weighting),
  numeric thresholds rather than "high"/"low".
- **Availability**: preview; not on trial capacities; Azure public cloud
  only, **excluding South Central US and East US**; no sovereign clouds
  (GCC-High, Bleu); not in CMK-encrypted workspaces. Teams app install
  required to receive messages, and recipients need **write** permission on
  the agent item.
- **Investigator insights** (preview) — the auto-root-cause analysis on
  anomaly detection. This is the item the 2026-08-29 drift audit flagged
  and never actioned; closing it here retires that finding.

### 3f. Tooling reach

`fab` **1.7.0** knows `OperationsAgent` in
`fabric_cli/commands/find/type_supported.yaml` but the name is **absent
from the `ItemType` enum** in `fabric_cli/core/fab_types.py` (both checked
on the installed package, 2026-09-02). So — exactly as `fabric-graph`
already documents for `GraphModel` — `fab find` can locate one, and `fab`
cannot create or address it. Reuse that skill's phrasing; it is the same
finding on a different type.

## Step 4 — the glob and the fixture

Glob: **`**/*.OperationsAgent/**`**. Two files per item, both relevant. No
narrowing needed.

Also add `**/*.OperationsAgent/**` to
[`claude/rules/fabric-git-serialization.md`](../../../claude/rules/fabric-git-serialization.md)
in the same change. It is missing today, so `Configurations.json` gets no
serialization rule at all — the identical bug wave 6 fixed for
`GraphModel`, and it will show up in the static check as an empty column
the moment the fixture exists.

Fixture: `tests/skills/fabric-triggers/fixtures/SampleOA.OperationsAgent/`
with `.platform` + `Configurations.json`, modelled on the ACME sample as the
other fixtures are — **with the UPN and all five GUIDs replaced**. Make the
fixture schema-*valid* (include `playbook: {}`) rather than copying the
sample's omission; the fixture tests globs, not the portal's serializer.

## Validation

The harness has changed since wave 5's brief was written — it is one
command now, and the expectation tables are parsed, so **no script edit is
needed**:

```powershell
./scripts/test-activation.ps1 -Set fabric -StaticOnly   # globs only, no session
./scripts/test-activation.ps1 -Set fabric               # static, then a cold session
```

- Add the two fixture rows to
  [`tests/skills/fabric-triggers/expected_activations.md`](../../../tests/skills/fabric-triggers/expected_activations.md)
  **in the same commit** as the skill —
  `SampleOA.OperationsAgent/.platform` and
  `SampleOA.OperationsAgent/Configurations.json`, each expecting
  `fabric-operations-agent` plus the serialization rule. `scripts/activation_expect.py`
  reads that table directly, so the rows *are* the assertion.
- The set's file count changes; check whether the README's "10 here" /
  "24 conditional skills" counts need updating with it.
- Body cap: aim under ~3,100 tokens, per wave 5's measured floor. This one
  should come in comfortably under — much of §3e belongs in
  `references/`, and the schema table is the only part that must be inline.
- `description` ≤ 1,024 chars, `when_to_use` ≤ 512. It needs a **`when_to_use`
  from the start**: `fabric-data-agent` and `fabric-operations-agent` are
  two agent skills whose names invite exactly the confusion §2 describes,
  and disambiguation is what that field is for. Note that this is a
  *conditional* skill, where [when-to-use-adoption.md](when-to-use-adoption.md)
  found the field near-free.
- Lint, `pre-commit run --all-files`, `/commit`.

## Preview risk — state it in the skill

Everything above is preview: the item, its Git integration, its deployment
pipeline support, and Investigator insights. Two doc trees describing one
item is itself a sign the surface has not settled. Date the volatile
claims in the skill body the way `fabric-data-agent` dates its
retirements, and register nothing here as GA. The
[`/drift-audit`](../../../skills/workflow/drift-audit/SKILL.md) Fabric
source already covers the RTI What's New feed, so churn will surface —
but only if the skill's claims are dated enough to be checkable.

## If the answer turns out to be no

Say so in the commit that deletes this brief, and record why. The likeliest
"no" is *"too preview to be worth encoding yet"* — a defensible call, and
one the wave 2 KQLQueryset decision has a template for. If that is the
outcome, the residue still has somewhere to go and should not be dropped:

- `**/*.OperationsAgent/**` into `fabric-git-serialization.md` **regardless**
  — that is a glob gap, not a skill decision, and it is free.
- The `shouldRun` / capacity-meter trap and the `Configurations.json`
  schema URL into `fabric-gotchas`.
- The Data Agent vs Operations Agent contrast into `fabric-data-agent`'s
  `when_to_use`.
- The variable-reference finding into `fabric-variable-library`, once
  round-tripped.
