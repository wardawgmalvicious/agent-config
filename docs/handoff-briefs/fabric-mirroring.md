# Skill handoff brief: fabric-mirroring

Last verified: 2026-08-30

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

> Guidance: Where the drafted SKILL.md lands. State personal vs. project scope and the exact path. Personal: `~/.claude/skills/{{skill-name}}/SKILL.md`. Project: `<repo-root>/.claude/skills/{{skill-name}}/SKILL.md`.

Personal scope, authored in the agent-config repo at
`skills/fabric-mirroring/SKILL.md`, live at
`~/.claude/skills/fabric-mirroring/SKILL.md` via the `skills/` junction the
moment it is written. Two reference files alongside it:

- `skills/fabric-mirroring/references/open-mirroring.md`
- `skills/fabric-mirroring/references/source-matrix.md`

## Scope

> Guidance: One paragraph. What the skill does, inline vs. forked execution (`context: fork` vs. default inline), model-invocable vs. user-only (`disable-model-invocation`, `user-invocable`), path-scoped vs. not (`paths:`). No design discussion — just the what.

A reference skill covering Mirroring in Fabric as a whole: the three
mechanically distinct kinds (database mirroring by replication, metadata
mirroring by shortcut, open mirroring by landing zone), which sources use
which, the `MirroredDatabase` REST surface, the open mirroring landing-zone
protocol, the cost and latency model, and the limits and failure modes that
actually get hit. Runs inline in the current session; model-invocable and
user-invocable. Not path-scoped — mirroring has no local file artifact to
glob on, unlike TMDL or PBIR, so the frontmatter `description` is the whole
trigger mechanism. Reference kind, not enforcement: no refusal patterns, no
severity rubric, no test fixtures.

## Frontmatter

> Guidance: Fill every field you intend to set. Delete lines for fields you're not using — don't leave them as empty placeholders. Constraint comments stay as inline YAML `#` comments so the filled brief carries its own reference.

```yaml
---
name: fabric-mirroring  # required; max 64 chars; lowercase letters/numbers/hyphens; forbidden words "anthropic"/"claude"
description: <drafted in the SKILL.md itself; see "Description char count" below>  # required; keep under 1,024 chars for Agent Skills portability
---
```

No other frontmatter fields are set. `paths:` is deliberately omitted (no
local artifact). `allowed-tools` is omitted so the skill inherits session
tools — it reads and explains, it does not run a scoped command set.
`context: fork` is not used; answers belong in the calling session.

## Description char count

> Guidance: State the count explicitly so Claude Code can re-check after draft. Pick the cap that matches your Tag (section below): publishable/open-standard → 1,024; personal/Claude Code-only → 1,536 combined.

Target ≤ 1,024 (portable cap), re-counted with the `yaml.safe_load`
one-liner after every wording change. Actual count recorded in the
post-draft report.

## Body structure outline

> Guidance: Numbered list or subheadings — one line per section describing what belongs there. Not draft prose. The body is what Claude Code drafts after receiving this brief.

1. **The three kinds of mirroring** — database / metadata / open, what each
   physically does, and why the distinction decides every later answer.
2. **Which kind each source uses** — compact table, GA vs preview, pointing
   at `references/source-matrix.md` for per-source limitations.
3. **Mirroring vs Copy job vs shortcut vs pipeline** — the decision boundary,
   including the explicit `fabric-copy-job` disambiguation.
4. **What you get** — `MirroredDatabase` item, auto SQL analytics endpoint,
   Direct Lake, three-part-name cross-database queries.
5. **Latency, cost, and capacity** — 15-second publish floor, backoff, free
   core compute, 1 TB storage per CU, paid extended capabilities, and what a
   paused or expired capacity does.
6. **REST API** — create with the `mirroring.json` definition part,
   `mountedTables`, `defaultSchema`, `retentionInDays`,
   `enableDeltaChangeDataFeed`, plus start/stop/status, and the
   managed-identity prerequisite that is not visible in the API shape.
7. **Open mirroring landing zone** — the protocol at body depth: folder
   layout, `_metadata.json` `keyColumns`, `__rowMarker__` semantics, 20-digit
   file naming, the last-column rule. Detail to `references/open-mirroring.md`.
8. **Limits and gotchas** — table cap, 1 TB/day throttle, no views in core
   mirroring, source database can't be changed, no ownership change, DDL
   reseed, capacity-pause reseed, varchar truncation, unpropagated RLS/DDM.
9. **Monitoring and first moves when nothing replicates** — portal statuses,
   `getTablesMirroringStatus`, workspace monitoring
   `MirroredDatabaseTableExecution` / `ReplicatorBatchLatency`, SQL analytics
   endpoint metadata-sync refresh.
10. **Constraints** — MUST/PREFER/AVOID summary, matching the house pattern
    in `fabric-gotchas`.
11. **See also** — neighbouring skills.

## Changes from source proposal

> Guidance: If the brief derives from a pasted proposal or prior conversation, enumerate departures with rationale. New artifact with no prior proposal: `N/A — new artifact`.

Derives from the scoping input this file replaces —
`docs/handoff-briefs/fabric-mirroring.md` as written by `/drift-update` on
2026-08-29, which recorded the authorization, the audit evidence, and the
undrilled set, and explicitly declined to pre-fill this template. That file
is superseded rather than kept: its Status and Provenance are carried into
the Notes section below so nothing authorizing is lost.

Departures from the scoping input's expected shape:

- **Name and kind unchanged.** `fabric-mirroring`, platform prefix, reference
  kind, no test fixture — all as anticipated.
- **The scope is wider than the audit window, deliberately.** The scoping
  input warned that scoping from the five August-2026 What's New rows would
  produce "a skill that covers August 2026 and nothing else." The skill is
  built on the `mirroring/overview` source matrix instead, which carries the
  pre-existing sources the window never mentioned.
- **The audit's five-row table does not survive as an outline.** Two of its
  rows are not in the overview matrix at all: **Google Lakehouse Runtime
  Catalog** and **Snowflake Iceberg** mirroring appear in What's New but not
  in the current `mirroring/overview` platform table. Conversely the overview
  table carries **Oracle**, **SAP**, **SharePoint List (preview)**, **Azure
  Database for MySQL (preview)** and **Dremio catalog (preview)**, none of
  which appeared in the window. The skill follows the overview matrix and
  says so.
- **One skill, not two.** Settled with the user before drilling. Open
  mirroring is a genuinely different mechanism from managed database
  mirroring, but a reader asking "how do I mirror X" does not know which half
  they are in, so splitting would split the trigger surface. The protocol
  detail goes to `references/open-mirroring.md` instead.
- **The copy-job trap is handled one-sided.** The scoping input suggested the
  fix "may mean editing `fabric-copy-job`'s description too." That edit is
  out of scope here — `/author-skill` forbids editing other skills — so this
  run spends a clause of the new description on the boundary and reports the
  proposed `fabric-copy-job` edit for a separate `/learn`. Confirmed with the
  user.

## Tag

> Guidance: `personal` / `publishable` / `client-only`. v1 default is `personal`. Tagging convention may tighten when the publication pipeline re-activates.

personal

## Portability caveats

> Guidance: Call out Claude Code-only frontmatter the author relied on — `shell: powershell`, `context: fork`, fine-grained `allowed-tools` Bash syntax, `effort` levels beyond standard, any hooks. Required content for `publishable`; `personal` can answer `N/A — personal scope`.

N/A — personal scope. Frontmatter is `name` + `description` only, which is
the portable Agent Skills core; nothing Claude Code-specific is relied on.

## Cross-reference dependencies

> Guidance: Skills, rules, or subagents this skill references. Tag each as (a) already converted, (b) pending conversion — future-edit dependency, or (c) external/standard. No cross-references: `N/A — no cross-references`.

- `fabric-copy-job` — (a) already converted. Disambiguation target. Carries a
  **pending future edit**: its description claims "the no-pipeline
  data-movement item" without naming Mirroring, so the boundary is currently
  drawn on one side only. Proposed, not made, by this run.
- `fabric-database` — (a) already converted. Fabric SQL database mirrors to
  OneLake automatically with no configuration; that skill owns the source,
  this one owns the mirroring mechanism.
- `fabric-rest-api` — (a) already converted. Owns the generic Fabric REST
  patterns (LRO polling, continuation tokens, the definition envelope); this
  skill covers only the `mirroredDatabases` specifics.
- `fabric-security` — (a) already converted. Owns the workspace-role and
  OneLake security model that mirrored-item sharing sits on.
- `fabric-eventhouse` / `fabric-realtime-dashboard` — (a) already converted.
  The Azure Monitor mirrored catalog surfaces through an Eventhouse endpoint.
- `fabric-gotchas` — (a) already converted. Nothing is moved into it by this
  run; mirroring failure modes stay with the mirroring skill.

> Verbatim — do not edit. Brief-specific observations belong in the
> Notes section above.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit (YAML hygiene rule).
4. If batch is 3+ skills, return a proposal before writing, per batch-conversion convention.

## Notes

> Guidance: Optional. Brief-specific observations that don't fit
> elsewhere — pattern dogfooding feedback, structural decisions worth
> flagging, one-off context. Leave blank or omit heading if nothing
> to note.

### Authorization, carried from the superseded scoping input

Authorized. `/drift-update` escalated
`docs/drift-audit/2026-08-29/fabric/07-decide-scope-for-fabric-mirroring.md`
on 2026-08-29 and the decision was option (1): write a `fabric-mirroring`
skill. Surfaced by the `/drift-audit 2026-07-31 --fabric` run as the first of
five bucket (b) new-skill candidates and the only one promoted to a
recommended action, on volume (five entries in one window, including the
Google BigQuery GA promotion at Fabric What's New head `5745ba3`) and on
consolidation (two older Iceberg preview rows retired *into* this set rather
than being promoted separately). `docs/drift-audit/` is gitignored, so that
brief cannot be relied on to still exist. Pre-existing local coverage was
none, and remains none — the 13 hits from
`grep -rli 'mirror' skills/*/SKILL.md` are incidental, `fabric-spark-monitoring`
matching on "Spark History Server mirror", an unrelated sense of the word.

### What was drilled

All by `microsoft_docs_fetch` on 2026-08-30 unless noted:

- `fabric/mirroring/overview` — three kinds, platform matrix, latency, cost,
  retention, Direct Lake, cross-database queries, sharing.
- `fabric/mirroring/open-mirroring-landing-zone-format` — the full protocol.
- `fabric/mirroring/mirrored-database-rest-api` — CRUD, definition JSON,
  start/stop/status, retention, CDF enablement.
- `fabric/mirroring/troubleshooting` — capacity behaviors, limits, schema
  hierarchy, Delta column mapping, varchar limits, ownership.
- `fabric/mirroring/azure-sql-database-limitations` — per-source depth
  exemplar (table, column, DDL and permission limits).
- `fabric/mirroring/extended-capabilities` — CDF and mirroring views, paid.
- `fabric/mirroring/catalog-mirroring/azure-monitor` — metadata mirroring
  exemplar plus its security caveats.
- `fabric/mirroring/monitor` — portal statuses, workspace monitoring.
- `fabric/onelake/unify-data` — the shortcut vs mirroring vs pipeline
  boundary, which is what the Copy job disambiguation is built on.
- `fabric/mirroring/catalog-mirroring/aws-glue` and its tutorial — via
  `microsoft_docs_search` excerpts only, not fetched in full.

### What was NOT drilled — this bounds the draft

- **Per-source tutorials and limitations for every source except Azure SQL
  Database.** Cosmos DB, Snowflake, Oracle, SAP, SharePoint List, MySQL,
  PostgreSQL, Databricks, Dremio, BigQuery and SQL Server each have their own
  limitations page; only the Azure SQL Database one was read in full. The
  source matrix therefore records *which kind* each source uses and links its
  limitations page, and does not claim per-source limits it did not read.
- **Snowflake Iceberg mirroring and Google Lakehouse Runtime Catalog
  mirroring**, two of the audit's five window entries. Neither appears in the
  current `mirroring/overview` platform table, and neither page was located.
  The skill says nothing about them.
- **The open mirroring partners ecosystem page**, and the Open Mirroring
  Python SDK beyond the fact of its existence.
- **`extended-capabilities-delta-change-data-feed`, `-views`, and `-billing`**
  — only the parent page was read, so the skill states that CDF and views are
  paid preview add-ons and does not describe their mechanics.
- **`monitor-logs`** — the log schema behind `MirroredDatabaseTableExecution`
  and `ReplicatorBatchLatency` is named, not detailed.
- **`fabric-cli` / `fabric-cicd` handling of `MirroredDatabase` items.** Not
  drilled at all; the skill makes no deployment claims.

### Two doc conflicts worth carrying into the draft

Both are recorded in the skill inline, because a reader who hits one will
otherwise assume the skill is wrong.

1. **Default retention.** `mirroring/overview` says the default is one day for
   mirrored databases created from the portal after mid-June 2025 and seven
   days for older ones; `mirrored-database-rest-api` says flatly "The default
   value is seven days." The allowed range, 1–30, is consistent across both.
2. **Table cap.** The live `troubleshooting` and
   `azure-sql-database-limitations` pages both say **1,000**; the
   `snowflake-limitations` page still says 500, and stale search-index chunks
   of the Azure SQL page return the old 500 figure. The skill uses 1,000 as
   the current general cap and flags that per-source pages can be lower and
   can lag.

Also worth not propagating: the REST API page's Note contains a typo,
`deafultSchema`. The property is `defaultSchema`, as that page's own JSON
examples show.

## Confidence

> Guidance: H / M / L with a one-line rationale. Separate confidence lines per dimension (structure vs. field specs vs. body content) are welcome when they diverge.

- **Structure** — H. Reference-kind platform skill in a shape this repo has
  built many times; the one non-obvious call (one skill, references split)
  was settled with the user before drilling.
- **Field specs** — H. Two frontmatter fields, both linted.
- **Body content** — H for the three-kinds spine, the REST surface, the open
  mirroring protocol, and the general limits: all fetched in full on
  2026-08-30. M for the source matrix, which is accurate about *which kind*
  each source uses but deliberately does not carry per-source limits it did
  not read. Not applicable to trigger behavior, which is untested — a changed
  SKILL.md does not reliably reload mid-session on Windows.
