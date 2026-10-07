# Handoff: rewrite the ontology binding rules

- **Audit run**: 2026-10-06
- **Source**: `fabric-iq-ontology`
- **Window**: floor `2026-09-02` (diff base `f78e4a0e`, 2026-08-31) →
  head `135b0dc1` (2026-10-05)
- **Covers recommended actions**: 4
- **Kind**: partial rewrite of one skill section whose source page was
  rewritten for the new experience. Content, with a likely knock-on in
  the `description`.
- **Target**: `skills/fabric/fabric-ontology/SKILL.md` (lines 148–161;
  possibly line 3), `skills/fabric/fabric-ontology/references/REFERENCE.md`
  (lines 108–111, 127–128)

## The problem

`SKILL.md` § "Binding data: the ordering and cardinality rules" was
written from the old binding page: static sources only from OneLake, a
static binding before any time-series one, and a key defined while
binding. The page now documents the new experience. It lists seven
source types, replaces the static-then-time-series flow with primary
and secondary sources, and drops the key-definition step. Its own
Limitations section still asserts one claim that its source list
undercuts.

## Evidence

All from `docs/iq/ontology/how-to-bind-data.md`, base `f78e4a0e` →
head `135b0dc1`, rewritten mostly by `80a24c9` (2026-09-29, +47/−59).

**Sources.** The base prerequisite:

> The data is in Microsoft Fabric—static data in OneLake, time series
> data in OneLake or an eventhouse.

The head prerequisite, its sub-bullet, and a new section:

> The data is in Microsoft Fabric. Supported sources include
> eventhouse, KQL database, lakehouse, mirrored database, semantic
> model, SQL database, or warehouse.

> For semantic models, you need both Read and Build permissions to
> bind the data to an ontology.

> The following data source types support data binding in ontology
> (preview): Eventhouse, KQL database, Lakehouse, Mirrored database,
> Semantic model, SQL database, Warehouse

The new overview widens it again: "source options include semantic
models, lakehouses, eventhouses, warehouses, SQL databases, mirrored
databases, and supported OneLake constructs such as shortcuts, views,
and materialized views."

**The page contradicts itself.** Its Limitations section, unchanged
but for wording, still reads:

```text
* Each entity type supports one **static** data binding. You can't combine static data from multiple sources for a single entity type.
    * You must use OneLake-backed sources for static data.
    * Entity types **do** support bindings from multiple **time series** sources. You can bind time series data from both eventhouse and lakehouse sources.
```

**Flow.** Removed: § "Add static data" and § "Add time series data
(after binding static data)", with the note the skill's "Static first"
rule rests on:

> Before you bind time series data to an entity type, make sure your
> static data binding is complete. The entity type must have at least
> one property with static data bound to it that you can use as the key
> to contextualize your time series data. This static data must exactly
> match a column in your time series data.

Added: § "Add data binding" and § "Add more data bindings":

> On the **Entity type properties** page, select **Add** and select
> your data table from the OneLake catalog. The system adds the new
> data source as a secondary data source.

> The data source loads and asks you to define the relationship between
> the primary and secondary data source. Select the common column from
> each table that allows them to relate to each other.

> If any columns exist in both source tables with the same name, the
> system adds a *_2* suffix to the default property names of the
> columns from the new data source.

**Keys.** Removed: the "Entity type key mapping" description ("You can
select string and integer columns from your source data as the entity
type key") and the step "Select **Define entity type key** at the top
of the configuration". The overview at head: "The updated ontology
model supports more flexible representations, including keyless entity
types, relationships without dedicated join tables". The property-types
include, `includes/supported-property-types.md`, is unchanged but for
case and still reads:

```text
| Entity type key | string, integer |
```

`a97a864` ("Remove key prereq", 2026-10-05) removed one line from
`how-to-create-relationship-types.md`, a page outside the registry
that the audit did not fetch.

**Unchanged at head:** managed lakehouse tables only, the
column-mapping exclusion, a renamed source table breaking the binding,
and custom property names of 1–26 characters, unique across entity
types.

## What to change

1. **`SKILL.md:150–152`**:

   > - **One static binding per entity type.** You cannot union static data
   >   from two sources into one entity type. Static sources must be
   >   OneLake-backed.

   The one-static-binding limit survives. Add the seven source types
   and the Read and Build requirement on semantic models. Keep
   "OneLake-backed" only as the page's own Limitations bullet, and
   record that it sits beside a source list that includes semantic
   models.
2. **`SKILL.md:153–154`** — many time-series bindings "from lakehouse
   *and* eventhouse sources together". Still the Limitations text;
   keep it.
3. **`SKILL.md:155–157`**:

   > - **Static first.** A time-series binding needs an existing statically
   >   bound property to contextualize against, and the static value must
   >   **exactly match** a column in the time-series data.

   Its source text is gone. Describe the documented flow instead: a
   primary source, secondary sources related to it on a common column,
   and the `_2` suffix on clashing column names.
4. **`SKILL.md:158–159`**:

   > - **Entity type keys are `string` or `integer` only.** One or more
   >   columns, together unique.

   The type restriction stands in the include. The key is no longer a
   binding step, and the overview announces keyless entity types: say
   a key is optional, and string or integer when defined.
5. **`REFERENCE.md:108–111`**, §2's preamble. The type table below it
   is still the include's, which lists lakehouse and eventhouse types
   only. Say so, now that five other source types bind.
6. **`REFERENCE.md:127–128`** — "Entity type keys must be `string` or
   `integer`." Align it with item 4.
7. **Knock-on, not named in the audit's action: `SKILL.md:3`.** The
   `description` lists "one static binding per entity type but many
   time-series ones, static before time-series, entity keys
   string/integer only". If items 3 or 4 change those claims, the
   `description` follows, or the trigger promises rules the body no
   longer states.

## Constraint on the fix

- **Removed text is not a reversed rule.** The evidence shows the
  static-first note and the key-definition step were removed. It does
  not show that a time-series source can now bind without a static
  one, or that a key is never needed: the new primary and secondary
  join on a common column may be the old contextualization under new
  names. Write what the page documents, and do not assert the opposite
  of the old rule.
- Record the Limitations contradiction; do not resolve it.
- Old-experience behaviour goes where brief 01's answer puts it.
- The `description` has little room; brief 03's constraint has the
  measured budget.

## Sequencing note

Run after brief 01, and after `fabric/04` in
`docs/audits/2026-10-06/fabric/` if it is still pending: that brief
restructures the skill around the TMDL layout, and the line numbers
here will move. Keep this apart from brief 03, which removes one
withdrawn claim from the same page's material and is verified by a
grep. The `description` retest is shared; see brief 03's sequencing
note.

## Verification

1. Re-open https://learn.microsoft.com/fabric/iq/ontology/how-to-bind-data
   with `microsoft_docs_fetch`, and check each claim in the rewritten
   section against it, the Limitations bullets included.
2. `grep -n -i "static first\|onelake-backed\|string. or .integer\|keyless\|secondary" skills/fabric/fabric-ontology/SKILL.md skills/fabric/fabric-ontology/references/REFERENCE.md`
   — every hit matches the page, or sits where brief 01's answer puts
   old-experience facts.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-ontology/SKILL.md`
4. If the `description` changed: `uv run --with pyyaml scripts/skill-status.py --stale`,
   then retest per `/test-skill` or record it as owed.
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against
`fabric-iq-ontology`, floor 2026-09-02, from both refs of the page
downloaded at pinned SHAs and diffed on disk in the audit session. The
overview and include quotes come from the same diff.

## Execution log

- **Executed**: 2026-10-07 — applied with deferrals
- **Session**: fresh
- **Files changed**: `skills/fabric/fabric-ontology/SKILL.md`,
  `skills/fabric/fabric-ontology/references/REFERENCE.md`
- **Verification**: step 1 — `how-to-bind-data` and
  `old-experience/how-to-bind-data` were fetched live this session
  (2026-10-07), with the overview for "keyless entity types"; each
  rewritten claim traces to one of them, the Limitations quote
  verbatim. Step 2: every hit matches the page or sits under the
  legacy marker. Step 3: the frontmatter lints. Step 4: the
  `description` changed, and `--stale` lists `fabric-ontology`
  (`untested-behaviour`); the retest is owed, per brief 03's
  sequencing note. Step 5, `pre-commit run --all-files`, runs once at
  the end of the pass.
- **Deferred**: the `description` retest, owed once with briefs 03, 05
  and 07.
- **Deviations**: the section now opens "From the binding page,
  checked 2026-10-07", the skill's own convention for a section newer
  than its 2026-09-02 header. Per brief 01's option 4, item 3's
  static-first rule and the key-while-binding step moved to an **Old
  experience (legacy, retires 2027-01-31):** paragraph sourced to the
  old-experience page, and the primary-and-secondary bullet says the
  new page neither states that rule nor lets a time-series source
  bind without a static one, per the constraint. Item 7 replaced
  "static before time-series, entity keys string/integer only" in the
  `description` with "secondary sources joined on a common column,
  optional string/integer keys": 974 of 1,024 characters after.
- **Needs**: a fresh session — after this pass lands and `fabric/04`'s
  last Needs line folds the TMDL layout into the `description`, the one
  `/test-skill fabric-ontology` retest every `description` edit here
  shares.
