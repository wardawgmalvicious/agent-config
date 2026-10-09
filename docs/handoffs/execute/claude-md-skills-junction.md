---
status: open
priority: 3
needs: [user]
blocked-by: []
written: 2026-10-09
---

# Handoff: `claude/CLAUDE.md` calls `skills` junctioned, where each skill is

- **Written**: 2026-10-09, from one inbox note of 2026-10-09 by a
  prompt-audit session in the personal machine-config repo. Re-measured
  against the payload at `7240d9e`, which changed nothing here.
- **Kind**: an edit to `claude/CLAUDE.md`, drafted below. `/triage`
  flagged it as a `CLAUDE.md` edit, and the user left it unapproved at
  that table on 2026-10-09, so it waits on their word.

## The wording

`claude/CLAUDE.md` § "Agent config source" says "**`skills` is
junctioned**, live on save". On disk `~/.claude/skills` is a plain
directory and each skill in it is a junction into this repo: `Get-Item`
read `Directory` for the folder and `Junction` for
`~/.claude/skills/land`, targeting `skills\workflow\land` (measured here
2026-10-09). Root `CLAUDE.md`'s table already says "one junction per
skill". The note's session read the same, and reported folders of
Claude Code's own beside the junctions, not re-read here.

The misreading costs where a tool walks the folder: a recursive `grep`
that does not follow junctions finds nothing under it, which is why
`learn` greps the deployed skills with `-R` (`43b5cf1`).

```diff
-`scripts/link-claude.ps1`: **`skills` is junctioned**, live on save; the
+`scripts/link-claude.ps1`: **each skill is a junction**, live on save; the
```

## Where it lands

`claude/CLAUDE.md` § "Agent config source", one line of the same
length, so the 200-line cap holds. It owes a dated entry at the end of
`docs/evidence/user-claude-md.md` § "Agent config source", whose opening
paragraph says "`skills` is junctioned, and is the only thing that is"
and stays as written, then
`./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`.

## Not checked

Which other folders Claude Code keeps in `~/.claude/skills`; the edit
does not depend on them.

## Re-measure before acting

```powershell
(Get-Item "$HOME\.claude\skills").Attributes; (Get-Item "$HOME\.claude\skills\land").LinkType   # Directory, then Junction, on 2026-10-09
```

```bash
grep -n "junctioned" claude/CLAUDE.md   # line 144 on 2026-10-09
```
