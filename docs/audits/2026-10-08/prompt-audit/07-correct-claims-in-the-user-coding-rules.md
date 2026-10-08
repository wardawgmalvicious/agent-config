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
