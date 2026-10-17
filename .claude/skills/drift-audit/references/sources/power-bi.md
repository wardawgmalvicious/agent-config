# `power-bi` — Power BI

Renamed from `powerbi` on 2026-10-16 to match the `power-bi` skill
group; the 2026-10-06 run's directory moved with it. A report, brief or
`**Needs**:` line written before then says `powerbi` and means this
source.

- `url`: `https://learn.microsoft.com/en-us/power-bi/fundamentals/whats-new`
  — read by *Fetch — the Learn page* below, not by `WebFetch`. There is
  no `repo`; *Why no `repo`* says why.
- `shape`: `table`
- `columns`: feature = `Feature`, description = `Description`, status = `Currently in preview`
- `sections`: the page's category headings, one table under each, which
  vary by month. August 2026's: `General`, `Copilot and AI`,
  `Reporting`, `Modeling`, `Data connectivity`, `Mobile`, `Embedded
  analytics`, `Developers and APIs`, `Visualizations` (checked
  2026-10-16).
- `filter`: keep a row only if it
  1. changes what a TMDL or PBIR definition can hold: a format-pane
     setting, a visual type, a theme property, a model property, a DAX
     function;
  2. changes how a semantic model is built, refreshed, secured or
     queried, in the service or any authoring tool, Direct Lake above
     all;
  3. changes a REST API, Git integration or deployment; or
  4. touches Fabric Apps, or Copilot and AI over a model or report.

  Everything else is bucket (d): Desktop-only UI, the Power Query UI,
  mobile, consumption features such as comments, embedding hosts and
  AppSource visuals. Chosen 2026-10-16 for agentic work on Direct Lake
  models through the service, where Desktop is rarely open. On August
  2026's 23 rows it keeps 12: both under `Modeling`, both under
  `Copilot and AI`, and 8 of `Reporting`'s 11.
- `drill.host`: `learn.microsoft.com`
- `drill.via`: `microsoft-learn-mcp`
- `drill.strip`: `#post-NNNN-_TocNNNN`, any `#post-...` — deliberately **not**
  the `#toc-hId-*` form the `fabric` entry strips. Checked 2026-08-29: this page
  carried zero of them (it is a single-month document with two unanchored
  community-blog links). Don't copy the pattern across on the assumption that
  the two pages render alike; re-check if that ever changes.
- `artifacts`: skills, rules, `CLAUDE.md`, MCP templates

## Fetch — the Learn page

This replaces SKILL.md § 4a and § 4b for this source, by § 4's override
rule: one call when the page has not moved, two when it has.

1. **Ask whether it moved.** `curl` the `url` into the scratchpad
   (SKILL.md § 3) and `grep` its `git_commit_id` meta tag, a bare 40-hex
   SHA, and its `updated_at`. With no Bash, `WebFetch` the page and ask
   for that tag by name: a broad prompt summarizes the page and drops
   it, and `microsoft_docs_fetch` returns no meta tags (2026-10-16). A
   SHA equal to the prior head, from the ledger footer (SKILL.md § 2),
   means no changes: report the source as § 4a step 2 reports zero
   landings, and fetch nothing more. On 2026-10-16 Learn still served
   `0e80b00b…`, updated 2026-08-25, 52 days without a publish; a web
   search found no September summary, so a lag and a changed cadence
   look alike from here.
2. **Read it whole** with `microsoft_docs_fetch`, which returns the page
   complete as markdown, every table in it: all 23 of August 2026's
   rows on 2026-10-16. § 4b's completeness check does not apply.
3. **Window by the month** its title and H1 name, as in *What's new in
   Power BI? August 2026 update*. A month later than the prior head's
   makes every row an addition (*Single-month page*). A new SHA under
   the same month is an edit in place: read its rows against the prior
   run's report, and say that an edit inside a row already reported
   cannot be seen, since no prior copy exists to diff.
4. **A window spanning two publishes** loses the earlier month from the
   page.
   [The archive page](https://learn.microsoft.com/en-us/power-bi/fundamentals/desktop-latest-update-archive)
   carries it under a dated, versioned heading, and its status column
   is `In preview as of this release`, so the `columns` mapping above
   does not carry over unchanged. Inferred 2026-10-06, not yet
   observed: the first run whose window spans two publishes measures
   this and corrects it in place.
5. **Record the head** in the Next-run footer as the `git_commit_id`
   with its `updated_at` date, which step 1 compares against next time.

## Single-month page

The page carries **one month of rows**, wholly replaced each month:
July's rows were all gone from August's in the 2026-09-07 window diff.
A row in the prior report but not on the page means last month rolled
off, **not** the preview→GA promotion the `table` contract reads into a
removal. A promotion arrives as a row of its own, `(Generally
Available)` in its name, as nine of August 2026's did.

## Why no `repo`

The public mirror, `MicrosoftDocs/powerbi-docs`, answered 404 at the
API, web and raw endpoints on 2026-09-07, with no redirect: a deletion
or a switch to private, which look alike from outside, so assert
neither. Authoring lives in the private `MicrosoftDocs/powerbi-docs-pr`,
and Learn still names the dead mirror in
`github_feedback_content_git_url`. Unmodified forks kept the mirror's
SHAs and served the 2026-09-07 and 2026-10-06 runs, but no fork can
hold a commit made after the takedown, so that route ends at Learn's
next publish. The user dropped it on 2026-10-16, and with it a commit
history that a page replaced whole each month barely needs. The route,
its fork checks and its measured runs are in git:

```bash
git show 911f709:.claude/skills/drift-audit/references/sources/power-bi.md
```
