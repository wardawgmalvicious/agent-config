# Handoff: add two documented harness facts to user rules

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 7 and 9
- **Kind**: factual additions to two user-scope rules from documented
  changes; each needs a deploy, no behaviour change
- **Target**: `claude/rules/claude-config-scoping.md`,
  `claude/rules/coding-bash.md`

## The problem

Two user-scope rules describe harness behaviour that changed this
window. `claude-config-scoping.md` puts `permissions.defaultMode` at
user scope as a matter of placement, while the harness now ignores its
two broadest values anywhere else. `coding-bash.md` says an enforcement
hook's failure lets the call through, which no longer holds for a
failure on the harness's side.

## D-1 — `auto` and `bypassPermissions` count only at user or managed scope

**Symptom.** The scope table's first row puts "model and effort
defaults, `permissions.defaultMode`, hooks that must run everywhere" in
`~/.claude/settings.json`, as placement, not as a rule.
**Cause.**

- `CHANGELOG.md` 2.1.257:
  > Changed `defaultMode: "bypassPermissions"` in `.claude/settings.json`
  > or `.claude/settings.local.json` to be ignored, like `"auto"`; set
  > it in user or managed settings, or pass `--permission-mode`
- https://code.claude.com/docs/en/settings, read 2026-10-06:
  > `permissions.defaultMode` values `auto` and `bypassPermissions`
  > don't take effect from project or local settings; set them in user
  > or managed settings instead, or pass `--permission-mode` for one
  > session. Before v2.1.257, `bypassPermissions` took effect from any
  > file.

**Fix.** State it as a rule under the table or in § "Gotchas": either
value in a project or local settings file is ignored.

## D-2 — a failure on the harness's side now blocks the call

**Symptom.** § "Claude Code hooks":
> Any other non-zero is reported as a hook error and the call proceeds
> — so a crash fails **open**.

**Cause.** `CHANGELOG.md` 2.1.288:
> Fixed PreToolUse and PermissionRequest hooks being skipped when
> matching them failed or the tool's input could not be serialized to
> JSON; the call is now blocked

The hooks docs page, fetched 2026-10-06, does not state it.
**Fix.** Keep the exit-code paragraph and add that a failure before the
hook runs, where matching it fails or the tool's input cannot be
serialized, now blocks the call (2.1.288, changelog only). The script's
own crash still fails open.

## Constraint on the fix

D-2 rests on the changelog alone: cite the version and say the hooks
page does not state it. Do not extend it to other events; the bullet
names PreToolUse and PermissionRequest only.

## Sequencing note

Brief 05 D-5 may edit `claude-config-scoping.md` too, in
§ "`~/.claude.json` is runtime state, not payload", after a probe.
Re-read the file before editing it.

## Verification

1. `grep -n "bypassPermissions" claude/rules/claude-config-scoping.md`
   — a hit.
2. `grep -n "2\.1\.288" claude/rules/coding-bash.md` — a hit.
3. `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/claude-config-scoping.md claude/rules/coding-bash.md`
4. `pre-commit run --all-files`. Both rules sit under `deferred` in
   `copilot/.source-hashes.json`, with no port, so no stamp is due.
5. From the main checkout,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`, then
   `diff claude/rules/coding-bash.md ~/.claude/rules/coding-bash.md` and
   the same for `claude-config-scoping.md` — no output.

## Provenance

Both from the 2026-10-06 `claude-code` run's changelog diff. D-1 was
confirmed on the settings page that day; D-2 is on no docs page the
audit read.

## Execution log

- **Executed**: 2026-10-07 — applied with deferrals
- **Session**: fresh (no audit or handoff run in this session; the whole
  pass, in its own worktree)
- **Files changed**: `claude/rules/claude-config-scoping.md`,
  `claude/rules/coding-bash.md`
- **Verification**: both quotes were in place, the table row at line 27
  and the exit-code sentence at lines 252–253. The two pages were
  re-read as raw markdown on 2026-10-07: the settings page still states
  D-1, and the hooks page still says nothing of a matching or
  serialization failure, so D-2's "the hooks page does not" holds that
  day. Step 1 — **passed**: `bypassPermissions` at lines 41 and 45.
  Step 2 — **passed**: `2.1.288` at line 260. Step 3 — **passed**:
  `lint-frontmatter.py` on both, exit 0. Step 4 (`pre-commit run
  --all-files`) runs once at the end of the run; both rules are under
  `deferred` in `copilot/.source-hashes.json`, so no stamp is due.
- **Deferred**: step 5 needs the deployed payload: from the main
  checkout after the landing, `link-claude.ps1 -SkillGroups
  workflow,social,meta`, then the two diffs.
- **Deviations**: none. D-1 went under the table as its own bold-led
  paragraph, the form § "`~/.claude.json` is runtime state" uses, and
  D-2 as its own paragraph after the exit-code one, which is unchanged.
- **Needs**: the landing — `link-claude.ps1` deploys both rules, then
  step 5's diffs.
