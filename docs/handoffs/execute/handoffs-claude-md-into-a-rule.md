---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-15
---

# Handoff: move docs/handoffs/CLAUDE.md into a rule

- **Written**: 2026-10-15, by the session that traced
  `nested-claude-md-misses.md`, kept at
  `git show e6c28bd:docs/handoffs/execute/nested-claude-md-misses.md`.
- **Kind**: an edit. The user chose the move that day, over leaving the
  file or moving it in that brief's branch, so nothing here waits on them.

## Why

On Windows a nested `CLAUDE.md` loads only on a path whose drive letter
is cased as the launch directory's, and a VS Code session stops writing
such paths at its first Bash call, while a `paths:` rule loads on either
spelling: `claude/rules/agent-instructions-scoping.md` § "How Claude Code
loads them" has the finding, and `scripts/test-instruction-loading.py`'s
d1 to d5 probe it. Here 15 of 50 fresh VS Code sessions that Read under
`docs/handoffs/` never loaded `docs/handoffs/CLAUDE.md` (2026-10-15), so
nearly a third of the sessions working the queue never saw its keys or
its landing steps.

## The move

- `git mv docs/handoffs/CLAUDE.md .claude/rules/<name>.md`, then add
  `paths:` with the one glob `docs/handoffs/**`, so `git blame -C` still
  reaches the commits that wrote each line. `handoff-briefs.md` fits the
  rules there; no name may repeat one in `claude/rules/`
  (`.claude/rules/editing-rules.md`).
- Re-root its links, which are relative to `docs/handoffs/` now:
  `execute/README.md` and its anchors become
  `../../docs/handoffs/execute/README.md`.
- It leaves `scripts/lint-claude-md.py`'s 60-line nested cap for
  `editing-rules.md`'s terms. Root `CLAUDE.md` § "Editing conventions"
  lists the rules here, so the name joins that list; root was 197 lines of
  200 on 2026-10-15.

## What to re-point

Every live mention, from
`git grep -n -E 'handoffs/CLAUDE\.md|\]\(\.\./CLAUDE\.md\)' -- ':!docs/audits' ':!docs/evidence'`
on 2026-10-15; the dated ledgers under `docs/audits/` and `docs/evidence/`
stand as written:

- root `CLAUDE.md` § "Branching and concurrent sessions", "land it as
  `docs/handoffs/CLAUDE.md` says"
- `docs/handoffs/execute/README.md`, three links to `../CLAUDE.md`, the
  first saying it "loads on the first Read under `docs/handoffs/`"
- `.claude/skills/`: `author-skill/SKILL.md` (two),
  `drift-update/SKILL.md`, `triage/references/formats.md`,
  `test-skill/references/reading-a-failure.md`
- `skills/workflow/`: `run-briefs/SKILL.md` (two), its
  `references/worker-prompt.md` and `references/landing-gate.md`, and
  `land/SKILL.md`. These are junctioned and live machine-wide the moment
  they change, so they change in the commit that moves the file.
- `scripts/skill-status.py`, a docstring line

`tests/scripts/handoff-status/test-findings.sh` plants a
`docs/handoffs/CLAUDE.md` to prove the scanner skips instruction files.
That stays: another repo's queue may keep one.

## Verify

- `uv run --with pyyaml scripts/lint-frontmatter.py .claude/rules/<name>.md`,
  then `pre-commit run --all-files`.
- The grep above prints nothing outside the ledgers and this brief,
  which its landing commit deletes.
- In a fresh VS Code session, make one Bash call, then Read a brief by a
  path spelled `C:\`: the rule arrives as a `nested_memory` attachment. On
  `main` before the move, the same steps load nothing.
