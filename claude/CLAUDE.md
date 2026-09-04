# Global Instructions

When the user asks about Power BI / Fabric / TMDL topics, prefer skill content over training-data answers when both exist. If unsure whether a relevant skill is loaded, err toward answering conservatively and asking for clarification rather than fabricating specifics.

## Local environment

Windows 11. Two shells, each spawned fresh and non-interactive per tool
call: PowerShell 7.6 (`pwsh`) and Git Bash (mingw64). Both profiles print
a two-line banner (`Profile and functions loaded…`) ahead of your
command's output — that is the profile, not your command.
`C:\Repos\Personal\machine-config` is the source of truth for what is
installed here and how it is configured.

**A process spawn costs ~0.4 s here, in both tool shells and from a
real console** (measured 2026-09-04: 120 `git`/`date` spawns in 46 s,
the same rate from a `start`-ed window). Bash scripts that fork per
line — a `$(...)` per iteration, a pipeline per case — therefore run
at a tenth of the speed you would guess, and a run that is merely
slow looks exactly like a hang: the tool's 120 s default kills it, and
`timeout` kills the children too, which surfaces as stray
`write error: Permission denied` / `Invalid argument` lines that read
like a bug. Do the arithmetic (spawns × 0.4 s) before diagnosing a
hang, give such runs a ten-minute cap in the background, and design
hooks for spawn economy — see `~/.claude/hooks/identity-guard.sh`.

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

### Writing files that contain backslashes

Two separate things eat backslashes here. Keep them apart — the remedy
differs, and blaming the wrong one sends you looking in the wrong place.

**The Bash tool collapses `\\` into `\`, including inside a quoted
heredoc.** A *single* backslash survives untouched, so Windows paths and
`\n` / `\t` / `\R` pass through fine; the PowerShell tool does neither.
What breaks is content that legitimately needs a doubled backslash: a
Python `'\\n'` arrives as `'\n'` and becomes a real newline, silently
corrupting the file with no error and no failed assertion. Build such
backslashes in-language (`chr(92)` in Python) or use the Write/Edit
tools, which are unaffected. Verified Sep 2026 — `\\` to `\`, `\\\\` to
`\\`, singles intact, both bare command text and `<<'EOF'`.

**Backslashes vanishing from a `sed` or `perl -e` expression are that
program's doing, not the tool's.** `sed 's|x|C:\Repos\Personal|'` yields
`C:ReposPersonal` — and still does when sed reads the script from a
file, which rules the tool out entirely. Undefined regex escapes are
simply dropped. So write Windows paths through a **quoted heredoc**
(`cat > file <<'EOF'`) to keep them away from a regex engine, and verify
the result. That remedy is sound; only its stated cause was wrong.
PowerShell here-strings (`@'...'@`) cannot be used inline in the Bash
tool at all, and they **fail silently rather than erroring** — the
delimiters are passed through as literal text. Put them in a `.ps1`
written by a quoted heredoc and run that file instead. Silent case
verified 2026-09-02.

### A leading `/` argument becomes a Git install path

MSYS2 rewrites any argument starting with a slash into a Windows path,
so `claude -p "/code-review"` from the Bash tool arrives as
`C:/Program Files/Git/code-review`. Quoting does not stop it, and
neither does trailing text: `"/my-skill do the thing"` becomes
`C:/Program Files/Git/my-skill do the thing`.

**It fails silently and looks like success.** No slash command is
parsed, so nothing is expanded — the model just reads a message that
happens to name a skill and invokes it through the Skill tool. The
answer is right and the skill did run, so a probe written to test
*slash* invocation has actually tested model-invocation. That matters
because a skill's `model:` pin is honoured on one path and dropped on
the other.

Run such a probe from PowerShell, or prefix the Bash one with
`MSYS2_ARG_CONV_EXCL='*'`. Both yield the real thing: a
`<command-name>` record, no `Skill` tool_use, the body inlined.
Measured 2026-09-02 on two skills.

### "Permission denied" renaming a directory

Windows refuses a directory rename while any process holds an open
handle beneath it; MSYS2 maps that to `EACCES`, so it surfaces as
`mv: cannot move 'x' to 'y': Permission denied`. An editor, a file
watcher, Defender or the search indexer is enough, and the hold is
usually brief.

**Retry — don't switch shells, and don't touch settings.** PowerShell
`Move-Item` fails the same way ("The process cannot access the file
because it is being used by another process"); it only appears to fix
things when the retry happens to land after the handle closes. A Claude
Code permission or sandbox denial refuses *before* the program runs, so
it never arrives as the program's own error text — nothing in
`settings.json` or `settings.local.json` is involved. Measured
2026-09-02 by holding a `FileStream` on a child file: Git Bash `mv` and
`git mv` both failed, both succeeded the instant it closed.

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

**`bash` from PowerShell is WSL, not Git Bash.** `Get-Command bash`
resolves to `C:\WINDOWS\system32\bash.exe`, so calling it from `pwsh`
enters WSL and fails on Windows paths with a relay error —
`execvpe(/bin/bash) failed: No such file or directory` — which reads
like a missing tool and isn't. Use
`& 'C:\Program Files\Git\bin\bash.exe'` explicitly for the mingw64
shell from PowerShell. (`sh` resolves to nothing at all.) Verified
2026-09-02.

**No image *generation*, but HTML renders to PNG with no install.** No
image model is available, so a picture can't be made from a prompt —
author HTML/SVG and screenshot it headless instead, which covers social
cards, diagrams and badges. Edge is the renderer, and only its **x86**
path exists (`C:\Program Files\Microsoft\Edge\` is not there):

    msedge --headless=new --disable-gpu --hide-scrollbars \
      --window-size=1280,640 --screenshot="C:/abs/out.png" "file:///C:/abs/in.html"

Both paths must be absolute and the source needs the `file:///C:/...`
triple-slash form. The PNG comes out exactly `--window-size` px and is
reproducible byte-for-byte. Success prints `N bytes written to file`; a
`fallback_task_provider.cc ... ERROR` line on stderr is noise, not a
failure. Verified 2026-09-02.

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
`C:/Repos/Personal/`, work under a separate client root — see
`~/.gitconfig` for the actual paths. In a repo outside both
roots `git commit` fails with *"Please tell me who you are"*, which is
deliberate: without `useConfigOnly`, git silently invents an author from
the domain-joined machine's AD record, i.e. the corporate email. Set one
explicitly there with `git config --local user.email …` rather than
touching the global config. `core.autocrlf` is `false` globally on
purpose; line-ending policy is per repo via a committed `.gitattributes`.

**The GitHub API actor is a third identity, bound separately from both.**
`gh` keeps one keyring entry per account it has logged into, with one
*active*, and the `github-mcp` server carries its own token (project
scope, in a repo's `.mcp.json`), so the two can resolve to **different
GitHub accounts**. A PR or merge issued under the wrong one is
attributed to an account with nothing to do with the `includeIf` author
on the commits, and nothing warns. Since 2026-09-04 the shell profiles
**folder-scope `gh`** the way git is: the wrapper reads the repo's
`user.name`, and when that is a logged-in account it runs `gh` under a
per-call `GH_TOKEN` for it. So `gh auth status` reports the keyring's
active account, **not** the one `gh` will act as here — probe with
`gh api user -q .login`, compare it with the MCP `get_me` where that
server is loaded, and use whichever matches the repo. A script or hook
that skips the profile gets the active account.

**Identity leaks through file content too, and the guard is a denylist.**
`useConfigOnly` protects the author field only. An **organization's**
account names — `AzureAD\…` / Entra accounts, tenant names, internal
hostnames — never go into a file or a commit message, whatever the
repo's visibility: private is a setting rather than a property, the
information is the employer's rather than yours to publish, and a
privileged account name is half a credential. **Your own** profile path
is the lesser case and the reason is portability, not privacy —
`C:\Users\<you>` in a doc describing how to set up *a* machine is a bug
before it is a leak. Write `~`, `$env:USERPROFILE` or `<username>`
unless the literal string is the point.

Check before committing, not after: a commit message cannot be fixed
forward. The trap is that documenting machine-specific behaviour is
exactly when real account names read as the subject matter rather than
as an incident. Hit in `machine-config` 2026-09-03 — both accounts
landed in the body *and* the message, and only the body could be
corrected. And once pushed, history cannot be fixed either: GitHub's
`refs/pull/N/head` are permanent and pin every commit a PR ever
touched, so `git filter-repo` plus a force-push leaves the leak
reachable, and the only effective remedy is to delete and recreate the
repo — done for `agent-config` on 2026-09-04, at the cost of its stars,
PRs and creation date.

The `identity-guard` hook (`~/.claude/hooks/`) turns that into a gate:
before a `git commit` it scans the added lines, after one it reads the
message back, and before a `git push` it scans every unpushed commit,
all against `~/.config/identity-denylist.txt` — a local file, in no
repo, because the list is itself the leak. It matches only what is on
the list, so a new client name is still yours to catch, and to add;
`exempt:` lines skip the client roots where the name belongs. gitleaks
is not this guard: it matches secrets, not names, and never reads a
message (measured 2026-09-04).

## Agent config source

`~/.claude/agents`, `hooks`, `mcp`, and `rules` are **copies** taken
from `C:\Repos\Personal\agent-config` by `scripts/link-claude.ps1`, so
editing the repo does **not** change them until that script runs again.
They were junctions until 2026-09-02; the change is deliberate, because
none of the four is hot-reloaded — a fresh session was needed either way
— so immediacy bought nothing while making every uncommitted save, and
every `git switch`/`stash`/`rebase`, live for every session on the
machine. Hooks were the sharp end: they execute.

The repo side is **not** flat: `agents`, `hooks`, `mcp`, and `rules`
live under `agent-config/claude/`, because they are written in Claude
Code's own formats. Only `skills` sits at the repo root, in the
tool-neutral Agent Skills format, grouped by domain (`fabric/`,
`powerbi/`, `workflow/`). Claude Code discovers a skill one level down
only, so `~/.claude/skills` is a real directory holding one junction per
skill rather than a single junction; `-SkillGroups` chooses which groups
deploy, and `-ClaudeDir` can target a project instead of home.

**`skills` is still junctioned, and is now the only thing that is** — it
is the one payload Claude Code watches, so edit-to-live is the authoring
loop rather than a hazard. A skill edit is live immediately; an agent,
hook, rule or MCP-template edit is not live until the script runs.

`~/.claude/CLAUDE.md` and `settings.json` are plain copies too, of
`claude/CLAUDE.md` and `claude/settings.json`, but on stricter terms:
they need `-Force` to overwrite, because Claude Code rewrites the live
`settings.json` at runtime. Edit the repo versions and re-run
`scripts/link-claude.ps1 -Force`.

## Coding conventions

Per-language conventions live in `~/.claude/rules/coding-<lang>.md`,
auto-loaded via `paths:` globs when matching files are in session
scope. Project-scope overrides via `.claude/rules/coding-<lang>.md`
in client repos. See userPreferences for the cross-language summary.

Fabric Git-synced repo serialization guidance (EOF newlines, mixed
CRLF/LF, the auto-generated view header, `.gitattributes -text`) lives
in `~/.claude/rules/fabric-git-serialization.md`, auto-loaded when
Fabric item-definition files enter session scope.
