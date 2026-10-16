---
status: deferred
priority: 2
needs: [user]
blocked-by: []
reopen-when: the organization's Claude seat is live on the corporate network, or machine-config's claude-login-pin.md picks a route the payload must follow
written: 2026-10-06
---

# Handoff: the payload when the work Claude account arrives

- **Written**: 2026-10-06, from two inbox notes of 2026-10-02 and
  2026-10-05 by VS Code sessions in a client Fabric repo, the first
  updated on that network on 2026-10-05, and from the Claude-target
  turn's transcript, read on this machine. Re-measured against the
  payload at `1a0c5f7`, which held none of it.
- **Folded**: 2026-10-13, an inbox note of 2026-10-12 by a session in
  machine-config reviewing its gateway brief, re-measured against the
  payload at `cabf9c9`.
- **Synced**: 2026-10-15, with machine-config's brief at `5685f27`,
  read in a session that had both repos open, so no note was sent.
- **Reframed**: 2026-10-16, from `claude-code-corporate-network.md`.
  The organization is taking Claude Team, perhaps Enterprise later, so
  the user no longer needs a way around the filter. Agreed that day with
  a machine-config session and approved by the user: the gateway stays
  in machine-config's `docs/handoffs/claude-code-gateway.md`, reframed
  as a project of its own and deferred until it has its own repo; the
  token launcher's removal is its `claude-onsite-removal.md`; and the
  per-folder login pin is its `claude-login-pin.md`. This brief keeps
  what the payload must change.
- **Kind**: two edits, each on its own trigger, the second shaped by
  the route the user picks in `claude-login-pin.md`.

## Why it waits

On the corporate network a filter resets Anthropic's hosts by name, so
Claude Code fails on its sign-in, not its route, and no proxy setting
changes that (`docs/handoffs/declined.md`, 2026-10-06). The
measurements are in
[docs/evidence/user-claude-md.md](../../evidence/user-claude-md.md)
§ "The corporate network, 2026-10-05", under the heading of the
`claude/CLAUDE.md` section that carries the rule, "GitHub Copilot does
not inherit this payload" (2026-10-13).

The organization's seat signs in through those hosts, so its rollout
should open them, though not necessarily for the personal login: a
filter by name cannot tell the two apart, yet the opening is IT's to
scope (reasoned, not measured). Until a session there signs in, the
rule stands, and the fallback there stays VS Code's Claude target on a
Copilot model.

## The corporate-network rule

**On the first trigger, re-measure both logins on that network**, and
correct the rule by what each does:

- **The work seat**: a session signs in and answers there.
- **The personal login**: a `/login` that completes there shows the
  sign-in host passes, and machine-config's `scripts/network-soak.ps1`
  measures `platform.claude.com` beside `api.anthropic.com`.

Then, in one commit:

- Correct `claude/CLAUDE.md` § "GitHub Copilot does not inherit this
  payload" in place: the sentence that Claude Code fails at sign-in on
  the corporate network goes, or names the login that still fails.
- Add a dated entry under that heading in
  [docs/evidence/user-claude-md.md](../../evidence/user-claude-md.md),
  leaving the 2026-10-05 one as it stands.
- Deploy with
  `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`.

With it, write a note to `~/handoff-inbox/machine-config/` naming each
login's outcome separately, since the personal one triggers
`claude-onsite-removal.md`, and correct this repo's auto-memory
`sole-reader-of-the-payload`, which has Copilot as the fallback on that
network. A session there that sees an outcome first `/learn`s it to
both inboxes.

## WebFetch behind a gateway

This matters again if the seat reaches Anthropic through a gateway, the
organization's Claude apps gateway among them, while the filter keeps
resetting `api.anthropic.com`.

Claude Code checks each WebFetch domain with `api.anthropic.com` even
when its model traffic goes elsewhere, unless `skipWebFetchPreflight` is
`true` (code.claude.com `network-config`, read 2026-10-02). On that
network the check would fail whenever the filter resets that host, with
`Unable to verify if domain ... is safe to fetch`, while chat goes on
working. Not observed: the 2026-10-05 turn made no WebFetch call. The
fix is a key in `claude/settings.json`, which costs Anthropic's domain
blocklist, and a settings change takes the user's yes.

## The payload side of a login pin

**Waits on machine-config's `claude-login-pin.md`**, which holds the
mechanism, its measurements and the user's pick of route. One
measurement shows what is at stake: on 2026-10-16 the user switched a
client repo's VS Code window to the work seat from the extension's
account menu, and the switch rewrote the shared
`~/.claude/.credentials.json`, so every new session on the machine
started on the work seat, personal repos included. No settings file can
pin the account or guard it: project and local settings ignore
`CLAUDE_CONFIG_DIR`, and `forceLoginOrgUUID` is enforced only from a
managed source (code.claude.com `env-vars` and `settings-reference`,
read 2026-10-16).

What the payload then needs, by route:

- **On either route**, a section in `claude/CLAUDE.md` beside "Azure CLI
  state is per tenant", saying how the login is pinned and what a wrong
  one looks like; and perhaps a `SessionStart` hook that warns when a
  session's account is not its folder's, since a hook runs on every
  launch path, the extension, `claude` in a terminal and each
  `claude -p` child alike. The hook reads the folder-to-identity map
  that machine-config generates into `~/.config`, so the payload holds
  no identity. `claude auth status` reports `email`, `orgId`, `orgName`
  and `subscriptionType`, and with every connection refused it printed
  the same fields in the same 2.5 to 2.7 s (2.1.293, measured
  2026-10-16), which is too slow for every session start; `.claude.json`
  in the config directory is fast to read, but an internal format.
- **On a second config directory**, the docs' own pattern for work and
  personal accounts side by side (code.claude.com `authentication`, read
  2026-10-16), the payload pays more:
  - `scripts/link-claude.ps1` hard-codes `$UserScopeDir` and
    `$GlobalMcpConfig` to `~/.claude` and `~/.claude.json`, so
    `-GlobalMcp` skips any other directory, which then starts without
    `microsoft-learn-mcp`; and root `CLAUDE.md` § "Commands" deploys to
    one directory.
  - `claude/settings.json`'s hook commands resolve `$HOME/.claude/...`
    (`.claude/rules/deploy-scripts.md`), so the second directory runs
    the first one's hooks.
  - `find-session.py`, `folder-sessions.py`, and `land`'s
    `never-prompted.sh` and `placed-elsewhere.sh` read
    `CLAUDE_CONFIG_DIR`, so each sees one directory's transcripts.
  - The payload's prose names `~/.claude/rules/...` by path.
- **On a work token**, nothing beyond the section above.

If IT deploys `forceLoginOrgUUID` to this laptop, the pin is moot, as
`claude-login-pin.md` says: Claude Code would then refuse the personal
login at startup in every folder.

## Where it lands

The rule lands on the first trigger, and the WebFetch key on its tell,
on the user's yes, deployed with
`./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`.
The brief is deleted once the rule and the pin's side have both landed,
or the pin's brief has closed on a route that needs nothing here. A
WebFetch case still open then becomes a brief of its own.

## Not checked

- Either login on that network since 2026-10-05.
- Whether a session already running moves to the work seat at its next
  token refresh, after another window's switch.
- The WebFetch check there, on any route.
- `claude auth status` on an expired token, or a connection that hangs
  rather than refuses.

## Scrubbing

This repo is public. The client repo is cited by kind, and the
organization and its network are named nowhere. Both notes and the
transcript were raw.

The work account's email, organization name and ID go in no file here
either: write "the work seat".

## Re-measure before acting

- Whether the hosts still reset there, tried more than once, since
  `api.anthropic.com` passes in bursts. Every try on 2026-10-05 failed
  `curl: (35)`:

  ```bash
  curl -sS -o /dev/null -w '%{http_code}\n' https://platform.claude.com
  ```

- Which account the stored login is, printing no identity:

  ```bash
  claude auth status | jq -b -c '{authMethod, subscriptionType, configDirectory}'
  ```

- Whether `claude-login-pin.md` has picked a route, and where its map
  lives.
