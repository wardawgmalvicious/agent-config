# Handoff: fold the VS Code docs findings into the retirement brief

- **Audit run**: 2026-10-06
- **Source**: `vscode-agent`
- **Window**: floor `2026-09-01` (diff base `28f76f5f`, 2026-08-28) →
  head `c642b585` (2026-10-01)
- **Covers recommended actions**: 1
- **Kind**: an **edit** to one open handoff brief, adding VS Code docs
  evidence to three of its removal steps. No payload file changes here:
  `README.md`, `claude/rules/agent-instructions-scoping.md` and
  `claude/CLAUDE.md` change later, when the retirement lands.
- **Target**: `docs/handoffs/execute/copilot-payload-retirement.md`,
  § "After the turn: remove" → "In this repo"

## The problem

The Copilot payload retirement rewrites three files whose claims about
VS Code went stale between 2026-09-01 and 2026-10-01: README § "Tool
support", the harness table in
`claude/rules/agent-instructions-scoping.md`, and `claude/CLAUDE.md`
§ "GitHub Copilot no longer inherits this payload". The retirement
brief plans each rewrite but records none of these docs changes, so the
session that lands it would rewrite from the stale claims.

The audit decided the three files are not edited ahead of the
retirement. The facts go into the brief that rewrites them.

## Evidence

Upstream is `microsoft/vscode-docs`, `docs/agent-customization/`, at
head `c642b585` (2026-10-01). The tables below marked "as rendered"
were fetched from the live site with WebFetch on 2026-10-06 and matched
`main`.

**E-1. Instruction locations are split by harness.** The
custom-instructions page, § "Instructions file locations", from release
1.139 (`4f4413d`, 2026-09-23), as rendered:

| Session and scope | Default file location |
| --- | --- |
| Agent Host workspace, Copilot format | `.github/instructions` |
| Agent Host workspace, Claude format | `.claude/rules` |
| Agent Host user, Copilot format | `~/.copilot/instructions` |
| Agent Host user, Claude format | `~/.claude/rules` |
| Local agent workspace | `.github/instructions` or `.claude/rules` |
| Local agent user | VS Code profile storage |

At base `28f76f5f` the page had a single "User profile" row,
`~/.copilot/instructions` or `~/.claude/rules`, and an IMPORTANT note
that Agent Host sessions read "harness-agnostic folders like
`~/.copilot/instructions` and `~/.claude/rules`". That sentence left
the page in release 1.137 (`dc7c2ba`, 2026-09-08). A shorter form
survives on the Agent Host concept page,
`docs/agents/concepts/agent-host.md:87`: "The Agent Host reads
user-level customizations from harness-agnostic folders like
`~/.copilot` and `~/.claude`."

**E-2. The format table has a Local row.** Same page, § "Choose a
format" (`4f4413d`), as rendered:

| Harness | Recommended project instructions | Targeted instructions |
| --- | --- | --- |
| Copilot | `.github/copilot-instructions.md` or `AGENTS.md` | `.github/instructions/**/*.instructions.md` |
| Anthropic Claude | `CLAUDE.md` | Markdown files in `.claude/rules` |
| OpenAI Codex | `AGENTS.md` | `AGENTS.md` files in subfolders |
| Local | `.github/copilot-instructions.md`, `AGENTS.md`, or `CLAUDE.md` | `.github/instructions/**/*.instructions.md` or Markdown files in `.claude/rules` |

§ "Use a `CLAUDE.md` file" now opens "For Claude Agent Host sessions,
use `CLAUDE.md` at the repository root", and then says "The Local agent
searches for Claude instructions in these locations when
`setting(chat.useClaudeMdFile)` is enabled".

**E-3. Claude-format hooks need `chat.useClaudeHooks`.** The hooks
page, rewritten by "Docs/agent hooks harness support (#10329)"
(`91b05da`, 2026-09-21), § "Local hook file locations", as rendered:

| Scope | File location | Notes |
| --- | --- | --- |
| Workspace, Claude format | `.claude/settings.json`, `.claude/settings.local.json` | Requires chat.useClaudeHooks |
| User, Claude format | `~/.claude/settings.json` | Requires chat.useClaudeHooks |

The source markdown adds "which is off by default". Of
`chat.hookFilesLocations`: "The setting's default value is empty
because the built-in locations are registered separately." Its row for
the Claude format: "Requires chat.useClaudeHooks. Local parses nested
commands but ignores matcher values, so every command for the event
runs." The page's session-target table sends the **Claude** target,
which runs on Agent Host with the Claude Agent SDK, to "the Claude
hooks reference" (https://code.claude.com/docs/en/hooks).

At base the page gave `chat.hookFilesLocations` a default of
`.github/hooks`, `.claude/settings.local.json`, `.claude/settings.json`
and `~/.claude/settings.json`, all `true`. Its FAQ said VS Code "reads
hook configurations from `.claude/settings.json`,
`.claude/settings.local.json`, and `~/.claude/settings.json` by
default" and "ignores matcher values".

**E-4. The Session Target picks the harness.** The hooks page,
§ "Choose the hook implementation for your session", as rendered: "The
**Session Target** control selects the agent harness." and "The Agent
Host is the process that hosts the Copilot, Claude, and Codex
harnesses. The Local harness runs in the extension host. The Chat view
and Agents window are clients that display and control sessions on
either host." Its table lists five targets: Local, Copilot, Claude,
Codex and Cloud.

## What to change

Edit only the retirement brief. Each item adds to one bullet under
§ "After the turn: remove" → "In this repo". Quote the stale text there
so the landing session can find it: the README line numbers below were
read on 2026-10-06 and will drift.

1. **The bullet "The docs a reader starts from"**, which names
   `README.md` § "Tool support". Add these passages, each with the
   evidence that makes it stale:
   - `:208-214`, the location table, "Checked 2026-09-09 against
     `microsoft/vscode-docs@main`". Its Instructions row gives
     `~/.copilot/instructions` and `~/.claude/rules` as user defaults
     for every consumer (E-1).
   - `:220`, "The Local agent *is* the sidebar Chat" (E-4).
   - `:234-239`, "Its defaults are `.github/hooks`,
     `.claude/settings.json`, `.claude/settings.local.json` and
     `~/.claude/settings.json`", and the watch item that "a release
     that adds a default location adds it **enabled**" (E-3).
   - `:266-268`, "Its replacement, Agent Host, "reads user-level
     customizations from harness-agnostic folders like `~/.copilot` and
     `~/.claude`" — so the payload keeps reaching Copilot without these
     settings at all." The quote survives on the concept page, but the
     per-harness rows contradict the conclusion (E-1). That also
     answers `:273-279`, which asks the `vscode-docs` drift source to
     watch for exactly this: the docs pair Copilot-format folders with
     the Copilot harness and Claude-format folders with the Claude
     harness, as the panels in the brief's § "What each target lists"
     showed.
   - `:383-389`, "Copilot parses the Claude hook format, not its
     semantics. Matchers are read and **ignored**". The docs now say
     this of the Local harness only, with `chat.useClaudeHooks` on; the
     Claude target runs Claude Agent SDK hooks (E-3).
   - `:391-395`, "Sessions on **Agent Host** read user-level
     instructions and agents from harness-agnostic folders
     (`~/.copilot/instructions`, `~/.claude/rules`,
     `~/.copilot/agents`)" (E-1).
2. **The bullet "Three statements from `6545f2e` are corrected, not
   cut."** To its `claude/rules/agent-instructions-scoping.md`
   correction, add: the docs' format table (E-2) has a **Local** row
   that the rule's table (`:151-154`) lacks, and writes the Copilot
   targeted glob as `.github/instructions/**/*.instructions.md` where
   the rule has `.github/instructions/*.instructions.md`. The rule's
   `:141-149`, which ties `chat.useAgentsMdFile`,
   `chat.useNestedAgentsMdFiles` and `chat.useClaudeMdFile` to the
   Local agent, already matches the page.
3. **The bullet on `claude/CLAUDE.md` § "GitHub Copilot no longer
   inherits this payload"**, which says the section "is rewritten
   around what reads the payload now". Add: the current `:181-183`,
   "never `~/.claude`, except `CLAUDE.md` where `chat.useClaudeMdFile`
   is on. That is the Copilot harness.", puts a Local-agent setting
   (E-2) on the Copilot harness. The docs' Copilot row lists no
   `CLAUDE.md`, while the 2026-09-30 Copilot panel listed the repo's
   root one by a route not traced. `:184-185`'s "unprobed here" is
   settled by the brief's own § "How it graded".

## Constraint on the fix

- **Edit none of the three files here.** The audit decided their edits
  ride with the retirement (`00-audit-report.md`, recommended
  action 1).
- **Record documented facts as documented.** The Local agent's
  user-scope row (E-1) disagrees with a bundle reading and a
  2026-09-09 measurement, and brief 02 carries that conflict. Do not
  write it into the retirement brief as settled behaviour.
- **The retirement brief is the user's** (`needs: [user]`). Add
  evidence only: change no step, decision or frontmatter.
- **If the retirement brief is gone**, it has landed. Stop, and put
  this brief back to the user rather than editing the three files from
  here.
- **Another session may be live in this tree**, and the retirement
  brief was last committed in `689d714` on 2026-10-06. Re-read it right
  before editing.

## Verification

1. `git diff --stat` lists only
   `docs/handoffs/execute/copilot-payload-retirement.md`, plus this
   brief's execution log.
2. `grep -n -E 'useClaudeHooks|profile storage|Session Target|\*\*/\*\.instructions\.md' docs/handoffs/execute/copilot-payload-retirement.md`
   prints hits under each of the three bullets.
3. `git diff --quiet -- README.md claude/rules/agent-instructions-scoping.md claude/CLAUDE.md && echo untouched`
   prints `untouched`.
4. `uv run scripts/handoff-status.py . --no-inbox` still lists
   `copilot-payload-retirement.md` under "needs you".
5. `pre-commit run --all-files`

## Sequencing note

Keep this apart from brief 02. Both add evidence to an open handoff
brief, but their targets fail differently: this one's is deleted when
the retirement lands, while 02's survives it, cut down. If the
retirement lands first, this brief stops and 02 still applies.

## Provenance

Surfaced by the 2026-10-06 `/drift-audit --sources vscode-agent` run,
floor 2026-09-01. It diffed the four registered pages on disk from a
blobless clone at pinned SHAs, and confirmed the hooks and
custom-instructions tables on the live site the same day. The README,
`claude/CLAUDE.md` and rule line numbers were read that day at
`689d714`.

## Execution log

- **Executed**: 2026-10-06 — applied
- **Session**: fresh (no audit or handoff run in this session; the
  report arrived by @-mention only)
- **Files changed**: `docs/handoffs/execute/copilot-payload-retirement.md`
- **Verification**: the retirement brief was still at `689d714`, and
  every quoted line sat where this brief put it: README `:208-214`,
  `:220`, `:234-239`, `:266-268`, `:273-279`, `:383-389` and
  `:391-395`; the rule's `:141-149` and `:151-154`; `claude/CLAUDE.md`
  `:181-185`. Step 1 — **passed**: `git diff --stat` listed the
  retirement brief alone. Step 2 — **passed**: hits under each bullet,
  `:447` under the `claude/CLAUDE.md` one, `:461` and `:463` under
  "Three statements from `6545f2e`", and `:488`, `:493`, `:504` and
  `:520` under "The docs a reader starts from". Step 3 — **passed**:
  `untouched`. Step 4 — **passed**: `copilot-payload-retirement.md`
  listed under "needs you". Step 5 (`pre-commit run --all-files`) runs
  once at the end of the run.
- **Deferred**: none
- **Deviations**: none to the edits. Three notes. The first bullet's
  six passages went in as a nested list, one item per passage, since
  each carries its own evidence, and its opening sentence names this
  audit's directory as their source. The `:220` item cites the hooks
  page as rendered 2026-10-06 and no commit, since E-4 names none. The
  `:208-214` item calls the Local agent's profile-storage row
  documented, not settled, and points at the bundle reading and the
  2026-09-09 measurement it disagrees with, per the second constraint.
