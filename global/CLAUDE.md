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

## Agent config source

`~/.claude/agents`, `hooks`, `mcp`, `rules`, and `skills` are directory
junctions into `C:\Repos\Personal\agent-config` — a file under either
path is the same file, and edits are committed from that repo.
`~/.claude/CLAUDE.md` and `settings.json` are plain copies: edit the
repo versions and re-run `scripts/link-claude.ps1 -Force`.

## Coding conventions

Per-language conventions live in `~/.claude/rules/coding-<lang>.md`,
auto-loaded via `paths:` globs when matching files are in session
scope. Project-scope overrides via `.claude/rules/coding-<lang>.md`
in client repos. See userPreferences for the cross-language summary.

Fabric Git-synced repo serialization guidance (EOF newlines, mixed
CRLF/LF, the auto-generated view header, `.gitattributes -text`) lives
in `~/.claude/rules/fabric-git-serialization.md`, auto-loaded when
Fabric item-definition files enter session scope.
