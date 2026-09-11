# Handoff: repair the skills-for-fabric registry entry

- **Audit run**: 2026-09-10
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-06` (diff base `912e06e0`) → head `65902bae`
  (2026-09-04)
- **Covers recommended actions**: 7
- **Kind**: changes how `/drift-audit` fetches, filters and verifies this
  source, plus one tool-scope change in the skill's frontmatter.
  Project-scope skill — live in sessions in this repo only. **D-5 is a
  decision, not an edit.**
- **Target**: `.claude/skills/drift-audit/references/sources.md` (the
  `skills-for-fabric` entry, lines 460–590),
  `.claude/skills/drift-audit/SKILL.md` line 6

## Context

The entry was registered on 2026-09-10 and first run the same day. The
run falsified the fetch assumption the entry is built on, and exposed
gaps in the vendored check, the counterpart table, clause 1 of the
filter and the skill's tool scope. What the run did to work around each
is the proposed fix. The defects are independent but land in one file
and are exercised by one re-run, which is why they are one brief.

## D-1 — the fetch strategy assumes a prepend-only file, and it is not

**Symptom.** `#### Fetch — HEAD once, read the sections above the floor`
(line 532) says:

> No prior-ref fetch is needed while the file stays prepend-only, which
> is **assumed, not verified** — the first run should confirm that the
> floor ref's version sections reappear unchanged in HEAD's

The first run found `CHANGELOG.md` edited in place after release:

| Commit | Date | Change | Sections touched |
| --- | --- | --- | --- |
| `9d5fe403` | 2026-08-06 | web edit, +6/-26 | 0.3.11, and **pre-floor 0.3.10, 0.3.6, 0.3.5** (hunks at old lines 34, 97, 177, 186) |
| `af9aff33` | 2026-08-06 | web edit, +0/-2 | 0.3.11 — removed two bullets |
| `a5e82199` | 2026-08-13 | +1/-2 | moved the `[0.3.12]` heading above its notes |
| `d231b957`, `e4dfaebd` | 2026-08-06 | +283/-283 each | line-ending flip and its revert; net zero |

A HEAD-only read cannot see a removal. The two bullets `af9aff33`
removed — the only public statement of upstream's catalog-total budget
check — now exist only in history. The pre-floor edits in `9d5fe403`
removed test and build references and changed no claim, so nothing was
lost this time. The strategy is still wrong: a retracted behavioural
claim would vanish the same way.

**Cause.** The entry assumed `claude-code`'s strictly prepend-only
changelog was typical.

**Fix.** Replace the strategy with what the run did:

1. `list_commits`, `path: CHANGELOG.md`, `since: <floor>`,
   `fields: ["sha"]`. Then `get_commit`, `detail: "stats"`,
   `perPage: 10` per SHA, which gives `CHANGELOG.md`'s position in the
   file list and its +/- counts.
2. `get_commit`, `detail: "full_patch"`, `perPage: 1`,
   `page: <position>` returns **only** that file's patch out of a
   squashed release. Verified 2026-09-10 on `22cafc90`: page 3 returned
   the `CHANGELOG.md` patch alone, out of a release touching ~1,960
   lines. Commits whose only file is `CHANGELOG.md` need no pagination.
3. Fetch the whole file once at the **base** ref — the last commit
   touching the path before the floor — for clause 1's "no earlier
   version section mentions" test. About 44 KB at v0.3.10, against
   58 KB at HEAD.
4. A pair of whole-file rewrites (+N/−N on every line) can be netted by
   comparing the file's blob SHA at the two refs from a root listing —
   `get_file_contents`, `path: "/"`, `fields: ["name","sha"]` — instead
   of reading either patch. That is how `d231b957` / `e4dfaebd` were
   cleared: blob `3fd6c501` at both `2b3530e8` and `e4dfaebd`.

Update the price line (lines 546–547, "Price: 1 call for HEAD, 2 for
the vendored path checks, and 1 per upstream `SKILL.md` read for
context") to match. The 2026-09-10 run spent about 10 stats calls, 7
isolated patches, 1 base fetch and 4 directory listings.

**Knock-on.** File pagination also defeats the trap that SKILL.md § 4a
and the `powerbi` entry describe — a per-commit patch dragging in a
whole squashed release. Generalizing it into § 4a is **not** in the
report's action; decide it separately.

## D-2 — path-filtered commit dates are branch dates, not merge dates

**Symptom.** Lines 534–535 say each release "lands as one squashed
commit, `Release vX from internal repo`". It lands as that commit on a
`release/vX` branch, then reaches `main` by a PR merge, sometimes days
later. A path-filtered `list_commits` shows the branch commit, not the
merge.

| Release | Branch commit | Merge to `main` |
| --- | --- | --- |
| v0.3.13 | `22cafc90`, 2026-08-20 08:34Z | `b8d541c` (PR #75), 2026-08-20 13:22Z |
| v0.3.15 | `65902bae`, 2026-09-04 13:13Z | `74f3262c` (PR #86), 2026-09-06 07:01Z |

**Cause.** Squash on the branch, merge commit on `main`, and history
simplification hiding the merge from a path filter.

**Fix.** Record it. A date floor can miss a release whose branch commit
predates the floor but whose merge follows it. Recommend next-run floors
of the last-seen branch-commit date plus one day, or the head SHA, as
the 2026-09-10 report's `## Next run` already does.

**Knock-on.** The vendoring notes cite `b8d541c`, the merge, which is
correct. The vendored check's `since:` should use that merge's time,
not the release heading's date.

## D-3 — the vendored check trusts an empty list

**Symptom.** Lines 526–530 check the vendored pair with `list_commits`,
`path: skills/<name>`, `since:` the vendored tag's date. An empty list
is also what a moved or deleted path returns — the same `[]` trap the
`powerbi` entry documents for forks.

**Fix.** Add a tree-SHA comparison. List `skills` at the vendored merge
commit and at HEAD with `fields: ["name","sha"]`; equal tree SHAs prove
the content is unchanged. One call per ref, and it covers the two
routed-to skills that clause 2 names as well. Measured 2026-09-10,
identical at `b8d541c` and `65902bae`:

| Upstream skill | Tree SHA |
| --- | --- |
| `powerbi-report-authoring` | `d160d140` |
| `powerbi-report-design` | `b9fe475b` |
| `powerbi-report-management` | `9b609076` |
| `powerbi-report-planning` | `4f847fca` |

## D-4 — the counterpart table misses two local skills

**Symptom.** The table at line 551 was matched by name against HEAD's
`skills/` listing, so it cannot see an upstream skill that no longer
exists there.

- `mlv-operations-cli` (added 0.3.5) is gone from HEAD's listing. Its
  work now routes to `spark-cli` — 0.3.14 lists "creating a materialized
  lake view" under Spark routing fixes. Local counterpart: `fabric-mlv`.
  The 0.3.11 MLV bullet reached the audit only by reading around the
  table; it became brief 03.
- `semantic-model-authoring`'s Prep-for-AI work has a local counterpart
  in `fabric-semantic-model-ai-instructions`, not only `fabric-tmdl` /
  `fabric-tmdl-api`; it became brief 05.

**Fix.** Add both rows, and say in the prose under the table that a
retired upstream name can still have a live local counterpart.

## D-5 — clause 1 is lexical, so consolidation renames pass it

**Symptom.** Clause 1 (line 470) keeps a bullet that "introduces a skill
name that no earlier version section mentions". This window's
consolidations passed on the new name alone: 13 names, of which only
`onelake-catalog-govern-cli` is new upstream. `activator-cli` (topic
since 0.3.1), `dataflows-cli` (since 0.3.0) and `eventschemaset-cli`
(since 0.3.10) reached bucket (b) as renames; eight more with registered
counterparts went to (d).

**Open question.** Keep the lexical test — every new name surfaces once,
including renames of topics no run had reported, which was true of this
first run — or exempt a rename whose predecessor appears in an earlier
section. **Put this to the user. Do not decide it while executing the
other items.**

## D-6 — "v0.3.12 changed both with no bullet" may be wrong

**Symptom.** Lines 519–523 read, in part:

> The changelog names those skills under `0.3.3` and `0.3.7` only —
> `v0.3.12` changed both with no bullet.

0.3.12 carries a catalog-wide bullet, verbatim:

> **The mandatory once-per-session "Update Check" blockquote** has been
> stripped from every `SKILL.md` (30 skills) and is no longer a
> structural requirement.

That plausibly explains v0.3.12's change to both vendored skills. It is
**unverified**: the audit did not diff the vendored `SKILL.md` across
v0.3.12.

**Fix.** Verify first — pull the vendored `SKILL.md` patch out of
`ab33f1da` with D-1's file pagination, or compare the file at
`2b3530e8` and `ab33f1da` for an Update Check blockquote. Then either
restate the claim as "no bullet *naming* them" or keep it. The practical
rule — check path history, not the changelog — stands either way, since
a catalog-wide bullet names no skill and clause 2 matches by name.

## D-7 — step 5 has now been run

**Symptom.** Line 586 opens **Unvalidated** and names the known-answer
window, floor 2026-08-20.

**Fix.** Record that the 2026-09-10 run passed all three assertions on
the 0.3.13–0.3.15 sections: both vendored checks empty and tree-SHA
proven, clause 1 surfacing `onelake-catalog-govern-cli`, and not
surfacing `databricks-migration` (mentioned in 0.3.0 and 0.3.9). Say
that it ran on a superset window (floor 2026-08-06) — the exact
known-answer floor was not run. The verification below runs it.

## D-8 — the drill needs a tool the skill does not list

**Symptom.** Line 488 reads `drill.strip: none — the bullets carry no
links`, and the entry requires a behavioural bullet to be confirmed on
Learn before it becomes a finding. With no link to follow, Phase 3 must
find the page — which needs `mcp__microsoft-learn-mcp__microsoft_docs_search`.
`SKILL.md` line 6's `allowed-tools` lists `microsoft_docs_fetch` but not
`microsoft_docs_search`; the 2026-09-10 run called it outside the
auto-approval scope.

**Fix.** Add `mcp__microsoft-learn-mcp__microsoft_docs_search` to
`allowed-tools`.

## Verification

1. Re-read `sources.md` immediately before editing — it is shared with
   other registry work — and confirm each quoted target is in `HEAD`:
   `git show HEAD:.claude/skills/drift-audit/references/sources.md | grep -n 'assumed, not verified'`.
2. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`
3. `uv run scripts/lint-skill-scopes.py`
4. In a fresh session, `/drift-audit 2026-08-20 --sources skills-for-fabric`
   — the known-answer floor. Confirm it follows D-1 (no whole-file HEAD
   read in context), runs D-3's tree-SHA check, and meets all three
   known-answer assertions.
5. `pre-commit run --all-files`

## Provenance

The first `/drift-audit` run against this source, on the day it was
registered (`8d91a3b`). Every defect surfaced during that run rather
than by review: D-1 to D-4 and D-8 as things the run had to work around,
D-5 and D-6 while applying the filter to the in-window sections. D-7 is
bookkeeping on the run's own result.
