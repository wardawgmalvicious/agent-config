# Skill handoff brief: fabric-dataflow

Last verified: 2026-09-12

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

`skills/fabric/fabric-dataflow/SKILL.md`, plus `references/REFERENCE.md`.

Deployable payload in the `fabric` group. On this machine that group is
**pruned from user scope on purpose**, so the linker will not deploy it
and no session's listing changes when it lands. That is the designed
outcome, not an omission — it reaches a client repo through
`link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups fabric`
or `copy-copilot.ps1 -SkillGroups fabric`.

The group directory is load-bearing. `skills/fabric-dataflow/SKILL.md`
would be skipped by the depth-pinned pre-commit hook *and* invisible to
Claude Code's one-level discovery — two silent failures from one
misplacement.

## Scope

Covers the Fabric **Dataflow Gen2 item** as Git and REST see it: the
`.Dataflow` folder and its definition parts, the typed `/dataflows` REST
namespace and the permissions each call needs, the execute/refresh/publish
job surface, the three documented CI/CD patterns, the Gen1 upgrade routes,
and the operational limits that decide whether a design works. Inline,
model-invocable, path-scoped to `**/*.Dataflow/**`.

It is **not** a port of upstream's `dataflows-cli`. That skill is a
three-mode dispatcher built on `az rest` whose authoring mode leans on an
endpoint its own documentation calls internal and undocumented. This one
is written from Microsoft Learn, describes the item rather than a CLI
session, and declines that surface — see Sources drilled and Notes.

## Sources drilled

**Drilled — Fabric REST reference (`microsoft-learn-mcp`, firsthand this
session):**

- [Dataflow definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/dataflow-definition)
  — the three definition parts and which are required; `formatVersion`
  accepts only `202502`; the `queriesMetadata`, `connections[]`,
  `queryGroups` and `computeEngineSettings` shapes; and the worked
  `mashup.pq` and MDF examples. This page establishes the composite
  `connectionId` shape.
- [Create Dataflow](https://learn.microsoft.com/rest/api/fabric/dataflow/items/create-dataflow)
  — contributor role, `Dataflow.ReadWrite.All` / `Item.ReadWrite.All`,
  201-or-202, supported-capacity limitation, and the `ItemType` enum that
  confirms `Dataflow` as the type name.
- [List Dataflows](https://learn.microsoft.com/rest/api/fabric/dataflow/items/list-dataflows)
  — viewer role, `Workspace.Read.All`, pagination.
- [Get Dataflow Definition](https://learn.microsoft.com/rest/api/fabric/dataflow/items/get-dataflow-definition)
  — **read *and write* permission**, POST not GET, LRO, and the sample
  whose four parts were base64-decoded here to confirm the on-disk shapes.
- [Update Dataflow Definition](https://learn.microsoft.com/rest/api/fabric/dataflow/items/update-dataflow-definition)
  — read and write, `?updateMetadata`, `CorruptedPayload`, and a sample
  that **includes `.platform`**.
- [Discover Dataflow Parameters](https://learn.microsoft.com/rest/api/fabric/dataflow/items/discover-dataflow-parameters)
  — read permission, service principals supported, nine parameter types
  with their exact string formats, and `DataflowNotParametricError`.
- [Run On Demand Execute](https://learn.microsoft.com/rest/api/fabric/dataflow/background-jobs/run-on-demand-execute)
  — member role, `Dataflow.Execute.All`, **service principals not
  supported**, the `executeOption` enum marking `SkipApplyChanges` as
  Default Value, and the path-form job type.
- [Run On Demand Item Job](https://learn.microsoft.com/rest/api/fabric/core/job-scheduler/run-on-demand-item-job)
  — the generic route, and the note that the job type moved from query
  parameter into the path with the old form still supported.

**Drilled — Fabric product documentation (firsthand):**

- [Dataflow Gen2 with CI/CD and Git integration](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-cicd-and-git-integration)
  — save-replaces-publish, the zero-row validation and its 10-minute
  schema ceiling, just-in-time publishing and the **February 1 2026**
  rule that a failed publish now fails the refresh, and four limitations
  including the manual save needed after a Git sync.
- [Public APIs capabilities for Dataflow Gen2](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-public-apis)
  — the generic-route operation table, and five current limitations: no
  service principal, `Get Item` filtering broken for the type, untyped
  calls returning the CI/CD item, **no destination authoring through the
  definition API**, and run APIs that can be invoked but never succeed.
- [CI/CD and ALM solution architectures](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-cicd-alm-solution-architecture)
  — the three patterns, absolute references by default, statically bound
  connections, and deployment rules that cannot touch connections or
  mashup logic.
- [Use public parameters](https://learn.microsoft.com/fabric/data-factory/dataflow-parameters)
  — the opt-in toggle, required-versus-optional semantics, and the
  limitation list including the scheduling block and the incremental
  refresh incompatibility.
- [Relative references](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-relative-references)
  — name-based binding via `!(Current Workspace)`.
- [Migrate using Save As](https://learn.microsoft.com/fabric/data-factory/migrate-to-dataflow-gen2-using-save-as)
  and [Upgrade Wizard](https://learn.microsoft.com/fabric/data-factory/migrate-to-dataflow-gen2-using-upgrade-wizard)
  — the two portal routes, the wizard's in-place irreversibility, its
  eight Needs-Attention reasons, the 50-enabled-query gate, the 24-hour
  retry lockout, the 30-day soft-delete window blocking outbound access
  protection, and the legacy-versus-modern connector swap with both M
  snippets.
- [Save Dataflow Gen One As Dataflow Gen Two](https://learn.microsoft.com/rest/api/power-bi/dataflows/save-dataflow-gen-one-as-dataflow-gen-two)
  — the Power BI REST preview call behind Save As, its four request
  fields, and its three non-fatal error codes.
- [Dataflow refresh](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-refresh)
  — **re-read firsthand after extraction**: the six refresh limits, the
  two auto-pause rules, the misleading `The key didn't match any rows in
  the table` error and its documented workaround, cancellation outcomes,
  and the 90-day staging-permission failure.
- [Data Factory limitations](https://learn.microsoft.com/fabric/data-factory/data-factory-limitations#data-factory-dataflow-gen2-limitations)
  — **re-read firsthand**: the 50-query cap and what does not count
  toward it, the Lakehouse naming and type restrictions, the six-version
  gateway window, the one-hour OAuth2 refresh ceiling, the Delta
  case-sensitivity collision, the 10-minute publish limit, guest-user
  exclusion, viewer-cannot-consume, and the 90-day staging re-auth.
- [Dataflow Gen2 pricing](https://learn.microsoft.com/fabric/data-factory/pricing-dataflows-gen2)
  — **re-read firsthand**: the two-tier CI/CD rate and its exact formula,
  the flat non-CI/CD rate, high-scale and fast-copy rates, and that fast
  copy bills aggregate core-seconds rather than wall clock.

**Drilled by subagent, quotes recorded, not independently re-read** —
[overview](https://learn.microsoft.com/fabric/data-factory/dataflows-gen2-overview),
[monitor](https://learn.microsoft.com/fabric/data-factory/dataflows-gen2-monitor),
[workspace monitoring](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-workspace-monitoring),
[incremental refresh](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-incremental-refresh),
[data destinations](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-data-destinations-and-managed-settings),
[variable libraries](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-variable-library-integration),
[variable references](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-variable-references),
[move queries](https://learn.microsoft.com/fabric/data-factory/move-dataflow-gen1-to-dataflow-gen2),
[fast copy](https://learn.microsoft.com/fabric/data-factory/dataflows-gen2-fast-copy),
[Dataflow activity](https://learn.microsoft.com/fabric/data-factory/dataflow-activity),
[parameterized tutorial](https://learn.microsoft.com/fabric/data-factory/dataflow-gen2-parameterized-dataflow),
[item ownership take-over](https://learn.microsoft.com/fabric/fundamentals/item-ownership-take-over),
and the Dataflow rows of the Git-integration and deployment-pipeline
supported-item lists. 262 quoted claims, in the run log. The three
carrying the most numbers were re-read firsthand and are listed above;
anything drafted from the remainder cites its page.

**Drilled — upstream and CLI, for scoping rather than for content:**

- `microsoft/skills-for-fabric@24cc0d2` `skills/dataflows-cli/` — the
  dispatcher plus nine reference files, surveyed into 38 endpoint rows and
  168 behavioural claims. Read to decide what this skill declines, not as
  a source of fact: the registry entry records that this catalog's claims
  are another team's, drilled rather than trusted.
- `microsoft/fabric-cli@b7af89b` `docs/` — `.Dataflow` is a supported
  **item** type for the filesystem commands, and is **absent** from the
  `job` group's supported types (`.Notebook`, `.DataPipeline`,
  `.SparkJobDefinition`, `.Lakehouse`). Release notes date Dataflow
  support to v1.2.0, October 2025.
- `fab --version` and `fab job --help` on this machine, v1.7.0.

**Not drilled — deliberate, and nothing in the skill describes these:**

- **`executeQuery` and its Arrow IPC response.** Upstream's single most
  used call. No Learn page for it surfaced in any search; the searches
  return the Power BI *DAX* Arrow endpoint instead, which is a different
  API for a different item. Left out entirely rather than encoded from a
  second-hand source.
- **`gatewayClusterDatasources`.** Upstream's own words: "an internal
  Power BI API (v2.0 is not a public API version) … not in Microsoft's
  published REST API documentation and may change without notice." The
  skill states that no documented route resolves `ClusterId` and stops
  there.
- **Connection and gateway CRUD** — `/v1/connections*`, `/v1/gateways`.
  Real Core API, but a different subject; it belongs to a connections
  skill that does not exist yet.
- **The Power BI Gen1 read surface** — `upstreamDataflows`,
  `transactions`, `datasources`, the admin listings. Relevant only to a
  bulk migration assessment, which this skill does not attempt.
- **Four upstream reference files** were never fetched, so no claim of
  theirs is even in the survey: `mashup-preview.md` (upstream's canonical
  `executeQuery` reference), `authoring-script-templates.md`,
  `connectors.md`, `m-language.md`.
- **Two Learn pages nobody read**, found only by following a link during
  verification: `dataflow-gen2-cost-performance-benchmarks` and
  `dataflow-gen2-partitioned-compute`. The second is the one that matters
  — it changes how standard compute is billed, and the pricing page's own
  note is the only thing about it recorded here.
- **Mapping Data Flow transform authoring.** The `.mdf` part's schema was
  read and is described structurally; the Spark-backed transform *design*
  surface was not, and it is preview and unbilled.
- **Copilot in Dataflow Gen2**, the connector catalogue, and the Power
  Query editor click-path generally.
- **No live tenant was touched.** Every claim is documentation, not
  observation. Nothing here was measured against a real Dataflow item,
  which is the single biggest difference between this brief and the
  `fabric-event-schema-set` one.

## Frontmatter

```yaml
---
name: fabric-dataflow  # repo linter requires it; max 64 chars; lowercase/digits/hyphens; no "anthropic"/"claude"
description: <the 1,007-char string counted below>  # required; gated at 1,024, the Agent Skills spec cap
when_to_use: <the 480-char string counted below>  # optional; gated separately at 512; Claude Code extension, not a spec field
paths:
  - "**/*.Dataflow/**"  # narrows activation: withheld from the startup listing until a matching file is Read
# model: inherit  # ALWAYS PRESENT, ALWAYS COMMENTED — an active model: key of any value blocks Copilot slash invocation and fails lint-frontmatter.py
# effort:  # commented placeholder = inherit the session level; there is no 'effort: inherit'. Platform skills stay unpinned
disable-model-invocation: false  # ALWAYS PRESENT; repo policy is false everywhere
---
```

`effort` stays commented, matching every other platform skill: these
auto-trigger alongside real work, so a pin there governs the user's
Fabric turn rather than a discrete skill run. `allowed-tools` is not set
— the skill reads and explains, and pre-approving nothing costs at most a
permission prompt.

## Description char count

- `description`: 1,007 / 1,024
- `when_to_use`: 480 / 512

Counted with the linter's own loader, not estimated. **Seventeen
characters of headroom** on `description` — re-count after any wording
change, not once at the end. If it overflows, cut the `queryMetadata.json`
`formatVersion` clause first: it is the least load-bearing for triggering
and is stated again in the body.

## Body structure outline

1. **What is on disk.** The `.Dataflow` folder, the three definition
   parts, which two are required, and that `fabric-git-serialization`
   and `coding-m` co-load here. Name the item-type-versus-product-name
   split: the folder and API say `Dataflow`, everything a user types says
   Dataflow Gen2.
2. **`queryMetadata.json`.** `formatVersion` is `202502` and nothing
   else. `queriesMetadata` keyed by query name, `loadEnabled` defaulting
   true and stripped on read-back, `connections[]`, `queryGroups`,
   `computeEngineSettings.allowFastCopy` and `maxConcurrency`.
3. **`mashup.pq`.** A `section Section1;` document with `shared` members,
   the leading `[StagingDefinition = [Kind = "FastCopy"]]` attribute, and
   the `[ItemType = "MDF"]` placeholder member that pairs with an `.mdf`
   part. Point at `coding-m` for style and do not restate it.
4. **The composite `connectionId`, and the gap under it.** Learn's own
   example shows a stringified `{"ClusterId":…,"DatasourceId":…}` inside
   a JSON string. State plainly that **no documented endpoint resolves
   `ClusterId`**, that the only known route is an internal v2.0 Power BI
   API this skill does not use, and that this is why definition-only
   authoring of a bound dataflow is not a supported path.
5. **REST: the typed namespace and its permission split.** `/dataflows`
   for CRUD and definitions. List needs viewer; **`getDefinition` needs
   read *and* write**, so there is no read-only route to a definition —
   the same shape `fabric-activator` documents for `/reflexes`. Create
   needs contributor. Both definition calls are LRO-capable.
6. **`updateDefinition` replaces everything — and unlike a semantic
   model, it takes `.platform`.** Full-replacement is the house-wide
   rule; cite `fabric-tmdl-api` rather than re-deriving it. Then the
   contrast worth the space: `fabric-tmdl-api` says never send
   `.platform`, and the Dataflow sample sends it *with* `?updateMetadata`.
   Pair that with `fabric-rest-api`'s rule that the flag and the part
   require each other.
7. **Running one.** Three spellings of the same idea, which is the
   confusion this section exists to settle: the typed
   `/dataflows/{id}/jobs/execute/instances`, the generic
   `/items/{id}/jobs/{jobType}/instances`, and the legacy
   `?jobType=` query form that still works. `Dataflow.Execute.All`,
   member role, **user identity only — service principals are not
   supported**. Then `executeOption`: the API reference marks
   `SkipApplyChanges` as the default while the CI/CD article reads as
   though `ApplyChangesIfNeeded` is, so **pass it explicitly** — the rule
   that holds under either reading.
8. **Save, publish, refresh.** Save auto-publishes; validation is a
   zero-row schema evaluation with a 10-minute per-query ceiling;
   just-in-time publish, and the February 2026 change that makes a failed
   publish fail the refresh instead of silently running the last good
   version. A Git sync or pipeline deploy needs a manual save or a
   publish job before the next refresh uses it.
9. **What the definition API cannot do.** The five documented
   limitations, led by the one that decides architectures: **a data
   destination cannot be authored through the definition API**, so an
   API-built dataflow stages and transforms but never persists.
10. **CI/CD.** The three patterns and what each cannot do — parameters
    need a caller, variable libraries are workspace-scoped and
    `mashup.pq`-only, relative references bind by name. Connections are
    statically bound under all three; deployment rules touch neither
    connections nor mashup logic.
11. **Gen1 upgrade.** Save As versus the Upgrade Wizard, as a decision
    with a one-way door in it: the wizard is in-place, keeps the ID, and
    cannot be reverted or retried for 24 hours. The 50-enabled-query
    gate. The legacy-to-modern connector swap, with the detail that an
    import-mode consumer keeps showing data until its next refresh, so
    nothing looks broken at first.
12. **Limits that decide designs.** Refresh caps, evaluation and total
    ceilings, the 50 staged-or-destination queries and what does not
    count, publish timing, gateway versions and the OAuth2 hour.
13. **Cost.** The two-tier CI/CD rate against the flat non-CI/CD rate —
    worth stating because it means a non-CI/CD item costs more per second
    for long queries — and fast copy billing aggregate core time.
14. **Gotchas.** The misleading connector error and its workaround; the
    two staging traps; viewer cannot consume; Delta case collision;
    Lakehouse naming and type restrictions.
15. **Reference** and **See also**, matching the house shape.

`references/REFERENCE.md` takes: the full parameter-type table with
formats, the destination support matrix and data-type table, incremental
refresh in full, the fast-copy connector and threshold detail, the
wizard's eight Needs-Attention rows, monitoring schemas and KQL, and the
worked cost formulas.

## Changes from source proposal

Derived from the accepted candidate in
[skills-for-fabric brief 07](../../audits/2026-09-10/skills-for-fabric/07-decide-new-skill-candidates.md),
where the user accepted all four candidates for `/author-skill` on
2026-09-11. Four departures, all settled with the user before drilling:

- **Named `fabric-dataflow`, not `dataflows-cli`.** House convention:
  item-type naming with the `fabric-` prefix, as `fabric-copy-job` and
  `fabric-data-pipeline` already do. Singular, because every other item
  skill here is. The Gen2, Power Query and mashup vocabulary earns its
  place in the description as trigger tokens instead.
- **One skill, not upstream's three-mode dispatcher.** Authoring and
  consumption share a trigger surface here — the same folder, the same
  REST namespace — so two skills would half-match every request. The
  Gen1 upgrade half is a lookup consulted mid-task, which is the
  `references/` contract.
- **Glob-scoped to `**/*.Dataflow/**`**, matching every other item-type
  skill. The cost is recorded rather than hidden: a REST-only question
  asked with no `.Dataflow` file open does not reach this skill cold, and
  `/fabric-dataflow` answers `Unknown command` until a matching file is
  Read. `fabric-copy-job` already carries exactly that cost.
- **The architecture is not carried at all.** No mode dispatcher, no
  read-once protocol, no terminal-write table, and not the mandatory
  `x-ms-fabric-skill` telemetry header — that header identifies
  *upstream's* skill, and sending it from a differently-authored skill
  would misreport which tool made the call.

## Tag

`personal`

## Portability caveats

Two Claude Code-only fields. `paths:` is the significant one: GitHub
Copilot parses the key, warns and ignores it, so a vendored copy is
**unconditional** there — always listed, never glob-gated. A skill whose
design leans on its glob therefore behaves differently in a client repo's
`.github/skills`, and `copy-copilot.ps1` applies no transformation.
`when_to_use` is likewise ignored by Copilot and is not one of the six
fields the claude.ai upload path accepts, so a skill carrying it
hard-fails that path — the `description` half stays portable by design.
The commented `model:` and `effort:` keys are inert everywhere and an
active `model:` would break Copilot slash dispatch.

## Cross-reference dependencies

- `fabric-git-serialization` (rule) — (a) already converted. Already
  globs `**/*.Dataflow/**`, so it co-loads on every file this skill
  fires on. Serialization mechanics stay there; do not restate them.
- `coding-m` (rule) — (a) already converted. Globs `**/*.pq`, so it
  co-loads on `mashup.pq` and owns M style. The skill cites it and
  stops.
- `fabric-tmdl-api` — (a) already converted. Owns the
  "`updateDefinition` must include ALL parts" rule. This skill cites it
  and then records the `.platform` divergence, which contradicts that
  skill's semantic-model-specific advice. **The divergence is real and
  both statements are correct for their own item type** — if a later
  reader tries to reconcile them into one rule, that is the trap.
- `fabric-rest-api` — (a) already converted. Owns LRO polling, the
  `?updateMetadata` / `.platform` pairing, pagination and rate limits.
  Its `jobType` table lists Notebook, DataPipeline, SparkJobDefinition
  and SemanticModel and **does not carry a Dataflow row**; adding one is
  a candidate `/learn` edit, deliberately out of scope here.
- `fabric-cli` — (a) already converted. Its description already names
  dataflow among the job types `fab` covers; the CLI docs list
  `.Dataflow` under filesystem types only and **not** under `job`.
  Worth a `/learn` check; not this skill's edit to make.
- `fabric-variable-library` — (a) already converted. Its reference
  already links the Dataflow integration page. Consumers stay there;
  the `mashup.pq`-only constraint is stated here.
- `fabric-data-pipeline` — (a) already converted. Owns `RefreshDataFlow`
  and the deployment-pipeline rebinding trap. Pointed at **by file**,
  since the globs are disjoint and a by-name pointer would be dead.
- `fabric-cicd` — (a) already converted. Carries the "first deployment
  still needs a manual publish/refresh" row, which the just-in-time
  publish section corroborates.
- `fabric-copy-job`, `fabric-mirroring` — (a) already converted.
  Alternative ingestion items; one disambiguating clause each, no more.
- `skills/README.md` — the single catalogue entry, in the Microsoft
  Fabric platform section, whose heading count goes 31 → 32.
- `.claude/settings.json` — **a `skillOverrides` entry is required** and
  is the step that has failed twice in a row, once per authoring run.
  `scripts/lint-skill-overrides.py` now catches it. Adding it is
  `/commit`'s or a follow-up's work, not this skill's own directory, but
  it must not be forgotten.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**The two Learn pages disagree about `executeOption`'s default, and the
skill must not pick a winner.** The API reference marks
`SkipApplyChanges` as "Default Value"; the CI/CD article says "The
default for this option to `ApplyChangesIfNeeded` is true." Both were
read firsthand. The draft states the disagreement and gives the rule that
is right either way — pass `executeOption` explicitly. Same shape as the
`fabric-event-schema-set` brief's "read `versions[]` back after any edit":
when the source is ambiguous, encode the action that survives both
readings rather than the reading you prefer.

**Delegation was split deliberately, and the verification was not
delegated.** Two subagents drilled in parallel on Sonnet; both returned
verbatim quotes per claim rather than summaries. Every load-bearing
number that reached this brief — the refresh caps, the limitations list,
the CU rates — was then re-read firsthand from the page, and all three
matched. That re-read is not ceremony: a 2026-09-11 run found a subagent
marking a claim CONFIRMED against a quote that did not support it.

**The `fab` CLI finding is a negative one and worth keeping.**
`.Dataflow` is a filesystem item type for `fab` but is absent from the
`job` group's supported types, so `fab job run` against a dataflow is not
documented to work. A reader coming from `fabric-cli`'s description,
which names dataflow among the job types, could reasonably expect
otherwise. The skill says what the CLI docs say and does not guess.

**Two things this brief knows that the skill will not claim.** Upstream
asserts `loadEnabled: false` is required on a destination query or
refresh fails, and that sending fewer than three parts silently drops
queries. Neither is on any Learn page read here. They are plausible and
they are upstream's, so they are recorded in this brief and left out of
the draft — or, if carried, carried with an inline unverified marker and
this date, the way `/learn` does it.

**No live tenant was touched**, so the fresh-session test cannot check
behaviour against a real item. The trigger contract is fully testable;
the content is only reviewable.

## Confidence

- **Structure**: H — item-type skill with a `paths:` glob, the shape
  `fabric-copy-job`, `fabric-data-pipeline` and `fabric-activator`
  already share, and the glob matches a rule that already globs the same
  folder.
- **Field specs**: M — both fields fit, but `description` has 17
  characters of headroom, so the final wording decides trigger quality
  and the re-count is mandatory.
- **Body content**: H on everything drilled firsthand from the REST
  reference and the three re-read pages. **M** on the subagent-drilled
  remainder, which is quoted but not independently re-read. **L** on
  anything touching a live item: nothing here was observed.
