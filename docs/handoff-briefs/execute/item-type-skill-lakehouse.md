# Handoff: does `.Lakehouse` need a skill?

- **Written**: 2026-08-31, from the trigger-fixture work (`9d49302`).
- **Kind**: coverage decision.
- **Status**: open. **Recommendation: not a "Lakehouse skill" — a
  shortcuts-and-ALM one, and probably a `paths:` glob on an existing skill
  rather than a new file.** See "What changed my read" below; the user's
  instinct was right but the file is more interesting than it looks.
- **Run in**: a fresh session.

## The user's framing, which is correct

> Lakehouses don't commit anything outside of shortcuts.

Confirmed. A Git-synced Lakehouse is four files and no data:

| File | Bytes (ACME) | Contents |
| --- | --- | --- |
| `.platform` | ~300 | item marker |
| `lakehouse.metadata.json` | small | `defaultSchema`, `schemaEnabled` |
| `alm.settings.json` | ~700 | which object types sync to Git |
| `shortcuts.metadata.json` | 4,755 | the actual payload |

Tables, files and the SQL analytics endpoint are **not** in Git. A skill
about "working with a Lakehouse" would be about things the agent never sees
in the repo — that is the case against, and it is a good one.

## What changed my read

`shortcuts.metadata.json` in ACME is not a flat list of paths:

```json
{
  "name": "ue_ACME_Holidays_v2",
  "path": "/Tables/bronze",
  "target": {
    "type": "OneLake",
    "oneLake": {
      "path": "Tables/ue_ACME_Holidays_v2",
      "itemReference": "$(/**/ACME_VL/ItemReferenceKustoOperation)"
    }
  }
}
```

That `$(/**/ACME_VL/...)` is a **Variable Library reference embedded in a
shortcut target** — a shortcut whose destination is rebound per environment
through `ACME_VL`. It is a real Fabric feature, it is not obvious, and
nothing in the payload documents it. `fabric-variable-library` (2,693 tok,
conditional on `**/*.VariableLibrary/**`) is the natural owner and does not
fire here.

`alm.settings.json` is the second non-obvious file: it enumerates the
shortcut target types (`OneLake`, `AdlsGen2`, `Dataverse`, `AmazonS3`,
`S3Compatible`, `GoogleCloudStorage`, `AzureBlobStorage`,
`OneDriveSharePoint`) with per-type `Enabled`/`Disabled` state, plus a
`DataAccessRoles` block. **This is a Git-sync control surface** — flipping
a state changes what deploys. `fabric-cicd` is the natural owner.

So the uncovered content is not "Lakehouse". It is *shortcut definitions
and their ALM behaviour*, which is narrow, real, and cheap.

## Three options, cheapest first

**Option A — `paths:` glob on `fabric-variable-library`.** Add
`**/*.Lakehouse/shortcuts.metadata.json`. The VL-reference syntax is the
thing worth knowing and that skill already owns VL references. Cost: one
frontmatter line, zero new listing tokens (it is already conditional). Add
a short section on shortcut targets to its body. **This is the recommended
starting point.**

**Option B — glob on `fabric-cicd` for `alm.settings.json`.** That skill is
currently *unconditional* (367 listing tokens), so giving it a `paths:`
glob is also a Workstream E move — it would leave the session listing
entirely. Check E in [skill-context-cost.md](skill-context-cost.md) first;
these two decisions interact and should be made together, not twice.

**Option C — a new `fabric-lakehouse` skill.** Only if A and B leave real
content homeless. Watch the trap: it will be tempting to fill it with
Lakehouse *product* knowledge (schema-enabled restrictions, the SQL
endpoint, V-Order, table maintenance) — none of which is in the repo, all
of which is reference rather than procedure, and which is exactly the
"reference document masquerading as a skill" pattern Workstream E exists to
push back on.

## Do this first

Read the whole of ACME's `Integration/ACME_LH_Operation.Lakehouse/` — all
four files — before choosing. 4,755 bytes of shortcuts is small enough to
read completely, and the decision turns on what is actually in it rather
than on what Lakehouses can do in general.

Then check whether `fabric-mlv` (materialized lake views, unconditional,
379 listing tokens) belongs on a Lakehouse glob too. It is Lakehouse-scoped
and is another Workstream E candidate — but confirm where MLV definitions
actually serialize before assuming it is `.Lakehouse/`; they may live in
the Notebook that creates them.

## Validation

- Whichever option: update
  `tests/skills/fabric-triggers/fixtures/SampleLH.Lakehouse/` in the same
  commit. It currently has `.platform` and `lakehouse.metadata.json`; add
  `shortcuts.metadata.json` and `alm.settings.json` (synthetic contents —
  no ACME item references), and change the *(none)* rows in
  `expected_activations.md`.
- Re-run the static check; confirm nothing else started matching.
- `pre-commit run --all-files`, `/commit`.
