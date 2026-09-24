---
paths:
  - "copilot/**"
  - "scripts/copy-copilot.ps1"
  - "scripts/lint-instructions.py"
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
- Ports drift, so `scripts/lint-instructions.py` gates them in pre-commit:
  `applyTo` must be one comma-separated string (a list parses, then matches
  nothing), no personal-repo name or profile path may leak, and a rule edit
  fails until its port is redone and re-recorded with `--stamp`.
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
- `~/.copilot` takes `workflow` only, never `social`. Copies are not live:
  re-run after editing a `skills/workflow/` skill or a ported rule.
