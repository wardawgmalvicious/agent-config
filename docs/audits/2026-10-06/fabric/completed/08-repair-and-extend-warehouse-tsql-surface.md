# Handoff: repair and extend the warehouse T-SQL surface

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 8 and 9
- **Kind**: four independent defects in one skill and one rule:
  - a repo-defect repair (text truncated by a refactor, recoverable
    from git);
  - additive syntax documentation of the same Warehouse T-SQL facts in
    the skill and the rule;
  - two minor edits.
- **Target**: `skills/fabric/fabric-warehouse/SKILL.md` (lines
  152–159), `skills/fabric/fabric-warehouse/references/t-sql-surface.md`
  (lines 6–15, 26–30), `skills/fabric/fabric-warehouse/references/platform-features.md`
  (lines 86, 110), `claude/rules/coding-tsql.md` (lines 30–35, 134, 201)

## Context

Actions 8 and 9 share one brief because they document the same new
Warehouse T-SQL surface in two files, and one Learn check verifies both.
The truncation repair travels with them because the COPY INTO edit
lands on the truncated lines; repair those first.

## D-1 — two passages were truncated by the references split

**Symptom.** `SKILL.md:154-156` is an orphaned continuation with no
bullet of its own. It follows the "Keep transactions short" bullet:

```text
- **Keep transactions short** to shrink the conflict window. Error 24556 / 24706
  = snapshot conflict → serialize and retry with exponential backoff.
  `PARQUET` / `CSV` / `JSONL` (JSONL April 2026). Needs Storage Blob Data Reader
  on ADLS or a SAS in CREDENTIAL; `WITH (AUTO_CREATE_TABLE = 'TRUE')` creates the
  target. Files ≥ 4 MB optimal.
```

`references/t-sql-surface.md:28-29` ends two bullets mid-sentence:

```text
- **COPY INTO** for external file ingestion — highest throughput. `FILE_TYPE`:
- **`bcp` is preview**; the `BULK LOAD` / `BULK INSERT` T-SQL statements are
```

**Cause.** Commit `dbed250` (2026-08-31, "refactor: split
fabric-warehouse detail into references/") cut both bullets. The audit
session checked every later commit touching either file, and all carry
the break.

**Fix.** Recover the text from the commit before the split.
`git show 'dbed250^:skills/fabric/fabric-warehouse/SKILL.md'`, lines
171–172, read on 2026-10-06:

```text
- **COPY INTO** for external file ingestion — highest throughput. `FILE_TYPE`: `PARQUET` / `CSV` / `JSONL` (JSONL added April 2026). Requires Storage Blob Data Reader on ADLS or SAS in CREDENTIAL. Set `WITH (AUTO_CREATE_TABLE = 'TRUE')` to create the target table on the fly. Files ≥ 4 MB optimal.
- **`bcp` is supported as a preview feature** for bulk load/export from the command line. The `BULK LOAD` and `BULK INSERT` T-SQL statements are **not** supported — use COPY INTO / OPENROWSET for in-engine ingestion instead.
```

Complete the two bullets in `t-sql-surface.md`, and remove the orphaned
fragment from `SKILL.md`. Its "Ingestion" bullet at `:157-159` already
points to the reference.

## D-2 — new Warehouse T-SQL syntax is undocumented

**Symptom.** `references/t-sql-surface.md:6-15`, "Supported features",
lists none of the following, and `coding-tsql.md`'s Warehouse-only
carve-out (`:30-35`) names only "the ANSI string operators … and
`OPTION (FOR TIMESTAMP AS OF ...)`":

- FROM-first queries;
- `GROUP BY ALL` and `ORDER BY ALL`;
- `ROLLUP`, `CUBE` and `GROUPING SETS`;
- `QUALIFY`;
- `MEDIAN`, `QUANTILE`, `APPROX_MEDIAN` and `APPROX_QUANTILE`.

**Evidence.** What's New:

- "New T-SQL syntax for Fabric Data Warehouse and the SQL analytics
  endpoint" was added to the page's Data Warehouse section by
  `80a24c9b` (2026-09-29) and deleted by the restructure `9eda27f8`
  (2026-10-02).
- "Warehouse T-SQL enhancements (Preview)" and "Warehouse analytical
  functions (Preview)" were added by `9eda27f8`.

Learn (agent-measured, 2026-10-06):

- `https://learn.microsoft.com/en-us/fabric/data-warehouse/tsql-surface-area`:
  - "support the `GROUP BY ALL` and `ORDER BY ALL` syntax without a
    column list."
  - "support analytical and aggregate functions specific including
    APPROX_MEDIAN, APPROX_QUANTILE, MEDIAN, and QUANTILE."
- `https://learn.microsoft.com/en-us/sql/t-sql/queries/from-select-transact-sql?view=fabric`
  — "`FROM`-first query syntax isn't supported in SQL Server, Azure SQL
  Database, Azure SQL Managed Instance, or SQL database in Fabric."
- `https://learn.microsoft.com/en-us/sql/t-sql/queries/select-qualify-clause-transact-sql?view=fabric`
  — "The `QUALIFY` clause filters rows returned by a query based on a
  search condition that can reference window (analytic) functions."
- The Fabric `GROUP BY` grammar adds `ROLLUP`, `CUBE`, `GROUPING SETS`
  and `()`.
- `https://learn.microsoft.com/en-us/sql/t-sql/functions/median-transact-sql?view=fabric`
  — "The `MEDIAN` function isn't supported in SQL Server, Azure SQL
  Database, Azure SQL Managed Instance, or SQL database in Fabric."

**Fix.** Add the constructs to `t-sql-surface.md` and to the rule's
carve-out, as Warehouse and SQL analytics endpoint only, never SQL
database in Fabric.

**Open question.** Preview status. What's New labels the enhancements
and analytical functions preview, but the Learn syntax pages carry no
preview banner. Record what each source says, dated, rather than
choosing.

**Knock-on, `coding-tsql.md`.**

- `:134` reads "Use CTEs (`WITH`) for any non-trivial multi-step logic."
  `QUALIFY` replaces the top-N-per-group CTE on Warehouse; say when to
  prefer it.
- `:201` forbids `SELECT *` in "production code, views, stored procs."
  A FROM-first query with no `SELECT` is an implicit `SELECT *`, so the
  rule should name that form too.

## D-3 — COPY INTO with workspace identity

**Symptom.** The COPY INTO guidance (the recovered D-1 text) names only
Storage Blob Data Reader or a SAS. What's New `91e49056` (2026-09-09)
added "COPY INTO with workspace identity (Generally Available)", August
2026.

**Fix.** Learn,
`https://learn.microsoft.com/en-us/fabric/data-warehouse/ingest-data`
(agent-measured): "The `WITH (CREDENTIAL = (IDENTITY = 'Workspace
Identity'))` clause allows `COPY INTO` to impersonate the workspace
identity only when it accesses the source." The agent read that it
applies to Blob, ADLS Gen2 and OneLake sources. Add it as a third
authentication option. The What's New row links `ingest-data-copy`,
which carries no authentication text; cite `ingest-data`.

## D-4 — warehouse deployment scripts

**Symptom.** `references/platform-features.md:86` says "Security never
deploys; migrate GRANT/DENY/RLS separately", and `:110` says "Security
objects — permissions need their own export and migration path."
What's New `9eda27f8` added "Warehouse pre/post deployment support
(Preview)".

**Fix.** Learn,
`https://learn.microsoft.com/fabric/data-warehouse/deployment-scripts`
(agent-measured): "A warehouse supports at most one pre-deployment
script and one post-deployment script."; "Use a post-deployment script
to recreate these objects after deployment". Add it, marked preview.

**Knock-on.** The Git-integration page still lists scripts "added
directly to the database project through Git" as not preserved. Keep
any existing warning about hand-authored files.

## Sequencing note

Brief 11 makes the COPY INTO and deployment-script edits in
`fabric-gotchas` (`SKILL.md:20, 54`). Keep the wording consistent with
D-3 and D-4. The rule edit loads `.claude/rules/editing-rules.md` on
Read; read it first.

## Verification

1. `grep -n "FILE_TYPE\|BULK INSERT\|JSONL" skills/fabric/fabric-warehouse/SKILL.md skills/fabric/fabric-warehouse/references/t-sql-surface.md`
   — no line ends mid-sentence, and `SKILL.md` has no orphaned fragment
   after "Keep transactions short".
2. `grep -n -i "QUALIFY\|GROUP BY ALL\|GROUPING SETS\|MEDIAN\|FROM-first" skills/fabric/fabric-warehouse/references/t-sql-surface.md claude/rules/coding-tsql.md`
   — each construct appears in both, marked Warehouse/SQL analytics
   endpoint only.
3. `grep -n -i "Workspace Identity" skills/fabric/fabric-warehouse` and
   `grep -n -i "deployment script" skills/fabric/fabric-warehouse/references/platform-features.md`.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-warehouse/SKILL.md`
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01, by the warehouse/Spark mapping subagent. The audit session
confirmed the truncation itself and recovered the pre-split text from
`dbed250^`. The truncation is a repo defect, not upstream drift. It
travels here only because D-3 edits the same lines. The new-syntax row
was transient, so a plain base-to-head diff would have missed it.

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: `skills/fabric/fabric-warehouse/SKILL.md`,
  `skills/fabric/fabric-warehouse/references/t-sql-surface.md`,
  `skills/fabric/fabric-warehouse/references/platform-features.md`,
  `claude/rules/coding-tsql.md`, `copilot/.source-hashes.json`
- **Verification**: steps 1–4 passed, with the deviation in step 2
  below; step 5 runs once at the end of the run. Step 1: no line ends
  mid-sentence, and `SKILL.md` has no fragment after "Keep
  transactions short". Step 2: FROM-first, `GROUP BY ALL`, `QUALIFY`
  and the `MEDIAN` family appear in both files, marked Warehouse and
  SQL analytics endpoint only; `GROUPING SETS` is in
  `t-sql-surface.md` only, per deviation 2. Step 3: Workspace Identity
  is in `t-sql-surface.md`, and the deployment scripts are in
  `platform-features.md`. Step 4: lint clean on `SKILL.md` and on the
  rule.
- **Learn, re-read 2026-10-06**: `tsql-surface-area` (`GROUP BY ALL` /
  `ORDER BY ALL`, `QUALIFY`, the four functions; among the
  limitations, `BULK LOAD` only); the FROM-first page (Warehouse and
  SQL analytics endpoint only; omitting `SELECT` means `SELECT *`); the
  `QUALIFY`, `MEDIAN`, `QUANTILE` and `APPROX_*` pages (not in SQL
  database in Fabric, with no preview label); the GROUP BY page (the
  ISO `ROLLUP`/`CUBE`/`GROUPING SETS` syntax applies to SQL Server,
  Azure SQL, MI and SQL database in Fabric); `ingest-data` (the
  Workspace Identity section as quoted, plus "The Warehouse also
  supports the traditional `BULK INSERT` statement for compatibility");
  and `deployment-scripts` (preview, at most one of each, used to
  recreate SQL security).
- **D-2's open question**: settled by its own instruction. Both
  statuses are recorded, dated, in each file: What's New preview
  (2026-10-02) and no Learn preview label (2026-10-06).
- **Deferred**: `claude/rules/coding-tsql.md` is a copied payload, so
  the edit goes live only when `link-claude.ps1` runs on `main` after
  the landing. Adjacent, not fixed: `platform-features.md:13` still
  says "(`BULK LOAD` / `BULK INSERT` T-SQL not supported)", the claim
  deviation 1 corrected elsewhere; it was outside the brief's lines and
  the user's answer. Behavioural confirmation needs a fresh session.
- **Deviations**: four. The first two were user-directed on 2026-10-06,
  after asking. (1) D-1's `bcp` bullet was completed from Learn, not
  verbatim: the pre-split text called `BULK INSERT` unsupported, which
  Learn no longer says. `SKILL.md`'s Ingestion bullet, inside the
  brief's lines, was corrected the same way. (2) D-2: `ROLLUP`, `CUBE`
  and `GROUPING SETS` are recorded as supported in Warehouse but not
  Warehouse-only, and stay out of the rule's SQL-database carve-out,
  because Learn's GROUP BY page gives that syntax to SQL database in
  Fabric. (3) The rule gained no new section: the constructs went into
  the carve-out, plus the two knock-ons, since the rule loads on every
  `.sql` file. (4) `lint-instructions.py --stamp` re-recorded the
  rule's hash for its Copilot port, per `editing-rules.md`, leaving the
  port itself untouched. Only the `coding-tsql` entry changed; the
  script wrote the file with CRLF, which `.gitattributes` normalizes.
- **Needs**: the landing — `link-claude.ps1` deploys the
  `coding-tsql` edit; the `platform-features.md:13` fix under Deferred
  needs nothing.
- **Needs**: none — the `platform-features.md:13` fix under Deferred.
  The landing is done: `link-claude.ps1` ran on `main` at `f82cfd5`,
  and the deployed `coding-tsql` matches the repo (`cmp`, 2026-10-06).
- **Closed**: 2026-10-06 — `platform-features.md:13` now says
  `BULK LOAD` is unsupported and `BULK INSERT` works for compatibility,
  mapped to `COPY INTO`, as `SKILL.md`'s Ingestion bullet does.
