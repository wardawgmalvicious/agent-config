# Skill handoff brief: fabric-operations-agent

Last verified: 2026-09-02

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

Personal scope, deployed by `scripts/link-claude.ps1`:

- Repo: `skills/fabric/fabric-operations-agent/SKILL.md`
- Repo: `skills/fabric/fabric-operations-agent/references/REFERENCE.md`
- Deployed: `~/.claude/skills/fabric-operations-agent/SKILL.md`

`fabric/` is the group directory the `fabric-` namespace implies. It is
repo-side only and does not survive into the deployed name — Claude Code
discovers a skill exactly one level under the skills root, so
`~/.claude/skills` holds one junction per skill. A run on this machine
must name `-SkillGroups workflow`, which **prunes** `fabric/`: this skill
will not be deployed to `~/.claude/skills` here, and that is correct and
deliberate. It is still linted by pre-commit and still tested by
`scripts/test-activation.ps1 -Set fabric`, which deploys both groups to a
throwaway probe.

## Scope

Covers the Microsoft Fabric **Operations Agent** item as it appears in
Git — the `<Name>.OperationsAgent/` folder, its `.platform`, and its
single definition part `Configurations.json` — plus the ALM consequences
of what that file contains. The skill is scoped to the *definition file*,
not the portal click-path: it exists so that someone reading or
hand-editing a committed `Configurations.json` knows what each key
means, which references survive a cross-workspace deployment, and which
serializer artifacts in the file are normal rather than corruption.

Behavioural detail that belongs to the running agent rather than the file
— the eight conditions, instruction-authoring shape, billing meters,
availability, Investigator insights, the three action-configuration
paths — goes to `references/REFERENCE.md`, with the body carrying only
the parts that change what you write in the file.

Inline, model-invocable, **path-scoped** on `**/*.OperationsAgent/**`.
That makes it the 26th conditional skill in the payload, so its listing
entry costs nothing until a matching file is `Read` — which is also why
it can afford a `when_to_use`.

## Sources drilled

Drilled, all 2026-09-02:

- `https://developer.microsoft.com/json-schemas/fabric/item/operationsAgents/definition/1.0.0/schema.json`
  — fetched in full (HTTP 200, 6,940 bytes, JSON Schema draft-07, title
  "Operations Agent"). Established the entire root shape, every enum, the
  `if/then` on `connection`, the `oneOf` on `messageDestination`, the
  `variableReference` pattern, and — decisively — that `parameter` is
  `{name, description}` with `additionalProperties: false` and **no**
  value field.
- [Create and configure operations agents](https://learn.microsoft.com/fabric/real-time-intelligence/operations-agent)
  — prerequisites (no trial capacities), Entra Agent ID and the delegated
  OBO identity, the 5-minute rule cadence, and the state-vs-transition
  condition table (8 conditions).
- [Operations agent best practices and limitations](https://learn.microsoft.com/fabric/real-time-intelligence/operations-agent-limitations)
  — one data source; Eventhouse regular tables only (no shortcuts,
  functions, materialized views); ontology same-workspace + static
  identifier property + no aggregations + no `AND`; 3-day operation
  expiry; English only; region exclusions; the Operational/Semantic
  instruction split.
- [Operations agent actions](https://learn.microsoft.com/fabric/real-time-intelligence/operations-agent-actions)
  — Teams app install, recipients need **write** on the agent item, the
  Activator item as the store for a Power Automate connection, and
  Investigator insights (preview).
- [Operations agent capacity and billing](https://learn.microsoft.com/fabric/real-time-intelligence/operations-agent-billing)
  — `Operations agent compute` at **0.46 CU-hours per hour**, the two
  reasoning meters, 30-day OneLake retention, and background-usage
  throttling that halts the agent after 24 hours over limits.
- [Operations Agent for Pipelines (preview)](https://learn.microsoft.com/fabric/data-factory/operations-agent-for-pipelines)
  — confirmed it is a *generation path*, not a second item type: step 4
  opens "your operations agent item", step 5 is the same
  Save/Start/Stop ribbon.
- [Create an operations agent grounded in an ontology](https://learn.microsoft.com/fabric/iq/ontology/how-to-create-operations-agent)
  — the ontology front door, and "adjust any action parameters if
  needed" at approval time.
- [Git integration → Supported items](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration#supported-items)
  — **Operations Agent *(preview)* is listed under Data Factory items**,
  linking to the pipeline page; the Real-Time Intelligence section does
  not list it. Trap confirmed by reading the rendered list.
- [Variable library overview → Supported items](https://learn.microsoft.com/fabric/cicd/variable-library/variable-library-overview#supported-items)
  — seven consumers listed (Pipeline, lakehouse shortcut, Notebook,
  Dataflow Gen 2, Copy job, User data functions, Plan). **Operations
  Agent is absent**, while the schema accepts a variable reference.
- `ms-fabric-cli` 1.7.0 on disk — `OperationsAgent` present in
  `fabric_cli/commands/find/type_supported.yaml`, absent from the
  `ItemType` enum in `fabric_cli/core/fab_types.py`.
- The live sample at
  `C:\Repos\ACME\fabric-acme\RealTime\OperationsAgent_1.OperationsAgent`
  (`.platform` 310 B, `Configurations.json` 1,683 B) and, as the control
  for the identity finding below, every `.platform` in that repo (35
  files) plus `ACME_PL_Orchestration.DataPipeline/pipeline-content.json`,
  `ACME_KDB_Operation.KQLDatabase/.platform` and
  `ACME_VL.VariableLibrary/valueSets/ENV-3P.json`.

**Not drilled, and therefore absent from the skill:**

- **The REST surface.** Operations Agent is *not* among the ~30 types in
  [Item definition overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview)
  (fetched in full 2026-09-02 — the omission is the finding). No
  create/get/update-definition payload shape was drilled, and the skill
  describes none. Same posture `fabric-realtime-dashboard` and
  `fabric-graph` already take for schema-URL-only item types.
- **Deployment pipelines → Supported items.** The wave-11 brief cites
  entry 3.9 there as well as in Git integration. Only the Git integration
  list was read this run; the skill claims Git integration support and
  says deployment-pipeline support is "also listed" without quoting a
  position.
- **The portal UI.** No click-path, no screenshots, no ribbon
  documentation beyond what the two docs pages state. Deliberate — the
  skill is about the file.
- **A round-trip of the variable reference.** The schema permits
  `$(/<Workspace>/<Library>/<Variable>)` in `dataSources`; nobody has
  confirmed the *service* resolves it. Recorded in the skill as
  schema-permits-unverified with the date, not as working behaviour.
- **A live API call.** No `az login` was available, so
  `GET /v1/workspaces/{ws}/items` was not made. This bounds the identity
  finding below to what Git alone proves.
- **A second, configured sample.** The one sample never had *Generate
  Playbook* run, so its `instructions` is `""` and `playbook` is absent.
  Every serializer observation is from that single item and is marked
  single-sample in the skill.

## Frontmatter

```yaml
---
name: fabric-operations-agent  # repo linter requires it; lowercase/digits/hyphens; ≤64 chars
description: {{see Description char count — drafted at step 6 and counted before commit}}
when_to_use: {{disambiguation against fabric-data-agent, fabric-eventhouse and Activator}}
paths:
  - "**/*.OperationsAgent/**"   # two files per item, both relevant; no narrowing needed
model: inherit                  # repo policy: inherit everywhere except commit
# effort: medium                # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false # repo policy: false everywhere
---
```

`argument-hint`, `arguments`, `allowed-tools`, `disallowed-tools`,
`context`, `background`, `agent`, `hooks`, `shell`, `metadata`,
`user-invocable`: not set — none applies to a path-scoped reference skill.

## Description char count

- `description`: 1,012 / 1,024
- `when_to_use`: 481 / 512

Both re-counted after the final wording edit, not once at the end. The
skill is conditional, so it costs nothing against the shared listing
budget until an `.OperationsAgent` file is `Read`; that is what makes the
`when_to_use` affordable, per
[when-to-use-adoption.md](when-to-use-adoption.md).

## Body structure outline

1. **Item identity** — `metadata.type` is `OperationsAgent`, folder
   `<Name>.OperationsAgent/`, definition part `Configurations.json`
   (plural, capital C), schema URL. One item type, two front doors.
2. **The ALM listing trap** — Git integration and deployment pipelines
   file it under *Data Factory*, not Real-Time Intelligence. Named early
   because it is what sends people looking in the wrong place.
3. **The definition schema** — root table (`configuration` / `playbook` /
   `shouldRun`, all required, `additionalProperties: false`), the four
   closed enums, the `connection`-iff-`FabricJobAction` rule, the
   `messageDestination` `oneOf`. This is the part that must be inline.
4. **What survives a deployment** — the identity finding: `dataSource.id`
   is the source's `.platform` `logicalId` verbatim; `jobArtifactId` is
   the target's `logicalId` **byte-reversed**; `jobWorkspaceId` is a
   plain workspace ID and is the one value that genuinely does not
   travel. Plus the schema-level asymmetry: `dataSources` accepts a
   variable reference, `fabricItemConnection` does not.
5. **`shouldRun` is deployed running state** — 0.46 CU-hours per hour per
   running agent, background usage, silent halt after 24 h over limits.
   Check it in every diff.
6. **Serializer artifacts that are not corruption** — absent `playbook`,
   duplicate `kind` key, parameter values carried in `description`,
   all-zeros `workspaceId`. Each marked single-sample.
7. **Which agent item do I want** — Operations Agent vs Data Agent vs
   Activator, in a short table. One sentence on Activator, not a section.
8. **Source constraints that shape the Eventhouse or ontology** — the
   subset of the limitations page that changes upstream design.
9. **Tooling reach** — `fab find` yes, `fab` create/address no. Reuse
   `fabric-graph`'s wording.
10. **Preview status and dated claims** — everything here is preview;
    volatile claims carry their verification date.

`references/REFERENCE.md`: the eight-condition table, instruction
authoring shape, the full billing table, availability and region
exclusions, Investigator insights, the three action-configuration paths,
and the Learn source list.

## Changes from source proposal

Derived from
[item-type-skill-operationsagent.md](item-type-skill-operationsagent.md)
(wave 11). Departures:

- **Step 3b is inverted, and this is the substantive change.** The brief
  concludes "the data source is portable across workspaces and the
  action target is not", and recommends `find_replace` in
  `fabric-cicd`'s `parameter.yml` for the action GUIDs. That does not
  survive contact with the sample. `dataSource.id` is the monitored KQL
  database's `.platform` `logicalId` **character for character**, and
  `jobArtifactId` is the target pipeline's `.platform` `logicalId` with
  its 16 bytes reversed — verified as an exact match and an involution:

  ```python
  import uuid
  rev = lambda g: str(uuid.UUID(bytes_le=uuid.UUID(g).bytes_le[::-1]))
  # illustrative synthetic pair; the real one was verified in the ACME sample
  rev("7c4d1e88-93af-4b02-9d61-2fa50c7e3b14")
  # -> '0c7e3b14-2fa5-9d61-4b02-93af7c4d1e88'
  ```

  So neither reference is a raw runtime GUID; both derive from the item's
  logicalId. The `find_replace` guidance would have been wrong, and the
  skill does not carry it. What is left of the asymmetry is real but
  narrower: it is a *schema* asymmetry — `dataSources` accepts a
  `variableReference`, `fabricItemConnection` is `additionalProperties:
  false` with no such alternative — and it constrains parameterisation,
  not portability.
- **Step 3d's "single most important thing to resolve" is *narrowed*,
  not resolved — and this brief said otherwise until the `--safe-mode`
  baseline caught it.** The evidence is real: the five action parameters
  match `ACME_PL_Orchestration.DataPipeline`'s parameter block by name,
  and each `description` string is that parameter's `defaultValue`
  rendered as text (`"false"`, `"20"`, `"Eastern Standard Time"`, `"1"`,
  `"300"`). The draft concluded from it that `description` **is** the
  value slot. **It does not follow.** Both readings — value-carrier, and
  prose that guides the LLM's runtime choice — predict exactly that
  observation, because under either one the portal seeds the field from
  the target's defaults. The docs in fact lean to the second: parameters
  are "passed when it invokes the action", and the approver "adjusts any
  action parameters if needed" in Teams, which is a runtime affordance.
  The skill now states the observation, names both readings, and says
  **do not hand-edit a `description` expecting it to pin a value** until
  someone has run the action and read what the target received. The
  discriminating test is one action invocation, not more file reading.
- **Step 3d's two-ID-families hypothesis is withdrawn.** The brief reads
  the non-RFC-4122 version nibble in `dataSource.id` as "logicalId
  shape" and the v4-shaped `jobArtifactId` as "runtime ID", concluding
  the file mixes Git-portable and non-portable references. The nibble
  observation was right and the inference from it was backwards: the
  odd nibble is what a *reversed* v4 GUID looks like. 33 of 35
  `.platform` `logicalId`s in the ACME repo reverse to valid RFC-4122 v4
  GUIDs, so the encoding is systematic rather than a property of that
  one file.
- **Investigation vs autonomous reasoning.** The brief names one
  reasoning meter; the billing page carries **two** at identical rates —
  `Investigation agent reasoning` and `Operations agent autonomous
  reasoning` — plus `Copilot in Fabric` at a lower rate for
  configuration-time LLM use. The reference file carries all three.
- **`subItemId` added.** Present in `fabricItemConnection` (optional,
  string) and in the sample as `""`; the brief's field list omits it.
- **The eventhouse-limits placement question is decided here**: the
  Eventhouse source limits live in **this** skill, not in
  `fabric-eventhouse`. They are constraints the *agent* imposes on a
  data source, and a reader hitting them is reading an
  `.OperationsAgent` file. `fabric-eventhouse` is not edited — this
  skill may not edit other skills.
- **Deferred out of scope, with somewhere to go.** Three residues the
  brief wanted placed in other files are *not* placed, because
  `/author-skill` may not edit other skills: the variable-reference
  finding into `fabric-variable-library`, the Data Agent contrast into
  `fabric-data-agent`'s `when_to_use`, and the `shouldRun` meter into
  `fabric-gotchas`. All three are `/learn` work, and the identity
  finding is bigger than any of them — see Notes.

## Tag

`personal`

## Portability caveats

N/A — personal scope. The skill sets no Claude Code-only frontmatter
beyond `when_to_use` and `paths:`, both of which the repo already uses
widely. `when_to_use` is not one of the Agent Skills spec's six fields,
so this skill would fail the claude.ai upload path — which is true of
every conditional skill here and is not a new constraint.

## Cross-reference dependencies

- `fabric-data-agent` — (a) already converted. The disambiguation
  target; named in `when_to_use` and in the body's comparison table.
- `fabric-eventhouse` — (a) already converted. Pointed at for authoring
  the monitored KQL database. Not edited.
- `fabric-gotchas` — (a) already converted. Its `PowerBIEntityNotFound`
  / logicalId-vs-runtime-ID row is pointed at, not restated.
- `fabric-graph` — (a) already converted. Source of the `fab find` /
  `ItemType` enum wording, reused rather than reinvented.
- `fabric-cicd` — (a) already converted. Pointed at for `parameter.yml`
  only where a genuinely non-portable value needs it (`jobWorkspaceId`).
- `fabric-variable-library` — (a) already converted. Referenced for the
  variable-reference syntax; its supported-items gap is recorded here
  and not fixed there.
- `claude/rules/fabric-git-serialization.md` — (b) **pending edit**.
  `**/*.OperationsAgent/**` is missing from its `paths:` list, so
  `Configurations.json` gets no serialization rule today. Same shape as
  the wave 6 `GraphModel` gap. It is a rule, not a skill, so this brief
  records it and `/test-skill` or `/commit` lands it.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**Redaction.** This repo is public. The ACME sample carries a real work
UPN, a workspace ID, and four item GUIDs; none appears in the skill, this
brief, or any example. Where the identity finding needs a worked pair, a
**synthetic** one is used and labelled as such. `docs/` and `tests/` are
gitleaks-allowlisted, so nothing mechanical would have caught a paste.

**The identity finding is bigger than this skill and is deliberately
under-claimed here.** Two facts are solid from Git alone and go in the
skill: `dataSource.id` equals the source item's `.platform` `logicalId`
verbatim, and `jobArtifactId` equals the target item's `logicalId`
byte-reversed. A third is strongly suggested and does **not** go in:
that `reverse(logicalId)` *is* the runtime item ID. The supporting
evidence is that the reversed form of the monitored KQL database's
logicalId appears elsewhere in the same repo as `itemId` in a Variable
Library item-reference value set and as `databaseItemId` in an
Eventstream — both places runtime IDs live. If it holds, it is a new and
checkable fact about something `fabric-gotchas` and `fabric-rest-api`
already document as "NOT interchangeable", and it would be worth a line
in both. It needs exactly one read-only `GET /v1/workspaces/{ws}/items`
to settle, and no `az login` was available this run. **It is queued as
its own brief** —
[logicalid-runtime-id-encoding.md](logicalid-runtime-id-encoding.md) —
rather than smuggled into this one.

**Test fixture note for `/test-skill`.** The fixture must be schema
*valid* — include `playbook: {}` — rather than copying the sample's
omission. The fixture tests the glob, not the portal's serializer, and a
fixture that reproduces a suspected serializer bug will read as the
contract later.

**Two queue rows change when this lands.** `tests/skills/fabric-triggers/`
goes from 15 conditional skills to 16 and its file count rises by two,
so the README's "10 there, 15 here … all 25" needs to become
"10 there, 16 here … all 26"; `skills/README.md`'s section heading goes
from 26 to 27.

## Confidence

- **Structure: H.** Path-scoped platform skill with a `references/`
  split is the shape a dozen `fabric-*` skills already have, and the
  glob has no narrowing question — two files per item, both relevant.
- **Field specs: H.** The schema was fetched in full and every enum,
  `required` list and conditional in the Frontmatter and body outline is
  quoted from it rather than remembered.
- **Body content: M-H.** The Learn-sourced half is H — five pages
  fetched in full this run. The serializer half is M: one sample, never
  playbook-generated, so `playbook`-absent and the duplicate `kind` key
  could be artifacts of that state rather than general behaviour. Both
  are marked single-sample in the skill. The identity finding is H for
  what it claims and deliberately silent on the part that needs an API
  call.
