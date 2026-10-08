---
status: open
priority: 2
needs: [user]
blocked-by: []
written: 2026-09-30
---

# Handoff: retire the Copilot payload

- **Written**: 2026-09-30, from the user's decision that day, made on
  seeing what VS Code lists under each of its session targets in a
  client Fabric repo, and from a read of the installed build the same
  day (transcript `230c3b1b`).
- **Kind**: a removal. The upkeep stopped the day this was written; the
  deletion waited on one turn only the user could run, which passed on
  2026-10-05, and now waits on one decision of the user's (§ "The
  decision the turn left"). Nothing is drafted.

## The decision

`copilot/` and `scripts/copy-copilot.ps1` exist because GitHub Copilot
reads its own folders, a repo's `.github/*` and `~/.copilot/*`, and
Copilot is what the user works through on the corporate network.
[copilot-client-repo-findings.md](copilot-client-repo-findings.md) has
who the payload was built for, and that no such reader exists.

VS Code's chat now takes a **session target**, which picks the harness
that runs a session: Local, Copilot, Claude or Codex. The harness, not
the model, decides which instruction files, rules and skills are read.
The Claude target runs Claude Code's own engine, reads `~/.claude` and a
repo's `.claude/`, and can answer on a model billed through the Copilot
subscription. On seeing that, the user said (2026-09-30):

> We no longer need to maintain the Copilot specific skills anymore or
> the payload based on what I am seeing.

So the payload has no reader, and it goes, as Codex support went on
2026-08-28 (`3f2c7d8`). That is the first of the two paths the findings
brief left open. The second, a frozen payload kept at user scope, is
what remains only if the turn below fails.

## What was measured

All on 2026-09-30, on VS Code 1.139.1 (commit `04c0d99f4f`), bar the
last two subsections, which carry their own dates. When this brief
lands, this section moves verbatim to `docs/evidence/user-claude-md.md`.

### What each target lists

The user opened the Agent Customizations panel on one client Fabric repo
under three targets. Each count was then checked against the folders on
disk:

- **Claude**: 26 instructions, which are the root `CLAUDE.md` and the 3
  files in `.claude/rules`, then the 21 files in `~/.claude/rules` and
  `~/.claude/CLAUDE.md`. 76 skills, 6 of them at user scope, the six in
  `~/.claude/skills`; `.claude/skills` holds 45, and the other 25 were
  outside the screenshot. 5 agents and 1 hook.
- **Copilot**: 26 instructions, which are
  `.github/copilot-instructions.md`, `AGENTS.md`, the root `CLAUDE.md`
  and the 10 files in `.github/instructions`, then the 13 in
  `~/.copilot/instructions`. 93 skills: 48 in `.github/skills`, 4 in
  `~/.copilot/skills` and 28 in `~/.agents/skills`, and 13 built in.
  2 hooks.
- **Codex**: 1 instruction, `AGENTS.md`. 61 skills: the same 48, and 13
  built in.

Every count that could be checked matches, and the two 26s are a
coincidence. **Only the Claude target lists an instruction or a skill
under `~/.claude` or `.claude/`.** Copilot lists the repo's root
`CLAUDE.md` beside its own files, and whether a setting decides that was
not traced. The 28 in
`~/.agents/skills` are Azure skills something else installed, none of
this payload. Claude's one hook entry is `~/.claude/settings.json`: the
build lists one entry per settings file that declares hooks, and the
repo's two declare none. Under the Claude target the MCP page shows only
"Access to MCP servers is disabled by your organization".

### What the build does

In `resources/app/out/vs/platform/agentHost/node/agentHostMain.js`:

- **A Claude session is Claude Code.** It loads
  `@anthropic-ai/claude-agent-sdk` and passes
  `settingSources:["user","project","local"]` and
  `systemPrompt:{type:"preset",preset:"claude_code"}`: all three
  settings scopes and Claude Code's own prompt, so `CLAUDE.md`, rules,
  skills, hooks and permissions load by the same code as in a terminal.
- **It changes three things.** `disallowedTools:["WebSearch"]` removes
  one tool; two in-process hooks are added, on `PreToolUse` and
  `UserPromptSubmit`; and permission prompts are answered through
  VS Code (`canUseTool`).
- **A Copilot-group model goes through a proxy VS Code runs**: the
  session gets `ANTHROPIC_BASE_URL` and a per-session
  `ANTHROPIC_AUTH_TOKEN`, in place of Anthropic's endpoint. A model from
  the Anthropic group takes no proxy: VS Code's docs call that route
  bring-your-own-key.
- **VS Code holds the MCP switch.** It reads the working directory's
  `.mcp.json` itself, leaves an enabled server there for the SDK to
  start, and names each server that is not enabled in the SDK's
  `deniedMcpServers`. `.claude.json` appears nowhere in the file, so a
  user-scope server cannot be on that list by name.

In `resources/app/out/vs/workbench/workbench.desktop.main.js`:

- `chat.mcp.access` takes `none`, `registry` or `all`, default `all`,
  and carries the policy `ChatMCP`, which returns `none` when the
  account's Copilot entitlement has `mcp` false, and `registry` when its
  `mcpAccess` is `registry_only`. Under `registry` it refuses a server
  that did not come from the registry.
- `chat.agentHost.claudeAgent.enabled`, default `true`, carries the
  policy `Claude3PIntegration`, which the docs'
  `github.copilot.chat.claudeAgent.enabled` refers to as well. **An
  organization can switch the Claude target off**, as this one switched
  MCP off.

### What no one has seen

A turn, until 2026-10-05 (§ "How it graded"). Of the 200 transcripts
under `~/.claude/projects` touched in the three days to 2026-09-30, 166
came from the Claude Code extension
(`entrypoint` `claude-vscode`) and 34 from `claude -p` (`sdk-cli`): none
from this target. VS Code's Agents window lists Claude Code's own
sessions, since it reads the same store, so a session shown there proves
nothing.

### Reproducing

Identifiers in the minified bundles change with every build, and an
update replaces the build's folder, so search by content:
`settingSources`, `deniedMcpServers`, `ANTHROPIC_BASE_URL`,
`Claude3PIntegration`, `ChatMCP`. Each file is one line of megabytes,
and a command built on `grep -o '.\{0,900\}<term>.\{0,900\}'` timed out
at 120 s, so slice it:

```bash
out="$LOCALAPPDATA/Programs/Microsoft VS Code/<commit>/resources/app/out"
python3.13 - "$(cygpath -w "$out/vs/platform/agentHost/node/agentHostMain.js")" settingSources <<'PY'
import sys
data = open(sys.argv[1], "rb").read()
at = data.find(sys.argv[2].encode())
print(at, data[max(0, at - 900):at + 900].decode("utf-8", "replace"))
PY
```

### What VS Code read for MCP

On 2026-10-03, on VS Code 1.140.0 and Copilot Chat 0.68.0, the day the
user enabled MCP servers for the organization:

- **VS Code reads both workspace files.** Each server it registers gets
  a log, `mcpServer.<source>.<name>.log`, in the window's folder under
  `%APPDATA%\Code\logs\`. This repo's window registered
  `microsoft-learn-mcp` from `.vscode/mcp.json` as `mcp.config.ws0`, and
  again, with `github-mcp`, from `.mcp.json` as `workspace-dot-mcp.0`:
  one server, twice. A client Fabric repo's window, with no
  `.vscode/mcp.json`, registered the six servers in its `.mcp.json`.
- **None had started.** Every log was empty, so what VS Code's own
  agents make of `${VAR}` and `headersHelper` in `.mcp.json` is unseen;
  ten of the project template's entries carry a `headersHelper`. The
  window had registered no server in the 26 hours it had been open,
  which fits the policy change reaching it: inferred, not traced.
- **Later that day the Local target started `github-mcp` from
  `.mcp.json`, and expanded no variable in it.** `${NAME}` and
  `${env:NAME}` both reached GitHub as typed, and `headersHelper` was
  ignored; with the helper alone, VS Code signed in to GitHub itself.
  The user kept the `${VAR}` header, so `github-mcp` fails in the Local
  target by decision (`claude/mcp/README.md` § "GitHub and multiple
  accounts"). The Claude target starts these servers through the SDK,
  so it should expand `${VAR}` as Claude Code does, given the variable
  in its environment: unseen. The Claude Code extension skips any
  project helper, the Fabric ones included, until the folder's
  lowercase-drive key is trusted (§ "The DCR error is a credential
  failure" there); whether the Claude target does is unseen, so a
  helper-backed server failing in step 5 below may be that rather than
  the policy.
- **The docs agree.** VS Code's MCP servers page (`ms.date` 2026-09-30)
  calls `.mcp.json` the "Workspace, portable format", and says "The flow
  also lists the deprecated .vscode/mcp.json and VS Code user-profile
  destinations for compatibility." Of the Agent Host, where a Claude
  session runs: "the Agent Host doesn't read .vscode/mcp.json directly.
  Instead, VS Code forwards your MCP server configuration to the Agent
  Host, except servers that require interactive input".
- **The VS Code session behind this was no Claude-target turn.** It ran
  in the Local target on a Claude model; its transcript, in
  `GitHub.copilot-chat\transcripts\` under VS Code's workspace storage,
  says `"producer":"copilot-agent"`.

### The corporate network, 2026-10-05

Measured on that network from 14:37 to 15:53 UTC by a VS Code session in
a client Fabric repo, with Windows `curl.exe`, Git Bash's curl,
`openssl s_client` and Claude Code 2.1.289: four CLI runs and the
extension's log. **No proxy and no TLS inspection: a filter resets
Anthropic's hosts by name.**

- **No proxy anywhere.** WinHTTP goes direct; WinINET has no proxy and no
  PAC URL; auto-detect is on, but `wpad` does not resolve and the .NET
  system proxy comes back direct. `github.com`, `pypi.org` and
  `login.microsoftonline.com` answer directly.
- **Reset by name.** `api.anthropic.com`, `claude.ai`, `claude.com`,
  `platform.claude.com`, `mcp-proxy.anthropic.com` and
  `console.anthropic.com` resolve to `160.79.104.10` and
  `2607:6bc0::10`. TCP connects in about 45 ms, and the connection is
  reset as the TLS handshake begins: `curl: (35) Recv failure:
  Connection was reset`, or `read ECONNRESET` in Claude Code's log.
- **Sign-in and refresh never got through.** `platform.claude.com`,
  `claude.com`, `console.anthropic.com` and `mcp-proxy.anthropic.com`
  failed every try, as did every token refresh in the log and a `/login`
  at 15:32.
- **The API got through in bursts.** curl passed around 15:10, 15:39 and
  15:52, ten tries of ten at 15:52 over IPv4 and IPv6, while
  `platform.claude.com` failed ten of ten on the same addresses;
  `claude.ai` passed once. 6 of 7 of Claude Code's model requests
  arrived, and each was answered `401 OAuth access token has expired`:
  the stored token had expired, and no refresh could reach
  `platform.claude.com`. So Claude Code fails on its login, not its
  route.
- **No TLS inspection**: completed handshakes showed publicly issued
  certificates.
- At 17:15 UTC a second session there saw `api.anthropic.com` and
  `platform.claude.com` reset while `api.github.com` answered `200`.
  VS Code's chat reaches its models through GitHub's hosts, which that
  network does not filter, so the Local target and the Claude target on
  a Copilot model both answered there.

## The turn it waits on

The findings brief set the test: the target "answers on the corporate
network". It did, on 2026-10-05 (§ "How it graded", below).

The steps are the user's, in the note
`2026-09-30-claude-session-target-probe.md` in that client repo's
directory under `~/handoff-inbox/`: a Claude-target chat on the repo as
a folder, a model from the Copilot group, one Read of a `.sql` file, and
optionally `/learn` as a second message. The user fills in its "What
happened" section and says so in a session here.

**Grade it from what the turn leaves on disk**, with the note for what
only the user saw:

1. **Find the transcript.** It should carry neither entrypoint above:

   ```bash
   find ~/.claude/projects -name '*.jsonl' -newermt 2026-10-01 -print0 |
     xargs -0 grep -L -E '"entrypoint":"(claude-vscode|cli|sdk-cli)"'
   ```

   Nothing back means the target wrote none there or reused an
   entrypoint: fall back to the note's time and the repo's project
   directory.
2. **It answered**, and on which model:
   `jq -b -r 'select(.type == "assistant") | .message.model' <transcript>`.
3. **A rule loaded on the Read**: one row per `nested_memory` record,
   and at least one `User` row, `coding-tsql.md` for a `.sql` file.

   ```bash
   jq -b -r 'select(.type == "attachment" and .attachment.type == "nested_memory")
     | [.attachment.content.type, .attachment.path] | @tsv' <transcript>
   ```

4. **The user-scope hooks ran**: any line for that session in
   `~/.claude/logs/instructions-loaded.log`, by
   `jq -b -c 'select(.session_id == "<id>")'`. `identity-guard` sits in
   the same settings file. No line is weak evidence, since that log has
   missed confirmed loads (`.claude/rules/activation-testing.md`).
5. **Which MCP servers' tools were offered**:
   `grep -o 'mcp__[A-Za-z0-9_-]*__' <transcript> | sort | uniq -c`.
   The user enabled MCP for the organization on 2026-10-03, so expect the
   client repo's `.mcp.json` servers under their own names, and VS Code's
   own tools bridged in as one server; a server offered both ways came by
   both routes (§ "What VS Code read for MCP"). The name `~/.claude.json`
   gives the user-scope server means the SDK read that file itself, since
   VS Code does not. None at all means the policy resolved to `none`, or
   to `registry`, which refuses these servers (§ "What the build does"):
   tell the user.
6. **`/learn`, if it was sent**: whether a turn started, and on which
   model, for § "The `model:` split".

What each outcome means:

- **2 and 3 hold**: remove, as below.
- **2 fails**, an error in place of an answer: the second path. Tell the
  user. This brief is deleted with that recorded, its name leaves the
  two `blocked-by` lists, and the findings brief's frozen payload is
  what is left to decide.
- **2 holds and 3 does not**: the target answers without the payload,
  which the build says cannot happen. Stop and report; delete nothing.

### How it graded

The turn ran on 2026-10-05 from 16:27 to 20:05 UTC: a Claude-target
chat on a client Fabric repo opened as a folder, on the corporate
network, in VS Code 1.140 (build `07f806f999`), with Claude Code 2.1.281
by the transcript and SDK 0.3.281. A Local-target session in that repo
graded it from disk up to 17:15 UTC; `/triage` re-graded the whole
transcript, `399df72e`, on this machine on 2026-10-06. The note in that
repo's inbox was not opened.

1. **Found**: `entrypoint` `sdk-ts` on all 929 entries that carry one,
   so the `grep -L` above finds it.
2. **Holds.** 261 answers, every one on `claude-sonnet-5-5`, routed
   through Copilot: the Agent Host logged no Anthropic credential
   (`tokenSource=absent`, `apiKeySource=absent`), as the grading session
   read it, and that day's Anthropic-routed runs ended `401` (§ "The
   corporate network, 2026-10-05"). Two error entries came after the
   first grading. VS Code's proxy answered `402` `quotaExceeded`, "You
   have exceeded your monthly quota", at 18:19:48 UTC, and 195 answers
   on the same model followed it, by a route not traced. At 20:05:33 UTC
   "Autocompact is thrashing" ended the session.
3. **Holds.** `nested_memory` records of type `User`:
   `claude-config-scoping.md` from 16:39 UTC, after Reads of `.mcp.json`,
   and `coding-markdown.md` from 18:15 UTC. No `.sql` file was read, so
   not `coding-tsql.md`, but by the same mechanism.
4. **Holds.** 102 lines of `instructions-loaded.log` carry the session's
   id. `identity-guard` was not seen to fire, since a passing hook leaves
   no entry.
5. **Not as expected.** Offered from the start: three VS Code extension
   servers; `microsoft-learn-mcp`, which only `~/.claude.json` defines,
   so the SDK read that file itself; and VS Code's bridged `host` and
   `client`. From 18:06 UTC three more, Docker Desktop's `MCP_DOCKER`
   among them, from a source not traced: `~/.claude.json` held only
   `microsoft-learn-mcp` on 2026-10-06. By 17:15 UTC none of the seven
   servers in that repo's `.mcp.json` was offered, though VS Code
   registered all seven in that window, and its `.claude/settings*.json`
   carry neither `enabledMcpjsonServers` nor
   `enableAllProjectMcpServers`. Whether a later one is among the seven,
   and why none came earlier, were not checked, so `${VAR}` and a
   project `headersHelper` under this target are still unseen. The
   session called `client` three times, and `host` and
   `microsoft-learn-mcp` once each; the Learn call returned a result.
6. **Not sent.** No user slash command: the 23 `<command-name>` strings
   sit inside `prompt_snapshot` attachments.

So 2 and 3 hold, which reads as remove, after the one decision the turn
left.

### The decision the turn left

**Whether the standalone GitHub Copilot desktop app is a supported
harness is the user's call before anything is removed.** It runs
Copilot CLI in worktrees it creates, so no VS Code target and no
`.vscode/settings.json` applies to it. A session in it reported what it
had loaded, on 2026-10-05 in a client Fabric repo, then checked that on
disk:

- **In full**: the repo's `AGENTS.md`, and its root `CLAUDE.md` with
  `@AGENTS.md` expanded, so `AGENTS.md` twice; and
  `~/.copilot/instructions/cross-repo-handoffs.instructions.md`.
- **As an index the agent opens itself**: the ports in
  `~/.copilot/instructions`, by `applyTo`, and the repo's
  `.claude/rules/`, by `paths:`.
- **Skills by name and description**: the repo's `.github/skills/`,
  which shadows same-named ones in `~/.copilot/skills/`, then those, and
  the app's own.
- **Nothing under `~/.claude`**, and no `.claude/skills/`: its junctions
  are git-ignored, so a worktree never has them.

After the removal the app keeps `AGENTS.md`, the index of the repo's
`.claude/rules/`, the handoff rule and its own skills, and loses the 12
ports and both skill sets. The note read the handoff rule as lost too,
but that file is no port and stays (§ "On this machine, after the
merge"). If the app is supported, both Copilot targets stay in the sync
and their drift is closed. On 2026-10-06, comparing each port with its
`claude/rules/` source by distinct non-blank lines after the
frontmatter, `coding-tsql` had 10 found only in the port and 19 only in
the rule, `coding-sparksql` 14 and 14, `coding-bicep` 1 and 19,
`coding-xaml` 3 and 6, `coding-csharp` 2 and 4, `coding-expressions` 1
and 3, and the other six 0 and 2. Pointing
`COPILOT_CUSTOM_INSTRUCTIONS_DIRS` at `~/.claude/rules` instead is
untested; it was unset at User scope on 2026-10-06, and the app does
parse `paths:` in a repo's `.claude/rules/`. Whether VS Code's Copilot
target, on the same runtime, loads the same is inferred, not tested.

## Before the turn: the upkeep has stopped

**The decision ends the upkeep on either path**, since a retired payload
is deleted and a frozen one is never redone. The bullets that told a
session otherwise were amended on 2026-09-30: the last one in each of
`.claude/rules/editing-rules.md` and `copilot-payload.md`, and the last
of § "Name and listing budget" in `editing-skills.md`. Their evidence
is in `docs/evidence/root-claude-md.md` § "Editing conventions".
Nothing of this part is left to do. What it changes for a session:

- **A rule edit leaves its port alone.** `lint-instructions` still fails
  the commit, with `drift`, until the new hash is recorded:

  ```bash
  uv run --with pyyaml scripts/lint-instructions.py --stamp
  ```

- **A new rule** goes into `copilot/.source-hashes.json` under
  `deferred`, with this brief as its reason.
- **Nothing is copied** to `~/.copilot` or into a repo.
- **A brief that still carries a port step** or a `copy-copilot.ps1` run
  drops it when it is worked:

  ```bash
  git grep -n -E 'copy-copilot|lint-instructions' -- docs/handoffs/execute
  ```

## After the turn: remove

Work this part in the brief's worktree. Little of it can break a
deployed state, but the hook and the files it reads leave in one commit.

### In this repo

- **One commit carries these together**, or `lint-instructions` runs
  over half a payload: `copilot/` whole, `scripts/copy-copilot.ps1`,
  `scripts/lint-instructions.py`, its hook and the comment above it in
  `.pre-commit-config.yaml`, and `tests/scripts/copy-copilot/`.
- **`scripts/payload-coverage.py` loses its ports mode**: `--ports`,
  `PORTS` and what only they call. Its coverage mode stays, since it is
  how a rule's reach over a repo was measured.
- **`.claude/rules/`**: `copilot-payload.md` goes. `editing-rules.md`
  loses "or its Copilot port" from its title, its
  `copilot/instructions/*.md` glob and its last bullet;
  `editing-skills.md` its copy bullet; `pre-commit-hooks.md` "Copilot
  ports" from its list of pair checks.
- **Root `CLAUDE.md`** sits at its 200-line cap, so this only frees
  lines: the `copilot/` clause of the `<tool>/` paragraph, both
  `copy-copilot.ps1` commands, the `copilot/instructions/` table row,
  the sentence opening "Copilot takes only", and each reference to
  `copilot-payload.md`. Until then both commands read as routine to
  every session here: the freeze sits in
  `.claude/rules/copilot-payload.md:60-64`, which loads only on a Read
  under `copilot/`, while root loads at launch (a prompt audit of this
  repo, 2026-10-08, finding 17). So the removal takes both lines out,
  or, should the payload be kept frozen, marks them frozen in their
  comments.
- **`claude/CLAUDE.md` § "GitHub Copilot no longer inherits this
  payload"** is rewritten around what reads the payload now: Claude Code
  and VS Code's Claude target read `~/.claude`, and no other target
  does. Keep its pointer to `vscode-scoping.md`. Retitle it without "no
  longer", which a prompt audit in a client repo read as migration
  wording on 2026-10-08, for instance as "GitHub Copilot does not inherit
  this payload"; the ledger's heading changes in the same commit, since
  a ledger's headings mirror its file's. It also takes the corporate
  network's rule, with its tell and its date: there Claude Code fails on its sign-in, `read
  ECONNRESET` as the TLS handshake begins, and a request that gets
  through is answered `401 OAuth access token has expired`, while the
  Claude target on a Copilot model answers (§ "The corporate network,
  2026-10-05"). The file sits at its 200-line cap, so the rewrite pays
  for the rule's lines.
  The file's `:181-183`, as read 2026-10-06, "never `~/.claude`, except
  `CLAUDE.md` where `chat.useClaudeMdFile` is on. That is the Copilot
  harness.", puts a Local-agent setting on the Copilot harness. The
  custom-instructions page now says "The Local agent searches for
  Claude instructions in these locations when
  `setting(chat.useClaudeMdFile)` is enabled", and its "Choose a
  format" table (`4f4413d`, 2026-09-23) gives Copilot
  `.github/copilot-instructions.md` or `AGENTS.md`, and
  `.github/instructions/**/*.instructions.md`, but no `CLAUDE.md`.
  The 2026-09-30 Copilot panel listed the repo's root one all the
  same, by a route not traced (§ "What each target lists"). Its
  `:184-185`, "unprobed here", is settled by § "How it graded".
  Its "never `~/.claude`" also disagrees with the rule it points to:
  `claude/rules/vscode-scoping.md:60-62`, as read 2026-10-08, has a
  profile carrying none of the `chat.*Locations` switches leave Copilot
  inheriting the whole payload (2026-09-11), and this section's ledger
  entry of 2026-09-24 (`docs/evidence/user-claude-md.md:1029-1034`)
  found a profile reading it. The rewrite settles which holds,
  profile by profile (a prompt audit of this repo, 2026-10-08,
  decision 2).
- **Three statements from `6545f2e` are corrected, not cut.** They were
  written that morning, before the panels were seen.
  `claude/rules/agent-instructions-scoping.md` calls the other
  harnesses' formats "unprobed on this machine", and its Copilot row
  omits the root `CLAUDE.md` that target lists; `claude/rules/README.md`
  and `claude/CLAUDE.md` each say "unprobed here".
  The rule's table (`:151-154`, read 2026-10-06) also lacks the
  **Local** row of the custom-instructions page's "Choose a format"
  table (`4f4413d`, 2026-09-23): `.github/copilot-instructions.md`,
  `AGENTS.md` or `CLAUDE.md` for project instructions, and
  `.github/instructions/**/*.instructions.md` or Markdown files in
  `.claude/rules` for targeted ones. The page writes Copilot's
  targeted glob as `.github/instructions/**/*.instructions.md`, where
  the rule has `.github/instructions/*.instructions.md`. The rule's
  `:141-149`, which ties `chat.useAgentsMdFile`,
  `chat.useNestedAgentsMdFiles` and `chat.useClaudeMdFile` to the
  Local agent, already matches the page.
- **The docs a reader starts from**: `README.md` § "Tool support", which
  is mostly Copilot; `skills/README.md`, `scripts/README.md` and
  `.claude/skills/README.md`; what
  `.claude/skills/author-skill/SKILL.md`,
  `.claude/skills/drift-handoff/references/brief-format.md` and
  `docs/handoffs/templates/skill-handoff.md` tell a new skill about
  Copilot; and the comments and messages naming the script in
  `.gitattributes`, `scripts/lint-claude-md.py`,
  `scripts/lint-skill-scopes.py` and `scripts/skill-overlap.py`.
  Six passages of § "Tool support" went stale against VS Code's docs
  between 2026-09-08 and 2026-09-23, by the 2026-10-06 `vscode-agent`
  audit (`docs/audits/2026-10-06/vscode-agent/`), which checked the
  live pages that day. Line numbers as read then:
  - `:208-214`, the location table "Checked 2026-09-09 against
    `microsoft/vscode-docs@main`": its Instructions row gives
    `~/.copilot/instructions` and `~/.claude/rules` as user defaults
    for every consumer. The custom-instructions page now gives a row
    per session and format (`4f4413d`, 2026-09-23): Agent Host reads
    `~/.copilot/instructions` for the Copilot format and
    `~/.claude/rules` for the Claude one, and the Local agent's user
    scope is "VS Code profile storage". That row is documented, not
    settled: it disagrees with the 1.139.0 bundle as
    [copilot-harness-switches.md](copilot-harness-switches.md) reads
    it, and with `:202-206`, measured 2026-09-09.
  - `:220`, "The Local agent *is* the sidebar Chat". The hooks page,
    as rendered 2026-10-06: "The **Session Target** control selects
    the agent harness", the Chat view and Agents window are "clients
    that display and control sessions on either host", and its table
    lists five targets, Local, Copilot, Claude, Codex and Cloud.
  - `:234-239`, "Its defaults are `.github/hooks`,
    `.claude/settings.json`, `.claude/settings.local.json` and
    `~/.claude/settings.json`", and the watch item that "a release
    that adds a default location adds it **enabled**". The hooks page
    (`91b05da`, 2026-09-21) now says `chat.hookFilesLocations`'
    "default value is empty because the built-in locations are
    registered separately", and that each Claude-format location
    requires `chat.useClaudeHooks`, "which is off by default".
  - `:266-268`, Agent Host "reads user-level customizations from
    harness-agnostic folders like `~/.copilot` and `~/.claude`", "so
    the payload keeps reaching Copilot without these settings at
    all". The quote still stands on the Agent Host concept page
    (`docs/agents/concepts/agent-host.md:87`), but the
    custom-instructions page dropped its own version in `dc7c2ba`
    (2026-09-08), and that page's per-harness rows contradict the
    conclusion. They also answer `:273-279`, which asks the
    `vscode-docs` drift source to watch for exactly this: the docs
    pair Copilot-format folders with the Copilot harness and
    Claude-format folders with the Claude harness, as the panels in
    § "What each target lists" showed.
  - `:383-389`, "Copilot parses the Claude hook format, not its
    semantics. Matchers are read and **ignored**". The hooks page
    (`91b05da`) now says that of the Local harness only, with
    `chat.useClaudeHooks` on; the Claude target runs the Claude Agent
    SDK and is sent to Claude Code's own hooks reference.
  - `:391-395`, "Sessions on **Agent Host** read user-level
    instructions and agents from harness-agnostic folders
    (`~/.copilot/instructions`, `~/.claude/rules`,
    `~/.copilot/agents`)": the custom-instructions page now pairs each
    instructions folder with one format, as under `:208-214`.
- **`.vscode/mcp.json` and `.vscode/mcp.template.json` left on
  2026-10-04**, ahead of the turn, at the user's word: `.mcp.json` is
  the one MCP file. The `**2026-10-04.**` entry under "Preamble" in
  `docs/evidence/root-claude-md.md` names the last commit that held
  them. Nothing of it is left to do here.
- **The ledgers take entries, never corrections.**
  `docs/evidence/user-claude-md.md` takes § "What was measured" and the
  turn's grading. `docs/evidence/root-claude-md.md` takes the removal
  under each heading whose rule changed, with the last commit that
  still holds the payload, so that
  `git show <sha>:scripts/copy-copilot.ps1` recovers it.
- **`.github/repo-settings.json` lists a `github-copilot` topic.**
  Dropping it, with `scripts/repo-settings.ps1 -Apply`, changes the
  public repo's settings, so it takes the user's yes.

Find the rest by what the payload was called, since most of this repo's
other mentions of Copilot are the Fabric and Power BI feature, and stay:

```bash
git grep -n -i -E 'copy-copilot|lint-instructions|copilot/instructions|source-hashes|no-copilot|\.github/(skills|instructions)'
```

### On this machine, after the merge

- **Deploy**: `./scripts/link-claude.ps1 -SkillGroups
  workflow,social,meta -Force`, never bare.
- **Remove what the script deployed to `~/.copilot`**, or the Copilot
  target goes on reading stale copies. The script has no uninstall, so
  this is by hand from its two manifests, and an `rm` outside the repo
  takes the user's yes: the files that
  `instructions/.managed-instructions.json` lists and the folders that
  `skills/.managed-skills.json` lists, then both manifests. On
  2026-09-30 that was 12 ports and 4 skills.
  `cross-repo-handoffs.instructions.md` beside them is no port: it keeps
  a Copilot-target session inside its workspace, and it stays.

### In the client repo

**Most of this was done there on 2026-10-02**, by that repo's own
session, on a branch and uncommitted when it reported: the two rules
took their bodies byte for byte, then `.github/copilot-instructions.md`
and `.github/instructions/` went, with the 8 ports and their manifest.
It kept `.github/skills/` and its manifest, which the user held back for
now, and pointed its Local agent at Claude's files
([copilot-harness-switches.md](copilot-harness-switches.md)). So the
note shrinks to `.github/skills/`, once the user says, and a check that
the branch landed. Those copies lagged 27 files across 16 skills that
day, and their manifest lacks `fabric-event-schema-set` only because
the skill was added here on 2026-10-01 (`7905f58`), after that repo's
last skills sync.

One client Fabric repo holds vendored copies, in two checkouts, and no
other repo two levels under `C:/Repos` or `C:/GitHub` did on
2026-09-30: 48 skills and 8 ports, each set with its manifest. That
repo's own session removes them, from a note written to its inbox. The
note carries:

- **Two rules are inverted first.** Its `.claude/rules/` holds two files
  that only point at same-named files in `.github/instructions/`, which
  hold the content (the findings brief, item 3). Each body moves into
  its rule before the instructions file is deleted, or the rule points
  at nothing, silently.
- Then `.github/skills/` and the 8 ports go, with both manifests.
- `.github/copilot-instructions.md` and `AGENTS.md` are that repo's to
  decide: the Copilot and Codex targets read them, and so do
  github.com's Copilot agent and, where it runs, Copilot code review,
  which reads `.github/instructions` too. `AGENTS.md` there names the
  pointer shape. A prompt audit run there on 2026-10-08 found it telling
  Copilot that it reads the repo's `CLAUDE.md`, and pointing it at
  `~/.claude/`: against `agent-instructions-scoping.md`, where
  `chat.useClaudeMdFile` stays `false`, `vscode-scoping.md`, which
  frames inheriting `~/.claude` as a defect, and `claude/CLAUDE.md`'s
  "never `~/.claude`". The retirement decides which side moves; the note
  to that repo carries it if ours stands.
- What it loses: a worktree or a fresh clone of that repo has no
  platform skills under any target, since `.claude/skills` there is
  git-ignored junctions, where `.github/skills` was tracked.
- What that session commits names no personal repo, by the user's rule
  (`claude/CLAUDE.md` § "Git identity is folder-scoped").

### The briefs this closes

- **[copilot-client-repo-findings.md](copilot-client-repo-findings.md)**
  is deleted in the landing commit, which records each item's no: the
  `social` hole and the stale help go with the script; nothing is
  vendored, so nothing needs the check, and the client repo's two
  committed lines leave with its copies; the pointer shape inverts and
  nothing lands here; the deferred port is moot.
- **[copilot-harness-switches.md](copilot-harness-switches.md)** is cut
  down, not deleted. The panels answer its questions 1 and 6 for what
  the Copilot target lists, and the files it was to edit are rewritten
  or deleted here. What is left is whether a Copilot- or Local-target
  session, started by habit, still takes anything from `~/.claude`: the
  Copilot panel counted 2 hook sources that no one opened, and
  machine-config's switches govern the Local harness alone. If the user
  does not care what those targets read, it is deleted with that no
  recorded.
- **Both name this brief in `blocked-by`.** Drop it there as this one
  is deleted, and re-point what links to any of the three:

  ```bash
  git grep -n -E 'copilot-(client-repo-findings|harness-switches|payload-retirement)' -- docs/handoffs
  ```

## What stays

- `claude/rules/vscode-scoping.md` and machine-config's profile
  switches: they keep the Local harness out of `~/.claude`, and a new
  chat in the Chat view still started there on 2026-09-26. A client repo
  turned its own Local agent the other way on 2026-10-02; whether that
  is the new default is the question of
  [copilot-harness-switches.md](copilot-harness-switches.md).
- The harness table in `claude/rules/agent-instructions-scoping.md`,
  corrected: facts about VS Code, true whatever this repo ships.
- What `identity-guard`, `push-gate.sh` and their READMEs say of a
  commit made outside Claude Code: still true of Source Control and a
  terminal.
- `skills/meta/.no-copilot` and the `model:` check, until the next
  section is settled.

## The `model:` split

`lint-frontmatter.py` fails an active `model:` in any skill that could
be vendored (`reaches_copilot()`), because an active key stopped VS Code
Copilot slash-dispatching the skill (2026-09-09). `skills/meta/` is
exempt by its `.no-copilot` marker, and `learn` pins `fable` there. With
nothing vendored, that reason is gone. **Whether another takes its place
is what `/learn` in the turn shows**: the Claude target lists `learn`,
and a pinned model has to be one the Copilot-routed proxy can serve.

- **It ran**: delete the `model-key` check, `reaches_copilot()` with the
  helper functions only it calls, and the marker, with their bullets in
  `editing-skills.md` and `pre-commit-hooks.md`. Leave each skill's
  commented `# model:` line alone: turning a pin on is a decision per
  skill, and rewording some fifty frontmatters is a change of its own.
- **It failed, or was not sent**: keep the check and the marker, and
  reword only their reason, from Copilot's slash dispatch to a model the
  Copilot-routed target cannot serve. If it failed, `learn`'s own pin is
  broken on the corporate network: put that to the user.

**`/learn` was not sent** (§ "How it graded", step 6), so the second
branch holds. The target's Copilot group was three models on
2026-10-05, Claude Sonnet 5.5, Claude Sonnet 5 and Claude Haiku 4.5, by
the Agent Host log as the grading session read it, while the Local
target ran Claude Opus 5.5 on Copilot that day. So `learn`'s `fable`
pin names a model the Copilot-routed target cannot serve, as `opus`
would: put that to the user. The live `~/.claude/settings.json` carries
`"model": "opus"`, a key of its own that the deploy keeps, and the turn
raised no error on it: it ran on the picker's model. Whether a skill's
pin is ignored the same way, or fails, is unseen.

## What it costs, and the way back

- **The Copilot, Local and Codex targets get none of the payload.**
  Accepted: the user picks the Claude target. Nor is the Copilot target
  a fallback for a server that needs authentication: "Copilot sessions
  can currently access only local MCP servers that don't require
  authentication" (VS Code's harness page, approved 2026-09-30).
- **The Claude target on a Copilot model has limits of its own**: no
  Opus in its group (§ "The `model:` split"), and a monthly quota, which
  its proxy reported exceeded on 2026-10-05 (§ "How it graded").
- **The Claude target is the organization's to switch off**
  (`Claude3PIntegration`). If it does, nothing of the payload reaches
  VS Code's chat on the corporate network, and the way back is git:
  revert the removal, or take the script and `copilot/` from the commit
  the ledger names and run it against `~/.copilot`. Claude Code itself
  gets through that network's filter only in gaps:
  [claude-code-corporate-network.md](claude-code-corporate-network.md)
  holds what is left for it.
- **MCP there is the organization's to switch off as well.** Its policy
  had MCP off until the user enabled it on 2026-10-03. Since then the
  Local target has started `github-mcp` and the Claude target
  `microsoft-learn-mcp` (§ "What VS Code read for MCP", § "How it
  graded"). If it goes off again, that is no part of this brief, and no
  reason to look for another route to a server. The tell is silence: no
  server listed, no trust prompt, no MCP tools, while Developer: Policy
  Diagnostics names the policy (a client repo's window, 2026-10-02).

## Not checked

- What let 195 answers through after the `402` on 2026-10-05: overage
  billing, a reset, or another route.
- Whether a skill's `model:` pin fails under the target, or is ignored
  as the settings' `model` was.
- Which two hook sources the Copilot panel counted, what the 25 skills
  outside the Claude screenshot were, and the 4 agents beside the one in
  `~/.claude/agents`.
- Whether the entitlement's `none` reaches a server the SDK finds by
  itself in `~/.claude.json`: the deny list is built from what VS Code
  reads, and it does not read that file. Moot while the organization
  leaves MCP on, as the user set it on 2026-10-03. That the SDK finds
  such a server is settled: the turn was offered `microsoft-learn-mcp`.
- Whether a setting makes the Claude target the default for a new chat.
  If one exists it is machine-config's, through its inbox.
- Whether Copilot code review runs on the client repo's pull requests,
  and that it reads `.github/instructions`: recalled that day, not read.

## Verification

- `pre-commit run --all-files`, and every negative-case suite, by the
  loop in root `CLAUDE.md` § "Commands".
- `uv run scripts/lint-claude-md.py`: both files inside their caps.
- The `git grep` under § "In this repo" returns only ledgers, audits,
  briefs not yet worked, and what § "What stays" lists.
- After the merge and the deploy: `cmp ~/.claude/CLAUDE.md
  claude/CLAUDE.md`, and `ls ~/.claude/skills | grep -E
  '^(fabric|pbir|pbid)-'` prints nothing.
- `ls -A ~/.copilot/instructions ~/.copilot/skills` shows the one
  instructions file that stays, and no manifest.
- Once the client repo has landed its note, its Copilot panel lists no
  skill or port of this payload and its Claude panel is unchanged: the
  user's to look at.

## Scrubbing

This repo is public. The client repo is cited by kind and its files by
role, the organization is named nowhere, and the user's words carry no
name. The inbox note and the transcript are raw.

## Re-measure before acting

- VS Code's version, and each string under § "What the build does" in
  its bundle: 1.139.1 on 2026-09-30.
- Which files VS Code takes MCP servers from: the `mcpServer.*.log`
  names in a window's folder under `%APPDATA%\Code\logs\` (1.140.0 on
  2026-10-03, § "What VS Code read for MCP").
- `ls -A ~/.copilot/instructions ~/.copilot/skills`, and each manifest.
- Which repos hold vendored copies: a `.managed-skills.json` or
  `.managed-instructions.json` under any repo's `.github`.
- `git log -1 --format=%h -- copilot`, and the same for
  `scripts/copy-copilot.ps1`: `91845fa` and `3775d1a` on 2026-09-30.
- `uv run scripts/handoff-status.py`, for briefs written since that
  carry a port step.
- The turn's transcript, `399df72e` under the client repo's project
  directory in `~/.claude/projects`, in case the session was resumed:
  1,321 lines, the last at 20:05:33 UTC on 2026-10-05, read 2026-10-06.
