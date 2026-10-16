# Handoff: decide the idle-compaction setting

- **Audit run**: 2026-10-16
- **Source**: `claude-code`
- **Window**: floor `fbe20e00` (2026-10-06, the 2026-10-06 run's head) →
  head `c017428c` (2026-10-16)
- **Covers recommended actions**: 6
- **Kind**: a **decision** on one Claude Code setting for this machine,
  then at most a one-key edit to `claude/settings.json`, machine-wide
  once deployed with `-Force`. The decision is the user's:
  `/drift-update` puts it back to the user rather than executing it.
- **Target**: `claude/settings.json`

## The problem

Claude Code 2.1.299 added idle compaction, on by default: a terminal
conversation of 200K or more tokens, left idle about 54 minutes, is
compacted before its one-hour prompt cache expires. `claude/settings.json`
sets nothing for it, so every session on this machine takes the default
without anyone having chosen it.

## Evidence

**Changelog**, `anthropics/claude-code` `CHANGELOG.md` at head
`c017428c8c27e604840435048d5bce6a9a22c040`, verbatim:

> ## 2.1.299
>
> - Added idle compaction in the terminal: a 200K+ token conversation
>   left idle for about 54 minutes is compacted before its one-hour
>   prompt cache expires, so your next message doesn't reprocess it all
> - Added `CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS` to change idle
>   compaction's 200K-token minimum; `"idleCompaction": false` in
>   settings.json turns it off. Both need v2.1.290 or later

> ## 2.1.302
>
> - Added an `Idle compaction` row to `/config` for turning idle
>   compaction off or back on; the notices shown after an idle compaction
>   now say how to turn it off

**Docs.** https://code.claude.com/docs/en/settings came back whole on
2026-10-16 with no entry for either key, so the changelog is the only
source.

**The payload today.** `claude/settings.json` sets `attribution`,
`hooks`, `enabledPlugins`, `skillOverrides`, `extraKnownMarketplaces`,
`modelSettings`, `bashOutputMaxChars`, `cleanupPeriodDays`,
`autoUpdatesChannel`, `permissions`, `env` and `deniedMcpServers`. No
`idleCompaction`, and `env` holds only `ENABLE_CLAUDEAI_MCP_SERVERS`.

**What a compaction costs here**, from the payload's own record:

- `.claude/rules/editing-rules.md`: "A rule's whole body is paid again
  after each compaction, at the next match, not once a session"
  (measured 2026-09-30).
- `claude/hooks/offer-handoff.sh` tells Claude after a compaction that
  "A compaction summary keeps conclusions and drops detail, most often
  what was not checked and which claims were observed rather than
  inferred." Whether it fires after an idle compaction is brief 04's
  open question.

What it saves, per the changelog: after the cache has expired, "your
next message doesn't reprocess it all".

## The decision

Put to the user:

- **A — keep the default, on.** No edit.
- **B — turn it off in the payload:** `"idleCompaction": false` at the
  top level of `claude/settings.json`.
- **C — move its threshold:** `CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS` in
  `claude/settings.json`'s `env`.
- **D — leave the payload alone and use `/config`'s Idle compaction
  row** (2.1.302) on this machine. Which file that row writes was not
  checked. If it writes `~/.claude/settings.json`, a key only the
  target holds survives `-Force` (`.claude/rules/deploy-scripts.md`).

## What to change

On B, add the key at the top level of `claude/settings.json`. On C, add
the variable to its `env` object, keeping `ENABLE_CLAUDEAI_MCP_SERVERS`.
On A or D, nothing in the payload.

## Constraint on the fix

- Cite the changelog for either key, with its version: the settings
  docs did not list them on 2026-10-16.
- `claude/settings.json` deploys as a key-level merge in which a shared
  key is replaced whole (`.claude/rules/deploy-scripts.md`), so an
  `env` edit replaces the deployed `env` entirely, and reaches
  `~/.claude/settings.json` only with `-Force`, from the main checkout.

## Verification

On B:

1. `grep -n '"idleCompaction": false' claude/settings.json`
2. From the main checkout, in pwsh,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`,
   then `grep -n 'idleCompaction' ~/.claude/settings.json`.
3. In a fresh terminal session, `/config`'s Idle compaction row reads
   off.

On C:

1. `grep -n 'CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS' claude/settings.json`,
   with `ENABLE_CLAUDEAI_MCP_SERVERS` still beside it.
2. The `-Force` deploy as in B, then the same grep against
   `~/.claude/settings.json`.

Either way:

3. `pre-commit run --all-files`.

## Sequencing note

Brief 02 may edit `claude/settings.json` too. If both decisions change
it, apply one after the other and deploy once, after the second.
Independent of brief 04, whose header edit describes Claude Code
whatever this machine chooses.

## Provenance

Recommended action 6 of the 2026-10-16 `/drift-audit claude-code` run,
flag-only, from its MCP / tooling / CLI bucket. The run read
`claude/settings.json` in its harness scan and fetched the settings
docs page whole.
