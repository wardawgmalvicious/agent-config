# Handoff: drop the OneLake-security exclusion

- **Audit run**: 2026-10-06
- **Source**: `fabric-iq-ontology`
- **Window**: floor `2026-09-02` (diff base `f78e4a0e`, 2026-08-31) →
  head `135b0dc1` (2026-10-05)
- **Covers recommended actions**: 3
- **Kind**: removal of a claim Learn withdrew, from one skill's
  `description`, body and reference. The `description` edit needs an
  activation retest.
- **Target**: `skills/fabric/fabric-ontology/SKILL.md` (line 3, the
  `description`; lines 111–113),
  `skills/fabric/fabric-ontology/references/REFERENCE.md` (line 232)

## The problem

`fabric-ontology` says a lakehouse with OneLake security enabled cannot
be an ontology data source, and says it in its trigger `description`.
Learn withdrew that limitation in September. The binding page no longer
lists it, its troubleshooting row is gone, and the new overview says
authoring and querying *respect* OneLake security on bound data.

## Evidence

| Commit | Date | Title | Ontology files |
| --- | --- | --- | --- |
| `611edf2` | 2026-09-21 | Remove OLS limit | `how-to-bind-data.md` +1/−2 |
| `dd8ac24` | 2026-09-22 | Remove outdated limit | `how-to-bind-data.md` +1/−1, `resources-troubleshooting.md` +2/−3 |

Removed from `how-to-bind-data.md` § "Limitations and troubleshooting",
present at base `f78e4a0e`:

> You can't use lakehouses with OneLake security enabled as data
> sources for bindings. If a lakehouse has OneLake security enabled,
> you can't use it as a data source in ontology.

The prerequisite bullet on the same page, base then head:

> Lakehouse tables conform to ontology (preview)'s data binding
> limitations: They are **managed**, do not have OneLake security
> enabled, and do not have column mapping enabled.

> Lakehouse tables conform to ontology (preview)'s data binding
> limitations: They're **managed** and don't have column mapping
> enabled.

Removed from `resources-troubleshooting.md` § "Troubleshoot data
binding":

```text
| Lakehouse not available as data source when creating a binding | Check to make sure **OneLake security** isn't enabled on your lakehouse. Lakehouses with OneLake security enabled aren't supported as data sources for bindings. |
```

Added to `overview.md` by `80a24c9` (2026-09-29), § "Lifecycle,
interoperability, and governance":

> Authoring and querying respect access to bound data, including
> OneLake security and source-enforced row-level security (RLS),
> object-level security (OLS), and column-level security (CLS),
> alongside programmatic access and CI/CD capabilities.

On 2026-10-06 the exclusion appeared at the three lines below and in
no other skill.

## What to change

1. **`SKILL.md:3`**, the `description`: inside "the data-binding rules
   (… managed tables only, no OneLake security, no delta column
   mapping)", drop "no OneLake security".
2. **`SKILL.md:111–113`**, § "The constraints that produce silent or
   confusing failures":

   > - **No OneLake security on the source lakehouse.** A lakehouse with it
   >   enabled does not appear in the data-source picker at all — it looks
   >   like a permissions problem and is not.

   Remove it as a current constraint. If anything replaces it, the
   overview supports only this much: access to bound data, OneLake
   security included, is enforced for authoring and querying.
3. **`REFERENCE.md:232`**, §6:

   ```text
   | Lakehouse **absent from the source picker** | OneLake security is enabled on it. |
   ```

## Constraint on the fix

- **The old experience was not checked.**
  `old-experience/how-to-bind-data.md` (11,205 bytes at head, added by
  `80a24c9`) was not fetched, and neither commit above touched it. If
  brief 01's answer keeps old-experience facts in a legacy section,
  fetch that page first: where it still carries the exclusion, the
  claim moves to the legacy section rather than vanishing.
- Claim no more than the overview's sentence. What the data-source
  picker shows for a lakehouse with OneLake security was not measured.
- **The `description` budget.** It measured 980 of its 1,024
  characters on 2026-10-06, and `when_to_use` 450 of 512. This edit
  only shortens it. Briefs 04, 05 and 07 point here for the figure.

## Sequencing note

Several briefs edit this `description`: this one, 04, 05 and 07 here,
and `fabric/04` in `docs/audits/2026-10-06/fabric/`. Run the activation
retest once, after the last of them lands, and record it as owed in
the others.

Do not bundle this with brief 04, though both come from the binding
page. This brief removes one withdrawn claim and is verified by a grep;
04 is a rewrite whose content needs judgment and a re-read of the page.

## Verification

1. `grep -n -i "onelake security" skills/fabric/fabric-ontology/SKILL.md skills/fabric/fabric-ontology/references/REFERENCE.md`
   — no hit states the exclusion as current.
2. `uv run --with pyyaml scripts/lint-frontmatter.py skills/fabric/fabric-ontology/SKILL.md`
3. `uv run --with pyyaml scripts/skill-status.py --stale` — lists
   `fabric-ontology` as owing a retest. Retest per `/test-skill`, or
   record it as owed per the sequencing note.
4. `pre-commit run --all-files`

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against
`fabric-iq-ontology`, floor 2026-09-02, from files downloaded at pinned
SHAs and diffed on disk in the audit session. The commit titles and
file stats came from the GitHub API in the same session. The registry
entry lists this exclusion among the claims "most likely to move", and
it moved.

## Execution log

- **Executed**: 2026-10-07 — applied with deferrals
- **Session**: fresh
- **Files changed**: `skills/fabric/fabric-ontology/SKILL.md`,
  `skills/fabric/fabric-ontology/references/REFERENCE.md`
- **Verification**: the constraint's lookup first. Brief 01's answer
  keeps old-experience facts, so
  [old-experience/how-to-bind-data](https://learn.microsoft.com/fabric/iq/ontology/old-experience/how-to-bind-data)
  was fetched live (2026-10-07): its prerequisite reads "They're
  **managed** and don't have column mapping enabled" and its
  Limitations carry no OneLake-security bullet, so the claim went to no
  legacy marker. The overview's sentence was confirmed live the same
  day. Step 1: every hit is the replacement bullet, which states the
  exclusion as withdrawn. Step 2: the frontmatter lints. Step 3:
  `--stale` lists `fabric-ontology` as `untested-behaviour`, a verdict
  `skill-status.py` checks before `retest-routing`, so the Phase B it
  owes covers this `description` edit too. Step 4,
  `pre-commit run --all-files`, runs once at the end of the pass.
- **Deferred**: the `description` retest, per the sequencing note
  run once after briefs 04, 05 and 07 here land their edits to it.
- **Deviations**: the bullet was replaced rather than only removed, as
  item 2 allows. The replacement quotes the overview's sentence, and
  adds the September 2026 withdrawal and that neither experience's
  binding page carries the old rule, both checked above.
- **Needs**: a fresh session — after this pass lands and `fabric/04`'s
  last Needs line folds the TMDL layout into the `description`, the one
  `/test-skill fabric-ontology` retest every `description` edit here
  shares.
