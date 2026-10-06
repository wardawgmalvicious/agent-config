# Handoff: add OneLake file URLs to the image authoring guidance

- **Audit run**: 2026-09-07
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 4
- **Kind**: content addition to committed skill prose, carrying one
  hard limitation. Additive, not a correction — nothing currently in the
  file is false.
- **Target**: `skills/powerbi/powerbi-report-authoring/references/image.md`

## The problem

`image.md` frames image sourcing entirely around one requirement: a
data-bound image field must carry `dataCategory: ImageUrl` in the
semantic model. That is still true, and the file's warn-before-creating
workflow around it is still correct.

What the file does not know is that **OneLake file URLs are now a
supported image source**, GA as of the August 2026 release, across a
wider set of visuals than the file currently discusses. It also does not
carry the limitation that comes with them, which is the part that bites:
OneLake file URLs **do not work in Publish to web or anonymous embed
scenarios**. An agent following this file today would author a report
that renders correctly in the service and silently breaks when published
publicly.

## Evidence

The `whats-new.md` row added at commit `369371ac` (2026-08-20), verbatim:

> OneLake file URLs for report visuals and maps (Generally Available) |
> Image files stored in OneLake can be used as image sources in the image
> visual, table and matrix cells, the card visual, button and list
> slicers, and custom icons in the Icons cell element. Power BI
> authenticates on the viewer's behalf. Reference layer maps and shape
> map files can also be linked from OneLake URLs.

The same release commit added a new upstream page,
`powerbi-docs/visuals/power-bi-onelake-files.md` (+137 lines, `status:
added`). Its commit-message description, verbatim:

> Adds powerbi-docs/visuals/power-bi-onelake-files.md covering uploading
> images to a lakehouse, copying the OneLake file URL, and using it in
> visuals, tables, matrices, conditional formatting, Azure Maps markers,
> and shape map custom maps.

And, as a distinct commit in the same merge:

> Note that Publish to web and anonymous embed scenarios don't support
> OneLake file URLs

The current local text, `image.md:143`:

> For data-bound image URLs, the column or measure must have **Data
> Category set to "Image URL"** in the semantic model.

followed by the `dataCategory: ImageUrl` inspection workflow at
lines 147–156.

## What to change

1. **`image.md`** — add OneLake file URLs as a recognised source, naming
   the surfaces upstream names: the image visual, table and matrix cells,
   the card visual, button and list slicers, and custom icons in the
   Icons cell element. Note that Power BI authenticates on the viewer's
   behalf, so no anonymous-access configuration on the lakehouse is
   implied.

2. **`image.md`** — record the Publish-to-web / anonymous-embed
   limitation somewhere it cannot be missed by an agent that reads only
   the sourcing section. This is the highest-value line in the brief.

3. **Relationship to `dataCategory: ImageUrl`** — resolve and state it.
   The two mechanisms interact and the audit did **not** establish how.
   Specifically: a OneLake URL typed into the image visual's *Enter URL*
   box is not data-bound and plainly needs no data category, while a
   OneLake URL arriving in a table/matrix cell through a column
   presumably still needs `dataCategory: ImageUrl`. Confirm before
   writing, and do not weaken the existing warn-before-creating workflow
   on an assumption.

## Constraint on the fix

**The upstream page behind this was not drilled.** The audit cited
`power-bi-onelake-files.md` from the release commit and the What's New
row but did not fetch it. Everything quoted in Evidence comes from the
What's New row and the commit messages — release-note prose, not spec.

So: fetch
<https://learn.microsoft.com/power-bi/visuals/power-bi-onelake-files>
via `microsoft-learn-mcp` before writing, and take the surface list, the
URL format, and the limitation wording from that page rather than from
this brief. The quotes here are sufficient to establish *that* the
capability exists and *that* the limitation exists; they are not
sufficient to document the URL syntax, and this brief deliberately does
not supply one.

Do not invent a sample OneLake URL. If the page gives one, use it; if it
does not, describe the shape without fabricating a concrete example.

## Verification

1. Fetch the upstream page and confirm each added claim appears there —
   particularly the visual list and the Publish-to-web / anonymous-embed
   limitation, which is quoted here from a commit message rather than
   from published prose.
2. `grep -rniE "onelake" skills/powerbi/powerbi-report-authoring/references/image.md`
   — confirms the addition landed where a reader of the sourcing section
   will see it.
3. `grep -rniE "publish to web|anonymous embed" skills/powerbi --include=*.md`
   — the limitation should be discoverable from the authoring skill, and
   this check also surfaces any other file that would now be
   contradicting it.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/powerbi/powerbi-report-authoring/SKILL.md`
   — the edit is to a `references/` file, but confirm the parent skill's
   description still describes what it covers.
5. `pre-commit run --all-files`.

## Provenance

Found by the 2026-09-07 `powerbi` drift audit against a 2026-08-01 floor,
from the `whats-new.md` diff at `369371ac`. The Publish-to-web limitation
does not appear in the What's New row at all — it was recovered from the
squash-merge commit message of the same release, which is why this brief
insists on confirming it against the published page before it is written
into a skill as fact.

## Execution log

- **Executed**: 2026-09-08 — applied
- **Session**: fresh
- **Files changed**: `skills/powerbi/powerbi-report-authoring/references/image.md`,
  `skills/powerbi/powerbi-report-authoring/SKILL.md`
- **Verification**: all five steps addressed; 1–4 ran and pass, 5 is run once at
  the end of the whole brief set.
  1. Upstream page fetched via `microsoft-learn-mcp` before anything was
     written, as the Constraint requires. Every added claim appears there,
     including the two the brief flagged as unconfirmed: the visual list
     (§ "Use OneLake images in visuals") and the limitation, which is published
     prose and not only a commit message — *"Publish to web and other anonymous
     embed scenarios don't support OneLake file URLs because those scenarios
     can't authenticate to OneLake."* The URL format was taken from the page
     verbatim; no sample URL was invented.
  2. `grep -ni onelake … image.md` — 13 hits, in the sourcing sections and the
     overview list a reader hits first.
  3. `grep -rniE "publish to web|anonymous embed" skills/powerbi` — two hits,
     both the new limitation block. No other file contradicts it.
  4. Lint passes on the parent `SKILL.md`.
- **What the drill resolved**: item 3 of **What to change** was an open question
  and the page answers it outright, so nothing was assumed. Three add-paths
  exist and they split cleanly: a URL typed into the format pane's **Enter URL**
  box is not data-bound and needs no data category, while a URL arriving via a
  **column** or a **measure** does require Data category = Image URL. The
  existing warn-before-creating workflow in § 3 is therefore untouched and now
  explicitly extends to OneLake URLs; it was not weakened.
- **Deferred**: no behavioural confirmation — an edited `SKILL.md` does not
  reliably reload mid-session on Windows, so the skill was not exercised after
  the edit. A fresh session would confirm it.
- **Deviations**: two, both narrow.
  - Section 2's blanket rule *"The URL must be publicly accessible (anonymous
    access, no sign-in required)"* would have made an agent reject a OneLake URL
    on sight, so a one-line exception pointing at section 4 was added there.
    Adding a source the file elsewhere forbids would not have satisfied item 1.
  - Verification step 4 asks whether the parent skill still describes what it
    covers. Its frontmatter `description` is generic, names no image sources and
    needed no change. Two **in-body index rows** did: the `references/` table row
    for `image.md`, and the gotcha row enumerating the source options an agent
    must prompt with — which the new section 4 turned from three into four.
    Both were updated. This is closing the loop on this brief's own edit rather
    than an adjacent fix.
  - The upstream page also carries the deployment-pipeline caveat that brief
    `08` owns for `fabric-cicd`. It is recorded here in the Considerations list
    because it is a property of OneLake image URLs that an author of one needs;
    brief `08` remains responsible for the `fabric-cicd` side.
