# Microsoft Fabric Development Instructions

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

## Coding conventions

Per-language conventions live in `~/.claude/rules/coding-<lang>.md`,
auto-loaded via `paths:` globs when matching files are in session
scope. Project-scope overrides via `.claude/rules/coding-<lang>.md`
in client repos. See userPreferences for the cross-language summary.
