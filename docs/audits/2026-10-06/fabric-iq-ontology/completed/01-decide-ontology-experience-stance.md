# Handoff: decide how fabric-ontology treats the two ontology experiences

- **Audit run**: 2026-10-06
- **Source**: `fabric-iq-ontology`
- **Window**: floor `2026-09-02` (diff base `f78e4a0e`, 2026-08-31) →
  head `135b0dc1` (2026-10-05)
- **Covers recommended actions**: 1
- **Kind**: a **decision** on how `fabric-ontology` treats the old and
  new ontology experiences. No file is corrected by this brief; briefs
  02–09 and 11 here apply the answer, so `/drift-update` puts it back
  to the user rather than executing it.
- **Target**: none directly; the answer governs
  `skills/fabric/fabric-ontology/` and brief 11's registry entry

## The problem

Learn's ontology docs now describe two experiences. The new one is the
default for new items. The old one, which is what every section of
`fabric-ontology` describes, can no longer be created in the Fabric UI,
can still be created through the APIs and CI/CD, and retires on
2027-01-31. Its pages moved under `docs/iq/ontology/old-experience/`.

The skill was verified against the docs on 2026-09-02, before the
split. Every rewrite briefed here has to know where an old-experience
fact goes when the new pages drop or change it: into the
new-experience text, into a dated legacy section, or nowhere. That is
one stance for the whole skill, and the docs do not settle it.

## Evidence

`docs/iq/ontology/overview.md` at head `135b0dc1`, § "Migrate from old
experience", added by `80a24c9` (the FabCon EU release merge,
2026-09-29):

> The new ontology experience is the default experience for new
> ontology items.

> You can't create new instances of the old ontology experience through
> the ontology interface in Fabric. It's still possible to create
> instances of the old experience by using the ontology APIs and CI/CD.

> If you already have an ontology that you created in the old
> experience, use the in-product action to **create a copy in the new
> experience**. The copy flow preserves the original item while
> creating a separate ontology item based on its supported definitions.

> Your old ontology stays in your workspace and is available until the
> old experience retires.

> The old experience of ontology retires on Jan 31, 2027.

The copy is a separate item, so consumers must be reconnected ("Agents,
Dashboards, Other integrations"), and the page says to "Recreate rules
and manually set up Activator alerts if you need them".
`resources-troubleshooting.md` at head adds that migration fails when
the old ontology "contains properties configured as *Defined at
Binding*" or "contains entities that use composite keys".

The old pages survive under `old-experience/` with a banner include
that reads, in part: "Use this documentation only if you're maintaining
an existing old experience item." At head that directory holds 11
pages, among them `overview.md`, `concepts-generate.md`,
`how-to-bind-data.md`, `concepts-agent-integration.md` and
`how-to-add-semantic-enrichment.md`. The troubleshooting and
tenant-settings pages have no old-experience copy.

**Half of the stance is already prescribed.** Today's `fabric` audit
wrote this brief, pending when this one was written:
`docs/audits/2026-10-06/fabric/04-rewrite-ontology-for-the-tmdl-experience.md`.
Its evidence is that the two experiences serialize differently: the new
one as `.tmdl` files, the old one as the JSON layout the skill
documents. Its item 2 sets the stance for that layout:

> Keep the JSON layout as a clearly marked legacy section with the
> 2027-01-31 retirement date. Existing items, and items created through
> the API, still use it until then.

Its item 4 applies a rule to one behavioural section, the storage-mode
matrix: "re-derive the storage-mode guidance from the current pages, or
mark it legacy if it described the old experience." No brief says
whether that rule governs the skill's other behavioural claims. These
are the ones that turn on it, each briefed here:

| Old-experience claim in the skill | New-experience pages at head | Brief |
| --- | --- | --- |
| No OneLake security on a source lakehouse | dropped; the overview says bound data's OneLake security is respected | 03 |
| A static binding first, its value matching a time-series column | the two-step flow and its note are gone; a primary and a secondary source join on a common column | 04 |
| The Import / Direct Lake / DirectQuery matrix and the generation limits | absent from the new generation page; kept in `old-experience/concepts-generate.md` | 05 |
| Every ontology has a refreshed instance graph | graph execution is optional and opt-in | 06 |
| The JSON definition schemas in REFERENCE §1 | legacy, per `fabric/04` item 2 | 09 |

## The decision

Where does an old-experience fact go when the new-experience pages
drop or change it?

1. **One dated legacy section for every old-experience fact.** The
   skill describes the new experience; whatever the old experience
   still does differently moves to a section dated to its 2027-01-31
   retirement, beside the JSON layout `fabric/04` already puts there.
   This is the stance the audit suggested: an item created through the
   APIs or CI/CD may be either experience until then, and the skill
   fires on any file under `*.Ontology/`.
2. **A legacy section for the layout only.** Take `fabric/04` item 2 as
   the whole answer: the behavioural sections describe the new
   experience, and old-experience behaviour is dropped from them.
3. **Drop the old experience now.** No legacy section at all. This
   contradicts `fabric/04` item 2, which would have to be re-briefed
   first.

Record the answer, with its option number, in this brief's execution
log. Briefs 02–09 and 11 read it from there.

## Sequencing note

Answer this before running brief 02 or any later brief here. It need
not precede `fabric/04`, whose item 2 fits options 1 and 2; only
option 3 conflicts with it.

## Verification

1. This brief's execution log records the answer and its option number.
2. After briefs 03–09 land:
   `grep -n -i "old experience\|legacy\|2027" skills/fabric/fabric-ontology/SKILL.md skills/fabric/fabric-ontology/references/REFERENCE.md`
   — every old-experience fact sits where the answer put it, and no
   section states one as current.

## Provenance

Surfaced by the 2026-10-06 `/drift-audit` run against
`fabric-iq-ontology`, floor 2026-09-02: the run that `fabric/04` item 9
asked for. Both refs of every registered page were downloaded at pinned
SHAs and diffed on disk in the audit session, not by a subagent. The
`fabric/04` quotes are that brief's, from the `fabric` audit run the
same day.

## Execution log

- **Executed**: 2026-10-06 — escalated
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in this session)
- **Files changed**: none
- **Verification**: step 1 — the answer and its option number are
  below. Step 2 waits on briefs 03–09.
- **Decision**: **option 4, in-place dated markers**, put to the user
  beside options 1–3 and chosen. Each section states the
  new-experience rule as current. Where the old experience differs,
  the same section carries it under a dated marker, in the two forms
  `fabric/04` wrote: the `### Old experience (legacy): the JSON layout`
  subsection, and elsewhere a paragraph opening **Old experience
  (legacy, retires 2027-01-31):**, sourced to the `old-experience/`
  page that states it. Brief 03's constraint, 08 D-2 and 11 D-1 each
  turn on whether the skill keeps old-experience facts: it does.
- **Deferred**: verification step 2, once briefs 03–09 land, by the
  `/drift-update` run that executes them.
- **Deviations**: option 4 is not in the brief. `fabric/04` was pending
  when the brief was written; by this run it had been applied,
  uncommitted, in the `2026-10-06-fabric` worktree, marking legacy
  material in place, a shape none of options 1–3 names. Option 4
  restructures none of that work, and the date in every marker makes
  the 2027-01-31 removal one grep.
- **Needs**: the rest of this pass — briefs 02–11, once the 2026-10-06
  `fabric` pass lands `fabric/04` and `fabric/07` on `main`. They
  apply this answer, and step 2 checks it.
- **Closed**: 2026-10-07 — briefs 02–11 applied option 4 in one cold
  `/drift-update` pass, and step 2 ran after brief 09. Every
  old-experience fact in both files sits under a dated marker; the one
  pointer left unmarked, "(the `Contextualizations` above)" in
  REFERENCE §5, was marked then, as brief 05's log records. The
  `description`'s definition-layout clause still names only the JSON
  layout: that is `fabric/04`'s last Needs line, tracked there.
