# Handoff: decide the new-skill candidates

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 22
- **Kind**: a **decision**: whether to author three candidate skills,
  plus two fold-ins to briefs already in the queue. No skill or rule is
  edited here. `/drift-update` puts the decision back to the user rather
  than executing it.
- **Target**: `docs/handoffs/execute/item-type-skill-fabric-plan.md`,
  `docs/handoffs/execute/fabric-user-data-functions-skill.md` (fold-ins
  only)

## Context

Three features went GA or gained real surface in this window, and no
skill covers any of them. Two more entries fall inside skills that are
already briefed. Accepting a candidate means running `/author-skill`
against it later. Declining it means recording the decline where this
repo records declines.

## D-1 — Business Events

**Evidence.**

- What's New `9eda27f8` (2026-10-02) added "Business Events (Generally
  Available)", September 2026. It pairs two base preview rows that are
  now gone: "Business Events in Real-Time Intelligence (Preview)" and
  "Business events persisted into Eventhouse (Preview)".
- "Activator as business events publisher (Preview)" is still preview
  at HEAD.
- Two guidance rows were added by `ecb721f5` and deleted by `9eda27f8`:
  "Business Event consumer guidance" and "Business Event scenario
  patterns".
- The Schema Registry manages Business Events schemas. Learn's
  `schema-registry-overview` says "Schema Registry also manages any
  schemas that you create as part of Business Events."
- Current coverage is passing mentions only:
  `skills/fabric/fabric-activator/SKILL.md:200` ("Publish business event
  (preview)") and `skills/fabric/fabric-event-schema-set/SKILL.md:335-336`
  (business events listed as untested).

**Audit's rationale.** A skill is worth writing if the item is in use.

## D-2 — dbt job

**Evidence.**

- The base preview row "dbt Job in Fabric Data Factory (Preview)" was
  promoted to "dbt job in Fabric Data Factory (Generally Available)",
  September 2026. At HEAD the page lists it in both tables.
- A guidance row, "Common dbt job patterns (Preview)", was added by
  `ecb721f5` and deleted by `9eda27f8`.
- No artifact mentions dbt beyond
  `skills/fabric/fabric-deployment-pipelines/references/REFERENCE.md:18`
  ("dbt Job *(preview)*"). Brief 10 re-checks that label.

**Audit's rationale.** A skill is worth writing only if dbt is in use;
otherwise ignore.

## D-3 — Fabric Maps

**Evidence.** The window's Maps rows:

- "Data-driven styling and map improvements (Generally Available)",
  August 2026, added by `91e49056`. `32ce042b` later edited its links.
- "Maps external feature services (Preview)", added by `9eda27f8`.
- "Workspace outbound access protection for Fabric Maps (Preview)",
  added by `91e49056`.
- "Fabric Maps in Real-Time Dashboards (Preview)", added by `ecb721f5`.

Nothing covers Maps beyond an item-type name in
`fabric-deployment-pipelines/references/REFERENCE.md:19`. Brief 15
flags the dashboard tile.

**Audit's rationale.** A skill is worth writing only if a Maps item is
in use.

## D-4 — fold into briefs already in the queue

- **Plan.** `ecb721f5` renamed the GA row "Planning (Generally
  Available)" (July 2026) to "Plan". `9eda27f8` added "Native Planning
  Engine (Preview)". Both belong to
  `docs/handoffs/execute/item-type-skill-fabric-plan.md` (ready; written
  2026-09-02, last touched 2026-10-01). That brief's line 129 notes that
  Learn lists Plan under "IQ (preview) items", which is still true of
  the Git and pipeline lists. Plan GA itself predates this window.
- **User Data Functions.** `9eda27f8` added "Warehouse User Data
  Function integration (Preview)". It belongs to
  `docs/handoffs/execute/fabric-user-data-functions-skill.md` (ready;
  written 2026-10-01).

**Fix.** Add one dated line to each brief pointing at the entry and at
this audit's `00-audit-report.md`. Change nothing else in either brief.

## Constraint on the fix

- Other candidates in the report's New-skill section were not part of
  the recommended action, so they are out of scope here:
  - capacity administration, network security and CMK, and connection
    governance, each judged "a section, not a skill";
  - the weak "fold or ignore" list.
- Re-read each `docs/handoffs/` file immediately before editing it.
  Other sessions work that queue, and a stale read drops their changes
  silently.

## Verification

1. A recorded decision for each of D-1 to D-3: accepted for
   `/author-skill`, or declined in the repo's declines ledger with its
   reason.
2. `git diff docs/handoffs/execute/item-type-skill-fabric-plan.md docs/handoffs/execute/fabric-user-data-functions-skill.md`.
   Each shows a single added line.
3. `uv run scripts/handoff-status.py`. Both briefs still parse and keep
   their queue state.
4. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric` (floor
2026-09-01). The Real-Time Intelligence and Data Factory mapping
subagents found that no skill covers these features. The audit session
read the fold-in targets from `handoff-status.py` and `grep` before
recommending fold-ins rather than new candidates.

## Execution log

- **Executed**: 2026-10-06 — escalated (D-1 to D-3 decided by the
  user), then D-4 applied
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: `docs/handoffs/execute/item-type-skill-fabric-plan.md`,
  `docs/handoffs/execute/fabric-user-data-functions-skill.md`
- **Decision (D-1 to D-3)**: put to the user with each candidate's
  evidence and the audit's test, whether the item is in use. **Answer:
  accept all three for `/author-skill`**: Business Events, the dbt job,
  and Fabric Maps. Nothing went to the declines ledger.
- **Verification**: steps 1–3 passed; step 4 runs once at the end of
  the run. Step 1: the three decisions are recorded above. Step 2: `git
  diff --numstat` shows `1 0` for each brief. Step 3: `handoff-status.py`
  still lists both, P2, with their state unchanged. Both were re-read
  just before editing, after checking that neither differed from `main`
  and that no live peer was named for either.
- **Deferred**: authoring the three skills, each a separate
  `/author-skill` run.
- **Deviations**: each fold-in is one unwrapped line in the brief's top
  list, past the 76-character wrap, because step 2 wants a single added
  line.
- **Needs**: `/author-skill` — three new skills, for Business Events,
  the dbt job item and Fabric Maps, each from this brief's evidence.
