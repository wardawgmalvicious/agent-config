# Drift audit — vscode-agent, 2026-10-06

## Audit window

- Floor: 2026-09-01 (resolved from: date)
- Fetch path: github-mcp, with an on-disk diff.
  - github-mcp resolved HEAD, the in-window list, the diff base and both directory listings: 5 calls.
  - All four registered files changed blob SHA. Reading them at both refs would have cost about 179 KB against the 150 KB budget. So no file entered context: a blobless shallow clone of `microsoft/vscode-docs` went into the session scratchpad and was diffed there.
  - 13 anonymous GitHub API calls supplied dates, subjects and the per-file commit lists.
  - Phase 3 checked two pages on the live site with WebFetch. Both matched `main`.
- Sources audited: vscode-agent — skipped: fabric, powerbi, claude-code, fabric-iq-ontology, skills-for-fabric (not selected by `--sources`)
- VS Code agent customization surface: 19 commits listed in window, which reached `main` as 17 first-parent commits — prior `28f76f5f` (2026-08-28) → head `c642b585` (2026-10-01). Counts are for the four registered files. Other pages in `path` are in brackets.
  - `c642b58` (2026-10-01) — "Refactor agent documentation (#10417)": `custom-instructions.md` +11/-0 [`agent-plugins.md`, `mcp-servers.md`]
  - `8889b05` (2026-09-29) — "VS Code release 1.140 (#10404)", release squash: `agent-skills.md` +7/-4, `hooks.md` +4/-2, `custom-agents.md` +1/-1, `custom-instructions.md` +1/-1 [every other page]
  - `1606fea` (2026-09-27) — PR #10398 merge, carrying `103ef3e6` ("clarify compatibility with OpenAI Codex"): `agent-skills.md` +9/-3
  - `4f4413d` (2026-09-23) — "VS Code release 1.139 (#10348)": `custom-instructions.md` +142/-215, `custom-agents.md` +112/-81 [`mcp-servers.md`]
  - `91b05da` (2026-09-21) — "Docs/agent hooks harness support (#10329)": `hooks.md` +186/-423, `custom-agents.md` +5/-5 [`agent-plugins.md`; outside `path`, `docs/agents/reference/hooks-reference.md` and `docs/agents/run/agent-harnesses.md`]
  - `c9d4cd2` (2026-09-18) — PR #10332 merge, carrying `2d3f6a89` and `70664392`: [`overview.md` +83/-60] only
  - `ff30176` (2026-09-18) — PR #10331 merge, carrying `2e915451`: [`overview.md` +6/-6] only
  - `b5fb0d9` (2026-09-17) — PR #10303 merge, carrying `5708902d`: [`mcp-servers.md` +2/-0] only
  - `e951b76` (2026-09-17) — PR #10300 merge (user-home references), carrying `79ccd275`: `agent-skills.md` +2/-2, `custom-agents.md` +1/-1, `custom-instructions.md` +1/-1 [`prompt-files.md`]
  - `b30d3f3` (2026-09-17) — PR #10297 merge, carrying `e5e77920`: [`mcp-servers.md` +9/-2] only
  - `3893104` (2026-09-15) — "VS Coode release 1.138 (#10288)": the date line of each of the four, +1/-1 [`agent-plugins.md` +94/-6]
  - `b2a3aa4` (2026-09-13) — PR #10278 merge (troubleshooting refresh), carrying `0e3f18b2` and `4316a2c4`: `custom-instructions.md` +3/-3
  - `dc7c2ba` (2026-09-08) — "VS Code release 1.137 (#10267)": `custom-instructions.md` +11/-19, `custom-agents.md` +9/-9, `agent-skills.md` +4/-3, `hooks.md` +1/-1 [`overview.md` +69/-7]
  - `99bbccc` (2026-09-03) — PR #10243 merge, carrying `78460cbe` and `0ff80a1`, which is dated 2026-08-28: [`language-models.md` +3/-3] only
  - `7177031` (2026-09-03) — PR #10237 merge (tools refresh), carrying `48c393d4`: [`tools.md` deleted, -80] only
  - `56b8f49` (2026-09-02) — "VS Code release 1.136 (#10221)": the date line of each of the four, +1/-1
  - `0959679` (2026-09-01) — PR #10217 merge, carrying `3407f557`: [`mcp-servers.md` +3/-1] only
- Net, base to head: `hooks.md` +188/-423, `custom-instructions.md` +159/-229, `custom-agents.md` +126/-95, `agent-skills.md` +19/-9.
  - The per-commit counts exceed the net by 5 lines in `hooks.md` and 12 in `custom-instructions.md`. Most of that is the date line each release rewrites. I did not check commit by commit for lines added and then removed inside the window.
  - From `overview.md` and the harness pages I read only the sections the deprecation notes link to. I did not diff them whole.

## Drift / gap candidates (existing artifacts)

- **README.md** (§ "Tool support") — instruction locations now split by harness _(vscode-agent)_
  - Specific change:
    - The custom-instructions page now gives one row per session and format (`4f4413d`). Agent Host's Copilot format reads `~/.copilot/instructions`, its Claude format reads `~/.claude/rules`, and the Local agent's user scope is "VS Code profile storage".
    - `:208-214`'s table ("Checked 2026-09-09") still lists both folders as user defaults for everything. `:391-395` lists `~/.claude/rules` among the folders Agent Host sessions read.
    - `:266-268` quotes "harness-agnostic folders like `~/.copilot` and `~/.claude`". That sentence still stands on the Agent Host concept page (`agent-host.md:87`), but it left the instructions page in `dc7c2ba`. The per-harness rows contradict what the README concludes from it: "the payload keeps reaching Copilot without these settings at all".
    - This settles what `:273-279` asks this source to watch for. The docs pair Copilot-format folders with the Copilot harness and Claude-format folders with the Claude harness, which is what the 2026-09-30 panels showed.
  - Reference: https://code.visualstudio.com/docs/agent-customization/custom-instructions
  - Proposed action: partial rewrite, through `copilot-payload-retirement.md`, which already rewrites § "Tool support". Do not edit ahead of it.
- **README.md** (§ "Tool support") — Claude-format hooks now need `chat.useClaudeHooks` _(vscode-agent)_
  - Specific change:
    - `:231-239` gives `chat.hookFilesLocations`' defaults as the four `.github`/`.claude` paths, and expects a future release to add new locations switched on.
    - The hooks page now says the setting's "default value is empty because the built-in locations are registered separately". Each Claude-format location "Requires `chat.useClaudeHooks`", which is off by default (`91b05da`, 2026-09-21; live page checked 2026-10-06).
    - `:383-389` says matchers are "read and ignored". That now applies only to the Local harness with `chat.useClaudeHooks` on. The Claude target runs the Claude Agent SDK and points to Claude Code's own hooks reference.
  - Reference: https://code.visualstudio.com/docs/agent-customization/hooks
  - Proposed action: partial rewrite, through the retirement brief, as above.
- **README.md** (§ "Tool support") — the Session Target picks the harness _(vscode-agent)_
  - Specific change: `:220-222` says "The Local agent *is* the sidebar Chat". The hooks and harness pages now call the Chat view and Agents window "clients that display and control sessions on either host". The **Session Target** control chooses among Local, Copilot, Claude, Codex and Cloud.
  - Reference: https://code.visualstudio.com/docs/agent-customization/hooks
  - Proposed action: minor edit, through the retirement brief.
- **claude/rules/vscode-scoping.md** — Claude hooks and the Local agent's user scope _(vscode-agent)_
  - Specific change:
    - `:60-62` says a profile with no location switches "inherited the whole `~/.claude` payload, hooks included". `:63-68` says a location left out of the map keeps its default, and the default is on.
    - The docs now say three things against that. Claude-format hooks need `chat.useClaudeHooks`, which is off by default. `chat.hookFilesLocations` has an empty default. The Local agent's user instructions live in profile storage, not `~/.claude/rules`.
    - This rule stays after the retirement (§ "What stays").
  - Reference: https://code.visualstudio.com/docs/agent-customization/hooks
  - Proposed action: minor edit, through `copilot-harness-switches.md`, which lists this file among those it will edit (`:108-110`).
- **claude/rules/agent-instructions-scoping.md** — the docs' format table gained a Local row _(vscode-agent)_
  - Specific change:
    - `:151-154` has rows for Copilot and Claude only. The page's "Choose a format" table (`4f4413d`) adds a **Local** row:
      - project: `.github/copilot-instructions.md`, `AGENTS.md` or `CLAUDE.md`
      - targeted: `.github/instructions/**/*.instructions.md` or `.claude/rules`
      - user: profile storage
    - The page writes Copilot's targeted glob as the recursive `**/*.instructions.md`, where the rule has `*.instructions.md`.
    - `:141-149` says `chat.useAgentsMdFile`, `chat.useNestedAgentsMdFiles` and `chat.useClaudeMdFile` apply to the Local agent only. The page now says the same.
  - Reference: https://code.visualstudio.com/docs/agent-customization/custom-instructions
  - Proposed action: minor edit, in the retirement brief's commit that corrects this table (§ "In this repo", the three statements from `6545f2e`).
- **claude/CLAUDE.md** (§ "GitHub Copilot no longer inherits this payload") — `chat.useClaudeMdFile` belongs to the Local agent _(vscode-agent)_
  - Specific change:
    - `:181-183` reads "never `~/.claude`, except `CLAUDE.md` where `chat.useClaudeMdFile` is on. That is the Copilot harness."
    - The page now ties that setting to the Local agent, and its Copilot row lists no `CLAUDE.md`. The 2026-09-30 Copilot panel did list the root `CLAUDE.md`, by a route nobody traced.
    - `:184-185`'s "unprobed here" was settled by the 2026-10-05 turn.
  - Reference: https://code.visualstudio.com/docs/agent-customization/custom-instructions
  - Proposed action: minor edit, through the retirement brief's rewrite of this section. `copilot-harness-switches.md` § "The claim in question" already questions this sentence.
- **copilot-harness-switches.md** (`docs/handoffs/execute/`) — three documented facts it does not record yet _(vscode-agent)_
  - Specific change:
    - (1) The docs say the Local agent's user instructions live in "VS Code profile storage" (`4f4413d`, 2026-09-23). The brief's reading of the 1.139.0 bundle (`:53-60`) lists `~/.claude/rules` as a built-in Claude location. README `:202-206` measured rules loading from that folder on 2026-09-09. Re-measure rather than pick one.
    - (2) The docs give `chat.hookFilesLocations` an empty default. The brief's table says "every built-in path `true`" (`:48`).
    - (3) The Copilot target's hooks are "the shared Copilot SDK implementation", documented on GitHub. The docs add: "Some harnesses discover the same hook files, such as `.github/hooks/*.json` or `.claude/settings.json`". That could explain the two hook entries the Copilot panel counted (retirement brief § "Not checked"). Unverified.
    - Not recorded anywhere here: whether machine-config's profile audit (`vscode-scoping.md:107-111`) checks `chat.useClaudeHooks`.
  - Reference: https://code.visualstudio.com/docs/agent-customization/hooks
  - Proposed action: flag. Add these to questions 1 and 2 and to the measured table when the brief is worked. The brief is blocked by the retirement.
- **drift-audit** (`references/sources.md`, `vscode-agent` entry) — the source has outgrown its file list, its release cadence and its purpose _(vscode-agent)_
  - Specific change:
    - Pages outside the fetched set:
      - `hooks.md` now covers only the harness choice and the Local setup. The Local schema moved to `docs/agents/reference/hooks-reference.md` (`91b05da`), outside `path`.
      - Which target runs which harness, and the Claude target's settings, are in `docs/agents/run/agent-harnesses.md` and `docs/agents/concepts/agent-harnesses.md`, also outside `path`.
      - Every Local-only deprecation note links to `overview.md` § "Migrate customizations". That page is in `path` but not in `files`.
    - `artifacts` is wrong in both directions. It names `scripts/README.md` and `scripts/link-claude.ps1`, which no finding touched. It leaves out `claude/CLAUDE.md`, `claude/rules/vscode-scoping.md` and `claude/rules/agent-instructions-scoping.md`, where the findings landed.
    - "VS Code ships monthly" no longer holds. The docs took releases 1.136 to 1.140 between 2026-09-02 and 2026-09-29.
    - The entry's premise is how the payload "reaches GitHub Copilot", and that ends with the retirement. What is still worth measuring is which targets read `~/.claude`.
  - Reference: https://github.com/microsoft/vscode-docs/commit/91b05da193962797de3ea3eaecfc10dab58801a4
  - Proposed action: partial rewrite, after a decision on what this source is for once the retirement lands.
- **drift-audit** (`SKILL.md` § 4a and § 7) — evidence from this run for the open fetch-strategy decision _(vscode-agent)_
  - Specific change:
    - (1) More than 5 commits on a directory source sends the skill to the two-ref `get_file_contents` route. Here that would have been about 179 KB against the 150 KB budget. A blobless shallow clone (`git clone --filter=blob:none --no-checkout --shallow-since=<date>`), diffed on disk, kept every file out of context and also gave exact attribution along the first-parent line.
    - (2) A `since:` listing misses a commit dated before the floor that reaches `main` through an in-window merge. `0ff80a1` (2026-08-28) arrived with `99bbccc` (2026-09-03). The two-ref diff includes its change. The commit list and the per-commit-patch route do not.
    - (3) The path filter returns branch commits and "Merge branch 'main' into …" commits rather than the merges that put them on `main`: 19 SHAs for 17 merges. A patch of a "merge main into branch" commit shows main's changes arriving, not the branch's own. `git log --first-parent <base>..<head> -- <path>` lists commits in the order they reached `main`.
  - Reference: https://github.com/microsoft/vscode-docs/commits/main/docs/agent-customization
  - Proposed action: flag. Add this to `docs/audits/2026-10-06/fabric/18-decide-table-source-fetch-strategy.md`, the same decision for `table` sources. Another session wrote that brief today and has not committed it.

## New-skill candidates

_(none)_

## MCP / tooling / CLI additions

- **`#file:` references in VS Code skills and agents** — a `SKILL.md` or `.agent.md` body can now reference a file as `#file:./path` (relative to the file) or `#file:~/path` (from the home folder) (`79ccd275`, merged in `e951b76`, 2026-09-17).
  - Reference: https://code.visualstudio.com/docs/agent-customization/agent-skills
  - Proposed action: flag. Nothing under `skills/`, `claude/` or `.claude/` uses it (`git grep -F '#file:'` finds 0), and nothing here needs it.

## No-op

- Five release squashes (1.136–1.140) rewrite every page's `DateApproved`. All four `MetaDescription`s were reworded.
- `custom-instructions.md`, all already consistent with this repo or irrelevant to it:
  - new examples, and a new "Verify your instructions" section
  - "Resolve conflicting instructions": sources are additive with no precedence, as `agent-instructions-scoping.md` already says
  - `/init` and `/create-instructions` are now Local-only
  - the Diagnostics view is replaced by **Developer: Open Agent Debug Logs**, which nothing here names
  - the Local agent reads `.github/copilot-instructions.md` only when `github.copilot.chat.codeGeneration.useInstructionFiles` is on
  - Agent Host user folders do not roam through Settings Sync
- `custom-agents.md`:
  - sections reordered
  - `~/.claude/agents` now listed at user scope, as README `:212` already has it
  - `chat.agentFilesLocations` and `chat.modeFilesLocations` deprecated and Local-only, as README `:216-229` already has it
  - agent-scoped `hooks` are Local-only, and `chat.useCustomAgentHooks` is replaced by `chat.useHooks` plus Workspace Trust
  - Agent Host loads no prompt files, and there are none here
- `agent-skills.md`:
  - `chat.agentSkillsLocations` deprecated and Local-only, as README already has it
  - Codex through Agent Host, and the Copilot app, added to the portability lists. The Codex payload was removed here on 2026-08-28.
  - the location table is unchanged and still not split by harness
- `overview.md`'s four migrations and "the Local agent will be removed in a future release" are already in README `:262-271` and in `copilot-harness-switches.md` questions 3 and 4. Its MCP migration to `.mcp.json` was done here on 2026-10-04 (`1a0c5f7`).
- `chat.editor.preferCopilotHarness` and remembered Claude selections (harness page) are already in `copilot-harness-switches.md` question 5.
- Root `CLAUDE.md:78-79`'s `chat.useClaudeMdFile` sentence: the retirement deletes it.
- In `path` but outside `files`, not diffed: `agent-plugins.md`, `mcp-servers.md`, `language-models.md`, `prompt-files.md`, `tool-sets.md`, and `tools.md`, deleted in `7177031`.

## Recommended actions

1. **README.md**, **claude/rules/agent-instructions-scoping.md** and **claude/CLAUDE.md**: fold their findings into `copilot-payload-retirement.md`, which already rewrites or corrects all three. Edit none of them ahead of it.
2. **copilot-harness-switches.md**: add the three documented facts, and leave the `claude/rules/vscode-scoping.md` edit to that brief. Re-measure the Local agent's user-scope instructions before either changes.
3. **machine-config**: ask through its inbox whether `vscode-profiles.ps1 -Audit` checks `chat.useClaudeHooks`.
4. **drift-audit** registry: decide what `vscode-agent` is for after the retirement. Then rewrite its `path`, `files`, `artifacts` and cadence note to match.
5. **drift-audit** `SKILL.md`: add this run's three points to fabric brief 18 before that decision is made.

## Next run

Pass one of these as the prior reference next time:

- VS Code agent customization surface head: `c642b585b02a55cbc28508a56c927d34262fded6` (2026-10-01)
- Or a single date: `2026-10-06`

A SHA from any registered source's repo, or any ISO date, is accepted.
