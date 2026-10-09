---
status: open
priority: 2
needs: [user]
blocked-by: []
written: 2026-10-08
---

# Handoff: drift-audit diffs an over-budget source on disk, and walks every version of a table source

- **Written**: 2026-10-08, by a `/triage` sweep, from one audit
  follow-up: the 2026-10-06 `fabric` audit's
  [brief 18](../../audits/2026-10-06/fabric/completed/18-decide-table-source-fetch-strategy.md),
  whose four decisions the user answered that day. Re-measured against
  the payload at `b0a8b24`: decisions 1 to 3 are not applied, and
  decision 4 is half applied.
- **Kind**: an edit to the project-scope `drift-audit` skill and one
  registry entry, after two questions for the user, then a re-run that
  is the verification. Nothing is drafted.

## What is decided, and what is open

Brief 18's log records the answers, each the recommended option:

1. The on-disk two-ref exemption extends from `changelog` sources to
   any source whose two refs exceed the budget.
2. A `table` source's in-window versions are always walked.
3. Scratchpad-only Bash, a `curl` or a `git clone`, and on-disk diffing
   are sanctioned in § 3, and the `powerbi` entry's "WebFetch, not curl"
   line changes to match.
4. § 4b's sizes and its WebFetch price for `fabric` are re-derived.

Open: E-2 and E-3 in that brief's Evidence, on how § 4a and § 7
enumerate in-window commits. Its log asks that both go to the user
before § 4a and § 7 are edited.

## Re-measured on 2026-10-08

- § 3 names no Bash use, and `allowed-tools` lists no `Bash`.
- § 4a step 3 still confines the on-disk two-ref path to the
  `changelog` shape (line 64), and § 4c still ends "Hold the diff in
  working memory; do not write it to disk." (line 109).
- `references/sources/powerbi.md` still says "Use `WebFetch`, not a
  shell `curl`" (lines 60–61).
- Decision 4 is half done. `346b0c1` and `b7015b0` gave § 4b measured
  sizes (147,882 characters for `fabric`'s `whats-new.md`) and dropped
  § 1's two stale ones. § 4b still prices `fabric` at "up to 14 (3 +
  its 11 named sections …)" (line 80), where its registry entry now
  names two. The same probes had a targeted prompt return a `fabric`
  section whole once in three, the case decision 4 says makes a source
  `github-mcp`-only in practice.

## Where it lands

`.claude/skills/drift-audit/SKILL.md` § 3, § 4a step 3, § 4b and § 4c,
and its `allowed-tools` if decision 3's Bash is to be pre-approved
rather than prompted; then `references/sources/powerbi.md`. Project
scope, so nothing deploys; the body edit owes `drift-audit` a
`/test-skill` retest, which `skill-status.py --stale` will name.

Two open briefs edit the same file:
[drift-audit-owed-rechecks.md](drift-audit-owed-rechecks.md), at § 2
and § 7, which plans around Bash being outside the skill's reach, and
[drift-audit-file-pagination.md](drift-audit-file-pagination.md), at
§ 4a step 5. Whichever lands second re-reads the file.

**Land this before the next `fabric` audit.** A run that follows § 4a
as written puts both refs in context, and its base-to-head diff cannot
see a row added and deleted inside the window, which is how brief 18's
run would have missed 22 rows with no error.

## Verification

Brief 18's own: re-run `/drift-audit --sources fabric --since
2026-09-01` under the amended procedure. It must recover the 22
transient rows in that brief's Evidence table and keep the full files
out of context.

## Not checked

What that re-run costs; nothing since 2026-10-06 has measured it.

## Re-measure before acting

```bash
grep -n -i 'changelog. shape\|do not write it to disk\|11 named sections' .claude/skills/drift-audit/SKILL.md   # lines 64, 80, 109 on 2026-10-08
grep -n 'not a shell' .claude/skills/drift-audit/references/sources/powerbi.md                              # line 60 on 2026-10-08
ls -d docs/audits/*/fabric                                                                                  # 2026-10-06 alone on 2026-10-08
```
