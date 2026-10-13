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
- **Folded**: 2026-10-13, two more inbox notes of that day by sessions
  in the same client estate, re-measured against the payload at
  `23d41cf`.
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

One binding has been read since (the same estate, 2026-10-13): a
pipeline schedule bound to a Variable Library Boolean whose default is
`false`, in a workspace whose active value set overrides it to `true`,
read `"enabled": true` and `enabledEvalState: "Normal"` from List Item
Schedules, twice. So, by that reading, the binding resolves through the
active value set. Not reported yet: what it wrote to `.schedules`, and
whether flipping the value moves `enabled`. The estate's session
promised a note on both.

**`enabledControlType`'s other values.** Seen once, as `UserEnabled`,
after a portal edit that moved a schedule's start and end dates
(measured by the note's session, 2026-10-13). Unread: what the portal
writes when it turns a schedule off, and whether the scheduler's
auto-disable writes a value.

**`enabledDetail`, its REST view.** List Item Schedules returned an
undocumented `"enabledDetail": {"enabledControlType": "UserEnabled",
"enabledEvalState": "Normal"}` beside the documented fields, for one
Cron schedule (one read by the estate's session, 2026-10-13). Learn's
`ItemSchedule` has no such field, and Update Item Schedule's body takes
only `enabled`, `configuration` and `executionData` (both read here,
2026-10-13): a probe can read the control type without a definition
read, and cannot set it. Unread: `enabledEvalState`'s other values, the
auto-disabled state perhaps among them, and whether every item type's
schedules carry the field.

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

`skills/fabric-core/fabric-rest-api/SKILL.md` § "Job Scheduling" gains
an `enabledDetail` line once its values are read.

## Not checked

No tenant was reachable from this run, and the Git-sync sandbox held no
`.schedules` file on 2026-10-13, so a probe there starts by scheduling a
pipeline. The schema gives `parameters` items one `type`,
`VariableReference`, under `configuration`, but portal-written files
put `parameters` beside `configuration`, and a Dataflow's item was typed
`"Text"` (`fabric-data-pipeline`'s `references/REFERENCE.md`,
2026-10-13). Whether a Controller binding writes a `VariableReference`
there or a field of its own is part of the read.

## Scrubbing

The notes named the client's pipelines, stages, commits, CI workflow,
Variable Library and value set; none is carried here. The field names
and error text are Fabric's own.

## Re-measure before acting

```bash
grep -rln "enabledControlType" skills/ claude/rules/   # fabric-data-pipeline's SKILL.md and REFERENCE.md, fabric-rest-api's gotchas.md, on 2026-10-13
grep -rln "Controller" skills/fabric-*/                 # nothing on 2026-10-13
grep -rln "enabledDetail" skills/                       # nothing on 2026-10-13
```

Search Learn again for a pipeline schedule's Controller first: a
pipeline page that documents it, or its `.schedules` form, may settle
part of this without a tenant.

Read `~/handoff-inbox/agent-config/` too: the estate's session promised
a note on what its binding writes and how a flip behaves, which may
settle the Controller without a tenant.
