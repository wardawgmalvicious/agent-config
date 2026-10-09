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

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: D-1: `skills/fabric/fabric-tmdl/SKILL.md`,
  `claude/rules/coding-tmdl.md`, `claude/rules/coding-dax.md`,
  `tests/skills/code-review/fixtures/Fixture.SemanticModel/definition/tables/tmdl_fixture.tmdl`
  (moved by `git mv`), `tests/skills/code-review/README.md`,
  `tests/skills/code-review/expected_findings.md`,
  `tests/skills/fabric-triggers/fixtures/SampleOntTmdl.Ontology/.platform`
  and `database.tmdl` (new), `tests/skills/fabric-triggers/README.md`,
  `tests/skills/fabric-triggers/expected_activations.md`,
  `copilot/.source-hashes.json`. D-2:
  `skills/fabric/fabric-database/SKILL.md`,
  `skills/fabric/fabric-copy-job/SKILL.md` and `references/REFERENCE.md`,
  `skills/fabric/fabric-data-agent/SKILL.md`,
  `references/status-and-retirements.md` and
  `references/authoring-workflow.md`,
  `skills/fabric/fabric-operations-agent/references/REFERENCE.md`,
  `claude/rules/fabric-git-serialization.md`,
  `skills/fabric/fabric-deployment-pipelines/SKILL.md` and
  `references/REFERENCE.md`, `claude/rules/coding-tsql.md`,
  `skills/fabric/fabric-semantic-model-ai-instructions/SKILL.md` and
  `references/REFERENCE.md`, `skills/fabric/fabric-semantic-model-audit/SKILL.md`
- **Decision (D-1)**: the open question and the three options were put
  to the user. Exclude was out: the Claude Code memory docs say only
  that `paths:` patterns are "matched against absolute file paths using
  glob syntax", and an open feature request asks for an `exclude:` field.
  Of 132 `.tmdl` files under `C:\Repos`, the code-review fixture was the
  only one outside a `.SemanticModel` folder. **Answer: Narrow.**
- **Verification**: steps 1–3 passed, bar the deploy half of step 1;
  step 4 runs once at the end of the run. Step 1:
  `test-activation.ps1 -StaticOnly` passed on all 74 fabric and 16 pbip
  fixtures; `grep -l '^paths:'` still counts 30, as the tables say. A
  rules pass (wcmatch, as the fabric README does it) gives
  `SampleOntTmdl.Ontology/database.tmdl` `fabric-ontology` and
  `fabric-git-serialization` alone, and the moved fixture still
  `coding-tmdl` and `coding-dax`. Step 2, one verdict per row:
  1. Edited: Warehouse `MERGE` is GA, per `tsql-surface-area`.
  2. Edited: the REST definition's CDC example writes `"Upsert"` with
     `upsertSettings.keys` and a source `changeDataSettings.readMethod`
     of `"SnapshotPlusIncremental"`; `"Merge"` is not on the page.
  3. Edited: `data-agent-source-control` says "Source control for Fabric
     data agents is currently in preview"; Git's supported-items list
     gives Data Agents no label, which both lines now say.
  4. Edited: 15,000 characters for the agent's own instructions; Learn
     gives no data-source limit.
  5. Split. Edited: "Only Eventhouse tables or shortcut tables are
     supported." Left: the limitations page says "excluding East US",
     but the region-availability page, read earlier in this run, lists
     South Central US without Operations agent; Learn disagrees with
     itself, so `REF:171-172` keeps both regions.
  6. Edited in part: `**/*.Plan/**` added, its folder observed on a real
     item 2026-09-30. The other seven stay out: Learn gives no folder
     suffix for any, only REST `ItemType` names, and Deployment plan has
     none. The fabric table's Known gaps names them.
  7. Edited: the inbound-protection precondition, a network paragraph
     with the REST path for the Git outbound policy, and per-item
     `itemOptionsBySourceItemId` with `validateOnly`.
  8. Edited: the Jaro-Winkler pages are preview; the `||` and `UNISTR`
     pages carry no label.
  9. Left: the rule's `=~`-over-`tolower()` advice is Learn's own
     case-insensitive row ("Use `Col =~ "lowercasestring"`. Don't use
     `tolower(Col) == "lowercasestring"`."), and the eventhouse table's
     partial-index `=~` row matches Learn's prefer-`==` row.
  10. Edited: both dates, each dated: February 2027 on every Q&A page and
     in Microsoft's extension notice, December 2026 on
     `semantic-model-best-practices`.

  Each edited row's grep returns the corrected text. Step 3: lint clean
  on the seven skills and four rules; `skill-status.py --stale` lists
  `fabric-tmdl` as `retest-activation`. `lint-instructions.py --stamp`
  changed only the `coding-dax`, `coding-tmdl` and `coding-tsql` hashes.
- **Deferred**: the deploy (`link-claude.ps1 -SkillGroups
  workflow,social,meta` after landing) and the check that the deployed
  `coding-tmdl`, `coding-dax`, `coding-tsql` and
  `fabric-git-serialization` match the repo; the real-path
  `test-activation.ps1 -Set fabric` and `-Set pbip`; and `/test-skill
  fabric-tmdl`. Two adjacent findings: `coding-tsql.md:33` says `||` and
  `UNISTR` don't apply to SQL database in Fabric, which their Learn pages
  list under Applies to; and, observed once and not isolated, the
  deployed `coding-dax` and `coding-tmdl` loaded right after a Write
  created `SampleOntTmdl.Ontology/database.tmdl`, with no `.tmdl` Read
  since the last flush, where `.claude/rules/editing-rules.md` says a
  rule "cannot govern creating a file".
- **Deviations**: five. (1) User-directed: Narrow, with the fixture moved
  as the option said; it now also pulls `fabric-git-serialization` and
  `fabric-tmdl-api`, as the code-review README says. (2) `fabric-tmdl`
  dropped `**/*.tmdl` rather than gaining `**/*.SemanticModel/**/*.tmdl`,
  which its `**/*.SemanticModel/**` already covers. (3) `coding-tmdl`'s
  "Applies to" line now names the `.SemanticModel` scope, since it listed
  Tabular Editor output that the narrowed glob no longer reaches outside
  one. (4) The new `SampleOntTmdl.Ontology/` fixture has two rows,
  assertion 10 and an entry among the unverified shapes, and assertion
  7's heading no longer calls `SampleAct.Activator/` the only synthetic
  fixture. (5) Row 10 also corrected the December-only date that brief
  16 wrote into `fabric-semantic-model-audit` earlier in this run. Rows
  2, 5 and 8 sat at lines briefs 09, 05 and 08 had shifted.
- **Needs**: a fresh session — `/test-skill fabric-tmdl` and the
  real-path activation runs; the deploy after landing, then the
  deployed-rules check; the next `fabric` audit — `coding-tsql.md:33`'s
  carve-out for `||` and `UNISTR`, and the Operations agent region line
  once Learn agrees with itself.
- **Needs**: a fresh session — `/test-skill fabric-tmdl` and the
  real-path activation runs; the next `fabric` audit —
  `coding-tsql.md:33`'s carve-out for `||` and `UNISTR`, and the
  Operations agent region line once Learn agrees with itself. The
  deploy and the deployed-rules check are done: `link-claude.ps1` ran
  on `main` at `f82cfd5`, and the deployed `coding-tmdl`,
  `coding-dax`, `coding-tsql` and `fabric-git-serialization` match the
  repo (`cmp`, 2026-10-06).
- **Needs**: a fresh session — `/test-skill fabric-tmdl` and the
  real-path activation runs. Both next-audit items landed 2026-10-06.
  The carve-out now gives SQL database in Fabric the string operators
  and fuzzy matching, which Learn's Applies-to lists name, and keeps
  time travel and the Warehouse-only syntax out (`97eef36`);
  `link-claude.ps1` deployed it from `main` at `84b7883`, and the
  deployed copy matches the repo (`cmp`, 2026-10-07). The Operations
  agent region line records both pages: the limitations page excludes
  East US, the region-availability page East US and South Central US.
- **Closed**: 2026-10-08 — carried by /triage to
  docs/handoffs/execute/tmdl-glob-real-path.md: the fabric set's
  real-path run, which assertion 10 has not had. The pbip half is
  covered by `skill-status.py --stale`, which lists `fabric-tmdl` as
  `retest-activation`, owing the `/test-skill fabric-tmdl` that runs it.
