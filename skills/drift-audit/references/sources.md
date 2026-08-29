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
| `repo` / `branch` / `path` | GitHub-hosted markdown. Enables the github-mcp fetch path and raw-URL fallback. |
| `url` | Non-GitHub source. WebFetch only; no commit list, so the window is resolved by the page's own dated entries. |
| `shape` | `table`, `prose`, or `changelog`. Drives extraction — see Shape contracts. |
| `columns` | `table` shape only: which columns carry the feature name, the description, and the preview/GA status. |
| `sections` | H2 / H3 headings used for targeted re-fetch when the WebFetch fallback summarizes the page. Ignored on the github-mcp path. |
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
- `drill.strip`: `#post-NNNN-_TocNNNN`, any `#post-...`
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
- `drill.strip`: `#post-NNNN-_TocNNNN`, any `#post-...`
- `artifacts`: skills, rules, `CLAUDE.md`, MCP templates

### `vscode-agent` — VS Code agent customization surface

- `repo`: `microsoft/vscode-docs`
- `branch`: `main`
- `path`: `docs/agent-customization/`
- `shape`: `prose`
- `sections`: `custom-instructions.md`, `agent-skills.md`, `custom-agents.md`,
  `hooks.md` — the four pages describing where VS Code looks for each
  artifact class
- `drill.host`: `code.visualstudio.com`
- `drill.via`: `webfetch`
- `artifacts`: `README.md`, root `CLAUDE.md`, `scripts/README.md`,
  `scripts/link-claude.ps1`

Governs how this repo's `~/.claude` payload reaches GitHub Copilot, so its
findings land on the repo's own deployment docs rather than on skills and
rules. Claims about this surface are version-pinned and go stale silently:
`~/.claude/skills` became a first-class `chat.agentSkillsLocations` entry
in VS Code 1.135, which retired a whole linker script whose docstring had
been quietly wrong for months. VS Code ships monthly — faster than the
Fabric cadence — and moves these pages (they were under
`docs/copilot/customization/` until the 2026 reorg), so a 404 on the path
means find the new one, not that the source is gone.

Two schema stretches, both deliberate. `path` is a **directory**, not a
single file, because the four pages change independently and the useful
unit is "did any of them move." And `artifacts` names repo files instead
of an artifact class, because this source cannot affect a skill or a rule.

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
  heading.

**Only `table` has been exercised.** The two What's New sources are
table-driven; `vscode-agent` is the first `prose` entry and has not been
run yet. `prose` and `changelog` are specified so a non-table source is a
registry entry plus a validated run, not a skill rewrite — but treat the
first run against either as unproven and check the extracted entries
against the live page by hand before trusting the report.

## Adding a source

1. Open the real page and confirm which shape it is. Do not assume `table`
   because both current sources are.
2. Add the entry above with every field filled. A missing `drill.via`
   defaults to `webfetch`; a missing `sections` list means the WebFetch
   fallback cannot do targeted re-fetch, so the source is github-mcp-only
   in practice for pages over ~40 KB.
3. Confirm `artifacts` is honest. A source that can only ever affect one
   rule shouldn't trigger a full skill sweep on every run.
4. Run `/drift-audit --sources <new-id>` against a window you already know
   the answer for, and check the extracted entries against the page.
5. If the source pushed the frontmatter `description` past its promise of
   what the skill covers, update it — the description is the entire
   model-invoked trigger mechanism.
