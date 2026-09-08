# Handoff: fold granular semantic model refresh controls into an existing skill

- **Audit run**: 2026-09-07
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 8
- **Kind**: small content addition **gated on an open placement
  decision**. The decision is the user's — put it to them before
  executing rather than picking a file.
- **Target**: one of `skills/fabric/fabric-semantic-model-audit/` or
  `skills/fabric/fabric-gotchas/SKILL.md`. Not both.

## The problem

The August 2026 release added granular refresh controls to semantic
models in the Power BI service. No artifact in this repo covers them —
confirmed by grep across `skills/powerbi`, `skills/fabric`, and
`claude/rules` at audit time, which returned nothing for "sync schema",
"refresh data only", or table-level refresh.

The audit classified this bucket (b) — genuinely uncovered — but
explicitly **not** a new-skill candidate. It is one paragraph of Service
UI behaviour, and this repo's skills are organised around file formats,
TMDL, and REST rather than portal walkthroughs.

## Evidence

The `whats-new.md` row added at `369371ac` (2026-08-20), verbatim:

> More control over semantic model refresh in Power BI Service | The
> **Refresh** button now offers three options: **Refresh schema and
> data**, **Sync schema only**, and **Refresh data only**. Refresh
> operations can also be performed at the table level.

Upstream reference given in the row:
<https://learn.microsoft.com/power-bi/connect-data/refresh-data>

### Existing coverage, for placement context

Neither candidate currently discusses these options, but both touch
refresh nearby:

- `fabric-semantic-model-audit` — `SKILL.md:49` reads the model's live
  state via `INFO.VIEW.*`; `references/REFERENCE.md:32` flags calculated
  columns that "recompute at refresh and bloat the model".
- `fabric-gotchas` — the repo's home for short, cross-cutting operational
  traps, one row each.

## Open question — where this lands

**Do not choose this unilaterally.** The audit named two candidates and
deliberately did not pick between them; `/drift-update` should surface
this to the user rather than execute it.

**Option A — `fabric-gotchas`.** One row. Fits if the value is "the
Refresh button is no longer a single action, and picking the wrong option
either skips your schema change or needlessly reloads data." That is a
trap-shaped fact, which is what the file collects.

**Option B — `fabric-semantic-model-audit`.** Fits if the value is
diagnostic — a schema/data split is directly relevant to a skill that
inspects live model state, and table-level refresh changes what "the
model was refreshed" means when auditing.

The distinction worth putting to the user: is this **a trap to avoid**
(A) or **context for interpreting model state** (B)?

## Constraint on the fix

The upstream page was **not drilled** this run. Everything above comes
from the What's New row. Before writing, fetch
<https://learn.microsoft.com/power-bi/connect-data/refresh-data> via
`microsoft-learn-mcp` and confirm the three option names and the
table-level behaviour, because option labels in release notes routinely
differ from the shipped UI.

Keep it short whichever file wins. This is a Service portal behaviour in
a repo whose skills are about definitions and APIs; a paragraph is
proportionate, a walkthrough is not.

Do not extend this into REST refresh semantics. Whether these options map
onto the enhanced refresh API is a separate question the audit did not
examine, and `fabric-tmdl-api` is a third file that is deliberately not
in scope here.

## Verification

1. Confirm the three option names and table-level refresh against the
   upstream page before writing.
2. `grep -rniE "sync schema|refresh data only|refresh schema and data" skills/ --include=*.md`
   — one file should match, not two. Matching both means the placement
   decision was not actually made.
3. `uv run --with pyyaml scripts/lint-frontmatter.py <the chosen SKILL.md>`
   — if the addition is summarised into `description`, that field is
   capped at 1024 chars.
4. `pre-commit run --all-files`.

## Provenance

Found by the 2026-09-07 `powerbi` drift audit against a 2026-08-01 floor.
It is the run's only bucket (b) finding, and the audit's judgment that it
is a fold-in rather than a new skill is recorded in `00-audit-report.md`
under New-skill candidates — that judgment is settled and is not
re-opened by this brief. Only the placement between the two named
candidates is open.

## Execution log

- **Executed**: 2026-09-08 — escalated (placement decision put to the user)
- **Session**: fresh
- **Files changed**: none
- **Verification**: step 1 ran and **passes with one correction to the brief's
  own Evidence**; step 2 ran as a baseline; steps 3–4 are not reachable until a
  file is chosen.
  1. Upstream page fetched via `microsoft-learn-mcp`. The three options are
     confirmed, but the shipped label for the first is **"Refresh Schema and
     data"** — capital *S* — where the What's New row this brief quotes writes
     "Refresh schema and data". This is exactly the release-note-vs-UI drift the
     Constraint warned about, so use the page's casing when writing. Verbatim:

     > - **Refresh Schema and data** - performs a schema sync first, followed by a data refresh.
     > - **Sync schema only** – Updates the semantic model to reflect the data source structure (for example, column type changes or new columns).
     > - **Refresh data only** – Loads fresh data while preserving the current schema in your semantic model.

     Two further facts the What's New row does not carry, both worth having
     before the placement call is made:
     - The expandable **Refresh** button appears in **both the Home ribbon and
       the Data pane** — not one location.
     - Table-level refresh is per-table *and* per-kind: *"By selecting an
       individual table, you can also choose whether to refresh its schema,
       data, or both."*
     - The page motivates the split with a **Direct Lake** scenario: the
       underlying Lakehouse table gains a column, and you may want the latest
       data without pulling the new column into the model.
  2. `grep -rniE "sync schema|refresh data only|refresh schema and data" skills/`
     returns nothing, so the coverage gap the brief describes still holds and
     no file matches yet. Re-run after the addition lands; exactly one file
     should match.
- **The open question, and why it was not answered here**: the Kind gates this
  brief on a placement decision and says the decision is the user's. Per
  `/drift-update` § 3, a decision brief is escalated and never executed, so no
  file was chosen and nothing was written. The question put to the user is the
  one the brief frames: is this **a trap to avoid** (Option A, one row in
  `fabric-gotchas`) or **context for interpreting model state** (Option B, a
  short addition to `fabric-semantic-model-audit`)?

  The drill surfaced one input the audit did not have: the upstream page frames
  the whole feature around a **Direct Lake** schema-drift scenario. That is
  state-interpretation shaped rather than trap shaped, so it is evidence for
  Option B — but it is offered as evidence, not as the decision.
- **Deferred**: the addition itself. Whichever option the user picks, the work
  is a separate, deliberately started task and is not folded into this run.
- **Deviations**: none. The Constraint was observed — the page was drilled
  before anything was written, `fabric-tmdl-api` was left out of scope, and
  REST refresh semantics were not examined.

### Decision — 2026-09-08

**Declined. Neither candidate; the fold-in is dropped.**

Asked at the `/drift-update` checkpoint as the Kind requires, and answered by
the user: neither Option A (`fabric-gotchas`) nor Option B
(`fabric-semantic-model-audit`). No file is changed and none will be.

The reasoning behind the option, recorded so it does not have to be
reconstructed: this is Power BI **Service portal UI** behaviour, and this
repo's skills are organised around file formats, TMDL and REST. The audit had
already ruled it out as a new-skill candidate on exactly that ground
(`00-audit-report.md`, New-skill candidates); declining the fold-in extends the
same judgement to the two existing-file options.

**This brief is spent — it should not be re-raised.** A later `powerbi` drift
audit that re-encounters the granular refresh rows should treat them as a
recorded no-op rather than an uncovered gap, and cite this decision. The
drilled evidence above stays on disk in case that judgement is ever revisited:
the three shipped option labels (note the capital *S* in **Refresh Schema and
data**), the Home-ribbon-and-Data-pane locations, per-table schema/data/both
granularity, and the Direct Lake motivation.

Verification step 2 now has a fixed expected result: `grep -rniE "sync
schema|refresh data only|refresh schema and data" skills/` should return
**nothing**, permanently, rather than matching exactly one file.
