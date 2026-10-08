---
status: open
priority: 1
needs: [user]
blocked-by: []
written: 2026-10-08
---

# Handoff: make coding-tmdl, coding-dax and code-review agree on names

- **Written**: 2026-10-08, by a `/triage` run, from two conflicts a
  prompt audit in a client Fabric repo session flagged without a hunk.
  Re-measured at `835171a`, which turned up the worse defect below.
- **Kind**: a decision of the user's on the naming convention, then
  edits to two rules and one skill. Nothing is drafted.
- **Priority 1**: `coding-tmdl.md` loads whenever a `.tmdl` file is read,
  and its examples write a property TMDL does not have.

## coding-tmdl writes a property TMDL does not have

`claude/rules/coding-tmdl.md`'s pattern is a "PascalCase identifier,
aliased display name with spaces" (line 35), and six of its examples
set `displayName: "…"` on a column or a measure. TOM has no such
property: the `Column` class lists 47 members and `Measure` 27, and
neither names one (Learn's API reference, fetched 2026-10-08), while
"All TMDL objects have an exact match with their TOM properties, except
for Translations and Role members" (TMDL reference, read 2026-10-08).
What TOM does carry is the object's `name`, which is what reports show
and DAX references, `sourceColumn` for the source's own name, and
per-culture `caption` translations. So the rule's aliasing likely has
to become the object named with spaces and `sourceColumn` holding the
PascalCase source name.

Not run: deserializing a file with a `displayName:` line, which would
show whether TMDL rejects it as an unknown keyword or drops it. Run
that before rewriting. The scheme predates `828b530` (2026-08-28),
which moved the file; no platform skill writes `displayName:`.

## coding-dax and coding-tmdl disagree on what DAX names a table

`claude/rules/coding-dax.md` (lines 23–25): "Table names: match the
model identifier (PascalCase per TMDL rule), wrapped in single quotes
when referenced: `'Transaction Line'`". Its own example is a name with
a space, and `coding-tmdl.md` says "DAX always references display
names: `'Transaction Line'[Order Total]`" (line 83). The audit noted
both came in one commit. Settling the section above settles this one.

## code-review restates conventions the rules own

`skills/workflow/code-review/SKILL.md` § "Naming & style" (lines 75–79
on 2026-10-08) gives its own list, and two lines disagree with the
rules a review loads as it reads the files:

- "DAX measures: PascalCase, descriptive", where `coding-dax.md` writes
  measures with spaces, as `[Total Sales]`.
- "KQL: `camelCase` for `let`-bound variables", where `coding-kql.md`
  has PascalCase for query-level constants and `_camelCase` or
  `_snake_case` for temporary values.

The shape: name the rule that owns each language and keep no copy of
its conventions, so there is one fact in one home.

## Where it lands

`claude/rules/coding-tmdl.md` and `coding-dax.md`, then
`code-review/SKILL.md` § "Naming & style". Both rules have Copilot
ports, so re-stamp them, porting nothing
(`.claude/rules/editing-rules.md`):
`uv run --with pyyaml scripts/lint-instructions.py --stamp`. The rules
deploy by copy; `code-review` owes a retest.

## Re-measure before acting

```bash
grep -n "displayName:" claude/rules/coding-tmdl.md                        # 6 lines on 2026-10-08
grep -n "PascalCase\|camelCase" skills/workflow/code-review/SKILL.md claude/rules/coding-dax.md claude/rules/coding-kql.md
```
