# agent-config: repo instructions

The source of the user's coding-agent configuration, written for and
validated against Claude Code; other tools may cherry-pick it, untested.
[README.md](README.md) has the full picture. Evidence for each rule here or
in `.claude/rules/` is in
[docs/evidence/root-claude-md.md](docs/evidence/root-claude-md.md), under
its heading: read it before changing a rule, not before following one.

Root `CLAUDE.md` is project scope, never deployed, and no mirror of
[claude/CLAUDE.md](claude/CLAUDE.md), the user-scope payload. It is the only
project-scope instruction file that loads at startup, and `.claude/rules/`
holds what a file here triggers. Add no parallel file for another tool: a
`copilot-instructions.md` and an `AGENTS.md` each drifted and were deleted.
**`<tool>/` names a payload's format, not its only consumer**: `claude/`
holds Claude Code's formats; `copilot/`, payload for other repos, exists
only because `applyTo` and `paths:` differ; `skills/` is top-level as no one
tool owns its format. This repo's own config sits where each tool looks:
`.mcp.json`, `.claude/settings.json`, `.vscode/mcp.json`.

`.claude/skills/` (`ls -d .claude/skills/*/`) holds skills that act only on
this repo: project scope, deployed nowhere, reached by no deploy script
(2026-09-09), since elsewhere they only spend listing budget. Payload upkeep
that must also run in client repos goes in `skills/meta/` (`learn`), whose
`.no-copilot` marker keeps it from Copilot and lets it pin `model:`
(`copilot-payload.md`). **`.claude/settings.json` collapses every platform
skill description to `name-only` here**, so none can match by description in
this repo: a miss here is no trigger bug. `lint-skill-overrides.py` checks
coverage; a new group goes in its `PLATFORM_GROUPS` or `BEHAVIOURAL_GROUPS`.

## Commands

```bash
pre-commit run --all-files            # every pre-commit-stage check, as CI runs it on push and PR to main
pre-commit run <hook-id> --all-files  # one hook, by its id in .pre-commit-config.yaml
uv run scripts/lint-claude-md.py      # cap both CLAUDE.md files; a path lints a scratch copy
uv run --with pyyaml scripts/skill-status.py --stale  # which skills need a retest, from the stamps
uv run --with pyyaml scripts/skill-status.py --stamp <skill> --phase activation,behaviour  # or real-use
uv run scripts/handoff-status.py      # every repo's open briefs and inbox notes; reads only
bash tests/scripts/handoff-status/test-findings.sh  # handoff-status's negative cases
bash tests/scripts/skill-overlap/test-routing.sh    # the routing gate's negative case
scripts/bootstrap-pre-commit          # a clone: install pre-commit and wire all three hook stages
ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid)-'  # after any deploy: must print nothing
```

```powershell
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force  # default; -Force adds claude/CLAUDE.md, settings.json
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta         # same, when neither of those changed
./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -GlobalMcp  # prune ~/.claude.json's MCP servers; after Docker Desktop
./scripts/copy-copilot.ps1 -CopilotDir <repo>/.github -SkillGroups fabric,powerbi  # committable, for a client repo
./scripts/copy-copilot.ps1 -CopilotDir ~/.copilot -SkillGroups workflow  # Copilot's user scope: never social; meta refused
./scripts/repo-settings.ps1           # GitHub settings vs .github/repo-settings.json; -Export, -Apply
```

**Never run `link-claude.ps1` without `-SkillGroups`**, bare or with
`-Force` alone: it re-links every platform skill, undoing the prune with no
error, just `Linked` lines and `Done. Payload verified …`; the later tell is
platform skills back in the listing (2026-08-31). Check by name with the
`grep` above, never by count. `-SkillGroups` **prunes** each group it omits
from user scope, which serves client repos too, so a stale `workflow,social`
deletes `meta`: restore one on purpose.

## How this repo is structured

| Repo path | Deployed to | Mechanism | Live when |
| --- | --- | --- | --- |
| `skills/<group>/` | `~/.claude/skills/<name>` | one junction per skill (`scripts/link-claude.ps1`) | immediately — same files |
| `.claude/skills/<name>/`, `.claude/rules/` | nowhere — read in place at project scope | none; no deploy script touches them | in sessions here only: skills immediately, a rule at its next matching Read |
| `claude/agents/`, `claude/hooks/`, `claude/rules/`, `claude/mcp/` | `~/.claude/agents`, `hooks`, `rules`, `mcp` | directory copy (`scripts/link-claude.ps1`) | after `scripts/link-claude.ps1` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | plain copy | after `scripts/link-claude.ps1 -Force` |
| `claude/settings.json` | `~/.claude/settings.json` | key-level merge: target-only keys kept, shared keys replaced whole | after `scripts/link-claude.ps1 -Force` |
| `claude/mcp/.mcp.global.template.json` | `~/.claude.json` (top-level `mcpServers` only) | single-key reconcile, prunes | after `scripts/link-claude.ps1 -GlobalMcp` |
| `copilot/instructions/` | `<repo>/.github/instructions` | file copy (`scripts/copy-copilot.ps1`) | in a teammate's clone, once committed there |

**`skills/` is the only junction** (2026-09-02): edit-to-live is the skill
authoring loop, while a junction elsewhere made every uncommitted state live
machine-wide, a half-written hook included. Never turn a copy into a link: a
symlinked `~/.claude/settings.json` broke upstream three times in 2026.
Copilot takes only `CLAUDE.md` from `~/.claude`, where a profile turns on
`chat.useClaudeMdFile`; `copy-copilot.ps1` routes the rest
(`copilot-payload.md`, [README](README.md#tool-support)).

## How the pieces trigger

A skill fires on its `description` and `when_to_use` (its whole model
trigger), on `/<name>`, or on a `paths:` glob, which hides it from the
startup listing until a matching file is Read: until then `/<name>` is
`Unknown command` (2026-09-02). A rule carries only `paths:` and loads the
same way. A hook edit is not live until `link-claude.ps1` runs; the old copy
runs on, silently. Test `identity-guard` with `tests/hooks/identity-guard/`
on the repo copy, then on the deployed one.

## Working on this repo

- `/author-skill`: a new skill, to a brief and a linted draft.
- `/test-skill`: a skill's fixtures, activation contract and tests.
- `/drift-audit` → `/drift-handoff` → `/drift-update` → `/commit`, in order.
- `/learn` deploys, like `/commit`, `/code-review` and `/land`; it edits the
  payload here and writes an inbox note anywhere else.

`docs/audits/` is a dated ledger ([README](docs/audits/README.md)), and
[docs/handoffs/execute/README.md](docs/handoffs/execute/README.md) the
queue, the only place order lives: read it first. Notes from other repos
land in `~/handoff-inbox/agent-config/` (see `~/handoff-inbox/README.md`)
for `/author-skill` to brief or `/learn` to edit in. They are raw: copy
nothing out verbatim, cite client evidence by kind, and delete one only once
it has landed and the user has said yes.

## Branching and concurrent sessions

Every file of a linked skill in a deployed group (`ls` below) is live
machine-wide, committed or not, as is any `git switch`, `stash`, `reset` or
`rebase` that changes one, pre-commit's own stash/restore around a commit
included. **Commit straight to `main`**; **branch only when an intermediate
state would break while deployed** (settled 2026-09-02; reconsider if
sessions collide silently again). This overrides when `claude/CLAUDE.md` §
"Branch naming" says to branch, not how to name one: edit the two together.
A platform skill is deployed only where a `-ClaudeDir` run linked it
(2026-09-24). Integrate by fast-forward, as the repo owner, as `/land` does:
squash collapses `/commit`'s split and rebase-merge rewrites its SHAs.

```bash
ls skills/workflow skills/social skills/meta   # the deployed groups
git switch main && git merge --ff-only <branch> && git push origin main
git show HEAD:<path> | grep -n "<target>"      # nothing back: the line is theirs
```

**With another session live in this tree, sequencing outranks branching**:
stay on `main`, commit small complete units, stage explicit paths, and never
`git checkout` or `git switch`, which moves their tree too. Re-read a file
they may be editing, the queue above all, right before editing it, or your
write drops their rows silently (2026-09-02); a target not in `HEAD` is
theirs: leave it, and note the fix in your commit message. **In one tree,
only a commit isolates your work**: the index is shared, so an uncommitted
change can vanish, staged or not, as `git status` looks innocent
(2026-09-12). `/commit` § "When another session shares this tree" has the
procedure; change it there, not here. A `--worktree` session has its own
index but not its own queue: the branches diverge, and a silent overwrite
becomes a merge `--ff-only` refuses. `.claude/settings.json` branches it
from local `HEAD`; the default, `fresh`, drops unpushed commits unannounced.
A worktree buys no payload isolation for the deployed groups (2026-09-02),
but loads its own tracked `.claude/skills/`, and by inference
`.claude/rules/` (2026-09-24, from the docs; unprobed).

## Editing conventions

- **Read a file before changing it, and change it with Edit or Write**: the
  Read is what loads its `.claude/rules/` guidance, and a `sed` or heredoc
  edit loads nothing, silently. For a new file, Read a sibling.
- Rules here: `editing-skills.md`, `editing-rules.md`, `copilot-payload.md`,
  `editing-claude-md.md`, `deploy-scripts.md`, `hooks-and-agents.md`,
  `pre-commit-hooks.md`, `activation-testing.md` and `skill-overrides.md`.
- Long detail goes in a skill's own `references/`, not its `SKILL.md`.
- **Adding a harness**: what only that tool reads goes under `<tool>/`,
  promoted to the root only when a second tool reads it, and deploys via a
  `scripts/link-<tool>.ps1` that leaves the tool's home real, tool-owned.
- **Both `CLAUDE.md` files** hold only what a session needs before any Read,
  and `scripts/lint-claude-md.py` caps them: `editing-claude-md.md` says
  what moves where. `claude/CLAUDE.md` deploys with the default above.

## Validating a change

Pre-commit gates what `.pre-commit-config.yaml` lists; `tests/scripts/` has
negative-case suites for the routing gate and `handoff-status.py`; behaviour
is checked by hand against `tests/`. `skill-status.py` says what an edit
needs retested (`paths:`, `description`, `when_to_use` or a behavioural
body, never `references/`), so keep no "untested" list.

**This paragraph is the manual test procedure** for a rule, subagent or
enforcement hook (a skill has `/test-skill`, plus any
`tests/skills/<name>/README.md`); `tests/agents/security-reviewer/README.md`
works one through. Run in a fresh session. Baseline with
`claude --safe-mode`, typed, never wired into config; it strips this file
too, so for this repo's skills see `/test-skill` step 8. For a
false-positive guard it is the wrong control, silently, since the base model
passes by never asking: ablate every reference to the guard instead
(2026-09-03). Compare with `expected_findings.md`, which says what must
*not* be caught too. Exercise both the documented invocation and the refusal
modes: a subagent that does the right thing but ignores its scope guard has
failed. Run `git status` afterwards: a run that edits its fixtures
invalidates every later comparison.

The two `tests/skills/*-triggers/expected_activations.md` assert every
conditional skill. Never restate their total: read it there, or run
`grep -l '^paths:' skills/*/*/SKILL.md | wc -l`. The static check,
`test-activation.ps1 -Set fabric -StaticOnly` then `-Set pbip`, holds the
tables to the globs. Activation is keyed to the Read tool, not `cat` or
`Grep`: a probe pins `--allowedTools Read --disallowedTools Bash …`, and the
transcript is the witness (`.claude/rules/activation-testing.md`).

## Line endings

This repo auto-normalizes text and pins Windows scripts to CRLF and
shell scripts to LF in `.gitattributes`. The Fabric
portal-serialization guidance in
`claude/rules/fabric-git-serialization.md` applies to Fabric Git-synced
repos, **not** to this one.
