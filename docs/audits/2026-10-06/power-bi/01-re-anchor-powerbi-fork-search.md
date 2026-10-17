# Handoff: re-anchor the powerbi fork search

- **Audit run**: 2026-10-06
- **Source**: `powerbi`
- **Window**: floor `2026-09-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 1
- **Kind**: correction to one step of the `powerbi` entry's fetch
  procedure. It changes which forks the audit considers: a wrong anchor
  sends a run to the Learn-page fallback while a verified fork exists.
  Verified by re-running the search on this window.
- **Target**: `.claude/skills/drift-audit/references/sources.md`, the
  `### powerbi` entry: step 2 of *Fetch strategy — fork primary, Learn
  page fallback*, and the *Young, but no longer improvised* paragraph

## The problem

Step 2 anchors the fork search at the audit's floor. Run as written on
2026-10-06 against a 2026-09-01 floor, it found no usable fork. The run
would have dropped to the Learn-page fallback while two forks held the
exact SHA Learn serves.

The floor is the wrong anchor. Step 3 prefers unmodified forks
(`created_at == updated_at`), and an unmodified fork holds the SHA Learn
serves only if it was created after that commit. So the commit's date
decides which forks can match, not the window being audited. The floor
worked on 2026-09-07 only because it (2026-08-01) came before the
commit (2026-08-25). Once the floor is later than the commit, the anchor
drops every fork made between the two: on this run, both that matched.

## Evidence

Measured in the audit session, 2026-10-06, through `github-mcp` and one
`WebFetch` of the Learn page.

**Step 1.** The live page's `git_commit_id` is
`0e80b00bf4b83809178cdce6b055171e9e0c9604`, with `updated_at`
2026-08-25T17:13:00Z, `ms.date` 2026-08-18 and the title "See What's New
in the August 2026 Power BI Update". `get_commit` on
`jajin7/powerbi-docs` dates the commit 2026-08-25T16:26:47Z ("Fix
broken forum link").

**Step 2 as written**, `powerbi-docs in:name fork:only
created:>=2026-09-01`: `total_count` 5, none usable.

| Repo | Created | Default branch | Verdict |
| --- | --- | --- | --- |
| `martinps3/powerbi-docs` | 2026-09-24 | `live` | `[]` for the path, rejected at step 4 |
| `tfitzmac/powerbi-docs-powershell` | 2026-09-22 | `main` | exact-name guard |
| `leblocks/powerbi-docs-powershell` | 2026-09-09 | `main` | exact-name guard |
| `rothja/powerbi-docs-powershell` | 2026-09-02 | `main` | exact-name guard |
| `hatem-mahdy-bahra-electric/powerbi-docs-powershell` | 2026-10-03 | `main` | exact-name guard |

**Step 2 anchored at Learn's `updated_at` date**,
`created:>=2026-08-25`: `total_count` 7, the five above plus:

| Repo | Created, equal to `updated_at` | HEAD for the path | Verdict |
| --- | --- | --- | --- |
| `jajin7/powerbi-docs` | 2026-08-31T18:05:10Z | `0e80b00b` | match, used |
| `bsnyder9/powerbi-docs` | 2026-08-26T19:43:10Z | `0e80b00b` | match |

On `jajin7`, `list_commits` for the path with
`since: 2026-09-01T00:00:00Z` returned `[]`, and with
`until: 2026-09-01T00:00:00Z`, `perPage: 1` returned `0e80b00b`: base
and head are the same commit.

**The text at issue**, step 2 as of 2026-10-06 (lines 121–128):

> 2. **Search with a date qualifier, not a sort.**
>    `powerbi-docs in:name fork:only created:>=<floor-date>`, anchored at or
>    just before the window floor.

and the *Young, but no longer improvised* paragraph (lines 184–196):

> It has
> now been exercised **twice by two independent runs, but still on only one
> window** (floor 2026-08-01).

**Earlier anchors.** The 2026-09-07 runs anchored at
`created:>=2026-08-20` (step 2's own measurement) and
`created:>=2026-08-01`
(`docs/audits/2026-09-07/powerbi/00b-audit-report-rerun.md`). Both came
before the commit, which is why the floor anchor never failed until a
floor passed the commit date.

## What to change

1. **Step 2's anchor.** Replace "anchored at or just before the window
   floor" with an anchor at the date of the commit Learn serves. Learn's
   `updated_at` is the usable stand-in: it lands at or just after the
   commit (16:26Z commit, 17:13Z publish), and a date qualifier at its
   date includes forks made that day. Keep the date qualifier, the
   no-`created`-sort warning and the 1162-result measurement. Only the
   anchor moves.
2. **Step 2's measured example.** Add this run beside the 2026-09-07
   one: at the floor, 5 results and no usable fork; at Learn's
   `updated_at` date, 7 results and two matching forks.
3. **The *Young, but no longer improvised* paragraph.** Correct "still
   on only one window" in place. Record the second window (floor
   2026-09-01, run 2026-10-06): the exact-name guard fired four times;
   the empty-fork rejection fired once (`martinps3`, created 2026-09-24,
   default branch `live`); two forks agreed on the SHA again; and the
   at-floor anchor failed, which the run reported rather than widening
   in silence.

## Constraint on the fix

- **Keep a date qualifier.** The bare query returned 1162 results on
  2026-09-07, with no usable fork on the first page.
- **The anchor is not a freshness check.** Step 4 stays the only proof
  that a fork holds the SHA Learn serves. An earlier anchor only widens
  the candidate list. A later one silently drops forks that match.
- **Do not fold in brief 02.** It records that the fork route probably
  cannot match at all once Learn republishes. This brief fixes the rule
  for the case where a fork can match, and it can be checked today.
- **Do not add a short-circuit step.** That Learn's `git_commit_id`
  alone settled this window is evidence brief 02 records. Making it a
  procedure step was not a recommended action.
- **Find the text by quote, not line number.** Brief 17 of the
  2026-10-06 `fabric` run edits the `### fabric` entry above this one.

## Verification

1. Run step 2 as edited against this window, with
   `mcp__github-mcp__search_repositories`. If Learn's `git_commit_id` is
   still `0e80b00b…`, the search must return `jajin7/powerbi-docs` and
   `bsnyder9/powerbi-docs`, and step 4 must pass for at least one. If
   Learn has moved on, this known answer has expired: record the step-4
   results against the new SHA in brief 02's log, since that is 02's
   test.
2. `grep -n 'created:>=' .claude/skills/drift-audit/references/sources.md`
   — no instruction in the `powerbi` entry still anchors at the floor.
   Dated measurements such as `created:>=2026-08-20` stay.
3. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`
   — `sources.md` has no frontmatter and `description` is untouched;
   confirm it still lints.
4. `pre-commit run --all-files`
5. Cold, in a fresh session: `/drift-audit --sources powerbi --since
   2026-09-01` reaches a verified fork from the entry as written, with
   no widening by hand, and reports 0 commits with prior and head
   `0e80b00b`. Valid only while Learn still serves `0e80b00b`.

## Sequencing note

Apply before brief 02. Both edit the `powerbi` entry, but this one is
checked now and 02 only by a future run, so they are separate briefs.
Whichever runs second re-reads the entry.

The 2026-10-06 `fabric` run has two briefs on this skill. Brief 17 edits
the `### fabric` entry of the same file. Brief 18 is a decision on
`SKILL.md` whose evidence cites this entry's step 1 ("Use `WebFetch`,
not a shell `curl`"). This brief does not touch step 1. Re-read the file
right before editing it.

## Provenance

Surfaced by the 2026-10-06 `/drift-audit --sources powerbi --since
2026-09-01` run. It was the first `powerbi` run since the 2026-09-07
pair, and the first whose floor falls after the commit Learn serves. The
run followed step 2 literally, found no usable fork, then widened the
anchor by hand and said so in its audit-window block.

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (no audit or handoff run in this session; no warm
  cap applied)
- **Files changed**: `.claude/skills/drift-audit/references/sources.md`
- **Verification**:
  - Step 1 — **passed**. Learn still serves `git_commit_id`
    `0e80b00bf4b83809178cdce6b055171e9e0c9604`, `updated_at`
    2026-08-25T17:13Z, title "August 2026", so the known answer holds.
    Step 2 as edited, `powerbi-docs in:name fork:only
    created:>=2026-08-25`, returned `total_count` 7, the brief's seven,
    `jajin7/powerbi-docs` and `bsnyder9/powerbi-docs` among them. Step 4
    passed for both: `list_commits` on the path, `perPage: 1`, returned
    `0e80b00b` on each.
  - Step 2 — **passed**. The one instruction left anchors at
    `<updated_at-date>`; the other three `created:>=` hits are dated
    measurements.
  - Step 3 — **passed**. `lint-frontmatter.py` on `SKILL.md`, exit 0.
  - Step 4 (`pre-commit run --all-files`) runs once at the end of the
    run.
- **Deferred**: step 5, the cold `/drift-audit --sources powerbi --since
  2026-09-01` run. This is a self-referential brief, and this run cannot
  re-audit against the registry it just edited. Valid only while Learn
  still serves `0e80b00b`.
- **Deviations**: none to the edits. Two notes. Step 2's placeholder
  `<floor-date>` became `<updated_at-date>`, since it named the old
  anchor. Correcting "still on only one window" in place also put the
  paragraph's restatement of it, "the *rule* has been replicated even
  though the window has not", into the past tense, so the paragraph no
  longer asserts both.
- **Needs**: the next powerbi drift audit — step 5's cold re-run, which
  must reach a verified fork with no widening by hand while Learn still
  serves `0e80b00b`.
