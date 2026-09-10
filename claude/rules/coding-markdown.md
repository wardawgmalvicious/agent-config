---
paths:
  - "**/*.md"
---

# Markdown Conventions

Applies to hand-authored markdown: READMEs, design notes, runbooks,
handoff briefs, and agent instruction files. Generated markdown is
exempt — tool output, a changelog assembled by a release script,
vendored upstream docs — and reformatting it by hand only guarantees the
next regeneration reverts you.

If a project-scope `.claude/rules/coding-markdown.md` exists, that file
supersedes this one.

This rule matches `**/*.md`, so it loads in nearly every session on the
machine. It is short for that reason: only conventions that survive
being applied to *any* repo's markdown belong here, and repo-specific
document structure belongs in that repo's own instructions instead.

## Line width

Hard-wrap prose at **76 characters**. Markdown renders soft-wrapped and
hard-wrapped text identically, so the width is chosen for the diff, not
the reader: a wrapped paragraph changes one line per edit, while an
unwrapped one changes the whole paragraph and the review has to re-read
it to find the edit.

What cannot wrap is exempt: table rows, a bullet whose content is one
long URL, and anything inside a code fence.

**Never reflow a paragraph you did not otherwise change.** A
whitespace-only rewrap rewrites `git blame` for every line it touches,
which costs most in documents carrying dated measurements — the blame
date is how a reader judges whether a claim is still true.

## Syntax

One form per element. Where markdown offers alternatives, these are the
portable choices:

| Element | Form | Why not the alternative |
| --- | --- | --- |
| Heading | ATX — `##` | setext cannot express depth past 2 |
| Unordered list | `-` | `*` collides with emphasis when scanning |
| Ordered list | `1.` | `1)` is not universally supported |
| Bold | `**bold**` | `__bold__` breaks inside snake_case words |
| Italic | `*italic*` | consistent with bold |
| Code fence | ```` ``` ```` | tilde fences are rarer in tooling |
| Link | inline `[text](url)` | reference links split the edit in two |

End the file with exactly one newline.

## Headings

- One `#` per file, matching what the file *is*.
- Never skip a level — `##` then `####` leaves the outline broken in
  every tool that builds one.
- Headings are addresses: something links to them, or will. Rename one
  only when the section's subject actually changed.
- Depth past `###` usually means the section wants to be its own file.

## Tables

Use a table when a reader compares **across** rows on two or more
attributes. A list with one attribute per item is a list; a table with
one column is a list with extra syntax.

Write the separator row minimally — `| --- |` — and do not pad cells to
align columns. Padding has to be recomputed whenever any cell's width
changes, so a one-word edit arrives as a diff touching every row, hiding
the change inside the reflow.

Keep table cells short. A cell running to three lines of prose is a
paragraph that has been put in a box.

## Code fences

Always tag the language: ` ```python `, ` ```bash `, ` ```json `. The
tag drives highlighting, and for an agent reading the file it is the
difference between a command to run and an illustration.

Use `text` for output, trees, and anything with no language. Fence
anything a reader might copy — paths, commands, filenames — rather than
leaving it as prose where a line break can corrupt it.

## Prose discipline

These are what make a document survive being read six months later.

**Front-load the conclusion.** The first sentence of a section says what
is true; the rest says how it was established. A reader who stops after
one sentence should not be misled.

**One fact, one home.** A number, a count, or a limit restated in a
second file is a number that will eventually disagree with itself, and
nothing checks it. Put it in one place and link to it. This is the most
common way a set of documents rots — each copy was correct when written.

**Date a measured claim.** "Measured 2026-09-10" lets a reader judge
staleness without re-deriving it. An undated claim is indistinguishable
from a guess once its author has moved on.

**Correct in place.** When something turns out to be wrong, edit the
original statement rather than appending a contradiction further down. A
document that asserts both X and not-X is worse than one asserting
either, because now the reader has to work out which is current.

**Say what the failure looks like.** Guidance that only describes the
happy path leaves the reader unable to tell whether they hit the case it
covers. Name the error text, the symptom, or the silence.

**Bold marks the load-bearing clause**, not every noun that feels
important. Emphasis everywhere is emphasis nowhere.

## Anti-patterns

- Reflowing or reformatting text you are not otherwise changing.
- Emoji as section markers or decoration.
- Nesting lists past two levels — restructure instead.
- "Note:", "Important:", "Remember:" where the sentence already carries
  the weight.
- Two trailing spaces as a line break. Use a blank line; the spaces are
  invisible and editors strip them.
- A heading with no content under it, standing in for a list item.
- Linking bare URLs as their own text when the destination has a name.
- Hedging a verified fact ("it seems that", "should probably") — either
  it was checked, or say plainly that it was not.
