# Handoff: correct claims in the user-scope coding rules

- **Audit run**: 2026-10-08
- **Source**: `prompt-audit`
- **Window**: floor none, the whole payload → head `c268691`
  (2026-10-08)
- **Covers recommended actions**: findings 6, 16, 25, 26, 29, 31 and 33
- **Kind**: factual corrections to user-scope coding rules, each checked
  against its own source. Reaches every repo at the next deploy.
- **Target**: `claude/rules/coding-python.md`,
  `claude/rules/coding-sparksql.md`,
  `claude/rules/coding-powershell.md`, `claude/rules/coding-tsql.md`,
  `claude/rules/coding-expressions.md`, `claude/rules/coding-kql.md`

## The problem

Seven passages in the user-scope coding rules state something their
platform's documentation, or the rule's own examples, contradicts. Each
loads in every repo that has a matching file.

## Evidence and what to change

Line numbers at `c268691`; each quote is the report's.

| # | Location | Says | Why it is wrong | Check against | Change |
| --- | --- | --- | --- | --- | --- |
| 6 | `coding-python.md:206-218` | "`notebookutils.runtime.context` parameters", and `source_schema or SourceSchema` | `fabric-spark` documents `runtime.context` as an identity dict, and the example never reads `SourceSchema`, since `"raw"` is truthy | `skills/fabric/fabric-spark`; Learn's notebook parameter docs | a parameters cell; the report suggests `globals().get` |
| 29 | `coding-python.md:174-194` | "operations are lazy", "`MEMORY_AND_DISK` by default" | textbook Spark, paid on every `.py` load, and the cache default is imprecise | Spark's `DataFrame.cache` docs | trim to the house choices, keeping the headings |
| 16 | `coding-sparksql.md:147-148` | "no variables (`DECLARE`), no `IF`/`WHILE`" | Fabric Runtime 2.0 (Spark 4.1, GA) adds session variables; Databricks has `DECLARE VARIABLE` and SQL scripting | Learn's Runtime 2.0 page; the Databricks SQL reference | state it per runtime |
| 25 | `coding-powershell.md:182-183` | "Scripts here run `Set-StrictMode`" | the rule loads in every repo, one script here calls it, and the rule's own template leaves it out | the template in the same file | make it conditional, or put it in the template if it is house style |
| 26 | `coding-tsql.md:56-57` | "Aliases: PascalCase" | every example table alias is lowercase (`c`, `line`, `prod`, `cust`) | the file's own examples | match the examples, or change them |
| 31 | `coding-expressions.md:9, 15` | "ADF / Synapse … no auto-load" | the rule's own `**/pipeline/*.json` glob is where their Git integration writes pipelines | the ADF and Synapse Git-integration docs | rewrite |
| 33 | `coding-kql.md:117-118` | "Default changed historically" | the reason is that `innerunique` dedupes the left side | the KQL `join` docs | rewrite to the reason |

## State when written

A `/triage` of a prompt audit run in a client repo against the same
payload landed on 2026-10-08:

- Finding 6, in `d60be04`: a parameter cell of defaults, converted in
  the next cell, after Learn (read that day) said the engine inserts a
  cell overriding the defaults by exact name. Already-applied; it took
  no `globals().get`.
- Other lines of `coding-sparksql.md` (`d60be04`) and
  `coding-powershell.md` (`8510852`), not this brief's.

Findings 16, 25, 26, 29, 31 and 33 still held at `566973a`. Re-read
each file at `HEAD` first; the patch's hunks for a file edited since
will not apply.

## Constraint on the fix

Findings 25 and 26 are choices, not errors, so record which way each
fix went and why. Finding 16 needs both runtimes' documentation: a rule
covering Fabric and Databricks must not state one runtime's limit as
both's.

## Verification

1. Each finding's source, with the date read, in the log.
2. `uv run --with pyyaml scripts/lint-frontmatter.py` on each changed
   rule.
3. `uv run --with pyyaml scripts/lint-instructions.py --stamp`:
   `coding-python`, `coding-sparksql`, `coding-tsql`,
   `coding-expressions` and `coding-kql` have frozen Copilot ports,
   which stay as they are (`editing-rules.md`).
4. `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`.
5. `pre-commit run --all-files`.

## Provenance

Findings 6 and 16 (high) and 25, 26, 29, 31 and 33 (medium) from
`/doctor prompt-audit` run in this repo on 2026-10-08. The session that
wrote this brief did not check them against their sources.

## Execution log

- **Executed**: 2026-10-08 — applied with deferrals
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: `claude/rules/coding-python.md`,
  `claude/rules/coding-sparksql.md`, `claude/rules/coding-powershell.md`,
  `claude/rules/coding-tsql.md`, `claude/rules/coding-expressions.md`,
  `claude/rules/coding-kql.md`, `copilot/.source-hashes.json`
- **Verification**: the staleness gate at `26f8582` found findings 16,
  25, 26, 29, 31 and 33 at the lines the table gives, and finding 6's
  post-fix text at `coding-python.md:206-222`, from `d60be04`, with the
  old quotes gone. Step 1 — **done**, every source read 2026-10-08:
  - 6, already in the tree: Learn's notebook page, § "Designate a
    parameters cell": "The execution engine adds a new cell beneath the
    parameters cell with input parameters in order to overwrite the
    default values", names matching; `d60be04`'s wording stands.
  - 29: PySpark's `DataFrame.cache` page (4.2.0 docs): "Persists the
    `DataFrame` with the default storage level (MEMORY_AND_DISK_DESER)",
    changed "to match Scala in 3.0".
  - 16: Learn's Runtime 2.0 page (GA, Spark 4.1, "session variables",
    and "it isn't the default runtime yet") and Runtime 1.3 page (Spark
    3.5); Spark's 4.1.0 release notes, "SQL Scripting is GA and enabled
    by default" (SPARK-54499); Learn's Databricks reference:
    `DECLARE VARIABLE` from Runtime 14.1, SQL scripting from 16.3, SQL
    stored procedures from 17.0.
  - 25 and 26: the files themselves, under **Deviations**.
  - 31: Learn's "Source control in Azure Data Factory" and "Source
    control in Synapse Studio", each read whole: every resource is
    exported as its own JSON, and neither names a folder; npm refused
    the ADF utilities README, 403.
  - 33: Learn's `join` operator and `innerunique` pages: "innerunique
    (default)", "Inner join with left side deduplication", and either
    duplicate may be the row kept.

  Step 2 — **passed**: `lint-frontmatter.py` on the six rules, exit 0.
  Step 3 — **passed**: `lint-instructions.py` failed `drift` on the
  five ported rules, as expected; `--stamp` recorded their five hashes,
  the ports untouched, and the re-check exited 0. Step 5
  (`pre-commit run --all-files`) runs once at the end of the run.
- **Deferred**: step 4, which needs the deployed payload:
  `link-claude.ps1` refuses a worktree, so from the main checkout after
  the landing, `./scripts/link-claude.ps1 -SkillGroups
  workflow,social,meta`, then `cmp` each deployed rule with the repo's.
  And finding 31's folder: Learn names none for ADF or Synapse, so line
  15 says what the glob matches, and a repo with either's Git
  integration would show where its pipelines land.
- **Deviations**: finding 25 went conditional: one of this repo's seven
  PowerShell files sets strict mode, `scripts/repo-settings.ps1`, the
  rule loads in every repo, and its own template leaves it out, so a
  house-style line would set a convention no file here follows. Finding
  26 follows the examples: their 13 table aliases are all lowercase and
  both column aliases PascalCase, so the rule names each case and no
  example changed. Finding 16 credits SQL scripting to Spark 4.1's
  notes, since Fabric's Runtime 2.0 page names only the variables, and
  names no default runtime, since that page still says 2.0 is not one.
  Finding 29 dropped "DataFrame operations are lazy" and the
  `MEMORY_AND_DISK` claim, kept the three headings and the house
  choices, and folded the repartition bullet into the coalesce
  preference. Finding 31 is applied as far as the glob establishes.
- **Needs**: the landing, an ADF or Synapse Git repo — `link-claude.ps1`
  deploys the six rules for step 4's diff; then where such a repo's
  pipelines land, to name the folder in `coding-expressions.md`.
