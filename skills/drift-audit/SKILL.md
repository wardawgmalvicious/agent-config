---
name: drift-audit
description: "Audit a Microsoft data-platform monthly feature summary or release-notes blog post (Fabric, Power BI, Real-Time Intelligence, Azure Data Factory, etc.) for skill staleness, drift in existing skills, new-skill candidates, and MCP/tooling additions. Use when reviewing Microsoft monthly blog updates or evaluating new Microsoft data platform features. Audits ~/.claude/skills/, ~/.claude/rules/, ~/.claude/CLAUDE.md, and ~/.claude/mcp/.mcp.global.template.json. Findings only — no edits."
argument-hint: "[blog-url]"
arguments: blog_url
allowed-tools: WebFetch Read Grep Glob
model: inherit
---

# Drift audit

Audit a Microsoft data-platform monthly feature or release-notes blog post (Fabric, Power BI, Real-Time Intelligence, Azure Data Factory, etc.) against the local Claude config — skills, rules, `CLAUDE.md`, MCP template — and emit a structured findings report. Inline execution; the report stays in the conversation so the user can iterate on follow-up actions.

**Read-only — never modify any artifact this turn.** Rewriting a skill / rule / `CLAUDE.md` / MCP template based on the findings is a separate, per-artifact task initiated after this audit completes.

## 1. Argument parsing

The user invokes with a blog URL — slash form `/drift-audit https://blog.fabric.microsoft.com/...` or natural language ("audit the April 2026 Fabric blog at <url>").

- Extract the URL. If absent, ask the user for it before proceeding — do not guess a default.
- Validate URL is on a known Microsoft data-platform blog domain (`blog.fabric.microsoft.com`, `powerbi.microsoft.com/en-us/blog`, etc.). Warn if not but proceed — this skill is intentionally permissive on source so it works against feature-launch posts and adjacent product blogs without code changes.

## 2. Read-only scope

Prohibited tools this turn: `Edit`, `Write`, `MultiEdit`, `NotebookEdit`. Do not call them regardless of what the audit findings suggest is needed.

If the user asks within this same turn to "fix the drift you found", "update fabric-mlv", "rewrite the skill", "patch CLAUDE.md", etc., refuse and explain:

> The audit is read-only by design. Each artifact rewrite is its own task with its own context — the audit report you just received is the input to that follow-up. Start a new request naming the specific skill or rule to update.

This separation matters because a single bad rewrite during audit triage can silently corrupt the artifact set, and the per-skill rewrite task has different review and validation steps than the audit itself. The body prompt is the only enforcement — `allowed-tools` lists the auto-approval scope, not a hard restriction.

## 3. Phase 1 — Index the blog

`WebFetch` the URL. Walk each feature / announcement section and capture:

- Heading text and a one-sentence summary.
- Code or syntax examples — T-SQL, Spark SQL, KQL (including management commands), DAX, M, TMDL, REST endpoints, CLI flags.
- Every `learn.microsoft.com` link in the section. **Strip unstable anchor IDs** (`#post-NNNN-_TocNNNN`, `#post-...`) before storing — those anchors break across page revisions and pollute downstream diffing.
- MCP-related announcements: new MCP servers, new tools on existing MCP servers, transport / URL / authentication changes.

Hold the indexed sections in working memory; do not write them to disk.

## 4. Phase 2 — Map to current artifacts

For each indexed section, decide its bucket. Use these scans:

- **Skill match** — `Glob ~/.claude/skills/*/SKILL.md` for directory-name keyword hits; `Grep` skill descriptions and bodies for feature-name and syntax keywords.
- **Rule match** — `Grep ~/.claude/rules/coding-*.md` for per-language overlap (a new T-SQL keyword lands on `coding-tsql.md`, a new DAX function on `coding-dax.md`, etc.).
- **CLAUDE.md match** — `Read ~/.claude/CLAUDE.md`; check whether a current instruction line is invalidated or extended by the announcement.
- **MCP match** — `Read ~/.claude/mcp/.mcp.global.template.json` for the current server inventory; identify whether the announcement adds, removes, or changes a server.

Classify each blog section into exactly one bucket:

- **(a) Drift / gap** — an existing skill, rule, or `CLAUDE.md` line covers the topic and the announcement changes the picture (new syntax, new limit, deprecation, behavioural change).
- **(b) New-skill candidate** — no current artifact covers the topic at all.
- **(c) Tooling / MCP / CLI** — affects the MCP template, `CLAUDE.md` tooling notes, or a referenced CLI's scope.
- **(d) No-op** — cosmetic, marketing, GA-of-already-tracked feature with no behavioural change, or unrelated to the current artifact scope.

If a section straddles two buckets, split it on the way in. Forcing a single bucket per finding keeps the report actionable — each bullet maps to one follow-up task.

## 5. Phase 3 — Selective MS Learn drill

Drilling MS Learn is expensive (token cost, latency, and brittle pages). Do it only where the answer affects an existing artifact's accuracy or a tooling decision.

- **Bucket (a) only** — `WebFetch` each linked MS Learn page. Extract: syntax additions, new limits / quotas / retention windows, deprecations, behavioural changes that contradict current artifact content. Cite the specific URL and the specific change in the report.
- **Bucket (b)** — blog summary only; do not drill. New-skill scoping is its own task and over-drilling here pre-commits to authoring before the user has agreed the skill is worth writing.
- **Bucket (c)** — `WebFetch` the linked MS Learn MCP reference page if present; extract server name, transport, URL. **Do not invent MCP transports or URLs.** If an endpoint is announced without a clear MS Learn reference, mark it `endpoint TBD — verify before template add` and stop.
- **Bucket (d)** — skipped.

Graceful handling: paywall / login-wall / 404 / redirect-loop → note inline in the report (`MS Learn fetch failed: <reason>`) and continue. One broken link must not block the rest of the audit.

## 6. Phase 4 — Report format

Emit one markdown report to the conversation, sections in this exact order. If a bucket is empty, still include the heading with `_(none)_` underneath — an empty heading is signal, not noise.

```markdown
## Drift / gap candidates (existing artifacts)

- **<artifact-slug>** — <blog section heading>
  - Specific change: <what's new or different>
  - MS Learn: <anchor-stripped URL>
  - Proposed action: <flag | minor edit | partial rewrite>

## New-skill candidates

- **<feature name>** — <one-line rationale: skill vs CLAUDE.md line vs ignore>
  - Blog: <blog section URL>

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
```

Report rules:

- **Flag-only.** Do not propose specific rewritten text — that is the per-artifact follow-up task's job.
- **One artifact per drift bullet.** If two artifacts overlap on the same blog section, write two bullets.
- **URLs are anchor-stripped** per Phase 1 invariant.
- **No invention.** MCP transports, URLs, server names — quote MS Learn or say "TBD". Never fabricate.

## 7. Closing constraints

After emitting the report, restate the read-only contract briefly so any follow-up turn in the same conversation lands cleanly:

> Audit complete. Read-only contract: no skill / rule / `CLAUDE.md` / MCP-template edits this turn. To act on a finding, start a new request naming the specific artifact and the action.

Constraints to honour throughout the turn:

- **Read-only.** `Edit` / `Write` / `MultiEdit` / `NotebookEdit` are off-limits.
- **Selective drill.** MS Learn fetches only for bucket (a) and bucket (c)-with-reference.
- **Anchor stripping.** Every URL emitted to the report has `#post-NNNN-_TocNNNN` removed.
- **No invention.** Quote MS Learn for MCP transports / URLs / server names, or say "TBD". Never fabricate.
