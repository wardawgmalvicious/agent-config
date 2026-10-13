# `fab deploy` (the Fabric CLI's deploy verb)

One-command CI/CD that wraps the [fabric-cicd](https://microsoft.github.io/fabric-cicd/latest/) Python library. Deploys items from local source folders to a target workspace, with environment-aware parameterization. Use this — not `fab api` — for code-first workspace promotion from a Git checkout.

```bash
fab deploy --config <config_file> [-tenv <env>] [-P '<json-array>'] [-f] [--output_format <fmt>] [--bulk_publish]
```

| Flag | Purpose |
|---|---|
| `--config <file>` | **Required.** Path to the deployment YAML. Defines source items, target workspace, item-types-in-scope, and the parameter file. |
| `-tenv`, `--target_env <env>` | Picks the env block (e.g. `dev` / `test` / `prod`) from the config + parameter file. |
| `-P`, `--params '<json>'` | JSON-array of override parameters: `'[{"p1":"v1","p2":"v2"}]'`. **Quote the whole array** — single object form (`-P key=value`) is *not* what this verb accepts (that's `fab find`'s param style — they differ). |
| `-f`, `--force` | Skip interactive confirmation (required in CI). |
| `--output_format <fmt>` | Override output format (json / text / etc.). |
| `--bulk_publish` | **v1.7+**, flagged experimental by `fab` when last read. Publish every item in one bulk-import API call instead of one at a time; the Bulk Import Item Definitions API underneath is GA (September 2026). |

Examples:

```bash
fab deploy --config config.yml --target_env dev
fab deploy --config config.yml --target_env prod -f
fab deploy --config config.yml --target_env test \
  -P '[{"param1":"value1"}]' -f
```

The config file resolves source folders, target workspace IDs/names, and per-env GUID replacements through fabric-cicd's parameter model — same `$workspace.$id` and `$items.<Type>.<name>.$id` tokens as the Azure DevOps tutorial's token table (its Key Takeaways line drops the second `$`, 2026-10-09). Authenticates via the active `fab auth` session (interactive or SPN).

## Built-in Azure DevOps task (`FabricCLI@1`, preview)

There are two ways to run `fab` in an Azure DevOps pipeline:

1. **Install-then-script** (the pattern in the [fabric-cicd ADO tutorial](https://learn.microsoft.com/fabric/cicd/tutorial-fabric-cicd-azure-devops)) — a `pip install ms-fabric-cli` step followed by a script step that calls `fab`. Works everywhere, but you own the install/version pinning in every pipeline.
2. **Built-in task** (preview, March 2026) — the [Azure DevOps Pipelines extension for Fabric](https://marketplace.visualstudio.com/items?itemName=ms-fabric.fabric-devops-pipelines) (marketplace ID `ms-fabric.fabric-devops-pipelines`) ships `fab` as a native `FabricCLI@1` task. The CLI is auto-provisioned in the pipeline runtime — **no `pip install` step**. Auth is via an Azure DevOps **service connection** to your Fabric tenant (rather than passing SPN env vars into a script). Get started at [aka.ms/FabCLI](https://aka.ms/FabCLI).

```yaml
- task: FabricCLI@1
  inputs:
    scriptType: 'pscore'          # ps | pscore | batch | bash
    scriptLocation: 'inlineScript'
    inlineScript: 'fab ls'
    FabricCLIVersion: 'v1.2.0'    # pin the CLI version
```

Prefer the built-in task for new pipelines (less boilerplate, service-connection auth); keep install-then-script when you need a CLI version the task doesn't yet offer, a self-hosted agent, or non-ADO CI. The task is **preview** — pin `FabricCLIVersion` and validate before relying on it for prod promotion.

## Reference

- GitHub Pages: [`fab deploy` command reference](https://microsoft.github.io/fabric-cli/commands/fs/deploy/)

## See also

- [fabric-cicd.md](fabric-cicd.md) — the library `fab deploy` wraps: `config.yml`, `parameter.yml`, feature flags and troubleshooting
- fabric-rest-api skill's `references/cli.md` — `fab` itself: paths, `fab auth` and its environment tokens, `fab api`
