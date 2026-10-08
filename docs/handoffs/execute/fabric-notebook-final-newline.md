---
status: open
priority: 2
needs: [user, a Git-synced Fabric repo]
blocked-by: []
written: 2026-10-07
---

# Handoff: measure whether Fabric ends a notebook part with a newline

- **Written**: 2026-10-07, by a `/triage` sweep, from one audit
  follow-up:
  2026-09-10 skills-for-fabric 04, in a run retired 2026-10-08
  (`git show 7dd627e:docs/audits/2026-09-10/skills-for-fabric/completed/04-measure-notebook-serialization-before-editing.md`),
  whose 2026-09-11 decision queued the measurement for a repo the user
  chooses. Re-measured at `4b6e108`: nothing has measured it since.
- **Kind**: a measurement in another repo, then a decision of the
  user's. No edit is authorized until the results are in.

## What is open

`claude/rules/fabric-git-serialization.md` says a `notebook-content.*`
part ends with a newline (lines 48–51 on 2026-10-07) and that item
folders take `-text`, not `text eol=lf` (lines 169–174). Upstream
`skills-for-fabric` 0.3.13 observed LF and no final newline, and Learn
says only that the service writes LF. The follow-up's "What to
measure" lists the six checks, and its "Decision after measuring" the
outcomes; neither is restated here.

Re-measured 2026-10-07: both rule passages are unchanged. Seven commits
have touched the rule since 2026-09-10, `7584a46` (2026-09-29) on how a
notebook sync rewrites markdown cells among them, and none measured a
notebook part's final byte.

## Three corrections to the follow-up

- **Count carriage returns with `tr -cd '\r' < <file> | wc -c`**, not
  its step 3's `grep -c $'\r'`, which miscounts in Git Bash
  (`~/.claude/CLAUDE.md` § "Shell traps").
- **Deploy with
  `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`**, not
  its `-SkillGroups workflow`, which would prune the `social` and
  `meta` groups (root `CLAUDE.md` § "Commands").
- Its knock-on named `claude/CLAUDE.md` and `claude/rules/README.md`.
  Only the README still summarizes the rule (lines 124–125).

## Where it runs

A Git-synced Fabric repo on this machine, the user's choice: the client
Fabric repo, or the personal sample Fabric repo kept as a test bed.
Its session can be asked through that repo's inbox, so the measurement
need not wait for a session here. Keep any repo, workspace or client
name out of what lands.

## Where it lands

`claude/rules/fabric-git-serialization.md`, and its README line if the
policy changes. A user-scope rule deploys by copy, so the edit owes the
deploy above and a `diff` of the deployed copy.

## Re-measure before acting

```bash
grep -n "notebook-content" claude/rules/fabric-git-serialization.md   # line 50 on 2026-10-07
git log --since='2026-10-07 00:00' --format='%h %ad %s' --date=short -- claude/rules/fabric-git-serialization.md
```
