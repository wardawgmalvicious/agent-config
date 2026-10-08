# Handoff: point drift-audit at the repo's skill trees

- **Audit run**: 2026-10-08
- **Source**: `prompt-audit`
- **Window**: floor none, the whole payload → head `c268691`
  (2026-10-08)
- **Covers recommended actions**: findings 9, 10 and 45
- **Kind**: changes which files `/drift-audit`'s mapping phase reads and
  where its proposed actions point. Behavior change in a project skill.
- **Target**: `.claude/skills/drift-audit/SKILL.md`

## The problem

`/drift-audit` Phase 2 decides whether an upstream change touches an
existing skill by globbing `~/.claude/skills/*/SKILL.md`. Platform
skills are pruned from user scope (root `CLAUDE.md` § "Commands"), so
no Fabric or Power BI skill is there to match. The audit reports that
every such change is then filed as a new-skill candidate. Its MCP
actions name the deployed `~/.claude/mcp/` copies, which the next
deploy overwrites, against the global rule to edit the repo, never
`~/.claude`. Three passages also keep "this line previously read…"
history, one of which restates a claim the file calls wrong.

## Evidence

- `.claude/skills/drift-audit/SKILL.md:115`, read 2026-10-08:
  > **Skill match** — `Glob ~/.claude/skills/*/SKILL.md` for
  > directory-name keyword hits; `Grep` skill descriptions and bodies
  > for feature-name and syntax keywords.
- Line 118 reads both MCP templates from `~/.claude/mcp/`, and the
  report's finding 10 quotes a proposed action at line 174: "add to
  ~/.claude/mcp/…".
- `claude/CLAUDE.md` § "Agent config source": "Edit the repo, never
  `~/.claude`."
- The report's finding 45: lines 24, 78 and 86 carry "this line
  previously read…", and line 78 restores a claim the file itself calls
  wrong.
- **Not established**: that a past run misfiled a platform match. The
  Grep half of line 115 names no path, so a run may have reached the
  repo through it. The Glob's target is wrong either way.

## What to change

1. **Line 115**: glob the repo's trees, `skills/*/*/SKILL.md` and
   `.claude/skills/*/SKILL.md`, and say the Grep covers both.
2. **Lines 118 and 174**: a proposed MCP action names
   `claude/mcp/.mcp.global.template.json` or
   `claude/mcp/.mcp.project.template.json`. Reading the deployed copy
   for the inventory is harmless after a deploy, but the repo copy is
   the one an action edits, so name it in both places.
3. **Lines 24, 78 and 86**: drop the history and keep the current claim
   only. At line 78, confirm the surviving sentence is the one the file
   holds true.

The patch's `drift-audit` hunks carry all three, and the file carries
no other brief's hunk.

## Constraint on the fix

`docs/handoffs/declined.md`, entry of 2026-10-08, "Removing dated
incident evidence from skills and rules": a removal that takes a
claim's only date or its failure description was declined, and only
trims that keep both landed. Finding 45's history goes only where it
says how a line came to be, never where it carries the date or the
failure a current claim rests on.

## Verification

1. `ls skills/*/*/SKILL.md .claude/skills/*/SKILL.md | grep -c fabric-tmdl`
   prints 1: the new glob reaches a pruned platform skill.
2. `grep -n 'Glob ~/.claude/skills\|previously read' .claude/skills/drift-audit/SKILL.md`
   prints nothing.
3. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`.
4. `uv run --with pyyaml scripts/skill-status.py --stale` names the
   retest this body edit needs; run it and stamp it.
5. `pre-commit run --all-files`.
6. Not gating: the next `/drift-audit` of `fabric` or `powerbi` should
   map a change to an existing platform skill as a skill match.

## Provenance

Findings 9 and 10 (high) and 45 (medium) from `/doctor prompt-audit`
run in this repo on 2026-10-08, audited against Fable 5.1, the model
`drift-audit` pins. The session that wrote this brief checked line
115's text the same day; the other lines are as the report quotes them.
