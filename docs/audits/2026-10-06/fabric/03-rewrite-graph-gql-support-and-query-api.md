# Handoff: rewrite the graph skill's GQL support and Query API

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 3
- **Kind**: partial rewrite of a skill's language-support claims and of
  its REST contract for running queries, plus one flag. The Query API
  half changes what code written from the skill sends and how it reads
  responses.
- **Target**: `skills/fabric/fabric-graph/SKILL.md` (lines 21, 75–87,
  107, 113, 115), `skills/fabric/fabric-graph/references/REFERENCE.md`
  (lines 159–160, 173, 205–213)

## The problem

`fabric-graph` says GQL in Fabric has no set operations, `UNION
DISTINCT` included, and no `NEXT`, and that variable-length patterns
stop at 8 hops. All three are now false: `UNION ALL` and `UNION
DISTINCT` are supported, `NEXT` composes query stages, and the 8-hop cap
applies to the Explore UI only.

The skill's Query API section is also out of date. It describes a
six-character status string with a `03` prefix. Learn documents a
`beta=true` parameter, five-character status codes and continuation
polling. Client code written from the skill would misread a
still-running query as an empty result.

## Evidence

**What's New.** Three rows were added by `80a24c9b` (2026-09-29) to the
page's Fabric IQ section and deleted by the restructure `9eda27f8`
(2026-10-02), so none is on the live page: "Graph in Microsoft Fabric:
GQL enhancements", "Graph in Microsoft Fabric: Extended graph
traversal", "Graph in Microsoft Fabric: Incremental data updates".

**The skill** (agent-measured, 2026-10-06):

- `SKILL.md:115` — "**Set operations not yet supported.** `UNION
  DISTINCT`, `EXCEPT`, `INTERSECT`, and `OTHERWISE` are not available"
- `SKILL.md:113` — "variable-length patterns support up to **8 hops**"
- `REF:159-160` — set operations "No"; `NEXT` "No"
- `SKILL.md:75-87` and `REF:173,205-213` — a "6-char string" status
  and a `03` prefix
- `SKILL.md:21` — "**No schema evolution.** … means **reingesting
  source data into a new model**"; `SKILL.md:107` — "**Save = ingest.**"

**Learn, checked in the audit session on 2026-10-06.**
https://learn.microsoft.com/fabric/graph/limitations:

> `UNION ALL` and `UNION DISTINCT` are supported. `INTERSECT`,
> `EXCEPT`, and `OTHERWISE` aren't yet supported.

The page's list of supported statements and clauses:

- `MATCH` and `OPTIONAL MATCH`; `WHERE`; `LET`; `FOR ... IN` with
  optional `ORDINALITY`;
- `NEXT`, including stages that contain `UNION`, `UNION DISTINCT` or
  `UNION ALL`;
- `RETURN` and `RETURN DISTINCT`; `GROUP BY`; `ORDER BY` with
  `NULLS FIRST`/`NULLS LAST`; `LIMIT` and `OFFSET`;
- `CALL`, `OPTIONAL CALL` and `EXISTS`; `CAST`.

Subqueries:

- Inline `CALL` and procedure-form `EXISTS` are supported.
- Named procedure calls, explicit import lists (`CALL (p) { ... }`),
  graph-pattern-only `EXISTS` and scalar `VALUE { ... }` are not.

Aggregates:

- Supported: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `COLLECT_LIST`,
  `COLLECT_ONE`, `COLLECT_ELEMENTS`, their `DISTINCT` variants, and
  horizontal variants.
- Not yet: `PERCENTILE_CONT`/`PERCENTILE_DISC`,
  `STDDEV_POP`/`STDDEV_SAMP` and `PRODUCT`.

Size and time limits:

- Responses over 64 MB are truncated, with status `01000` (canonical
  `01M11`), and intermediate results are capped at 128 MB.
- A query has 20 minutes in total, including continuations, after
  which it fails with HTTP 408 `QueryTimeout`.

The mapping agent also read, on 2026-10-06:

- "The **Explore** UI path builder supports up to eight hops… This
  user-interface limit doesn't apply to GQL queries entered in the code
  editor."
- The conformance page marks GQ20 (linear composition with `NEXT`) as
  "Yes".
- The language guide adds `FOR`, `CALL`, `WHEN`, `OPTIONAL MATCH`, the
  `TRAIL`/`SIMPLE`/`ACYCLIC` path modes and `ANY SHORTEST`.

**Query API, checked in the audit session** —
https://learn.microsoft.com/fabric/graph/gql-query-api:

```http
POST https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/graphModels/{graphModelId}/executeQuery?beta=true
```

> The Query API is in beta and isn't recommended for production use. Set
> the required `beta` query parameter to `true`. The older
> `preview=true` parameter remains supported for backward
> compatibility, but use `beta=true` for new integrations.

Continuation: a query still running returns HTTP 200 with
`status.code` `02000`, an empty table and `result.nextPage`. The client
re-sends the same body with `&continuationToken=<token>`, percent-encoded
once, until `nextPage` is absent. Status codes,
from https://learn.microsoft.com/fabric/graph/gql-reference-status-codes:

| Code | Meaning |
| --- | --- |
| `00000` | success with at least one row |
| `00001` | omitted result, reserved for future DDL/DML |
| `01000` | warning or informational |
| `02000` | no rows yet; with `nextPage`, still running |
| `42000` | user-correctable query error |
| `50000` | system or unclassified error |

Learn: "Every status object includes a five-character alphanumeric
code". The canonical GQLSTATUS is kept in `_graphaneGqlStatus`: for
example `22003` and `22012` both surface as `42000`. Don't parse the
description text. The agent also read HTTP 408, 429 and 499 on the
API page.

**Incremental updates.** Learn,
https://learn.microsoft.com/en-us/fabric/graph/manage-data: "Because
save and ingestion are a single operation, every save refreshes your
graph data." The limitations page: "Schema changes trigger a graph
reload." No Learn page documents incremental updates yet.

## What to change

1. **`SKILL.md:115`** — set operations: `UNION ALL` and `UNION
   DISTINCT` supported; `INTERSECT`, `EXCEPT` and `OTHERWISE` not yet.
2. **`SKILL.md:113`** — the 8-hop cap is the Explore UI's; GQL in the
   code editor is not limited by it.
3. **`REF:159-160`** — flip set operations and `NEXT` to match, and add
   the statements Learn now lists if the table enumerates statements.
4. **`SKILL.md:75-87` and `REF:173, 205-213`** — the Query API: the
   `beta=true` parameter, five-character codes, continuation polling,
   the 64 MB truncation and the 20-minute total timeout.
5. **`SKILL.md:21` and `:107`** — flag only. Leave the text, and note
   that incremental updates were announced on 2026-09-29 with no Learn
   page yet.

## Constraint on the fix

- Do not document incremental updates until Learn does. The skill's
  "save = ingest" claim still matches Learn.
- Out of scope, noted by the mapping agent but not in the recommended
  action:
  - `REF:389` says "Parquet and CSV only", where Learn says OneLake and
    mirrored databases.
  - `REF:392` gives a 20-minute create timeout, where Learn says hours.
  - `REF:387` caps graph models at 10 per workspace, and `:397` lists
    `ANY`/`RECORD` as unsupported; Learn now lists `RECORD` as a type.
  - `SKILL.md:40-69` uses graph-type DDL, which the language guide says
    Graph doesn't accept directly.

  These are unverified here; raise them as a separate request rather
  than folding them in.

## Verification

1. `grep -n -i "set operation\|UNION\|8 hops\|NEXT\|preview=true\|beta=true\|6-char\|03" skills/fabric/fabric-graph/SKILL.md skills/fabric/fabric-graph/references/REFERENCE.md`
   — no hit still denies `UNION DISTINCT` or `NEXT`, and no hit
   describes a six-character status.
2. Re-open the limitations, query-API and status-code pages and confirm
   the quoted text.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-graph/SKILL.md`
4. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01, by the Real-Time Intelligence mapping subagent. That agent
found the Query API drift while drilling the GQL entries; it is not
itself a What's New row. All three GQL rows were transient: added and
deleted inside the window. The audit session checked the set-operation
and Query API facts itself. A plain base-to-head diff would have missed
these rows, which is brief 18's subject.
