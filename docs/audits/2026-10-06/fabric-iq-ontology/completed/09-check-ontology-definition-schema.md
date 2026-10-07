# Handoff: check the ontology definition schema

- **Audit run**: 2026-10-06
- **Source**: `fabric-iq-ontology`
- **Window**: floor `2026-09-02` (diff base `f78e4a0e`, 2026-08-31) →
  head `135b0dc1` (2026-10-05)
- **Covers recommended actions**: 9
- **Kind**: doc lookup on the REST item-definition pages, which lie
  outside this source, then an edit to the reference's schema section
  only where the pages establish one.
- **Target**: `skills/fabric/fabric-ontology/references/REFERENCE.md`
  (§1, lines 7–106)

## The problem

The new ontology docs describe modelling concepts that REFERENCE §1's
definition schemas have no place for: namespaces beyond the one
allowed value, inheritance and shared properties, metrics, and rules.
§1 is written from the REST item-definition page, which the registry
entry excludes from this source on purpose, so the audit could flag
the gap but not measure it.

## Evidence

`overview.md` at head `135b0dc1`, added by `80a24c9` (2026-09-29):

> **Manage the model as it evolves.** Organize definitions with
> namespaces, reuse common concepts through inheritance, create named
> versions, and use Fabric permissions and lifecycle tooling.

> **Inheritance** lets authors define a common entity type and extend
> it for more specialized concepts. **Shared properties** let authors
> define a property once and reference it across multiple entity types.

> A **metric** represents a governed calculation associated with
> ontology concepts. In the preview experience, metrics originate from
> DAX measures in a source semantic model and retain their connection
> to that source.

> A **rule** is a natural-language statement of business logic linked
> to ontology concepts.

Also new in the window, none of it fetched: version history, RDF,
Turtle and OWL import with RDF and Turtle export, and item sharing
(`how-to-use-version-history`, `how-to-import-export`,
`how-to-share-permissions`).

What §1 says now:

- `REFERENCE.md:33` — `namespace`: "Allowed value: `usertypes`."
- `REFERENCE.md:34` — `baseEntityTypeId`: "Inheritance."
- `REFERENCE.md:44–46` — `EntityTypeProperty`, with `redefines` and
  `baseTypeNamespaceType`.
- No part for metrics or rules.

**Recorded by `fabric/04`**, from the `fabric` audit the same day and
not re-checked here: the REST page is now titled "Ontology definition
(TMDL/new experience)". It defines the new experience as TMSL/TMDL,
"flat, item-folder-relative `.tmdl` text files plus the platform-owned
`.platform` metadata file", with a `tables/{name}.tmdl` part whose
measures carry DAX expressions. The JSON layout §1 describes now lives
at `.../definitions/ontology-old-definition`.

## What to change

1. Fetch both REST pages with `microsoft_docs_fetch`:
   https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-definition
   and
   https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/ontology-old-definition.
2. Against the TMDL page: how namespaces, inheritance, shared
   properties, metrics and rules serialize, where it says. Add to the
   TMDL section `fabric/04` writes only what the page shows.
3. Against the old-definition page: whether §1's JSON tables still
   hold, among them the `namespace` allowed values,
   `baseEntityTypeId` and `redefines`. Correct the legacy section where
   they differ.

## Constraint on the fix

- Do not compose TMDL the page does not show; `fabric/04` sets the same
  bound. A local export would be ground truth, and none exists on this
  machine (registry note, re-measured 2026-09-09).
- Where the pages do not settle a concept, record it in §1 as
  unverified, with the date, rather than infer a schema from the portal
  docs.

## Sequencing note

Run after `fabric/04` in `docs/audits/2026-10-06/fabric/`: its items 1
and 2 rebuild §1 around the TMDL definition and move the JSON tables
to a legacy section, and this brief then checks the result for the
concepts above. Run before brief 11, whose D-3 re-points the registry
entry's note on the REST page.

## Verification

1. The execution log names both REST pages as fetched in the executing
   session.
2. `grep -n -i "namespace\|inherit\|metric\|rule\|old-definition" skills/fabric/fabric-ontology/references/REFERENCE.md`
   — each concept is documented from a page, or marked unverified with
   a date.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-ontology/SKILL.md`
4. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against
`fabric-iq-ontology`, floor 2026-09-02. The overview quotes come from
the on-disk diff at pinned SHAs. The REST pages sit outside this
source's registry entry by design, so the audit did not fetch them;
the facts about them here are `fabric/04`'s.

## Execution log

- **Executed**: 2026-10-07 — applied
- **Session**: fresh
- **Files changed**: `skills/fabric/fabric-ontology/references/REFERENCE.md`
- **Verification**: step 1 — both REST pages were fetched in this
  session (2026-10-07): `ontology-definition`, whose 122k-character
  result was read by section from the saved output, and
  `ontology-old-definition`. Step 2: each of the five concepts is
  documented from the TMDL page, and the legacy tables from the
  old-definition page; none needed an "unverified" mark. Step 3: the
  frontmatter lints. Step 4, `pre-commit run --all-files`, runs once at
  the end of the pass.
- **Deferred**: none
- **Deviations**: item 2 went in as a `####` subsection under §1's TMDL
  heading, keywords only: the fetch collapsed the page's TMDL examples,
  and the constraint bars composing any. It carries one trap verbatim:
  `projected` and `enrichment` metrics, the kinds that surface a DAX
  measure, lose their `backingMeasure` "on the TMDL round trip". Item 3
  found §1's JSON tables still hold (`namespace` still only `usertypes`,
  `baseEntityTypeId` and `redefines` unchanged) but missing the
  `semanticEnrichment` object the page now gives entity types,
  properties and relationship types, so it was added, and the
  "not re-checked" sentence now dates the re-check. §8, rewritten by
  brief 08 earlier this run, said nothing here explains rules and
  metrics and named no date for the REST pages; item 2 made the first
  false and this lookup supplied the second, so both were corrected.
