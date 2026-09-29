---
status: open
priority: 2
needs: [user]
blocked-by: []
written: 2026-09-29
---

# Handoff: every brief starts in a worktree, not only a parallel one

- **Written**: 2026-09-29, from a session that read that day's parallel
  sessions' transcripts at the user's request. The two landing fixes it
  found are in `docs/handoffs/CLAUDE.md`, measured in
  [README.md](README.md) § "A brief's worktree lands without a push";
  this brief holds the rest.
- **Kind**: a decision, then edits. `needs: user` for § "The question";
  the two items under § "Either way" do not wait on it.

## The question

Root `CLAUDE.md` § "Branching and concurrent sessions" commits straight
to `main` (settled 2026-09-02) and sends a brief to a worktree only when
it is worked "in parallel" (2026-09-27). Two answers are needed:

1. **Does every brief start in a worktree named after it?** Entered with
   `EnterWorktree`, or launched with `claude --worktree <brief>`, once
   its evidence is re-measured from the main checkout. The main checkout
   keeps non-brief work, landing and deploying.
2. **Where does a brief go whose check needs the deployed payload**
   (§ "What stays in the main checkout")? It stays in the main checkout,
   which keeps unverified work off `main`; or it edits in a worktree,
   lands, and is verified on `main`, fixing forward there, which keeps
   the isolation.

A no to the first keeps "in parallel", and the commit says why.
Branching in place stays out either way: a `git switch` moves every
session's tree (root, 2026-09-02).

## Why: 2026-09-29

Among the sessions in this tree that day, these four left the evidence.
Times are UTC; local time was four hours earlier, the same date.

| Transcript | Work | Where |
| --- | --- | --- |
| `1c8ba406` | brief `fabric-alter-table-and-serialization-gaps`, then follow-ups | a worktree, because the user said a peer was live; the main checkout after landing |
| `17acda19` | brief `copilot-port-selection` | the main checkout |
| `22196fc0` | `/test-skill test-skill`, then `/learn` | the main checkout |
| `b8459a74` | a test run's findings, then `/learn` | the main checkout |

- **The trigger did not fire with its condition met.** `17acda19` ran
  `ListAgents` first, at 17:58, saw two busy peers in this tree, and
  worked its brief in the main checkout.
- **Only a worktree claims a brief.** `handoff-status.py` prints "in
  flight" when a worktree's directory name matches a brief's stem
  (`detail()`), so `copilot-port-selection` read `ready` to every session
  while it was worked.
- **The worktree brief needed the user once**, to be told a peer was
  live. `1c8ba406` landed seven commits by rebase and fast-forward in
  under two minutes, with one `SendMessage` to its peer.
- **The guard's cost was re-measuring.** It refused three read-only
  commands against client repos: one ran `git -C` there, one named
  `.git` in a `find` filter, and one it called too complex to verify.
  Glob, Grep and a plain `find` ran. A fourth refusal, during `/commit`,
  was a git command beside a shell variable, which the session split.
- **Asked to keep out of a test run, `17acda19` made its own worktree**:
  `git worktree add` in its scratchpad, commits there, and a
  fast-forward from the main checkout.

**The user sent six coordination prompts that day**, and three came from
a brief worked outside a worktree:

| Time | Transcript | Prompt, abridged | Brief outside a worktree |
| --- | --- | --- | --- |
| 15:17 | `b8459a74` | "Peer is committing right now. Go ahead and commit when the peer is finished." | no |
| 16:04 | `22196fc0` | "The other test-skill session is staging and committing their hunk, please do so afterwards" | no |
| 16:13 | `1c8ba406` | "There is another session working on the tree as a heads up, so branch or tree accordingly" | yes: take a worktree |
| 18:04 | `1c8ba406` | "Yes commit and watch for the peer's work." | no: follow-ups after landing |
| 18:18 | `22196fc0` | "Other session is committing right now" | yes: `17acda19`'s commits |
| 18:28 | `17acda19` | "There is a new session going and doing a test run of test-skill" | yes |

The count is user messages in that day's transcripts under
`~/.claude/projects/c--Repos-Personal-agent-config/` matching
`session|coordinat|peer|interfer|wiped|collision`, less pasted prompts
and those about starting a new session. Re-run it after the next day of
parallel work.

## What stays in the main checkout

Work whose check needs the deployed payload, which a worktree cannot
reach:

- **A skill in a deployed group**, listed by
  `ls skills/workflow skills/social skills/meta`. `~/.claude/skills`
  junctions the main checkout's copy, and user scope outranks project
  scope, so a worktree's edit loads nowhere, and a probe from the
  worktree tests the main checkout's version with nothing said.
- **Anything under `claude/` checked only once deployed, and
  `/test-skill` step 7**: `link-claude.ps1` refuses a linked worktree
  (`ac3d22e`).
- **`test-activation.ps1` without `-StaticOnly`**, which deploys to its
  probe directory through `link-claude.ps1` and is refused the same way.
  `-StaticOnly` exits before the deploy and runs anywhere.
- **Evidence a brief re-measures with `git` in another repo**: measure it
  before entering, rather than route around the guard.

Skills in `.claude/skills/` need no carve-out: a worktree loads its own
copy (root ledger, probe 6, 2026-09-24).

## Edits, if yes

1. **Root `CLAUDE.md`** § "Branching and concurrent sessions": "or to
   work a brief in parallel (below)" and "**Work a brief in parallel in
   a worktree named after it**" become every brief, naming
   `EnterWorktree` beside `claude --worktree`, re-measuring first, and
   the carve-outs by pointer. Root is at 199 of 200 lines, so the edit
   is net zero or moves something out; `uv run scripts/lint-claude-md.py`
   checks.
2. **`claude/CLAUDE.md` § "Branch naming"**, read with it as root
   requires. It needed no change on 2026-09-27 (`a7754da`), since it
   defers to a repo's own convention; check that still holds.
3. **`docs/evidence/root-claude-md.md`** § "Branching and concurrent
   sessions": a dated entry carrying § "Why" in the ledger's form.
4. **`docs/handoffs/CLAUDE.md`**, 58 of its 60 lines: its in-flight
   bullet points at root for when to take a worktree, which stays true.
   Add only what a session must know before starting one, if it fits.
5. **[README.md](README.md)**: the reasoning.
6. **`/test-skill`** stops when it runs in a linked worktree on a
   deployed-group skill, since its probes would load the main
   checkout's copy. `link-claude.ps1`'s refusal at step 7 is loud
   already.

## Either way

These hold whether a brief takes a worktree always or only in parallel,
and may land first.

- **`link-claude.ps1` admits a worktree for a probe target.** Its
  refusal protects `~/.claude` and any real `-ClaudeDir`, where junctions
  into a worktree go live and dangle once it is removed.
  `test-activation.ps1` creates its probe root, marks it
  `.activation-probe` and deletes it, so admitting a worktree run whose
  `-ClaudeDir` sits under a marked probe root lets a platform-skill brief
  run its real-path activation test in its own worktree. Not any
  `-ClaudeDir`: a client repo's `.claude` takes one too. Prove it in a
  scratch clone as `ac3d22e` did: refused for the default target and an
  unmarked `-ClaudeDir`, admitted under a marked probe root, its
  junctions resolving into the worktree.
- **`handoff-status.py` tells a held claim from a parked one.** Claude
  Code locks the worktree a session holds, and
  `git worktree list --porcelain` prints a `locked` line for it, so "in
  flight" could say whether a session still holds the worktree or left
  it unlanded. A crashed session's lock stays, which `/prune-branches`
  unlocks once its pid is dead, so the pid in the lock's reason is the
  better witness. A planted case goes in
  `tests/scripts/handoff-status/test-findings.sh`.

## Left open

- **Non-brief work in parallel.** Half the prompts above passed between
  sessions doing `/test-skill`, `/learn` or follow-ups in the main
  checkout, with no brief to name a worktree after. `17acda19`'s
  scratchpad worktree is one route, improvised: no guard, no claim, and
  whether a Read in it loads this repo's `paths:` rules is untested.
  Whether `/commit` § "When another session shares this tree" offers it
  is a separate question.
- **Audit briefs** run as one numbered pass per directory, and
  `handoff-status.py` matches worktrees against `execute/` stems only,
  so this proposal does not reach `/drift-update`.
- Agent teams stay ruled out (root ledger, 2026-09-24).

## Verification

- `uv run scripts/lint-claude-md.py`: root at or under 200 lines,
  `docs/handoffs/CLAUDE.md` at or under 60.
- `pre-commit run --all-files` passes, `lint-briefs` among it.
- `uv run scripts/handoff-status.py . --no-inbox` marks a brief in flight
  while its worktree exists, and, after the second item under § "Either
  way", held or parked.
- The count under § "Why", re-run after the next day of parallel work.
