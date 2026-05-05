# MS Learn link bundle — Fabric REST API

Curated set of Microsoft Learn pages relevant to working with the Fabric REST API surface — item CRUD, definitions, long-running operations, pagination, throttling, jobs and scheduler, item-specific endpoints, capacity / workspace / admin, Git integration, deployment pipelines. Load on demand when you need the authoritative spec for a specific endpoint or pattern.

The 3 highest-leverage entry points (item management overview, long-running operations, throttling) are also linked in the parent SKILL.md `## Reference` section for in-context use; this file holds the comprehensive set.

## Concept and getting started

- [Fabric REST API documentation structure](https://learn.microsoft.com/rest/api/fabric/articles/api-structure) — how the reference is organized (Core APIs vs Workload APIs), how to navigate the per-item-type entries.
- [Item management overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/item-management-overview) — what a Fabric item is, the CRUD surface, and the per-experience support matrix (which item types support definition vs payload, service principal, etc.). Authoritative starting point.
- [Fabric API quickstart](https://learn.microsoft.com/rest/api/fabric/articles/get-started/fabric-api-quickstart) — getting an Entra token and calling your first Fabric REST endpoint.

## Core CRUD operations

- [Items — REST API reference](https://learn.microsoft.com/rest/api/fabric/core/items) — the top-level Items API: Create / Get / List / Update / Delete and the definition variants. Pair with the item-definition overview.
- [Item definition overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/item-definition-overview) — the `definition` envelope (`format`, `parts`, base64 payloads), per-item-type formats, and the `?updateMetadata=true` `.platform` rule.

## Pagination, long-running operations, throttling, troubleshooting

- [Pagination](https://learn.microsoft.com/rest/api/fabric/articles/pagination) — `continuationToken` / `continuationUri` patterns, when each is null, opacity rules.
- [Long-running operations](https://learn.microsoft.com/rest/api/fabric/articles/long-running-operation) — the 200/201/202 trichotomy, `Location` / `x-ms-operation-id` / `Retry-After` headers, polling via Get Operation State, retrieving via Get Operation Result. Worked notebook-creation example included.
- [Throttling](https://learn.microsoft.com/rest/api/fabric/articles/throttling) — the 429 rate-limit response, `Retry-After` semantics, per-caller-per-API enforcement model.
- [Troubleshoot Microsoft Fabric REST APIs](https://learn.microsoft.com/rest/api/fabric/articles/get-started/fabric-api-troubleshooting) — common 401 / 403 / 404 / 429 error codes (`TokenExpired`, `InsufficientScopes`, `InsufficientPrivileges`, `WorkspaceNotFound`, `EntityNotFound`, `RequestBlocked`) and resolutions. First stop when an API call fails.

## Job scheduler

- [Job Scheduler — REST API reference](https://learn.microsoft.com/rest/api/fabric/core/job-scheduler) — Run Item Job, Cancel, Get Item Job Instance, schedule CRUD. Authoritative for the `jobType` parameter and schedule body shape.

## Item-specific REST patterns

- [Manage and execute notebooks with REST APIs](https://learn.microsoft.com/fabric/data-engineering/notebook-public-api) — Notebook item CRUD, Run on Demand, definition update, SPN auth. Start here for notebook automation.
- [Pipeline REST API capabilities](https://learn.microsoft.com/fabric/data-factory/pipeline-rest-api-capabilities) — DataPipeline item CRUD, `jobType=Pipeline` runs, getting job instance state.
- [Spark Job Definition REST API tutorial](https://learn.microsoft.com/fabric/data-engineering/spark-job-definition-api) — end-to-end create / upload main file via OneLake / update with file URLs. Two-API dance (Fabric REST + OneLake DFS).
- [SemanticModel definition (REST envelope)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/semantic-model-definition) — TMDL vs TMSL exclusivity, `definition.pbism`, `definition/` folder layout. Pair with `fabric-tmdl-api` skill.
- [Create a SQL database with the REST API](https://learn.microsoft.com/fabric/database/sql/deploy-rest-api) — PowerShell 5.1 and 7.4 worked examples for SQL Database CRUD via Items API.

## Capacity, workspace, and admin

- [Workspaces in Fabric and Power BI](https://learn.microsoft.com/fabric/fundamentals/workspaces) — workspace concept, settings, capacity assignment, identity. Useful for understanding what `assignToCapacity` actually does.
- [Roles in workspaces](https://learn.microsoft.com/fabric/fundamentals/roles-workspaces) — the Admin / Member / Contributor / Viewer matrix. Notebook-API note clarifies which roles can CRUD vs execute via REST.
- [Enable service principal for admin APIs](https://learn.microsoft.com/fabric/admin/enable-service-principal-admin-apis) — tenant-setting requirement for SPN-driven admin API calls. The "Service principals can use Fabric APIs" switch.

## Git integration and CI/CD via REST

- [Git — REST API reference](https://learn.microsoft.com/rest/api/fabric/core/git) — workspace Git connect / commit / update from Git / status, plus update-my-git-credentials for SPN-backed connections.
- [Automate Git integration via APIs](https://learn.microsoft.com/fabric/cicd/git-integration/git-automation) — PowerShell sample patterns (commit, sync, branch operations) using the Git REST endpoints.
- [What is Microsoft Fabric Git integration?](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration) — concept + considerations + commit-size and ADO-specific limits. Read alongside the REST reference.
- [Automate Git integration with a service principal in Azure DevOps](https://learn.microsoft.com/fabric/cicd/git-integration/automate-git-integration-with-service-principal) — SPN-backed Git connections, configured-vs-automatic credentials, the connection-id + Update My Git Credentials flow.
- [Bulk Import Item Definitions API tutorial (CI/CD with Azure DevOps)](https://learn.microsoft.com/fabric/cicd/tutorial-bulkapi-cicd) — end-to-end Azure DevOps pipeline using the bulk-import API to deploy items from Git folders to a target workspace.
- [Get started with deployment pipelines](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/get-started-with-deployment-pipelines) — UI walkthrough; deployment-pipelines REST endpoints follow the same shape (the `fabric-cli` skill shows the `fab api -A powerbi pipelines` patterns).

## MCP server (agent-driven Fabric REST)

- [Fabric Core MCP Server tools reference](https://learn.microsoft.com/rest/api/fabric/articles/mcp-servers/core-remote/tools-core-mcp-server) — preview MCP server exposing Fabric Core API (workspaces, items, folders, capacities, operations) as MCP tools. Useful when wiring Claude or other agents directly to a Fabric tenant.
