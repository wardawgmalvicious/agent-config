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
  a platform skill its group's prefix: `PLATFORM_PREFIXES` in
  `scripts/lint-skill-overrides.py` is the list. Names are one flat
  namespace across both trees
  (`pre-commit-hooks.md`). The harness reserves `anthropic-skills`, and
  every `anthropic-skills:<name>`, for skills synced from claude.ai, so no
  skill here takes that name (2026-10-06).
- The listing truncates `description` + `when_to_use` at 1536 characters
  (`skillListingMaxDescChars`), silently. The budget is split per field:
  `description` ≤ 1024, the Agent Skills spec cap and one of the fields the
  claude.ai upload accepts, so that half stays portable; `when_to_use` ≤
  512, a Claude Code extension. `DESCRIPTION_MAX` and `WHEN_TO_USE_MAX` in
  `scripts/lint-frontmatter.py` gate each, so an edit to one cannot overflow
  the other and a failure names the field to cut; `LISTING_MAX` fires only
  if those two are edited apart (2026-09-01).
- **Listing text routes; it cannot license.** A `when_to_use` granting what
  the harness withholds reads as the skill's claim, not the user's word:
  `commit`'s "use it unasked, on the user's standing word" fired in 0 of 3
  Opus 5.5 arms against the harness's commit-only-when-asked, one of them
  searching memory for that word (2026-10-14, 2.1.293). A standing
  permission goes in `claude/CLAUDE.md`; the skill keeps the procedure.
- Lint with `uv run --with pyyaml scripts/lint-frontmatter.py <SKILL.md>`;
  pre-commit runs it over both trees. PowerShell passes a wildcard through
  unexpanded, which fails, so expand it first:
  `$files = Get-ChildItem skills -Filter SKILL.md -Recurse | % FullName`.
- Skills hot-reload, through the junctions too: an added or removed skill
  and a `skillOverrides` change reach the next listing with no restart
  (2026-08-31, 2.1.251), and so does an in-place `description` edit
  (2026-09-02, 2.1.252). That proves the listing refreshes, not that a
  reworded trigger then fires.

## Invocation and spend fields

- Write `effort`, `disable-model-invocation` and `model:` into every
  `SKILL.md`, even at their defaults, so each lever's flip point is visible.
  `effort` has no `inherit` value: omitting it is the inherit, so carry it
  commented. An unsupported level falls back, silently, to the highest
  supported one below it.
- `model:` is active only in `.claude/skills/`, where a pin is kept on
  purpose; unpinned there, it reads `model: inherit`. Everywhere under
  `skills/` it is commented, as `# model: inherit` (`commit` keeps
  `# model: sonnet`, `learn` `# model: fable`), since **a pinned skill
  hangs on VS Code's Claude session target**, which reads
  `~/.claude/skills`. On Opus 5.5 through Copilot, `/learn test` sent with
  `model: fable` hung and left no transcript while `/commit` and
  `/prune-branches` loaded, and `learn` loaded once unpinned, though the
  target listed Fable 5.1 among its models (2026-10-13). Nothing errors:
  the failure is the silence. `lint-frontmatter.py` enforces the split
  (`pre-commit-hooks.md` has how to prove it).
- Where `model:` is active the pin is live, since those skills are reached
  by typing their names. Pin `fable` only where judgment is irreducible —
  wording a `description`, not executing a numbered brief — because it costs
  2.5 times Opus 5.5 per input and output token, 1.25 times per cache hit
  (pricing page, 2026-10-08). List the pins with
  `grep -rn "^model:" .claude/skills skills`.
- Pin the alias, not the dated ID, which freezes on one release once the
  next ships. The CLI carries its own model table, so a stale CLI resolves
  an alias to an older release silently (2026-09-12): compare
  `claude --version` with the `latest` release channel,
  `irm https://downloads.claude.ai/claude-code-releases/latest` in pwsh,
  before trusting a model-routing reading (2026-10-09).
- `model:` lasts one turn, and only when the skill is slash-invoked: one
  reached by its description runs on the session model, while the session
  is told it runs on the pin, so only `message.model` in the transcript
  shows which ran. In auto mode, where sessions here start, a pin to a
  model auto mode does not support, Haiku 4.5 among them, is dropped even
  when slash-invoked, while `haiku`, now Haiku 5.5, runs on its pin
  (2026-10-13, 2.1.293). It is inert on a conditional
  skill, which has no cold slash route, and live on an unconditional
  one. `effort` applies on both paths, at either scope.
- The session default is saved per model, under `modelSettings` in
  `claude/settings.json`: `claude-opus-5-5` at `xhigh`. Opus 5.5 and later
  take that entry from user settings, never a top-level `effortLevel`, and
  start at their own default, `medium` for Opus 5.5, until a level
  is saved (2.1.280); `/effort` saves to the deployed copy, which the next
  `-Force` replaces whole (`deploy-scripts.md`). A setting holds at most
  `xhigh`, never `max` (settings reference, 2026-10-07).
  `effort: max` sits on every behavioural skill but `commit` and the
  `fable` pins, at `xhigh`: the migration guide gives Fable 5.1 `xhigh` for
  "the most capability-sensitive workloads", and nothing measured shows
  `max` beating it (2026-10-08). On platform skills `effort` stays
  commented, because they auto-trigger beside real work and a pin would
  govern that turn. Derive the set with
  `grep -rln "^effort: max" skills/ .claude/skills/`, never a count. The
  session level is live state, not the file: it can drift mid-session with
  nothing warning, and only the transcript shows the real value. Below
  `max`, the pins raise effort while their skill is active, the floor they
  exist for (2026-09-01), and no setting reaches `max`.
- `disable-model-invocation: true` drops the description from the listing in
  every session on the machine and blocks subagent preloading and scheduled
  firing. It is `false` everywhere here but `run-briefs`, which spends
  usage and lands branches, so it runs only when typed (2026-10-12).
- `ultracode` is not an effort level but a toggle in `/effort` that leaves
  the level unchanged (2.1.284), so `max` is the highest pin.
- `allowed-tools` pre-approves a call for the invoking turn by matching
  the command text as the model spells it: the permissions page says a
  Bash rule matches "the whole command text", and its `~/` anchor is for
  path rules only. `find-session`'s rule names
  `~/.claude/skills/find-session/scripts/find-session.py`; under
  `dontAsk` an Opus arm that kept the `~` ran, and a Haiku arm that wrote
  the expanded, quoted path was refused (2026-10-06, 2.1.291). So the
  body spells the command as the rule does, and a model that expands `~`
  loses the grant.

## Bundled scripts

- A script goes in its skill's `scripts/` when a deployed skill runs it
  outside this repo; one serving this repo's upkeep stays in `scripts/`.
  Either way its negative cases are `tests/scripts/<script>/`.
- `SKILL.md` names it `${CLAUDE_SKILL_DIR}/scripts/<file>`, which Claude
  Code also substitutes in an `allowed-tools` Bash rule. Through a
  junction it expands to the junction's path, not its target, with
  forward slashes (2.1.293, 2026-10-12), so it suits either shell. A
  `references/` file is Read unsubstituted, so it spells
  `~/.claude/skills/<name>/scripts/<file>`. Older skills spell that in
  `SKILL.md` too, which works; `find-session`'s `allowed-tools` rule
  moves only with a `dontAsk` re-run of the arms above.
- A bundled script takes the repo it acts on from an argument or the
  working directory, never its own folder: through the junction, git run
  there finds this checkout, and paths built on `$PSScriptRoot` land in
  the skill folder, exit 0 (2026-10-12). `coding-bash.md`'s
  `SCRIPT_DIR/../..` is for a script that lives in the repo it serves.

## A skill a peer is testing

A tester edits no file, yet holds its skill: `/test-skill`'s stamp
hashes the skill as it is on disk when written, so an edit landing
mid-run is recorded as tested, with nothing to say so. Before editing a
skill, ask a `ListAgents` row that names it, as `test-skill: <name>`
rows did, and hold the edit until it says the stamp is written. Its idle
notice is not that: its turns end while probe arms run (2026-10-13).
