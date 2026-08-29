---
name: drift-audit
description: "Audit registered upstream docs sources for drift since a prior commit SHA or date — detect new GA / preview features, syntax additions, deprecations, and tooling changes that affect existing skills, rules, CLAUDE.md, or the MCP templates. Sources live in a registry (references/sources.md) covering Microsoft Fabric (incl. RTI) and Power BI What's New, plus the VS Code agent customization docs that govern how this config reaches GitHub Copilot; RTI folds into the Fabric source. Use when running a monthly Fabric / Power BI staleness check, evaluating recent Microsoft data-platform features, checking whether VS Code moved the chat.*Locations wiring, or auditing what changed on the registered pages between two points in time. Narrow a run with --sources <id,id>. Prefers github-mcp for exact file bytes and commit patches, falling back to WebFetch on raw.githubusercontent.com. Findings only — no edits."
argument-hint: "[prior-sha-or-date] [--sources id,id]"
arguments: prior_ref
allowed-tools: WebFetch Read Grep Glob mcp__github-mcp__list_commits mcp__github-mcp__get_commit mcp__github-mcp__get_file_contents mcp__microsoft-learn-mcp__microsoft_docs_fetch
model: inherit
---

# Drift audit

Audit the source markdown of registered upstream docs pages against the local Claude config — skills, rules, `CLAUDE.md`, MCP templates — and emit a structured findings report. Inline execution; the report stays in the conversation so the user can iterate on follow-up actions.

**Read-only — never modify any artifact this turn.** Rewriting a skill / rule / `CLAUDE.md` / MCP template based on the findings is a separate, per-artifact task initiated after this audit completes.

## 1. Sources

The audit input is a **registry**, not a fixed pair of pages. `Read` [references/sources.md](references/sources.md) at the start of every run and drive the pipeline from it. Never hardcode a repo, path, section heading, or doc host into the run — if something needed for a source isn't in its registry entry, the entry is incomplete and that is the finding.

Each entry carries an `id` (what `--sources` matches), its GitHub repo / branch / path or plain `url`, a `shape` (`table` / `prose` / `changelog`) that drives extraction, `sections` for the WebFetch fallback, a `drill` block (host, mechanism, anchor-strip patterns) for Phase 3, and the `artifacts` classes it can produce findings against. The registry's Shape contracts section defines what "an entry" means per shape; its Adding a source checklist is the procedure for widening the audit.

As registered today: `fabric` and `powerbi`, both `table` shape, both public and fetchable anonymously.

## 2. Argument parsing

The user invokes with a prior reference — slash form `/drift-audit <ref>`, natural language ("audit since SHA `abc1234`", "audit since 2026-03-15"), or no argument. The reference is applied to every audited source independently.

- **SHA** (40-hex or 7+hex prefix) — resolve to its commit timestamp against any registered source's repo (the SHA's source repo doesn't have to match; we only need its date). Use that date as the floor for every source's `since` window.
- **ISO date** (`YYYY-MM-DD`) — use directly as the floor.
- **No argument** — default to 35 days back from today. Print the resolved floor date in the audit window section.
- **Anything else** — ask the user to clarify; do not guess.

A single reference applied to every source is intentional: the audit window is "what changed since I last checked," not "what changed in the Fabric repo specifically." Each source resolves the window against its own commits.

**`--sources <id,id>`** narrows the run to the named registry ids. Absent, audit every registered source. An id with no registry entry is an error — list the valid ids and stop rather than silently auditing a subset. Skipped sources are named in the report so an empty bucket is never mistaken for a clean one.

## 3. Read-only scope

Prohibited tools this turn: `Edit`, `Write`, `MultiEdit`, `NotebookEdit`. Do not call them regardless of what the audit findings suggest is needed.

If the user asks within this same turn to "fix the drift you found", "update fabric-mlv", "rewrite the skill", "patch CLAUDE.md", etc., refuse and explain:

> The audit is read-only by design. Each artifact rewrite is its own task with its own context — the audit report you just received is the input to that follow-up. Start a new request naming the specific skill or rule to update.

This separation matters because a single bad rewrite during audit triage can silently corrupt the artifact set, and the per-skill rewrite task has different review and validation steps than the audit itself. The body prompt is the only enforcement — `allowed-tools` lists the auto-approval scope, not a hard restriction.

## 4. Phase 1 — Fetch and diff each source

Work through the selected sources in registry order. Two fetch paths; pick once, at the top of the run, and say which one the report used.

### 4a. Preferred path — `github-mcp`

Available when the `github-mcp` tools are present in the session. Returns exact file bytes and real unified patches, so nothing is reconstructed from a summary.

1. **Resolve HEAD** — `list_commits` on the source's repo, filtered to its `path`, `perPage: 1`. Record `<head-sha>` and `<head-date>`.
2. **List commits in window** — `list_commits` with the same path filter and `since: <floor-date>T00:00:00Z`. If zero commits, mark the source "no changes" and move on (it still gets an audit-window line and a Next-run entry).
3. **Get the changes** — two strategies, by commit count:
   - **5 or fewer in-window commits** — `get_commit` per SHA and read the unified patch for the source's `path`. Added and removed lines come straight from the patch; no side-by-side reconstruction.
   - **More than 5** — `get_file_contents` at the prior ref and again at `<head-sha>`, then diff the two versions as in step 4c. Cheaper than a patch per commit once the count climbs.
4. Skip 4b entirely.

### 4b. Fallback path — `WebFetch`

Used when `github-mcp` is unavailable. Keeps the skill working for anyone cherry-picking it into a plain `~/.claude/`.

- Raw markdown at any ref: `https://raw.githubusercontent.com/<repo>/<sha-or-branch>/<path>`
- Commits list: `https://api.github.com/repos/<repo>/commits?path=<path>&per_page=<n>` with optional `&sha=<ref>` or `&since=<ISO-date>`

GitHub anonymous API limit is 60 requests/hour and this path is unauthenticated. Budget ~3 calls per source (commits list, raw at prior ref, raw at HEAD), plus one re-fetch per section when the completeness check below trips. Two sources fit comfortably; a registry past roughly six sources does not, and that is the point at which the `github-mcp` path stops being optional.

Resolve the diff base the same way: if the user supplied a date, use the parent of the oldest in-window commit; if a SHA whose repo matches this source, use that SHA directly; if a SHA from another source's repo, fall back to the date-based resolution.

**Completeness check — re-fetch by section if summarized.** `WebFetch` passes responses through a small LLM that summarizes pages above ~30–40 KB. Both registered What's New sources are ~50 KB; a broad "return the full markdown" prompt typically returns a bulleted feature list with table rows collapsed and descriptions dropped. After each fetch, scan the payload for tell-tale summarization: bullet lists where pipe-delimited tables should be, "additional sections truncated" language, missing description columns, or entry counts that look thin for a monthly cadence. If summarized, **re-fetch the same URL with targeted section prompts — one per heading in the source's registry `sections` list**, each asking for that section's content verbatim. Cache results in working memory keyed by section heading. Targeted prompts reliably return full content; broad ones do not. Skip this step only if the broad fetch returned complete, unsummarized content for every section.

A source whose registry entry has no `sections` list has no targeted-re-fetch escape hatch. If its broad fetch comes back summarized, report the source as `fetch incomplete — github-mcp required` rather than diffing a summary.

### 4c. Extract entries — by the source's `shape`

Walk prior and HEAD, splitting into entries per the registry's Shape contracts (`table` — rows keyed by the feature column; `prose` — heading blocks; `changelog` — version sections). For each entry present in HEAD but not in prior, capture:

- The section heading (and parent heading if relevant), or the version string for `changelog`.
- The entry's own fields — for `table`, the cells named by the entry's `columns` mapping; for `prose` and `changelog`, the entry text.
- Any link into the source's `drill.host`. **Strip the anchor patterns named in `drill.strip`** before storing — unstable anchors break across page revisions and pollute downstream diffing.
- Code or syntax examples — T-SQL, Spark SQL, KQL, DAX, M, TMDL, REST endpoints, CLI flags.
- MCP-related entries: new MCP servers, new tools on existing servers, transport / URL / authentication changes.

Also capture **removed entries** as a separate set — a removal usually signals GA promotion (status cleared, row moved between tables) or a deprecation. Flag both kinds; preview-to-GA is high-value drift signal because skills often hedge on preview status.

Hold the diff in working memory; do not write it to disk.

## 5. Phase 2 — Map to current artifacts

For each diff entry, decide its bucket. Scan only the artifact classes the source's registry `artifacts` field lists:

- **Skill match** — `Glob ~/.claude/skills/*/SKILL.md` for directory-name keyword hits; `Grep` skill descriptions and bodies for feature-name and syntax keywords.
- **Rule match** — `Grep ~/.claude/rules/coding-*.md` for per-language overlap (a new T-SQL keyword lands on `coding-tsql.md`, a new DAX function on `coding-dax.md`, etc.).
- **CLAUDE.md match** — `Read ~/.claude/CLAUDE.md`; check whether a current instruction line is invalidated or extended by the entry.
- **MCP match** — `Read ~/.claude/mcp/.mcp.global.template.json` **and** `~/.claude/mcp/.mcp.project.template.json` for the current server inventory across both global and per-project scopes; identify whether the entry adds, removes, or changes a server. Placing a finding is a two-step test. First, does it work from Claude Code at all? The Fabric-hosted `api.fabric.microsoft.com/v1/mcp/*` endpoints do not (OAuth DCR unsupported) and belong only in the VS Code workspace template, `.vscode/mcp.template.json` in the agent-config repo. Second, if it does work: is it bound to a workload (needs a workspace ID, database, connection string, or a running desktop app) or not? Workload-bound goes in the project template; cross-workload — docs, source control, cloud control plane — goes in the global one. Transport is not the test; a stdio server can be workload-bound and an http server can be universal.

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

- Floor: <ISO date> (resolved from: <sha | date | default-35d>)
- Fetch path: <github-mcp | WebFetch fallback>
- Sources audited: <id, id> — skipped: <id, id | none>
- <label>: <commit-count> commits in window — prior `<prior-sha-or-floor>` → head `<head-sha>` (<head-date>)
- ...one line per audited source, registry order...

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
  - Proposed action: <add to ~/.claude/mcp/.mcp.global.template.json | ~/.claude/mcp/.mcp.project.template.json | .vscode/mcp.template.json | CLAUDE.md note | flag>

## No-op

- <short bullet, no detail>
- <short bullet, no detail>

## Recommended actions

1. <ordered, flag-only — name the artifact and the action verb>
2. ...

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
- **Next-run footer always printed.** Even when buckets are empty — the SHAs are the user's handoff to next month.

## 8. Closing constraints

After emitting the report, restate the read-only contract briefly so any follow-up turn in the same conversation lands cleanly:

> Audit complete. Read-only contract: no skill / rule / `CLAUDE.md` / MCP-template edits this turn. To act on a finding, start a new request naming the specific artifact and the action.

Constraints to honour throughout the turn:

- **Read-only.** `Edit` / `Write` / `MultiEdit` / `NotebookEdit` are off-limits.
- **Registry-driven.** Every repo, path, section, doc host, and anchor pattern comes from `references/sources.md`. Nothing about a source is hardcoded here.
- **Selective drill.** Upstream fetches only for bucket (a) and bucket (c)-with-reference.
- **Anchor stripping.** Every URL emitted to the report has the source's `drill.strip` patterns removed.
- **No invention.** Quote the upstream reference for MCP transports / URLs / server names, or say "TBD". Never fabricate.
- **Per-artifact follow-up.** Each flagged drift is its own task; never bulk-rewrite from one audit.
