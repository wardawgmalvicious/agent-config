---
status: deferred
priority: 3
needs: [user]
blocked-by: []
reopen-when: IT answers on Anthropic's hosts for the corporate network, or WebFetch fails its domain check in a Claude-target session there
written: 2026-10-06
---

# Handoff: Claude Code on the corporate network waits on IT

- **Written**: 2026-10-06, from two inbox notes of 2026-10-02 and
  2026-10-05 by VS Code sessions in a client Fabric repo, the first
  updated on that network on 2026-10-05, and from the Claude-target
  turn's transcript, read on this machine. Re-measured against the
  payload at `1a0c5f7`, which held none of it.
- **Kind**: a decision, the user's, parked until IT answers. Nothing is
  drafted, and nothing here is worth building before that answer.

## Why it waits

On the corporate network a filter resets Anthropic's hosts by name, so
Claude Code fails on its sign-in, not its route, and no proxy setting
changes that (`docs/handoffs/declined.md`, 2026-10-06). The
measurements, and the rule that carries them into `claude/CLAUDE.md`,
are in [copilot-payload-retirement.md](copilot-payload-retirement.md)
§ "The corporate network, 2026-10-05"; once that brief lands, they are
in `docs/evidence/user-claude-md.md`.

Asking IT to allow those hosts comes first. The filter reset every
Anthropic name it was shown, which makes a deliberate block likely, and
routing around a deliberate block is the organization's call, not a
technical one.

## What the user decided, 2026-10-02

Nothing billed per token. The Copilot Business seat is already paid
monthly, and VS Code's Claude target on a Copilot model bills against it
and sends model traffic only to GitHub's hosts, so that target is the
fallback on that network. It answered there on 2026-10-05. A gateway is
parked as a possible project, not a need.

Two things seen on 2026-10-05 bear on that, read from the turn's
transcript on this machine on 2026-10-06 (the retirement brief's § "How
it graded"):

- **The seat has a monthly quota.** At 18:19:48 UTC VS Code's proxy
  answered `402` `quotaExceeded`, "You have exceeded your monthly
  quota". 195 answers on the same model followed; whether overage
  billing or something else let them through was not traced.
- **The target's Copilot group has no Opus**: Claude Sonnet 5.5, Claude
  Sonnet 5 and Claude Haiku 4.5, by the Agent Host log as a session there
  read it.

## What is left if IT keeps the block

- **A long-lived token**, researched 2026-10-05 from code.claude.com
  `authentication`, not tried. `claude setup-token` prints a one-year
  OAuth token for `CLAUDE_CODE_OAUTH_TOKEN`, billed to the claude.ai
  plan, not per token. Claude Code never refreshes it, so the sign-in
  hosts stop mattering and only `api.anthropic.com` is left, which let 6
  of 7 of Claude Code's model requests through on 2026-10-05. It carries
  model requests only: no Remote Control and no claude.ai connectors. It
  ranks above the `/login` credential, so one set at User scope applies
  on every network. Minting it takes the `/login` browser flow, so it is
  done off that network, and it works only through the filter's gaps, so
  the point about IT holds for it too. Machine-config would set the
  variable, as it sets the PATs: a note to its inbox, not an edit here.
- **A gateway the user runs**, through `ANTHROPIC_BASE_URL`, carries
  inference only: the docs list `/v1/messages` and a few optional calls
  as what a gateway receives, not sign-in or refresh, so a plan login
  still fails there, and fast mode's availability check calls
  `api.anthropic.com` directly. It is a server to host where that network
  reaches it, kept in step with Claude Code releases. Inferred from
  code.claude.com `llm-gateway` and `llm-gateway-protocol`, read
  2026-10-02.
- **Ruled out on 2026-10-02**, as billed per token: Microsoft Foundry, on
  an Azure subscription, and Anthropic's `claude gateway`, which also
  stops a signed-in Claude Code at startup wherever it is unreachable.

## WebFetch in the Claude target

Claude Code checks each WebFetch domain with `api.anthropic.com` even
when its model traffic goes elsewhere, unless `skipWebFetchPreflight` is
`true` (code.claude.com `network-config`, read 2026-10-02). On that
network the check would fail whenever the filter resets that host, with
`Unable to verify if domain ... is safe to fetch`, while chat goes on
working. Not observed: the 2026-10-05 turn made no WebFetch call. The
fix is a key in `claude/settings.json`, which costs Anthropic's domain
blocklist, and a settings change takes the user's yes.

## Where it lands

Nothing until IT answers, or the tell above is seen.

- IT allows the hosts: this brief is deleted, with that recorded.
- IT keeps the block: the user picks between the Claude target alone, the
  token and a gateway. The token is a note to machine-config's inbox; a
  gateway is a project of its own. **Assuming the block holds, a note
  scoping the gateway was drafted to machine-config's inbox on
  2026-10-07** (`2026-10-07-claude-code-gateway.md`), as the search for a
  solution; this brief stays deferred until IT answers.
- The WebFetch tell is seen: `skipWebFetchPreflight` goes into
  `claude/settings.json` on the user's yes, deployed with
  `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`.

## Not checked

- What let 195 answers through after the `402`.
- The token, the gateway and the Claude target's WebFetch, on that
  network or anywhere.

## Scrubbing

This repo is public. The client repo is cited by kind, and the
organization and its network are named nowhere. Both notes and the
transcript were raw.

## Re-measure before acting

- Whether the hosts still reset there, tried more than once, since
  `api.anthropic.com` passes in bursts. Every try on 2026-10-05 failed
  `curl: (35)`:

  ```bash
  curl -sS -o /dev/null -w '%{http_code}\n' https://platform.claude.com
  ```

- The code.claude.com pages above, for the token's lifetime and what a
  gateway receives.
