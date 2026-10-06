# Handoff: repair the fabric registry entry

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 20
- **Kind**: four mechanical defects in one registry entry of the
  project-scope `drift-audit` skill. Each changes what the next `fabric`
  audit extracts or strips, but none changes how it fetches; that is
  brief 18.
- **Target**: `.claude/skills/drift-audit/references/sources.md`, the
  `### fabric` entry (lines 29–51 as of 2026-10-06)

## Context

On 2026-10-02 the What's New page was restructured (`9eda27f8`, "20260929
whats new (#16748)", `whats-new.md` +135/−368). The registry entry
describes a page that no longer exists, and two of its fields did not
describe the page even before the restructure.

## D-1 — `sections` names headings the page no longer has

**Symptom.** The entry's `sections` field reads: "`Generally available
features`, `Features currently in preview`, `Microsoft Fabric Platform
Features`, and the per-workload subsections (Data Factory, Data
Engineering, Data Science, Real-Time Intelligence, Data Warehouse,
Databases, OneLake, Fabric platform)".

**Cause.** Measured by `grep -n '^#'` on both versions in the audit
session:

| Ref | Headings |
| --- | --- |
| base `8375c89d` | `## New to Microsoft Fabric?`, `## Features currently in preview`, `## Generally available features`, `## Community`, `## Power BI`, `## Microsoft Fabric platform features`, `## Continuous Integration/Continuous Delivery (CI/CD) in Microsoft Fabric`, `## Data Factory in Microsoft Fabric`, `## Fabric Apps (Preview)`, `## Fabric Data Engineering`, `## Fabric Data Science`, `## Cosmos DB in Microsoft Fabric`, `## SQL database in Microsoft Fabric`, `## Fabric Data Warehouse`, `## Fabric Mirroring`, `## Real-Time Intelligence in Microsoft Fabric`, `## Fabric IQ`, `## Related content`, plus `####` "samples and guidance" subsections |
| head `7ff5f2b3` | `## New to Microsoft Fabric?`, `## Features currently in preview`, `## Generally available features`, `## Community`, `## Power BI`, `## Stay up to date`, `## Related content` |

Several names in the field ("Databases", "OneLake", "Fabric platform")
did not match the base page either.

**Fix.** List the two table headings that carry entries, verbatim:
`Features currently in preview` and `Generally available features`.

**Open question.** Is a section re-fetch enough to un-summarize a
WebFetch read of either table? Each holds about 100–200 rows (198 and
105 at HEAD), which may itself pass the summarization threshold.
Brief 18 owns that pricing question; record here only what the headings
are.

## D-2 — `columns` names columns the page does not have

**Symptom.** The field reads "feature = `Feature`, description =
`Description`, status = `Currently in preview`".

**Cause.** Neither version has a `Description` or `Currently in preview`
column. The table headers, identical at both refs:

```text
| **Feature** | **Learn more** |                 (preview table)
|**Month** | **Feature** | **Learn more** |      (GA table)
```

Status is not a column. It comes from which table the row is in, plus a
`(Preview)` / `(Generally Available)` suffix inside the bold feature
name. The suffix's spelling varies, e.g. "(Generally available)",
"(preview)" and "(Early Access Preview)".

**Fix.** Set feature = the bold text in `Feature`, description =
`Learn more`, status = table membership (plus suffix), and add the GA
table's `Month` column.

**Knock-on.** The `powerbi` entry carries the same `columns` string.
Check it against that page before assuming the same fix, as its own
entry warns: "Don't copy the pattern across on the assumption that the
two pages render alike".

## D-3 — `drill.strip` misses a third anchor form

**Symptom.** `drill.strip` lists `#post-NNNN-_TocNNNN`, any `#post-...`,
and `#toc-hId-<signed-int>`.

**Cause.** A community-blog anchor form, `#community-<postid>-mcetoc_<id>_<n>`,
appeared in this window. Counts measured in the audit session:

| Form | base `8375c89d` | head `7ff5f2b3` |
| --- | --- | --- |
| `#post-…` | 14 | 10 |
| `#toc-hId-…` (either sign) | 37 | 13 |
| `#community-<id>-mcetoc_…` | 0 | 108 |

At HEAD the new form has two id shapes, `mcetoc_1k3kj91s5_<n>` (98
links) and `mcetoc_1k3t…_<n>` (10 links). Both match the regex
`#community-\d+-mcetoc_[A-Za-z0-9_]+`, which the audit used.

**Fix.** Add the pattern with its counts and date, in the same style as
the entry's note on the signed `#toc-hId` integer.

## D-4 — the entry carries no size note

**Symptom.** Other entries record their measured size (`claude-code`
~590 KB, `skills-for-fabric` 58 KB). This one records none, and
`SKILL.md` § 4b still says both What's New sources are ~50 KB.

**Cause.** Measured in the audit session:

| Ref | Bytes | Lines |
| --- | --- | --- |
| base `8375c89d` | 207,309 | 609 |
| head `7ff5f2b3` | 147,892 | 388 |

**Fix.** Record both sizes, dated, with the consequence: two full
versions are about 355 KB, more than twice the 150 KB per-source budget,
and even a unified diff of this window measured 267,382 bytes. The
`SKILL.md` § 4b claim is brief 18's to correct; don't edit `SKILL.md`
here.

## Sequencing note

Do not bundle this with brief 18. This brief corrects registry facts and
is verified by greps against the live page. Brief 18 decides how the
audit fetches and is verified by re-running an audit. Different
verification, different risk. Both touch `.claude/skills/drift-audit/`,
so whichever runs second re-reads the file it edits.

## Verification

1. `curl -sSf https://raw.githubusercontent.com/MicrosoftDocs/fabric-docs/main/docs/fundamentals/whats-new.md -o <scratchpad>/wn.md`,
   then `grep -n '^#' <scratchpad>/wn.md`. Every heading named in
   `sections` exists.
2. `grep -n '^| *\*\*\(Feature\|Month\)' <scratchpad>/wn.md`. The
   headers match the new `columns` mapping.
3. `grep -oE '#community-[0-9]+-mcetoc_[A-Za-z0-9_]+' <scratchpad>/wn.md | wc -l`
   is non-zero, and stripping with the new pattern leaves zero.
4. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`.
   The `description` is untouched; confirm it still lints.
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric` (floor
2026-09-01), the first run of this source since 2026-09-01. Every figure
above was measured directly in the audit session on files downloaded at
pinned SHAs, not by a subagent.
