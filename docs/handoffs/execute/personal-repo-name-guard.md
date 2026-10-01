---
status: deferred
priority: 3
needs: [user]
blocked-by: []
reopen-when: a personal repo's name is found committed in a repo under a client root
written: 2026-09-30
---

# Handoff: should a hook keep personal repo names out of company repos

- **Written**: 2026-09-30, when the rule landed in `claude/CLAUDE.md`
  § "Git identity is folder-scoped". The user deferred the hook that
  day.
- **Kind**: a change to `identity-guard`'s reach. The shape below was
  never approved, so it goes back to the user when this reopens.

## Why it waits

The user's rule, quoted in `docs/evidence/user-claude-md.md` under the
same heading, lets what already exists stay. So one name slipping
through does no lasting harm, and the sentence that states the rule
loads in every session at no cost. When the rule landed, no breach
of it had been seen: the one session that met the case asked the user
first.

The cold probes run after the deploy, in the ledger under the same
heading, are the case for building it: Haiku wrote the path into a
client repo's README and flagged nothing, so a Haiku subagent making a
client repo's commit holds neither this rule nor that repo's own.

## The shape it could take

`identity-guard` runs the other way. It keeps the names on
`~/.config/identity-denylist.txt` out of every repo, and an `exempt:`
line skips a client root altogether, so it never looks for this. A
second kind of line, a personal repo's name scanned **only** under the
`exempt:` roots, would reuse its scans. Read
`claude/hooks/identity-guard.sh`'s header before choosing a format.

What that shape would still miss (read from the header, 2026-09-30):

- **A substring match fails on real text.** Each list line is a
  case-insensitive fixed string, and `agent-config` is inside the Learn
  slug `data-agent-configurations`
  ([copilot-client-repo-findings.md](copilot-client-repo-findings.md),
  item 2, which met it in `lint-instructions.py`). These names need
  word boundaries.
- **Branch names and pull request text are outside it.** It scans added
  lines and messages on `git commit` and `git push`, never a ref's name,
  and a PR is opened through `gh` or `github-mcp`.
- **Only Claude Code's commits reach it** in a repo that does not wire
  its git-hook mode.

## Verification, once built

- `tests/hooks/identity-guard/` gains cases for the new line kind: a
  name under an exempt root blocks, the same name elsewhere passes, and
  a word that merely contains one passes. Run the suite on the repo copy,
  then on the deployed one after `./scripts/link-claude.ps1 -SkillGroups
  workflow,social,meta`.
- `pre-commit run --all-files`.

## Scrubbing

This repo is public. The client roots the scan would cover live in the
local denylist's `exempt:` lines and are named nowhere here.
