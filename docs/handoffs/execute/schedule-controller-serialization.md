---
status: open
priority: 3
needs: [tenant]
blocked-by: []
written: 2026-10-13
---

# Handoff: a schedule's Controller through a deployment pipeline, and `enabledControlType`'s other values, are unread

- **Written**: 2026-10-13, from one inbox note of 2026-10-13 by a
  session in a client Fabric repo whose CI turns pipeline schedules off
  on `main`. Re-measured against the payload at `a981b7d`, which named
  neither the field nor the Controller; the note's main learning landed
  in this run as `fabric-data-pipeline` § 7's fifth trap.
- **Folded**: 2026-10-13, two more inbox notes of that day by sessions
  in the same client estate, re-measured against the payload at
  `23d41cf`.
- **Folded**: 2026-10-13, a further inbox note from the same estate,
  which read what a Controller binding writes and timed a flip each
  way. Re-measured against the payload at `240d023`, which named none
  of its fields; its correction to `fabric-rest-api`'s schedule types
  landed in that run.
- **Folded**: 2026-10-13, a fourth inbox note from the same estate,
  which brought the first binding by Git sync into a workspace that
  never had one. Re-measured against the payload at `cf7a595`, which
  changed nothing this brief names.
- **Kind**: an investigation in a Fabric tenant, then edits to that
  trap, its reference rows, `fabric-rest-api`'s Job Scheduling and
  `fabric-variable-library`. Nothing is drafted.

## What is open

**The Controller.** Learn's *Schedule a user data function* page lists
a **Controller** setting, "Variable used to control execution from
variable library", and a search found no pipeline page that names one
(both 2026-10-13). A pipeline's *Edit schedule* pane has it all the
same, by the user's screenshots as the note relays them (2026-10-13): a
*Controller* with *Select variable*, warning that the variable's Boolean
value will set the schedule's on/off property. So a Variable Library may
switch a schedule per environment where CI now edits `enabled`. Git
sync kept a binding once (below); whether a deployment pipeline does is
unread.

**What a binding writes** is a field of its own at the entry level, not
a `VariableReference` parameter. One binding's portal commit changed
two lines of the schedule's entry and nothing else in the file, and a
`getDefinition` read afterwards matched it byte for byte (measured by
the estate's session, 2026-10-13):

```diff
-      "enabled": true,
-      "enabledControlType": "UserEnabled",
+      "enabledVariableReference": "$(/**/<library>/<variable>)",
+      "enabledControlType": "VariableReferenceManaged",
```

`jobType`, `configuration` and the entry's `"parameters": []` kept their
values, and the reference takes the `$(/**/<library>/<variable>)` form
of a shortcut's target and `notebookutils.variableLibrary.get()`. So
`enabledControlType` records whether the user or a variable sets the
schedule, as the first note inferred. The 1.0.0 schema requires
`enabled` on every entry, beside `jobType` and `configuration`
(re-fetched here, 2026-10-13), so a bound entry fails the published
schema while the portal writes it and the scheduler runs it: a third way
the schema trails the portal. A script that flips `enabled` has nothing
to flip there: the estate's CI selects `.enabled == true` or
`.enabledControlType == "UserEnabled"`, and neither matched. Written in
this form and brought by Git sync into a workspace that never had one, a
binding was kept (below), so the portal's two lines can be written by
hand; one brought by a deployment pipeline is not seen.

**When a flip takes effect.** The binding resolves through the active
value set: the variable's default is `false`, the workspace's active
value set overrides it to `true`, and the schedule read `enabled` as
`true`. The schedule reads the variable on a timer, and List Item
Schedules gives the next read as
`enabledDetail.nextResolveVariableReferenceDateTime`. One Cron schedule
on a 15-minute interval, flipped once each way and read through List
Item Schedules and List Item Job Instances (the estate's session,
2026-10-13, times UTC):

| When | What |
| --- | --- |
| 14:55 | `enabled` `true`, control type `VariableReferenceManaged`, `enabledEvalState` `Normal`; next read 14:57:21 |
| 14:57 to 14:58 | Next read moved to 15:12:23; a run started at 14:58:02 |
| 15:13:09 | A portal edit set the override to `false` and was committed; a run had started at 15:13:04 |
| by 15:14:50 | `enabled` `false`; next read 15:28:23 |
| 15:28 and 15:43 | Neither slot ran; after 15:28:23 the next read moved to 15:44:23, so a schedule that is off still reads |
| 15:31:36 to 15:32:08 | An update from Git restored `true`; the library's live value set then matched the commit byte for byte |
| 15:32:15 | `enabled` still `false`; next read 15:44:23 |
| by 15:45:41 | `enabled` `true`; next read 16:00:23 |
| 15:46:03 | A scheduled run started, and completed at 15:47:15 |

So a portal edit took effect within two minutes, ahead of the next
read, while a value that came by Git sync waited about 12 minutes for
it; one that comes by deployment probably waits too (inferred). Reads
came 15 then 16 minutes apart, the schedule's own interval, so whether
they follow it or a fixed timer is unknown. Saving the binding moved
the run times, from 14:00, 14:15 and 14:30 to 14:43:01 and 14:58:02, as
turning the schedule back on did (15:46:03). An earlier note of the day
put the portal flip at "about a minute"; the table bounds it. Learn's
*Job scheduler in Microsoft Fabric* warns that a variable library in a
schedule's parameters may sync late after CI/CD (read here,
2026-10-13); the table measures that lag for a Controller.

**A binding through Git sync.** A second workspace of the estate held
the pipeline's schedule unbound and off from about 10:57 UTC on
2026-10-13: `"enabled": false`, and no `enabledControlType`. A pull
request merged at 17:54:45 replaced those lines with the bound pair
above, and the user synced the workspace to it between 17:55 and 18:22.
Read by the estate's session, times UTC:

| When | What |
| --- | --- |
| 18:22 | `getDefinition`'s `.schedules` part matched the branch's file, line endings aside; List Item Schedules read `enabled` `false`, control type `VariableReferenceManaged`, and `enabledEvalState` and `nextResolveVariableReferenceDateTime` both `null` |
| before 18:42 | The portal's Schedules pane, in the user's screenshot: *Inactive*, under variable control, *Not available* for its last and next update |
| 18:42:40 | Same schedule ID as the portal's; `enabled` `false`, `enabledEvalState` `Normal`, next read 18:49:23, `createdDateTime` 18:02:25 |

The variable defaults to `false` and that workspace's value set does not
override it, so off is right, and List Item Job Instances shows no run
of the pipeline there. So the binding survives Git sync into a workspace
whose schedule was unbound, and `enabledEvalState` and the next read
both `null` mean it has not been read yet, not that it failed: the first
read came 20 to 40 minutes after `createdDateTime`, so judge a synced
binding only once `enabledEvalState` is set. The estate's session, its
first read at 18:22, had recorded that as an open question.
`createdDateTime` is the sync's minute, though the workspace had held
the schedule since about 10:57, while the schedule of the flips above,
bound in the portal, kept its creation time of 04:54:16: the sync seems
to replace a schedule rather than edit it (inferred; the old ID and
creation time were not read). A flip was not tried there; it should
take effect at a read, since that workspace read the same `Normal`
through both of its flips (inferred).

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
read, and cannot set it. On the bound schedule above it read
`VariableReferenceManaged` and carried a third field,
`nextResolveVariableReferenceDateTime`, which no unbound schedule has
shown; `enabledEvalState` read `Normal` there throughout, on and off,
so it does not follow on/off. It read `null` before a synced binding's
first read (above). Unread: `enabledEvalState`'s other values, the
auto-disabled state perhaps among them, and whether every item type's
schedules carry the field.

**Other items' `.schedules`.** Whether a notebook's or a user data
function's file carries the field, and whether Git sync checks it there
too. Learn's two `.schedules` screenshots, a pipeline's and a
notebook's, show none (viewed 2026-10-13).

## Where it lands

`skills/fabric-engineering/fabric-data-pipeline/SKILL.md` § 7: the
`enabledControlType` trap, which names the Controller first, as the way
to switch a schedule per environment with no CI flip: the binding
survives Git sync (above), while deployment is unread. Scope the trap
whatever that read says: its bold lead says turning a schedule off
means deleting
`enabledControlType` too, which a bound entry, with no `enabled` to set,
contradicts. Its `references/REFERENCE.md` § "`.schedules` — full
schema": the `enabled` row (absent on a bound entry), the
`enabledControlType` row (`VariableReferenceManaged`), a new
`enabledVariableReference` row, and the required `enabled` in the
paragraph on how the schema trails the portal. A body edit owes what
`uv run --with pyyaml scripts/skill-status.py --stale` lists afterwards.
A user data function finding goes to
`fabric-user-data-functions-skill.md`, deferred; no skill covers a
notebook's `.schedules` on 2026-10-13.

`skills/fabric-core/fabric-rest-api/SKILL.md` § "Job Scheduling" gains
an `enabledDetail` line, `nextResolveVariableReferenceDateTime` among
its fields, once its values are read: `null` and `Normal` so far, with
the wait before a synced binding's first read.

`skills/fabric-core/fabric-variable-library/SKILL.md`: a short schedule
section beside "Lakehouse shortcut consumption", carrying the timing
above, since Learn's supported-items list names no schedule among its
nine (read here, 2026-10-13).

## Not checked

No tenant was reachable from this run, and the Git-sync sandbox held no
`.schedules` file on 2026-10-13, so a probe there starts by scheduling a
pipeline. The schema gives `parameters` items one `type`,
`VariableReference`, under `configuration`, but portal-written files
put `parameters` beside `configuration`, and a Dataflow's item was typed
`"Text"` (`fabric-data-pipeline`'s `references/REFERENCE.md`,
2026-10-13). A Controller binding writes no `VariableReference` there: it
is a field of its own at the entry level (above).

## Scrubbing

The notes named the client's pipelines, stages, commits, CI workflow,
Variable Library, variable and value set; none is carried here. The
field names and error text are Fabric's own.

## Re-measure before acting

```bash
grep -rln "enabledControlType" skills/ claude/rules/   # fabric-data-pipeline's SKILL.md and REFERENCE.md, fabric-rest-api's gotchas.md, on 2026-10-13
grep -rln "Controller" skills/fabric-*/                 # nothing on 2026-10-13
grep -rln "enabledDetail" skills/                       # nothing on 2026-10-13
grep -rln "VariableReferenceManaged" skills/            # nothing on 2026-10-13
```

Search Learn again for a pipeline schedule's Controller first: a
pipeline page that documents it, or its `.schedules` form, may settle
part of this without a tenant.

The Git-sync half came by an inbox note of 2026-10-13 and is folded
above. A binding brought by a deployment pipeline still needs a tenant,
or a note from an estate that deploys a bound schedule: read
`~/handoff-inbox/agent-config/` for one.
