---
status: open
priority: 1
needs: []
blocked-by: []
written: 2026-09-29
---

# Handoff: what a worktree for every brief leaves open

- **Written**: 2026-09-29, from a session that read that day's parallel
  sessions' transcripts at the user's request.
- **Decided** the same day: every brief takes a worktree named after it,
  and a brief whose check needs the deployed payload lands, then runs
  the check on `main`. Root `CLAUDE.md` § "Branching and concurrent
  sessions" holds the rule, its ledger the evidence, and
  [README.md](README.md) § "Every brief takes a worktree" the reasoning,
  with the two edits made the same day: `link-claude.ps1` admits a probe
  root from a worktree, and the view says held, parked or merged.
- **Decided** 2026-09-30, on the root ledger's recount that day: work
  with no brief takes no worktree route, and a `/drift-update` pass takes
  one named after its audit directory. `/drift-update` steps 2, 4.4 and 5
  carry the second, and [README.md](README.md) § "Audit briefs are a
  second queue" the reasoning. Agent teams stay ruled out (root ledger,
  2026-09-24).
- **Kind**: one behaviour retest, of an edit this brief's worktree
  landed.

## Left open

`/drift-update`'s body changed, so it owes a behaviour retest, and its
next pass is due on 2026-10-01, for the `fabric` and `powerbi` audits.
Run `/test-skill drift-update` in a fresh session from the main
checkout, not a worktree: a retest's one write is its stamp, which goes
on `main` (`/test-skill` step 10). Delete this brief in that stamp's
commit.

## Re-measure before acting

```bash
uv run --with pyyaml scripts/skill-status.py --stale   # drift-update reads retest-behaviour until the stamp
git log --oneline -1 -- .claude/skills/drift-update/SKILL.md   # the edit under test
```
