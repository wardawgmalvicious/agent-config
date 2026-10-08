# `skills-for-fabric` — Microsoft's Fabric skill catalog

- `repo`: `microsoft/skills-for-fabric`
- `branch`: `main`
- `path`: `CHANGELOG.md`
- `shape`: `changelog`
- `sections`: none — the file was 67,836 bytes on 2026-10-08, inside the
  100,000 characters WebFetch reads per call, but WebFetch hands a
  `raw.githubusercontent.com` page to its summarizing model whatever its
  size (SKILL.md § 4b), and with no `sections` there is no targeted
  re-fetch to fall back on. So this source is github-mcp-only in
  practice, as `claude-code` is.
- `filter`: keep a bullet only if it
  1. introduces a skill name that no earlier version section mentions —
     a vendor-or-author candidate, bucket (b). **An `### Added` heading is
     not that test**: `databricks-migration` carries three `0.3.14` bullets
     under Added and has existed since `0.3.0`;
  2. names a skill vendored here, or one a vendored skill routes to —
     `powerbi-report-authoring`, `powerbi-report-design`,
     `powerbi-report-planning`, `powerbi-report-management`;
  3. names an upstream skill with a counterpart here (table below) **and**
     states a behavioural fact — a limit, a request shape, an error and its
     cause — rather than rewording a workflow; or
  4. changes how the catalog itself routes — descriptions, the listing
     budget, references between skills. That is bucket (c).

  Everything else is bucket (d). The migration skills (`synapse-`,
  `databricks-`, `hdinsight-`, `pipeline-migration`) carry much of the
  volume and fall to (d) unless a migration is actually in progress.
- `drill.host`: `learn.microsoft.com`
- `drill.via`: `microsoft-learn-mcp`
- `drill.strip`: none — the bullets carry no links.
- `artifacts`: `skills/powerbi/powerbi-report-authoring/`,
  `skills/powerbi/powerbi-report-design/`, the counterpart skills in the
  table below, `claude/rules/fabric-git-serialization.md`

**A skill catalog rather than a docs page, so its claims are drilled, not
trusted.** Every other source here is documentation, where a claim is
ground truth. This one is another team's skills — claims about Fabric at
the same standing as ours. A behavioural bullet becomes a finding only
once the fact is confirmed on Learn, which is what `drill` is for here.
What upstream *says* is read from `skills/<name>/SKILL.md` with
`get_file_contents`; that is a fetch for context, not the drill.

Registered 2026-09-10, when an outside-repo check for skill prior art was
scoped and collapsed to this one repo. A GitHub code search that day
returned ~2,800 `SKILL.md` files mentioning "Microsoft Fabric" outside
Microsoft's orgs, overwhelmingly aggregators re-hosting the same few
skills; this is the one authoritative origin. `MicrosoftDocs/Agent-Skills`
is the other official catalog and is Azure-scoped — its "Fabric" hits were
Azure Service Fabric and passing mentions. **Don't register an
aggregator or a community catalog here.** A third-party skill is
instructions an agent executes with your permissions, so vendoring one
is running a stranger's prompt.

## Vendored files — check path history, not the changelog

The two `powerbi-report-*` skills are vendored verbatim at `v0.3.13`
(`b8d541c`); each carries a *Local vendoring note* recording that. The
CHANGELOG is **not a complete record of file changes**, measured
2026-09-10 in both directions:

- `list_commits` filtered to either vendored skill's directory returns the
  `v0.3.3`, `v0.3.7` and `v0.3.12` release commits. The changelog names
  those skills under `0.3.3` and `0.3.7` only — `v0.3.12` changed both
  under a catalog-wide bullet that names no skill. Its only change to
  either was stripping the "Update Check" blockquote from `SKILL.md`,
  which `0.3.12` announces for every skill at once; `references/` and
  `assets/` were untouched (verified 2026-09-11 by diffing each
  `SKILL.md` at `65cb0bce` and `ab33f1da`). Clause 2 matches by name, so
  a catalog-wide bullet slips past it either way.
- `0.3.14` says every skill description was rewritten. Neither vendored
  skill's path history shows a `0.3.14` commit.

So for the vendored pair, run `list_commits` with `path:
skills/<name>` and `since:` the vendored merge's time — `b8d541c`,
2026-08-20T13:22:57Z, not the release heading's date — once per skill,
and treat any commit as a re-sync candidate whatever the changelog says.
At registration both returned nothing after `v0.3.12`: the vendored
copies were current through `v0.3.15`.

**An empty list is not proof on its own.** A moved or deleted path
returns the same `[]`, the trap `powerbi` documents for forks. Confirm it
with tree SHAs: list `skills` at the vendored merge commit and at HEAD
with `get_file_contents`, `fields: ["name","sha"]`; equal tree SHAs prove
the content unchanged. One call per ref also covers the two routed-to
skills clause 2 names. Measured 2026-09-10, identical at `b8d541c` and
`65902bae`:

| Upstream skill | Tree SHA |
| --- | --- |
| `powerbi-report-authoring` | `d160d140` |
| `powerbi-report-design` | `b9fe475b` |
| `powerbi-report-management` | `9b609076` |
| `powerbi-report-planning` | `4f847fca` |

## Fetch — one `CHANGELOG.md` patch per commit, isolated by file pagination

Each release lands as one squashed commit, `Release vX from internal
repo`, on a `release/vX` branch, roughly weekly — `0.3.12` through
`0.3.15` shipped 2026-08-13, 08-20, 08-26 and 09-04. It reaches `main`
by a PR merge, sometimes days later, and a path-filtered `list_commits`
shows the **branch commit, not the merge** — history simplification
hides the merge from a path filter:

| Release | Branch commit | Merge to `main` |
| --- | --- | --- |
| v0.3.13 | `22cafc90`, 2026-08-20 08:34Z | `b8d541c` (PR #75), 2026-08-20 13:22Z |
| v0.3.15 | `65902bae`, 2026-09-04 13:13Z | `74f3262c` (PR #86), 2026-09-06 07:01Z |

So a date floor can miss a release whose branch commit predates the floor
but whose merge follows it. Floor the next run at the last-seen branch
commit's date plus one day, or pass that commit's SHA.

**The file is not prepend-only**, unlike `claude-code`'s. The first run,
2026-09-10, found `CHANGELOG.md` edited in place after release:
`9d5fe403` rewrote `0.3.11` and the pre-floor `0.3.10`, `0.3.6` and
`0.3.5` sections, `af9aff33` removed two `0.3.11` bullets, and
`a5e82199` moved a heading. A HEAD-only read cannot see a removal — the
two bullets `af9aff33` removed now exist only in history — so read the
history:

1. `list_commits`, `path: CHANGELOG.md`, `since: <floor>`,
   `fields: ["sha"]`. Then `get_commit`, `detail: "stats"`,
   `perPage: 10` per SHA, for `CHANGELOG.md`'s position in the file list
   and its +/- counts.
2. `get_commit`, `detail: "full_patch"`, `perPage: 1`,
   `page: <position>` returns **only** that file's patch out of a
   squashed release — verified 2026-09-10 on `22cafc90`, where page 3
   returned the `CHANGELOG.md` patch alone out of a release touching
   ~1,960 lines. A commit whose only file is `CHANGELOG.md` needs no
   pagination.
3. Fetch the whole file once at the **base** ref — the last commit
   touching the path before the floor — for clause 1's "no earlier
   version section mentions" test: ~44 KB at `v0.3.10`, against 58 KB at
   HEAD. It need not enter context: `curl` it to the scratchpad over
   anonymous HTTPS
   (`https://raw.githubusercontent.com/microsoft/skills-for-fabric/<sha>/CHANGELOG.md`)
   and run `grep -c` per name against the local copy, as the 2026-09-12
   run did — 44,935 bytes on disk, none of it in the conversation, where
   `get_file_contents` would have put all of it. Same exemption the
   `changelog` shape contract already states for a two-ref diff, applied
   to the base read.
4. Net a pair of whole-file rewrites (+N/−N on every line) by comparing
   the file's blob SHA at the two refs from a root listing —
   `get_file_contents`, `path: "/"`, `fields: ["name","sha"]` — instead
   of reading either patch. That is how the `d231b957` / `e4dfaebd`
   line-ending flip and its revert were cleared: blob `3fd6c501` at both
   `2b3530e8` and `e4dfaebd`.

Price, from the 2026-09-12 run: 31 github-mcp calls — 7 `list_commits`,
8 directory and file listings, 5 `stats`, 11 isolated patches — plus 1
raw HTTPS base fetch, 4 Learn searches and 1 WebFetch. (The 2026-09-10
run, for comparison: ~10 stats calls, 7 isolated patches, 1 base fetch
and 4 directory listings, plus 1 call per upstream `SKILL.md` read.)

## Counterparts here — matched by name only

| Upstream | Here |
| --- | --- |
| `eventhouse-cli` | `fabric-eventhouse` |
| `eventstream-cli` | `fabric-eventstream` |
| `spark-cli` | `fabric-spark` |
| `sqldw-cli` | `fabric-warehouse`, `fabric-warehouse-monitoring` |
| `sqldb-cli` | `fabric-database` |
| `variable-library-cli` | `fabric-variable-library` |
| `fabriciq`, `fabriciq-ontology-cli` | `fabric-ontology` |
| `semantic-model-authoring` | `fabric-tmdl`, `fabric-tmdl-api`; `fabric-semantic-model-ai-instructions` for Prep data for AI |
| `mlv-operations-cli` (retired upstream) | `fabric-mlv` |
| `deployment-pipelines-authoring-cli` | `fabric-deployment-pipelines`; `fabric-cicd` (partial) |
| `git-integration-operations-cli` | `fabric-cicd` (partial), `fabric-git-serialization` rule |
| `onelake-catalog-govern-cli` | `fabric-catalog-governance` |
| `activator-cli` | `fabric-activator` |
| `dataflows-cli` | `fabric-dataflow` |

Matched by name on 2026-09-10, from the `skills/` listing and the
changelog, **without reading either side's content**. The listing cannot
see a retired name, so the first run found two gaps and they were added
2026-09-11: `mlv-operations-cli` (added `0.3.5`) is gone from HEAD's
`skills/`, its MLV work routed to `spark-cli` by `0.3.14`, yet its
`0.3.11` bullet still mapped to `fabric-mlv`; and
`semantic-model-authoring`'s Prep data for AI work maps to
`fabric-semantic-model-ai-instructions`. **A retired upstream name can
still have a live local counterpart** — check a bullet naming a skill
absent from HEAD against this table before dropping it. Upstream's `-cli`
suffix suggests CLI procedures where ours are mostly reference and gotcha
content, so a counterpart is a place to look rather than a duplicate. An
upstream skill with no counterpart is reported under clause 1 of the
filter once, in the window that introduces it, and not again on every
run. `onelake-catalog-govern-cli` is the worked case: surfaced from
`0.3.15`, accepted, and authored here as `fabric-catalog-governance` on
2026-09-12 — so it now has a counterpart and clause 1 will not surface
it again.

`activator-cli` is the **second** worked case and a different one, which
is why both rows are worth keeping in view. It was not a new topic: the
`0.3.11` bullet consolidated `activator-authoring-cli` and
`activator-consumption-cli`, both named since `0.3.1`, so it passed
clause 1 on the **new name alone** — exactly the behaviour brief 06's
D-5 deliberately kept. Accepted 2026-09-11 with the other three
candidates and authored here as `fabric-activator` on 2026-09-12. So a
consolidation rename has now produced a real skill once, which is the
evidence D-5 was waiting on: the lexical test earns its false positives.
Every candidate accepted on 2026-09-11 was authored here on 2026-09-12
and now holds a counterpart row above, so clause 1 will not surface any
of them again.

The repo also ships `.claude-plugin/` and `plugins/`, and `0.3.14` names
two bundles, `fabric-skills` and `powerbi-authoring`. Installing a bundle
is a third option beside vendoring and authoring; it was not evaluated
here. `0.3.16` adds a fourth: a root `apm.yml` plus a generated
`skills/<name>/apm.yml` per skill, so `apm install
microsoft/skills-for-fabric --skill <name>` installs one skill rather
than a whole bundle. Also unevaluated — no claim that `apm` is installed
here, or that a single-skill install beats vendoring.

**Read bucket (c) even when nothing maps.** `0.3.14` fixed three
failures this repo also guards against: skills pointing at skills that had
been merged away, descriptions that lost the literal tokens a request
matches on, and a catalog close enough to the listing budget that later
skills risked being known by name alone. Upstream hits these problems at
a larger catalog size first, which makes its changelog an early warning
for this payload's own mechanics.

**Step 5 of *Adding a source* passed on a superset window, 2026-09-10.**
The first run, floor 2026-08-06, met all three known-answer assertions
on the `0.3.13`–`0.3.15` sections: both vendored path checks empty and
tree-SHA proven, clause 1 surfacing `onelake-catalog-govern-cli`, and
clause 1 **not** surfacing `databricks-migration` (mentioned in `0.3.0`
and `0.3.9`).

**The exact known-answer floor, 2026-08-20, was run on 2026-09-12 and
passed in the stable form below.** All three assertions held. The
vendored pair came back empty and tree-SHA proven when bounded at
`65902bae` — `[]` on both paths since `2026-08-20T13:22:57Z`, and the
four `powerbi-report-*` tree SHAs (`d160d140`, `b9fe475b`, `9b609076`,
`4f847fca`) identical at `b8d541c` and `65902bae`. The clause-1
subtraction passed: the sole in-window lexical hit,
`onelake-catalog-govern-cli`, was subtracted by the counterpart table
and reported under No-op, for zero new-skill candidates — which is what
proves the table was consulted. And no retired name produced a false
positive: `databricks-migration` (4 base mentions) stayed in bucket (d),
as did the six retired names `0.3.14` cites, each with 2–5.

Judge it on commits up to `65902bae` (`v0.3.15`) only: `v0.3.16`
(`f1802196`, 2026-09-10T14:27Z) touched both vendored skills after that
run, so a run today also returns that commit per vendored path —
correctly, as a re-sync candidate, but outside the known answer. That
run measured the unbounded case too: all four `powerbi-report-*` tree
SHAs moved at `v0.3.16`, yet blob SHAs show `SKILL.md`, `references/`
and `assets/` byte-identical to `b8d541c` — the entire delta is one
generated `apm.yml` per directory. A moved tree SHA is a **trigger, not
a verdict**; narrow by blob SHA before reading any patch.

**One of those three assertions expired on 2026-09-12**, when
`onelake-catalog-govern-cli` gained a counterpart above — and any
name-based positive control expires the same way, because clause 1
fires on *absence from the counterpart table*, and authoring the
counterpart is what this pipeline exists to do. Naming one of the
remaining brief 07 candidates would only reset the same fuse.

Assert the stable half instead. `00-audit-report.md` in the 2026-09-10
run directory records that window's full clause-1 outcome: the hits
that already had counterparts, under No-op, and those that did not, as
new-skill candidates. Upstream history at those SHAs cannot rot, so the
expected output is that recorded set minus whatever the counterpart
table holds at run time. Checking the subtraction is the assertion —
and unlike naming one skill, it proves the table was consulted.
