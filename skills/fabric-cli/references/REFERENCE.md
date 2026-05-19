# MS Learn link bundle — Fabric CLI (`fab`)

Curated set of Microsoft Learn pages and canonical GitHub Pages references for the Fabric CLI (`fab` — `pip install ms-fabric-cli`, Python 3.10 / 3.11 / 3.12 / 3.13). Covers the CLI itself plus the underlying REST APIs it wraps, since most `fab api` workflows benefit from understanding the REST surface.

**Version baseline (verified against the GitHub release notes and local `fab --help`):**

- **v1.5.0 (March 15, 2026 — GA)**: introduces `fab deploy` (wraps the `fabric-cicd` Python library for one-command workspace CI/CD); adds export/import format support for `.SemanticModel` and `.SparkJobDefinition`; ships the `.ai-assets/` folder (context / modes / prompts / skills for Copilot / Claude / Cursor); positions report rebinding (`fab set semanticModelId`) and semantic-model refresh (`fab job run`) as first-class. Note: "REPL mode" in the marketing copy = `fab config set mode interactive`, not a new verb. "AI agent execution layer" = the bundled `.ai-assets/` files, not a CLI subcommand.
- **v1.6.x (April 2026)**: adds `fab find` for OneLake-catalog search across workspaces; promotes VariableLibrary from portal-only to full CRUD via standard verbs; adds `fab rm --hard` permanent delete; adds Map and DigitalTwinBuilder item types; adds Lakehouse export/import (previously metadata-only); CLI-startup perf improvements.
- Python 3.10 / 3.11 / 3.12 / 3.13. Confirm the running install with `fab --version`.

The 3 highest-leverage entry points (CLI Learn intro, canonical GitHub Pages docs, item management overview) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** The Microsoft Learn coverage of `fab` is light — primarily the install/login walkthrough and the What's New release notes. The full per-command reference (every verb, flag, output schema) lives on the GitHub Pages site at `microsoft.github.io/fabric-cli/`, maintained by the CLI team. Both are linked below.

## Concept and getting started

- [Fabric command line interface (Microsoft Learn)](https://learn.microsoft.com/rest/api/fabric/articles/fabric-command-line-interface) — install (`pip install ms-fabric-cli`), Python 3.10+ prerequisite, `fab auth login` flow variants (interactive, SPN secret, SPN cert, managed identity), basic command invocation, `--help` discovery.
- [Fabric CLI documentation site (GitHub Pages — canonical reference)](https://microsoft.github.io/fabric-cli/) — full per-command reference: every `fab <verb>`, flags, JMESPath query support, `fab api` audience routing. Treat this as the authoritative source.
- [fabric-cli GitHub repository](https://github.com/microsoft/fabric-cli) — source code, issue tracker, release notes. Useful when reporting bugs or checking unreleased features.
- [What's new in Microsoft Fabric — March 2026 GA features](https://learn.microsoft.com/fabric/fundamentals/whats-new#generally-available-features) — the marketing-side Fabric CLI v1.5 GA entry. Useful for cross-checking what shipped, but the authoritative per-version changelog is the release-notes feed below.
- [Fabric CLI GitHub releases](https://github.com/microsoft/fabric-cli/releases) — per-version changelogs. The v1.5.0 and v1.6.x notes are the source of truth for what each release actually adds (verb names, flag changes, item-type additions). Fetch with `gh release view <tag> --repo microsoft/fabric-cli` to avoid the bot-gated `blog.fabric.microsoft.com` redirect.
- [`.ai-assets/` in the fabric-cli repo](https://github.com/microsoft/fabric-cli/tree/main/.ai-assets) — the bundled context / modes / prompts / skills files for AI coding assistants that ship as part of v1.5+. This is what "AI agent execution layer" in the marketing copy actually refers to.

## Worked examples

- [Create a SQL database with the Fabric CLI](https://learn.microsoft.com/fabric/database/sql/deploy-cli) — end-to-end `fab create` workflow plus the `fab api` pattern for non-default options (e.g., custom collation via the underlying REST endpoint).

## Underlying REST APIs the CLI wraps

- [Fabric REST API documentation structure](https://learn.microsoft.com/rest/api/fabric/articles/api-structure) — Core APIs vs Workload APIs. When `fab api` doesn't have a higher-level wrapper, you'll be calling these directly with `fab api -A {audience}`.
- [Item management overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/item-management-overview) — what `fab create` / `fab rm` / `fab cp` / `fab mv` / `fab export` / `fab import` map to under the hood.
- [Item definition overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview) — the `definition` envelope shape that `fab export` produces and `fab import` consumes (TMDL parts, PBIR parts, notebook parts, etc.).
- [Long-running operations](https://learn.microsoft.com/rest/api/fabric/articles/long-running-operation) — what `fab` is polling under the hood for create / job-run / definition-update operations.
- [Throttling](https://learn.microsoft.com/rest/api/fabric/articles/throttling) — 429 handling. `fab` does not aggressively retry; honor `Retry-After` in your scripts.
- [Pagination](https://learn.microsoft.com/rest/api/fabric/articles/pagination) — `fab ls` and `fab api` LIST endpoints use this. The CLI handles pagination internally; useful to understand for chained `fab api` patterns.

## Authentication for CLI use

- [App objects and service principals](https://learn.microsoft.com/entra/identity-platform/app-objects-and-service-principals) — concept reference for the SPN auth flow `fab auth login --service-principal` / `--certificate` triggers.
- [Enable service principal for admin APIs](https://learn.microsoft.com/fabric/admin/enable-service-principal-admin-apis) — the tenant setting required before SPN-driven `fab` admin calls work. Without this, `fab api` admin endpoints 403.
- [Automate Git integration with a service principal in Azure DevOps](https://learn.microsoft.com/fabric/cicd/git-integration/automate-git-integration-with-service-principal) — SPN configuration patterns when using `fab` for Git-integrated workspace automation.

## Lakehouse and OneLake operations

- [Manage a lakehouse with the REST API](https://learn.microsoft.com/fabric/data-engineering/lakehouse-api) — backing API for `fab table optimize` / `fab table vacuum` / `fab table load`. Same options exposed (V-Order, Z-Order, retention).
- [Run Delta table maintenance in Lakehouse](https://learn.microsoft.com/fabric/data-engineering/lakehouse-table-maintenance) — UI walkthrough; clarifies the maintenance options `fab table` exposes programmatically.

## CI/CD with `fab` and friends

- [`fab deploy` command reference (GitHub Pages)](https://microsoft.github.io/fabric-cli/commands/fs/deploy/) — v1.5 one-command workspace deploy. `--config <yaml>` required; `--target_env`, `--params`, `--force` optional. Deploys all items / specific folders / specific items based on the config + parameter file. Wraps `fabric-cicd` under the hood, including the `$workspace.$id` and `$items.<Type>.<name>.id` token model.
- [fabric-cicd Python library (microsoft.github.io)](https://microsoft.github.io/fabric-cicd/latest/) — the library `fab deploy` wraps. Useful when reading config files (the same parameter / feature-flag model applies) or when you need finer-grained control than `fab deploy` exposes (e.g., orphan-cleanup, feature flags like `enable_shortcut_publish`).
- [Choose the best Fabric CI/CD workflow option for you](https://learn.microsoft.com/fabric/cicd/manage-deployment) — decision guide across fabric-cicd, Bulk Import Item Definitions API, and Fabric deployment pipelines. Resolves the common confusion about which surface to use.
- [Tutorial: CI/CD for Microsoft Fabric using Azure DevOps + fabric-cicd Python package](https://learn.microsoft.com/fabric/cicd/tutorial-fabric-cicd-azure-devops) — end-to-end SPN-authenticated deployment from Azure DevOps using the `fabric-cicd` Python helper. Same config / parameter file pattern that `fab deploy` consumes — useful for understanding what `--config` expects to find.
- [Automate Fabric deployment pipelines via APIs](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/pipeline-automation-fabric) — PowerShell samples for the *service-side* deployment-pipeline automation (distinct from `fab deploy`) that you can equally invoke through `fab api -A powerbi pipelines/...`.
- [Fabric CLI in Azure DevOps (Preview, March 2026)](https://blog.fabric.microsoft.com/blog/fabric-cli-in-azure-devops-automation-without-friction-preview) — `fab` packaged as a built-in ADO pipeline task; removes the `pip install ms-fabric-cli` setup step from YAML.
