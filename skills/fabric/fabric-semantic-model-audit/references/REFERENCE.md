# Reference — semantic model audit

Long detail for [`../SKILL.md`](../SKILL.md): the check catalogue, the
exact invocations for each evidence tier, the star-schema pattern
vocabulary, the Direct Lake constraint table, and the MS Learn link
bundle.

Verified 2026-09-02 against the pages in [§7](#7-ms-learn-link-bundle).

## 1. Check catalogue

Tier key: **D** = TMDL on disk (offline), **Q** = `INFO.VIEW.*` over
executeQueries, **N** = Fabric notebook (`sempy.fabric`).

| # | Check | Tier | Evidence | Remediation, and its cost |
| --- | --- | --- | --- | --- |
| 1 | Tables on both sides of a relationship | D | a table owning both a `fromColumn` and a `toColumn` | Collapse the snowflake into one dimension table; costs redundant denormalized storage |
| 2 | Inactive relationship with no `USERELATIONSHIP` | D | `isActive: false` count vs. `USERELATIONSHIP` occurrences in `tables/*.tmdl` | Delete it, or add the measure that uses it. Free, and usually a pure win |
| 3 | Role-playing dimension | D | **per (fact, dim) pair** — one table reaching one dimension more than once | Duplicate the dimension per role, one active relationship each; costs model size (usually negligible). **Check §5 first for Direct Lake** |
| 4 | Bidirectional cross-filter | D | `crossFilteringBehavior: bothDirections` | Single-direction plus a bridging table where genuinely many-to-many |
| 5 | Ambiguous filter paths | D | two or more paths between the same tables, at least one bidirectional | Remove a relationship, or weight with `USERELATIONSHIP` |
| 6 | Limited relationship | D | many-to-many cardinality, **or** cross source group in a composite model | Introduce a bridging dimension so a "one" side exists |
| 7 | One-to-one cardinality | D | `fromCardinality: one` + `toCardinality: one` | Merge the tables |
| 8 | `DateTime` key columns | D | relationship on a `dateTime` column | Strip the time part in Power Query — **not** the Modeling tab |
| 9 | Disconnected table | D | table in no relationship | **Verify before flagging** — legitimate for what-if parameters |
| 10 | Assume referential integrity | D | `referentialIntegrity` on a DirectQuery relationship | Only with genuine integrity; otherwise results silently understate |
| 11 | Missing `formatString` / `summarizeBy` | D | column and measure properties | Set explicitly (see `coding-tmdl.md`) |
| 12 | Implicit measures | D | numeric columns with `summarizeBy` other than `none` and no explicit measure | Create explicit measures; set `summarizeBy: none` |
| 13 | Non-descriptive names | D | `TR_AMT`, `F_SLS`, `DIM_GEO_01` | Rename, or supply `description` and synonyms |
| 14 | Missing descriptions | D/Q | tables, columns, measures | Add concise descriptions — required for AI consumers |
| 15 | Measure `[State]` not `Ready` | Q | `INFO.VIEW.MEASURES()` | Fix the broken DAX |
| 16 | Calculated columns doing Power Query work | Q | non-empty `[Expression]` on a column | Move upstream; calc columns recompute at refresh and bloat the model |
| 17 | High-cardinality columns | N | `model_memory_analyzer()` → `Columns` | Reduce cardinality, correct data types, drop unused columns |
| 18 | Column-level memory hot spots | N | `model_memory_analyzer()` → `Columns` / `Tables` | Drop or retype; the biggest single lever on import model size |
| 19 | 60+ BPA rules | N | `run_model_bpa()` | Per rule; five categories — Performance, DAX Expressions, Error Prevention, Maintenance, Formatting |
| 20 | Direct Lake Delta health | N | Delta Analyzer (`sempy_labs`) | V-Order, row group size, non-destructive update patterns — lakehouse work, not model work |

Checks 1–14 need no capacity, no credential and no network.

## 2. Offline (TMDL) invocations

Storage modes, relationship counts, and the two greps behind check 2:

```bash
grep -rh "mode:" definition/tables/*.tmdl | sort | uniq -c
grep -c "^relationship " definition/relationships.tmdl
grep -c "isActive: false"  definition/relationships.tmdl
grep -c "crossFilteringBehavior" definition/relationships.tmdl
grep -rn -i "USERELATIONSHIP" definition/tables/
```

Fact/dimension side split — the input to checks 1 and 3:

```bash
grep -oP "fromColumn:\s*\K[^.\[]+" definition/relationships.tmdl | sort | uniq -c
grep -oP "toColumn:\s*\K[^.\[]+"   definition/relationships.tmdl | sort | uniq -c
```

Tables appearing in **both** outputs are check 1. For check 3, resolve
each relationship to its `(fromTable, toTable)` pair and look for a pair
appearing more than once — **not** for a table appearing often on the
to-side.

## 3. Live metadata — `INFO.VIEW.*`

Four canned projections, as `scripts/data/dax.sh -s <name>` ships them.
Use them directly as DAX where no wrapper is deployed.

| `-s` value | Projection |
| --- | --- |
| `tables` | `[Name]`, `[StorageMode]`, `[IsHidden]`, `[DataCategory]`, `[Expression]` (calc-table DAX), `[Description]` |
| `columns` | `[Table]`, `[Name]`, `[DataType]`, `[SummarizeBy]`, `[IsHidden]`, `[FormatString]`, `[Expression]`, `[Description]`, filtered to `[DataCategory] <> "RowNumber"` |
| `measures` | `[Table]`, `[Name]`, `[DataType]`, `[FormatString]`, `[DisplayFolder]`, `[IsHidden]`, `[State]`, `[Expression]`, `[Description]` |
| `relationships` | `[Relationship]`, `[IsActive]`, `[CrossFilteringBehavior]`, `[SecurityFilteringBehavior]`, `[State]` |

```dax
EVALUATE
SELECTCOLUMNS (
    INFO.VIEW.RELATIONSHIPS (),
    "Relationship", [Relationship],
    "Active", [IsActive],
    "CrossFilter", [CrossFilteringBehavior],
    "State", [State]
)
ORDER BY [Relationship]
```

Note the `relationships` projection carries **no cardinality** — for
checks 6 and 7 either widen the projection or read TMDL.

Three caveats, all of which produce wrong answers rather than errors:

1. **`INFO.VIEW.*` blanks `[Expression]` for users without write
   permission on the model.** Empty formulas mean read-only access, not
   an empty model.
2. The executeQueries reference states INFO functions are unsupported
   through that endpoint. **That is stale** — verified working against a
   Direct Lake model on a Fabric capacity. Don't "fix" it back to a
   `getDefinition` round trip on the strength of that sentence.
3. One `EVALUATE` per call; 100,000 rows or 1,000,000 values, whichever
   comes first, and 15 MB; 120 requests per minute. Exceeding the row cap
   truncates and reports the error inside a **200** response. Requires
   the *Dataset Execute Queries REST API* tenant setting plus Build
   permission.

## 4. Fabric notebook tier — `sempy.fabric`

Fabric-only: *"Use of semantic link is supported only in Microsoft
Fabric."* Available in the default runtime from **Fabric Runtime 1.2
(Spark 3.4)** up — no `%pip install` needed. `%pip install -U
semantic-link` only to move ahead of the runtime version.

```python
run_model_bpa(dataset: str | UUID, workspace: str | UUID | None = None,
              export: Literal['html','table','zip','none'] = 'html',
              return_dataframe: bool = False, language: str | None = None,
              credential: TokenCredential | None = None) -> DataFrame | None

model_memory_analyzer(dataset: str | UUID, workspace: str | UUID | None = None,
                      export: Literal['html','table','zip'] | None = 'html',
                      return_dataframe: bool | None = False,
                      credential: TokenCredential | None = None) -> Dict[str, DataFrame] | None
```

`model_memory_analyzer(..., return_dataframe=True)` returns a dict keyed
`Model Summary`, `Tables`, `Partitions`, `Columns`, `Relationships`,
`Hierarchies`. `Columns` is the only first-party path to column-level
memory and cardinality for a Direct Lake model.

**Permission gates, three of them, each failing differently:**

| Call | Path | Needs |
| --- | --- | --- |
| `run_model_bpa`, `model_memory_analyzer`, `connect_semantic_model` | TOM | **ReadWrite** on the model |
| `list_tables`, `list_measures`, `read_table` | XMLA | XMLA read-only enabled |
| Creating the notebook from a model entry point | portal | **Build** on the model, Fabric capacity, workspace **contributor** |

Stock notebooks ship from three entry points — the **Home** ribbon when
editing the model in the service, the **Model health** dropdown on the
model details page, and **More options (…)** in the OneLake catalog.
Prefer them over writing one; this skill deliberately ships no notebook.

`semantic-link-labs` (`import sempy_labs as labs`) is the extension
library — `get_measure_dependencies`, `measure_dependency_tree`,
`delta_analyzer`, `get_delta_table_history`. Also Fabric-only.

**Known limitation:** notebooks fail to run if the semantic model name
ends with a whitespace.

## 5. Direct Lake constraints that bound remediation

| Constraint | Direct Lake on OneLake | Direct Lake on SQL |
| --- | --- | --- |
| Calculated tables | Yes (preview) | No — except calculation groups, what-if and field parameters |
| Calculated columns | Preview, **User Context only**, unmaterialized — **cannot be used in relationships** | Not supported |
| Multiple tables from the same source table | Not supported in Desktop or web modeling; XMLA tools can, but **Edit tables** and **refresh** then error | Same |
| Composite modelling with Import | Supported | Not supported |
| Relationship column data types | Must match | Must match |
| One-side uniqueness | Queries **fail** on duplicates | Same |
| Cardinality / cross-filter validation in web modeling | **None** — selections assumed correct | **None** |
| Auto date/time | Supported | Not supported |
| DirectQuery fallback | Not supported | Supported unless disabled |

The consequence for check 3: the documented import remediation
(duplicate the role-playing dimension) is largely unavailable in Direct
Lake. Add the role table upstream in the lakehouse and bind it instead.

## 6. Star-schema pattern vocabulary

Phrase findings in these terms — each has a defined remediation.

- **Surrogate key** — an added unique identifier, not in the source.
  Needed when a dimension has no single unique column; add a Power Query
  index column and merge it into the fact query.
- **Snowflake dimension** — normalized tables for one business entity.
  Generally collapse into one model table.
- **Role-playing dimension** — one dimension filtering facts differently
  (order / ship / delivery date). Duplicate per role.
- **SCD Type 1** — overwrite; a non-incremental refresh achieves it.
- **SCD Type 2** — versioned members with a surrogate key and
  `StartDate` / `EndDate`. Power Query **cannot** produce it; load from a
  pre-built SCD2 table. Give the version column a non-ambiguous label.
- **Junk dimension** — consolidate many tiny attribute dimensions into
  one, keyed by a surrogate.
- **Degenerate dimension** — a fact-table attribute used for filtering
  (order number). Sanctioned exception to the no-mixing rule.
- **Factless fact / bridging table** — dimension keys only; the
  recommended way to relate two dimensions many-to-many.

## 7. MS Learn link bundle

- [Understand star schema and the importance for Power BI](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema)
  — classification, snowflake trade-off, the whole pattern vocabulary in §6.
- [Model relationships in Power BI Desktop](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-relationships-understand)
  — cardinality, cross-filter, active/inactive, regular vs. limited,
  table expansion, ambiguity resolution, performance ordering.
- [Semantic model best practices for data agent](https://learn.microsoft.com/en-us/fabric/data-science/semantic-model-best-practices)
  — the "Common pitfalls to avoid" list and the Prep-for-AI precedence rule.
- [Use notebooks with a semantic model](https://learn.microsoft.com/en-us/power-bi/transform-model/service-notebooks)
  — BPA, Memory Analyzer, entry points, permissions.
- [What is semantic link?](https://learn.microsoft.com/fabric/data-science/semantic-link-overview)
  — the Fabric-only constraint and runtime availability.
- [`sempy.fabric` API reference](https://learn.microsoft.com/python/api/semantic-link-sempy/sempy.fabric)
  — signatures and the ReadWrite requirement.
- [Understand Direct Lake query performance](https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-understand-storage)
  — join indexes at query time, residency states, V-Order, row groups,
  update patterns.
- [Direct Lake overview](https://learn.microsoft.com/fabric/fundamentals/direct-lake-overview)
  — the considerations and limitations table reproduced in §5.
- [Create calculated columns in Power BI Desktop](https://learn.microsoft.com/power-bi/transform-model/desktop-calculated-columns)
  — the Direct Lake expression-context table and the no-relationships rule.
- [Semantic Model Data Agent Checklist](https://github.com/microsoft/fabric-toolbox/blob/main/samples/data_agent_checklist_notebooks/Semantic%20Model%20Data%20Agent%20Checklist.md)
  (`microsoft/fabric-toolbox`) — its *Semantic Model Optimization*
  section is folded into §1; the rest is data agent configuration and
  belongs to `fabric-data-agent`.

### Deliberately not drilled

The four relationship drill-throughs
(`relationships-active-inactive`, `relationships-bidirectional-filtering`,
`relationships-many-to-many`, `relationships-one-to-one`) — the parent
page's summary of each is what this skill encodes, and these are the next
pass if a dimension needs more depth. Also not drilled:
`import-modeling-data-reduction`, the published Tabular Editor BPA rule
set (so this skill names the five categories but enumerates no rules),
and `delta-optimization-and-v-order`.
