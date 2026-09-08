# Handoff: note that Copilot reads bookmark-hidden visuals in `pbir-bookmarks`

- **Audit run**: 2026-09-07 (**second** run — see Provenance)
- **Source**: `powerbi`
- **Window**: floor `2026-08-01` → head `0e80b00b` (2026-08-25)
- **Covers recommended actions**: 10 of **`00b-audit-report-rerun.md`**
  (not of `00-audit-report.md`; two audits of this window ran on this
  date)
- **Kind**: one-sentence caveat added to committed skill prose. Lowest
  priority in this set. **The first run classified this same item as a
  no-op** — read Provenance before executing.
- **Target**: `skills/powerbi/pbir-bookmarks/SKILL.md`

## The problem

`pbir-bookmarks` documents per-visual `display.mode` `hidden`/`visible`
as the visibility mechanism, and documents hide-and-reveal bookmark
patterns built on it. As of August 2026, a visual in the `hidden` state
is **no longer excluded from Copilot summarization**: Copilot Summary and
the Copilot Narrative visual now read visuals that are hidden by default
and revealed by a display-only report bookmark.

Nothing in the skill is false — `display.mode` still is the correct
visibility toggle, and that is the claim the skill actually makes. What
changed is an *implication* a reader can reasonably draw: that hiding a
visual keeps its content out of generated narrative text. It no longer
does.

## Evidence

From `whats-new.md` at head `0e80b00b`, the **Copilot and AI** section,
verbatim:

> Copilot Summary and Copilot Narrative can now read visuals hidden
> behind bookmarks — Copilot Summary and the Copilot Narrative visual can
> now read visuals that are hidden by default and revealed by a
> display-only report bookmark. RLS and OLS permissions remain enforced.

The row links to
`https://learn.microsoft.com/en-us/power-bi/explore-reports/copilot-pane-summarize-content`
and
`https://learn.microsoft.com/en-us/power-bi/create-reports/copilot-create-narrative`.

**Neither page was drilled.** See Constraint.

### Current local coverage

`skills/powerbi/pbir-bookmarks/SKILL.md` frontmatter describes

> per-visual `display.mode` hidden/visible as the ONLY correct visibility
> toggle (NOT root-level `isHidden`)

and the body's flag table at `SKILL.md:145-146` covers `suppressDisplay`
and `suppressData`. A grep across `skills/powerbi/pbir-bookmarks/`
returns no mention of Copilot.

## What to change

One sentence in `skills/powerbi/pbir-bookmarks/SKILL.md`, placed wherever
`display.mode: hidden` is introduced: hidden visuals are still rendered
out of view for the reader, but Copilot Summary and the Copilot Narrative
visual can read them; RLS and OLS remain enforced.

## Constraint on the fix

**Do not exceed the What's New row.** The row is the only evidence
gathered — the two linked Copilot pages were not fetched, so the precise
scope is unestablished: whether this covers every hidden visual or only
those revealed by a display-only bookmark, whether it applies in Desktop
as well as the service, and whether any setting opts out are all
**unknown**. Word the caveat as the row words it, or drill the two pages
first and word it from them.

**Do not frame this as a security or RLS hole.** The row states RLS and
OLS remain enforced. The accurate framing is disclosure surface — content
a report author may have assumed was excluded from generated narrative
text is not — not a permissions bypass. Overstating it would be worse
than omitting it.

## Verification

1. `grep -rniE "copilot" skills/powerbi/pbir-bookmarks --include=*.md`
   — previously zero hits; should now return the caveat.
2. Confirm the wording does not claim more than the quoted row, per
   Constraint. If the two Copilot pages were drilled, cite them.
3. `uv run --with pyyaml scripts/lint-frontmatter.py skills/powerbi/pbir-bookmarks/SKILL.md`
   — this skill's `description` is already long; if the caveat was
   summarized into it, the 1024-char cap is the likely failure and the
   linter will name the field.
4. `pre-commit run --all-files`.

## Provenance

Found by the **second** `powerbi` drift audit run on 2026-09-07, against
the same window and head as the first.

**The two runs disagree on this item, and the disagreement is the reason
to read carefully before acting.** The first run listed it in its no-op
bucket (`00-audit-report.md`, No-op list) — a reasonable call: it is a
service-side Copilot behaviour and changes no PBIR encoding. The second
run classified it bucket (a) and promoted it to a recommended action, on
the narrower ground that `pbir-bookmarks` teaches hide-and-reveal
patterns and a reader can draw a now-false inference from them.

This brief exists because the second run's report recommended it, and
`/drift-handoff` transcribes recommendations rather than re-adjudicating
them. But it is the weakest item in this set by some margin, it is a
judgement call rather than a factual correction, and **declining it is a
legitimate outcome** — in which case say so and drop the brief rather
than leaving it pending indefinitely.
