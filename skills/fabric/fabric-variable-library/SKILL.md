---
name: fabric-variable-library
description: "Use for Microsoft Fabric Variable Library — config-as-code for parameterizing notebooks and pipelines per environment. Covers definition parts (variables.json, settings.json, valueSets/<name>.json — no `format` field, omit it), variable types (String, Boolean, Number, Integer, DateTime, Guid, ItemReference, ConnectionReference), notebook consumption via `notebookutils.variableLibrary.getLibrary('Lib').<var>` dot notation (NOT `.get('lib','var')`) or the `get(\"$(/**/Lib/Var)\")` reference-path form, runtime limits (same-workspace only, no SPN, active value set), the ItemReference kernel-shape trap (dict-like; `.value()` AttributeErrors), Git-sync `InvalidContent (ValueMismatch)`, the `bool('false')` → True trap, pipeline integration via the `libraryVariables` block (three keys, no `libraryId`), the pipeline type mapping (Boolean→Bool, Integer→Int, DateTime/Guid→String, Number unsupported, Item/ConnectionReference→Object), Expression-object wrapping, and the runtime-ID rule for ItemReference."
paths:
  - "**/*.VariableLibrary/**"
model: inherit
# effort: medium   # unset = inherit session effort; there is no 'effort: inherit'
disable-model-invocation: false
---

# Fabric Variable Library

Config-as-code for parameterizing notebooks and pipelines per environment. Stored as a Fabric item with definition parts under source control; consumed at runtime via `notebookutils.variableLibrary` (notebooks) or the `libraryVariables` block (pipelines).

## Definition parts

| Part Path | Content | Required |
|---|---|---|
| `variables.json` | Variable names, types, default values | Yes |
| `settings.json` | `valueSetsOrder` (empty array when no Value Sets) | Yes |
| `valueSets/<name>.json` | Per-environment overrides | Only when using Value Sets |
| `.platform` | Item metadata JSON | No (handled by Git/REST layer) |

**Critical**: VariableLibrary does **NOT** support the `format` field in definition requests. Omit it entirely — including `"format": null` may cause errors. (See fabric-rest-api skill for the definition envelope.)

## Supported variable types

| Type | Tier | Description |
|---|---|---|
| `String` | Basic | Text |
| `Boolean` | Basic | true / false (stored as a string!) |
| `Number` | Basic | Floating-point. **Not supported in pipelines** |
| `Integer` | Basic | Whole numbers |
| `DateTime` | Basic | ISO 8601 |
| `Guid` | Basic | GUID |
| `ItemReference` | Advanced | Fabric item binding (`{itemId, workspaceId}`) |
| `ConnectionReference` | Advanced | External connection (Snowflake, Azure SQL, …) by ID, so items reference it without embedded credentials; exposes `.connectionId` |

## variables.json

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/variableLibrary/definition/variables/1.0.0/schema.json",
  "variables": [
    { "name": "lakehouse_name", "type": "String", "value": "bronze_lakehouse" },
    { "name": "enable_logging", "type": "Boolean", "value": "true" },
    { "name": "target_warehouse", "type": "ItemReference",
      "value": { "itemId": "...", "workspaceId": "..." } }
  ]
}
```

## settings.json + Value Sets

`settings.json` is always present. `valueSetsOrder` is an empty array when no Value Sets are used:

```json
{ "$schema": "...", "valueSetsOrder": [] }
```

When Value Sets are configured, list them in priority order:

```json
{ "$schema": "...", "valueSetsOrder": ["test", "prod"] }
```

Every entry in `valueSetsOrder` must have a matching file under `valueSets/`:

```json
{
  "$schema": "...",
  "name": "dev",
  "variableOverrides": [
    { "name": "lakehouse_name", "value": "bronze_dev" }
  ]
}
```

## Git-sync validation (`InvalidContent`)

Importing a Variable Library from Git validates the whole item; a failure surfaces on the workspace sync as `InvalidContent (first issue: ValueMismatch)` / "Item content cannot be used". Two verified causes (2026-08-06):

1. **A value-set override names a variable that doesn't exist** — when renaming a variable in `variables.json`, propagate the rename to **every** `valueSets/*.json`, including value sets populated by someone else.
2. **An empty `value`** — the library rejects `""` for any variable or override. For not-yet-supplied values use a sentinel (e.g. `FILL-ME`) and make consumers treat it as unset.

Also enforced: override value type must match the variable's declared type, and the item must stay under 1 MB.

## Notebook consumption

Use `getLibrary()` + dot notation:

```python
lib = notebookutils.variableLibrary.getLibrary("MyConfig")
name = lib.lakehouse_name        # String
flag = lib.enable_logging        # Returns string "true" / "false"

# Boolean: compare as string — bool("false") is True in Python!
if flag.lower() == "true":
    ...
```

**Wrong patterns** (cause runtime failure or silent bugs):

```python
notebookutils.variableLibrary.get("MyConfig", "lakehouse_name")   # ❌ signature does not exist
bool(flag)                                                         # ❌ "false" → True
```

The **reference-path form** of `get()` does exist and auto-types the value — the `/**/` prefix is required and names are case-sensitive:

```python
notebookutils.variableLibrary.get("$(/**/MyConfig/lakehouse_name)")   # ✅
```

**Runtime limits** (all verified 2026-08-06): same-workspace libraries only; **no SPN support** — scheduled / service-principal runs must receive values as notebook parameters instead; always resolves the workspace's **active value set**. Works in the pure-Python (non-Spark) kernel.

**ItemReference shape differs by kernel.** The pure-Python kernel returns a plain dict-like object — `.get("itemId")` is already the GUID string; the documented `.get("itemId").value()` accessor (Spark surface) raises `AttributeError: 'str' object has no attribute 'value'` there. Accept both:

```python
ref = notebookutils.variableLibrary.get("$(/**/MyConfig/target_warehouse)")
item_id = ref.get("itemId")
if callable(getattr(item_id, "value", None)):
    item_id = item_id.value()
```

### Blank-parameter + lazy resolution pattern

Ship the notebook's parameters cell blank and resolve blanks from the workspace's Variable Library at run time. Interactive runs — including branched-out workspaces — pick up their own workspace's config with zero edits; pipeline runs pass every parameter explicitly and never touch the API, which sidesteps the no-SPN limit by design:

```python
# parameters cell:  WAREHOUSE = ""   # pipeline overrides with an explicit value

def vl_lookup(name: str):
    try:
        return notebookutils.variableLibrary.get(f"$(/**/MyConfig/{name})")
    except Exception as exc:
        raise RuntimeError(f"Variable Library lookup failed for '{name}' — is the library in "
                           "this workspace, and does this runtime support variableLibrary?") from exc

WAREHOUSE = WAREHOUSE or vl_lookup("WarehouseConnectionString")
```

## Pipeline consumption

Pipelines consume Variable Library values via a `libraryVariables` block, **sibling to** `activities` (not nested):

```json
{
  "properties": {
    "activities": [{
      "name": "Run ETL",
      "type": "TridentNotebook",
      "typeProperties": {
        "notebookId": {
          "value": "@pipeline().libraryVariables.notebook_id",
          "type": "Expression"
        }
      }
    }],
    "libraryVariables": {
      "notebook_id": {
        "libraryName": "MyConfig",
        "variableName": "notebook_id",
        "type": "String"
      }
    }
  }
}
```

Each entry needs exactly **three** keys — `libraryName`, `variableName`,
`type`. There is **no `libraryId`**: every entry in live Git-synced
pipelines carries these three and nothing else (36 entries across two
pipelines, checked 2026-09-02), and no Microsoft Learn page mentions
such a field. The object key (`notebook_id` above) is the local alias
the expression uses; `variableName` is the name in the library, and the
two need not match.

### Pipeline type mapping

Pipeline type names DIFFER from Variable Library type names. Map carefully:

| Variable Library Type | Pipeline Type |
|---|---|
| Boolean | **Bool** |
| Integer | **Int** |
| String | **String** |
| DateTime | **String** |
| Guid | **String** |
| Number | **unsupported in pipelines** |
| ItemReference | **Object** |
| ConnectionReference | **Object** |

The two advanced types are `Object`, not `String`, because the whole
point of them is property access — `.itemId`, `.workspaceId`,
`.connectionId` — which a string cannot carry:

```json
"notebookId": { "value": "@pipeline().libraryVariables.NotebookRef.itemId",
                "type": "Expression" }
```

`Object` is confirmed against live Git-synced pipelines (2026-09-02);
Learn documents the dotted property access but not the type name.
**`Number` has no pipeline representation at all** — Learn's
known-limitations list is explicit that Number types aren't supported in
pipelines, so a Number variable cannot be consumed from one. Use
`Integer`, or `String` and cast.

Dynamic references must be wrapped in Expression objects: `{"value": "@pipeline().libraryVariables.x", "type": "Expression"}`. Bare strings are treated as literals — not resolved.

## Lakehouse shortcut consumption

**This skill does not fire on a Lakehouse** — no `paths:` glob reaches
`shortcuts.metadata.json`, deliberately (see the note at the end of this
section). Read this when you are already here for a Variable Library.

A OneLake shortcut can bind its **target** to a variable, so one shortcut resolves to a different item per environment. In Git this lands in `<Name>.Lakehouse/shortcuts.metadata.json` — an array of shortcut objects, where the reference-path form replaces the `itemReference` value:

```json
{
  "name": "ue_Holidays_v2",
  "path": "/Tables/bronze",
  "target": {
    "type": "OneLake",
    "oneLake": {
      "path": "Tables/ue_Holidays_v2",
      "itemReference": "$(/**/MyConfig/ItemReferenceOperation)"
    }
  }
}
```

The backing variable must be type **`ItemReference`**, whose value is a `{"workspaceId", "itemId"}` GUID pair — not a lakehouse name. The Runtime ID rule below applies unchanged.

Two constraints worth knowing before designing around this:

- **Variable libraries are the only supported assignment method.** Shortcut variables cannot be assigned via REST API; the portal's *Manage shortcut → Edit target* pane is the assignment surface, and Git is where the result is read back.
- The reference is **static** — it points at one item and does not re-resolve across environments by itself. Per-stage behaviour comes from value sets, each pointing at a different item.

Whether shortcuts reach Git at all is controlled by `alm.settings.json` in the same folder, which carries an `Enabled`/`Disabled` state per target type (`Shortcuts.OneLake`, `Shortcuts.AdlsGen2`, `Shortcuts.Dataverse`, `Shortcuts.AmazonS3`, and four more) plus `DataAccessRoles`. A shortcut whose target type is `Disabled` there will not sync — check it before debugging a shortcut that "vanished" on deploy.

**Why no glob on `shortcuts.metadata.json`.** Binding a shortcut target to
a variable is one *option*, not what a shortcuts file is. Most shortcuts
carry a plain `workspaceId`/`itemId` pair and have nothing to do with
Variable Library, so a `**/*.Lakehouse/shortcuts.metadata.json` glob would
pull this skill into every Lakehouse regardless — the same over-broad shape
as the bare `**/.platform` that had to be narrowed out of
`pbip-project-structure`. The discriminator is `$(...)` *inside* the file,
where no glob can see it. Tried and reverted 2026-09-01.

## Runtime ID rule (cross-reference)

`ItemReference` variable values are passed **verbatim** to consumers — they are NOT resolved against `.platform` `logicalId`. Always store the **runtime item ID** (the GUID from the Fabric portal URL or `GET /v1/workspaces/{wsId}/items` response). See fabric-rest-api skill for the runtime-vs-logicalId distinction — using the wrong one is a leading cause of `PowerBIEntityNotFound` from pipelines.

## Gotchas

| Issue | Resolution |
|---|---|
| `.get("lib", "var")` fails at runtime | Use `getLibrary("lib").var` — always dot notation |
| `bool("false")` → `True` | Compare as string: `flag.lower() == "true"` |
| Definition rejected — `format` field | Omit `format` entirely — VariableLibrary does not support it |
| Pipeline variable wrong type | Map correctly: Boolean→Bool, Integer→Int, DateTime/Guid→String, Item/ConnectionReference→**Object**. `Number` has no pipeline type — switch the variable to Integer or String |
| Pipeline expression treated as literal | Wrap in `{"value": "...", "type": "Expression"}` |
| Pipeline variable not resolving | Check `libraryName` + `variableName` and the Expression wrapper. There is no `libraryId` — adding one is not the fix |
| `.itemId` / `.connectionId` unresolved on a library variable | Entry declared `"type": "String"`; advanced types must be `"type": "Object"` |
| Value Sets ignored | Add `valueSetsOrder` array to `settings.json` |
| Value Set validation error | Create matching file under `valueSets/` for every entry in `valueSetsOrder` |
| `PowerBIEntityNotFound` from `ItemReference` | Stored a `.platform` `logicalId` instead of the runtime item ID |
| Git sync fails `InvalidContent (ValueMismatch)` | Rename propagated to `variables.json` but not every `valueSets/*.json`, or an empty `value` — the library rejects `""`; use a `FILL-ME` sentinel |
| `AttributeError: 'str' object has no attribute 'value'` on ItemReference | Pure-Python kernel returns dict-like — `.get("itemId")` is already the GUID; only call `.value()` when it exists |
| Lookup fails under SPN / scheduled run | `notebookutils.variableLibrary` has no SPN support — pass values as notebook parameters from the pipeline |

## Reference

- Microsoft Learn: [What is a variable library? (overview + supported items)](https://learn.microsoft.com/fabric/cicd/variable-library/variable-library-overview)
- Microsoft Learn: [NotebookUtils variable library utilities for Fabric](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-variable-library)
- Microsoft Learn: [Variable library integration with pipelines](https://learn.microsoft.com/fabric/data-factory/variable-library-integration-with-data-pipelines)
- Comprehensive MS Learn link bundle (concept / variable types / value sets / per-consumer integration / REST / ADF migration): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-rest-api skill — definition envelope, runtime ID vs logicalId, `?updateMetadata=true` flag
- fabric-spark skill — `notebookutils.runtime.context` (sibling API to `notebookutils.variableLibrary`)
