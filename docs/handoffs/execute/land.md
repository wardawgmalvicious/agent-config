# Skill handoff brief: land

Last verified: 2026-09-02

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

`skills/workflow/land/SKILL.md`. No `references/` split — see
[Body structure outline](#body-structure-outline). Deploys by junction
to `~/.claude/skills/land/`. The `workflow/` group directory is not
optional: the pre-commit hook matches `^skills/[^/]+/[^/]+/SKILL\.md$`
and Claude Code discovers skills exactly one level under the skills
root.

**This is a workflow skill, so it is one of the few this machine
actually deploys** — `-SkillGroups workflow` is the standing state. But
a **new** skill is not live until `scripts/link-claude.ps1` runs:
`~/.claude/skills` holds one junction *per skill*, so a directory that
did not exist at the last run has no junction and is invisible to every
session. Measured 2026-09-02 — `land` was absent from a listing of 8
junctions immediately after the file was written. (`author-skill`'s
preamble claims deployment "needs no step"; that holds for an *edit* to
an already-junctioned skill, not for a new one. Flagged for `/learn`.)

Once linked it behaves as root `CLAUDE.md`'s branching section
describes: live in every session on this machine the moment a save hits
disk, uncommitted and regardless of branch. Finish the frontmatter
before walking away.

## Scope

A **branch-landing procedure**, sibling to `commit` and starting exactly
where it stops. `commit`'s safety rails end at "Commit, report, stop"
and its Finish requires "an explicit note that nothing was pushed";
`land` takes it from there: push the branch, verify which GitHub account
is authenticated, open the PR through `github-mcp`, **stop for
confirmation**, then fast-forward `main` and verify the merge and CI.
Inline, model-invocable and `/`-invocable, **no `paths:` glob** —
landing is a discrete act you ask for, not something a file should
trigger. One skill rather than two: the steps share state (branch name,
commit range, PR number) and splitting would force re-derivation
halfway.

## Sources drilled

Drilled 2026-09-02:

- **Root [`CLAUDE.md`](../../../CLAUDE.md), "Branching and concurrent
  sessions"** — the authority this skill encodes rather than restates.
  Establishes: integration is **fast-forward only**, because rebase
  merges are disabled on this repo (`405 Rebase merges are not
  allowed`) and squash "would collapse the logical split `/commit` just
  made"; the exact command `git switch main && git merge --ff-only
  <branch> && git push origin main`; "GitHub marks the PR merged once
  its commits are reachable"; **open the PR with `github-mcp`, not
  `gh`**, because the two authenticate as different accounts;
  `allow_*_merge` and branch protection are **not readable
  unauthenticated** (`null` / `401`), so a rebase rejection surfaces at
  merge time and not before; `git switch` is unsafe while another
  session shares the tree, since one working tree has one HEAD; and a
  commit another session makes while you are on your branch **lands on
  your branch**.
- **[`skills/workflow/commit/SKILL.md`](../../../skills/workflow/commit/SKILL.md)**
  — the boundary. Its Safety rails ("Never push, amend, force, rebase,
  or tag unless the user asked… Commit, report, stop") and its Finish
  ("plus an explicit note that nothing was pushed") are what make `land`
  a separate skill rather than a section of `commit`. Also the source
  for house voice and for the `model` / `effort` precedent.
- **Live execution of PR #7 in this session** — the reference case, and
  where most of this was measured rather than read. Push, identity
  comparison, `create_pull_request`, `git switch main`, `git merge
  --ff-only`, `git push origin main`, merge verification, CI polling.
  Confirmed the fast-forward path leaves the repo at **zero merge
  commits** and that GitHub flipped the PR to `merged: true`,
  `merged_by: wardawgmalvicious`, with no use of the merge button.
- **`gh auth status` on this machine** — resolves to `wmalcolm-fdi`, the
  **work** account, against a repo owned by `wardawgmalvicious`.
- **`github-mcp` tool surfaces, used live**: `get_me` (returned
  `wardawgmalvicious`), `create_pull_request`, and `pull_request_read`
  with methods `get` and `get_check_runs`. The check-runs shape is what
  the verification step reads: on PR #7 two `pre-commit` runs reported
  `conclusion: success`, alongside a `copilot-pull-request-reviewer` run
  that is **not** a gate.

Not drilled, deliberately:

- **The `405 Rebase merges are not allowed` response itself.** Inherited
  from root `CLAUDE.md`, which records it as verified on PR #6 on
  2026-09-02. **Not independently reproduced in this run** — no rebase
  merge was attempted, and attempting one to confirm would be a
  destructive test against `main`. The skill cites it as the repo's
  documented reason for `--ff-only`, never as something it measured.
- **The GitHub REST repository-settings API** (`allow_rebase_merge`,
  `allow_squash_merge`, `allow_merge_commit`) read *authenticated*. Root
  `CLAUDE.md` establishes only that they are unreadable
  unauthenticated. Whether the MCP identity can read them is unknown and
  was not tested, so the skill never advises checking them and treats
  `--ff-only` as the standing rule instead.
- **`merge_pull_request` (the MCP merge tool) and the GitHub merge
  button.** Deliberately excluded rather than unexamined: this repo
  lands locally by fast-forward, and both of those produce merge shapes
  the repo rejects.
- **Branch protection, required reviews, CODEOWNERS.** None surfaced on
  this repo and none were configured during the run. The skill assumes
  an unprotected `main` and says so.
- **Fork and cross-repo pull requests**, and any repo other than
  `agent-config`. The skill is written for the case where the pusher
  owns the repo and the branch is on `origin`.
- **`gh` as a PR tool.** Excluded by root `CLAUDE.md`, so it was read
  only far enough to establish *which* account it holds.

## Frontmatter

```yaml
---
name: land  # repo linter requires it; max 64 chars; lowercase/digits/hyphens
description: <see draft — trigger vocabulary plus the commit disambiguation>  # gated at 1,024
disable-model-invocation: false  # ALWAYS PRESENT; repo policy: false everywhere
model: inherit  # ALWAYS PRESENT; repo policy: inherit everywhere except commit
effort: max  # ALWAYS PRESENT; repo policy: max on the workflow skills that drive this repo
---
```

No `paths:` — see [Scope](#scope). No `when_to_use`: this is an
**unconditional** skill whose description sits permanently in every
session's listing, which is exactly where the field is not near-free.
[when-to-use-adoption.md](when-to-use-adoption.md) owns that call for
the unconditional half; setting it here would pre-empt it. No
`allowed-tools` — the git and MCP calls are already governed by the
session, and `commit` sets none either.

**`model: inherit` rather than `commit`'s `sonnet`, deliberately.** The
mechanical half would run fine on a cheap model, but the PR body is
judgement work — it carries validation outcomes and decision reasoning
into the durable artifact — and a `model:` pin *is* honoured here,
because `land` is unconditional and therefore genuinely slashable (the
wave 8 finding: pins are slash-only, and inert on the conditional
platform skills). Revisit if the spend shows up.

## Description char count

- `description`: 683 / 1,024
- `when_to_use`: N/A — not set (see Frontmatter)

**The binding constraint here is the aggregate, not the per-field cap.**
The eight existing workflow descriptions total ~6,230 chars and are all
unconditional at user scope, so `land` adds its full length to every
session on this machine. Keep it near 600 and spend the budget on
trigger vocabulary, not on summary.

## Body structure outline

`SKILL.md` only — **no `references/` split.** The long background this
skill would otherwise carry already lives in root `CLAUDE.md`, which
auto-loads in this repo, so a reference file would duplicate it.

1. **What this is** — the boundary with `commit`, in two lines.
2. **Preflight** — clean tree; not already on `main`; and the
   concurrent-session check, because the `git switch` later is not
   scoped to you.
3. **Establish the identity before anything outward** — compare
   `gh auth status` against `github-mcp get_me` and use the one matching
   the repo owner. The gate on everything after it.
4. **Push the branch.**
5. **Survey what is actually landing** — the commit range, and
   specifically whether commits from another session rode along.
6. **Open the PR** — through `github-mcp`. What the body owes: why
   rather than what, validation outcomes, and disclosure of any
   concurrent-session commits.
7. **Checkpoint** — stop. Report the PR and wait, because everything
   after this pushes `main`.
8. **Land by fast-forward** — the exact command, and why each of the
   three alternatives is wrong here.
9. **Verify** — `merged: true`, CI check runs, and that the merge-commit
   count did not move.
10. **Constraints** — never force, never squash, never `gh` for the PR,
    never merge without the checkpoint.

## Changes from source proposal

Derived from the `/learn` request in this session ("a sibling skill to
commit… publish branch, open pr, merge to main"). Two material
departures, both agreed with the user before drafting:

1. **This reverses a recorded decision.** Wave 15, closed earlier the
   same day, resolved the PR-skill question **no**, on the grounds that
   "the flow is three commands plus 'open the PR with `github-mcp`, not
   `gh`', both already in root `CLAUDE.md`… a skill would spend
   permanent listing budget on text already in context." That reasoning
   was sound for what it evaluated and wrong on the measurement: the
   flow is ~10 operations with two silent-failure modes, and the PR body
   is judgement work the payload does not cover anywhere. The reversal
   is deliberate, was put to the user with the prior decision quoted,
   and **must be recorded** — wave 15's row needs a pointer to the
   reversal, and this work needs a queue row of its own as **wave 18**
   (17 is the Power BI MCP template).
2. **Scope stops at a checkpoint** rather than running end to end. The
   user chose this over an unattended full run: pushing `main` is the
   one irreversible step, and `commit`'s own rule is never to push
   unless asked.

## Tag

`personal`

## Portability caveats

**One real dependency: `github-mcp`.** The identity check and PR
creation both go through that MCP server, and its absence is not a
graceful degradation — falling back to `gh` is exactly the failure the
skill exists to prevent, and on this machine would file the PR under the
wrong account. A machine without `github-mcp` should open the PR by hand
in the browser rather than reach for `gh`. Everything else is plain git.

Nothing else Claude-Code-only is relied on: no `context: fork`, no
hooks, no `allowed-tools`, no `paths:`, no `shell: powershell`.

## Cross-reference dependencies

- `commit` — (a) exists. The predecessor; `land` begins at its Finish.
  **Cite, do not restate** — `land` must not re-explain committing, and
  `commit` keeps its "nothing was pushed" rule unchanged.
- Root [`CLAUDE.md`](../../../CLAUDE.md) — (c) external to `skills/`,
  and the **authority** for `--ff-only`, the rebase-disabled fact and
  the `github-mcp`-not-`gh` rule. It auto-loads in this repo, so `land`
  cites it rather than duplicating the reasoning. Note the asymmetry:
  `land` also deploys to *other* repos where root `CLAUDE.md` does not
  load, so the procedure must stand alone even though the rationale
  lives there.
- `github-mcp` MCP server — (c) external. Required; see
  [Portability caveats](#portability-caveats).
- `code-review` — (a) exists. Optional pre-land step; `land` should
  mention it once and not require it.
- [`docs/handoffs/execute/README.md`](README.md) — (b) **pending edit.**
  Wave 15's row records the "no" this brief reverses, and wave 18 needs
  registering. Not this skill's file to change during drafting; it goes
  in the same commit.

## Claude Code's post-draft checklist

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**The identity trap is why this skill earns its listing budget, and it
is worth stating why it is invisible.** Root `CLAUDE.md` already says to
use `github-mcp` and not `gh`. What it cannot do is make the
*comparison* happen: during PR #7 the check ran only because the file
was re-read at the right moment. `gh` is authenticated, it works, it
reports success, and the PR simply appears under `wmalcolm-fdi`. There
is no error, and a wrong-account PR looks identical to a right-account
one until someone reads the author. A procedure step converts a rule
that must be remembered into one that gets executed.

**The concurrent-session disclosure is new, and nothing in the payload
covered it.** Three commits authored by another session in the same
working tree rode along in PR #7. Root `CLAUDE.md` predicts that they
land on your branch; it does not say that a PR description silently
including someone else's work is a review problem. The skill adds the
disclosure step.

## Confidence

- **Procedure — H.** Every step was executed end to end during this
  session against PR #7, and the outcomes were verified rather than
  assumed: merged state read back from the API, CI conclusions read
  back, merge-commit count re-counted at zero.
- **The rebase-disabled premise — M, and inherited.** Root `CLAUDE.md`
  records the `405` on PR #6; this run did not reproduce it. The
  practical guidance is unaffected, because `--ff-only` is correct
  whether rebase merging is disabled or merely undesirable here — but if
  the constraint is ever re-checked, that is the sentence to re-verify.
- **Structure and frontmatter — H.** Follows `commit` directly, with the
  one deliberate divergence on `model:` recorded above.
