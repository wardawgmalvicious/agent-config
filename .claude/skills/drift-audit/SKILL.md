---
name: drift-audit
description: "Audit registered upstream docs sources for drift since a prior commit SHA or date — detect new GA / preview features, syntax additions, deprecations, and harness or tooling changes that affect existing skills, rules, CLAUDE.md, settings.json, hooks, or the MCP templates. Sources live in a registry (references/sources.md): Microsoft Fabric (incl. RTI) and Power BI What's New, the VS Code agent-customization docs behind the GitHub Copilot wiring, Microsoft's skills-for-fabric catalog, and the anthropics/claude-code CHANGELOG — the harness the rest runs inside. Use when running a monthly Fabric / Power BI staleness check, checking whether VS Code moved the chat.*Locations settings, checking whether a Claude Code release renamed a hook event or moved a ~/.claude path, or auditing what changed on the registered pages between two points in time. Narrow a run with --sources <id,id>. Prefers a scratchpad clone, then github-mcp, for exact bytes and commit history, falling back to WebFetch. Findings only — no edits."
argument-hint: "[prior-sha-or-date] [--sources id,id]"
arguments: prior_ref
allowed-tools: WebFetch Read Grep Glob mcp__github-mcp__list_commits mcp__github-mcp__get_commit mcp__github-mcp__get_file_contents mcp__github-mcp__search_repositories mcp__microsoft-learn-mcp__microsoft_docs_fetch mcp__microsoft-learn-mcp__microsoft_docs_search
model: fable  # judgment-heavy; alias not dated ID — see .claude/rules/editing-skills.md
effort: xhigh
disable-model-invocation: false
---

# Drift audit

Audit the source markdown of registered upstream docs pages against the local Claude config — skills, rules, `CLAUDE.md`, MCP templates — and emit a structured findings report. Inline execution; the report stays in the conversation so the user can iterate on follow-up actions.

**Read-only — never modify any artifact this turn.** Rewriting a skill / rule / `CLAUDE.md` / MCP template based on the findings is a separate, per-artifact task initiated after this audit completes.

## 1. Sources

The audit input is a **registry**, not a fixed pair of pages. At the start of every run, `Read` [references/sources.md](references/sources.md), which holds the schema and the shape contracts, then each selected source's own file, `references/sources/<id>.md`: the ids `--sources` names, or with no `--sources` every file there. List them with `Glob`, pattern `*.md`, `path` this skill's `references/sources/` directory. A pattern carrying a `/` is matched from the working directory, not from `path`, whenever `path` sits inside it: `references/sources/*.md` under the skill's own directory answers `No files found` with every file present, while the same files spelled from the repo root, `.claude/skills/drift-audit/references/sources/*.md`, list them all under that same `path`, and `Grep`'s `glob` behaves the same (2026-10-08, CLI 2.1.292; first seen 2026-10-06, 2.1.291). Only under a `path` outside the working directory is such a pattern matched from `path`. A pattern with no `/` matches at any depth under `path`, inside the working directory or out, which is why this lookup uses one. **A lookup that finds no file has failed; it never means an empty registry** — stop and say so. Drive the pipeline from them. Never hardcode a repo, path, section heading, or doc host into the run — if something needed for a source isn't in its registry entry, the entry is incomplete and that is the finding.

Each entry carries an `id` (what `--sources` matches), its GitHub repo / branch / path (plus `files`, when that path is a directory) or plain `url`, a `shape` (`table` / `prose` / `changelog`) that drives extraction, `sections` for the WebFetch fallback, a `drill` block (host, mechanism, anchor-strip patterns) for Phase 3, and the `artifacts` classes it can produce findings against. The registry's Shape contracts section defines what "an entry" means per shape; its Adding a source checklist is the procedure for widening the audit.

Don't restate the set of sources anywhere, as a list or as a count — the directory owns it, and a copied list goes stale: one omitted `fabric-iq-ontology` for five days after it was registered on 2026-09-02. The sources are public and fetchable anonymously, with exceptions. `claude-code` and `skills-for-fabric` are files with no `sections` list, and a targeted WebFetch returns a `fabric` section whole only once in three (2026-10-08), so in practice only a clone or the `github-mcp` path can read those three; each entry records its own size. And `powerbi`'s upstream repo was taken down — 404 at the API, web and raw endpoints as of 2026-09-07 — so that source fetches by the strategy written into its own registry entry rather than from a `repo` field.

## 2. Argument parsing

The user invokes with a prior reference — slash form `/drift-audit <ref>`, natural language ("audit since SHA `abc1234`", "audit since 2026-03-15"), or no argument. A passed reference is applied to every audited source independently; with none, each source takes its own floor from the ledger.

- **SHA** (40-hex or 7+hex prefix) — resolve to its commit timestamp against any registered source's repo (the SHA's source repo doesn't have to match; we only need its date). Use that date as the floor for every source's `since` window.
- **ISO date** (`YYYY-MM-DD`) — use directly as the floor.
- **No argument** — each source floors at its own last audit, read from the ledger, which keeps the newest run of every source for the next audit to start from (`docs/audits/README.md` § Retiring a run):
  - **Find the run.** `Glob` pattern `00*-audit-report*.md`, `path` `docs/audits`, lists every run's report, a re-run's `00b-…` too. Per selected source, take the one under `<date>/<id>/` with the latest date, read from the path, not from `Glob`'s order, which is by modification time; where one directory holds two, the later name. The ledger here is never empty, so a `Glob` that finds no report has failed, as § 1's lookup can: stop and say so.
  - **Read only its footer.** `Grep` that report for `^## Next run` with `-A 30`. It is the report's last section, so that reaches the end; never Read the whole report for it.
  - **Take the source's line**, the one naming it by label or id. Its head SHA is from that source's own repo, so it is that source's prior reference alone, resolved as the SHA bullet resolves one, and § 4b takes it as the diff base. Where the line or the source's entry names a different floor, take that one: `powerbi`'s 2026-10-06 footer says to reuse 2026-09-01, because Learn's month labels would fall before a later date. A footer with no line for the source is asked about, not guessed.
  - **No run on disk** — that source floors 35 days back from today.
  - **Report it.** Print each source's floor, and the run it came from, in the audit window section.
- **Anything else** — ask the user to clarify; do not guess.

A passed reference applies to every source, intentionally: the audit window is "what changed since I last checked," not "what changed in the Fabric repo specifically." Each source resolves the window against its own commits. With no argument, "since I last checked" is per source, because sources get audited on different dates: on 2026-10-13 the newest `skills-for-fabric` run was from 2026-09-12 and the rest from 2026-10-06, and a single 35-day floor, 2026-09-08, already fell after the 2026-09-01 that `powerbi`'s footer says to reuse.

**`--sources <id,id>`** narrows the run to the named registry ids. Absent, audit every registered source. An id with no file under `references/sources/` is an error — list the valid ids, those files' names less `.md`, and stop rather than silently auditing a subset. Skipped sources are named in the report so an empty bucket is never mistaken for a clean one.

**Owed re-checks.** Once every floor is resolved, find the follow-ups this run owes. A brief whose open work only a drift audit can do names that audit on its log's `**Needs**:` line (`/drift-update` § 4.6), and `/triage` leaves such a line for the audit to settle: on 2026-10-07 a `powerbi` follow-up still waited on the audit that had run the day before. `handoff-status.py` lists these lines too, but it is a repo script, which § 3's Bash allowance does not reach:

- **List the open lines.** `Grep` pattern `^- \*\*Needs\*\*:`, `path` `docs/audits`, `glob` `!**/completed/**`, output mode `content` with line numbers. The negated glob drops every brief under a `completed/` folder (2026-10-14, CLI 2.1.293), which is every finished one: `scripts/audit-status.py` files a brief there once its log leaves nothing open, and the `lint-audit-index` hook fails a commit with one on the wrong side. A brief never run has no such line. In each file only the hit with the highest line number counts, since a later session appends a fresh line rather than rewriting one.
- **Keep the ones owed here**, from any run's directory, `prompt-audit/` included: a line whose words before its first ` — ` name the next drift audit of a selected source, by id or label, or of any source, or the first one after a condition, such as Learn republishing, which this window meets or does not. `/drift-update` writes `the next <source-id> drift audit`; older lines vary, as "the next `fabric` audit" and "the next `/drift-audit --sources fabric-iq-ontology` run" do.
- **Read what each owes**: its line whole, from its log, and the step of its brief that the line names, each by `Read`'s `offset` and `limit`, never the whole brief.
- **Do each where its work falls**, a check of this skill's own behaviour in the phase it names, an upstream question in this window's diff, and report every one under § 7's `## Owed re-checks`.

## 3. Read-only scope

Prohibited tools this turn: `Edit`, `Write`, `MultiEdit`, `NotebookEdit`. Do not call them regardless of what the audit findings suggest is needed.

**Bash has one sanctioned use: upstream bytes in the session scratchpad.** `git clone` or `curl` a registered source into a new directory there, then list, show, diff and extract inside it (§ 4a), writing any script or table to a directory of its own beside the downloads, never among them. Nothing else: no write outside the scratchpad, no git command against this repo, no repo script. `allowed-tools` leaves `Bash` out on purpose (2026-10-14), so each call goes through the session's permission mode. Sanctioned 2026-10-06, after that day's `fabric` and `vscode-agent` runs each needed it, one to diff 14 versions of a file on disk, the other to diff a clone (`docs/audits/2026-10-06/fabric/completed/18-decide-table-source-fetch-strategy.md`).

If the user asks within this same turn to "fix the drift you found", "update fabric-spark", "rewrite the skill", "patch CLAUDE.md", etc., refuse and explain:

> The audit is read-only by design. Each artifact rewrite is its own task with its own context — the audit report you just received is the input to that follow-up. Start a new request naming the specific skill or rule to update.

This separation matters because a single bad rewrite during audit triage can silently corrupt the artifact set, and the per-skill rewrite task has different review and validation steps than the audit itself. The body prompt is the only enforcement — `allowed-tools` lists the auto-approval scope, not a hard restriction.

## 4. Phase 1 — Fetch and diff each source

Work through the selected sources in id order, alphabetical. Three fetch paths, in order of preference: a clone (4a), `github-mcp` where no clone can be taken (each 4a step's *Without a clone*), and WebFetch (4b). Pick once, at the top of the run, and say which one the report used; a source that fell to another says so on its own line.

**An entry may override them.** Where a registry entry documents its own fetch strategy — because its upstream repo is gone, or it was never GitHub-hosted — that strategy replaces 4a and 4b for that source, and any trust check it specifies is mandatory rather than advisory. § 1's no-hardcoding rule is what makes the entry authoritative: read it before assuming `repo` is a static field, and name the path taken in the report as you would for 4a or 4b.

### 4a. Preferred path — a clone, else `github-mcp`

A blobless clone in the scratchpad (§ 3) holds a source's whole commit graph and every tree, so the run lists its window by ancestry rather than by date, sees what landed on the branch rather than the branch commits a path filter returns, and keeps every version and diff on disk. Blobs arrive lazily, only for the versions asked for, and two sources on one repo share a clone. Where none can be taken — no Bash, or `git` cannot reach GitHub — run each step's *Without a clone* on the `github-mcp` tools: exact bytes and real unified patches, but listed by date and by path filter, with the two blind spots step 2 names.

1. **Clone, and resolve HEAD** — the newest landing (step 2) that touched `path`:

   ```bash
   git clone --quiet --filter=blob:none --no-checkout --single-branch --branch <branch> https://github.com/<repo>.git <scratchpad>/<repo-name>
   git -C <clone> log --first-parent -1 --format='%H %cI' HEAD -- <path>
   ```

   Record `<head-sha>` and `<head-date>`. **Clone whole; never cut it with `--shallow-since`.** A commit with any parent older than the cut keeps none of its parents, so one merge of an old branch severs the first-parent line: on 2026-10-14 a cut at 2026-08-01 severed `fabric-docs` at `a423669`, a 2026-09-17 merge of a fork branch, and the base for a 2026-09-01 floor came back empty. Whole is cheap: the same day, in seconds each, `fabric-docs` came to 57 MB (60,411 commits), a `powerbi-docs` fork to 55 MB and `vscode-docs` to 21 MB (git 2.55). *Without a clone*: `list_commits` on the source's repo, filtered to its `path`, `perPage: 1`, `fields: ["sha"]`, then `get_commit` on that one SHA with `detail: "none"` for its date. `detail` governs file stats only — the commit message always comes back, so on a squash-merged repo budget a few KB for that one call.
2. **List the window by ancestry, one line per landing.** A landing is a commit on the branch's first-parent line: a squash, a PR merge, or, on a mirror such as `fabric-docs`, a sync merge from the private repo whose carried commits name the change.

   ```bash
   git -C <clone> log --first-parent --numstat --format='%h %cs %s' <base>..<head-sha> -- <path>
   git -C <clone> log --format='%h %as %s' <landing>^2 ^<landing>^1 ^<base> -- <path>   # what a merge landing carries
   ```

   `<base>` comes from **Resolving the diff base** in § 4b. Under `--first-parent` a merge's numbers are against its first parent, so each line's +/- is what that landing brought. Fetch messages (`git log -1 --format=%B <sha>`) only for the SHAs that turn out to matter. If zero landings, mark the source "no changes" and move on (it still gets an audit-window line and a Next-run entry). A landing that carries nothing past the base changed nothing here, and its version can predate the base: name it, and walk no version for it. That happens after a base that is itself a carried commit, as heads recorded before 2026-10-14 are on a mirror; the `fabric` entry has the case.

   Ancestry, because a date filter misses a commit dated before the floor that lands inside the window: `vscode-agent`'s `0ff80a1` (2026-08-28) reached `main` through `99bbccc` (2026-09-03). Landings, because a path filter lists branch commits and "Merge branch 'main' into …" commits rather than the merges that landed them — 19 SHAs for 17 landings on that 2026-10-06 run — and a "Merge branch 'main'" patch shows `main`'s changes arriving, not the branch's own. *Without a clone*: `list_commits` with the same path filter, `since: <floor-date>T00:00:00Z`, and `fields: ["sha"]` (add `html_url` if the report wants links). **Always list with minimal fields.** A squash-merged repo puts an entire release branch in one commit, and the message alone then runs to thousands of characters — one filtered page of `microsoft/vscode-docs` came back at ~74 KB before this was pinned down. That list has both faults, so the report's audit window names them for the source.
3. **Get the changes — on disk, and only what fits enters context.** A version or a diff on disk costs no context; step 4's budget governs what is read into the conversation.
   - **Read the diff, not the files**: `git -C <clone> diff <base> <head-sha> -- <path>`, or `git -C <clone> log --first-parent -p <base>..<head-sha> -- <path>` where attribution matters. Added and removed lines come straight from the patch; no side-by-side reconstruction.
   - **When the two refs outgrow the budget, whatever the shape, extract on disk** and read only the extracted entries or the changed region — never both refs, and never a diff that itself outgrows the budget, as `fabric`'s did on its 2026-09-01 window (its entry has the sizes). A `changelog` reads its added region, in slices once it is long (`claude-code`'s entry has the slice size).
   - **A `table` source walks every in-window version, always**, and reads its classified table in place of the diff: `git -C <clone> show <sha>:<path>` for the base and each landing, into the scratchpad, then key and classify them per § 4c. A base-to-head diff cannot see a row added and deleted inside the window. On `fabric`'s 2026-09-01 window that was 22 rows, the window's new Warehouse T-SQL syntax and the TMDL ontology experience among them, which a base-to-head diff would have dropped with no error (brief 18, cited in § 3). On a clone the walk is cheap: that window is 12 versions, the base and 11 landings (2026-10-14).
   - *Without a clone*, by commit count. **5 or fewer** — `get_commit` per SHA with `detail: "full_patch"`, reading the patch for the source's `path`. **More than 5** — the file at the base (resolve it with **Resolving the diff base** in § 4b; resolving it by commit order instead of by `path` silently drops changes) and at `<head-sha>`, cheaper than a patch per commit once the count climbs. Where Bash still runs, `curl` each ref's `https://raw.githubusercontent.com/<repo>/<sha>/<path>` into the scratchpad and the on-disk rules above hold, the walk included; with no Bash, `get_file_contents` puts both refs in context, so step 4's budget decides. A `changelog` appends at the top, so each per-commit patch is a small block of new lines: read patches at or below the ">5" count, and above it a two-ref diff only on disk, else patches still, never two full files in context. On `claude-code`'s `CHANGELOG.md`, 29 commits in a 35-day window were cheaper as patches and 85 across 89 days as one on-disk two-ref diff, 2 calls against 85. Where the source's `path` is a **directory**, `get_file_contents` on it returns a listing rather than content — fetch each name in the entry's `files` list instead, at both refs, after narrowing that list per step 4.
4. **Size what enters context before reading it.** Call count is a poor proxy for context cost — eight `get_file_contents` calls is cheap in calls and ~190 KB of markdown in the window. Two moves, in order:
   - **Narrow by blob SHA.** On a directory `path`, list it at *both* refs: `git -C <clone> ls-tree -r <ref> -- <path>`, or *without a clone* `get_file_contents` with `fields: ["name", "size", "sha"]`. That `sha` is the file's blob hash, so a name carrying the same `sha` at both refs did not change and must not be fetched; on `github-mcp` the two `size` values are the exact byte cost of fetching one that did. Two listings, no content, and more precise than a per-file `list_commits` sweep.
   - **Spend a budget, in delta order.** Budget roughly **150 KB per source per run** for what enters context: a diff costs its own size, and a two-ref read in context costs `size(prior) + size(head)`. Take the changed files in descending size-delta order, and stop when the budget is gone — naming any file left undiffed in the report. A source that cannot fit its own changed set is a signal its `files` list is too broad.
5. **Strategy escape hatch.** On a clone, step 2's `--numstat` sizes every landing before any patch is read. *Without a clone*, commit count is only a proxy for patch size, and it breaks on repos that squash release branches. If a listing or a patch comes back oversized — truncated, worth spilling to a file, or plainly bigger than the alternative — switch strategy regardless of what the count said: from per-commit patches to a two-ref file diff, or via `get_commit` with `detail: "stats"` to see which files actually moved before pulling any patch at all. Name the strategy you ended on in the report.
6. Skip 4b, all but its base rule.

### 4b. Fallback path — `WebFetch`

Used when neither a clone nor `github-mcp` is available. Keeps the skill working for anyone cherry-picking it into a plain `~/.claude/`.

- Raw markdown at any ref: `https://raw.githubusercontent.com/<repo>/<sha-or-branch>/<path>` — one URL per name in `files` when `path` is a directory
- Commits list: `https://api.github.com/repos/<repo>/commits?path=<path>&per_page=<n>` with optional `&sha=<ref>` or `&since=<ISO-date>`

GitHub anonymous API limit is 60 requests/hour and this path is unauthenticated. **Price the selected set before running it, and price it in calls rather than sources.** A single-file source costs ~3 (commits list, raw at prior ref, raw at HEAD) plus one re-fetch per `sections` entry when the completeness check below trips; a **directory** `path` costs `1 + 2 x |files|` instead. Source count is therefore a bad proxy — one directory source with a long `files` list outweighs three single-file ones.

Worked again on 2026-10-14, from the entries: `fabric-iq-ontology` 35 (17 files), `vscode-agent` 9 (4 files), `powerbi` ~0 GitHub calls — its entry override degrades to the Learn page, not to raw URLs — and 0 for `fabric`, `claude-code` and `skills-for-fabric`, which are not attempted (below). That is 44 of 60 worst case, up from ~36 on 2026-09-08, when `fabric-iq-ontology` listed 6 files and `fabric` priced at up to 14 for 11 sections, so the set fits with less headroom than a per-source budget suggests. Re-derive it rather than trusting that figure. Once a run's projected calls approach the limit, the `github-mcp` path stops being optional.

A source its registry entry marks github-mcp-only, a label older than the clone path that means WebFetch cannot read it whole, is not attempted on this path at all: name it in the report's skipped list rather than diffing a summary of it. A source whose entry defines its own fetch strategy is priced by that strategy and not by this rule.

**Resolving the diff base — one rule, and it governs every fetch path.** If the prior reference is a SHA whose repo matches this source, passed or taken from the ledger by § 2, use that SHA directly; *without a clone*, also drop it from § 4a's in-window list, which starts at midnight of its date and so returns it: its changes are already in the base. If a SHA from another source's repo, fall back to the date resolution. For a date, the base is **the last landing that touched the source's `path` before the floor**: `git -C <clone> log --first-parent -1 --format=%H --before=<floor-date>T00:00:00Z <head-sha> -- <path>`. An empty answer has failed, never "no prior state": the clone stops short, or `path` moved, as the `vscode-agent` entry records once. *Without a clone*, `list_commits` with that `path`, `until: <floor-date>T00:00:00Z`, `perPage: 1`, `fields: ["sha"]` — which returns a branch commit dated before the floor even when it reached the branch after it. On 2026-10-14, with `until: 2026-09-05`, it returned `skills-for-fabric`'s `65902bae`, the v0.3.15 release commit of 2026-09-04 that reached `main` on 2026-09-06: that release would sit in the base and in no list, with no error, so the report names this limit for the source.

**Not "the parent of the oldest in-window commit"**, which is wrong on any repo that merges release branches. The oldest in-window commit is typically the monthly release *merge*, so its first parent is a same-day main-branch commit that never touched the audited file and is dated *inside* the window. Measured on `powerbi` on 2026-09-07: that rule resolved `f1f53694` (2026-08-20, touching `service-get-started.md` and `power-bi-visualization-card.md` — not `whats-new.md`), where the correct rule resolves `443eb78f` (2026-07-22, the July release merge, which is genuinely the file's previous version).

It survived undetected because it produced an identical diff — nothing else touched that file in between, so the two bases are byte-identical for `path`. That is luck, not correctness. Had any in-window commit touched the audited file *before* the release merge, its change would sit in the **base** and vanish from the diff: a silent under-report with no error path and no symptom in the output. Resolve the base by path, always.

**Completeness check — re-fetch by section if summarized.** No registry source comes back raw on this path, whatever its size. `WebFetch` returns a page verbatim only when its host is on the harness's preapproved list (`code.claude.com` is), the server sends `text/markdown`, and the text from `offset` runs under 100,000 characters. `raw.githubusercontent.com` sends `text/plain` and is on the list only under `/anthropics` and `/anthropic-experimental`, so every raw URL above goes through a small model instead: it reads at most 100,000 characters from `offset`, and for a host off the list it is told to quote at most 125 characters at a time and paraphrase the rest (2026-10-08, CLI 2.1.292). A broad "return the full markdown" prompt on `fabric`'s `whats-new.md`, 147,882 characters, came back as a ~3 KB prose overview with no table rows. It ended in the `[WebFetch note: …]` that a page past 100,000 characters gets, naming how much went unread and the `offset` to read on. After each fetch, look for that note, then scan the payload for tell-tale summarization: bullet lists where pipe-delimited tables should be, cells paraphrased around short quoted fragments, "additional sections truncated" or "[Continuing through all remaining rows …]" language, missing description columns, renamed entries, or entry counts that look thin for a monthly cadence. If any shows, **re-fetch the same URL with targeted section prompts — one per heading in the source's registry `sections` list**, each asking for that section's content verbatim, and again at the note's `offset` for a section that runs past the cut. Cache results in working memory keyed by section heading. Targeted prompts beat broad ones but are not reliable. `fabric`'s `Generally available features` holds 105 rows, and the 100,000-character cut falls in its eighth: fetched from the section's own start, an offset this path has no way to learn, a targeted prompt returned every row verbatim; from offset 0 it paraphrased the seven rows before the cut; reading on from offset 100,000, it returned two rows and elided the other 95. So scan each targeted result for the same tells, and once a section will not come back whole, report the source as `fetch incomplete — clone or github-mcp required` rather than diffing part of it. Skip this step only if the broad fetch returned complete, unsummarized content for every section.

A source whose registry entry has no `sections` list has no targeted-re-fetch escape hatch. If its broad fetch comes back summarized, report the source as `fetch incomplete — clone or github-mcp required` rather than diffing a summary.

### 4c. Extract entries — by the source's `shape`

Walk prior and HEAD, splitting into entries per the registry's Shape contracts (`table` — rows keyed by the feature column; `prose` — heading blocks; `changelog` — version sections); a `table` source walks every version § 4a step 3 put on disk, as below. For each entry present in HEAD but not in prior, and each transient one, capture:

- The section heading (and parent heading if relevant), or the version string for `changelog`.
- The entry's own fields — for `table`, the cells named by the entry's `columns` mapping; for `prose` and `changelog`, the entry text.
- Any link into the source's `drill.host`. **Strip the anchor patterns named in `drill.strip`** before storing — unstable anchors break across page revisions and pollute downstream diffing.
- Code or syntax examples — T-SQL, Spark SQL, KQL, DAX, M, TMDL, REST endpoints, CLI flags.
- MCP-related entries: new MCP servers, new tools on existing servers, transport / URL / authentication changes.
- Harness entries: hook events and their JSON fields, `settings.json` keys, frontmatter fields on skills / subagents / rules, `~/.claude/` path changes, `permissions` rule syntax, plugin and marketplace layout.

Apply the source's `filter` first if it has one. A filtered-out entry is bucket (d) — record it as a count, not a bullet, and never drill it.

Also capture **removed entries** as a separate set — a removal usually signals GA promotion (status cleared, row moved between tables) or a deprecation. Flag both kinds; preview-to-GA is high-value drift signal because skills often hedge on preview status.

**A `table` source is classified on disk.** Key every row of every version, in every table carrying the feature column, by its feature name, per the entry's `columns` mapping, with any status the mapping puts inside the name (`(Preview)`, `(Generally Available)`) stripped, so a row moving between tables keeps its key; record each key's table or section, and its month where the table has one. Then put each key in one class: *added* (in HEAD, not prior), *transient* (in some in-window version, in neither prior nor HEAD), *promoted* (its table or status moved), or *removed* (in prior, not HEAD, perhaps under a new name). Write that to a table in the scratchpad and read only its changed keys, in a compact view within step 4's budget. On `fabric`'s 2026-09-01 window the table held 453 keys, 309 of them changed: 389 KB with each row's captured cells, 23 KB as a view of the changed keys. All 22 transient rows sat in per-workload tables gone by HEAD, outside the two the entry's `sections` names (2026-10-15). Capture a transient entry from the last version that held it, like any added one, and say in the report that it is gone at HEAD.

Keep the files on disk: what enters the conversation is a diff, the extracted entries or the table's changed keys, never both refs whole.

## 5. Phase 2 — Map to current artifacts

For each diff entry, decide its bucket. Scan only the artifact classes the source's registry `artifacts` field lists:

- **Skill match** — `Glob` this repo's two skill trees, `skills/*/*/SKILL.md` and `.claude/skills/*/SKILL.md`, for directory-name keyword hits; `Grep` the skill descriptions and bodies in both trees for feature-name and syntax keywords. Not `~/.claude/skills`: the platform groups are pruned from user scope, so no Fabric or Power BI skill is there to match.
- **Rule match** — `Grep ~/.claude/rules/coding-*.md` for per-language overlap (a new T-SQL keyword lands on `coding-tsql.md`, a new DAX function on `coding-dax.md`, etc.).
- **CLAUDE.md match** — `Read ~/.claude/CLAUDE.md`; check whether a current instruction line is invalidated or extended by the entry.
- **MCP match** — `Read claude/mcp/.mcp.global.template.json` **and** `claude/mcp/.mcp.project.template.json` for the current server inventory across both global and per-project scopes; identify whether the entry adds, removes, or changes a server. Placing a finding is a two-step test. First, does it work from Claude Code at all? The Fabric-hosted `api.fabric.microsoft.com/v1/mcp/*` endpoints do not connect through Claude Code's **automatic** OAuth flow (DCR), but a `headersHelper` command supplying an `az` bearer does reach them — **every endpoint probed as of 2026-09-14 (CLI 2.1.268) connects**: bare `dataPlane/sqlEndpoint` and `dataPlane/kqlEndpoint`, `core`, `powerbi`, a workspace/item-bound `kqlEndpoint`, and the workspace-bound Activator reflex URL. So the hosted endpoints are **not** categorically out of Claude Code's reach — place each one by measurement, and treat "hosted" as saying nothing about reachability. The single measured failure is the workspace/item-bound `dataPlane/sqlEndpoint`, which returns `MCP endpoint not found` in the one tenant probed while its bound `kqlEndpoint` sibling connects; the second documented route, `--client-id`/`--client-secret`, is still unprobed. An unprobed endpoint that Learn documents goes in the project template, marked **Unprobed** in `claude/mcp/README.md` (2026-10-02); one found only in upstream config stays out. Note that a helper producing no credential prints the DCR error itself, so that error is not evidence the route is unsupported — see `claude/mcp/README.md`. Second, if it does work: is it bound to a workload (needs a workspace ID, database, connection string, or a running desktop app) or not? Workload-bound goes in the project template; cross-workload — docs, source control, cloud control plane — goes in the global one. Transport is not the test; a stdio server can be workload-bound and an http server can be universal.
- **Harness match** — `Read ~/.claude/settings.json` for the hook event wiring, permissions, and env keys currently in use; `Glob ~/.claude/hooks/*` and `Grep` them for event names and hook JSON fields; `Grep` skill / subagent / rule frontmatter for the fields the entry touches (`allowed-tools`, `paths`, `model`, `argument-hint`). A renamed hook event or a moved `~/.claude` path breaks the deployed payload silently — there is no error path, so this scan is the only detection. Findings here land on the repo files the source's `artifacts` names, including `scripts/link-claude.ps1` when a deployed location moves.

Classify each diff entry into exactly one bucket:

- **(a) Drift / gap** — an existing skill, rule, or `CLAUDE.md` line covers the topic and the entry changes the picture (new syntax, new limit, deprecation, behavioural change, GA-from-preview where the skill flagged preview status).
- **(b) New-skill candidate** — no current artifact covers the topic at all.
- **(c) Tooling / MCP / CLI** — affects an MCP template, `CLAUDE.md` tooling notes, or a referenced CLI's scope.
- **(d) No-op** — cosmetic, marketing, or unrelated to the current artifact scope.

If a diff entry straddles two buckets, split it on the way in. Forcing a single bucket per finding keeps the report actionable — each bullet maps to one follow-up task.

**Do not bulk-rewrite from a single audit — drift edits are per-artifact decisions.** A monthly diff can list ten flagged entries; that's ten separate per-skill rewrite tasks, not one batch.

## 6. Phase 3 — Selective upstream drill

Drilling upstream docs is expensive (token cost, latency, and brittle pages). Do it only where the answer affects an existing artifact's accuracy or a tooling decision. Open each link with the mechanism its source's `drill.via` names — `microsoft-learn-mcp` (`microsoft_docs_fetch`, which returns the full page rather than a summary) for the Microsoft sources, `webfetch` otherwise. Never assume a doc host; read it from the entry.

- **Bucket (a) only** — drill each linked page. Extract: syntax additions, new limits / quotas / retention windows, deprecations, behavioural changes that contradict current artifact content. Cite the specific URL and the specific change in the report.
- **Bucket (b)** — diff entry only; do not drill. New-skill scoping is its own task and over-drilling here pre-commits to authoring before the user has agreed the skill is worth writing.
- **Bucket (c)** — drill the linked MCP reference page if present; extract server name, transport, URL. **Do not invent MCP transports or URLs.** If an endpoint is announced without a clear reference page, mark it `endpoint TBD — verify before template add` and stop.
- **Bucket (d)** — skipped.

Graceful handling: paywall / login-wall / 404 / redirect-loop → note inline in the report (`drill failed: <reason>`) and continue. One broken link must not block the rest of the audit.

## 7. Phase 4 — Report format

Emit one markdown report to the conversation, sections in this exact order. If a bucket is empty, still include the heading with `_(none)_` underneath — an empty heading is signal, not noise.

```markdown
## Audit window

- Floor: <ISO date> (resolved from: <sha | date>) | per source (resolved from: ledger)
  - <id>: `<sha-or-date>` (<date>) from <`docs/audits/<run-date>/<id>/` | default-35d>
  - ...on a per-source floor only, one line per audited source...
- Fetch path: <clone | github-mcp | WebFetch fallback>
- Sources audited: <id, id> — skipped: <id, id | none>
- <label>: <n> landings in window — prior `<prior-sha-or-floor>` (<prior-date>) → head `<head-sha>` (<head-date>)
  - `<sha>` (<date>) — <a squash's subject | the merge, and the commits it carries>, `<path>` <+n/-m>
  - ...one line per landing, newest first; without a clone, one per listed commit, and the listing's two limits...
- ...one block per audited source, id order...

## Drift / gap candidates (existing artifacts)

- **<artifact-slug>** — <diff entry feature name> _(<source-id>)_
  - Specific change: <what's new or different>
  - Reference: <anchor-stripped URL>
  - Proposed action: <flag | minor edit | partial rewrite>

## New-skill candidates

- **<feature name>** — <one-line rationale: skill vs CLAUDE.md line vs ignore>
  - Source: <source-id> / <section heading>

## MCP / tooling / CLI additions

- **<server or CLI name>** — <what's new>
  - Reference: <URL or "endpoint TBD — verify">
  - Proposed action: <add to claude/mcp/.mcp.global.template.json | claude/mcp/.mcp.project.template.json | CLAUDE.md note | flag>

## No-op

- <short bullet, no detail>
- <short bullet, no detail>

## Owed re-checks

- **`<run-date>/<dir>/<NN>-<slug>.md`** — owed to <the next `<id>` drift audit | any drift audit>, by its `**Needs**:` line at `:<line>`
  - Owes: <what the line, and the step it names, ask of this run>
  - Outcome: <passed | failed | answered | not in this window> — <what this run saw, and the action carrying any work | what the window lacked>
  - Leaves open: <what else its line names, such as a fresh session | nothing>

## Recommended actions

1. <ordered, flag-only — name the artifact and the action verb>
2. ...
n. <last, whenever Owed re-checks lists any — stamp each one's log>

## Next run

Pass one of these as the prior reference next time:

- <label> head: `<head-sha>` (<head-date>)
- ...one line per audited source...
- Or a single date: `<today's ISO date>`

A SHA from any registered source's repo, or any ISO date, is accepted.
```

Report rules:

- **Flag-only.** Do not propose specific rewritten text — that is the per-artifact follow-up task's job.
- **One artifact per drift bullet.** If two artifacts overlap on the same diff entry, write two bullets.
- **Every drift bullet names its source id.** With a registry, "which page said this" is no longer inferable from the finding.
- **URLs are anchor-stripped** per the source's `drill.strip`, per the Phase 1 invariant.
- **No invention.** MCP transports, URLs, server names — quote the upstream reference or say "TBD". Never fabricate.
- **Enumerate the in-window landings, never just the count.** One line each, with its date and what it is, and for a merge the commits it carries. A bare "3 commits in window" is unfalsifiable: it hides which commits were inspected and which were only listed, and it strands a later reader who wants to reproduce the diff. Twice now — 2026-09-07 on `powerbi`, both runs — the per-commit list has been the thing someone needed to check afterwards. Where a commit was listed but never fetched, say so on its line rather than describing it. Without a clone the lines are the listed commits, and the block names the two limits § 4a step 2 gives that list.
- **Every owed re-check gets an outcome**, even on a run that could do none of them, so the next reader knows it was looked for. *Passed* and *failed* are checks this run performed; *answered* is an upstream question this window settles, either way; *not in this window* names what was missing: a floor after what the check must reproduce, which only `/drift-audit <its floor> --sources <id>` would hold, a condition still unmet, or no in-window change for it to read. A failure, and an answer that calls for an edit, is a finding like any other, with its bucket entry and its own action, which the outcome names. The last action stamps them all, and `/drift-handoff` writes it as the brief that closes each one or records what it still waits on.
- **Next-run footer always printed.** Even when buckets are empty — the SHAs are the user's handoff to next month, and a no-argument run reads them back from the ledger (§ 2). So each audited source gets its own line, with its head SHA, and on that line any floor the next run should take instead.

## 8. Closing constraints

After emitting the report, restate the read-only contract briefly so any follow-up turn in the same conversation lands cleanly:

> Audit complete. Read-only contract: no skill / rule / `CLAUDE.md` / MCP-template edits this turn. To capture the recommended actions as handoff briefs on disk, run `/drift-handoff` now — it reads this report from the conversation, so it has to run before the context is lost. Its copy of this report is also where the next no-argument audit takes each source's floor. A later session then executes those briefs with `/drift-update`. To act on a finding directly instead, start a new request naming the specific artifact and the action.

Constraints to honour throughout the turn:

- **Read-only.** `Edit` / `Write` / `MultiEdit` / `NotebookEdit` are off-limits, and Bash works in the scratchpad alone (§ 3).
- **Registry-driven.** Every repo, path, section, doc host, and anchor pattern comes from the source's own file under `references/sources/`. Nothing about a source is hardcoded here.
- **Selective drill.** Upstream fetches only for bucket (a) and bucket (c)-with-reference.
- **Anchor stripping.** Every URL emitted to the report has the source's `drill.strip` patterns removed.
- **No invention.** Quote the upstream reference for MCP transports / URLs / server names, or say "TBD". Never fabricate.
- **Per-artifact follow-up.** Each flagged drift is its own task; never bulk-rewrite from one audit.
