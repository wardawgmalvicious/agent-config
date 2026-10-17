---
status: open
priority: 1
needs: [user]
blocked-by: [machine-config-merge.md]
written: 2026-10-17
---

# Handoff: rename this repo developer-config and retire machine-config

- **Written**: 2026-10-17, beside
  [machine-config-merge.md](machine-config-merge.md), in the same
  session, with the machine state below measured that day.
- **Kind**: machine state and GitHub, in a fixed order, each step
  checked before the next. No worktree: this renames the folder a
  worktree would live in, and `link-claude.ps1` refuses to run from one.
  Its commits go to `main` once the folder has its new name.
- **Runs from**: a terminal session launched in `C:\Repos\Personal`,
  with VS Code and every Claude session in either repo closed;
  `ListAgents` names none. Not this workspace and not this repo: Windows
  will not rename a folder that something holds open, and says only
  `Permission denied`. Launched there, the session loads none of this
  repo's `.claude/rules/`, and its `CLAUDE.md` only on a first Read
  inside it, so Read root `CLAUDE.md`, `.claude/rules/deploy-scripts.md`
  and `.claude/rules/handoff-briefs.md` first, and the rules the merge
  wrote for `machine/`.
- **Run with**: Opus 5.5 at high. The steps are fixed and checked; their
  order is the hard part, and it is written here.

## Why the order matters

Each step moves something that finds a folder by its path, and each
fails without a word if it runs too early or too late. The sharpest is
machine-config's: its profile stubs embed its checkout's path, so once
that checkout is gone every new shell skips its profile silently, and
only a `setup.ps1` run from the new folder rewrites them. And the repo
turns private before any push, or that push publishes `machine/`.

## The steps

1. **Re-measure** (below): the merge has landed, no worktree exists
   here, `main` is unpushed past the merge, and machine-config's HEAD is
   still the SHA the merge recorded. A later commit there is ported into
   `machine/` first.
2. **Inventory what points at either folder** before anything moves,
   keeping the list in the session, never in a file here. On
   2026-10-17:
   - 10 skill junctions at user scope, and 62 in three other repos'
     `.claude/skills/`, each from a `-ClaudeDir <repo>/.claude
     -SkillsOnly -SkillGroups <groups>` run: record each repo's groups,
     read from the skills it holds;
   - both profile stubs, `$PROFILE.CurrentUserAllHosts` and `~/.bashrc`;
   - `MachineConfig-WeeklyVSCodeAudit`, the one scheduled task that runs
     from the machine-config checkout; `MachineConfig-AgentKeepAwake`
     and `MachineConfig-ClaudeUpdate` run from `~/scripts`;
   - Claude Code's project folders under `~/.claude/projects/` for each
     repo, agent-config's holding its memory and 172 transcripts and
     machine-config's its memory and 24, placed by the `cwd` their
     transcripts record, never by decoding a name, which maps `:`, `\`
     and `.` alike to `-`;
   - `~/.claude.json`'s project entries for both folders, under both
     drive-letter casings, with any local-scope MCP servers in them;
   - the VS Code workspace deployed under `C:/Repos`, and each profile's
     folder associations;
   - `~/handoff-inbox/agent-config/` and
     `~/handoff-inbox/machine-config/`, both empty.
3. **GitHub, before any push.** Check which account `gh` acts as,
   `gh api user -q .login`. Snapshot the settings with
   `skills/workflow/recreate-repo/scripts/repo-settings.ps1 -Export`.
   Rename the repo `developer-config`, make it private, and point
   `origin` at the new URL. Private drops GitHub's secret scanning and
   push protection, which a personal account's private repo cannot
   have, so export the settings again, to commit after step 4.
4. **The folder.** Rename `C:\Repos\Personal\agent-config` to
   `developer-config`. Every skill junction dangles from here until
   step 6, so go straight on.
5. **Claude Code's state.** Move agent-config's project folder to the
   new folder's name, `c--Repos-Personal-developer-config`, so this
   repo's memory follows it. Fold machine-config's memory files into
   it, each re-read against the merged repo, and merge the two
   `MEMORY.md` indexes. Re-add any local-scope MCP server from the new
   folder with `claude mcp add --scope local`, never by editing
   `~/.claude.json` while a session runs. Rename the inbox folder,
   remove machine-config's, and update `~/handoff-inbox/README.md` if it
   names either.
6. **The payload.** From the new folder,
   `./scripts/link-claude.ps1 -SkillGroups workflow,social,meta -Force`,
   then root `CLAUDE.md`'s post-deploy grep, which must print nothing,
   and a check that every user-scope junction resolves into the new
   folder. Then each repo from step 2, with exactly the groups it held:
   `-SkillGroups` prunes a group it omits. This is also the first
   deploy of the merge's `claude/CLAUDE.md`.
7. **The machine.** Check that the identity store the merge wrote is in
   place, then run `machine/setup.ps1 -WhatIf`, then the real run on the
   user's go, in the background, since it outlasts a tool call. Then
   check: both stubs name the new folder; a fresh `pwsh` and Git Bash
   each load their profile; `~/scripts` is current; git resolves an
   identity in a personal repo and in a work repo, tested as present and
   never printed. Re-register `MachineConfig-WeeklyVSCodeAudit` from
   `machine/docs/scheduled-tasks.md`; its name can stay. With VS Code
   closed, run `machine/scripts/vscode-profiles.ps1 -Associate`, then
   reopen VS Code on the new folder and pick the Claude target if it
   asks.
8. **Push `main`**, now private, with the settings snapshot committed.
9. **machine-config goes**, only once steps 1 to 8 hold and the user
   says yes. No bundle is kept, by the user's call of 2026-10-17, and
   GitHub's 90-day restore would bring the history back, so it is no
   fallback either. `gh repo delete` needs the `delete_repo` scope,
   which the user grants with
   `gh auth refresh -h github.com -s delete_repo`, since a refresh
   widens whichever account is active (`claude/CLAUDE.md`). Then the
   local folder, with nothing holding it.

## After the cutover

The skills the merge makes room for, each to be briefed through
`/author-skill`. Each gathers values by prompt, the way `/land` asks
before acting, and leaves the writing to scripts that take parameters,
keep `-WhatIf` and are tested, so a machine where Claude Code cannot run
still has them.

- **provision-identity**, project scope. Asks the kind (personal, work
  or client), the root folder, the commit name and email, the GitHub
  username and PAT variable name, the Claude login, the Azure tenant's
  short name and ID, and the names to add to the identity denylist;
  shows every write for one yes; then writes the store and renders from
  it through `GitIdentity.ps1`, `claude-accounts.ps1` and a new tenant
  writer. A PAT or an SSH passphrase never goes through a prompt, whose
  answer is kept in the transcript and sent to the model: it hands
  `github-pat-bootstrap.ps1` or `ssh-keygen-bootstrap.ps1` to a
  terminal, whose masked prompt needs a real console anyway, then
  checks that the variable exists without reading it.
- **diagnose-machine**, user scope, since the trouble shows up in
  whatever repo is open: ECONNRESET, a slow Git Bash, PATH and Python.
  It runs the doctor scripts and `network-soak.ps1` from `~/scripts`
  and reads them against `machine/README.md`'s "When…" runbooks; it
  asks before any repair and before elevating, and `-Elevate` then
  raises the one Windows prompt.
- **add-tool**, project scope: where a package goes, the
  `winget show --scope user` check before `RequiresAdmin`, and
  `claude/CLAUDE.md`'s tool lists in the same commit.
- **finish-bootstrap**, project scope: reads a JSON summary of a
  `setup.ps1` run, today written only by its elevated half, then walks
  `machine/docs/manual-steps.md` and the scheduled tasks, one prompt per
  step.

These stay scripts, run by hand or by a task: `setup.ps1`, which runs
before Claude Code exists; `upgrade-packages.ps1`, self-contained to run
on machines this repo does not manage; `claude-onsite.ps1`, for when
Claude Code cannot sign in; `claude-update.ps1` and
`agent-keep-awake.ps1`, scheduled tasks; the `gh` shims; and
`python-setup.ps1` and `vscode-profiles.ps1`, which `setup.ps1` calls.

## Where it lands

Its commits go to `main` in the renamed folder: the settings snapshot,
any fix forward, and the commit that deletes this brief, which first
writes the four skills above into briefs of their own unless
`/author-skill` already has, so they outlive it.

## Scrubbing

As the merge's: no organization, account, tenant or client name and no
work email in a file or a commit message. Cite the repos holding
junctions by kind.

## Not checked

- Whether Claude Code adopts a moved project folder's memory at the next
  launch in the renamed folder: check that the first session there lists
  this repo's memories.
- What `gh repo rename` leaves redirecting, and for how long.
- Whether a client repo's own files name this repo's folder.

## Re-measure before acting

```powershell
git -C C:\Repos\Personal\agent-config worktree list            # main only
git -C C:\Repos\Personal\agent-config log --oneline origin/main..main
git -C C:\Repos\Personal\machine-config rev-parse --short HEAD  # the merge's SHA
Get-ChildItem 'C:\Repos\*\*\.claude\skills\*' -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.LinkType -eq 'Junction' -and "$($_.Target)" -like 'C:\Repos\Personal\agent-config*' } |
    Group-Object { $_.Parent.Parent.Parent.FullName } | Select-Object Count, Name
Get-ScheduledTask -TaskName 'MachineConfig-*' | ForEach-Object { $_.TaskName; $_.Actions.Arguments }
Select-String -LiteralPath $PROFILE.CurrentUserAllHosts, "$HOME\.bashrc" -Pattern 'machine-config' -SimpleMatch -List |
    Select-Object Path
```
