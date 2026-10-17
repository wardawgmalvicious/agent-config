---
status: deferred
priority: 3
needs: [an ADF or Synapse Git repo]
blocked-by: []
reopen-when: a repo on this machine holds Azure Data Factory or Synapse Git integration
written: 2026-10-17
---

# Handoff: name the folder ADF and Synapse write pipelines to

- **Written**: 2026-10-17, from one audit follow-up,
  [2026-10-08/prompt-audit/07](../../audits/2026-10-08/prompt-audit/completed/07-correct-claims-in-the-user-coding-rules.md),
  by `/triage`. Re-measured against the payload at `7d0757e`, which
  changed nothing the follow-up left open.
- **Kind**: an edit, not drafted: one sentence in a user-scope rule,
  once a real repo shows the folder.

## The open item

`claude/rules/coding-expressions.md` loads on `**/pipeline/*.json`, and
its lines 16-17 say ADF and Synapse pipeline expressions auto-load
"where the repo keeps their JSON in a `pipeline/` folder", by hand
otherwise. That is true whatever folder either service writes, so the
rule is correct as it stands. What it cannot yet say is whether Git
integration puts pipelines in `pipeline/`, which would turn the
condition into a plain statement, or somewhere the glob misses, which
would call for a second glob.

Re-measured 2026-10-17: Learn's "Source control in Azure Data Factory"
and "Source control in Synapse Studio" name a configurable root folder
and say each resource is exported as its own JSON, with no subfolder
named. Everything finds no `linkedService` folder anywhere on this
machine, so no repo here holds either service's Git integration. The
follow-up's own reads, of 2026-10-08, found the same.

## Where it lands

`claude/rules/coding-expressions.md`, the scope list under the H1. A
user-scope rule: after the edit, lint it with
`uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/coding-expressions.md`,
and deploy with `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta`.
A changed glob also owes a check that it matches the repo's files.

## Not checked

The folder layout itself: no repo here to read, and no Learn page that
gives it. The ADF utilities' npm README, which may show one, refused
the 2026-10-08 session with 403 and was not retried.

## Re-measure before acting

```bash
es -n 5 -ad linkedService   # 2026-10-17: nothing; a hit is a Git-integrated ADF or Synapse repo
sed -n 9,18p claude/rules/coding-expressions.md   # 2026-10-17: the conditional at 16-17
```
