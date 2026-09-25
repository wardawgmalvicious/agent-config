---
name: 'Bicep Conventions'
description: 'Bicep templates, parameter files and linter config: the linter as a gate, what-if blind spots, redeploys that replace rather than merge, and deleting resources'
applyTo: '**/*.bicep,**/*.bicepparam,**/bicepconfig.json'
---

# Bicep Conventions

Applies to Bicep templates and modules, `.bicepparam` parameter files,
and the `bicepconfig.json` that configures their linter, however they
deploy: `az deployment`, a pipeline, or a deployment stack.

## Only what a green build hides

This rule says nothing about syntax, naming, or anything the Bicep
linter already checks. Measured 2026-09-25 on a repo's Bicep written
with no Bicep guidance in place: both entry points passed every default
linter rule, and the familiar traps were already handled —
`principalType` on each role assignment, `existing` for resources
another template owns, `environment()` for cloud URLs. Each section
below is a case where the build passes, the deploy succeeds, and the
thing you wanted did not happen.

## The linter gates only at `error`

- **A warning never fails `bicep build` or `bicep lint`.** Both print it
  and exit 0, and only an `error`-level finding exits 1 (Bicep CLI
  0.47.16, 2026-09-25). A CI step running `az bicep build` therefore
  catches compile errors and the few rules that default to `error`, and
  lets every warning through as a green check.
- **Many rules are off by default, and an off rule prints nothing.**
  `what-if-short-circuiting`, `use-user-defined-types`,
  `use-recent-api-versions` and `no-hardcoded-location` are among them.
- So a repo that deploys Bicep keeps a `bicepconfig.json` at the root of
  its Bicep tree and raises to `error` each rule it means to gate. Every
  file, a module included, uses the nearest one, looking in its own
  folder first and then upward, so one at the root covers `modules/`.

```json
{
  "analyzers": {
    "core": {
      "rules": {
        "what-if-short-circuiting": { "level": "error" }
      }
    }
  }
}
```

## What-if can miss a module

- **A module whose resource names come from a runtime value can
  short-circuit what-if**: its resources are predicted less precisely,
  or left out of the results entirely, and the what-if response carries
  a diagnostic saying so. A runtime value is one known only once the
  deployment runs, such as another module's output or a property of a
  resource the same deployment creates.
- The symptom is a clean what-if that lists fewer changes than the
  template makes. The `what-if-short-circuiting` rule names the cause:
  *"Parameter '<name>' is used as a resource identifier, API version, or
  condition in the module '<module>'. Providing a runtime value for this
  parameter will lead to short-circuiting or less precise predictions in
  What-If."*
- **Pass a deployment-time constant instead**, built from parameters and
  variables, and restore with `dependsOn` the ordering that the output
  reference implied:

```bicep
module environment 'modules/environment.bicep' = {
  params: {
    workspaceName: 'log-${baseName}' // not logs.outputs.name
  }
  dependsOn: [logs]
}
```

- What-if also shows some expressions unevaluated: `utcNow()`,
  `newGuid()`, secure parameter values, and resource functions such as
  `listKeys()`. A property set from another resource's `properties`,
  which Bicep compiles to `reference()`, reports as changing on every
  run whether it will or not, so a Modify recurring on such a property
  is noise, not drift.

## A redeploy replaces, it does not merge

- **Every property a template leaves out is reset to its default when
  the resource is redeployed**, in incremental mode too. The template is
  the whole state of each resource it declares, never a patch to it.
- **So a change made outside the template is reverted by the next
  deploy**, which still exits 0: an `az ... update`, a portal edit,
  another pipeline's write. Move the setting into the template, or read
  the live value and pass it back in, as a pipeline must for a container
  image that a separate app pipeline sets. What-if shows the revert as a
  Modify wherever it can evaluate the resource.
- Where a setting can live on a resource or on a child resource, the
  choice decides what a redeploy keeps. A virtual network's subnets
  belong in its `subnets` property, never in `virtualNetworks/subnets`
  children. A web app's `sites/config` child is left alone by an empty
  object and replaced when values are supplied.

## Removing a resource from the template deletes nothing

- **Incremental mode leaves a resource the template no longer declares
  where it is**, still running and still billed, and what-if lists it as
  `Ignore`, not `Delete`.
- Complete mode, which deletes such resources, is being deprecated.
  Delete through a deployment stack instead. `az stack group create`
  requires `--action-on-unmanage`: `deleteResources` removes what the
  template stops declaring, and `detachAll` leaves it in place, as
  incremental mode does.

```bash
az stack group create --name <stack> --resource-group <rg> \
  --template-file main.bicep --parameters main.bicepparam \
  --action-on-unmanage deleteResources --deny-settings-mode none
```

## Checking a change

- `az bicep lint --file <entry>.bicep` before committing: exit 1 means
  an `error`, and warnings print but pass.
- `az deployment group what-if` before deploying, read for three things:
  fewer changes than you made (a short-circuited module), a Modify on a
  resource you did not touch (an out-of-band change about to be
  reverted), and an `Ignore` on one you removed (it keeps running).
