# Handoff: re-measure the spawn cost and decide the read-block note

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 10
- **Kind**: measurement of one timing figure in D-1 and a decision on
  one line in D-2, both landing in `claude/CLAUDE.md`
- **Target**: `claude/CLAUDE.md`, `docs/evidence/user-claude-md.md`

## The problem

`claude/CLAUDE.md` states a spawn cost measured before two Windows
changes to the Bash tool. It also says nothing about a one-time offer
auto mode now makes which, if accepted, makes the file tools refuse
every read outside the working directory, the handoff inbox among them.

## D-1 — the spawn figure predates two Bash tool changes

**Symptom.** § "Local environment":
> **A spawn costs ~0.4 s** (2026-09-04): per-line forks look hung,
> killed at 120 s with stray `write error` lines. Do the arithmetic
> (spawns × 0.4 s), background them with a ten-minute cap, and keep
> hooks spawn-lean.

Its ledger entry, `docs/evidence/user-claude-md.md` § "Local
environment", measured 120 `git`/`date` spawns in 46 s, in both tool
shells and from a real console. The same section describes Git Bash's
two session modes by `/proc/$$/cmdline`.
**Cause.**

- `CHANGELOG.md` 2.1.287: "Windows: Improved Bash tool speed by removing
  a subshell that ran before every command".
- `CHANGELOG.md` 2.1.274: "Fixed the Bash tool re-sourcing the shell
  profile (a multi-second stall on the next command) after every plugin
  reload; it now does so only when the plugins' `bin/` directories
  changed".

**Fix.** Repeat the 2026-09-04 method on the current CLI, in both tool
shells and a real console. If the figure moved, correct it in place
with the new date and add a ledger entry; re-check the two
`/proc/$$/cmdline` modes while there. The ledger saw the same cost from
a real console, outside the harness, so it may not move: the
measurement decides.

## D-2 — a one-time offer would block reads outside the repo

**Symptom.** § "Agent config source" sends sessions to
`~/handoff-inbox/<repo>/`, and skills here read `~/.claude/projects/`
transcripts and `~/.claude/logs/`, all outside a repo's working
directory. Neither `claude/settings.json` nor the deployed
`~/.claude/settings.json` set
`permissions.blockReadsOutsideWorkingDirectories` on 2026-10-06.
**Cause.**

- `CHANGELOG.md` 2.1.257: "Added a one-time prompt in auto mode before
  the first file read outside the working directories, with the option
  to block such reads (`permissions.blockReadsOutsideWorkingDirectories`)";
  2.1.284 added the answer "Yes, but ask again next time".
- https://code.claude.com/docs/en/permissions, read 2026-10-06:
  > Set `permissions.blockReadsOutsideWorkingDirectories` to make the
  > file tools refuse the paths it fences in every permission mode. In
  > auto mode, Claude Code offers to turn it on the first time Claude
  > reads outside the working directories.

**Fix.** After the answer.
**Open question.** a) a line in `claude/CLAUDE.md` saying not to accept
the block, and what accepting it breaks; b) set the key to `false` in
`claude/settings.json`, if that stops the offer, which is unmeasured;
c) nothing, since the offer comes once and may already have been
declined. `claude/CLAUDE.md` is capped by `scripts/lint-claude-md.py`,
so a line in moves one out, and the user has asked that it carry no
repo paths (2026-09-23).

## Verification

1. `uv run scripts/lint-claude-md.py`
2. A dated entry under the matching heading of
   `docs/evidence/user-claude-md.md` for each claim changed
   (`.claude/rules/editing-claude-md.md`).
3. `pre-commit run --all-files`.
4. From the main checkout,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`,
   then `diff claude/CLAUDE.md ~/.claude/CLAUDE.md` — no output. A
   `-Force` run also merges `claude/settings.json`: read brief 03 D-1's
   knock-on before running it.

## Provenance

Both from the 2026-10-06 `claude-code` run's changelog diff; D-2 was
confirmed on the permissions page that day, and the two settings files
were read by the audit session, which changed neither.

## Execution log

- **Executed**: 2026-10-07 — escalated (D-1 to a session with the user;
  D-2 answered: a line in `claude/CLAUDE.md`)
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: none
- **Open question**: both put to the user. D-1: a later session with the
  user, who times the real-console arm while the session times the two
  tool shells. D-2: **a)**, one line in `claude/CLAUDE.md` saying to
  answer "Yes, and keep allowing" and what the block breaks, with no repo
  path in it, and a line moved out to stay under the cap.
- **Verification**: none of the brief's steps apply, since no file
  changed. A docs lookup, raw markdown read 2026-10-07, settled what
  option **b)** called unmeasured, and the user chose with it in hand.
  The settings reference gives `false` as "the same as unset", and the
  permission-modes page makes the offer while the block is off, so a
  `false` cannot stop it. "Yes, and keep allowing any reads outside the
  working directories" records the answer, so the offer does not return.
  Under the block, files Claude Code itself needs stay readable, "such
  as" its skills, rules, agents and `CLAUDE.md`: `~/handoff-inbox/` is
  refused, while whether transcripts and logs are is open, as the list
  is open-ended. The deployed `~/.claude/settings.json` still lacks the
  key on 2026-10-07. `pre-commit run --all-files` runs once at the end
  of the run.
- **Deferred**: D-1, and the edit D-2's answer implies, with steps 1, 2
  and 4 after them.
- **Deviations**: none.
- **Needs**: user, a session of its own — D-1's spawn timing with the
  user at a real console, where brief 09's `--safe-mode` probe runs too,
  the figure corrected in place with a ledger entry only if it moved,
  and the two `/proc/$$/cmdline` modes re-checked; D-2's line, with what moves out to keep the cap; then
  steps 1 and 2, and step 4's `-Force` deploy after reading brief 03
  D-1's knock-on.
- **Needs**: brief 03's landing — step 4's `-Force` deploy and its diff,
  run with brief 03's once `effortLevel` leaves `claude/settings.json`,
  since a deploy before then would leave `effortLevel: "max"` in
  `~/.claude/settings.json` for good: the merge keeps target-only keys.
  D-1, D-2 and steps 1 to 3 were done 2026-10-07 in a session with the
  user, who chose this order.
