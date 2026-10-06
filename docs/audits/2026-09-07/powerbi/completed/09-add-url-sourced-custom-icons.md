# Handoff: document URL-sourced custom icons in `pbir-conditional-formatting`

- **Audit run**: 2026-09-07 (**second** run — see Provenance)
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 6 of **`00b-audit-report-rerun.md`**
  (not of `00-audit-report.md`; two audits of this window ran on this
  date)
- **Kind**: content addition to a skill that encodes JSON property paths.
  Carries the **same empirical constraint as brief `04`** — the evidence
  establishes a UI capability, not a JSON encoding. Share `04`'s PBIP
  round-trip rather than doing a second one.
- **Target**: `skills/powerbi/pbir-conditional-formatting/` (`SKILL.md`
  and/or `references/REFERENCE.md`)

## The problem

Conditional formatting in tables and matrices can now take a **custom
icon from a URL** — a field value pointing at a web or OneLake image —
in addition to the built-in icon sets the skill documents. An agent asked
today to conditionally render a custom icon from a data column has
nothing in this skill to work from.

This is uncovered surface rather than a false claim: nothing in
`pbir-conditional-formatting` is wrong, it simply predates the feature.

## Evidence

Two independent upstream statements, both from this window.

From `https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-onelake-files`,
under **Use OneLake images in visuals**, verbatim:

> **Conditional formatting**: Use an image URL column for custom table or
> matrix icons. For more information, see [Use a custom icon from a
> URL](../create-reports/desktop-conditional-table-formatting#use-a-custom-icon-from-a-url).

From the August release commit `369371ac` (2026-08-20), the message
records the doc change that introduced it:

> Conditional formatting (icons): add Use a custom icon from a URL
> subsection describing Field value with web or OneLake URLs

and, for the matrix format-settings page:

> Matrix visual format settings: note Icons Field value supports OneLake
> URLs for custom icons

The dedicated upstream subsection is at
`https://learn.microsoft.com/en-us/power-bi/create-reports/desktop-conditional-table-formatting#use-a-custom-icon-from-a-url`.

### Current local coverage

`skills/powerbi/pbir-conditional-formatting/references/REFERENCE.md:11`
describes the linked upstream page as covering *"backgrounds, font color,
data bars, icons, web URLs"* and maps it to *"the `dataBars` / `icon`
blocks the parent skill documents"*.

Read that line carefully before writing: it mentions "web URLs" as part
of the **upstream page's** contents, which is not the same as this skill
documenting a URL-sourced icon. Confirm which is actually true in the
skill body before deciding whether this is an addition or an expansion of
something already half-present.

## What to change

`skills/powerbi/pbir-conditional-formatting` — add the URL-sourced icon
as a recognised icon source alongside the built-in sets, noting that the
field value may be a web URL **or** a OneLake file URL.

Where the skill states the encoding, the `icon` block's representation of
a field-value-driven URL icon is what has to be correct. See Constraint.

## Constraint on the fix

**The evidence is a UI capability, not a JSON encoding.** This skill's
value is that its `visual.json` property paths are right; the upstream
pages describe format-pane labels and give no property names for the
URL-icon case. The audit did **not** establish the encoding.

So, exactly as brief `04` requires for its six items: derive the
encoding empirically — author a table or matrix in Power BI Desktop with
a URL-sourced custom icon, save as PBIP, and read the resulting
`visual.json`. `pbir` (the `pbir-cli` tool) is installed globally on this
machine and is the natural way to inspect it. **If the encoding cannot be
observed, document the capability and its UI path and omit the JSON** —
an omission costs one lookup; an invented property name produces a report
that fails validation or silently drops formatting.

If the OneLake half is documented, carry the two limits that bound it,
both from the OneLake page: viewers need Read on the lakehouse item *and*
OneLake Read on the folder, and **Publish to web / anonymous embed cannot
use OneLake URLs at all**.

## Sequencing note

**Execute in the same session as brief `04`
(`04-catalog-new-visual-formatting-properties.md`).** That brief needs a
Power BI Desktop round-trip to establish JSON property names for six
August formatting settings; this needs the same round-trip for a seventh.
Doing them separately means opening Desktop twice for one class of work.

They are separate briefs only because they land in different skills —
`04` in `pbir-visual-json`, this in `pbir-conditional-formatting` — and
because either can be dropped without affecting the other if its property
proves unobservable.

Also related to brief `03` (`03-add-onelake-image-urls.md`), which covers
the OneLake image-source model for `image.md`. That one is pure prose
verified by grep and should **not** wait on a Desktop session.

## Verification

1. `grep -rniE "custom icon|icon.{0,12}url|onelake" skills/powerbi/pbir-conditional-formatting --include=*.md`
   — the addition landed.
2. If any JSON was written, confirm it against the PBIP export produced
   for brief `04`, not against this brief. Record the Desktop build used;
   the audit established a release month (August 2026) and no build
   number.
3. `pbir validate <report-path>` on a report exercising the new encoding,
   if example JSON was added.
4. `uv run --with pyyaml scripts/lint-frontmatter.py skills/powerbi/pbir-conditional-formatting/SKILL.md`
   — `description` is capped at 1024 chars. Long detail belongs in
   `references/`, per this repo's editing conventions.
5. `pre-commit run --all-files`.

## Provenance

Found by the **second** `powerbi` drift audit run on 2026-09-07, against
the same window as the first.

The first run folded conditional-formatting icons into its `image.md`
brief (`03`) as one item in the OneLake image-source list, and did not
raise `pbir-conditional-formatting` as a target in its own right. The
second run drilled the OneLake page, which names conditional formatting
as a distinct scenario with its own upstream subsection, and treated the
owning skill as a separate artifact. Both readings are defensible; this
brief exists so the skill that actually owns the `icon` block is not
missed. Nothing here contradicts brief `03`.

## Execution log

- **Executed**: 2026-09-08 — applied (capability documented, JSON encoding
  omitted per Constraint)
- **Session**: fresh
- **Files changed**: `skills/powerbi/pbir-conditional-formatting/SKILL.md`,
  `skills/powerbi/pbir-conditional-formatting/references/REFERENCE.md`
- **Verification**: steps 1 and 4 ran and pass; 2 and 3 are not applicable
  because no JSON was written; step 5 runs once at the end of the brief set.
  1. `grep -rniE "custom icon|icon.{0,12}url|onelake"
     skills/powerbi/pbir-conditional-formatting` — 10 hits where there were
     none, across the new `#### Custom icon from a URL` subsection, a new
     gotcha row, and the updated `references/REFERENCE.md` index line.
  4. Lint passes; nothing was summarised into `description`, so the 1024-char
     cap was not approached.
- **The "addition or expansion?" question the brief posed — answered: an
  addition.** `references/REFERENCE.md:11` lists "web URLs" among the upstream
  page's contents, and the drill shows that refers to the page's **Format as web
  URLs** section, which makes cell values into hyperlinks. That is a different
  feature from a URL-sourced *icon*, and the skill body documented neither. The
  `icon` block at `SKILL.md:256` encodes only the **Rules** style driving a
  built-in set (`value` → `Conditional.Cases` → `'SymbolMedium'`), so nothing
  was half-present to expand.
- **Constraint honoured — no invented property names.** The encoding for the
  **Field value** icon source was not observed, for the same reason brief `04`
  is blocked: it needs a Desktop PBIP round-trip, and Desktop (Store build
  **2.157.1354.0**) cannot be driven from an agent shell. `pbir` 0.9.7 was not
  a substitute — its bundled schema predates this release, as recorded in
  `04`'s log. So the brief's explicit fallback was taken: *"document the
  capability and its UI path and omit the JSON."* The new subsection says so in
  as many words, and warns that the Rules-style block above does not carry over
  unchanged — an agent that assumed it did would produce exactly the silent
  formatting drop the Constraint is guarding against.
- **Both OneLake limits carried**, as the Constraint requires: the per-viewer
  permission requirement (Read on the lakehouse item *and* OneLake Read on the
  folder) and the Publish-to-web / anonymous-embed exclusion, the latter also
  as a gotcha-table row since that is where a trap of that shape is looked for.
- **Sequencing note — not honoured, and could not be.** The note asks that this
  run share brief `04`'s Desktop round-trip. `04` is blocked and no round-trip
  happened, so there was nothing to share. The prose half of this brief does not
  depend on it and was completed; the JSON half joins `04` in waiting for the
  same Desktop session, and should be done in that one sitting as the note
  intends.
- **Deferred**: the `visual.json` encoding for the Field-value icon source; and
  behavioural confirmation, since an edited `SKILL.md` does not reliably reload
  mid-session on Windows.
- **Deviations**: the upstream subsection was drilled directly rather than taken
  from the brief's quotes. It supplied the format list (BMP, JPG, JPEG, GIF,
  PNG, SVG) and the exact UI path, neither of which the brief carried.
