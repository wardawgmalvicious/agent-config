# `claude-code` — Claude Code releases

- `repo`: `anthropics/claude-code`
- `branch`: `main`
- `path`: `CHANGELOG.md`
- `shape`: `changelog`
- `sections`: none — the file is ~590 KB, far past the WebFetch
  summarization threshold, and there is no heading set worth re-fetching
  by name. This source is **github-mcp-only** in practice.
- `filter`: keep a bullet only if it names the config surface this repo
  owns — a `settings.json` key, a hook event or hook JSON field, skill /
  subagent / rule frontmatter, a `~/.claude/` path, a `permissions` rule,
  MCP config schema, plugin or marketplace layout, or a `claude` CLI flag
  the scripts and docs here reference. Everything else is bucket (d), and
  is not drilled.
- `drill.host`: `code.claude.com` (paths under `/docs/en/`) — **not**
  `docs.claude.com`
- `drill.via`: `webfetch`
- `drill.strip`: none — anchors here are stable heading slugs, so keep them
- `artifacts`: `claude/settings.json`, `claude/hooks/`, `claude/agents/`,
  skill and rule frontmatter, `claude/mcp/`, `claude/CLAUDE.md`, root
  `CLAUDE.md`, `.claude/rules/`, `scripts/link-claude.ps1`

This is the harness the rest of the config runs inside, so it is the one
source that can invalidate an artifact's *mechanism* rather than its
content — a renamed hook event or a moved `~/.claude` path breaks the
payload silently, exactly like the `vscode-agent` case.

Anthropic publishes no git-backed mirror of `code.claude.com/docs`, so
`CHANGELOG.md` is the only diffable surface for this product; the docs
pages are Phase 3 drill targets only. `feed.xml` in the same repo is the
same content as RSS and is not a better source. `examples/settings/`,
`examples/hooks/`, and `examples/mdm/` are small and directly relevant,
but they are illustrations rather than spec — the changelog announces
every change they would eventually reflect.

Two measured facts drive the fields above, both of which stress the
pipeline harder than the What's New sources do:

- **Volume, per window length.** Two measured samples, not one operating
  range: ~29 commits and ~550 bullets across 35 days, and 85 commits,
  77 version sections and 1713 bullets across 89 days. That is roughly
  **0.95 commits/day and ~19 bullets/day** — scale by the window rather
  than reading the 35-day figures as the source's steady state. Roughly
  two thirds of bullets are `Fixed` TUI or platform bugs, so without
  `filter` the report is unreadable; the 89-day run passed 418 of 1713
  bullets, which is the evidence the filter earns its place. Do not filter
  on the leading verb alone, though — `Fixed Grep and Glob not applying
  Read(...) deny rules to files reached through a symlinked search path`
  is a permissions-model finding wearing a bugfix prefix.
- **Size.** ~590 KB, 380+ version sections, and it only grows. This is why
  SKILL.md § 4a treats `changelog` sources specially: letting two full
  files into context to diff them would pull ~1.2 MB to learn what a small
  append-at-top region already says. The bound is not "always patch" — it
  is to keep the full files out of the conversation, by per-commit patch
  on short windows and by an on-disk two-ref diff on long ones.

**This source never produces a new-skill candidate, and that is deliberate.**
The harness ships live coverage of itself — the `claude-code-guide` subagent
plus first-party `update-config`, `keybindings-help`, and `plugin-dev:*`
skills — all refreshing faster than a monthly audit can. A repo-authored
reference skill would compete for the same triggers against always-current
content and lose *silently*, because a skill's `description` is the entire
trigger mechanism. What is repo-specific here is not "how Claude Code works"
but "how this payload is wired into it": the junction-vs-copy split, why
`settings.json` is copied, the fixture procedure. Those belong in root
`CLAUDE.md` and `.claude/rules/` (sessions here), `README.md` (cherry-pickers),
and this audit's own `docs/audits/<date>/claude-code/` ledger (dated
evidence). Findings land on the `artifacts` above; bucket (b) stays empty.
Checked 2026-08-30 — the 2026-08-29 run's 418 filtered bullets across 89 days
produced zero new-skill candidates, which is the expected result, not a thin
one.
