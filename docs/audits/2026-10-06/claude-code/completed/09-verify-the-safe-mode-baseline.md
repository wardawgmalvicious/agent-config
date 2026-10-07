# Handoff: verify the safe-mode baseline

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 11
- **Kind**: probe of what `claude --safe-mode` keeps in D-1, then a
  correction to root `CLAUDE.md`; D-2 alone is a documented edit that
  does not wait on it
- **Target**: `CLAUDE.md`, `.claude/rules/activation-testing.md`

## The problem

The repo's manual test procedure baselines with `claude --safe-mode`.
Since 2.1.283–2.1.285 a session with no permission mode configured
starts in auto mode. If `--safe-mode` drops `permissions.defaultMode`
with the rest of the payload, the baseline now runs in auto mode, which
prefers `cat`, and a `cat` loads nothing. Separately, the activation
probe recipe denies Bash, which on Windows now removes PowerShell as
well; the rule does not say so.

## D-1 — what permission mode a `--safe-mode` baseline runs in

**Symptom.** Root `CLAUDE.md` § "Validating a change":
> Baseline with `claude --safe-mode`, typed, never wired into config; it
> strips this file too, so for this repo's skills see `/test-skill` step
> 8.

`.claude/skills/test-skill/references/reading-a-failure.md` records
what `--safe-mode` strips and keeps, measured from 2026-09-13, and says
nothing of the permission mode.
**Cause.**

- `CHANGELOG.md` 2.1.284:
  > Changed interactive terminal and VS Code sessions to start in auto
  > mode when no permission mode is configured, on every plan and
  > provider; `permissions.defaultMode` still overrides it
- 2.1.283 made the same change for third-party providers and
  telemetry-off sessions, and 2.1.285 for `claude -p` and Python Agent
  SDK sessions on those.

**Fix.** A cold probe: start `claude --safe-mode` in a scratch
directory and in this repo, and read the permission mode from `/status`
or the transcript. Then say in § "Validating a change" what mode the
baseline runs in and, if auto, how to pin it for a fair comparison, for
instance `--permission-mode default`; add the result to
`reading-a-failure.md` too, where the other `--safe-mode` facts live.

## D-2 — denying Bash on Windows removes PowerShell too

**Symptom.** `.claude/rules/activation-testing.md`, first bullet: a
probe measuring activation "pins `--allowedTools Read --disallowedTools
Bash …`".
**Cause.** `CHANGELOG.md` 2.1.287:
> Windows: Added a startup warning when denying the Bash tool also turns
> off the PowerShell tool, so Claude has no shell tool

**Fix.** One clause: on Windows the Bash deny removes PowerShell as
well, so the probe has no shell tool at all, which is what it wants.

## Sequencing note

Brief 02 corrects the same first bullet of `activation-testing.md`, and
the file carried another session's uncommitted edit when this was
written. Land 02 first, re-read the bullet, then add D-2; do not bundle
them.

## Verification

1. D-1: the probe's transcript or `/status` output, cited in a dated
   entry in `docs/evidence/root-claude-md.md` under § "Validating a
   change".
2. `grep -n "PowerShell" .claude/rules/activation-testing.md` — a hit.
3. `uv run scripts/lint-claude-md.py`
4. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/rules/activation-testing.md`
5. `pre-commit run --all-files`.

## Provenance

From the 2026-10-06 `claude-code` run's changelog diff. Whether
`--safe-mode` keeps `permissions.defaultMode` is the open part; the
audit did not run it.

## Execution log

- **Executed**: 2026-10-07 — escalated (D-1 to the user's console
  session that brief 08 D-1 holds; D-2 applied)
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: `.claude/rules/activation-testing.md`
- **Open question**: where D-1's probe runs, put to the user, who chose
  the real-console session brief 08's D-1 already needs: the baseline is
  typed, so it starts interactively, and 2.1.284's auto-mode default
  covers interactive sessions while `claude -p` follows 2.1.285's rule.
- **Verification**: the sequencing note held: brief 02's correction of
  this bullet landed on `main` as `6751e6e`, this run's brief 02 left
  the file alone, and the bullet was re-read before D-2 went in. D-2's
  quote sat at line 18, D-1's at root `CLAUDE.md` lines 175–176. Step 2
  — **passed**: `PowerShell` at line 22. Step 3 — **passed**:
  `lint-claude-md.py`, root unchanged at 200 of 200. Step 4 —
  **passed**: `lint-frontmatter.py`, exit 0. Step 5 (`pre-commit run
  --all-files`) runs once at the end of the run.
- **Deferred**: step 1 is D-1's.
- **Deviations**: none. One note: D-2 went at the bullet's end as its own
  sentence, leaving the lines `6751e6e` wrote unreflowed, and its
  evidence stays in this brief, since only D-1's step names a ledger
  entry.
- **Needs**: user, shared with brief 08 — D-1's `claude --safe-mode`
  start in a scratch directory and in this repo, its mode read from
  `/status` or the transcript and cited in a dated root-ledger entry
  (step 1); then § "Validating a change" and the test-skill
  `reading-a-failure.md` say which mode the baseline runs in, and how to
  pin it if auto.
- **Closed**: 2026-10-07 — D-1 probed on 2.1.291, in a session with the
  user: `--safe-mode` keeps `permissions.defaultMode`, so a baseline runs
  in auto as the payload arm does. Sonnet `-p` arms read `auto` under the
  flag from a scratch directory and this repo, a control without user
  settings read `default`, and a typed console start recorded `auto`
  (`655da078`). The suggested `--permission-mode default` pin would have
  set the arms apart, so root `CLAUDE.md` stays as it is, at the user's
  call, and the fact went to `reading-a-failure.md` and the root ledger.
  Steps 1 to 5 passed.
