# Global Instructions

When the user asks about Power BI / Fabric / TMDL topics, prefer skill content over training-data answers when both exist. If unsure whether a relevant skill is loaded, err toward answering conservatively and asking for clarification rather than fabricating specifics.

## Local environment

Windows 11. Two shells, each spawned fresh and non-interactive per tool
call: PowerShell 7.6 (`pwsh`) and Git Bash (mingw64). Both profiles print
a two-line banner (`Profile and functions loaded…`) ahead of your
command's output — that is the profile, not your command.
`C:\Repos\Personal\machine-config` is the source of truth for what is
installed here and how it is configured.

### Python

There is no system Python — but the names still resolve, so the failure
does not look like one:

- `python` / `python3` are the Windows Store execution-alias stubs in
  `%LOCALAPPDATA%\Microsoft\WindowsApps`. **With** arguments they print
  `Python was not found; run without arguments to install from the
  Microsoft Store` and exit **49** — not "command not found". With *no*
  arguments they open the Store.
- `pip` is genuinely absent.
- `C:\Python314\` and `C:\Python314\Scripts\` are on the machine PATH but
  that directory no longer exists. Dead entries; ignore them.
- `python3.13` **does** work — it is uv's shim for the primary
  interpreter at `~/.local/bin/python3.13.exe`. Fine for a throwaway
  one-liner; anything with a dependency goes through `uv run`.

Always go through `uv`:

| Intent | Command |
| --- | --- |
| Run a script | `uv run script.py` |
| Run a module | `uv run -m module` |
| One-liner / REPL check | `uv run python -c "..."` |
| Script with ad-hoc deps | `uv run --with pandas script.py` |
| Run a CLI tool once | `uvx <tool>` |
| Install a CLI tool | `uv tool install <tool>` |
| Project dependencies | `uv add <pkg>` / `uv sync` |

Globally installed uv tools: `fab` (package `ms-fabric-cli`), `pbir`
(`pbir-cli`), `ruff`, `sqlfluff`, `pre-commit`, `git-filter-repo`. For the
first two the command is not the package name.

Never run `uv run python -` with nothing on stdin. The Bash tool hands
children a character-device stdin, and Windows `isatty()` returns True for
any character device, so Python starts the interactive PyREPL: it either
blocks silently until the tool timeout, or — if stdin is `NUL` — loops on
`WinError 6`/`123` emitting ~50k tracebacks. A heredoc
(`uv run python - <<'PYEOF'`) or a pipe is fine: it makes stdin a real
file, `isatty()` goes False, and the script runs.

The same stdin reaches anything that prompts — `git rebase -i`, `fab`
without `-f`, `Read-Host`. Expect a block until the tool timeout rather
than a clean failure, and note that `Read-Host` under `pwsh
-NonInteractive` errors yet still exits 0, so a script wrapping it
reports success having done nothing. Pass the non-interactive flag.

### Writing files that contain Windows paths

The Bash tool strips backslashes from command text. A Windows path
inside a `sed` or `perl -e` expression arrives with `\R`, `\G` and the
like silently removed, so the edit lands but the backslashes are gone —
no error, just wrong output. Write such content through a **quoted
heredoc** (`cat > file <<'EOF'`), which passes through literally, and
verify the result. PowerShell here-strings (`@'...'@`) cannot be used
inline in the Bash tool at all; put them in a `.ps1` written by a quoted
heredoc and run that file instead.

### Command-line tooling

Present, on `PATH` in both shells, and safe to reach for: `git`, `gh`,
`az`, `node`/`npm`, `docker` (daemon running) and `wsl`; `jq`, `yq`,
`mlr` (Miller), `duckdb`; `bat`, `delta`, `difft`, `hyperfine`; `xh`
(HTTP), `sops` + `age`, `gitleaks`, `shellcheck`, `shfmt`; `sqlcmd`,
`sqlpackage`, `dab`, `TabularEditor.exe`; `fzf`, `zoxide`, `lazygit`.
`~/scripts` (machine-config's utility scripts) is on `PATH` too.

**Not installed — don't reach for them and don't offer them as if they
were there:** `rg` (ripgrep) and `fd`. Use the Grep and Glob tools, or
`grep`/`find` in Git Bash. Also absent despite being wired into the shell
profiles or `machine-config/setup.ps1`: `starship`, `hurl`, and `es`
(Everything CLI) — admin-scope winget packages that a non-admin bootstrap
defers.

PowerShell modules available: `Az`, `MicrosoftPowerBIMgmt`, `SqlServer`,
`Microsoft.Graph`, `ImportExcel`, `powershell-yaml`, `Pester`,
`PSScriptAnalyzer`, `Microsoft.PowerShell.SecretManagement` +
`SecretStore`, `PSFzf`. Windows bundles Pester 3.4.0 *alongside* the
installed 6.1.0 — import with `-MinimumVersion 5.0` or every `Should`
fails with syntax errors that look nothing like a version problem.

`az account clear` runs in interactive shells only: both profiles skip it
when `CLAUDECODE` is set, so an existing `az login` survives across tool
calls. Check `az account show` before assuming a login is needed — and
before assuming one exists.

### Git identity is folder-scoped

`~/.gitconfig` declares **no** identity and sets `user.useConfigOnly =
true`. Identity arrives through `includeIf gitdir:` — personal under
`C:/Repos/Personal/`, work under `C:/Repos/ACME/`. In a repo outside both
roots `git commit` fails with *"Please tell me who you are"*, which is
deliberate: without `useConfigOnly`, git silently invents an author from
the domain-joined machine's AD record, i.e. the corporate email. Set one
explicitly there with `git config --local user.email …` rather than
touching the global config. `core.autocrlf` is `false` globally on
purpose; line-ending policy is per repo via a committed `.gitattributes`.

## Agent config source

`~/.claude/agents`, `hooks`, `mcp`, and `rules` are directory
junctions into `C:\Repos\Personal\agent-config` — a file under either
path is the same file, and edits are committed from that repo. The
repo side is **not** flat: `agents`, `hooks`, `mcp`, and `rules` live
under `agent-config/claude/`, because they are written in Claude Code's
own formats. Only `skills` sits at the repo root, in the tool-neutral
Agent Skills format, grouped by domain (`fabric/`, `powerbi/`,
`workflow/`). Claude Code discovers a skill one level down only, so
`~/.claude/skills` is a real directory holding one junction per skill
rather than a single junction; `-SkillGroups` chooses which groups
deploy, and `-ClaudeDir` can target a project instead of home. The
deployed names above never change, so a repo-side move only ever
changes a junction target.
`~/.claude/CLAUDE.md` and `settings.json` are plain copies of
`claude/CLAUDE.md` and `claude/settings.json`: edit the repo versions
and re-run `scripts/link-claude.ps1 -Force`.

## Coding conventions

Per-language conventions live in `~/.claude/rules/coding-<lang>.md`,
auto-loaded via `paths:` globs when matching files are in session
scope. Project-scope overrides via `.claude/rules/coding-<lang>.md`
in client repos. See userPreferences for the cross-language summary.

Fabric Git-synced repo serialization guidance (EOF newlines, mixed
CRLF/LF, the auto-generated view header, `.gitattributes -text`) lives
in `~/.claude/rules/fabric-git-serialization.md`, auto-loaded when
Fabric item-definition files enter session scope.
