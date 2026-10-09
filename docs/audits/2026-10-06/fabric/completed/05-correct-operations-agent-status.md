# Handoff: correct the operations agent's status

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 5
- **Kind**: status correction (preview → GA) across one skill and its
  reference, plus one constraint added. Content; a `description` edit,
  if any, needs a retest.
- **Target**: `skills/fabric/fabric-operations-agent/SKILL.md` (lines
  14–16, 289), `skills/fabric/fabric-operations-agent/references/REFERENCE.md`
  (line 5)

## The problem

`fabric-operations-agent` calls the operations agent preview throughout,
and tells its reader to "Register nothing as GA". The item has been
generally available since June 2026. What is preview is its support for
workspace outbound access protection (OAP), and that support blocks
some of the agent's actions.

## Evidence

**What's New.**

- At the diff base `8375c89d`, the GA table carried "Operations agent
  (Generally Available)" dated June 2026, in both the GA table and the
  Fabric IQ section. The monthly roll-off in `ecb721f5` (2026-09-01)
  moved it to the archive page, so the skill was wrong before this
  window opened.
- Commit `91e49056` (2026-09-09) added "Workspace outbound access
  protection for Operations Agent (Preview)".

**Learn** (agent-measured, 2026-10-06) —
https://learn.microsoft.com/en-us/fabric/security/workspace-outbound-access-protection-operations-agent:

> Operations agent is generally available. Support for operations agent
> with workspace OAP is in preview.

Per the same page, OAP blocks Teams, Power Automate and cross-workspace
actions.

**The skill** (agent-measured):

- `SKILL.md:14-16` — "The item, its Git integration, its
  deployment-pipeline support and Investigator insights are all
  **preview**"
- `SKILL.md:289` — "Register nothing as GA."
- `REF:5` — "The item is preview throughout."

## What to change

1. `SKILL.md:14-16` — the item is GA. Check Git integration,
   deployment-pipeline support and Investigator insights one by one on
   Learn, and keep "preview" on whichever still carries it.
2. `SKILL.md:289` — replace the instruction with what is now true.
3. `REF:5` — same correction.
4. Add the OAP constraint: OAP support is preview, and under OAP the
   Teams, Power Automate and cross-workspace actions are blocked.

## Constraint on the fix

- Flip only what Learn flips. Example of what not to flip:
  `fabric-deployment-pipelines/references/REFERENCE.md:18` still lists
  "Operations Agent *(preview)*" for pipeline support, transcribed from
  Learn. Item GA does not make every surface GA.
- Out of scope: the audit also flagged the monitoring item embedding an
  Operations Agent and a new **View performance** dashboard (`SKILL.md:42`).
  That finding is not in this brief's recommended action. `REF:44` and
  `:168` belong to brief 20's incidental checks.

## Verification

1. `grep -n -i "preview\|GA\b" skills/fabric/fabric-operations-agent/SKILL.md skills/fabric/fabric-operations-agent/references/REFERENCE.md`
   — every surviving "preview" names a surface Learn still marks
   preview.
2. Re-open the OAP page and confirm the quoted sentence.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-operations-agent/SKILL.md`
4. If the `description` changed: `uv run --with pyyaml scripts/skill-status.py --stale`
   and retest, or stamp the retest as owed.
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01, by the IQ mapping subagent, through the OAP row. The base
version of the page confirms the June 2026 GA date, so this correction
does not depend on the agent's Learn reading alone.

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: `skills/fabric/fabric-operations-agent/SKILL.md`,
  `skills/fabric/fabric-operations-agent/references/REFERENCE.md`
- **Verification**: steps 1–4 ran; step 5 runs once at the end of the
  run. Step 1: every surviving "preview" names a surface Learn still
  marks preview, namely Git integration, deployment pipelines,
  Investigator insights, OAP support and the *Operations agent for
  pipelines* page title. Step 2: the OAP page, re-opened 2026-10-06,
  reads "Operations agent is generally available. Support for
  operations agent with workspace OAP is in preview." Step 3: lint
  clean. Step 4: `skill-status.py --stale` lists
  `fabric-operations-agent` as `untested-behaviour`. Its activation
  stamp covers only `paths:`, which is unchanged, and it has no
  behaviour stamp to go stale, so the retest the `description` edit
  owes is Phase B, owed below.
- **Item 1, one by one, 2026-10-06**: Git integration's supported-items
  list still reads "Operations Agent *(preview)*" under Data Factory;
  deployment pipelines' list reads the same; Investigator insights is
  headed "(preview)" on the operations-agent actions page. All three
  kept "preview"; only the item flipped.
- **Deferred**: the routing retest. Step 1's grep covers line 3, whose
  "Operations Agent item (preview)" named the GA item, so `(preview)`
  was dropped from the `description`. That needs `/test-skill
  fabric-operations-agent` in a fresh session.
- **Deviations**: the `description` edit above. It is outside the named
  lines, but step 1 required it and the brief's Kind allows it.
- **Needs**: a fresh session — `/test-skill fabric-operations-agent`,
  the retest the `description` edit owes.
- **Closed**: 2026-10-08 — covered, by /triage:
  `skill-status.py --stale` lists `fabric-operations-agent` as
  `untested-behaviour`, which owes the `/test-skill` run this log
  names; root `CLAUDE.md` keeps no other untested list.
