---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-01
---

# Handoff: User Data Functions (`UserDataFunction`) need a skill

- **Written**: 2026-10-01, from two inbox notes of 2026-10-01 by sessions
  in a client Fabric Git-sync sandbox repo, one on the item and one on
  `fab` and REST. Re-measured against the payload at `4f473d2`:
  `UserDataFunction` still hits only the serialization rule's glob, a
  LinkedIn suffix list and two activation-test lines. Landed beside this
  brief: fabric-cicd's UDF caveat, fabric-deployment-pipelines' button
  row, the serialization rule's UDF bytes, and fabric-rest-api's
  `FunctionSet` type.
- **Kind**: an edit, by `/author-skill`:
  `skills/fabric/fabric-user-data-functions/`,
  `paths: "**/*.UserDataFunction/**"`, the serialization rule's glob.
  Nothing is drafted. The report side of translytical task flows is a
  second skill, [translytical-task-flow-skill.md](translytical-task-flow-skill.md).

Labels: **documented** is Learn or the fabric-cicd repo, read by the
note's session 2026-09-30 or 2026-10-01, several only as search excerpts
(marked, so fetch before encoding); **observed** is that session in the
portal, the repo, REST or `fab` 1.7.0; **inferred** means what it says.

## Naming the description must cover

Learn says "user data functions item"; Power BI's button pane and the
Warehouse page say **function set** for the item and **data function**
for each `@udf.function()`; `git/status` types it `FunctionSet` and the
pipeline activity holds `functionSetId` (observed); REST, `.platform`
and `fab` say `UserDataFunction`. "UDF" already means Spark and DAX UDFs
in this payload, so the description says "not Spark UDFs, not DAX UDFs".

## What it is (documented, search excerpts)

A serverless host for Python 3.11 functions, called from pipelines,
notebooks, Activator rules, Power BI translytical task flows and REST
clients; it stores no data. Develop mode edits and tests; Run only runs
what was last published.

## The definition: the docs disagree, the portal matches one

| Part | Learn Git pages | Learn REST page | fabric-cicd sample | Portal commit |
| --- | --- | --- | --- | --- |
| Code | `function-app.py` | `function_app.py` | `function_app.py` | `function_app.py` |
| Item JSON | `definitions.json` | `definition.json` | `definition.json` | `definition.json` |
| Metadata | `resources/functions.json` | required | `.resources/functions.json` | none |

Observed across three portal commits: a new item is `.platform` and
`definition.json` with every list empty, `libraries.public` included;
the first publish adds `function_app.py` and `fabric-user-data-functions`
at `"version": "1.0"` (Library management shows `~= 1.0`; the operator
isn't serialized); a connection adds a `connectedDataSources[]` entry.
`functions.json` is never needed: `getDefinition` returns three parts
and `createItem` without it built a working item. Functions default to
`isPublicEndpointEnabled: true`, and the service sorts `functions[]` by
name, so a hand-added entry out of order costs one round-trip commit.
Bytes moved to the serialization rule on 2026-10-01.

## Programming model (documented, the programming-model page in full)

- `import fabric.functions as fn` and `udf = fn.UserDataFunctions()` are
  required; `@udf.function()` makes a function invocable and needs a
  return annotation; undecorated functions are helpers.
- **Parameter names are camelCase with no underscores** and annotated;
  `req`, `context` and `reqInvocationId` are reserved. Function names may
  carry underscores (observed). A local load with
  `fabric-user-data-functions` 1.0.142 accepted a `product_name`
  parameter, so only publishing enforces the rule (observed).
- Types in: `str`, `datetime` from ISO, `bool`, `int`, `float`, lists,
  `dict`, pandas `DataFrame` and `Series`; out: the same plus `None`.
  Defaults make a parameter optional, JSON-serializable only.
- Connections are decorators: `@udf.connection(argName=…, alias=…)` for
  `FabricSqlConnection`, `FabricLakehouseClient` or
  `FabricVariablesClient`; `@udf.generic_connection(…, audienceType=…)`
  for an owner-identity token to Cosmos DB or Key Vault.
- `@udf.context` gives `invocation_id` and `executing_user`; authorize on
  `Oid` with `TenantId`, not the mutable `PreferredUsername`.
- `fn.UserThrownError(message, props)` returns a handled error; `async
  def` works; batch mode (`max_batch_size=900`) needs a preview switch.
- Underneath it is the Azure Functions Python v2 model: each function an
  HTTP trigger with `req`, which is where the file name and the reserved
  names come from, plus two hidden functions serving the item's OpenAPI
  spec (observed in the SDK). `datetime.now()` is UTC (observed).

## How other items link to it, and what survives a deploy

Learn's cross-workspace binding page has no UDF section (documented).

| Link | Stored as | Survives a deploy | Label |
| --- | --- | --- | --- |
| UDF to a Fabric data source | target's `logicalId`, all-zero `workspaceId`, `artifactType: SqlDbNative` | likely | form observed, rebind inferred |
| Code to its connection | alias string in the decorator | while the alias holds | documented |
| Power BI button | raw workspace and item GUIDs plus function name | no | documented |
| Warehouse proxy | item and function name, live Warehouse only | no: Git doesn't carry it | observed |
| Notebook | name or id, optional workspace | by name, same workspace | form documented |
| Pipeline Functions activity | `functionSetId` = UDF `logicalId`, all-zero workspace, a connection GUID | likely | form observed |
| Activator rule action | — | commit and deploy fail | `fabric-activator` §11 |

- **REST stores the data-source link with real IDs** and Git with the
  `logicalId` form; a REST create in Git's form fails, atomically,
  `ConnectionSourceNotFound`, and succeeds once rewritten, the new item
  answering at once with no portal step (observed). Committed back, a
  REST-made item serializes byte-identical to the portal's.
- The alias is the item name with underscores removed (observed once);
  renaming or deleting a connection fails every function still using it
  at runtime (documented).
- **Warehouse proxies**: `CREATE OR ALTER FUNCTION dbo.f AS EXTERNAL
  FUNCTION <item>.<function>` worked, `sys.objects` type `XF`, one
  invocation per call; Git didn't carry the proxies while it carried a
  plain function in the same Warehouse, so a post-deploy script must
  recreate them (observed).
- **Pipelines**: the activity type is `AzureFunctionActivity` even for a
  UDF, with `functionName`, `functionSetId`, `workspaceId` and a flat
  `parameters` map; the run's output adds `monitoringUrl` and
  `executionDuration` (observed). `fabric-data-pipeline`'s reference
  lists `AzureFunction`, which needs checking against a portal-written
  Azure Function activity.

## Invocation and identity

- Invoke URL, on no page read: `POST https://api.fabric.microsoft.com/v1/
  workspaces/{ws}/userDataFunctions/{item}/functions/{name}/invoke`, JSON
  body, a token for `https://api.fabric.microsoft.com` (observed). The
  response is `functionName`, `invocationId`, `status`, `output`,
  `errors`.
- SQL rows returned from `cursor.fetchall()` arrive as a Python repr
  string, not a JSON array, though the item's own OpenAPI spec promises
  an array: convert rows first (observed).
- `UserThrownError` comes back `"status": "BadRequest"`,
  `errorCode: "UserThrown"`, `props` as `properties` (observed);
  `executing_user` is the caller (observed from the portal).
- A calling app needs `UserDataFunction.Execute.All` or
  `item.Execute.All`; report users need Execute through Share (documented,
  search excerpts).

## Lifecycle, limits and cost (documented, search excerpts: fetch first)

Published functions run Python 3.11 while Develop-mode Test runs 3.12;
publishing takes minutes with a two-minute cooldown from any route; only
the owner edits and publishes; limits 4 MB request, 240 s (100 s through
the public endpoint), 30 MB response, 28.6 MB private wheel, 15-minute
Test session; no service principal or managed identity through managed
connections; the network must allow `multipart/form-data`. Billing is per
run plus small idle OneLake storage.

## CI/CD

- Deployment pipelines carry connections and libraries (documented).
- **A Git Update publishes code with no portal step** (observed): a
  function added in git ran at once in Run only mode.
- fabric-cicd 1.3.0 publishes the type generically; its logical-ID pass
  should rewrite a same-workspace connection when the connected item's
  folder is in the repository directory (inferred from source, not run).
  Its docs name `definitions.json` and `functions.json`, both wrong
  against the portal.
- `fab` 1.7.0 handles the type, without a run verb; `export` writes
  REST's IDs and `bulk-export` Git's (landed in fabric-cli 2026-10-01).

## Doc defects, for `/drift-audit` and the skill's caveats

The two Learn Git pages' file names; the REST example's invalid JSON
(no comma between two `functions[]` objects) and its "required"
`functions.json`; the Warehouse page's repeated Remarks bullets;
upstream's button reference listing items "of type `UserDataFunctions`",
which REST rejects 400 `InvalidItemType` (observed); the SDK overview's
context example reading `context.` from a parameter named `myContext`;
and two pages still calling translytical task flows preview, GA since
March 2026 (Power BI Desktop 2.152.882.0, search excerpts).

## Neighbours to point here once it lands (`/learn` follow-ups)

`fabric-activator` §6 and §11; `fabric-variable-library` references
beside the UDF runtime entry; `fabric-warehouse` § Beyond T-SQL
authoring (proxy functions, `RETURNS` to narrow the inferred
`VARCHAR(MAX)`, `XF`, batch mode, `queryinsights.external_api_call_stats`);
`fabric-data-pipeline` § Activity types; `fabric-spark`
(`notebookutils.udf.getFunctions`).

## Open questions, in the order worth probing

1. Connection kinds: a Warehouse's and a Lakehouse's `artifactType` and
   alias, and whether an unused connection serializes.
2. Library management: a PyPI entry's shape, and whether a private wheel
   lands in Git.
3. Public access off: what it stops, and its default per creation route.
4. In a second workspace: whether the connection rebinds through Git;
   fabric-cicd with and without the SQL database's folder; a
   cross-workspace connection's Git form.

## Where it lands

`skills/fabric/fabric-user-data-functions/SKILL.md` and `references/`,
a `skills/README.md` row, fixtures via `/test-skill`. Test queries the
note proposed: "My Power BI data function button doesn't list my
function"; "Publishing fails on a parameter named `product_name`"; "Will
my UDF's SQL connection still work after deploying to test?"; "What files
does a UserDataFunction folder hold in Git?"; "Call a Fabric UDF from a
Warehouse query".

## Not checked

The pages read only as search excerpts (limits, overview, NotebookUtils,
Functions activity, the Python app tutorial); the VS Code extension and
local debugging; logs and monitoring; Business events as a data source;
Functions in Fabric Apps, a different authoring surface, out of scope.

## Scrubbing

The sources were raw. The client prefix in item names and the generated
alias is left out, as are workspace names, GUIDs and the sandbox's
SHAs; function names and code are Microsoft's portal samples. The
sandbox holds the item at all three stages, but its alias and
`artifactId` must be genericized before any fixture.

## Re-measure before acting

- `grep -rn UserDataFunction skills/ claude/`: on 2026-10-01, the
  serialization rule (glob and bytes), fabric-cicd, fabric-rest-api,
  fabric-deployment-pipelines and the LinkedIn reference.
- Learn's service-limits and programming-model pages, before encoding
  any limit.
