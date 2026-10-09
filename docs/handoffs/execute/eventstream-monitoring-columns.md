---
status: open
priority: 3
needs: [tenant]
blocked-by: []
written: 2026-10-08
---

# Handoff: Eventstream's monitoring samples filter on a column Learn no longer lists

- **Written**: 2026-10-08, by a `/triage` sweep, from one audit
  follow-up: the 2026-10-06 `fabric` audit's
  [brief 06](../../audits/2026-10-06/fabric/completed/06-update-eventstream-connectors-and-monitoring.md),
  whose live check no session could run. Re-measured against the
  payload at `b0a8b24`, which changed nothing here.
- **Kind**: a measurement in a Fabric tenant, then an edit to three KQL
  samples.

## What is open

`skills/fabric/fabric-eventstream/references/monitoring.md` gives the
Eventstream monitoring tables' base columns as `ItemId`, `ItemName` and
`ItemKind`, from Learn on 2026-10-06, but its three KQL samples still
filter on `ArtifactId` (lines 24, 31 and 39 on 2026-10-08), under a
dated note that they are unmeasured against the new schema. No
workspace monitoring database was reachable on 2026-10-06 to say which
column a current one carries.

## Where it lands

The three samples in `references/monitoring.md`, and the unmeasured
note above them (line 19), which goes once they are measured.
`fabric-eventstream`'s routing retest is not this brief's:
`skill-status.py --stale` lists the skill as `retest-routing`.

## Not checked

Whether any workspace on a tenant this machine reaches has workspace
monitoring on and an eventstream with **Log Eventstream activity**
enabled. Learn says enabling workspace monitoring does not turn the
second on.

## Re-measure before acting

```bash
grep -n 'where ArtifactId' skills/fabric/fabric-eventstream/references/monitoring.md   # lines 24, 31, 39 on 2026-10-08
```

In the monitoring database, a `getschema` on any of the four
`EventStream*` tables says which ID column the samples should filter on.
