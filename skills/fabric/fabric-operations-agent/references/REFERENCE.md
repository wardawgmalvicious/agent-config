# Operations Agent — behavioural reference

Detail that belongs to the *running* agent rather than to
`Configurations.json`. All verified **2026-09-02** against the Learn
pages listed at the bottom. The item is preview throughout.

## Conditions: state vs transition

The agent runs each rule's query **every 5 minutes** while active and
tracks the result against a condition. The state/transition split is the
whole game — choosing `Is above` where you meant `Crosses above` is how
an agent floods a Teams channel.

- **State conditions** are met *any time* the current value satisfies
  them, so they re-signal on every evaluation while the value holds. Use
  one when you care about *being* in a state.
- **Transition conditions** are met *only at the moment* the value
  changes from not satisfying to satisfying — including from null — and
  do not signal again until the value leaves and re-enters. Use one when
  you care about the *change*.

| Condition | Type | When it's met |
| --- | --- | --- |
| Is above | State | Any time the property is above the value |
| Crosses above | Transition | Property changes from below to above (or from null to above) |
| Is below | State | Any time the property is below the value |
| Crosses below | Transition | Property changes from above to below (or from null to below) |
| Enters range | Transition | Property changes from outside to inside the range |
| Exits range | Transition | Property changes from inside to outside the range |
| Is | State | Any time the property matches the value |
| Becomes | Transition | Property changes to the value from a different value (or null) |

Each rule is backed by an explicit query you can inspect. Copy it into a
KQL Queryset or the Ontology graph query editor to test it — for KQL,
replace the `startTime` / `endTime` parameters with recent timestamps or
`now()`.

## Data source constraints

Decide these while designing the Eventhouse or ontology — none is
workaroundable once the agent exists.

- **One data source per agent.** Full stop.
- **Eventhouse: regular tables only.** Shortcut tables, functions and
  materialized views are all unsupported. Flatten nested JSON columns
  before configuring the agent — flat tables with descriptive column
  names parse better.
- **Populate the ingestion time column.** The agent defaults to a
  table's ingestion time to identify when records arrived, and uses it
  both to query for the latest data and to calculate change over time.
- **Ontology is more limited than Kusto.** It must live in the **same
  workspace** as the agent; entities to be monitored need at least one
  **static property** to serve as the identifier, with timeseries
  properties bound to eventhouse fields; only **basic property values**
  are supported (no average, minimum or maximum); and rules requiring
  **`AND` conditions are not supported** at all.
- **Quote awkward column names.** A rule referencing a column or
  property whose name contains special characters — underscores or
  hyphens — must enclose it in double quotation marks.

## Instruction authoring

The docs give a shape worth reproducing: split **Operational
Instructions** from **Semantic Instructions**, one rule per line,
higher-priority rules first (position affects how an LLM weights them),
and numeric thresholds rather than "high" / "low".

```
*** Operational Instructions ***
1. Alert me when a trip has high occupancy level.
2. Alert me when a trip has high departure delay.

*** Semantic Instructions ***
1. Information about a trip can be found in 'TripUpdateFlattened' table,
   each identified by the 'trip_id' column.
2. Occupancy status of a trip is calculated as the latest occupancy
   status from the vehicle the trip is associated with. The value 'HIGH'
   means high occupancy level.
3. The departure delay is measured in number of seconds. Higher than 300
   seconds of delay is considered significant.
```

Other best practices: add plain-language **column descriptions** in the
KQL table schema where a name is unclear; name the column that uniquely
identifies the business object (`StationID`, `SensorID`) and say which
table it belongs to; review executed queries in the KQL database's
**Query insights** tab.

Copilot chat (from the ribbon) can draft the instructions and rules
conversationally, and reports back when an instruction is unclear,
references unavailable data, or asks for an unsupported condition or
action.

## Billing meters

All **background usage**, so throttled only after the capacity is over
its limits for 24 hours — at which point background tasks are rejected
and the agent's processing halts.

| Fabric operation | Rate |
| --- | --- |
| Operations agent compute | **0.46 CU-hours per hour** |
| Operations agent autonomous reasoning | 400 CU-s / 1,000 input tokens; 40 CU-s / 1,000 cached input; 1,600 CUs / 1,000 output |
| Investigation agent reasoning | same rates as autonomous reasoning |
| Copilot in Fabric | 100 CUs / 1,000 input tokens; 10 CU-s / 1,000 cached input; 400 CUs / 1,000 output |
| OneLake storage | per GB per hour; monitored data retained **30 days** |

Three phases drive consumption. **Configuration**: Copilot while
generating the playbook, plus Eventhouse queries to identify fields.
**Active monitoring**: the compute meter, plus Eventhouse charges for the
5-minute queries and storage for cached results. **Condition met**: a
reasoning meter, plus any Power Automate licensing for an approved flow.

Pausing the capacity stops the meter.

## Action configuration

Three paths, all reachable from **Add action** in Agent setup.

- **Teams message** — the default; no configuration needed to reach the
  creator. Under *Agent behavior* → **Edit**, choose a direct message to
  an individual or a post in a Teams channel. Recipients must be in your
  organization and hold **write** permission on the agent item.
- **Fabric item action** — browse to an item and select the function.
  Runs notebooks, pipelines, user-defined functions and other items. The
  action's name and description are what the agent uses to decide *which*
  action fits the condition, so write them for that purpose.
- **Power Automate action** — select a workspace and an **Activator**
  item, which stores the connection and is used for nothing else. Copy
  the connection string, open the flow builder, paste it into
  **Connection string**, and save. Parameter values reach the flow
  through dynamic content.

Install the **Fabric Operations Agent** Teams app to receive messages; it
is in the Teams app store if it does not install automatically.

## Investigator insights (preview)

When the agent detects an anomaly it automatically runs Investigator
insights to explain it, without you querying anything. Open the agent's
Teams message → **Investigate further** → **View full investigation**.
Sections: **Investigation scope** (the table analysed), **Key
observations** (actual values, deviations from baseline, trends and
outliers), and **Pattern analysis** (dimensions that changed
significantly, signals that shifted).

A "no meaningful patterns" result is a normal outcome, not a failure —
it means the investigation ran and found no correlated signals. Results
are also suppressed when the analysis contradicts the alert logic,
produces irrelevant information, or exceeds Teams message limits.

## Runtime, identity and availability

- Queries run **every 5 minutes** when active.
- **Operations expire after three days** with no action taken, and
  cannot then be approved.
- **One data source per agent.**
- Each agent gets its own **Microsoft Entra Agent ID** (a specialized
  service principal), so actions attribute to the agent rather than an
  anonymous user session, and the agent outlives the creator's account
  lifecycle. Visible in the item's status bar.
- The agent nevertheless runs **delegated (OBO) as its creator** —
  queries and actions use the creator's credentials, and changing the
  recipient does not change that.
- Heavy usage can throttle messages, in which case Teams gets simplified
  non-LLM-generated text.
- Outputs are probabilistic. **English only** for instructions and goals.
- Azure public cloud Fabric regions only, **excluding South Central US
  and East US**. Not in sovereign clouds (GCC-High, Bleu). Not in
  workspaces encrypted with customer-managed keys. **Trial capacities are
  not supported.**
- Tenant settings required: operations agent, Microsoft Copilot and Azure
  OpenAI. If the capacity is not in a US or EU region, also enable Azure
  OpenAI cross-geo processing and storage.

## Sources

- [Create and configure operations agents](https://learn.microsoft.com/fabric/real-time-intelligence/operations-agent)
- [Operations agent actions](https://learn.microsoft.com/fabric/real-time-intelligence/operations-agent-actions)
- [Operations agent best practices and limitations](https://learn.microsoft.com/fabric/real-time-intelligence/operations-agent-limitations)
- [Operations agent capacity and billing](https://learn.microsoft.com/fabric/real-time-intelligence/operations-agent-billing)
- [Operations Agent for Pipelines (preview)](https://learn.microsoft.com/fabric/data-factory/operations-agent-for-pipelines)
- [Create an operations agent grounded in an ontology](https://learn.microsoft.com/fabric/iq/ontology/how-to-create-operations-agent)
- [Git integration → Supported items](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration#supported-items)
- [Variable library overview → Supported items](https://learn.microsoft.com/fabric/cicd/variable-library/variable-library-overview#supported-items)
