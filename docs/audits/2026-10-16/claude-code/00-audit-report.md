# Drift audit — claude-code, 2026-10-16

## Audit window

- Floor: per source (resolved from: ledger)
  - claude-code: `fbe20e00e2851fc01506f54f98a8f0b875af3847` (2026-10-06T18:59:09Z) from `docs/audits/2026-10-06/claude-code/`
- Fetch path: clone (blobless, `main`, 929 commits; the floor SHA is an ancestor of head, used as the diff base directly)
- Sources audited: claude-code — skipped: fabric, fabric-iq-ontology, powerbi, skills-for-fabric, vscode-agent (not selected)
- Claude Code releases: 8 landings in window — prior `fbe20e0` (2026-10-06) → head `c017428c8c27e604840435048d5bce6a9a22c040` (2026-10-16T20:52:45Z)
  - `c017428` (2026-10-16) — squash "chore: Update CHANGELOG.md and feed.xml", `CHANGELOG.md` +66/-0 — 2.1.302 (63 bullets)
  - `03b5892` (2026-10-15) — same subject, +54/-0 — 2.1.301 (51)
  - `94506ff` (2026-10-14) — +91/-0 — 2.1.300 (88)
  - `db93774` (2026-10-14) — +193/-0 — 2.1.299 (190)
  - `2301018` (2026-10-09) — +82/-0 — 2.1.296 (79)
  - `602df92` (2026-10-08) — +146/-0 — 2.1.295 (143)
  - `71cddde` (2026-10-08) — +5/-0 — 2.1.294 (2)
  - `79babc3` (2026-10-07) — +59/-0 — 2.1.293 (56)
  - Strategy: one on-disk two-ref diff, a single hunk `@@ -1,5 +1,701 @@` with 0 removed lines, so a strict prepend; its 696-line, 100,873-byte region read in two slices. 672 bullets in 10 days (~67/day; 2.1.299 alone 190). File 945,458 → 1,046,331 bytes. This session runs CLI 2.1.301 (VS Code extension).

## Drift / gap candidates (existing artifacts)

- **claude/rules/coding-bash.md** — `onFailure: "block"` for command and HTTP hooks _(claude-code)_
  - Specific change: 2.1.295 lets a hook opt into failing closed: can't start, exit code other than 0 or 2, timeout, or invalid output then does what exit 2 does on that event; no effect on Stop/SubagentStop or `async` hooks. 2.1.299 adds that on Windows a PreToolUse/PermissionRequest hook with no shell now blocks when Git for Windows is absent. § "Claude Code hooks" says a crash "fails **open**" with no opt-out.
  - Reference: https://code.claude.com/docs/en/hooks#block-the-action-when-a-hook-fails
  - Proposed action: minor edit
- **claude/settings.json** — `onFailure` on `identity-guard` and `security-reviewer-memory-scope` _(claude-code)_
  - Specific change: both PreToolUse guards fail open today by design (hooks README:43); `"onFailure": "block"` is now one key away. The bash.exe degradation in `claude/CLAUDE.md` (forks killed at 120 s) is what would turn a block into a wedged session.
  - Reference: as above
  - Proposed action: flag — a decision, then record it either way
- **claude/hooks/README.md** — "Fails open by design" paragraph _(claude-code)_
  - Specific change: the design reason still holds, but the sentence now needs to say the opt-in exists and why it is off (or on).
  - Reference: as above
  - Proposed action: minor edit, after the decision above
- **.claude/skills/drift-audit/references/sources/claude-code.md** — Size and slice bullets _(claude-code)_
  - Specific change: "~1.2 MB" for two full files is stale: 1,991,789 bytes this run (owed by brief 01). The slice rule's reason, "to pass the Read tool's 25,000-token cap", has a second route since 2.1.296: Read's `allow_large` (present in this session's tool schema). A fourth volume sample: 8 commits, 8 version sections, 672 bullets in 10 days.
  - Reference: changelog 2.1.296 (`allow_large`); measured here
  - Proposed action: minor edit
- **claude/hooks/offer-handoff.sh** — header names two compaction triggers _(claude-code)_
  - Specific change: 2.1.299 adds idle compaction in the terminal: a 200K+ token conversation idle ~54 minutes is compacted before its one-hour cache expires. The hook fires on `SessionStart` matcher `compact` after it too, with its stdout waiting for the next prompt; the header says "auto or manual".
  - Reference: changelog 2.1.299 and 2.1.302 — `code.claude.com/docs/en/settings` has no `idleCompaction` entry (page fetched whole, 56.6 KB, 2026-10-16)
  - Proposed action: minor edit
- **skills/workflow/find-session/scripts/find-session.py** — transcripts now carry `api-request` records _(claude-code)_
  - Specific change: 2.1.300 records each API request's system prompt, tools and parameters in the local transcript; `{"type":"api-request"` lines with `systemPrompt` are in this session's transcript on 2.1.301. The script skips unknown `type`s, so results stay right, but it `json.loads` every line of every transcript on the machine and each request now adds a full system prompt.
  - Reference: changelog 2.1.300 only
  - Proposed action: flag — measure a transcript's growth; add a cheap line-prefix skip if it matters
- **skills/meta/scope-instructions/scripts/folder-sessions.py** — the same records _(claude-code)_
  - Specific change: as above; it also counts `compact_boundary` and `user` records only, so its measures are unaffected, its cost is not.
  - Reference: changelog 2.1.300 only
  - Proposed action: flag

## New-skill candidates

_(none — by this source's design)_

## MCP / tooling / CLI additions

- **`idleCompaction` settings key, `CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS`, `/config` "Idle compaction" row** — new, default on; `"idleCompaction": false` turns it off (2.1.299, 2.1.302)
  - Reference: changelog only — the settings docs page has no entry (fetched 2026-10-16)
  - Proposed action: flag — a decision for `claude/settings.json`; the payload sets nothing today

## No-op

- ~640 of 672 bullets filtered out: TUI, Claude Tag, Cloud sessions, Code Review, VS Code panel, mods API, gateway, self-hosted runner.
- 2.1.293 single-file Bash `cat`/`head`/`sed -n`/`grep` loads rules and nested CLAUDE.md — already landed 2026-10-15 in `activation-testing.md`, `editing-rules.md`, `claude/rules/README.md`, `agent-instructions-scoping.md`, `test-activation.ps1`; root CLAUDE.md:188 still holds for skills.
- 2.1.295 a `cat` that printed nothing no longer counts as a read — consistent with the above.
- 2.1.299 `mcp__a` allow rules reach only that server; `.claude/settings.json` names full tool ids, and `security-reviewer` lists no MCP server.
- 2.1.299 `UserPromptSubmit` runs before skill expansion — `name-session.sh` already matches the raw `/skill arg` form.
- 2.1.301 artifact updates no longer refused under an `Edit|Write` PreToolUse hook — the payload's shape; fixed upstream.
- 2.1.295 `--tools` now also excludes late-registering built-ins — strengthens the probe rule in `claude/CLAUDE.md`.
- 2.1.299 worktree guard now refuses some awk programs — root CLAUDE.md's list is illustrative.
- 2.1.299 `claude -p` names an invalid settings file on stderr.
- 2.1.299 MCP OAuth flows now send `headers`/`headersHelper` — `claude/mcp/README.md`'s 2x2 unchanged (a helper emitting nothing has nothing to send).
- 2.1.296 `autoCompactWindow` subagent frontmatter — unused; no lint allowlists agent fields.
- 2.1.296 `--debug` logs each command hook's command, outcome and duration.
- 2.1.299/2.1.296 Read, Write and Edit refuse non-UTF-8 files instead of converting; Write keeps a BOM — `coding-powershell.md` unaffected.
- 2.1.299 WebFetch effort follows the caller's level — § 4b's model premise stands; the preapproved-host raw read held this run.
- 2.1.301 Grep and Glob error on a failed search program — § 1's empty-result guard still covers the slash-pattern trap.
- 2.1.302 `claude -p` with no mode starts in `default` on third-party providers or with telemetry off — probes here stay `auto`.
- 2.1.293 `--model haiku` now resolves to Haiku 5.5 (1M context, $0.10/$0.50 per Mtok).
- 2.1.300 the harness now asks for full scratchpad paths itself; `claude/CLAUDE.md`'s 8.3 expansion still adds.
- New keys the payload doesn't use: `CLAUDE_CODE_AUTO_MODE_MODEL`, `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL`, `advisorModel`/`--advisor` (AWS only), `deniedMcpServers` on the runner.
- 2.1.300 exit resume command names the session by ID — as `find-session` does.
- 2.1.299 skill names with hidden or `<`/`>` characters no longer offered — none here.
- 2.1.293 claude.ai skill sync every 40 minutes; `synced/` untouched by the prune.
- 2.1.300 `--worktree` fixes (tag named like a commit, reftable, bare-repo base); 2.1.299 `enabledMcpjsonServers` single-string fix — array here.

## Owed re-checks

- **`2026-10-06/claude-code/01-repair-claude-code-registry-entry.md`** — owed to the next `claude-code` drift audit, by its `**Needs**:` line at `:133`
  - Owes: reading the corrected entry as the behavioural check; the Size bullet's "~1.2 MB".
  - Outcome: passed on the read — the entry drove the run (filter, slices, the removed-lines check, which found 0); failed on "~1.2 MB" — two full files are 1,991,789 bytes, carried by the registry-entry bullet above.
  - Leaves open: nothing
- **`2026-10-06/claude-code/11-re-probe-drift-audit-tool-premises.md`** — owed to any drift audit, by its `**Needs**:` line at `:135`
  - Owes: that § 1's slash-free `Glob` lists the registry; on a WebFetch-path run only, that § 4b's completeness check catches the note and the tells.
  - Outcome: passed — `Glob` pattern `*.md` with `path` the sources directory listed all six files on 2.1.301; not in this window — the § 4b half, since this run took the clone path.
  - Leaves open: the § 4b check, until a run falls back to WebFetch

## Recommended actions

1. `claude/rules/coding-bash.md` § Claude Code hooks — minor edit: `onFailure: "block"` (2.1.295) and the Windows no-shell block (2.1.299) beside "fails open".
2. `claude/settings.json` — decide `onFailure` for `identity-guard` and `security-reviewer-memory-scope`; record the decision.
3. `claude/hooks/README.md` — minor edit to the fail-open paragraph per 2.
4. `.claude/skills/drift-audit/references/sources/claude-code.md` — minor edit: measured two-file size, `allow_large` beside the slice rule, the fourth volume sample.
5. `claude/hooks/offer-handoff.sh` — minor edit: idle compaction as a third trigger.
6. `claude/settings.json` — decide `idleCompaction`; flag only.
7. `skills/workflow/find-session/scripts/find-session.py` — flag: measure `api-request` growth, skip cheaply if warranted.
8. `skills/meta/scope-instructions/scripts/folder-sessions.py` — same flag.
9. Stamp both owed re-checks' logs: 01 closed by 4; 11's Glob half passed, § 4b half still waiting on a WebFetch-path run.

## Next run

Pass one of these as the prior reference next time:

- Claude Code releases (`claude-code`) head: `c017428c8c27e604840435048d5bce6a9a22c040` (2026-10-16T20:52:45Z)
- Or a single date: `2026-10-16` — a date floor re-includes today's landing; the SHA does not.

A SHA from any registered source's repo, or any ISO date, is accepted.
