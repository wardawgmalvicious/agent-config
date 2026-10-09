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

## Evidence from the vscode-agent run, 2026-10-06

The `vscode-agent` run the same day hit the same budget on a `prose`
source with a directory `path`, and found two faults in how § 4a and
§ 7 enumerate in-window commits. Its report is
`docs/audits/2026-10-06/vscode-agent/00-audit-report.md`.

**E-1. A directory source over budget, and the method that kept it out
of context.** It bears on decision 1: a `prose` directory source
exceeds the budget too. 19 listed in-window commits is more than 5, so
§ 4a step 3 sends the run to `get_file_contents` at both refs. All four
registered files changed blob SHA:

| File | Bytes at base `28f76f5f` | Bytes at head `c642b585` |
| --- | --- | --- |
| `custom-instructions.md` | 25,395 | 23,527 |
| `agent-skills.md` | 19,598 | 21,731 |
| `custom-agents.md` | 22,879 | 23,652 |
| `hooks.md` | 24,962 | 17,571 |

That is 179,315 bytes at both refs, against the 150 KB per-source
budget. The run cloned instead, into the session scratchpad, and
diffed on disk:

```bash
git clone --quiet --filter=blob:none --no-checkout --single-branch --branch main \
  --shallow-since=2026-08-26 https://github.com/microsoft/vscode-docs.git <scratchpad>/repo
git -C <scratchpad>/repo diff 28f76f5f c642b585 -- docs/agent-customization/<file>
git -C <scratchpad>/repo log --first-parent --numstat 28f76f5f..c642b585 -- docs/agent-customization/
```

Blobs arrive lazily, only for the diffs asked for, so no file entered
context. `--shallow-since` has to fall before the diff base's date.

**E-2. A `since:` listing misses a commit merged in the window but
dated before it.** `list_commits` with `path:
docs/agent-customization/` and `since: 2026-09-01T00:00:00Z` returned
19 SHAs. `git log 28f76f5f..c642b585 -- docs/agent-customization/`
returned 20. The extra one, `0ff80a1` ("Update documentation for agent
customization and source control sections", 2026-08-28,
`language-models.md` +3/-3), reached `main` in the window through
`99bbccc` (the PR #10243 merge, 2026-09-03). The two-ref diff includes
its change. The commit enumeration does not, and neither would the
per-commit-patch route § 4a takes at 5 commits or fewer.

**E-3. The path filter lists branch commits, not what landed.** Of the
19 listed SHAs, 7 are squash merges on `main`'s first-parent line, 9
are branch commits, and 3 are "Merge branch 'main' into …" commits
(`70664392`, `4316a2c4`, `78460cbe`). The 10 PR merges that landed the
branch commits are not listed: `1606fea`, `c9d4cd2`, `ff30176`,
`b5fb0d9`, `e951b76`, `b30d3f3`, `b2a3aa4`, `99bbccc`, `7177031` and
`0959679`. A per-commit patch of a "Merge branch 'main' into …" commit
diffs against the branch, so it shows main's changes arriving rather
than the branch's own. `git log --first-parent <base>..<head> --
<path>` lists the 17 commits as they reached `main`.

The registry already records both faults for one source. Its
`skills-for-fabric` entry, § "Fetch — one `CHANGELOG.md` patch per
commit, isolated by file pagination", notes that "a path-filtered
`list_commits` shows the **branch commit, not the merge**" and that "a
date floor can miss a release whose branch commit predates the floor
but whose merge follows it"
(`.claude/skills/drift-audit/references/sources/skills-for-fabric.md`).
E-2 and E-3 show the same faults on a second repo.

**E-4. Another Bash precedent**, bearing on decision 3. The clone,
diffs and listings of E-1 ran in Bash, writing only to the session
scratchpad.

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

The vscode-agent run's E-2 and E-3, above, bear on how § 4a and § 7
enumerate in-window commits, which no decision here asks yet.

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

## Execution log

- **Executed**: 2026-10-06 — escalated (decisions 1–4 answered by the
  user)
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: none
- **Decision**: put to the user with the brief's problem and evidence,
  plus the vscode-agent pass's E-1 to E-4. That pass added them in
  `36d7e77`, which had not reached this worktree's copy when the
  decisions were put, and it asked for them to go to the user with this
  brief. Each answer was the recommended option:
  1. Extend the on-disk two-ref exemption to **any source whose two
     refs exceed the budget**, not only `table` sources.
  2. **Always** walk every in-window version of a `table` source.
  3. **Sanction scratchpad-only Bash** (`curl` or `git clone`) and
     on-disk diffing in § 3; the `powerbi` entry's "WebFetch, not curl"
     line changes to match.
  4. Make the § 4b corrections as described.
- **Verification**: none ran, since a decision brief edits nothing in
  this run. Its steps belong to the follow-up: the re-run must recover
  all 22 transient rows in the Evidence table and keep the full files
  out of context.
- **Deferred**: the `SKILL.md` edit the answers imply, and its
  verification. E-2 and E-3, on commit enumeration, were shown to the
  user, but no decision asks about them: a `since:` listing misses a
  commit merged in the window but dated before it, and a path-filtered
  listing returns branch commits, not what landed. The follow-up should
  put them to the user before it edits § 4a and § 7.
- **Deviations**: none.
- **Needs**: a fresh session — apply decisions 1–4 to
  `.claude/skills/drift-audit/SKILL.md` (§ 3, § 4a step 3, § 4b, § 4c)
  and the `powerbi` registry entry, asking about E-2 and E-3 first, then
  re-run `/drift-audit --sources fabric --since 2026-09-01` to recover
  the 22 transient rows.
- **Closed**: 2026-10-08 — carried by /triage to
  docs/handoffs/execute/drift-audit-on-disk-diffing.md: decisions 1 to
  4's edits to `drift-audit` and the `powerbi` entry, E-2 and E-3 for
  the user first, and the re-run that recovers the 22 transient rows.
  Decision 4 was half applied by then, in `346b0c1` and `b7015b0`.
