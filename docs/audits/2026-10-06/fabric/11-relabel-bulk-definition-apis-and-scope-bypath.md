# Handoff: relabel the bulk definition APIs and scope the byPath claim

- **Audit run**: 2026-10-06
- **Source**: `fabric`
- **Window**: floor `2026-09-01` (diff base `8375c89d`, 2026-08-31) →
  head `7ff5f2b3` (2026-10-02)
- **Covers recommended actions**: 12 and 18
- **Kind**: status relabels and one claim narrowed across five skills,
  plus per-skill minor edits and flags. Content; no behaviour change.
  The REST/CLI/CI-CD surface is shared, which is why one brief holds it.
- **Target**:
  - `skills/fabric/fabric-rest-api/SKILL.md` (lines 162, 164–219) and
    `references/REFERENCE.md` (line 54)
  - `skills/fabric/fabric-gotchas/SKILL.md` (lines 20, 23–24, 41, 50–51,
    54)
  - `skills/fabric/fabric-cicd/SKILL.md` (lines 21–25, 261, 270)
  - `skills/fabric/fabric-cli/SKILL.md` (lines 62, 200)
  - `skills/fabric/fabric-tmdl-api/SKILL.md` (line 15) and
    `references/REFERENCE.md` (line 16)

## Context

Actions 12 and 18 share a brief because the bulk-definition GA and the
`byPath` question touch the same five skills. One re-read of the
bulk-import page verifies both. Each skill's remaining items ride along
as their own D-section.

## D-1 — the bulk definition APIs are GA

**Symptom.** Commit `9eda27f8` (2026-10-02) added "Bulk item definition
APIs (Generally Available)", September 2026, pairing the base preview
row "Bulk import and export items definition (Preview)". The skills
still say:

- `fabric-cicd/SKILL.md:261` — "Single bulk-import API call instead of
  per-item (beta; non-prod)"
- `fabric-cli/SKILL.md:200` — "**Experimental, v1.7+.**"
- `fabric-tmdl-api/references/REFERENCE.md:16` — "[Bulk Import / Bulk
  Export Item Definitions (beta)](https://learn.microsoft.com/rest/api/fabric/core/items/bulk-import-item-definitions%28beta%29)"

**Evidence.** Learn (agent-measured, 2026-10-06):

- `https://learn.microsoft.com/en-us/rest/api/fabric/core/items/bulk-import-item-definitions`
  — "Imports item definitions for multiple items into a workspace in a
  single operation."
- The Items index lists "Bulk Import Item Definitions | Bulk import item
  definitions into the workspace."
- The definitions overview page still says "(beta)".
- The IQ subagent read that SemanticModel is supported and that bulk
  import accepts `.platform` parts.

**Fix.** Relabel the API as GA in all three. Leave the `fabric-cicd`
library's and the `fab` CLI's own flag status as they are unless their
own docs changed; that status is unverified here. Repoint `REF:16` to
the URL without `%28beta%29`. In `fabric-tmdl-api/SKILL.md:15`, scope
"Never include `.platform`" to `updateDefinition`.

## D-2 — "byPath is not accepted" is contradicted for bulk import

**Symptom.** `fabric-rest-api/SKILL.md:162` says "The `byPath` form … is
not accepted by the Fabric REST endpoints", and `fabric-gotchas/SKILL.md:41`
repeats it.

**Evidence.** Learn's Bulk Import example includes a part at
`"path": "/Folder1/Folder2/MyReport.Report/definition.pbir"`. The audit
session fetched the page on 2026-10-06 and base64-decoded its payload:

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json",
  "version": "4.0",
  "datasetReference": {
    "byPath": {
      "path": "../../MyDataset.SemanticModel"
    }
  }
}
```

**Fix.** Narrow both claims to the single-item create and update
endpoints, where they were measured. Note that Learn's bulk-import
example sends `byPath` to a model in the same request, and that this is
unmeasured.

**Constraint.** This is a documentation example, not a probe. Do not
reverse the gotcha; scope it.

## D-3 — Core MCP is GA (`fabric-rest-api`)

`references/REFERENCE.md:54` calls Fabric Core MCP "preview MCP server
exposing Fabric Core API". "Fabric Core MCP Server (Generally
Available)" was promoted in September 2026. The endpoint and scope are
unchanged, per
`https://learn.microsoft.com/en-us/rest/api/fabric/articles/mcp-servers/core-remote/get-started-core`,
checked in the audit session: `https://api.fabric.microsoft.com/v1/mcp/core`,
scope `https://api.fabric.microsoft.com/.default`. Drop "preview".

## D-4 — file-level commit (`fabric-rest-api`)

The Git section, `SKILL.md:164-219`, has no commit call. "File-level Git
commit (Preview)" was added by `9eda27f8`. Learn,
`https://learn.microsoft.com/en-us/rest/api/fabric/core/git/commit-to-git`
(agent-measured): "You can choose to commit all changes, specific items,
or specific files within items using the FileLevelSelective mode." Add
the call, with the mode marked preview. Brief 10 adds the same feature
to the Git rule; keep the names consistent.

## D-5 — `fabric-gotchas` items

- **`SKILL.md:54`** — "`DropObjectsNotInSource = false` is fixed for
  warehouse deploys … Drop it by hand on the target, or accept the
  drift." A post-deployment T-SQL script is now a third path. The source
  is "Warehouse pre/post deployment support (Preview)" and
  `https://learn.microsoft.com/fabric/data-warehouse/deployment-scripts`.
  Learn does not mention table drops specifically, so word it
  accordingly.
- **`SKILL.md:20`** — "Grant role or use SAS in CREDENTIAL". Add
  `CREDENTIAL = (IDENTITY = 'Workspace Identity')`, from "COPY INTO with
  workspace identity (Generally Available)" and
  `https://learn.microsoft.com/fabric/data-warehouse/ingest-data`.
- **`SKILL.md:23-24, 50-51`** — these treat warehouse definition 2.0 as
  settled. Learn,
  `https://learn.microsoft.com/en-us/fabric/data-warehouse/warehouse-system-file-version-history`:
  "This feature is in preview." Flag: add the label; no other change.

## D-6 — `fabric-cicd` items

- **`SKILL.md:21-25`** — the surface table is silent on deployment
  plans. Learn's overview says "The `fabric-cicd` library doesn't
  support deployment plans." Flag: one line.
- **`SKILL.md:270`** — the skill says attached-lakehouse GUIDs need
  parameterization and notebook resources aren't source-controlled.
  Learn,
  `https://learn.microsoft.com/en-us/fabric/cicd/cross-workspace-dependency-binding`,
  disagrees on both:
  - Auto-binding "Requires enabling "Lakehouse Auto-Binding in Git" in
    the notebook settings." and "This setting is off by default." With
    it on, the binding is by logical ID, including through deployment
    pipelines and bulk import.
  - The built-in Resources folder can be committed to Git; it is
    optional and off by default.

  The library's own behaviour is unverified. This came from the
  transient row "Microsoft Fabric CI/CD resources", added by
  `ebc6f751` and deleted by `9eda27f8`.

## D-7 — `fabric-cli` item

**`SKILL.md:62`** scopes `fab find` to "display name / description /
workspace name". "OneLake Catalog table discovery (Preview)" adds table
and column-name search. The Search API reference,
`https://learn.microsoft.com/en-us/rest/api/fabric/core/catalog/search`,
still documents only those three fields, so the extension is blog-only.
Flag: no edit until Learn documents it.

## Sequencing note

Brief 08 makes the same COPY INTO and deployment-script edits in
`fabric-warehouse`. Keep the wording consistent with D-5.

## Constraint on the fix

Out of scope: the same table-discovery flag sits at
`fabric-rest-api/SKILL.md:20`, but no recommended action names it there.
Leave it.

## Verification

1. `grep -rn -i "beta; non-prod\|Experimental, v1.7\|%28beta%29" skills/fabric`
   — no hit left.
2. `grep -rn "byPath" skills/fabric/fabric-rest-api/SKILL.md skills/fabric/fabric-gotchas/SKILL.md`
   — both claims are scoped to the single-item endpoints, and both
   mention the bulk-import example.
3. `grep -n -i "preview MCP" skills/fabric/fabric-rest-api/references/REFERENCE.md`
   — no hit.
4. `uv run --with pyyaml scripts/lint-frontmatter.py` on each of the
   five `SKILL.md` files touched.
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against `fabric`, floor
2026-09-01, by the platform/CI-CD and IQ mapping subagents. The audit
session decoded the bulk-import payload itself (`curl` the page, then
`base64 -d` the `definition.pbir` part) and checked the Core MCP page
itself. The other quotes are the agents'.

## Execution log

- **Executed**: 2026-10-06 — applied with deferrals
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: `skills/fabric/fabric-rest-api/SKILL.md`,
  `skills/fabric/fabric-rest-api/references/REFERENCE.md`,
  `skills/fabric/fabric-gotchas/SKILL.md`,
  `skills/fabric/fabric-cicd/SKILL.md`,
  `skills/fabric/fabric-cli/SKILL.md`,
  `skills/fabric/fabric-tmdl-api/SKILL.md`,
  `skills/fabric/fabric-tmdl-api/references/REFERENCE.md`
- **Verification**: steps 1–4 passed; step 5 runs once at the end of
  the run. Step 1: no hit. Step 2: both `byPath` claims are scoped to
  the single-item endpoints, and both cite the bulk-import example as
  unmeasured. Step 3: no hit. Step 4: lint clean on all five
  `SKILL.md` files; no `description` changed.
- **Learn, read 2026-10-06**: the Bulk Import reference (no beta or
  preview text and no `beta=true` on the URI; SemanticModel and
  `.platform` parts in its example; the `byPath` `definition.pbir` as
  the audit decoded it); Commit To Git (`FileLevelSelective` with
  `itemsWithFileSelection` / `selectedFiles`, scope
  `Workspace.GitCommit.All`; file-level commit is preview per the
  compare-and-commit page); the cross-workspace binding and
  notebook-source-control pages (auto-binding off by default, per
  notebook; the Resources folder committable, but "integration with
  deployment pipelines and public APIs are not currently supported");
  the warehouse system-file release notes ("This feature is in
  preview"); and the deployment-plan pages. D-3's endpoint and scope
  are the audit session's check.
- **Deferred**: D-7 is a flag with no edit. `fab find` (`fabric-cli`
  `SKILL.md:62`) keeps its three search fields until the Catalog Search
  API reference documents table and column search.
- **Deviations**: four. (1) D-1, `fabric-cli`: the brief leaves the
  flag's own status alone while step 1 wants "Experimental, v1.7" gone,
  so the line now says the flag was experimental "when last read"
  beside the GA API. (2) D-1, `fabric-tmdl-api` `REF:16`: Bulk Export
  is named without a link, since only the import page's URL was
  verified. (3) D-6: Learn's note that deployment pipelines and public
  APIs don't carry the notebook Resources folder rode along with the
  Git half, since it bears on the library directly. (4) D-4: the commit
  call sits after the existing "Both calls" bullets, so "both" still
  means Get Status and Update From Git. The workspace-identity and
  deployment-script wording in `fabric-gotchas` follows brief 08's in
  `fabric-warehouse`.
- **Needs**: the next fabric drift audit — D-7: whether the Catalog
  Search API documents table and column search, before `fabric-cli`'s
  `fab find` line changes.
