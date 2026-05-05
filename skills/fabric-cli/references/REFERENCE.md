# MS Learn link bundle — Fabric CLI (`fab`)

Curated set of Microsoft Learn pages and canonical GitHub Pages references for the Fabric CLI (`fab` — `pip install ms-fabric-cli`). Covers the CLI itself plus the underlying REST APIs it wraps, since most `fab api` workflows benefit from understanding the REST surface.

The 3 highest-leverage entry points (CLI Learn intro, canonical GitHub Pages docs, item management overview) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

**Note on docs split:** The Microsoft Learn coverage of `fab` is light — primarily the install/login walkthrough. The full per-command reference (every verb, flag, output schema) lives on the GitHub Pages site at `microsoft.github.io/fabric-cli/`, maintained by the CLI team. Both are linked below.

## Concept and getting started

- [Fabric command line interface (Microsoft Learn)](https://learn.microsoft.com/rest/api/fabric/articles/fabric-command-line-interface) — install (`pip install ms-fabric-cli`), `fab auth login` flow variants (interactive, SPN secret, SPN cert, managed identity), basic command invocation, `--help` discovery.
- [Fabric CLI documentation site (GitHub Pages — canonical reference)](https://microsoft.github.io/fabric-cli/) — full per-command reference: every `fab <verb>`, flags, JMESPath query support, `fab api` audience routing. Treat this as the authoritative source.
- [fabric-cli GitHub repository](https://github.com/microsoft/fabric-cli) — source code, issue tracker, release notes. Useful when reporting bugs or checking unreleased features.

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

- [Tutorial: CI/CD for Microsoft Fabric using Azure DevOps + fabric-cicd Python package](https://learn.microsoft.com/fabric/cicd/tutorial-fabric-cicd-azure-devops) — end-to-end SPN-authenticated deployment from Azure DevOps using the `fabric-cicd` Python helper. Complementary to `fab` for higher-level item-publish workflows.
- [Automate Fabric deployment pipelines via APIs](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/pipeline-automation-fabric) — PowerShell samples for deployment-pipeline automation that you can equally invoke through `fab api -A powerbi pipelines/...`.
