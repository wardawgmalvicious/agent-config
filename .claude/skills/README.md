# This repo's own maintenance skills

Five skills that operate on `agent-config` itself. They live here at
**project scope** rather than in [skills/](../../skills/), and the
distinction is not filing — it is what the two directories mean.

`skills/` is **payload**: content deployed elsewhere, by
`scripts/link-claude.ps1` into `~/.claude/skills` as one junction per
skill, or by `scripts/copy-copilot.ps1` into a client repo's
`.github/skills` as committed files. These five are not payload. Their
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

The deployed groups are the counter-case: useful in any repo, so
deployable. `/commit` and `/code-review` never left
[skills/workflow/](../../skills/workflow/); `/land` came back to it and
`/learn` left for [skills/meta/](../../skills/meta/), for which see the
last section.

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
  the analysis has no reason to write; runs inline because it reads the
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

## The two that left

`land` was here too, and **moved back to
[skills/workflow/](../../skills/workflow/land/) on 2026-09-13** — the
move this file predicted. The reason recorded for demoting it did not
survive checking: it was said to be built on `github-mcp`, which is
project scope, so a user-scope listing advertised it where its tools
could not run. But client repos declare `github-mcp` in their own
`.mcp.json` too, the skill treats a confirmed `gh` as a first-class
route rather than a fallback, and its only real use was in a client
repo ten hours before the demotion. Project scope put it in the one
repo whose convention is to commit straight to `main` and never open a
PR, and removed it from the repos that do. The dependency argument does
not apply to it.

`learn` **moved to [skills/meta/](../../skills/meta/learn/) on
2026-09-15**, and its demotion was the more costly mistake of the two,
because the thing it broke is silent. `learn` was filed here on the
reasoning that its *destination* is this repo's payload. True, and
beside the point: a learning is produced wherever the problem was hit,
which is usually a client repo, and project scope meant `/learn` was
not in that session's listing at all. Nothing reports a learning that
was never captured. The evidence is
`~/handoff-inbox/2026-09-15-kusto-streaming-and-warehouse-git-serialization.md`,
nine Fabric learnings whose preamble diagnoses it directly: "`/learn`
is project scope and fires only in sessions inside `agent-config`. This
arrived from a client repo."

It is payload now because it carries a **mode split** rather than a
repo assumption — edit mode inside this checkout, note mode everywhere
else, writing to `~/handoff-inbox/` instead of editing. It went to a new
`skills/meta/` group rather than `workflow/` because its subject is the
agent payload rather than the user's repo — the same subject as the five
here, differing only in needing to run everywhere. The group's
`.no-copilot` marker is what lets it **keep** its `model: fable` pin as
deployed payload.

**The general lesson for this directory**, paid for twice: the test for
project scope is *where the skill runs*, not *where its output lands*.
`land` was filed here for its dependency and `learn` for its
destination; both were reasons that a skill's own body, not its scope,
should answer. The remaining five act on this working tree's structure
— its groups, its linter, its queue, its ledger — which is the only
thing that has held.
