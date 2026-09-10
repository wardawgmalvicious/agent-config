# Skill handoff brief: fabric-event-schema-set

Last verified: 2026-09-10

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

Personal scope, deployed by `scripts/link-claude.ps1`:

- Repo: `skills/fabric/fabric-event-schema-set/SKILL.md`
- Deployed: `~/.claude/skills/fabric-event-schema-set/SKILL.md`

The `fabric/` group directory is repo-side only and does not survive into
the deployed name. This skill joins the existing `fabric-*` family, which
is also vendored into client repos through `.managed-skills.json` — so
`copy-copilot.ps1` will carry it to `<client-repo>/.github/skills/` on the
next sync, and it should be added to that manifest at the same time.

## Scope

Documents the Fabric **Event Schema Set** item — the `.EventSchemaSet`
folder and its single `EventSchemaSetDefinition.json` part — as the
contract a schema-associated Eventstream custom endpoint validates
incoming events against. The subject is the item's own anatomy and
editing model: the two independent places a human-readable description
lives, the shape of the file you upload versus the envelope the portal
generates around it, how versions are minted, and the byte format the
definition round-trips in.

It stops at the item boundary. The producer wire format, the
`dataschema` URI anatomy, the registry host, and the destination table
naming already belong to `fabric-eventstream` and are cross-referenced
rather than restated. What this skill adds that no existing skill has is
the **edit-path asymmetry**: the same description change mints a new
schema version through the portal and does not through Git.

Inline, model-invocable, not path-scoped.

## Sources drilled

Drilled — a live verification session against the client estate on
2026-09-10 (sandbox workspace, `<workspace>`), plus repo-internal
material:

- **A real upload / commit-back cycle.** A 10-field schema was authored
  as an Avro record, uploaded through the portal, and the committed-back
  `EventSchemaSetDefinition.json` read to see what the service preserved,
  generated, and rewrote. This established the round-trip facts in
  Findings 1, 2, 5, 6 and 7.
- **A live version-bump experiment.** Description text was edited in Git,
  committed, pushed, and synced, then the resulting definition inspected.
  This is Finding 4, the headline.
- **A rejected portal form entry** at 265 characters — Finding 3.
- `.github/skills/fabric-eventstream/references/cloudevents-producer.md`
  in `<client-repo>` — establishes the producer contract this skill defers
  to, and carries the "Version-bump gotcha" paragraph that Finding 4
  corrects.
- `<client-repo>` repo layout: `.gitattributes` (`workspaces/** -text`),
  `scripts/validate_schema_set.py` (what a downstream consumer reads out
  of the definition), and `schemas/<source>/*.json` (a worked example of
  upload files kept under review in Git).

Not drilled, and the draft must not describe any of it:

- **Microsoft Learn.** Two plausible documentation URLs for event schema
  sets returned 404. This surface appears genuinely undocumented, which
  is consistent with the existing note in `cloudevents-producer.md` that
  the producer wire format is "not documented on Microsoft Learn". Every
  claim in this brief is observed behavior on one tenant, on one date —
  not a documented contract, and the draft should say so in those terms.
- **The REST surface.** Whether `getDefinition` / `updateDefinition`
  behave like the Git sync path or like the portal path on versioning is
  untested. This matters because it decides whether the Finding 4 rule
  generalizes to "not the portal" or is specific to Git integration.
- **Field-level structural edits via Git.** Deliberately untested — see
  the hazard in Finding 8. Nothing in the draft may claim to know what
  happens.
- **Deployment-pipeline behavior**, beyond the pre-existing note that a
  pipeline copy of a schema set does not populate its backing catalog.
- **Multi-version coexistence.** Only single-version schemas were
  observed after the rebuild; how the portal presents a schema holding
  both `v1` and `v2` was not seen.

## Frontmatter

```yaml
---
name: fabric-event-schema-set  # repo linter requires it; upstream optional — display label only, the /command comes from the directory name; max 64 chars; lowercase/digits/hyphens; no "anthropic"/"claude"
description: <FILLED — copy verbatim from "Description char count" below>  # repo linter requires it (upstream: recommended); gated at 1,024, the Agent Skills spec cap — see Description char count
when_to_use: <FILLED — copy verbatim from "Description char count" below>  # optional; appended to description in the skill listing; gated separately at 512, the Claude-Code-only remainder of the 1,536 truncation point. NOT one of the spec's six fields — a skill using it hard-fails the claude.ai upload path
disable-model-invocation: false  # ALWAYS PRESENT; true = manual-only (/commit-style): the description leaves context entirely; also blocks subagent preloading and scheduled-task prompts. Repo policy: false everywhere
model: inherit  # ALWAYS PRESENT; sonnet / opus / haiku / full model ID / inherit; turn-scoped — the session model resumes on the next prompt; with context: fork, sets the subagent's model instead. Repo policy: inherit everywhere except commit (sonnet)
# effort:  # ALWAYS PRESENT, as a value or a commented-out placeholder — there is no `inherit` value, so omitting the field IS the inherit; low / medium / high / xhigh / max. Repo policy: max on the workflow skills that drive this repo, commented on platform skills — this is a platform skill
paths:  # optional; glob patterns for path-scoped auto-activation. No leading `/`, no backslash separator, and never a bare `*.ext` — the linter rejects those as silent narrowers
  - "**/*.EventSchemaSet/**"
---
```

**`paths:` reversal, 2026-09-10.** An earlier draft of this brief left
`paths:` unset, arguing the file locations were `<client-repo>` layout
conventions that would never fire elsewhere. That was wrong, and the
repo already disproves it: `*.EventSchemaSet/` is a **Fabric item-type
folder suffix**, not a repo convention, so it appears in every
Git-synced Fabric workspace regardless of layout. The house pattern is
already `**/*.<ItemType>/**` — `fabric-eventstream` carries
`"**/*.Eventstream/**"`, and 27 of the vendored skills use the same
shape (measured 2026-09-10 in `<client-repo>/.github/skills/`).

The glob covers the definition and `.platform` together. It does **not**
cover the upload files, which have no fixed location — those stay on
description-triggered activation, which is why the description carries
"authoring the Avro upload files" explicitly.

One thing to confirm at draft time (checklist item 1): whether `paths:`
**adds** an activation route alongside description matching or
**narrows** activation to those paths only. The whole family sets it
alongside rich descriptions, which implies additive, but that is
inference from house practice rather than a read of the docs.

## Description char count

Counted from the drafts below, unwrapped to the single-line form YAML
will hold, with the em dashes rendered as ASCII hyphens:

- `description`: 997 / 1,024
- `when_to_use`: 329 / 512

`description` has only 27 characters of headroom. Any wording change
during drafting needs a re-count, not an eyeball.

Draft `description`:

> Use for the Microsoft Fabric Event Schema Set item
> (EventSchemaSetDefinition.json) — the contract a schema-associated
> Eventstream custom endpoint validates events against, and what
> silently drops an event that does not match. Covers the two
> independent description stores (eventTypes[].description, a portal
> form entry capped at 256 characters, versus the Avro record-level doc
> inside schemas[].versions[].schema, which an uploaded file carries and
> the portal preserves verbatim), the bare-Avro shape of an upload file
> versus the envelope the portal generates around it, fresh-upload
> version reset to v1, and the version-bump asymmetry that decides where
> to edit: changing a schema in the portal mints a new version, changing
> the same text in Git and syncing does not. Includes the hazard that
> follows — Git is the safe path for doc-only edits and the unsafe path
> for field changes, which need the bump — plus portal re-serialization
> at 2-space indent and the CRLF/no-trailing-newline byte format.

Draft `when_to_use`:

> Use when adding, editing or deleting schemas in a Fabric event schema
> set; deciding whether a description change belongs in the portal or in
> Git; hitting the 256-character description limit; authoring the Avro
> upload files a schema set is populated from; or working out why a
> schema version bumped and what that broke downstream.

Both counts were measured, not estimated, and still **must be re-counted
after drafting** per checklist item 2 — the description sits 27
characters under its cap.

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
4. **The two description stores.** A table: where each lives, who sets
   it, whether an upload can reach it, and its limit. The load-bearing
   point is that they are unrelated fields and an upload cannot set the
   event-type description.
5. **What you author versus what the portal generates.** The upload file
   is a bare Avro record — `fields`, `type`, `name`, optional `doc`. The
   entire `eventTypes` envelope is generated. Include a minimal worked
   upload file.
6. **Versioning, and the edit-path asymmetry.** Findings 4, 5 and 8. This
   is the section the skill exists for. State the portal behavior, the
   Git behavior, the resulting rule, and the untested hazard as three
   separately-labelled claims — observed, observed, inferred.
7. **Why the version is load-bearing.** It propagates into the bronze
   table name, the ingest control row's schema version, the Lakehouse
   shortcut, and the `dataschema` URI. A silent bump desynchronises all
   four at once, and the failure mode is acked-and-dropped events.
8. **Byte format and serialization.** The two parts do **not** share a
   line-ending convention — see the Item structure note. Neither carries
   a trailing newline; neither has a BOM; `workspaces/** -text` is what
   keeps both round-tripping. The portal re-serializes the Avro string at
   2-space indent regardless of the upload's formatting, and `ancestor`
   self-references on a `v1`.
9. **Gotchas table**, in the house format.

## Changes from source proposal

N/A — new artifact, derived from a live verification session rather than
a prior written proposal.

## Tag

`publishable` — the subject is Fabric platform behavior with no
client-specific logic. See Notes: the observations were made against a
named client estate and the entity names must be genericized in the
draft.

## Portability caveats

Nothing Claude Code-only is relied on. No `context: fork`, no hooks, no
`shell: powershell`, no `allowed-tools`, and `effort` is a commented
placeholder rather than a set level.

`paths:` is **not** a portability risk, contrary to a plausible
assumption that path scoping is a Claude Code feature and that Copilot
offers only `applyTo` on `.github/instructions/*.instructions.md`.
Copilot's `SKILL.md` reads `paths:` too — 27 of the vendored skills in
`<client-repo>/.github/skills/` set it, in the same `**/*.<ItemType>/**`
form (measured 2026-09-10). `applyTo` is the instructions-file
mechanism and a separate thing; both can be true at once.

One transform the Copilot copy applies that this brief does not control:
the vendored skills carry `model:` **commented out**, annotated "any
model: value blocks Copilot slash invocation". So `model: inherit` as
specified above is the Claude-side value, and the copy step is expected
to comment it. Worth confirming `copy-copilot.ps1` still does that when
this skill is added to `.managed-skills.json`.

One content caveat that is not about frontmatter: every claim is observed
behavior on a single tenant on a single date, with no Microsoft Learn
page to cite behind any of it. The draft should carry that framing
explicitly rather than presenting the findings as documented contract.

## Cross-reference dependencies

- **`fabric-eventstream`** — *pending edit dependency, and the reason
  this brief is worth executing promptly.* Its
  `references/cloudevents-producer.md` states under "Version-bump gotcha"
  that **"Editing a schema in the set mints a new version (it does not
  edit in place)"**, without qualifying the edit path. Finding 4 shows
  that is true of the portal and false of Git. That paragraph needs the
  qualifier added, or the two skills will contradict each other. Also
  owns the producer contract, `dataschema` anatomy, registry host and
  destination-table naming, all of which this skill defers to.
- **`fabric-eventhouse`** — already converted; owns bronze table creation
  and `.create-merge` schema evolution, which is where events land.
- **`fabric-gotchas`** — already converted; the silent-drop failure mode
  belongs in its table too if it is not there already.
- **Avro 1.12 specification** — external/standard. The `doc` attribute on
  a record, and Parsing Canonical Form stripping `doc` (the reason a
  doc-only change is fingerprint-identical, which is the mechanism most
  likely behind Finding 4).

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**The findings, stated once, so the draft has a single source.** Items 1–7
are observed; item 8 is inferred and labelled as such.

1. **Two description stores, not one.** `eventTypes[].description` is
   entered in the portal form at upload time. The Avro record-level `doc`
   travels inside the schema string. An uploaded file cannot set the
   event-type description — confirmed by uploading a file carrying a
   record `doc` and still being required to type name and description.
2. **Record-level `doc` survives the upload verbatim.** Key order
   `fields` / `type` / `name` / `doc` preserved, and all field-level
   `doc` values preserved. The portal does not canonicalize the schema.
3. **`eventTypes[].description` is capped at 256 characters** in the
   portal form. A 265-character value was rejected. Whether the same cap
   applies to the record-level `doc` was not tested — a 214-character
   one uploaded fine.
4. **★ A description edit made in Git and synced does not bump the
   schema version.** It held at `v1`. The same edit made in the portal
   mints a new version. This is the finding the skill exists for.
5. **A fresh upload registers as `v1`** even where that schema name
   previously reached `v2`/`v3`/`v4` and was deleted. Version numbering
   follows the schema object, not the name.
6. **The portal re-serializes the Avro string at 2-space indent**
   regardless of the uploaded file's own formatting (the uploads were
   4-space). Do not try to match portal whitespace from source.
7. **`ancestor` self-references on a first version** — `"id": "v1"` with
   `"ancestor": "v1"`.
8. **Inferred hazard — do not present as tested.** If a Git edit does not
   mint a version, a Git edit that *adds, removes or retypes a field*
   presumably also does not — which would silently mutate a `v1` whose
   content changed underneath already-produced events, while `dataschema`
   still resolves to `v1`. That was deliberately not tested, because the
   desired behavior there is a bump. The rule to state: **Git is the safe
   path for doc-only edits and the unsafe path for structural ones; make
   structural changes in the portal so the version is minted.**

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

Note also that `config.version` reads `"2.0"` here, which is the
`.platform` schema version and **not** an indicator of the item's
definition format — that value reads `2.0` for every item type in a
Fabric repo. The draft should not invite anyone to read it as a format
signal.

**Genericize before drafting.** The evidence comes from a named client
estate — `<workspace>`, `<table>`, `<table>`, `<table>`,
`<column>`, `<column>`. The behaviors are generic; the names are
not. Worked examples in the draft should use neutral entity names.

**Why this did not become a `fabric-eventstream` section.** The schema
set is a separate Fabric item with its own definition file, its own
editing model and its own portal surface; `fabric-eventstream` is already
large and its schema material is about the *stream's* association with a
set, not the set's internals. The split is by item, matching how the rest
of the `fabric-*` family is divided.

**Queue row.** Per `execute/README.md`, a row is added when a brief
outlives the session that wrote it. This brief was written mid-way
through unrelated client work and will not be executed the same day, so
it likely needs one — but that call belongs to whoever picks it up.

## Confidence

- **Structure: H.** Follows the template and the `fabric-*` family's
  established item-per-skill split; the body outline maps one-to-one onto
  findings that are already written down.
- **Field specs: M.** Frontmatter is inherited from the template rather
  than re-verified at source, which is exactly what checklist item 1
  exists for. Both char counts were measured rather than estimated, but
  the description's 27-character headroom makes any rewording a re-count.
- **Body content: H for findings 1–7**, each observed directly in one
  session with the resulting file read back from Git. **L for finding
  8**, which is reasoned from finding 4 and explicitly untested — it must
  reach the draft as an inference with its reasoning shown, never as a
  verified behavior.
