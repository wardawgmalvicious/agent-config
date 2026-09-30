---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-09-29
---

# Handoff: what a worktree for every brief still needs

- **Written**: 2026-09-29, from a session that read that day's parallel
  sessions' transcripts at the user's request. The two landing fixes it
  found are in `docs/handoffs/CLAUDE.md`, measured in
  [README.md](README.md) § "A brief's worktree lands without a push".
- **Decided** the same day: every brief takes a worktree named after it,
  and a brief whose check needs the deployed payload lands, then runs
  the check on `main`. Root `CLAUDE.md` § "Branching and concurrent
  sessions" holds the rule, its ledger the evidence, and
  [README.md](README.md) § "Every brief takes a worktree" the reasoning.
- **Kind**: two edits the decision did not wait on; either may land
  first.

## `link-claude.ps1` admits a worktree for a probe target

Its refusal protects `~/.claude` and any real `-ClaudeDir`, where
junctions into a worktree go live and dangle once it is removed.
`test-activation.ps1` creates its probe root, marks it
`.activation-probe` and deletes it, so admitting a worktree run whose
`-ClaudeDir` sits under a marked probe root lets a platform-skill brief
run its real-path activation test in its own worktree, where today it
waits until after the merge. Not any `-ClaudeDir`: a client repo's
`.claude` takes one too. Prove it in a scratch clone as `ac3d22e` did:
refused for the default target and an unmarked `-ClaudeDir`, admitted
under a marked probe root, its junctions resolving into the worktree.
Then drop `test-activation.ps1` from the list in [README.md](README.md)
§ "Every brief takes a worktree", and qualify root's "git and
`link-claude.ps1` both refuse a worktree" within its 200-line cap.

## `handoff-status.py` tells a held claim from a parked one

Claude Code locks the worktree a session holds, and
`git worktree list --porcelain` prints a `locked` line for it, so "in
flight" could say whether a session still holds the worktree or left it
unlanded. A crashed session's lock stays, which `/prune-branches`
unlocks once its pid is dead, so the pid in the lock's reason is the
better witness. A third state is neither: a brief whose check needs the
deployed payload keeps its worktree after the merge, unlocked once
`ExitWorktree` `keep` has run, until the check passes on `main`. Its
branch is then an ancestor of `main`, which tells it from a parked one.
A planted case of each goes in
`tests/scripts/handoff-status/test-findings.sh`.

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
- Agent teams stay ruled out (root ledger, 2026-09-24).

## Verification

- `pre-commit run --all-files` passes, `lint-briefs` and
  `lint-claude-md` among it.
- The first item: the scratch-clone proof above, then
  `./scripts/test-activation.ps1 -Set pbip` run from a worktree.
- The second: the planted cases pass, and
  `uv run scripts/handoff-status.py . --no-inbox` says held, parked or
  merged for a brief whose worktree exists.
- The root ledger's count of coordination prompts, re-run after the next
  day of parallel work.
