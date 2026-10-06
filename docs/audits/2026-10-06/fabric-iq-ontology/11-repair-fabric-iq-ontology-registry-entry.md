# Handoff: repair the fabric-iq-ontology registry entry

- **Audit run**: 2026-10-06
- **Source**: `fabric-iq-ontology`
- **Window**: floor `2026-09-02` (diff base `f78e4a0e`, 2026-08-31) →
  head `135b0dc1` (2026-10-05)
- **Covers recommended actions**: 11
- **Kind**: four defects in one registry entry of the project-scope
  `drift-audit` skill. Each changes what the next `fabric-iq-ontology`
  audit fetches, strips or maps, and is verified by re-running it.
- **Target**: `.claude/skills/drift-audit/references/sources/fabric-iq-ontology.md`
  (lines 6–20 and 47–69 as of 2026-10-06)

## Context

The entry was registered on 2026-09-02 for one skill,
`fabric-ontology`, and its `files` are "the six pages
`fabric-ontology` is built on". The release merged on 2026-09-29
rebuilt the doc set for a new experience. One of the six pages moved,
the claims the entry exists to track now live partly outside the six,
and the entry's prose predates the split.

## D-1 — `files` names a moved page and misses the claims' homes

**Symptom.** `files`, lines 6–11, lists `overview.md`,
`concepts-generate.md`, `how-to-bind-data.md`,
`concepts-agent-integration.md`, `resources-troubleshooting.md` and
`overview-tenant-settings.md`. At head `135b0dc1`,
`concepts-generate.md` is not in `docs/iq/ontology/`: `80a24c9` moved
it to `old-experience/`, and `how-to-generate-from-semantic-models.md`
replaced it.

**Cause.** The entry's prose, lines 22–27, says it exists for claims
such as "the property-type table gained a row", "the
one-static-binding-per-entity-type limit moved" and "the MCP endpoint
path changed". At head those live in:

| Claim | File at head | In `files`? |
| --- | --- | --- |
| Property, key and timestamp types | `includes/supported-property-types.md` | no |
| Manual refresh | `includes/refresh-graph-model.md` | no |
| MCP endpoint path; the service-principal known issue | `how-to-use-ontology-mcp-server.md` | no |
| Enrichment, REFERENCE §4's source | `how-to-add-metadata.md` | no |
| Graph materialization and refresh | `how-to-use-ontology-graph.md` | no |
| Capacity and billing | `resources-capacity-usage.md` | no |
| The static-binding limit | `how-to-bind-data.md` | yes |

The audit diffed the first three anyway, because the entry's prose
names their claims. The include's new refresh wording and the MCP
page's known issue fed briefs 06 and 08.

**Fix.** Replace `concepts-generate.md` with
`how-to-generate-from-semantic-models.md`, and add the pages the
rewritten skill cites.

**Open question.** Whether `old-experience/` pages enter `files` until
2027-01-31. That follows brief 01's answer: if the skill keeps a
legacy section, the pages it cites are worth tracking until the
retirement.

**Knock-on.**

- A name under `includes/` or `old-experience/` is not in the listing
  of `path` that `drift-audit` § 4a step 4 narrows by blob SHA; that
  subdirectory needs listing too. Commits touching it are already in
  the `list_commits` filter, since `path` covers subdirectories.
- `drift-audit` § 4b prices this source at "13 (6 files)" WebFetch
  calls, worked on 2026-09-08. Re-derive the figure if `files` changes
  length.
- `files` says REFERENCE §8 lists the undrilled pages; brief 08
  rewrites §8, so keep the two consistent.

## D-2 — the entry has no `drill.strip`

**Symptom.** The entry has `drill.host` and `drill.via`, lines 15–16,
but no `drill.strip`. `sources.md` § "Adding a source", step 2:
"Create `sources/<id>.md` with every field filled."

**Cause.** Omitted at registration. The audit built its report URLs
from page paths, which carried no anchor, so nothing broke.

**Fix.** Add the field. There is a real choice:

- `none`, with the reason above.
- Strip every `#…` fragment. Heading anchors on this doc set moved in
  this window: `c02fe35` renamed the heading `Ontology item (preview)`,
  so the base link `overview-tenant-settings.md#ontology-item-preview`
  lost its target. The troubleshooting page at head still links
  `concepts-generate.md#data-requirements` and
  `concepts-generate.md#support-for-semantic-model-modes` on a page
  that moved.

## D-3 — the prose predates the split

**Symptom.** Two passages describe the doc set as it was.

- Lines 47–63, the retirement rule, tie the source's life to a first
  local sample and to GA. They do not mention the old experience, its
  copies under `old-experience/`, or its retirement on 2027-01-31. The
  "definition layout" they say a sample would settle, "the `{}`
  envelope, the `EntityTypes/{id}/` and `DataBindings/{guid}.json`
  shapes", is the old experience's; per `fabric/04`, the new one is
  TMDL. Their list of claims "most likely to move" names the
  OneLake-security exclusion, which moved in this window (brief 03).
- Lines 65–69 name the REST item-definition page,
  `rest/api/fabric/articles/item-management/definitions/ontology-definition`,
  as the source of "the definition-part schemas". Per `fabric/04`, from
  the `fabric` audit the same day, that page now documents the TMDL
  new experience, and the JSON schemas are at
  `.../definitions/ontology-old-definition`.

**Fix.** Record the split and the 2027-01-31 retirement, dated, and
point the REST note at both pages. Keep the retirement rule's
substance unless brief 01's answer changes what the skill covers.

## D-4 — `artifacts` omits `claude/mcp/`

**Symptom.** `artifacts`, lines 17–20, lists three skills and
`claude/rules/fabric-git-serialization.md`. The project template now
carries the ontology's MCP server:
`claude/mcp/.mcp.project.template.json:139–141`, entry
`ontology-remote-mcp`, URL
`https://api.fabric.microsoft.com/v1/mcp/dataPlane/workspaces/<WorkspaceId>/items/<OntologyId>/ontologyEndpoint`,
documented at `claude/mcp/README.md:254`.

**Cause.** `drift-audit` § 5 scans only the artifact classes an entry
lists. The entry's prose names "the MCP endpoint path changed" as a
claim it exists to catch, yet such a change would map to the skill and
not to the template that serves the endpoint.

**Fix.** Add `claude/mcp/` to `artifacts`.

**Open question.** The audit said to consider this, not to do it.
Adding it costs every run of this source one more file class in its
Phase 2 scan.

## Sequencing note

Run last: `files` should name what the rewritten skill cites, so after
briefs 02–09 here and `fabric/04` in `docs/audits/2026-10-06/fabric/`.
D-1's open question needs brief 01's answer, and D-3 reads brief 09's
result. Like `fabric/17`, this brief is verified by a re-run and not by
greps on the skill, so do not bundle it with the skill briefs.

## Verification

1. `get_file_contents` on `docs/iq/ontology/` at `main` with
   `fields: ["name"]`, plus `includes/` and `old-experience/` where
   `files` names them: every name in `files` exists.
2. `grep -n "drill.strip\|2027\|old-experience\|ontology-old-definition" .claude/skills/drift-audit/references/sources/fabric-iq-ontology.md`
   — each repair is present.
3. Re-run `/drift-audit --sources fabric-iq-ontology 2026-09-02`
   against the amended entry. `00-audit-report.md` in this directory is
   the known answer: the same 32 commits through `135b0dc`, plus any
   since; every name in `files` fetched at both refs, or marked absent
   at the base; and, if D-4 added it, an MCP finding mapped to
   `claude/mcp/`.
4. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`
   — untouched; confirm it still lints.
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against
`fabric-iq-ontology`, floor 2026-09-02, the first run of this source
with a directory under `docs/audits/`. The directory listings at both
refs, and the template and README lines, were read in the audit
session. The REST page facts in D-3 are `fabric/04`'s.
