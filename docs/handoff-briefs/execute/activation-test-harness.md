# Handoff: script the conditional-activation test

- **Written**: 2026-09-01, from the wave 4 A1 verification, at the user's
  request to make that ad-hoc process repeatable.
- **Kind**: tooling. One script, plus a README edit. No skill or subagent
  — see "Shape" for why.
- **Status**: open. **Blocked on
  [activation-cleanroom-null.md](activation-cleanroom-null.md)** for the
  question of *where* the harness may run; the rest can be designed now.
- **Run in**: a fresh session.
- **Queue**: [README.md](README.md) has the order.

## The problem

`tests/skills/{pbip,fabric}-triggers/` assert which conditional skills
load on which files. The **static** check (a wcmatch pass over the
frontmatter globs) is cheap, scripted, and already documented — it tests
the globs. It does not test that Claude Code *acts* on them.

The harness half was run by hand for the first time on 2026-09-01 and
took most of a session, because the obvious version of it is silently
broken on this machine in two separate ways:

1. **The platform skills are not deployed here.** `-SkillGroups workflow`
   prunes `fabric` and `powerbi` out of `~/.claude/skills`, so every
   fixture reports "nothing loaded" — **indistinguishable from a broken
   glob**. This is the trap; it has no error path.
2. **The documented observation method could not work.** The fabric
   README told you to grep a `--debug-file` log for lines that are all
   emitted before any Read. Corrected in `c4d2de5`: the assertion lives
   in the session transcript, as a `skill_listing` attachment with
   `isInitial: false`.

The manual sequence that does work, and that this brief exists to
automate:

```powershell
# setup - project scope, gitignored, leaves the user-scope prune alone
./scripts/link-claude.ps1 -ClaudeDir <target>/.claude -SkillsOnly -SkillGroups powerbi
# probe - one cold session
claude -p "Read <fixture> and reply ok" --model "opus[1m]" --output-format json
# assert - grep the transcript, NOT the debug log and NOT the model
#   attachment.type == 'skill_listing' and attachment.isInitial == false
# teardown - remove the junctions
```

## Shape — recommendation

**One PowerShell script, `scripts/test-activation.ps1`, with teardown in a
`finally` block.** Not a worktree, not a subagent, not a skill:

- **Not a worktree or branch.** The deploy target is `.claude/skills`,
  which is *already gitignored* — the working tree is never touched, so
  there is nothing to isolate. A worktree would add path indirection for
  no benefit and make the fixture paths harder to reason about, which is
  the one thing the blocked sibling brief says may matter.
- **Not a subagent.** Activation is decided at session start from the
  skills root. A subagent cannot give you a cold session with a *different*
  skills root, so it cannot run this test. (A subagent transcript is its
  own file under `subagents/agent-<id>.jsonl`, which is worth knowing but
  does not help here.)
- **Not a skill.** The mechanics are deterministic and want to be run by
  CI or by hand, not chosen by a model. The two trigger READMEs already
  hold the "how to interpret" half.
- **Teardown must be `finally`.** An interrupted run that leaves 12
  junctions in `.claude/skills` changes what every later session in this
  repo sees, silently. Same failure class as the 2026-08-31 bare
  `link-claude.ps1` run that undid the prune.

## The open design question: cost

Naively, one cold `claude -p` per fixture file. There are ~50 fixtures
across both sets, so a full run is ~50 sessions — expensive enough that
nobody will run it, which makes it worthless.

The cheaper design turns on a fact **not yet established**: activation
appears to be a *delta* (`isInitial: false`, and the sibling attachment
types `deferred_tools_delta` / `agent_listing_delta` use the same
pattern). If so, one session can read many fixtures and emit one
attachment per *newly matched* skill — but then a skill already activated
by an earlier file will not re-appear, so per-file assertions are not
independent and read order matters.

**Establish this first**, in one session: read two fixtures that share a
skill, and check whether the second read emits an attachment. Then choose:

- **Delta confirmed** — one session per fixture *set*, reading files in a
  fixed order, asserting the cumulative sequence. ~2 sessions per full
  run. Needs `expected_activations.md` to gain an order-aware form.
- **Delta not confirmed** (re-emits per file) — one session can still
  cover a whole set, asserting per file directly. Even better.
- **Neither** — fall back to one session per *item type* rather than per
  file, ~15 sessions, run on demand rather than per commit.

This is also the question left open at the end of wave 4: whether an
activation fires once per session or once per matching file.

## Scope

- `scripts/test-activation.ps1` — setup, probe, parse, diff, teardown.
- Parse `expected_activations.md` directly rather than duplicating the
  assertions; those tables are the contract and must not fork.
- Report a diff of expected-vs-observed skill *lists*. Ignore the token
  columns — they are a ceiling, not a measurement (see `c4d2de5`,
  `b08e93b`).
- Refuse to run if `~/.claude/skills` is the deploy target. This script
  must never touch user scope.
- Update both trigger READMEs to point at the script as the real-path
  test, keeping the manual method as the explanation of what it does.

## Explicitly out of scope

Wiring it into `pre-commit` or CI. It spends model tokens and needs a
`claude` binary and credentials; it is an on-demand check, like the
fixture procedures in `tests/`. Revisit only once a full run is cheap
enough to be boring.

## Done when

A single command runs the real-path test for a named fixture set, diffs
against `expected_activations.md`, restores the machine to its prior state
even on failure, and a fresh session can be handed the README and get the
same result without rediscovering either trap above.
