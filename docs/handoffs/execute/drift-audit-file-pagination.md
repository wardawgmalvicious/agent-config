---
status: open
priority: 3
needs: [user]
blocked-by: []
written: 2026-10-07
---

# Handoff: decide whether drift-audit reads one file's patch by pagination everywhere

- **Written**: 2026-10-07, by a `/triage` sweep, from one audit
  follow-up:
  2026-09-10 skills-for-fabric 06, in a run retired 2026-10-08
  (`git show 7dd627e:docs/audits/2026-09-10/skills-for-fabric/completed/06-repair-skills-for-fabric-registry-entry.md`),
  whose D-1 knock-on was left as a separate decision. Re-measured at
  `4b6e108`: still undecided, with a second source now behind it.
- **Kind**: a decision of the user's, then a sentence or two in
  `.claude/skills/drift-audit/SKILL.md` § 4a.

## The question

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

## Evidence since the follow-up

- The 2026-09-12 `skills-for-fabric` run used the paginated read eleven
  times without a failure (the follow-up's log).
- The 2026-09-07 `powerbi` rerun met the trap it defeats: `369371ac`, a
  squashed monthly release merge of 624 additions and 298 deletions,
  under the five-commit line, sent it to step 5's two-ref diff instead
  (`git show 7dd627e:docs/audits/2026-09-07/powerbi/00b-audit-report-rerun.md`).
  `references/sources/powerbi.md` records the same trap.

## If yes

Step 5 gains the paginated read as its first move on an oversized
squashed commit, before the two-ref diff; the source entries keep only
what is theirs. The body edit owes `drift-audit` a retest
(`skill-status.py --stale`). `drift-audit-owed-rechecks.md` edits § 2
of the same file: whichever lands second re-reads it.

## Re-measure before acting

```bash
grep -n 'page: <position>' .claude/skills/drift-audit/SKILL.md .claude/skills/drift-audit/references/sources/*.md   # only skills-for-fabric.md on 2026-10-07
```
