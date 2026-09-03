# Expected findings — `fabric-semantic-model-audit` on a planning model

The fixture is a **planning** semantic model (Microsoft's Fabric IQ Plan
sample — see [README.md](README.md) for provenance). It exists to test one
thing the reporting-model fixtures cannot: the **planning-model carve-out**
in `SKILL.md` §3, added 2026-09-03.

The carve-out is a *false-positive guard*, so this table has two halves and
**both must hold**. A run that stays silent about everything passes half of
it and fails the other half — going quiet is the regression this fixture is
here to catch.

Everything below is mechanically derivable from `definition/` with no
capacity and no credential — tier D (TMDL on disk), checks 1–14.

## A. Must NOT be reported as defects — the carve-out

| # | Structure | Why it is correct here |
| --- | --- | --- |
| A1 | `dim_subcategory` on both sides — owns `CategoryKey` as a from-column, `SubcategoryKey` as a to-column | The doc's own example. Subcategory carries its parent key so valid hierarchy combinations derive from the dimension model. **Check 1's "collapse the snowflake" is destructive here** — it removes what generates the planning grid's rows. |
| A2 | `dim_product` on both sides — owns `SubcategoryKey` as a from-column, `ProductKey` as a to-column | Same pattern one level down; the Region > Category > Subcategory > Product chain is the mechanism, not a modelling accident. |
| A3 | `bridge__region_category`, `bridge__region_segment_product`, `bridge__product__year` in **no relationship at all** | Validity tables. Each carries an `IsValid` boolean against dimension keys, maintained through PowerTable. Check 9 fires on all three and must stand down — they are deliberately unrelated. |
| A4 | `dim_scenario` modelled as a dimension (`ScenarioKey`, `IsForecast`, `OpenFrom`, `OpenUntil`) | Scenario-as-data replaces per-scenario measure sets. Ten measures here rather than ten per scenario. Not a finding in either direction. |

**A1 and A2 are the sharp ones.** Check 1 fires on both by construction,
so a run that reports "snowflake — collapse into one dimension table" for
either has failed, no matter how well it does elsewhere.

## B. Must STILL be reported — the guard must not go soft

The carve-out exempts a *shape*, not the model. These are genuine and a run
that suppresses them has over-applied it:

| # | Finding | Evidence |
| --- | --- | --- |
| B1 | **Auto date/time is on** — four `LocalDateTable_*` tables plus `DateTableTemplate_*` | Power BI generates one hidden date table per date column; pure model bloat with an explicit `dim_date` already present. Nothing to do with planning. |
| B2 | Relationships on `dateTime` columns — `dim_scenario.OpenFrom`, `dim_scenario.OpenUntil`, `dim_date.Date`, `dim_date.'Year Month'` | Check 8. All four join to auto-generated `LocalDateTable_*`. |
| B3 | If `dim_date` or `dim_scenario` is reported as both-sides, it must be **attributed to B1** | Both are on both sides *only* because auto date/time added the relationships. Calling either a planning snowflake, or exempting them via the carve-out, are both wrong — the carve-out covers A1/A2, not these. |
| B4 | **`IsValid` compared to a string literal** — `Modelling Measures Table.tmdl:38, 121, 128` | `IsValid` is `dataType: boolean` in all three bridge tables, but the DAX tests it against `"true"` / `"TRUE"` / `"TRUE"`. DAX does no implicit boolean↔text conversion, so Cases 4 and 9 return nothing. **Two of the ten measures are dead.** This is a real defect in Microsoft's published sample, found on 2026-09-03 and confirmed against the TMDL. |

B4 does not discriminate — all three runs below found it, payload and baseline
alike — so it proves nothing about the carve-out. It is here as a **severity
anchor**: a run that produces style notes while missing two dead measures has
regressed, whatever it does with A1/A2.

## C. Must not be claimed at all

| # | Claim | Why it would be wrong |
| --- | --- | --- |
| C1 | Any inactive relationship | `relationships.tmdl` contains **no** `isActive: false`. Checks 2 has nothing to report. |
| C2 | Any role-playing dimension | Counting is per (fact, dimension) pair; `fact_pl` reaches each dimension exactly once. Check 3 does not fire. |
| C3 | Direct Lake framing | Every partition is `mode: import`. §1 says establish storage mode first, and the import/Direct Lake split changes the relationship guidance — getting this backwards invalidates §5 and §6. |

## Pass criteria

1. Storage mode established as **import** before any relationship advice (§1).
2. **A1 and A2 not reported as snowflakes to collapse.** The single most important line.
3. A3's three bridge tables not reported as disconnected-table defects.
4. B1 and B4 reported.
5. No C-column claim made.

Criterion 2 is the carve-out — and, per the control section below, it is the
*only* criterion here that the carve-out changes. Criteria 4 and 5 are the
regression guard: they are why a silent run is a failure rather than a pass.
Criterion 3 is kept for completeness but **discriminates nothing** — it passes
with the carve-out stripped out, so do not read it as evidence either way.

**Result, 2026-09-03: all five pass.** The shipped skill stood down on A1/A2
with the planning reasoning stated explicitly, stood down on A3, established
import mode first, and still returned eight findings including B1 and B4. It
did not go quiet.

## The control — and why it is not `--safe-mode`

**Measured 2026-09-03, three cold sessions, same neutral prompt** ("Audit the
semantic model at fixtures/… and report what you find" — it must not mention
planning, snowflakes or the carve-out, or it tells the model the answer).

| Run | Check 1 — snowflake | Check 9 — bridges |
| --- | --- | --- |
| `--safe-mode`, payload off | not raised | not raised |
| Skill with the **carve-out stripped** | **raised** — *"collapsing the three into one `dim_product` … is the standard fix"*, ranked #4 in its own fix list | not raised |
| Skill as shipped | stood down, correctly | stood down, correctly |

Two things follow, and the first one overturns what this section used to say.

**`--safe-mode` is the wrong control.** It was predicted to fail criterion 2
and it passes — but not because the carve-out is worthless. The base model
runs no checklist, so it never applies the both-sides test and never reaches
check 1 at all; it read the model holistically, called it a star schema, and
spent its attention on the DAX. A control that cannot fire the check cannot
falsify the guard on it. **The discriminating control is the skill with the
carve-out removed** — same checks, same prompt, one paragraph different — and
that run flags A1/A2 and prescribes collapsing. That is the measurement that
earns the carve-out its place, and it is the one to re-run when either the
carve-out or check 1 changes.

Keep the `--safe-mode` run anyway, for the criterion 4/5 half: it is still the
control for whether the *skill* adds anything over the base model.

**The carve-out's check-9 clause is redundant.** §3 claims "check 1 fires on
the first of those and check 9 on the last, and both are wrong here." Check 9
stood down in *both* stripped runs without any help — §9's existing
disconnected-table/virtual-relationship guidance already covers it, and both
runs said so unprompted. So criterion 3 passes either way and tests nothing.
Only the check-1 half of the carve-out is load-bearing.

One methodology note for whoever re-runs the stripped control: strip **both**
references. Deleting §3's bullet while leaving §9's "the planning-model
carve-out in §3 is documentation-derived" makes the build self-contradictory —
the first attempt did exactly that, and the run noticed the dangling promise
and hedged its check-1 finding on those grounds. It still flagged, so the
result held *a fortiori*, but the confound pushed toward standing down and a
clean strip is what the table above reports.
