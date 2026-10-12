# Declined MCP servers

Servers weighed for the [templates](README.md) and refused. Read this
before weighing one, so a refused server is not weighed again on the old
evidence. Entries are dated and never corrected in place: a server that
comes back with new evidence gets a new entry.

## 2026-10-12 — Context7 as the docs layer for Apache Spark and other libraries

- **From**: the user, with an M365 Copilot answer proposing three
  layers: the Learn server for Fabric, Context7 for Apache Spark, pandas
  and other libraries, and the repo for its own code. Weighed against a
  client Fabric repo's notebooks.
- **Why not**: version is that layer's whole job, and Context7's
  `/apache/spark` index is `master`, tagged only `v3_5_1` and `v3_5_2`,
  so it pins neither Runtime 1.3's Spark 3.5.5 nor Runtime 2.0's Spark
  4.1. The client repo reaches Spark through `spark.sql()` strings,
  `notebookutils` and `spark.conf`, not the DataFrame API, so Learn and
  Apache's SQL reference already cover it. Context7 stores each query
  for benchmarking and passes it to OpenAI, Google Gemini and Anthropic
  for reranking (its data-safety page), so client-work questions leave
  the machine. A library's owners also write into the agent's context,
  through `context7.json`'s `rules`: CVE-2026-75130, published
  2026-08-18 against Context7 through 2.1.2, is prompt injection by that
  route, Noma's ContextCrush report its reference, and the record names
  no fixed version. In auto mode, beside tenant logins and `GITHUB_PAT_*`
  variables, that is a path to both. Spark's own versioned docs serve
  with none of this, and `25197ee` routes `fabric-spark` to them.
- **Would change it**: a personal repo on a fast-moving library that
  publishes no versioned docs. It would go in that repo's `.mcp.json` as
  the bare remote entry, never through `npx ctx7 setup` or the plugin,
  each of which installs a rule or skill sending every library question
  to Context7. Not at user scope, though it is docs lookup: its queries
  leave the machine, so it is bound to what a repo may send.

## 2026-10-12 — DesktopCommanderMCP for Office files and file search

- **From**: the user, for the user-scope template, drawn by its PDF,
  DOCX and Excel support and its file search. Weighed from its source
  at `v0.2.52`, the version its documented `@latest` install fetched
  that day.
- **Why not**: most of its 26 tools are a second route to the files and
  the shell that the guards here never see, and the one gap it fills,
  Office files, Bash fills too. `identity-guard` matches only
  `Bash|PowerShell`, and `paths:` rules and skills load only on Claude
  Code's own Read, Write and Edit: a commit through its `start_process`
  skips the identity check wherever no pre-commit hook repeats it, and
  a `.tmdl` read through it loads no TMDL guidance. Its file tools
  default to `allowedDirectories: []`, the whole disk, and its
  `set_config_value` lets the model change that, `blockedCommands` and
  `telemetryEnabled`; its `SECURITY.md` says its restrictions "can be
  circumvented by design". Telemetry is on by default, and every 30
  minutes it fetches a flags file from `desktopcommander.app`, which
  the telemetry opt-out does not stop. Two of those flags append
  `[SYSTEM INSTRUCTION]` text to tool results, asking for feedback or
  starting an onboarding flow: both off in the live file that day, but
  the vendor can switch them on for every install without a release.
  Every call's arguments, whole files written and command-line tokens
  included, go "not redacted or sanitized" (its README) to
  `claude_tool_call.log` in the user profile, and it never deletes a
  rotated log. Scope is not the reason: the README's test would pass
  it, as it is bound to no tenant or workspace. The gap: Read opens PDFs
  but no DOCX, PPTX or XLSX, and `0778339` hid the synced Office skills
  from Claude. DuckDB's `excel` extension reads and writes XLSX,
  markitdown, proposed to machine-config as a global uv tool the same
  day, converts DOCX and PPTX to Markdown, and Grep, Glob and `es`
  already search.
- **Would change it**: a need for a REPL held open across turns, which
  its `interact_with_process` gives and nothing here does. It would go
  at local scope in that one repo, pinned rather than `@latest`, with
  `DESKTOP_COMMANDER_DISABLE_TELEMETRY=1`; neither the pin nor the
  opt-out stops the flags fetch.
