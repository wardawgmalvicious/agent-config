---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-09-10
---

# Skill handoff brief: fabric-event-schema-set

Last verified: 2026-10-01

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

Payload, in the `fabric` group:

- Repo: `skills/fabric/fabric-event-schema-set/SKILL.md`
- Deployed on this machine: **nowhere**. The `fabric` group is pruned
  from `~/.claude/skills` by design, so the new skill enters no session
  here and no linker run changes that.
- Deployed to a client repo: by group. Both routes pick up a new skill
  in the group with no change, and `copy-copilot.ps1` records it in the
  destination's `.managed-skills.json` itself — that manifest is
  generated, never edited by hand.

```powershell
./scripts/link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups fabric
./scripts/copy-copilot.ps1 -CopilotDir <repo>/.github -SkillGroups fabric
```

## Scope

Documents the Fabric **Event Schema Set** item — the `.EventSchemaSet`
folder and its single `EventSchemaSetDefinition.json` part — as the
contract a schema-associated Eventstream custom endpoint validates
incoming events against. The subject is the item's own anatomy and
editing model: the four places a human-readable description
lives, the shape of the file you upload versus the envelope the portal
generates around it, when a new schema version is and is not minted, and
the byte format the definition round-trips in.

It stops at the item boundary. The producer wire format, the
`dataschema` URI anatomy, the registry host, and the destination table
naming already belong to `fabric-eventstream` and are cross-referenced
rather than restated. What this skill adds that no existing skill has is
**which route mints a version**: every portal save that reaches
**Finish** does, even a description-only one, while a Git sync stores
`versions[]` exactly as pushed, so an edited entry changes in place and a
hand-written one is accepted (observed 2026-09-30). The rule that
follows: from Git, append a version rather than edit one, and read
`versions[]` back after any edit, by any route.

Inline, model-invocable, path-scoped.

## Sources drilled

Drilled — live verification sessions in two tenants' sandbox workspaces,
on 2026-09-10 and 2026-09-30, plus repo-internal material and Microsoft
Learn:

- **A real upload / commit-back cycle.** A 10-field schema was authored
  as an Avro record, uploaded through the portal, and the committed-back
  `EventSchemaSetDefinition.json` read to see what the service preserved,
  generated, and rewrote. This established the round-trip facts in
  Findings 1, 2, 5, 6 and 7.
- **A live version experiment, Git side only.** Description text was
  edited in Git, committed, pushed, and synced, then the resulting
  definition inspected. This is Finding 4.
- **A rejected portal form entry** at 265 characters — Finding 3.
- **Seven edits in four rounds, 2026-09-30**, in the second tenant, on a
  schema set with nothing attached: three portal saves (a field `doc`; an
  event-type description; a description again, with the Avro
  byte-identical to the last version), one upload, and three Git syncs
  (an in-place edit to two schemas' `v2`, one adding a field; a
  hand-written `v3`; a change to an event type's inline `schema` alone).
  Each was read back from the committed definition and the portal's
  History pane. Findings 1, 3, 4, 6 and 8 changed, and Finding 9 is new.
  The triage that folded this in re-read the definition's Git history the
  same day, and it agreed.
- **Microsoft Learn**, read 2026-09-30, after two URLs tried on
  2026-09-10 had returned 404: the REST
  [EventSchemaSet definition](https://learn.microsoft.com/rest/api/fabric/articles/item-management/definitions/eventschemaset-definition)
  page, the schema-set pages under
  `learn.microsoft.com/fabric/real-time-intelligence/schema-sets/`
  (`schema-registry-overview`, `create-manage-event-schema-sets`,
  `create-manage-event-schemas`, `manage-event-schema-versions`,
  `import-event-schemas`), and Real-Time hub's
  `event-schema-registry-page`. They document the definition format and
  that a portal update mints a version. They say nothing of `ancestor`,
  the top-level `name`, the newest-first order of `versions[]` or a Git
  sync, and one line is wrong for a Git sync (Finding 4).
- **Re-measured 2026-10-01, before drafting; nothing moved against the
  brief.** The sample item's newest commit was still the 2026-09-30
  inline-only change, both schemas at `v3` and one inline copy diverged;
  the `fabric-eventstream` correction stood; Learn still carried the
  line Finding 4 cites. Learn's pages also document what this brief had
  not recorded: bulk **Import** of several versions, numbered by the
  registry, a `device-telemetry-schema-example` page, and that
  registering a schema does not validate events. Newly measured: the
  whole definition re-serializes byte for byte as `json.dumps(indent=2)`
  with CRLF and no final newline (ASCII content only), and the draft's
  two Git-route scripts were run on a copy of the item. The
  deployment-pipeline note cited below was not found in the payload, so
  the draft cites `fabric-eventstream`'s nearest line instead.
- [skills/fabric/fabric-eventstream/references/cloudevents-producer.md](../../../skills/fabric/fabric-eventstream/references/cloudevents-producer.md)
  — the producer contract this skill defers to. Its "Version-bump
  gotcha" was the only evidence of a bump before 2026-09-30: `Products`
  reaching `v2` after a `bytes`→`string` retype, a **structural** edit
  whose edit path it does not record.
- The client repo's layout: its `.gitattributes` marks the workspace tree
  `-text`, a validation script there reads fields out of the definition,
  and a directory of upload files is kept under review in Git — a worked
  example of authoring outside the portal.

Not drilled, and the draft names each as untested rather than describe
it:

- **Whether the validating registry follows a Git sync**: an in-place
  edit, a hand-written version, or a diverged inline copy (Findings 8 and
  9). Nothing produced events on 2026-09-30. Still open, item 4.
- **The REST surface.** Whether `getDefinition` / `updateDefinition`
  mint versions like the Git sync path or like the portal is untested
  (Still open, items 2 and 3).
- **Deployment-pipeline behavior**, beyond the pre-existing note that a
  pipeline copy of a schema set does not populate its backing catalog.

## Frontmatter

```yaml
---
name: fabric-event-schema-set  # repo linter requires it; upstream optional — display label only, the /command comes from the directory name; max 64 chars; lowercase/digits/hyphens; no "anthropic"/"claude"
description: <FILLED — copy verbatim from "Description char count" below>  # repo linter requires it (upstream: recommended); gated at 1,024, the Agent Skills spec cap — see Description char count
when_to_use: <FILLED — copy verbatim from "Description char count" below>  # optional; appended to description in the skill listing; gated separately at 512, the Claude-Code-only remainder of the 1,536 truncation point. NOT one of the spec's six fields — a skill using it hard-fails the claude.ai upload path
disable-model-invocation: false  # ALWAYS PRESENT; true = manual-only (/commit-style): the description leaves context entirely; also blocks subagent preloading and scheduled-task prompts. Repo policy: false everywhere
# model: inherit  # ALWAYS PRESENT, ALWAYS COMMENTED — an active model: key of any value blocks Copilot slash invocation and fails lint-frontmatter.py
# effort:  # ALWAYS PRESENT, as a value or a commented-out placeholder — there is no `inherit` value, so omitting the field IS the inherit. Repo policy: commented on platform skills — this is a platform skill
paths:  # optional; narrows activation — withheld from the listing until a matching file is Read. No leading `/`, no backslash separator, never a bare `*.ext`
  - "**/*.EventSchemaSet/**"
---
```

**`paths:` narrows activation; it does not add a route.** A skill
carrying a glob is withheld from the startup listing until a matching
file is `Read`, so before then its description cannot match and
`/fabric-event-schema-set` answers `Unknown command` (root `CLAUDE.md`,
measured 2026-09-02). An earlier revision of this brief left that open
and assumed the description would still fire on its own. It will not.

The glob is kept anyway. `*.EventSchemaSet/` is a Fabric item-type
folder suffix, not a repo convention, so it appears in every Git-synced
Fabric workspace; the house pattern is `**/*.<ItemType>/**`, as
`fabric-eventstream` carries `"**/*.Eventstream/**"`. It covers the
definition and `.platform` together.

The cost is stated rather than hidden: **authoring the Avro upload files
does not activate this skill cold**, because those files have no fixed
location and no glob can name them. "authoring the Avro upload files"
stays in `when_to_use` for matching once the skill is listed, but it is
not a route in. The only cold route from the producer side is a pointer
in `fabric-eventstream` naming the **file** — see Cross-reference
dependencies.

## Description char count

Counted from the drafts below, unwrapped to the single-line form YAML
will hold, em dashes as written:

- `description`: 1,002 / 1,024
- `when_to_use`: 393 / 512

Both counts were measured, not estimated, on 2026-09-30 after the drafts
were rewritten, and re-counted from the drafted `SKILL.md` on 2026-10-01
per checklist item 2: unchanged.

Draft `description`:

> Use for the Microsoft Fabric Event Schema Set item
> (EventSchemaSetDefinition.json) — the contract a schema-associated
> Eventstream custom endpoint validates events against, and what
> silently drops an event that does not match. Covers the four
> description stores (eventTypes[].description, schemas[].description,
> versions[].description and the Avro record-level doc inside
> versions[].schema), the bare-Avro shape of an upload file versus the
> envelope the portal generates around it, the inline schema a portal
> save swaps in for an event type's schemaUrl, fresh-upload version
> reset to v1, and which route mints a version: every portal save does,
> even a description-only one, while a Git sync stores versions[] as
> pushed, so from Git append a version rather than edit one and read
> versions[] back after any edit. Plus serialization (an upload stored
> verbatim, the editor writing 1-space indent), the ancestor chain, and
> the item's per-file byte format (CRLF definition, LF .platform, no
> trailing newline).

Draft `when_to_use`:

> Use when adding, editing or deleting schemas in a Fabric event schema
> set; deciding whether a schema edit belongs in the portal or in Git;
> writing a new schema version by hand in Git; authoring the Avro upload
> files a schema set is populated from; or working out why a schema
> version did or did not bump, or why a field added in Git shows nowhere
> in the portal, and what that broke downstream.

## Body structure outline

1. **What the item is, and the one rule that matters.** Single-part item;
   the registry gate drops non-matching events with no error anywhere.
   Cross-reference `fabric-eventstream` for the producer side rather than
   restating it.
2. **Item structure on disk.** The two-file folder, verbatim, so the
   section doubles as a test fixture — see the Item structure note below
   for the exact content. This is also what makes the `paths:` glob
   correct, so it earns its place early.
3. **Definition anatomy.** `eventTypes[]` (id, description, format,
   envelopeMetadata, schemaUrl, schemaFormat) and `schemas[]` (id,
   format, versions[] of id / format / schema / ancestor). The `schema`
   value is a **JSON string** holding the Avro record, not a nested
   object — the single most confusing thing about reading the file.
   Learn's definition page adds an optional `description` on `schemas[]`
   and `versions[]`, `eventTypeCategory` (`EventType` or
   `BusinessEventType`), `protocol` and `protocolOptions`, and makes an
   event type's `schemaUrl` and inline `schema` mutually exclusive. The
   file adds what the page omits: a top-level `name` holding the display
   name, `ancestor`, and `versions[]` newest first (Finding 7). A portal
   save swaps `schemaUrl` for an inline `schema` (Finding 9).
4. **The four description stores.** A table: where each lives, who sets
   it, whether an upload reaches it, and its limit where one is known.
   The load-bearing point is that they are unrelated fields: an upload
   fills the event-type description from the file, and nothing keeps the
   stores in step afterwards (Finding 1).
5. **What you author versus what the portal generates.** The upload file
   is a bare Avro record — `fields`, `type`, `name`, optional `doc`. The
   entire `eventTypes` envelope is generated, and the create form's name
   and description are filled from the file. Include a minimal worked
   upload file with neutral entity names.
6. **Versioning — the route decides.** Findings 4, 5, 8 and 9 as
   separately labelled claims: every portal save mints, and a Git sync
   stores `versions[]` as pushed (observed 2026-09-30, portal minting
   documented); a fresh upload starts at `v1`; an in-place Git edit is
   Finding 8's hazard at the item level; and the inline copy can diverge
   unseen. What stays untested is said beside each: whether the registry
   that validates events follows a Git sync. The rule: **from Git, append
   a version rather than edit one, and after any edit, by any route, read
   `versions[]` back and confirm the version your `dataschema` URI names
   still exists and still describes what producers send.**
7. **Why the version is load-bearing.** It propagates into the bronze
   table name, the ingest control row's schema version, the Lakehouse
   shortcut, and the `dataschema` URI. An unnoticed bump desynchronises
   all four at once, and so does a structural change that did *not*
   bump; the failure mode either way is acked-and-dropped events.
8. **Byte format and serialization.** The two parts do **not** share a
   line-ending convention — see the Item structure note. Neither carries
   a trailing newline; neither has a BOM; a `-text` attribute on the
   workspace tree is what keeps both round-tripping. An upload is stored
   byte for byte, whatever the portal editor saves is 1-space indent
   with no trailing newline, and a Git edit written that way round-trips
   with nothing to commit (Finding 6). `ancestor` self-references on a
   `v1` and names the previous version after it (Finding 7).
9. **Gotchas table**, in the house format, including a field added in
   Git that shows nowhere in the portal (Finding 9).

## Changes from source proposal

N/A — new artifact, derived from a live verification session rather than
a prior written proposal.

## Tag

`publishable` — the subject is Fabric platform behavior with no
client-specific logic. The observations were made in a client estate;
this brief cites that evidence by kind only, and the draft must do the
same.

## Portability caveats

Nothing Claude Code-only is relied on for *behavior*: no
`context: fork`, no hooks, no `shell: powershell`, no `allowed-tools`.

**`paths:` does not carry to Copilot.** Copilot warns on the key and
ignores it (`scripts/copy-copilot.ps1`, FORMAT note), so in a client
repo's vendored `.github/skills/` copy this skill is **unconditional** —
listed on description relevance in every session. That is the opposite
of its Claude Code behavior and is acceptable here: the description is
specific enough not to fire on unrelated work. `when_to_use` and
`effort` likewise warn there and are ignored.

`model:` is carried commented out in the source `SKILL.md` itself.
`copy-copilot.ps1` applies no frontmatter transformation, so nothing
downstream comments it for you.

One content caveat that is not about frontmatter: Learn now documents the
definition format and that a portal update mints a version (read
2026-09-30), and the draft cites those pages for exactly that. Everything
else is observed behavior, in two tenants on two dates, and the draft
carries that framing explicitly rather than presenting it as documented
contract. One Learn line is wrong for a Git sync (Finding 4) and must not
be quoted as the rule.

## Cross-reference dependencies

- **`fabric-eventstream`** — *edit landed 2026-09-30.* Its
  [references/cloudevents-producer.md](../../../skills/fabric/fabric-eventstream/references/cloudevents-producer.md),
  under "Version-bump gotcha", no longer says every edit mints: it splits
  the route, a portal edit minting and a Git sync not, and its Gotchas
  row follows. As this dependency required, it names the **file** —
  `*.EventSchemaSet/EventSchemaSetDefinition.json` — not the skill,
  because the two skills' globs are disjoint and a skill-name pointer is
  dead whenever the schema set's glob has not matched (`author-skill`
  step 6). Its `SKILL.md` no longer says none of it is on Learn. Re-read
  both against the drafted skill, and edit them **in this repo's
  source**, never a client repo's vendored copy, which the next sync
  overwrites. `fabric-eventstream` also owns the producer contract,
  `dataschema` anatomy, registry host and destination-table naming, all
  of which this skill defers to.
- **`fabric-eventhouse`** — already converted; owns bronze table creation
  and `.create-merge` schema evolution, which is where events land.
- **`fabric-gotchas`** — already converted; the silent-drop failure mode
  belongs in its table too if it is not there already.
- **Avro 1.12 specification** — external/standard. The `doc` attribute on
  a record, and Parsing Canonical Form stripping `doc` — the mechanism
  hypothesis B rested on, refuted 2026-09-30 (Notes).

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**The findings, stated once, so the draft has a single source.** Each is
observed, in the tenant and on the date it gives; 2026-09-30's were
re-read from the definition's Git history by the triage that folded them
in. What is inferred or still untested is said in the finding.

1. **Four description stores, independent once set.**
   `eventTypes[].description`, optional in the create form ("Optionally,
   enter a description", Learn); `schemas[].description` and
   `versions[].description`, both optional on Learn's definition page;
   and the Avro record-level `doc` inside the schema string. **Corrected
   2026-09-30:** an upload does fill the create form's name and
   description from the file, and the stored event-type description
   equalled the record `doc` verbatim, as Learn's import page says of its
   own review. On 2026-09-10, in the other tenant, a name and
   description still had to be typed, so the forms may differ or the
   portal may have changed. Which part of the file supplies the name is
   unknown, the file and the record sharing one. Afterwards the stores
   are separate: a later event-type description edit left the Avro `doc`
   as uploaded.
2. **Record-level `doc` survives the upload verbatim.** Key order
   `fields` / `type` / `name` / `doc` preserved, and all field-level
   `doc` values preserved. The portal does not canonicalize the schema,
   and on 2026-09-30 it stored the upload byte for byte (Finding 6).
3. **The event-type description's cap is unestablished.** A 265-character
   value was rejected at upload on 2026-09-10; a 257-character one was
   accepted on Update and stored exactly on 2026-09-30. The cap sits
   between 258 and 265, or differs between the create and Update forms;
   the create form was not retested (Still open, item 1). Learn gives a
   256-character limit only for the schema set's own name. Whether a cap
   applies to the record-level `doc` was not tested — a 214-character
   one uploaded fine.
4. **The route decides whether an edit mints** (2026-09-30; the Git
   doc-only case also 2026-09-10, in the other tenant). Every portal
   **Update** that reaches **Finish** puts a new version at the head of
   `versions[]`, its `ancestor` naming the one before: a field `doc`
   change did, an event-type description change with the Avro equal once
   parsed did, and one whose Avro text was byte-identical to the previous
   version's did. Learn documents portal minting. A Git sync stores
   `versions[]` as written: an in-place edit to two schemas' `v2`, a
   structural field addition included, stayed `v2`; a hand-written `v3`
   with `"ancestor": "v2"` was accepted as a third version; and a change
   to an event type's inline `schema` alone minted nothing (Finding 9).
   Learn's definition page says "A new version is created when a new
   schema is provided to the EventType item", which the last case
   contradicts for a Git sync; for REST `updateDefinition` it is
   untested (Still open, item 3).
5. **A fresh upload registers as `v1`** even where that schema name
   previously reached `v2`/`v3`/`v4` and was deleted. Version numbering
   follows the schema object, not the name. A fresh upload registered as
   `v1` again on 2026-09-30; the deleted-name case was not retested.
6. **An upload is stored verbatim; the editor writes 1-space.**
   **Corrected 2026-09-30:** a 621-byte, 4-space upload ending in a
   newline was stored byte for byte, and everything the portal editor
   saved — the visual builder's `v1`, and each Update — is exactly
   `json.dumps(obj, indent=1)` with no trailing newline, as is Learn's
   example. A Git edit serialized that way round-trips with nothing to
   commit. Whether the 2026-09-10 tenant's 2-space reading was a
   difference between tenants or a change since is unknown.
7. **`ancestor` self-references on a first version** — `"id": "v1"` with
   `"ancestor": "v1"`. Each later version names the one before it,
   `versions[]` lists the newest first, and the definition carries a
   top-level `name` holding the item's display name, which Learn's page
   omits. Two and three versions per schema were seen on 2026-09-30, in
   the file and in History.
8. **The hazard, observed at the item level.** A Git edit to an existing
   version rewrites it in place (Finding 4), so a producer pinned to it
   would be validated, if the registry follows the definition, against
   content that changed underneath it, while `dataschema` still
   resolves. Whether the registry that validates events serves a
   rewritten version, a hand-written one, or neither is untested (Still
   open, item 4): the draft presents the item-level fact as observed and
   the event-level consequence as inferred. Until a producer has run
   against it, make structural changes in the portal.
9. **A portal save swaps the event type's `schemaUrl` for an inline
   `schema`**, byte-identical to the newest version's (three saves,
   2026-09-30); an upload writes `"schemaUrl": "#/schemas/<id>"`. The
   file respects Learn's mutual exclusion, and the newest schema text is
   then held twice. **The two copies can disagree with nothing showing
   it**: an edit to the inline copy alone, synced from Git, minted
   nothing, shows nowhere in the portal, whose schema pages read
   `versions[]` only, and left Source control empty, so the service
   presumably stored it as pushed (inferred; not read back through REST
   `getDefinition`, Still open, item 2). Which copy a producer is
   validated against is untested. The next portal save presumably
   overwrites the inline copy (inferred from the swap).

**What Finding 4 settled.** Two hypotheses stood here until 2026-09-30:
A, that the edit path decides, and B, that the content decides, minting
only when the schema's Parsing Canonical Form changes, which strips
`doc`. The portal minted for a `doc`-only change and for a byte-identical
one, and a Git sync did not mint a structural change, so B is refuted on
both routes. A holds, refined: Git can make a version, but only by
writing the entry itself. Inferred from one item type, and worth checking
before assuming it of another: an item that keeps its own version history
in its definition may treat a Git sync as a state write rather than an
edit.

**Still open, each needing a tenant**, and each labelled untested in the
draft:

1. The create form's description cap, between 258 and 265 characters
   (Finding 3). Cheap.
2. A REST `getDefinition` read confirming that the inline copy diverged
   from `v3` (Finding 9). Cheap, with a token for the tenant.
3. Whether REST `updateDefinition` mints like the portal or like Git
   (Finding 4).
4. End to end: a producer against an in-place-edited version, a
   hand-written one and a diverged inline copy, through a
   schema-associated custom endpoint. Not cheap: it needs an
   eventstream, and the `422` `MessagingCatalogConfiguration` fault in
   `cloudevents-producer.md` may still block creating the destination.

**Item structure, and the test fixture.** The item is a two-file folder,
measured 2026-09-10. Nothing else is in it — no subdirectories, no
additional parts:

```text
<ItemName>.EventSchemaSet/
├── .platform
└── EventSchemaSetDefinition.json
```

`.platform` is the standard Fabric Git-integration part, with nothing
schema-set-specific in it beyond the `type`:

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json",
  "metadata": {
    "type": "EventSchemaSet",
    "displayName": "<ItemName>"
  },
  "config": {
    "version": "2.0",
    "logicalId": "<guid>"
  }
}
```

The fixture detail most likely to be got wrong: **the two files do not
share a line-ending convention.** `.platform` is LF; the definition is
CRLF. Neither ends with a trailing newline — the last byte of both is
`}`. A fixture generated by an ordinary editor will silently normalize
both to LF-with-final-newline and stop resembling the real item.

Re-measured 2026-09-30, in the second tenant's item: the definition is
CRLF on every line and `.platform` LF, neither with a BOM or a final
newline. **A multi-version fixture exists there**: the definition as of
that evening holds two schemas at three versions each. Its only raw
identifier is the top-level `name`, which a fixture genericizes. One
schema's inline copy was left diverged from its `v3` (Finding 9), so
read the item fresh rather than trusting this paragraph.

Note also that `config.version` reads `"2.0"` here, which is the
`.platform` schema version and **not** an indicator of the item's
definition format — that value reads `2.0` for every item type in a
Fabric repo. The draft should not invite anyone to read it as a format
signal.

**Neutral names only.** Worked examples use `Orders`, `Customers` and
`Products` — already the vocabulary of `cloudevents-producer.md` — and
invented field names. No name from the source estate appears in this
brief, and none may appear in the draft or its fixtures.

**Tests belong to `/test-skill`, not the draft.** With the glob, this is
a new conditional skill, so it owes a fixture under
`tests/skills/fabric-triggers/` and a row in that set's
`expected_activations.md`. The Item structure above is the fixture's
content, byte format included.

**Why this did not become a `fabric-eventstream` section.** The schema
set is a separate Fabric item with its own definition file, its own
editing model and its own portal surface; `fabric-eventstream` is already
large and its schema material is about the *stream's* association with a
set, not the set's internals. The split is by item, matching how the rest
of the `fabric-*` family is divided.

## Confidence

- **Structure: H.** Follows the template and the `fabric-*` family's
  established item-per-skill split; the body outline maps one-to-one onto
  findings that are already written down.
- **Field specs: M.** Frontmatter follows the corrected template and the
  house pattern in `fabric-eventstream`, but was not re-verified at
  source, which is what checklist item 1 exists for.
- **Body content: H for findings 2, 4, 5, 6 and 7**, each observed with
  the file read back from Git, and portal minting documented on Learn.
  **M for findings 1 and 3**, each corrected on 2026-09-30 from one
  observation that disagrees with the other tenant's. **M for finding
  9**: the swap seen three times, the divergence once and partly
  inferred. **H for finding 8's item-level fact and L for its
  event-level consequence**, which stays untested until a producer runs
  and reaches the draft as an inference with its reasoning shown.

## Re-measure before acting

- The sandbox item, in a client sample repo on this machine:
  `git log --format='%h %ad %s' --date=iso -- '*.EventSchemaSet/*'`,
  then read the newest definition. On 2026-09-30 both schemas stood at
  `v3`, one with its inline copy holding a field its `v3` lacks.
- `grep -n "Git sync" skills/fabric/fabric-eventstream/references/cloudevents-producer.md`:
  the corrected *Version-bump gotcha*, landed 2026-09-30.
- Learn's EventSchemaSet definition page and the schema-set pages,
  before the draft quotes either.
