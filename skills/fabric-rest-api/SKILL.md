---
name: fabric-rest-api
description: "Use for Microsoft Fabric REST API patterns: listing and paginating workspaces/items with continuationToken/continuationUri, calling /v1/workspaces/{wsId}/items, handling long-running operations (202 Accepted, Location header, polling /v1/operations/{id}, Retry-After, /result), the runtime item ID vs .platform logicalId distinction (PowerBIEntityNotFound root cause), the 201-or-202 create pattern, jobType values for /jobs/instances (RunNotebook, Pipeline, SparkJob, Refresh — NOT DefaultJob), the `definition` envelope and `?updateMetadata=true` `.platform` flag, job scheduling (Daily/Weekly/Monthly), 429 rate limiting with Retry-After, and capacity assignment."
---

# Fabric REST API patterns

Base URL: `https://api.fabric.microsoft.com/v1`

## Finding Workspaces and Items

1. List workspaces: `GET /v1/workspaces` → paginate with `continuationToken`
2. Find by name: iterate results until `displayName` matches
3. List items in workspace: `GET /v1/workspaces/{wsId}/items?type={ItemType}`
4. Type-specific endpoints return extra `properties` (connection strings, etc.):
   `GET /v1/workspaces/{wsId}/{lakehouses|warehouses|notebooks|semanticModels|...}`

## Item IDs: Runtime vs logicalId

Every Fabric item has **two** GUIDs, and they are NOT interchangeable. Using the wrong one is a leading cause of `PowerBIEntityNotFound` / `EntityNotFound` errors when referencing items by ID from a pipeline, notebook parameter, REST call, or Variable Library variable.

| Identifier | Source | Resolved by | Use for |
|---|---|---|---|
| **Runtime item ID** | Fabric portal URL (`…/items/{guid}`); `GET /v1/workspaces/{wsId}/items` response `id` | The Fabric engine at execution time | Pipeline activity `notebookId` / `pipelineId`, Variable Library values consumed at runtime, REST `/items/{id}` calls, `notebookutils.runtime.context` lookups |
| **logicalId** | `.platform` file → `config.logicalId` | Git integration / source-control tooling | `.platform` payloads, PBIP + pbir-cli + `fab import` source-control operations |

The two values can look visually similar — Git integration sometimes derives one as a byte-swapped permutation of the other (segments reshuffled) — but Fabric will NOT silently fall back from one to the other at runtime.

**Rule of thumb:** if the value ends up in a payload the Fabric engine reads (pipeline definition, Variable Library value, REST body), use the **runtime item ID**. If it ends up in a file the Git integration layer reads (`.platform`, PBIP manifest), use the **logicalId**.

To fetch the runtime ID:
- Portal: open the item, copy the trailing GUID from the URL
- REST: `GET /v1/workspaces/{wsId}/items` → find by `displayName`, return `id`
- `fab` CLI: `fab get "Workspace.Workspace/Item.ItemType" -q id`

**Variable Library specifically:** variable string values are passed **verbatim** to consumers — they are NOT resolved against `.platform` logicalIds. Always store the runtime item ID.

## Long-Running Operations (LRO)

Many mutating calls return `202 Accepted` with `Location` and `x-ms-operation-id` headers.

- Poll: `GET /v1/operations/{operationId}` → `status: Running|Succeeded|Failed`
- Get result: `GET /v1/operations/{operationId}/result` (after Succeeded)
- Honor `Retry-After` header. Use exponential backoff if absent.

**Item creation is 201-OR-202, not "always sync" or "always LRO"** — the same endpoint can return either depending on current provisioning load. Always branch on status code; never assume sync. A function that only inspects the body on 2xx will silently return before the item is queryable whenever Fabric picks the LRO path, racing any immediately-downstream call that expects the new item to exist.

Canonical `create_*` pattern for Fabric item creation:

```python
def create_item(access_token: str, item_name: str, ...) -> str:
    """Return the newly-created item's GUID. Handles 201 and 202."""
    workspace_id = notebookutils.runtime.context["currentWorkspaceId"]
    endpoint = f"https://api.fabric.microsoft.com/v1/workspaces/{workspace_id}/<items_path>"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }
    body = {"displayName": item_name}

    response = requests.post(endpoint, headers=headers, json=body)

    if response.status_code == 201:
        # Synchronous creation — the body is the created item
        item_id = response.json()["id"]
    elif response.status_code == 202:
        # LRO — poll to completion, then fetch /result for the item body
        result_response = poll_lro(response, headers, return_result=True)
        item_id = result_response.json()["id"]
    else:
        response.raise_for_status()

    return item_id
```

The `poll_lro` helper honors `Retry-After`, polls `Location` until the operation reaches `Succeeded`, and (with `return_result=True`) fetches `/result` to return the actual created-item body.

## Definition APIs

Item types with content (Notebook, SemanticModel, Report, DataPipeline) accept a `definition` object containing `format`, `parts`, and base64-encoded payloads.

```
PATCH /v1/workspaces/{wsId}/items/{itemId}/definition[?updateMetadata=true]
```

- **`?updateMetadata=true` controls whether `.platform` is honored.** Without it, any `.platform` part in `definition.parts` is silently ignored — `displayName`/`description` won't update.
- Conversely, setting `?updateMetadata=true` *requires* a `.platform` part. The flag without `.platform` returns 400.
- For content-only updates (typical), omit the flag.
- Notebook-specific alternative: `POST /v1/workspaces/{wsId}/notebooks/{id}/updateDefinition` — same body shape.
- `getDefinition` is a POST with empty body (`'{}'`) — bare POST returns HTTP 411 Length Required. Result is fetched via the LRO's `{Location}/result` URL (note the `/result` suffix).
- Per-item-type specifics live in `fabric-tmdl-api` (semantic models), `fabric-spark` (notebooks, SparkJobDefinition, Environment, Lakehouse shortcuts), `fabric-eventhouse` (Eventhouse, KQLDatabase), `fabric-variable-library` (VariableLibrary), and pbir-cli/pbir-report-workflow (Report).

### Support matrix

| Item Type | Formats | Main parts |
|---|---|---|
| Notebook | `ipynb` (default), `FabricGitSource` | `notebook-content.ipynb` or `.py`/`.sql`/`.scala`/`.r` |
| DataPipeline | *(default)* | `pipeline-content.json` |
| SemanticModel | `TMSL`, `TMDL` (prefer) | `definition/database.tmdl`, `model.tmdl`, `tables/*.tmdl`, `definition.pbism` |
| Report | `PBIR-Legacy`, `PBIR` (prefer) | `definition/report.json`, `version.json`, `pages/*`, `definition.pbir` |
| Lakehouse | `LakehouseDefinitionV1` | `lakehouse.metadata.json` (+ optional `shortcuts.metadata.json`) |
| SparkJobDefinition | `SparkJobDefinitionV1`, `SparkJobDefinitionV2` | `SparkJobDefinitionV1.json` (+ `Main/`, `Libs/` for V2) |
| Environment | *(default — set `null`)* | `Libraries/PublicLibraries/environment.yml`, `Setting/Sparkcompute.yml` |
| VariableLibrary | **omit `format` entirely** | `variables.json`, `settings.json`, `valueSets/<name>.json` |
| Eventhouse | `JSON` | `EventhouseProperties.json` |
| KQLDatabase | `JSON` | `DatabaseProperties.json` (+ optional `DatabaseSchema.kql`) |
| Other (KQLDashboard, CopyJob, Dataflow, Eventstream, MirroredDatabase, GraphQLApi, etc.) | varies | see [MS schema index](https://github.com/microsoft/json-schemas/tree/main/fabric/item) |

**`definition.pbir` `byConnection` only**: Fabric REST API supports only `byConnection` semantic-model references in PBIR. The `byPath` form (used locally with pbir-cli) is not accepted by the Fabric REST endpoints — switch to `byConnection` before deploying.

## Job Execution

```
POST /v1/workspaces/{wsId}/items/{itemId}/jobs/instances?jobType={jobType}
```

| Item Type | jobType |
|---|---|
| Notebook | `RunNotebook` |
| DataPipeline | `Pipeline` |
| SparkJobDefinition | `SparkJob` |
| SemanticModel | `Refresh` |

**Gotcha**: `DefaultJob` does NOT work for most item types. Use the type-specific value above.

## Job Scheduling

```
POST /v1/workspaces/{wsId}/items/{itemId}/jobs/{jobType}/schedules
```

URL path is `/jobs/{jobType}/schedules` — NOT `/jobs/instances/schedules`. Body:

```json
{
  "enabled": true,
  "configuration": {
    "startDateTime": "2026-01-01T06:00:00.000Z",
    "endDateTime":   "2027-01-01T06:00:00.000Z",
    "type": "Daily",
    "interval": 1,
    "localTimeZoneId": "UTC",
    "times": ["06:00"]
  }
}
```

`enabled`, `configuration.startDateTime`, `configuration.endDateTime`, and `configuration.type` are all required. Omitting `endDateTime` returns 400. `type` ∈ `Daily | Weekly | Monthly`; `Weekly` also requires `weekDays` (array of day names). List with `GET .../schedules`; delete with `DELETE .../schedules/{scheduleId}`.

## Rate Limiting

`429 Too Many Requests` includes a `Retry-After` header (seconds). Honor it; never tight-loop. Use exponential backoff with jitter when `Retry-After` is absent.

| Category | Approximate limit |
|---|---|
| Admin APIs | 200 req/hour per principal per tenant |
| OneLake (ADLS) | Standard Azure Storage throttling, per workspace |
| Warehouse TDS | ~128 concurrent connections (varies by SKU) |

Watch `x-ms-ratelimit-remaining-*` response headers to back off before hitting the limit.

## Capacity

- `GET /v1/capacities` — list available capacities. Filter `state == "Active"`.
- `POST /v1/workspaces/{wsId}/assignToCapacity` with `{ "capacityId": "..." }` — assigns workspace to capacity.
- Lakehouse, Warehouse, Notebook execution, and Spark Job Definitions all require workspace capacity. Without it, item creation returns `FeatureNotAvailable`.
- After assignment, verify `GET /v1/workspaces/{wsId}` shows `capacityAssignmentProgress: "Completed"` before creating capacity-dependent items.

## Pagination

All list APIs use continuation-token pagination. Keep calling with `?continuationToken={value}` until the token is null. The response also includes `continuationUri` — the fully-formed next-page URL — which you can call directly without re-constructing the query string. The token itself is opaque; never modify it.

## Reference

- Microsoft Learn: [Item management overview](https://learn.microsoft.com/rest/api/fabric/articles/item-management/item-management-overview)
- Microsoft Learn: [Long-running operations](https://learn.microsoft.com/rest/api/fabric/articles/long-running-operation)
- Microsoft Learn: [Throttling](https://learn.microsoft.com/rest/api/fabric/articles/throttling)
- Comprehensive MS Learn link bundle (concept / CRUD / LRO / pagination / throttling / jobs / item-specific / workspace / Git+CI/CD / MCP): [references/REFERENCE.md](references/REFERENCE.md)
