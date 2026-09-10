# Handoff: ship the workflow skills to Copilot

- **Written**: 2026-09-09, as the surviving half of a brief that also
  covered the Claude-side scope split. That half is **done** — see
  "What already happened" below — and this is what it left.
- **Kind**: a decision, then a one-line script invocation. No new skill
  is written and no payload moves.
- **Run in**: any session here. The blocking question is a judgment call
  about client repos, not a measurement.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The premise correction that started all of this

Keep this at the top: it is the reason the original brief existed, and
it is still the thing most likely to send a future session down a wrong
path.

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

**The actual cause was found separately and is now fixed.** A `model:`
key of *any* value stops VS Code Copilot dispatching a skill as a slash
command — the request never reaches a model and no session is created,
so it reads as a hang rather than an error. Measured 2026-09-09 with
single-variable probes: `sonnet` and `inherit` both broke it, while
`effort:`, `when_to_use:` and `disable-model-invocation:` were all fine.
Every `SKILL.md` here now carries the value as a commented placeholder
(`# model: inherit`), and `scripts/lint-frontmatter.py` fails the build
on an uncommented one, so this cannot regress silently.

## What already happened

The Claude-side scope split was executed 2026-09-09 and needs nothing
further:

- Seven skills — `author-skill`, `test-skill`, `learn`, `drift-audit`,
  `drift-handoff`, `drift-update`, `land` — moved from
  `skills/workflow/` to `.claude/skills/` at project scope. They are
  authored in place, deploy nowhere, and no script reaches them.
- `skills/workflow/` keeps `code-review` and `commit`.
- `scripts/link-claude.ps1` and `scripts/copy-copilot.ps1` needed **no
  code change** — both select out of `skills/`, so the moved skills are
  simply invisible to them.
- `.gitignore` gained `!/.claude/skills/`, and the pre-commit skills
  hook gained a second depth-pinned arm for the project-scope tree.

**That dissolved the design tension this brief used to carry.** The old
open question was that `copy-copilot.ps1` selects by group and no group
meant "the ones Copilot should get", because `workflow` would have
included `land`. With `land` moved to project scope, `workflow` *is*
exactly the portable set — so the four options once listed here (a third
group, a `-SkillNames` parameter, ship-and-degrade, a frontmatter
marker) are all unnecessary. Do not rebuild any of them.

## What is left

One question, then one command.

**The question: does a client repo want `commit` and `code-review` from
this repo at all?** Both are harness-neutral — re-verified 2026-09-09 by
grepping for `harness`, `identity-guard`, `github-mcp`, `~/.`, `mcp` and
`hook`. `code-review` has no coupling whatsoever, and its one
`CLAUDE.md` mention stays true because Copilot reads `CLAUDE.md` as a
documented default. `commit` has three soft spots that are *worth a
read* before shipping rather than blockers:

1. "`git add -p` unavailable in this harness" — true of Claude Code, not
   necessarily of the reader's.
2. The `identity-guard` backstop, which is a hook that exists only on
   this machine.
3. `~/.config/identity-denylist.txt`, same.

None breaks the skill; each makes it describe a guard the reader does
not have. Decide whether to ship `commit` as-is, port those three lines,
or ship `code-review` alone.

**The command**, once decided:

```powershell
./scripts/copy-copilot.ps1 -CopilotDir <repo>/.github -SkillGroups fabric,powerbi,workflow
```

Note this vendors **personally authored** skills into a client's
history, which the platform groups mostly avoid by being derived from
public Microsoft docs. `copy-copilot.ps1`'s own `.NOTES` flags it: it is
a one-way door once pushed, so review the diff before committing.

## Worth confirming while there

The original step 0 asked whether the workflow skills appear in
Copilot's `/` menu at all, given they were reaching the session (they
showed in `Used N references`) while `/commit` did not appear. The
`model:` finding above is a sufficient explanation and the fix is in, so
this is now a confirmation rather than an investigation: type `/` in
Chat and check that `commit` and `code-review` are listed. If they are
still absent with no `model:` key anywhere, that is a *new* finding —
auto-load and the slash menu would be reading different roots — and
worth recording on its own.
