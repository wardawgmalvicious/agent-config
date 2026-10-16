---
status: open
priority: 2
needs: [user]
blocked-by: []
written: 2026-10-15
---

# Handoff: `link-claude.ps1` links into a client repo without checking its ignore line

- **Written**: 2026-10-15, from one inbox note of 2026-10-13 by a
  session in a client repo that runs a Python worker on Azure Container
  Apps. Re-measured against the payload at `f8abbed`: the script holds
  no `check-ignore` and reads no `.gitignore`.
- **Kind**: a decision, the user's, since it changes a deploy script;
  then the edit. Nothing is drafted.

## The gap

`link-claude.ps1 -ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups
<groups>` makes `.claude/skills/<name>` junctions inside a client
repo's tree. Two client repos carried `/.claude/skills/` in their
`.gitignore` on 2026-10-13, and the note's repo had no such line until
that session added it that day. The script neither adds nor checks it.

**Git follows a junction**, measured here on 2026-10-15 in a scratch
repo with Git for Windows 2.55.0, `core.symlinks` true: `git add -A`
staged a junction's target file as an ordinary `100644` blob under the
junction's path. So without the line, a broad add in a client repo
commits a copy of every linked skill, this payload's text with it, the
leak `personal-repo-name-guard.md` (deferred) would guard from the other
side.

## The proposal

Before linking, run `git -C <repo> check-ignore -q .claude/skills/<name>`
against `-ClaudeDir`'s parent, and stop, or warn, when it fails. Which
of the two, and whether the script may add the line itself, is the
user's call. `skills/README.md` § "Platform groups" states the
precondition in prose since 2026-10-15, and changes with whatever the
script comes to do.

## Where it lands

`scripts/link-claude.ps1` on its `-ClaudeDir` path, a negative-case
suite under `tests/scripts/` if one is added, and
`.claude/rules/deploy-scripts.md`'s `-ClaudeDir` bullet. Then one run
against a scratch repo without the line, and one with it.

## Not checked

- Whether any client repo with linked groups lacks the line today.
- A `git add` of one named path rather than `-A`, and how `git status`
  shows an unignored junction.

## Scrubbing

The note was genericized at source; the repos are cited by kind.

## Re-measure before acting

```bash
grep -n -i -E 'check-ignore|gitignore' scripts/link-claude.ps1   # nothing on 2026-10-15
grep -n 'Ignore `/.claude/skills/`' skills/README.md             # the precondition, since 2026-10-15
```

Re-run the junction test with the current Git for Windows: a junction
from a scratch repo's `.claude/skills/<name>` to a folder holding a
file, `git add -A`, then `git ls-files -s`.
