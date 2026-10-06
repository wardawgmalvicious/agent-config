# Handoff: add the data agent's ontology known issues

- **Audit run**: 2026-10-06
- **Source**: `fabric-iq-ontology`
- **Window**: floor `2026-09-02` (diff base `f78e4a0e`, 2026-08-31) →
  head `135b0dc1` (2026-10-05)
- **Covers recommended actions**: 10
- **Kind**: minor edit adding two known issues to one paragraph of
  `fabric-data-agent`. Body only; no `description` change.
- **Target**: `skills/fabric/fabric-data-agent/SKILL.md` (line 21)

## The problem

`fabric-data-agent` keeps the data-agent-side behaviours of an
ontology source in one paragraph. Learn added two known issues on that
side in this window, and the paragraph has neither: a data agent does
not work with an ontology bound through semantic models, and duplicate
relationship names break natural-language queries.

## Evidence

`resources-troubleshooting.md` at head `135b0dc1`, § "Troubleshoot
ontology as data agent source", both absent at base `f78e4a0e`:

```text
| Natural language query errors | Due to a known issue affecting duplicate relationship names, ensure relationship names are unique. |
```

> Due to a current known issue, data agent doesn't work with an
> ontology that uses semantic models for binding.

`fabric/04`'s sibling `fabric/07` quotes the same sentence from
`how-to-create-data-agent`.

`SKILL.md:21` now ends:

> Three data-agent-side behaviours belong here rather than there: an
> ontology source is still **preview**, the agent's first few queries
> after creation can fail while it initializes (wait and retry), and
> **aggregation is a known gap** — add the instruction `Support group
> by in GQL` to the agent's instructions.

## What to change

`SKILL.md:21`, the paragraph quoted above. Add both issues as
data-agent-side behaviours, and correct the count ("Three").

## Sequencing note

`fabric/07` item 2, in `docs/audits/2026-10-06/fabric/`, rewrites the
same paragraph: it retires the group-by workaround and adds the
semantic-model issue. If it has run, add only the duplicate
relationship-name issue and recount. If it has not, keep this edit to
the two additions and leave the group-by clause to it.

## Constraint on the fix

Do not restore the group-by workaround here, though the ontology
troubleshooting page at head still documents it, unchanged in this
window:

```text
| Query results don't aggregate correctly | There's a known issue affecting aggregation in queries. To enable better aggregation, add the instruction `Support group by in GQL` to the agent's instructions as described in [Provide agent instructions](tutorial-4-create-data-agent.md#provide-agent-instructions). |
```

Its link target, `tutorial-4-create-data-agent.md`, is not in the
directory at head; `80a24c9` removed it. `fabric/07` retires the
workaround on the strength of a different page. That conflict is
recorded here for whoever runs `fabric/07`, and is not this brief's to
settle.

## Verification

1. `grep -n -i "semantic model\|relationship name" skills/fabric/fabric-data-agent/SKILL.md`
   — both issues present at line 21 or its successor.
2. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-data-agent/SKILL.md`
3. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against
`fabric-iq-ontology`, floor 2026-09-02, from the on-disk diff of the
troubleshooting page at pinned SHAs. `fabric-data-agent` is in this
source's `artifacts`, which is why an ontology page produced a finding
against it.
