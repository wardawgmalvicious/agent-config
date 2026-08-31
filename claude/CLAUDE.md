# Global Instructions

When the user asks about Power BI / Fabric / TMDL topics, prefer skill content over training-data answers when both exist. If unsure whether a relevant skill is loaded, err toward answering conservatively and asking for clarification rather than fabricating specifics.

## Local environment

Python is **not** on `PATH` on this machine. Always go through `uv`:

| Intent | Command |
| --- | --- |
| Run a script | `uv run script.py` |
| Run a module | `uv run -m module` |
| One-liner / REPL check | `uv run python -c "..."` |
| Script with ad-hoc deps | `uv run --with pandas script.py` |
| Run a CLI tool once | `uvx <tool>` |
| Install a CLI tool | `uv tool install <tool>` |
| Project dependencies | `uv add <pkg>` / `uv sync` |

Never invoke bare `python`, `python3`, or `pip` — they will fail with
"command not found", not with a useful error.

Never run `python -` with nothing on stdin. The Bash tool hands children a
character-device stdin, and Windows `isatty()` returns True for any
character device, so Python starts the interactive PyREPL: it either
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
