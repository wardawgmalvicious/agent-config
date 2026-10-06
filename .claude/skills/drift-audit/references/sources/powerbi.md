# `powerbi` — Power BI

- `repo`: **resolved per run** — see *Fetch strategy* below. The former
  value, `MicrosoftDocs/powerbi-docs`, is dead; do not fetch from it.
- `branch`: `main`
- `path`: `powerbi-docs/fundamentals/whats-new.md` — **unchanged and still
  correct.** The path inside the repo never moved; only the container went.
- `url`: `https://learn.microsoft.com/en-us/power-bi/fundamentals/whats-new`
  — the documented fallback, per *Fetch strategy* below.
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

## Upstream takedown — measured 2026-09-07

`MicrosoftDocs/powerbi-docs` returned **404** at all three endpoints, with
`-L` passed and no redirect followed:

| Endpoint | Status |
| --- | --- |
| `https://api.github.com/repos/MicrosoftDocs/powerbi-docs` | **404** |
| `https://github.com/MicrosoftDocs/powerbi-docs` | **404** |
| `https://raw.githubusercontent.com/MicrosoftDocs/powerbi-docs/main/powerbi-docs/fundamentals/whats-new.md` | **404** |

A GitHub **rename** answers 301 on the API and redirects the web UI, so
this is a deletion or a switch to private. Those two are indistinguishable
from outside — do not write the entry, or a report, as if you know which,
and do not assert *why* it happened. Nothing observable speaks to intent.

**It breaks § 4b as well as § 4a, which is the non-obvious part.** The
WebFetch fallback builds `https://raw.githubusercontent.com/<repo>/...`
from this same `repo` value, so it 404s identically. No path in the
documented pipeline survives — which is why this entry carries its own,
and why "swap in a new repo" was never the fix.

Sibling probes the same day: `MicrosoftDocs/fabric-docs` 200, and the live
Learn page 200. The docs are alive and only the public mirror went away;
the blast radius is this entry alone. Learn still advertises the dead
mirror as its source (`github_feedback_content_git_url`), and authoring lives
in the private `MicrosoftDocs/powerbi-docs-pr` (also 404 to us).

## Fetch strategy — fork primary, Learn page fallback

**Primary — resolve an unmodified fork at run time.** Forks survived the
takedown and were reparented, and the public mirror preserved the private
repo's SHAs, so upstream bytes are still reachable under another namespace.

1. **Get the target SHA first.** `WebFetch` the live Learn page (the
   `url` above) and read the **`git_commit_id`** meta tag — a bare 40-hex
   SHA. Ask for that tag by name; a broad prompt summarizes the page and
   drops it. Use `WebFetch`, not a shell `curl`: § 3 keeps this skill
   read-only and Bash is deliberately outside its tool scope.

   **Do not read `original_content_git_url` for this.** It carries a
   *branch*, not a SHA — `.../powerbi-docs-pr/blob/live/...`, checked
   2026-09-07. The `gitcommit` tag holds the same SHA wrapped in a URL and
   is an acceptable second choice; `github_feedback_content_git_url` still
   advertises the dead public mirror and is worthless here.

2. **Search with a date qualifier, not a sort.**
   `powerbi-docs in:name fork:only created:>=<updated_at-date>`, anchored
   at the date of the commit Learn serves, never at the window floor: an
   unmodified fork holds that SHA only if it was made after the commit,
   so a floor later than the commit drops every fork made between the two.
   Learn's `updated_at` is the usable stand-in for the commit's date. It
   lands at or just after the commit (16:26Z commit, 17:13Z publish, on
   2026-08-25), and a date qualifier at its date includes forks made that
   day. **Repository search has no `created`
   sort** — `sort=created` is accepted and silently ignored, so results
   return by relevance and "the most recent fork" cannot be expressed as a
   sort. Measured 2026-09-07: the bare query returned **1162** results
   whose first page contained no in-window fork at all; adding
   `created:>=2026-08-20` returned **3** and surfaced both usable ones.
   Measured 2026-10-06, with a floor of 2026-09-01 after a commit of
   2026-08-25: `created:>=2026-09-01` returned **5** and no usable fork;
   `created:>=2026-08-25`, Learn's `updated_at` date, returned **7** and
   both matching forks.

3. **Filter the candidates.**
   - `name` must be exactly `powerbi-docs`. `in:name` matches substrings,
     so `powerbi-docs-powershell` — a fork of a *different, still-live*
     repo — returns on the same query.
   - Prefer `created_at == updated_at` (forked, never modified since).
     Treat this as a *tamper* check, not a freshness one — see below.

4. **Verify each candidate against the step-1 SHA.** The fork's HEAD for
   `path` must equal it exactly. Take the first that matches; on a
   mismatch move to the next candidate rather than settling for it. Only
   then run § 4a against that fork, with the unchanged `path`.

5. **Fall back** to the Learn page (below) when no candidate matches.

**Never hardcode a fork.** A personal fork can be deleted, made private,
or edited at any time, and an edited one returns *plausible markdown* — a
worse failure than a clean 404, because the run silently diffs someone's
edits against upstream and reports them as drift. Step 4 is the whole
safety margin and costs one page fetch; it is not optional.

**What step 4 catches — the rule run literally, 2026-09-07.** Four forks
were checked against Learn's `git_commit_id`
`0e80b00bf4b83809178cdce6b055171e9e0c9604`:

| Fork | Created | HEAD for `path` | Verdict |
| --- | --- | --- | --- |
| `jajin7/powerbi-docs` | 2026-08-31 | `0e80b00b…` | match |
| `bsnyder9/powerbi-docs` | 2026-08-26 | `0e80b00b…` | match |
| `R1k91/powerbi-docs` | 2025-12-24 | `16ffea41…` | **stale — rejected** |
| `MrIndia-hub/powerbi-docs` | 2025-09-20 | `[]` | **empty — rejected** |

That establishes three things. **`created_at == updated_at` is not
sufficient alone** — all four satisfy it and two are useless, because an
unmodified fork can simply be *old*; step 2's date qualifier and step 4's
SHA check are what supply freshness. **The route has redundancy** — two
independent forks agreed on the SHA, so one fork vanishing does not sink
the option. And **an unusable fork answers HTTP 200 with `[]`**, not a
404 — read uncritically that is indistinguishable from "no commits in
window", which would report *no drift* on a broken source. Never accept
an empty commit list from a fork that has not already passed step 4.

`updated_at` is **not** a freshness proxy either, in the other direction:
`prerit-g/powerbi-docs` carried the most recent `updated_at` (2026-09-06)
and returned zero in-window commits on this path — its update did not sync
upstream.

**Fallback — read the live page via `microsoft-learn-mcp`.** When no fork
passes step 4, fetch the `url` above. That tool returns full pages rather
than summaries, so the ~13 KB page arrives complete and § 4b's
completeness check does not apply. There is no commit list, so the window
resolves from the page's own dated entries, per the `url` schema row — no
true prior-ref diff, and a silently edited row is undetectable. Additions
remain detectable for the reason below.
After Learn's next publish, expect to land here (inferred 2026-10-06,
not yet observed). No fork can sync a commit made after the public
mirror went away, so the first run after Learn republishes should expect
every candidate to fail step 4. That is **the expected path, not a broken
route**, and a run that meets it does not improvise. The measured half:
on 2026-10-06, Learn's `git_commit_id` alone settled the window, and the
forks only reconfirmed it. What confirms the rest is that first run's
step-4 results against the new SHA, and that run corrects this text in
place.

**Young, but no longer improvised.** The route was improvised during the
2026-09-07 audit on a single fork, then hardened the same day by running
the written rule literally against three more — which is what produced
steps 1–3 above: the audit's own draft named the wrong metadata field,
relied on a sort that does not exist, and had no substring guard. It has
now been exercised **by three independent runs, on two windows** (floors
2026-08-01 and 2026-09-01). The second run followed steps 1–4 as
written, reached the same `git_commit_id` via two forks that agreed
(`jajin7`, `bsnyder9`), and the exact-name guard fired twice to drop
`powerbi-docs-powershell` — so the *rule* had been replicated even though
the window had not. Both runs also independently recovered the same three
in-window commits. A run that finds it insufficient should say so in the
report rather than improvising again in silence.
The third run, on 2026-10-06 against the 2026-09-01 floor, did just that
on the second window: step 2, then anchored at the floor, found no
usable fork, and the run widened the anchor by hand and said so in its
report. The rest of the rule held. The exact-name guard fired four
times, the empty-fork rejection once (`martinps3`, created 2026-09-24,
default branch `live`), and two forks agreed on the SHA again.

## Squash-merged monthly release — size before you fetch

The monthly publish arrives as **one squashed release merge**, so the
in-window commit count is a poor proxy for patch size and SKILL.md § 4a's
">5 commits" test picks the wrong strategy here almost every month.
Measured 2026-09-07: **three** in-window commits — comfortably under the
threshold that selects per-commit patches — but the release commit
`369371ac` carried 624 additions / 298 deletions across ~30 files with a
~10 KB commit message, of which `whats-new.md` was 68 lines. Pulling
`full_patch` would have dragged the entire release into context to read
one page.

On this source, § 4a step 5's escape hatch is therefore the **normal**
path rather than the exception. Size first with `get_commit` at
`detail: "stats"` (cap it with `perPage` — the file list is long), then
take the two-ref diff on the single `path`. Both 2026-09-07 runs reached
that conclusion independently and from opposite directions — one via raw
URLs, one via `github-mcp` — which is the evidence it is a property of
the source rather than of either run.

The base for that two-ref diff is **the last commit touching `path`
before the floor**, not the release merge's parent — see SKILL.md § 4b,
*Resolving the diff base*. This source is precisely where that
distinction bites: the merge's first parent is a same-day main-branch
commit that never touches `whats-new.md` and is dated inside the window.

## Single-month document

This page carries **one month of rows**, wholly replaced each month —
July's rows were entirely gone from August's in the 2026-09-07 window
diff. Two consequences:

- A row in prior but not HEAD means **last month rolled off**, *not* the
  preview→GA promotion the `table` shape contract assumes for removals.
  Never report a removal here as a GA promotion without checking the live
  page.
- The fallback degrades gracefully rather than failing: the live page
  hands you the current month's additions directly, which is most of what
  a monthly run wants.
  That holds for one publish per window. Inferred 2026-10-06, not yet
  observed: a window spanning two publishes loses the earlier month from
  the live page, and
  [the archive page](https://learn.microsoft.com/en-us/power-bi/fundamentals/desktop-latest-update-archive)
  carries it under a dated, versioned heading. Its status column is
  `In preview as of this release`, so the `columns` mapping above does
  not carry over unchanged. The first run whose window spans two
  publishes measures this, and corrects it in place.
