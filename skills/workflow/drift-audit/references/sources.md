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

#### Upstream takedown — measured 2026-09-07

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

#### Fetch strategy — fork primary, Learn page fallback

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
   `powerbi-docs in:name fork:only created:>=<floor-date>`, anchored at or
   just before the window floor. **Repository search has no `created`
   sort** — `sort=created` is accepted and silently ignored, so results
   return by relevance and "the most recent fork" cannot be expressed as a
   sort. Measured 2026-09-07: the bare query returned **1162** results
   whose first page contained no in-window fork at all; adding
   `created:>=2026-08-20` returned **3** and surfaced both usable ones.

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

**Young, but no longer improvised.** The route was improvised during the
2026-09-07 audit on a single fork, then hardened the same day by running
the written rule literally against three more — which is what produced
steps 1–3 above: the audit's own draft named the wrong metadata field,
relied on a sort that does not exist, and had no substring guard. It has
still only been exercised on one window. A run that finds it insufficient
should say so in the report rather than improvising again in silence.

#### Single-month document

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

- **Volume, per window length.** Two measured samples, not one operating
  range: ~29 commits and ~550 bullets across 35 days, and 85 commits,
  77 version sections and 1713 bullets across 89 days. That is roughly
  **0.95 commits/day and ~19 bullets/day** — scale by the window rather
  than reading the 35-day figures as the source's steady state. Roughly
  two thirds of bullets are `Fixed` TUI or platform bugs, so without
  `filter` the report is unreadable; the 89-day run passed 418 of 1713
  bullets, which is the evidence the filter earns its place. Do not filter
  on the leading verb alone, though — `Fixed Grep and Glob not applying
  Read(...) deny rules to files reached through a symlinked search path`
  is a permissions-model finding wearing a bugfix prefix.
- **Size.** ~590 KB, 380+ version sections, and it only grows. This is why
  SKILL.md § 4a treats `changelog` sources specially: letting two full
  files into context to diff them would pull ~1.2 MB to learn what a small
  append-at-top region already says. The bound is not "always patch" — it
  is to keep the full files out of the conversation, by per-commit patch
  on short windows and by an on-disk two-ref diff on long ones.

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
this audit's own `docs/audits/<date>/claude-code/` ledger (dated
evidence). Findings land on the `artifacts` above; bucket (b) stays empty.
Checked 2026-08-30 — the 2026-08-29 run's 418 filtered bullets across 89 days
produced zero new-skill candidates, which is the expected result, not a thin
one.

### `fabric-iq-ontology` — Fabric IQ ontology doc set

- `repo`: `MicrosoftDocs/fabric-docs`
- `branch`: `main`
- `path`: `docs/iq/ontology/`
- `files`: `overview.md`, `concepts-generate.md`, `how-to-bind-data.md`,
  `concepts-agent-integration.md`, `resources-troubleshooting.md`,
  `overview-tenant-settings.md` — the six pages `fabric-ontology` is
  built on. The `how-to-create-*`, `how-to-use-rules` and tutorial pages
  are deliberately out of the fetch set; §8 of that skill's
  `references/REFERENCE.md` lists them as undrilled.
- `shape`: `prose`
- `sections`: none — these pages are individually small, so the fetch
  unit is the whole file, as with `vscode-agent`.
- `drill.host`: `learn.microsoft.com`
- `drill.via`: `microsoft-learn-mcp`
- `artifacts`: `skills/fabric/fabric-ontology/`,
  `skills/fabric/fabric-data-agent/`,
  `skills/fabric/fabric-operations-agent/`,
  `claude/rules/fabric-git-serialization.md`

**A doc-set source, not a change feed — and the first one aimed at a
single skill.** The `fabric` What's New source will announce that
ontology reaches GA; it will not announce that the property-type table
gained a row, that the one-static-binding-per-entity-type limit moved, or
that the MCP endpoint path changed. Those are exactly the claims
`fabric-ontology` encodes, and they live only in the spec pages.

Registered 2026-09-02, when that skill was authored. Two properties make
it worth the slot and neither generalizes: the workload is **preview**, so
the pages move under their own steam rather than on the What's New
cadence; and the skill was written **entirely from docs with no local
sample**, because no ontology item exists in any repo on this machine.
Every other Fabric skill here was checkable against a real export. That
is the condition this source substitutes for — so do **not** read it as a
precedent for one source per skill. Retire it if an ontology item ever
lands in a Git-synced workspace here, or if the item goes GA and settles.

The REST **item-definition** spec is a separate page in a separate repo
(`rest/api/fabric/articles/item-management/definitions/ontology-definition`)
and is *not* covered here. It is the source for the definition-part
schemas in that skill's reference, and it drifts on its own schedule;
check it by hand when the definition layout is in question.

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
