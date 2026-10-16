# Handoff: document hook onFailure in coding-bash.md

- **Audit run**: 2026-10-16
- **Source**: `claude-code`
- **Window**: floor `fbe20e00` (2026-10-06, the 2026-10-06 run's head) →
  head `c017428c` (2026-10-16)
- **Covers recommended actions**: 1
- **Kind**: correction to a user-scope coding rule that loads on every
  `*.sh` file in every repo once deployed; prose only, no hook or
  settings change
- **Target**: `claude/rules/coding-bash.md`, § "Claude Code hooks",
  lines 251–265

## The problem

`coding-bash.md` says a hook's crash fails open, as a fact of Claude
Code: "Any other non-zero is reported as a hook error and the call
proceeds — so a crash fails **open**." Since 2.1.295 that is only the
default. A command or HTTP hook entry can set `"onFailure": "block"`,
and then a hook that cannot start, exits with a code other than 0 or 2,
times out or prints invalid output does what exit 2 does on that event.

Two neighbouring sentences move with it. The rule's advice that "a
deliberate open whose check never ran exits 1" holds only on the
default: under `"block"` an exit 1 is a failure, and blocks. And 2.1.299
added a Windows case to the rule's paragraph on failures before the hook
runs.

## Evidence

**Changelog**, `anthropics/claude-code` `CHANGELOG.md` at head
`c017428c8c27e604840435048d5bce6a9a22c040`, verbatim:

> ## 2.1.295
>
> - Added `onFailure: "block"` for command and HTTP hooks: a hook that
>   can't start, times out, or exits with an unexpected code blocks the
>   action instead of letting it through

> ## 2.1.299
>
> - Windows: Fixed PreToolUse and PermissionRequest hooks that set no
>   shell failing open when Git for Windows isn't installed; a guard that
>   fails now blocks the call

**Hooks docs**, read 2026-10-16:
https://code.claude.com/docs/en/hooks#block-the-action-when-a-hook-fails

The page is 270,765 characters, so WebFetch handed its first 100,000 to
its fetch model, which was asked to quote verbatim. Re-read the section
before quoting it into the rule. As returned:

> On most events, when a hook fails or times out, Claude Code still
> carries out the action, so a policy hook with a wrong path or a
> crashing script lets everything through. To block the action instead,
> set `"onFailure": "block"` on a `command` or `http` hook. The default
> value is `"continue"`. Requires Claude Code v2.1.295 or later.

> With `"block"` set, a failure does what exit code 2 does on that event,
> except on `PermissionRequest`, where it denies the request.

The page's list of what counts as a failure: a command hook that can't
start; "Exit code other than 0 or 2: counts for a command hook even if
it printed JSON that allows the action, such as `permissionDecision:
"allow"`. To return a JSON decision, exit 0"; an HTTP error; a timeout;
invalid output, where "Plain-text stdout from a command hook isn't a
failure". The field has no effect on `Stop`, `SubagentStop`,
`TaskCompleted` and `TeammateIdle` hooks, nor on command hooks set
`async` or `asyncRewake`. The fetch named only `command` and `http`
hooks as taking it.

**The rule today**, `claude/rules/coding-bash.md:251–265`:

> **Enforcement hooks** (PreToolUse) use `set -euo pipefail` and signal
> through exit codes: `0` allows, `2` blocks with stderr fed back to Claude
> as the rejection reason. Any other non-zero is reported as a hook error
> and the call proceeds — so a crash fails **open**. Decide deliberately
> which side a failure should land on, and say so in the header. **A
> deliberate open whose check never ran exits 1, not 0**: Claude Code shows
> a non-zero exit's first stderr line as a `hook error` notice, while
> stderr from an exit 0 reaches only the debug log (hooks docs, read
> 2026-09-27), so an exit-0 abstention reads as a clean pass.
>
> **A failure before the hook runs now blocks.** Since 2.1.288, when
> matching a PreToolUse or PermissionRequest hook fails, or the tool's
> input cannot be serialized to JSON, the call is blocked rather than the
> hook skipped; the changelog says so and the hooks page does not
> (2026-10-07). The script's own crash still fails open, as above.

## What to change

All three in § "Claude Code hooks" of `claude/rules/coding-bash.md`.

1. **Lines 253–255**, "Any other non-zero is reported as a hook error
   and the call proceeds — so a crash fails **open**. Decide
   deliberately which side a failure should land on, and say so in the
   header." Say that open is the default, `"continue"`, and that
   `"onFailure": "block"` on the hook's settings entry (2.1.295, command
   and http hooks) turns a failure to start, an exit other than 0 or 2,
   a timeout or invalid output into what exit 2 does on that event. The
   "decide deliberately" sentence gains its mechanism: the side is set
   in settings, and the header says which and why.
2. **Lines 255–259**, "**A deliberate open whose check never ran exits
   1, not 0**". Add that this holds on the default only: under
   `"onFailure": "block"` an exit 1 is a failure and blocks.
3. **Lines 261–265**, "**A failure before the hook runs now blocks.**"
   Add 2.1.299's case: on Windows, a PreToolUse or PermissionRequest
   hook that sets no `shell` now blocks when Git for Windows is absent,
   where it failed open before. The paragraph's last sentence, "The
   script's own crash still fails open, as above", gains "unless its
   entry sets `onFailure`" or words to that effect.

Date each new claim: hooks docs read 2026-10-16, changelog 2.1.295 and
2.1.299.

## Constraint on the fix

- Document the mechanism, not this payload's choice. Whether
  `identity-guard` and `security-reviewer-memory-scope` should set the
  key is brief 02's decision, and this rule loads in every repo.
- Claim nothing about `onFailure` on `mcp_tool`, `prompt` or `agent`
  hooks: the page, as fetched, names only `command` and `http`.
- Keep the 2.1.288 sentence. Matching or serializing that fails before
  the hook runs is a different case, and still true.

## Verification

1. `grep -n 'onFailure' claude/rules/coding-bash.md` — hits in the
   enforcement paragraph and in the paragraph opening "A failure before
   the hook runs".
2. `grep -n '2\.1\.299' claude/rules/coding-bash.md` — the Windows case.
3. `grep -n 'fails \*\*open\*\*' claude/rules/coding-bash.md` — any
   surviving hit reads as the default, not as the only behaviour.
4. `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/coding-bash.md`
5. From the main checkout, in pwsh,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`, then
   `diff claude/rules/coding-bash.md ~/.claude/rules/coding-bash.md` —
   no output. `claude/rules/` deploys by copy, so the edit is not live
   until then.
6. `pre-commit run --all-files`.

## Sequencing note

Do not bundle with brief 02. This one documents a mechanism in a rule
every repo loads, and a grep verifies it; brief 02 decides whether this
payload's two guard hooks use it, and is verified against the hooks.
Different verification, different blast radius. Landing this one first
gives brief 02's README edit a rule to point at.

## Provenance

Recommended action 1 of the 2026-10-16 `/drift-audit claude-code` run.
The changelog bullets come from the run's on-disk two-ref diff of a
blobless clone, so they are exact. The docs quotes come from the run's
Phase 3 drill through WebFetch's model, and the run read only the
page's first 100,000 characters.
