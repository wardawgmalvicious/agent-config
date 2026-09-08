# Handoff: repair the `powerbi` drift-audit registry entry

- **Audit run**: 2026-09-07
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 1
- **Kind**: changes how the audit fetches. Not a prose correction — this
  edit decides whether `/drift-audit --sources powerbi` can run at all.
  Blast radius is every future run of that source.
- **Target**: `skills/workflow/drift-audit/references/sources.md` (the
  `powerbi` entry), and possibly `skills/workflow/drift-audit/SKILL.md`
  if the chosen strategy needs pipeline support.

## The problem

The `powerbi` registry entry names `repo: MicrosoftDocs/powerbi-docs`.
That repository no longer exists publicly. Every documented fetch path in
`SKILL.md` § 4 derives from that one field, so **both** of them are dead:

- **§ 4a (github-mcp)** — `list_commits` / `get_file_contents` both fail
  at the repository endpoint.
- **§ 4b (WebFetch fallback)** — builds
  `https://raw.githubusercontent.com/<repo>/...` from the same `repo`
  value, so it 404s identically. The fallback is not a fallback here.

A future `/drift-audit --sources powerbi` therefore fails outright. It
does not degrade to a partial answer; there is no path left to try.

This run produced findings anyway, but only via a recovery route that is
**not described anywhere in the skill** and was improvised at run time
(see Evidence). Nothing in the repo currently records that the source is
broken or how the recovery worked.

## Evidence

### The repo is gone, and it is not a rename

`curl -sS -o /dev/null -w '%{http_code}' -L` against each URL, run
2026-09-07:

| URL | Status |
| --- | --- |
| `https://api.github.com/repos/MicrosoftDocs/powerbi-docs` | **404** |
| `https://github.com/MicrosoftDocs/powerbi-docs` | **404** |
| `https://raw.githubusercontent.com/MicrosoftDocs/powerbi-docs/main/powerbi-docs/fundamentals/whats-new.md` | **404** |
| `https://api.github.com/repos/MicrosoftDocs/powerbi-docs-powershell` | 200 |
| `https://api.github.com/repos/MicrosoftDocs/fabric-docs` | 200 |
| `https://learn.microsoft.com/en-us/power-bi/fundamentals/whats-new` | 200 |

`-L` was passed, and no redirect was followed — a GitHub **rename**
answers 301 on the API and redirects the web UI, so this is a deletion or
a switch to private. Those two are indistinguishable from outside; do not
write the entry as if you know which.

The two sibling rows matter: `MicrosoftDocs/fabric-docs` is 200, so the
`fabric` source is unaffected and the blast radius is this entry alone.

### The docs themselves are alive; only the mirror went away

The live Learn page's HTML metadata, fetched the same day:

```
content_git_url="https://github.com/MicrosoftDocs/powerbi-docs/blob/main/powerbi-docs/fundamentals/whats-new.md"
original_content_git_url="https://github.com/MicrosoftDocs/powerbi-docs-pr/blob/live/powerbi-docs/fundamentals/whats-new.md"
```

So Learn still advertises the dead public mirror as its source, and
authoring has always lived in `MicrosoftDocs/powerbi-docs-pr` (private,
also 404 to us). **The path inside the repo never changed** — the
registry's `path: powerbi-docs/fundamentals/whats-new.md` is still
correct. Only the container is gone.

### The recovery route actually used

Forks survived the takedown and were reparented. `search_repositories`
with `powerbi-docs in:name fork:only` returned 1162 results, several
created *inside* the audit window with `created_at == updated_at`
(i.e. forked and never modified since).

`jajin7/powerbi-docs` — created 2026-08-31, never modified — was used.
Its `list_commits` on the registry `path`, `since: 2026-08-01`, returned
three commits, HEAD `0e80b00b`.

The cross-check that established the fork is genuine upstream content:
the live Learn page pins its source commit as
`powerbi-docs-pr/blob/0e80b00bf4b83809178cdce6b055171e9e0c9604/...`, and
the fork's HEAD for this file is that same SHA. The public mirror
preserved the private repo's SHAs, so a fork's history is byte-identical
to what Learn published.

One negative result worth keeping: `prerit-g/powerbi-docs`, despite the
most recent `updated_at` (2026-09-06), returned **zero** in-window
commits on this path — its update did not sync upstream. Recency of
`updated_at` is not a proxy for upstream freshness; `created_at` on an
unmodified fork is.

## What to change

The entry currently reads (fields only; see the file for full text):

```
- `repo`: `MicrosoftDocs/powerbi-docs`
- `branch`: `main`
- `path`: `powerbi-docs/fundamentals/whats-new.md`
```

Two things must land:

1. **Record the takedown as dated fact.** State that
   `MicrosoftDocs/powerbi-docs` returned 404 at the API, web, and raw
   endpoints on 2026-09-07 with no redirect, that a rename would have
   301'd, and that deleted-vs-private is not determinable from outside.
   Note that this breaks § 4b as well as § 4a, since the fallback builds
   raw URLs from `repo` — that is the non-obvious part and the reason
   this is not simply "swap in a new repo".

2. **Choose a durable fetch strategy** and write it into the entry.

### Open question — which strategy

A real decision, not a formality. Both options are defensible and the
audit deliberately did not pick one.

**Option A — resolve an unmodified fork at run time.** Keeps the
`table`-shape diff, real commit lists, and per-commit patches. Costs a
fork-search step and a trust check before each run.

- Do **not** hardcode `jajin7/powerbi-docs`. A personal fork can be
  deleted, made private, or edited at any time, which would silently
  substitute someone's edits for upstream content — a worse failure than
  a clean 404 because it still returns plausible markdown.
- If this option is taken, the entry needs the selection rule written
  down: prefer `created_at == updated_at` (never modified), prefer the
  most recent such fork, and **verify** the fork's HEAD for the path
  against the SHA in the live Learn page's `original_content_git_url`
  before trusting it. That verification step is what makes the option
  safe, and it is cheap — it is one `curl` of the Learn page.

**Option B — read the Learn page via `microsoft-learn-mcp`.** The schema
already anticipates this: the `url` field is documented as "Non-GitHub
source. WebFetch only; no commit list, so the window is resolved by the
page's own dated entries." `drill.via` for this source is already
`microsoft-learn-mcp`, and that tool returns full pages rather than
summaries, so the ~13 KB page arrives complete.

- What is lost: no commit history, so no true prior-ref diff and no
  detection of a silently edited row. Additions are still detectable
  because the page is a single-month document (see Constraint below).
- What is gained: no dependence on a third party's fork.

A hybrid is legitimate — Option A as primary with Option B recorded as
the documented fallback, which would restore the two-path structure the
entry lost.

## Constraint on the fix

The audit established one fact that bounds Option B and should be written
into the entry regardless of which option wins: **this page is a
single-month document.** July's rows were wholly replaced by August's in
the window diff, so a row absent from HEAD means "last month rolled off",
*not* the preview→GA promotion that the `table` shape contract in
`sources.md` assumes for removals.

That has two consequences:

- The shape contract's claim that a removal "usually means preview→GA
  promotion" is wrong for this source and should be qualified where it
  applies to `powerbi`.
- Under Option B, reading the live page gives you the current month's
  additions directly, which is most of what a monthly run wants. The
  window mechanism degrades gracefully rather than failing.

Do **not** assert why Microsoft retired the mirror. Nothing in the
evidence speaks to intent, and the entry only needs the observable facts.

## Sequencing note

Do not bundle this with brief `02`–`05`. Those are factual corrections to
skill prose verified by grep and lint; this one changes the audit's fetch
mechanism and is verified by re-running the audit. Different verification,
different risk — a bad prose edit leaves a stale sentence, a bad registry
edit means the next run either fails or silently diffs someone's fork
edits against upstream.

This brief should land **first**. Until it does, the source cannot be
re-audited, which means none of the other briefs' findings can be
refreshed or confirmed against a later window.

## Verification

1. `uv run --with pyyaml scripts/lint-frontmatter.py skills/workflow/drift-audit/SKILL.md`
   — `sources.md` is body content with no frontmatter, but if the entry's
   change widened or narrowed what the skill covers, the `description`
   is the entire trigger mechanism and must still match.
2. Re-run the audit against a window whose answer is already known:
   `/drift-audit --sources powerbi 2026-08-01`. It must reproduce this
   run's three commits (`369371ac`, `a154ef24`, `0e80b00b`) and head
   `0e80b00b`. This is the real test — the registry entry is only fixed
   if a cold run works from what the file says, with no improvisation.
3. If Option A was chosen, confirm the written selection rule is
   sufficient by following it literally against a *different* fork than
   `jajin7/powerbi-docs`, and check that the Learn-page SHA verification
   step catches a fork that has diverged.
4. `pre-commit run --all-files`.

## Provenance

Surfaced by the first `/drift-audit --sources powerbi` run since the
takedown, on 2026-09-07 against a 2026-08-01 floor. The failure was
immediate and unambiguous — a 404 on the first `list_commits` call — and
was confirmed repo-specific by the sibling probes in Evidence before any
recovery was attempted.

Worth knowing when trusting this brief: every fact above was measured
this run, but the **recovery route is improvised**, not a tested feature
of the skill. It worked and was cross-checked against the Learn page's
pinned SHA, but it has been exercised exactly once, on one fork, for one
window. Treat Evidence as reliable and the Option A procedure as a
sketch that this brief's step 3 is meant to harden.

## Execution log

- **Executed**: 2026-09-07 — applied with deferrals
- **Session**: fresh (no audit report in context; no warm cap applied)
- **Files changed**: `skills/workflow/drift-audit/references/sources.md`,
  `skills/workflow/drift-audit/SKILL.md`
- **Open question**: put to the user, who chose the **hybrid — Option A
  (fork resolution) primary, Option B (Learn page) documented fallback**,
  i.e. the brief's own sketch. Written into the entry as
  *Fetch strategy — fork primary, Learn page fallback*.
- **Verification**:
  - Step 1 (lint `SKILL.md`) — **passed**. `description` still matches
    scope; the edit neither widened nor narrowed what the skill covers.
  - Step 2 (re-run `/drift-audit --sources powerbi`) — **deferred**, see
    below.
  - Step 3 (harden Option A against other forks) — **ran, and found three
    defects in this brief's own procedure**; all three corrected in the
    entry. Detail under Deviations.
  - Step 4 (`pre-commit run --all-files`) — **passed** (gitleaks, skills
    frontmatter, rules frontmatter).
  - Evidence re-confirmed before writing dated facts: all three
    `MicrosoftDocs/powerbi-docs` endpoints still 404; `fabric-docs` and the
    Learn page still 200.
- **Deferred**:
  - **The audit re-run (step 2).** Self-referential brief — this skill
    cannot re-run an audit against the registry it just edited. Deferred
    to the next `/drift-audit --sources powerbi 2026-08-01`, which must
    reproduce `369371ac`, `a154ef24`, `0e80b00b` with head `0e80b00b`,
    cold, with no improvisation.
  - **Behavioural reload.** `SKILL.md` changed, so its frontmatter
    (including the new `allowed-tools` entry) is not reliably live in this
    session. Fresh session required.
- **Deviations**:
  1. **The brief's trust check named the wrong metadata field.** It said
     to read the SHA from `original_content_git_url`; measured today, that
     field carries a *branch* (`powerbi-docs-pr/blob/live/...`), not a
     SHA. The SHA lives in the **`git_commit_id`** meta tag. A run
     following the brief literally could not have performed the check at
     all. Entry corrected to `git_commit_id`, with `gitcommit` named as
     the second choice.
  2. **"Prefer the most recent such fork" was not expressible.**
     Repository search has no `created` sort — `sort=created` is accepted
     and silently ignored, so results return by relevance; the bare query
     gave 1162 results whose first page held no in-window fork.
     Replaced with a `created:>=<floor-date>` qualifier (1162 → 3, both
     usable forks surfaced).
  3. **`created_at == updated_at` is insufficient alone.** Run literally
     against four forks: `jajin7` and `bsnyder9` matched the Learn SHA;
     `R1k91` (created 2025-12-24) satisfied the rule but returned a stale
     `16ffea41…`; `MrIndia-hub` returned **HTTP 200 with `[]`**, which is
     indistinguishable from "no commits in window" and would report *no
     drift* on a broken source. All recorded in the entry, plus a
     substring guard (`powerbi-docs-powershell` — a fork of a different,
     still-live repo — matches `powerbi-docs in:name`).
  4. **`SKILL.md` edited** under the brief's "possibly … if the chosen
     strategy needs pipeline support" clause: `search_repositories` added
     to `allowed-tools` (the primary path calls it every run; it is a read
     tool, so § 3's read-only posture holds), a § 4 note that a registry
     entry may override both fetch paths, and § 1's now-false claim that
     every registered source is anonymously fetchable.
  5. **Trust check pinned to `WebFetch`, not the brief's `curl`.** § 3
     keeps this skill read-only and Bash is deliberately outside its tool
     scope, so a shell `curl` is not available to it.
- **Not done, deliberately**: § 1's registered-source list still omits
  `fabric-iq-ontology` (registered 2026-09-02). Unbriefed adjacent defect;
  left for its own finding rather than widening this diff.
