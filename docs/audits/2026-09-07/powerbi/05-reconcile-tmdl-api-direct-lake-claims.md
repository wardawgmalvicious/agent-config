# Handoff: reconcile `fabric-tmdl-api`'s Direct Lake calculated-column claims

- **Audit run**: 2026-09-07
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 6
- **Kind**: factual correction to committed prose, resolving a
  self-contradiction inside one skill. No behavior changes.
- **Target**: `skills/fabric/fabric-tmdl-api/references/REFERENCE.md`
  (line 43), and `skills/fabric/fabric-tmdl-api/SKILL.md` (line 68) for
  one small addition.

## The problem

`fabric-tmdl-api` contradicts itself about whether Direct Lake supports
calculated columns.

`references/REFERENCE.md:43` says they are unsupported. `SKILL.md:68`
says Direct Lake on OneLake has supported them since an April 2026
preview. The second is correct; the first is a stale parenthetical that
survived the April update.

An agent that loads the reference file and not the skill body — or that
greps for "Direct Lake" and hits line 43 first — will state the opposite
of what the same skill says two files over.

## Evidence

The contradiction, both quoted verbatim from the repo at audit time.

`references/REFERENCE.md:43`:

> - [Direct Lake overview](https://learn.microsoft.com/fabric/fundamentals/direct-lake-overview) — concept: framing, Direct Lake on SQL vs OneLake, comparison vs Import/DirectQuery (calculated columns/hybrid tables/partitions all unsupported in DL).

`SKILL.md:68`:

> - **Calculated columns / tables (April 2026 preview)**: Direct Lake on **OneLake** now supports unmaterialized calculated columns (and calculated tables that reference them). Direct Lake on **SQL** still does not. User-context-aware DAX (`USERCULTURE`, `USERPRINCIPALNAME`, `CUSTOMDATA`, etc.) requires `expressionContext: userContext` on the column.

Upstream adjudicates in favour of `SKILL.md`. From
<https://learn.microsoft.com/power-bi/transform-model/desktop-calculated-columns>,
fetched 2026-09-07 via `microsoft-learn-mcp` — the storage-mode ×
expression-context matrix, verbatim rows:

```
| Direct Lake on OneLake | N/A | Unmaterialized (preview) |
| Direct Lake on SQL     | N/A | N/A                      |
```

(columns are `Standard (default)` and `User Context`.)

And the note beneath it, verbatim:

> Support for calculated columns in Direct Lake on OneLake semantic
> models is in preview. Only the **User Context** expression context is
> supported. Columns are evaluated at query time and don't materialize.
> Because they don't materialize, these calculated columns can't be used
> in relationships. Expressions that don't reference user-aware functions
> or secured columns behave like any other DAX calculated column.

### What triggered this, and what is genuinely new

The August 2026 What's New carried a *Direct Lake calculated columns
(Preview)* row (added at `a154ef24`, 2026-08-23). Comparing it against
the support matrix shows it is a **re-announcement** of the April
preview, not a status change — the matrix still says preview, still says
User Context only, still says unusable in relationships.

The one new fact in the August row is the **authoring surface**:

> Calculated columns can be defined using DAX in web modeling and Power
> BI Desktop on Direct Lake on OneLake semantic models without changing
> storage mode.

`SKILL.md:68` does not say where these can be authored, so "and Power BI
Desktop" is a real, small addition.

## What to change

1. **`references/REFERENCE.md:43`** — the parenthetical
   `(calculated columns/hybrid tables/partitions all unsupported in DL)`
   is wrong for Direct Lake on OneLake. Correct it to distinguish DL on
   OneLake from DL on SQL, matching `SKILL.md:68`.

   Scope note: the audit verified the **calculated columns** half only.
   It did **not** verify the claims about hybrid tables or partitions in
   the same parenthetical. Do not silently correct those too — either
   check them against the Direct Lake overview page or leave them
   untouched and narrow the correction to calculated columns.

2. **`SKILL.md:68`** — add that calculated columns can be authored in
   Power BI Desktop as well as web modeling.

## Constraint on the fix

**Two other files make the same claims correctly. Do not touch them.**
The audit drilled the calculated-columns page expecting drift across the
board and found these already accurate:

- `skills/fabric/fabric-semantic-model-audit/references/REFERENCE.md:155`
  — "Calculated columns | Preview, **User Context only**, unmaterialized
  — **cannot be used in relationships** | Not supported". Matches the
  matrix and the note exactly.
- `skills/fabric/fabric-tmdl/references/REFERENCE.md:108` — "Direct Lake
  on OneLake gained calculated-column support in April 2026 (preview).
  Direct Lake on SQL still does not allow calculated columns or
  calculated tables." Matches.

The temptation when fixing a contradiction is to harmonise every nearby
file. Here that would introduce errors into two correct ones.

Also: this staleness **predates the audit window**. The April 2026
preview is what made line 43 wrong; the August re-announcement only
surfaced it. Do not date the correction to August as though the
capability changed then.

## Verification

1. `grep -rniE "unsupported in DL|all unsupported" skills/fabric --include=*.md`
   — should return nothing, or only claims that survive scrutiny.
2. `grep -rniE "calculated column" skills/fabric/fabric-tmdl-api --include=*.md`
   — read every hit and confirm `SKILL.md` and `references/REFERENCE.md`
   now agree with each other.
3. Re-read the two files named under Constraint and confirm they are
   **unchanged** — `git diff --stat` should not list them.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-tmdl-api/SKILL.md`.
5. `pre-commit run --all-files`.

## Provenance

Found by the 2026-09-07 `powerbi` drift audit against a 2026-08-01 floor.
Notable that a *Power BI* source surfaced a defect in a *Fabric* skill —
the What's New row prompted a drill of the calculated-columns page, and
checking the local artifacts against that page is what exposed the
internal contradiction.

The drill result is the strongest part of this brief: the support matrix
was read directly from the live page rather than inferred from a release
note, which is also what allowed the audit to certify the two files under
Constraint as correct instead of assuming they had drifted alongside.
