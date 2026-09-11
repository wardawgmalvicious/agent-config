# Drift audit — skills-for-fabric, 2026-09-10

## Audit window

- Floor: 2026-08-06 (resolved from: default-35d)
- Fetch path: github-mcp. The entry's own strategy is to read HEAD once and treat the file as prepend-only. This run found the file is **not** prepend-only, so I used a different path. I read one `CHANGELOG.md` patch per commit, isolated from each squashed release with `get_commit` file pagination (`perPage: 1, page: N`). I fetched the full base ref only for clause-1 history.
- Sources audited: skills-for-fabric. Skipped: fabric, powerbi, vscode-agent, fabric-iq-ontology, claude-code (not in `--sources`).
- skills-for-fabric: 10 commits in window. Prior `912e06e0` (2026-07-30, v0.3.10) → head `65902bae` (2026-09-04). main is at `74f3262c` (2026-09-06), the PR #86 merge of that same release.
  - `65902bae` (2026-09-04): Release v0.3.15, `CHANGELOG.md` +17/-0
  - `99de3299` (2026-08-26): Release v0.3.14, +27/-0
  - `22cafc90` (2026-08-20): Release v0.3.13, +18/-1 (the −1 is the `[Unreleased]` heading)
  - `a5e82199` (2026-08-13): fix placing the v0.3.12 notes under their heading, +1/-2
  - `ab33f1da` (2026-08-13): Release v0.3.12, +26/-0
  - `af9aff33` (2026-08-06): web edit removing two 0.3.11 bullets about a catalog-total startup-metadata check, +0/-2
  - `9d5fe403` (2026-08-06): web edit removing internal test/build references from 0.3.11 **and from the pre-floor 0.3.10, 0.3.6 and 0.3.5 sections**, +6/-26
  - `e4dfaebd` (2026-08-06): revert of `d231b957`, +283/-283. Patch not fetched; the blob `3fd6c501` is identical at `2b3530e8` and `e4dfaebd`, so the pair nets to zero.
  - `d231b957` (2026-08-06): line-ending flip plus a 0.3.11 edit, +283/-283. Patch not fetched (reverted).
  - `2b3530e8` (2026-08-06): Release v0.3.11, +68/-1
- Vendored pair: both path checks since `b8d541c` (2026-08-20T13:22:57Z) return `[]`. The tree SHAs of all four `powerbi-report-*` skills are identical at `b8d541c` and HEAD, which proves the empty result is real and not a dead path.
- Known-answer check (registry step 5), run on a superset window: the vendored checks are empty, clause 1 surfaces `onelake-catalog-govern-cli`, and it does not surface `databricks-migration` (mentioned in 0.3.0 and 0.3.9). All three pass.

## Drift / gap candidates (existing artifacts)

- **fabric-warehouse-monitoring**: result set caching _(skills-for-fabric)_
  - Specific change: upstream 0.3.15 says it "stopped recommending result-set caching while the feature is unavailable". Learn confirms the feature "is currently disabled". Learn also defines `result_cache_hit` as `2` = hit, `1` = created, `0` = not applicable. `SKILL.md:83-85` says "(Preview)" with `1` = hit, `0` = miss, negative = skip reason. `REFERENCE.md:29` repeats the negative codes.
  - Reference: https://learn.microsoft.com/fabric/data-warehouse/result-set-caching
  - Proposed action: minor edit
- **fabric-warehouse-monitoring**: Capacity Metrics correlation _(skills-for-fabric)_
  - Specific change: Learn says the Metrics app "Operation Id … no longer maps to the distributed statement ID". It says to correlate by the billing interval's start and end times against `exec_requests_history` instead. `REFERENCE.md:36` still describes drilling from Operation Id to `distributed_statement_id`. Learn's sample query also carries `sql_pool_name`; custom SQL pools don't appear anywhere in the skill (flag only).
  - Reference: https://learn.microsoft.com/fabric/data-warehouse/how-to-observe-utilization
  - Proposed action: minor edit
- **fabric-eventstream**: pause/resume lifecycle _(skills-for-fabric)_
  - Specific change: the skill has no pause/resume coverage. Learn: `POST …/eventstreams/{id}/resume` requires `startType` (`Now` / `WhenLastStopped` / `CustomTime`), with an optional `customStartDateTime`. Support for pause and resume varies by node. Git and deployment pipelines do not carry pause/resume state, and after a deploy all target resources become active. I did not fetch the pause endpoint, and upstream's claim about endpoint order is unconfirmed.
  - Reference: https://learn.microsoft.com/rest/api/fabric/eventstream/topology/resume-eventstream
  - Proposed action: minor edit
- **fabric-mlv**: MLV execution definitions _(skills-for-fabric)_
  - Specific change: Learn confirms the `/mlvexecutiondefinitions` CRUD API and `executionData.mlvExecutionDefinitionId` on both on-demand refresh and schedules. Deleting a definition also removes its linked schedules. None of this is in the skill. Upstream's claim that history can show a `MaterializedLakeViews` job type is **not** confirmed: Learn shows `RefreshMaterializedLakeViews` throughout, so don't encode it. This bullet reached the audit only because the counterpart table is missing `fabric-mlv`.
  - Reference: https://learn.microsoft.com/fabric/data-engineering/materialized-lake-views/materialized-lake-views-public-api
  - Proposed action: minor edit
- **fabric-git-serialization rule**: final newline on notebook parts _(skills-for-fabric)_
  - Specific change: upstream observes an LF export with **no final newline** for `notebook-content.py`, `pipeline-content.json` and `.platform`, and pins them with `text eol=lf`. Our rule says `notebook-content.*` **does** end with a newline, and requires `-text`, not `eol=lf`. Learn confirms the service commits LF, but says nothing about the final newline. Upstream itself calls this "not a documented platform guarantee". It is unconfirmed, so it's not a finding by the registry's standard.
  - Reference: https://learn.microsoft.com/fabric/cicd/git-integration/git-integration-process
  - Proposed action: flag and settle by measuring a real notebook export
- **fabric-semantic-model-ai-instructions**: Git-deployed AI settings need a refresh _(skills-for-fabric)_
  - Specific change: found while drilling the 0.3.15 Prep-for-AI bullet. Learn says AI instructions and AI data schemas are saved to the LSDL, the model's linguistic schema. LSDL edits that arrive through Git or deployment pipelines need a service refresh to take effect; for DirectQuery and Direct Lake that applies once a day. The skill doesn't mention this.
  - Reference: https://learn.microsoft.com/power-bi/create-reports/copilot-prepare-data-ai
  - Proposed action: minor edit

## New-skill candidates

- **`onelake-catalog-govern-cli`**: the only upstream skill that is genuinely new in this window. It covers governance across domains, workspaces, capacities, protection and curation. No local counterpart.
  - Source: skills-for-fabric / 0.3.15 Added
- **`activator-cli`**: a clause-1 hit on the new name only; it merges skills that existed since 0.3.1. Locally, Activator exists only as an Eventstream destination and an MCP template entry. The four 0.3.13 fixes are useful input if this gets authored, e.g. `HTTP 400 DisplayName field is required`.
  - Source: skills-for-fabric / 0.3.11 Added
- **`dataflows-cli`**: a clause-1 hit on the new name only; it merges skills that existed since 0.3.0. There is no local Dataflow Gen2 skill.
  - Source: skills-for-fabric / 0.3.11 Changed
- **`deployment-pipelines-authoring-cli`**: `fabric-cicd` covers deployment pipelines with one table row. The upstream bullet lists many limits (300-item cap, one deploy per pipeline, `Pipeline.Deploy` scope, `lastDeploymentTime` semantics). Not drilled, per the rule for this bucket.
  - Source: skills-for-fabric / 0.3.11 Added
- **`eventschemaset-cli`**: already queued as `docs/handoffs/execute/fabric-event-schema-set.md` (`5bded54`, today). No action.
  - Source: skills-for-fabric / 0.3.12 Changed

## MCP / tooling / CLI additions

- **Hosted Power BI modeling MCP**: upstream's `.mcp.json` at `65902bae` has `powerbi-modeling-mcp` as `http` at `https://api.fabric.microsoft.com/v1/mcp/powerbi/authoring`. Learn documents only the query server at `/v1/mcp/powerbi`, which is already `powerbi-remote-mcp` in the VS Code template.
  - Reference: endpoint TBD — verify before template add
  - Proposed action: `.vscode/mcp.template.json`, once Learn confirms it
- **Remote Power BI MCP with external clients**: Learn documents registering the remote server in external clients with a pre-registered Entra app, and names Claude Desktop. That could undercut drift-audit's Phase 2 rule that Fabric-hosted `/v1/mcp/*` servers don't work from Claude Code because dynamic OAuth client registration is unsupported.
  - Reference: https://learn.microsoft.com/power-bi/developer/mcp/remote-mcp-server-external-clients
  - Proposed action: flag. Check whether Claude Code accepts a pre-registered OAuth client before changing the rule.
- **`tools` key in `mcpServers`**: upstream 0.3.11 says Claude Code rejects a per-server `tools` key. Our templates don't use one (grepped today).
  - Reference: 0.3.11 Fixed
  - Proposed action: flag. No change needed today.
- **How upstream keeps its catalog routable** (0.3.14; the budget check is visible only in the `af9aff33` history):
  - Descriptions now name the neighbouring skill that owns adjacent work. They are about 40% shorter, capped at 450 characters, with about 3,850 characters of headroom in the startup listing.
  - Skills past the listing budget are "known only by name".
  - Literal tokens a user types were restored to descriptions.
  - References to skills that had been merged away were fixed.
  - A catalog-total startup-metadata ratchet check was added.
  - Our equivalents: `lint-frontmatter.py` caps each skill but has no catalog-total check, and nothing checks cross-skill references. `fabric-database`'s description never claims plain querying, which is exactly the failure upstream fixed in `sqldb-cli`.
  - Reference: 0.3.14 Changed/Fixed
  - Proposed action: flag

## No-op

- Eight clause-1 hits that already have a registered counterpart: `git-integration-operations-cli`, `fabriciq-ontology-cli`, `eventstream-cli`, `eventhouse-cli`, `sqldb-cli`, `variable-library-cli`, `sqldw-cli`, `spark-cli`. These are consolidation renames with no behavioural claim.
- Migration skills: 12 `synapse-migration` and 5 `databricks-migration` bullets.
- Plugin bundles, installation, the `check-updates` removal and the Cowork marketplace fix.
- `sqldw-cli` wording and diagnostics changes: pressure intervals, the `bigint` widening (our sample never uses `SUM`), follow-up phrasing.
- Prep-for-AI preservation during edits: already covered by `fabric-tmdl-api`'s rule that `updateDefinition` must include every part.
- `spark-consumption-cli` switching from `sqlcmd` to the MCP route.
- Removal bullets for merged skills.
- `9d5fe403`'s scrubs of older sections: test and build references only, no claim changed.
- Vendored pair: zero clause-2 hits, unchanged since `b8d541c`.

## Recommended actions

1. **fabric-warehouse-monitoring**: fix the Result Set Caching section (feature disabled; `2/1/0` encoding) and `REFERENCE.md:29`.
2. **fabric-warehouse-monitoring**: fix `REFERENCE.md:36` (Operation Id no longer maps to `distributed_statement_id`) and add correlation by interval start/end times.
3. **fabric-eventstream**: add resume/`startType` and the caveat that CI/CD resets pause state.
4. **fabric-mlv**: add execution definitions and `executionData`, without the unconfirmed job-type claim.
5. **fabric-git-serialization rule**: measure a real notebook export's final newline before any edit, then decide between `-text` and `eol=lf` per item type.
6. **fabric-semantic-model-ai-instructions**: add the rule that Git-deployed LSDL changes need a refresh.
7. **drift-audit registry, `skills-for-fabric` entry**: correct it.
   - Replace "HEAD once, prepend-only assumed" with per-commit patches isolated by file pagination. `9d5fe403` edited sections 0.3.10, 0.3.6 and 0.3.5.
   - Record that the path-filtered list shows the release-branch commit, which can predate the merge to main (v0.3.15: 09-04 commit, 09-06 merge).
   - Add the tree-SHA check for the vendored pair.
   - Add `fabric-mlv` and `fabric-semantic-model-ai-instructions` to the counterpart table.
   - Decide whether renames should count under clause 1.
   - Note that 0.3.12's "Update Check blockquote stripped from every SKILL.md" plausibly explains the vendored change the registry calls unbulleted (unverified).
   - Mark step 5 as passed.
   - Add `microsoft_docs_search` to `allowed-tools`: the bullets carry no links, so drilling needs search.
8. **New-skill candidates**: decide on `onelake-catalog-govern-cli`, Activator, Dataflows and deployment pipelines; each accepted one goes through `/author-skill`.
9. **Catalog checks**: consider a catalog-total listing-budget check and a cross-skill reference lint, and check whether "query my SQL database" routes to `fabric-database` or `fabric-warehouse`.
10. **MCP**: confirm `/v1/mcp/powerbi/authoring` on Learn before adding it to the template, and check Claude Code's pre-registered OAuth support before revisiting the placement rule.

## Next run

Pass one of these as the prior reference next time:

- skills-for-fabric head: `65902bae` (2026-09-04). main is at `74f3262c` (2026-09-06), the merge of the same release.
- Or a single date: `2026-09-05`, rather than today. A release commit dated before the floor but merged after it would otherwise be missed; v0.3.15 was merged two days after its commit.

A SHA from any registered source's repo, or any ISO date, is accepted.
