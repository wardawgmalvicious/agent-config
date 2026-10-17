---
status: open
priority: 2
needs: []
blocked-by: []
written: 2026-10-16
---

# Handoff: restate the payload's VS Code claims for the Claude target

- **Written**: 2026-10-16. On that day the user chose VS Code's Claude
  session target for every chat, and stopped using the Local and
  Copilot targets. The payload was read at `2bdad8a`, where the
  deployed copies of the three files below matched the repo.
- **Kind**: prose edits to two user-scope rules, `claude/CLAUDE.md` and
  `claude/rules/README.md`, plus one dated evidence entry. No behaviour
  changes. The machine-config edits this decision needs went to
  `~/handoff-inbox/machine-config/2026-10-16-vscode-claude-target-only.md`.

## Why it waited

Machine-config provisions the VS Code profiles, and this repo's note of
2026-10-16 asked it to hide Local in every profile
(`chat.editor.localAgent.enabled` `false`) and to drop the eleven
settings that VS Code 1.142.0's own setting text says only Local uses,
so that the passages below are restated once, against the profiles as
they stand. **It landed on machine-config's `main` on 2026-10-17** as
`d37a1a7` (the three named profiles, its `vscode-profiles.md` rule and
`docs/manual-steps.md`), then `60b20c8` and `cc1b2a1` (its keep-awake
watcher, which no file here names). `/triage` re-measured it that day,
below, and reopened this brief.

## What is stale

Line numbers are as of `2bdad8a`, re-checked unchanged at `d56fe51` on
2026-10-17.

**`claude/CLAUDE.md:181-189`**, § "GitHub Copilot does not inherit this
payload":

> Claude Code, VS Code's **Claude** session target (its engine,
> 2026-10-05) and its **Local** target on default locations (2026-10-08)
> read `~/.claude`; the **Copilot** target does not, on any model.

The Local clause describes a target no longer in use.

**`claude/rules/agent-instructions-scoping.md`**:

- `:176-183`, the bullet "Each fact has one home". It tells the reader to
  leave `chat.useClaudeMdFile` at `true` so that "the Local agent then
  reads the `CLAUDE.md` … which is wanted since 2026-10-08". Once Local
  is gone, nothing here reads it that way.
- `:185-201`, "Every VS Code claim here is the Local agent harness", and
  the harness table that follows. These describe what each target reads,
  but nothing in them says which target is in use here.

**`claude/rules/vscode-scoping.md`**, the Local passages that brief 02
of `docs/audits/2026-10-16/vscode-agent/` named as a separate task for
after machine-config lands:

- "Every profile has its own settings" (`:56-63`)
- "An unlisted location keeps its default" (`:64-72`), which says the
  profiles keep Claude's locations on because "the Local agent reading
  them is wanted (2026-10-08)"
- "Claude's hooks stay off" (`:73-81`)
- "These switches govern the Local harness alone" (`:82-97`), with its
  "keep them" on the four pins. Brief 02 rewrites only the clause at
  `:96`.
- `chat.includeReferencedInstructions` (`:104-113`)

**`claude/rules/README.md`**: the descriptions of both rules, at `:133`
and `:171`. They say each rule now reads "as keeping the files in, as the
user chose on 2026-10-08", and that `chat.useClaudeMdFile` is left on.

## What to change

1. **`claude/CLAUDE.md`**: state that the Claude target is the one in
   use (2026-10-16), and drop the Local clause. The section is at its
   200-line cap, and `claude-work-account.md` needs room in this file,
   so make the edit save a line rather than add one.
2. **`agent-instructions-scoping.md`**: cut the "Each fact has one home"
   bullet's `chat.useClaudeMdFile` advice down to what still holds. Open
   the harness paragraph by naming the Claude target as the one in use
   here. Keep the table's Claude and Copilot rows: the Copilot row still
   covers `.github/` files in client repos. On the Local row, ask the
   user whether to drop it now or when VS Code removes Local, and record
   their answer in the commit message.
3. **`vscode-scoping.md`**: restate each passage listed above against
   the profiles as they stand after machine-config's landing. Copy its
   pin set from machine-config's `.claude/rules/vscode-profiles.md`
   rather than from this brief. Add the fact these passages lack: a new
   chat starts on the target the profile last picked
   (`chat.userSelectedSessionType`, kept in storage, never in a settings
   file), and no setting can name Claude as the default. That was read
   from 1.142.0's bundle on 2026-10-16; the machine-config note has the
   full selection order. As landed on 2026-10-17, that rule keeps all
   four pins, `chat.editor.preferCopilotHarness` included, where this
   repo's 2026-10-16 note expected that one to stop mattering once Local
   was hidden: nobody verified that a remembered Local pick is checked
   against Local's switch. It drops a pin only once VS Code stops
   registering it, so "keep them, though they match the defaults" now
   holds for three of the four. No profile, Default included, sets any
   of the eleven Local-only settings, so the `chat.*Locations`, Claude's
   hooks and `chat.includeReferencedInstructions` passages describe
   settings set nowhere here. Add too that a fresh machine needs one pick
   per profile after apply, as machine-config's rule and
   `docs/manual-steps.md` now say.
4. **`claude/rules/README.md`**: rewrite both descriptions to match.
5. **`docs/evidence/user-claude-md.md`**: add a dated entry at the end of
   § "GitHub Copilot does not inherit this payload" for edit 1, as
   `.claude/rules/editing-claude-md.md` requires.

## Constraint on the fix

- **Keep the heading** "GitHub Copilot does not inherit this payload".
  `claude-work-account.md` and the evidence ledger cite it by name.
- **Leave the corporate-network sentence** in that section to
  `claude-work-account.md`, which corrects it once someone measures it
  on that network. Whichever brief lands second re-reads the section
  before editing.
- **Do not write that VS Code has removed Local.** It hid Local here by
  the user's choice. The removal is still only announced, and narrowing
  that claim is brief 02's work.
- Date every new claim to the session that measured it.

## Re-measure before acting

- Confirm machine-config has landed its note: each
  `configs/vscode/profiles/*.settings.json` there carries
  `"chat.editor.localAgent.enabled": false`. Also read its
  `.claude/rules/vscode-profiles.md` for the pin set it kept. On
  2026-10-17 all three, and Default's live `settings.json`, carried the
  four pins and none of the eleven.
- Read each profile's remembered target, as it was read on 2026-10-16:
  the `chat.userSelectedSessionType` key in each
  `globalStorage/state.vscdb` under `%APPDATA%\Code\User`, opened by
  `python3.13`'s `sqlite3` with `mode=ro`. That day only Fabric
  remembered `agent-host-claude`. Say how many profiles remember Claude
  now. On 2026-10-17 all four did, Default, Config, Azure and Fabric,
  read from copies of the four files.
- Check whether brief 02 of the 2026-10-16 vscode-agent audit has run.
  If it has, its clause at `vscode-scoping.md:96` is already rewritten:
  work around it. On 2026-10-17 it had not: that run is unexecuted.

## Verification

1. `uv run scripts/lint-claude-md.py`: `claude/CLAUDE.md` at most 199
   lines.
2. `grep -n "Local" claude/CLAUDE.md` should show no hit in the Copilot
   section.
3. `grep -n "wanted since 2026-10-08\|reading them is wanted" claude/rules/*.md`
   should print nothing.
4. `uv run --with pyyaml scripts/lint-frontmatter.py claude/rules/vscode-scoping.md claude/rules/agent-instructions-scoping.md`.
5. Deploy from the main checkout, in pwsh:
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`.
   Then, in Git Bash, run `diff --strip-trailing-cr` between each of the
   three edited files and its `~/.claude` copy; each should print
   nothing. After that,
   `ls ~/.claude/skills | grep -E '^(fabric|pbir|pbid|pbip|powerbi|msix)-'`
   should print nothing too.
6. `pre-commit run --all-files`.

## Where it lands

Work it in a worktree named `vscode-claude-target-only`. Land it from
the main checkout as `.claude/rules/handoff-briefs.md` describes, then
deploy from `main` as in step 5, and delete this brief in the commit
that finishes the work. If a step is skipped, for example because the
user keeps the Local row until VS Code removes Local, say so in that
commit.

## Scrubbing

This repo is public. The organization, its Claude plan and the client
repos are named nowhere here, and the edits must keep it that way.
