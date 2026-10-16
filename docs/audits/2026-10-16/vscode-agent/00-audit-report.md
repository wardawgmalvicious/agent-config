# Drift audit — vscode-agent, 2026-10-16

## Audit window

- Floor: per source (resolved from: ledger). Argument `vscode-agent` read as `--sources vscode-agent`, as today's `fabric` and `claude-code` runs read theirs.
  - vscode-agent: `c642b585b02a55cbc28508a56c927d34262fded6` (2026-10-01) from `docs/audits/2026-10-06/vscode-agent/`
- Fetch path: clone (blobless, `microsoft/vscode-docs` `main`, 21 MB). Strategy: base→head diff of the four `files`, 72,728 bytes, read whole; `prose` shape, so no per-version walk.
- Sources audited: vscode-agent — skipped: claude-code, fabric, fabric-iq-ontology, powerbi, skills-for-fabric (narrowed by the argument)
- VS Code agent customization surface: 9 landings in window — prior `c642b585` (2026-10-01) → head `e6026c88063236095c7801d87c51e5c47aa39be5` (2026-10-16T08:31-07:00). `path` +/- first, the four `files`' share after.
  - `e6026c880` (2026-10-16) — merge of #10497, carries `e1efbf99b` "Restructure MCP content"; `mcp-servers.md` +105/-311, three one-liners, +111/-314; `files` untouched
  - `baa88c2fb` (2026-10-16) — merge of #10495, carries `8fc5e5375` "Refresh Custom Agents article for correctness and structure"; +109/-240, `files` +95/-232 (`custom-agents.md` +72/-220)
  - `108c8cb60` (2026-10-14) — squash "Add MCP configuration from Customizations editor (#10478)"; `mcp-servers.md` +129/-53, `overview.md` +6/-4; `files` untouched
  - `f7ee5a5c6` (2026-10-14) — squash "VS Code release 1.142 (#10469)"; +27/-11, `files` +4/-4 (`DateApproved` → 10/14/2026)
  - `fdf324630` (2026-10-13) — squash "Simplify agent terminology (#10452)"; +120/-111, `files` +73/-71 ("Local agent" → "Local harness", "Agent Host" dropped)
  - `a88484276` (2026-10-08) — squash "Clarify Copilot harness across docs (#10448)"; `hooks.md` +2/-2
  - `2264a3af4` (2026-10-08) — merge of #10410, carries 7 commits: `f41d09d5a` (10-08), `7d368b828` (10-07), `33d3464fe`, `b9dbee47d`, `fc37c7a9d`, `c5c14400c`, `eeb699708` (all 2026-09-30, before the floor; the entry's documented case); `migrate-customizations.md` new +221, `overview.md` +5/-96; `files` +5/-5
  - `a2f9dd4e6` (2026-10-07) — squash "Direct to GH docs for GH enterprise managed settings (#10432)"; `mcp-servers.md` +1/-1; `files` untouched
  - `4fe6b0340` (2026-10-06) — squash "VS Code release 1.141 (#10431)"; +115/-20, `files` +22/-4
  - Left undiffed, outside `files`: `mcp-servers.md` (+261/-370 over four landings), `migrate-customizations.md` (new), `overview.md`, `agent-plugins.md`, `prompt-files.md`, `tool-sets.md`, `language-models.md`. Three targeted reads were taken beyond the entry, on disk: `mcp-servers.md`'s diff grepped for `mcp.json`/harness and its "Choose a configuration destination" section read at head; `docs/agents/reference/ai-settings.md`'s `chat.*Locations` rows and `mcp-configuration.md`'s `.mcp.json` lines at both refs, because `README.md`, `vscode-scoping.md` and `claude-config-scoping.md` carry claims only those pages can witness.
  - Live renders not fetched: the clone holds the pages' own source at head, and the site can only lag it; the follow-up checks the live page before editing.

## Drift / gap candidates (existing artifacts)

- **README.md:187-189** — hooks page restructured _(vscode-agent)_
  - Specific change: `hooks.md` § "Choose the hook implementation for your session" now tables four Session Target choices (Copilot, Claude, Codex, Cloud) with Local in a note, and drops the sentence the README paraphrases ("Agent Host hosts Copilot, Claude and Codex; Local runs in the extension host; Chat view and Agents window are clients of either host"). "Agent Host" no longer appears on the four pages. README's "five targets … clients of either host (rendered 2026-10-06)" is true as dated, no longer what the page says.
  - Reference: https://code.visualstudio.com/docs/agent-customization/hooks
  - Proposed action: minor edit
- **README.md:200-201** — removal notice narrowed _(vscode-agent)_
  - Specific change: at base, `docs/agents/reference/ai-settings.md` said "This setting and the Local agent will be removed in a future release" on `chat.instructionsFilesLocations`, `chat.promptFilesLocations`, `chat.agentFilesLocations` and `chat.agentSkillsLocations`. At head only `chat.agentSkillsLocations` (`:369`) still carries it; the other three now read "for the Local harness" with a migration link and no removal sentence. README's "the docs mark those settings and the harness for removal" now holds for one of four. Page sits outside the source's `path`.
  - Reference: https://code.visualstudio.com/docs/agents/reference/ai-settings
  - Proposed action: minor edit
- **claude/rules/vscode-scoping.md:96** — same fact, second home _(vscode-agent)_
  - Specific change: "the docs mark Local and these switches for removal together" — as above; one of the four settings keeps the sentence at head.
  - Reference: https://code.visualstudio.com/docs/agents/reference/ai-settings
  - Proposed action: minor edit
- **.claude/skills/drift-audit/references/sources/vscode-agent.md** — entry incomplete for what the payload claims _(vscode-agent)_
  - Specific change: (1) `:18` "Governs how this repo's `~/.claude` payload reaches GitHub Copilot" is stale since the Copilot payload retirement landed 2026-10-13 (`be70086`; README:209-214). (2) `files` omits the pages this window changed most — `migrate-customizations.md` now holds the `chat.*Locations` migration semantics that left `overview.md`, and `mcp-servers.md` was rewritten twice. (3) `path` excludes `docs/agents/reference/`, where the removal notice (`ai-settings.md`), `.mcp.json` reading rules (`mcp-configuration.md`) and the custom-agent field table (`custom-agent-file-reference.md`, where `custom-agents.md`'s table moved this window) now live. (4) No `drill.strip` field, which the schema lists. Checked and holding: the `:37-40` claim — `agent-skills.md` at head still lists six SKILL.md fields, `model` not among them.
  - Reference: `docs/audits/2026-10-06/vscode-agent/04-decide-vscode-agent-source-scope.md` (D-4, the user's call, condition now met)
  - Proposed action: partial rewrite, after D-4 decides keep-re-scoped or retire

## New-skill candidates

_(none)_

## MCP / tooling / CLI additions

- **Customization Marketplace (Experimental)** — `agent-skills.md` § "Install a skill from the Customization Marketplace": with `chat.customizations.marketplace.enabled` on, **Discover** installs a skill package into a chosen user or workspace skills directory; `~/.claude/skills/` is among the listed personal locations. A real directory installed there survives `link-claude.ps1`'s prune, which skips non-reparse-point items (`scripts/link-claude.ps1:741`), and root `CLAUDE.md`'s post-deploy `ls … | grep` check names only platform prefixes.
  - Reference: https://code.visualstudio.com/docs/agent-customization/agent-skills
  - Proposed action: flag; off by default, no edit until a profile here turns it on
- **`chat.mcp.workspaceRootConfig.enabled`** (new in window, Experimental) — gates only whether **MCP: Add Server** offers the workspace-root `.mcp.json` destination; "Existing `.mcp.json` files remain available when this setting is off" (`mcp-configuration.md:414` at head). `claude-config-scoping.md:30` ("everyone who clones, in Claude Code and VS Code") holds; `:33`'s "docs call this file deprecated" holds, now as "labeled deprecated in the guided flow".
  - Reference: https://code.visualstudio.com/docs/agents/reference/mcp-configuration
  - Proposed action: none — recorded so the next run need not re-derive it

## No-op

- Terminology sweep: "Local agent" → "Local harness", "Agent Host" dropped across the four pages; `vscode-scoping.md` and `agent-instructions-scoping.md` quote the bundle's setting text, dated, not the pages
- UI renames: **Configure Chat** gear → **Open Customizations**; **New X (Workspace/User)** dropdown → plus icon per group
- `/skills`, `/create-skill`, `/hooks` (Local or Copilot), `/create-hook`, `/init`, `/create-instructions`, `/agents` scoped to Local; handoffs now "In the Local harness"
- `custom-agents.md`: user-level rows split by harness (`~/.copilot/agents` Copilot, `~/.claude/agents` Claude); Local's user-level agents stated as profile storage — same docs-omit shape `agent-instructions-scoping.md:199` records for `~/.claude/rules`; no artifact claims otherwise
- `github.copilot.chat.organizationCustomAgents.enabled` default flipped to on (Copilot harness)
- Anchors renamed with the old kept: `hooks.md#agent-scoped-hooks-for-local`, `custom-instructions.md#sync-local-agent-instructions-across-devices`; `overview.md#migrate-*` → `migrate-customizations.md#move-*`; no artifact links any
- `mcp-servers.md` dropped "the Agent Host doesn't read `.vscode/mcp.json` directly … forwards" (quoted in `docs/evidence/user-claude-md.md:1605`, a dated ledger line)
- Codex wording: "through Agent Host (Experimental)" → "experimental Codex integration"

## Owed re-checks

- **`2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`** — owed to any drift audit, by its `**Needs**:` line at `:135`
  - Owes: the behavioural check — § 1's slash-free `Glob` lists the registry; on a WebFetch-fallback run only, § 4b's completeness check catches the note and the tells
  - Outcome: passed — `Glob` pattern `*.md`, `path` the skill's `references/sources/`, returned six files (this session, VS Code extension; CLI version not read). § 4b: not in this window — clone path, no fallback
  - Leaves open: the § 4b half, until a run falls back; today's two earlier runs owed the same line, and it still stands
- **`2026-10-06/vscode-agent/04-decide-vscode-agent-source-scope.md`** — owed to the user, not this run, at `:142`; named because its condition is met
  - Owes: the D-4 call after `copilot-payload-retirement.md` lands — keep `vscode-agent` re-scoped or retire it
  - Outcome: not in this window's remit — the retirement landed 2026-10-13; the registry-entry finding above is this run's input to it
  - Leaves open: the decision, then the entry edit verified by that brief's steps

## Recommended actions

1. `README.md:187-189` — minor edit: the hooks page's four-plus-Local layout; drop "clients of either host"
2. `README.md:200-201` — minor edit: removal notice now on `chat.agentSkillsLocations` alone
3. `claude/rules/vscode-scoping.md:96` — minor edit: same fact; consider one home for it
4. `.claude/skills/drift-audit/references/sources/vscode-agent.md` — put D-4 of brief 04 to the user, now unblocked; on keep, partial rewrite: premise at `:18`, `files`, `path` (or a second source for `docs/agents/reference/`), `drill.strip`
5. Marketplace install into `~/.claude/skills` — flag only
6. Stamp `2026-10-06/claude-code/11`'s log with this run's outcome

## Next run

Pass one of these as the prior reference next time:

- VS Code agent customization surface head: `e6026c88063236095c7801d87c51e5c47aa39be5` (2026-10-16)
- Or a single date: `2026-10-16`

A SHA from any registered source's repo, or any ISO date, is accepted.
