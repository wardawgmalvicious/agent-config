---
status: deferred
priority: 2
needs: [user]
blocked-by: []
reopen-when: the work config directory machine-config made is signed in to measure against, or the organization's Claude seat is live on the corporate network
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
- **Designed**: 2026-10-16, the payload's share of the per-folder
  login, once the user chose a config directory per account that day.
- **Folded**: 2026-10-17, an inbox note of 2026-10-16 by a machine-config
  session working its `claude-login-pin.md`, re-measured against
  machine-config at `5a0c66c` and its `.claude/rules/claude-accounts.md`:
  the device-policy answer, the work root, the map's format, the
  extension's route and three findings below. machine-config's side
  landed whole that day; the work directory exists, signed out.
- **Kind**: two edits, each on its own trigger: the corporate-network
  rule, and the payload's share of the login pin, built once
  machine-config's side and the measurements below are ready.

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

**The route is a config directory per account**, which the user chose
on 2026-10-16, to build once the work directory is signed in: the docs'
own pattern for work and personal accounts side by side
(code.claude.com `authentication`, read 2026-10-16). No device login
policy will tie this laptop to the organization, as the user, an admin
of its plan, said on 2026-10-16 (machine-config's brief). Folders under
the work root (`config.psd1`'s `WorkRepoRoot`) run under the work
directory, and every other folder, those outside every root included,
under `~/.claude`; a client root joins the work account only by
declaring `ClaudeAccount = 'work'`, and none does. Machine-config's
`claude-login-pin.md` holds the mechanism: which directory each launch
gets, the VS Code profiles, the terminal wrapper, and moving the client
projects' transcripts and memory into the work directory. A VS Code
window gets its account from a profile setting; the process wrapper was
dropped, since on Windows it would have to be a compiled `.exe`, under
which the extension stops following the CLI's directory (extension
2.1.301 code, read by that session).

**The map is a contract with machine-config**, which keeps its format in
`.claude/rules/claude-accounts.md` and bumps `version` on any change a
reader must know about (read 2026-10-17):

- `~/.config/claude-accounts.json`, generated, `version` 1. Each account
  lists `configDir`, `claudeJson` (the `.claude.json` the directory
  uses, so step 1 reads it rather than deriving it), `env` and `orgId`.
- `env` is the exact value a launcher puts in `CLAUDE_CONFIG_DIR`, and
  `null` means leave it unset: setting it, even to `~/.claude`, moves
  `.claude.json` into that directory.
- A folder takes the account of the longest root that is it or contains
  it, case-insensitively, separators folded, on a component boundary;
  no root means `default`.
- `orgId` is `null` until that account is signed in. A reader that meets
  another `version` fails open and says so.

One measurement shows what is at stake: on 2026-10-16 the user switched a
client repo's VS Code window to the work seat from the extension's
account menu, and the switch rewrote the shared
`~/.claude/.credentials.json`, so every session on the machine moved to
the work seat, personal repos included: a new one at its start, and a
running one at its next request, with no restart and the same session
id (a client session's transcript, extension 2.1.301). No settings file can
pin the account or guard it: project and local settings ignore
`CLAUDE_CONFIG_DIR`, and `forceLoginOrgUUID` is enforced only from a
managed source (code.claude.com `env-vars` and `settings-reference`,
read 2026-10-16).
A directory per account keeps a switch inside that directory.

The payload's share, in build order:

1. **Deploy to every account's directory.** `scripts/link-claude.ps1`
   hard-codes `$UserScopeDir` and `$GlobalMcpConfig` to `~/.claude` and
   `~/.claude.json`, so `-GlobalMcp` skips any other directory, which
   then starts without `microsoft-learn-mcp`. It should take every
   directory the map names as user scope, so the default command
   deploys to all of them and none goes stale unseen, and reconcile the
   MCP servers in each one's own `.claude.json`: with
   `CLAUDE_CONFIG_DIR` set, the CLI wrote `.claude.json` and a
   `backups/` folder inside that directory and left `~/.claude.json`
   alone (2.1.293, measured 2026-10-16). Root `CLAUDE.md` § "Commands"
   and `.claude/rules/deploy-scripts.md` follow. It runs before the work
   directory's first session, which then never starts bare.
2. **Hooks.** `claude/settings.json`'s hook commands resolve
   `$HOME/.claude/...` (`.claude/rules/deploy-scripts.md`), so a work
   session runs the personal directory's copies, which one deploy keeps
   identical: keep that. But three hooks keep state at a fixed
   `$HOME/.claude` where it should follow `CLAUDE_CONFIG_DIR`, as
   `name-session.sh` and `prune-probe-sessions` already do:
   `log-instructions-loaded.sh` and `log-skill-invocations.sh` would log
   work sessions into the personal directory, and
   `security-reviewer-memory-scope.sh` allows only the personal
   directory's `agent-memory/security-reviewer/`, so that agent could
   not keep its memory in a work session.
3. **Readers of transcripts and sessions.** `find-session.py`,
   `folder-sessions.py`, and `land`'s `never-prompted.sh` and
   `placed-elsewhere.sh` read `CLAUDE_CONFIG_DIR`, so each sees one
   directory: `find-session` should search every directory the map
   names, `folder-sessions` the one its repo maps to, and the two
   `land` scripts every directory a peer may run under.
4. **A section in `claude/CLAUDE.md`** beside "Azure CLI state is per
   tenant": which directory a folder gets; the tell of a wrong one,
   `claude auth status`'s `configDirectory` and `subscriptionType`,
   printing no identity; and never to switch accounts from the
   extension's menu, which rewrites that directory's login under every
   session in it, each keeping the old account's email in its context
   (a client session's transcript, 2026-10-16). The file stands at its
   200-line cap, so the section pays for itself: the corporate-network
   sentence the rule above corrects is one candidate.
5. **A `SessionStart` guard hook** that warns when a session's
   directory or account is not its folder's, since a hook runs on every
   launch path, the extension, `claude` in a terminal and each
   `claude -p` child alike. It reads the map from `~/.config`, so the
   payload holds no identity, and the session's organization from
   `.claude.json` in its directory, fast to read but an internal
   format. `claude auth status` reports `email`, `orgId`, `orgName` and
   `subscriptionType`, and with every connection refused it printed the
   same fields in the same 2.5 to 2.7 s (2.1.293, measured 2026-10-16),
   which is too slow for every session start. A check at start is
   enough, since a switch cannot cross directories; where the map is
   absent, the hook fails open and says so.
6. **The prose paths.** The payload names `~/.claude/rules/...` by path,
   which in a work session is the personal directory's copy, identical
   after one deploy, unless Read refuses it as outside the working
   directories (below). If it does, the deploy rewrites the path in each
   directory's copy, or the prose stops naming the directory.

**Measure before building**, each against a session logged in under a
second directory, the work one once machine-config makes it:

- `ListAgents` and `SendMessage` between sessions under different
  directories. The coordination of 2026-10-16 crossed accounts, and the
  `land` scripts find a peer by its file under a config directory, so
  this decides both whether such a coordination survives the split and
  what those scripts must search. A live session registers as
  `<config dir>/sessions/<pid>.json`, with `cwd`, `peerProtocol` and
  `messagingSocketPath` among its keys (seen under `~/.claude` by the
  machine-config session, 2026-10-16); where a work session registers is
  not measured.
- Whether Read refuses `~/.claude/...` from a session whose directory
  is elsewhere, once `blockReadsOutsideWorkingDirectories` is on.
- Where server-managed settings are cached, so that the organization's,
  which the user will set as an admin of its plan (2026-10-16), stay
  out of personal sessions. They reach only accounts already in the
  organization (code.claude.com `authentication`, read 2026-10-16).
- Whether VS Code's built-in Agents profile runs the payload's hooks,
  the guard included, and takes a claude.ai login at all. It shares
  Default's settings and the extension contributes no session type
  there, so a Claude session in it is VS Code's own Claude target on
  `~/.claude` (the machine-config session, 2026-10-16).

IDE integration needs nothing: the extension always writes its lock
file to `~/.claude/ide`, the CLI also searches there whenever
`CLAUDE_CONFIG_DIR` is set, and the panel uses the in-process
`claude-vscode` MCP server, not the lock file (extension 2.1.301 code,
read by that session, 2026-10-16).

If a device policy ever deploys `forceLoginOrgUUID` to this laptop, the
pin is moot, as `claude-login-pin.md` says: Claude Code would then
refuse the personal login at startup in every folder. Machine-config's
map generator warns when managed settings carry it.

## Where it lands

The rule lands on the first trigger, and the WebFetch key on its tell,
on the user's yes, deployed with
`./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`.
The brief is deleted once the rule and the pin's side have both landed,
or the pin is dropped, as a device login policy would drop it. A
WebFetch case still open then becomes a brief of its own.

## Not checked

- Either login on that network since 2026-10-05.
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

- Whether the work directory is signed in: the map's `work` account has
  a non-null `orgId`, tested without printing it. On 2026-10-16 it was
  signed out, and signing in is the user's step, after step 1's deploy
  to every directory:

  ```powershell
  $env:CLAUDE_CONFIG_DIR = "$HOME\.claude-work"; claude auth login
  ```

- Whether machine-config's `.claude/rules/claude-accounts.md` still
  gives the map `version` 1.
