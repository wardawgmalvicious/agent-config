# Editing an Event Schema Set from Git

The two scripts behind `SKILL.md` §6: one reads `versions[]` back, the
other appends a version. Both were run on 2026-10-01 against a copy of a
real definition, two schemas at three versions each, one with a diverged
inline copy. What each run does and does not prove is under each script.

## Reading versions back

Run it after every edit, by any route, portal included:

```python
import json
import sys

# Usage: python readback.py <Name>.EventSchemaSet/EventSchemaSetDefinition.json
d = json.loads(open(sys.argv[1], "rb").read())
heads = {s["id"]: s["versions"][0] for s in d.get("schemas", []) if s.get("versions")}

for s in d.get("schemas", []):
    chain = ", ".join(f"{v['id']} (ancestor {v.get('ancestor')})" for v in s.get("versions", []))
    print(f"schema {s['id']}: {chain}")

for et in d.get("eventTypes", []):
    if "schema" in et:
        head = heads.get(et["id"])
        if head is None:
            print(f"event type {et['id']}: inline schema, no schema of that id")
        elif et["schema"] == head["schema"]:
            print(f"event type {et['id']}: inline schema matches {head['id']}")
        else:
            print(f"event type {et['id']}: inline schema DIFFERS from {head['id']}")
    else:
        print(f"event type {et['id']}: schemaUrl {et.get('schemaUrl')}")
```

On the test copy it printed this, names changed:

```text
schema Orders: v3 (ancestor v2), v2 (ancestor v1), v1 (ancestor v1)
schema Customers: v3 (ancestor v2), v2 (ancestor v1), v1 (ancestor v1)
event type Orders: inline schema matches v3
event type Customers: inline schema DIFFERS from v3
```

- **Check the head against every producer's `dataschema`.** The first
  version listed is the current one; a producer naming another is pinned
  to it (`SKILL.md` §7).
- **`DIFFERS` is the divergence** the portal never shows (`SKILL.md`
  §6): fix it by appending a version, not by editing either copy.
- **It pairs an inline event type with the schema of the same `id`**,
  which is how the portal generates them (`SKILL.md` §3). A set whose ids
  differ needs its own pairing.
- **It reads the file, not the service.** Whether the registry serves
  what the file says after a Git sync is untested.

## Appending a version

```python
import json

path = "<Name>.EventSchemaSet/EventSchemaSetDefinition.json"
schema_id = "Customers"
record = {  # the whole new Avro record, not a diff
    "type": "record",
    "name": "Customers",
    "doc": "A customer as registered, one record per sign-up.",
    "fields": [
        {"name": "customerId", "type": "string", "doc": "Customer identifier, unique per source system"},
        {"name": "registeredAt", "type": "long", "doc": "When the customer registered, epoch milliseconds UTC"},
        {"name": "region", "type": "string", "doc": "Sales region code"},
        {"name": "segment", "type": "string", "doc": "Marketing segment"},
    ],
}

d = json.loads(open(path, "rb").read())
schema = next(s for s in d["schemas"] if s["id"] == schema_id)
head = schema["versions"][0]                    # newest first
text = json.dumps(record, indent=1)             # the editor's form: 1-space, no final newline
schema["versions"].insert(0, {
    "id": f"v{int(head['id'][1:]) + 1}",
    "format": head["format"],
    "schema": text,
    "ancestor": head["id"],
})
for et in d["eventTypes"]:
    if et["id"] == schema_id and "schema" in et:
        et["schema"] = text                     # keep the inline copy equal to the new head

out = json.dumps(d, indent=2).replace("\n", "\r\n")
open(path, "wb").write(out.encode("utf-8"))     # bytes: text mode on Windows doubles the CR
```

**What it wrote on the test copy**: one entry at the head of
`versions[]`, its `id` one past the head's, its `ancestor` the old head
and its `format` copied from it, and the inline `schema` set to the same
text. Nothing else changed: CRLF on every line, no BOM, `}` the last
byte. Then commit, push, update the workspace from Git, and run the
read-back.

What that run proves, and what it does not:

- **It proves the bytes.** The file comes out as a portal save would
  write it (`SKILL.md` §8), so the commit shows the appended version and
  nothing else.
- **It does not prove Fabric accepts it.** A Git sync accepted a
  hand-written version once, on 2026-09-30 (`SKILL.md` §6).
- **It does not prove the registry validates against it.** Untested:
  until a producer has run against one, make structural changes in the
  portal.

Three things the script assumes:

- **Ids are `v<n>`**, and the head is the highest, since `versions[]`
  lists the newest first (`SKILL.md` §8).
- **ASCII content.** `json.dumps` escapes anything else as `\uXXXX`,
  and how Fabric writes such text is unmeasured; compare the bytes Fabric
  commits back before trusting the round trip.
- **The record is whole.** It becomes the version's entire schema, so
  copy the head's record and change it rather than writing only the new
  field.

## The event type before and after a portal Update

Key order, from the committed file on 2026-09-30:

| State | Keys, in file order |
| --- | --- |
| Created by upload or in the visual builder | `id`, `description`, `format`, `envelopeMetadata`, `schemaUrl`, `schemaFormat` |
| After any portal **Update** | `id`, `description`, `format`, `envelopeMetadata`, `schemaFormat`, `schema` |

So the swap moves the schema reference from before `schemaFormat` to
after it, as well as inlining it. A Git edit that adds `schema` while
keeping `schemaUrl` breaks Learn's mutual exclusion; what a sync does
with that is untested.
