# Handoff: trial prompt-audit and skill-doctor

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 12
- **Kind**: trial run of two new harness commands, then a decision on
  whether either joins this repo's validation procedure
- **Target**: `CLAUDE.md` § "Validating a change", if either is adopted

## The problem

Two first-party commands overlap work this repo does by hand.
`/doctor prompt-audit` audits instruction files for stale paths, stale
commands and contradictions; `/skill-doctor` reports which loaded skills
go unused and what they cost in context. Neither has been run here, so
whether either earns a place in § "Validating a change" is unknown.

## Evidence

- https://code.claude.com/docs/en/memory, read 2026-10-06:
  > To have Claude check your instruction files for outdated or
  > conflicting content, run `/doctor prompt-audit` in a session. Claude
  > looks for problems such as instructions written for older models,
  > references to files or commands that don't exist, and files that
  > contradict each other. You get a report of findings with proposed
  > edits, and nothing in your files changes until you ask Claude to
  > apply them.

  > By default, the audit covers your CLAUDE.md, CLAUDE.local.md, and
  > AGENTS.md files, plus the rules, skills, commands, subagents, and
  > output styles under `.claude/` and `~/.claude/`.

  > The audit runs through the bundled `/claude-api` skill. It's
  > unavailable while that skill is turned off in `skillOverrides` or
  > with `disableBundledSkills`. `/doctor prompt-audit` requires Claude
  > Code v2.1.283 or later.
- `CHANGELOG.md` 2.1.283 added it, and in the same release made stale
  paths, stale commands and contradicting instruction files lead its
  report.
- `CHANGELOG.md` 2.1.261:
  > Added `/skill-doctor` to show which loaded skills go unused and what
  > they cost in context, so you can prune them
- This repo's `.claude/settings.json` `skillOverrides` collapses only
  platform skills, so `claude-api` stays available here.

## What to change

1. Run `/doctor prompt-audit` once in a session in this repo, apply
   nothing from it there, and read its report against root `CLAUDE.md`,
   `claude/CLAUDE.md` and the rules. Note what it found that
   `scripts/lint-claude-md.py`, the pre-commit hooks and the drift
   audits did not, and what the run cost.
2. Run `/skill-doctor` once and set its report beside
   `scripts/skill-telemetry.py` and `scripts/skill-status.py`. It
   measures listing cost, not activation:
   `.claude/rules/activation-testing.md` § "No log sees a skill's
   conditional activation" still holds.
3. Put both results to the user.

**Open question.** Does either join § "Validating a change", and where?
Root `CLAUDE.md` is capped, so a line in moves one out.

## Constraint on the fix

A finding the audit reports is not a brief: any edit it proposes to a
rule or a skill goes through that file's own route, never applied from
the trial session in passing.

## Verification

1. The two reports, or their summaries, recorded with the decision.
2. If root `CLAUDE.md` changed: `uv run scripts/lint-claude-md.py`, a
   dated entry in `docs/evidence/root-claude-md.md`, and
   `pre-commit run --all-files`.

## Provenance

Found by the 2026-10-06 `claude-code` run in its changelog diff, with
`/doctor prompt-audit` checked against the memory docs that day.
`/skill-doctor` is on no docs page the audit read.

## Execution log

- **Executed**: 2026-10-07 — escalated (the trial needs the user)
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: none
- **Open question**: where the trial runs, put to the user, who chose a
  session with them. Both are built-in commands the user types, which
  this run cannot invoke. The adoption question waits on their reports.
- **Verification**: none of the brief's steps apply, since no file
  changed. `pre-commit run --all-files` runs once at the end of the run.
- **Deferred**: the whole trial, steps 1 and 2 with it.
- **Deviations**: none.
- **Needs**: user — run `/doctor prompt-audit` and `/skill-doctor` once
  each in a fresh session here, applying nothing; record both reports
  and what each cost against `lint-claude-md.py`, the pre-commit hooks,
  the drift audits and `skill-telemetry.py`; then put the adoption
  question to the user, any finding going through its file's own route.
