# Reflex REST operations and error codes

Drilled 2026-09-12 from the Fabric REST reference (`rest/api/fabric/reflex/items/*`)
and [Troubleshoot Fabric Activator errors](https://learn.microsoft.com/fabric/real-time-intelligence/data-activator/activator-troubleshooting).

## The seven operations

Base: `https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}`

| Operation | Verb and path | Permission | Delegated scopes |
| --- | --- | --- | --- |
| List Reflexes | `GET /reflexes` | *viewer* workspace role | `Workspace.Read.All` or `Workspace.ReadWrite.All` |
| Create Reflex | `POST /reflexes` | *contributor* workspace role | `Reflex.ReadWrite.All` or `Item.ReadWrite.All` |
| Get Reflex | `GET /reflexes/{id}` | see note | — |
| Update Reflex | `PATCH /reflexes/{id}` | see note | — |
| Delete Reflex | `DELETE /reflexes/{id}` | see note | — |
| Get Reflex Definition | `POST /reflexes/{id}/getDefinition` | **read *and write*** on the reflex | `Reflex.ReadWrite.All` or `Item.ReadWrite.All` |
| Update Reflex Definition | `POST /reflexes/{id}/updateDefinition` | see note | — |

**Note on the four rows not drilled individually.** Only List, Create
and Get Definition were read in full. Get / Update / Delete Reflex and
Update Reflex Definition are confirmed to **exist** in the namespace,
but their permission and scope lines were not read — do not state them.
Get Reflex is documented elsewhere as returning the same metadata as the
generic Get Item API.

### List Reflexes

`GET /reflexes?recursive={bool}&rootFolderId={guid}&continuationToken={token}`

Paginated. `recursive` defaults to **true** (items in the folder and all
nested folders). Response items carry `id`, `displayName`,
`description`, `type`, `workspaceId`, `sensitivityLabel`, and may carry
`folderId`, `tags` and `defaultIdentity`. `continuationToken` /
`continuationUri` are removed from the response when there are no more
records. Error: `InvalidItemType`.

This is the **only** drilled read-only route into an Activator. It gives
you the inventory and nothing about the rules inside.

### Create Reflex

Request body:

| Field | Required | Notes |
| --- | --- | --- |
| `displayName` | **yes** | Must follow item-type naming rules |
| `definition` | no | `ReflexDefinition` — `format` + `parts` |
| `description` | no | **Max 256 characters** |
| `folderId` | no | Defaults to the workspace |
| `sensitivityLabelSettings` | no | `labelId` + `sensitivityLabelApplyStrategy` |

`sensitivityLabelApplyStrategy` is `ApplyOrFail` (the default — fail the
operation if the label cannot be applied) or `Ignore`.

Responses: `201 Created`, or `202 Accepted` with `Location`,
`x-ms-operation-id` and `Retry-After` while provisioning. `429` carries
`Retry-After`.

Error codes: `InvalidItemType`, `ItemDisplayNameAlreadyInUse`,
`CorruptedPayload`, `WorkspaceItemsLimitExceeded`.

Limitation: the workspace must be on a supported Fabric capacity.

**`displayName`, not `name`.** Upstream reports the wrong field failing
with `HTTP 400 DisplayName field is required`; the requirement is
documented, that literal string is upstream's observation.

### Get Reflex Definition

`POST /reflexes/{id}/getDefinition?format={format}`

- **Needs read *and write* permissions.** There is no read-only route to
  a definition.
- **Blocked for a Reflex with an encrypted sensitivity label.**
- The sensitivity label is not part of the returned definition.
- Supports LRO: `200` with the definition, or `202` + `Location` +
  `x-ms-operation-id` + `Retry-After`.
- Error: `OperationNotSupportedForItem`.

### Update Reflex Definition

Confirmed to exist. The platform-part rule is documented on the Reflex
definition page: `updateDefinition` accepts `.platform` **only if you
set the URL parameter `updateMetadata=true`**.

### Identity support

Create, List and Get Definition all support **User** and **service
principal / managed identity**.

## Error codes

Activator emails an error code when something breaks after creation.
Recipients are set per item at **Home > Settings > Notifications**.

### Data ingestion

| Code | Cause | Fix |
| --- | --- | --- |
| `PowerBiSourceNotFoundOrInsufficientPermission` | Semantic model deleted, or permissions changed since the alert was made | Check the dataset exists and you can access it; if deleted, objects and rules stop working — recreate on another model |
| `QueryEvaluationError` | The semantic model's structure changed after the alert was created | Restore the original structure, or delete the object and recreate the rule |
| `EventHubNotFound` | The Eventstream was deleted, or its connection to the Activator was removed | Reconnect an Eventstream to the object |
| `EventHubException` | Eventstream raised an exception on import | Inspect the Eventstream and its connection for errors |
| `UnauthorizedAccess` | Eventstream permissions changed since connection | Restore access to the Eventstream item |
| `IncorrectDataFormat` | Event data is not in a format Activator recognises | Data must be JSON dictionary format |

### Rule evaluation

| Code | Cause | Fix |
| --- | --- | --- |
| `ProcessingLimitsReached` | Too many events/second, or the rule activates too often | Reduce event rate, or make the rule fire less often |
| `WorkspaceCapacityDeallocated` | The workspace's capacity is deallocated | Have a capacity assigned to the workspace |
| `DefinitionFailedValidation` | Rule definition invalid — documented as an **internal** Activator problem | Ask on the Activator community site |
| `MaxDelayReached` | No incoming data for the rule for seven days; the rule is not being evaluated — documented as internal | Ask on the Activator community site |
| `PreviewActivatorMigrationRequired` | Item created during the preview period and needs manual migration | Follow the migration blog post |

### Exceeded capacity

| Code | Cause | Fix |
| --- | --- | --- |
| `CapacityLimitExceeded` | Capacity limit exceeded for **more than 24 hours**; throttling pauses rule evaluation, background operations and activations | Fix capacity, then **reactivate the rules** — they do not resume on their own |

### Alerts and actions

| Code | Cause |
| --- | --- |
| `UserNotFound` | Recipient of an email or Teams alert could not be located |
| `EmptyEmailPropertyForUser` | Your email address is not set in your Azure profile (blocks the test action) |
| `RecipientThrottled` | Recipient is over the message limit — see the limits table in SKILL.md §9 |
| `FabricItemThrottled` | Too many Fabric-item activations in the window (50/user/minute) |
| `BotBlockedByUser` | Recipient blocked the Activator Teams bot |
| `TeamsAppBlockedInTenant` | Teams admin blocked the Activator app |
| `BotNotInstalledInTeamsChatOrChannel` | Activator bot is not installed in the target chat or channel |
| `ReflexAppDisabledInTenant` | The "Reflex - Public" Entra application is disabled org-wide |
| `MessageRecipientAmbiguous` | Multiple users share the same email address or UPN |
| `OfficeSubscriptionMissing` | No Microsoft Office subscription |
| `TeamsDisabled` | Entra tenant blocks the Microsoft Teams service principal |
| `TeamsChatOrChannelNotFound` | The configured Teams chat or channel no longer resolves |
| `FabricItemNotFound` | The action's Fabric item no longer exists |
| `FabricItemExecutionUnauthorized` | Unauthorized while executing the item — reselect the item and save the rule again |
| `FabricItemExecutionNoPermissions` | Permission error executing the item — get access, or ask its creator |
| `BlockedByOutboundAccessProtection` | Outbound Access Protection on the workspace blocks the action |

Note how many of these are **tenant- or Entra-level** rather than
Activator problems: `ReflexAppDisabledInTenant`, `TeamsDisabled`,
`TeamsAppBlockedInTenant`, `OfficeSubscriptionMissing`,
`BlockedByOutboundAccessProtection`. A rule that evaluates correctly and
delivers nothing is usually one of these, and none of them is fixable
inside the Activator item.

## Symptom table

Reproduced from the troubleshooting page's own table:

| Symptom | Possible cause | Remediation |
| --- | --- | --- |
| Rules not firing | Eventstream not pushing data, incorrect object keys, conditions never met | Validate stream connectivity, use rule preview, check object schema mapping |
| Alert spam or repeated triggers | Stateless operators (e.g. *less than*) instead of stateful (e.g. *decreases*) | Redesign with `DECREASES` / `BECOMES`, or debounce |
| No actions triggered | Misconfigured action target, or rule not satisfied | Check action bindings; ensure payloads match what the target expects |
| Unexpected latency over 30 s | Cold start, high object cardinality, or Eventstream bottleneck | Warm up with test events, review cardinality, check Eventstream diagnostics |
| "No data" errors after 10 min | Source idle or disconnected | Monitor source health; add heartbeat rules |
| Firing too often in test | Synthetic or replayed fast-changing data | Use deduplicated test data and filters |

## Diagnostics

- **Preview a rule** before activating — shows how often it would have
  fired on historical events. Catches misconfigured filters,
  high-frequency triggers and wrong object grouping.
- **Eventstream monitoring panel** — confirm flow, timestamps and
  payload structure; spot dropouts and format mismatches.
- **Triggered-action logs** — pipeline run history and Power Automate
  logs carry timestamp, payload, triggering rule and success/failure.
- **Schema mismatch is silent.** Activator "might silently fail to bind
  rules to data" on a misspelled field or a string/numeric mismatch.
  Confirm schema in Eventstream's live sample view *before* creating the
  rule.

## Escalating to Microsoft

The documented ticket contents: workspace and activator name,
Eventstream source details, rule IDs and conditions, approximate
timestamps and affected object keys, and the triggered action's
configuration with the expected outcome. Sanitized sample event
payloads, screenshots of rule preview and monitoring, and whether it
reproduces elsewhere all help.
