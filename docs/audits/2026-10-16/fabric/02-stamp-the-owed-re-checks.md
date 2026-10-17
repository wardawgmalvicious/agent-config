# Handoff: stamp the re-checks this audit owed

- **Audit run**: 2026-10-16
- **Source**: `fabric`
- **Window**: floor `7ff5f2b3` (2026-10-02, the 2026-10-06 run's head) →
  head `0cbcc6f71` (2026-10-15)
- **Covers recommended actions**: 2
- **Kind**: bookkeeping in the committed dated ledger. Six execution logs
  gain one appended line each, a `**Closed**:` on one and a fresh
  `**Needs**:` on five; no guidance, payload or behaviour changes. Edits
  only, with nothing to decide.
- **Target**: six briefs in three run directories, numbered under
  Evidence, and the `README.md` that `audit-status.py` generates in each

## Context

The 2026-10-16 `fabric` audit owed six re-checks: the open `**Needs**:`
lines under `docs/audits/` that name the next `fabric` drift audit, or
any drift audit. Its report gives each an outcome under
`## Owed re-checks`: one passed, one passed half its check, and four
were not in this window. None of the six logs says so yet, and the next
audit, `handoff-status.py` and the audit indexes all read those logs to
learn what still waits, and on what.

Four of the fabric re-checks also point at skills that have moved since
their briefs ran on 2026-10-06, so the lines carried forward name where
each claim sits now.

## Evidence

A log's counting line is its last `**Needs**:` line, the one
`/drift-update` and `/drift-audit` § 2 both read. Line numbers are as of
2026-10-16. The outcomes are the report's; the Learn reads behind them
were made through `microsoft-learn-mcp` that day.

### Target 1 — the Spark SQL MLV GA month

`docs/audits/2026-10-06/fabric/02-rewrite-mlv-optimal-refresh-tables.md`,
log at `:156`, `**Executed**: 2026-10-06 — applied with deferrals`.
Counting line, `:203`:

> - **Needs**: the next fabric drift audit — a Learn statement of the
>   Spark SQL MLV GA month, to settle `SKILL.md:3` and
>   `references/REFERENCE.md:3`. The `REFERENCE.md:52` fix landed
>   2026-10-06: Runtime 2.0 is still opt-in, quoting the runtime page's
>   "By default, all new workspaces currently use Runtime 1.3".

Not in this window. Learn's MLV overview and Spark SQL reference carry
no GA month; the overview's only status is "PySpark authoring
(Preview)". What's New's GA row "Materialized lake views (Generally
Available)", month September 2026, did not change in the window. The
skill moved: `fabric-mlv` is folded into `fabric-spark`, whose
description, `skills/fabric-engineering/fabric-spark/SKILL.md:3`, no
longer dates GA, while
`skills/fabric-engineering/fabric-spark/references/mlv.md:307` still
says "the declarative `CREATE MATERIALIZED LAKE VIEW` Spark SQL surface
(GA March 2026)".

### Target 2 — incremental graph updates

`docs/audits/2026-10-06/fabric/03-rewrite-graph-gql-support-and-query-api.md`,
log at `:187`, `**Executed**: 2026-10-06 — applied with deferrals`.
Counting line, `:222`:

> - **Needs**: the next fabric drift audit — whether Learn documents
>   incremental graph updates, which settles item 5; its manage-data page
>   still read "every save refreshes your graph data" on 2026-10-08. The
>   rest left this log that day, by /triage: …

Not in this window. Learn's manage-data page still reads "Because save
and ingestion are a single operation, every save refreshes your graph
data", and design-graph-schema "Graph currently doesn't support schema
evolution"; no graph row changed in the window. The claims item 5
flagged, once `fabric-graph`'s `SKILL.md:21` and `:107`, now sit in
`fabric-iq`: `skills/fabric-ai/fabric-iq/references/graph.md:11` and
`:115`, and `references/graph-reference.md:196`.

### Target 3 — Catalog Search table and column search

`docs/audits/2026-10-06/fabric/11-relabel-bulk-definition-apis-and-scope-bypath.md`,
log at `:188`, `**Executed**: 2026-10-06 — applied with deferrals`.
Counting line, `:233`:

> - **Needs**: the next fabric drift audit — D-7: whether the Catalog
>   Search API documents table and column search, before `fabric-cli`'s
>   `fab find` line changes.

Not in this window. The Catalog Search REST reference still says
`search` "supports searching across the display name, workspace display
name, and description of the CatalogEntry", and its `CatalogEntryType`
holds only `FabricItem` and `Workspace`. The "OneLake Catalog table
discovery (Preview)" row did not change. `fabric-cli` is gone: the
`fab find` line is now
`skills/fabric-core/fabric-rest-api/references/cli.md:54`, naming the
three fields the reference still names.

### Target 4 — Dataflow warehouse schema and destination expressions

`docs/audits/2026-10-06/fabric/14-update-dataflow-destinations-and-pipeline-activities.md`,
log at `:133`, `**Executed**: 2026-10-06 — applied with deferrals`.
Counting line, `:198`; the two `**Behavioural confirmation**:` bullets
after it, at `:209` and `:228`, are not `Needs` lines:

> - **Needs**: the next `fabric` audit — what Learn still leaves
>   undocumented, read 2026-10-07: the "Dataflow dynamic warehouse schema
>   (Preview)" row links the destinations page, which still allows
>   Warehouse only fixed schema, and no page shows how a destination
>   expression is written into `mashup.pq`. Correct `fabric-dataflow`
>   `REF:93-98` or `SKILL.md:269-278` once Learn documents either. …

Not in this window. The destinations page still says "When loading data
into the warehouse, only fixed schema is supported", and the dynamic
expression editor page says "It isn't a general-purpose Power Query M
expression editor", showing an expression only as tokens in the editor;
neither preview row changed. `fabric-dataflow`'s
`references/REFERENCE.md:93-98` stands, and so does the `SKILL.md`
passage, now `:273-282`.

### Target 5 — the skill-match reading

`docs/audits/2026-10-08/prompt-audit/02-point-drift-audit-at-the-repo-skill-trees.md`,
log at `:87`, `**Executed**: 2026-10-08 — applied with deferrals`.
Counting line, `:153`:

> - **Needs**: the next `/drift-audit` of `fabric` or `powerbi`, for step
>   6's skill-match reading on a real diff; the retest is done.

Its step 6: "Not gating: the next `/drift-audit` of `fabric` or
`powerbi` should map a change to an existing platform skill as a skill
match."

Passed. The run globbed `skills/*/*/SKILL.md` (32 skills) and
`.claude/skills/*/SKILL.md` (6), and its one bucket-(a) entry mapped to
`fabric-security`, under `skills/fabric-core/`: a platform skill pruned
from user scope, reached through the repo tree. The line waits on
nothing else.

### Target 6 — drift-audit's tool premises

`docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`,
log at `:94`, `**Executed**: 2026-10-07 — escalated (…`. Counting line,
`:135`:

> - **Needs**: the next `/drift-audit` run — the behavioural check alone,
>   as the line above says. …

The line above, `:117`, defines the check: "that § 1's slash-free
`Glob` lists the registry, and, only on a run that falls back to the
WebFetch path, that § 4b's completeness check catches the note and the
tells."

Half passed. § 1: `Glob` with pattern `*.md` and `path` the skill's
`references/sources/` directory listed all six registry entries. § 4b:
not in this window, since the run took the clone path and no WebFetch
fallback ran.

## What to change

Append one line to each log, after its last bullet, and rewrite nothing
above it. The earlier lines were accurate when written, and only a
log's last `**Needs**:` line counts, so a fresh one supersedes without
an edit. Each new line names this run's directory,
`docs/audits/2026-10-16/fabric/`.

1. **Target 1**: a fresh `**Needs**:` opening "the next fabric drift
   audit —": a Learn statement of the Spark SQL MLV GA month, to settle
   `fabric-spark`'s `references/mlv.md:307`, "(GA March 2026)". Say
   that the 2026-10-16 run found none, and that the brief's `SKILL.md:3`
   target is gone: `fabric-mlv` became part of `fabric-spark`, whose
   description no longer dates GA.
2. **Target 2**: a fresh `**Needs**:` opening "the next fabric drift
   audit —": whether Learn documents incremental graph updates, which
   settles item 5. Say that manage-data still read "every save refreshes
   your graph data" on 2026-10-16, and that the claims item 5 flagged
   now sit in `fabric-iq`, `references/graph.md:11` and `:115` and
   `references/graph-reference.md:196`.
3. **Target 3**: a fresh `**Needs**:` opening "the next fabric drift
   audit —": D-7, whether the Catalog Search API documents table and
   column search, before the `fab find` line changes. Say that the
   reference still named three fields on 2026-10-16, and that the line
   is now `fabric-rest-api`'s `references/cli.md:54`, not `fabric-cli`'s
   `SKILL.md:62`.
4. **Target 4**: a fresh `**Needs**:` opening "the next fabric drift
   audit —", for the same open work: Learn documenting dynamic warehouse
   schema, or how a destination expression is written into `mashup.pq`.
   Say that neither was documented on 2026-10-16, and that the
   `SKILL.md` passage is now `:273-282`.
5. **Target 5**: a `**Closed**: 2026-10-16 —` line: step 6's
   skill-match reading passed on a real diff, in
   `docs/audits/2026-10-16/fabric/`, whose one drift entry mapped to
   `fabric-security`, a platform skill reached through
   `skills/*/*/SKILL.md`.
6. **Target 6**: a fresh `**Needs**:` opening "the next drift audit
   that falls back to WebFetch —": § 4b's completeness check alone, that
   it catches the `[WebFetch note: …]` and the summarization tells. Say
   that § 1's half passed on 2026-10-16, when the slash-free `Glob`
   listed all six registry entries, and that the run took the clone
   path.
7. **Regenerate the three indexes**:

   ```bash
   uv run scripts/audit-status.py --dir docs/audits/2026-10-06/fabric
   uv run scripts/audit-status.py --dir docs/audits/2026-10-08/prompt-audit
   uv run scripts/audit-status.py --dir docs/audits/2026-10-06/claude-code
   ```

   Only target 5 moves, into
   `docs/audits/2026-10-08/prompt-audit/completed/`. Then run
   `git grep -n 02-point-drift-audit-at-the-repo-skill-trees.md` and
   re-point any live path. On 2026-10-16, before this directory was
   written, it named only that directory's generated `README.md`, which
   the regeneration rewrites, and line 106 of the brief itself, its own
   text. This directory's `00-audit-report.md` and this brief now name
   it too, as it stood: the report is verbatim and this brief's text is
   its own, so neither is re-pointed.

## Constraint on the fix

- **No `**Closed**:` on targets 1–4 or 6.** `audit-status.py` reads a
  `**Closed**:` line anywhere in a log as closing the brief, and files
  it under `completed/`; each of those five still waits on a later
  audit, target 6 on half its check.
- **Edit no skill.** These lines record where each claim sits now;
  correcting a claim is a brief of its own.

## Verification

1. `grep -n '2026-10-16' docs/audits/2026-10-06/fabric/02-rewrite-mlv-optimal-refresh-tables.md docs/audits/2026-10-06/fabric/03-rewrite-graph-gql-support-and-query-api.md docs/audits/2026-10-06/fabric/11-relabel-bulk-definition-apis-and-scope-bypath.md docs/audits/2026-10-06/fabric/14-update-dataflow-destinations-and-pipeline-activities.md docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md docs/audits/2026-10-08/prompt-audit/completed/02-point-drift-audit-at-the-repo-skill-trees.md`
   — each file prints its new line, and the last path exists.
2. `git diff --numstat` on the first five paths of step 1 — `0` in the
   deletions column of each: appended, nothing rewritten.
3. `grep -c '^- \*\*Closed\*\*:'` on the same five — `0` for each.
4. `uv run scripts/handoff-status.py` — targets 1–4 grouped under "the
   next fabric drift audit", target 6 under its WebFetch line, and
   target 5 gone from the open list.
5. `uv run scripts/audit-status.py --check`.
6. `pre-commit run --all-files`.

## Sequencing note

Last in this directory, as a stamp brief always is. Independent of
brief 01: they share no file, and neither outcome changes the other.

## Provenance

Recommended action 2 of the 2026-10-16 `/drift-audit --sources fabric`
run. Its § 2 listed every open `**Needs**:` line under `docs/audits/`
outside `completed/`, kept the last in each file, and kept the six that
name the next `fabric` drift audit or any drift audit;
`00-audit-report.md` § Owed re-checks holds each outcome.
`/drift-handoff` § 4 writes this brief whenever a report lists owed
re-checks, since stamping records outcomes the audit already reached.

## Execution log

- **Executed**: 2026-10-17 — applied with deferrals
- **Session**: fresh (no audit or handoff ran in this session; the
  whole pass, in worktree `2026-10-16-fabric`)
- **Files changed**:
  `docs/audits/2026-10-06/fabric/02-rewrite-mlv-optimal-refresh-tables.md`,
  `docs/audits/2026-10-06/fabric/03-rewrite-graph-gql-support-and-query-api.md`,
  `docs/audits/2026-10-06/fabric/11-relabel-bulk-definition-apis-and-scope-bypath.md`,
  `docs/audits/2026-10-06/fabric/14-update-dataflow-destinations-and-pipeline-activities.md`,
  `docs/audits/2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`,
  `docs/audits/2026-10-08/prompt-audit/completed/02-point-drift-audit-at-the-repo-skill-trees.md`,
  which the regeneration moved there, and that directory's `README.md`;
  the other two indexes came back current
- **Verification**: the staleness gate found all six counting lines as
  quoted, at `:203`, `:222`, `:233`, `:198`, `:153` and `:135` at
  `9b00967`, and no 2026-10-16 line in any of the six. The skill lines
  the new lines cite read as the brief gives them: `mlv.md:307`'s "(GA
  March 2026)", no GA date in `fabric-spark`'s `SKILL.md:3`,
  `graph.md:11` and `:115`, `graph-reference.md:196`, `cli.md:54`, and
  `fabric-dataflow`'s `SKILL.md:273-282` and `REF:93-98`. Step 1 —
  **passed**: each file prints its new line, and the moved path exists.
  Step 2 — **passed**: `0` deletions on all five. Step 3 — **passed**:
  `0` on all five. Step 4 — **passed**: targets 1 to 4 under "the next
  fabric drift audit", target 6 under its WebFetch line, target 5 gone
  from the open list. Step 5 — **passed**: "9 audit index(es) current".
  Step 6 (`pre-commit run --all-files`) runs once at the end of the run.
- **Deferred**: none of the brief's own work; one adjacent finding,
  under Needs.
- **Deviations**: one. Step 7's `git grep` also named two paths in
  `docs/audits/2026-10-17/power-bi/`, a run dated after this brief: its
  `00-audit-report.md:33`, verbatim, and its
  `03-stamp-the-owed-re-checks.md:43`, a brief's own text, whose target 1
  already says to append nothing once this `**Closed**:` line and the
  move are in place. Neither is re-pointed, for the reasons the brief
  gives for its own directory's two.
- **Needs**: a session of its own — the adjacent finding, seen at step
  4: `scripts/handoff-status.py` run from a linked worktree defaults its
  sweep root to `REPO.parents[1]`, which is the main checkout's
  `.claude/`, so it swept 1 repo and printed 6 orphan inbox directories
  and 0 inbox notes, where `C:/Repos` as the root swept 11, with no
  orphan and 4 notes. The pre-commit hook's `--check --no-inbox` is
  unaffected. Fix the default for a linked worktree, with a case in
  `tests/scripts/`, then a `**Closed**:` line here.
