---
name: drift-handoff
description: "Turn a completed drift-audit report into handoff briefs on disk. Use immediately after a /drift-audit run, or when the user asks to prepare handoffs, write up the findings, or capture the recommended actions from an audit. Writes one directory per run — docs/audits/<audit-date>/<source-id>/ — holding the audit report verbatim as 00-audit-report.md plus one numbered brief per recommended action, grouped so each brief covers a single kind of work with its own verification steps. Only recommended actions become briefs; every other finding stays a conversational read-through. Runs inline and reads the report from the current session, so it cannot reconstruct an audit it did not see."
argument-hint: "[source-id]"
allowed-tools: Read Write Glob Grep
model: inherit
effort: max
disable-model-invocation: false
context: inline
---

# Drift handoff

Turn a completed `/drift-audit` report into files on disk: the report itself, plus one brief per recommended action, each self-contained enough for a later session to pick up cold.

`/drift-audit` is read-only by contract and writes nothing — its findings live only in the conversation that produced them. This skill is the write half of that pair, split deliberately so the turn doing the analysis has no write capability and the turn doing the writing has no analysis pressure. Executing what gets written is a third turn again, `/drift-update`, and belongs to a later session.

**Transcribe decisions already made; do not re-open them.** If a finding looks wrong while writing it up, say so in chat and leave the brief faithful to the report.

**Creates files only.** `Edit` is deliberately absent from `allowed-tools` — this skill never modifies an existing file.

Repo-relative paths below are relative to the agent-config repo (`C:\Repos\Personal\agent-config`), not the session's cwd. `~/.claude/skills` is a junction into that repo, so this skill can fire from a session in any repo; the output always lands in agent-config, where the `.gitignore` entry covering it lives.

## 1. Preconditions

A `/drift-audit` report must be present **in this conversation**. Check for the report's own structure — an `## Audit window` block and a `## Recommended actions` list — not for a mention of an audit.

If it is absent, **refuse and stop**:

> No `/drift-audit` report in this conversation. This skill transcribes a report; it cannot reconstruct one. Run `/drift-audit [prior-sha-or-date]` first, then re-invoke.

Do not substitute a summary of an audit, a memory of a prior session, or a re-derived set of findings. A brief citing evidence nobody actually gathered is worse than no brief.

If the invocation named a `<source-id>` argument, restrict output to that source. Otherwise write a directory per source the report audited.

## 2. Resolve the target directory

`docs/audits/<audit-date>/<source-id>/`

- `<audit-date>` — the date the audit **ran**, ISO format. Not the window floor.
- `<source-id>` — the registry id from `skills/drift-audit/references/sources.md` (`fabric`, `powerbi`, `vscode-agent`, `claude-code`, …), spelled exactly as the report's `Sources audited` line spells it. Multiple sources in one run get sibling directories, never a merged one.

`Write` creates missing parent directories, so there is no separate mkdir step — and no `Bash` in `allowed-tools` to run one.

**Before writing anything, `Glob` the target directory.** If files already exist there, `Read` them and stop to ask. Two audits of one source on one day are different audits; silently overwriting the first one's briefs destroys the only copy. Offer to suffix the directory rather than overwrite.

Confirm `.gitignore` still carries `/docs/audits/*` before the first write of a session. Without it these working notes land in version control.

## 3. Persist the report

Write the audit report **verbatim** as `00-audit-report.md`, exactly as emitted — every bucket including `## No-op`, and the `## Next run` footer.

Verbatim is the point. The briefs cite this file for their evidence, and the `## Next run` SHAs are what the following audit needs as its floor. A re-summarized report loses both. Do not reformat, re-order, drop empty `_(none)_` headings, or otherwise improve it.

The only permitted addition is a leading H1 (`# Drift audit — <source-id>, <audit-date>`) when the emitted report had none, since the report format starts at `## Audit window`.

## 4. Group recommended actions into briefs

One brief per **kind of work**, not per numbered action. The report's `Recommended actions` list is flag-only and ordered for reading, not for execution — several of its entries routinely belong to one task.

**The test: do they share verification steps?** If yes, one brief. If no, two.

Worked examples of the rule:

- Two actions correcting the same false claim across four prose files — **one brief**. One grep verifies all four.
- One action fixing prose and one changing how the audit fetches — **two briefs**. The first needs a grep; the second needs two re-runs. Different verification, different risk.
- Four mechanical defects in one registry entry — **one brief**, sub-sectioned `D-1`…`D-4`. They land in the same file and one re-run exercises all of them.

Number the files `01-`, `02-`, … with a kebab-case slug naming the work: `01-correct-vscode-version-attribution.md`, `02-repair-vscode-agent-registry-entry.md`. Order by dependency where one exists, otherwise by the report's own action order.

If grouping is genuinely ambiguous, split rather than merge. An over-split brief is a small annoyance; an under-split one hides a task with its own failure mode inside another task's verification.

## 5. Brief contents

`Read` [references/brief-format.md](references/brief-format.md) for the section-by-section spec and a complete worked example. In summary, every brief carries:

- A metadata block: audit run date, source id, **window** (floor → head SHA + date), which recommended actions it covers, kind of work, target files.
- The problem, the evidence with refs, and exactly what to change and where.
- Constraints on the fix, verification steps, provenance.

The **window** belongs in every brief, not only in the report. An audit is defined by its window, not its run date — two runs on one day with different floors are different audits, and a brief naming only the date cannot be matched back to the evidence that produced it.

Write each brief to be read **cold**, by a session with none of this conversation's context. Anything it needs that lives only in the transcript has to be in the file.

## 6. What not to write

- **No brief for a bucket (d) no-op.** They are in `00-audit-report.md`; that is enough.
- **No brief for a finding absent from `Recommended actions`.** Buckets (a), (b), and (c) can each carry findings the audit deliberately did not promote to an action. Promoting one here would be re-opening the analysis, which is exactly what the split exists to prevent.

This boundary is the skill's main editorial rule, and it has a failure mode: an empty or short file set looks like a clean audit. So **say in chat which findings were deliberately left unwritten**, by name, with one line each on why they stayed conversational. A finding the user wants briefed after all is a new `/drift-audit` recommendation or an explicit request — not a judgment call made here.

## 7. Report and stop

List the files written, one line each:

```
docs/audits/2026-08-29/vscode-agent/
  00-audit-report.md                          audit report, verbatim
  01-correct-vscode-version-attribution.md    actions 1–2 · prose correction
  02-repair-vscode-agent-registry-entry.md    actions 3–4 · registry repair
```

Then the deliberate omissions from step 6. Then stop.

Do **not** start the work the briefs describe. That is `/drift-update`'s job — preferably from a fresh session, which is what proves the briefs are readable cold. Doing it here re-merges the two halves the split separated.

Hand off to `/commit` only if something **tracked** changed. `docs/audits/` is gitignored, so a normal run leaves the tree clean and nothing to commit — say so rather than invoking `/commit` against an empty diff. A run worth keeping is copied into `docs/handoffs/examples/` as a tracked example; that copy is a separate, explicit request.
