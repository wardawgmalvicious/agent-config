# Handoff: decide what the vscode-agent source audits, then repair its entry

- **Audit run**: 2026-10-16
- **Source**: `vscode-agent`
- **Window**: floor `c642b585` (2026-10-01, the 2026-10-06 run's head) →
  head `e6026c88` (2026-10-16)
- **Covers recommended actions**: 4
- **Kind**: a **decision** on one registry entry of the project-scope
  `drift-audit` skill, then a partial rewrite of that entry to match. It
  changes what the next `vscode-agent` audit fetches and where it maps
  findings, and is verified by a re-run. The decision is the user's:
  `/drift-update` puts it back to the user rather than executing it.
- **Target**: `.claude/skills/drift-audit/references/sources/vscode-agent.md`;
  the skill's `description` in `.claude/skills/drift-audit/SKILL.md`;
  the log of
  `docs/audits/2026-10-06/vscode-agent/04-decide-vscode-agent-source-scope.md`

## The problem

The `vscode-agent` entry's premise ended on 2026-10-13. Its file says
the source "Governs how this repo's `~/.claude` payload reaches GitHub
Copilot", and that payload was retired that day. Brief 04 of the
2026-10-06 run put the question this raises, keep the source re-scoped
or retire it, and the user chose that day to decide once the retirement
had landed. It has. This window adds evidence: the entry's fetch set
missed most of what the run needed, and the run still found stale claims
about VS Code in this repo's prose.

## Evidence

### The prior brief

`docs/audits/2026-10-06/vscode-agent/04-decide-vscode-agent-source-scope.md`
holds four defects in this entry, all deferred on 2026-10-06:

- D-1, the fetch set misses where the facts moved;
- D-2, `artifacts` names the wrong files;
- D-3, the cadence note is stale;
- D-4, the premise ends with the retirement: the open question.

Its log, `:133-136`: "Asked 2026-10-06 whether to keep the source,
re-scoped to which VS Code session targets read `~/.claude`, or retire
it; the user chose to decide after the retirement lands, as the
Sequencing note advises." Its counting line, `:142`:

> - **Needs**: user, after `copilot-payload-retirement.md` lands — the
>   D-4 call, keep `vscode-agent` re-scoped or retire it, and then its
>   registry edit as a task of its own, verified by this brief's steps.

This brief is that task of its own. It does not restate D-1 to D-3:
read them in brief 04.

### The retirement

The Copilot-format payload was removed on 2026-10-13 (`be70086`).
`README.md:209-212`: "Until 2026-10-13 a second payload, `copilot/` and
the script that copied it, vendored skill groups and hand-made
instruction ports into a repo's `.github` and into `~/.copilot` for the
Copilot target. The Claude target left it no reader, so it was removed".

### This window's four items

The report's drift bullet on the entry (`00-audit-report.md` in this
directory) names four:

1. **The premise**, `vscode-agent.md:18-20`: "Governs how this repo's
   `~/.claude` payload reaches GitHub Copilot, so its findings land on
   the repo's own deployment docs rather than on skills and rules."
   Stale since 2026-10-13: D-4's symptom, now true.
2. **`files`** omits the two pages this window changed most:
   - `docs/agent-customization/migrate-customizations.md`, new in
     `2264a3af4` (2026-10-08, +221). It holds the migration guidance
     that left `overview.md` (-96 in the same landing), and
     `agent-skills.md`, `custom-agents.md` and `custom-instructions.md`
     now send each deprecated `chat.*Locations` setting's reader there.
   - `docs/agent-customization/mcp-servers.md`, rewritten twice:
     `108c8cb60` (2026-10-14, +129/-53) and `e6026c880` (2026-10-16,
     +105/-311).
3. **`path`** excludes `docs/agents/reference/`, where three facts the
   run needed now live (sizes at `e6026c88`):
   - `ai-settings.md` (64,646 bytes): the removal notice brief 02
     corrects.
   - `mcp-configuration.md` (24,302 bytes): the `.mcp.json` reading
     rules that `claude/rules/claude-config-scoping.md:30` and `:33`
     rest on, and the new `chat.mcp.workspaceRootConfig.enabled`
     (`:414`).
   - `custom-agent-file-reference.md` (10,820 bytes): new in `baa88c2fb`
     (2026-10-16), where `custom-agents.md`'s header-field and
     Claude-format tables moved (`custom-agents.md` +72/-220 in that
     landing).

   D-1 found `hooks-reference.md` (13,699 bytes) in the same directory
   on 2026-10-06.
4. **No `drill.strip`**, which the registry schema lists
   (`references/sources.md` § "Entry schema"). Every other entry sets
   one, `none` with its reason where nothing needs stripping:
   `claude-code.md:20`, "none — anchors here are stable heading slugs,
   so keep them"; `fabric-iq-ontology.md:31`, "every `#…` fragment",
   because "This doc set's heading anchors move". In this window two
   anchors on the fetched pages were renamed, the old ones kept as HTML
   anchors: `hooks.md#agent-scoped-hooks-for-local` and
   `custom-instructions.md#sync-local-agent-instructions-across-devices`.

### What else the run showed

- It took three targeted reads outside the entry to reach its findings:
  `mcp-servers.md`'s diff and its "Choose a configuration destination"
  section, `ai-settings.md`'s four rows at both refs, and
  `mcp-configuration.md`'s `.mcp.json` lines at both refs.
- Its findings landed on `README.md`, which `artifacts` lists, and on
  `claude/rules/vscode-scoping.md`, which it does not: `artifacts` lists
  `.claude/rules/`, this repo's project-scope rules, not
  `claude/rules/`, the user-scope payload. Brief 04's D-2 found the same
  of the 2026-10-06 run.
- One claim in the entry held: `vscode-agent.md:37-40`. `agent-skills.md`
  at head still lists six SKILL.md frontmatter fields, `name`,
  `description`, `argument-hint`, `user-invocable`,
  `disable-model-invocation` and `context`, and `model` is not among
  them.
- Two VS Code releases fell in the window, for D-3: 1.141 (`4fe6b0340`,
  2026-10-06) and 1.142 (`f7ee5a5c6`, 2026-10-14).

## The decision

Put to the user, as brief 04's D-4 framed it:

- **A — keep the source**, re-scoped to which VS Code session targets
  read `~/.claude`. Within A, one sub-choice the report names: cover
  `docs/agents/reference/` by widening `path` or by a second source.
  Brief 04's D-1 names a third, leaving those pages as Phase 3 drill
  targets.
- **B — retire it** with the payload it was written for.

## What to change

**On A**, one partial rewrite of `vscode-agent.md`:

1. The premise, `:18-20`, and the lines that lean on it, the
   `artifacts` rationale at `:65-78`: restate what the source is for
   after the retirement.
2. `files`: add `migrate-customizations.md` and `mcp-servers.md`, and
   `overview.md`, which brief 04's D-1 asked for.
3. `path`: reach the pages under `docs/agents/reference/`, at least
   `ai-settings.md`, `mcp-configuration.md`,
   `custom-agent-file-reference.md` and `hooks-reference.md`, by the
   sub-choice above.
4. `drill.strip`: add the field, a pattern or `none` with its reason, as
   the other entries do.
5. Brief 04's D-2 (`artifacts`) and D-3 (cadence), from that brief: they
   land in this file, and the same re-run verifies them.

Then the skill: its `description` says the registry holds "the VS Code
agent-customization docs behind the GitHub Copilot wiring"; restate it,
as brief 04's knock-on says. If `files` grows, re-derive `SKILL.md`
§ 4b's "`vscode-agent` 9 (4 files)" from its `1 + 2 x |files|` rule.

**On B**: delete `vscode-agent.md`, and remove the source from the
skill's `description` and from `SKILL.md` § 4b's pricing paragraph.
Then
`grep -n "vscode-agent" .claude/skills/drift-audit/SKILL.md .claude/skills/drift-audit/references/sources.md`
and take each hit: a dated worked example may stay as history; a
pointer to the entry's file, such as § 4b's "as the `vscode-agent`
entry records once", needs its evidence moved or the pointer
re-pointed.

**Either way**, once the edit lands, append to brief 04's log a
`**Closed**: <date> —` line naming this brief and the outcome. Then run
`uv run scripts/audit-status.py --dir docs/audits/2026-10-06/vscode-agent`,
which files brief 04 under `completed/`, and
`git grep -n 04-decide-vscode-agent-source-scope.md` to re-point any
live path. Brief 04's D-1 to D-3 are carried out here on A and moot on
B, so it waits on nothing else. This directory's `00-audit-report.md`
names brief 04 as it stood and is verbatim: leave it.

## Constraint on the fix

- The decision is the user's. Brief 04's log records the user deferring
  it once; neither that deferral nor this audit's recommendation to put
  it again is an answer.
- Price a wider fetch set before settling on it. On a clone the run
  reads a diff, but on the WebFetch fallback a directory `path` costs
  `1 + 2 x |files|` calls against GitHub's anonymous 60 an hour
  (`SKILL.md` § 4b), and the sizes above count against § 4a's ~150 KB
  budget wherever a page is read whole.
- Keep no list of the registered sources anywhere
  (`references/sources.md` § "Registered sources").

## Verification

1. **On A**: re-run
   `/drift-audit c642b585b02a55cbc28508a56c927d34262fded6 --sources vscode-agent`
   against the amended entry, with this directory's `00-audit-report.md`
   as the known answer. The run should reach
   `migrate-customizations.md`, `mcp-servers.md` and the
   `docs/agents/reference/` pages through the entry, not by targeted
   reads outside it, and its diff should still carry the hooks-page
   restructure, the removal sentence left on `chat.agentSkillsLocations`
   alone, and `chat.mcp.workspaceRootConfig.enabled`, each mapped to the
   files it bears on. **On B**: `/drift-audit --sources vscode-agent`
   stops on an unknown id and lists the valid ids without it.
2. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/skills/drift-audit/SKILL.md`,
   then `uv run --with pyyaml scripts/skill-status.py --stale`, which
   should list `drift-audit` for a retest, since its `description`
   changed.
3. `grep -n "Copilot wiring" .claude/skills/drift-audit/SKILL.md` — no
   output.
4. `grep -n '^- \*\*Closed\*\*:' docs/audits/2026-10-06/vscode-agent/completed/04-decide-vscode-agent-source-scope.md`
   — one line. Then `uv run scripts/audit-status.py --check`.
5. `pre-commit run --all-files`.

## Sequencing note

Independent of briefs 01 and 02, which correct prose this source
surfaced and stand whatever is decided here; run it after them if the
A re-run should find those claims settled. Keep it apart from them: this
changes what the audit fetches and is verified by a re-run, while they
change prose and are verified by a grep.

## Provenance

Recommended action 4 of the 2026-10-16 `/drift-audit vscode-agent` run,
whose drift bullet on the entry names the four items. The page sizes and
the landing that added `custom-agent-file-reference.md` were read from
the run's scratchpad clone while this brief was written, and the
`drill.strip` comparison from the other registry entries.
