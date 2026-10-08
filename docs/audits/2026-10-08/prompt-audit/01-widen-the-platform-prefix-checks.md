# Handoff: widen the platform prefix checks

- **Audit run**: 2026-10-08
- **Source**: `prompt-audit`
- **Window**: floor none, the whole payload → head `c268691`
  (2026-10-08)
- **Covers recommended actions**: findings 1 and 2
- **Kind**: correction to a post-deploy guard command and a prefix list
  in project-scope instructions. No script changes.
- **Target**: `CLAUDE.md`, `.claude/rules/editing-skills.md`

## The problem

Root `CLAUDE.md`'s post-deploy check greps `~/.claude/skills` for four
of the six platform prefixes, and `.claude/rules/editing-skills.md`
lists five. `PLATFORM_PREFIXES` in `scripts/lint-skill-overrides.py`
has six: the grep misses `pbip-` and `powerbi-`, the rule `powerbi-`.
Three skills carry those prefixes, so the check that "must print
nothing" passes with any of them linked to user scope.

## Evidence

- `CLAUDE.md` § "Commands", line 42 at `c268691`:
  `ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid|msix)-'  # after any deploy: must print nothing`
- `scripts/lint-skill-overrides.py:74`:
  `PLATFORM_PREFIXES = ("fabric-", "pbir-", "pbid-", "pbip-", "powerbi-", "msix-")`
- `skills/powerbi/` holds `pbip-project-structure`,
  `powerbi-report-authoring` and `powerbi-report-design` (globbed
  2026-10-08).
- `.claude/rules/editing-skills.md:16-18`: "give a platform skill its
  group's prefix, `fabric-`, `pbir-`/`pbid-`/`pbip-` or `msix-`:
  `PLATFORM_PREFIXES` in `scripts/lint-skill-overrides.py` is the
  list."
- Measured 2026-10-08: the six-prefix grep printed nothing, so nothing
  is leaked now. Every `pbip-` and `powerbi-` skill sits in
  `skills/powerbi/` beside `pbir-` skills the four-prefix grep does
  match, so a whole-group re-link still shows. The gap bites only if
  the groups are reorganized or one of those skills is linked alone.
- `docs/evidence/root-claude-md.md:356` records an older,
  three-prefix form of the grep.

## What to change

1. **`CLAUDE.md`**, § "Commands", the line quoted above: widen the
   alternation to `^(fabric|pbir|pbid|pbip|powerbi|msix)-`. The line
   count stays the same, and root `CLAUDE.md` sits at its cap.
2. **`.claude/rules/editing-skills.md`**, § "Name and listing budget",
   the sentence quoted above: name `PLATFORM_PREFIXES` as the list and
   stop enumerating it. That is the audit's fix, and it leaves the
   list one home.

`prompt-audit.patch` has both hunks, but **its files also carry other
briefs' hunks**: `CLAUDE.md` holds finding 17's (brief 05) and
`editing-skills.md` findings 19 to 21's (brief 04). `git apply
--include` takes whole files, so apply these two by hand, or apply each
file and revert the hunks that belong elsewhere.

## Verification

1. `ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid|pbip|powerbi|msix)-'`
   prints nothing and exits 1.
2. `grep -n 'PLATFORM_PREFIXES = ' scripts/lint-skill-overrides.py`
   names exactly the prefixes the new grep spells.
3. `uv run scripts/lint-claude-md.py`.
4. A dated entry in `docs/evidence/root-claude-md.md`, under the
   heading line 356 sits in, recording the widened grep. The ledger
   takes a new entry, never an in-place fix.
5. `pre-commit run --all-files`.

## Provenance

Findings 1 and 2, both high confidence, from `/doctor prompt-audit` run
in this repo on 2026-10-08. The session that wrote this brief checked
both quotes, the prefix tuple and the three skills against the files
the same day.
