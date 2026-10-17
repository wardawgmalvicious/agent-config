# Drift audit — power-bi, 2026-10-17

## Audit window

- Floor: per source (resolved from: ledger). Argument `power-bi` read as `--sources power-bi`.
  - power-bi: `0e80b00bf4b83809178cdce6b055171e9e0c9604` (2026-08-25) from `docs/audits/2026-10-06/power-bi/`; its footer says reuse `2026-09-01` over a later date — moot this run, the page did not move.
- Fetch path: the entry's own strategy (§ 4 override) — `curl` of the Learn page into the scratchpad, meta tags read. No clone, github-mcp or WebFetch.
- Sources audited: power-bi — skipped: claude-code, fabric, fabric-iq-ontology, vscode-agent (not selected).
- Power BI What's New: 0 landings in window — prior `0e80b00b…` (2026-08-25) → head `0e80b00b…` (2026-08-25). Title still *August 2026 update*, `ms.date` 2026-08-18, `updated_at` 2026-08-25T17:13:00Z: 53 days without a publish. Per entry step 1, no rows were read.
  - Not a cadence change: Microsoft has published [Power BI September 2026 Feature Summary](https://community.fabric.microsoft.com/blog/fbc_pbiupdatesblog/power-bi-september-2026-feature-summary/5325831) and [Power BI October 2026 Feature Summary](https://community.fabric.microsoft.com/blog/fbc_pbiupdatesblog/power-bi-october-2026-feature-summary/5374650) on the Fabric Community blog while Learn still serves August. The blog is unregistered, so nothing from it was audited; it is the evidence for the one finding below.

## Drift / gap candidates (existing artifacts)

- **drift-audit** (`references/sources/power-bi.md`) — the source's `url` lags its upstream _(power-bi)_
  - Specific change: Learn's What's New page is two monthly publishes behind the Fabric Community blog; the entry's step 1 ("a lag and a changed cadence look alike from here") is now answerable — the venue moved, or Learn's page is no longer kept monthly.
  - Reference: the two blog URLs above. Drill failed: both answer `HTTP 403` to WebFetch, and `microsoft_docs_fetch` does not cover that host, so a fetch mechanism for the blog is TBD.
  - Proposed action: flag — a decision brief on the fetch target. Search snippets (unverified, not audited) show what a re-pointed source would read in September alone: DirectQuery models created and edited in the service; Full-Text Indexing preview adding `TEXTCONTAINS` / `TEXTSIMILARITY` DAX functions; PBIP GA; a Purge Data option in the Fabric APIs; model editors blocking read-only users from Copilot and remote MCP tools; data answers in M365 Copilot GA. All four of the entry's filter clauses would keep rows from that list.

## New-skill candidates

_(none)_

## MCP / tooling / CLI additions

_(none)_

## No-op

_(none)_

## Owed re-checks

- **`2026-10-08/prompt-audit/02-point-drift-audit-at-the-repo-skill-trees.md`** — owed to the next `/drift-audit` of `fabric` or `powerbi`, by its `**Needs**:` line at `:153`
  - Owes: step 6's skill-match reading on a real diff.
  - Outcome: not in this window — zero landings, nothing to map. The 2026-10-16 `fabric` run passed it (`docs/audits/2026-10-16/fabric/00-audit-report.md:53-56`).
  - Leaves open: stamping its log; no run since has.
- **`2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`** — owed to any drift audit, by its `**Needs**:` line at `:135`
  - Owes: § 1's slash-free `Glob` lists the registry; on a WebFetch-fallback run only, § 4b's completeness check catches the note and the tells.
  - Outcome: passed — `Glob` pattern `*.md`, `path` the sources directory, returned five files (six on 2026-10-16; `skills-for-fabric` retired in `34618f8`). § 4b half: not in this window — the entry's own fetch ran, no fallback.
  - Leaves open: the § 4b half, until a run falls back.

## Recommended actions

1. **`.claude/skills/drift-audit/references/sources/power-bi.md`** — decide the fetch target: keep Learn and accept the lag, or add the Fabric Community blog (shape, columns, sections and a 403-proof fetch all to be re-derived; the blog is prose per feature, not a table).
2. **`2026-10-06/power-bi/00-audit-report.md` footer** — once action 1 lands, its "re-run once the title moves past August" guidance is superseded by the new entry.
3. Stamp both owed re-check logs.

## Next run

Pass one of these as the prior reference next time:

- Power BI What's New head: `0e80b00bf4b83809178cdce6b055171e9e0c9604` (2026-08-25)
- Or a single date: reuse `2026-09-01`, not today's — a 2026-10-17 floor falls after September's and October's month labels. Re-run once Learn's title moves past August 2026, or once action 1 re-points the source.

A SHA from any registered source's repo, or any ISO date, is accepted.
