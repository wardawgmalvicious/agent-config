# Handoff: scope the TMDL globs and check the incidental findings

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 23
- **Kind**: two unrelated tasks that share one recommended action:
  - an activation-glob change on one skill and two rules. It changes
    what loads when a file is read, so it needs activation tests and a
    deploy for the rules.
  - a batch of one-line verifications of incidental findings.

  They can land independently.
- **Target**: `skills/fabric/fabric-tmdl/SKILL.md` (`paths:`),
  `claude/rules/coding-tmdl.md` (`paths:`), `claude/rules/coding-dax.md`
  (`paths:`); the incidental targets listed in D-2

## D-1 — `**/*.tmdl` will match ontology files

**Symptom.** The current globs, read 2026-10-06:

| File | `paths:` |
| --- | --- |
| `skills/fabric/fabric-tmdl/SKILL.md` | `**/*.tmdl`, `**/*.SemanticModel/**` |
| `claude/rules/coding-tmdl.md` | `**/*.tmdl`, `**/definition/**/model.bim` |
| `claude/rules/coding-dax.md` | `**/*.dax`, `**/*.tmdl`, `**/*.bim` |

**Cause.** Learn's ontology definition page, checked 2026-10-06 (see
brief 04): "New experience ontology items support the **TMDL** format …
The parts are flat, item-folder-relative `.tmdl` text files plus the
platform-owned `.platform` metadata file." Reading any part of a
new-experience ontology export would therefore load semantic-model
authoring guidance and the DAX and TMDL coding rules. Those rules are
wrong for an ontology in places: an ontology carries ontology-only
extensions. No ontology item exists in a repo on this machine yet, so
the collision has not happened.

**Fix.** Options, for the executor to choose:

- **Narrow.** Change `**/*.tmdl` to `**/*.SemanticModel/**/*.tmdl` in
  all three. This drops standalone `.tmdl` files outside an item folder;
  check whether any repo here relies on those first.
- **Exclude.** Use a negated glob, if Claude Code's `paths:` supports
  one. This is unverified; check the docs before relying on it.
- **Accept the collision.** Leave the globs, and have `fabric-ontology`
  tell its reader that these rules co-load and do not apply.

**Open question.** The ontology item folder's suffix (presumably
`.Ontology`) is unverified, because there is no local export.

**Knock-on.**

- A glob change on a conditional skill or rule changes the activation
  contract. Update `tests/skills/*-triggers/expected_activations.md`.
  Run the static check (`test-activation.ps1 -Set pbip -StaticOnly`,
  and `-Set fabric`) and `/test-skill` for `fabric-tmdl`.
- The two rules are copies deployed by `scripts/link-claude.ps1`. They
  go live only after
  `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`; never
  run it without `-SkillGroups`.
- Brief 04 should land first; it establishes the ontology layout.

## D-2 — incidental findings, one check each

These were found while mapping, not triggered by any in-window entry.
All are agent-measured except where marked. For each one: check it,
then either edit (if confirmed) or leave it with a one-line note in the
execution log (if not). Two are covered elsewhere: the `fabric-warehouse`
truncation is brief 08 D-1, and the `fabric-mlv` Runtime 2.0 re-check
and region line are brief 02.

| # | Target | Claim in the repo | What Learn or the evidence says |
| --- | --- | --- | --- |
| 1 | `skills/fabric/fabric-database/SKILL.md:22` | "\| MERGE \| Preview only \| Fully supported \|" (Warehouse column) | Learn: "`MERGE` syntax is supported and is a generally available feature"; `fabric-warehouse/SKILL.md:132` already says GA |
| 2 | `skills/fabric/fabric-copy-job/references/REFERENCE.md:86,88`, `SKILL.md:57` | CDC uses `writeBehavior: "Merge"` | The REST definition page's CDC examples use `"writeBehavior": "Upsert"` with `upsertSettings` and `changeDataSettings.readMethod` (`https://learn.microsoft.com/en-us/rest/api/fabric/articles/item-management/definitions/copyjob-definition`) |
| 3 | `skills/fabric/fabric-data-agent/SKILL.md:23`, `references/status-and-retirements.md:7` | Git/CI-CD for data agents is GA | `https://learn.microsoft.com/en-us/fabric/data-science/data-agent-source-control`: "Source control for Fabric data agents is currently in preview." |
| 4 | `skills/fabric/fabric-data-agent/references/authoring-workflow.md:24` | "doesn't document a single hard limit" on instructions | `https://learn.microsoft.com/en-us/fabric/data-science/how-to-create-data-agent`: "you can write up to 15,000 characters". That limit is for data-agent instructions; don't carry it to semantic-model AI instructions without checking |
| 5 | `skills/fabric/fabric-operations-agent/references/REFERENCE.md:44, 168` | "Shortcut tables ... unsupported"; "excluding South Central US and East US" | `operations-agent-limitations`: "Only Eventhouse tables or shortcut tables are supported." and "excluding East US." |
| 6 | `claude/rules/fabric-git-serialization.md` `paths:` | 29 item-folder globs | Learn's Git supported-items list also names Deployment plan, Plan, Maps, Graph QuerySet, Cosmos DB, ML experiment and model, and dbt Job. The folder suffixes are unverified |
| 7 | `skills/fabric/fabric-deployment-pipelines/references/REFERENCE.md:98-112`, `SKILL.md:170` | Assignment preconditions and deploy options | `https://learn.microsoft.com/en-us/fabric/cicd/cicd-security`: "Deployment pipelines aren't currently supported for workspace with inbound access protection." Workspace outbound access protection blocks Git unless "Allow Git integration" is on (`GET /workspaces/{workspaceId}/gitOutboundPolicy`). Deploy accepts per-item `validateOnly` through `options.itemOptionsBySourceItemId` |
| 8 | `claude/rules/coding-tsql.md:240-241` | Groups `\|\|` with the preview fuzzy-match functions and `UNISTR` | Learn's `\|\|` page has no preview banner; the `JARO_WINKLER_*` pages do |
| 9 | `claude/rules/coding-kql.md:188-189` | Prefer `=~` over `tolower()` | `fabric-eventhouse/SKILL.md:219` marks `=~` "❌ partial", and Learn's best-practices table says "Use `==`. \| Don't use `=~`." Low confidence; read both in context first |
| 10 | `skills/fabric/fabric-semantic-model-ai-instructions/SKILL.md:40`, `references/REFERENCE.md:30` | Depend on Q&A | Learn dates the Q&A retirement "December 2026" (`semantic-model-best-practices`) and "February 2027" (the Q&A pages). Record both, dated |

## Verification

1. **D-1.** The changed globs pass the static activation check. The
   `expected_activations.md` tables match `grep -l '^paths:' skills/*/*/SKILL.md`.
   After the deploy, the rules' deployed copies match the repo.
2. **D-2.** The execution log has one verdict per row (edited or left,
   with the reason). For each edited row, a `grep` of the quoted claim
   returns the corrected text.
3. `uv run --with pyyaml scripts/lint-frontmatter.py` on every
   `SKILL.md` touched. `uv run --with pyyaml scripts/skill-status.py --stale`
   names any skill whose `paths:` changed.
4. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric` (floor
2026-09-01). The IQ mapping subagent found the glob collision while
drilling the ontology definition, and the audit session verified the
TMDL format and read the three `paths:` blocks itself. The incidental
rows came from the five mapping subagents' coverage notes, as recorded
in the report's "Incidental" list.
