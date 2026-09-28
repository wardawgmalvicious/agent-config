---
status: open
priority: 1
needs: []
blocked-by: []
written: 2026-09-27
---

# Handoff: each brief carries its own state, and the queue is generated

- **Written**: 2026-09-27, from the user's decisions that day, after a
  session measured how often the queue README is read and surveyed how
  other agent tooling keeps a backlog.
- **Kind**: edits, decided, in six steps. Step 1 landed 2026-09-27:
  `360884a` taught `handoff-status.py` to read frontmatter, and the
  commit after it gave every brief its own. Step 3 landed next, ahead of
  step 2, so the rule allowed a nested file before the first was written,
  and step 2 after it, then step 4, then step 5. Step 6 is left.
- **Status**: the first brief written in the format it introduces.

## The decision

The user, 2026-09-27, answering five questions:

1. **No hand-maintained queue.** Each brief carries its state in
   frontmatter, and `handoff-status.py` generates the view.
2. **Priority is three buckets**, not a total order: anything in one
   bucket may run in parallel.
3. **A worktree named after a brief claims it.**
4. **The ban on nested `CLAUDE.md` files here goes**, replaced by a lint
   for the places one does harm, and `docs/handoffs/CLAUDE.md` comes
   first.
5. **`claude/CLAUDE.md` stays where it is for now**, its double load a
   separate brief:
   [payload-claude-md-double-load.md](payload-claude-md-double-load.md).
   Not this one.

## Why the single file goes

[README.md](README.md) is "the only place the execution order lives", so
every session that starts or lands a brief edits it. Two sessions in one
tree drop each other's rows silently, which root `CLAUDE.md` has recorded
since 2026-09-02; two in worktrees conflict on it at merge. So briefs run
one at a time, whatever else would allow more.

It is also read less than it is written. Of 24 sessions that edited a
brief here between 2026-09-11 and 2026-09-27, 7 opened the README first
of their own accord, 4 more because the user named it, and 11 never did
([nested-instruction-files.md](nested-instruction-files.md), § "Phase 2").

Surveyed 2026-09-27, everything built for parallel agents keeps state
per task and generates the view. Backlog.md holds one file per task with
frontmatter and draws its board from them; log4brains drops sequential
numbering, which its README says avoids git merge issues, and generates
its site; spec-kit and Kiro shard by feature directory with no index
across features. Taskmaster began with one `tasks.json`, met this exact
collision (its issue #744), and added tagged task lists to fix it.
Claude Code's agent teams claim tasks under file locking with
dependencies, but are experimental, one team per session, and share one
working tree: a fan-out tool, not a durable backlog (docs read
2026-09-27). No public agent-config repo was found keeping a brief
directory with a generated view.

## The design

**Frontmatter is the state.** A restricted YAML subset, so the reader
stays stdlib and the lint strict: `key: value` or `key: [a, b]`, nothing
else.

| Key | Values | Meaning |
| --- | --- | --- |
| `status` | `open`, `deferred` | Landing deletes the brief, so there is no third state |
| `priority` | `1`, `2`, `3` | Now, next, later; within a bucket, no order |
| `needs` | list: `user`, `tenant`, `desktop`, or a short phrase | What a session cannot supply alone; empty means it can act |
| `blocked-by` | list of brief filenames here | Each must exist; a landing deletes its name from the others |
| `reopen-when` | text | Required when `deferred`: the trigger |
| `written` | `YYYY-MM-DD` | Tiebreak within a bucket, oldest first |

The body keeps the narrative, and states no status the frontmatter
holds.

**The view is generated.** `uv run scripts/handoff-status.py` groups a
directory's briefs into ready, needs you, needs something else, blocked
and deferred, by bucket then age, and marks a brief in flight when a git
worktree is named after it. A repo whose briefs carry no frontmatter
keeps its index and is read as before, which covers `machine-config` and
the client repos.

**A worktree claims a brief.** `claude --worktree <brief-name>` isolates
the index and HEAD, which a shared tree cannot, and `git worktree list`
shows what is in flight with nothing committed. The brief is deleted on
its branch, and the branch lands as `/land` lands one.

**Deploy only from the main checkout**, after integrating.
`link-claude.ps1` junctions skills into whichever checkout runs it
(`$RepoRoot = Split-Path -Parent $PSScriptRoot`), so a deploy from a
worktree points every skill at a directory that is deleted when the
worktree goes.

**What still conflicts is real content**: the evidence ledgers,
`tests/skills/.tested.json`, `copilot/.source-hashes.json`. Between
worktrees those surface loudly at rebase, where the README dropped rows
in silence.

## Steps

1. **Frontmatter and the generated view.** `handoff-status.py` reads
   frontmatter, groups and sorts, marks worktrees in flight, and gains
   findings for bad frontmatter and a missing `blocked-by` target; a brief
   with frontmatter is never `unindexed`. A `--no-inbox` flag lets
   pre-commit run it on this repo alone, as `lint-briefs`. Every brief
   here gets frontmatter. `test-findings.sh` plants each new finding.
   The README table stays until step 2, so nothing reads a half-built
   queue.
2. **`docs/handoffs/CLAUDE.md` and the README.** The nested file holds
   what a session must know before touching a brief, short, since it
   loads on the first Read anywhere under `docs/handoffs/`. The README
   loses its table and keeps the reasoning. Root `CLAUDE.md`,
   `docs/handoffs/README.md`, `author-skill`, `test-skill`, `drift-update`
   and `audit-status.py` stop pointing at the table. As landed:
   `author-skill` and `test-skill` never pointed at it, and `drift-update`
   and `audit-status.py` point at the README's audit table, which stays
   for step 5. `handoff-status.py` had to stop reading the new file as a
   brief, and the brief templates gained frontmatter the commit before,
   since `/author-skill` builds from them and `lint-briefs` fails a brief
   without it.
3. **The ban becomes a lint.** `.claude/rules/editing-claude-md.md` drops
   "never a subdirectory `CLAUDE.md`" and covers nested files. A check
   fails a nested `CLAUDE.md` or `AGENTS.md` under
   `claude/{agents,hooks,rules,mcp}/`, which deploy, inside
   `skills/<group>/<name>/`, which ships, or under `tests/`, where
   fixtures need a clean context, and caps a nested file's length.
   `claude/CLAUDE.md` is the payload, excepted by name. It landed wider:
   all of `claude/` and `.claude/`, and an `AGENTS.md` anywhere, the
   ledger entry saying why.
4. **Parallel work in root `CLAUDE.md`.** § "Branching and concurrent
   sessions" says commit straight to `main` (settled 2026-09-02). It
   keeps that for serial work and adds a worktree per brief for parallel
   work, deploy from main only. Edit it with `claude/CLAUDE.md` § "Branch
   naming", as the paragraph requires. As landed: `link-claude.ps1`
   refuses a linked worktree, from the commit before, since per-file rules
   ask for a deploy after an edit and a worktree session would follow
   them; landing goes to the main checkout as well, because git will not
   move `main` from a worktree. § "Branch naming" lost its `agent-config`
   example and needed no rule change, since a fast-forward records no
   branch name. `/land` has no route for a branch whose worktree is
   linked: its default opens with `git switch main`, which fails there.
   [land-rework.md](land-rework.md) takes that up.
5. **The audit second queue is generated too.** README § "Audit briefs are
   a second queue" is another hand-kept list. Escalated audit briefs with
   no `**Closed**` line are what it lists, and `audit-status.py` already
   reads those logs. As landed: the table also listed deferred and
   applied-with-deferrals briefs, and missed three open logs, powerbi 07
   among them, declined but never closed. Each open log now carries a
   `**Needs**:` line, `handoff-status.py` prints them grouped by it with
   `audit-status.py`'s rule, and `lint-briefs` fails an open one without.
6. **Re-plan [handoff-convention-cross-repo.md](handoff-convention-cross-repo.md).**
   Its core says order lives in exactly one file, which this supersedes.
   None of its Q1 edits was drafted.

## Verification

- `bash tests/scripts/handoff-status/test-findings.sh` passes, each new
  finding planted and firing, the resolved fixture quiet.
- `uv run scripts/handoff-status.py` shows every brief here in its group,
  and `machine-config` and the client repos as before.
- `pre-commit run --all-files` passes with `lint-briefs` in it.
- Step 3's check fails on a planted `claude/rules/CLAUDE.md` and passes
  without it.
