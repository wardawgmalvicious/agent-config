---
name: fabric-event-schema-set
description: "Use for the Microsoft Fabric Event Schema Set item (EventSchemaSetDefinition.json) — the contract a schema-associated Eventstream custom endpoint validates events against, and what silently drops an event that does not match. Covers the four description stores (eventTypes[].description, schemas[].description, versions[].description and the Avro record-level doc inside versions[].schema), the bare-Avro shape of an upload file versus the envelope the portal generates around it, the inline schema a portal save swaps in for an event type's schemaUrl, fresh-upload version reset to v1, and which route mints a version: every portal save does, even a description-only one, while a Git sync stores versions[] as pushed, so from Git append a version rather than edit one and read versions[] back after any edit. Plus serialization (an upload stored verbatim, the editor writing 1-space indent), the ancestor chain, and the item's per-file byte format (CRLF definition, LF .platform, no trailing newline)."
when_to_use: "Use when adding, editing or deleting schemas in a Fabric event schema set; deciding whether a schema edit belongs in the portal or in Git; writing a new schema version by hand in Git; authoring the Avro upload files a schema set is populated from; or working out why a schema version did or did not bump, or why a field added in Git shows nowhere in the portal, and what that broke downstream."
paths:
  - "**/*.EventSchemaSet/**"
# model: inherit  # any model: value blocks Copilot slash invocation
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Fabric Event Schema Set: the definition file and what mints a version

The **Event Schema Set** is the Real-Time Intelligence item that holds the
Avro schemas a schema-associated Eventstream checks events against —
Learn's *Schema Registry*, one item per set. This skill is about the
item's own file: its anatomy, who writes which part, and which edits make
a new version.

**Dated, and mostly observed.** Microsoft Learn documents the definition
format and that a portal update mints a version (read 2026-10-01).
Everything else was observed in two tenants' sandbox workspaces on
2026-09-10 and 2026-09-30, and re-measured from the committed file on
2026-10-01. Each claim says which it is, and §6 says where Learn is wrong
for a Git sync.

**Not here: the producer side.** The CloudEvents wire format, the
`dataschema` URI, the registry host and the destination table names
belong to `fabric-eventstream`, in its `references/cloudevents-producer.md`.
That skill loads when a file under `*.Eventstream/` is read, so open the
eventstream's `eventstream.json` rather than asking for it by name.

## 1. What the item is, and the rule that matters

- **One definition part**, `EventSchemaSetDefinition.json` (Learn). It
  holds `eventTypes[]`, each an event with its CloudEvents envelope, and
  `schemas[]`, each an Avro schema with its `versions[]`. Avro is the
  only schema format the registry supports (Learn).
- **The set validates nothing by itself.** "Registering a schema doesn't
  validate or filter events" (Learn); an eventstream's schema association
  does. A schema-associated custom endpoint checks each event against the
  version its `dataschema` URI names. **An event that does not match is
  accepted and then dropped**: the send succeeds, nothing lands, and the
  only trace is a generic *dropped per schema registry error policy*
  diagnostic on the eventstream (`fabric-eventstream`).

So **every edit to this file changes what producers are validated
against, and the version number is how they find it.** Read `versions[]`
back after any edit, by any route (§6).

## 2. The item on disk

```text
<ItemName>.EventSchemaSet/
├── .platform
└── EventSchemaSetDefinition.json
```

Two files, nothing else (measured 2026-09-10 and 2026-09-30). `.platform`
is the standard Git-integration part, schema-set specific only in its
`type`:

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json",
  "metadata": {
    "type": "EventSchemaSet",
    "displayName": "<ItemName>"
  },
  "config": {
    "version": "2.0",
    "logicalId": "<guid>"
  }
}
```

**`config.version` is not a format signal.** It is the version of the
`.platform` file's own format (Learn, *Git integration source code
format*), `2.0` for every item type, and says nothing about the
definition's. The two files also differ in byte format: §8.

The schema set's **own** name and description, set in its settings
(Learn), are the item's, not a schema's. `.platform` carries the name as
`displayName`, and Fabric's Git format gives it an optional
`metadata.description` (Learn; not observed here, where none was set).
The definition repeats the display name as a top-level `name` (§3).

## 3. Definition anatomy

| Object | Fields Learn documents | What the file adds |
| --- | --- | --- |
| root | `eventTypes`, `schemas` | `name`, the item's display name |
| `eventTypes[]` | `id`, `description`, `eventTypeCategory`, `format`, `envelopeMetadata`, `schemaUrl` or `schema`, `schemaFormat`, `protocol`, `protocolOptions` | `schema` in place of `schemaUrl` after a portal **Update** (§6) |
| `schemas[]` | `id`, `description`, `format`, `versions` | nothing |
| `versions[]` | `id`, `description`, `format`, `schema` | `ancestor`, and newest-first order (§8) |

The values the file held at every commit on 2026-09-30, as in Learn's
example:

- An event type's `format` is `CloudEvents/1.0`. Its `envelopeMetadata`
  requires string `id`, `type`, `source` and `specversion`, and
  `type.value` repeats the event type's `id`.
- `schemaFormat`, a schema's `format` and a version's `format` are all
  `Avro/1.12.0`.
- Creating a schema, by upload or in the visual builder, writes
  `"schemaUrl": "#/schemas/<id>"`; the generated event type and its
  schema share that `id`.
- `eventTypeCategory`, `protocol`, `protocolOptions` and the optional
  `description` on `schemas[]` and `versions[]` never appeared.

**`schema` is a JSON string, not an object.** Every `versions[].schema`,
and an event type's inline `schema`, holds the Avro record serialized
into a string, so the file shows it as one line of `\n` and `\"`. Parse
it twice:

```python
import json

d = json.loads(open(path, "rb").read())
record = json.loads(d["schemas"][0]["versions"][0]["schema"])
```

`schemaUrl` and an inline `schema` are mutually exclusive (Learn), and
the file respects that: an event type carries one or the other.

## 4. The four description stores

| Store | Written by | Filled by an upload? |
| --- | --- | --- |
| `eventTypes[].description` | the create form's optional description, and **Update** | yes on 2026-09-30, from the record `doc`; typed by hand on 2026-09-10 |
| `schemas[].description` | optional on Learn's page; no portal route seen | no |
| `versions[].description` | optional on Learn's page; no portal route seen | no |
| the record-level `doc`, inside `versions[].schema` | the Avro you author | yes, verbatim |

**They are unrelated fields once set.** An upload fills the event-type
description from the record `doc`, verbatim (2026-09-30), and nothing
keeps the two in step afterwards: a later event-type description edit
left the record `doc` as uploaded. Field-level `doc`s live inside the
record and survive an upload verbatim (2026-09-10 and 2026-09-30).

**The event-type description's cap is unestablished.** 265 characters
was rejected at upload (2026-09-10) and 257 accepted on **Update**
(2026-09-30), so the cap sits between 258 and 265, or differs between the
two forms. Keep it to 257. No cap was found on a record `doc`, where 214
characters uploaded. Learn gives a limit only for the schema set's own
name: fewer than 256 UTF-8 characters.

## 5. What you author, and what the portal generates

**You author a bare Avro record; Fabric generates everything around
it.** An upload file is the record alone — `type`, `name`, `fields`, and
an optional `namespace` and `doc` — kept in a file such as `.avsc`;
"Event payloads aren't schema definitions" (Learn). The event type, its
envelope, the `schemas[]` entry and its first version are generated.

```json
{
  "type": "record",
  "name": "Customers",
  "doc": "A customer as registered, one record per sign-up.",
  "fields": [
    { "name": "customerId", "type": "string", "doc": "Customer identifier, unique per source system" },
    { "name": "registeredAt", "type": "long", "doc": "When the customer registered, epoch milliseconds UTC" },
    { "name": "region", "type": "string", "doc": "Sales region code" }
  ]
}
```

- **The create form fills its name and description from the file**
  (2026-09-30), the description from the record `doc`. Which part of the
  file supplies the name is unknown, since the test's file and record
  shared one. On 2026-09-10, in the other tenant, both had to be typed.
- **The upload is stored byte for byte** as `v1`: key order, indentation
  and a final newline all survive (2026-09-30). The portal does not
  canonicalize it, but its next save rewrites the text (§8).
- **There are four ways in** (Learn): upload a file, build in **Schema
  view**, paste into **Code view**, or **Import** several files at once —
  one or more schemas, one or more versions of each. The registry assigns
  the version numbers, not the file names, so check the grouping and order
  its review shows. Only the upload and the visual builder were seen
  writing the file.
- **Download** on a schema saves its definition (Learn); the shape of the
  downloaded file was not examined.

## 6. Versioning: the route decides

**Whether an edit makes a version depends on how it reaches the service,
not on what changed.**

| Route | New version? | Basis |
| --- | --- | --- |
| Portal **Update** that reaches **Finish** | **Yes, every time**: a field `doc`, an event-type description, even Avro byte-identical to the last version | Learn; three saves, 2026-09-30 |
| A new schema, by upload | Starts at `v1`, even where a deleted schema of that name had reached `v4` | 2026-09-10; `v1` again 2026-09-30 |
| **Import** of several versions | One per file, numbered by the registry | Learn; not observed |
| Git sync, an existing entry edited | **No**: it changes in place, a structural change included | 2026-09-30; `doc` only, 2026-09-10 |
| Git sync, a hand-written entry added | **Yes, as written**: accepted as the next version | 2026-09-30 |
| Git sync, an event type's inline `schema` alone changed | **No**: stored, and shown nowhere | 2026-09-30 |
| REST `updateDefinition` | Untested | none |

A portal version goes to the **head** of `versions[]`, its `ancestor`
naming the one before (§8).

**Learn's definition page is wrong for a Git sync.** Its line "A new
version is created when a new schema is provided to the EventType item"
is contradicted by the last Git row, which provided one and minted
nothing. Don't quote it as the rule. Content doesn't decide either: the
portal minted a byte-identical schema, and Git did not mint a structural
change.

**The inline copy can diverge from the head, unseen.** A portal
**Update** swaps an event type's `schemaUrl` for an inline `schema`
byte-identical to the newest version (three saves, 2026-09-30). An edit
to that copy alone, synced from Git, minted nothing, left the
workspace's Source control with nothing to commit, and showed nowhere in
the portal, whose schema pages read `versions[]` only. So the service
presumably stored it as pushed; that is inferred, not read back through
REST `getDefinition`. Which copy a producer is validated against is
untested, and the next portal save presumably overwrites the inline one.

**What stays untested is the event-level half of every Git row**:
whether the registry that validates events follows an in-place edit, a
hand-written version or a diverged inline copy. The item-level facts are
observed; what producers would then hit is inferred.

So:

1. **Make any change producers will see in the portal.** It mints, and
   minting is documented.
2. **From Git, append a version; never edit one.** Write the next `id`
   at the head of `versions[]` with `ancestor` naming the current head,
   and, where the event type carries an inline `schema`, the same text
   there, as a portal save would.
   [references/editing-from-git.md](references/editing-from-git.md) has a
   script that writes it in the bytes the portal would.
3. **After any edit, by any route, read `versions[]` back.** Confirm that
   the version each producer's `dataschema` names still exists and still
   describes what producers send. The same reference has a read-back
   script that also flags a diverged inline copy.

**History is not a rollback** (Learn). Viewing an earlier version doesn't
restore it, and deleting a schema isn't a way back to one. A comparison
isn't a compatibility check, and the UI exposes no compatibility policy.

## 7. Why the version is load-bearing

A version id travels further than this file:

- **The producer pins it**: the `dataschema` URI ends `/versions/vN`.
- **The destination names tables by it**: an Eventhouse destination
  creates its tables as `{CloudEventType}_{CloudEventSchemaVersion}`,
  such as `Orders_v2`, the version taken from the `dataschema` URI.
- **Whatever reads those tables inherits it**: a control-table row naming
  the version, a shortcut to the versioned table.

The first two are `fabric-eventstream`'s, with the evidence. So an
unnoticed portal bump leaves producers naming a version that is no longer
current, and an in-place Git edit changes a version under producers that
still name it. The symptom is the same either way: events accepted and
then dropped. After a new version the destination may also need
publishing again before it routes it, which `fabric-eventstream` presumes
and has not tested.

## 8. Byte format and serialization

| | `EventSchemaSetDefinition.json` | `.platform` |
| --- | --- | --- |
| Line endings | CRLF, every line | LF |
| Final newline | none; the last byte is `}` | none; the last byte is `}` |
| BOM | none | none |

Measured 2026-09-10, 2026-09-30 and 2026-10-01. A fixture written by an
ordinary editor gets LF and a final newline in both, and stops looking
like the item.

**Keep Git from translating them.** A `-text` attribute on the workspace
tree is what lets both round-trip (2026-09-30). `text eol=lf` would strip
the definition's CRs, which every portal commit writes back.

**The whole file is `json.dumps(d, indent=2)` with CRLF.** Re-serializing
the 2026-09-30 item that way — keys in the order read, each `\n` made
`\r\n`, no final newline — reproduced it byte for byte (measured
2026-10-01, on ASCII-only content; how Fabric escapes other text is
unmeasured).

**The schema strings take two forms.**

- An **upload** is stored verbatim (§5).
- Everything the **portal editor** writes — the visual builder's `v1`,
  each Update, the inline copy — is exactly `json.dumps(record,
  indent=1)` with no final newline, as is Learn's example. A Git edit
  serialized that way round-trips with nothing to commit (2026-09-30). So
  the first portal save after an upload makes a version that differs from
  `v1` in whitespace, even when nothing else changed.

On 2026-09-10 the other tenant's editor output read as 2-space; whether
that was a difference between tenants or a change since is unknown.

**Version order and `ancestor`.** `versions[]` lists the newest first. A
first version names itself, `"id": "v1"` with `"ancestor": "v1"`, and
each later one names the one before. Ids run `v1`, `v2` and on, never
semantic versions (Learn). Up to three versions per schema were seen on
2026-09-30, in the file and in the portal's History.

## 9. Gotchas

| Issue | Cause | Fix |
| --- | --- | --- |
| A field added in Git shows nowhere in the portal | It went into an event type's inline `schema`; the portal's schema pages read `versions[]` only | Append a version carrying the field, and keep the inline copy equal to it (§6) |
| A Git edit didn't bump the version | A Git sync stores `versions[]` as pushed | Append a version instead of editing one |
| The version bumped though only a description changed | Every portal **Update** that reaches **Finish** mints | Expected: point each producer's `dataschema` at the new version |
| A re-uploaded schema came back as `v1` | A fresh upload is a new schema; numbering follows the schema, not its name | Re-point every `dataschema` at a version that exists now |
| An event-type description is rejected | Over a cap between 258 and 265 characters (§4) | Keep it to 257 |
| `v1` keeps the upload's indent and final newline, and the next save rewrites them | An upload is stored verbatim; the editor writes `indent=1` | Expected: compare versions parsed, not as text |
| Every line of the definition shows as changed | Line endings translated by `text` or `eol=lf` | Set `-text` on the workspace tree and restore the CRLF bytes |
| `.platform` `config.version` taken for the definition format | It is the `.platform` format's own version, `2.0` everywhere | Ignore it |
| Events dropped after a schema edit | The version producers name moved, or changed in place | §7, then `fabric-eventstream`'s producer reference |

## 10. Constraints

- **Never edit an existing `versions[]` entry from Git.** It changes in
  place under the producers that name it (§6).
- **Read `versions[]` back after every edit**, portal included, and check
  each producer's `dataschema` against it.
- **Until a producer has run against a Git-written version, make
  structural changes in the portal.** Whether the validating registry
  follows a Git sync is untested.
- **Don't quote Learn's "a new version is created when a new schema is
  provided" as the rule.** A Git sync contradicts it.
- **Keep the bytes**: a CRLF definition, an LF `.platform`, no final
  newline and no BOM in either, and `-text` to keep Git out of it.
- **Say so when you reach the untested edge.** Untested here: adding or
  deleting a whole schema from Git; REST `getDefinition` and
  `updateDefinition`, and whether the latter mints; deployment
  pipelines, beyond `fabric-eventstream`'s note that schema-enabled
  eventstreams don't survive one with their registries intact; business
  events (`eventTypeCategory` `BusinessEventType`); and the create form's
  description cap. Schema Registry itself went GA in September 2026
  (What's New), and Learn says it "also manages any schemas that you
  create as part of Business Events" (2026-10-06): documentation, not a
  test, so business events stay on this list.

Scripts for the Git route — reading `versions[]` back, and appending a
version in the portal's bytes — are in
[references/editing-from-git.md](references/editing-from-git.md).
