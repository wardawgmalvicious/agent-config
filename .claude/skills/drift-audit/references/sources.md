# Drift-audit source registry

The audit input. `SKILL.md` holds the pipeline; this file and the files
under `sources/` hold what the pipeline runs against. Adding a domain to
the audit is a new file there, not a change to the skill body.

Each file under `sources/` is one source, and its filename less `.md` is
the `id` that `--sources` accepts.

## Entry schema

| Field | Meaning |
| --- | --- |
| `id` | Slug, and the source's filename less `.md`. What `--sources` matches on. Lowercase, no spaces. |
| `label` | Human name for the report's audit-window section: the file's H1, after the id. |
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

One file per source, `sources/<id>.md`, headed `` # `<id>` — <label> ``
with the schema's fields under it. A run lists `sources/` with `Glob`,
by the call `SKILL.md` § 1 gives, and takes the files in id order,
alphabetical: Claude Code's Glob tool returns paths by modification
time, so its order would reshuffle a report whenever an entry was
edited.

**Keep no list of the sources.** The directory is the set; `ls` it.
Hand-kept lists went stale twice before the registry was split on
2026-10-06: `SKILL.md` § 1 records its own case, and
`.claude/skills/README.md` named only the two What's New sources with
six registered. Name a source by its id where one matters, and restate
neither the set nor its count.

## Shape contracts

What "an entry" means for the diff, per shape.

- **`table`** — the page is one or more markdown tables. The unit is a
  **row**, keyed by the feature-name column. A row present in HEAD but not
  in prior is an addition; a row present in prior but not HEAD is a
  removal, which usually means preview→GA promotion (row moved between
  tables, status column cleared) rather than deletion. **That reading does
  not hold on a single-month page** — where the whole table is replaced
  each month, as on `powerbi`, a removal means last month rolled off and
  carries no GA signal at all. Check the source's entry before reading a
  removal as a promotion. Capture the feature,
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

**All three contracts have now been exercised.** The two What's New
sources are table-driven. `vscode-agent` exercised `prose` on 2026-08-29
against a 2026-06-01 floor — four heading-structured pages, both refs
fetched whole, entries diffed at paragraph granularity — and the findings
held up against the live pages, so that contract is no longer
theoretical. `claude-code` exercised `changelog` on the same date against
the same floor — 85 commits over 89 days, 77 version sections and 1713
bullets, diffed by downloading `CHANGELOG.md` at two pinned refs and
comparing on disk — and the extracted entries checked out against the live
file, confirming it is a strict prepend. That run also established that
§ 4a's unbounded "always patch" exemption inverts on a long window, which
is why the rule above is now stated as a mechanism rather than an
absolute. `prose` and `changelog` are specified so a non-table source is a
registry entry plus a validated run, not a skill rewrite.

## Adding a source

1. Open the real page and confirm which shape it is. Do not assume `table`
   because the What's New sources are.
2. Create `sources/<id>.md` with every field filled. A missing `drill.via`
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
