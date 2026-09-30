---
status: deferred
priority: 3
needs: []
blocked-by: []
reopen-when: the next day of parallel sessions here has passed, for the root ledger's coordination count
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
- **Kind**: what the rule does not reach, deferred until a day of
  parallel work shows whether it matters.

## Left open

- **Non-brief work in parallel.** Half the six prompts in the root
  ledger's 2026-09-29 entry passed between sessions doing `/test-skill`,
  `/learn` or follow-ups in the main checkout, with no brief to name a
  worktree after. `17acda19`'s scratchpad worktree is one route,
  improvised: no guard, no claim, and whether a Read in it loads this
  repo's `paths:` rules is untested. Whether `/commit` § "When another
  session shares this tree" offers it is a separate question.
- **Audit briefs** run as one numbered pass per directory, and
  `handoff-status.py` matches worktrees against `execute/` stems only,
  so the rule does not reach `/drift-update`.
- **A stamp taken in a worktree can name a commit `main` never gets.**
  `skill-status.py --stamp` records `HEAD`'s short SHA, and the landing's
  rebase rewrites that commit whenever `main` has moved, though
  `docs/handoffs/CLAUDE.md` says to cite a SHA only after the rebase
  (`b4e097b`'s message). `--stale` never reads the field, so only the
  provenance is wrong. Stamping after the rebase, or on `main` with
  `--at` once landed, keeps it true; which one `/test-skill` asks for is
  the user's call.
- Agent teams stay ruled out (root ledger, 2026-09-24).

## On reopening

Re-run the root ledger's count of coordination prompts, by the method
its 2026-09-29 entry under § "Branching and concurrent sessions" gives,
over the next day on which sessions here ran in parallel. If prompts
from non-brief work recur, put the first bullet above to the user as a
decision, `needs: [user]`; if none do, drop it. The brief goes once
nothing above is open.
