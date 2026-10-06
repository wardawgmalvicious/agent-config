# Handoff: decide what the vscode-agent source audits after the retirement

- **Audit run**: 2026-10-06
- **Source**: `vscode-agent`
- **Window**: floor `2026-09-01` (diff base `28f76f5f`, 2026-08-28) →
  head `c642b585` (2026-10-01)
- **Covers recommended actions**: 4
- **Kind**: a **decision** on one registry entry of the project-scope
  `drift-audit` skill, then an edit to match. It changes what the next
  `vscode-agent` audit fetches and where it maps findings, and is
  verified by a re-run. The decision is the user's: `/drift-update`
  puts it back to the user rather than executing it.
- **Target**: `.claude/skills/drift-audit/references/sources.md`,
  § "`vscode-agent` — VS Code agent customization surface"; possibly
  `.claude/skills/drift-audit/SKILL.md` (its `description` and § 1)

## The problem

The `vscode-agent` entry was written for a payload that reached GitHub
Copilot. That payload is being retired
(`docs/handoffs/execute/copilot-payload-retirement.md`). In September
2026 the docs the entry watches also moved part of what it needs to
pages it does not fetch. The 2026-10-06 run needed three pages outside
`files`, and every one of its findings landed outside `artifacts`.

## D-1 — the fetch set misses where the facts moved

**Symptom.** The entry fetches `custom-instructions.md`,
`agent-skills.md`, `custom-agents.md` and `hooks.md` under
`path: docs/agent-customization/`. The run also needed:

| Page | Holds | In `path`? |
| --- | --- | --- |
| `docs/agents/reference/hooks-reference.md` | the Local hook schema, moved out of `hooks.md` in `91b05da` (2026-09-21) | no |
| `docs/agents/run/agent-harnesses.md`, `docs/agents/concepts/agent-harnesses.md` | which target runs which harness; the Claude target's settings (`github.copilot.chat.claudeAgent.enabled`, BYOK, permission modes) | no |
| `docs/agent-customization/overview.md`, § "Migrate customizations" | where every Local-only deprecation note links | yes, not in `files` |

**Cause.** An upstream reorganization. `hooks.md` now covers the
harness choice and the Local configuration only.

**Fix.** Add `overview.md` to `files`. For the pages outside `path`
there is a real choice, because `path` is one directory per entry:
a second entry; a parent `path` such as `docs/`, which every release
squash touches, so the commit count stops meaning anything; or leaving
them as Phase 3 drill targets.

**Knock-on.** `SKILL.md` § 4b prices `vscode-agent` at 9 WebFetch
calls for 4 files. Re-derive that figure if `files` grows.

## D-2 — `artifacts` names the wrong files

**Symptom.** `artifacts` is `README.md`, root `CLAUDE.md`,
`.claude/rules/`, `scripts/README.md` and `scripts/link-claude.ps1`.
The run touched neither `scripts/` file. Its findings landed on
`claude/CLAUDE.md`, `claude/rules/vscode-scoping.md` and
`claude/rules/agent-instructions-scoping.md`, which the list omits.

**Fix.** List where findings land once the retirement is done.

## D-3 — the cadence note is stale

**Symptom.** The entry says "VS Code ships monthly — faster than the
Fabric cadence". The docs took five releases between 2026-09-02 and
2026-09-29: 1.136 (`56b8f49`, 2026-09-02), 1.137 (`dc7c2ba`,
2026-09-08), 1.138 (`3893104`, 2026-09-15), 1.139 (`4f4413d`,
2026-09-23) and 1.140 (`8889b05`, 2026-09-29).

**Fix.** State the cadence as measured, with its date.

## D-4 — the premise ends with the retirement

**Symptom.** The entry "Governs how this repo's `~/.claude` payload
reaches GitHub Copilot". After the retirement nothing ships to
Copilot. What stays measurable is which VS Code session targets read
`~/.claude`.

**Open question.** The user's: keep the source, re-scoped to that
question, or retire it with the payload. Facts that bear on it:

- The Claude target runs Claude Code's own engine: the Claude Agent SDK
  with `settingSources` user, project and local
  (`copilot-payload-retirement.md` § "What the build does"). The
  `claude-code` source already audits that engine.
- The docs say the Local agent "will be removed in a future release"
  (`overview.md` § "Migrate prompt files to skills"), and
  `vscode-scoping.md` and machine-config's switches govern it alone.
- Without this source, a VS Code-side change, such as a new default
  target or a new switch like `chat.useClaudeHooks`, arrives only by
  measurement.

**Knock-on.** The skill's `description` names "the VS Code
agent-customization docs behind the GitHub Copilot wiring" and
"checking whether VS Code moved the chat.*Locations settings", and
`SKILL.md` § 1 lists the registered ids. Either outcome changes them
(the registry's § "Adding a source", step 6).

## Verification

1. Re-run `/drift-audit --sources vscode-agent --since 2026-09-01`
   against the amended entry. `00-audit-report.md` in this directory is
   the known answer. A re-scoped entry still surfaces
   `chat.useClaudeHooks` (`91b05da`) and the Local agent's
   profile-storage row (`4f4413d`), and maps them to the files they
   landed on. A retired entry is verified by the same command stopping
   on an unknown id.
2. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`.
   If the `description` changed, also run
   `uv run --with pyyaml scripts/skill-status.py --stale`.
3. `pre-commit run --all-files`

## Sequencing note

Wait for the retirement to land: the answer depends on what it leaves.
Keep this apart from brief 05, which feeds a decision about how every
source is fetched. This brief decides what one source is for.

## Provenance

Surfaced by the 2026-10-06 `vscode-agent` run while it mapped its
findings: every one landed outside `artifacts`, and three of the pages
it needed sat outside `files`.
