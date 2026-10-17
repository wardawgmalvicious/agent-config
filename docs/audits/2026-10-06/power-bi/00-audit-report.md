# Drift audit: powerbi, 2026-10-06

## Audit window

- **Floor:** 2026-09-01 (resolved from: ISO date argument)
- **Fetch path:** the `powerbi` entry's own route. Learn's `git_commit_id` led to a verified fork (`jajin7/powerbi-docs`), read through `github-mcp`. No diff strategy was needed because there are no commits in the window.
- **Sources audited:** `powerbi`. Skipped: `fabric`, `vscode-agent`, `claude-code`, `fabric-iq-ontology`, `skills-for-fabric` (not selected by `--sources`).
- **Power BI What's New:** 0 commits in window. Prior `0e80b00b` (2026-08-25) → head `0e80b00b` (2026-08-25).
  - _(none)_. The last commit to touch `powerbi-docs/fundamentals/whats-new.md` is still `0e80b00b` (2026-08-25T16:26Z, "Fix broken forum link"). The 2026-09-07 run already audited it as its head.

**The zero means the page hasn't changed, and Learn is the evidence for that, not the fork.** Learn serves `git_commit_id` `0e80b00bf4b83809178cdce6b055171e9e0c9604` with `updated_at` 2026-08-25T17:13Z, and the title still says "August 2026". The archive page stops at July 2026. `jajin7`'s empty list for the window counts only because the step-4 check passed. That fork was created on 2026-08-31 and has had nothing pushed since, so it can't hold a later commit. Its `[]` would look the same whether or not upstream had moved.

**The fork route worked on a second window, but only after I widened the date anchor.**
- **At the floor:** step 2 with `created:>=2026-09-01` returned five repos, none of them usable.
  - Four were `powerbi-docs-powershell` substring hits, dropped by the exact-name check.
  - The fifth was `martinps3/powerbi-docs` (created 2026-09-24, default branch `live`). It returned `[]` for the path, so I rejected it.
- **At Learn's `updated_at` date:** `created:>=2026-08-25` returned seven repos, including `jajin7` (2026-08-31) and `bsnyder9` (2026-08-26).
  - Both have `0e80b00b` as HEAD for the path, and both still have `created_at == updated_at`. I used `jajin7`.

**I couldn't settle whether Learn is lagging or September was quiet.** A web search on 2026-10-06 found the July and August 2026 feature summaries but no September one. A search is weak evidence that something doesn't exist.

**Last run:** the most recent `powerbi` audit in `docs/audits/` is dated 2026-09-07 (floor 2026-08-01, head `0e80b00b`). A 2026-09-01 floor leaves no gap, because the base is resolved by path and comes back as that same head (`until: 2026-09-01` returned `0e80b00b`).

There were no diff entries, so no anchors needed stripping. Repository search still lists only `powerbi-docs-powershell` under `MicrosoftDocs`. That fits the takedown but doesn't re-check the 404.

Calls used: 1 WebFetch, 3 repository searches, 5 `list_commits`, 1 `get_commit` (`detail: none`), 1 Learn search, 1 web search.

## Drift / gap candidates (existing artifacts)

_(none)_

## New-skill candidates

_(none)_

## MCP / tooling / CLI additions

_(none)_

## No-op

_(none)_. There are no diff entries in the window.

## Recommended actions

1. **Re-anchor the fork search in the `powerbi` registry entry** (`.claude/skills/drift-audit/references/sources.md`, Fetch strategy step 2).
   - Anchored at this run's floor, the search found no usable fork. Both matching forks were created before the floor, and I only reached them by anchoring at Learn's `updated_at` date.
   - In the same edit, add this second window to the "Young, but no longer improvised" paragraph.
   - Minor edit.
2. **Flag two gaps in the same entry.** Both are inferred, not measured.
   - **Fork route ends at the takedown:** no fork can sync a commit made after the mirror went away. The first run after Learn republishes should expect every candidate to fail step 4 and fall back to the Learn page.
   - **Fallback sees one month:** the Learn page shows a single month. A window that spans two monthly updates needs `desktop-latest-update-archive` for the month that dropped off.
   - Flag only. Confirm on the first run after Learn republishes before writing it down as fact.

## Next run

Pass one of these as the prior reference next time:

- Power BI What's New head: `0e80b00bf4b83809178cdce6b055171e9e0c9604` (2026-08-25)
- Or a single date: `2026-09-01`. Reuse this floor rather than today's date. Nothing was published in this window, and the Learn fallback works out the window from the page's own dates. A September update's month label would fall before a 2026-10-06 floor even if it is published later.

A SHA from any registered source's repo, or any ISO date, is accepted. Re-run once Learn's What's New title moves past August 2026.
