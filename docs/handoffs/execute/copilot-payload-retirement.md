---
status: open
priority: 2
needs: [user, a Claude-target turn on the corporate network]
blocked-by: []
written: 2026-09-30
---

# Handoff: retire the Copilot payload

- **Written**: 2026-09-30, from the user's decision that day, made on
  seeing what VS Code lists under each of its session targets in a
  client Fabric repo, and from a read of the installed build the same
  day (transcript `230c3b1b`).
- **Kind**: a removal. The upkeep stopped the day this was written; the
  deletion waits on one turn only the user can run. Nothing is drafted.

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
last subsection, which carries its own date. When this brief lands, this
section moves verbatim to `docs/evidence/user-claude-md.md`.

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

A turn. Of the 200 transcripts under `~/.claude/projects` touched in the
three days to 2026-09-30, 166 came from the Claude Code extension
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

## The turn it waits on

The findings brief set the test: the target "answers on the corporate
network". Everything above says it will, and nothing has shown it. The
user is next on that network in the week of 2026-10-05.

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
  `copilot-payload.md`.
- **`claude/CLAUDE.md` § "GitHub Copilot no longer inherits this
  payload"** is rewritten around what reads the payload now: Claude Code
  and VS Code's Claude target read `~/.claude`, and no other target
  does. Keep its pointer to `vscode-scoping.md`. If the heading changes,
  the ledger's changes in the same commit, since a ledger's headings
  mirror its file's.
- **Three statements from `6545f2e` are corrected, not cut.** They were
  written that morning, before the panels were seen.
  `claude/rules/agent-instructions-scoping.md` calls the other
  harnesses' formats "unprobed on this machine", and its Copilot row
  omits the root `CLAUDE.md` that target lists; `claude/rules/README.md`
  and `claude/CLAUDE.md` each say "unprobed here".
- **The docs a reader starts from**: `README.md` § "Tool support", which
  is mostly Copilot; `skills/README.md`, `scripts/README.md` and
  `.claude/skills/README.md`; what
  `.claude/skills/author-skill/SKILL.md`,
  `.claude/skills/drift-handoff/references/brief-format.md` and
  `docs/handoffs/templates/skill-handoff.md` tell a new skill about
  Copilot; and the comments and messages naming the script in
  `.gitattributes`, `scripts/lint-claude-md.py`,
  `scripts/lint-skill-scopes.py` and `scripts/skill-overlap.py`.
- **`.vscode/mcp.json` and `.vscode/mcp.template.json` go**, leaving
  `.mcp.json` the one MCP file: the user's call on 2026-10-03, once
  § "What VS Code read for MCP" showed VS Code reading it ("it seems
  likely we can maintain just one mcp file now"). The live file holds
  only `microsoft-learn-mcp`, which `.mcp.json` has. The template's two
  entries the project template lacks, `eventhouse-remote-mcp` and
  `warehouse-remote-mcp`, each join it or are recorded as left out in
  `claude/mcp/README.md`, with the reason `.vscode/README.md` gives, and
  that README keeps only what is not MCP. Re-point what names either
  file, and correct `claude/rules/claude-config-scoping.md`, whose table
  gives VS Code only `.vscode/mcp.json`: `git grep -n -E '\.vscode/mcp'`.
  This holds on either path of § "What each outcome means": on the
  second, it moves to the findings brief as this one is deleted.
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
  pointer shape.
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
  chat in the Chat view still started there on 2026-09-26.
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

## What it costs, and the way back

- **The Copilot, Local and Codex targets get none of the payload.**
  Accepted: the user picks the Claude target.
- **The Claude target is the organization's to switch off**
  (`Claude3PIntegration`). If it does, nothing of the payload reaches
  VS Code's chat on the corporate network, and the way back is git:
  revert the removal, or take the script and `copilot/` from the commit
  the ledger names and run it against `~/.copilot`.
- **MCP there is the organization's to switch off as well.** Its policy
  had MCP off until the user enabled it on 2026-10-03, and no server has
  yet been seen to start under any target (§ "What VS Code read for
  MCP"). If it goes off again, that is no part of this brief, and no
  reason to look for another route to a server.

## Not checked

- A turn through the target, above all.
- Which two hook sources the Copilot panel counted, what the 25 skills
  outside the Claude screenshot were, and the 4 agents beside the one in
  `~/.claude/agents`.
- Whether the entitlement's `none` reaches a server the SDK finds by
  itself in `~/.claude.json`: the deny list is built from what VS Code
  reads, and it does not read that file. Moot while the organization
  leaves MCP on, as the user set it on 2026-10-03.
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
