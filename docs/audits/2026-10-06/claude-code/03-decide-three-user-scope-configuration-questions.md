# Handoff: decide three user-scope configuration questions

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 3, 5 and 17
- **Kind**: decision on three configuration questions, then the edits
  each answer implies; D-4 alone is a documented edit that waits on none
  of them
- **Target**: `claude/settings.json`, `.claude/rules/editing-skills.md`,
  `.claude/rules/deploy-scripts.md`, `claude/CLAUDE.md`

## The problem

Three harness changes this window leave user-scope choices unmade. The
top-level `effortLevel` in `claude/settings.json` no longer governs
Opus 5.5, and the deployed file has already moved to per-model
settings. Claude Code now syncs the claude.ai account's skills and
plugins into every terminal session unless told not to. And two new
knobs, `bashOutputMaxChars` and a narrower `claude --bare`, could serve
this payload or its probe recipe. Each is the user's call. One related
fact is not a choice: `~/.claude/skills` now holds entries the harness
owns, and `.claude/rules/deploy-scripts.md` does not say so.

## D-1 — `effortLevel: "max"` no longer governs the default model

**Symptom.** `claude/settings.json` carries `"effortLevel": "max"`. The
deployed `~/.claude/settings.json`, read 2026-10-06, has no top-level
`effortLevel` and carries instead:

```json
"model": "opus",
"modelSettings": {
  "claude-opus-5": {},
  "claude-opus-5-5": {
    "effortLevel": "xhigh"
  }
}
```

Whether `/effort` wrote that or the harness dropped the `max` is not
known. `.claude/rules/editing-skills.md` § "Invocation and spend fields"
still says:

> The session default is `"effortLevel": "max"` in
> `claude/settings.json`.

> `ultracode` is not an effort level (it reports as `xhigh`), so `max`
> is the highest pin.

**Cause.**

- `CHANGELOG.md` 2.1.280:
  > Changed an effort level saved before `/effort` became per-model to
  > no longer apply to newly released models such as Opus 5.5; they
  > start at their default until you pick a level
- https://code.claude.com/docs/en/model-config, read 2026-10-06:
  > Opus 5.5 starts at `medium` unless one of the sources above sets a
  > level for it, and a top-level `effortLevel` in your user settings
  > file doesn't count for Opus 5.5. That key is the older form
  > `/effort` wrote before Claude Code saved levels per model: it keeps
  > applying where it applied before, on Opus 5, Fable 5.1, and earlier
  > models, while Opus 5.5 and models released after it start at their
  > own default until you choose a level for them with `/effort` or the
  > `/model` picker.
- https://code.claude.com/docs/en/settings-reference, read 2026-10-06:
  `effortLevel` takes `low`, `medium`, `high` or `xhigh`, not `max`;
  `modelSettings` (2.1.251+) maps a model to `effortLevel`,
  `maxEffortLevel` and `autoCompactWindow` (2.1.288+); a
  `maxEffortLevel` (2.1.267+) of `"max"` sets no cap. Skill and subagent
  `effort:` frontmatter still takes `max`.
- `CHANGELOG.md` 2.1.284:
  > Changed Ultracode into its own toggle in `/effort` (Tab, or
  > `/effort ultracode [on|off]`): it no longer forces xhigh effort and
  > stays on at any effort level
- `CHANGELOG.md` 2.1.267:
  > Fixed `effort:` frontmatter on custom commands, skills, and
  > subagents being ignored on models whose default effort is still
  > pinned (Opus 4.7, Opus 4.8, Fable 5)

**Fix.** After the answer, set `claude/settings.json` to it, then
rewrite the two bullets quoted above to match the answer and the docs.
Check the same section's "Below `max`, the pins raise effort, the floor
they exist for (2026-09-01)" against the 2.1.267 fix, which came after
that measurement.
**Open question.** Which effort configuration should the payload carry?
a) `modelSettings` per model, at the levels the user picks (the deployed
file holds `claude-opus-5-5: xhigh` today), with the top-level key
dropped; b) the same, keeping the top-level key for Opus 5, Fable 5.1
and earlier; c) no change, accepting the drift from the deployed file.
**Knock-on.** `claude/settings.json` deploys as a key-level merge
(`.claude/rules/deploy-scripts.md`): a `-Force` run today would put
`effortLevel` back beside the target-only `modelSettings`, and would
replace `modelSettings` whole if the repo file carried it. Brief 04
rewrites another bullet of the same section.

## D-2 — the claude.ai account's skills and plugins sync in

**Symptom.** `~/.claude/skills/synced/` sat beside the payload's
junctions on 2026-10-06, and every session's listing carries the
account's skills as `anthropic-skills:<name>`: `docs`, `docx`, `pdf`,
`pptx`, `xlsx`, `deep-research` and others. `claude/settings.json` sets
neither sync key; its `enabledPlugins` already turns one synced plugin
off by hand, `cowork-plugin-management@synced`.
**Cause.**

- `CHANGELOG.md` 2.1.275:
  > Added syncing of the skills and plugins enabled on your claude.ai
  > account to terminal sessions signed in with it; opt out with
  > `syncClaudeAiSkills: false` or `syncClaudeAiPlugins: false`
- https://code.claude.com/docs/en/skills, read 2026-10-06:
  > To stop syncing on a machine, set `syncClaudeAiSkills` to `false` in
  > your user settings. Claude Code stops downloading, and the next time
  > it starts it moves the skills it already synced to
  > `~/.claude/skills/.trash/` and no longer loads them.
- https://code.claude.com/docs/en/settings, read 2026-10-06: a `false`
  for either key is honoured from managed settings, `--settings`,
  `~/.claude/settings.json` or `.claude/settings.local.json`, and "a
  `false` in `.claude/settings.json` is ignored".

**Fix.** After the answer, set or leave the keys in
`claude/settings.json`.
**Open question.** a) keep both on; b) skills off; c) plugins off;
d) both off. The cost is listing budget in every session
(`.claude/rules/editing-skills.md` § "Name and listing budget"); the
gain is the account's skills, `docs` and the office formats among them,
in terminal sessions.

## D-3 — two new knobs: `bashOutputMaxChars` and `claude --bare`

**Symptom.** Neither is used here.
**Cause.**

- `CHANGELOG.md` 2.1.261 added `bashOutputMaxChars`, which raises how
  much command output Claude receives inline before it is saved to a
  file, up to 128K characters; the settings reference lists it as a
  number, unset by default, at any scope.
- `CHANGELOG.md` 2.1.286:
  > Changed `--bare` to connect only the MCP servers named on the
  > command line, send the model no system reminders, and start no
  > background tasks; under `--bare`, a shell command that reaches its
  > timeout now stops instead of moving to the background

  `claude/CLAUDE.md` § "Agent config source" gives the cold-probe recipe
  as
  `claude -p '<question>' -n 'probe: <topic>' --model haiku --tools Read,Glob,Grep --strict-mcp-config`.

**Fix.** After the answers.
**Open question.** First: a) set `bashOutputMaxChars`, and to what, or
b) leave it unset. Second: a) add `--bare` to the probe recipe, or
b) leave the recipe. Before choosing the second (a): whether "no system
reminders" also withholds `CLAUDE.md`, which a probe run "from the
target repo" exists to read, is unmeasured.

## D-4 — `deploy-scripts.md` does not name the harness-owned entries

**Symptom.** `.claude/rules/deploy-scripts.md` says:
> Claude Code finds a skill one level deep,
> `<skills-root>/<name>/SKILL.md`, so `~/.claude/skills` is a real
> directory of per-skill junctions, not one junction for `skills/`.

On 2026-10-06 the directory also held `synced/`, which Claude Code
writes, and the docs name a `.trash/` beside it.
**Cause.** The sync in D-2. `CHANGELOG.md` 2.1.271 moves synced copies
not refreshed within `cleanupPeriodDays` to the trash, and 2.1.280 fixed
"skills in `~/.claude/skills/` being moved to `~/.claude/skills/.trash/`
when a `manifest.json` in that folder listed their names".
**Fix.** Say that `synced/` and `.trash/` belong to Claude Code, not the
payload, and that the linker's prune leaves them alone: its loop skips
every entry that is not a reparse point (`scripts/link-claude.ps1`,
lines 655–656 on 2026-10-06). It holds whatever D-2 decides.

## Verification

1. `git diff claude/settings.json` shows the answers to D-1 to D-3 and
   nothing else.
2. `grep -n '"effortLevel": "max"' .claude/rules/editing-skills.md` — no
   hit, unless the D-1 answer keeps it.
3. `grep -n "synced" .claude/rules/deploy-scripts.md` — a hit.
4. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/rules/editing-skills.md .claude/rules/deploy-scripts.md`
5. `uv run scripts/lint-claude-md.py`, if `claude/CLAUDE.md` changed.
6. `pre-commit run --all-files`.
7. From the main checkout,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`;
   then each answered key in `~/.claude/settings.json` holds its answer
   and the target-only keys (`theme`, `tui`, and `modelSettings` unless
   D-1 moved it into the repo file) survive; then
   `ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid|msix)-'` prints
   nothing.

## Provenance

The changes are from the 2026-10-06 `claude-code` run's changelog diff
and the docs pages read that day. The deployed settings file and
`~/.claude/skills` were read by the audit session, which wrote neither.
