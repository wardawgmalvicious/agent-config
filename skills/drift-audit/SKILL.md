---
name: drift-audit
description: "Audit the Microsoft Fabric and Power BI What's New docs source for drift since a prior commit SHA or date — detect new GA / preview features, syntax additions, deprecations, and tooling changes that affect existing skills, rules, CLAUDE.md, or the MCP template. Use when running a monthly Fabric / Power BI staleness check, evaluating recent Microsoft data-platform features, or auditing what changed on the official What's New pages between two points in time. Diffs raw markdown at MicrosoftDocs/fabric-docs and MicrosoftDocs/powerbi-docs on GitHub against the user-supplied reference; RTI updates fold into the Fabric source. Findings only — no edits."
argument-hint: "[prior-sha-or-date]"
arguments: prior_ref
allowed-tools: WebFetch Read Grep Glob
model: inherit
---

# Drift audit

Audit the source markdown of the Microsoft Fabric and Power BI "What's New" docs pages against the local Claude config — skills, rules, `CLAUDE.md`, MCP template — and emit a structured findings report. Inline execution; the report stays in the conversation so the user can iterate on follow-up actions.

**Read-only — never modify any artifact this turn.** Rewriting a skill / rule / `CLAUDE.md` / MCP template based on the findings is a separate, per-artifact task initiated after this audit completes.

## 1. Sources

Two GitHub-hosted markdown sources are the audit input. Both are public, both fetchable anonymously.

| Source | Repo | Branch | Path |
| --- | --- | --- | --- |
| Fabric (incl. RTI) | `MicrosoftDocs/fabric-docs` | `main` | `docs/fundamentals/whats-new.md` |
| Power BI | `MicrosoftDocs/powerbi-docs` | `main` | `powerbi-docs/fundamentals/whats-new.md` |

Real-Time Intelligence has no separate What's New page — RTI updates fold into the Fabric source above. Don't search for one.

URL patterns:

- Raw markdown at any ref: `https://raw.githubusercontent.com/<repo>/<sha-or-main>/<path>`
- Commits list: `https://api.github.com/repos/<repo>/commits?path=<path>&per_page=<n>` with optional `&sha=<ref>` or `&since=<ISO-date>`

GitHub anonymous API limit is 60 requests/hour. A monthly audit uses ~6 calls (2 sources × 3 fetches each: commits list, raw at prior ref, raw at HEAD). Well within budget; no auth required for v1.

## 2. Argument parsing

The user invokes with a prior reference — slash form `/drift-audit <ref>`, natural language ("audit since SHA `abc1234`", "audit since 2026-03-15"), or no argument. The reference is applied to both sources independently.

- **SHA** (40-hex or 7+hex prefix) — resolve to its commit timestamp via `https://api.github.com/repos/<any-repo>/commits/<sha>` (the SHA's source repo doesn't have to match the audit source; we only need its date). Use that date as the floor for both sources' `&since=` query.
- **ISO date** (`YYYY-MM-DD`) — use directly as the floor.
- **No argument** — default to 35 days back from today. Print the resolved floor date in the audit window section.
- **Anything else** — ask the user to clarify; do not guess.

A single reference applied to both sources is intentional: the audit window is "what changed since I last checked," not "what changed in the Fabric repo specifically." Each source resolves the window against its own commits.

## 3. Read-only scope

Prohibited tools this turn: `Edit`, `Write`, `MultiEdit`, `NotebookEdit`. Do not call them regardless of what the audit findings suggest is needed.

If the user asks within this same turn to "fix the drift you found", "update fabric-mlv", "rewrite the skill", "patch CLAUDE.md", etc., refuse and explain:

> The audit is read-only by design. Each artifact rewrite is its own task with its own context — the audit report you just received is the input to that follow-up. Start a new request naming the specific skill or rule to update.

This separation matters because a single bad rewrite during audit triage can silently corrupt the artifact set, and the per-skill rewrite task has different review and validation steps than the audit itself. The body prompt is the only enforcement — `allowed-tools` lists the auto-approval scope, not a hard restriction.

## 4. Phase 1 — Fetch and diff the docs source

For each of the two sources, in order (Fabric first, Power BI second):

1. **Resolve HEAD** — `WebFetch https://api.github.com/repos/<repo>/commits?path=<path>&per_page=1` with a prompt that extracts the most recent commit's SHA, ISO date, and short message. Record as `<head-sha>` and `<head-date>`.
2. **List commits in window** — `WebFetch https://api.github.com/repos/<repo>/commits?path=<path>&since=<floor-date>T00:00:00Z&per_page=20` with a prompt that extracts SHAs + dates + short messages. If zero commits in window, mark source "no changes" and skip to step 5 (still print Next-run footer).
3. **Fetch prior content** — `WebFetch https://raw.githubusercontent.com/<repo>/<prior-ref>/<path>` retrieving the full markdown. If the user supplied a date, use the parent of the oldest in-window commit (one commit before the floor) as the diff base; if a SHA whose repo matches this source, use that SHA directly; if a SHA from the other repo, fall back to the date-based resolution above.
4. **Fetch HEAD content** — `WebFetch https://raw.githubusercontent.com/<repo>/main/<path>`.
4a. **Verify fetch completeness — re-fetch by section if summarized.** `WebFetch` passes responses through a small LLM that summarizes pages above ~30–40 KB. Both Fabric and Power BI What's New raw markdown are ~50 KB; a broad "return the full markdown" prompt typically returns a bulleted feature list with table rows collapsed and descriptions dropped. After steps 3 and 4, scan each returned payload for tell-tale summarization: bullet lists where pipe-delimited tables should be, "additional sections truncated" language, missing description columns, or feature counts that look thin for a monthly cadence. If summarized, **re-fetch the same URL with targeted section prompts** — one per known H2 / H3 (`Generally available features`, `Features currently in preview`, `Power BI updates`, `Microsoft Fabric Platform Features`, and the per-workload subsections like Data Factory / Data Engineering / Real-Time Intelligence / Warehouse). Each targeted prompt asks for verbatim pipe-delimited rows in that section. Cache results in working memory keyed by section heading. Targeted prompts reliably return full row content; broad ones do not. Skip this step only if the broad fetch returned full pipe-delimited tables for every section.
5. **Section diff in working memory** — walk both versions side by side. For each H2 / H3 / table row present in HEAD but not in prior, capture:
   - The section heading (and parent heading if relevant).
   - The feature row's feature-name column, description column, and preview-flag column (for table-row entries — both What's New pages are table-driven with Feature / Description / Currently in preview columns).
   - Any `learn.microsoft.com` link in the row. **Strip unstable anchor IDs** (`#post-NNNN-_TocNNNN`, `#post-...`) before storing — those anchors break across page revisions and pollute downstream diffing.
   - Code or syntax examples in the row description — T-SQL, Spark SQL, KQL, DAX, M, TMDL, REST endpoints, CLI flags.
   - MCP-related entries: new MCP servers, new tools on existing servers, transport / URL / authentication changes.
6. Also capture **removed rows** as a separate set — a row removed from HEAD usually signals GA promotion (preview-flag cleared, row moved between tables) or a feature deprecation. Flag both kinds; preview→GA is high-value drift signal because skills often hedge on preview status.

Hold the diff in working memory; do not write it to disk.

## 5. Phase 2 — Map to current artifacts

For each diff entry, decide its bucket. Use these scans:

- **Skill match** — `Glob ~/.claude/skills/*/SKILL.md` for directory-name keyword hits; `Grep` skill descriptions and bodies for feature-name and syntax keywords.
- **Rule match** — `Grep ~/.claude/rules/coding-*.md` for per-language overlap (a new T-SQL keyword lands on `coding-tsql.md`, a new DAX function on `coding-dax.md`, etc.).
- **CLAUDE.md match** — `Read ~/.claude/CLAUDE.md`; check whether a current instruction line is invalidated or extended by the entry.
- **MCP match** — `Read ~/.claude/mcp/.mcp.global.template.json` **and** `~/.claude/mcp/.mcp.project.template.json` for the current server inventory across both global and per-project scopes; identify whether the entry adds, removes, or changes a server. A finding can land in either template: globally-applicable stdio servers go in the global template; per-workspace remote servers requiring workspace/item IDs go in the project template.

Classify each diff entry into exactly one bucket:

- **(a) Drift / gap** — an existing skill, rule, or `CLAUDE.md` line covers the topic and the entry changes the picture (new syntax, new limit, deprecation, behavioural change, GA-from-preview where the skill flagged preview status).
- **(b) New-skill candidate** — no current artifact covers the topic at all.
- **(c) Tooling / MCP / CLI** — affects the MCP template, `CLAUDE.md` tooling notes, or a referenced CLI's scope.
- **(d) No-op** — cosmetic, marketing, or unrelated to the current artifact scope.

If a diff entry straddles two buckets, split it on the way in. Forcing a single bucket per finding keeps the report actionable — each bullet maps to one follow-up task.

**Do not bulk-rewrite from a single audit — drift edits are per-artifact decisions.** A monthly diff can list ten flagged entries; that's ten separate per-skill rewrite tasks, not one batch.

## 6. Phase 3 — Selective MS Learn drill

Drilling MS Learn is expensive (token cost, latency, and brittle pages). Do it only where the answer affects an existing artifact's accuracy or a tooling decision.

- **Bucket (a) only** — `WebFetch` each linked MS Learn page. Extract: syntax additions, new limits / quotas / retention windows, deprecations, behavioural changes that contradict current artifact content. Cite the specific URL and the specific change in the report.
- **Bucket (b)** — diff entry only; do not drill. New-skill scoping is its own task and over-drilling here pre-commits to authoring before the user has agreed the skill is worth writing.
- **Bucket (c)** — `WebFetch` the linked MS Learn MCP reference page if present; extract server name, transport, URL. **Do not invent MCP transports or URLs.** If an endpoint is announced without a clear MS Learn reference, mark it `endpoint TBD — verify before template add` and stop.
- **Bucket (d)** — skipped.

Graceful handling: paywall / login-wall / 404 / redirect-loop → note inline in the report (`MS Learn fetch failed: <reason>`) and continue. One broken link must not block the rest of the audit.

## 7. Phase 4 — Report format

Emit one markdown report to the conversation, sections in this exact order. If a bucket is empty, still include the heading with `_(none)_` underneath — an empty heading is signal, not noise.

```markdown
## Audit window

- Floor: <ISO date> (resolved from: <sha | date | default-35d>)
- Fabric: <commit-count> commits in window — prior `<prior-sha-or-floor>` → head `<head-sha>` (<head-date>)
- Power BI: <commit-count> commits in window — prior `<prior-sha-or-floor>` → head `<head-sha>` (<head-date>)

## Drift / gap candidates (existing artifacts)

- **<artifact-slug>** — <diff entry feature name>
  - Specific change: <what's new or different>
  - MS Learn: <anchor-stripped URL>
  - Proposed action: <flag | minor edit | partial rewrite>

## New-skill candidates

- **<feature name>** — <one-line rationale: skill vs CLAUDE.md line vs ignore>
  - Source: <fabric | powerbi> / <section heading>

## MCP / tooling / CLI additions

- **<server or CLI name>** — <what's new>
  - MS Learn: <URL or "endpoint TBD — verify">
  - Proposed action: <add to ~/.claude/mcp/.mcp.global.template.json | CLAUDE.md note | flag>

## No-op

- <short bullet, no detail>
- <short bullet, no detail>

## Recommended actions

1. <ordered, flag-only — name the artifact and the action verb>
2. ...

## Next run

Pass one of these as the prior reference next time:

- Fabric head: `<head-sha>` (<head-date>)
- Power BI head: `<head-sha>` (<head-date>)
- Or a single date: `<today's ISO date>`

A SHA from either repo, or any ISO date, is accepted.
```

Report rules:

- **Flag-only.** Do not propose specific rewritten text — that is the per-artifact follow-up task's job.
- **One artifact per drift bullet.** If two artifacts overlap on the same diff entry, write two bullets.
- **URLs are anchor-stripped** per Phase 1 invariant.
- **No invention.** MCP transports, URLs, server names — quote MS Learn or say "TBD". Never fabricate.
- **Next-run footer always printed.** Even when buckets are empty — the SHAs are the user's handoff to next month.

## 8. Closing constraints

After emitting the report, restate the read-only contract briefly so any follow-up turn in the same conversation lands cleanly:

> Audit complete. Read-only contract: no skill / rule / `CLAUDE.md` / MCP-template edits this turn. To act on a finding, start a new request naming the specific artifact and the action.

Constraints to honour throughout the turn:

- **Read-only.** `Edit` / `Write` / `MultiEdit` / `NotebookEdit` are off-limits.
- **Selective drill.** MS Learn fetches only for bucket (a) and bucket (c)-with-reference.
- **Anchor stripping.** Every URL emitted to the report has `#post-NNNN-_TocNNNN` removed.
- **No invention.** Quote MS Learn for MCP transports / URLs / server names, or say "TBD". Never fabricate.
- **Per-artifact follow-up.** Each flagged drift is its own task; never bulk-rewrite from one audit.
