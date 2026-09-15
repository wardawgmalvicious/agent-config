# Handoff: a pairwise skill-overlap script

- **Written**: 2026-09-10, out of a session that scoped a skill for
  finding similar, consolidatable and deprecatable skills. The skill was
  deferred — see [skill-portfolio-audit.md](skill-portfolio-audit.md) —
  and this script is the part that survived.
- **Kind**: one script; a scope-aware inventory fix to
  [skill-telemetry.py](../../../scripts/skill-telemetry.py) that lands
  first; and two small edits to project-scope skills that consume the
  script.
- **Status**: **spent 2026-09-15 — every part of the Kind above has
  landed**, script and both consumers. `scripts/skill-overlap.py` implements all four signals,
  `routing` gates commits as `lint-skill-routing`, and its negative case
  is proved by `tests/scripts/skill-overlap/test-routing.sh` — the live
  tree passing says nothing, since a gate firing on nothing looks
  identical. The design fork is settled below. The prerequisite — the
  `skill-telemetry.py` inventory — landed the same day; see that section
  for what it cost beyond the estimate and the counting rule it leaves
  behind. The consumer edits are in `author-skill` §2 and `learn` Step 4,
  and neither skill gains retest debt: both were already `untested` per
  `skill-status.py`. **This brief is kept only until the v1 output format
  has been used in anger** — signal 5, body duplication, was deferred
  until signals 1-4 proved that format, and nothing has yet exercised it
  outside its own acceptance run. Delete it, and its queue row, once
  something has.
- **Run in**: this repo, in a fresh session.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## Why: every existing tool looks at one skill at a time

| Tool | Unit | Answers |
| --- | --- | --- |
| `lint-skill-scopes.py` | pair, by name | do two skills share a name |
| `skill-telemetry.py` | one skill | was it listed, chosen, activated |
| `payload-coverage.py` | one file | does anything in the payload match it |
| `author-skill` §2 | one topic | does a grep find it |

Consolidation is a property of a **pair** — the argument
`lint-skill-scopes.py` already makes about name collisions, where neither
file is wrong on its own. Nothing measures pairs on *content*: two
descriptions that both half-match one request, two globs that always
fire together, a description routing to a skill that is not there.

## The signals, and what each measured on 2026-09-10

### 1. Routing integrity — a skill names a skill that does not exist

**The cheapest signal and the only one that is a bug by default.** Measured
by collecting every backticked name with a platform prefix (`fabric-`,
`pbir-`, `pbid-`, `pbip-`, `powerbi-`) across `skills/`,
`.claude/skills/` and `claude/rules/`, and subtracting the skills on
disk in both trees: **13 unknown names, 11 of them noise.**

The table is grouped by **where the allowlist entry comes from**, because
that is what the script has to implement — not by what kind of thing the
name is.

| Noise class | Allowlist source | Names |
| --- | --- | --- |
| MCP servers | derived — `claude/mcp/`, `.mcp.json` | `fabric-rti-mcp`, `powerbi-modeling-mcp`, `fabric-data-factory-mcp`, `fabric-kqlendpoint` |
| rules | derived — `claude/rules/*.md` | `fabric-git-serialization` |
| drift-audit source ids | derived — the `` ### `<id>` `` headings in `sources.md` | `fabric-iq-ontology` |
| GitHub repo names | hand list | `powerbi-docs`, `powerbi-docs-powershell`, `fabric-toolbox` |
| CLIs | hand list | `powerbi-desktop`, `powerbi-report-author` |
| upstream bundle names | hand list | `fabric-skills`, `powerbi-authoring` |
| counterfactual names in `skills/README.md`'s naming rationale | excluded by path | `fabric-pipeline`, `fabric-reflex`, `fabric-governance`, `fabric-deployment-pipeline` — one per authoring run that explains a name *not* chosen |

The 2 real ones are `powerbi-report-planning` and
`powerbi-report-management`, both in the vendored `powerbi-report-*`
pair — and `powerbi-report-planning` is in **both descriptions**, the
surface triggers are matched against. The skill's own *Local vendoring
note* says it is not installed.

The noise classes grow, and the table above is the **2026-09-15 re-run
classified in full**: 19 raw hits, 17 noise, the 2 real ones unchanged.
An earlier pass recorded 19 but accounted for only 17 of them and put
four of the five new names in the counterfactual class. Only three are.
The other two land in classes that change the work:

- `fabric-kqlendpoint` is an **MCP server**, not a skill — it is in
  `claude/mcp/.mcp.project.template.json`, so the derived allowlist
  catches it with no hand-keeping at all.
- `powerbi-authoring` is a second **upstream bundle name** beside
  `fabric-skills`, both in `drift-audit/references/sources.md`. So that
  class is two rather than a one-off, and needs a hand list entry rather
  than being waved through.

**Derive the allowlist rather than hand-keeping it** where a machine
source exists, per the Allowlist source column. That leaves a hand list
of **seven** — two CLIs, two bundle names and three GitHub repo names —
which is the whole maintenance burden, and every other class is derived
or excluded by path. Only `fabric-iq-ontology` is an actual source id:
the three repo names were grouped with it while this table was being
regrouped by source, and they have no heading to derive from. Checked
against `sources.md` on 2026-09-15, the six `` ### `` headings are
`fabric`, `powerbi`, `vscode-agent`, `claude-code`, `fabric-iq-ontology`
and `skills-for-fabric`, and only the fifth carries a platform prefix —
so that arm earns its place by being future-proof for the next source
registered, not by what it catches today. The naming-rationale class has no source either and, unlike the
CLIs, grows with every authoring run, so the lean is to exclude that
file's naming section by path rather than keep listing the names it
invents. `fabric-deployment-pipeline` is the sharpest case for that:
it is the **singular** at `skills/README.md:103` — "Plural, and not
`fabric-deployment-pipeline`" — against the `fabric-deployment-pipelines`
skill that does exist. A singular/plural near-miss is both the most
convincing false positive and, anywhere but that file, exactly the real
bug this signal is for.

Upstream shipped the same fix. `microsoft/skills-for-fabric` `0.3.14`,
under Fixed: three skills "pointed you at skills that no longer exist"
after earlier merges. That is evidence the check is worth running, not
just possible.

**Candidate pre-commit hook.** A description naming a missing skill is
a bug unless it is a recorded override — the two vendored descriptions
are, per the settled decision below — so this half can gate commits the
way `lint-skill-scopes.py` does. A body mention is weaker — prose may
discuss a skill that was deliberately not installed — so report those
without failing.

### 2. Trigger overlap — two descriptions half-match one request

`powerbi-report-authoring`'s description claims "pages, visuals,
filters, slicers, bookmarks, themes, or formatting". `pbir-pages`,
`pbir-filters`, `pbir-bookmarks`, `pbir-themes` and
`pbir-conditional-formatting` each own one of those. `skill-telemetry.py
coverage` the same day flagged it `LISTED-NEVER-CHOSEN` across 105
listings.

**Overlap between a conditional and an unconditional skill is
asymmetric**, and the report has to say which. The five `pbir-*` skills
carry `paths:` globs and compete only after a matching `Read`, while
the unconditional one is in every listing. `author-skill` §2 already
names the failure — "the model is choosing between two descriptions
that both half-match" — but only checks for it when a skill is created.

Keep the metric cheap, deterministic and dependency-free: shared
distinctive tokens across `description` + `when_to_use` — backticked
terms, quoted trigger phrases, product nouns — ranked per pair. **No
embeddings.** A deterministic score can be re-run and reviewed; a model
score can be neither. The output is a ranked list for a person, not a
verdict.

### 3. Glob co-activation — two conditional skills that fire together

`payload-coverage.py --by-file` already matches globs to real files; on
a client repo that day it reported up to six payload items on a single
notebook file. The pairwise question it does not ask: over a sweep of
real repos, how often does a file matching skill A also match skill B?
If A's matches are a subset of B's everywhere, the harness never sees
them apart.

Report **skill–skill** pairs only. A rule and a skill co-activating is
the design — rules carry conventions, skills carry procedures — and
listing those would bury the signal.

### 4. Usage — joined from `skill-telemetry.py`, not recomputed

Take `skill-telemetry.py coverage --json` and join by name. Carry its
caveats into the output verbatim, because they decide whether a zero
means anything:

- Telemetry is **this machine only**. Platform skills have been pruned
  from user scope here since 2026-08-31, and they ship to teammates
  through `copy-copilot.ps1`, where no transcript exists.
- Most `LISTED-NEVER-CHOSEN` listings **predate that prune**.
- `verdict()` never says delete, and neither does this script. Rarely
  used is not unused.

### Out of scope for v1: body duplication

The same guidance in two skills is real — it is exactly what the
one-fact-one-home rule in `coding-markdown.md` exists to stop — but the
signal is fuzzy and noisy. Leave it until signals 1–4 have proven the
output format.

## Prerequisite: `skill-telemetry.py` cannot see project-scope skills

**Done 2026-09-15.** `skills_on_disk()` walks both roots and carries a
`scope` field; `coverage` now lists every skill in both trees and shows
`user` or `proj` per row. The new script takes its both-trees inventory
from the same function.

Two corrections to what this section claimed, both found by re-running
its evidence rather than reading it. It is **six** project-scope skills,
not seven — `land` moved back to `skills/workflow/` on 2026-09-13, after
this brief was written — and the counts were **50 listed against 56 on
disk** at the time of the fix, not 44 against 51. Derive them; don't
copy these either.

The fix was not the one-function change this section budgeted for, and
the reason is worth carrying into the new script. **Scope changes what a
listing count means**, so widening the inventory alone would have
produced wrong flags rather than missing ones — the first run printed
`author-skill … listed 229` against a denominator of 131 sessions,
because the numerator spanned the period before the 2026-09-09 split
when those six were deployed machine-wide. A count is only meaningful
against the set of sessions that could have produced it, so a `proj`
row's `listed` is this repo's sessions alone and the pre-split
remainder is reported beside it as `[+N pre-split listings
machine-wide]`. Anything joining on this data inherits that rule:
**never compare a `listed` count across scopes.**

Widening it immediately paid the dividend this section predicted.
`drift-audit` and `drift-update` both flag `SLASH-ONLY` — reached by
name, description never matched — which no run before this one could
have surfaced, since neither skill was in the table at all.

## The design fork: new script, or a subcommand

This is a real choice, so make it at execution rather than here:

- **A new `scripts/skill-overlap.py`.** Cleanest to read, but it would
  hold the *third* copy of `GLOB_FLAGS` — `payload-coverage.py`'s
  docstring records the second as deliberate, because
  `activation-expect.py`'s hyphen makes it un-importable — and a second
  skill-inventory walker.
- **A subcommand on `payload-coverage.py`.** It already owns the glob
  matcher and loads the frontmatter of every path-scoped rule and skill.
  Signals 1 and 2 need *every* skill, not just path-scoped ones, so its
  loader widens; signal 4 shells out to `skill-telemetry.py --json`.
- **An importable shared module** (underscore-named) holding
  `GLOB_FLAGS` and the inventory, imported by all three scripts.
  Removes the duplication rather than adding to it, but touches three
  working scripts to add one.

Lean: the subcommand, because it avoids the third copy without touching
the scripts that already work. Revisit if the subcommand's arguments
stop reading like the same tool.

**Settled 2026-09-15 on the third option, by the lean's own test.** The
subcommand's arguments do not read like the same tool.
`payload-coverage.py` is a flat parser whose first positional is `repos`
with `nargs="+"`, so a subcommand name and a repo path are ambiguous
without restructuring a working CLI — and the existing
`payload-coverage.py <repo>` form would break. The deeper objection is
the one the lean asked to be tested: `payload-coverage.py <repo>` answers
a question *about a repo*, and signals 1, 2 and 4 take no repo argument
at all. Only signal 3 sweeps repos. Three of four signals would sit under
a parser demanding an argument they never use.

Scoped tighter than this option was written, though — it touches **one**
working script, not three. `scripts/_skill_inventory.py` holds the walk
and the flags; `scripts/skill-overlap.py` imports it; and of the existing
walkers only `skill-telemetry.py` was migrated, because its `_skill_meta`
had to widen to carry description *text* regardless, and migrating a
second consumer is what proves the module is not shaped only for its
first. `payload-coverage.py` and `activation-expect.py` were left alone:
neither needs anything else the module offers, and a refactor with no
caller is risk without payoff.

Two constraints found while building it, both worth keeping:

- **The module returns a list, not a dict keyed by name.**
  `lint-skill-scopes.py` exists to find two skills sharing one name, so a
  name-keyed inventory silently drops one of every pair it looks for.
  `by_name()` is there for callers that know uniqueness is gated.
- **`payload-coverage.py`'s recorded reason for duplicating `GLOB_FLAGS`
  was backwards.** Its docstring says the two scripts "cannot share the
  code" because a hyphen makes `activation-expect.py` un-importable. A
  hyphenated script cannot be imported *from*; it can import. The
  constraint never existed, and a shared module was always available.

## Consumers — the edits that make it pay

**Both landed 2026-09-15.** Neither adds a trigger, so the payload did
not gain a third coverage checker.

One thing was learned in the doing. The brief says to run the script
"against the candidate's draft description or topic", and there is no way
to do that: the script reads skills off disk, so a description that does
not exist yet cannot be scored. `author-skill` §2 therefore runs it
against the **nearest existing skill** the topic would sit beside, which
answers the same question — what already clusters here — from a starting
point that exists.

1. **`author-skill` §2.** Run the script against the candidate's draft
   description or topic alongside the existing grep, and act on its
   overlap list with the three outcomes §2 already defines. Add one
   independent line: **before authoring a platform skill, check
   `microsoft/skills-for-fabric`'s `skills/` listing** and decide
   vendor versus author. The counterpart table in `drift-audit`'s
   `skills-for-fabric` registry entry is the starting map. That line
   does not depend on the script and can land first.
2. **`learn` Step 4.** The same call, when the destination skill for a
   learning is unclear.

## Acceptance — known answers

- **Routing** finds `powerbi-report-planning`, in two descriptions,
  and `powerbi-report-management`, and reports both as accepted
  overrides rather than failures — see the settled decision below. It
  reports **none** of the 17 noise names in the table above. A fixture
  naming a genuinely missing skill fails it. Re-derive the raw count
  before trusting it; 19 was true on 2026-09-15 and the counterfactual
  class grows with every authoring run. **Met 2026-09-15** — 56 skills,
  45 allowlisted names, zero unknowns, exit 0. `powerbi-report-planning`
  is found in the descriptions of both `powerbi-report-authoring` and
  `powerbi-report-design`, `powerbi-report-management` in prose, and all
  are reported as accepted overrides citing `1fa3061`. The negative case
  is `tests/scripts/skill-overlap/test-routing.sh` case 2, which fails a
  fixture whose description names a skill that does not exist; all five
  cases pass.
- **Trigger overlap** ranks `powerbi-report-authoring` against the five
  `pbir-*` skills near the top of its list. **Met 2026-09-15**, at ranks
  3, 4, 5, 9 and 11 of its 40 scored pairs, above every cross-domain
  pair. It took one tuning pass to get there, and the reason is worth
  keeping: the first run ranked `drift-update` and `test-skill` above
  four of the five, scoring on `verify`, `edit`, `brief`, `first` and
  `user` alone. **Vocabulary about invoking a skill is in every
  description by construction**, so it distinguishes nothing and belongs
  in the stoplist — which is the same reasoning as inverse document
  frequency, applied to a class frequency alone does not separate. The
  global top 15 was captured before and after and is unchanged in
  composition, which is what says the metric was tuned rather than
  fitted to its own acceptance test.
- **Inventory**: `skill-telemetry.py coverage` lists every skill in both
  trees. Re-derive the count; don't copy it from this brief. **Met
  2026-09-15** — row count equals the two trees' `SKILL.md` count, and
  no row reports more listings than its scope had sessions.
- **No output line recommends deletion.** Same contract as `verdict()`.
  **Met** — each subcommand's legend says so explicitly, and the
  `--usage` join prints `skill-telemetry.py`'s caveats verbatim,
  including that rarely used is not unused. Conditional skills are
  annotated `conditional` on the usage line so a `listed 0` is not read
  as a finding.

## The decision this surfaced — settled 2026-09-11

`powerbi-report-planning` is routed to from both vendored descriptions
and is not installed. **The local override stays.** The skill was left
out on purpose when the pair was vendored — `1fa3061`, 2026-08-25: "The
largely-overlapping planning and management skills were not vendored" —
and each *Local vendoring note* routes to `pbir-report-workflow`
instead. Vendoring it now would put two descriptions on one request,
which is what signal 2 exists to flag.

So the routing check still **finds** both names — they are its known
answer — but reports them as accepted overrides citing `1fa3061`, and a
commit gate must not fail on them. Editing the vendored description
text was not an option either way: the note says to diff against
upstream on re-sync and re-apply that section only, so a description
edit is silently lost on the next re-sync.

## Post-draft checklist

- `ruff check` — pre-commit runs it since `ae472da`.
- An entry in [scripts/README.md](../../../scripts/README.md), and a
  line in root `CLAUDE.md`'s Commands block beside `payload-coverage.py`.
- If routing integrity becomes a hook: add it to
  `.pre-commit-config.yaml` and prove its `files:` pattern against a
  path that must match and one that must not. A pattern that misses
  prints `(no files to check) Skipped`, which scans as a pass.
- `uv run --with pyyaml scripts/lint-frontmatter.py` on both edited
  skills.
