# Handoff: add idle compaction to offer-handoff's header

- **Audit run**: 2026-10-16
- **Source**: `claude-code`
- **Window**: floor `fbe20e00` (2026-10-06, the 2026-10-06 run's head) →
  head `c017428c` (2026-10-16)
- **Covers recommended actions**: 5
- **Kind**: comment correction in a deployed user-scope hook's header,
  after one claim is confirmed; no behaviour change, and not live until
  `link-claude.ps1` copies it
- **Target**: `claude/hooks/offer-handoff.sh`, header lines 13–15

## The problem

`offer-handoff.sh`'s header names two kinds of compaction: "SessionStart
with matcher "compact" fires after every compaction, auto or manual".
Claude Code 2.1.299 added a third, idle compaction in the terminal, and
the header should name it. Whether the hook fires after an idle
compaction is not yet established, so the claim has to be confirmed
before it is written.

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
2026-10-16, 56.6 KB of raw markdown, with no mention of
`idleCompaction`, idle compaction or `CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS`.
This run did not read the hooks page's SessionStart or PreCompact
sections.

**The header today**, `claude/hooks/offer-handoff.sh:11–19`:

> long enough. PreCompact could not have offered anything anyway: Claude Code
> discards its systemMessage, and its exit-2 stderr reaches only the user, on
> a manual /compact. PostCompact receives the summary and discards its output
> too. SessionStart with matcher "compact" fires after every compaction, auto
> or manual, and its plain stdout joins Claude's context: after a /compact on
> 2.1.291 (2026-10-06), Claude quoted the text back, which it sees prefixed
> "SessionStart:compact hook success:", from a transcript record of type
> attachment, hook_success, written just after the compact_boundary.

**Not established.** The report says the hook "fires on `SessionStart`
matcher `compact` after it too, with its stdout waiting for the next
prompt". No run has seen an idle compaction, and neither the changelog
nor the docs read say which hook events one raises.

## What to change

1. **`claude/hooks/offer-handoff.sh:14–15`**, "fires after every
   compaction, auto or manual": name idle compaction (2.1.299) among the
   compactions the hook fires after, in the form the confirmation below
   supports — a third kind, or a kind of auto compaction if the hook
   input reports it as one.

## Constraint on the fix

- **Confirm first.** Either the hooks docs say an idle compaction raises
  `SessionStart` with source `compact` (read the SessionStart section's
  `source` values and PreCompact's `trigger` values for an idle one), or
  a transcript shows it: an attachment record, `hook_success`, reading
  "SessionStart:compact hook success:" just after an idle compaction's
  `compact_boundary`. If neither confirms it, write that idle compaction
  exists and that whether this hook fires after one is unconfirmed,
  dated, rather than asserting it.
- Header only. The script's behaviour does not change, and nothing in
  it should start handling idle compaction.
- If brief 05 turns idle compaction off on this machine, keep the
  header's mention: it describes Claude Code, not this machine's
  settings.

## Verification

1. `grep -n -i 'idle' claude/hooks/offer-handoff.sh` — the header names
   it, in the confirmed form.
2. `bash tests/hooks/offer-handoff/test-offer-handoff.sh` — passes
   unchanged.
3. `shellcheck claude/hooks/offer-handoff.sh`
4. From the main checkout, in pwsh,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`, then
   `diff claude/hooks/offer-handoff.sh ~/.claude/hooks/offer-handoff.sh`
   — no output.
5. `pre-commit run --all-files`.

## Sequencing note

Independent of brief 05: this records what Claude Code does, and brief
05 decides whether this machine lets it. Neither outcome changes the
other's edit.

## Provenance

Recommended action 5 of the 2026-10-16 `/drift-audit claude-code` run.
The changelog text is exact, from the run's on-disk diff. That the hook
fires after an idle compaction is the audit's inference, which its drift
bullet states as fact; this brief marks it unconfirmed so the fix does
not encode it unchecked.
