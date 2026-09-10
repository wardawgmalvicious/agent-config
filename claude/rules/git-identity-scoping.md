---
paths:
  - "**/.gitconfig"
  - "**/.gitconfig-*"
  - "**/gitconfig"
  - "**/gitconfig-*"
---

# Git identity: which config file owns it

Applies when editing a git config file — the deployed `~/.gitconfig`, or
the source copies a machine-setup repo keeps under `configs/`. On a
machine with more than one identity these files decide who every commit
is attributed to, and **every failure mode here is silent**: the wrong
author is stamped at commit time and surfaces at push, once the history
already needs rewriting.

If a project-scope `.claude/rules/git-identity-scoping.md` exists, that
file supersedes this one.

## The shape

Identity is routed by folder, not declared once:

| File | Declares | Why |
| --- | --- | --- |
| `~/.gitconfig` | everything **except** `[user] name`/`email` | a machine-wide default is a wrong default |
| `~/.gitconfig-<context>` | one `[user]`, one signing key, one credential username | pulled in by an `includeIf` for that root |
| `<repo>/.git/config` | a per-repo override | the only correct place for a repo outside every root |

`user.useConfigOnly = true` in the base config is load-bearing rather
than belt-and-braces. Without it git does not error on a missing
identity — it **invents** one, and on a domain-joined Windows machine it
builds that from the AD record, i.e. the corporate email. With it, a
commit in a repo outside every configured root fails with:

```text
*** Please tell me who you are.
fatal: no email was given and auto-detection is disabled
```

That failure is the feature. Answer it with `git config --local
user.email ...` in that repo, never by adding an identity to the base
config.

## `includeIf gitdir:` matches more strictly than it looks

Four ways the pattern silently matches nothing. All verified on git
2.55.0.windows.2, 2026-09-10.

- **A trailing `/` is required.** `gitdir:C:/Repos/Personal/` matches the
  root and everything beneath it; `gitdir:C:/Repos/Personal` — same path,
  no slash — matches **nothing at all**, including the directory itself.
  Git appends `**` only to a pattern that ends in `/`. Writing `/**`
  explicitly works and is the same thing.
- **`gitdir:` is case-sensitive, and that includes the drive letter.**
  `c:/Repos/...` against a `C:` path matches nothing. Use `gitdir/i:`
  unless you have a reason not to; it fixes drive-letter and directory
  case together.
- **An 8.3 short path never matches.** Git compares against the resolved
  long path (`git rev-parse --absolute-git-dir`), so a pattern built from
  `C:/Users/RUNNER~1/...` is dead on arrival. Build patterns from the
  long form.
- **Later wins.** Includes are applied in file order and a second one
  overrides the first, so two roots that overlap resolve to whichever is
  written last, with nothing to indicate it.

There is no error path for any of these. The include simply does not
apply, `useConfigOnly` then refuses the commit, and the message points at
the identity rather than at the pattern that failed to match.

## `git config --global user.email` is the wrong command here

It does not edit the included file. It writes `email` into `~/.gitconfig`
*above* the `includeIf`, so inside a configured root the included value
still wins and **the command appears to have done nothing** — reading
the value back returns the old one. What it actually did is plant a
machine-wide default that now applies in every repo outside every root,
which is precisely what `useConfigOnly` exists to prevent. Measured
2026-09-10.

Read the truth back with origins rather than trusting a bare read:

```bash
git config --show-origin --get-all user.email
git rev-parse --absolute-git-dir     # what the includeIf is matched against
```

Two values listed means an include is layered over a base entry — in a
correctly shaped config the base entry should not exist.

## Line endings live here, policy does not

`core.autocrlf = false` belongs in the base config, and the actual
line-ending policy belongs in each repo's committed `.gitattributes`
instead. A global `autocrlf = true` rewrites every checkout on a machine
according to one person's platform, which is not a property the repo can
see or review. Setting it per repo, in a file everyone clones, is.

## What does not belong in any of these files

- **An organization's account names** — Entra or `AzureAD` accounts,
  tenant names, internal hostnames. A machine-setup repo's git configs
  are exactly where these get written as subject matter rather than as a
  leak. Use a placeholder and let the setup script substitute it.
- **A token.** Credential helpers hold credentials; a config file that
  contains one has published it to every clone and every backup.
- **The GitHub API actor.** `gh` and an MCP GitHub server authenticate
  from their own tokens and can resolve to a *different* account than the
  `includeIf` author on the commits, with nothing warning that a PR
  landed under the wrong identity. Nothing in this file influences that —
  confirm it separately with `gh api user -q .login` before opening or
  merging anything.
