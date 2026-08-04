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

## Fabric Git-synced repos: portal serialization

Fabric re-serializes an item's definition files whenever the item is
committed from the portal, and its canonical form for JSON and SQL
parts (`pipeline-content.json`, `variables.json`, eventstream/report
JSON, Warehouse `.sql` scripts) **has no final newline** — a trailing
newline added locally is stripped on the next portal round-trip,
producing a whitespace-only diff. TMDL, `notebook-content.*`, and
`.kql` parts *do* end with a newline.

When editing files inside `*.{ItemType}` folders of a Fabric
Git-synced repo:

- **Preserve the file's existing EOF exactly** — never append a final
  newline to a file that lacks one, never remove one that's there.
- New JSON / SQL item parts: end at the last character, no final
  newline. New TMDL / notebook / KQL parts: end with one.
- Don't "clean up" portal-written formatting in Warehouse scripts —
  trailing spaces after commas in table DDL and the
  `-- Auto Generated (Do not modify) <hash>` header on views are
  reapplied by the portal on every sync.
