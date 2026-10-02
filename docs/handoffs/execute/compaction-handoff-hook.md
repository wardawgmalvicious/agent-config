---
status: open
priority: 3
needs: [user]
blocked-by: []
written: 2026-10-01
---

# Handoff: a user-scope hook that offers a hand-off after compaction

- **Written**: 2026-10-01, from an inbox note of 2026-10-01 by a session
  in a client Fabric sandbox repo, which built a project-scope version
  that day; the user wants to explore one across all repos. Re-measured
  against the payload at `4f473d2`: `claude/settings.json` wires only
  `InstructionsLoaded`, `PreToolUse` and `PostToolUse`, and no hook, rule
  or skill covers compaction events. The note's platform facts landed in
  `claude/rules/coding-bash.md` § Claude Code hooks on 2026-10-01.
- **Kind**: a decision, the user's, then an edit: a hook script, its
  `claude/settings.json` entry and tests, which never land from a note.
  Nothing is drafted here.

## What the platform allows (documented, hooks reference, confirmed 2026-10-01)

- **PreCompact cannot tell Claude anything.** Exit 2 blocks compaction
  and its stderr goes to the user on a manual `/compact`; its
  `systemMessage` and `continue` are discarded. Blocking an auto
  compaction skips it, or fails the request when the compaction was
  recovering from a context-limit error.
- **SessionStart with matcher `compact` can**: it fires after any
  compaction, and its plain stdout is added to Claude's context. Text
  there should read as facts, not commands, or it can trip
  prompt-injection defences.
- **PostCompact** receives `compact_summary` and has no decision
  control: it could write a dated draft beside the queue with no action
  from Claude (a lead, not tried).
- No hook input carries context size as the context fills, so no hook
  warns before an auto compaction; a UserPromptSubmit estimate from the
  transcript's `usage` would cost a bash spawn per prompt (not built).
  `autoCompactWindow` moves when auto compaction fires (not fetched).

## The user's call, and the design it sets

**Offer, never block** (the user's words in the origin repo, 2026-10-01,
recorded there in project-scoped auto-memory no other repo reads): a
first version blocked a bare `/compact` with a hand-off message, and the
user turned it down the same day, wanting to judge when to hand off. The
replacement is SessionStart `compact` alone: it states that a brief could
be written while the summary still holds the thread, lists the open
briefs, and writes one only on the user's word. Whether that preference
earns a line in `claude/CLAUDE.md`, which is at its cap, is a question
for the user.

## What a user-scope version must settle

- **Worktrees**: `CLAUDE_PROJECT_DIR` stays at the main checkout while
  the input's `cwd` follows Claude into a worktree, so the list should
  come from `cwd`'s checkout, which means reading stdin.
- **Repos with no queue**: print nothing, or a one-line offer.
- **Which briefs**: all, or only the one in flight; audit follow-ups or
  not.
- **Spawns**: builtins only. The origin's pipe tests averaged 2,740 ms per
  run under load, nearly all of it Git Bash starting (one observation,
  against `claude/CLAUDE.md`'s 0.4 s per spawn); fine after a compaction,
  too much per prompt.
- **Duplicates**: a user-scope command that differs from the origin's
  project hook runs beside it, so that one goes, as a change made from
  its own repo.
- **Tests** under `tests/hooks/<name>/`, as `identity-guard` has. A hook
  that reads stdin blocks when run by hand with none; pipe-test with JSON
  or `</dev/null`.

Observed in the origin's pipe tests: a backslash `CLAUDE_PROJECT_DIR`
opened inside double quotes, CRLF frontmatter parsed with the CR
stripped, `README.md` skipped by name. Not observed: the hook firing in
a live session.

## Where it lands

`claude/hooks/<name>.sh`, a SessionStart entry in `claude/settings.json`,
a `claude/hooks/README.md` entry carrying the compaction facts above,
and `tests/hooks/<name>/`; live after `link-claude.ps1 … -Force`.

## Not checked

The hook firing live; `ask` decisions under auto mode; `autoCompactWindow`.

## Scrubbing

The origin repo is cited by kind, its SHAs left out.

## Re-measure before acting

- `grep -n '"SessionStart"\|"PreCompact"' claude/settings.json`: nothing
  on 2026-10-01.
- The hooks reference's PreCompact, PostCompact and SessionStart
  sections, since hook events move between releases.
