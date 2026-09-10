# This repo's own maintenance skills

Seven skills that operate on `agent-config` itself. They live here at
**project scope** rather than in [skills/](../../skills/), and the
distinction is not filing — it is what the two directories mean.

`skills/` is **payload**: content deployed elsewhere, by
`scripts/link-claude.ps1` into `~/.claude/skills` as one junction per
skill, or by `scripts/copy-copilot.ps1` into a client repo's
`.github/skills` as committed files. These seven are not payload. Their
whole subject is this repo's own structure — its groups, its linter, its
handoff queue, its audit ledger — so outside this working tree they have
nothing to act on.

They were at user scope until 2026-09-09, which meant every session on
this machine carried them in its startup listing, including client-repo
sessions where they could only ever be noise. A `description` is the
entire trigger mechanism and the listing has a budget, so that cost was
real and paid in the wrong place.

Being here means:

- **No script touches them.** Both deploy scripts select out of
  `skills/`, so neither can see this directory. Neither needed changing
  when these moved.
- **They are live on save, for sessions in this repo only.** No junction
  and no copy step — Claude Code reads them in place. Blast radius is
  one working tree instead of the machine.
- **`.gitignore` carries `!/.claude/skills/`** to keep them tracked
  against the `/.claude/*` runtime-state exclusion, and the pre-commit
  skills hook has a second depth-pinned arm for this tree. Both are load
  bearing: without the first they would be silently untracked, without
  the second silently unlinted.
- **A name collision with `skills/` is guarded, because it would
  otherwise be silent.** User scope outranks project scope, so
  re-creating one of these names under `skills/` shadows the copy here:
  no conflict, no warning, and the only symptom is a skill behaving like
  an older version of itself. `scripts/lint-skill-scopes.py` fails the
  commit on it, and on a duplicate across `skills/` groups. Neither
  deploy script can see the first case — `link-claude.ps1` never reads
  this directory, correctly, since nothing here deploys.

`/commit` and `/code-review` are the two that stayed in
[skills/workflow/](../../skills/workflow/): both are useful in any repo,
so both remain deployable.

## The skills

- [author-skill/](author-skill/) — author a new skill for this repo end
  to end: coverage check, name and namespace, doc drilling, a filled
  handoff brief in [docs/handoffs/](../../docs/handoffs/), then
  the `SKILL.md` draft and the post-draft checks. Ends at a linted draft
  plus a fresh-session test plan — no fixtures, no commit. Deliberately
  overlaps the loaded `skill-creator` and `plugin-dev:skill-development`
  plugin skills, which know the Agent Skills format but not this repo's
  naming rules, `references/` split, lint command, or brief-before-draft
  discipline. Named for the verb you invoke, and kept distinct from
  `skill-creator` in trigger matching.
- [test-skill/](test-skill/) — the second half of `/author-skill`: write
  a drafted skill's trigger fixtures, update the
  `expected_activations.md` contract, run the static and real-path
  activation tests, then check behaviour in a cold session against a
  `--safe-mode` baseline. Named as the verb you invoke, and paired with
  `author-skill` deliberately — that skill stops at a linted draft and
  writes no fixtures, so nothing validated a new skill until this one
  existed. Reads the handoff brief from disk rather than from session
  context, so it runs cold like `/drift-update` instead of depending on
  the authoring run. Skills only; subagents and hooks keep the manual
  procedure in [tests/](../../tests/).
- [learn/](learn/) — "learn!": capture a session learning into the
  skill / rule / CLAUDE.md that should have covered it. Auto-detects
  which guidance was in use, checks existing coverage, verifies against
  docs, proposes a diff for approval, hands off to `/commit`.
- [drift-audit/](drift-audit/) — audit registered upstream docs sources
  for skill staleness, drift in existing skills, new-skill candidates,
  and MCP/tooling additions. Findings only — no edits. Sources are a
  registry ([references/sources.md](drift-audit/references/sources.md)),
  not a hardcoded list — Fabric and Power BI What's New today, and
  widening the audit to another domain is an entry there plus a
  validated run. Named for the job, not the target: it audits rules,
  `CLAUDE.md`, and the MCP templates too, so `skill-audit` would name a
  quarter of its scope and would collide with a plausible future skill
  that actually audits skill quality.
- [drift-handoff/](drift-handoff/) — the write half of `/drift-audit`:
  turn its report into `docs/audits/<date>/<source-id>/`, holding
  the report verbatim plus one brief per recommended action, grouped by
  shared verification steps. Split from `drift-audit` so the turn doing
  the analysis has no write capability; runs inline because it reads the
  report out of the current conversation. Only recommended actions
  become briefs — everything else stays conversational.
- [drift-update/](drift-update/) — the third turn: execute the briefs
  `/drift-handoff` left on disk. Walks them in numbered order with a
  checkpoint each — confirm the quoted evidence still exists, apply,
  run the brief's own verification, stamp an execution log — and stops
  on the first failure. Briefs whose `Kind` is a decision rather than
  an edit are escalated, never executed. Reads briefs from disk and
  never from the conversation, which is what keeps `drift-handoff`'s
  cold-read contract honest: a brief that can't be executed without
  opening the audit report is reported as a brief-format defect.
- [land/](land/) — the step after `/commit`: push the branch, verify
  which GitHub account is actually authenticated, open the PR through
  `github-mcp`, then fast-forward `main` and check CI. Stops for
  confirmation before the push to `main`, the one irreversible step.
  Named `land` because root [CLAUDE.md](../../CLAUDE.md) already says to
  "land a branch locally rather than through the merge button" — the
  repo's own vocabulary. Earns its place because two steps fail
  *silently*: `gh` and `github-mcp` can authenticate as different
  accounts, so a PR lands under the wrong identity with no error.

  `land` is here for a **different reason from the other six**, and is
  the one most likely to be moved back. It is not repo-specific — any
  repo has branches to land. It is *dependency*-specific: it is built on
  `github-mcp` throughout, and that server is project scope here, so a
  user-scope listing was advertising it in sessions whose tools could
  not run it. It is also acknowledged as unpolished and seldom used.
  Project scope is where its tools actually are; polish it before
  promoting it.
