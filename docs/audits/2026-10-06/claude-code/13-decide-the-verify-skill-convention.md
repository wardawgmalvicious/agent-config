# Handoff: decide the verify skill convention

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 16
- **Kind**: decision on adopting a `verify` skill, after a check of how
  the harness's pre-commit instruction meets the `commit` skill
- **Target**: `skills/workflow/commit/SKILL.md`, or a new skill

## The problem

Since 2.1.286 the harness tells Claude to run a skill named `verify` or
`simplify` right before each commit. A first-party `simplify` skill is
listed in sessions here, so that instruction may already run beside the
`commit` skill's own procedure, unasked. No `verify` skill exists,
though one could carry this repo's gates.

## Evidence

- https://code.claude.com/docs/en/skills, read 2026-10-06:
  > When a session starts with a skill named `verify` or `simplify` in
  > place, Claude Code's commit instructions tell Claude to run it right
  > before each commit, except for changes to docs or tests. This
  > requires Claude Code v2.1.286 or later.
- `CHANGELOG.md` 2.1.286:
  > Improved commit guidance: when your project or user skills include
  > one named `verify`, Claude is now told to run it right before
  > committing, except for docs-only and tests-only commits
- The skill listing of sessions here on 2026-10-06 carried `simplify`,
  described as "Review the changed code for reuse, simplification,
  efficiency, and altitude cleanups, then apply the fixes."
- The changelog names project or user skills and `verify` only; the
  docs add `simplify` and do not say whether a bundled skill counts.
- `skills/workflow/commit/SKILL.md` names neither skill (2026-10-07).

## What to change

1. Check first: in the transcript of a commit made here on 2.1.286 or
   later, find whether the harness's commit instructions name
   `simplify`. If they do, a skill that applies fixes runs right before
   a commit that `commit` has already split and staged.
2. Then put the decision to the user.

**Open question.** a) write a `verify` skill through `/author-skill`,
for instance one that runs `pre-commit run --all-files`, which the hooks
also run at commit; b) have `commit` say what to do with the harness's
instruction, if step 1 finds `simplify` named; c) neither.

## Verification

1. Step 1's finding, with the transcript and record it came from.
2. If a skill is written: `/test-skill <name>`. If `commit` changes:
   its retest, which
   `uv run --with pyyaml scripts/skill-status.py --stale` names.
3. `pre-commit run --all-files`.

## Provenance

Found by the 2026-10-06 `claude-code` run in its changelog diff and the
skills page fetched that day through WebFetch; the `simplify` listing
is the audit session's own.
