---
status: open
priority: 2
needs: []
blocked-by: [copilot-payload-retirement.md]
written: 2026-09-26
---

# Handoff: which harness the Copilot switches govern

- **Written**: 2026-09-26, from a `machine-config` inbox note of
  2026-09-24, which read VS Code 1.139.0's bundle while adding a check
  that every profile writes each Claude location out `false`, and a
  re-read of 1.139.1's bundle the day this was written.
- **Kind**: an investigation, then edits to every file here that states
  how Copilot is kept out of `~/.claude`. Nothing is drafted: the user
  wants the new VS Code settings model worked out first.

## The claim in question

This repo keeps Copilot out of the `~/.claude` payload with VS Code
switches: every `chat.*Locations` entry naming a Claude root written out
`false`, and `chat.useClaudeMdFile` off where the payload's `CLAUDE.md`
should not reach Copilot. `claude/CLAUDE.md` § "GitHub Copilot no longer
inherits this payload" states the result: Copilot reads "never
`~/.claude`, except `CLAUDE.md` where `chat.useClaudeMdFile` is on".

Every one of those switches describes itself as "only used by the Local
agent harness", so the claim is true of that harness with the switches
off and unknown for any other. New chat sessions still start in the
Local harness, so the switches hold on this machine today. The same
build ships an Agent Host Copilot SDK harness that does not read them,
and marks the Local harness for removal "in a future release".

## What was measured

VS Code 1.139.0 (commit `2242ebbb54`) on 2026-09-24, strings from
`resources/app/out/nls.messages.json` and defaults from
`resources/app/out/vs/workbench/workbench.desktop.main.js`:

| Setting | Default | Its description adds |
| --- | --- | --- |
| `chat.agentSkillsLocations` | every built-in path `true` | "only used by the Local agent harness" |
| `chat.instructionsFilesLocations` | every built-in path `true` | the same |
| `chat.hookFilesLocations` | every built-in path `true` | the same; loads Claude `settings.json` hooks too |
| `chat.agentFilesLocations` | `.github/agents`, `.claude/agents`, `~/.copilot/agents` `true` | the same, and deprecated with the Local harness |
| `chat.useClaudeMdFile` | `true` | the same |
| `chat.useClaudeHooks` | `false` | the same; a Claude-format hook runs only when it is on |

- **Nine Claude locations** sit in the built-in arrays as
  `source: "claude-*"` entries: `.claude/skills`, `~/.claude/skills`,
  `.claude/rules`, `~/.claude/rules`, `.claude/agents`,
  `~/.claude/agents`, `.claude/settings.json`,
  `.claude/settings.local.json` and `~/.claude/settings.json`. Prompt
  files have none. `~/.claude/agents` is in the discovery array but not
  in `chat.agentFilesLocations`' default map; whether it is read while
  unlisted was not traced.
- **The deprecation**, on `chat.agentFilesLocations`: "This setting and
  the Local agent harness will be removed in a future release", pointing
  at a *Migrate Location Settings* command. VS Code's custom-instructions
  page, updated 2026-09-16, calls `chat.instructionsFilesLocations`
  deprecated and Local-only too, and says to migrate its locations
  (fetched 2026-09-25 by a client repo's session).
- **Other harnesses ignore the settings outright**: "The settings {0} are
  no longer read by {1}. Move the customizations into supported harness
  folders so both VS Code and {1} can use them." Related strings
  deprecate prompt files for such a harness ("Convert them to skills").
- **Harness selection**: `chat.defaultToCopilotHarness` and
  `chat.editor.preferCopilotHarness` both default `false`, and a
  `chat.editor.preferCopilotHarness.policy` is registered too. The chat
  picker offers a harness per session, Claude and Codex beside the
  Copilot SDK.
- **This machine**, 2026-09-24: none of the four live profiles (Default,
  Fabric, Config, Azure) sets either harness setting, and no
  `SOFTWARE\Policies\Microsoft\VSCode` key exists under `HKLM` or `HKCU`.

Re-read on 1.139.1 (commit `04c0d99f4f`, installed 2026-09-25) on
2026-09-26:

- **The harness defaults are experiment-controlled.** Both settings
  still default `false`, and both carry `experiment: {mode: "startup"}`,
  so a VS Code experiment can change the effective default at a startup
  with no settings file changing. Whether this machine sits in such an
  experiment is unknown.
- **Sixteen strings** carry "only used by the Local agent harness".
  Among them are `chat.useAgentsMdFile`, `chat.useNestedAgentsMdFiles`,
  `chat.useClaudeMdFile` and `chat.includeReferencedInstructions`, so the
  import form's Copilot side in
  [nested-instruction-files.md](nested-instruction-files.md) rests on
  Local-only settings too. The sixteen were not all mapped to settings.

## What it puts in question here

Outside `docs/handoffs/`, 42 mentions in 13 files on 2026-09-26:

```bash
git grep -cE 'chat\.(\*Locations|agentSkillsLocations|instructionsFilesLocations|hookFilesLocations|agentFilesLocations|useClaudeMdFile|useClaudeHooks)' -- ':!docs/handoffs'
```

The ones that state the model rather than cite it:

- `claude/CLAUDE.md` § "GitHub Copilot no longer inherits this payload",
  and root `CLAUDE.md`'s line that Copilot takes `CLAUDE.md` only where a
  profile turns `chat.useClaudeMdFile` on.
- `claude/rules/vscode-scoping.md`: the per-profile and
  unlisted-location gotchas, and `chat.includeReferencedInstructions`,
  every one a Local-only setting.
- `.claude/rules/copilot-payload.md`: the switches in its first bullet,
  and its bullet on hooks, where 1.139.0 runs no Claude-format hook unless
  `chat.useClaudeHooks` is on, and that defaults off.
- `README.md` § "Tool support", `scripts/copy-copilot.ps1`, and the two
  `docs/evidence/` ledgers that record these switches.

## Questions for the investigation

1. What does the Agent Host Copilot SDK harness read, and does any of it
   come from `~/.claude` or a workspace's `.claude/` by default?
2. Does that harness have any off-switch for Claude's files, per profile
   or otherwise?
3. What does *Migrate Location Settings* move, and where? Its strings
   say it moves customizations found through the location settings, and
   `~/.claude/skills` is a junction into this repo. Try it on a scratch
   profile first, never a real one.
4. When is the Local harness due to go? The release notes should say.
5. Does an explicit `false` for both harness settings hold against an
   experiment? A set value outranks a default, and a default is all an
   experiment changes, but that is unverified here.
6. Does the SDK harness read `AGENTS.md` and `CLAUDE.md`, and follow an
   instructions file's links, and under what settings? The answer
   decides whether the import form's two Copilot conditions outlive the
   Local harness.

## What machine-config already did

Landed there 2026-09-24:

- `062a2f2` wrote every Claude location out `false` in the Azure
  profile, which had inherited the payload since `d72a414`.
- `13c7b89` added the `-Audit` check: any profile, Default included,
  with a Claude location unlisted or not `false`, or a switch left on.
  The list it checks is `ClaudeLocations` and `ClaudeSwitches` in its
  `configs/vscode/profiles/profiles.psd1`, read out of the 1.139.0
  bundle, and a comment there records the harness limit.
- `cf6c683` holds the stored profiles to the same list at commit time.

Neither harness setting nor `chat.includeReferencedInstructions` is on
that list (2026-09-26). A change to the list, or a check on the harness
settings, goes to `~/handoff-inbox/machine-config/`: the check lives
there.

## Reproducing

Identifiers in the minified bundle, and string ids, change with every
build, so search by content:

```bash
out="$LOCALAPPDATA/Programs/Microsoft VS Code/<commit>/resources/app/out"
jq -r 'to_entries[] | select(.value | test("harness"; "i"))
  | "\(.key): \(.value)"' "$out/nls.messages.json"
grep -oE '.{0,120}source:"claude-[a-z-]+".{0,120}' \
  "$out/vs/workbench/workbench.desktop.main.js"
grep -oE '"chat\.(defaultToCopilotHarness|editor\.preferCopilotHarness)":\{[^}]{0,200}' \
  "$out/vs/workbench/workbench.desktop.main.js"
```

`Code.VisualElementsManifest.xml` beside `Code.exe` names the current
build's commit directory; an older one can linger beside it.

## Re-measure before acting

- VS Code's version, and each string and default above in its bundle:
  1.139.0 on 2026-09-24, 1.139.1 on 2026-09-26.
- The mention count above, by its own command.
- machine-config's `ClaudeLocations` and `ClaudeSwitches`.
