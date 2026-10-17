# Handoff: decide the power-bi fetch target

- **Audit run**: 2026-10-17
- **Source**: `power-bi`
- **Window**: floor `0e80b00b` (2026-08-25, the 2026-10-06 run's head) →
  head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 1
- **Kind**: decision on which upstream page the `power-bi` source reads,
  not an edit. The user chooses; the registry entry's edits, and a
  validation run if the target changes, follow from that choice.
- **Target**: `.claude/skills/drift-audit/references/sources/power-bi.md`

## The problem

The `power-bi` source reads Learn's What's New page, and on 2026-10-17
that page still served the August 2026 update, unchanged since
2026-08-25. Microsoft has since published a September and an October
2026 Power BI feature summary on the Fabric Community blog, which no
registry entry reads. So a run of this source reports no changes while
two months of features go unaudited, and only a web search the entry
does not ask for shows it.

The entry's fetch step 1 ends "so a lag and a changed cadence look alike
from here". The two posts settle that the monthly summaries continue: it
is Learn's page that has not kept pace, whether it lags or is no longer
kept monthly. Which page the source reads is the user's call.

## Evidence

### Learn's page, 2026-10-17

A `curl -sSL` of the entry's `url`,
`https://learn.microsoft.com/en-us/power-bi/fundamentals/whats-new`, into
the session scratchpad: 63,605 bytes, carrying

```text
<meta name="ms.date" content="2026-08-18T00:00:00Z"
<meta name="updated_at" content="2026-08-25T17:13:00Z"
<meta name="git_commit_id" content="0e80b00bf4b83809178cdce6b055171e9e0c9604"
<title>See What&#39;s New in the August 2026 Power BI Update - Power BI | Microsoft Learn</title>
```

The SHA is the 2026-10-06 run's head (line 59 of its report,
`git show 7837759:docs/audits/2026-10-06/power-bi/00-audit-report.md`),
so the entry's step 1 had the run fetch nothing more, and no row was
read. Fifty-three days since `updated_at`. The same SHA was served on
2026-10-06, per that run's report, and on 2026-10-16, per the entry's
step 1, which adds "a web search found no September summary".

### The blog posts, 2026-10-17

A `WebSearch` for `Power BI September 2026 Feature Summary`, its
`allowed_domains` set to `powerbi.microsoft.com`,
`blog.fabric.microsoft.com`, `community.fabric.microsoft.com` and
`learn.microsoft.com`, returned among others:

| Title | URL |
| --- | --- |
| Power BI August 2026 Feature Summary | https://community.fabric.microsoft.com/blog/fbc_pbiupdatesblog/power-bi-august-2026-feature-summary/5348434 |
| Power BI September 2026 Feature Summary | https://community.fabric.microsoft.com/blog/fbc_pbiupdatesblog/power-bi-september-2026-feature-summary/5325831 |
| Power BI October 2026 Feature Summary | https://community.fabric.microsoft.com/blog/fbc_pbiupdatesblog/power-bi-october-2026-feature-summary/5374650 |
| Fabric September 2026 Feature Summary | https://community.fabric.microsoft.com/blog/fbc_fabricupdatesblogs/fabric-september-2026-feature-summary/5325825 |

The same search unrestricted, `"Power BI" "September 2026" feature
summary update`, returned third-party reposts and no Microsoft page.

Neither Power BI post was read. `WebFetch` answered `HTTP 403 Forbidden`
for the September and the October URL, and `microsoft_docs_fetch` reads
Learn, not that host. Their publication dates are unknown; the search
tool's summary put September's "around FabCon in Barcelona". The
trailing IDs do not follow the months: August's is above September's.

### What September's post holds, per search snippets alone

Unverified: the search tool's summary of result snippets, not the post.

- Copilot and AI: data answers in Microsoft 365 Copilot generally
  available; semantic model editors can block read-only users from
  querying a model through Copilot and remote MCP tools.
- Reporting: a Report ribbon on the web (preview); Live Visual Sharing
  in Outlook on the web (preview); the table visual's Export to Excel
  limit rising from 150,000 to 500,000 rows, "coming soon".
- Modeling: DirectQuery semantic models created and edited in the
  service; Full-Text Indexing (preview), adding the `TEXTCONTAINS` and
  `TEXTSIMILARITY` DAX functions.
- Data connectivity: the modern Power Query editor in Desktop (preview);
  an Outlook Mail connector (preview), without scheduled refresh.
- Developers: Power BI Projects (PBIP) generally available; a Purge Data
  option for the Fabric APIs.

Each of the entry's four `filter` clauses would keep at least one of
them: the DAX functions (1), DirectQuery models in the service (2), PBIP
and the APIs (3), Copilot over a model (4). October's contents were not
seen at all.

## The decision

Put to the user; never executed. The report's two options:

1. **Keep Learn and accept the lag.** Runs keep reporting no changes
   until Learn publishes. Then the window spans two or more months, and
   the entry's step 4 applies: the skipped months sit only on the
   archive page, whose status column differs, a route "inferred
   2026-10-06, not yet observed".
2. **Add the Fabric Community blog.** Shape, columns, sections and a
   fetch that gets past the 403 are all re-derived, by `sources.md`
   § Adding a source. The report expects prose per feature, not a
   table; no post was read to check that.

Choosing 2 opens questions this audit did not answer:

- **Discovery.** Each month is its own post at its own URL, unlike
  Learn's one page, and the IDs do not order by month, so a run needs a
  way to list the window's posts.
- **Fetch.** `WebFetch` gets a 403; whether `curl`, which `/drift-audit`
  § 3 allows into the scratchpad, gets the page is unprobed.
- **Placement.** Inside this entry, beside or instead of its `url`, or
  a source of its own; the schema gives an entry one `url`.

## What to change

After the user's choice, in
`.claude/skills/drift-audit/references/sources/power-bi.md`:

1. **Either way**, correct fetch step 1 in place. It reads: "On
   2026-10-16 Learn still served `0e80b00b…`, updated 2026-08-25, 52
   days without a publish; a web search found no September summary, so
   a lag and a changed cadence look alike from here." On 2026-10-17 a
   domain-restricted search found the September and October posts.
2. **Option 1**: nothing more.
3. **Option 2**: the entry, or a new `sources/<id>.md`, written to
   `sources.md` § Adding a source, steps 1 to 6. Its step 6 reaches
   `.claude/skills/drift-audit/SKILL.md`'s `description`, which names
   "Power BI What's New".

## Constraint on the fix

- **No post has been read.** Publication dates, shape and every feature
  above come from search results; measure each before writing it into
  the entry.
- **Brief no skill from the snippets.** They are unaudited; a run with
  the new fetch is what audits them.

## Verification

1. The user's choice, in this brief's execution log.
2. `grep -n 'look alike from here' .claude/skills/drift-audit/references/sources/power-bi.md`
   — no output.
3. Option 2 only: `/drift-audit 2026-09-01 --sources power-bi`, or the
   new id, in a fresh session. That window's answer is known
   (`sources.md` § Adding a source, step 5): it surfaces the September
   and October posts.
4. Option 2 only, if `SKILL.md` changed:
   `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`,
   then `uv run --with pyyaml scripts/skill-status.py --stale`.
5. `pre-commit run --all-files`.

## Sequencing note

Brief 02 waits on this choice; brief 03 does not. Don't bundle 02 into
this one: another file, another verification, and a target that is a
verbatim ledger report, a risk this brief does not carry.

## Provenance

Recommended action 1 of the 2026-10-17 `/drift-audit power-bi` run. The
run read nothing past Learn's meta tags, as the entry's step 1 directs
on an unchanged SHA. The posts surfaced through a web search made to
answer step 1's own lag-or-cadence question, and Phase 3's drill of them
failed on the 403, so the finding rests on search-result titles and
URLs, not on the posts.
