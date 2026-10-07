# Drift audit — claude-code, 2026-10-06

## Audit window

- Floor: 2026-08-30 (resolved from: date)
- Fetch path: github-mcp — `list_commits` resolved HEAD, the by-`path` base and the in-window SHAs; one `gh api` projection of the same REST listing supplied each commit's date and subject (keeps ~38 signed commit objects out of context); both pinned refs were downloaded from `raw.githubusercontent.com` to the scratchpad and diffed on disk, the `changelog` long-window path, so only the added region (2,438 lines, 357,781 bytes) entered context, in six Read slices because the Read tool caps a call at 25k tokens.
- Sources audited: claude-code — skipped: fabric, fabric-iq-ontology, powerbi, skills-for-fabric, vscode-agent (not selected by `--sources`; their buckets are unaudited, not clean)
- Installed CLI during the run: 2.1.291; HEAD's top section is 2.1.292 (released today).
- Claude Code releases (`claude-code`): 38 commits in window — prior `f1af9b1f4b1fd4c776135381606edada82ef638e` (2026-08-28T18:19:26Z, last commit touching `CHANGELOG.md` before the floor; top section 2.1.251) → head `fbe20e00e2851fc01506f54f98a8f0b875af3847` (2026-10-06T18:59:09Z; top section 2.1.292). Diff: 587,814 → 945,458 bytes; two hunks — the prepend (`+2,437` lines: 34 version sections, 2,336 top-level bullets) and one in-place rewording of a 2.1.252 bullet (hook output cap "over 50K characters" → "over 10,000 characters … 2,000-character preview"). So the file was not a strict prepend this window. Every commit below is `chore: Update CHANGELOG.md and feed.xml` by GitHub Actions; each was listed, not fetched individually — the content came from the one two-ref diff.
  - `fbe20e00` (2026-10-06T18:59Z) — changelog update, `CHANGELOG.md` — listed, not fetched individually
  - `8e60c4ca` (2026-10-06T03:54Z) — same — listed, not fetched individually
  - `e8ae4518` (2026-10-05T23:32Z) — same — listed, not fetched individually
  - `2bfb629d` (2026-10-03T23:06Z) — same — listed, not fetched individually
  - `1c229fcd` (2026-10-02T20:19Z) — same — listed, not fetched individually
  - `52c76441` (2026-10-01T18:43Z) — same — listed, not fetched individually
  - `816ec211` (2026-10-01T17:59Z) — same — listed, not fetched individually
  - `f5f60250` (2026-09-30T19:09Z) — same — listed, not fetched individually
  - `ec44ca97` (2026-09-29T19:27Z) — same — listed, not fetched individually
  - `8364969e` (2026-09-28T18:01Z) — same — listed, not fetched individually
  - `7779afb1` (2026-09-25T21:49Z) — same — listed, not fetched individually
  - `163ae3a2` (2026-09-25T02:20Z) — same — listed, not fetched individually
  - `ddcb43a2` (2026-09-24T18:37Z) — same — listed, not fetched individually
  - `d78be948` (2026-09-23T19:18Z) — same — listed, not fetched individually
  - `56f36532` (2026-09-22T16:37Z) — same — listed, not fetched individually
  - `8187baaa` (2026-09-21T12:12Z) — same — listed, not fetched individually
  - `bf7d404e` (2026-09-19T03:10Z) — same — listed, not fetched individually
  - `f708f4f0` (2026-09-18T18:11Z) — same — listed, not fetched individually
  - `ca02e7de` (2026-09-18T18:06Z) — same — listed, not fetched individually
  - `31a3b00b` (2026-09-18T02:12Z) — same — listed, not fetched individually
  - `38035964` (2026-09-17T22:32Z) — same — listed, not fetched individually
  - `68ac8bbf` (2026-09-17T00:11Z) — same — listed, not fetched individually
  - `aad35ba3` (2026-09-15T20:22Z) — same — listed, not fetched individually
  - `f96c3b49` (2026-09-15T00:42Z) — same — listed, not fetched individually
  - `f2ccbe27` (2026-09-14T22:12Z) — same — listed, not fetched individually
  - `2b40e76d` (2026-09-12T19:45Z) — same — listed, not fetched individually
  - `df52d04a` (2026-09-11T19:17Z) — same — listed, not fetched individually
  - `536a2e23` (2026-09-10T20:30Z) — same — listed, not fetched individually
  - `9cdc2a4d` (2026-09-09T19:58Z) — same — listed, not fetched individually
  - `347b38e4` (2026-09-08T23:55Z) — same — listed, not fetched individually
  - `8e02f6dd` (2026-09-08T20:37Z) — same — listed, not fetched individually
  - `ab9b2cf7` (2026-09-06T02:54Z) — same — listed, not fetched individually
  - `d7dbd9a0` (2026-09-04T19:58Z) — same — listed, not fetched individually
  - `b3f0e501` (2026-09-03T23:48Z) — same — listed, not fetched individually
  - `f173a697` (2026-09-02T22:33Z) — same — listed, not fetched individually
  - `aef74afe` (2026-09-01T22:33Z) — same — listed, not fetched individually
  - `a1e64dc4` (2026-09-01T17:53Z) — same — listed, not fetched individually
  - `f275fa28` (2026-08-31T19:46Z) — same — listed, not fetched individually
- Filter: of 2,336 bullets, ~2,290 went to bucket (d) as a count (TUI, cloud sessions, Slack, Code Review, VS Code extension, gateway, mods/plugins internals, platform fixes). Removed entries: none; the one `-` line is the rewording above, which *confirms* `coding-bash.md`'s 10,000 / 2,000 figures rather than changing them.

## Drift / gap candidates (existing artifacts)

- **root `CLAUDE.md`** — path-scoped rules and nested `CLAUDE.md` now load on Write/Edit, not only Read _(claude-code, 2.1.288)_
  - Specific change: "Fixed path-scoped `.claude/rules` and nested CLAUDE.md files not loading when Write or Edit creates or changes a file in their scope (previously only Read loaded them)". Docs now read: "Path-scoped rules trigger when Claude uses the Read, Write, or Edit tool on a file matching the pattern". § "Editing conventions" ("the Read is what loads its `.claude/rules/` guidance"), § "How the pieces trigger" ("loads the same way") and the structure table ("a rule at its next matching Read") all state Read-only. The load still arrives with the tool result, so "Read before changing" stays right for governing the edit itself; what changed is that a Write/Edit without a prior Read now loads the rule for the rest of the session. `cat`/`sed`/heredoc still load nothing.
  - Reference: https://code.claude.com/docs/en/memory#path-specific-rules
  - Proposed action: minor edit
- **`.claude/rules/editing-rules.md`** — "loads when a file matching it is Read … cannot govern creating a file" _(claude-code, 2.1.288)_
  - Specific change: as above; a Write that creates the first file in a directory now loads the rule (after the write). The "cat, sed or heredoc" half stays true.
  - Reference: https://code.claude.com/docs/en/memory#path-specific-rules
  - Proposed action: minor edit
- **`.claude/rules/activation-testing.md`** — "Activation is keyed to the `Read` tool, not to the file" _(claude-code, 2.1.288)_
  - Specific change: for rules and nested `CLAUDE.md`, Write and Edit now also trigger; the 2.1.288 bullet names rules and nested CLAUDE.md only, not skills' `paths:`, so the skill half of the claim is unconfirmed either way. The probe recipe (`--allowedTools Read --disallowedTools Bash`) still works; its stated premise needs the wider trigger set. Also: on Windows denying Bash also turns off PowerShell (2.1.287 added a startup warning for it), so a probe that denies Bash has no shell tool at all — worth recording as the intended control.
  - Reference: https://code.claude.com/docs/en/memory#path-specific-rules
  - Proposed action: minor edit, then re-measure the skill `paths:` trigger set
- **`.claude/rules/editing-claude-md.md`** — "A nested `CLAUDE.md` loads on the session's own first Read beneath it, never at launch" _(claude-code, 2.1.288)_
  - Specific change: nested CLAUDE.md also loads on Write/Edit in its directory (changelog; the docs' nested-file sentence still says "when Claude opens a file there with the Read tool" for `AGENTS.md`).
  - Reference: https://github.com/anthropics/claude-code/blob/fbe20e00e2851fc01506f54f98a8f0b875af3847/CHANGELOG.md (2.1.288)
  - Proposed action: minor edit
- **`claude/rules/agent-instructions-scoping.md`** — "Write, Grep, Glob and Bash load nothing" and the "Fails silently when … only Grep, `cat` or a new file touch it" row _(claude-code, 2.1.288, 2.1.292)_
  - Specific change: Write and Edit now load rules and nested files (2.1.288); and the transcript gained a line "when a nested one isn't loaded", plus "instruction file not loaded" lines no longer go stale after `/cd` (2.1.292) — a second witness beside the `nested_memory` attachment and the terminal `Loaded` line the docs describe. The rule's probe date is 2.1.282.
  - Reference: https://code.claude.com/docs/en/memory#path-specific-rules
  - Proposed action: partial rewrite of § "How Claude Code loads them"
- **`claude/rules/README.md`** — "via Read, session-context, or an agent inspecting the working tree" _(claude-code, 2.1.288)_
  - Specific change: trigger set is Read, Write or Edit on a matching file.
  - Reference: https://code.claude.com/docs/en/memory#path-specific-rules
  - Proposed action: minor edit
- **`claude/settings.json`** — `effortLevel: "max"` no longer governs Opus 5.5; per-model `modelSettings` is the live form _(claude-code, 2.1.280, 2.1.267, 2.1.257)_
  - Specific change: "an effort level saved before `/effort` became per-model [no longer applies] to newly released models such as Opus 5.5; they start at their default until you pick a level"; docs: "a top-level `effortLevel` in your user settings file doesn't count for Opus 5.5 … keeps applying on Opus 5, Fable 5.1, and earlier models", Opus 5.5 defaults to `medium`, and `/effort` saves under `modelSettings.<model>.effortLevel`. `settings-reference` lists `effortLevel` values as low/medium/high/xhigh only (`max` is a frontmatter `effort` value and a `maxEffortLevel` no-cap value). **Measured 2026-10-06:** the deployed `~/.claude/settings.json` has no `effortLevel` at all and carries `"modelSettings": {"claude-opus-5": {}, "claude-opus-5-5": {"effortLevel": "xhigh"}}` — whether the harness dropped `max` or a `/effort` pick rewrote it is unmeasured; a `-Force` deploy would re-add the repo key beside the target-only `modelSettings`. `maxEffortLevel` (2.1.267) is new too.
  - Reference: https://code.claude.com/docs/en/model-config#adjust-effort-level and https://code.claude.com/docs/en/settings-reference#modelsettings
  - Proposed action: flag — a decision on what the payload carries (`effortLevel`, `modelSettings` per model, both), then edit
- **`.claude/rules/editing-skills.md`** — "The session default is `"effortLevel": "max"`" and "`ultracode` is not an effort level (it reports as `xhigh`)" _(claude-code, 2.1.280, 2.1.284, 2.1.267)_
  - Specific change: the session default on Opus 5.5 is `medium` unless a per-model level is saved (see above); Ultracode became its own toggle that "no longer forces xhigh effort and stays on at any effort level" (2.1.284), and `--effort ultracode` starts at xhigh; `effort:` frontmatter was "ignored on models whose default effort is still pinned (Opus 4.7, Opus 4.8, Fable 5)" until 2.1.267 — the 2026-09-01 measurement predates that fix.
  - Reference: https://code.claude.com/docs/en/model-config#adjust-effort-level
  - Proposed action: partial rewrite of § "Invocation and spend fields"
- **`.claude/rules/editing-skills.md`** — "`model:` lasts one turn, and only when the skill is slash-invoked … the pin silently ignored (2026-09-01)" _(claude-code, 2.1.259)_
  - Specific change: 2.1.259 "Fixed frontmatter `model:` on custom commands and skills being ignored in interactive sessions" and "Fixed auto mode running a turn on a model it doesn't support when a command or skill's frontmatter `model:` named one; the turn now keeps the session model". Docs now carry the auto-mode caveat verbatim: "In auto mode … a model that auto mode doesn't support also isn't used, and the session keeps its current model." The 2026-09-01 measurement was taken on the broken build. This session is evidence the `fable` pin is honoured on slash invocation in auto mode.
  - Reference: https://code.claude.com/docs/en/skills
  - Proposed action: re-measure the description-triggered case on ≥2.1.291, then minor edit
- **`.claude/rules/editing-skills.md`** — "Names are one flat namespace across both trees" _(claude-code, 2.1.282, 2.1.283)_
  - Specific change: the harness reserves the `anthropic-skills` namespace for skills synced from claude.ai ("skill folders, command files and workflow commands in the `anthropic-skills` … namespace no longer load"); the `claude-ai` reservation was reverted in 2.1.283.
  - Reference: https://code.claude.com/docs/en/skills
  - Proposed action: minor edit
- **`.claude/rules/deploy-scripts.md`** — "`~/.claude/skills` is a real directory of per-skill junctions" _(claude-code, 2.1.275, 2.1.280, 2.1.271)_
  - Specific change: Claude Code now syncs the skills enabled on the claude.ai account into `~/.claude/skills/synced/` (2.1.275), moves them to `~/.claude/skills/.trash/` when `syncClaudeAiSkills: false` is set or they age out under `cleanupPeriodDays` (2.1.271), and 2.1.280 fixed a bug where a `manifest.json` there moved *user* skills to `.trash/`. **Measured 2026-10-06:** `~/.claude/skills` holds `synced` beside the eight junctions; `link-claude.ps1`'s prune loop (lines 655–656) skips every non-reparse-point entry, so the linker already tolerates `synced/`, `.trash/` and a stray file — no script change, a documentation one. Supporting pattern: symlinked components are being gated upstream (plugin symlink paths refused 2.1.257; symlinked `.claude/rules` ask approval 2.1.284; a symlinked settings file's target now takes the settings-file permission question 2.1.290; cleanup deleting relocation junctions fixed 2.1.280) — more evidence for "copies, not links", and worth watching for user-scope skill junctions.
  - Reference: https://code.claude.com/docs/en/skills#how-synced-skills-behave
  - Proposed action: minor edit
- **`claude/settings.json`** — `syncClaudeAiSkills` / `syncClaudeAiPlugins` unset _(claude-code, 2.1.275)_
  - Specific change: both default on; a `false` is honoured only from user, local or managed scope ("a `false` in `.claude/settings.json` is ignored"). The synced set (`anthropic-skills:docs`, `pdf`, `pptx`, `xlsx`, `deep-research`, …) is in every session's listing on this machine, which is the listing-budget cost `editing-skills.md` and root `CLAUDE.md` already guard against for platform skills; `enabledPlugins` already turns `cowork-plugin-management@synced` off by hand.
  - Reference: https://code.claude.com/docs/en/settings-reference#syncclaudeaiskills
  - Proposed action: flag — decide, then edit
- **`claude/mcp/README.md`** — § "Per-server timeout — deliberately absent", verified against 2.1.251 _(claude-code, 2.1.274)_
  - Specific change: "Fixed Streamable HTTP MCP tool calls timing out after about 5 minutes even when a longer per-server `timeout` was set" — so the "no deadline worth raising" reading was wrong for http servers until 2.1.274. Docs now also describe, for HTTP/SSE servers, "a second, per-request timer that covers each request through to the server's first response byte … the greatest of three values: 60 seconds, the tool timeout that applies to the server, and `MCP_TIMEOUT`"; values below 1000 ms are ignored; and a 401/403 re-runs the `headersHelper` and retries once.
  - Reference: https://code.claude.com/docs/en/mcp
  - Proposed action: partial rewrite of that section
- **`claude/mcp/README.md`** — § "What belongs at which scope": "every user-scope server loads its whole tool surface into every session" _(claude-code, 2.1.287, 2.1.285, 2.1.288)_
  - Specific change: "Changed MCP server `alwaysLoad: false` to defer all of that server's tools behind tool search" (2.1.287), and a tool's own `_meta['anthropic/alwaysLoad']` is honoured (2.1.285) — a per-server lever that changes the scope cost argument. The `alwaysLoad` key was not found on the `/docs/en/mcp` page via WebFetch today.
  - Reference: endpoint/key docs TBD — verify before any template edit; changelog 2.1.287
  - Proposed action: flag
- **`claude/mcp/README.md`** — elicitation and DCR sections _(claude-code, 2.1.287, 2.1.281)_
  - Specific change: "Added URL prompts from MCP servers on the 2025-11-25 protocol … If a server no longer connects after this update, add `"bareElicitationCapability": true` to its MCP config entry" (2.1.287); URL-mode elicitation on 2026-07-28 connections (2.1.281); `{"decision":"block"}` from `Elicitation`/`ElicitationResult` hooks now honoured (2.1.284). The Fabric hosted endpoints are the servers most likely to need the new key; none has been probed on ≥2.1.287. The key is not on the `/docs/en/mcp` page per today's WebFetch.
  - Reference: key docs TBD — verify before template add; changelog 2.1.287
  - Proposed action: flag — probe one hosted endpoint on the current CLI
- **`claude/mcp/README.md`** — § "Prerequisites (project scope)", the stdio servers _(claude-code, 2.1.292, 2.1.274)_
  - Specific change: "Changed local (stdio) MCP server connections to negotiate protocol version 2026-07-28 by default on every install …; `MCP_PROTOCOL_NEGOTIATION=legacy` opts out", and servers that ignore the newer check are "remembered for 7 days and connected the older way" after one slow connect. Affects every `npx`/`uvx`/`dnx` entry in the project template.
  - Reference: https://code.claude.com/docs/en/mcp
  - Proposed action: minor edit
- **`claude/mcp/README.md`** — § "If you script an edit to `~/.claude.json` yourself": "a live session rewrites this file from memory … can be reverted" _(claude-code, 2.1.259)_
  - Specific change: "Fixed concurrent sessions silently reverting each other's `~/.claude.json` changes — workspace trust no longer resets and MCP/project state is no longer lost". Whether an *external* script's write is still at risk is unmeasured on the new build.
  - Reference: changelog 2.1.259 (no docs statement found)
  - Proposed action: flag — re-measure before relaxing the backup advice
- **`claude/rules/claude-config-scoping.md`** — same revert claim, plus the scope table _(claude-code, 2.1.259, 2.1.257)_
  - Specific change: as above; and "`defaultMode: "bypassPermissions"` in `.claude/settings.json` or `.claude/settings.local.json` [is] ignored, like `"auto"`" — the docs now say both values "don't take effect from project or local settings". The table already puts `defaultMode` at user scope; the sentence makes it a rule rather than a placement.
  - Reference: https://code.claude.com/docs/en/settings (precedence page, "The file can't set that value")
  - Proposed action: minor edit
- **`claude/agents/security-reviewer.md`** — permission-mode paragraph; no `omitClaudeMd` _(claude-code, 2.1.271, 2.1.292)_
  - Specific change: "Added `omitClaudeMd` to agent frontmatter … letting custom and plugin subagents run without user, project and local CLAUDE.md files" (2.1.271, docs-confirmed); subagent `permissionMode` frontmatter is live (docs: "If you leave it unset, the subagent inherits the main conversation's permission mode"; 2.1.292 fixed `permissionMode: auto` entering auto when unavailable). The agent's text names only the deprecated Task-tool `mode`.
  - Reference: https://code.claude.com/docs/en/sub-agents
  - Proposed action: flag — decide on `omitClaudeMd`; minor edit either way
- **`claude/rules/coding-bash.md`** — § "Claude Code hooks": "Any other non-zero is reported as a hook error and the call proceeds — so a crash fails open" _(claude-code, 2.1.288)_
  - Specific change: "Fixed PreToolUse and PermissionRequest hooks being skipped when matching them failed or the tool's input could not be serialized to JSON; the call is now blocked" — the exit-code semantics stand, but a harness-side failure to run the hook now fails *closed*. Not on the hooks docs page.
  - Reference: changelog 2.1.288
  - Proposed action: minor edit
- **`claude/CLAUDE.md`** — § "Local environment": "A spawn costs ~0.4 s (2026-09-04)" _(claude-code, 2.1.287, 2.1.274)_
  - Specific change: "Windows: Improved Bash tool speed by removing a subshell that ran before every command" (2.1.287); the Bash tool re-sources the shell profile only when plugin `bin/` directories change (2.1.274). The figure and possibly the `/proc/$$/cmdline` mode description predate both.
  - Reference: changelog 2.1.287
  - Proposed action: flag — re-measure
- **`claude/CLAUDE.md`** — § "Agent config source": reads of `~/handoff-inbox/` and `~/.claude/…` from a repo _(claude-code, 2.1.257, 2.1.284)_
  - Specific change: auto mode now offers, once, "before the first file read outside the working directories, … the option to block such reads (`permissions.blockReadsOutsideWorkingDirectories`)" (2.1.257; "Yes, but ask again next time" added 2.1.284). Accepting the block would make every inbox and log read fail in every mode.
  - Reference: https://code.claude.com/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories
  - Proposed action: flag
- **root `CLAUDE.md`** — § "Validating a change": the `--safe-mode` baseline _(claude-code, 2.1.283, 2.1.284)_
  - Specific change: interactive sessions "start in auto mode when no permission mode is configured, on every plan and provider; `permissions.defaultMode` still overrides it". A baseline that strips settings therefore runs in auto mode too (unverified for `--safe-mode` specifically) — relevant because auto mode prefers `cat`, which activates nothing.
  - Reference: https://code.claude.com/docs/en/permissions
  - Proposed action: flag — verify what `--safe-mode` keeps
- **drift-audit registry: `references/sources/claude-code.md`** — volume, size and shape facts _(claude-code, this run)_
  - Specific change: measured 2026-10-06 — 38 commits, 34 version sections, 2,336 top-level bullets and 358 KB across 39 days (2026-08-28 → 2026-10-06), about **60 bullets/day** against the entry's "~19 bullets/day"; the new region alone is 2.4× the skill's ~150 KB per-source budget and the Read tool's 25k-token cap forced six slices; and the file was not a strict prepend (one in-place rewording). The entry's filter earned its place again: ~46 bullets kept of 2,336.
  - Reference: this report
  - Proposed action: partial rewrite of the entry's "Two measured facts" paragraph

## New-skill candidates

_(none)_ — per the registry entry this source produces none by design; the one harness convention that a new skill *could* satisfy (a skill named `verify`) is reported under tooling below, for the user to decide.

## MCP / tooling / CLI additions

- **`/doctor prompt-audit`** (also `/checkup prompt-audit`) — audits "CLAUDE.md, CLAUDE.local.md, and AGENTS.md files, plus the rules, skills, commands, subagents, and output styles under `.claude/` and `~/.claude/`" for stale paths, stale commands and contradicting instruction files; takes a path argument; runs through the bundled `claude-api` skill (2.1.283, improved 2.1.283 later in the same release). _(claude-code)_
  - Reference: https://code.claude.com/docs/en/memory (section "Audit your instruction files")
  - Proposed action: flag — run it on this repo once, as a candidate addition to root `CLAUDE.md` § "Validating a change"
- **`/skill-doctor`** — "show which loaded skills go unused and what they cost in context, so you can prune them" (2.1.261). _(claude-code)_
  - Reference: changelog 2.1.261
  - Proposed action: flag — evaluate beside `skill-status.py`/`skill-telemetry.py` and `.claude/rules/activation-testing.md` § "No log sees a skill's conditional activation" (it is a listing-cost tool, not an activation witness)
- **Skills named `verify` or `simplify` run before commits** — "When a session starts with a skill named `verify` or `simplify` in place, Claude Code's commit instructions tell Claude to run it right before each commit, except for changes to docs or tests" (2.1.286; docs-confirmed). The first-party `/simplify` is present in sessions here, so that instruction may already be live beside `skills/workflow/commit`. _(claude-code)_
  - Reference: https://code.claude.com/docs/en/skills
  - Proposed action: flag — decide whether a `verify` skill wrapping `pre-commit run --all-files` is wanted, and check `commit`'s interplay
- **WebFetch** — "Fixed WebFetch silently dropping page text past 100,000 characters; it now says how much was unread and takes an `offset` to read on" (2.1.290). Measured today on 2.1.291: three code.claude.com pages of 50–76 KB came back as *raw markdown spilled to a file* rather than a summary, while smaller ones were answered by the summarizer — which is not the premise `drift-audit` § 4b records ("summarizes pages above ~30–40 KB"). _(claude-code)_
  - Reference: changelog 2.1.290
  - Proposed action: flag — re-measure § 4b's completeness-check premise in `.claude/skills/drift-audit/SKILL.md`
- **Glob/Grep** — "Fixed Grep and Glob reporting no matches when the file or folder they were given could not be read; Claude now retries once or tells you" (2.1.292), after "the search path being probed on disk before the permission check" moved (2.1.260). Both are candidates for the `No files found` anomaly `drift-audit` § 1 records against 2.1.291. _(claude-code)_
  - Reference: changelog 2.1.292, 2.1.260
  - Proposed action: flag — re-probe § 1's Glob call on 2.1.292 and date the workaround
- **`bashOutputMaxChars`** — new setting to raise "how much command … output Claude receives inline before it is saved to a file, up to 128K characters" (2.1.261; `taskOutputMaxChars` was retired in 2.1.277). _(claude-code)_
  - Reference: https://code.claude.com/docs/en/settings-reference#bashoutputmaxchars
  - Proposed action: flag — optional `claude/settings.json` key
- **`claude --bare`** — "connect only the MCP servers named on the command line, send the model no system reminders, and start no background tasks" (2.1.286). A candidate for the cold-probe recipe in `claude/CLAUDE.md`, which uses `--strict-mcp-config`. _(claude-code)_
  - Reference: changelog 2.1.286
  - Proposed action: flag

## No-op

- ~2,290 bullets: TUI, vim mode, cloud sessions, Claude Tag, Code Review, VS Code extension, Claude apps gateway, Claude Mods/plugin internals, Bedrock/Vertex/Foundry.
- `Write(path)` rules not matching (2.1.275) — no settings or `allowed-tools` here use one.
- Mid-pattern `:*` Bash rules (2.1.282) — none here; all rules use the trailing space-star form.
- Inline `!` shell in skills on CRLF (2.1.290) and under auto mode (2.1.271) — no skill here uses `!`.
- `<system-reminder>` escaping in hook output (2.1.292) — no hook here emits one.
- `InstructionsLoaded` gains `effort`, reliable `agent_id`/`agent_type` (2.1.288) — the hook logs the whole event; the `load_reason` set is unchanged (local histogram matches the docs' five values).
- `claude project purge` → `claude purge` (2.1.288) — unreferenced in the repo.
- `.claude/scheduled_tasks.json` (2.1.273) — covered by `/.claude/*` in `.gitignore`.
- `"attribution": false` (2.1.281) — the repo keeps the object form the changelog itself recommends for shared files.
- `timeZone` / `timeFormat` settings (2.1.257) — interface clock only; `claude/CLAUDE.md`'s UTC guidance is about tool output.
- AGENTS.md support (2.1.277) and its Bedrock/telemetry-off extension (2.1.281) — already in `agent-instructions-scoping.md` with both version floors.
- Hook default timeouts (UserPromptSubmit 30 s, SessionEnd 1.5 s budget) — consistent with the repo's explicit `timeout: 10` entries.
- `type: "sdk"` MCP entries skipped (2.1.274) — not used.
- `NO_PROXY` honoured for Claude Code's own requests (2.1.292) — pointer for `docs/handoffs/execute/claude-code-corporate-network.md`, no artifact here.
- 2.1.252 hook-output bullet reworded 50K → 10,000 / 2,000-character preview — matches `coding-bash.md` (read 2026-10-06).

## Recommended actions

1. **Repair** `.claude/skills/drift-audit/references/sources/claude-code.md`: re-state volume (~60 bullets/day), size per window, the non-strict-prepend case, and the 25k-token Read cap on the new region.
2. **Update** the rules-load trigger set (Read, Write or Edit) in root `CLAUDE.md`, `.claude/rules/editing-rules.md`, `.claude/rules/activation-testing.md`, `.claude/rules/editing-claude-md.md`, `claude/rules/agent-instructions-scoping.md` and `claude/rules/README.md`, keeping "Read before changing" as the way to get the rule in context *before* the edit; then re-measure whether skill `paths:` also fire on Write/Edit.
3. **Decide** effort configuration in `claude/settings.json` — `effortLevel: max` versus per-model `modelSettings` (the deployed file already carries `modelSettings`) — and **rewrite** `.claude/rules/editing-skills.md` § "Invocation and spend fields" (session default, Ultracode toggle, `effort:` fix in 2.1.267).
4. **Re-measure** `model:` on a description-triggered skill on ≥2.1.291 and **edit** `.claude/rules/editing-skills.md` with the auto-mode caveat and the reserved `anthropic-skills` namespace.
5. **Decide** `syncClaudeAiSkills` / `syncClaudeAiPlugins` in `claude/settings.json`; **edit** `.claude/rules/deploy-scripts.md` to name `~/.claude/skills/synced/` and `.trash/` as harness-owned entries the prune skips.
6. **Rewrite** `claude/mcp/README.md` § "Per-server timeout" (2.1.274 fix, HTTP per-request timer, helper re-run on 401/403); **flag** `alwaysLoad: false` under § "What belongs at which scope"; **probe** one hosted Fabric endpoint on the current CLI for `bareElicitationCapability`; **add** the stdio `MCP_PROTOCOL_NEGOTIATION=legacy` opt-out under § "Prerequisites"; **re-measure** the `~/.claude.json` revert hazard before relaxing it there and in `claude/rules/claude-config-scoping.md`.
7. **Edit** `claude/rules/claude-config-scoping.md`: `defaultMode` `auto`/`bypassPermissions` take effect only from user or managed settings.
8. **Decide** `omitClaudeMd` for `claude/agents/security-reviewer.md` and **edit** its permission-mode paragraph to name the `permissionMode` frontmatter; **fold** the same documented fact into `docs/handoffs/execute/drift-fetch-subagent.md`'s open question.
9. **Edit** `claude/rules/coding-bash.md` § "Claude Code hooks": a harness-side failure to match or serialize a PreToolUse hook now blocks the call (2.1.288).
10. **Re-measure** the spawn cost in `claude/CLAUDE.md` § "Local environment" after 2.1.287; **flag** there the one-time `blockReadsOutsideWorkingDirectories` offer for inbox and `~/.claude` reads.
11. **Verify** what `claude --safe-mode` keeps now that unconfigured sessions start in auto mode, and **edit** root `CLAUDE.md` § "Validating a change" accordingly; **record** in `.claude/rules/activation-testing.md` that denying Bash on Windows also removes PowerShell.
12. **Run** `/doctor prompt-audit` on this repo once and **decide** whether it joins root `CLAUDE.md` § "Validating a change"; **evaluate** `/skill-doctor` beside the skill-telemetry scripts.
13. **Re-probe** `drift-audit` § 1's Glob anomaly on 2.1.292 and **re-measure** § 4b's WebFetch summarization premise (raw spill observed today).
14. **Fold** the 2.1.286 (worktree subagent double load), 2.1.287 (nested CLAUDE.md re-attached after resume/compaction) and 2.1.281 (`--add-dir` double send) fixes into `docs/handoffs/execute/payload-claude-md-double-load.md` as evidence — its measured double loads were on 2.1.268–2.1.281.
15. **Record** this run's Phase 1 cost in `docs/handoffs/execute/drift-fetch-subagent.md`: no compaction and nothing left undiffed, but a 358 KB new region read whole, 2.4× the budget — the figure that brief asks to capture.
16. **Decide** the `verify` skill convention (2.1.286) and check `skills/workflow/commit`'s interplay with the harness's pre-commit `verify`/`simplify` instruction.
17. **Consider** `bashOutputMaxChars` and `claude --bare` as optional additions to `claude/settings.json` and the probe recipe.

## Next run

Pass one of these as the prior reference next time:

- Claude Code releases (`claude-code`) head: `fbe20e00e2851fc01506f54f98a8f0b875af3847` (2026-10-06T18:59:09Z)
- Or a single date: `2026-10-06` — note a date floor re-includes today's three commits (`since` is midnight UTC); the SHA does not.

A SHA from any registered source's repo, or any ISO date, is accepted.
