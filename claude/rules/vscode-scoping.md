---
paths:
  - "**/.vscode/*.json"
  - "**/*.code-workspace"
  - "**/vscode/**/*.json"
---

# VS Code configuration: what belongs where

Applies when editing `.vscode/*.json`, a `.code-workspace` file, or a
stored VS Code profile. The question these files keep raising is not
*what* to set but *where* — the same key is correct in one scope and
actively wrong in another.

If a project-scope `.claude/rules/vscode-scoping.md` exists, that file
supersedes this one.

## The scope table

| Scope | Committed? | Controls | Put here |
| --- | --- | --- | --- |
| **Profile** (`%APPDATA%/Code/User/profiles/<generated>/`) | no — machine-local | **which extensions load**, plus personal settings | Anything that is a property of *you*: theme, keybindings, terminal shell, which toolset a domain needs |
| **`.vscode/settings.json`** | yes | editor behavior in this repo | Anything that is a property of *the codebase* — a formatter that produces conforming diffs, files that must not be hand-edited, associations for extensions the repo's file types need |
| **`.vscode/extensions.json`** | yes | *suggestions only* | The list a new clone should be prompted to install |
| **`.vscode/tasks.json`** | yes | runnable commands | Awkward invocations worth not retyping |
| **`.code-workspace`** | either | multi-root folder set | Only when a window genuinely needs two repos open at once: Claude Code loads little of the second folder's guidance (`agent-instructions-scoping.md`) |

The test for `.vscode/settings.json`: **would a colleague cloning this
repo need it to produce a conforming diff?** If yes it is repo scope. If
it merely suits your taste, it is profile scope and does not belong in
the repo.

## Only a profile controls which extensions load

`extensions.json` is named misleadingly. It is a *recommendation* list —
it prompts on first open and populates the "Recommended" filter. It never
installs, never enables, and never disables anything. A repo cannot trim
the extension set a window loads; only the profile bound to that window
can. So "this repo should be lightweight" is a profile task, and
`extensions.json` is documentation with a UI attached.

## Gotchas

- **A `defaultFormatter` naming an extension that is not enabled fails
  silently.** No error, no warning, no marker: format-on-save simply
  stops working, indefinitely. Whenever you set
  `"[lang]": { "editor.defaultFormatter": "<id>" }`, confirm `<id>` is
  actually installed and enabled in the profile that opens this repo —
  the setting is validated by nobody.
- **`useDefaultFlags` in `storage.json` is a live link, not a copy.** A
  named profile with `"useDefaultFlags": { "settings": true }` has no
  settings of its own; edits made "in" it write back into Default. The
  profile editor's *Use Default Profile* tick is easy to leave on, and
  the symptom — changes to one profile appearing in another — reads as a
  sync bug rather than a scoping one.
- **Every profile has its own settings.** Each keeps a `settings.json`
  under `%APPDATA%\Code\User\profiles\<id>\` unless it shares Default's;
  `%APPDATA%\Code\User\settings.json` is Default's alone, and the
  Settings UI edits the current window's profile. A switch set in one
  profile is absent from the rest, so what the Local agent reads is
  decided per profile: on 2026-09-11 one profile carried none of the
  `chat.*Locations` entries the others wrote out `false`, so its Local
  agent alone read the whole `~/.claude` payload.
- **An unlisted location keeps its default, and the default is on.** The
  `chat.*Locations` settings are location → boolean maps *over* the
  built-in locations, nine of them Claude's (1.141.0), so leaving one
  out reads it as surely as listing it `true`: every profile here does
  one or the other for Claude's rules, skills and agents, since the Local
  agent reading them is wanted (2026-10-08). Turning one off means
  writing it out `false`, since an omitted one stays live:
  `.claude/skills` and `.claude/rules` did on 2026-09-11, while every
  root listed beside them read `false`.
- **Claude's hooks stay off.** A Claude-format hook runs under the Local
  agent only with `chat.useClaudeHooks` on, which defaults `false`, with
  no experiment and no configuration default able to move it (1.141.0).
  Leave it unset, as every profile here does (2026-10-13). Each also
  holds those hooks off a second way, listing Claude's three hook files
  `false` in `chat.hookFilesLocations` or setting `chat.useHooks`
  `false`, Default since that evening (read 2026-10-15). Reading
  Claude's guidance is wanted, while its hook scripts were never tested
  under another harness.
- **These switches govern the Local harness alone, and an experiment
  can move a new chat off it.** Each says it is "only used by the Local
  agent harness"; the Copilot target reads nothing under `~/.claude`,
  and the Claude target reads it as Claude Code does.
  `chat.defaultToCopilotHarness` and `chat.editor.preferCopilotHarness`,
  default `false`, start a new chat on the Copilot target in Local's
  place, and `chat.editor.localAgent.enabled`, default `true`, hides
  Local when off. All three are experiment-controlled at startup, but an
  experiment changes only a default (1.141.0), so a value a profile sets
  holds against it, and a policy outranks both. So every profile here
  sets all three at those defaults, and
  `chat.copilotHarnessIntroduction.mode`, which an experiment here had
  at `afterRequest`, to `off` (2026-10-13, read 2026-10-15): keep them,
  though they match the defaults. A Claude-target pick is unaffected;
  the docs mark Local and these switches for removal together, so plan
  for the Claude target.
- **The Settings UI may not save.** Object-valued `chat.*` settings
  edited through the UI can leave `settings.json` untouched with no
  error — measured 2026-09-09, repeated edits against an mtime four days
  stale, and again 2026-09-11, when two of four object-valued settings
  set through the UI never reached the file. Edit the profile's
  `settings.json` directly and check it afterwards.
- **`chat.includeReferencedInstructions` makes a link an include.** On,
  Copilot's Local agent loads in full every file linked from
  `copilot-instructions.md` or an applied `*.instructions.md`, though not
  from `AGENTS.md` or `CLAUDE.md`. It defaults off, and Edit mode follows
  links regardless (1.139.1). A profile's `true` reaches every repo it
  opens: on 2026-09-25 one took a client repo's Copilot load from 18 KB
  to 89 KB, found only by asking Copilot what it had loaded. Whether a
  link should load is the repo's call, so set it in that repo's
  `.vscode/settings.json`, and write a path meant to be read on demand as
  a code span, which holds under either value.
- **Globs do not match leading dots.** VS Code's glob engine (like the
  shell, unlike Python's `fnmatch`) will not let `*` match a leading dot,
  so `*.platform` matches nothing at all. Fabric names two item parts as
  dotfiles where the whole filename is the extension — `.platform` and
  `.schedules` — and both need `**/.platform` form. A `files.associations`
  or `files.readonlyInclude` entry matching nothing raises no error, so
  verify the glob resolves rather than assuming it did.
- **`files.readonlyInclude` blocks the editor, not the filesystem.**
  Correct for generated or portal-owned files: it stops the stray
  keystroke while leaving the generating script free to write. It is not
  a permission and not a safety guarantee.
- **Normalising line endings is not always a courtesy.** In a repo whose
  files are rewritten by an external system on its own schedule — Fabric
  Git sync being the case at hand — adding `files.eol` or an
  `.editorconfig` restarts a whitespace-only diff war. Check what owns
  the file before standardising it.

## Drift

Profiles accumulate. Extensions are installed once on a whim and never
removed, and Default is where they land, so the working set grows
monotonically unless something measures it. On this machine
`machine-config`'s `scripts/vscode-profiles.ps1 -Audit` reports these
failure modes among others — Default-only extensions, dangling formatter
references, live-vs-repo drift, and profiles re-linked to Default — and
exits non-zero on findings. It checks no `chat.*` setting.
