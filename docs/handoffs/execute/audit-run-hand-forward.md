---
status: open
priority: 2
needs: [user]
blocked-by: []
written: 2026-10-17
---

# Handoff: a new audit run takes over the open work of the run before it

- **Written**: 2026-10-17, from a question the user raised after the
  `/triage` sweep of `docs/audits/2026-10-06/fabric/` (`97ac811`).
  Measured against the tree at `97ac811`.
- **Kind**: two decisions for the user, then edits to
  `/drift-audit`, `/drift-handoff`, the triage reference and two
  READMEs, possibly with a case in `tests/scripts/audit-status/`.
  No edits are drafted yet.

## The problem

A drift-audit run can't be retired while it still holds open work, and
right now open work never leaves the run that first wrote it. Two gaps
cause this.

**1. A wait the new audit couldn't settle is stamped back onto the old
run.** `/drift-audit` § "Owed re-checks" finds every `**Needs**:` line
that names it. `/drift-handoff`'s last brief stamps each result onto the
old log. A re-check that "was not in this window" gets a fresh
`**Needs**:` line *in the old run* (`/drift-handoff` SKILL.md, "A fresh
`**Needs**:` line on each one not in this window"). That old run then
never becomes retirable. Measured 2026-10-17:

- The 2026-10-16 fabric audit re-checked 2026-10-06/fabric 03, 11 and
  14.
- It re-stamped all three in `1f8e847`, which pins the 2026-10-06 run
  open, even though a newer fabric run is on disk.
- `/triage` could only mark them Stays, because
  `audit-follow-ups.md` § 4 says a re-check the next audit performs
  stays put.
- The same thing holds 2026-10-06/claude-code 01 and 11 and
  fabric-iq-ontology 11.

**2. Briefs that were never executed are invisible to the next audit
of their source.** Two facts combine here:

- `/drift-audit` floors each source at the head of its newest run.
  Because of that, it never re-reads the rows an older run's briefs came
  from.
- § "Owed re-checks" finds only `**Needs**:` lines, and "A brief never
  run has no such line."

So a newer run can write a brief against the same skill lines as an
older brief nobody executed. Or the newer window can void the older
brief outright, for example when a preview it relabels goes GA. Neither
run says so.

- The gate `/drift-update` runs before applying a brief ("confirm the
  brief's quoted evidence still exists") catches changes on the skill
  side, not upstream ones.
- Measured 2026-10-17: `2026-10-16/claude-code/` (7 briefs) and
  `2026-10-16/vscode-agent/` (5) are unexecuted. The next audit of
  either source would hit this case.

## Proposed shape

Hand the work forward. Don't move files: a brief's window, evidence and
report link all belong to the run that wrote it, and `lint-audit-index`
checks each directory's index against its own briefs.

1. **Carry each unsettled wait forward at the stamp step.** The old log
   gains `**Closed**: <date> — carried to <new-run>/<NN>`. The new run's
   stamp brief takes the wait as its own work: it is stamped "applied
   with deferrals", with a `**Needs**:` line naming the next audit. That
   way, every open wait for a source lives in exactly one place, its
   newest run, and the older run becomes retirable once its other briefs
   are finished.
2. **Read the previous run's unexecuted briefs as input.** When
   `/drift-audit` floors a source at a run that still has briefs never
   executed, it lists them and checks each one's targets against the new
   window. `/drift-handoff` then does one of three things with each:
   - **Supersede it:** append a Closed line, "superseded by
     `<new>/<NN>`", where a new brief re-scopes the same target.
   - **Carry its still-valid actions into a new brief.**
   - **Leave it**, with a line in the report saying why.

   `/drift-update` skips a closed brief, so a stale one can't run later.

## Decisions for the user

1. **The form the carry takes.**
   - *(a)* One stamp brief per run, holding every carried wait under one
     `**Needs**:` line. This is the simplest.
   - *(b)* One brief per carried wait in the new run. Each wait then
     closes on its own, at the cost of more files.
2. **What happens to unexecuted briefs.**
   - *(a)* Absorb them, as described above.
   - *(b)* Gate: `/drift-audit` refuses to audit a source whose newest
     run has unexecuted briefs until `/drift-update` runs or the user
     says to proceed.
   - *(c)* Both: warn, then absorb.

   (b) is cheap, but it blocks an audit on a backlog. (a) costs part of
   a run.

## Design points to settle while editing

- **A carried wait still needs its constraint.** The original brief's
  body holds the evidence, and the rule the open work still has to
  follow (`audit-follow-ups.md` § 2). Once the old run is retired, a
  link into it breaks. Retiring re-points only links outside
  `docs/audits/` (§ 8 step 2), so either:
  - the carry copies the constraint (one or two lines), or
  - the retire step also re-points the newest run's links into the
    retired one, to `git show <sha>:<path>`.
- **`/triage`'s Stays verdict mostly goes away.** After this change it
  covers only waits written before the change. Decide whether a one-off
  sweep carries the six waits pinned today into their newest runs, which
  would make `2026-10-06/fabric` and `2026-10-06/claude-code` retirable.
- **`audit-status.py` needs no new outcome.** It treats any `**Closed**:`
  line as closing a brief (`:272`), and `--retirable` already wants
  "every brief finished, and a later run on disk". Check this against
  its suite in `tests/scripts/audit-status/` rather than assuming it.

## Where it lands

- `.claude/skills/drift-audit/SKILL.md` § "Owed re-checks": add a
  sibling step that lists the floor run's unexecuted briefs.
- `.claude/skills/drift-handoff/SKILL.md`: the stamp brief's two bullets
  ("A `**Closed**:` line", "A fresh `**Needs**:` line"), and the
  supersede rule. Check whether its `references/brief-format.md` needs
  the change too.
- `.claude/skills/triage/references/audit-follow-ups.md` § 3–4: the
  Stays row, and "A later audit of the same source may own the work
  now".
- `docs/handoffs/execute/README.md` § "Audit briefs are a second queue"
  and `docs/audits/README.md` § "Retiring a run": the reasoning behind
  the change, recorded where each section keeps it.
- All three skills live in `.claude/skills/`: project scope, never
  deployed. Each edit to a behavioural body owes a retest, and
  `skill-status.py --stale` will name it. `triage` and `drift-audit`
  already show `retest-routing` (2026-10-17).

## Re-measure before acting

```bash
uv run scripts/handoff-status.py . --no-inbox                  # 2026-10-17: 9 follow-ups, 6 pinned to "the next … drift audit"; 3 runs not executed
uv run scripts/audit-status.py --retirable                     # 2026-10-17: none
grep -n "fresh \`\*\*Needs\*\*:\` line" .claude/skills/drift-handoff/SKILL.md
grep -n "A brief never run has no such line" .claude/skills/drift-audit/SKILL.md
```
