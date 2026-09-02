# Handoff: does the Ontology item need a skill?

- **Written**: 2026-09-02, from the same coverage question that produced
  [skill-semantic-model-audit.md](skill-semantic-model-audit.md).
- **Kind**: coverage decision, then `/author-skill`.
- **Status**: open. **Recommendation: yes, author it** — as
  `fabric-ontology`, scoped to *generating an ontology from an existing
  Fabric asset and consuming it from agents*, not to the portal
  click-path.
- **Run in**: a fresh session. Step 1 is a name verification that must
  land before any glob is written.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.
- **Sibling**: author this **before**
  [skill-semantic-model-audit.md](skill-semantic-model-audit.md) if doing
  both — the generation-constraint matrix in step 3 is drilled here and
  merely cited there.

## The gap

`grep -rni "ontology" skills/ claude/ tests/` returns hits in exactly
**one** file: `fabric-data-agent`, whose `description` already lists
Ontology as one of the eight data-agent sources, and whose body mentions
it in passing. There is no skill, no rule glob, no fixture, and no
`fabric-git-serialization.md` entry.

That is a live inconsistency, not just an absence: the payload already
tells the model that a data agent can be grounded on an ontology, and
then has nothing to say when it is.

**Ontology is a Git-supported item.**
[Git integration → Supported items](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration#supported-items)
lists it under a distinct **"IQ (preview) items"** group alongside Plan.
So ontology definitions land in a Git-synced repo as files, on the same
footing as a `.DataPipeline` or a `.SemanticModel` — which is what makes
a `paths:`-scoped skill the right shape rather than a prose-only
reference.

## Step 1 — verify the folder suffix before writing the glob

**Do not assume `.Ontology`.** Wave 0 of this queue was spent entirely on
confirming three item-type folder names that had been guessed, and the
`.OperationsAgent` brief opens on the same problem from the other
direction (an item filed under the wrong workload in the ALM support
list). `C:\Repos\ACME\fabric-acme` has **no** ontology item today —
confirmed 2026-09-02 — so there is no local sample to read the suffix
off, which is precisely the condition under which a guess gets committed.

Resolve it from a Git-synced workspace that actually contains one, or
from the Fabric REST item-types list. The same applies to the
`definition/` layout inside it: unknown, and unguessable.

Until that is settled, the glob and the fixture are both blocked. Nothing
else in this brief is.

## Step 2 — check the overlap, especially with `fabric-graph`

Two skills already stand next to this and the boundary is not obvious.

**`fabric-graph`** (`**/*.GraphModel/**`) covers the GraphModel item, GQL,
graph-type DDL and the executeQuery API. The ontology docs say the
*ontology graph* is "provided within ontology by Graph in Microsoft
Fabric" — so ontology sits **on top of** the item `fabric-graph` already
documents. Decide explicitly whether the ontology skill defers all graph
mechanics to `fabric-graph` (recommended) or restates any. Two
constraints below are inherited straight from Graph — the `Decimal`
nulls and the column-mapping restriction — and those must be *in* the
ontology skill even though their cause lives in the other, because they
bite at ontology-generation time.

**`fabric-data-agent`** covers agent configuration and already carries
the four configuration layers. The ontology skill should own *ontology as
a source* and hand off everything else. Grep it before drafting; if it
already says enough about ontology sources, that section shrinks to a
pointer.

Note both are conditional skills on disjoint globs, so co-loading is not
the issue here that it is for the DataPipeline brief — an ontology folder
will not pull in `fabric-graph`.

## Step 3 — the content that is genuinely uncovered

This is the half worth writing, and most of it is already drilled.

### The generation-from-semantic-model support matrix

From
[concepts-generate](https://learn.microsoft.com/en-us/fabric/iq/ontology/concepts-generate),
fetched 2026-09-02. This table is the skill's highest-value payload — it
is a hard capability matrix that cannot be guessed and produces silent
partial failures when wrong:

| Feature | Import | Direct Lake | DirectQuery |
| --- | --- | --- | --- |
| Entity type / property / relationship **definitions** | ✅ | ✅ | ✅ |
| Entity type **bindings to data** | ❌ | ✅ **only if** the backing lakehouse workspace has **inbound public access enabled** | ❌ |
| Relationship type **bindings** | ❌ | ✅ only when a primary key is identified | ❌ |
| **Querying** via bindings | ❌ | ✅ (excluding measures and calculated columns) | ❌ |

The trap is stated in the doc and is the reason this belongs in a skill:
when Direct Lake bindings fail the inbound-public-access test, **"the
ontology item is created successfully but that entity type has no data
bindings."** Success, then nothing. That is a silent failure with a
green checkmark.

Practical read for this machine's reference model: `ACME_SM_Operation`
is 16 Direct Lake tables and 1 import table, so it sits in the only
column where generation does anything useful — and its one import table
is `_MeasuresTable`, whose measures are excluded from querying anyway.

### The hard constraints, all from the same page

- **Managed lakehouse tables only** — not external tables that merely
  appear in the lakehouse.
- **No delta column mapping.** Auto-enabled where column names contain
  `,` `;` `{}` `()` `\n` `\t` `=` **or a space** — and auto-enabled on
  the delta tables backing **import-mode** semantic model tables.
- **`Decimal` is unsupported by Fabric Graph** → **null values on every
  query** for those properties. `Double` is fine. `Decimal` is the
  natural money type, so this hits currency columns first.
- **Duplicate property names across entity types must share a type.** A
  string `ID` on one entity and an integer `ID` on another breaks
  generation.
- **Not from `My workspace`.**
- Manual follow-up is required after generation regardless: bind time
  series, review entity keys (especially multi-key), bind relationship
  types.

**Verify before asserting**, and flag it in the draft: `dataType` in TMDL
is not the delta column type, and the TMDL table name is not the delta
table name. `ACME_SM_Operation` has zero `dataType: decimal` and zero
spaced column names *in TMDL* — which says nothing certain about the
lakehouse columns underneath. The check belongs at the lakehouse, and the
skill should say so rather than teaching a TMDL-side grep that produces
false confidence.

### Agent integration

From
[concepts-agent-integration](https://learn.microsoft.com/en-us/fabric/iq/ontology/concepts-agent-integration),
fetched 2026-09-02 — five consumption paths, which is the "what is this
for" half:

| Agent | Shape | Audience |
| --- | --- | --- |
| Fabric **operations agent** | Continuous monitoring + actions | Ops |
| Fabric **data agent** | Conversational Q&A in Fabric | Analysts |
| **Foundry IQ** agent | Developer agent with tool calling | Developers |
| **Copilot Studio** agent | Low-code conversational | Makers |
| **Custom agents via the ontology MCP server** | Any MCP client | Developers |

The last row is the one worth weight: **an ontology can act as an MCP
server**, which puts it in the same category as this repo's own
`claude/mcp/` templates and makes it directly relevant to how the user
works, not just to Fabric.

The operations-agent row also connects this brief to
[item-type-skill-operationsagent.md](item-type-skill-operationsagent.md)
— that brief already cites
`fabric/iq/ontology/how-to-create-operations-agent` as the
ontology-grounded variant of the item it covers. **Cross-link the two
skills; do not duplicate.** Whichever is authored second should cite the
first.

### Not drilled

The `how-to-*` pages (`how-to-bind-data`,
`how-to-use-ontology-mcp-server`, `how-to-create-agent-*`), the
four-part tutorial, `resources-troubleshooting`, and the REST/definition
surface. All are named here so the next reader knows the omission is
deliberate. `how-to-bind-data` and `how-to-use-ontology-mcp-server` are
the two most likely to change the skill's shape and should be drilled
first.

## Step 4 — the glob

Blocked on step 1. Once the suffix is confirmed, the DataPipeline brief's
reasoning applies unchanged: prefer `**/*.<Suffix>/**` over naming
individual files, so `.platform` and the definition files are all
covered, and verify with the static check before committing.

The free side-fix, same shape as wave 6: if the suffix is confirmed and
`fabric-git-serialization.md` does not glob it, add it. **That lands even
if the skill decision goes the other way.**

## Validation

- Add a fixture under `tests/skills/fabric-triggers/fixtures/` in the
  **same commit** as the skill, add its rows to
  `expected_activations.md`, and run
  `./scripts/test-activation.ps1 -Set fabric`. The fixture needs a real
  definition file, so it too is blocked on step 1.
- Run `-StaticOnly` first — it needs no session and catches a wrong glob
  before a cold run is spent on it.
- Body cap ~2,700–3,100 tokens. The support matrix and the constraint
  list are dense enough to earn `SKILL.md`; the five agent paths and the
  tutorial detail go to `references/`.
- Preview churn: this is a preview item in a preview workload. Date the
  claims in the body and register the ontology doc set as a
  `/drift-audit` source in the same pass, so the next audit sees it.
- Lint, `pre-commit run --all-files`, `/commit`.

## If the answer turns out to be no

The likeliest "no" is that the user has no ontology item and no near-term
plan for one, making this a skill authored against docs alone with no
real-use validation — a weaker basis than every other platform skill in
the payload. If so, the residue is small and placeable: the generation
constraint matrix into `fabric-gotchas`, the ontology-as-source note into
`fabric-data-agent`, and the `fabric-git-serialization.md` glob from
step 4 regardless. Record the reasoning in the deleting commit, and the
reconsider-if condition: **the first ontology item that appears in a
Git-synced workspace reopens this.**
