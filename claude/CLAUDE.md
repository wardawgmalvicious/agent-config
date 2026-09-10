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

- `python` / `python3` are Windows Store alias stubs — with arguments
  they fail with exit **49**, not "command not found". `pip` is absent,
  and the `C:\Python314\` PATH entries are dead.
- `python3.13` **does** work — uv's shim for the primary interpreter.
  Fine for a throwaway one-liner; anything with a dependency goes
  through `uv run`.

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

MSYS2 rewrites any Bash-tool argument starting with a slash into a
Windows path, so `claude -p "/code-review"` arrives as `C:/Program
Files/Git/code-review`. Quoting does not stop it and neither does
trailing text, and **it fails silently** — nothing reports the mangling.
Prefix with `MSYS2_ARG_CONV_EXCL='*'`, or run from PowerShell. (Probing
a skill's *slash* path has further traps; `test-skill` covers them.)

### "Permission denied" renaming a directory

Windows refuses a directory rename while any process holds an open
handle beneath it — an editor, a file watcher, Defender or the indexer
is enough — and MSYS2 surfaces that as `mv: cannot move 'x' to 'y':
Permission denied`. The hold is usually brief.

**Retry.** Don't switch shells: PowerShell `Move-Item` fails the same
way, and only appears to fix things when the retry lands after the
handle closes. Don't touch settings either — a Claude Code permission
or sandbox denial refuses *before* the program runs, so it never
arrives as the program's own error text.

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
author HTML/SVG and screenshot it headless with Edge instead, whose
**x86** path is the only one present (`C:\Program Files\Microsoft\Edge\`
is not there). Both paths must be absolute and the source needs the
`file:///C:/...` triple-slash form. Recipe and failure modes:
`agent-config/docs/social/README.md`.

PowerShell modules available: `Az`, `MicrosoftPowerBIMgmt`, `SqlServer`,
`Microsoft.Graph`, `ImportExcel`, `powershell-yaml`, `Pester`,
`PSScriptAnalyzer`, `Microsoft.PowerShell.SecretManagement` +
`SecretStore`, `PSFzf`. Pester has a version trap that reads as a syntax
error — see `~/.claude/rules/coding-powershell.md` before writing tests.

`az account clear` runs in interactive shells only: both profiles skip it
when `CLAUDECODE` is set, so an existing `az login` survives across tool
calls. Check `az account show` before assuming a login is needed — and
before assuming one exists.

### Git identity is folder-scoped

`~/.gitconfig` declares **no** identity; it arrives through `includeIf
gitdir:` — personal under `C:/Repos/Personal/`, work under a separate
client root. In a repo outside both roots `git commit` fails with
*"Please tell me who you are"*, which is deliberate rather than broken:
answer it with `git config --local user.email …` in that repo, never by
adding an identity to the global config. Why that is the shape, the
line-ending policy that lives beside it, and the four ways an
`includeIf` pattern silently matches nothing are in
`~/.claude/rules/git-identity-scoping.md`, which loads whenever a git
config file is opened.

**The GitHub API actor is a third identity, bound separately from both.**
`gh` and the project-scope `github-mcp` server carry separate tokens and
can resolve to **different GitHub accounts**. A PR or merge issued under
the wrong one is attributed to an account with nothing to do with the
`includeIf` author on the commits, and nothing warns. Since 2026-09-04
the shell profiles **folder-scope `gh`** the way git is, so `gh auth
status` reports the keyring's active account, **not** the one `gh` will
act as here — probe with `gh api user -q .login` and compare against the
repo before acting. The full procedure is in the `land` skill.

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
forward, and neither can pushed history — for **two** reasons, the
second of which gets missed. `refs/pull/N/head` pin every commit a PR
ever touched; and even with no PR refs at all, GitHub serves
unreachable objects by explicit SHA until it garbage-collects, on no
schedule you control. A `filter-repo` rewrite plus force-push therefore
does not remove a pushed leak — delete-and-recreate is the only
immediate remedy. The trap is that documenting machine-specific
behaviour is exactly when real account names read as subject matter
rather than as an incident.

The `identity-guard` hook (`~/.claude/hooks/`) turns that into a gate:
before a `git commit` it scans the added lines, after one it reads the
message back, and before a `git push` it scans every unpushed commit,
all against `~/.config/identity-denylist.txt` — a local file, in no
repo, because the list is itself the leak. It matches only what is on
the list, so a new client name is still yours to catch, and to add;
`exempt:` lines skip the client roots where the name belongs. gitleaks
is not this guard: it matches secrets, not names, and never reads a
message (measured 2026-09-04).

### Branch naming

`<type>/<kebab-slug>`, in every repo. `<type>` is the conventional-commit
vocabulary — `feat`, `fix`, `docs`, `refactor`, `chore`, plus `perf`,
`test`, `build`, `ci` where they apply — so a branch and the commits on
it agree without maintaining a second taxonomy. Not `feature`, not
`bugfix`, not `hotfix`: whatever `/commit` would write as the type is
the type.

`<slug>` names the subject in kebab-case, two to four words:
`feat/fabric-ontology-skill`, `fix/coding-kql-glob`,
`docs/semantic-model-briefs`. Prefer the noun the change is about over
the action taken on it — `git log` already carries the verb. No ticket
numbers, no dates, and no position or sequence markers (`wave-3`,
`part-2`): positions churn and the name outlives them.

A repo's own committed convention wins over this one. Check
`CONTRIBUTING.md`, or `git branch -a` for what the repo already does,
before naming the first branch in an unfamiliar repo.

## Agent config source

`~/.claude` is deployed from `C:\Repos\Personal\agent-config` by
`scripts/link-claude.ps1`. **`skills` is junctioned, and is the only
thing that is** — a `SKILL.md` edit is live in every session on this
machine the moment it hits disk. `agents`, `hooks`, `mcp` and `rules`
are **copies**; `CLAUDE.md` and `settings.json` are copies needing
`-Force`. An edit to any of those is **not live until the script runs
again**, and nothing says so. Repo layout, deployment mechanics and the
reasoning behind them live in that repo's own `CLAUDE.md`, which loads
in sessions there.

### GitHub Copilot no longer inherits this payload

Since 2026-09-09 every `chat.*Locations` entry pointing at a Claude
root is `false` in VS Code user settings, and `chat.useClaudeMdFile` is
off — so Copilot inherits none of `~/.claude`: not skills, rules,
agents, hooks, or this file. It reads `~/.copilot/*` and a repo's
`.github/*` instead, which `agent-config/scripts/copy-copilot.ps1`
vendors into a repo (there is no user-scope Copilot payload; the
`~/.copilot/*` roots are enabled but empty). Editing anything under
`~/.claude` therefore changes Claude Code's behaviour alone. The Claude
paths remain *documented defaults* on that surface — they are switched
off deliberately, not unsupported.

**An unlisted location keeps its default, and the default is on.** Each
setting is a location → boolean map *over* the documented defaults, so
turning inheritance off means writing every Claude root out as `false`.
Omitting one leaves it enabled with nothing to show for it:
`.claude/skills` and `.claude/rules` stayed live that way while every
root listed beside them read `false`.

**The Settings UI does not reliably persist these.** Object-valued
`chat.*` settings edited through the UI can leave `settings.json`
untouched with no error — measured 2026-09-09, repeated edits against
an mtime four days stale. Edit `%APPDATA%\Code\User\settings.json`
directly and check the mtime afterwards rather than trusting the UI.

### User-scope MCP servers are deliberately three

`~/.claude.json` holds top-level `mcpServers`, and that key is reconciled
against `agent-config/claude/mcp/.mcp.global.template.json` by
`scripts/link-claude.ps1 -GlobalMcp` — off by default even under
`-Force`, because that file is Claude Code's runtime state rather than
payload. User scope is `microsoft-learn-mcp`, `azure-mcp` and
`dockerhub-mcp`: servers useful in any repo. **Everything Fabric and
Power BI is project scope** (`<fabric-repo>/.mcp.json` and the like), so
those tools are absent here and that is not a fault to fix — a
user-scope server loads its whole tool surface into every session on the
machine, including ones where it cannot fire. Reach for a project's
`.mcp.json` rather than promoting a server to user scope.

That file has parsing traps that corrupt it silently, and Docker
Desktop re-adds an unfiltered `MCP_DOCKER` entry that double-loads every
azure and dockerhub tool. Both are covered in
`agent-config/claude/mcp/README.md`; read it before editing the file.

## Coding conventions

Per-language conventions live in `~/.claude/rules/coding-<lang>.md`,
auto-loaded via `paths:` globs when matching files are in session
scope. Project-scope overrides via `.claude/rules/coding-<lang>.md`
in client repos. See userPreferences for the cross-language summary.

Fabric Git-synced repo serialization guidance (EOF newlines, mixed
CRLF/LF, the auto-generated view header, `.gitattributes -text`) lives
in `~/.claude/rules/fabric-git-serialization.md`, auto-loaded when
Fabric item-definition files enter session scope.
