# `fabric-iq-ontology` — Fabric IQ ontology doc set

- `repo`: `MicrosoftDocs/fabric-docs`
- `branch`: `main`
- `path`: `docs/iq/ontology/`
- `files`: `overview.md`, `how-to-generate-from-semantic-models.md`,
  `how-to-bind-data.md`, `concepts-agent-integration.md`,
  `resources-troubleshooting.md`, `overview-tenant-settings.md`,
  `how-to-use-ontology-graph.md`, `resources-capacity-usage.md`,
  `how-to-add-metadata.md`, `how-to-use-ontology-mcp-server.md`,
  `includes/supported-property-types.md`,
  `includes/refresh-graph-model.md`, and, until the old experience
  retires on 2027-01-31, `old-experience/overview.md`,
  `old-experience/how-to-bind-data.md`,
  `old-experience/concepts-generate.md`,
  `old-experience/resources-capacity-usage.md` and
  `old-experience/how-to-add-semantic-enrichment.md` — the pages
  `fabric-ontology` cites, plus the two includes holding its type table
  and refresh wording (2026-10-07). The rest of the doc set is
  deliberately out of the fetch set; §8 of that skill's
  `references/REFERENCE.md` lists it as undrilled. Names under
  `includes/` and `old-experience/` are not in the listing of `path`
  that `SKILL.md` § 4a step 4 narrows by blob SHA, so list those two
  subdirectories too. On the raw path the 17 names cost `1 + 2 x 17` =
  35 calls, against the 13 that § 4b worked for six on 2026-09-08.
- `shape`: `prose`
- `sections`: none — these pages are individually small, so the fetch
  unit is the whole file, as with `vscode-agent`.
- `drill.host`: `learn.microsoft.com`
- `drill.via`: `microsoft-learn-mcp`
- `drill.strip`: every `#…` fragment. This doc set's heading anchors
  move: `c02fe35` (2026-10-01) renamed a tenant-settings heading, so
  `overview-tenant-settings.md#ontology-item-preview` lost its target,
  and the troubleshooting page still links `concepts-generate.md#…`
  anchors on a page that moved. A page link loses little, since each
  page is fetched whole. Chosen 2026-10-07.
- `artifacts`: `skills/fabric/fabric-ontology/`,
  `skills/fabric/fabric-data-agent/`,
  `skills/fabric/fabric-operations-agent/`,
  `claude/rules/fabric-git-serialization.md`, `claude/mcp/` — the
  project template's `ontology-remote-mcp` entry serves the endpoint
  this source watches (added 2026-10-07)

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

**The doc set split on 2026-09-29.** The FabCon EU release (`80a24c9`)
rebuilt it for a *new experience*, the default for new items, whose
definition is TMDL; the *old experience*, whose definition is JSON, kept
its pages under `old-experience/` and retires on **2027-01-31**.
`fabric-ontology` keeps both, marking old-experience facts in place
(brief 01 of the 2026-10-06 pass), so `files` tracks the old-experience
pages it cites until that date. Drop them then.

**Retirement is narrower than it looks, and the trap is that it fires on
the good news.** As originally written the condition read as
automatic — *retire it if an ontology item ever lands in a Git-synced
workspace here* — and a local ontology item is expected here soon. A sample is ground truth for the
**definition layout** only — what `.platform` carries, and the TMDL
parts of a new-experience item or the `{}` envelope, `EntityTypes/{id}/`
and `DataBindings/{guid}.json` shapes of an old one. It says
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
only when the item goes GA and settles. Three of the listed claims moved
in the window the 2026-10-06 audit covered: the OneLake-security
exclusion was withdrawn (2026-09-21), and the split dropped static-first
ordering from the new binding page and made entity keys optional.

The REST **item-definition** specs are separate pages in a separate repo
and are *not* covered here:
`rest/api/fabric/articles/item-management/definitions/ontology-definition`
for the new experience's TMDL parts, and `.../ontology-old-definition`
for the old experience's JSON (both checked 2026-10-07). They are the
source for the definition-part schemas in that skill's reference, and
they drift on their own schedule; check them by hand when the definition
layout is in question.
