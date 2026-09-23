# Handoff: the hooks pick their jq wrapper with `command -v`, and fail open when it resolves but cannot run

- **Written**: 2026-09-22, from the inbox note
  `2026-09-17-hooks-fail-open-when-timeout-is-blocked.md`, filed by a
  `machine-config` session diagnosing a Defender ASR block on Git Bash.
  Re-verified against this repo's payload and against the deployed copies
  2026-09-22 before this brief was written.
- **Source notes deleted** 2026-09-22, with the user's explicit approval,
  once this brief carried their content — so this file and `git log` are
  now the only record of them.
- **Kind**: one code change to `claude/hooks/identity-guard.sh` plus the
  same change to three sibling hooks, and **one decision** — whether the
  identity guard should fail *closed* when it cannot parse its input.
  Deploys by **copy**, so nothing is live until `link-claude.ps1` runs.
- **Status**: **Open, nothing landed.** The defect is confirmed present
  in all four hooks and in all four deployed copies. The machine state
  that triggers it is **not reproduced here** — see Evidence.
- **Run in**: this repo. The hook suite in `tests/hooks/identity-guard/`
  is the one machine-checkable suite in the repo and must be run twice —
  against the repo copy and again against the deployed copy after the
  link script.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The defect

Four hooks select their jq wrapper the same way:

```bash
JQ=(jq)
if command -v timeout >/dev/null 2>&1; then JQ=(timeout 5 jq); fi
```

**`command -v` proves the file is on `PATH`, not that it runs.** On a
machine where Git is installed user-scope, Defender's ASR rule *"Block
use of copied or impersonated system tools"*
(`C0033C00-D16D-4114-A5A0-DC9B3A7D2CEB`) blocks Git's
`usr\bin\timeout.exe` — and `sort.exe` and `find.exe` with it. Measured
by the filing session:

```text
/usr/bin/bash: line 1: /usr/bin/timeout: Permission denied
timeout rc=126
```

Every `"${JQ[@]}"` call then exits 126 and jq never runs.

**In `identity-guard.sh` that failure is swallowed.** Lines 113–116, read
here 2026-09-22:

```bash
JQ=(jq)
if command -v timeout >/dev/null 2>&1; then JQ=(timeout 5 jq); fi
RAW=$(printf '%s' "$INPUT" | "${JQ[@]}" -r \
    '[.hook_event_name, ...] | ... | @tsv' 2>/dev/null) || exit 0
```

`|| exit 0` is the whole problem. **The guard allows every commit and
every push without scanning, and reports nothing.** Its output is
byte-identical to a clean pass.

## The blast radius is narrower here and wider everywhere else

This is the part the note could not see, and it changes where the
urgency sits.

**In this repo the guard survives**, because it has a second entry point.
`identity-guard.sh` line 93 branches on `--git-hook`, which is how
[`.pre-commit-config.yaml`](../../../.pre-commit-config.yaml) invokes it
at the commit, message and push stages. That path sets `EVENT` and `CMD`
directly from the argument and **never touches jq**, so an unusable
`timeout` cannot reach it. A commit here is still scanned.

**Everywhere else it does not.** The Claude Code hook path is the *only*
guard in every repo that has not run `pre-commit install` — which is
every client repo on this machine. There the jq path is the whole gate,
and it fails open.

So the ordering that matters is: this is not an emergency in
`agent-config`, and it is a silent, total bypass in the repos where the
denylist actually has names to catch.

**The other three hooks carry the same selection** —
`log-instructions-loaded.sh:28`, `log-skill-invocations.sh:19`,
`security-reviewer-memory-scope.sh:25`. The first two are observability
and losing them is cheap. The third is an enforcement hook and is not.

**One correction to the note.** It says
`security-reviewer-memory-scope.sh`'s own comment suggests it "likely
fails loudly rather than open — unverified". The comment says the
opposite, in as many words: a timeout "trips errexit and the hook exits
non-zero, which Claude Code reports as a hook error and **allows the
call** — the same fail-open path any other jq failure already takes
today". So that hook fails open too, deliberately and with its reasoning
recorded. The decision below therefore applies to it as well.

## The change

**Fall back rather than probe.** The probe is answering the wrong
question, and no probe can answer the right one short of running the
thing:

```bash
JQ=(timeout 5 jq)
"${JQ[@]}" --version >/dev/null 2>&1 || JQ=(jq)
```

Or, without the extra spawn, retry on the exit status that means *could
not execute* — 126 (found, not executable) and 127 (not found) — since
jq's own failures use other codes.

**Spawn economy is a real constraint here and argues for the retry
form.** `claude/CLAUDE.md` measures a process spawn at ~0.4 s on this
machine, and `security-reviewer-memory-scope.sh`'s own comment calls
itself "the highest-frequency jq call here" because it fires on every
Edit and Write. A probe-at-start-up costs one extra spawn per hook
invocation on the healthy path; a retry costs nothing unless the failure
actually happens. Prefer the retry.

## The decision, which is the part that is not mechanical

**Should `identity-guard` fail closed when jq produces no output at
all?**

Today `|| exit 0` treats *"could not parse the hook input"* the same as
*"this is not a git command"*. For a guard those are different answers,
and only one of them is safe to assume.

The case for closed: this hook exists because a pushed identity leak
cannot be fixed forward — `refs/pull/N/head` pins every commit a PR
touched, and GitHub serves unreachable objects by SHA until it collects,
on no schedule anyone controls. `claude/CLAUDE.md` is explicit that
delete-and-recreate is the only immediate remedy. A guard that silently
abstains on that class of failure is worth less than its reputation.

The case for open: a hook that exits non-zero on a machine where jq is
merely slow blocks every commit in every session, with an error most
readers will resolve by removing the hook. `identity-guard.sh` line 108
already has `command -v jq >/dev/null 2>&1 || exit 0` — an existing,
deliberate fail-open for jq being absent entirely — so flipping only the
*unparseable* case would leave two adjacent behaviours with opposite
answers and no comment saying why.

**A middle form worth costing:** fail open but **print to stderr**, so
the abstention is visible in the transcript rather than indistinguishable
from a pass. That addresses the actual defect — the silence — without
turning a tooling fault into a commit blocker. It is the author's
recommendation, and it is a recommendation rather than a decision.

## Evidence

| Claim | Status |
| --- | --- |
| All four hooks use `command -v timeout` with no fallback | **Verified here 2026-09-22**, repo copies and deployed copies byte-identical |
| The `--git-hook` path bypasses jq entirely | **Verified here**, `identity-guard.sh:93` |
| `timeout` exits 126 under the ASR rule | **Measured by the filing session**, output quoted; **not reproduced here** |
| The ASR rule applies only to a user-scope Git install | **Relayed**, from Defender log counts (74 blocks vs 0) |
| `security-reviewer-memory-scope.sh` also fails open | **Verified here** from its own comment; the note guessed otherwise |

**The machine state is not reproduced and may not be reproducible on
demand.** The note records that Claude Code has run Git's
`usr\bin\bash.exe` via `CLAUDE_CODE_GIT_BASH_PATH` since 2026-09-17,
because `bin\bash.exe` is blocked by the same rule and `usr\bin\bash.exe`
is not. **Before that the hooks failed visibly**, because bash itself
could not start. So the fix that made hooks work at all is what turned a
loud failure into a silent one — worth saying in any text that lands,
because it means the healthy-looking present state is the symptom.

To check whether this machine is currently in that state:

```powershell
& "$env:LOCALAPPDATA\Programs\Git\usr\bin\bash.exe" -c -l 'timeout 2 true; echo rc=$?'
```

`rc=126` with `Permission denied` means yes. **Run this before landing**
— if the machine is no longer in that state, the change is still correct
(`command -v` still cannot prove executability) but the brief should say
the trigger was not live at landing time.

## Deployment

`claude/hooks/` deploys by **copy**:

```powershell
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force
```

Never bare — see [CLAUDE.md](../../../CLAUDE.md) § Commands. `-Force` is
not strictly required for `hooks/` (the copied directories take repo
content without it; `-Force` is only needed to *delete* a target-only
file), but the standing invocation carries it and diverging here buys
nothing. Confirm the prune held by name afterwards:
`ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid)-'` must be empty.

**The deployed copy keeps executing the previous version until that
runs, and nothing says so.** That is the general hook trap
[CLAUDE.md](../../../CLAUDE.md) records, and it is sharper than usual
here: a half-deployed fix to a *guard* reads as a working guard.

## Verification

- `bash tests/hooks/identity-guard/...` — the suite in
  [tests/hooks/identity-guard/](../../../tests/hooks/identity-guard/),
  run against the repo copy, then again against `~/.claude/hooks/` after
  the link script. [CLAUDE.md](../../../CLAUDE.md) requires both.
- **Add a negative case**, because this is exactly the shape the repo
  keeps being bitten by: a gate firing on nothing looks identical to a
  gate that passes. Put a non-executable `timeout` earlier on `PATH` in a
  throwaway directory, run the hook against input carrying a denylisted
  term, and assert it **blocks**. Without that case the fix is untested
  by construction — the healthy path exercises neither arm.
- `pre-commit run --all-files` clean, which also exercises the
  `--git-hook` path.

## Dependencies

- Blocks nothing and is blocked by nothing. It touches no skill, no
  `paths:` glob and no fixture set, so no activation run and no
  `/test-skill`.
- Adjacent to [bash-snapshot-and-mcp-credential-env.md](bash-snapshot-and-mcp-credential-env.md)
  only in subject — both are about the Bash environment being different
  from what the payload assumes — but they touch different files and
  neither needs the other.
- The decision above is the user's, not the executing session's. Put it
  back rather than picking one, the way a decision-kind brief is handled
  under [README.md](README.md) § "A brief can be a decision rather than
  an edit".
