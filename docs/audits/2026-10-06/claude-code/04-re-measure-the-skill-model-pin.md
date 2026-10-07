# Handoff: re-measure the skill `model:` pin

- **Audit run**: 2026-10-06
- **Source**: `claude-code`
- **Window**: floor `2026-08-30` (base `f1af9b1f`, 2026-08-28) → head
  `fbe20e00` (2026-10-06)
- **Covers recommended actions**: 4
- **Kind**: measurement in a cold probe session, then a correction to one
  rules bullet; D-2 alone is a documented edit that does not wait on it
- **Target**: `.claude/rules/editing-skills.md`

## The problem

`.claude/rules/editing-skills.md` says a skill's `model:` pin holds only
when the skill is slash-invoked and is silently ignored when its
description triggers it. That was measured on 2026-09-01, before Claude
Code 2.1.259 fixed `model:` being ignored in interactive sessions, so
the rule may describe a bug since fixed. The same file calls skill names
one flat namespace, which the harness now qualifies.

## D-1 — the description-triggered case predates a fix

**Symptom.** § "Invocation and spend fields":
> `model:` lasts one turn, and only when the skill is slash-invoked: one
> reached by its description runs on the session model, the pin silently
> ignored (2026-09-01).

**Cause.**

- `CHANGELOG.md` 2.1.259, two bullets:
  > Fixed frontmatter `model:` on custom commands and skills being
  > ignored in interactive sessions

  > Fixed auto mode running a turn on a model it doesn't support when a
  > command or skill's frontmatter `model:` named one; the turn now
  > keeps the session model
- https://code.claude.com/docs/en/skills, read 2026-10-06:
  > In auto mode, and in plan mode while the classifier reviews
  > commands, a model that auto mode doesn't support also isn't used,
  > and the session keeps its current model.
- Seen in the audit session itself, 2026-10-06 on 2.1.291 in auto mode:
  `/drift-audit`, pinned `model: fable`, ran on Fable 5.1 when typed as
  a slash command, and the next turn was back on Opus 5.5. That confirms
  the slash path and the one-turn life, and says nothing about the
  description path.

The WebFetch summary of the skills page also said `model` applies "for
both manually invoked and description-triggered skills". That sentence
was the summarizer's own, not a quote: do not cite it.

**Fix.** Measure first, cold, on the current CLI: a scratch skill
pinned to a model other than the session's, reached by its description,
with `Skill` in `--tools`, since a session without it gets no listing at
all (measured 2026-10-06 on 2.1.291, in flight in
`docs/evidence/root-claude-md.md` when this was written). Read the
turn's assistant records' `message.model`. Run it in default mode and
in auto mode, which the docs treat differently. Then rewrite the bullet
to the result, with the auto-mode caveat and the measurement's date.

## D-2 — names are not quite one flat namespace

**Symptom.** § "Name and listing budget":
> Names are one flat namespace across both trees (`pre-commit-hooks.md`).

**Cause.**

- https://code.claude.com/docs/en/skills, read 2026-10-06:
  > Claude Code reserves the name `anthropic-skills`, and every name
  > inside that namespace such as `anthropic-skills:pdf`, for skills
  > synced from claude.ai
- `CHANGELOG.md` 2.1.282: skill folders, command files and workflow
  commands in the `anthropic-skills` or `claude-ai` namespace no longer
  load; 2.1.283 reverted the `claude-ai` half.

**Fix.** Add that the harness reserves `anthropic-skills` and every
`anthropic-skills:<name>` for claude.ai-synced skills, so no skill here
takes that name. The flat namespace across the two trees still holds;
keep that sentence.

## Sequencing note

Brief 03 D-1 rewrites two other bullets of § "Invocation and spend
fields". Land one before starting the other and re-read the section
first; do not bundle them, since 03 waits on the user and this on a
probe.

## Verification

1. D-1: the probe's transcripts show each arm's model; cite them in a
   dated entry in `docs/evidence/root-claude-md.md`, where this rule's
   evidence goes (`.claude/rules/editing-rules.md`).
2. `grep -n "anthropic-skills" .claude/rules/editing-skills.md` — a hit.
3. `uv run --with pyyaml scripts/lint-frontmatter.py .claude/rules/editing-skills.md`
4. `pre-commit run --all-files`.

## Provenance

Found by the 2026-10-06 `claude-code` run in its changelog diff and
checked against the skills page the same day. The Fable observation is
the audit session's own model notices, not a designed probe.
