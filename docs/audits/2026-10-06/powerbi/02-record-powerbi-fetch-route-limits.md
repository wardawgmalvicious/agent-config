# Handoff: record the powerbi fetch route's two expected limits

- **Audit run**: 2026-10-06
- **Source**: `powerbi`
- **Window**: floor `2026-09-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 2
- **Kind**: prose addition recording two inferred limits of the
  `powerbi` entry's fetch route. No procedure step changes. Only the
  first run after Learn republishes can confirm them, and that run is
  the reader a wrong edit would mislead.
- **Target**: `.claude/skills/drift-audit/references/sources.md`, the
  `### powerbi` entry: the *Fallback — read the live page* paragraph and
  the second bullet of *Single-month document*

## The problem

The `powerbi` entry describes its fork route as if it keeps working, and
its Learn fallback as if one read of the page covers any window. Neither
is likely to survive Learn's next publish of the page, and the entry
says nothing about either.

1. **The fork route ends at the takedown.** A fork is a copy taken when
   it was made. With the public mirror gone, no fork can sync a commit
   made after it went away. Learn's next publish will carry a SHA no
   fork holds, so every candidate will fail step 4. Step 5 already falls
   back when that happens, but the entry presents a full miss as the
   exception. A run that meets one could read the route as broken and
   improvise, or keep searching for a fork that cannot exist.
2. **The fallback sees one month.** The live page carries a single
   month, wholly replaced. If two publishes land between runs, the
   earlier month is gone from the live page and survives only on the
   archive page. The *Single-month document* bullet says "the live page
   hands you the current month's additions directly, which is most of
   what a monthly run wants". That holds for one publish per window and
   is silent about two.

Both are inferred, not measured. The audit's action says to flag them,
and to "Confirm on the first run after Learn republishes before writing
it down as fact."

## Evidence

**Measured in the audit, 2026-10-06.**

- Learn still serves `git_commit_id`
  `0e80b00bf4b83809178cdce6b055171e9e0c9604`, `updated_at`
  2026-08-25T17:13Z, title "August 2026": 42 days without a publish.
- The fork route only reconfirmed Learn. Learn's SHA already equaled
  the prior run's head (`0e80b00b`, per
  `docs/audits/2026-09-07/powerbi/00b-audit-report-rerun.md`) before any
  fork was consulted. The fork search, step-4 checks and window listing
  took 9 `github-mcp` calls to agree with it. The fork's own `[]` for
  the window carried no information: `jajin7/powerbi-docs` was created
  2026-08-31 and never pushed to, so it could not hold a later commit
  whether or not upstream moved.
- A fork made after the takedown did not help either:
  `martinps3/powerbi-docs`, created 2026-09-24 with default branch
  `live`, returns `[]` for the path.
- `search_repositories` with `powerbi-docs in:name user:MicrosoftDocs`
  lists only `MicrosoftDocs/powerbi-docs-powershell`. That fits the
  takedown; it does not re-check the 404.

**Gathered after the report, same session.**

- **No other page carries the update.** The Fabric What's New page's
  `## Power BI` section is a browser-version note and a link to
  `power-bi/fundamentals/desktop-latest-update?tabs=powerbi-service`.
  That URL serves the same document as the registered `url`, with the
  same `canonicalUrl`, `document_id` and `git_commit_id`.
- **The archive page's shape.** Learn search excerpts of
  [the archive page](https://learn.microsoft.com/en-us/power-bi/fundamentals/desktop-latest-update-archive)
  show each rolled-off month under its own versioned heading, such as
  `## July 2026 update (version 2.156.951.0)`. Its 2026 tables have the
  header
  `| Feature | Description | In preview as of this release |`,
  where every table on the live page had
  `| Feature | Description | Currently in preview |`
  on 2026-10-06. Older months vary: the September 2025 section has
  two-column tables,
  `| Feature | Details and related documentation |`.
- **Why the page has not moved: not settled, but a publish looks
  close.**
  - Learn's archive, June 2026 section: "FabCon Europe takes place in
    Barcelona from September 28 to October 1". Its September 2025
    section says that month's summary "coincides with FabCon Vienna".
  - The `fabric` source took its FabCon release on 2026-09-29
    (`80a24c9b`, "FabCon EU 2026 Release 9/28") and folded the September
    2026 feature summary into its tables on 2026-10-02 (`9eda27f8`), per
    `docs/audits/2026-10-06/fabric/00-audit-report.md`.
  - Power BI Report Builder shipped version 15.7.1820.75 on 2026-09-18,
    per its Learn change log.
  - A web search found no September 2026 Power BI feature summary, and
    the Power BI blog index answered `WebFetch` with 403.

## What to change

1. **Gap 1, in the *Fallback — read the live page* paragraph.** Record,
   dated 2026-10-06 and labeled as inference:
   - no fork can sync a commit made after the mirror went away, so the
     first run after Learn republishes should expect every candidate to
     fail step 4 and land on this fallback;
   - that outcome is the expected path, not a broken route, so a run
     meeting it does not improvise;
   - the measured half: on 2026-10-06, Learn's `git_commit_id` alone
     settled the window and the forks only reconfirmed it;
   - what confirms the rest: that first run's step-4 results against
     the new SHA.
2. **Gap 2, in the second bullet of *Single-month document*.** Record,
   labeled as inference: a window spanning two publishes loses the
   earlier month from the live page; the archive page carries it under a
   dated, versioned heading; and the archive's status column is
   `In preview as of this release`, so the `columns` mapping does not
   carry over unchanged. Link the archive page by its URL.
3. **Leave both as inference** until the first run after Learn
   republishes measures them. That run corrects the text in place.

## Constraint on the fix

- **Inference, not fact.** Neither gap was observed. Write neither as
  measured, and date both.
- **No procedure change.** Do not reorder primary and fallback, retire
  the fork route, or add a short-circuit step. Fork-primary was the
  user's choice on 2026-09-07, recorded in the execution log of that
  run's brief 01. Revisiting it is the user's decision, not this edit.
- **Do not assert why the mirror went away, or that Microsoft will
  publish a September update.** The entry already declines the first.
  The timing evidence makes the second likely, nothing more.

## Verification

1. `grep -n 'desktop-latest-update-archive' .claude/skills/drift-audit/references/sources.md`
   — at least one hit inside the `### powerbi` entry.
2. Read the `### powerbi` entry top to bottom. Steps 1–5 are unchanged
   apart from brief 01's step-2 edit. Both gaps are dated 2026-10-06 and
   labeled as inference, and no sentence states either as measured.
3. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`
4. `pre-commit run --all-files`
5. **Deferred, not runnable yet.** The first
   `/drift-audit --sources powerbi` after Learn's page title moves past
   "August 2026" confirms or refutes gap 1: every fork fails step 4
   against the new SHA. If its window spans two publishes, it also tests
   gap 2: the earlier month appears only on the archive. That run
   corrects this text in place.

## Sequencing note

Apply after brief 01. Both edit the `powerbi` entry, but 01 is checked
now and this one only by a future run, so they are separate briefs.
Whichever runs second re-reads the entry.

The 2026-10-06 `fabric` run has two briefs on this skill. Brief 17
edits the `### fabric` entry of the same file. Its D-2 knock-on asks
whether this entry's `columns` string holds, and the live-page headers
under Evidence answer that for the live page. Brief 18 is a decision on
`SKILL.md` that may settle whether this skill can `curl` to disk, which
would change how a fallback run could read the archive. Re-read the
file right before editing it.

## Provenance

Surfaced by the 2026-10-06 `/drift-audit --sources powerbi --since
2026-09-01` run. It found Learn's page unchanged since the prior run's
head, and saw that the fork route had only reconfirmed Learn's own SHA.
Both gaps are reasoned from how forks work and from the page's
single-month shape, not observed. The archive, timing and alternate-page
evidence was gathered after the report in the same session, through
Microsoft Learn search and `WebFetch`.

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (no audit or handoff run in this session; no warm
  cap applied)
- **Files changed**: `.claude/skills/drift-audit/references/sources.md`
- **Verification**:
  - Step 1 — **passed**. `desktop-latest-update-archive` hits once, at
    line 265, inside the `### powerbi` entry (lines 53–271).
  - Step 2 — **passed**. Read top to bottom: against `HEAD`, the only
    hunks inside steps 1–5 are brief 01's two on step 2. Gap 1 ends the
    *Fallback* paragraph and gap 2 ends the second *Single-month
    document* bullet, each labeled "inferred 2026-10-06, not yet
    observed". The one sentence written as measured is this brief's own
    measured half: Learn's `git_commit_id` alone settled the 2026-10-06
    window.
  - Step 3 — **passed**. `lint-frontmatter.py` on `SKILL.md`, exit 0.
  - Step 4 (`pre-commit run --all-files`) runs once at the end of the
    run.
- **Deferred**: step 5, not runnable yet. Learn still served `0e80b00b`,
  title "August 2026", when brief 01 was verified in this run, so no
  republish has happened to test either gap.
- **Deviations**: none
- **Needs**: the first powerbi drift audit after Learn republishes —
  step 5: its step-4 results against the new SHA confirm or refute gap
  1, a window spanning two publishes tests gap 2, and it corrects the
  entry in place.
