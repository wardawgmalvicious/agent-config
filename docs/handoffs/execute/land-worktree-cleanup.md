---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-17
---

# Handoff: land should ask to remove the worktree it lands from, then remove it

- **Written**: 2026-10-17, from one inbox note of 2026-10-16 by a VS
  Code session in machine-config that landed a brief's branch from its
  own linked worktree. Re-measured against the payload at `7d0757e`,
  which still keeps both by default. The same note's second learning,
  `/learn` step 5's transcript slug inside a worktree, landed beside
  this brief.
- **Kind**: an edit across `land`'s body, its reference, and two places
  that share its gate. Nothing is drafted beyond the shape below.

## The friction

Every landing from a linked worktree ends with the user cleaning up by
hand. `land` step 9 keeps the worktree and the local branch, because
the landing session is the one inside the worktree, and hands over the
commands "for once the session has ended", or points at `/exit`'s
keep-or-remove offer (`references/linked-worktree.md` § "Step 9: the
worktree goes before the branch"). On 2026-10-16 the user, in VS Code,
reported no such offer there, and that it was not the first time (the
user's report; the missing `/exit` offer is not measured).

The skill already records that the session can do it: `ExitWorktree`
`keep` released the lock, "so a session that came back that way removed
its own worktree (2.1.282, 2026-09-29)". It holds back because the
tool's description says to call it only when the user asks, and the
skill never asks. From inside the worktree the commands cannot run: the
lock names this session's own pid, and the worktree guard refuses
`git -C` aimed at the main checkout.

## The shape

1. **Step 6**: from a linked worktree this session is in, name the
   worktree's removal with the branch deletion it already discloses, in
   the same `AskUserQuestion` as the go-ahead. That yes is the ask the
   tool requires.
2. **Step 9**, once the remote half has run from the worktree:
   `ListAgents` and step 1's placement scripts, then `ExitWorktree`
   `keep`, never `remove`, which after `git branch -m` left the renamed
   branch, saying nothing (the reference, 2.1.282).
3. **From the main checkout**: `git worktree list --porcelain` for a
   leftover `locked` line, then `git -C <worktree> status --short`,
   `git worktree remove <worktree>` and
   `git merge-base --is-ancestor <branch> <sha> && git branch -D <branch>`.
4. **A lock still naming this session's pid** after the `keep`, the
   refused-`EnterWorktree` case `docs/handoffs/execute/README.md`
   records, takes `git worktree unlock <worktree>` first, as
   `.claude/rules/handoff-briefs.md` says. A lock naming another live
   session, a dirty tree, or a no at step 6 keeps both, with the
   commands handed over as today.

Measured by the note's session, 2026-10-16, Claude Code 2.1.301,
entrypoint `claude-vscode`, the second measurement after 2026-09-29's
on 2.1.282 from a `claude --worktree` launch: before, the porcelain read
`locked claude session <name> (pid <its own pid>)`; a Bash `git -C` to
the main checkout was refused as redirecting a worktree-isolated
session; `ExitWorktree` `keep` returned the session to the main
checkout, still naming the branch by `EnterWorktree`'s generated name
though `git branch -m` had renamed it; after, no `locked` line, a clean
status, `git worktree remove` exit 0, and the guarded `git branch -D`
deleted the branch. Step 8's main-checkout catch-up,
`git merge --ff-only origin/main`, could run from there under the same
answer, but was not tried.

## Where it lands

- `skills/workflow/land/SKILL.md`: step 6's disclosure, and step 9's
  "**The branch is checked out in a linked worktree**" bullet, which then
  covers only a worktree another session holds or step 6 did not cover.
  A body edit: `land` needs a behaviour retest after.
- `skills/workflow/land/references/linked-worktree.md` § "Step 9": the
  session's own worktree becomes the default case and "**Otherwise keep
  both**" the fallback, its `/exit` pointer gaining the VS Code report;
  § "From the main checkout, when the user asks for it" points at step
  6.
- The same gate in `.claude/rules/handoff-briefs.md` (a brief's
  worktree, no push) and `.claude/skills/author-skill/SKILL.md`'s
  hand-off: decide whether each takes the same ask. The rule's edit
  owes its ledger entry in `docs/evidence/root-claude-md.md`.

## Not checked

- Nothing was re-run here; it needs a landing from a linked worktree.
- That VS Code shows no `/exit` offer.
- Whether `ExitWorktree` `keep` on a `claude --worktree` launch, not an
  `EnterWorktree` one, still releases the lock on 2.1.301.

## Scrubbing

The source note named only a personal repo, its branches, a pid and
paths under the personal root; the pid and the branch names are
generalized here.

## Re-measure before acting

```bash
grep -n "Otherwise keep both\|when the user asks" skills/workflow/land/references/linked-worktree.md   # 2026-10-17: lines 80 and 129
grep -n "ExitWorktree" .claude/rules/handoff-briefs.md .claude/skills/author-skill/SKILL.md   # 2026-10-17: one each
```
