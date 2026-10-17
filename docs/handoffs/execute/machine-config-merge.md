---
status: open
priority: 1
needs: [user]
blocked-by: []
written: 2026-10-17
---

# Handoff: merge machine-config into this repo

- **Written**: 2026-10-17, in a session with this repo and machine-config
  open in one VS Code workspace, at the user's request to consolidate
  them. Measured against this repo at `e8c6eeb` and machine-config at
  `cc1b2a1`.
- **Decided by the user, 2026-10-17**: merge machine-config in, then
  rename this repo `developer-config`; make it private; keep the push
  gate; delete machine-config from GitHub, history and all, keeping no
  local bundle, so its identity values live nowhere.
- **Kind**: an edit, in the worktree `machine-config-merge`. Renaming
  the folder and the GitHub repo, retiring machine-config and every
  change to machine state are
  [repo-rename-cutover.md](repo-rename-cutover.md), which waits on this.
- **Runs from**: this VS Code workspace, this repo first and
  machine-config as its second folder. Not this repo alone: with reads
  outside the working directories blocked, as `claude/CLAUDE.md`
  advises, Read refuses machine-config there. As a second folder,
  machine-config brings none of its own guidance: its `CLAUDE.md` and
  ten `.claude/rules/` files never load, and no user-scope `paths:` rule
  fires on a Read of its files
  (`claude/rules/agent-instructions-scoping.md`). Read its `CLAUDE.md`,
  its rules, its `docs/handoffs/README.md` and its five briefs before
  planning; the copy under `machine/` then loads like any file here.
- **Run with**: Fable 5.1 at xhigh, not max. Send mechanical sweeps,
  such as listing every reference to either repo, to Sonnet 5.5
  subagents, so the main context keeps the judgment.

## Why

This repo's payload stands on what machine-config installs and wires up:
Claude Code itself, Git and its folder-scoped identities, the `gh`
wrappers in `~/scripts`, `uv` and `pre-commit`, the per-tenant Azure CLI
directories, `PYTHONUTF8` and `~/.config/claude-accounts.json`. Each repo
names the other in prose, in 25 files here and 23 there (2026-10-17),
and a change on one side reaches the other as an inbox note. One repo is
one clone and one bootstrap, and one pre-commit run can hold the halves
to each other: `claude/CLAUDE.md`'s tool lists against `setup.ps1`'s
`$packages` and `uv-tools.txt`, which drift today with nothing to tell.

## What must be true when it lands

How to get there is the session's call, in as many commits as it takes.
These are the outcomes, and the traps on the way.

**machine-config's tracked tree is under `machine/`, without history.**
Interleaved, it would break: `setup.ps1` copies every top-level
`scripts/*.ps1` to `~/scripts`, which is on PATH, so this repo's
`link-claude.ps1` and linters would ship there. Export it with
`git archive` from the main checkout before entering the worktree, whose
guard refuses git in another repo, and record its SHA. Its repo-level
files merge into this repo's own instead of moving: `.claude/rules/`,
`.claude/settings.json`, `.mcp.json`, `.vscode/`, `.github/`,
`.gitattributes`, `.gitignore`, `.pre-commit-config.yaml`,
`PSScriptAnalyzerSettings.psd1`, `CLAUDE.md`, `README.md` and
`docs/handoffs/`.

**No tracked file holds an identity value.** On 2026-10-17 a denylisted
name stood in four: `config.psd1`'s identity block, `docs/ssh-setup.md`,
`scripts/vscode-profiles.ps1` and
`configs/vscode/profiles/profiles.psd1`. Every identity key leaves
`config.psd1` for a local store that `setup.ps1` and every other reader
load: the Git names and emails, the GitHub usernames and PAT variable
names, `RepoRoot`, `WorkRepoRoot`, `ClientIdentities` and
`ClaudeWorkConfigDir`, the personal ones too, so one mechanism holds
them all. The store is:

- outside the repo, under `~/.config/` beside `az-tenants.json` and
  `claude-accounts.json`, since neither a worktree nor a fresh clone
  carries an ignored file; `~/.config/identities.json`, say;
- seeded from a tracked template of placeholders when absent, as
  `configs/azure/az-tenants.template.json` is, so a fresh machine meets
  the placeholder skips that exist today;
- shaped for a later skill that adds one identity by prompting for each
  value ([repo-rename-cutover.md](repo-rename-cutover.md) § "After the
  cutover");
- read through one loader that keeps `scripts/lib/ConfigHelpers.ps1`
  pure, tested under strict mode.

The other three files take their values from the store or say "the work
account". identity-guard scans every line the copy adds: a commit it
blocks means the scrub is unfinished, never that the guard is wrong.

**The move changes nothing on this machine, and that is shown.**
`setup.ps1` writes `~/.gitconfig` whole on every run, and no identity is
global, so a run that finds no identities leaves no `includeIf` behind,
and git then refuses to commit in every repo. Write the real store from
this machine's `config.psd1`, then show that what `setup.ps1` would now
write for `~/.gitconfig` and each include file is byte-identical to the
live files, and that `claude-accounts.ps1` would write the same map,
printing none of them. A render function that the region and a test
both call is one way.

**One set of instruction files.** Run `/scope-instructions` over
machine-config's `CLAUDE.md` and handoff `README.md`, and place each
part by this repo's rules:

- commands and repo-wide conventions in root `CLAUDE.md`, within its
  cap, with a `machine/` row in § "How this repo is structured";
- what a session must know before touching `machine/` in `paths:` rules
  on the narrowest globs that work, not a nested `CLAUDE.md`, as
  `.claude/rules/editing-claude-md.md` says;
- the reasoning in `machine/README.md`.

machine-config's ten rules move to `.claude/rules/` with `machine/` on
every glob. Both repos have a `pre-commit-hooks.md`, which become one,
and no project rule may share a name with one in `claude/rules/`.

**One pre-commit config and one push gate.** This repo's identity-guard
hooks stay, running the repo copy at commit, message and push, and
replace machine-config's wrapper around the deployed copy. This repo's
`scripts/push-gate.sh` stays and machine-config's twin goes, its
override key renamed from `agentconfig.push`. PSScriptAnalyzer and
Pester join, and PSScriptAnalyzer then lints this repo's own `.ps1`
files for the first time, `link-claude.ps1` and `test-activation.ps1`
among them: fix what it finds rather than widen the two exclusions
machine-config froze. `default_install_hook_types` names every stage
the hooks use, and one bootstrap replaces `scripts/bootstrap-pre-commit`
and `machine/scripts/pre-commit-bootstrap.ps1`. gitleaks now scans
`machine/` under this repo's allowlist, which exempts `tests/` alone:
allowlist a path if one needs it, never the tree.

**One queue.** machine-config's five briefs move into this directory,
their paths re-pointed, landing from now on as this repo's briefs land.
Its `claude-login-pin.md` and this repo's `claude-work-account.md` are
two halves of one feature that send each other inbox notes: re-point
both, and ask the user whether they become one.

**The new name wherever text is current.** Current text says
`developer-config`, `.github/repo-settings.json`'s `_repo` and the
override key included; `docs/audits/` and `docs/evidence/` are dated and
stay as they stand. Skills such as `learn` and `triage` name this repo
to decide whether a learning is edited here or sent to an inbox, so a
missed one sends it to an inbox nothing reads. A reference from one half
to the other becomes a relative path. A line naming either folder, such
as `claude/CLAUDE.md`'s source-of-truth lines or
`docs/scheduled-tasks.md`'s `$repo`, is written for
`C:\Repos\Personal\developer-config`, true only once the cutover renames
the folder, so nothing deploys between this landing and the cutover. On
2026-10-17 no script here told the repo by its folder name, and
`push-gate.sh`'s override key was the one name in logic.

## Put to the user

- Whether `setup.ps1` ends by running `link-claude.ps1`, below its admin
  stop, so one command bootstraps a fresh machine. The default groups
  then need one home: a default inside `link-claude.ps1` would also end
  its bare-run trap, but changes a rule root `CLAUDE.md` states.
- `/scope-instructions`' proposal table, which it applies only on
  approval.
- Whether `claude/CLAUDE.md` names the repo's folder at all, since the
  user wants it free of repo paths (this repo's auto-memory
  `global-claude-md-no-repo-refs`).
- What becomes of `personal-config.code-workspace`, which joins two
  folders this merge makes one.
- Whether the two Claude-account briefs above become one.

## Checks before landing

- `pre-commit run --all-files` in the worktree, now with Pester and
  PSScriptAnalyzer beside gitleaks, identity-guard and the linters.
- `uv run scripts/lint-claude-md.py`, and
  `uv run scripts/handoff-status.py . --no-inbox --check`.
- `machine/setup.ps1 -WhatIf` from the worktree, against the real store.
  Never a real run from a worktree: it points every new shell's profile
  at the worktree (machine-config's `CLAUDE.md`).
- The byte-identical proof above.
- `./scripts/test-activation.ps1 -Set fabric -StaticOnly`, then
  `-Set pbip`, if a `paths:` glob outside `machine/` changed.

## Where it lands

From the main checkout with no push, as `.claude/rules/handoff-briefs.md`
says, and nothing deployed after it: the cutover deploys once the folder
has its new name, and should follow at once. From the export on,
machine-config takes no commit; the cutover checks its HEAD against the
recorded SHA. Landing deletes this brief and drops it from the
cutover's `blocked-by`.

## Scrubbing

This repo is public until the cutover. No organization, account, tenant
or client name and no work email goes in this brief, a commit message or
a file: write "the work identity" and "the work root". Print no identity
value while proving the move; compare by hash or by a yes or no.

## Not checked

- About 1,100 lines of `setup.ps1` this brief's session did not read:
  978 to 1155, and 1466 to the end.
- Which scripts besides `setup.ps1` read the identity keys: only it did
  through `$config.` on 2026-10-17, but a script may read `config.psd1`
  under another name.
- How long a commit takes once Pester and PSScriptAnalyzer run on every
  one here.

## Re-measure before acting

From the main checkout, before the worktree:

```bash
git -C C:/Repos/Personal/machine-config status --short           # clean on 2026-10-17
git -C C:/Repos/Personal/machine-config worktree list            # main only
git -C C:/Repos/Personal/machine-config rev-parse --short HEAD   # cc1b2a1
uv run scripts/handoff-status.py . --no-inbox
```

A moved HEAD is fine once read. A dirty tree or a worktree there is
someone's work in progress: stop and ask. Then list the tracked files
holding a denylisted name, printing paths, never names: write the
denylist's names, less its `#` comments, blank lines and `exempt:`
lines, to a scratchpad file, run `git -C <repo> grep -l -i -F -f <file>`
on each repo, and delete the file. On 2026-10-17 that listed the four
files above in machine-config, and in this repo only
`docs/social/social-preview.png`, where three characters sit inside
compressed pixel data, an `IDAT` chunk: chance bytes, not text.
