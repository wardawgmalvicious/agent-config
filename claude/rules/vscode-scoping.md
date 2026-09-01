---
paths:
  - "**/.vscode/*.json"
  - "**/*.code-workspace"
  - "**/vscode/profiles/*.json"
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
| **`.code-workspace`** | either | multi-root folder set | Only when a window genuinely needs two repos open at once |

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
`machine-config`'s `scripts/vscode-profiles.ps1 -Audit` reports the four
failure modes above — Default-only extensions, dangling formatter
references, live-vs-repo drift, and profiles re-linked to Default — and
exits non-zero on findings.
