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

Per-language conventions live in this repo's `rules/coding-<lang>.md`
files (Claude Code loads them from `~/.claude/rules/coding-<lang>.md`
via directory junction, auto-triggered by each rule's `paths:`
frontmatter glob). Project-scope overrides via
`.claude/rules/coding-<lang>.md` in client repos.

Fabric Git-synced repo serialization guidance (EOF newlines, mixed
CRLF/LF, the auto-generated view header, `.gitattributes -text`) lives
in `rules/fabric-git-serialization.md`, auto-loaded in tools that
support path-scoped rules when Fabric item-definition files enter
session scope.

## About this file

This mirrors [global/CLAUDE.md](CLAUDE.md) — same content, for tools
that look for `AGENTS.md` instead of `CLAUDE.md`. Unlike
`global/CLAUDE.md` (deployed to `~/.claude/CLAUDE.md` by
[scripts/link-claude.ps1](../scripts/link-claude.ps1)), there's no
single well-known user-global path across every `AGENTS.md`-aware tool,
so this file isn't wired into a deploy script — copy it to wherever
your own tool looks for a personal, cross-repo instructions file, or
merge it into an existing one.
