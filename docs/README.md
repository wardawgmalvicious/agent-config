# Docs

Internal documentation for the repo's authoring workflow.

## Layout

- [handoffs/](handoffs/) — templates, worked examples, and pending
  briefs for the brief-before-draft pattern used to author skills and
  subagents. A filled brief lives here until the work lands, then is
  deleted. See [Handoff discipline](../README.md#handoff-discipline) in
  the top-level README for context.
- [social/](social/) — the GitHub social preview card: its HTML source,
  the rendered 1280x640 PNG, and how to re-render it. GitHub does not
  read the file from here; the card is uploaded by hand under
  **Settings → General → Social preview**, so a re-render is only half
  the job.
- [project-CLAUDE-template.md](project-CLAUDE-template.md) — fill-in
  starter for a project-scope `CLAUDE.md` in client/project repos.
  The content is tool-neutral, so it serves equally as an `AGENTS.md`
  for a repo whose tooling reads that instead.

Two further directories are gitignored and not part of the public repo:

- `project-instructions/` — the author's personal Claude Desktop project
  instructions (easier to edit here and paste into Desktop).
- `audits/` — generated `/drift-audit` output, one directory per run at
  `audits/<audit-date>/<source-id>/`, holding the audit report plus a
  brief per recommended action. Working notes with a short half-life:
  consumed by a follow-up task, then stale. A run worth keeping gets
  copied into `handoffs/examples/` rather than un-ignored in place.

`handoffs/` and `audits/` **both hold handoff briefs** — the split
between them is lifecycle, not kind. A `handoffs/execute/` brief is
hand-derived, committed when written, and deleted individually once its
work lands; an `audits/` directory is machine-generated, disposable as a
whole, and regenerable by re-running the audit. Renamed from
`handoff-briefs/` and `drift-audit/` on 2026-09-02.
