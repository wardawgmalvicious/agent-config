---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-01
---

# Handoff: Cosmos DB in Fabric (`CosmosDBDatabase`) needs a skill

- **Written**: 2026-10-01, from one inbox note of 2026-09-30, extended
  2026-10-01, by a session in a client Fabric Git-sync sandbox repo whose
  workspace holds a Cosmos DB database loaded with the portal's sample
  data. Re-measured against the payload at `4f473d2`: `cosmos` still hits
  only mirrored Azure Cosmos DB, the Eventstream CDC source,
  supported-item lists and the MCP README. Three of the note's small
  edits landed beside this brief: fabric-cicd's three Cosmos rules,
  fabric-auth's audience row and fabric-mirroring's native-item line.
- **Kind**: an edit, by `/author-skill`:
  `skills/fabric/fabric-cosmos-db/`, `paths: "**/*.CosmosDBDatabase/**"`.
  Nothing is drafted.

Labels: **documented** is Learn (`learn.microsoft.com/fabric/database/
cosmos-db/` unless another root is given) or the fabric-cicd docs, read
by the note's session on 2026-09-30 or 2026-10-01; **observed** is that
session in the portal, the repo, REST from a workstation, or the
Capacity Metrics app; **inferred** means what it says.

## Why its own skill

It is the Azure Cosmos DB for NoSQL engine inside Fabric, and the deltas
are what an agent gets wrong. `fabric-database` is SQL only, by its
description and its `**/*.SQLDatabase/**/*.sql` glob, and two engines in
one skill would blur its trigger. Git integration and deployment
pipelines both list "Cosmos database" as preview (documented).

## Where Azure habits are wrong (documented: `overview`, `faq`, `limitations`)

| Azure habit | In Fabric |
| --- | --- |
| Account key or connection string | Entra ID only, no keys |
| Manual, serverless or autoscale throughput | Autoscale only; an SDK create without it fails *"Offer Type is restricted to Autoscale for your account."* |
| Any throughput | 1,000–50,000 RU/s maximum, more by ticket; portal-made containers get 5,000; the portal cannot change it, the SDK can, and so can a Git Update (observed, below) |
| .NET SDK default Direct mode | Gateway mode only, set explicitly (`how-to-authenticate`, C#) |
| `DefaultAzureCredential` in a notebook | A custom `TokenCredential` over `notebookutils.credentials.getToken("https://cosmos.azure.com/")` (`how-to-authenticate-notebooks`) |
| Stored procedures, triggers, UDFs | Not supported |
| Analytical store, Synapse Link | Automatic OneLake mirror, nothing to configure (`mirror-onelake`) |
| Multi-region, CMK, Private Link, rename | None; 25 containers per database, more by ticket |
| Any Fabric region | Not India West, Qatar Central, UAE Central, Austria East, Chile Central, South Central US |
| Vector `float16` (Azure's `vector-search` lists it) | Not supported: `float32`, `int8`, `uint8`. The portal offers `float16`, and saving it fails "Workload Error Code Unknown" (observed) |

Not the same item: **Mirrored Azure Cosmos DB** copies an Azure account
and needs 7- or 30-day continuous backup there; `fabric-mirroring` owns
it.

## The definition

Documented (REST `cosmosdb-database-definition`): `definition.json`
(required) and `.platform`. `definition.json` is `{$schema,
containers[]}`; each container is `options.autoscaleSettings.
maxThroughput` plus `resource`, the Azure container resource object
(`id`, `partitionKey`, `indexingPolicy`, `defaultTtl`, `uniqueKeyPolicy`,
`conflictResolutionPolicy`, `computedProperties`, `geospatialConfig`,
`vectorEmbeddingPolicy`, `fullTextPolicy`). `MultiHash` takes up to three
key paths; the key is immutable.

Observed in the portal's serialization (schema
`…/fabric/item/CosmosDB/definition/CosmosDB/2.0.0/schema.json`): settings
only, no items, endpoint or connection, and no identifier beyond
`.platform`'s `logicalId`. LF, no final newline. `resource` keys come out
`id` first, then alphabetical; nested objects keep a fixed order; an
unset property is omitted, never `null`; containers sort by `id`,
ignoring case (one export, inferred). A container made with **+ New
container** carries empty `fullTextPolicy` (`en-US`) and
`vectorEmbeddingPolicy` blocks the sample loader's container lacks. A
fixture can be rebuilt from Microsoft's sample container: key
`/categoryName`, `Hash` version 2, `maxThroughput` 5000, `/*` included
and `/"_etag"/?` excluded, `Consistent` indexing.

The REST page disagrees with the portal (observed): its example keys on
`/category`, a property no sample item has; it marks
`partitionKey.systemKey` required, which nothing writes; it lists
`IndexingMode` lowercase; its `VectorIndex` names `types` where the
portal writes `type`, omits `quantizerType`, marks
`quantizationByteSize` and `vectorIndexShardKey` required, and gives
ranges that differ from `indexing-policies` (byte size minimum 1, read
2026-10-01) and Azure's tips page (search list 10–500).

## How a change crosses between portal and Git (observed, seven workspace commits, 2026-09-30 and 2026-10-01)

- **Portal to Git.** Container settings save from the ribbon's **Save**;
  an unsaved edit is simply absent. A vector path adds a `/<path>/*`
  exclusion, which removing the path leaves behind. The portal pins
  `quantizationByteSize` 128 on a `product` index the user didn't size,
  where Learn's default is dynamic: a deploy then carries it everywhere
  (inferred). `flat` took its documented 505-dimension maximum; `int8`
  saved where `float16` failed on the same path.
- **Git to the workspace, on Update.** `maxThroughput` applied to two
  live containers, which the portal can't set (as far as the next export
  shows). A container only git defines was created, empty, with its
  settings. A container dropped from git was **not** deleted, and the
  next commit from a workspace that still has it puts it back in git:
  retiring one takes a deletion in each workspace.
- **A partition-key change fails the Update**: "Workload Error Code
  ContainerOperationFailure", naming the container, not the setting. The
  workspace could not commit until the change was reverted in git, as
  Learn's `partial-update` says; the container's settings were left as
  they were.
- **`Git_HeadNotSynced`**: here a branch four single-parent commits ahead
  with no net item change hid **Update all** and blocked nothing. That
  data point landed in fabric-gotchas' row on 2026-10-01.

## The OneLake copy and its SQL analytics endpoint

Documented: Delta, no setup; nested objects arrive as JSON strings; a
later property becomes a column, a missing one NULL; TTL expiry
propagates; items cap at 2 MB. Observed from `INFORMATION_SCHEMA`:

- Address `[<db>].[<db>].[<container>]`, schema named for the item, no
  `dbo`; `tutorial-mirroring`'s `[dbo].[SampleData]` fails.
- Strings, ISO dates and arrays of objects are `varchar(max)` (the last
  JSON text, for `OPENJSON`); every number is `float`, whole ones too;
  `_ts` is `bigint`; `_etag`, `_self`, `_attachments` are not copied.
- No truncation: a 10,000-character string read back whole, so the
  `faq`'s 8 KB truncation is stale for a table made after 2025-11-18.
- One container is one table, the union of every document type: split it
  into views by a type property and cast before modelling (inferred).

## Throughput and cost

Documented (`billing-usage`, `autoscale-throughput`): autoscale never
drops below 10% of its maximum, each hour bills its peak, 100 RU/s =
0.067 CU. So an idle portal-made container (5,000 maximum) holds 500 RU/s,
about 1,206 CU(s) an hour (inferred), unlike items whose compute runs only
when used.

Observed, unexplained (2026-10-01, F16): the Capacity Metrics app showed
the item only as OneLake transactions, 342.5 CU(s) under the old
"via Proxy" / "via Redirect" names, with listings 71% of it, and **no
Cosmos DB compute** at all, though the floor above predicts some 45
times that. No filter hid it; the app's version wasn't recorded and is
the next suspect. Learn's OneLake pages say those names merged in May
2026, so the app or its feed may be stale (inferred).

## Connecting, and links from other items

- Fabric's `GET …/cosmosDbDatabases` returns `properties.serverFqdn`, a
  URL `https://<item-id>.z<xy>.sql.cosmos.fabric.microsoft.com` (one item
  seen), against the REST reference's bare sample; `databaseName` is the
  display name (observed).
- The data plane is the Azure Cosmos DB REST API. A token from `az
  account get-access-token --resource https://cosmos.azure.com`, sent as
  `type=aad&ver=1.0&sig=<token>`, listed, queried and read items at 1.3–5.6
  RU a request; its `aud` is Cosmos DB's app ID, not the URL. Another
  audience fails 401 "…accepts tokens intended for []", which names no
  fix (observed).
- Over REST, a cross-partition `COUNT` or `TOP` fails 400 "…can not be
  directly served by the gateway", even with one key range; scoped by
  partition key or key-range id it runs. SDKs hide this (observed).
- Learn's notebook credential sample fails as printed: `Optional` and
  `Any` unimported, and `endpoint` used where `COSMOS_ENDPOINT` is defined
  (inferred from reading).
- A UDF connects through a generic connection and `get_cosmos_client`;
  the page spells the audience `CosmosDb` and `CosmosDB` (documented,
  unverified which works). The Spark connector `cosmos.oltp` reads,
  writes and creates live containers.
- A link to this item is an endpoint plus a database name, so it doesn't
  survive a move without rebinding (inferred).

## Authorization

Documented (`authorization`): Read, ReadAll (adds the OneLake files) and
Write; Viewer gets Read and ReadAll. Untested conflict: `limitations`
says item permissions apply to every Cosmos DB item in the workspace,
`mirroring-limitations` that they aren't supported.

## Learn conflicts, for the skill's caveats

Besides the REST page's defects above: the `time-to-live` page's bullet
that `-1` disables expiry holds for an item's `ttl`, not a container's;
`how-to-monitor` doesn't mark the metrics the portal labels deprecated;
vector paths are immutable on four pages and mutable on two, and were
added, removed and re-added in place (observed); Azure's REST query page
says only the master key works, yet an `aad` token did, and its
`{"@id": …}` parameter example fails 400 against its own table's
`name`/`value` form (observed); and the sample data itself differs from
the `sample-data` page (180 products, 652 reviews, `countryOfOrigin` on
every product, observed).

## For the skill to carry once it exists

- `fabric-database` § See also: not Cosmos DB in Fabric; see this skill.
- `fabric-gotchas` rows pointing here: "Offer Type is restricted to
  Autoscale for your account." (documented); "Workload Error Code
  Unknown" saving a `float16` vector path (observed); "Workload Error
  Code ContainerOperationFailure" from a Git Update that changes a
  partition key (observed); and the 401 "…accepts tokens intended for
  []", pointing at fabric-auth's row.
- Trigger vocabulary: Cosmos DB in Fabric, `CosmosDBDatabase`, NoSQL
  database, container, partition key, RU/s, autoscale, `maxThroughput`,
  `ContainerOperationFailure`, `cosmos.fabric.microsoft.com`, Gateway
  mode, Cosmos DB SQL analytics endpoint, `OPENJSON`, vector / full-text
  / hybrid search.

## Where it lands

`skills/fabric/fabric-cosmos-db/SKILL.md` and its `references/`, a
`skills/README.md` row, fixtures and `expected_activations.md` rows via
`/test-skill`.

## Not checked

Whether fabric-cicd or deployment pipelines behave as the Git Update did
(inferred); the `/.default` scope form; why Capacity Metrics shows no
compute; whether a container keeps its items through a failed Update;
the Azure agent kit Learn names (`AzureCosmosDB/cosmosdb-agent-kit`),
unread and Azure-framed.

## Scrubbing

The source was raw. Item, database and workspace names are left out,
and the sandbox's commit SHAs too; container and property names are
Microsoft's public sample data.

## Re-measure before acting

- `grep -rli cosmos skills/`: on 2026-10-01, the files above plus
  fabric-cicd, fabric-auth and fabric-mirroring's new line.
- Learn's Cosmos DB in Fabric `faq` and `limitations` before encoding
  the deltas table, which preview churn can move.
