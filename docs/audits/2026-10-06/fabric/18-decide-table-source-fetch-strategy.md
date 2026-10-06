# Handoff: decide how the audit fetches a large table source

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 21
- **Kind**: a **decision** on the audit pipeline itself, followed by a
  `SKILL.md` edit. It changes how `/drift-audit` fetches and diffs a
  `table` source, and is verified by re-running an audit. The decision
  is the user's: `/drift-update` puts it back to the user rather than
  executing it.
- **Target**: `.claude/skills/drift-audit/SKILL.md` (§ 4a step 3, § 4b
  pricing paragraph and completeness check, § 4c)

## The problem

As written, the audit cannot audit this window of the `fabric` source
correctly. It fails in two ways, and nothing reports either failure:

1. **Context cost.** With more than 5 in-window commits, § 4a tells a
   `table` source to `get_file_contents` both refs and diff them. That
   would put about 355 KB of markdown into context against a 150 KB
   per-source budget. The on-disk exemption that would avoid it is
   written for `changelog` sources only.
2. **Silent under-reporting.** A base-to-head diff cannot see a row
   that was added and then deleted inside the window. Here that was 22
   rows, among them the window's most consequential: new Warehouse T-SQL
   syntax, the TMDL ontology experience and three GQL changes. Briefs 03,
   04 and 08 rest on them. A run that followed § 4a literally would have
   reported none of them, with no error.

§ 4b's "Both registered What's New sources are ~50 KB" and its WebFetch
price for `fabric` ("up to 14 (3 + its 11 named sections …)") are also
stale.

## Evidence

**Sizes and diff volume**, measured in the audit session on files
downloaded at pinned SHAs:

| Measure | Value |
| --- | --- |
| base `8375c89d` | 207,309 bytes, 609 lines |
| head `7ff5f2b3` | 147,892 bytes, 388 lines |
| `diff -u base head` | 736 lines, 267,382 bytes |
| in-window commits | 13 (one merge, `7ff5f2b3`) |

The unified diff alone is over the per-source budget. What kept the run
in budget was extracting rows by key on disk and bringing only the
classified rows into context.

**The method that worked**:

1. Raw HTTPS fetch of all 13 in-window versions plus the base, to the
   session scratchpad. That was 14 `curl` calls and 14 anonymous GitHub
   API calls for per-commit stats.
2. Confirm the chain is linear for the path. Each consecutive on-disk
   diff's +/− counts matched the API stats wherever the API listed the
   file. The API omitted it for `80a24c9b`, a 300-plus-file release.
3. Key each table row by its first bold span, recording its table or
   section and month. Normalize the `(Preview)` / `(Generally
   Available)` suffix so that cross-table moves match.
4. Classify each key: present at HEAD but not base; transient (added in
   the window, absent at HEAD); promoted; or gone under its base name.
   Write the result to an on-disk table (204 rows) and read only that
   table into context.

**The 22 transient rows.** Each was present from its first commit until
the restructure `9eda27f8` deleted it.

| Row | First seen |
| --- | --- |
| SQLCon/FabCon Europe SQL team sessions | `ecb721f5` |
| On-premises data gateway August 2026 release | `ecb721f5` |
| Common dbt job patterns (Preview) | `ecb721f5` |
| BACPAC and DACPAC guidance | `ecb721f5` |
| Business Event consumer guidance | `ecb721f5` |
| Business Event scenario patterns | `ecb721f5` |
| Private Eventstream source guidance | `ecb721f5` |
| Microsoft Fabric CI/CD resources | `ebc6f751` |
| Use AI functions with Power BI | `ebc6f751` |
| Fabric Influencers Spotlight August 2026 | `91e49056` |
| Modern Fabric Pipeline canvas (Preview) | `91e49056` |
| Manage Fabric connections at scale | `91e49056` |
| Private Snowflake connectivity for pipelines and Copy Jobs | `91e49056` |
| Fabric Data Warehouse medallion architecture best practices | `91e49056` |
| Updated workspace monitoring experience (Preview) | `80a24c9b` |
| Vector indexes and vector search in SQL database (Generally Available) | `80a24c9b` |
| Migration Assistant for Teradata (Preview) | `80a24c9b` |
| New T-SQL syntax for Fabric Data Warehouse and the SQL analytics endpoint | `80a24c9b` |
| Ontology new experience (preview) | `80a24c9b` |
| Graph in Microsoft Fabric: GQL enhancements | `80a24c9b` |
| Graph in Microsoft Fabric: Extended graph traversal | `80a24c9b` |
| Graph in Microsoft Fabric: Incremental data updates | `80a24c9b` |

This is the known answer for D-1's re-run.

**Precedents already in the registry.**

- The `skills-for-fabric` entry `curl`s its base file to the scratchpad
  and runs `grep -c` against it (its step 3, "as the 2026-09-12 run
  did").
- The `claude-code` run of 2026-08-29 diffed two refs on disk.
- Against that, the `powerbi` entry says "Use `WebFetch`, not a shell
  `curl`: § 3 keeps this skill read-only and Bash is deliberately
  outside its tool scope." The registry contradicts itself on Bash.

**Related deferred brief.** `docs/handoffs/execute/drift-fetch-subagent.md`
is deferred until a single-source run compacts mid-Phase-1. This run did
not compact, so it does not reopen that brief; it is listed only because
it is the queue's other fetch-strategy question.

## Decisions to put to the user

1. **On-disk exemption scope.** Extend § 4a's on-disk two-ref exemption
   from `changelog` to `table` sources, or to any source whose two refs
   exceed the budget?
2. **When to walk the in-window versions.** Options:
   - always, for a `table` source with more than N commits;
   - only when the base-to-head diff deletes a large block (here −368
     lines in one commit);
   - always. The cost here was 13 extra raw fetches.
3. **Bash in a read-only skill.** Settle the registry's contradiction:
   either sanction scratchpad-only `curl` and on-disk diffing in
   `SKILL.md` § 3, or route bytes through `github-mcp` only.
4. **§ 4b corrections.** Replace "~50 KB" with measured, dated sizes,
   and re-derive the WebFetch price for `fabric` now that only two table
   sections remain. If even those come back summarized, say the source
   is `github-mcp`-only in practice, as `claude-code` and
   `skills-for-fabric` already are.

## Verification

1. Re-run `/drift-audit --sources fabric --since 2026-09-01` under the
   amended procedure. It must recover all 22 transient rows above and
   keep the full files out of context.
2. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`.
   If the `description` changed, also run
   `uv run --with pyyaml scripts/skill-status.py --stale`.
3. `pre-commit run --all-files`

## Sequencing note

Keep this apart from brief 17. That brief repairs registry facts and is
verified by grep. This one changes the pipeline and is verified by a
re-run. Different verification, different risk.

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01. The run deviated from § 4a on purpose: it diffed on disk
and walked every in-window version. It said so in its audit-window
block. The deviation is what found the 22 rows, so the evidence for the
change is the run's own output.
