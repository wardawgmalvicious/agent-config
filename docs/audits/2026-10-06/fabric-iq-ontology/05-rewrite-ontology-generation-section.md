# Handoff: rewrite the ontology generation section

- **Audit run**: 2026-10-06
- **Source**: `fabric-iq-ontology`
- **Window**: floor `2026-09-02` (diff base `f78e4a0e`, 2026-08-31) →
  head `135b0dc1` (2026-10-05)
- **Covers recommended actions**: 5
- **Kind**: partial rewrite of one skill section and one reference
  section, whose source page moved under `old-experience/` and was
  replaced. Content, with a likely knock-on in the `description`.
- **Target**: `skills/fabric/fabric-ontology/SKILL.md` (lines 77–104;
  possibly line 3), `skills/fabric/fabric-ontology/references/REFERENCE.md`
  (lines 201–218)

## The problem

`SKILL.md` § "Generating an ontology from a semantic model" and
REFERENCE §5 are built on `concepts-generate.md`. That page moved to
`old-experience/concepts-generate.md` in `80a24c9` (2026-09-29). Its
successor, `how-to-generate-from-semantic-models.md`, adds metrics,
calculated columns, a Read and Build requirement and multi-model
generation. It carries neither the storage-mode matrix nor any of the
old page's limitations. Other current pages still assert some of those
limitations; the old-experience page alone keeps the rest.

## Evidence

`how-to-generate-from-semantic-models.md` at head `135b0dc1`, added by
`80a24c9` (+122) and touched since by `444ba38` and `c02fe35`:

> One way to create an ontology (preview) is to generate it directly
> from a semantic model. You can also pull data into a single ontology
> (preview) from more than one semantic model.

> You need both Read and Build permissions on the semantic models to
> generate an ontology from a semantic model and query the semantic
> models using ontology.

What generation creates now includes metrics:

> **Metrics** on entity types based on DAX measures in the semantic
> model.

The manual follow-ups gained a step:

> Rename entity types or relationships to friendly names as needed.

Multi-model generation goes through the agent only:

> Currently, you can add a second semantic model to an existing
> ontology only through the ontology agent.

The overview at head adds calculated columns: "The updated experience
expands semantic-model alignment to include calculated columns and DAX
measures." Metrics keep their source: "The source semantic model
remains the owner of the DAX expression".

**Where the old page's content went.** None of it is on the new
generation page:

| Old `concepts-generate.md` content | Still asserted at head by |
| --- | --- |
| The Import / Direct Lake / DirectQuery matrix | `old-experience/concepts-generate.md` only |
| Inbound public access disabled → no bindings | `resources-troubleshooting.md`, row "The ontology item is created but entity types have no data bindings", linking `concepts-generate.md#support-for-semantic-model-modes` |
| Semantic model service and XMLA limits | `old-experience/concepts-generate.md` only |
| Managed lakehouse tables only; no delta column mapping | `how-to-bind-data.md`, Limitations |
| `Decimal` returns null | `resources-troubleshooting.md`, row "Queries return null values for `Decimal` properties" |
| Duplicate property names must share a type | `resources-troubleshooting.md`, row "The ontology item is created but some entity types are missing", linking `concepts-generate.md#data-requirements` |
| Not from **My workspace** | `resources-troubleshooting.md`, row "The ontology item fails to generate" |

The troubleshooting page's `concepts-generate.md` links resolve to no
file at head, since the page left `docs/iq/ontology/`. Whether Learn
redirects them was not checked.

## What to change

1. **`SKILL.md:79–82`** — what generation creates and leaves undone.
   Add metrics from DAX measures (and calculated columns), and the
   rename follow-up.
2. **`SKILL.md:84–101`** — the storage-mode matrix and the
   inbound-public-access failure built on it. Only the old-experience
   page carries the matrix, while a current troubleshooting row still
   asserts its central failure. Verify whether it holds for the new
   experience before keeping it as current; otherwise move it where
   brief 01's answer puts old-experience facts.
3. **`SKILL.md:103–104`** — "You also **cannot generate from `My
   workspace`**". The troubleshooting page still asserts it; re-source
   it there.
4. Add the Read and Build requirement, and multi-model generation
   through the ontology agent only. Brief 07 adds the agent as a
   consumption path: cross-reference it rather than describe the agent
   twice.
5. **`REFERENCE.md:203`** — the source link,
   https://learn.microsoft.com/fabric/iq/ontology/concepts-generate.
   Point it at the new page, and at the old-experience page for
   whatever stays legacy.
6. **`REFERENCE.md:205–214`** — the produced and manual lists, as in
   item 1.
7. **`REFERENCE.md:216–218`** — "generation inherits the ordinary
   Power BI service constraints — semantic model size limits and XMLA
   endpoint limitations apply". Only the old-experience page says so
   now.
8. **Knock-on, not named in the audit's action: `SKILL.md:3`.** The
   `description` names "the Import / Direct Lake / DirectQuery support
   matrix whose Direct Lake bindings fail silently when the backing
   lakehouse workspace has inbound public access disabled". It follows
   item 2.

## Constraint on the fix

- **Learn is inconsistent here, so do not settle the matrix by
  assumption.** The new generation page is silent on storage modes,
  the old-experience page keeps the matrix, and a current
  troubleshooting row still blames Import mode and inbound public
  access. Keep it as current only on a current page's word, and say
  which page was checked.
- `fabric/04` item 4 owns the same matrix in the same terms:
  "re-derive the storage-mode guidance from the current pages, or mark
  it legacy if it described the old experience." Whichever runs second
  reads the first one's result instead of deciding again.
- The `description` has little room; brief 03's constraint has the
  measured budget.

## Sequencing note

Run after brief 01, and after `fabric/04` in
`docs/audits/2026-10-06/fabric/`. The matrix is shared with `fabric/04`
item 4, the ontology agent with brief 07, and the `description` retest
with brief 03.

## Verification

1. Re-open https://learn.microsoft.com/fabric/iq/ontology/how-to-generate-from-semantic-models
   and https://learn.microsoft.com/fabric/iq/ontology/old-experience/concepts-generate
   with `microsoft_docs_fetch`. Each claim in the rewritten section
   traces to one of them, and every legacy claim to the second.
2. `grep -n "concepts-generate" skills/fabric/fabric-ontology/references/REFERENCE.md`
   — any hit points at the `old-experience/` path.
3. `grep -n -i "metric\|read and build\|My workspace\|DirectQuery" skills/fabric/fabric-ontology/SKILL.md`
   — the additions are present, and the matrix sits where item 2 put
   it.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-ontology/SKILL.md`
5. If the `description` changed: `uv run --with pyyaml scripts/skill-status.py --stale`,
   then retest per `/test-skill` or record it as owed.
6. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against
`fabric-iq-ontology`, floor 2026-09-02. The old page was diffed on disk
against both its successor and its `old-experience/` copy, each
downloaded at pinned SHAs; the troubleshooting rows come from the same
session's diff of that page.

## Execution log

- **Executed**: 2026-10-07 — applied with deferrals
- **Session**: fresh
- **Files changed**: `skills/fabric/fabric-ontology/SKILL.md`,
  `skills/fabric/fabric-ontology/references/REFERENCE.md`
- **Verification**: step 1 — `how-to-generate-from-semantic-models`
  and `old-experience/concepts-generate` were fetched live this session
  (2026-10-07), with `resources-troubleshooting` and the overview. Each
  current claim traces to the new page, bar two the brief itself
  sources to the overview (calculated columns; the model owning the
  DAX) and `My workspace`, re-sourced to the troubleshooting page;
  every legacy claim traces to the old page. Step 2: the only
  `concepts-generate` hit is the `old-experience/` link. Step 3: the
  additions are present, and the matrix sits under the legacy marker.
  Step 4: the frontmatter lints. Step 5: the `description` changed;
  `--stale` lists `fabric-ontology`, and the retest is owed. Step 6,
  `pre-commit run --all-files`, runs once at the end of the pass.
- **Deferred**: the `description` retest, owed once with briefs 03, 04
  and 07.
- **Deviations**: item 2 kept `fabric/04`'s legacy marking of the
  matrix, as the constraint says the second to run reads the first's
  result. Per that constraint's "say which page was checked", the
  marker paragraph now also records that the troubleshooting page,
  checked 2026-10-07, still blames Import mode and disabled inbound
  public access for a generated ontology with no bindings, linking the
  old page, so the failure is unverified for the new experience; its
  "checked" date moved to 2026-10-07. Item 3 moved `My workspace` out
  from under the legacy paragraphs, beside item 4's Read-and-Build and
  multi-model sentences, so it no longer reads as legacy. Item 4 went
  in `SKILL.md` only, since it names no file. Item 7's sentence became
  a legacy paragraph. Item 8: the `description` now reads "generating
  an ontology from semantic models, and the old experience's Import /
  Direct Lake / DirectQuery matrix whose Direct Lake bindings fail
  silently when the lakehouse workspace has inbound public access
  disabled": 975 of 1,024 characters after. Brief 01's step 2, run
  after brief 09, found item 6's manual list still calling the legacy
  JSON part the way to bind relationship types, "(the
  `Contextualizations` above)"; it now reads "(in the old experience,
  the `Contextualizations` above)".
- **Needs**: a fresh session — after this pass lands and `fabric/04`'s
  last Needs line folds the TMDL layout into the `description`, the one
  `/test-skill fabric-ontology` retest every `description` edit here
  shares.
