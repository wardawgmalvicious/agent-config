# Handoff: split `skills/workflow/` by scope, then decide what Copilot gets

- **Written**: 2026-09-09, after trying to run `/commit` in GitHub
  Copilot Chat in a client repo and getting a wrong answer about why it
  did not appear.
- **Kind**: a scope decision, then a payload move plus `link-claude.ps1`
  changes. Not a `/author-skill` job — no new skill is written.
- **Run in**: a fresh session. This touches the group model that
  `link-claude.ps1`, the user-scope prune, and root `CLAUDE.md`'s whole
  "How this repo is structured" section are all built on.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The premise correction that prompted this

Copilot Chat, asked why `/commit` did not work, answered that `SKILL.md`
is not slash-invocable in Copilot and that `.github/prompts/*.prompt.md`
is the only primitive that is. **That is wrong**, and building a
prompt-file wrapper on top of it would have been wasted work.

Checked 2026-09-09 against `code.visualstudio.com/docs/copilot/customization/agent-skills`:

> Skills are available as slash commands in chat, alongside prompt
> files. Type `/` in the chat input field to see a list of available
> skills and prompts, and select a skill to invoke it.

`user-invocable` defaults to **`true`**, and arguments pass the same way
(`/webapp-testing for the login page`). The three invocation fields form
a matrix, all of which Copilot supports and Claude Code also honours:

| Frontmatter | In `/` menu | Auto-loads |
| --- | --- | --- |
| *(default)* | yes | yes |
| `user-invocable: false` | no | yes |
| `disable-model-invocation: true` | yes | no |

Prompt files are a **parallel** primitive, not a required wrapper.

**Still unexplained, and step 0 below:** why `/commit` did not appear,
given the workflow skills were reaching that session (they showed in
`Used N references` on 2026-09-09) and `~/.claude/skills` was one of the
two enabled roots.

## Two axes, and the request conflated them

The ask was "make `commit`, maybe `land` and `code-review`, available in
Chat; the rest are repo-specific, split them out." That is two
independent questions and they give different answers:

- **Axis 1 — repo-general vs `agent-config`-specific.** Decides Claude
  Code *scope*: user or project.
- **Axis 2 — harness-neutral vs Claude Code-coupled.** Decides whether a
  skill can be shipped to Copilot at all.

Measured 2026-09-09 by grepping each skill for `harness`,
`identity-guard`, `github-mcp`, `~/.`, `mcp`, `hook`:

| Skill | Axis 1 | Axis 2 | Coupling found |
| --- | --- | --- | --- |
| `code-review` | repo-general | **neutral** | none. Its one `CLAUDE.md` mention stays true — Copilot reads `CLAUDE.md` as a documented default |
| `commit` | repo-general | light | 3 places: "`git add -p` unavailable in this harness", the `identity-guard` backstop, `~/.config/identity-denylist.txt` |
| `land` | repo-general | **hard** | built on `github-mcp` throughout — account probing, PR creation, the two-identity guard |
| `author-skill`, `test-skill`, `learn`, `drift-audit`, `drift-handoff`, `drift-update` | **`agent-config`-specific** | n/a | they maintain this repo's own payload |

`land` is the one that does not yield to a port. Its whole subject is
that `gh` and `github-mcp` authenticate as different accounts — and MCP
is already recorded as the single payload piece that cannot cross to
Copilot. A Copilot `land` would be a different skill, not a translation.

## The part that pays off regardless of Copilot

All nine workflow skills sit at **user scope**, so the six
`agent-config`-specific ones are in the startup listing of every session
on this machine — including client-repo sessions where they can never
usefully fire. A `description` is the entire trigger mechanism and the
listing has a budget, so this is a real cost paid in the wrong place.

Root `CLAUDE.md` already records the measurement that makes the fix
safe: **project scope adds names user scope lacks** (2026-09-02). Six
skills that only ever run here belong in this repo's own
`.claude/skills`, not in every client session.

So the split is worth doing on Claude Code grounds alone. Copilot is the
occasion, not the justification.

## Proposed shape — confirm before executing

- `skills/workflow/` keeps the repo-general verbs: `commit`,
  `code-review`, `land`. User scope, as today.
- A second group — name it in the session; `skills/repo/` and
  `skills/authoring/` were both floated — takes `author-skill`,
  `test-skill`, `learn`, `drift-audit`, `drift-handoff`, `drift-update`.
  Project scope in this repo only.

Then, on axis 2: ship `code-review` to Copilot as-is, `commit` after a
small content port, and `land` not at all.

## The unresolved design tension

`copy-copilot.ps1` selects by **group**, and this split does not give a
group that means "the ones Copilot should get" — `workflow` would
include `land`. Options, none chosen:

1. A third group, splitting on axis 2 as well. Clean selection, but the
   group name stops describing what the skill *is*.
2. `-SkillNames` on `copy-copilot.ps1` for per-skill selection.
3. Ship `land` and let it degrade — it would auto-load in Copilot on
   description relevance and then reference tools that are not there.
   Cheapest, and the worst failure mode: confidently wrong.
4. Mark `land` in its own frontmatter and have the script read it — the
   port list would then live with the skill rather than in a script
   argument, which is how `copilot/.source-hashes.json` handles the
   rules that were deliberately not ported.

## Step 0 — answer these before moving any file

1. **Do the workflow skills appear in Copilot's `/` menu at all?** Type
   `/` in Chat in a client repo with `~/.claude/skills` enabled. If they
   are absent while still showing in `Used N references`, that is a
   finding worth recording on its own — auto-load and the slash menu
   would be reading different roots — and it changes what shipping to
   `.github/skills` buys. If they are present, the original problem was
   only that `/commit` needed selecting from the menu.
2. **Re-run the coupling grep.** The table above is a 2026-09-09
   snapshot and these files are edited often. Wave 14's evidence rotted
   in under two hours; this queue's standing rule is to re-measure a
   row's own evidence rather than read it off the row.
3. **Confirm project-scope skills actually resolve here** with the six
   moved out of user scope — the 2026-09-02 measurement was about
   project scope *adding* names, not about a name existing *only* there.

## Execution notes

- `-SkillGroups` **prunes**: the first `link-claude.ps1` run after the
  move deletes the six from `~/.claude/skills`. That is intended, but it
  means a half-done move leaves this repo's own maintenance skills
  unavailable in the very session doing the move. Land the repo-side
  move and the deployment change together.
- Root `CLAUDE.md` states "workflow-only prune" in several places and
  names the group in its command block. Those lines move with the split.
- `tests/` reference workflow skills by path; check before renaming.
- The `.claude/settings.json` `skillOverrides` block collapses platform
  skill descriptions in sessions here. Six newly project-scoped skills
  will now be *in* those sessions' listings where they were previously
  arriving from user scope — same listing, different source, so no
  change is expected, but confirm rather than assume.
