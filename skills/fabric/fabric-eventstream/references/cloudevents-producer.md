# Producing to a schema-associated custom endpoint

The **producer** wire format — how an external app must format events it
pushes to a schema-associated custom-endpoint source. Verified end-to-end
(2026-07-07 / 2026-08-06) and **not documented on Microsoft Learn**.

This is the **producer** side — how an *external* app must format events it pushes to a custom-endpoint source. The Eventstream authoring side (adding the source, wiring destinations) is above; this section is what the sending code has to get right. Applies only when the custom endpoint has an **associated schema** (a schema group / EventDefinition set). The portal's authoritative reference is the endpoint's **Show sample code → Event Hub tab**, which emits `CloudNative.CloudEvents` SDK code.

Verified end-to-end (2026-07-07) by pushing records and reading them back via Kusto; this wire format is **not** documented on Microsoft Learn (the extended-features docs describe the UI, not the format).

### Binary content mode is required — not structured

The endpoint's Azure Stream Analytics EventHub input adapter reads CloudEvents attributes from the Event Hub message's **application properties** (CloudEvents AMQP **binary** content mode), *not* from the JSON body. Structured mode — the whole CloudEvent in the body with `ContentType=application/cloudevents+json` — is **silently ignored**: the adapter still hunts for a `type` property, doesn't find it, and drops the event with:

```
Microsoft.Streaming.AzureStreamAnalytics.Adapters.Input.EventHub.Exceptions.CloudEventPropertyMissingException: CloudEvent property type is missing.
```

### Correct per-event shape (`Azure.Messaging.EventHubs.EventData`)

- **Body** = the data payload JSON *only* (just the record fields — not a wrapped CloudEvent).
- **ContentType** = `application/json`.
- **Application properties**, each prefixed `cloudEvents:` (the CloudEvents AMQP binding convention):

| Property | Value | Notes |
|---|---|---|
| `cloudEvents:specversion` | `1.0` | |
| `cloudEvents:type` | schema name, e.g. `Orders` | **Selects the schema** — must exactly match a schema id in the associated set (**case-sensitive**) |
| `cloudEvents:source` | any non-empty URI | Value unconstrained by the schema envelope |
| `cloudEvents:id` | fresh GUID per event | CloudEvents requires `source`+`id` unique |
| `cloudEvents:dataschema` | `https://<host>.<region>.messagingcatalog.azure.net/schemagroups/<schema-set itemId>/schemas/<type>/versions/<vN>` | **Required to route to a table** — the `/versions/vN` segment supplies `{CloudEventSchemaVersion}` |

The portal sample copies the attributes generically:

```csharp
foreach (var attr in cloudEvent.GetPopulatedAttributes())
    eventData.Properties[$"cloudEvents:{attr.Key}"] = attr.Value?.ToString();
```

### Where the schema-group base URI comes from

Anatomy of the base: `https://<host>.<region>.messagingcatalog.azure.net/schemagroups/<groupId>` — the producer appends `/schemas/{type}/versions/{vN}` itself.

- **`<groupId>` = the Event Schema Set's runtime item id** (verified 2026-08-06 across three schema sets: the group GUID in each working `dataschema` equals the schema set's item id). The group half IS therefore derivable — store an ItemReference to the schema set (e.g. in a Variable Library) and use its `itemId`.
- **`<host>` (`rthprod…` label) is service-generated and per schema set** — three schema sets in one tenant + region produced three different hosts (verified 2026-08-06). It is NOT tenant- or region-stable: never share it across environments; capture it per schema set. `rth` = Real-Time hub, `prod` = service ring; the rest is an opaque scale-unit/instance label.
- The host is the **Fabric-auto-provisioned Azure Schema Registry** ("messaging catalog") endpoint. It's **not surfaced in the Fabric portal UI** except inside the custom endpoint's **Show sample code → Event Hub tab** — copy it from there (verified 2026-07-08).
- **Not present in the git-synced Eventstream definition** either: the `.Eventstream` folder (`eventstream.json`, `eventstreamProperties.json`, `.platform`) carries `schemaMode` and the `{CloudEventType}_{CloudEventSchemaVersion}` table template but **no `messagingcatalog` host** (verified 2026-07-08). The CustomEndpoint source's `properties` is `{}`.

### Two independent gates

1. **Envelope gate** — the adapter finds `type` in the application properties. Fails with `CloudEventPropertyMissingException` if attributes are in the body or not `cloudEvents:`-prefixed.
2. **Schema-validation gate** — the body fields must match the Avro schema types. All-string schemas pass easily; non-string fields (Avro `bytes` / `boolean`) reject mismatched JSON values. A failure here shows a generic *"dropped per schema registry error policy"* diagnostic (not the envelope exception).

### Destination table naming (Eventhouse)

A schema-associated eventstream → Eventhouse (processed ingestion) **auto-creates one table per schema**, named `{CloudEventType}_{CloudEventSchemaVersion}` — e.g. `Orders_v1`, `Products_v2`. The version comes from the `dataschema` `/versions/vN` segment.

### Version-bump gotcha

**Editing a schema in the set mints a new version** (it does not edit in place). The `dataschema` URI must point at the **current** version, and versions can differ across schemas in the same set (observed: `Orders` / `Customers` at `v1`, `Products` at `v2` after a `bytes`→`string` edit). Point at the wrong version → the event validates against the old version's types → dropped. (Open question: whether Fabric accepts a `latest` form in `dataschema` to avoid pinning — untested.)

Reference C# implementation: `edgebridge.core/Helpers/AzureEventHubPusher.cs` (`SendBatch` sets the `cloudEvents:*` props; `ExportToAzureEventHub` is the SDK path) and `edgebridge.core/Models/Job/JobOutput.cs` (`BuildDataSchema`).

### Custom endpoint connection anatomy (Event Hub mode)

Everything in a custom endpoint's connection string except the key follows service-generated naming conventions (verified 2026-08-06 against three real endpoints):

```
Endpoint=sb://<namespace>.servicebus.windows.net/;SharedAccessKeyName=key_<guid>;SharedAccessKey=<secret>;EntityPath=<namespace>_eh
```

- **Namespace**: `eseh<random>` (e.g. `esehexampleabcdefgh123`) — the portal labels it "Event hub name".
- **EntityPath** (the hub — `eventhub_name` in SDKs): always **`<namespace>_eh`**. Derive it; don't store it separately.
- **SAS policy name**: `key_<guid>` — not secret. Only `SharedAccessKey` is secret material.

This enables a **parts-built connection string**: namespace + key name in per-environment config (Variable Library), only the key in Key Vault, assembled at run time — see `fabric-variable-library` (blank-parameter resolution pattern). Caveat: these are observed service conventions, not documented contracts; if the `_eh` suffix ever changes, the failure mode is an Event Hubs entity-not-found at send time.

Schema support itself is a **creation-time flag**: it cannot be enabled on an existing eventstream, and schema-enabled eventstreams don't survive deployment pipelines with their registries intact — plan workspaces accordingly (e.g. one shared multi-environment workspace for the schema-enabled ingestion edge, one endpoint + schema set per environment).

## Gotchas

| Issue | Cause | Fix |
|---|---|---|
| `CloudEventPropertyMissingException: ...type is missing` when pushing to a schema-associated custom endpoint | Attributes sent in the body / structured mode | Use CloudEvents **binary** mode: `cloudEvents:`-prefixed application properties (esp. `cloudEvents:type`), body = payload JSON only. See *Producing to a schema-associated custom endpoint* above |
| Event associates in **Data preview** but no table is written | Missing / wrong `cloudEvents:dataschema` | Set `dataschema` to the current schema version URI (`/versions/vN`) — it's what routes to a table |
| Event dropped after editing a schema | The schema edit bumped the version | Update `dataschema` `/versions/vN` to the new current version; versions can differ per schema in the same set |
| Events rejected / missing after copying producer config to another environment | Schema-registry host or group id reused across environments | Host and group are **per schema set** — capture `<host>`, `<region>`, and the schema set's itemId per environment |
