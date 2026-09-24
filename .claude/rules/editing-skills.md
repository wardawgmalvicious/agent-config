---
paths:
  - "skills/**/SKILL.md"
  - ".claude/skills/**/SKILL.md"
---

# Editing a SKILL.md

Both trees: `skills/<group>/<name>/` is payload, `.claude/skills/<name>/` is
this repo's own. Long detail belongs in the skill's `references/`, as root
`CLAUDE.md` says.

## Name and listing budget

- Name a behavioural skill as the verb you invoke (`commit`, `learn`); give
  a platform skill a `fabric-`, `pbir-` or `pbid-` prefix. Names are one
  flat namespace across both trees (`pre-commit-hooks.md`).
- The listing truncates `description` + `when_to_use` at 1536 characters
  (`skillListingMaxDescChars`), silently. The budget is split per field:
  `description` ≤ 1024, the Agent Skills spec cap and one of the fields the
  claude.ai upload accepts, so that half stays portable; `when_to_use` ≤
  512, a Claude Code extension. `DESCRIPTION_MAX` and `WHEN_TO_USE_MAX` in
  `scripts/lint-frontmatter.py` gate each, so an edit to one cannot overflow
  the other and a failure names the field to cut; `LISTING_MAX` fires only
  if those two are edited apart (2026-09-01).
- Lint with `uv run --with pyyaml scripts/lint-frontmatter.py <SKILL.md>`;
  pre-commit runs it over both trees. PowerShell passes a wildcard through
  unexpanded, which fails, so expand it first:
  `$files = Get-ChildItem skills -Filter SKILL.md -Recurse | % FullName`.
- Skills hot-reload, through the junctions too: an added or removed skill
  and a `skillOverrides` change reach the next listing with no restart
  (2026-08-31, 2.1.251), and so does an in-place `description` edit
  (2026-09-02, 2.1.252). That proves the listing refreshes, not that a
  reworded trigger then fires.
- A `skills/workflow/` skill reaches Copilot only as a copy: after editing
  one, re-run
  `./scripts/copy-copilot.ps1 -CopilotDir ~/.copilot -SkillGroups workflow`.

## Invocation and spend fields

- Write `effort`, `disable-model-invocation` and `model:` into every
  `SKILL.md`, even at their defaults, so each lever's flip point is visible.
  `effort` has no `inherit` value: omitting it is the inherit, so carry it
  commented. An unsupported level falls back, silently, to the highest
  supported one below it.
- `model:` is active only where Copilot cannot reach the file:
  `.claude/skills/`, and a `skills/<group>/` carrying a `.no-copilot`
  marker; unpinned there, it reads `model: inherit`. Everywhere else under
  `skills/` it is commented, as `# model: inherit` (`commit` keeps
  `# model: sonnet`). An active `model:` of any value stops VS Code Copilot
  slash-dispatching the skill: nothing is sent, no session starts, and it
  reads as a hang (2026-09-09). `effort:`, `when_to_use:` and
  `disable-model-invocation:` are harmless there. `lint-frontmatter.py`
  enforces the split (`pre-commit-hooks.md` has how to prove it).
- Where `model:` is active the pin is live, since those skills are reached
  by typing their names. Pin `fable` only where judgment is irreducible —
  wording a `description`, not executing a numbered brief — because it costs
  twice the Opus tier (2026-09-12). List the pins with
  `grep -rn "^model:" .claude/skills skills`.
- Pin the alias, not the dated ID, which freezes on one release once the
  next ships. The CLI carries its own model table, so a stale CLI resolves
  an alias to an older release silently: compare `claude --version` with
  `winget list --id Anthropic.ClaudeCode` before trusting a model-routing
  reading (2026-09-12).
- `model:` lasts one turn, and only when the skill is slash-invoked: one
  reached by its description runs on the session model, the pin silently
  ignored (2026-09-01). It is inert on a conditional skill, which has no
  cold slash route, and live on an unconditional one. `effort` applies on
  both paths, at either scope.
- The session default is `"effortLevel": "max"` in `claude/settings.json`.
  `effort: max` sits on every behavioural skill but `commit` (`xhigh`); on
  platform skills it stays commented, because they auto-trigger beside real
  work and a pin would govern that turn. Derive the set with
  `grep -rln "^effort: max" skills/ .claude/skills/`, never a count. The
  session level is live state, not the file: it can drift mid-session with
  nothing warning, and only the transcript shows the real value. Below
  `max`, the pins raise effort, the floor they exist for (2026-09-01).
- `disable-model-invocation: true` drops the description from the listing in
  every session on the machine and blocks subagent preloading and scheduled
  firing. It is `false` everywhere here.
- `ultracode` is not an effort level (it reports as `xhigh`), so `max` is
  the highest pin.
