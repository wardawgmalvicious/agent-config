# `claude-code` — Claude Code releases

- `repo`: `anthropics/claude-code`
- `branch`: `main`
- `path`: `CHANGELOG.md`
- `shape`: `changelog`
- `sections`: none — the file is 945 KB (2026-10-06), far past the
  100,000 characters WebFetch reads per call (SKILL.md § 4b), and there
  is no heading set worth re-fetching by name. This source is
  **github-mcp-only** in practice.
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

- **Volume, per window length.** Three measured samples, not one operating
  range: ~29 commits and ~550 bullets across 35 days; 85 commits, 77
  version sections and 1713 bullets across 89 days; and 38 commits, 34
  version sections and 2336 bullets across the 39 days to 2026-10-06.
  Commits hold near one a day in all three, but bullets ran ~16 and ~19
  a day in the first two and ~60 in the third, so the bullet rate moves
  from window to window and is **no constant to scale by**. Roughly
  two thirds of bullets are `Fixed` TUI or platform bugs, so without
  `filter` the report is unreadable; the 89-day run passed 418 of 1713
  bullets, which is the evidence the filter earns its place. Do not filter
  on the leading verb alone, though — `Fixed Grep and Glob not applying
  Read(...) deny rules to files reached through a symlinked search path`
  is a permissions-model finding wearing a bugfix prefix.
- **Size.** 945 KB and 414 version sections on 2026-10-06, and it only
  grows. This is why
  SKILL.md § 4a treats `changelog` sources specially: letting two full
  files into context to diff them would pull ~1.2 MB to learn what a small
  append-at-top region already says. The bound is not "always patch" — it
  is to keep the full files out of the conversation, by per-commit patch
  on short windows and by an on-disk two-ref diff on long ones. On a
  five-week window the new region alone outgrows the ~150 KB per-source
  budget — 358 KB in the 39 days to 2026-10-06 — and must be read in
  slices of about 420 lines to pass the Read tool's 25,000-token cap. The
  file is a prepend almost always, but a bullet is now and then reworded
  in place — one 2.1.252 bullet in that window — so a run reads the
  diff's removed lines too.

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
