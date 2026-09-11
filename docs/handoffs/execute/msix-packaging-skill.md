# Handoff: MSIX packaging skill

- **Written**: 2026-09-10, as the remainder of the C# rules brief once
  its two rules shipped. That brief proposed three artifacts;
  [coding-csharp.md](../../../claude/rules/coding-csharp.md) and
  [coding-xaml.md](../../../claude/rules/coding-xaml.md) are the first
  two, and this is the third.
- **Kind**: one skill, authored through `/author-skill`. Nothing is
  drafted and nothing is drilled.
- **Status**: **open, written 2026-09-10.**
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## Why a skill and not a rule

Packaging is a procedure with an ordering and failure modes: sign,
version, build the package, publish the `.appinstaller`, then update.
That is skill-shaped. A rule fires on a file and states conventions, and
there is no convention to state about a manifest in the abstract — only
steps to get right in sequence. The rules brief said the same thing and
kept this out of `paths:`-scoped rule form for that reason.

Whether the skill itself should carry a `paths:` glob is open, and
`/author-skill` decides it. A glob on `**/*.appxmanifest` and
`**/*.appinstaller` would make it conditional, which withholds it from
the startup listing and makes the path its only cold entry. A packaging
request usually arrives as words ("publish a new version"), not as a
manifest being read, so an unconditional description may be the better
trigger. Measure, don't assume.

## What is uncovered

After the two rules landed, the reference WinUI repo went from 2% to 80%
covered (`payload-coverage.py`, 2026-09-10). Of the 41 files still
uncovered, these are packaging surfaces:

| Extension | Files |
| --- | --- |
| `.appxmanifest` | 1 |
| `.appinstaller` | 1 |
| `.manifest` | 1 |
| `.resw` | 1 |
| `.sln` | 1 |

The rest is app config (`.json`), a `.csv`, and repo dotfiles, none of
which want a rule. Re-derive before starting:

```bash
uv run --with pyyaml --with wcmatch python scripts/payload-coverage.py \
    <repo-root>
```

## Context, not the definition

The reference repo is self-contained WinUI 3 on the Windows App SDK
(`net10.0-windows10.0.19041.0`) and ships through an `.appinstaller`.
That is one repo and one distribution channel. A skill built around it
would be wrong for Store submission or an unpackaged app, so the drill
covers the channels, and the reference repo is only a test case.

Sources to drill: Learn's MSIX and App Installer docs, the Windows App
SDK deployment guide (packaged vs unpackaged, framework-dependent vs
self-contained), and signing.

## Carried from the rules brief, still unactioned

Reading the reference repo's four `.csproj` files on 2026-09-10 turned up
three findings that are **code-review findings for that repo, not
payload content**. A rule stating them would be false everywhere else.
They are recorded here only so they are not lost with the rules brief:

- Two packages referenced at different versions across projects, which
  central package management would collapse.
- `Platforms` disagreeing three ways across four projects.
- Two generations of the Windows Community Toolkit in one app (the
  WinUI-2-era `CommunityToolkit.WinUI.UI.Controls` 7.x beside 8.x
  controls).

The platforms disagreement is the one that bears on packaging, since the
package architecture is chosen from it.

## Constraint: this repo is public and the client name is denylisted

The reference repo's name and path are on
`~/.config/identity-denylist.txt`, so `identity-guard` blocks a commit
that adds either — which is why this brief says "the reference WinUI
repo" throughout. Package versions, target frameworks and file
extensions are public facts and are fine. The skill itself must not name
the repo either: it loads into every repo, and a client's name in it
would be both a leak and wrong everywhere else.
