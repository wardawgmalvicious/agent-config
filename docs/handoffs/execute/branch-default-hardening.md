# Handoff: harden "branch before committing" from advice into policy

- **Written**: 2026-09-14, out of a machine-config session that was
  asked where its branching habit came from. The finding is that its
  only source is harness text — durable enough, since it ships on every
  machine, but blanket, and matching neither repo measured.
- **Kind**: one payload edit to `claude/CLAUDE.md`, plus one open
  decision about whether to enforce rather than advise.
- **Status**: **prose edit landed 2026-09-14; deploy pending, one
  decision open.** Deploying is gated on
  [az-tenant-model-fallout.md](az-tenant-model-fallout.md) item 1 — see
  "Deploy dependency" below. The edit itself was not, and has shipped.
  See the execution log at the bottom.
- **Run in**: any session here.
- **Queue**: [README.md](README.md) has the execution order, and this
  brief now has a row there (added 2026-09-14 with the edit).

## The gap

[claude/CLAUDE.md:287](../../../claude/CLAUDE.md) § "Branch naming"
specifies **how to name** a branch — `<type>/<kebab-slug>`, the
conventional-commit vocabulary, no ticket numbers or sequence markers —
and says nothing about **when to make one**.

The only "when" in force is Claude Code's own built-in Bash-tool text:

> Commit or push only when the user asks. If on the default branch,
> branch first.

That ships with the harness, applies on every machine, and cannot be
edited. It is also **advisory prose, not a gate**: nothing blocks a
commit on `main`. So it holds when a session is reading carefully and
quietly lapses when a change feels small — which is exactly the observed
pattern.

## What was measured, 2026-09-14

- `machine-config` branches every change and lands through `land`.
  `main` there is **not** protected (`gh api .../branches/main/protection`
  → 404 "Branch not protected"), and its pre-commit hooks — gitleaks,
  PSScriptAnalyzer, Pester — fire on any commit regardless of branch. So
  nothing repo-local or server-side is producing that behaviour.
- **This repo is a deliberate opt-out, and it is working correctly.**
  [CLAUDE.md](../../CLAUDE.md) § "Branching and concurrent sessions"
  (line 505): *"Settled 2026-09-02: it stays the trigger, and branching
  stays the exception."* The reflog shows 20 consecutive direct-to-`main`
  commits, and the `docs/azure-tenant-config-dirs` branch from the
  2026-09-14 session was folded in by fast-forward and deleted.
- `fabric-tools` is the genuine gap: **no** branching guidance in its
  CLAUDE.md either way, and its last three commits went straight to
  `main`. It has its own brief at `docs/handoffs/branch-workflow.md`
  in that repo.

## The edit

Add a "when to branch" clause to `claude/CLAUDE.md` § "Branch naming",
or as a short sibling section immediately after it. Content to cover:

- Branch when the work is more than one commit, or when an intermediate
  state would be broken or deployed. One self-contained commit does not
  need one.
- The branch is what makes `land` usable — its step-1 preflight asserts
  `git branch --show-current` is not `main`, and its `--ff-only`
  integration is what preserves the logical commit split.
- Repo precedence. **This is load-bearing and must not be weakened.**
  The existing closing sentence — *"A repo's own committed convention
  wins over this one"* — is what keeps this repo's own opt-out correct.
  The new clause sits **under** that sentence, not above it. A clause
  that reads as universal would put the payload in contradiction with
  the repo that ships it.

Consider whether this repo's § "Branching and concurrent sessions"
should gain a one-line pointer saying it is a deliberate override of the
user-scope default. Not required; it would make the relationship legible
from the overriding side rather than only the overridden one.

## Deploy dependency

`claude/CLAUDE.md` is deployed as a **copy** and only `-Force` pushes it
(`scripts/link-claude.ps1`, `.PARAMETER Force`). That is the same flag
that overwrites `settings.json`, whose live copy carries four
`/config`-owned keys the repo copy lacks — the open item 1 of
[az-tenant-model-fallout.md](az-tenant-model-fallout.md). Land the edit
freely; **diff before deploying**, or settle that item first.

## Open decision: advise, or enforce

The edit above is still advice. The only mechanism that enforces is a
`PreToolUse` Bash hook refusing `git commit` when
`git branch --show-current` equals the default branch.

- **Precedent exists and is close**: `claude/hooks/identity-guard.sh` is
  already a `PreToolUse` Bash hook that inspects `git commit`, and is
  already written for spawn economy — this machine costs ~0.4 s per
  process spawn, so a naive hook is not free.
- **It sees only what Claude Code issues.** Copilot, VS Code's Source
  Control view and a plain terminal all pass straight through, exactly
  as documented for `identity-guard`.
- It needs an override path for the legitimate single-commit case, or it
  will be fought rather than followed — and this repo's own convention is
  that very case, so the hook must read repo policy or be opt-in per
  repo. **That is the hard part, and it is why this is a decision rather
  than a task.**

Recommendation: land the prose edit first and see whether it holds.
Reach for the hook only if a lapse recurs after the payload says it
plainly.

## Deliberately excluded

- **GitHub branch protection.** Server-side and it would catch every
  surface, but it forces PRs for all work and is each repo's own call —
  not this repo's payload, and not something a CLAUDE.md edit can set.
- **Editing this repo's opt-out.** It is dated, reasoned and measured.
  Nothing here is evidence against it.

## Execution log

**2026-09-14 — prose edit landed; title is a misnomer, corrected here.**

The brief's own framing was wrong in one way worth recording, because it
would have misled whoever landed it. "Hardening advice into policy"
describes the opposite of what the edit does. The harness rule — *"If on
the default branch, branch first"* — is **unconditional**. The clause
that landed adds a condition, so it is strictly *weaker*: it licenses
exactly the direct-to-`main` commits this brief opens by treating as a
lapse. That is still the right edit, because the blanket rule matched
neither repo measured, but its value is *"write down the policy actually
in force so it stops being reconstructed per session"*, not *"close a
gap"*. The landed text says so in the payload itself.

Applied:

- [claude/CLAUDE.md](../../../claude/CLAUDE.md) § "Branch naming" — two
  paragraphs after the repo-precedence sentence, which is left untouched
  and is now explicitly named as governing the new clause. The `/land`
  preflight claim was verified against
  [skills/workflow/land/SKILL.md:25](../../../skills/workflow/land/SKILL.md)
  (`git branch --show-current  # must not be main`) before being written
  down.
- [CLAUDE.md](../../CLAUDE.md) § "Branching and concurrent sessions" —
  the pointer the brief left optional, made non-optional. Without it the
  two files carried near-identical prose with no link between them,
  which is the "one fact, one home" failure mode. It marks this repo as
  a deliberate override and says to edit the two together.
- [README.md](README.md) — queue row added, count 8 → 9.

**Not** done, and why:

- **Not deployed.** `link-claude.ps1 -Force` is still gated on
  [az-tenant-model-fallout.md](az-tenant-model-fallout.md) item 1. The
  payload edit is inert in every session until that runs.
- **The hook decision stands open**, unchanged and with its lean intact.
