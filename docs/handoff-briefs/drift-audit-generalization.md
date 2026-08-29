# Handoff brief: generalize `drift-audit` beyond the Microsoft docs sources

Status: **open** — drafted 2026-08-28, not yet acted on.
Target artifact: [skills/drift-audit/SKILL.md](../../skills/drift-audit/SKILL.md) (175 lines, single file, no `references/`).

## Why this brief exists

The skill was written when every skill in this repo was Fabric or Power BI.
Its two doc sources are hardcoded to `MicrosoftDocs/fabric-docs` and
`MicrosoftDocs/powerbi-docs`, so adding a skill in an unrelated domain — a
SharePoint HTML-building skill is the live example — gives that skill no
staleness check at all. The audit would keep reporting clean while the new
skill silently rots.

This is a revision brief, not a new-skill brief, so it does not use
[skill-handoff-template.md](skill-handoff-template.md) verbatim. The
frontmatter and post-draft validation sections still apply.

## Decision already taken: do not rename to `skill-audit`

Considered and rejected. Recorded here so it is not relitigated.

- **It audits more than skills.** Phase 2 scans four artifact classes:
  `~/.claude/skills/*/SKILL.md`, `~/.claude/rules/coding-*.md`,
  `~/.claude/CLAUDE.md`, and both MCP templates. `skill-audit` names one
  quarter of the target surface.
- **It reads as a different tool.** "Skill audit" most naturally means
  *audit the quality of my skills* — frontmatter validity, description
  triggering, overlap between skills. That is a plausible future skill, and
  taking the name now would collide with it.
- **The name was never the problem.** `drift-audit` accurately describes the
  job: detect drift between upstream truth and local artifacts. What is
  narrow is the **source list**, and the fix is to widen it.

Keep `drift-audit`. Widen the sources.

## Current shape

Source table, SKILL.md §1:

| Source | Repo | Branch | Path |
| --- | --- | --- | --- |
| Fabric (incl. RTI) | `MicrosoftDocs/fabric-docs` | `main` | `docs/fundamentals/whats-new.md` |
| Power BI | `MicrosoftDocs/powerbi-docs` | `main` | `powerbi-docs/fundamentals/whats-new.md` |

Everything downstream of that table is already domain-neutral in structure
but Microsoft-flavored in its details:

- §2 argument parsing — neutral.
- §4 fetch/diff — neutral mechanics, but step 4a hardcodes Microsoft H2/H3
  section names (`Generally available features`, `Features currently in
  preview`, per-workload subsections) for the re-fetch-when-summarized
  workaround, and §5 assumes a **table-driven** page with
  Feature / Description / Currently-in-preview columns.
- §5 bucket classification — neutral.
- §6 MS Learn drill — Microsoft-specific by name and by link shape.

So roughly: the pipeline generalizes, the *page-shape assumptions* do not.
That is the real work, and it is more than editing a table.

## Proposed change

**A source registry with per-source shape metadata**, replacing the
two-row table. Each entry carries what the fetch and diff steps currently
assume implicitly:

- `id` and human label
- repo / branch / path (or a plain URL for non-GitHub sources)
- `shape`: `table` (Microsoft What's New) vs `prose` vs `changelog`
- section headings to use for the targeted re-fetch when `WebFetch`
  summarizes a large page
- which artifact classes the source can produce findings for
- the drill-down doc host, so §6 is not hardcoded to `learn.microsoft.com`

Then §4a and §5 read the shape rather than assuming Microsoft's.

## Open questions for the next session

1. **Is `prose`/`changelog` shape support actually needed for v2?** A
   SharePoint source may or may not have a table-driven What's New. Check
   the real page before building a generic differ — if it is also
   table-driven, v2 is much smaller than this brief implies.
2. **Does the audit stay one skill, or fan out per domain?** One skill with
   N sources means every run pays for every domain. A `sources` argument
   (`/drift-audit --sources fabric,powerbi`) may be the cheaper answer than
   splitting.
3. **Where does the registry live** — inline in SKILL.md, or a
   `references/sources.md` that the skill reads? Adding a `references/`
   directory would make this the first behavioral skill to have one.
4. **GitHub API budget.** §1 notes 60 req/hour anonymous and ~6 calls for
   two sources. Five sources is ~15 calls, still fine; ten is not, and the
   skill would need the authenticated path. Note that `github-mcp` is now
   available project-scoped with a PAT, which changes what is possible here.

## Constraints to preserve

- **Read-only.** §3's prohibition on `Edit`/`Write`/`MultiEdit`/`NotebookEdit`
  and the refusal text for in-turn fix requests are the skill's core
  behavioral contract. Any rewrite keeps them verbatim.
- **`allowed-tools: WebFetch Read Grep Glob`** — unchanged unless the
  authenticated-GitHub question above is answered yes.
- **Frontmatter `description` is the whole trigger mechanism.** If sources
  become plural, the description must stop promising Fabric/Power BI
  specifically, without ballooning past 1,024 chars.
- **The MCP-placement guidance in §5 was just rewritten** (see the
  `refactor(mcp): scope the templates by workload` commit) and is current.
  Do not regress it to the old transport-based rule.

## Post-draft validation

1. `uv run --with pyyaml scripts/lint-frontmatter.py skills/drift-audit/SKILL.md`
2. Restart the Claude Code session — skill edits do not reliably reload
   mid-session on Windows.
3. Run the audit against a known window with the existing two sources and
   confirm the report is unchanged in shape from the pre-revision run.
4. Confirm the read-only refusal still fires: ask it to "fix the drift you
   found" in the same turn and check it declines.
