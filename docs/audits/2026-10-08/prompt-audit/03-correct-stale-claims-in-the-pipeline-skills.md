# Handoff: correct stale claims in the pipeline skills

- **Audit run**: 2026-10-08
- **Source**: `prompt-audit`
- **Window**: floor none, the whole payload → head `c268691`
  (2026-10-08)
- **Covers recommended actions**: findings 11, 12, 13, 14, 15, 42, 43,
  44 and 46
- **Kind**: corrections to project-scope skill bodies that a newer file
  contradicts: a path, a count, a reason, a scope. Finding 12 adds one
  step.
- **Target**: `.claude/skills/author-skill/SKILL.md`,
  `.claude/skills/drift-update/SKILL.md`,
  `.claude/skills/test-skill/SKILL.md`

## The problem

Three of this repo's pipeline skills state things a newer file has
since contradicted. Each passage still reads as current, and a cold
session follows it.

## Evidence and what to change

Line numbers at `c268691`; each quote is the report's.

| # | Location | Says | Contradicted by | Change |
| --- | --- | --- | --- | --- |
| 11 | `drift-update:289-292` | "does not reliably reload mid-session" | `editing-skills.md` § "Name and listing budget": skills hot-reload (2026-08-31, 2026-09-02) | rewrite the reason; the conclusion stays |
| 46 | `drift-update:384-386` | "Found 2026-09-11 … until the view replaced it" | history, not instruction | remove |
| 12 | `author-skill:460-464` | proposes deleting briefs "whose skill … now exists" | `docs/handoffs/CLAUDE.md:53`: such a brief means `/test-skill` has not run | add a bullet that keeps it queued |
| 13 | `author-skill:289-291` | "The other two examples predate…" | only `author-skill.example.md` remains | rewrite |
| 14 | `author-skill:78` | `templates/subagent-handoff.md` | the file is `docs/handoffs/templates/subagent-handoff.md` | fix the path |
| 42 | `author-skill:415-424` | step 8 lists three catalogue sections | project-scope entries go in `.claude/skills/README.md`, and Meta, Social and Windows apps sections exist | rewrite |
| 43 | `author-skill:466-470` | "a skill under `skills/` … cannot run in a worktree" | `test-skill:227-239` probes platform groups from a worktree | narrow it to `workflow`, `social` and `meta` |
| 15 | `test-skill:197-198` | "56 fixtures" | 74 + 16 are tracked; the file says never to restate a count | rewrite without a count |
| 44 | `test-skill:26-27` | paths pinned to the main checkout | briefs are worked in worktrees, so this sends writes to the main checkout | rewrite |

The session that wrote this brief checked finding 15's text, at line
198, on 2026-10-08. The patch's hunks for these three files carry every
fix, and the files carry no other brief's hunk.

## Constraint on the fix

Finding 12 adds behavior: a brief whose skill exists stays queued until
`/test-skill` stamps it. Read `docs/handoffs/CLAUDE.md` before writing
the bullet, and point at its rule rather than restating it. Finding 15's
fix states no count at all, by the file's own rule and root
`CLAUDE.md`'s.

Findings 11 and 46 trim history, so they fall under
`docs/handoffs/declined.md`'s entry of 2026-10-08, "Removing dated
incident evidence from skills and rules": a removal that takes a
claim's only date or its failure description was declined. Cut only
what says how a passage came to be, and keep the date and the failure
any current claim rests on.

## Verification

1. `ls docs/handoffs/templates/subagent-handoff.md` succeeds
   (finding 14).
2. `grep -n '56 fixtures\|until the view replaced' .claude/skills/test-skill/SKILL.md .claude/skills/drift-update/SKILL.md`
   prints nothing.
3. `grep -n 'Repos.Personal.agent-config' .claude/skills/test-skill/SKILL.md`:
   any line left names a place to read, never one to write.
4. `uv run --with pyyaml scripts/lint-frontmatter.py` on each of the
   three files.
5. `uv run --with pyyaml scripts/skill-status.py --stale`: run the
   retests it names and stamp each.
6. `pre-commit run --all-files`.

## Provenance

Findings 11 to 15 (high) and 42 to 46 less 45 (medium) from
`/doctor prompt-audit` run in this repo on 2026-10-08. `author-skill`
pins Fable 5.1 and was audited against it.
