# Handoff: rename the ontology tenant settings

- **Audit run**: 2026-10-06
- **Source**: `fabric-iq-ontology`
- **Window**: floor `2026-09-02` (diff base `f78e4a0e`, 2026-08-31) →
  head `135b0dc1` (2026-10-05)
- **Covers recommended actions**: 2
- **Kind**: factual correction of one renamed tenant setting and one
  newly required one, across one skill and its reference. Body only;
  no `description` change.
- **Target**: `skills/fabric/fabric-ontology/SKILL.md` (lines 194–195,
  204–207), `skills/fabric/fabric-ontology/references/REFERENCE.md`
  (lines 162–164, 227, 251)

## The problem

`fabric-ontology` calls the tenant setting that gates the item
*Ontology item (preview)*, in five places. Learn renamed it *Users can
create ontology (preview) items*, and the new experience also requires
*Users can create Fabric items*. `claude/mcp/README.md:254` already
uses both new names, so the repo disagrees with itself.

## Evidence

`docs/iq/ontology/overview-tenant-settings.md` was rewritten by
`c02fe35` ("Ontology add tenant settings (#16773)", 2026-10-01,
+11/−3). At base `f78e4a0e`:

> ## Ontology item (preview)
>
> This setting is **required** to create ontology (preview) items:
> *Enable Ontology item (preview)*.

At head `135b0dc1`, which matched the live page when the audit fetched
it on 2026-10-06, under the heading "Users can create Fabric items":

> This setting is **required** to create ontology (preview) items with
> the new experience: *Users can create Fabric items*.

> If you don't enable this setting, you get errors when creating a new
> ontology item, including while migrating from the old experience to
> the new experience.

And under "Users can create ontology (preview) items":

> This setting is **required** to create ontology (preview) items:
> *Users can create ontology (preview) items*.

The admin path moved as well: "**OneLake catalog** > **Govern** >
**Configurations** > **Tenant settings**". The data-agent and
operations-agent sections are unchanged.

The same commit rewrote the prerequisite bullet on the pages that named
the setting, the binding, generation and MCP pages among them:

> **Users can create ontology (preview) items** and **Users can create
> Fabric items** enabled on your Fabric tenant.

On 2026-10-06, `grep -rn "Ontology item (preview)"` over the repo,
`docs/audits/` aside, found the old name in `fabric-ontology` only, at
the five lines below.

## What to change

1. **`SKILL.md:194–195`**, § "Consuming an ontology", the MCP
   paragraph:

   > It needs **F2+ capacity** and the
   > *Ontology item (preview)* tenant setting.

   Name both settings, as the MCP page's prerequisites do.
2. **`SKILL.md:204–207`**, § "Before you start: tenant settings":

   > Creating the item at all requires the **Ontology item (preview)**
   > tenant setting. Failure to create a new ontology is *most commonly*
   > this and not anything about your data.

   Rename it, and add *Users can create Fabric items*, which Learn says
   produces the same symptom ("you get errors when creating a new
   ontology item").
3. **`REFERENCE.md:162–164`**, §3 "The MCP endpoint":

   > Prerequisites: **F2 or higher** paid Fabric capacity (or P1+ Power BI
   > Premium with Fabric enabled), and the *Ontology item (preview)* tenant
   > setting.
4. **`REFERENCE.md:227`**, §6, the first row:

   ```text
   | Item won't create | Tenant setting *Ontology item (preview)* not enabled. |
   ```
5. **`REFERENCE.md:251`**, §7:

   > - **Ontology item (preview)** — required to create the item at all.

   Add *Users can create Fabric items* as its own bullet. The admin
   path is optional here; the skill names none today.

## Constraint on the fix

- Scope *Users can create Fabric items* as Learn does: "required to
  create ontology (preview) items with the new experience". `c02fe35`
  also changed one line in each of four `old-experience/` pages, which
  were not fetched, so whether the old-experience prerequisites name
  both settings is unmeasured. Brief 01's answer decides whether the
  skill says anything about that case.
- Use Learn's exact setting names, italicized as the skill does now.

## Sequencing note

`fabric/04` item 5, in `docs/audits/2026-10-06/fabric/`, adds *Users
can create Fabric items* at `SKILL.md:204`. It neither renames the
first setting nor touches `REFERENCE.md`. If it has run, re-measure the
five lines above: rename wherever the old name survives, and add the
second setting only where it is still missing.

## Verification

1. `grep -rn "Ontology item (preview)" skills/ claude/` returns nothing.
2. `grep -n "Users can create" skills/fabric/fabric-ontology/SKILL.md skills/fabric/fabric-ontology/references/REFERENCE.md`
   — both names at each of the five sites, or a stated reason where
   one is absent.
3. `grep -n "Users can create" claude/mcp/README.md` — the wording
   agrees with the skill's.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-ontology/SKILL.md`
5. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against
`fabric-iq-ontology`, floor 2026-09-02. The base and head quotes come
from files downloaded at pinned SHAs and diffed on disk in the audit
session; the head page was also checked against live Learn there.

## Execution log

- **Executed**: 2026-10-07 — applied
- **Session**: fresh
- **Files changed**: `skills/fabric/fabric-ontology/SKILL.md`,
  `skills/fabric/fabric-ontology/references/REFERENCE.md`
- **Verification**: steps 1–4 passed. No "Ontology item (preview)"
  under `skills/` or `claude/`; both names at each of the five sites;
  `claude/mcp/README.md:254` uses the same two names; the frontmatter
  lints. Step 5, `pre-commit run --all-files`, runs once at the end of
  the pass.
- **Deferred**: none
- **Deviations**: every target was matched by its quote, since
  `fabric/04` had moved the line numbers. At site 2, § "Before you
  start: tenant settings", `fabric/04` item 5 had already added *Users
  can create Fabric items*, so per the sequencing note that site was
  only renamed; the rename lengthened its first line, so the paragraph
  was rewrapped to 76, a 91-character line in it included. The admin
  path, optional per item 5, was not added.
