# Handoff: a pairwise skill-overlap script

- **Written**: 2026-09-10, out of a session that scoped a skill for
  finding similar, consolidatable and deprecatable skills. The skill was
  deferred — see [skill-portfolio-audit.md](skill-portfolio-audit.md) —
  and this script is the part that survived.
- **Kind**: one script; a one-function fix to
  [skill-telemetry.py](../../../scripts/skill-telemetry.py) that lands
  first; and two small edits to project-scope skills that consume the
  script.
- **Status**: **open, written 2026-09-10.** Nothing is drafted.
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

| Noise class | Names |
| --- | --- |
| MCP servers | `fabric-rti-mcp`, `powerbi-modeling-mcp`, `fabric-data-factory-mcp` |
| CLIs | `powerbi-desktop`, `powerbi-report-author` |
| rules | `fabric-git-serialization` |
| drift-audit source ids, repo names | `fabric-iq-ontology`, `powerbi-docs`, `powerbi-docs-powershell`, `fabric-toolbox` |
| a naming rationale | `fabric-pipeline`, in `skills/README.md` |

The 2 real ones are `powerbi-report-planning` and
`powerbi-report-management`, both in the vendored `powerbi-report-*`
pair — and `powerbi-report-planning` is in **both descriptions**, the
surface triggers are matched against. The skill's own *Local vendoring
note* says it is not installed.

The noise classes grow: the `skills-for-fabric` registry entry written
the same day added `fabric-skills`, an upstream bundle name, so a re-run
now finds 14. **Derive the allowlist rather than hand-keeping it** where
a machine source exists — rule names from `claude/rules/*.md`, MCP
server names from `claude/mcp/` and `.mcp.json`, source ids from the
`` ### `<id>` `` headings in `drift-audit/references/sources.md`. CLIs and
external repo names have no such source and need a short hand list.

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

`skills_on_disk()` walks `skills/<group>/<name>/` only. Since the
2026-09-09 scope split moved seven skills to `.claude/skills/`, its
`coverage` table has listed **44** skills while **51** exist across both
trees (measured 2026-09-10). `learn`, `author-skill` and the rest can
therefore never be flagged. `triggers` still shows them, because it
reads transcripts rather than disk — which is why the gap is easy to
miss.

Fix it to walk both roots before building on it. The new script needs
the same both-trees inventory.

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

## Consumers — the edits that make it pay

Neither of these adds a trigger, so the payload does not gain a third
coverage checker.

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
  reports **none** of the eleven noise names above, nor
  `fabric-skills`. A fixture naming a genuinely missing skill fails it.
- **Trigger overlap** ranks `powerbi-report-authoring` against the five
  `pbir-*` skills near the top of its list.
- **Inventory**: `skill-telemetry.py coverage` lists every skill in both
  trees. Re-derive the count; don't copy it from this brief.
- **No output line recommends deletion.** Same contract as `verdict()`.

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
