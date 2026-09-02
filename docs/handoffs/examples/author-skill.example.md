# Skill handoff brief: author-skill

Last verified: 2026-09-01

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

Personal scope, deployed by `scripts/link-claude.ps1`:

- Repo: `skills/workflow/author-skill/SKILL.md`
- Deployed: `~/.claude/skills/author-skill/SKILL.md`

The group directory (`workflow/`) is repo-side only and does not survive
into the deployed name: `~/.claude/skills` is a real directory holding
**one junction per skill**, because Claude Code discovers a skill exactly
one level under the skills root. The skill is live the moment the file
lands — no `-Force` needed, since junctioned payload is the same file on
both sides. A run must name `-SkillGroups workflow` on this machine; a
bare run re-links all 44 skills and silently undoes the platform-skill
prune.

## Scope

Authors a new skill for this repo end to end. Input is a **topic**, not a
brief: the skill checks for existing coverage, decides the name and
namespace, drills the official documentation behind the topic, writes a
filled handoff brief to `docs/handoffs/execute/<name>.md` using
`templates/skill-handoff.md`, drafts the `SKILL.md` from that brief, runs
the post-draft checks, and adds the skill's entry to `skills/README.md`.
It ends at a linted draft plus a fresh-session test plan. It does not
write test fixtures and does not commit.

The brief is an **intermediate artifact**, not an input. That was the
substantive change this skill made to the repo's documented practice,
and it landed before drafting began: both `docs/handoffs/README.md`
and root `README.md` described a two-surface split where a chat session
wrote the brief and Claude Code drafted from it, justified by the chat
surface having more context and being better at structural proposal.
That justification no longer holds — Claude Code drills sources inline
via MCP — so both files were rewritten to describe the pattern without
naming a surface. The brief survives the collapse because it is the
record of what was decided and what was deliberately left out, and the
excluded set is what bounds the draft.

Inline, model-invocable, not path-scoped.

## Sources drilled

> **Reconstructed 2026-09-01.** This heading postdates the brief — it was
> added to the template after this skill shipped. What follows is derived
> from what the brief's own text evidences, not from a record kept at the
> time. A brief written today fills this in during step 4, before the
> draft.

Drilled — all repo-internal, which is the point of a house-style skill:
`templates/skill-handoff.md` (the field list in Frontmatter below came
from it), `docs/handoffs/README.md` and root `README.md` (the
two-surface split this brief overturned), the drift brief numbered 07 in
its run directory (the "incidental grep hits are not coverage" failure
mode, and the undrilled-set discipline), `skills/README.md` (house entry
style), and the loaded skill listing (the `skill-creator` /
`plugin-dev:skill-development` overlap).

Not drilled: the upstream Agent Skills specification and Claude Code's
own frontmatter reference. Every field claim in this brief is inherited
from the template rather than confirmed at source, which is why the
post-draft checklist opens with re-verifying frontmatter against current
docs. Nothing in the drafted skill describes the format itself — that
omission is deliberate and is the stated reason `skill-creator` is not
redundant with this skill.

## Frontmatter

```yaml
---
name: author-skill  # repo linter requires it; max 64 chars; lowercase letters/numbers/hyphens; forbidden words "anthropic"/"claude"
description: Author a new skill for this repo end to end — take a topic, check for existing coverage, drill the official docs behind it, write a filled handoff brief to docs/handoffs/, then draft the SKILL.md and run the post-draft checks. Use when asked to write, author, create, or scaffold a new skill, or when a drift-audit new-skill candidate has been accepted. Encodes this repo's own conventions rather than generic skill advice — verb naming for behavioral skills and fabric-/pbir-/pbid- prefixes for platform ones, the description as the entire trigger mechanism, long detail split into references/, lint-frontmatter.py, and the junction deployment that makes a skill live immediately. Drills before it writes and never encodes an unverified claim. Ends at a linted draft plus a fresh-session test plan; writes no test fixtures and does not commit. To fold a session learning into guidance that already exists, use learn instead.  # required; house target ≤ 1,024 chars
argument-hint: "[topic]"  # optional; autocomplete display hint shown in / menu
allowed-tools: Read Write Edit Glob Grep Bash WebFetch  # Edit is for skills/README.md and the brief, not for rewriting unrelated skills
model: inherit  # always present
effort: max  # always present; a floor under the max session default, so it only bites if the session drops below max
disable-model-invocation: false  # always present; declined repo-wide
context: inline  # naming and scoping decisions need the user in the loop; a fork would decide them alone
---
```

Two notes on the field choices. **`Edit` is included** — unlike
`drift-handoff`, this skill must modify two existing tracked files
(`skills/README.md` and, on first run, `docs/handoffs/README.md`),
so withholding `Edit` would not work. The body must bound that instead of
the tool list doing it. **`context: inline`** because the name, the
namespace, and the "is this actually one skill or two" call are all
decisions the user should see before drilling begins.

MCP tools are deliberately absent from `allowed-tools`: the drilling step
should prefer `microsoft-learn-mcp` / `github-mcp` when they are
available and fall back to `WebFetch` when they are not, and pinning MCP
server names into frontmatter would make the skill fail closed on a
machine without them.

**`model`, `effort` and `disable-model-invocation` postdate this brief.**
They were written out across all 44 skills on 2026-09-01 by the
repo-wide spend-policy pass, on the principle that the flip point for
each lever should be visible in the file rather than absent. A brief
written today specifies all three up front — they are not optional
fields to be omitted at the default.

## Description char count

- `description`: 931 / 1,024 house target (1,536 linter gate)
- `when_to_use`: N/A — not set

Counted, not estimated, against the shipped file. That leaves 93 chars of
headroom against the house target, which is little enough that any wording
change during drafting **must** be re-counted. If it exceeds the target,
cut the `/learn` disambiguation sentence first — it is the least
load-bearing for triggering — and move it into the body.

## Body structure outline

1. **When this is the wrong skill.** Route edits to existing guidance to
   `/learn`. Note that `skill-creator` and `plugin-dev:skill-development`
   exist and are not wrong, only generic: they know the Agent Skills
   format, not this repo's naming rules, lint command, `references/`
   split, junction deployment, or its trigger-description discipline.
   State that as the reason this skill exists, so the duplication reads
   as deliberate.
2. **Check for existing coverage first.** `grep -rli` the topic across
   `skills/*/*/SKILL.md`, and check `fabric-gotchas` specifically — the
   `/learn` skill already treats it as the default home for
   troubleshooting content. Warn on the failure mode from drift brief 07:
   incidental grep hits ("Spark History Server mirror") are not coverage.
   If an existing skill covers the topic, stop and propose extending it.
3. **Name and namespace.** Behavioral skills take the verb you invoke;
   platform skills take a `fabric-` / `pbir-` / `pbid-` prefix.
   `powerbi-*` is reserved for vendored upstream skills and must not be
   used for new local ones. The namespace also picks the group directory,
   which is load-bearing — a flat `skills/<name>/SKILL.md` is skipped by
   the depth-pinned linter hook *and* invisible to one-level discovery.
   Check the proposed name does not collide with a loaded plugin skill's
   trigger surface.
4. **Drill the sources.** Prefer `microsoft-learn-mcp` for Learn pages and
   `github-mcp` for exact repo bytes; fall back to `WebFetch`. Record
   which pages were drilled **and which were not** — the undrilled set is
   what bounds the draft, and drift brief 07 is the worked example of why
   that matters.
5. **Write the filled brief** to `docs/handoffs/execute/<name>.md`
   from `templates/skill-handoff.md`. Check the path is not already
   occupied first — a `/drift-update` escalation leaves its scoping input
   at exactly that name. Every template heading survives; sections that
   do not apply get `N/A — <reason>`. The brief records what was decided
   and what was deliberately excluded, which is the part that outlives
   the draft.
6. **Draft the `SKILL.md`.** Long detail goes to
   `skills/<group>/<name>/references/`, not the body — root `CLAUDE.md`
   is explicit about this. The `description` is the entire model-invoked
   trigger mechanism, so it is written to fire on the queries the skill
   should answer, not to summarize the body.
7. **Post-draft checks.** `uv run --with pyyaml scripts/lint-frontmatter.py
   skills/<group>/<name>/SKILL.md`; re-count the description; `cat` the
   whole file after any edit (YAML hygiene); `pre-commit run --all-files`.
8. **Add the entry to `skills/README.md`** in the right section, matching
   the house style there — what it covers plus, where the name is not
   self-evident, why it is named that. The `drift-audit` entry is the
   model for the latter.
9. **Report, sweep, hand off to `/commit`.** State plainly that the skill
   has not been behaviourally tested: trigger behaviour is a fresh-session
   task even though skills themselves hot-reload, because a changed
   `description` is a changed trigger. Name the queries it should fire on
   so the test is runnable. Propose the spent brief's deletion or
   promotion rather than leaving it to the convention.
10. **Constraints.** No unverified claims — if drilling did not establish
    it, it does not go in. No fixtures. No commit. Do not edit skills
    other than the one being authored, and do not widen the diff to
    adjacent cleanups; that is `/learn` and `/simplify` territory.

## Changes from source proposal

Derived from a conversational proposal on 2026-08-29 that suggested a new
`docs/author-skill/` or `docs/create-skill/` directory holding the brief.
Two departures:

- **No new directory.** `docs/handoffs/` already exists, already
  holds the template, and its README already documents that open briefs
  are deleted once the change lands. `drift-handoff-skill.md` is the
  precedent. A third top-level `docs/` folder would fragment a convention
  documented in two places.
- **Name is `author-skill`, not `create-skill`.** Verb-first matches
  `commit` / `learn` / `code-review` / `drift-audit`, and it stays
  distinct from the loaded `skill-creator` plugin skill in trigger
  matching.

Scope was settled by two decisions taken in that conversation: the skill
takes a **topic** and runs the full pipeline (not a brief-to-draft
executor), and it produces **no test fixtures**.

## Tag

`personal`

## Portability caveats

The skill is portable in format but not in content — it hardcodes this
repo's layout (`skills/<group>/`, `docs/handoffs/execute/`,
`scripts/lint-frontmatter.py`) and its naming conventions. Anyone
cherry-picking it would need to rewrite steps 2, 3, 5, 7 and 8. That is
acceptable and worth saying in the skill body: it is deliberately a
house-style skill, which is the whole reason it exists alongside the
generic `skill-creator`.

One Claude Code-only field is relied on, and it postdates this brief:
**`effort: max`**, added by the 2026-09-01 spend-policy pass. It is not
part of the Agent Skills spec and a portable copy would drop it with no
loss of behaviour — it pins a floor, and the session already sits at
`max`. `argument-hint` and `allowed-tools` are standard; no
`shell: powershell`, no `context: fork`, no hooks.

## Cross-reference dependencies

- `learn` — (a) already converted. The disambiguation runs both ways:
  `/learn` folds a session learning into guidance that exists;
  `/author-skill` creates guidance that does not. Both skills point at
  each other; `skills/workflow/learn/SKILL.md` gained its line as part
  of this work.
- `commit` — (a) already converted. Handoff target.
- `drift-audit` / `drift-handoff` / `drift-update` — (a) already
  converted. `/drift-audit` produces the new-skill candidates that are
  this skill's most likely upstream input; `/drift-update` escalates the
  scoping decision that authorizes a run.
- `skill-creator`, `plugin-dev:skill-development` — (c) external. Not
  dependencies; named in the body only to justify the overlap.
- `docs/handoffs/README.md` and root `README.md` — **done.** Both
  carried the two-surface split; both were rewritten to be
  surface-agnostic before drafting began, so this skill now implements
  documented practice rather than contradicting it. The duplication is
  worth remembering: root `CLAUDE.md` names drifting project-scope
  instruction files as this repo's recurring failure mode, and this
  brief originally listed only the first of the two.
- `docs/handoffs/templates/skill-handoff.md` — (a) already
  converted. Consumed as-is at the time. **It has since changed**
  (2026-09-01): the artifact-path guidance names the group directory, the
  three spend fields are marked always-present, the char-count section
  asks for two numbers, and a `Sources drilled` heading was added. This
  brief was refreshed to match; a brief filled from the current template
  will not look identical to the 2026-08-29 original.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**This brief was refreshed on 2026-09-01** and is no longer a verbatim
snapshot of what was written on 2026-08-29. The design record — the
two departures in `Changes from source proposal`, the scope decisions,
the field rationale — is unchanged. What was updated is every claim about
the repo that had since gone stale: the group directories under
`skills/`, `execute/` as the brief target, the three spend fields, and
the template's own changes. It is kept current rather than frozen because
`examples/README.md` cites it as *the* reference for brief form, so a
stale copy is one that gets copied forward. `git log` has the original.

**The README convention change has landed.** Both
`docs/handoffs/README.md` and root `README.md` describe the
pattern without naming a surface. The open item this brief recorded —
`drift-handoff-skill.md` sitting at the top level with its change already
shipped — is **resolved**: it was deleted, and the lifecycle is now
documented in three parts (delete on landing, promote to `examples/` if
still cited, `git log --diff-filter=D` to recover). That the
delete-once-landed rule failed on its first real test is why
`/author-skill` step 9 performs the promotion-or-deletion sweep itself
instead of trusting the convention to hold.

**This brief is its own first dogfood.** It was written by hand against
`templates/skill-handoff.md`, which is exactly what the skill automates
at step 5. If the skill's generated briefs do not look like this one,
that is a finding about the skill, not about this brief.

**Ordering risk worth naming — now spent, and still unanswered.**
The first real use of `/author-skill` was to be `fabric-mirroring`, a
reference skill with no enforcement contract, i.e. the easy case: it
would not exercise step 1's routing logic or step 2's stop-and-propose
path, so a clean first run would be weak evidence that those work.
`skills/fabric/fabric-mirroring/` now exists, so that run has happened.
Whether the two untested paths have been exercised since is not recorded
anywhere, which is the residue of this risk rather than its resolution.

## Confidence

- **Structure**: H — the brief pattern, the directory, and the template
  all exist and have a shipped precedent in `drift-handoff-skill.md`.
- **Field specs**: M — the `description` sits 93 chars under the 1,024
  house target, close enough that the exact final wording decides trigger
  quality. Re-count is mandatory, not advisory.
- **Body content**: M — steps 2, 4 and 6 carry the real editorial
  judgement (what counts as existing coverage, what counts as drilled
  enough, what belongs in `references/` versus the body) and prose alone
  is the only enforcement. Expect to tighten those after the first two
  real runs.
