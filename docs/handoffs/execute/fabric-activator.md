# Skill handoff brief: fabric-activator

Last verified: 2026-09-12

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

`skills/fabric/fabric-activator/SKILL.md`, plus
`references/reflex-entities.md` and `references/rest-and-errors.md`.

Deployable payload, `fabric` group. On this machine that group is
**pruned from user scope** by the documented
`link-claude.ps1 -SkillGroups workflow,social` run, so this skill enters
no session's payload here and needs no linker run — nothing is broken
when it stays unlinked. It reaches a client repo through
`link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups fabric`
or `copy-copilot.ps1 -SkillGroups fabric`, both of which pick up a new
skill in the group automatically.

## Scope

One skill covering the Fabric Activator item (`Reflex` in the API and in
Git) end to end: what the definition looks like on disk and over REST,
how to author and inspect rules, and the limits, costs and
lifecycle-management exclusions that decide whether any of it works.
Inline execution, model-invocable, and **path-scoped** on
`**/*.Reflex/**` and `**/*.Activator/**`. Authoring and consumption are
deliberately one skill rather than two, following upstream's own
consolidation of `activator-authoring-cli` and
`activator-consumption-cli` into a single `activator-cli` at v0.3.11:
the two halves share one entity model, and splitting them would make the
model choose between two descriptions that both half-match the same
item.

## Sources drilled

Drilled 2026-09-12, firsthand in the main session — no subagents, so
every quote below was read by the session that wrote this brief. About
a dozen distinct pages plus one real item.

**Learn — item definition and REST**

- ◆ `rest/api/fabric/articles/item-management/definitions/reflex-definition`
  — the whole structural basis. "Reflex is also known as **Activator**.
  Both names refer to the same item type"; the two definition parts
  (`ReflexEntities.json` required, `.platform` not); "The
  `ReflexEntities.json` part contains a JSON **array** of entity
  objects"; the seven entity types (`container-v1`,
  `simulatorSource-v1`, `kqlSource-v1`, `realTimeHubSource-v1`,
  `eventstreamSource-v1`, `fabricItemAction-v1`, `timeSeriesView-v1`);
  `uniqueIdentifier` / `parentContainer.targetUniqueIdentifier` /
  `parentObject.targetUniqueIdentifier` wiring; per-type payload tables;
  the `timeSeriesView-v1` four-way split through `definition.type`
  (`Event` / `Object` / `Attribute` / `Rule`); template IDs
  (`SourceEvent`, `SplitEvent`, `IdentityPartAttribute`,
  `IdentityTupleAttribute`, `BasicEventAttribute`, `EventTrigger`,
  `AttributeTrigger`); the three rule action types (`TeamsMessage`,
  `EmailMessage`, `FabricItemInvocation`) with their property tables;
  `definition.settings.shouldRun`; and the load-bearing escaping rule —
  "The `definition.instance` property stores the template configuration
  as a **JSON-encoded string** (not a nested JSON object). You must
  escape this string". Also the platform-part rule that
  `updateDefinition` accepts `.platform` "only if you set the URL
  parameter `updateMetadata=true`", and the Tip that the practical way
  to get a valid template instance is to configure the item in the UI
  then call Get Item Definition.
- ◆ `rest/api/fabric/reflex/items` — there is a **dedicated Reflex API
  namespace**, not only Core Items: Create / Delete / Get / Get
  Definition / List / Update / Update Definition Reflex.
- ◆ `rest/api/fabric/reflex/items/create-reflex` — `POST
  /v1/workspaces/{workspaceId}/reflexes`; `displayName` is the required
  request-body field (`CreateReflexRequest`); *contributor* workspace
  role; `Reflex.ReadWrite.All` or `Item.ReadWrite.All`; LRO with 201 or
  202 + `Location` + `x-ms-operation-id` + `Retry-After`; error codes
  `InvalidItemType`, `ItemDisplayNameAlreadyInUse`, `CorruptedPayload`,
  `WorkspaceItemsLimitExceeded`; `description` capped at 256 chars.
- ◆ `rest/api/fabric/reflex/items/get-reflex-definition` — the
  permission trap. "The caller must have *read and write* permissions
  for the reflex", scopes `Reflex.ReadWrite.All` or
  `Item.ReadWrite.All`; it is a **POST** to `.../getDefinition`, supports
  LRO, and "This API is blocked for a Reflex with an encrypted
  sensitivity label."
- ◆ `rest/api/fabric/reflex/items/list-reflexes` — the other half of
  that asymmetry: *viewer* workspace role, `Workspace.Read.All` or
  `Workspace.ReadWrite.All`, a plain `GET`, paginated by
  `continuationToken`, with `recursive` and `rootFolderId` filters.
- `rest/api/fabric/articles/item-management/item-management-overview` —
  "Reflex is also known as Activator"; and that a create request cannot
  carry both a definition and a payload.
- `rest/api/fabric/articles/onelakecatalog/overview` — Reflex has a
  type-specific Get endpoint that "currently return[s] the same metadata
  as the generic Get Item API".

**Learn — behaviour, limits, cost**

- ◆ `fabric/real-time-intelligence/data-activator/activator-limitations`
  — every number the skill quotes. 10,000 events/second/rule and
  "Activator stops your rule" past it; 500 rules per Activator item; the
  action-limit table (Email 500/item/hour and 30/rule/recipient/hour;
  Teams 500/item/hour, 30/rule/recipient/hour, 100/recipient/hour,
  50/tenant/second; Power Automate 10,000/rule/hour; **Fabric item
  activations 50/user/minute**); email recipients must be internal and
  on a verified tenant domain, never external or guest; Teams channels
  unsupported and group chats must be recently active; and the
  **lifecycle-management exclusions** — an Activator using Azure Blob
  Storage events, Power BI as a data source, or a User Data Function as
  an action errors when you try to deploy or commit it. Plus the
  preview→GA migration history (read-only Jan 2025, deleted March 2025),
  the supported Power BI visual and Real-Time Dashboard tile lists, and
  the Power BI ingestion metric-ownership trap.
- ◆
  `fabric/real-time-intelligence/data-activator/activator-capacity-usage`
  — the four meters and their CU(hr) rates (rule uptime 0.02222/hour,
  event ingestion 0.000011111/event, event computations
  0.00000278/computation, storage 0.00177/GB/hour); 30-day event
  retention; interactive vs background split; and the flagged Important:
  "Pausing or stopping a rule doesn't stop the event listener. The event
  listener continues to run and incur capacity consumption until the
  rule is removed." Also "Active rules incur costs even if no data is
  ingested into them."
- ◆
  `fabric/real-time-intelligence/data-activator/activator-troubleshooting`
  — the complete error-code catalogue across four groups (data
  ingestion, rule evaluation, exceeded capacity, alert and action), the
  symptom/cause/remediation table, and the four built-in diagnostics.
- `fabric/real-time-intelligence/data-activator/ingestion/ingestion-overview`
  — the source taxonomy the skill uses: **query** sources (Power BI, KQL
  Querysets, Real-Time Dashboards — Activator runs a query on a
  schedule) versus **streaming** sources (Eventstreams, Fabric events,
  Azure events — pushed continuously).
- `fabric/real-time-intelligence/data-activator/rule-actions` — the
  seven Fabric item types a rule can run (Dataflow, Pipeline, Spark job,
  Notebook, Function, Copy job, Publish business event (preview)) and
  "The **Copy job** type doesn't accept parameters."
- `fabric/real-time-intelligence/data-activator/activator-trigger-fabric-items`
  — the parameter coercion tables. Activator accepts string, boolean and
  number (float); `1,234.56` parses, `123,45` yields **0**, and
  null/whitespace/any other string yields 0 or false. Invalid input
  coerces silently rather than failing.
- `fabric/real-time-intelligence/data-activator/activator-alert-queryset`
  — alerts are supported only against KQL databases **inside an
  Eventhouse**, not an external Azure Data Explorer cluster; and an
  alert query on a 1- or 5-minute interval "effectively keeps Eventhouse
  in an **always-on** state".
- ◆ `fabric/real-time-intelligence/mcp-remote-activator` — the preview
  remote MCP server: the URL shape
  `https://api.fabric.microsoft.com/v1/mcp/workspaces/<Workspace ID>/reflexes/<Artifact ID>`,
  OAuth via Entra, the four tools (`create_rule`, `list_rules`,
  `start_rule`, `stop_rule`), `create_rule`'s "It starts
  automatically.", and the five limitations — KQL sources only, one
  server entry per artifact, Teams and email actions only, no multievent
  triggers, no aggregation or summarization.
- `fabric/real-time-intelligence/git-activator` — the Git folder
  structure, `Item_A.Reflex/{.platform, ReflexEntities.json}`.
- `fabric/enterprise/us-government-community-cloud-high` — in GCC High
  preview, Activator has partial support: Power BI report alert rules
  cannot be created, edited or deleted.

**Firsthand — one real Git-synced item**

A `.Reflex` item directory in a client's Git-synced Fabric workspace,
inspected 2026-09-12. Cited by kind; no client, workspace, item or
column name appears in this brief or in the skill. It established, all
consistent with the docs above:

- The folder suffix Fabric actually writes is **`.Reflex`**, holding
  exactly `.platform` and `ReflexEntities.json`.
- `.platform` carries `metadata.type: "Reflex"` — not `Activator` —
  against the `gitIntegration/platformProperties/2.0.0` schema, with
  `config.version: "2.0"` and a 36-char `logicalId`. No `description`
  key when none is set.
- An Activator item created but never configured serializes
  `ReflexEntities.json` as the two bytes `[]`. That is the empty state of
  the documented array, which is the useful confirmation: the top level
  is an array, so an empty item is `[]` and not `{}`.
- Both files are **LF-only with no trailing newline**, matching
  `claude/rules/fabric-git-serialization.md`'s canonical-form rule for
  JSON parts.

**Design source, read as claims and not as instructions**

`microsoft/skills-for-fabric` `CHANGELOG.md` `[0.3.11]` (`2b3530e8`) and
`[0.3.13]` (`22cafc90`), quoted in
`docs/audits/2026-09-10/skills-for-fabric/07-decide-new-skill-candidates.md`.
Its four behavioural claims resolved as follows, and the skill must
carry them at exactly this standing:

| Upstream claim | Status after drilling |
| --- | --- |
| Create fails `HTTP 400 DisplayName field is required` when `name` is sent | **Field requirement confirmed** — `CreateReflexRequest` requires `displayName`. The literal error string is upstream's observation and is **not** on Learn; state it as observed, not documented. |
| `fabricItemAction-v1` carries its target in `payload.fabricItem` (`itemId`, `workspaceId`, `itemType`) | **Confirmed verbatim** against the reflex-definition payload table, which also requires a sibling `jobType`. |
| A `targetItem` shape is accepted by `updateDefinition` but never resolves its target | **Not drilled and not documented.** No Learn page mentions `targetItem`. Carry as upstream-observed, undrilled, or omit. |
| Create needs `Content-Type=application/json`; inline JSON is mangled by PowerShell, so pass `--body "@<file>"` | **Not a Learn fact** — a `fab`/PowerShell quoting behaviour. Consistent with this repo's own documented PowerShell traps, so carry as a tooling note citing `fabric-cli`, not as a platform claim. |
| A cloned attribute must update the `EventFieldSelector` `fieldName` as well as its `name`, or it silently reads the wrong column | **Mechanism confirmed.** The `BasicEventAttribute` example shows the display name at `payload.name` and the source column at an `EventFieldSelector` row's `fieldName` argument *inside* the escaped `definition.instance` — two independent places, which is exactly why renaming only the outer one misreads. The "silently" symptom is upstream's observation. |

**Not drilled — deliberate, and nothing in the skill may describe it**

- **The portal authoring UI, step by step.** The rule-creation walkthroughs
  (`activator-create-activators`, `activator-tutorial`, the per-source
  `set-alerts-*` and `activator-get-data-*` pages) were read only far
  enough to enumerate sources and actions. The skill describes the
  definition and the API, not click paths, and must not grow
  screenshots-in-prose.
- **`activator-latency`** was never opened. Nothing in the skill may
  state a latency figure, a lookback window, or a late-arrival
  tolerance. The troubleshooting table's "Unexpected latency (over 30s)"
  row is the only latency claim available and it is a symptom row, not a
  specification.
- **Power Automate custom actions** (`activator-trigger-power-automate-flows`)
  — named as an action type only. No flow-side detail.
- **Ontology-authored rules** (`fabric/iq/ontology/how-to-use-rules`) —
  seen in search only. It is real and it routes rules into an Activator
  item, but `fabric-ontology` owns that ground; the skill mentions the
  relationship and stops.
- **Business events as a publish target** — confirmed to exist as a
  preview action type. The Real-Time hub schema-registry half is
  `fabric-event-schema-set`'s, still queued.
- **Anything about Activator in a deployment pipeline beyond the
  documented exclusions.** No pairing, autobinding or deployment-rule
  behaviour was drilled.
- **No tenant was called.** Every REST claim is from the API reference;
  no request in this brief was executed. The only firsthand evidence is
  the two files on disk described above.
- **No `fab` CLI verb was verified.** Whether `fab` has first-class
  Activator/Reflex commands was not established; the skill must route
  CLI work to `fabric-cli` rather than inventing a command.

## Frontmatter

```yaml
---
name: fabric-activator  # repo linter requires it; lowercase/digits/hyphens; ≤64 chars
description: <see Description char count — the entire model-invoked trigger surface>
when_to_use: <the glob note plus the neighbour routing; see the pointer-reachability note in Notes>
paths:  # NARROWS activation: withheld from the startup listing until a matching file is Read
  - "**/*.Reflex/**"
  - "**/*.Activator/**"
disable-model-invocation: false  # ALWAYS PRESENT; repo policy false everywhere
# model: inherit  # ALWAYS PRESENT, ALWAYS COMMENTED — an active model: key of any value blocks Copilot slash dispatch and fails lint-frontmatter.py
# effort: max   # commented on every platform skill, which therefore inherits the session level
---
```

Both glob arms are kept deliberately. `.Reflex` is the suffix Fabric
demonstrably writes — the Git-integration page shows only `.Reflex`, and
so does the one real item inspected — so `**/*.Activator/**` is
defensive against the portal name ever being used for a folder. It costs
nothing while the skill is conditional, and it matches
`claude/rules/fabric-git-serialization.md`, which already globs both.

## Description char count

- `description`: recount after drafting, cap 1,024
- `when_to_use`: recount after drafting, cap 512

The two are enforced separately by `DESCRIPTION_MAX` and
`WHEN_TO_USE_MAX` and sum to the 1,536 listing truncation point. Put the
literal tokens a request will carry in the **first sentence** — for this
skill that is `Activator`, `Reflex`, `ReflexEntities.json`, `rule` and
`alert`. Because the skill is conditional it is out of the startup
listing entirely, so the aggregate listing budget is not the binding
constraint here; the per-field caps are.

## Body structure outline

1. **The item, and its two names.** Reflex ≡ Activator. `.Reflex`
   folder with `.platform` + `ReflexEntities.json`; `metadata.type` is
   `Reflex`; LF, no trailing newline. An empty item is `[]`.
2. **The entity model.** The seven types as a table; the
   `uniqueIdentifier` graph and the two parent references; how
   `timeSeriesView-v1` covers Event, Object, Attribute and Rule through
   `definition.type`. Point at `references/reflex-entities.md` for the
   per-type payload tables and the worked end-to-end example.
3. **`definition.instance` is an escaped JSON string.** The single
   highest-value trap in the format, and the reason hand-authoring is a
   poor idea. State the documented route: configure in the UI, then
   `getDefinition`, then edit the retrieved instance. Include the
   clone-an-attribute failure — `payload.name` and the
   `EventFieldSelector` `fieldName` are two different places.
4. **The REST surface.** The Reflex namespace's seven operations with
   verb, permission and scope. Lead with the asymmetry: **List needs a
   viewer role; `getDefinition` needs read *and* write** and is blocked
   outright by an encrypted sensitivity label — so "just inspect it" is
   not a read-only operation. `displayName` not `name`. LRO on create
   and getDefinition. `updateMetadata=true` for `.platform`. Full error
   lists go to `references/rest-and-errors.md`.
5. **Sources.** Query sources versus streaming sources, and what each
   implies for rule behaviour. The Eventhouse-only restriction on KQL
   queryset alerts, and the always-on cost consequence of a 1–5 minute
   alert query.
6. **Actions.** The three definition-level action types against the
   seven portal item types; Copy job takes no parameters; the silent
   coercion of bad numbers and booleans to 0 / false.
7. **Inspecting an existing item.** List → getDefinition → base64
   decode → walk the array by `uniqueIdentifier` → read
   `settings.shouldRun` to tell a live rule from a saved one.
8. **The remote MCP server (preview).** URL shape, the four tools, and
   its five limitations. Flag the asymmetry worth knowing: `create_rule`
   starts a rule automatically, while the documented definition example
   ships `shouldRun: false`.
9. **Limits.** 500 rules per item; 10,000 events/s stops the rule; the
   action-throttle table; email internal-only; no Teams channels.
10. **Cost, and the one that surprises people.** The four meters;
    stopping a rule does not stop its event listener — only deleting it
    does; active rules bill with no data flowing; 30-day event
    retention.
11. **Git and lifecycle management.** The serialization rules, then the
    exclusion list: Blob Storage events source, Power BI source, or UDF
    action means commit and deployment **error**. This is the section a
    Git-synced repo reader most needs and the reason the glob is worth
    having.
12. **Boundaries.** Which neighbour owns what, written so the pointers
    are reachable — see Notes.

`references/reflex-entities.md`: per-entity payload tables, template
catalogue, the step/row/argument anatomy, and the complete decoded
example. `references/rest-and-errors.md`: the seven operations in full,
and the four error-code groups with cause and fix.

## Changes from source proposal

Derives from
`docs/audits/2026-09-10/skills-for-fabric/07-decide-new-skill-candidates.md`,
whose execution log records the user accepting all four candidates for
`/author-skill` on 2026-09-11. Departures from that brief's framing:

- **Named `fabric-activator`, not `fabric-reflex` or `activator-cli`.**
  The portal and every request use "Activator"; `Reflex` is carried in
  the description as a trigger token and throughout the body as the API
  and Git name. Chosen with the user, 2026-09-12, on the same reasoning
  that mapped `onelake-catalog-govern-cli` to
  `fabric-catalog-governance`.
- **One skill, not two.** Matches upstream's own v0.3.11 consolidation
  rather than the `pbir-cli` / `pbir-report-workflow` split.
- **Conditional rather than unconditional**, unlike
  `fabric-catalog-governance`. Settled with the user against a real
  `.Reflex` item, which made the glob's trigger surface concrete rather
  than hypothetical. The cost is recorded in Notes.
- **The upstream CLI framing is dropped.** Upstream is an
  `activator-cli`; this skill is definition-and-REST reference plus
  gotchas, matching how every other `fabric-*` skill here is shaped, and
  routes actual CLI invocation to `fabric-cli`.

## Tag

`personal`

## Portability caveats

Claude Code-only frontmatter: `paths:` and the commented `effort:`.
Under GitHub Copilot `paths:` warns and is **ignored**, so a vendored
copy in `<repo>/.github/skills` is **unconditional** there — it is in
the listing from the start, which inverts this skill's whole activation
design. Two consequences for the draft: the body must not assume a
`.Reflex` file is open, and the `when_to_use` glob sentence reads as
false on that surface. `copy-copilot.ps1` applies no frontmatter
transformation.

## Cross-reference dependencies

All (a) already converted, except as marked:

- `fabric-eventstream` — owns the Activator **destination** and the
  `Set alert` flow, including `references/activator-destination.md`.
  Glob-scoped on `**/*.Eventstream/**`, so **disjoint from this skill**.
- `fabric-eventhouse` — the KQL database behind a `kqlSource-v1` and
  behind queryset alerts. Glob-scoped, disjoint.
- `fabric-copy-job` — already states that Activator can trigger a Copy
  job and that Copy job actions take no parameters. Glob-scoped,
  disjoint. Keep the two statements consistent; do not edit it here.
- `fabric-mlv` — the auto-created "FMLV Refresh" Notebook + Activator
  pair. Glob-scoped, disjoint.
- `fabric-operations-agent` — already routes deterministic non-LLM
  alerting to Activator, and stores a `PowerAutomateAction` connection in
  an Activator item. Glob-scoped, disjoint.
- `fabric-rest-api` — LRO polling and `continuationToken` pagination,
  both of which this skill's surface uses. **Unconditional**, so
  reachable by name.
- `fabric-auth` — token audiences for Fabric REST. Unconditional.
- `fabric-cicd` — deployment pipelines and Git integration, where the
  lifecycle-management exclusions bite. Unconditional.
- `fabric-cli` — where `fab` invocation and `fab api` passthrough live,
  including the `--body "@<file>"` form. Unconditional.
- `claude/rules/fabric-git-serialization.md` — (c) a rule, not a skill.
  Already globs `**/*.Reflex/**` and `**/*.Activator/**`, so it
  **co-loads on the same files** as this skill. Do not restate its EOF
  and line-ending policy; cite it.
- `fabric-event-schema-set` — (b) **pending**, queued at
  `docs/handoffs/execute/fabric-event-schema-set.md`. Owns the business
  event schema registry that Activator's preview publish action targets.
  Reference the relationship without depending on the file existing.
- `.vscode/mcp.template.json` — (c) this repo's own template, which
  already carries an `activator-remote-mcp` entry whose URL matches the
  drilled Learn shape exactly. Cite it as the wiring example.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**Every neighbour worth pointing at is glob-scoped and disjoint from
this one.** `fabric-eventstream`, `fabric-eventhouse`,
`fabric-copy-job`, `fabric-mlv` and `fabric-operations-agent` all carry
`paths:` globs that no `.Reflex` file matches, so a by-name pointer to
any of them is **dead** from a session this skill activated in — the
model calls the Skill tool, gets `Unknown skill`, and reports the skill
as not installed. That is the exact failure measured on
`pbir-filters` → `pbir-themes`, 2026-09-04. So in the draft: point at
`fabric-rest-api`, `fabric-auth`, `fabric-cicd` and `fabric-cli` **by
name** (all unconditional, all reachable), and point at every
glob-scoped neighbour **by the file that activates it** — "open the
`.Eventstream` item's definition" rather than "use `fabric-eventstream`".
This is the single most likely thing to get wrong in the draft.

**What the glob costs, recorded so the decision can be revisited.** A
conditional skill is withheld from the startup listing, so cold,
`/fabric-activator` answers `Unknown command` and a worded request
("alert me when the pipeline fails") matches nothing. Much of the real
Activator surface — creating a rule over REST, choosing an action,
reading a throttling error — arrives that way rather than as a `.Reflex`
file being opened. The user chose the house pattern anyway, with a real
item in hand as the trigger case. Revisit only on evidence: a session
where Activator work was clearly wanted and the skill never loaded.

**The fixture is owed, and `expected_activations.md` already says so.**
`tests/skills/fabric-triggers/expected_activations.md` lists `Reflex`
under **Known gaps** — "No `Environment`, `Reflex`, `MirroredDatabase`,
`CopyJob` or `SparkJobDefinition` fixture. None has a conditional skill
today… Add the fixture *with* the glob, in the same commit." That is
`/test-skill`'s work, not this run's. The conditional-skill count in
that file moves 27 → 28, and both new globs need a `-StaticOnly` pass.

**The shape to model it on, recorded here so the cold run does not need
this session.** Taken from the real Git-synced item, genericized — no
client, workspace or item name. Two files in
`<name>.Reflex/`, both **LF with no trailing newline**:

`ReflexEntities.json` — the two bytes `[]`, which is the empty state of
the documented array, not a stub.

`.platform` — five keys, no `description` when none is set:

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json",
  "metadata": { "type": "Reflex", "displayName": "<name>" },
  "config": { "version": "2.0", "logicalId": "<36-char guid>" }
}
```

`metadata.type` is **`Reflex`**, not `Activator` — worth asserting in
the fixture, since it is the evidence that the `**/*.Activator/**` glob
arm is defensive rather than observed. A fixture for that second arm has
no real item behind it; write it as a synthetic negative-to-positive
control and say so, rather than implying Fabric produces it.

**Two follow-ups are outside `/author-skill`'s edit scope and must not
be forgotten.** Both were verified as still outstanding on 2026-09-12,
after the draft landed:

1. **`.claude/settings.json` `skillOverrides` does not cover this
   skill.** Measured: 43 platform skills on disk, 42 override entries,
   and `fabric-activator` is the only one missing. That block is a
   by-name map with no pattern form, so a new skill is **silently
   uncovered** — and this is a repeat: commit `1c64590`,
   *fix(settings): cover fabric-catalog-governance in skillOverrides*,
   is the previous `/author-skill` run being caught by exactly this.
   Add the entry in the commit that lands this skill. Re-derive rather
   than trusting the count above.
2. **The `skills-for-fabric` registry gains a counterpart row.**
   `activator-cli` → `fabric-activator` belongs in the table at
   `.claude/skills/drift-audit/references/sources.md:619`, next to
   `onelake-catalog-govern-cli` → `fabric-catalog-governance`, so
   clause 1 of that source's filter stops re-surfacing it as an
   unauthored candidate. Note in the prose there that this was the
   second worked case.

The `skills/README.md` entry and the Fabric section count 30 → 31 were
both done in this run.

**Two other accepted candidates remain unstarted**: `dataflows-cli` and
`deployment-pipelines-authoring-cli`. Neither is a dependency of this
one.

## Confidence

- **Structure — H.** Item-per-skill is the settled `fabric-*` pattern,
  the tree and group are unambiguous, and the glob follows the rule and
  the co-loading serialization rule both.
- **Field specs — H.** Frontmatter follows current repo policy; both
  caps are re-counted at draft time; the `paths:` arms are copied from a
  rule that already ships them.
- **Body content — H for the definition, REST, limits and cost halves**,
  all quoted firsthand from the API reference and the limitations and
  capacity pages, with the serialization confirmed against a real item.
  **M for the four upstream behavioural claims**, which are graded
  individually in the table above and must reach the draft at that
  grading rather than flattened into fact. **L for anything portal- or
  latency-shaped**, which is why both are on the not-drilled list and
  must stay out.
