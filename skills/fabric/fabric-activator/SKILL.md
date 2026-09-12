---
name: fabric-activator
description: "Use for Microsoft Fabric Activator — the `Reflex` item type (Reflex and Activator are the same item) that watches data and fires rules and alerts. Covers `ReflexEntities.json` as Git and REST see it: a flat JSON array of entities wired by `uniqueIdentifier`, with `definition.instance` an escaped JSON string and not a nested object; the `/reflexes` REST namespace and its permission split — List needs only a viewer role, but `getDefinition` needs read AND write; `displayName` not `name` on create; query sources (Power BI, KQL queryset, Real-Time Dashboard) versus streaming (Eventstream, Fabric events, Azure Blob events); actions and their silent parameter coercion (Copy job takes none, a bad number becomes 0); the preview remote MCP server; and the limits and costs that bite — 500 rules per item, 10,000 events/s stops a rule, stopping a rule does not stop its billed event listener, and a Blob-events source, Power BI source or User Data Function action makes a Git commit or a deployment fail."
when_to_use: "Fires on any file under `*.Reflex/` or `*.Activator/`, so `ReflexEntities.json` and `.platform` both match and `fabric-git-serialization` co-loads. The definition, REST surface and gotchas — not the portal click-path. For an Eventstream's Activator destination, or the KQL database behind a `kqlSource-v1`, open that item's own definition file: those skills are glob-scoped elsewhere and unreachable by name from here. `fabric-rest-api`, `fabric-auth`, `fabric-cicd` and `fabric-cli` are reachable by name."
paths:
  - "**/*.Reflex/**"
  - "**/*.Activator/**"
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: max   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Fabric Activator (the `Reflex` item)

Activator watches data and takes an action when a condition is met. It
is the **deterministic, non-LLM** half of Fabric's reactive story.

**`Reflex` and `Activator` name the same item type.** Learn says so
outright, and the split is consistent: `Activator` is the portal and
product name, `Reflex` is what the REST API, the `ItemType` enum, the
`.platform` file and the Git folder suffix all use. Expect both in the
same sentence and do not treat a `Reflex` in a payload as a different
thing.

Three neighbours own adjacent ground, and **two of them cannot be
reached by name from here** — their `paths:` globs do not match a
`.Reflex` file, so naming them yields `Unknown skill`. Open the item's
own definition file instead:

| Adjacent work | How to get there |
| --- | --- |
| Wiring an Activator destination onto an Eventstream, or `Set alert` from one | Open the `.Eventstream` item's definition |
| The KQL database a `kqlSource-v1` queries | Open the `.Eventhouse` / `.KQLDatabase` item's definition |
| LRO polling, `continuationToken` pagination, token audiences | `fabric-rest-api`, `fabric-auth` — both reachable by name |
| `fab` invocation and `fab api` passthrough | `fabric-cli` — reachable by name |

## 1. What is on disk

A Git-synced Activator is a `<name>.Reflex/` directory holding exactly
two files:

| File | Required | What it is |
| --- | --- | --- |
| `ReflexEntities.json` | yes | The whole configuration — sources, objects, attributes, rules |
| `.platform` | no (over REST) | Fabric platform metadata; `metadata.type` is `Reflex` |

`.Reflex` is the suffix Fabric actually writes — the Git-integration
docs show only that form, and so did the one real item measured for this
skill (2026-09-12). The payload also globs `**/*.Activator/**`
defensively; do not read that as evidence the portal name is ever used
for a folder.

**Both files are JSON parts, so canonical form is LF with no final
newline.** `claude/rules/fabric-git-serialization.md` co-loads on these
same paths and owns that policy — follow it there rather than restating
it. Observed on a real item: LF-only, no trailing newline, both files.

**An Activator created but never configured serializes as `[]`.** Two
bytes. That is not an error and not an empty object — it is the empty
state of an array, which is the useful thing to know before you write a
parser against it.

## 2. `ReflexEntities.json` is a flat array

The top level is a **JSON array of entity objects**, not an object with
named sections. Every entity carries the same three properties:

```json
[
  { "uniqueIdentifier": "<guid>", "payload": { }, "type": "<entity-type>" }
]
```

Structure lives in the **references between entities**, not in nesting.
Entities point at each other by `uniqueIdentifier` through two parent
properties:

- `payload.parentContainer.targetUniqueIdentifier` — on every entity
  except the container itself.
- `payload.parentObject.targetUniqueIdentifier` — on attribute and rule
  views, naming the object they belong to.

Seven entity types exist:

| `type` | Role |
| --- | --- |
| `container-v1` | Top-level grouping; everything else references one |
| `simulatorSource-v1` | Simulated data, for prototyping a rule |
| `kqlSource-v1` | A KQL query against an Eventhouse, on an interval |
| `realTimeHubSource-v1` | Workspace events from Real-Time hub |
| `eventstreamSource-v1` | A Fabric Eventstream |
| `fabricItemAction-v1` | A Fabric item a rule can invoke |
| `timeSeriesView-v1` | Events, objects, attributes **and** rules |

`timeSeriesView-v1` is the one that carries the logic, and it wears four
hats distinguished only by `payload.definition.type` — `Event`,
`Object`, `Attribute` or `Rule`. So counting rules means filtering the
array on that nested value, not on `type`.

Per-entity payload tables, the template catalogue and a full decoded
example are in
[references/reflex-entities.md](references/reflex-entities.md).

## 3. `definition.instance` is an escaped string, not an object

The highest-value trap in the format. A time series view's logic lives
in `payload.definition.instance`, and Learn is explicit: it "stores the
template configuration as a **JSON-encoded string** (not a nested JSON
object). You must escape this string."

So the real logic is one level of escaping down. Editing it means
parsing a string out of JSON, parsing *that* as JSON, editing, and
re-serialising both ways. Two consequences:

- **Do not hand-author a template instance.** The documented route is
  the reliable one: configure the item in the portal, call
  `getDefinition`, then modify the retrieved instance. Learn recommends
  exactly this.
- **A cloned attribute has two places holding the column.** The display
  name is `payload.name`; the column it actually reads is a `fieldName`
  argument on an `EventFieldSelector` row *inside* the escaped
  `instance`. Renaming the outer one alone leaves the clone reading the
  original column. Upstream reports this failing silently, with no error
  — that symptom is an observation rather than documented, but the
  two-places mechanism is confirmed by the `BasicEventAttribute` example
  in the definition reference.

## 4. REST — the `/reflexes` namespace

There is a dedicated Reflex service, not just Core Items: Create,
Delete, Get, Get Definition, List, Update, Update Definition.

**Lead with the permission asymmetry, because it inverts the obvious
assumption.**

| Operation | Verb | Workspace role | Delegated scope |
| --- | --- | --- | --- |
| List Reflexes | `GET .../reflexes` | viewer | `Workspace.Read.All` |
| Create Reflex | `POST .../reflexes` | contributor | `Reflex.ReadWrite.All` or `Item.ReadWrite.All` |
| Get Reflex Definition | `POST .../reflexes/{id}/getDefinition` | **read *and write* on the item** | `Reflex.ReadWrite.All` or `Item.ReadWrite.All` |

**Reading a definition is not a read-only operation.** There is no
`Reflex.Read.All` route to it. A least-privilege inventory job can list
Activators with a viewer role and get names, IDs, descriptions,
sensitivity labels and tags — but the moment it wants to know *what
rules exist inside*, it needs write access. Plan the identity
accordingly, and say so rather than requesting write silently.

`getDefinition` is also **blocked outright for a Reflex carrying an
encrypted sensitivity label**, so a governed tenant can have items no
automation can read.

Four more things that bite:

- **`displayName`, not `name`.** `CreateReflexRequest` requires
  `displayName`; `description` is optional and capped at 256
  characters. Upstream reports sending `name` failing with `HTTP 400
  DisplayName field is required` — the field requirement is documented,
  that exact string is upstream's observation.
- **Create and `getDefinition` are long-running.** Either can answer
  `202` with `Location`, `x-ms-operation-id` and `Retry-After` instead
  of `201`/`200`. Poll; `fabric-rest-api` owns the pattern.
- **`.platform` is ignored on update unless you ask.** `updateDefinition`
  accepts the platform part "only if you set the URL parameter
  `updateMetadata=true`".
- **A request cannot carry both a definition and a payload.**

Operation-by-operation detail and the full error catalogue are in
[references/rest-and-errors.md](references/rest-and-errors.md).

## 5. Sources — query versus streaming

The split decides how a rule behaves, so establish which one you have
before debugging why a rule did not fire.

| Kind | Sources | How data arrives |
| --- | --- | --- |
| **Query** | Power BI, KQL Queryset, Real-Time Dashboard, Warehouse SQL query (preview) | Activator runs a query on a schedule and evaluates rules against the results |
| **Streaming** | Eventstream, Fabric events, Azure Blob Storage events | Events are pushed continuously as they occur |

Two consequences worth knowing up front:

- **KQL queryset alerts need an Eventhouse.** Only queries against KQL
  databases *within an Eventhouse* are supported; a queryset pointed at
  an external Azure Data Explorer cluster cannot carry an alert.
- **A frequent alert query defeats Eventhouse idle savings.** An alert
  query on a 1- or 5-minute interval "effectively keeps Eventhouse in an
  always-on state" — Eventhouse idles down only after more than five
  minutes with no queries or ingestion.

Query-based sources also bind data differently and may create objects
automatically; the object-assignment workflow is for streaming sources.

## 6. Actions

The definition knows three action types — `TeamsMessage`,
`EmailMessage`, and `FabricItemInvocation`, which references a
`fabricItemAction-v1` entity by its `uniqueIdentifier`. The portal
exposes seven runnable Fabric item types: Dataflow, Pipeline, Spark job,
Notebook, Function, Copy job, and Publish business event (preview).

- **A `fabricItemAction-v1` carries its target in
  `payload.fabricItem`** — `itemId`, `workspaceId`, `itemType` — with a
  sibling `jobType`. Upstream additionally reports that a `targetItem`
  shape is accepted by `updateDefinition` yet never resolves its target;
  **that is undrilled and appears nowhere in the docs**, so treat it as
  an unverified warning, not a rule.
- **Copy job accepts no parameters.** Every other runnable type does.
- **Bad parameter values coerce silently.** Activator takes string,
  boolean and number (float). `1,234.56` parses to 1234.56 and `1e3` to
  1000, but `123,45` yields **0**, and null, whitespace or any other
  string yields 0 or `false`. Nothing errors — the job runs with a wrong
  value. Define the parameter name and type exactly as the target item
  does.
- **User Data Functions take the full type set** the function supports,
  including `list[]` and `dict`.

## 7. Inspecting an existing Activator

1. `List Reflexes` for names and IDs — viewer role is enough.
2. `getDefinition` for the parts (needs write; see §4).
3. Base64-decode the `ReflexEntities.json` part.
4. Walk the array, indexing by `uniqueIdentifier`, then follow
   `parentContainer` and `parentObject` to rebuild the tree.
5. Filter `timeSeriesView-v1` on `definition.type == "Rule"` to find
   rules, and read `definition.settings.shouldRun` to tell a **running**
   rule from a merely saved one. The documented example ships
   `shouldRun: false`.

In a Git-synced repo, steps 1–3 are replaced by reading the file — which
is also what activates this skill.

## 8. The remote MCP server (preview)

Fabric ships an HTTP MCP endpoint scoped to **one** Activator item:

```
https://api.fabric.microsoft.com/v1/mcp/workspaces/<Workspace ID>/reflexes/<Artifact ID>
```

OAuth against Entra; this repo's `.vscode/mcp.template.json` already
carries a matching `activator-remote-mcp` entry. Four tools:
`create_rule`, `list_rules`, `start_rule`, `stop_rule`.

**`create_rule` starts the rule automatically**, where the definition
path ships `shouldRun: false`. A rule made this way is live — and
billing — from creation.

Its limits are narrow enough to check before reaching for it: **KQL data
sources only**, one server entry **per artifact**, **Teams and email
actions only**, no multi-event correlation, and **no aggregation** —
conditions evaluate individual events. Anything involving a Fabric item
action, an Eventstream source, or an average over a window is out of
scope for the MCP path and belongs in the definition.

## 9. Limits

| Limit | Value |
| --- | --- |
| Rules per Activator item | **500** (any source mix) |
| Incoming events/second/rule | **10,000** — past it, Activator **stops the rule** |
| Fabric item activations | 50/user/minute |
| Email | 500/item/hour; 30/rule/recipient/hour |
| Teams | 500/item/hour; 30/rule/recipient/hour; 100/recipient/hour; 50/tenant/second |
| Power Automate | 10,000 flow executions/rule/hour |

Exceeding the event rate **stops** the rule rather than shedding load,
which is the one to design around.

**Recipients are constrained too.** Email goes only to internal
addresses on the creator's tenant or a verified domain — never external
or guest. Teams **channels are not supported at all**, private channels
included, and a group chat must be recently active to be selectable.

Also unsupported: alerts on a report using Dynamic M parameters, alerts
from the Capacity Metrics app, and alerts from a SQL analytics endpoint.
In GCC High preview, Power BI report alert rules cannot be created,
edited or deleted.

## 10. Cost — stopping a rule does not stop the bill

Four meters, in CU-hours: **rule uptime** 0.02222/hour (a flat charge
while a rule is active), **event ingestion** 0.000011111/event, **event
computations** 0.00000278/computation, **storage** 0.00177/GB/hour with
all events retained 30 days.

**The one that surprises people, flagged Important on Learn:**

> Pausing or stopping a rule doesn't stop the event listener. The event
> listener continues to run and incur capacity consumption until the
> rule is removed.

So **delete** a test rule; stopping it is not enough. And "active rules
incur costs even if no data is ingested into them" — a stale rule on a
dead stream still bills rule uptime. Audit for stale and redundant rules
rather than assuming an idle Activator is free.

Stateful computations — lookbacks, cross-event calculations — are
materially more expensive than per-event evaluation. A Real-Time hub
subscription is owned by the Activator, so its listener and event
operations bill against the Activator item under the Azure/Fabric events
rates, not the table above.

## 11. Git and lifecycle management — the exclusion list

**An Activator using any of these cannot be committed or deployed:**

- Azure Blob Storage events as a data source
- Power BI as a data source
- Fabric User Data Functions as an action

Include one in a deployment pipeline or a Git-integrated workspace and
you get an error on commit or deploy. Support is stated as planned, not
present. This is the first thing to check when an otherwise healthy
workspace fails to sync one item — the failure is a property of the
Activator's *contents*, not of the repo, so nothing about the Git
configuration will explain it. Deployment pipelines and Git integration
themselves are `fabric-cicd`'s.

One more ownership trap that survives a sync: a Power BI ingestion's
metric is owned by whoever created it, and only that user can query it.
Change the credentials or lose their access and ingestion stops —
recreate the ingestion and its rules under the new user.

## 12. Gotchas

| Symptom | Cause | Fix |
| --- | --- | --- |
| `getDefinition` returns 401/403 for a user who can see the item | Definition read needs **write**, not read | Grant write, or stay with `List Reflexes` metadata |
| `getDefinition` fails on one item only | Encrypted sensitivity label blocks the API | No API route; read it in the portal |
| Create returns 400 about `DisplayName` | `name` sent instead of `displayName` | Use `displayName` |
| Commit or deploy fails for one Activator | A Blob-events source, Power BI source, or UDF action | §11 — no workaround |
| Rule silently stopped | Over 10,000 events/s | Reduce event rate or narrow the rule |
| A job ran with a 0 or `false` parameter | Silent coercion of an unparseable value | Match the target item's parameter name and type exactly |
| A cloned attribute reads the wrong column | Only `payload.name` was changed, not the `EventFieldSelector` `fieldName` | Edit both, inside the escaped `instance` |
| Consumption continues after stopping every rule | Event listeners outlive stopped rules | Delete the rules |
| Alert spam on every matching event | A stateless operator where a transitional one was meant | Use `BECOMES` / `INCREASES` / `DECREASES` |
| Rule never fires, no error | Field-name or type mismatch binding rule to data | Check the live sample; Activator can fail to bind silently |

Activator emails an error code when something breaks after creation, and
the recipients are configurable under **Home > Settings > Notifications**.
Every code, grouped by stage, with cause and fix, is in
[references/rest-and-errors.md](references/rest-and-errors.md).

## 13. Before activating a rule

- **Preview it.** Activator can show how often the rule *would* have
  fired on historical data. Use it on any high-volume stream.
- **Prefer stateful operators** so a value sitting past a threshold does
  not re-alert forever.
- **Add a heartbeat rule** to catch a stream going silent — a rule that
  never fires and a source that died look identical otherwise.
- **Check the ceiling**: 500 rules per item, and the per-recipient
  throttles, before designing a fan-out.

## Reference

- [references/reflex-entities.md](references/reflex-entities.md) —
  per-entity payloads, template catalogue, decoded example
- [references/rest-and-errors.md](references/rest-and-errors.md) —
  the seven operations, and every error code
- Learn: [Reflex definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/reflex-definition)
- Learn: [Activator limitations](https://learn.microsoft.com/fabric/real-time-intelligence/data-activator/activator-limitations)
- Learn: [Activator capacity consumption and billing](https://learn.microsoft.com/fabric/real-time-intelligence/data-activator/activator-capacity-usage)
- Learn: [Troubleshoot Activator errors](https://learn.microsoft.com/fabric/real-time-intelligence/data-activator/activator-troubleshooting)
- Learn: [Ingestion overview](https://learn.microsoft.com/fabric/real-time-intelligence/data-activator/ingestion/ingestion-overview)
- Learn: [Remote MCP server for Activator (preview)](https://learn.microsoft.com/fabric/real-time-intelligence/mcp-remote-activator)
- Learn: [Activator GitHub integration](https://learn.microsoft.com/fabric/real-time-intelligence/git-activator)

## See also

- `fabric-rest-api` — LRO polling, `continuationToken` pagination
- `fabric-auth` — token audiences for Fabric REST
- `fabric-cicd` — deployment pipelines, Git integration
- `fabric-cli` — `fab` and `fab api` passthrough
- `claude/rules/fabric-git-serialization.md` — co-loads on these paths
- Open the `.Eventstream` or `.Eventhouse` item's definition to reach the
  skills that own those (they cannot be named from here)
