# Skill handoff brief: drift-handoff

Last verified: 2026-08-29

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

Personal scope, deployed via the existing `skills/` junction:

- Repo: `skills/drift-handoff/SKILL.md`
- Deployed: `~/.claude/skills/drift-handoff/SKILL.md`

No new linking step — `scripts/link-claude.ps1` already junctions
`skills/` wholesale.

## Scope

Turns a completed `/drift-audit` report into files on disk. It reads the
report from the current conversation, writes it verbatim as
`00-audit-report.md`, and writes one brief per **recommended action**
into `docs/drift-audit/<audit-date>/<source-id>/`. Findings that did not
reach the Recommended actions list stay conversational and are not
written — that boundary is the skill's main editorial rule.

It exists to hold a boundary that `drift-audit` cannot hold alone.
`drift-audit` is explicitly read-only, and its own body says the prose is
the only enforcement. Adding `Write` to it would put write capability
into the one turn actively reasoning about which artifacts need
changing. Splitting removes that pairing: the audit turn has no write
capability, and this turn has no analysis pressure — it transcribes
decisions already made into new files in a gitignored directory.

Inline, model-invocable, not path-scoped.

## Frontmatter

```yaml
---
name: drift-handoff  # required; max 64 chars; lowercase letters/numbers/hyphens; forbidden words "anthropic"/"claude"
description: Turn a completed drift-audit report into handoff briefs on disk. Use immediately after a /drift-audit run, or when the user asks to prepare handoffs, write up the findings, or capture the recommended actions from an audit. Writes one directory per run — docs/drift-audit/<audit-date>/<source-id>/ — holding the audit report verbatim as 00-audit-report.md plus one numbered brief per recommended action, grouped so each brief covers a single kind of work with its own verification steps. Only recommended actions become briefs; every other finding stays a conversational read-through. Runs inline and reads the report from the current session, so it cannot reconstruct an audit it did not see.  # required; keep under 1,024 chars
argument-hint: "[source-id]"  # optional; autocomplete display hint shown in / menu
allowed-tools: Read Write Glob Grep  # deliberately no Edit — this skill only creates new files
model: inherit
context: inline  # MUST stay inline; a fork loses the conversation holding the report
---
```

Note the two deliberate omissions. **No `Edit`** — the skill creates
files and never modifies existing ones, so `Edit` would only widen blast
radius for no capability gained. **No `context: fork`** — see Portability
caveats.

## Description char count

Approximately 720 / 1,024 portable cap. Re-count after drafting; the
draft above is indicative, not final.

## Body structure outline

1. **Preconditions** — refuse if no `/drift-audit` report is present in
   the conversation. State plainly that the skill cannot reconstruct one
   and that the user should run `/drift-audit` first. Do not guess at
   findings from a summary or from memory of a prior session.
2. **Resolve the target directory** — `docs/drift-audit/<audit-date>/<source-id>/`,
   where `<audit-date>` is the date the audit ran and `<source-id>` is
   the registry id. Multiple sources in one run get sibling directories.
   Create with `mkdir -p`; never overwrite an existing directory's files
   without reading them first.
3. **Persist the report** — write the audit report verbatim as
   `00-audit-report.md`. Verbatim matters: the briefs cite it, and a
   re-summarized report loses the evidence that justified each finding.
4. **Group recommended actions into briefs** — one brief per *kind of
   work*, not per numbered action. Two actions correcting prose in the
   same files are one brief; two actions changing fetch behavior are
   another. The test: do they share verification steps? If yes, one
   brief. Number files `01-`, `02-`, … with a kebab-case slug.
5. **Brief contents** — each carries: audit run date, source id, the
   window (floor → head SHA + date), which recommended actions it
   covers, kind of work, the problem, the evidence with refs, exactly
   what to change and where, constraints on the fix, verification steps,
   and provenance. The window belongs in every brief because an audit is
   defined by its window, not its run date — two runs on one day with
   different floors are different audits.
6. **What not to write** — no brief for bucket (d) no-ops, and none for
   findings absent from Recommended actions. Say in the chat which
   findings were deliberately left unwritten, so an empty file set is
   never mistaken for a clean audit.
7. **Report and stop** — list the files written with one line each. Hand
   off to `/commit` only if something tracked changed; the audit
   directory is gitignored, so usually nothing is.

## Changes from source proposal

Two departures from the conversation that produced this brief.

- The proposal considered adding `Write` to `drift-audit` guarded by a
  `PreToolUse` hook modeled on `security-reviewer-memory-scope.sh`. That
  hook keys on `.agent_type`, which exists only for **subagents**; an
  inline skill has none, so the pattern does not transfer. Dropped in
  favor of the split, which needs no enforcement mechanism.
- Persisting the audit report (`00-audit-report.md`) was not in the
  original proposal. Added because `drift-audit` writes nothing, so
  without it the briefs cite a report that exists only in a transcript.

## Tag

`publishable` — the repo is public and cherry-picked. Nothing in the
skill is machine- or account-specific.

## Portability caveats

- `context: inline` is load-bearing, not a default. The skill reads the
  audit report out of the current conversation; a forked context would
  not have it. Any port that runs skills in isolation by default must
  supply the report another way.
- The `docs/drift-audit/` path assumes this repo's layout and its
  `.gitignore` entry. A port needs both, or the output lands in version
  control.
- Otherwise plain Agent Skills format — no Claude Code-only frontmatter,
  no hooks, no `shell:` dependency.

## Cross-reference dependencies

- **`drift-audit`** — (a) already exists. Hard dependency: this skill is
  meaningless without its report. `drift-audit`'s closing contract
  already tells the user to start a new request to act on findings;
  that sentence should be updated to name `/drift-handoff` as the
  intended next step. **That edit is part of this task.**
- **`skills/drift-audit/references/sources.md`** — (a) exists. Source of
  the `<source-id>` directory name. Read-only here.
- **`.gitignore`** — (a) already carries `/docs/drift-audit/*` as of this
  session. Verify before first run.
- **`commit`** — (c) external to this skill; invoked only if tracked
  files changed.

> Verbatim — do not edit. Brief-specific observations belong in the
> Notes section above.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit (YAML hygiene rule).
4. If batch is 3+ skills, return a proposal before writing, per batch-conversion convention.

## Notes

The two briefs already written by hand at
`docs/drift-audit/2026-08-29/vscode-agent/` are the worked example of
the intended output. They are gitignored, so read them before they are
cleaned up, or copy one into `docs/handoff-briefs/examples/` first.
Their structure is what section 5 above is describing.

Deliberately **not** in scope: generalizing this to brief any findings
(code-review, security-reviewer). That is arguably the real shape, and
`drift-handoff` is its drift-specific case — but building the general
version now would be speculative. Worth revisiting once a second
findings-producing skill wants the same treatment.

## Confidence

- **Structure**: H — the split is a straightforward separation of
  concerns and the output format is already exercised by hand.
- **Field specs**: M — `context: inline` and the `allowed-tools` set are
  reasoned rather than tested; confirm `Write` without `Edit` behaves as
  expected before relying on it.
- **Body content**: M — the grouping rule ("do they share verification
  steps?") worked on a sample of one audit. It may need refinement once
  a run produces more than four recommended actions.
