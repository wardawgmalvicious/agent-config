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
