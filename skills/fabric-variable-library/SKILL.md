---
name: fabric-variable-library
description: "Use for Microsoft Fabric Variable Library — config-as-code for parameterizing notebooks and pipelines across environments. Covers definition parts (variables.json, settings.json, valueSets/<name>.json — VariableLibrary does NOT support the `format` field, omit entirely), supported variable types (String, Boolean, Number, Integer, DateTime, ItemReference), notebook consumption via `notebookutils.variableLibrary.getLibrary('Lib').<var>` dot notation (NOT `.get('lib','var')` — that signature does not exist), the `bool('false')` → True trap (compare strings with `.lower() == 'true'`), pipeline integration via `libraryVariables` block (sibling to `activities`), the Variable-Library-to-Pipeline type-name mapping (Boolean→Bool, Integer→Int, Number→Double, DateTime→String, ItemReference→String), Expression-object wrapping for dynamic references, Value Sets ordering via `valueSetsOrder` in settings.json, and the runtime-ID rule for ItemReference values."
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

## Reference

- Microsoft Learn: [What is a variable library? (overview + supported items)](https://learn.microsoft.com/fabric/cicd/variable-library/variable-library-overview)
- Microsoft Learn: [NotebookUtils variable library utilities for Fabric](https://learn.microsoft.com/fabric/data-engineering/notebookutils/notebookutils-variable-library)
- Microsoft Learn: [Variable library integration with pipelines](https://learn.microsoft.com/fabric/data-factory/variable-library-integration-with-data-pipelines)
- Comprehensive MS Learn link bundle (concept / variable types / value sets / per-consumer integration / REST / ADF migration): [references/REFERENCE.md](references/REFERENCE.md)

## See also

- fabric-rest-api skill — definition envelope, runtime ID vs logicalId, `?updateMetadata=true` flag
- fabric-spark skill — `notebookutils.runtime.context` (sibling API to `notebookutils.variableLibrary`)
