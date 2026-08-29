# Docs

Internal documentation for the repo's authoring workflow.

## Layout

- [handoff-briefs/](handoff-briefs/) — templates, worked examples, and
  pending briefs for the brief-before-draft pattern used to author
  skills and subagents. A filled brief lives here until the work lands,
  then is deleted. See
  [Handoff discipline](../README.md#handoff-discipline) in the
  top-level README for context.
- [project-CLAUDE-template.md](project-CLAUDE-template.md) — fill-in
  starter for a project-scope `CLAUDE.md` in client/project repos.
  The content is tool-neutral, so it serves equally as an `AGENTS.md`
  for a repo whose tooling reads that instead.

Two further directories are gitignored and not part of the public repo:

- `project-instructions/` — the author's personal Claude Desktop project
  instructions (easier to edit here and paste into Desktop).
- `drift-audit/` — generated `/drift-audit` output, one directory per
  run at `drift-audit/<audit-date>/<source-id>/`, holding the audit
  report plus a brief per recommended action. Working notes with a short
  half-life: consumed by a follow-up task, then stale. A run worth
  keeping gets copied into `handoff-briefs/examples/` rather than
  un-ignored in place.
