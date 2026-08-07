---
name: fabric-variable-library
description: "Use for Microsoft Fabric Variable Library — config-as-code for parameterizing notebooks and pipelines across environments. Covers definition parts (variables.json, settings.json, valueSets/<name>.json — no `format` field, omit it), variable types (String, Boolean, Number, Integer, DateTime, ItemReference), notebook consumption via `notebookutils.variableLibrary.getLibrary('Lib').<var>` dot notation (NOT `.get('lib','var')`) or the `get(\"$(/**/Lib/Var)\")` reference-path form, runtime limits (same-workspace only, no SPN, active value set), the ItemReference kernel-shape trap (dict-like; `.value()` AttributeErrors), Git-sync `InvalidContent (ValueMismatch)` (stale override name or empty value), the blank-parameter + lazy-resolution pattern, the `bool('false')` → True trap, pipeline integration via the `libraryVariables` block, the type-name mapping (Boolean→Bool, Integer→Int, Number→Double, DateTime/ItemReference→String), Expression-object wrapping, `valueSetsOrder`, and the runtime-ID rule for ItemReference."
paths:
  - "**/*.VariableLibrary/**"
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

| Type | Description |
|---|---|
| `String` | Text |
| `Boolean` | true / false (stored as a string!) |
| `Number` | Floating-point |
| `Integer` | Whole numbers |
| `DateTime` | ISO 8601 |
| `ItemReference` | Fabric item GUID binding (`{itemId, workspaceId}`) |

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
        "libraryId": "<guid>",
        "variableName": "notebook_id",
        "type": "String"
      }
    }
  }
}
```

Each `libraryVariables` entry needs **all four**: `libraryName`, `libraryId`, `variableName`, `type`.

### Pipeline type mapping

Pipeline type names DIFFER from Variable Library type names. Map carefully:

| Variable Library Type | Pipeline Type |
|---|---|
| Boolean | **Bool** |
| Integer | **Int** |
| Number | **Double** |
| DateTime | **String** |
| String | **String** |
| ItemReference | **String** |

Dynamic references must be wrapped in Expression objects: `{"value": "@pipeline().libraryVariables.x", "type": "Expression"}`. Bare strings are treated as literals — not resolved.

## Runtime ID rule (cross-reference)

`ItemReference` variable values are passed **verbatim** to consumers — they are NOT resolved against `.platform` `logicalId`. Always store the **runtime item ID** (the GUID from the Fabric portal URL or `GET /v1/workspaces/{wsId}/items` response). See fabric-rest-api skill for the runtime-vs-logicalId distinction — using the wrong one is a leading cause of `PowerBIEntityNotFound` from pipelines.

## Gotchas

| Issue | Resolution |
|---|---|
| `.get("lib", "var")` fails at runtime | Use `getLibrary("lib").var` — always dot notation |
| `bool("false")` → `True` | Compare as string: `flag.lower() == "true"` |
| Definition rejected — `format` field | Omit `format` entirely — VariableLibrary does not support it |
| Pipeline variable wrong type | Map correctly: Boolean→Bool, Integer→Int, Number→Double, DateTime/ItemReference→String |
| Pipeline expression treated as literal | Wrap in `{"value": "...", "type": "Expression"}` |
| Pipeline variable not resolving | Include BOTH `libraryName` and `libraryId` |
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
