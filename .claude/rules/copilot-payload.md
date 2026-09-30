---
paths:
  - "copilot/**"
  - "scripts/copy-copilot.ps1"
  - "scripts/lint-instructions.py"
  - "scripts/payload-coverage.py"
---

# The Copilot payload

- `scripts/copy-copilot.ps1` is the only route from this repo to GitHub
  Copilot, in a clone and on this machine: since 2026-09-09 every
  `chat.*Locations` entry naming a Claude root is `false`, so Copilot reads
  `.github/*` and `~/.copilot/*`, plus `CLAUDE.md` only in a profile that
  sets `chat.useClaudeMdFile`. Which profile sets what is machine state: the
  ledger has the history, and `~/.claude/rules/vscode-scoping.md` has the
  traps in those `chat.*` settings. Beyond `copy-copilot.ps1` and
  `lint-instructions.py`, Copilot wiring is not maintained here, and Copilot
  never writes here: its learnings arrive through the handoff inbox.
- `copilot/` is payload for other repos and is never read here: hand-made
  `*.instructions.md` ports of `claude/rules/`, each carrying an `applyTo`
  glob string, because `applyTo` and `paths:` are not interchangeable.
  Through it a rule keeps its globs, as `applyTo`; Copilot honours `paths:`
  too, in the Claude Rules format (`**` when absent), so a rule stays
  conditional where a skill does not (2026-09-09).
- A port names another file as a code span, never a Markdown link: under
  `chat.includeReferencedInstructions` a link from an applied instructions
  file loads its target in full, and a profile or a repo can turn that on
  without the port knowing (`~/.claude/rules/vscode-scoping.md`,
  2026-09-26).
- Ports drift, so `scripts/lint-instructions.py` gates them in pre-commit:
  `applyTo` must be one comma-separated string (a list parses, then matches
  nothing), no personal-repo name or profile path may leak, no relative
  link may ship, and a rule edit fails until its hash is re-recorded with
  `--stamp`.
  `copilot/.source-hashes.json` lists the rules deliberately not ported, so
  a new rule surfaces as a decision rather than an omission.
- A vendored skill loses `paths:` and `effort:`, which Copilot warns about
  and ignores, so a conditional skill is unconditional there; an active
  `model:` breaks its slash dispatch outright (`editing-skills.md`). No hook
  reaches Copilot: it reads Claude's hook format but ignores matchers, which
  once ran the `security-reviewer` write guard far wider, and
  `chat.hookFilesLocations` is `false` everywhere.
- A group carrying a `.no-copilot` marker (`skills/meta/`) is skipped on
  every run, bare included, and refused by name if requested.
  `lint-frontmatter.py` reads the same file to allow an active `model:`, so
  the exclusion and the exemption cannot drift apart.
- `-Payload skills|instructions` leaves an omitted payload alone, while
  `-SkillGroups` prunes an omitted group. Each payload tracks what it
  deployed in its own manifest and prunes only that; a collision it did not
  create is skipped unless `-Force` adopts it.
- A repo target gets only the ports whose `applyTo` matches one of its
  tracked files, less the target's own `skills/` and `instructions/`, and
  `~/.copilot` gets every one: VS Code lists each available instructions
  file in every agent request, matched or not (2026-09-26). A held port the
  manifest owns is pruned. The matching is `payload-coverage.py --ports`,
  called through `uv`, so a missing `uv` or a failed call stops the run
  rather than shipping every port; `-AllInstructions` does that on purpose.
  `bash tests/scripts/copy-copilot/test-port-selection.sh` is its test.
- `~/.copilot` takes `workflow` only, never `social`. **The payload is
  frozen until it is removed** (2026-09-30): no port is redone and no copy
  refreshed after an edit, in `~/.copilot` or in a repo, since the user
  decided to retire it
  (`docs/handoffs/execute/copilot-payload-retirement.md`).
