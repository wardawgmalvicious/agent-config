# Handoff: decide onFailure for the two guard hooks

- **Audit run**: 2026-10-16
- **Source**: `claude-code`
- **Window**: floor `fbe20e00` (2026-10-06, the 2026-10-06 run's head) →
  head `c017428c` (2026-10-16)
- **Covers recommended actions**: 2 and 3
- **Kind**: a **decision** on how this payload's two PreToolUse guard
  hooks fail, then the edits it implies: on a block, `claude/settings.json`
  (machine-wide once deployed with `-Force`), the hooks README and the
  hooks' headers; on the default, the README alone. The decision is the
  user's: `/drift-update` puts it back to the user rather than executing
  it.
- **Target**: `claude/settings.json` (`hooks.PreToolUse`, lines 17–36),
  `claude/hooks/README.md` (lines 25–48); on a block also
  `claude/hooks/identity-guard.sh` (lines 80–97) and
  `claude/hooks/security-reviewer-memory-scope.sh` (lines 10–14, 34–41)

## The problem

Both guard hooks fail open by design, and the hooks README gives the
reason: "Fails open by design: a broken hook must not wedge every commit
on the machine". Until 2.1.295 open was also the only behaviour Claude
Code had for a hook that crashed, timed out or could not start. Now a
settings entry can set `"onFailure": "block"`, so open is a choice the
payload makes by leaving the key unset, and nothing records that choice
or why.

## Evidence

**The mechanism.** Brief 01 quotes the changelog and the hooks docs. In
short: with `"onFailure": "block"` on a command hook, a failure to
start, an exit other than 0 or 2, a timeout or invalid output does what
exit 2 does on that event, and the default is `"continue"`. On
`PreToolUse`, exit 2 refuses the call. On `PostToolUse` the tool has
already run, and exit 2 hands stderr back to Claude.

**The wiring**, `claude/settings.json:17–36`:

```json
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/hooks/security-reviewer-memory-scope.sh"
          }
        ]
      },
      {
        "matcher": "Bash|PowerShell",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/hooks/identity-guard.sh"
          }
        ]
      }
    ],
```

`identity-guard.sh` is wired on `PostToolUse` `Bash|PowerShell` too
(`:47–55`). No entry sets `onFailure` or `timeout`; this run did not
read the default hook timeout.

**What each hook does when it cannot check**, read from the hooks on
2026-10-16 while this brief was written:

- **`identity-guard.sh`** runs on every Bash and PowerShell call, but
  "a non-git command is rejected by a bash pattern before jq runs"
  (`:74–75`) and exits 0. On a `git commit` or `git push` whose input jq
  cannot read, or with jq missing, it exits 1, "allow unscanned, and say
  so" (`:93–97`; `not_scanned` at `:118–121`). Its header, `:80–84`:
  "Failure side: OPEN. … a broken repo state or a missing tool lets the
  call through rather than wedging every commit on the machine. The
  tests in tests/hooks/identity-guard/ are what make that acceptable".
- **`security-reviewer-memory-scope.sh`** runs on every Edit and Write
  in every session, the main one included. Its first jq call (`:47`)
  comes before its agent-type check (`:49–53`), so input jq cannot read
  exits 1 (`unreadable`, `:38–41`) whoever the caller is. It runs under
  `set -euo pipefail` (`:16`).
- Both are started as `bash $HOME/.claude/hooks/<name>.sh`, so a bash
  that will not start, or a deployed script that is missing, fails
  every call of their matchers alike.

**The machine.** `claude/CLAUDE.md` § "Local environment": "A Git Bash
spawn costs ~60 ms, ~0.5 s once `bash.exe` degrades, until a reboot …
Forks look hung, killed at 120 s". The report reads that degradation as
what would turn a block into a wedged session.

**A second layer.** `identity-guard.sh` also runs as a git hook from
`.pre-commit-config.yaml`, at commit, message and push, whoever commits
(`.claude/rules/hooks-and-agents.md`). Its failure side in that mode is
separate: "in git-hook mode a 1 would block" (`:95–96`). `onFailure`
touches only the Claude Code entries.

**The README today**, `claude/hooks/README.md:42–48`:

> No denylist means
> no check, silently. Fails open by design: a broken hook must not wedge
> every commit on the machine, and
> [tests/hooks/identity-guard/](../../tests/hooks/identity-guard/) is
> what makes that acceptable. Open is not silent where the scan never
> ran: with jq missing or unable to read the input, the call proceeds
> under a `hook error` notice saying it was not scanned.

and, for `security-reviewer-memory-scope.sh`, `:30–31`: "Requires
[jq](https://jqlang.org); input it cannot read allows the call under a
`hook error` notice saying so."

## The decision

Per hook, put to the user:

- **A — both on the default.** No settings change. The README records
  that `onFailure` exists and why it stays unset: each hook runs on
  every call of its matcher, so blocking on failure would turn one
  broken jq, a missing deployed script or a stalled bash into every
  Edit and Write, or every Bash and PowerShell call, refused across the
  machine.
- **B — `"onFailure": "block"` on `identity-guard`'s PreToolUse entry
  only.** A jq failure then refuses only `git commit` and `git push`,
  the calls the guard exists for, since other commands exit 0 before
  jq. A bash that will not start, a missing script or a timeout refuses
  every Bash and PowerShell call.
- **C — block on both.** B, plus every Edit and Write on the machine
  refused whenever `security-reviewer-memory-scope.sh` cannot read its
  input or cannot run.

Setting the key on `identity-guard`'s PostToolUse entry changes only
what Claude is told after a failure: the command, and any commit, has
already run.

## What to change

Once the user has decided:

1. **`claude/settings.json`** — on B or C, add `"onFailure": "block"` to
   each chosen hook object, the one holding `"type": "command"`, and
   nothing else. On A, no change.
2. **`claude/hooks/README.md`**, the paragraph at `:42–48` quoted above
   — say that `onFailure` exists (2.1.295), which side each hook takes,
   and why. On B or C, the clauses that say a call proceeds unscanned
   (`:46–48` for identity-guard, `:30–31` for the memory-scope hook)
   change to say the call is refused, for whichever hook was switched.
3. **On B or C only**, the header of each switched hook:
   `identity-guard.sh:80–97` ("Failure side: OPEN", and exit code 1,
   "allow unscanned"), `security-reviewer-memory-scope.sh:10–14` and
   `:34–37` ("the same fail-open side as before"). On A both headers
   stay true and are left alone.

## Constraint on the fix

- The decision is the user's. Brief 01's rule text documents the key;
  it does not choose for this payload.
- Under B or C, the exit-1 "allow unscanned" paths become refusals.
  That is the point of choosing block, not a defect to code around.
- `claude/settings.json` deploys as a key-level merge in which a shared
  key such as `hooks` is replaced whole (`.claude/rules/deploy-scripts.md`),
  so an edit reaches `~/.claude/settings.json` only with `-Force`, from
  the main checkout.

## Verification

On A:

1. `grep -n 'onFailure' claude/hooks/README.md` — the record and its
   reason.
2. `grep -c 'onFailure' claude/settings.json` — `0`.

On B or C:

1. `grep -n '"onFailure": "block"' claude/settings.json` — one hit per
   chosen entry.
2. `bash tests/hooks/identity-guard/test-identity-guard.sh` against the
   repo copy.
3. From the main checkout, in pwsh,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`;
   then `grep -n 'onFailure' ~/.claude/settings.json`, and the
   identity-guard tests again against the deployed copy
   (`.claude/rules/hooks-and-agents.md`).
4. One cold probe that the installed CLI honours the key: a fresh
   `claude -p` session given a scratch `--settings` file whose
   PreToolUse `Bash` hook names a script that does not exist, with
   `"onFailure": "block"`. The docs' message for that case reads
   `failed; blocking because onFailure is "block"`, and the command
   must not run. Without the key, the same call runs.

Either way:

5. `pre-commit run --all-files`.

## Sequencing note

After brief 01, which puts the mechanism in the rule, and not bundled
with it: a grep verifies that one, while this one waits on the user and
is verified against the hooks. Brief 05 may edit `claude/settings.json`
too. If both decisions change it, apply one after the other and deploy
once, after the second.

## Provenance

Recommended actions 2 and 3 of the 2026-10-16 `/drift-audit
claude-code` run, whose harness scan read `claude/settings.json`, the
hooks README and the hooks. The per-hook failure paths under Evidence
were read from the hooks while this brief was written, the same day.
