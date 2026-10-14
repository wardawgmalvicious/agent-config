---
status: deferred
priority: 3
needs: [tenant]
blocked-by: []
reopen-when: a workspace on a tenant this machine reaches has workspace monitoring collecting and an eventstream with Log Eventstream activity on
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

`skills/fabric-realtime/fabric-eventstream/references/monitoring.md` gives the
Eventstream monitoring tables' base columns as `ItemId`, `ItemName` and
`ItemKind`, from Learn on 2026-10-06, but its three KQL samples still
filter on `ArtifactId` (lines 24, 31 and 39 on 2026-10-14), under a
dated note that they are unmeasured against the new schema. No
workspace monitoring database was reachable on 2026-10-06 or
2026-10-14 to say which column a current one carries.

## Where it lands

The three samples in `references/monitoring.md`, and the unmeasured
note above them (line 19), which goes once they are measured. Its
**Monitoring tables** link names `fabric-workspace-monitoring-tables`,
which Learn merged into the overview on 2026-08-21 (`93d46317`), leaving
a redirect: point it at `fabric-workspace-monitoring#monitoring-tables`.
No retest follows: the skill's routing retest ran 2026-10-13 (brief
06's log), and an edit under `references/` owes none.

## Checked 2026-10-14

No reachable workspace had workspace monitoring on, so nothing was
measured.

- **Tenants.** In the client tenant this machine is signed in to, no
  item in any of its 20 workspaces had a type or name mentioning
  monitoring (`GET /v1/workspaces/{id}/items`). The personal tenant was
  not signed in.
- **Setup is portal-only.** Learn documents Workspace settings →
  **Monitoring** (`fundamentals/enable-workspace-monitoring`), and a
  Learn search found no REST route. Two choices there are permanent:
  the destination Eventhouse, and an Operations Agent once added.
- **A database may not be enough.** "A supported table might not appear
  until the corresponding item generates telemetry"
  (`fundamentals/workspace-monitoring-overview`), so the `getschema` may
  also need an eventstream with **Log Eventstream activity** on that has
  emitted. Learn says enabling workspace monitoring does not turn that
  setting on.
- **Learn disagrees with itself.** `fabric-workspace-monitoring` has
  listed `ItemId` since MicrosoftDocs/fabric-docs `ae219681`
  (2026-09-29), whose message reads "Adjusted existing table
  descriptions and column names for clarity".
  `query-fabric-workspace-monitoring-data` still filters on `ArtifactId`,
  last edited in `7173f7bc` (2026-08-24). A GitHub code search of the
  `microsoft` org for `EventStreamMetrics` found no sample or template to
  settle it.

## Re-measure before acting

```bash
grep -n 'where ArtifactId' skills/fabric-realtime/fabric-eventstream/references/monitoring.md   # lines 24, 31, 39 on 2026-10-14
```

Re-read Learn's query page, whose samples filtered on `ArtifactId` on
2026-10-14. In the monitoring database, a `getschema` on any of the four
`EventStream*` tables says which ID column the samples should filter on.
