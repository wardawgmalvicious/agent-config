# Handoff: why does a clean room never activate a conditional skill?

- **Written**: 2026-09-01, from the wave 4 A1 verification.
- **Kind**: investigation. No edit is known to be needed — the outcome may
  be "documented harness limitation" rather than a fix.
- **Status**: open. **Blocks the design of
  [activation-test-harness.md](activation-test-harness.md)**, which wants
  to run in exactly the configuration that failed here.
- **Run in**: a fresh session. Everything needed is below; the session
  that found it is not required.
- **Queue**: [README.md](README.md) has the order.

## The observation

Closing A1 needed a cold session with the `powerbi` skill group deployed
(this machine prunes to `workflow` only, so the platform skills are not in
`~/.claude/skills` and cannot activate anywhere). Two configurations were
tried. They disagree, and only one of them works.

| Configuration | Skills deployed | Rule loaded? | Skill activated? |
| --- | --- | --- | --- |
| **In-repo** — `agent-config/.claude/skills`, cwd = the repo | 12 project skills, 7 conditional | yes | **yes** |
| **Clean room** — a scratch dir outside any repo, cwd = that dir | same 12, same 7 conditional | **no** | **no** |

The in-repo runs produced the expected `skill_listing` attachment with
`isInitial: false` — `['pbip-project-structure']` on a manifest,
`['pbir-conditional-formatting', 'pbir-filters', 'pbir-visual-json']` on
`visual.json`. The clean room produced **no such attachment on any run**,
and no `fabric-git-serialization` load either, despite that rule being
user-scope and therefore present in both.

Both configurations were confirmed to have discovered the skills: the
debug log reports `7 conditional skills stored (activated when matching
files are touched)` and `project: 12` in each. So this is not a discovery
failure. Something between discovery and matching differs.

## Ruled out

Each of these was tested, not reasoned about:

- **`skillOverrides`.** The repo's `.claude/settings.json` collapses all
  37 platform skills to `name-only`; the clean room has no settings file.
  That is the wrong direction — the *overridden* configuration is the one
  that worked.
- **Being a git repo.** `git init` in the clean room changed nothing.
- **The 8.3 short path.** The first clean-room runs used a `EXAMPL~1` cwd;
  re-running with the full `exampleuser` path changed nothing.
- **Project vs user scope.** The in-repo positive was itself a
  *project*-scope deploy, so project scope activates fine.
- **Print vs interactive.** The in-repo positive was a `claude -p` run.

## Hypotheses not yet tested

Roughly in order of cheapness:

1. **The fixture path.** The clean room read `fixtures/…`; the repo read
   `tests/skills/pbip-triggers/fixtures/…`. Both should match `**/*.pbir`,
   but the matcher may key on something about the path's relationship to
   the project root rather than the path itself. Cheapest test: copy the
   fixtures into the clean room at the *same* relative depth as the repo
   and re-probe.
2. **Trust.** Claude Code prompts for trust on a new directory. A
   `claude -p` run in an untrusted directory may silently disable
   file-triggered loading. Test: check whether the clean room appears in
   the trust store, trust it explicitly, re-probe.
3. **A temp-directory exclusion.** The clean room was under
   `AppData/Local/Temp`. Test: repeat under `C:\Repos\scratch-activation`
   instead — outside both a repo and temp.
4. **The junctions.** `link-claude.ps1` creates directory junctions into
   this repo. Both configurations used them, so this is unlikely, but a
   copy rather than a junction is a cheap control.

## Why it matters

Not for A1 — that is closed on the in-repo positive. It matters because
the obvious way to build a repeatable activation test is a disposable
scratch directory, and **that is the configuration that silently reports
"nothing activated" for every fixture**. A harness built on it would pass
a broken glob and fail a correct one identically. Resolve this, or design
the harness to run in-repo and prove it.

It also matters as a claim about the payload: if some directory property
switches off `paths:` loading, that is a fact about when this repo's
skills and rules work at all, and belongs in `CLAUDE.md`.

## How to observe

Do **not** read a counter, and do **not** ask the session what it can see
— both were tried and neither works (self-report varied across identical
runs). Grep the session transcript at
`~/.claude/projects/<project-slug>/<session-id>.jsonl` for an attachment
whose `type` is `skill_listing` with `isInitial` **false**. Full method in
[`../../../tests/skills/pbip-triggers/README.md`](../../../tests/skills/pbip-triggers/README.md).

## Done when

Either the clean room activates and the difference is named, or the
failure is reproduced, understood and written into `CLAUDE.md` as a
constraint on where `paths:` loading works. A third acceptable outcome:
bounded and handed upstream as a bug report, with the harness pinned to
in-repo runs.
