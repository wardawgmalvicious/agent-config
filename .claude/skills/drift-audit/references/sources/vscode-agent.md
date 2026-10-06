# `vscode-agent` — VS Code agent customization surface

- `repo`: `microsoft/vscode-docs`
- `branch`: `main`
- `path`: `docs/agent-customization/`
- `files`: `custom-instructions.md`, `agent-skills.md`, `custom-agents.md`,
  `hooks.md` — the four pages describing where VS Code looks for each
  artifact class
- `shape`: `prose`
- `sections`: none — the four pages are individually small, so the fetch
  unit is the whole file (see `files`), and there is no heading worth
  re-fetching by name.
- `drill.host`: `code.visualstudio.com`
- `drill.via`: `webfetch`
- `artifacts`: `README.md`, root `CLAUDE.md`, `.claude/rules/`,
  `scripts/README.md`, `scripts/link-claude.ps1`

Governs how this repo's `~/.claude` payload reaches GitHub Copilot, so its
findings land on the repo's own deployment docs rather than on skills and
rules. Claims about this surface go stale silently, and are as often wrong
on arrival — twice now. `scripts/link-copilot.ps1` was written to work
around a `chat.agentSkillsLocations` gap that had already been closed for
two months, and the audit that retired the script is what caught it. Then
a 2026-09-04 measurement recorded `~/.claude/skills` as not resolving, and
a 2026-09-09 retest found it resolving fine — the earlier run had most
likely toggled that root off, because the `chat.*Locations` settings are a
per-location on/off map and *not* the additive allowlist their own
"deprecated, only used by the Local agent" note suggests. Both failures
share a shape: a negative result about this surface was written down as a
property of the tool. Pin such claims to a date you have checked, not to a
version you have inferred, and prefer re-measuring to reasoning forward
from a past result.

**A third failure mode, and the audit cannot catch this one.** Measured
2026-09-09: an active `model:` key in a `SKILL.md` stops VS Code
dispatching that skill as a slash command — nothing is sent, no session
is created, so it reads as a hang rather than an error. The page lists
six frontmatter fields (`name`, `description`, `argument-hint`,
`user-invocable`, `disable-model-invocation`, `context`) and `model` is
not among them, while other undocumented fields this payload carries
(`effort:`, `when_to_use:`) are simply ignored. So the breakage lives in
what the page does **not** say, and no diff of it will ever surface
that. Bound this source's promise accordingly: it witnesses what VS Code
documents, not how VS Code behaves. Findings of that kind arrive by
measurement or not at all — which is an argument for probing the slash
path (`test-skill` covers the traps) rather than expecting Phase 3 to
drill one out.

VS Code ships monthly — faster than the Fabric cadence — and moves these
pages (they were under `docs/copilot/customization/` until the 2026
reorg), so a 404 on the path means find the new one, not that the source
is gone. `list_commits` does not follow renames, so a window that
straddles a move resolves its prior ref against the *old* path: filtering
`docs/agent-customization/` with `until:` a 2026-06-01 floor returns
nothing at all, and the directory reads as newly created rather than
renamed. The pre-reorg state is under `docs/copilot/customization/`
(`b9731d7c` is its last commit before that floor). Diff across the two
paths rather than reading the empty listing as "no prior state."
This repo also squashes a whole release branch into one commit,
so its commit *messages* run to thousands of characters — list with
`fields: ["sha"]` and let SKILL.md § 4a's sizing and escape-hatch steps
pick the strategy, because the commit count here says nothing about the
volume.

One schema stretch, deliberate: `artifacts` names repo files instead of
an artifact class, which keeps Phase 2 off a full skill sweep this source
rarely earns. The **directory** `path` is not a stretch but the reason
`files` exists — the four pages change independently, the useful unit is
"did any of them move," and a directory is what `list_commits` wants
while `files` is what `get_file_contents` wants.

That narrowness is a scope choice, not a claim about reach. This source
*can* surface findings that bear on skills — the 2026-08-29 run turned up
forked skill context (`context: fork` in `SKILL.md` frontmatter, gated by
`github.copilot.chat.skillTool.enabled`, landed `eea0ec7e`) — but VS
Code's skill features are not Claude Code's, so the payoff does not
justify sweeping every skill on every run. Report findings like that as
bucket (c) tooling notes rather than mapped drift.
