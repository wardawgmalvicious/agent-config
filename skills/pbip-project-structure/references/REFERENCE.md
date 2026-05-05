# MS Learn link bundle — PBIP project structure

Curated set of Microsoft Learn pages relevant to Power BI Project (PBIP) folder structure — the canonical Microsoft documentation for `.pbip` / `.pbir` / `.pbism` / `.platform` files, the SemanticModel and Report folders, the byPath vs byConnection thick-vs-thin distinction, PBIX → PBIP conversion, Git integration, and the Fabric REST item-definition envelope that mirrors the on-disk structure.

The 3 highest-leverage entry points (PBIP overview, model authoring, Fabric Git integration) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note:** This skill is one of the better-aligned PBIR-family skills with MS Learn coverage — Microsoft documents the PBIP project format directly under `learn.microsoft.com/power-bi/developer/projects/`. The parent skill adds details on PBIX internal extraction (UTF-16LE vs UTF-8 file mix, OPC ZIP layout) and the rename-cascade that the official docs gloss over.

## Power BI Project (PBIP) — the canonical reference

- [Power BI Desktop project (PBIP) overview](https://learn.microsoft.com/power-bi/developer/projects/projects-overview) — start here. Concept, when to use PBIP vs PBIX, model authoring vs report authoring, what's git-friendly vs not.
- [Power BI Desktop project — semantic model folder](https://learn.microsoft.com/power-bi/developer/projects/projects-dataset) — `definition.pbism`, the `definition/` folder (TMDL) vs `model.bim` (TMSL), `diagramLayout.json`, the `unappliedChanges.json` git-tracking choice, version → format mapping (1.0 = TMSL only; 4.0+ = TMSL or TMDL).
- [Power BI Desktop project — report folder](https://learn.microsoft.com/power-bi/developer/projects/projects-report) — `definition.pbir`, the `definition/` folder (PBIR JSON) vs `report.json` legacy, `pages/`, `visuals/`, `bookmarks/`, `StaticResources/`. Pairs with every `pbir-*` skill.
- [Save Power BI Desktop file as a PBIP project](https://learn.microsoft.com/power-bi/developer/projects/projects-save-as-pbip) — File → Save As workflow.
- [Model authoring in Power BI Desktop projects](https://learn.microsoft.com/power-bi/developer/projects/projects-overview#model-authoring) — TMDL view, external-tool integration unique to PBIP.

## Entry-point file shapes

- [.pbip file format](https://learn.microsoft.com/power-bi/developer/projects/projects-overview#pbip) — `version`, `artifacts[].report.path`, `settings.enableAutoRecovery`. The optional top-level wrapper.
- [.pbir definitionProperties schema (developer.microsoft.com)](https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json) — canonical schema for `definition.pbir`, including `byPath` / `byConnection` shapes the parent skill documents.
- [.pbism definitionProperties schema (developer.microsoft.com)](https://developer.microsoft.com/json-schemas/fabric/item/semanticModel/definitionProperties/1.0.0/schema.json) — canonical schema for `definition.pbism`.
- [.platform schema (developer.microsoft.com)](https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json) — canonical schema for `.platform`.

## Direct Lake / live editing in Desktop (PBIP-specific)

- [Direct Lake in Power BI Desktop](https://learn.microsoft.com/fabric/fundamentals/direct-lake-power-bi-desktop) — PBIP + remote semantic model live-editing model, when local thick model can vs can't be saved.
- [Remote modeling with PBIP](https://learn.microsoft.com/fabric/fundamentals/direct-lake-power-bi-project) — Direct Lake-aware PBIP authoring; what's saved locally vs what stays in the workspace.

## Fabric Git integration (where PBIP lives in source control)

- [Introduction to Fabric Git integration](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration) — concept, supported items, what a workspace Git connection is.
- [Source code format in Git integration](https://learn.microsoft.com/fabric/cicd/git-integration/source-code-format) — repo layout, automatically-generated system files (`.platform`, `cache.abf`, `localSettings.json`), what *not* to commit. Confirms the parent skill's `cache.abf` / `unappliedChanges.json` git-ignore guidance.
- [Connect a workspace to a Git repo](https://learn.microsoft.com/fabric/cicd/git-integration/git-get-started) — wiring up Git → workspace.
- [Sync changes between Git and workspace](https://learn.microsoft.com/fabric/cicd/git-integration/git-integration-process) — pull/commit semantics.

## REST envelope (Fabric Items API)

- [Item definition overview (Fabric REST)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview) — definition-based APIs (`Get/Update/Create with Definition`), the `.platform` rules (only respected on Update with `?updateMetadata=true`).
- [Report definition (REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/report-definition) — exact `definition/` part shape that mirrors the on-disk Report folder.
- [SemanticModel definition (REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition) — `definition.pbism`, `definition/` (TMDL) vs `model.bim` (TMSL), `diagramLayout.json`.

## TMDL (the language inside the SemanticModel `definition/` folder)

- [TMDL overview](https://learn.microsoft.com/analysis-services/tmdl/tmdl-overview) — language, indentation, expressions, `///` comments. See `fabric-tmdl` skill for authoring rules.
- [Get started with TMDL](https://learn.microsoft.com/analysis-services/tmdl/tmdl-how-to) — TmdlSerializer API.

## PBIX format (for the parent skill's "extract a PBIX" section)

- [Power BI Desktop file (.pbix) format](https://learn.microsoft.com/power-bi/transform-model/desktop-import-pbix-files) — high-level concept of the OPC ZIP container.
- (No first-party MS Learn doc covers the internal `Version`/`Settings`/`Metadata`/`Connections`/`DataModel`/`SecurityBindings` structure. The parent skill's encoding table is the authoritative reference for that.)

## Forking, ALM, deployment pipelines

- [Deployment pipelines overview](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines) — Dev / Test / Prod stage management, the workspace deployment flow that downstream of `pbir publish`.
- [ALM Toolkit (third-party)](http://alm-toolkit.com/) — schema-compare for semantic models. Referenced from MS Learn external-tools docs.

## See also (this repo)

- `pbir-cli` — CLI that reads/writes the project
- `pbir-report-workflow` — end-to-end report build using the project
- All `pbir-*` skills — JSON shapes inside `Report.Report/definition/`
- `fabric-tmdl` — TMDL authoring rules inside `SemanticModel/definition/`
- `fabric-tmdl-api` — Fabric REST envelope for `getDefinition` / `updateDefinition`
- `pbid-tom-live` — when you need to script the live model in Desktop instead of editing files
