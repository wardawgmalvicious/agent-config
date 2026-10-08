# Handoff: fold the Copilot and reviewer items into their open briefs

- **Audit run**: 2026-10-08
- **Source**: `prompt-audit`
- **Window**: floor none, the whole payload → head `c268691`
  (2026-10-08)
- **Covers recommended actions**: findings 17, 18 and 24, and decision 2
- **Kind**: edits to two open handoff briefs. No payload changes: each
  item lands when its brief is worked.
- **Target**: `docs/handoffs/execute/copilot-payload-retirement.md`,
  `docs/handoffs/execute/security-reviewer-blind-retest.md`

## The problem

Four items belong to work already briefed. Fixing them in the payload
now would collide with those briefs, which rewrite the same passages.

## Evidence and where each goes

Quotes are the report's, at `c268691`.

| Item | Location | Says | Goes to |
| --- | --- | --- | --- |
| finding 17 | root `CLAUDE.md:49-50` | the two `copy-copilot.ps1` command lines, read as routine | `copilot-payload-retirement.md`: the freeze in `.claude/rules/copilot-payload.md:60-64` loads only on a Read under `copilot/`, while root loads every session, so the retirement marks or removes the lines |
| finding 18 | `claude/CLAUDE.md:179` | heading "GitHub Copilot no longer inherits this payload" | `copilot-payload-retirement.md:427`, which already plans this section's rewrite; the ledger heading at `docs/evidence/user-claude-md.md:996` moves with it |
| decision 2 | `claude/rules/vscode-scoping.md:61-64` against `claude/CLAUDE.md:181-182` | the rule says plain Copilot inherits `~/.claude`; the global file says it never reads it, which the ledger (`user-claude-md.md:1029-1034`) shows is false for one profile | `copilot-payload-retirement.md`, settled with the retirement |
| finding 24 | `claude/agents/security-reviewer.md:16` | "the `mode` parameter that used to pin it…" | `security-reviewer-blind-retest.md`, whose retest covers an edit to the agent |

The patch's hunks for `CLAUDE.md` (finding 17), `claude/CLAUDE.md` and
`docs/evidence/user-claude-md.md` (finding 18) and
`claude/agents/security-reviewer.md` (finding 24) are starting points
for whoever works those briefs, not for this one.

## State when written

A `/triage` of a prompt audit run in a client repo against the same
user-scope payload committed folds to both target briefs on 2026-10-08,
in `566973a`:

- Finding 18: `copilot-payload-retirement.md` now retitles the heading
  without "no longer". Already-applied.
- Finding 24: `security-reviewer-blind-retest.md` § "D-3" moves the
  `permissionMode` paragraph that finding 24 quotes. Confirm it covers
  the "used to pin" sentence; if so, already-applied.
- Decision 2: the retirement brief now carries a client repo's
  `AGENTS.md` set against `vscode-scoping.md` and `claude/CLAUDE.md`.
  That is close to decision 2 but not the same pair, the rule against
  the global file, so fold decision 2 beside it unless that fold
  already settles it.
- Finding 17: not folded. The client audit could not see root
  `CLAUDE.md`, which is project scope here.

Re-read both briefs at `HEAD` before folding.

## Verification

1. Each item above appears in its target brief exactly once.
2. `uv run scripts/handoff-status.py . --check --no-inbox`.
3. `pre-commit run --all-files`.

## Provenance

Findings 17, 18 and 24 and decision 2, all medium confidence, from
`/doctor prompt-audit` run in this repo on 2026-10-08. The report
itself routes finding 18 and decision 2 to the retirement brief; the
user took the same route for finding 17 that day.
