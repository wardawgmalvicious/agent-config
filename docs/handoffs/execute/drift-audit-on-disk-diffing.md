---
status: open
priority: 2
needs: [user]
blocked-by: []
written: 2026-10-08
---

# Handoff: drift-audit diffs an over-budget source on disk, walks every version of a table source, and may page one file's patch

- **Written**: 2026-10-08, by a `/triage` sweep, from one audit
  follow-up: the 2026-10-06 `fabric` audit's
  [brief 18](../../audits/2026-10-06/fabric/completed/18-decide-table-source-fetch-strategy.md),
  whose four decisions the user answered that day. Re-measured against
  the payload at `b0a8b24`: decisions 1 to 3 are not applied, and
  decision 4 is half applied.
- **Merged**: 2026-10-15, on the user's word, the other open brief on
  § 4a, `drift-audit-file-pagination.md` (written 2026-10-07), as
  § "The pagination question" below: one file, one retest. Merged on
  this branch, which had edited that brief, so the merge lands with it.
- **Kind**: an edit to the project-scope `drift-audit` skill and its
  registry entries, made on this brief's branch on 2026-10-14 after the
  user's answers that day; then the verification run, before the branch
  lands; and the pagination question, the user's.

## What is decided, and what is open

Brief 18's log records the answers, each the recommended option:

1. The on-disk two-ref exemption extends from `changelog` sources to
   any source whose two refs exceed the budget.
2. A `table` source's in-window versions are always walked.
3. Scratchpad-only Bash, a `curl` or a `git clone`, and on-disk diffing
   are sanctioned in § 3, and the `powerbi` entry's "WebFetch, not curl"
   line changes to match.
4. § 4b's sizes and its WebFetch price for `fabric` are re-derived.

On 2026-10-14 the user answered E-2 and E-3, in that brief's Evidence,
on how § 4a and § 7 enumerate in-window commits: by ancestry rather
than by date, and by landing, naming what a merge carries. They settled
two conditions too: Bash stays out of `allowed-tools`, so each call
goes through the session's mode, and a fresh-context Phase 1 run
verifies the change before it lands. This branch applied all of it that
day, and its commit says what each section became. Open: that run, and
the pagination question.

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

Landed on this branch, 2026-10-14: `.claude/skills/drift-audit/SKILL.md`
§ 3, § 4a, § 4b, § 4c, § 7 and its description, `allowed-tools`
unchanged; `references/sources.md`; and the `claude-code`, `fabric`,
`powerbi` and `skills-for-fabric` entries. Project scope, so nothing
deploys; the body edit owes `drift-audit` a `/test-skill` retest,
routing then behaviour, which `skill-status.py --stale` will name.

A yes to the pagination question edits § 4a step 5 of the same file,
and the one retest covers both. § 2's owed re-checks, landed
2026-10-14, read the ledger with `Grep`; on this branch they say
`handoff-status.py` is a repo script that § 3's Bash allowance does not
reach, which Bash kept out of `allowed-tools` leaves true.

**Land this before the next `fabric` audit.** A run that follows § 4a
as written puts both refs in context, and its base-to-head diff cannot
see a row added and deleted inside the window, which is how brief 18's
run would have missed 22 rows with no error.

## Verification

Brief 18's own: re-run `/drift-audit --sources fabric --since
2026-09-01` under the amended procedure. It must recover the 22
transient rows in that brief's Evidence table and keep the full files
out of context. By the user's answer of 2026-10-14 it is a
fresh-context Phase 1 run, made before the branch lands. It does not
exercise the pagination read, which serves only a run with no clone.

## Not checked

What that re-run costs; nothing since 2026-10-06 has measured it.

## Re-measure before acting

```bash
grep -n -i 'changelog. shape\|do not write it to disk\|11 named sections' .claude/skills/drift-audit/SKILL.md   # lines 64, 80, 109 on 2026-10-08; none on this branch, 2026-10-15
grep -n 'not a shell' .claude/skills/drift-audit/references/sources/powerbi.md                              # line 60 on 2026-10-08; none on this branch, 2026-10-15
ls -d docs/audits/*/fabric                                                                                  # 2026-10-06 alone on 2026-10-08
```

## The pagination question

- **Written**: 2026-10-07, by a `/triage` sweep, from one audit
  follow-up:
  2026-09-10 skills-for-fabric 06, in a run retired 2026-10-08
  (`git show 7dd627e:docs/audits/2026-09-10/skills-for-fabric/completed/06-repair-skills-for-fabric-registry-entry.md`),
  whose D-1 knock-on was left as a separate decision. Re-measured at
  `4b6e108`: still undecided, with a second source now behind it.
- **Kind**: a decision of the user's, then a sentence or two in
  `.claude/skills/drift-audit/SKILL.md` § 4a.

### The question

Whether § 4a takes up the read the `skills-for-fabric` entry uses to pull
one file's patch out of a squashed release: `get_commit` with
`detail: "stats"` for the file's position, then `detail: "full_patch"`,
`perPage: 1`, `page: <position>`, which returns that file's patch
alone (`references/sources/skills-for-fabric.md`, § "Fetch — one
`CHANGELOG.md` patch per commit", on 2026-10-07).

§ 4a, unchanged on 2026-10-07: step 3 reads `full_patch` per commit at
five commits or fewer, and step 5's escape hatch goes as far as
`detail: "stats"` "to see which files actually moved", then switches
to a two-ref file diff. It never names the paginated read.

### Evidence since the follow-up

- The 2026-09-12 `skills-for-fabric` run used the paginated read eleven
  times without a failure (the follow-up's log).
- The 2026-09-07 `powerbi` rerun met the trap it defeats: `369371ac`, a
  squashed monthly release merge of 624 additions and 298 deletions,
  under the five-commit line, sent it to step 5's two-ref diff instead
  (`git show 7dd627e:docs/audits/2026-09-07/powerbi/00b-audit-report-rerun.md`).
  `references/sources/powerbi.md` records the same trap.
- Since 2026-10-14 § 4a prefers a clone, where
  `git log --first-parent -p -- <path>` isolates one file's patch with
  no pagination. The question now covers only each step's *Without a
  clone*, the `github-mcp` route.

### If yes

Step 5 gains the paginated read as its first move on an oversized
squashed commit, before the two-ref diff; the source entries keep only
what is theirs. The body edit owes `drift-audit` a retest
(`skill-status.py --stale`).

### Re-measure the question

```bash
grep -n 'page: <position>' .claude/skills/drift-audit/SKILL.md .claude/skills/drift-audit/references/sources/*.md   # only skills-for-fabric.md on 2026-10-07, and on this branch, 2026-10-15
```
