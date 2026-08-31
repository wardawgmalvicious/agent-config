# Drift-audit source registry

The audit input. `SKILL.md` holds the pipeline; this file holds what the
pipeline runs against. Adding a domain to the audit is an entry here, not
a change to the skill body.

Each `id` below is what `--sources` accepts.

## Entry schema

| Field | Meaning |
| --- | --- |
| `id` | Slug. What `--sources` matches on. Lowercase, no spaces. |
| `label` | Human name for the report's audit-window section. |
| `repo` / `branch` / `path` | GitHub-hosted markdown. Enables the github-mcp fetch path and raw-URL fallback. `path` may be a single file or a directory. |
| `files` | Optional; meaningful only when `path` is a directory. The filenames under it worth fetching. `path` drives the `list_commits` filter, `files` drives `get_file_contents` — which returns a directory listing, not content, if handed the directory. |
| `url` | Non-GitHub source. WebFetch only; no commit list, so the window is resolved by the page's own dated entries. |
| `shape` | `table`, `prose`, or `changelog`. Drives extraction — see Shape contracts. |
| `columns` | `table` shape only: which columns carry the feature name, the description, and the preview/GA status. |
| `sections` | H2 / H3 headings used for targeted re-fetch when the WebFetch fallback summarizes the page. Ignored on the github-mcp path. |
| `filter` | Optional. Which entries are worth reporting, for sources whose volume would otherwise swamp the report. Entries it excludes go straight to bucket (d) undrilled. |
| `drill.host` | Doc host the source's rows link into. |
| `drill.via` | `microsoft-learn-mcp` or `webfetch`. How Phase 3 opens a linked page. |
| `drill.strip` | Unstable anchor patterns to remove from every URL before it reaches the report. |
| `artifacts` | Artifact classes this source can produce findings against. Narrows the Phase 2 scans. |

## Registered sources

### `fabric` — Microsoft Fabric (incl. RTI)

- `repo`: `MicrosoftDocs/fabric-docs`
- `branch`: `main`
- `path`: `docs/fundamentals/whats-new.md`
- `shape`: `table`
- `columns`: feature = `Feature`, description = `Description`, status = `Currently in preview`
- `sections`: `Generally available features`, `Features currently in preview`,
  `Microsoft Fabric Platform Features`, and the per-workload subsections
  (Data Factory, Data Engineering, Data Science, Real-Time Intelligence,
  Data Warehouse, Databases, OneLake, Fabric platform)
- `drill.host`: `learn.microsoft.com`
- `drill.via`: `microsoft-learn-mcp`
- `drill.strip`: `#post-NNNN-_TocNNNN`, any `#post-...`, and `#toc-hId-<signed-int>`
  — the community-blog table-of-contents form. **The integer is signed**, so the
  hyphen doubles on negatives (`#toc-hId-1329740083` *and* `#toc-hId--1208717068`);
  a pattern anchored on one hyphen misses roughly half. At 2026-08-29 the page
  carried 37 of these against 14 `#post-...`, so both forms are live — the
  `#post-...` patterns are incomplete, not superseded.
- `artifacts`: skills, rules, `CLAUDE.md`, MCP templates

Real-Time Intelligence has no separate What's New page — RTI updates fold
into this source. Don't search for one.

### `powerbi` — Power BI

- `repo`: `MicrosoftDocs/powerbi-docs`
- `branch`: `main`
- `path`: `powerbi-docs/fundamentals/whats-new.md`
- `shape`: `table`
- `columns`: feature = `Feature`, description = `Description`, status = `Currently in preview`
- `sections`: `Generally available features`, `Features currently in preview`,
  `Power BI updates`
- `drill.host`: `learn.microsoft.com`
- `drill.via`: `microsoft-learn-mcp`
- `drill.strip`: `#post-NNNN-_TocNNNN`, any `#post-...` — deliberately **not**
  the `#toc-hId-*` form the `fabric` entry strips. Checked 2026-08-29: this page
  carried zero of them (it is a single-month document with two unanchored
  community-blog links). Don't copy the pattern across on the assumption that
  the two pages render alike; re-check if that ever changes.
- `artifacts`: skills, rules, `CLAUDE.md`, MCP templates

### `vscode-agent` — VS Code agent customization surface

- `repo`: `microsoft/vscode-docs`
- `branch`: `main`
- `path`: `docs/agent-customization/`
- `files`: `custom-instructions.md`, `agent-skills.md`, `custom-agents.md`,
  `hooks.md` — the four pages describing where VS Code looks for each
  artifact class
- `shape`: `prose`
- `sections`: none — the four pages are individually small, so the fetch
  unit is the whole file (see `files`), and there is no heading worth
  re-fetching by name.
- `drill.host`: `code.visualstudio.com`
- `drill.via`: `webfetch`
- `artifacts`: `README.md`, root `CLAUDE.md`, `scripts/README.md`,
  `scripts/link-claude.ps1`

Governs how this repo's `~/.claude` payload reaches GitHub Copilot, so its
findings land on the repo's own deployment docs rather than on skills and
rules. Claims about this surface go stale silently, and are as often wrong
on arrival: `scripts/link-copilot.ps1` was written to work around a
`chat.agentSkillsLocations` gap that had already been closed for two
months, and the audit that retired the script is what caught it. Pin such
claims to a date you have checked, not to a version you have inferred.
VS Code ships monthly — faster than the Fabric cadence — and moves these
pages (they were under `docs/copilot/customization/` until the 2026
reorg), so a 404 on the path means find the new one, not that the source
is gone. `list_commits` does not follow renames, so a window that
straddles a move resolves its prior ref against the *old* path: filtering
`docs/agent-customization/` with `until:` a 2026-06-01 floor returns
nothing at all, and the directory reads as newly created rather than
renamed. The pre-reorg state is under `docs/copilot/customization/`
(`b9731d7c` is its last commit before that floor). Diff across the two
paths rather than reading the empty listing as "no prior state."
This repo also squashes a whole release branch into one commit,
so its commit *messages* run to thousands of characters — list with
`fields: ["sha"]` and let SKILL.md § 4a's sizing and escape-hatch steps
pick the strategy, because the commit count here says nothing about the
volume.

One schema stretch, deliberate: `artifacts` names repo files instead of
an artifact class, which keeps Phase 2 off a full skill sweep this source
rarely earns. The **directory** `path` is not a stretch but the reason
`files` exists — the four pages change independently, the useful unit is
"did any of them move," and a directory is what `list_commits` wants
while `files` is what `get_file_contents` wants.

That narrowness is a scope choice, not a claim about reach. This source
*can* surface findings that bear on skills — the 2026-08-29 run turned up
forked skill context (`context: fork` in `SKILL.md` frontmatter, gated by
`github.copilot.chat.skillTool.enabled`, landed `eea0ec7e`) — but VS
Code's skill features are not Claude Code's, so the payoff does not
justify sweeping every skill on every run. Report findings like that as
bucket (c) tooling notes rather than mapped drift.

### `claude-code` — Claude Code releases

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
  `CLAUDE.md`, `scripts/link-claude.ps1`

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

- **Volume.** ~29 commits and ~550 bullets in a 35-day window, of which
  roughly two thirds are `Fixed` TUI or platform bugs. Without `filter`
  the report is unreadable. Do not filter on the leading verb alone,
  though — `Fixed Grep and Glob not applying Read(...) deny rules to files
  reached through a symlinked search path` is a permissions-model finding
  wearing a bugfix prefix.
- **Size.** 587 KB, 380 version sections. This is why SKILL.md § 4a
  exempts `changelog` sources from the ">5 commits → diff two full files"
  rule; here that rule would pull ~1.2 MB to learn what ~29 small
  append-at-top patches already say.

**This source never produces a new-skill candidate, and that is deliberate.**
The harness ships live coverage of itself — the `claude-code-guide` subagent
plus first-party `update-config`, `keybindings-help`, and `plugin-dev:*`
skills — all refreshing faster than a monthly audit can. A repo-authored
reference skill would compete for the same triggers against always-current
content and lose *silently*, because a skill's `description` is the entire
trigger mechanism. What is repo-specific here is not "how Claude Code works"
but "how this payload is wired into it": the junction-vs-copy split, why
`settings.json` is copied, the fixture procedure. Those belong in root
`CLAUDE.md` (sessions editing this repo), `README.md` (cherry-pickers), and
this audit's own `docs/drift-audit/<date>/claude-code/` ledger (dated
evidence). Findings land on the `artifacts` above; bucket (b) stays empty.
Checked 2026-08-30 — the 2026-08-29 run's 418 filtered bullets across 89 days
produced zero new-skill candidates, which is the expected result, not a thin
one.

## Shape contracts

What "an entry" means for the diff, per shape.

- **`table`** — the page is one or more markdown tables. The unit is a
  **row**, keyed by the feature-name column. A row present in HEAD but not
  in prior is an addition; a row present in prior but not HEAD is a
  removal, which usually means preview→GA promotion (row moved between
  tables, status column cleared) rather than deletion. Capture the feature,
  description, and status cells plus any `drill.host` link in the row.
- **`prose`** — the page is dated headings with paragraphs under them. The
  unit is a **heading block**. Diff at paragraph granularity within a
  changed block; a wholly new heading is one entry.
- **`changelog`** — the page is version-stamped release notes. The unit is
  a **version section**; each bullet under a new version is one entry, and
  the version string is the entry's provenance instead of a section
  heading. Apply the entry's `filter`, if it has one, per bullet before
  anything else — an excluded bullet is bucket (d) and is never drilled.
  Changelogs append at the top, so a commit patch is a small block of new
  lines. At or below the ">5" commit count, diff them from patches; above
  it a two-ref diff is fine **provided both refs are diffed on disk and
  only the new region enters context** — never let two full files into the
  conversation (SKILL.md § 4a).

**`table` and `prose` have been exercised; `changelog` has not.** The two
What's New sources are table-driven. `vscode-agent` exercised `prose` on
2026-08-29 against a 2026-06-01 floor — four heading-structured pages,
both refs fetched whole, entries diffed at paragraph granularity — and
the findings held up against the live pages, so that contract is no
longer theoretical. `claude-code` is the first `changelog` entry and has
not been run. `prose` and `changelog` are specified so a non-table source
is a registry entry plus a validated run, not a skill rewrite — but treat
the first `changelog` run as unproven and check the extracted entries
against the live file by hand before trusting the report.

## Adding a source

1. Open the real page and confirm which shape it is. Do not assume `table`
   because the What's New sources are.
2. Add the entry above with every field filled. A missing `drill.via`
   defaults to `webfetch`; a missing `sections` list means the WebFetch
   fallback cannot do targeted re-fetch, so the source is github-mcp-only
   in practice for pages over ~40 KB. If `path` is a directory, `files` is
   not optional in practice — without it, content fetches return a listing
   and the audit has nothing to diff.
3. If the page carries more entries per window than a report can usefully
   hold, write a `filter`. A source with no filter and hundreds of entries
   per run produces a report nobody reads, which is the same as no audit.
4. Confirm `artifacts` is honest. A source that can only ever affect one
   rule shouldn't trigger a full skill sweep on every run.
5. Run `/drift-audit --sources <new-id>` against a window you already know
   the answer for, and check the extracted entries against the page.
6. If the source pushed the frontmatter `description` past its promise of
   what the skill covers, update it — the description is the entire
   model-invoked trigger mechanism.
