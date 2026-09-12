# `ReflexEntities.json` — entity reference

Every claim here is from the Learn [Reflex
definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/reflex-definition)
page, drilled 2026-09-12, except where marked otherwise.

The file is a **JSON array**. Each element:

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `uniqueIdentifier` | string (GUID) | yes | Other entities reference this value |
| `payload` | object | yes | Shape varies by `type` |
| `type` | string | yes | One of the seven below |

Parent references, both inside `payload`:

| Property | References |
| --- | --- |
| `parentContainer.targetUniqueIdentifier` | a `container-v1`; present on all entities except the container |
| `parentObject.targetUniqueIdentifier` | an `Object` time series view; present on attribute and rule views |

The documented hierarchy:

```ascii
Container
├── Data Source (simulator, KQL, Real-time Hub, or Eventstream)
├── Event View (selects/transforms events from the data source)
├── Object View (represents an entity, e.g., "Package")
│   ├── Attribute View (identity field, e.g., "PackageId")
│   ├── Attribute View (measured value, e.g., "Temperature")
│   └── Rule View (trigger + action)
└── Action (optional Fabric item reference, e.g., a Pipeline to invoke)
```

## `container-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | Display name |
| `type` | string | yes | Classification, e.g. `samples`, `kqlQueries` |

Note the collision: `payload.type` here is a *container classification*,
a different field from the entity's own top-level `type`.

## Data sources

### `simulatorSource-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | |
| `runSettings.startTime` | ISO 8601 | no | |
| `runSettings.stopTime` | ISO 8601 | no | |
| `version` | string | no | e.g. `V2_0` |
| `type` | string | yes | Simulated data type, e.g. `PackageShipment` |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |

### `kqlSource-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | |
| `runSettings.executionIntervalInSeconds` | number | no | Poll interval |
| `query.queryString` | string | yes | The KQL |
| `eventhouseItem.targetUniqueIdentifier` | GUID | yes | The Eventhouse |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |

An interval of 60–300 s keeps the Eventhouse effectively always-on — see
SKILL.md §5.

### `realTimeHubSource-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | |
| `connection.scope` | string | yes | e.g. `Workspace` |
| `connection.tenantId` | GUID | yes | |
| `connection.workspaceId` | GUID | yes | |
| `connection.eventGroupType` | string | yes | e.g. `Microsoft.Fabric.WorkspaceEvents` |
| `filterSettings.eventTypes[].name` | string | yes | e.g. `Microsoft.Fabric.ItemCreateSucceeded` |
| `filterSettings.filters` | array | no | |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |

### `eventstreamSource-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | |
| `metadata.eventstreamArtifactId` | GUID | yes | The Eventstream |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |

## `fabricItemAction-v1`

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | Display name of the action |
| `fabricItem.itemId` | GUID | yes | |
| `fabricItem.workspaceId` | GUID | yes | |
| `fabricItem.itemType` | string | yes | e.g. `Pipeline` |
| `jobType` | string | yes | e.g. `Pipeline` |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |

```json
{
  "uniqueIdentifier": "ffffffff-5555-6666-7777-aaaaaaaaaaaa",
  "payload": {
    "name": "Run alert pipeline",
    "fabricItem": {
      "itemId": "b1b1b1b1-cccc-dddd-eeee-f2f2f2f2f2f2",
      "workspaceId": "a0a0a0a0-bbbb-cccc-dddd-e1e1e1e1e1e1",
      "itemType": "Pipeline"
    },
    "jobType": "Pipeline",
    "parentContainer": {
      "targetUniqueIdentifier": "00aa00aa-bb11-cc22-dd33-44ee44ee44ee"
    }
  },
  "type": "fabricItemAction-v1"
}
```

`payload.fabricItem` is where the target lives. A `targetItem` shape is
reported upstream (`microsoft/skills-for-fabric` CHANGELOG `[0.3.13]`) as
accepted by `updateDefinition` while never resolving its target —
**unverified, and absent from every Learn page drilled**. Treat as a
warning, not a documented behaviour.

## `timeSeriesView-v1`

Four roles, distinguished by `payload.definition.type`. Shared payload:

| Property | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | yes | |
| `parentContainer.targetUniqueIdentifier` | GUID | yes | |
| `definition.type` | string | yes | `Event` / `Object` / `Attribute` / `Rule` |
| `definition.instance` | string | no | **JSON-encoded string**, see below |

### `Event`

`definition.instance` required. Templates: `SourceEvent` (select
directly from a source), `SplitEvent` (split by object identity).

### `Object`

Simplest entity in the file — `definition.type: "Object"` and nothing
else. Parent for attributes and rules.

### `Attribute`

`definition.instance` required; `parentObject` required. Templates:

| Template | Purpose |
| --- | --- |
| `IdentityPartAttribute` | Part of an object's identity |
| `IdentityTupleAttribute` | Combines identity parts into one identifier |
| `BasicEventAttribute` | Extracts a simple value from an event field |

### `Rule`

`definition.instance` required; `parentObject` optional. Templates:
`EventTrigger` (on any occurrence), `AttributeTrigger` (on a condition
over an attribute). Plus settings:

| Property | Type | Notes |
| --- | --- | --- |
| `definition.settings.shouldRun` | boolean | Whether the rule is **active**; set `true` to enable |
| `definition.settings.shouldApplyRuleOnUpdate` | boolean | Apply to historical data on update |

`shouldRun` is the field that separates a saved rule from a running one,
and a running rule bills rule uptime.

## Template instances

`definition.instance` is a **JSON-encoded string, not a nested object**,
and must be escaped inside the file. Decoded, every instance has the
same shape:

```json
{
  "templateId": "<template-name>",
  "templateVersion": "1.1",
  "steps": [
    {
      "name": "<step-name>",
      "id": "<step-guid>",
      "rows": [
        {
          "name": "<row-name>",
          "kind": "<row-kind>",
          "arguments": [
            { "name": "<arg-name>", "type": "<arg-type>", "value": "<arg-value>" }
          ]
        }
      ]
    }
  ]
}
```

`templateId` is one of `SourceEvent`, `SplitEvent`,
`IdentityPartAttribute`, `IdentityTupleAttribute`, `BasicEventAttribute`,
`EventTrigger`, `AttributeTrigger`. Row `kind` values seen in the
documented examples include `SourceReference`, `Event`, `EventField`,
`TypeAssertion`, `NumberSummary`, `NumberBecomes`, `TextValueCondition`,
`EachTime`, `TeamsMessage`, `AttributeReference`, `TimeDrivenWindowSpec`.

**Cross-entity references live in arguments.** An `entityId` argument
holds another entity's `uniqueIdentifier` — that is how an event view
names its source and a rule names its attribute. A rename that misses an
`entityId` re-points the graph silently.

### Where a column name actually lives

In a `BasicEventAttribute`, the display name and the source column are
two independent places:

- `payload.name` — e.g. `"Temperature (°C)"`
- inside the escaped instance, an `EventFieldSelector` row of kind
  `EventField` with an argument `{"name": "fieldName", "value":
  "Temperature"}`

Clone an attribute and change only the first, and it still reads the
original column.

### An `AttributeTrigger` rule, decoded

The documented four-step example: average temperature over a rolling
10-minute window, above 20, filtered to one item type, sending Teams.

| Step | Row kinds | What it does |
| --- | --- | --- |
| `ScalarSelectStep` | `AttributeReference`, `NumberSummary` + `TimeDrivenWindowSpec` | Select the attribute; `op: Average`, `width`/`hop` 600000.0 |
| `ScalarDetectStep` | `NumberBecomes`, `EachTime` | `op: BecomesGreaterThan`, `value: 20.0`; fire each time |
| `DimensionalFilterStep` | `AttributeReference`, `TextValueCondition` | `op: IsEqualTo` against another attribute |
| `ActStep` | `TeamsMessage` | `messageLocale`, `recipients`, `headline`, `optionalMessage`, `additionalInformation` |

Note `width`/`hop` are milliseconds expressed as floats
(`600000.0` = 10 minutes) with `"type": "timeSpan"`.

## Action property tables

### `TeamsMessage`

| Property | Type |
| --- | --- |
| `messageLocale` | string |
| `recipients` | array |
| `headline` | array |
| `optionalMessage` | array |
| `additionalInformation` | array |

### `EmailMessage`

| Property | Type |
| --- | --- |
| `messageLocale` | string |
| `sentTo` | array |
| `copyTo` | array |
| `bCCTo` | array |
| `subject` | string |
| `headline` | string |
| `optionalMessage` | string |
| `additionalInformation` | string |

Note the shape difference: Teams takes arrays for the text fields,
email takes strings.

### `FabricItemInvocation`

Executes a Fabric item with optional parameters, referencing a
`fabricItemAction-v1` entity by `uniqueIdentifier`.

## Minimal valid file

The documented create-request example base64-decodes to a single
container:

```json
[
  {
    "uniqueIdentifier": "00aa00aa-bb11-cc22-dd33-44ee44ee44ee",
    "payload": {
      "name": "Package delivery sample",
      "type": "samples"
    },
    "type": "container-v1"
  }
]
```

An Activator created and never configured holds `[]` instead — measured
on a real Git-synced item, 2026-09-12.

## Definition payload over REST

```json
{
  "format": "json",
  "parts": [
    { "path": "ReflexEntities.json", "payload": "<base64>", "payloadType": "InlineBase64" },
    { "path": ".platform",           "payload": "<base64>", "payloadType": "InlineBase64" }
  ]
}
```

`format` is `json` — the only supported value. `payloadType` is
`InlineBase64` — the only supported value.
