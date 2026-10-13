---
status: open
priority: 3
needs: [tenant]
blocked-by: []
written: 2026-10-13
---

# Handoff: what a schedule's Controller and `enabledControlType` write to `.schedules` is unread

- **Written**: 2026-10-13, from one inbox note of 2026-10-13 by a
  session in a client Fabric repo whose CI turns pipeline schedules off
  on `main`. Re-measured against the payload at `a981b7d`, which named
  neither the field nor the Controller; the note's main learning landed
  in this run as `fabric-data-pipeline` § 7's fifth trap.
- **Kind**: an investigation in a Fabric tenant, then an edit to that
  trap and its reference row. Nothing is drafted.

## What is open

**The Controller.** Learn's *Schedule a user data function* page lists
a **Controller** setting, "Variable used to control execution from
variable library", and a search found no pipeline page that names one
(both 2026-10-13). A pipeline's *Edit schedule* pane has it all the
same, by the user's screenshots as the note relays them (2026-10-13): a
*Controller* with *Select variable*, warning that the variable's Boolean
value will set the schedule's on/off property. So a Variable Library may
switch a schedule per environment where CI now edits `enabled`. Unread:
what a bound schedule writes to `.schedules`, and whether Git sync and
deployment pipelines keep the binding. The note's inference, untested:
`enabledControlType` records whether the user or a variable sets
`enabled`.

**`enabledControlType`'s other values.** Seen once, as `UserEnabled`,
after a portal edit that moved a schedule's start and end dates
(measured by the note's session, 2026-10-13). Unread: what the portal
writes when it turns a schedule off, and whether the scheduler's
auto-disable writes a value.

**Other items' `.schedules`.** Whether a notebook's or a user data
function's file carries the field, and whether Git sync checks it there
too. Learn's two `.schedules` screenshots, a pipeline's and a
notebook's, show none (viewed 2026-10-13).

## Where it lands

`skills/fabric-engineering/fabric-data-pipeline/SKILL.md` § 7: the
`enabledControlType` trap, which names the Controller first if the
binding survives Git sync and deployment. Its `references/REFERENCE.md`
§ "`.schedules` — full schema": the `enabledControlType` row. A body
edit owes what `uv run --with pyyaml scripts/skill-status.py --stale`
lists afterwards. A user data function finding goes to
`fabric-user-data-functions-skill.md`, deferred; no skill covers a
notebook's `.schedules` on 2026-10-13.

## Not checked

No tenant was reachable from this run, and the Git-sync sandbox held no
`.schedules` file on 2026-10-13, so a probe there starts by scheduling a
pipeline. The schema gives `configuration.parameters` items one `type`,
`VariableReference`: whether a Controller binding writes there or to a
field of its own is part of the read.

## Scrubbing

The note named the client's pipelines, stages, commits and CI workflow;
none is carried here. The field names and error text are Fabric's own.

## Re-measure before acting

```bash
grep -rln "enabledControlType" skills/ claude/rules/   # fabric-data-pipeline's SKILL.md and REFERENCE.md, fabric-rest-api's gotchas.md, on 2026-10-13
grep -rln "Controller" skills/fabric-*/                 # nothing on 2026-10-13
```

Search Learn again for a pipeline schedule's Controller first: a
pipeline page that documents it, or its `.schedules` form, may settle
part of this without a tenant.
