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
