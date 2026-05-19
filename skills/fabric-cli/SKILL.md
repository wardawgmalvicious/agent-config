---
name: fabric-cli
description: "Use for the Fabric CLI `fab` (v1.5 GA March 2026, `pip install ms-fabric-cli`, Python 3.10–3.13, pre-installed in Fabric Notebooks) — filesystem-style CLI over Fabric + Power BI REST. Covers path syntax (Workspace.Workspace/Item.ItemType, .ItemType suffix mandatory, hidden roots .capacities/.connections/.domains/.gateways), auth reuse from `az login`, navigation (ls/cd/pwd/exists/get/desc/find), item CRUD (mkdir/set/rm/cp/mv/ln/export/import), ACLs, capacity/domain assign, labels, jobs (incl. semantic-model refresh + dataflow), table maintenance, shortcuts via `fab ln`, `fab deploy --config <yaml>` for one-command workspace CI/CD on top of fabric-cicd (v1.5+), `fab api` REST passthrough (-A powerbi/storage/azure), deployment pipelines, report rebind via `fab set semanticModelId`, DuckDB-on-OneLake, executing DAX via fab api, and common gotchas (InvalidPath, GUID vs friendly names for schema tables, -f for non-interactive)."
---

# Fabric CLI (`fab`)

Filesystem-style CLI over the Fabric + Power BI REST APIs. Paths use `Workspace.Workspace/Item.ItemType/...`. The `.ItemType` suffix is **mandatory** on items. Workspaces use `.Workspace`; hidden roots like `.capacities`, `.connections`, `.domains`, `.gateways` expose tenant resources.

**Version / install:** v1.5 went GA March 2026; current is v1.6.x (April 2026+). Install with `pip install ms-fabric-cli` or `uv tool install ms-fabric-cli`. Requires Python 3.10, 3.11, 3.12, or 3.13. Pre-installed in Fabric Notebooks (no install step needed when running `!fab ...` from a notebook cell). Confirm version with `fab --version`. Canonical per-command reference: [microsoft.github.io/fabric-cli](https://microsoft.github.io/fabric-cli/). Release notes: [github.com/microsoft/fabric-cli/releases](https://github.com/microsoft/fabric-cli/releases).

**Interactive (REPL) mode:** `fab config set mode interactive` switches `fab` to a persistent shell where commands no longer need the `fab` prefix and `cd` state survives between calls. Default is command-line mode.

**AI assets (v1.5+):** The repo's [`.ai-assets/`](https://github.com/microsoft/fabric-cli/tree/main/.ai-assets) folder bundles `context/`, `modes/`, `prompts/`, and `skills/` files designed to be loaded by AI coding assistants (Copilot, Claude, Cursor) so the assistant can author `fab` invocations correctly. These are *consumable artifacts*, not CLI verbs — there is no `fab agent` or `fab ai` subcommand.

## Authentication

`fab` reuses the current Azure CLI session (`az login`). It auto-acquires tokens for Fabric and Power BI audiences. Storage / OneLake operations via `fab api -A storage` require the same Az CLI session. `fab auth` tokens do **not** work for OneLake storage calls from external tools — acquire via `az account get-access-token --resource https://storage.azure.com` instead (OneLake's audience is Azure Storage, not the Fabric API).

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
| `fab get <path> [-v] [-q <jmespath>] [-o <file>]` | Item details; `-v` all properties |
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
| `fab import <path> -i <dir> -f` | Import definition from local folder (`-f` required for non-interactive) |
| `fab ln <link-path> --target <target-path>` | Create a OneLake shortcut (alias `mklink`) |

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

### Labels

| Command | Purpose |
|---|---|
| `fab label list-local` | Configured sensitivity labels |
| `fab label set <path> --name <Label>` | Apply label |
| `fab label rm <path> -f` | Remove label |

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

One-command CI/CD that wraps the [fabric-cicd](https://microsoft.github.io/fabric-cicd/latest/) Python library. Deploys items from local source folders to a target workspace, with environment-aware parameterization. Use this — not `fab api` — for code-first workspace promotion from a Git checkout.

```bash
fab deploy --config <config_file> [-tenv <env>] [-P '<json-array>'] [-f] [--output_format <fmt>]
```

| Flag | Purpose |
|---|---|
| `--config <file>` | **Required.** Path to the deployment YAML. Defines source items, target workspace, item-types-in-scope, and the parameter file. |
| `-tenv`, `--target_env <env>` | Picks the env block (e.g. `dev` / `test` / `prod`) from the config + parameter file. |
| `-P`, `--params '<json>'` | JSON-array of override parameters: `'[{"p1":"v1","p2":"v2"}]'`. **Quote the whole array** — single object form (`-P key=value`) is *not* what this verb accepts (that's `fab find`'s param style — they differ). |
| `-f`, `--force` | Skip interactive confirmation (required in CI). |
| `--output_format <fmt>` | Override output format (json / text / etc.). |

Examples:

```bash
fab deploy --config config.yml --target_env dev
fab deploy --config config.yml --target_env prod -f
fab deploy --config config.yml --target_env test \
  -P '[{"param1":"value1"}]' -f
```

The config file resolves source folders, target workspace IDs/names, and per-env GUID replacements through fabric-cicd's parameter model — same `$workspace.$id` and `$items.<Type>.<name>.id` tokens documented in the Azure DevOps tutorial. Authenticates via the active `fab auth` session (interactive or SPN).

**When to use `fab deploy` vs Power BI deployment pipelines:** `fab deploy` is **source-of-truth-is-Git** (workspace = artifact of the deploy). Power BI deployment pipelines is **source-of-truth-is-workspace** (dev workspace promotes to test/prod workspaces via the service-side pipeline). They are distinct surfaces — don't mix.

## Deployment Pipelines (Power BI service-side)

For the service-side stage-to-stage deployment pipelines (different feature from `fab deploy`), there are no native verbs — use `fab api -A powerbi`:

```bash
fab api -A powerbi pipelines                                     # user pipelines
fab api -A powerbi admin/pipelines                               # all tenant
fab api -A powerbi "pipelines/$PIPELINE_ID/stages"
fab api -A powerbi "pipelines/$PIPELINE_ID/operations"

fab api -X post "deploymentPipelines/$PIPELINE_ID/stages/$STAGE_ID/assignWorkspace" -i '{"workspaceId":"<ws>"}'
fab api -X post "deploymentPipelines/$PIPELINE_ID/deploy" -i '{
  "sourceStageOrder": 0,
  "targetStageOrder": 1,
  "options": {"allowCreateArtifact": true, "allowOverwriteArtifact": true}
}'
```

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

**Critical:** `fab export` does **not** create intermediate directories. Always `mkdir -p <out>` first, or it fails with `InvalidPath`. **Never** include `.platform` when making definition API calls directly — it is Git integration metadata. See the fabric-tmdl-api skill.

Non-exportable types: `.Dashboard`, `.SQLEndpoint`. (`.Lakehouse` is now exportable as of v1.6.) Check with `fab desc .<ItemType>`.

**VariableLibrary (v1.6+):** Variable Libraries now have full CLI coverage via the standard verbs — `mkdir`, `get`, `set`, `rm`, `ls`, `export`, `import`, `cp`, `mv` — backed by the Variable Library REST APIs. Before v1.6 only the portal could manage them.

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
| Import/export hangs | Expects interactive confirmation | Always pass `-f` in scripts and automation |
| GUID path fails on schema table | DuckDB Delta reader on non-dbo schemas | Use friendly names with `.Lakehouse` suffix |
| DuckDB auth fails | No CLI chain specified | `CREATE SECRET (...CHAIN 'cli')` forces Az CLI creds |
| Tokens rejected for OneLake | Used `fab auth` token, or wrong audience | Acquire via `az account get-access-token --resource https://storage.azure.com` (OneLake's audience is Azure Storage, NOT the Fabric API) |
| `403` on refresh / datasources / permissions API | Viewer role | Needs Contributor+; stop retrying — it's permissions |
| Empty response from admin APIs | Missing `$top` query parameter | Add `$top=100` (escape `$` in bash: `\$top`) |
| Activity events empty | Missing quotes around dates | Dates must be quoted ISO 8601 inside URL |
| Workspace path with apostrophe "fails" | Over-escaping | Wrap in double quotes; no backslashes needed |
| Export strips sensitivity label | `-f` force flag | Informational, not an error; label is dropped intentionally |
| Cannot export `.Lakehouse` / `.Dashboard` / `.SQLEndpoint` | Not definition-exportable | Use `fab cp` for lakehouse files; others have no export |
| `.platform` breaks REST definition calls | Git metadata, not a part | Strip before any direct API payload |
| DAX quote chaos | Bash + JSON double escaping | Write JSON to a temp file via heredoc |
| Session burning CUs after `nb exec` | Forgotten Livy session | Wrap session cleanup in `finally`; idle sessions cost compute until 20-min timeout |
| `fab job run` wrong job type | *(rare)* | CLI auto-selects; if needed use `fab api` with correct `jobType` per fabric-rest-api skill |

## Reference

- Microsoft Learn: [Fabric command line interface (install + login)](https://learn.microsoft.com/rest/api/fabric/articles/fabric-command-line-interface)
- GitHub Pages: [Fabric CLI documentation (canonical per-command reference)](https://microsoft.github.io/fabric-cli/)
- GitHub Pages: [`fab deploy` command reference](https://microsoft.github.io/fabric-cli/commands/fs/deploy/)
- Microsoft Learn: [Item management overview (REST APIs `fab` wraps)](https://learn.microsoft.com/rest/api/fabric/articles/item-management/item-management-overview)
- Microsoft Learn What's New: [Fabric CLI v1.5 GA — March 2026](https://learn.microsoft.com/fabric/fundamentals/whats-new#generally-available-features) — one-command workspace deploys with fabric-cicd integration, first-class Power BI (rebind/refresh), pre-installed in Fabric Notebooks, Python 3.13, 30+ item types.
- Comprehensive MS Learn link bundle (concept / examples / underlying REST / authentication / lakehouse ops / CI/CD): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-rest-api skill — direct REST patterns behind `fab api`
- fabric-tmdl-api skill — definition payloads for semantic models
- fabric-auth skill — token audiences when acquiring tokens outside `az login`
