# Handoff: fold three documented VS Code facts into the harness-switches brief

- **Audit run**: 2026-10-06
- **Source**: `vscode-agent`
- **Window**: floor `2026-09-01` (diff base `28f76f5f`, 2026-08-28) →
  head `c642b585` (2026-10-01)
- **Covers recommended actions**: 2
- **Kind**: an **edit** to one blocked handoff brief, adding three
  documented facts and two passages of a file it already plans to edit.
  No rule or setting changes here: `claude/rules/vscode-scoping.md`
  stays with that brief.
- **Target**: `docs/handoffs/execute/copilot-harness-switches.md`

## The problem

`copilot-harness-switches.md` works out which VS Code harness the
`chat.*` switches govern, then edits every file here that says how
Copilot is kept out of `~/.claude`, `claude/rules/vscode-scoping.md`
among them. Its evidence is the 1.139.0 and 1.139.1 bundles, plus docs
a client repo's session fetched on 2026-10-05. Three facts the docs now
state are missing from it, and the first contradicts both its bundle
reading and a measurement recorded in README.

## Evidence

Upstream is `microsoft/vscode-docs`, `docs/agent-customization/`, at
head `c642b585` (2026-10-01). Both pages quoted were checked on the
live site on 2026-10-06.

**F-1. The Local agent's user instructions are documented as profile
storage.** The custom-instructions page, § "Instructions file
locations" (`4f4413d`, release 1.139, 2026-09-23): "Local agent user |
VS Code profile storage" and "Local agent workspace |
`.github/instructions` or `.claude/rules`". Four sources now disagree
about `~/.claude/rules` under the Local agent:

| Source | What it says |
| --- | --- |
| VS Code docs, 2026-09-23 | not a Local location; the Local user scope is profile storage |
| this brief, 1.139.0 bundle (`:53-60`) | one of nine built-in `source: "claude-*"` locations |
| README `:202-206`, measured 2026-09-09 | a `.sql` file "loaded exactly two of the twelve rules in `~/.claude/rules`" |
| machine-config `configs/vscode/profiles/profiles.psd1:106` (`13c7b89`, 2026-09-24) | a Claude location its profile audit checks under `chat.instructionsFilesLocations` |

**F-2. `chat.hookFilesLocations` is documented with an empty default.**
The hooks page (`91b05da`, 2026-09-21): "The setting's default value is
empty because the built-in locations are registered separately." This
brief's table (`:48`) gives 1.139.0's default as "every built-in path
`true`". Its `:51` row, `chat.useClaudeHooks` defaulting `false`,
agrees with the docs: each Claude-format location "Requires
`chat.useClaudeHooks`", which "is off by default".

**F-3. The Copilot target's hooks are the Copilot SDK's.** The hooks
page, § "Choose the hook implementation for your session", has this row:

```text
| **Copilot** | Agent Host | Shared Copilot SDK implementation | Use the GitHub Copilot hooks reference. |
```

It links https://docs.github.com/en/copilot/reference/hooks-reference,
and the page goes on: "Some harnesses discover the same hook files,
such as `.github/hooks/*.json` or `.claude/settings.json`. This file
compatibility does not make their behavior identical." That is a
candidate source for the two hook entries the Copilot panel counted on
2026-09-30, which nobody opened (`copilot-payload-retirement.md`
§ "Not checked"). Unverified: the docs do not say which harness
discovers `.claude/settings.json`.

**F-4. The two `claude/rules/vscode-scoping.md` passages these touch.**
This brief lists the file (`:108-110`) without them:

- `:60-62`: "on 2026-09-11 one profile carried none of the Copilot
  `chat.*Locations` switches, so Copilot there still inherited the
  whole `~/.claude` payload, hooks included." Per F-2, Claude-format
  hooks need `chat.useClaudeHooks` as well.
- `:63-68`: "**An unlisted location keeps its default, and the default
  is on.**" Per F-2 the hooks map defaults empty, and per F-1 the Local
  agent's documented user location is profile storage.

## What to change

Edit only `copilot-harness-switches.md`:

1. **§ "What was measured"**: after the 1.139.0 table and its bullets,
   add F-1 and F-2 as documented facts, each with its commit and date,
   marked where they disagree with the table's `chat.hookFilesLocations`
   row (`:48`) and with the nine-location list (`:53-60`). Carry F-1's
   four-source table.
2. **§ "Questions for the investigation"**, question 1, on what the
   Agent Host Copilot SDK harness reads: add F-3, marked as a candidate
   and unverified.
3. **§ "What it puts in question here"**, the `vscode-scoping.md`
   bullet (`:108-110`): add the two passages of F-4.
4. **Where the brief orders its work**: the Local agent's user-scope
   instructions are re-measured before this brief's conclusions or
   `vscode-scoping.md` change. README `:202-206` names the method used
   on 2026-09-09.

## Constraint on the fix

- **No rule, setting, README or machine-config edit here.** The
  `vscode-scoping.md` edit belongs to the brief being edited
  (`00-audit-report.md`, recommended action 2).
- **Do not settle F-1 by reasoning.** The registry entry for this
  source asks to "prefer re-measuring to reasoning forward from a past
  result" (`.claude/skills/drift-audit/references/sources.md`,
  `vscode-agent`).
- **Leave the frontmatter alone**: the brief stays blocked by
  `copilot-payload-retirement.md`.
- **If the retirement has landed**, it will have cut this brief down
  (`copilot-payload-retirement.md` § "The briefs this closes"). Add the
  facts to what is left. If the brief was deleted with a no, stop and
  put this brief back to the user.
- **Re-read the brief right before editing.** Another session may be
  live in this tree, and the line references above are from
  2026-10-06.

## Verification

1. `git diff --stat` lists only
   `docs/handoffs/execute/copilot-harness-switches.md`, plus this
   brief's execution log.
2. `grep -n -E 'profile storage|registered separately|Shared Copilot SDK|hooks included' docs/handoffs/execute/copilot-harness-switches.md`
   prints at least one hit for each term.
3. `git diff --quiet -- claude/rules/vscode-scoping.md && echo untouched`
   prints `untouched`.
4. `pre-commit run --all-files`, whose `lint-briefs` hook checks the
   frontmatter.

## Sequencing note

Keep apart from brief 01, whose target is deleted when the retirement
lands while this one's survives, cut down. Keep apart from brief 03 as
well, which reads another repo and may write to its inbox. Different
targets, different failure modes.

## Provenance

Surfaced by the 2026-10-06 `vscode-agent` run while it mapped its
findings onto this repo. The machine-config row of F-1's table was read
on 2026-10-06 while this brief was written, not during the audit.
