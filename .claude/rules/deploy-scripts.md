---
paths:
  - "scripts/link-claude.ps1"
  - "claude/settings.json"
  - "claude/mcp/**"
---

# Deploying with link-claude.ps1

Root `CLAUDE.md` § "Commands" has the invocations and the never-bare rule; §
"How this repo is structured" has the table of each mechanism and when an
edit goes live.

- `claude/settings.json` deploys as a key-level merge: a key only the target
  has, such as the `/config`-owned `theme` or `model`, survives `-Force`; a
  key both sides have is replaced whole, so a runtime edit nested inside a
  repo-owned key is lost (2026-09-14).
- `~/.claude.json` is the only target with its own opt-in switch,
  `-GlobalMcp`. It replaces the file's top-level `mcpServers` with
  `claude/mcp/.mcp.global.template.json` and prunes the rest, touching no
  other key. It is off even under `-Force`, skipped under `-SkillsOnly`, and
  ignored unless `-ClaudeDir` is user scope: that file is Claude Code's
  runtime state, not payload, and no other scope has one (a project's
  equivalent is its committed `.mcp.json`, which the linker never deploys).
  Every run reports the drift regardless. Docker Desktop re-adds
  `MCP_DOCKER` whenever it connects a client, and nothing here needs it
  (2026-09-14). The two `ConvertFrom-Json` switches that keep the round trip
  lossless are in `claude/mcp/README.md`; each fails silently when omitted.
- Templates describe other repos and sit in their payload; live config
  describes this repo and sits where its tool looks. The VS Code MCP
  template is the exception: it sits in `.vscode/` beside its live file,
  because that is where it deploys.
- The copies are copies on purpose: never turn `claude/CLAUDE.md`,
  `claude/settings.json` or a copied directory into a link. A symlinked
  `~/.claude/settings.json` broke three times upstream in 2026, once
  destructively (2.1.247's sandbox cleanup deleted it).
- A copied directory takes repo content without `-Force`; `-Force` is needed
  only to delete a target-only file.
- Claude Code finds a skill one level deep, `<skills-root>/<name>/SKILL.md`,
  so `~/.claude/skills` is a real directory of per-skill junctions, not one
  junction for `skills/`. A branch that lacks a linked skill leaves its
  junction dangling once checked out, until the script runs again. Claude
  Code never reads `~/.claude/mcp`; that copy exists so the template-copy
  commands in `claude/mcp/README.md` resolve.
- Deployed names are fixed by each tool, so moving payload under `claude/`
  changes only where the script reads from, and the next run picks it up
  without `-Force`. Hook commands resolve via `$HOME/.claude/...`, whatever
  the layout.
- `-SkillGroups` deletes only junctions resolving into this repo's
  `skills/`, so a skill authored in the target survives the prune.
- Run the script from the tree whose content you want deployed: it takes
  `$RepoRoot` from `$PSScriptRoot`. The main tree's copy run with
  `-ClaudeDir <worktree>` relinks every junction back to the main tree,
  printing `Relink` and still ending `Done` (2026-09-02). Given
  `-ClaudeDir`, `-SkillGroups` prunes that directory's `skills/`, never user
  scope.
- `-ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups fabric` pushes only
  the Fabric skills into a client repo, without this machine's agents, hooks
  or rules. They are junctions, so every save to one is live in that repo's
  sessions from then on.
