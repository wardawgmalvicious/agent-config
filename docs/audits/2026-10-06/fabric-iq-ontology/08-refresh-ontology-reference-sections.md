# Handoff: refresh the ontology reference sections

- **Audit run**: 2026-10-06
- **Source**: `fabric-iq-ontology`
- **Window**: floor `2026-09-02` (diff base `f78e4a0e`, 2026-08-31) →
  head `135b0dc1` (2026-10-05)
- **Covers recommended actions**: 8
- **Kind**: four independent minor edits, three in one skill's
  reference and one in its body. No `description` change.
- **Target**: `skills/fabric/fabric-ontology/references/REFERENCE.md`
  (line 179; lines 220–245; lines 256–265),
  `skills/fabric/fabric-ontology/SKILL.md` (lines 165–168)

## Context

Four places in `fabric-ontology` cite or summarize pages that moved,
lost content or gained rows in this window. Each edit is small and is
checked against one page, and all four land in the same two files.

## D-1 — §4 cites a page that moved

**Symptom.** `REFERENCE.md:179`:

> Source: [Add semantic enrichment with metadata](https://learn.microsoft.com/fabric/iq/ontology/how-to-add-semantic-enrichment).

**Cause.** `80a24c9` (2026-09-29) moved that page to
`old-experience/how-to-add-semantic-enrichment.md` and added
`how-to-add-metadata.md` for the new experience. The audit fetched the
new page live on 2026-10-06, and it supports every claim in §4:

> **Synonyms**: Only entity types support synonyms. Properties and
> relationship types don't support synonyms.

> **Duplicate keys**: Each entity type, property, and relationship type
> must have unique keys for additional metadata. If you add duplicate
> keys, you get an error.

> Ontology query generation doesn't directly use the metadata.

> publicly available data agent experiences don't currently use
> relationship-level enrichment.

> Add unit information for numeric properties, such as `unit: celsius`
> or `unit: USD`.

**Fix.** Point §4 at
https://learn.microsoft.com/fabric/iq/ontology/how-to-add-metadata.
The page says "metadata" where the skill says "semantic enrichment";
adopting its term is optional.

## D-2 — the skill's enrichment example was deleted upstream

**Symptom.** `SKILL.md:165–168`:

> It is not decoration: the documented example is a data agent
> that cannot answer "which ice cream shops sold the most frozen desserts?"
> until `Products` gains the synonym `frozen desserts`.

**Cause.** `118630f` ("Remove data agent metrics (#16525)",
2026-09-17) changed `how-to-add-semantic-enrichment.md` by +5/−42, and
four images with it: `data-agent-before.png`, `data-agent-after.png`,
`example-category.png` and `example-products.png`. The new
`how-to-add-metadata.md`, fetched in full, has no such example.

**Fix.** Drop the example, or replace it with one the current page
documents.

**Open question.** Not checked: whether
`old-experience/how-to-add-semantic-enrichment.md` still carries the
example. If it does, the example is old-experience documentation, and
brief 01's answer says where it goes.

## D-3 — §6 lacks the known issues added in this window

**Symptom.** §6, `REFERENCE.md:220–245`, maps 16 symptoms. None covers
migration, the MCP server or inheritance.

**Cause.** `resources-troubleshooting.md` at head `135b0dc1` carries
these rows, absent at base; six in-window commits touched the page,
`80a24c9`, `444ba38` and `a1ff6db` among them:

```text
| Migration fails | Check whether your old ontology meets either of these failure conditions: <br>- The old ontology contains properties configured as *Defined at Binding* <br>- The old ontology contains entities that use composite keys <br><br> Both of these conditions cause migration to fail. Remove the problematic properties or keys and retry the migration. |
| Can't use Service Principal to access the ontology MCP | This feature is currently unavailable due to a known issue. |
| Can't query a parent entity and get the instances of the inheriting entities | This feature is currently unavailable due to a known issue. |
```

And a pointer, on the troubleshooting page and twice in the overview:

> For ontology known issues, see Microsoft Fabric known issues
> (https://support.fabric.microsoft.com/known-issues/) and search for
> *ontology*.

`how-to-use-ontology-mcp-server.md` carries the service-principal issue
too: "Due to a known issue, you can't currently use Service Principal
to access the ontology MCP." `claude/mcp/README.md:254` already
records it.

**Fix.** Add the three rows, symptom first as §6 is written, and the
known-issues pointer.

**Knock-on.** The service-principal issue belongs beside §3's MCP
endpoint as well.

**Out of scope.** Other new rows on that page belong to other briefs:
the semantic-model Read and Build row to 04, the ontology agent's
sections to 07, the data-agent rows to 10. The existing "aggregates
wrongly" row, `REFERENCE.md:241`, is no brief's here: `fabric/04` item
6 retires the group-by workaround in `SKILL.md:197–200` only, and the
troubleshooting page at head still documents it (row quoted in brief
10).

## D-4 — §8's undrilled list is stale

**Symptom.** `REFERENCE.md:256–265` names the pages left undrilled on
2026-09-02, and singles out `how-to-view-entity-type-details` as owning
"the graph-refresh mechanics referenced above".

**Cause.** At head `135b0dc1`:

- `how-to-view-entity-type-details.md` moved to `old-experience/` in
  `80a24c9`. `how-to-view-ontology-details.md` is new, and the
  `refresh-graph-model` include now links its refresh mechanics to
  `how-to-use-ontology-graph.md`.
- `80a24c9` added 14 pages besides the generation page:
  `how-to-add-metadata`, `how-to-create-data-agent`,
  `how-to-import-export`, `how-to-reuse-properties`,
  `how-to-share-permissions`, `how-to-use-inheritance`,
  `how-to-use-metrics`, `how-to-use-namespaces`,
  `how-to-use-ontology-agent`, `how-to-use-ontology-graph`,
  `how-to-use-version-history`, `how-to-view-ontology-details`,
  `resources-privacy-compliance-faq` and
  `resources-responsible-ai-faq`.
- `how-to-create-entity-types`, `how-to-create-relationship-types`,
  `how-to-use-rules` and `how-to-use-resource-links` now exist twice,
  at the root and under `old-experience/`.
- `resources-capacity-usage.md` changed in five commits, `8e5fefb`
  among them (+103/−6, "Expand ontology billing and capacity usage
  guidance"). Brief 06 drills it.

**Fix.** Rewrite §8 against the head directory listing: what moved
under `old-experience/`, what is new, and which pages briefs 05, 06,
07 and 09 drilled. Keep the section's purpose, which is to name each
omission so that it stays deliberate.

## Sequencing note

Run after brief 01 (D-2's open question) and brief 06 (D-4's drilled
pages), and after `fabric/04` in `docs/audits/2026-10-06/fabric/`,
which restructures the same reference.

## Verification

1. `grep -n "how-to-add-semantic-enrichment\|frozen desserts\|how-to-view-entity-type-details" skills/fabric/fabric-ontology/SKILL.md skills/fabric/fabric-ontology/references/REFERENCE.md`
   — no hit, or each one points at an `old-experience/` page on
   purpose.
2. Re-open https://learn.microsoft.com/fabric/iq/ontology/resources-troubleshooting
   and confirm the three rows and the pointer.
3. List `docs/iq/ontology/` on `MicrosoftDocs/fabric-docs` `main` with
   `get_file_contents`, `fields: ["name"]`; every page §8 names exists
   there or under `old-experience/`.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-ontology/SKILL.md`
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against
`fabric-iq-ontology`, floor 2026-09-02. D-1's quotes come from
`how-to-add-metadata` fetched live through `microsoft-learn-mcp`; D-2's
commit figures from the GitHub API; D-3's rows and D-4's listings from
the on-disk diff and the directory listings at both pinned refs.

## Execution log

- **Executed**: 2026-10-07 — applied with deferrals
- **Session**: fresh
- **Files changed**: `skills/fabric/fabric-ontology/SKILL.md`,
  `skills/fabric/fabric-ontology/references/REFERENCE.md`
- **Verification**: step 1 — every hit points at an `old-experience/`
  page on purpose: the D-2 legacy link and §8's old-experience lists.
  Step 2: `resources-troubleshooting` was fetched live (2026-10-07) and
  carries the three rows and the pointer. Step 3: `docs/iq/ontology/`
  and `old-experience/` were listed on `main` with `get_file_contents`
  the same day; every page §8 names is in one of them. Step 4: the
  frontmatter lints. Step 5, `pre-commit run --all-files`, runs once at
  the end of the pass.
- **D-1**: §4 now cites `how-to-add-metadata`, fetched live; it carries
  every §4 claim. The skill's term "semantic enrichment" was kept.
- **D-2**: the open question was a lookup, and brief 01's log already
  answers where an old-experience fact goes, naming this defect. Both
  `how-to-add-metadata` and `old-experience/how-to-add-semantic-enrichment`,
  fetched live, lack the example, so it was dropped and replaced by
  the current page's own statement of what metadata improves.
- **D-3**: the three rows went in before the data-agent rows, so those
  stay last, and the known-issues pointer after the table. The
  knock-on put the service-principal issue beside §3's MCP
  prerequisites, sourced to `how-to-use-ontology-mcp-server`, fetched
  live. Every existing §6 row was checked against the live page and
  holds, so the source line now carries that date.
- **D-4**: §8 was rewritten against the listing. It names what this
  pass drilled, briefs 05–07 and this one, with the brief 01 and 03
  lookups, and what it did not. `how-to-create-data-agent` and
  `how-to-create-agent-copilot-studio` are listed as not drilled,
  though `fabric/04` quoted single claims from Learn on 2026-10-06,
  since a quote is not a drill. Brief 09 has not run, so §8 says only
  that §1's schemas come from the REST pages, outside this doc set.
- **Deferred**: an adjacent finding, not fixed. §6's note "the last
  four are data-agent-side" sits under three data-agent rows, which
  was so before this pass.
- **Deviations**: D-2 also added a dated legacy line quoting the old
  enrichment page, "Data agent doesn't use the semantic enrichment
  fields", under brief 01's option 4: that page now says the opposite
  of what the dropped example implied, and a reader with an old item
  would otherwise expect the current page's agent benefit.
- **Needs**: a fresh session — a one-word edit, by `/learn` or the
  next brief to touch §6, that corrects "the last four" to three.
