# Handoff: add MLV execution definitions to fabric-mlv

- **Audit run**: 2026-09-10
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-06` (diff base `912e06e0`) → head `65902bae`
  (2026-09-04)
- **Covers recommended actions**: 4
- **Kind**: content addition to a platform skill's REST section, from
  Microsoft Learn. Frontmatter change optional and budget-bound.
- **Target**: `skills/fabric/fabric-mlv/SKILL.md`,
  `skills/fabric/fabric-mlv/references/REFERENCE.md`

## The problem

`fabric-mlv` documents only the job-scheduler endpoints, so it can
refresh a lakehouse's whole MLV lineage but not a subset. Fabric added
**MLV execution definitions** — saved selections of MLVs, upstream
lakehouses, refresh mode and Spark environment — and an
`executionData.mlvExecutionDefinitionId` field that scopes an on-demand
refresh or a schedule to one of them. None of this is in the skill.

## Evidence

Upstream trigger — `microsoft/skills-for-fabric` `CHANGELOG.md`,
`[0.3.11] - 2026-08-06` (release commit `2b3530e8`), under Changed,
verbatim:

> **`skills/mlv-operations-cli`** -- documents the Fabric MLV job-type
> mismatch where history/status can show `MaterializedLakeViews`, but
> on-demand refresh must use the lakehouse-scoped
> `refreshMaterializedLakeViews/instances` endpoint. The skill now also
> absorbs the 2026-07-01 public API additions for MLV execution
> definitions and selected-lineage refresh via
> `executionData.mlvExecutionDefinitionId`, and directs interactive
> recurring refresh to Lakehouse schedules instead of notebook or
> pipeline orchestration.

Confirmed on Learn, 2026-09-10 —
[Manage and refresh materialized lake views in Fabric with APIs](https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/materialized-lake-views-public-api):

> An MLV execution definition is a saved configuration that specifies
> which materialized lake views to refresh, which upstream lakehouses to
> include, and which refresh mode and Spark environment to use. It
> defines a subset of the lineage that can be refreshed independently.

Endpoints, all under
`https://api.fabric.microsoft.com/v1/workspaces/{WORKSPACE_ID}/lakehouses/{LAKEHOUSE_ID}`:

| Operation | Request | Response |
| --- | --- | --- |
| Create | `POST /mlvexecutiondefinitions` | `201 Created`, `Location` |
| List | `GET /mlvexecutiondefinitions` | `200 OK` |
| Get | `GET /mlvexecutiondefinitions/{id}` | `200 OK` |
| Update | `PATCH /mlvexecutiondefinitions/{id}` | `200 OK` |
| Delete | `DELETE /mlvexecutiondefinitions/{id}` | `200 OK` |
| Scoped refresh | `POST /jobs/RefreshMaterializedLakeViews/instances` with `executionData` | `202 Accepted`, `Location`, `Retry-After: 60` |
| Scoped schedule | `POST` or `PATCH /jobs/RefreshMaterializedLakeViews/schedules[/{id}]` with `executionData` | `201` / `200` |

Create body, from Learn's sample:

```json
{
  "displayName": "Gold Chain – Sales",
  "description": "Nightly refresh for the Sales gold-layer views",
  "settings": {
    "environment": {
      "referenceType": "ById",
      "itemId": "<ENVIRONMENT_ID>",
      "workspaceId": "<ENVIRONMENT_WORKSPACE_ID>"
    },
    "refreshMode": "Optimal"
  },
  "currentLakehouseExecutionContext": {
    "mode": "Selected",
    "selectedMlvs": ["dbo.gold_sales_summary", "dbo.gold_sales_daily"]
  },
  "extendedLineageExecutionContext": {
    "mode": "All"
  }
}
```

Scoping a refresh or schedule:
`{"executionData": {"mlvExecutionDefinitionId": "<mlvExecutionDefinitionId>"}}`.

Two silent behaviours, verbatim:

> Only the fields provided in the request body are updated; omitted
> fields retain their existing values.

> Delete an MLV execution definition. Any schedules linked to it are also
> removed.

REST reference:
https://learn.microsoft.com/rest/api/fabric/lakehouse/materialized-lake-views

Current skill — `SKILL.md` line 195:

> `{jobType}` is `RefreshMaterializedLakeViews` for every MLV endpoint.

and lines 197–214 list on-demand refresh, schedule CRUD and job-instance
endpoints only.

## What to change

1. **`SKILL.md`, `## REST API (job scheduler)`** (line 193): add the
   execution-definition CRUD endpoints and the `executionData` body on
   on-demand refresh and on schedule create/update. Include the PATCH
   merge semantics and the linked-schedule deletion — a caller will not
   guess either.
2. **`references/REFERENCE.md`, the REST section** (lines 36–38): add the
   REST reference link above.
3. **Optional:** the `description` names "`RefreshMaterializedLakeViews`
   REST job-type"; adding "execution definitions" would help triggering,
   but the description is at the 1,024-character cap (measured roughly
   2026-09-10). Only if something else gives way; the linter decides.

## Constraint on the fix

- **Do not encode upstream's job-type mismatch.** Learn's job-instance
  samples show `"jobType": "RefreshMaterializedLakeViews"` and never show
  `MaterializedLakeViews`. Line 195 agrees with Learn; keep it.
- Learn's samples show `refreshMode` values `Optimal` and `Full`. Don't
  list others without a source.
- Upstream's advice to direct interactive recurring refresh to Lakehouse
  schedules is a workflow preference, not a platform fact. Not part of
  this brief.

## Out of scope

The drift-audit registry's counterpart table does not list `fabric-mlv`,
which is why this bullet reached the audit only by reading around the
table. That is fixed in brief 06, not here.

## Verification

1. `grep -nE 'mlvexecutiondefinitions|mlvExecutionDefinitionId' skills/fabric/fabric-mlv/SKILL.md`
   — both present.
2. `grep -n 'MaterializedLakeViews' skills/fabric/fabric-mlv/SKILL.md | grep -v RefreshMaterializedLakeViews`
   — no hits, so no mismatch claim was encoded.
3. Re-fetch the Learn page and confirm endpoint paths and field names.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-mlv/SKILL.md`
5. `pre-commit run --all-files`

## Provenance

First `/drift-audit --sources skills-for-fabric` run, 2026-09-10, from a
0.3.11 `mlv-operations-cli` bullet. The execution-definition API is
confirmed on Learn; the job-type mismatch is not, and Learn's samples
point the other way.

## Execution log

- **Executed**: 2026-09-11 — applied
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in the session)
- **Files changed**: `skills/fabric/fabric-mlv/SKILL.md`,
  `skills/fabric/fabric-mlv/references/REFERENCE.md`
- **Verification**: steps 1–4 passed. Step 1: CRUD paths at lines
  223–227 and `mlvExecutionDefinitionId` at 253. Step 2: no bare
  `MaterializedLakeViews`. Step 3: the Learn page re-fetched, with every
  path, status code, field name, the PATCH merge and the
  linked-schedule deletion as the brief quotes them. Every job-instance
  sample there still reads `RefreshMaterializedLakeViews`. Step 4: lint
  clean. The REST reference link was fetched before adding it; it
  resolves to the five execution-definition operations. Step 5 runs once
  at the end of the run.
- **Behavioural confirmation**: deferred here, run 2026-09-12 by
  `/test-skill fabric-mlv` in a fresh session. Phase A was skipped —
  `fabric-mlv` carries no `paths:` glob, so it has no activation
  contract to fixture. Four `-p` probes outside this repo with MCP and
  web stripped (`--strict-mcp-config`, `WebFetch`/`WebSearch`
  disallowed), so the answers measure the skill rather than a re-fetch
  of the Learn page it was drilled from. The `--safe-mode` baseline —
  payload proven absent, 54 slash commands against 67 — declined all
  three claims outright and offered to go read the docs instead.
  Model-invocation and `/fabric-mlv` each returned the
  `mlvexecutiondefinitions` casing, the PATCH merge and the
  linked-schedule deletion. Neither invented a rule for the nested
  `settings` merge Learn leaves open; both flagged it as unverified.
- **Optional item 3 measured rather than assumed**: a subset-refresh
  question naming neither "execution definition" nor
  `mlvExecutionDefinitionId` still model-invoked the skill, so leaving
  the description at its 1,024-character cap cost no triggering.
- **Deviations**: optional item 3 skipped. The description measured
  exactly 1,024 characters on 2026-09-11, and nothing gives way without
  an unbriefed trigger rewrite. The new material is a `###` subsection
  closing `## REST API (job scheduler)`. Line 195 is unchanged, and only
  `Optimal` / `Full` are named.
