# `fabric-iq-ontology` — Fabric IQ ontology doc set

- `repo`: `MicrosoftDocs/fabric-docs`
- `branch`: `main`
- `path`: `docs/iq/ontology/`
- `files`: `overview.md`, `concepts-generate.md`, `how-to-bind-data.md`,
  `concepts-agent-integration.md`, `resources-troubleshooting.md`,
  `overview-tenant-settings.md` — the six pages `fabric-ontology` is
  built on. The `how-to-create-*`, `how-to-use-rules` and tutorial pages
  are deliberately out of the fetch set; §8 of that skill's
  `references/REFERENCE.md` lists them as undrilled.
- `shape`: `prose`
- `sections`: none — these pages are individually small, so the fetch
  unit is the whole file, as with `vscode-agent`.
- `drill.host`: `learn.microsoft.com`
- `drill.via`: `microsoft-learn-mcp`
- `artifacts`: `skills/fabric/fabric-ontology/`,
  `skills/fabric/fabric-data-agent/`,
  `skills/fabric/fabric-operations-agent/`,
  `claude/rules/fabric-git-serialization.md`

**A doc-set source, not a change feed — and the first one aimed at a
single skill.** The `fabric` What's New source will announce that
ontology reaches GA; it will not announce that the property-type table
gained a row, that the one-static-binding-per-entity-type limit moved, or
that the MCP endpoint path changed. Those are exactly the claims
`fabric-ontology` encodes, and they live only in the spec pages.

Registered 2026-09-02, when that skill was authored. Two properties make
it worth the slot and neither generalizes: the workload is **preview**, so
the pages move under their own steam rather than on the What's New
cadence; and the skill was written **entirely from docs with no local
sample**, because no ontology item exists in any repo on this machine.
Every other Fabric skill here was checkable against a real export. That
is the condition this source substitutes for — so do **not** read it as a
precedent for one source per skill.

**Confirmed keep, 2026-09-09.** Both halves of the premise were
re-measured rather than read off the line above: `find` over the repo
roots still returns zero `*.Ontology` items, and the `fabric` skill group
**is** deployed into a client repo, so `fabric-ontology` and the two agent
skills in `artifacts` are live for someone. The question that prompted the
re-check — whether a source aimed at an unused workload earns its slot —
resolves the other way round from how it reads: *not* having a sample is
precisely why the docs are this skill's only ground truth.

**Retirement is narrower than it looks, and the trap is that it fires on
the good news.** As originally written the condition read as
automatic — *retire it if an ontology item ever lands in a Git-synced
workspace here* — and a local ontology item is expected here soon. A sample is ground truth for the
**definition layout** only — the `{}` envelope, the `EntityTypes/{id}/`
and `DataBindings/{guid}.json` shapes, what `.platform` carries. It says
nothing about the claims most likely to move and most expensive to get
wrong: the one-static-binding-per-entity-type limit, static-before-
time-series ordering, string/integer-only entity keys, managed-tables-only
and the OneLake-security and delta-column-mapping exclusions, the
`Decimal`-returns-null trap, and Direct Lake bindings failing silently
when the backing lakehouse workspace has inbound public access disabled.
Those are behavioural and support-matrix facts that no single export
exhibits. So: **a first local sample retires the layout half of this
source, not the source.** Narrow the `files` list to the pages carrying
limits and the support matrix at that point, and retire the entry outright
only when the item goes GA and settles.

The REST **item-definition** spec is a separate page in a separate repo
(`rest/api/fabric/articles/item-management/definitions/ontology-definition`)
and is *not* covered here. It is the source for the definition-part
schemas in that skill's reference, and it drifts on its own schedule;
check it by hand when the definition layout is in question.
