# Drift handoff brief format

The section-by-section spec for one brief, plus a complete worked
example. `SKILL.md` step 5 points here.

A brief is read **cold** — by a session holding none of the context of
the conversation that produced the audit. Every section below exists
because a cold reader needs it. If a section would be empty, drop the
heading rather than writing "N/A"; unlike the handoff-brief templates in
`docs/handoffs/`, this format is not a fixed checklist.

## Filename

`NN-kebab-slug.md`, where `NN` is `01`, `02`, … and the slug names the
work as an imperative: `01-correct-vscode-version-attribution.md`,
`02-repair-vscode-agent-registry-entry.md`. Not the finding, the work —
`repair-registry-entry`, never `registry-entry-defects`.

## Title

`# Handoff: <imperative phrase>` — the same verb as the slug, in prose.

## Metadata block

A bullet list directly under the title. Required:

```markdown
- **Audit run**: <ISO date the audit ran>
- **Source**: `<source-id>`
- **Window**: floor `<sha-or-date>` → head `<head-sha>` (<head-date>)
- **Covers recommended actions**: <n, or n and n, or n–n>
- **Kind**: <one line naming the kind of work and its blast radius>
```

Optional, when the targets are known up front and are few:

```markdown
- **Target**: `<path>`, `<path>`
```

Notes on the fields:

- **Window** is non-negotiable. An audit is defined by its window, not
  its run date; two runs on one day with different floors are different
  audits. Copy it from the report's `## Audit window` block.
- **Covers recommended actions** is what lets a reader go back to
  `00-audit-report.md` and confirm nothing was dropped in the grouping.
  Every action in the report must appear in exactly one brief's list.
- **Kind** is doing real work: it is where "factual correction to
  committed prose, no behavior changes" is distinguished from
  "changes how the audit fetches". That distinction is what justified
  splitting the two briefs in the first place.

## Body sections

Required, in this order:

1. **The problem** (or **Context**) — what is wrong, in a few sentences.
   State it as fact, not as a finding: "Four files claim X. It is
   false." A cold reader should not have to infer the defect from the
   evidence.
2. **Evidence** — the refs, tables, timelines, or symptoms that
   establish the problem. Cite specific SHAs, dates, file paths, and
   quote upstream text verbatim where the wording is what is at issue.
   This is the section that cannot be reconstructed later, so it is the
   one to over-supply.
3. **What to change** — every target, enumerated, each with enough
   locating detail to find the text without a search: the file, the
   paragraph, and the offending line quoted. Where a target is
   arguable rather than plainly wrong, say so and say why it is
   included anyway.
4. **Verification** — numbered, runnable, in order. Prefer commands
   over descriptions. Every brief ends with the repo's standard gates
   where they apply (`uv run --with pyyaml scripts/lint-frontmatter.py
   <file>`, `pre-commit run --all-files`). The shared-verification test
   in `SKILL.md` step 4 is what decides brief boundaries, so this
   section is also the evidence that the grouping was right.
5. **Provenance** — which audit run surfaced this, and anything about
   how it was found that bears on trusting it. One short paragraph.

Optional, inserted where they read naturally:

- **Constraint on the fix** — bounds on the correction that are not
  obvious from the problem. Typically: what the evidence does *not*
  establish, so the fix does not overreach. ("Do not swap one
  unverified version number for another.")
- **Not fixable** / **Out of scope** — parts of the problem that will
  survive the fix, and why that is acceptable. Commit messages are the
  recurring case: history is not rewritten, so corrected files disagree
  with the messages that introduced the error.
- **Sequencing note** — when two briefs must not be bundled, say so in
  both, with the reason. "Different verification, different risk" is
  the usual reason and is worth stating explicitly, because bundling is
  the tempting default for a reader who sees two small briefs.

## Sub-sectioning a multi-defect brief

When one brief covers several independent defects in one target, give
each its own `## D-1 — <symptom>` heading with a consistent internal
shape:

```markdown
## D-2 — `sections` holds the wrong kind of value

**Symptom.** <what is observably wrong>
**Cause.** <why>
**Fix.** <what to do; state options where a real choice exists>
**Open question.** <a decision the fixer must make, if any>
**Knock-on.** <what else this touches, if anything>
```

Keep `Verification` and `Provenance` at brief level, not per defect —
they are shared, which is why the defects are one brief.

## Worked example

Preserved from `docs/audits/2026-08-29/vscode-agent/`, the first
run that produced briefs by hand. That directory is gitignored and
short-lived; this copy is the durable one. Lightly trimmed.

---

# Handoff: correct the VS Code 1.135 attribution

- **Audit run**: 2026-08-29
- **Source**: `vscode-agent`
- **Window**: floor `2026-03-01` → head `28f76f5f` (2026-08-28)
- **Covers recommended actions**: 1 and 2
- **Kind**: factual correction to committed prose. No behavior changes.

## The problem

Four files claim `~/.claude/skills` became a usable
`chat.agentSkillsLocations` location in **VS Code 1.135**, and that this
is what obsoleted `scripts/link-copilot.ps1`. It is false. The location
was already documented two months before the linker was written.

A second, related claim — that the linker's docstring had been "quietly
wrong for months" — is also false. The docstring existed for five days.

## Evidence

`docs/agent-customization/agent-skills.md` in `microsoft/vscode-docs`
carries a byte-identical locations table at all three refs checked:

| Ref | Date | `~/.claude/skills` present? |
| --- | --- | --- |
| `cf47dadb` | 2026-06-26 | yes — listed under Personal skills |
| `27ab87b0` (1.134) | 2026-08-19 | yes |
| `28f76f5f` (HEAD) | 2026-08-28 | yes |

The table reads, verbatim:

```
| Personal skills, stored in your user profile | `~/.copilot/skills/`, `~/.claude/skills/`, `~/.agents/skills/` |
```

Timeline that settles it:

| Date | Event | Ref |
| --- | --- | --- |
| 2026-06-26 | `~/.claude/skills` already documented | `cf47dadb` |
| 2026-08-04 | docs reorg into `docs/agent-customization/` | `db6dab74` |
| **2026-08-24** | `link-copilot.ps1` created, docstring claims the location is off | `70eb028` |
| 2026-08-25 | VS Code 1.135 released | `9deb39cd` |
| 2026-08-29 | linker deleted | `a49b159` |

So the docstring was **wrong from birth**, not made wrong by 1.135. The
fact it denied had been true for roughly two months when it was written.

## What to change

Four files. Each states or implies the same wrong causality.

1. **`CLAUDE.md`** (root) — the paragraph beginning "Two traps are worth
   remembering", containing:
   > `~/.claude/skills` has been a first-class `chat.agentSkillsLocations`
   > location since VS Code 1.135

2. **`scripts/README.md`** — the paragraph beginning "There is
   deliberately **no `link-copilot.ps1`**", containing:
   > VS Code 1.135 made `~/.claude/skills` a first-class location

3. **`skills/drift-audit/references/sources.md`** — the `vscode-agent`
   entry prose, which carries **both** errors:
   > `~/.claude/skills` became a first-class `chat.agentSkillsLocations`
   > entry in VS Code 1.135, which retired a whole linker script whose
   > docstring had been quietly wrong for months.

4. **`README.md`** — under Tool support:
   > Turning them on is purely a settings decision (VS Code 1.135+)

   This one is a version *floor*, not a causal claim, so it is not
   strictly wrong. But it is unverified and it reinforces the same
   mistaken impression. Either substantiate the floor or drop the
   version qualifier.

## Constraint on the replacement text

Do not swap one unverified version number for another. What is actually
established is a **date floor, not a version**: documented since at
least 2026-06-26. The earlier history lives under the pre-reorg path
`docs/copilot/customization/agent-skills.md` and was **not** checked.

Optional, if a precise origin is wanted: trace that path back through
`db6dab74` to find the commit that first added `~/.claude/skills`. Not
required — "documented since at least 2026-06-26" is defensible as-is
and is what the evidence supports.

## Not fixable

Commit messages `a49b159` and `62fd636` both assert the 1.135 causality.
History is not being rewritten for this. The corrected files will
disagree with those messages; that is acceptable and worth a sentence in
whichever commit lands this correction, so a reader who follows a
`git blame` back to them is not misled.

## Verification

1. `grep -rn "1\.135" --include="*.md" .` — every surviving hit should
   be either a factual release-date reference or removed entirely.
2. `uv run --with pyyaml scripts/lint-frontmatter.py skills/drift-audit/SKILL.md`
   — the `sources.md` edit is body-only, but the skill description also
   mentions the surface; confirm it still lints and still describes what
   the registry actually covers.
3. `pre-commit run --all-files`.

## Provenance

Found by the first validation run of the `vscode-agent` drift-audit
source, registered in `62fd636` roughly one hour before the run. The
source caught a false claim that the same session had committed to three
files — which is the failure class it was registered to catch.
