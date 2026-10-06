# Handoff: correct the mirroring kinds and flag the September announcements

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: none — briefed on request after the
  handoff; see Context
- **Kind**: minor edits and dated flags in one skill and its reference.
  Content only, unless D-4 row a is confirmed: that reaches the
  `description`, which changes what the skill triggers on.
- **Target**: `skills/fabric/fabric-mirroring/SKILL.md` (lines 3, 45,
  56–57, 198–210, 241–242),
  `skills/fabric/fabric-mirroring/references/source-matrix.md` (lines
  15, 29–30, 37–40, 186–192)

## Context

The report's first `fabric-mirroring` entry (`00-audit-report.md`, lines
289–296) never became a recommended action, so `/drift-handoff` wrote no
brief for it. The user asked for one the same day, after the directory
was first committed (`c982a59`). The entry proposes "flag (status);
minor edit (SharePoint List mirroring kinds)". D-1 to D-3 carry it.

D-4 is not from the audit. Re-reading Learn to write this brief turned
up four Snowflake claims, in the same two files, that did not match
Learn even when the skill was written. They share this brief's files
and verification, so they are here rather than in a brief of their own.

*Flag* means what it means in the rest of this run's briefs: keep the
current status label, and add a dated note beside the line. Never flip
a status on What's New alone.

**The What's New rows**, at head `7ff5f2b3`. None of them exists at
base `8375c89d`.

- **SharePoint List mirroring (Generally available)**: GA table,
  September 2026, first seen `80a24c9b` (2026-09-29). "SharePoint List
  mirroring is now generally available. You can continuously replicate
  SharePoint list data into OneLake and use it across Fabric
  workloads."
- **Extended mirroring capabilities (Generally Available)**: GA table,
  September 2026, first seen `9eda27f8` (2026-10-02). They "add change
  feeds and source-view mirroring for advanced replication scenarios",
  linking to "Extended capabilities in Mirroring".
- **Snowflake security-role mirroring (Preview)**: preview table, first
  seen `9eda27f8`. It "brings Snowflake role definitions into Fabric",
  linking to the same page.

**How Learn was read.** On 2026-10-06, as raw markdown from
`MicrosoftDocs/fabric-docs` at `main`, which is where the line numbers
below come from, and cross-checked through `microsoft-learn-mcp`. The
source table on `mirroring/overview` and
`mirroring/get-started-with-mirroring` is one include,
`docs/mirroring/includes/mirrored-sources-table.md`.

## D-1 — SharePoint List is listed as one kind, and its status is split

**Symptom.**

- `SKILL.md:56`: `| SharePoint List (preview) | Database |`
- `references/source-matrix.md:29`:
  `| SharePoint List (preview) | Database | — |`

**Cause.**

- **Kind.** `e42ed53c` (2026-09-24, "Enhance mirrored sources table
  with additional mirroring types") changed the include's row from
  "Database mirroring" to "Database mirroring, Metadata mirroring", and
  it still reads that at `main`. `mirroring/sharepoint-list` (`ms.date`
  2026-08-27) gives the split: "Document Library data is surfaced in
  OneLake through shortcuts, … without replicating the data itself",
  beside "The replication of managed table data into OneLake". The page
  carries Snowflake boilerplate ("Explore the tables that reference data
  in your Delta Lake tables from Snowflake."), so paraphrase it rather
  than quote it.
- **Status.** What's New lists it GA. Learn's include still reads
  "SharePoint List (preview)" and links "Tutorial: SharePoint List
  (preview)", and `get-started-with-mirroring.md:36` reads "Sources
  marked **(preview)** are in public preview; all other sources are
  generally available." The SharePoint List page itself has no preview
  label.

**Fix.** In both files, give the kind as Database and Metadata: list
data is replicated, and Document Library data comes through shortcuts.
Flag the status: keep "(preview)", and add a dated note that What's New
lists SharePoint List mirroring GA in September 2026 while Learn's
source table still marks it preview.

## D-2 — extended capabilities: What's New says GA, Learn says preview

**Symptom.**

- `SKILL.md:198`: `## 7. Extended capabilities (paid, preview)`
- `SKILL.md:209-210`: "**Mirroring views** — replicates source view
  logic instead of physical tables. **Snowflake only** in preview."
- `SKILL.md:241-242`: "(Mirroring views is the paid preview add-on in
  §7.)"
- `references/source-matrix.md:191-192`: "**Mirroring views**, the paid
  preview extended capability, is currently Snowflake-only."

**Cause.** `mirroring/extended-capabilities` (`ms.date` 2026-06-24)
still heads both sections "(preview)": "## Delta change data feed
(preview)" and "## Mirroring views (preview)". The report named only
the views label. The page also notes "Currently, views are only
supported in preview in mirroring for Snowflake.", and
`extended-capabilities-views.md:19` says the same. Its pricing claim
still matches the skill: "Mirroring without extended capabilities is
free."

**Fix.** Flag only. Keep every preview label. Add one dated note at the
§7 heading: What's New lists extended mirroring capabilities GA
(September 2026), while Learn still marks both change data feed and
mirroring views preview, read 2026-10-06.

## D-3 — Snowflake security-role mirroring is announced, not documented

**Symptom.** The skill doesn't mention it. `SKILL.md:253-258`, "Security
does not travel", says row-level security, object-level permissions,
dynamic data masking and Purview sensitivity labels "are **not**
propagated to the replicated data in OneLake".

**Cause.** The What's New row links to `mirroring/extended-capabilities`,
which has no text on roles or security. `mirroring/snowflake-limitations`
(`ms.date` 2026-02-26), line 84, still reads: "Fabric doesn't replicate
Snowflake Row-Level Security (RLS) and Column-Level Security (CLS)
policies. You must manually reconfigure equivalent security policies in
Fabric."

**Fix.** Flag only. Leave `SKILL.md:253-258` alone: it still holds for
RLS and CLS. Add one dated line to `source-matrix.md`'s Snowflake
section, saying that What's New announced role-definition mirroring in
preview (September 2026) and that Learn documented no such feature on
2026-10-06.

**Constraint.** Don't guess what "role definitions" become in Fabric:
workspace roles, OneLake security roles or SQL roles. Learn says
nothing yet.

## D-4 — four Snowflake claims that never matched Learn

Found while writing this brief, not by the audit. None was caused by an
in-window change: on 2026-08-30, the date the skill gives for its read
of Learn, Learn already disagreed with it on each. `mirroring/snowflake`
gained its object-type and authentication tables in `b53c4771`
(2026-07-02), with only a terminology edit since (`6724b585`,
2026-09-02). The views page has not changed since it was created
(`f0e3bab2`, 2026-06-29). For each row: check it against Learn, then
edit it if confirmed, or leave it with a one-line note in the execution
log.

| # | Target | Claim in the skill | What Learn says |
| --- | --- | --- | --- |
| a | `SKILL.md:57` and line 3 (`description`); `source-matrix.md:30`, `:188` | Snowflake is metadata mirroring; the description adds "data never moves" | The include read "Database mirroring" at `5745ba3b` (2026-08-28), and "Database mirroring, Metadata mirroring" since `e42ed53c`. `mirroring/snowflake`: "The replication of managed table and view data into OneLake and conversion to Parquet"; Iceberg table metadata comes through shortcuts. Against that, `onelake/unify-data` lists Snowflake under "Metadata mirroring (shortcuts)" (search excerpt only) |
| b | `source-matrix.md:191` | "Snowflake auth is username/password or Entra SSO" | `mirroring/snowflake`, "Supported authentication methods": key pair authentication is supported ("RSA key pair for service account scenarios"); workspace identity is not |
| c | `source-matrix.md:189-190`, `:37-40` | "native tables only are supported"; Snowflake Iceberg mirroring is undocumented, and "this skill says nothing about them" | `mirroring/snowflake`, "Supported Snowflake object types": managed tables, Iceberg tables, views and materialized views. Iceberg needs "a storage connection to the underlying Iceberg table storage". The page doesn't mark views preview or paid; `extended-capabilities` does, and D-2 keeps that |
| d | `SKILL.md:209-210` | Mirroring views, with no refresh cadence | `extended-capabilities-views.md:61`: "Fabric refreshes views every 12 hours, rather than in near real time as it does for table mirroring." The object-type table says the same for materialized views |

**Knock-on.** Row a reaches the `description`, which today reads
"metadata mirroring (catalog sync over OneLake shortcuts, data never
moves — Snowflake, Databricks, Dremio, AWS Glue, Azure Monitor)". A
`description` edit changes what the skill triggers on. Run
`uv run --with pyyaml scripts/skill-status.py --stale` and do the
retest it names, or split the `description` edit into its own task and
say so in the execution log.

## Constraint on the fix

- **Re-date only what was re-read.** `SKILL.md:45` ("From the
  `mirroring/overview` platform table as of 2026-08-30.") and
  `source-matrix.md:15` date the source table. AWS Glue and Azure
  Monitor have never been in it: include versions `6f1f50a8`,
  `5745ba3b` and `e42ed53c` were checked on 2026-10-06. Don't credit
  those two rows to the table when you re-date it.
- **Stay out of the monitoring passage.** `SKILL.md:315-317` belongs to
  brief 12.

## Sequencing note

Brief 12 (action 14) also edits `skills/fabric/fabric-mirroring/SKILL.md`,
at lines 315–317. Either can land first, but whichever runs second
re-reads the file before editing. Don't bundle them: brief 12 moves
three skills to the monitoring item and is verified across all three.

## Verification

1. `grep -n "SharePoint List" skills/fabric/fabric-mirroring/SKILL.md skills/fabric/fabric-mirroring/references/source-matrix.md`
   No row gives the kind as "Database" alone, and each has the dated
   status note beside it.
2. `grep -n "Extended capabilities" skills/fabric/fabric-mirroring/SKILL.md`
   The §7 heading still says preview, with the dated What's New note
   beside it.
3. `git diff skills/fabric/fabric-mirroring/SKILL.md` has no hunk inside
   the "Security does not travel" paragraph, and
   `grep -n -i "role" skills/fabric/fabric-mirroring/references/source-matrix.md`
   finds the dated line in the Snowflake section.
4. The execution log has one verdict per D-4 row: edited, or left with
   the reason.
5. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-mirroring/SKILL.md`.
   If the `description` changed,
   `uv run --with pyyaml scripts/skill-status.py --stale` names the
   skill; do the retest it asks for, or log it as deferred.
6. `pre-commit run --all-files`

## Provenance

The 2026-10-06 `/drift-audit` run against `fabric` (floor 2026-09-01)
found D-1 to D-3. One of its mapping subagents drilled
`extended-capabilities`, the source table and `snowflake-limitations`;
its quotes were agent-measured, and the audit left the finding out of
its action list, probably by mistake. The same session wrote this brief
later that day, at the user's request. It re-read every page as raw
markdown at `main` and walked the include's history, which dated the
SharePoint List change to `e42ed53c` and turned up D-4. D-4 rests on
that re-read alone.
