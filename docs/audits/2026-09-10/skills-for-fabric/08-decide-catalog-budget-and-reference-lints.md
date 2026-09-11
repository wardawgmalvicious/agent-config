# Handoff: decide on a catalog-wide listing-budget check and a cross-skill reference lint

- **Audit run**: 2026-09-10
- **Source**: `skills-for-fabric`
- **Window**: floor `2026-08-06` (diff base `912e06e0`) → head `65902bae`
  (2026-09-04)
- **Covers recommended actions**: 9 (first half)
- **Kind**: **decision**, then possibly new lint code in `scripts/` wired
  into pre-commit. Changes no skill.
- **Target** (if accepted): `scripts/lint-skill-scopes.py` or a new
  `scripts/*.py`, and `.pre-commit-config.yaml`

## The problem

Upstream hit three catalog-scale failures in 0.3.14 that this repo's
checks would not catch: a catalog close enough to the startup listing
budget that later skills risked being known by name only, descriptions
that lost the literal words users type, and skills pointing at skills
that had been merged away. `lint-frontmatter.py` caps each skill on its
own. Nothing here measures the whole catalog, and nothing checks that a
skill named in another skill's body still exists.

## Evidence

Upstream, `CHANGELOG.md` `[0.3.14] - 2026-08-26` (release commit
`99de3299`), verbatim:

> **The full skill catalog fits comfortably within what the assistant
> reads at startup.** Only each skill's name and description are loaded
> up front, and that space is limited. The catalog previously ran close
> enough to the limit that adding skills risked pushing later ones past
> it -- and a skill past the limit is known only by its name, so the
> assistant can no longer tell what it does and chooses between skills
> on the name alone. The descriptions are now about 40% shorter with no
> loss of routing accuracy, leaving room for the catalog to grow.

> **`activator-cli`, `sqldw-cli` and `variable-library-cli`** -- these
> skills pointed you at skills that no longer exist. ... Handing work to
> a name that is not installed left the request stranded.

and, from the literal-tokens fix:

> ... every description still inside the 450-character cap, for 361
> characters against roughly 3,850 of bundle headroom.

Upstream's own check — a 0.3.11 bullet that `af9aff33` removed from the
public changelog on 2026-08-06, so it is visible only in that commit's
patch:

> **Catalog-total startup-metadata check** -- `quality_checker.py` now
> measures the whole catalog's startup metadata (name + description, the
> only parts loaded at startup) against the runtime budget. The existing
> per-skill 1023-character cap cannot protect the catalog on its own.
> The check is a ratchet: it fails on regression past `STARTUP_CEILING`
> and warns otherwise.

This repo:

- `scripts/lint-frontmatter.py` lines 46–48 — `DESCRIPTION_MAX = 1024`,
  `WHEN_TO_USE_MAX = 512`, `LISTING_MAX = 1536` — all per skill.
- `scripts/lint-skill-scopes.py` already runs over the whole skill set;
  its docstring says it "checks the whole set at once rather than a
  changed file". That is the natural home for a whole-catalog measure.
- No cross-skill reference check exists. The only "dangling" logic in
  `scripts/` is junction handling in `link-claude.ps1` (line 536).

## Open questions

- **What is the real budget?** Upstream's figures are for its own
  runtime, GitHub Copilot CLI first. Claude Code's listing budget has to
  come from Claude Code's docs (`code.claude.com/docs/en/skills`) or the
  `claude-code-guide` agent. Do not reuse upstream's numbers.
- **Which catalog?** On this machine the workflow-only prune lists a
  handful of skills, but a client repo with the `fabric` group deployed
  lists 41 more. Measure per deployable group combination, or the worst
  case.
- **What counts as a reference?** Backticked skill names in `See also`
  bullets and in prose ("the **fabric-spark skill**"). Name-shaped tokens
  that are not skills — the `fabric-cicd` *library* against the
  `fabric-cicd` skill — will produce false positives. Settle the matching
  rule before writing the lint.

## Verification (if accepted)

1. A fixture with a deliberately dangling reference fails the lint, and
   the current tree passes.
2. The budget check prints the measured total and cites where its
   ceiling came from.
3. `pre-commit run --all-files`, and
   `pre-commit run <new-hook> --files <path-that-must-match>` shows
   `Passed`, not `Skipped` — a `files:` pattern that misses reports
   success.

## Sequencing note

Split from brief 09 although the report puts both in one action. This
one is lint code verified by fixtures; 09 is a routing probe verified in
a cold session. Different verification, different risk.

## Provenance

First `/drift-audit --sources skills-for-fabric` run, 2026-09-10, reading
bucket (c) as the registry asks even when nothing maps: upstream hits
these failures at a larger catalog size first, so its changelog is an
early warning for this payload's own mechanics.

## Execution log

- **Executed**: 2026-09-11 — escalated
- **Session**: fresh (the audit report was in context via the
  invocation's @-mention; no audit or handoff ran in the session)
- **Files changed**: none
- **Verification**: none run. This is a decision brief, and
  `/drift-update` does not execute those.
- **Decision**: **queue both** the catalog-wide listing-budget check
  and the cross-skill reference lint, as their own task. That task
  settles the three open questions first: the real budget comes from
  Claude Code's docs, not upstream's numbers; the budget is measured per
  deployable group combination or at the worst case; and the reference
  matching rule is fixed before any code is written.
- **Deferred**: the open questions and all three verification steps.
- **Deviations**: none.
