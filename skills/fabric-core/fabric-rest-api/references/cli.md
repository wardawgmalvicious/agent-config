# Fabric CLI (`fab`)

Filesystem-style CLI over the Fabric + Power BI REST APIs. Paths use `Workspace.Workspace/Item.ItemType/...`. The `.ItemType` suffix is **mandatory** on items. Workspaces use `.Workspace`; hidden roots like `.capacities`, `.connections`, `.domains`, `.gateways` expose tenant resources.

**Version / install:** v1.5 went GA March 2026; current is v1.7.x (v1.7.0 shipped 2026-08-18, after v1.6.1 on 2026-04-29). Install with `pip install ms-fabric-cli` or `uv tool install ms-fabric-cli`. Requires Python 3.10, 3.11, 3.12, or 3.13. Pre-installed in Fabric Notebooks (no install step needed when running `!fab ...` from a notebook cell). Confirm version with `fab --version`. Canonical per-command reference: [microsoft.github.io/fabric-cli](https://microsoft.github.io/fabric-cli/). Release notes: [github.com/microsoft/fabric-cli/releases](https://github.com/microsoft/fabric-cli/releases).

**Interactive (REPL) mode:** `fab config set mode interactive` switches `fab` to a persistent shell where commands no longer need the `fab` prefix and `cd` state survives between calls. Default is command-line mode.

**AI assets (v1.5+):** The repo's [`.ai-assets/`](https://github.com/microsoft/fabric-cli/tree/main/.ai-assets) folder bundles `context/`, `modes/`, `prompts/`, and `skills/` files designed to be loaded by AI coding assistants (Copilot, Claude, Cursor) so the assistant can author `fab` invocations correctly. These are *consumable artifacts*, not CLI verbs — there is no `fab agent` or `fab ai` subcommand.

## Authentication

`fab` does **not** reuse the Azure CLI session: its auth module has no Azure CLI credential, so with `az` signed in and `fab` logged out, `fab ls` fails `[AuthenticationFailed] Failed to get access token` (`fab` 1.7.0 source, and a run, 2026-10-01). It takes `fab auth login` (interactive, service principal or managed identity), or tokens in environment variables, which leave its stored login alone, so a shell pinned to one tenant through `AZURE_CONFIG_DIR` stays pinned:

```bash
export FAB_TOKEN="$(az account get-access-token --resource https://analysis.windows.net/powerbi/api --query accessToken -o tsv | tr -d '\r')"
export FAB_TOKEN_ONELAKE="$(az account get-access-token --resource https://storage.azure.com --query accessToken -o tsv | tr -d '\r')"
```

- **Both are required**: either alone fails `both_fab_and_onelake_tokens_required`.
- **`FAB_TOKEN` carries the Power BI audience**: `fab` checks its `aud` against `https://analysis.windows.net/powerbi/api` alone.
- **`FAB_TOKEN_AZURE`** (`https://management.azure.com`) serves only Azure-scope commands, but `fab auth status` crashes without it, `[UnexpectedError] FAB_TOKEN_AZURE`, since it reads the variable before checking that it is set.
- They expire like any access token: mint them in the same shell call as the `fab` command.

`fab auth` tokens do **not** work for OneLake storage calls from external tools — acquire via `az account get-access-token --resource https://storage.azure.com` instead (OneLake's audience is Azure Storage, not the Fabric API).

## Path Syntax

```
Workspace.Workspace/Item.ItemType[/Files|Tables/...]
.capacities/MyCap.Capacity
.connections/conn.Connection
.domains/Analytics.Domain
.gateways/gw.Gateway
```

Names with spaces or apostrophes work inside double quotes with no escaping: `"Claude Code's Workspace.Workspace"`.

## Core Command Reference

### Navigation & Discovery

| Command | Purpose |
|---|---|
| `fab ls [path]` | List workspaces / items / files / tables |
| `fab ls -l` | Long format |
| `fab ls -a` | Include hidden roots |
| `fab ls -q "<jmespath>"` | Filter server response (replaces many `fab api` calls) |
| `fab cd <path>` | Change working path (session-scoped) |
| `fab pwd` | Current path |
| `fab exists <path>` | Returns `* true` / `* false` |
| `fab get <path> [-v] [-q <jmespath>] [-o <file>] [-f]` | Item details. Without `-q` it lists the queryable property paths, not their values (`-v` too); `-q .` prints everything, definition parts decoded. On an item, pass `-f` |
| `fab desc .<ItemType>` | List commands supported by an item type |
| `fab find "<text>" [-P type=[...]] [-l]` | OneLake-catalog search across all workspaces by display name / description / workspace name (**v1.6+**). `-P` uses `key=value` / `key!=value` with `[a,b]` bracket syntax (distinct from the JSON-array form `fab deploy` uses) |
| `fab open <path>` | Open the workspace or item in the browser |

### Item CRUD

| Command | Purpose |
|---|---|
| `fab mkdir <path> [-P key=value,...]` | Create workspace or item; `-P capacityname=...` for workspaces |
| `fab set <path> -q <prop> -i <value>` | Update a single property (e.g. `displayName`, `description`, `semanticModelId`) |
| `fab rm <path> -f [--hard]` | Delete (alias `del`); `--hard` permanently deletes an item (no recovery, **v1.6+**) |
| `fab cp <src> <dst> [-r] [-f] [-bpc]` | Copy item or files; `-bpc` blocks cross-folder same-name conflicts |
| `fab mv <src> <dst> [-r] [-f]` | Move / rename |
| `fab export <path> -o <dir> [-a] [-f] [--format py]` | Export item definition; `-a` entire workspace |
| `fab bulk-export <path> -o <dir> --recursive [-f]` | Export every supported item in a `.Workspace` or `.Folder`, folder structure kept (**v1.7+**); `--recursive` is required for both targets, and `-f` also waves through a non-empty output dir |
| `fab import <path> -i <dir> -f` | Import definition from local folder (`-f` required for non-interactive) |
| `fab ln <link-path> --target <target-path>` | Create a OneLake shortcut (alias `mklink`) |

**`export` writes REST's IDs, `bulk-export` Git's.** `fab export` calls `getDefinition`: object IDs, the real workspace ID, and an all-zero `.platform` `logicalId`, with no `description`. `bulk-export` writes `logicalId`s and an all-zero `workspaceId`, as a portal commit does, so redeploy or compare with a repo from it. Both re-indent JSON to 4 spaces and write CRLF in every part, code included, so commit neither into a Git-synced folder as is, and compare with `jq -S` (`fab` 1.7.0, two User Data Functions items, 2026-10-01). `bulk-export` also drops types without a word: one run's summary counted a skipped `Warehouse` and four `SQLEndpoint`s and never mentioned a `Plan`, an `EventSchemaSet` or an `AppBackend`, so check it against `fab ls`.

### Access Control

| Command | Purpose |
|---|---|
| `fab acl ls <path> [-l]` | List permissions |
| `fab acl get <path> -q "<jmespath>"` | Query specific ACL fields |
| `fab acl set <path> -I <objectId> -R <Role> [-f]` | Grant role |
| `fab acl rm <path> -I <upn\|clientId> -f` | Revoke |

Role values by resource:

| Resource | Roles |
|---|---|
| Workspace | `Admin`, `Member`, `Contributor`, `Viewer` |
| Connection | `Owner`, `User`, `UserWithReshare` |
| Gateway | `Admin`, `ConnectionCreator`, `ConnectionCreatorWithResharing` |

### Assignment

| Command | Purpose |
|---|---|
| `fab assign .capacities/<C>.Capacity -W <ws>` | Assign workspace to capacity |
| `fab assign .domains/<D>.Domain -W <ws> -f` | Assign workspace to domain |
| `fab unassign .capacities/<C>.Capacity -W <ws>` | Unassign |
| `fab start .capacities/<C>.Capacity` | Resume capacity |
| `fab stop .capacities/<C>.Capacity -f` | Pause capacity (stops all workloads) |

**The `.domains` verbs are tenant-admin only.** `ls`, `get`, `mkdir`, `rm`, `set`, `assign` and `unassign` against `.domains` all require tenant-level Fabric Administrator privileges (fab docs, 2026-09-12) — the capacity verbs above do not. A workspace admin holding a domain contributor role can still assign their own workspace through the Core API, which `fab` reaches only as a passthrough: `fab api -X post "workspaces/$WS_ID/assignToDomain" -i '{"domainId":"<id>"}'`. See the fabric-catalog-governance skill.

### Labels

| Command | Purpose |
|---|---|
| `fab label list-local` | Configured sensitivity labels |
| `fab label set <path> --name <Label>` | Apply label |
| `fab label rm <path> -f` | Remove label |

**All `fab label` commands require tenant-level Fabric Administrator privileges**, and they resolve names from a local JSON file registered with `fab config set local_definition_labels <json_path>` — `list-local` lists that file, not the tenant's labels.

### Jobs

| Command | Purpose |
|---|---|
| `fab job run <path> [--timeout <s>] [--polling_interval <s>]` | Synchronous run |
| `fab job run <path> -P key:type=value,...` | With typed parameters (`string`, `int`, `bool`) |
| `fab job start <path>` | Async (fire and forget) |
| `fab job run-list <path> [--schedule]` | List runs / scheduled runs |
| `fab job run-status <path> --id <jobId>` | Single run status |
| `fab job run-cancel <path> --id <jobId> [--wait]` | Cancel |
| `fab job run-sch <path> --type daily --interval 10:00 --enable` | Create schedule |
| `fab job run-update <path> --id <schedId> [--enable\|--disable]` | Update schedule |
| `fab job run-rm <path> --id <schedId> -f` | Delete schedule |

`fab job run` auto-selects the right job type per item (notebook / pipeline / semantic model refresh / Spark job) — no manual `jobType` equivalent to the REST API required.

### Tables (Lakehouse)

| Command | Purpose |
|---|---|
| `fab table schema <path>` | Show Delta table schema |
| `fab table load <path> --file <Files/...> --mode append\|overwrite` | Load file into Delta table (non-schema lakehouses only) |
| `fab table optimize <path> [--vorder] [--zorder col1,col2]` | OPTIMIZE + optional Z-order |
| `fab table vacuum <path> --retain_n_hours <N>` | VACUUM |

## REST API Passthrough (`fab api`)

Direct REST access when native commands don't cover the operation.

```bash
fab api "<endpoint>"                               # Fabric (default)
fab api -A powerbi "<endpoint>"                    # Power BI
fab api -A storage "<onelake path>"                # OneLake DFS
fab api -A azure "<endpoint>"                      # Azure RM
fab api -X post "<endpoint>" -i '<json>|<file>'    # POST with body
fab api "<endpoint>" -q "value[0].id"              # JMESPath filter
```

**`-i` sets `Content-Type: application/json` for you — don't pass `-H` for
it.** `fab api -i` hands the body to the client as `json=`, and the client
sets that header on every request that is not a multipart upload; only the
separate `--file` path skips it, where `requests` supplies its own boundary
type. A `-H` you pass is merged *after* the default, so it overrides rather
than supplies. Measured 2026-09-13 against `fab` **1.7.0**
(`client/fab_api_client.py`, `commands/api/fab_api_request.py`). Upstream's
`skills-for-fabric` adds `-H "Content-Type=application/json"` to its own
POST example and Learn's `fab api` example carries it too — on this version
that is redundant, not required. If you do pass it, the form is `key=value`
(`=`, not `:` — that is `fab` syntax, not HTTP syntax).

| Audience | Flag | Base URL | Use Cases |
|---|---|---|---|
| Fabric | *(default)* | `api.fabric.microsoft.com` | Items, workspaces, operations, admin |
| Power BI | `-A powerbi` | `api.powerbi.com` | Refresh, datasets, datasources, deployment pipelines, DAX execute, gateways, activity events, admin |
| Storage | `-A storage` | OneLake DFS/Blob | File enumeration with `-P resource=filesystem,recursive=...` |
| Azure | `-A azure` | `management.azure.com` | Capacity pause/resume, ARM resources |

**Idiom — extract an ID and chain:**

```bash
WS_ID=$(fab get "Prod.Workspace" -q "id" | tr -d '"')
MODEL_ID=$(fab get "Prod.Workspace/Model.SemanticModel" -q "id" | tr -d '"')
fab api -A powerbi "groups/$WS_ID/datasets/$MODEL_ID/refreshes" -X post -i '{"type":"Full"}'
```

## Workspace Deployment (`fab deploy`, v1.5+)

`fab deploy`, and the `FabricCLI@1` task that runs `fab` in Azure
DevOps, are the **fabric-deploy** skill's: its `references/fab-deploy.md`
holds the flags, beside the fabric-cicd library the verb wraps and the
route choice between them and deployment pipelines.

## Deployment Pipelines (Power BI service-side)

No native `fab` verbs — use `fab api`, and **mind the audience**, because
two different APIs reach this feature: the Fabric Core surface
(`deploymentPipelines/...`) is the default with no `-A` flag, the older
Power BI surface (`pipelines/...`) needs `-A powerbi`, and crossing them
is a 404 that reads like a missing feature. Request shapes, scopes, item
pairing, rules and limits are the **fabric-deploy** skill's.
`fab deploy` is the Git-driven surface and a different thing entirely.

## Export / Import Formats

| Item Type | Local Format | Notes |
|---|---|---|
| `.Report` | PBIR folder | `.pbir` launches Power BI Desktop (Developer Mode) |
| `.SemanticModel` | TMDL folder | `definition/database.tmdl`, `model.tmdl`, `tables/*.tmdl` (export/import formats stabilized in v1.5) |
| `.SparkJobDefinition` | JSON folder | Export/import added in v1.5 |
| `.Notebook` | `.py` or folder | Use `--format py` for plain Python |
| `.DataPipeline` | JSON folder | Activity definitions |
| `.Lakehouse` | Metadata + tables | Export/import support added in **v1.6+**; before that, only `fab cp` worked for Files |

Export output layout:

```
output/
  Model.SemanticModel/
    .platform
    definition/
      database.tmdl
      model.tmdl
      tables/
  Report.Report/
    .platform
    definition.pbir
    definition/
```

`fab export` does not create intermediate directories: run `mkdir -p <out>` first, or it fails with `InvalidPath`. **Never** include `.platform` when making definition API calls directly — it is Git integration metadata. See the fabric-tmdl skill's `references/definition-api.md`.

Non-exportable types: `.Dashboard`, `.SQLEndpoint` (`.Lakehouse` exports from v1.6). Check with `fab desc .<ItemType>`.

**VariableLibrary (v1.6+):** full CLI coverage via the standard verbs — `mkdir`, `get`, `set`, `rm`, `ls`, `export`, `import`, `cp`, `mv` — backed by the Variable Library REST APIs.

## DuckDB on OneLake

Fastest way to explore lakehouse / warehouse / SQL Database Delta tables without building a semantic model. Requires `duckdb` installed and `az login` active.

```sql
INSTALL delta; INSTALL azure;
LOAD delta; LOAD azure;
CREATE SECRET (TYPE azure, PROVIDER credential_chain, CHAIN 'cli');

SELECT * FROM delta_scan(
  'abfss://my-workspace@onelake.dfs.fabric.microsoft.com/MyLH.Lakehouse/Tables/bronze/orders'
) LIMIT 10;
```

`CHAIN 'cli'` forces use of Az CLI creds; otherwise DuckDB tries managed identity first and fails on local machines.

**Friendly names vs GUIDs:**

| Format | Works for `dbo` | Works for named schemas |
|---|---|---|
| GUID: `abfss://<wsId>@onelake.../<itemId>/Tables/...` | Yes | **No** (Bad Request on parquet read) |
| Friendly: `abfss://<ws>@onelake.../<Name>.<Type>/Tables/schema/...` | Yes | Yes |

**Always use friendly names for schema-namespaced tables.** The `.Lakehouse` / `.Warehouse` / `.SQLDatabase` suffix is required.

| Item type | Friendly path | Notes |
|---|---|---|
| Lakehouse | `.../LH.Lakehouse/Tables/...` | Direct Delta |
| Warehouse | `.../WH.Warehouse/Tables/...` | Direct Delta |
| SQL Database | `.../DB.SQLDatabase/Tables/...` | Auto-mirrored Delta; ~15s replication delay; extra `MSSQL_System_Uniquifier` column |

Raw files under `Files/` via `read_csv()`, `read_json()`, `read_parquet()` with glob patterns (`*`, `**`). Cross-item joins in one query — different `abfss://` paths per item. Read-only; no write-back to lakehouse tables.

## Executing DAX via `fab api`

```bash
cat > /tmp/dax.json << 'EOF'
{
  "queries": [{
    "query": "EVALUATE SUMMARIZECOLUMNS ( 'Date'[Year], \"@Total\", [Total Sales] )"
  }],
  "serializerSettings": { "includeNulls": false }
}
EOF
fab api -A powerbi "groups/$WS_ID/datasets/$MODEL_ID/executeQueries" -X post -i /tmp/dax.json
```

Temp file avoids the double-escaping trap (bash single-quote + JSON double-quote). DAX rules unchanged: `EVALUATE` required, single-quote tables, fully-qualify columns.

## Common Workflows

```bash
# Find all semantic models in a workspace
fab ls "Prod.Workspace" -q "[?type=='SemanticModel'].name"

# Bulk export all reports
mkdir -p /tmp/reports
fab ls "Prod.Workspace" | grep ".Report" | while read item; do
  fab export "Prod.Workspace/$item" -o /tmp/reports -f
done

# Rebind a report to a new model after deployment (v1.5 first-class path)
fab set "Prod.Workspace/Report.Report" -q semanticModelId -i "<new-model-id>"

# Trigger semantic model refresh (v1.5 first-class via fab job, no fab api required)
fab job run "Prod.Workspace/Sales.SemanticModel"                       # synchronous
fab job start "Prod.Workspace/Sales.SemanticModel"                     # fire and forget
fab job run "Prod.Workspace/Sales.SemanticModel" -P refreshType:string=Full

# Equivalent REST passthrough (still valid if you need finer control over the body)
fab api -A powerbi "groups/$WS_ID/datasets/$MODEL_ID/refreshes" -X post -i '{"type":"Full"}'
fab api -A powerbi "groups/$WS_ID/datasets/$MODEL_ID/refreshes?\$top=1"
```

## Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `InvalidPath: No such file or directory` on export | Output dir does not exist | `mkdir -p` first; `fab export` does not create parents |
| Import/export, or `get` on an item, hangs or fails `Found xterm-256color, while expecting a Windows console` (Git Bash) / `No Windows console found` (PowerShell) | A confirmation prompt (for `get`, the sensitivity label) with no console to answer it | Always pass `-f` in scripts and automation |
| `[AuthenticationFailed] Failed to get access token` with `az` signed in | `fab` never reads the Azure CLI login | `fab auth login`, or the env tokens under Authentication |
| GUID path fails on schema table | DuckDB Delta reader on non-dbo schemas | Use friendly names with `.Lakehouse` suffix |
| DuckDB auth fails | No CLI chain specified | `CREATE SECRET (...CHAIN 'cli')` forces Az CLI creds |
| Tokens rejected for OneLake | Used `fab auth` token, or wrong audience | Acquire via `az account get-access-token --resource https://storage.azure.com` (OneLake's audience is Azure Storage, NOT the Fabric API) |
| `403` on refresh / datasources / permissions API | Viewer role | Needs Contributor+; stop retrying — it's permissions |
| Empty response from admin APIs | Missing `$top` query parameter | Add `$top=100` (escape `$` in bash: `\$top`) |
| Activity events empty | Missing quotes around dates | Dates must be quoted ISO 8601 inside URL |
| Workspace path with apostrophe "fails" | Over-escaping | Wrap in double quotes; no backslashes needed |
| Export strips sensitivity label | `-f` force flag | Informational, not an error; label is dropped intentionally |
| Cannot export `.Dashboard` / `.SQLEndpoint`, or `.Lakehouse` before v1.6 | Not definition-exportable | The first two have no export; before v1.6, `fab cp` for lakehouse files |
| `.platform` breaks REST definition calls | Git metadata, not a part | Strip before any direct API payload |
| DAX quote chaos | Bash + JSON double escaping | Write JSON to a temp file via heredoc |
| Session burning CUs after `nb exec` | Forgotten Livy session | Wrap session cleanup in `finally`; idle sessions cost compute until 20-min timeout |
| `fab job run` wrong job type | *(rare)* | CLI auto-selects; if needed use `fab api` with correct `jobType` per [the skill's body](../SKILL.md), *Job Execution* |

## Reference

- Microsoft Learn: [Fabric command line interface (install + login)](https://learn.microsoft.com/rest/api/fabric/articles/fabric-command-line-interface)
- GitHub Pages: [Fabric CLI documentation (canonical per-command reference)](https://microsoft.github.io/fabric-cli/)
- Microsoft Learn: [Item management overview (REST APIs `fab` wraps)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/item-management-overview)
- Microsoft Learn What's New: [Fabric CLI v1.5 GA — March 2026](https://learn.microsoft.com/fabric/fundamentals/whats-new#generally-available-features) — one-command workspace deploys with fabric-cicd integration, first-class Power BI (rebind/refresh), pre-installed in Fabric Notebooks, Python 3.13, 30+ item types.
- Comprehensive MS Learn link bundle (concept / examples / underlying REST / authentication / lakehouse ops / CI/CD): [cli-links.md](cli-links.md)

## See also

- fabric-deploy skill — picking the route and planning a deploy; its `references/fab-deploy.md` holds `fab deploy` and the `FabricCLI@1` task, and its `references/fabric-cicd.md` covers the Python library `fab deploy` wraps: direct `FabricWorkspace` / `publish_all_items` usage, parameter.yml model, feature flags
- [The skill's body](../SKILL.md) — direct REST patterns behind `fab api`
- fabric-tmdl skill — its `references/definition-api.md` covers definition payloads for semantic models
- [auth.md](auth.md) — token audiences when acquiring tokens outside `az login`
