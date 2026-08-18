---
name: fabric-cicd
description: "Use for the fabric-cicd Python library (`pip install fabric-cicd`, v1.3 Aug 2026, Python 3.9–3.13) — Microsoft's official code-first CI/CD deployment library for Fabric workspaces: `FabricWorkspace`, `publish_all_items`, `unpublish_all_orphan_items`, `deploy_with_config` + config.yml, and the `parameter.yml` model (find_replace, key_value_replace, spark_pool, semantic_model_binding, `$workspace.$id` / `$items.<Type>.<name>.$id` dynamic variables, `$ENV:` pipeline variables, `_ALL_`, regex capture groups, `extend` templates). Covers the explicit-TokenCredential requirement (v1.0 breaking change — DefaultAzureCredential fallback removed), feature flags (enable_lakehouse_unpublish, enable_bulk_publish, enable_shortcut_publish, enable_hard_delete, selective include/exclude), full-deployment-no-diffs semantics, per-item-type caveats (Warehouse/SQL DB shell-only, Lakehouse shortcut handling, Variable Library active value set), Azure DevOps / GitHub Actions pipeline wiring incl. OIDC, running from a Fabric notebook, and troubleshooting (change_log_level, FABRIC_CICD_FILE_LOGGING_ENABLED, devtools debug scripts, private-link configure_fabric_fqdn). Invoke when the user mentions fabric-cicd, FabricWorkspace, publish_all_items, parameter.yml, or code-first Fabric workspace deployment from Git."
---

# fabric-cicd (Python deployment library)

Microsoft's official open-source Python library for **code-first CI/CD into Fabric workspaces**. It abstracts the Fabric REST item-definition APIs: point it at a Git checkout of a Fabric Git-synced workspace folder and it publishes every in-scope item into the target workspace.

**Version / install:** current is v1.3.x (August 2026). `pip install fabric-cicd` (or `uv add fabric-cicd`). Python 3.9–3.13. Docs: [microsoft.github.io/fabric-cicd](https://microsoft.github.io/fabric-cicd/latest/) · repo: [github.com/microsoft/fabric-cicd](https://github.com/microsoft/fabric-cicd).

**v1.0 (April 2026) was a breaking release**: `token_credential` became **required** — the `DefaultAzureCredential` fallback and implicit Fabric-notebook auth were removed. Any pre-1.0 sample that omits the credential no longer runs.

## Which deployment surface am I on?

| Surface | Source of truth | When |
|---|---|---|
| **fabric-cicd** (this skill) | Git | Python-scripted deploys in ADO / GitHub Actions / notebooks; finest control (feature flags, orphan cleanup, selective publish) |
| `fab deploy --config config.yml` | Git | Same engine, CLI wrapper — one-command deploys; see fabric-cli skill |
| Fabric deployment pipelines (service-side) | Workspace | Dev workspace promoted stage-to-stage in the portal / REST; no local code involved |

`fab deploy` **wraps fabric-cicd** and consumes the same `config.yml` / `parameter.yml`. Don't mix Git-driven deploys and service-side deployment pipelines on the same workspaces. Decision guide: [Choose the best Fabric CI/CD workflow](https://learn.microsoft.com/fabric/cicd/manage-deployment).

## Deployment model

- **Full deployment every run** — no commit-diff inspection. The target workspace converges to the repository state; drift is overwritten. (`get_changed_items(repository_directory, git_compare_ref="HEAD~1")` exists if you want to scope a run yourself.)
- Source layout = what Fabric Git integration writes: `<item-name>.<ItemType>/` folders (plus optional workspace subfolders) and an optional `parameter.yml` / `config.yml` at the repository-directory root. Don't hand-craft item folders — commit them from the portal.
- Only item types with source-control + public-API support are deployable (34 types as of v1.3).
- Deploys into the tenant of the executing identity.

## Quick start

```python
from azure.identity import AzureCliCredential
from fabric_cicd import FabricWorkspace, publish_all_items, unpublish_all_orphan_items

workspace = FabricWorkspace(
    workspace_id="<target-workspace-guid>",     # or workspace_name=
    environment="PROD",                          # must match parameter.yml env keys
    repository_directory="<path-to-workspace-folder>",
    item_type_in_scope=["Notebook", "DataPipeline", "Environment"],  # omit → all types
    token_credential=AzureCliCredential(),       # REQUIRED since v1.0
)

publish_all_items(workspace)
unpublish_all_orphan_items(workspace)            # delete workspace items not in repo
```

## Core API

```python
FabricWorkspace(*, repository_directory, token_credential,
                item_type_in_scope=None, environment="N/A",
                workspace_id=None, workspace_name=None)
# workspace_id takes precedence over workspace_name; one is required.

publish_all_items(ws, item_name_exclude_regex=None,
                  folder_path_exclude_regex=None, folder_path_to_include=None,
                  items_to_include=None,          # ["Name.ItemType", ...]
                  shortcut_exclude_regex=None)

unpublish_all_orphan_items(ws, item_name_exclude_regex="^$",  # default excludes nothing
                           items_to_include=None)

deploy_with_config(config_file_path, *, token_credential,
                   environment="N/A", config_override=None)   # → DeploymentResult

append_feature_flag(flag) / remove_feature_flag(flag) / get_supported_feature_flags()
change_log_level("DEBUG")
configure_fabric_fqdn(workspace_id)   # private-link workspaces — call BEFORE FabricWorkspace
get_changed_items(repository_directory, git_compare_ref="HEAD~1")
```

The selective-publish parameters (`items_to_include`, `folder_path_*`, `shortcut_exclude_regex`) require their **experimental feature flags** (below) or they're ignored.

## Authentication

Pass any `azure.identity` `TokenCredential`:

| Context | Credential |
|---|---|
| Local dev | `AzureCliCredential()` / `AzurePowerShellCredential()` |
| ADO / GitHub SPN | `ClientSecretCredential(client_id=..., client_secret=..., tenant_id=...)` |
| OIDC / federated | `WorkloadIdentityCredential()` |
| Self-hosted agent / Azure VM | `ManagedIdentityCredential()` |
| Fabric notebook | custom wrapper below |

Running **inside a Fabric notebook** (implicit auth was removed):

```python
import time
from azure.core.credentials import TokenCredential, AccessToken

class FabricNotebookCredential(TokenCredential):
    def get_token(self, *scopes, **kwargs):
        return AccessToken(notebookutils.credentials.getToken("pbi"), int(time.time()) + 3600)
```

The identity needs Contributor+ on the target workspace (Admin for `enable_hard_delete`). SPNs additionally need the tenant setting *Service principals can use Fabric APIs* — same prerequisites as any Fabric REST automation (see fabric-auth skill).

## parameter.yml

Environment-specific value substitution applied to file contents at publish time, keyed by the `environment` passed to `FabricWorkspace`. Lives at the repository-directory root.

### find_replace — string / regex replacement

```yaml
find_replace:
  - find_value: "123e4567-e89b-12d3-a456-426614174000"   # dev lakehouse GUID as committed
    replace_value:
      PPE:  "f47ac10b-58cc-4372-a567-0e02b2c3d479"
      PROD: "9b2e5f4c-8d3a-4f1b-9c3e-2d5b6e4a7f8c"
    item_type: "Notebook"                 # optional filters
    item_name: ["Hello World"]            # exact, case-sensitive
    file_path: "**/notebook-content.py"   # abs / relative / glob
```

Optional: `is_regex: "true"` (then `find_value` is a regex; **capture group 1** is what gets replaced — include surrounding context in the pattern), `ignore_case: "true"`.

```yaml
  # Re-point a notebook's default lakehouse to the target workspace's copy
  - find_value: \#\s*META\s+"default_lakehouse":\s*"([0-9a-fA-F-]{36})"
    replace_value:
      _ALL_: "$items.Lakehouse.Example_LH.$id"
    is_regex: "true"
    item_type: "Notebook"
```

### key_value_replace — JSONPath-targeted replacement

```yaml
key_value_replace:
  - find_key: $.properties.activities[?(@.name=="Load_Intake")].typeProperties.source.datasetSettings.externalReferences.connection
    replace_value:
      PPE:  "6c517159-d27a-41d5-b71e-ca1ecff6542b"
      PROD: "0f2ef3d1-1f34-4e0e-9483-6c8dbc077514"
    item_type: "DataPipeline"
```

### spark_pool — Environment-item pool remapping

```yaml
spark_pool:
  - instance_pool_id: "72c68dbc-0775-4d59-909d-a47896f4573b"
    replace_value:
      PPE:  { type: "Capacity", name: "CapacityPool_Medium" }
      PROD: { type: "Capacity", name: "CapacityPool_Large" }
```

### semantic_model_binding — post-deploy connection binding

```yaml
semantic_model_binding:
  default:
    connection_id:
      _ALL_: "<connection-guid>"          # or per-env keys; string or list
  models:
    - semantic_model_name: "Sales Model"
      connection_id:
        PPE:  "<guid>"
        PROD: "<guid>"
```

### Dynamic replacement variables

Usable in `replace_value` (not combinable with `is_regex`):

| Variable | Resolves to |
|---|---|
| `$workspace.$id` / `$workspace.$name` / `$workspace.$name_encoded` | Target workspace id / name / URL-encoded name |
| `$workspace.<name>.$id` | Another workspace's id by name |
| `$items.<Type>.<name>.$id` | Deployed item's id (type/name **case-sensitive**, attribute lowercase) |
| `$items.<Type>.<name>.$sqlendpoint` | Lakehouse / Warehouse / MirroredDatabase / SQLDatabase connection string |
| `$items.<Type>.<name>.$sqlendpointid` | Lakehouse / MirroredDatabase endpoint id |
| `$items.Eventhouse.<name>.$queryserviceuri` | Eventhouse query URI |

### Other mechanics

- `_ALL_` env key = same replacement for every environment.
- `$ENV:var_name` in `replace_value` reads a pipeline/OS environment variable — requires the `enable_environment_variable_replacement` feature flag.
- `extend:` — list of relative paths to split parameter files into templates.
- Validation runs automatically at deploy start (deployment halts on failure); pre-validate with `devtools/debug_parameterization.py`.
- Dynamic variables **disable bulk publish mode**, and using any of them triggers eager SQL-endpoint resolution for all Lakehouses/Warehouses in the target workspace.

## Config-file deployment (`deploy_with_config`)

Single-call deployment driven by a `config.yml` — the same file `fab deploy` consumes. **Every field accepts either a scalar (all envs) or a per-env mapping** (`dev:` / `test:` / `prod:`).

```yaml
core:
  workspace_id:                 # or workspace: <name>; id wins
    dev:  "8b6e2c7a-..." 
    prod: "7c3e1f8b-..."
  repository_directory: "."     # relative to config.yml
  item_types_in_scope: [Notebook, DataPipeline, Environment, Lakehouse]
  parameter: "parameter.yml"

publish:                        # optional; omitted → publish everything
  exclude_regex: "^DONT_DEPLOY.*"
  folder_exclude_regex: { dev: "^/DONT_DEPLOY_FOLDER" }   # flag-gated; mutually
  folder_path_to_include: { prod: ["/DEPLOY_FOLDER"] }    #   exclusive per env
  items_to_include: ["Hello World.Notebook"]              # flag-gated
  skip: { dev: true, test: false, prod: false }

unpublish:                      # optional; omitted → orphans ARE unpublished
  exclude_regex: "^DEBUG.*"
  skip: { prod: true }

features:                       # feature flags to enable
  - enable_shortcut_publish

constants:                      # override fabric_cicd.constants values
  DEFAULT_API_ROOT_URL: "https://api.fabric.microsoft.com"
```

```python
deploy_with_config("config.yml", token_credential=cred, environment="prod",
                   config_override={"publish": {"skip": {"prod": False}}})
```

## Feature flags (`append_feature_flag`)

| Flag | Effect |
|---|---|
| `enable_lakehouse_unpublish` / `enable_warehouse_unpublish` / `enable_sqldatabase_unpublish` / `enable_eventhouse_unpublish` / `enable_kqldatabase_unpublish` | Allow orphan deletion of **data-bearing items** — off by default as data-loss protection |
| `enable_hard_delete` | Bypass workspace recycle bin on unpublish; requires workspace **Admin** |
| `enable_shortcut_publish` / `continue_on_shortcut_failure` | Deploy Lakehouse shortcuts / tolerate shortcut failures |
| `disable_workspace_folder_publish` | Don't create workspace subfolders |
| `enable_environment_variable_replacement` | Activate `$ENV:` in parameter.yml |
| `enable_response_collection` | `publish_all_items` returns collected API responses |
| `enable_experimental_features` + `enable_bulk_publish` | Single bulk-import API call instead of per-item (beta; non-prod) |
| `enable_experimental_features` + `enable_items_to_include` / `enable_exclude_folder` / `enable_include_folder` / `enable_shortcut_exclude` | Activate the selective-publish parameters |

Enumerate at runtime: `get_supported_feature_flags()`.

## Item-type caveats (the ones that bite)

- **Warehouse / SQL Database**: **shell only** — no tables/views/procs deployed. Pair with SqlPackage/dacpac for schema (see fabric-database skill).
- **Lakehouse**: shell + (flag-gated) shortcuts; schemas only deployed when a schema contains a shortcut. Deletion blocked unless `enable_lakehouse_unpublish`.
- **Notebook**: `.py` and `.ipynb` supported; attached-lakehouse GUIDs need parameterization (regex example above); notebook resources aren't source-controlled.
- **Environment**: custom pool references need the `spark_pool` section; resources not source-controlled.
- **Semantic Model / Report**: use `semantic_model_binding` for connections; report→model rebinding handled when both deploy together.
- **Dataflow**: same-workspace dependencies auto-ordered; first deployment still needs a manual publish/refresh.
- **Variable Library**: the **active value set is selected by the `environment` value** — the deploy picks the value set matching the environment name.
- **Eventhouse / KQL Database**: parameterization not applied to these types; KQL table data not source-controlled.
- **Data Pipeline / Copy Job / Mirrored Database / Paginated Report**: connection references are **not** source-controlled — parameterize connection GUIDs (`key_value_replace` on `externalReferences.connection`) and pre-create connections in the target.
- **ML Experiment / Mounted Data Factory**: shell only / requires the external ADF to exist.

Full 34-type matrix: [reference/item_types](https://microsoft.github.io/fabric-cicd/latest/reference/item_types/).

## Pipeline wiring (ADO / GitHub Actions)

Canonical pattern — auth step establishes an Azure context, then a plain Python step runs the deploy script:

- **Azure DevOps**: `AzureCLI@2` or `AzurePowerShell@5` task with a service connection, inline step runs `python deploy.py`; SPN secrets via a Key-Vault-linked variable group. Tutorial: [CI/CD with Azure DevOps + fabric-cicd](https://learn.microsoft.com/fabric/cicd/tutorial-fabric-cicd-azure-devops).
- **GitHub Actions**: `azure/login` with **OIDC federated credentials** (`permissions: id-token: write`), branch→environment mapping via `environment: ${{ github.ref_name }}`, workspace ids from environment-scoped `vars`/`secrets`.
- Inside the script, branch/environment name selects the `environment` argument, which selects the parameter.yml / config.yml env keys.

Full YAML: [example/release_pipeline](https://microsoft.github.io/fabric-cicd/latest/example/release_pipeline/).

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| 401 / "credential required" | v1.0 removed implicit auth — pass an explicit `TokenCredential`; check workspace role |
| Old sample without `token_credential` fails | Same breaking change — update the constructor call |
| Parameter not substituted | Env name mismatch with `replace_value` keys; `find_value` not byte-exact; validate with `devtools/debug_parameterization.py` |
| Item deploy fails, vague error | `change_log_level()` + set `FABRIC_CICD_FILE_LOGGING_ENABLED` — full stack traces go **only** to `fabric_cicd.error.log` |
| Recreate-after-delete fails | Wait ~5 min between deleting and recreating an item with the same name |
| Orphan Lakehouse/Warehouse not deleted | Intentional — needs the matching `enable_*_unpublish` flag |
| `items_to_include` / folder filters ignored | Missing `enable_experimental_features` + the specific flag |
| Bulk publish "Dependencies could not be resolved" | All dependent items must be in the same batch; also: dynamic parameter variables disable bulk mode |
| Private-link workspace unreachable | `configure_fabric_fqdn(workspace_id)` **before** constructing `FabricWorkspace` |
| 429 rate limiting | Smaller batches; retry-after in the error log |
| Selective run wanted despite full-deploy model | `get_changed_items()` + `items_to_include`, or accept full deploys (the design intent) |

## Reference

- Docs: [microsoft.github.io/fabric-cicd](https://microsoft.github.io/fabric-cicd/latest/) — [getting started](https://microsoft.github.io/fabric-cicd/latest/how_to/getting_started/) · [parameterization](https://microsoft.github.io/fabric-cicd/latest/how_to/parameterization/) · [config deployment](https://microsoft.github.io/fabric-cicd/latest/how_to/config_deployment/) · [feature flags](https://microsoft.github.io/fabric-cicd/latest/how_to/optional_feature/) · [troubleshooting](https://microsoft.github.io/fabric-cicd/latest/how_to/troubleshooting/) · [changelog](https://microsoft.github.io/fabric-cicd/latest/changelog/)
- Microsoft Learn: [Fabric ci-cd overview](https://learn.microsoft.com/rest/api/fabric/articles/fabric-ci-cd) · [Choose the best CI/CD workflow](https://learn.microsoft.com/fabric/cicd/manage-deployment) · [ADO tutorial](https://learn.microsoft.com/fabric/cicd/tutorial-fabric-cicd-azure-devops)
- Repo: [github.com/microsoft/fabric-cicd](https://github.com/microsoft/fabric-cicd) (issues, `devtools/` debug scripts)

## See also

- fabric-cli skill — `fab deploy` wrapper over this library; service-side deployment-pipeline REST via `fab api -A powerbi`
- fabric-auth skill — token audiences, SPN setup, 401 debugging
- fabric-rest-api skill — the underlying item-definition / LRO API patterns
- fabric-variable-library skill — value-set selection semantics this library keys off `environment`
