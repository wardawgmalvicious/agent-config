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

- [audits/](audits/) — `/drift-audit` output, one directory per run at
  `audits/<audit-date>/<source-id>/`, holding the audit report verbatim
  plus a brief per recommended action. Tracked and kept: each directory
  is the dated record of what an upstream source looked like that day.
  See [audits/README.md](audits/README.md) for the lifecycle.

One directory is gitignored and not part of the public repo:

- `project-instructions/` — the author's personal Claude Desktop project
  instructions (easier to edit here and paste into Desktop).

`handoffs/` and `audits/` **both hold handoff briefs** — the split
between them is lifecycle, not kind. A `handoffs/execute/` brief is a
queue row: hand-derived, committed when written, and deleted
individually once its work lands, because a spent row invites redoing
finished work. An `audits/` directory is a ledger entry:
machine-generated, executed as a whole, and kept in place afterwards,
because the date is the index and the snapshot outlives the execution.
Renamed from `handoff-briefs/` and `drift-audit/` on 2026-09-02;
`audits/` became tracked on 2026-09-07.
