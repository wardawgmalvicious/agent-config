# Skill handoff brief: fabric-event-schema-set

Last verified: 2026-09-10

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
editing model: the two independent places a human-readable description
lives, the shape of the file you upload versus the envelope the portal
generates around it, when a new schema version is and is not minted, and
the byte format the definition round-trips in.

It stops at the item boundary. The producer wire format, the
`dataschema` URI anatomy, the registry host, and the destination table
naming already belong to `fabric-eventstream` and are cross-referenced
rather than restated. What this skill adds that no existing skill has is
**one observed case where an edit did not mint a version** — a doc-only
change synced from Git held at `v1` — and the rule that follows from not
yet knowing why: read `versions[]` back after any edit rather than
assuming a bump either way.

Inline, model-invocable, path-scoped.

## Sources drilled

Drilled — a live verification session in a client's sandbox workspace on
2026-09-10, plus repo-internal material:

- **A real upload / commit-back cycle.** A 10-field schema was authored
  as an Avro record, uploaded through the portal, and the committed-back
  `EventSchemaSetDefinition.json` read to see what the service preserved,
  generated, and rewrote. This established the round-trip facts in
  Findings 1, 2, 5, 6 and 7.
- **A live version experiment, Git side only.** Description text was
  edited in Git, committed, pushed, and synced, then the resulting
  definition inspected. This is Finding 4.
- **A rejected portal form entry** at 265 characters — Finding 3.
- [skills/fabric/fabric-eventstream/references/cloudevents-producer.md](../../../skills/fabric/fabric-eventstream/references/cloudevents-producer.md)
  — the producer contract this skill defers to. Its "Version-bump
  gotcha" is the only prior evidence of a bump: `Products` reaching `v2`
  after a `bytes`→`string` retype, a **structural** edit whose edit path
  it does not record.
- The client repo's layout: its `.gitattributes` marks the workspace tree
  `-text`, a validation script there reads fields out of the definition,
  and a directory of upload files is kept under review in Git — a worked
  example of authoring outside the portal.

Not drilled, and the draft must not describe any of it:

- **Microsoft Learn.** Two plausible documentation URLs for event schema
  sets returned 404. This surface appears genuinely undocumented, which
  is consistent with the existing note in `cloudevents-producer.md` that
  the producer wire format is "not documented on Microsoft Learn". Every
  claim in this brief is observed behavior on one tenant, on one date —
  not a documented contract, and the draft should say so in those terms.
- **A doc-only edit made in the portal.** Not performed. This is the
  case that decides what Finding 4 means (see Notes), and it is cheap and
  safe to run on a throwaway schema with no producer attached.
- **Field-level structural edits via Git.** Deliberately untested — see
  Finding 8. Nothing in the draft may claim to know what happens.
- **The REST surface.** Whether `getDefinition` / `updateDefinition`
  mint versions like the Git sync path or like the portal is untested.
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

- `description`: 928 / 1,024
- `when_to_use`: 335 / 512

Both counts were measured, not estimated, and still **must be re-counted
after drafting** per checklist item 2.

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
> version reset to v1, and when a schema version is minted: a doc-only
> edit synced from Git held at v1, so read versions[] back after any
> edit rather than assuming a bump. Plus portal re-serialization at
> 2-space indent, the self-referencing ancestor on v1, and the item's
> per-file byte format (CRLF definition, LF .platform, no trailing
> newline).

Draft `when_to_use`:

> Use when adding, editing or deleting schemas in a Fabric event schema
> set; deciding whether a schema edit belongs in the portal or in Git;
> hitting the 256-character description limit; authoring the Avro upload
> files a schema set is populated from; or working out why a schema
> version did or did not bump and what that broke downstream.

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
   upload file with neutral entity names.
6. **Versioning — what was observed and what was not.** Findings 4, 5
   and 8, as separately labelled claims: observed (a Git doc-only edit
   held at `v1`), prior observation (a field retype reached `v2`, edit
   path unrecorded), not observed (a portal doc-only edit; a Git field
   edit). Then the two hypotheses from Notes and what each predicts, and
   the rule that holds under both: **after any edit, by any path, read
   `versions[]` back and confirm the version your `dataschema` URI names
   still exists and still describes what producers send.** If the
   discriminating test in Notes has run by draft time, replace the
   hypotheses with its result and date it.
7. **Why the version is load-bearing.** It propagates into the bronze
   table name, the ingest control row's schema version, the Lakehouse
   shortcut, and the `dataschema` URI. An unnoticed bump desynchronises
   all four at once, and so does a structural change that did *not*
   bump; the failure mode either way is acked-and-dropped events.
8. **Byte format and serialization.** The two parts do **not** share a
   line-ending convention — see the Item structure note. Neither carries
   a trailing newline; neither has a BOM; a `-text` attribute on the
   workspace tree is what keeps both round-tripping. The portal
   re-serializes the Avro string at 2-space indent regardless of the
   upload's formatting, and `ancestor` self-references on a `v1`.
9. **Gotchas table**, in the house format.

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

One content caveat that is not about frontmatter: every claim is observed
behavior on a single tenant on a single date, with no Microsoft Learn
page to cite behind any of it. The draft should carry that framing
explicitly rather than presenting the findings as documented contract.

## Cross-reference dependencies

- **`fabric-eventstream`** — *pending edit dependency.* Its
  [references/cloudevents-producer.md](../../../skills/fabric/fabric-eventstream/references/cloudevents-producer.md),
  under "Version-bump gotcha", states flatly that **"Editing a schema in
  the set mints a new version (it does not edit in place)"**. Finding 4
  shows a doc-only edit synced from Git did not. Edit that paragraph
  **in this repo's source**, not in any client repo's vendored copy,
  which the next sync overwrites: qualify the claim as observed for a
  field retype, add the 2026-09-10 Git doc-only observation, and point
  at the read-back rule. Because the two skills' globs are disjoint, the
  pointer must name the **file** —
  `*.EventSchemaSet/EventSchemaSetDefinition.json` — not the skill: a
  skill-name pointer is dead whenever the schema set's glob has not
  matched (`author-skill` step 6). `fabric-eventstream` also owns the
  producer contract, `dataschema` anatomy, registry host and
  destination-table naming, all of which this skill defers to.
- **`fabric-eventhouse`** — already converted; owns bronze table creation
  and `.create-merge` schema evolution, which is where events land.
- **`fabric-gotchas`** — already converted; the silent-drop failure mode
  belongs in its table too if it is not there already.
- **Avro 1.12 specification** — external/standard. The `doc` attribute on
  a record, and Parsing Canonical Form stripping `doc` — the mechanism
  behind hypothesis B in Notes.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**The findings, stated once, so the draft has a single source.** Items 1–3
and 5–7 are observed. Item 4 is observed on the Git side only. Item 8 is
inferred and labelled as such.

1. **Two description stores, not one.** `eventTypes[].description` is
   entered in the portal form at upload time. The Avro record-level `doc`
   travels inside the schema string. An uploaded file cannot set the
   event-type description — confirmed by uploading a file carrying a
   record `doc` and still being required to type name and description.
2. **Record-level `doc` survives the upload verbatim.** Key order
   `fields` / `type` / `name` / `doc` preserved, and all field-level
   `doc` values preserved. The portal does not canonicalize the schema,
   though it does re-indent it (Finding 6).
3. **`eventTypes[].description` is capped at 256 characters** in the
   portal form. A 265-character value was rejected. Whether the same cap
   applies to the record-level `doc` was not tested — a 214-character
   one uploaded fine.
4. **A doc-only edit made in Git and synced did not bump the schema
   version.** It held at `v1`. That half is observed. The earlier
   revision of this brief also stated that "the same edit made in the
   portal mints a new version"; no such portal edit appears in the
   session's record, so that half is **unestablished** and must not
   reach the draft as observed. The only recorded bump is the structural
   retype in `cloudevents-producer.md`, path unrecorded.
5. **A fresh upload registers as `v1`** even where that schema name
   previously reached `v2`/`v3`/`v4` and was deleted. Version numbering
   follows the schema object, not the name.
6. **The portal re-serializes the Avro string at 2-space indent**
   regardless of the uploaded file's own formatting (the uploads were
   4-space). Do not try to match portal whitespace from source.
7. **`ancestor` self-references on a first version** — `"id": "v1"` with
   `"ancestor": "v1"`.
8. **Inferred hazard — do not present as tested.** If Git sync never
   mints a version, a Git edit that *adds, removes or retypes a field*
   would silently mutate a `v1` whose content changed underneath
   already-produced events, while `dataschema` still resolves to `v1`.
   That was deliberately not tested, because the desired behavior there
   is a bump. Whether the hazard is real depends on which hypothesis
   below holds.

**What Finding 4 means is undecided, and one test decides it.** Two
hypotheses fit the evidence equally well:

- **A — the edit path decides.** A portal save always mints a version;
  a Git sync never does. Then Finding 8's hazard is real, and the rule is
  "structural edits in the portal, doc-only edits in either".
- **B — the content decides.** The service mints only when the schema's
  canonical form changes. Avro's Parsing Canonical Form strips `doc`, so
  a doc-only edit never mints, by either path, and a structural edit
  mints by either path. Then Finding 8's hazard does not exist, and
  where you edit does not matter.

They disagree on two cases: a doc-only edit in the portal (A: bumps; B:
does not) and a field edit via Git (A: does not; B: bumps). The first is
cheap and safe — one portal description edit on a throwaway schema with
no producer attached, then read the definition back. Run it before
drafting if possible. Until then, the read-back rule in body section 6
is correct under both hypotheses, which is why the draft leads with it.

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
- **Body content: H for findings 1–3 and 5–7**, each observed directly
  in one session with the resulting file read back from Git. **M for
  finding 4** — the Git half is observed, the portal half is not, and
  the mechanism is two live hypotheses. **L for finding 8**, which
  depends on hypothesis A and is explicitly untested — it must reach the
  draft as an inference with its reasoning shown, never as a verified
  behavior.
