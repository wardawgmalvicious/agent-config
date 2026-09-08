# Handoff: retire the Fluent 2 preview framing across the theme skills

- **Audit run**: 2026-09-07
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 2 and 3
- **Kind**: factual correction to committed skill prose. No behavior
  changes, no frontmatter changes. Both files repeat one stale premise,
  so one grep verifies both.
- **Target**: `skills/powerbi/pbir-themes/SKILL.md`,
  `skills/powerbi/pbir-pages/SKILL.md`

## The problem

Both skills describe Fluent 2 as a **preview** base theme that is
**Desktop-only**, sits behind a **Preview features** toggle, and is
**not** the default for new reports. All four of those statements are now
false. The August 2026 release took modern visual defaults to GA, made
Fluent 2 the default base theme for new reports in both Desktop and the
service, and moved the whole customization surface from the
"Customize current theme" dialog into a new **Theme** pane on the View
ribbon.

This is the exact case the audit's bucket (a) calls out as high-value:
a skill hedging on preview status after the feature shipped. An agent
reading `pbir-themes` today will tell the user to enable a preview toggle
that no longer exists, and will name the wrong default base theme.

## Evidence

Live upstream page, fetched 2026-09-07 via `microsoft-learn-mcp`:
<https://learn.microsoft.com/power-bi/create-reports/power-bi-reports-visual-defaults>

Its applies-to line, verbatim:

```
**Applies to:** ✅ Power BI Desktop and Power BI service
```

Its base-theme table, verbatim:

```
| **Fluent 2** | Default base theme for new reports. Modern styling aligned with the Microsoft Fluent 2 design system. |
| **Classic 2026** | Previous default base theme. Incremental refresh of Classic 2018. |
| **Classic 2018** | Original base theme for legacy compatibility. |
```

And, verbatim:

```
New reports created in Power BI Desktop or the Power BI service use Fluent 2 by default.
```

The switching procedure, verbatim:

```
1. On the **View** ribbon, toggle on the **Theme** pane.
2. In the **Theme settings** section at the top of the Theme pane, select the **Base theme** dropdown.
3. Choose the base theme you want: **Fluent 2**, **Classic 2026**, or **Classic 2018**.
```

Nothing on the page carries a preview label, and there is no mention of
an Options › Preview features toggle anywhere.

The `whats-new.md` row added in the window (commit `369371ac`,
2026-08-20), verbatim:

> Modern visual defaults and customize themes formatting panes
> (Generally Available) | New reports start with the Fluent 2 base theme.
> Use the Theme pane to set a base theme, adjust color palettes, change
> text styles, set visual and page properties, and import or export
> custom themes in Desktop or on the web. Font overrides are removed from
> the base theme so the Text section now applies consistently across all
> visuals.

### What is confirmed still correct — do not "fix" these

Two claims in `pbir-pages` were checked against the live page and hold:

- New pages default to **1920x1080** — page says
  "**Canvas size**: New pages default to 1920x1080".
- Existing pages don't auto-resize — page says "Existing reports and
  existing pages don't update their page size when you switch to the new
  base theme. Only new pages use the new default canvas size."

## What to change

### D-1 — `pbir-themes` calls Fluent 2 preview and Desktop-only

**Symptom.** The base-theme table row reads:

> `| `Fluent 2` | Preview (Desktop only) | Modern Fluent 2 styling. New pages default to **1920x1080** (initial page stays 1280x720). Adds chart / button / slicer / small-multiples style presets. Enable via Options › Preview features › "Modern visual defaults and customize theme improvements". |`

**Cause.** Written against the April 2026 preview.

**Fix.** Status becomes GA and available in Desktop *and* the service.
Drop the "Enable via Options › Preview features …" sentence entirely —
the toggle is gone, not renamed. Keep the page-size and style-preset
notes; both are still accurate.

### D-2 — `pbir-themes` names the wrong default base theme

**Symptom.** The table row reads:

> `| `Classic 2026` | Default for new reports | Incremental refresh of `CY24SU10`-era defaults. |`

**Cause.** Same vintage as D-1.

**Fix.** Fluent 2 is the default for new reports; Classic 2026 is the
*previous* default. Note that the two rows must move together — leaving
D-1 fixed and D-2 unfixed produces a table claiming two different
defaults.

**Knock-on.** The heading above the table is `### Base Themes (April
2026)`. That date stamp is now misleading; restamp it to the date this
correction is verified, not to "August 2026" — the skill's convention is
to pin a claim to a date someone checked.

### D-3 — `pbir-themes` documents the retired switching path

**Symptom.** The sentence under the table reads:

> Switch via View › Themes › Customize current theme › Base theme
> dropdown. The Customize-theme dialog also surfaces aspect-ratio
> page-size presets and table/matrix style enhancements when the preview
> is on.

**Cause.** The dialog was replaced by the Theme pane at GA.

**Fix.** Replace with the View ribbon → **Theme** pane → **Theme
settings** → Base theme dropdown path quoted in Evidence. Drop the
trailing "when the preview is on" conditional.

**Knock-on.** The Theme pane exposes surface this skill does not cover at
all, and `pbir-themes` owns report-wide defaults and filter-pane styling
per its own `when_to_use`. Newly available and in scope: **Theme
settings** (import/export/remove), **Colors** (palette, data, structural,
sentiment, divergent), **Text**, **Visual properties** (background,
border, header icons, tooltip, shadow, padding), **Page** (canvas
settings, background, wallpaper), **Filter pane**, and **Filter cards**.
Also new: an "Update to the latest base theme" banner with an **Update
theme** button, and a **Reset to default** tile in the Themes dropdown.
Adding these is in scope for this brief but is the lowest-priority part
of it — the corrections above are what stop the skill misleading.

### D-4 — the base-theme font-override behavior change

**Symptom.** Not a wrong line; an absent one. `pbir-themes` owns
`textClasses` and the theme-inheritance chain, and the GA release changed
how fonts resolve: *"Font overrides are removed from the base theme so
the Text section now applies consistently across all visuals."* The live
page corroborates under Uniform visual styling: *"**Fonts**: Uniform font
style, colors, and sizes across visuals"*.

**Fix.** Record the change where the skill explains theme inheritance.

**Open question.** The upstream wording is release-note prose, not a spec
of which JSON properties moved. Whether this needs a corresponding note
in `powerbi-report-authoring/references/theming.md` (which documents the
resolution cascade) was **not** investigated this run. Check before
editing; do not assume.

### D-5 — `pbir-pages` repeats the preview label and the retired dialog

**Symptom.** The prose under Common Page Sizes reads:

> The Fluent 2 (preview) base theme bumps new-page default to 1920x1080.
> Initial page in a report stays 1280x720; existing pages don't
> auto-resize when switching base themes. Customize-theme dialog also
> surfaces aspect-ratio presets for common page sizes. See `pbir-themes`
> for base-theme switching.

**Fix.** Drop "(preview)". Change "Customize-theme dialog" to the Theme
pane. Leave the two page-size claims alone — both verified correct.

**Knock-on.** The Common Page Sizes table row
`| Default 16:9 (Classic 2018 / Classic 2026 base theme) | 1280 x 720 |`
is accurate *per theme* but now misleads: a reader scanning for "the
default" sees 1280x720, while a new report today starts on Fluent 2 at
1920x1080. Reframe so the effective default for new reports is
unambiguous. This is the one arguable target in the brief — the row is
not false — and it is included because the audit judged the framing
actively misleading once Fluent 2 became the default.

## Constraint on the fix

Correct the status, the default, and the workflow — do not restate the
whole upstream page. These are authoring skills for PBIR/theme JSON, not
a mirror of the Learn docs; the Theme pane detail in D-3 earns its place
only where it maps to something encodable in theme JSON.

Do not attach a version number to the GA. What the evidence establishes
is a **release month and a checked date**: announced in the August 2026
update (`whats-new.md` at `369371ac`, 2026-08-20), page confirmed GA on
2026-09-07. No Desktop build number was verified this run.

## Verification

1. `grep -rniE "preview|customize current theme|customize-theme" skills/powerbi/pbir-themes/SKILL.md skills/powerbi/pbir-pages/SKILL.md`
   — every surviving hit must be either unrelated to Fluent 2 or a
   deliberate historical reference. This single grep covers both files
   and is why these two actions are one brief.
2. `grep -rniE "fluent ?2" skills/powerbi --include=*.md` — catches any
   third file repeating the stale framing. `pbir-pages` and `pbir-themes`
   were the only two hits at audit time; a new hit means the correction
   is incomplete.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/powerbi/pbir-themes/SKILL.md`
   and the same for `skills/powerbi/pbir-pages/SKILL.md`. Both edits are
   body-only, but `pbir-themes` has a long `description` already near the
   1024-char cap — if D-3's additions push into it, the linter names the
   field to cut.
4. `pre-commit run --all-files`.

## Provenance

Found by the 2026-09-07 `powerbi` drift audit against a 2026-08-01 floor.
The `whats-new.md` row flagged the GA; the live visual-defaults page was
then drilled directly to confirm each specific claim rather than
inferring status from the release note, which is why Evidence quotes the
page and not just the What's New table.

One caveat on trusting the window: this run's diff was recovered from a
fork of the deleted upstream repo (see brief `01`). The fork was
cross-checked against the SHA the live Learn page pins, and every claim
in this brief was additionally confirmed against the live page, so the
findings here do not depend on the fork being trustworthy.

## Execution log

- **Executed**: 2026-09-08 — applied with deferrals
- **Session**: fresh (the rerun report was read as the invocation argument; no audit ran in this session)
- **Files changed**: `skills/powerbi/pbir-themes/SKILL.md`, `skills/powerbi/pbir-pages/SKILL.md`
- **Verification**: steps 1–3 ran and pass. Step 1's first run surfaced a
  surviving stale hit the brief did not enumerate — the Learn link label at
  `pbir-themes/SKILL.md:253` still read "Fluent 2 preview" — which was
  corrected and step 1 re-run clean. The one remaining step-1 hit is the
  deliberate historical reference at line 44 ("The Theme pane replaced the
  Customize-theme dialog at GA"). Step 2 returns four hits across the two
  target files, all corrected text; no third file repeats the stale framing.
  Step 4 (`pre-commit run --all-files`) is run once at the end of the whole
  brief set, not per brief.
- **Deferred**:
  - **D-4 open question — answered, no edit made.**
    `powerbi-report-authoring/references/theming.md` was checked as the brief
    instructed. It documents the `textClasses` cascade and the derived
    classes but makes **no** claim about base-theme font overrides, so the
    GA change contradicts nothing there and no corresponding note is
    required. It does, separately, carry a retired UI name at line 240 —
    "**4 primary classes** (editable in Customize Theme dialog)" — which is
    the same dialog→pane rename as D-3. That file is not in this brief's
    **Target**, and no other brief in this set names it, so it was left
    alone and is reported as an adjacent finding instead.
  - **The "initial page stays 1280x720" carve-out is unverified.** The audit's
    recommended action 5 asks for it to be re-verified against a real new
    report, and the GA page carries no initial-page exception. D-1 and D-5
    both direct that the page-size notes be kept, so the claim survives
    unchanged in both files. Verifying it needs Power BI Desktop, which this
    run cannot drive.
  - **No behavioural confirmation.** An edited `SKILL.md` does not reliably
    reload mid-session on Windows, so neither skill was exercised after the
    edit. Lint and the prose greps pass; a fresh session would confirm
    behaviour.
- **Deviations**: one, and it widened the diff by a single line — the
  line 253 link label. It was not enumerated in **What to change**, but the
  brief's own verification step 1 is written to fail on exactly that hit, so
  leaving it would have meant reporting a failed verification for a defect
  the brief plainly intends to retire. Nothing else outside the enumerated
  targets was touched.
