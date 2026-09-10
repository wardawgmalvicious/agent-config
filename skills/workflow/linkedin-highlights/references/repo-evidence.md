# Extracting career evidence from a git repo

The procedure behind steps 1–5 of `linkedin-highlights`. It is written
to be reused: a later resume or CV skill should point here rather than
re-deriving the counting rule, and nothing below is specific to the
LinkedIn field.

Everything here was measured against one real repo on 2026-09-10 — sole
authored, 363 commits, June–September 2026 — read for structure and
history only. That repo is referred to descriptively throughout and
never by name; see the skill's step 7 for why.

## A. Establish authorship and the date boundary

Do this first. Every count downstream is filtered by its answers.

```bash
git shortlog -sne --all                      # who committed, how much
git log --author="<user>" --since=<start> --until=<end> --oneline
git log --reverse --format='%ad %s' --date=short | head -1   # repo start
git log -1 --format='%ad' --date=short                       # last commit
```

Three things come out of this:

- **Whether the user is the author.** Sole authorship is a claim worth
  making and it is checkable. Shared authorship means every count from
  section C is `--author`-filtered, and the prose says "contributed to"
  rather than "built".
- **Whether the repo's activity matches the stated role dates.** If the
  user's commits sit outside the role window, ask. Do not widen the
  window silently.
- **Tenure, which bounds claim size.** A three-month engagement cannot
  support a multi-year narrative.

An author filter is only as good as the identity behind it. `shortlog
-sne` shows every name/email pair, so a user who committed under two
addresses shows up as two rows — check before filtering on one.

## B. Read the docs before the history

Order: `README` → `ARCHITECTURE` → `CONTRIBUTING` → any `docs/` tree →
history.

**The reason is measured, not stylistic.** In the reference repo:

| Source | Size |
| --- | --- |
| Architecture document | 5,533 words, 31 headings |
| README | 2,208 words |
| Contributing guide | 1,607 words |
| Commits carrying a conventional-commit prefix | ~14 of 363 (~4%) |

Commit-subject mining is therefore unreliable in the general case — 96%
of that history carries no structured subject at all. The documentation
states purpose and design intent in the author's own words; git history
cannot, and a history without prefixes cannot even be grouped by type.

Use history for the three things docs cannot give: **when** work
happened, **how much of it was the user's**, and whether a documented
intent actually shipped.

## C. Build the inventory — count items, not files

### The trap

A naive count over paths is wrong by one to two orders of magnitude.
Measured in the reference repo:

| Naive count | True count |
| --- | --- |
| 91 Reports | **1** |
| 48 Warehouses | **1** |
| 23 Semantic Models | **1** |

Fabric and PBIR serialization explode a single item into a directory
tree of per-object files — a PBIR report is one JSON per visual, a
warehouse one definition per object. Counting matching *paths* counts
the serialization, not the work.

The same trap exists outside Fabric wherever a tool serializes one
logical artifact across many files: `.pbip` projects, Terraform module
trees, dbt model directories, generated API clients.

### The rule

**Count the distinct item *directories*, not the files beneath them.**

Fabric Git-synced repos make this mechanical, because an item folder is
named `<name>.<ItemType>`. The suffix set is documented in
`claude/rules/fabric-git-serialization.md` and across the `fabric-*`
skills: `.Report`, `.SemanticModel`, `.Warehouse`, `.Lakehouse`,
`.Notebook`, `.Eventstream`, `.Eventhouse`, `.KQLDatabase`,
`.KQLQueryset`, `.KQLDashboard`, `.DataPipeline`, `.Dataflow`,
`.Environment`, `.SQLDatabase`, `.MirroredDatabase`,
`.SparkJobDefinition`, `.Activator`, `.Reflex`, `.VariableLibrary`,
`.GraphModel`, `.GraphQLApi`, `.UserDataFunction`, `.CopyJob`,
`.DataAgent`, `.Ontology`, `.OperationsAgent`, `.ApacheAirflowJob`,
`.MountedDataFactory`.

```bash
# distinct item directories by type
git ls-files | grep -oE '[^/]+\.(Report|SemanticModel|Warehouse|Lakehouse|Notebook)/' \
  | sort -u | sed 's|.*\.||; s|/||' | sort | uniq -c
```

### Verify every count a second way

**A count that reaches prose has been produced by two different
commands.** This is the discipline that caught the 91-vs-1 gap in the
first place, and it is cheap. A second check can be:

- `git ls-files | grep -c '\.Report/'` — file count, expected to be
  *much larger*; a file count equal to the item count means the pattern
  matched the directory marker only.
- Listing the item directories by name and reading them: `git ls-files
  | grep -oE '[^/]+\.Report/' | sort -u`. Names are the check — three
  items with the same name is a bug in the pattern, not three items.
- The workspace or deployment manifest, if the repo has one.

If the two disagree, neither number goes in the prose until the
disagreement is explained.

The honest inventory for the reference repo, after this treatment: 4
workspaces, 14 notebooks, 8 eventstreams, 2 KQL databases, 2 data
pipelines, and one each of report, warehouse, semantic model, eventhouse
and lakehouse.

### Numbers that are never claims

**Line totals.** Whole-history insertions in the reference repo run
~684k against ~219k deletions. That is generated item serialization, and
it measures the tooling rather than the work. Insertion counts, deletion
counts and net-lines figures never appear in career prose.

**Raw commit counts**, unqualified. 363 commits says nothing without
knowing what a commit means in that repo. It is usable as a date-range
and consistency signal, not as a volume claim.

**File counts**, for the reason the whole section exists.

## D. Sort claims by evidence strength

Every candidate claim lands in exactly one tier.

**Tier 1 — countable from the repo now.** Item counts, date ranges,
languages and platforms in use, sole vs. shared authorship, integrations
that exist as code. These go in as stated fact.

**Tier 2 — documented as design intent in the repo's own docs.** An
architecture document's stated goal, a README's stated purpose, a
documented SLA target. These go in phrased as what the work was *built
to do* — never as what it *achieved*, which is a tier-3 claim wearing a
tier-2 source.

**Tier 3 — knowable only to the user.** Users served, uptime, cost,
hours saved, revenue, business outcome, team size, stakeholders,
adoption, before/after comparisons.

**Tier 3 never becomes prose from inference.** A repo cannot know any of
it. Every one of these is checkably false to a peer in the field if
guessed wrong, and a career document is the worst place to be caught
inflating. Tier 3 is asked, answered, or written qualitatively — those
are the only three outcomes.

The tiering is also the drafting order. A Highlights entry that opens
with a tier-3 outcome and supports it with tier-1 counts reads as
evidence; one that opens with tier-2 intent reads as a job posting.
