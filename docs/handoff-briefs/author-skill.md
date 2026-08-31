# Skill handoff brief: author-skill

Last verified: 2026-08-29

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

Personal scope, deployed via the existing `skills/` junction:

- Repo: `skills/author-skill/SKILL.md`
- Deployed: `~/.claude/skills/author-skill/SKILL.md`

No new linking step — `scripts/link-claude.ps1` already junctions
`skills/` wholesale, so the skill is live the moment the file lands.

## Scope

Authors a new skill for this repo end to end. Input is a **topic**, not a
brief: the skill checks for existing coverage, decides the name and
namespace, drills the official documentation behind the topic, writes a
filled handoff brief to `docs/handoff-briefs/<name>.md` using
`skill-handoff-template.md`, drafts the `SKILL.md` from that brief, runs
the post-draft checks, and adds the skill's entry to `skills/README.md`.
It ends at a linted draft plus a fresh-session test plan. It does not
write test fixtures and does not commit.

The brief is an **intermediate artifact**, not an input. That was the
substantive change this skill made to the repo's documented practice,
and it landed before drafting began: both `docs/handoff-briefs/README.md`
and root `README.md` described a two-surface split where a chat session
wrote the brief and Claude Code drafted from it, justified by the chat
surface having more context and being better at structural proposal.
That justification no longer holds — Claude Code drills sources inline
via MCP — so both files were rewritten to describe the pattern without
naming a surface. The brief survives the collapse because it is the
record of what was decided and what was deliberately left out, and the
excluded set is what bounds the draft.

Inline, model-invocable, not path-scoped.

## Frontmatter

```yaml
---
name: author-skill  # required; max 64 chars; lowercase letters/numbers/hyphens; forbidden words "anthropic"/"claude"
description: Author a new skill for this repo end to end — take a topic, check for existing coverage, drill the official docs behind it, write a filled handoff brief to docs/handoff-briefs/, then draft the SKILL.md and run the post-draft checks. Use when asked to write, author, create, or scaffold a new skill, or when a drift-audit new-skill candidate has been accepted. Encodes this repo's own conventions rather than generic skill advice — verb naming for behavioral skills and fabric-/pbir-/pbid- prefixes for platform ones, the description as the entire trigger mechanism, long detail split into references/, lint-frontmatter.py, and the junction deployment that makes a skill live immediately. Drills before it writes and never encodes an unverified claim. Ends at a linted draft plus a fresh-session test plan; writes no test fixtures and does not commit. To fold a session learning into guidance that already exists, use learn instead.  # required; keep under 1,024 chars
argument-hint: "[topic]"  # optional; autocomplete display hint shown in / menu
allowed-tools: Read Write Edit Glob Grep Bash WebFetch  # Edit is for skills/README.md and the brief, not for rewriting unrelated skills
model: inherit
context: inline  # naming and scoping decisions need the user in the loop; a fork would decide them alone
---
```

Two notes on the field choices. **`Edit` is included** — unlike
`drift-handoff`, this skill must modify two existing tracked files
(`skills/README.md` and, on first run, `docs/handoff-briefs/README.md`),
so withholding `Edit` would not work. The body must bound that instead of
the tool list doing it. **`context: inline`** because the name, the
namespace, and the "is this actually one skill or two" call are all
decisions the user should see before drilling begins.

MCP tools are deliberately absent from `allowed-tools`: the drilling step
should prefer `microsoft-learn-mcp` / `github-mcp` when they are
available and fall back to `WebFetch` when they are not, and pinning MCP
server names into frontmatter would make the skill fail closed on a
machine without them.

## Description char count

935 / 1,024 portable cap — counted, not estimated, against the draft
above. That leaves 89 chars of headroom, which is little enough that any
wording change during drafting **must** be re-counted. If it exceeds the cap, cut the
`/learn` disambiguation sentence first — it is the least load-bearing for
triggering — and move it into the body.

## Body structure outline

1. **When this is the wrong skill.** Route edits to existing guidance to
   `/learn`. Note that `skill-creator` and `plugin-dev:skill-development`
   exist and are not wrong, only generic: they know the Agent Skills
   format, not this repo's naming rules, lint command, `references/`
   split, junction deployment, or the 1024-char trigger discipline.
   State that as the reason this skill exists, so the duplication reads
   as deliberate.
2. **Check for existing coverage first.** `grep -rli` the topic across
   `skills/*/SKILL.md`, and check `fabric-gotchas` specifically — the
   `/learn` skill already treats it as the default home for
   troubleshooting content. Warn on the failure mode from drift brief 07:
   incidental grep hits ("Spark History Server mirror") are not coverage.
   If an existing skill covers the topic, stop and propose extending it.
3. **Name and namespace.** Behavioral skills take the verb you invoke;
   platform skills take a `fabric-` / `pbir-` / `pbid-` prefix.
   `powerbi-*` is reserved for vendored upstream skills and must not be
   used for new local ones. Check the proposed name does not collide with
   a loaded plugin skill's trigger surface.
4. **Drill the sources.** Prefer `microsoft-learn-mcp` for Learn pages and
   `github-mcp` for exact repo bytes; fall back to `WebFetch`. Record
   which pages were drilled **and which were not** — the undrilled set is
   what bounds the draft, and drift brief 07 is the worked example of why
   that matters.
5. **Write the filled brief** to `docs/handoff-briefs/<name>.md` from
   `skill-handoff-template.md`. Every template heading survives; sections
   that do not apply get `N/A — <reason>`. The brief records what was
   decided and what was deliberately excluded, which is the part that
   outlives the draft.
6. **Draft the `SKILL.md`.** Long detail goes to
   `skills/<name>/references/`, not the body — root `CLAUDE.md` is
   explicit about this. The `description` is the entire model-invoked
   trigger mechanism, so it is written to fire on the queries the skill
   should answer, not to summarize the body.
7. **Post-draft checks.** `uv run --with pyyaml scripts/lint-frontmatter.py
   skills/<name>/SKILL.md`; re-count the description; `cat` the whole file
   after any edit (YAML hygiene); `pre-commit run --all-files`.
8. **Add the entry to `skills/README.md`** in the right section, matching
   the house style there — what it covers plus, where the name is not
   self-evident, why it is named that. The `drift-audit` entry is the
   model for the latter.
9. **Report and hand off to `/commit`.** State plainly that the skill has
   not been behaviourally tested: a changed `SKILL.md` does not reliably
   reload mid-session on Windows, so trigger behaviour is a fresh-session
   task. Name the queries it should fire on so the test is runnable.
10. **Constraints.** No unverified claims — if drilling did not establish
    it, it does not go in. No fixtures. No commit. Do not edit skills
    other than the one being authored, and do not widen the diff to
    adjacent cleanups; that is `/learn` and `/simplify` territory.

## Changes from source proposal

Derived from a conversational proposal on 2026-08-29 that suggested a new
`docs/author-skill/` or `docs/create-skill/` directory holding the brief.
Two departures:

- **No new directory.** `docs/handoff-briefs/` already exists, already
  holds the template, and its README already documents that open briefs
  sit at that level and are deleted once the change lands.
  `drift-handoff-skill.md` is the precedent. A third top-level `docs/`
  folder would fragment a convention documented in two places.
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
repo's layout (`skills/`, `docs/handoff-briefs/`,
`scripts/lint-frontmatter.py`) and its naming conventions. Anyone
cherry-picking it would need to rewrite steps 2, 3, 5, 7 and 8. That is
acceptable and worth saying in the skill body: it is deliberately a
house-style skill, which is the whole reason it exists alongside the
generic `skill-creator`.

No Claude Code-only frontmatter is relied on. `argument-hint` and
`allowed-tools` are both standard; no `shell: powershell`, no
`context: fork`, no hooks, no `effort`.

## Cross-reference dependencies

- `learn` — (a) already converted. The disambiguation runs both ways:
  `/learn` folds a session learning into guidance that exists;
  `/author-skill` creates guidance that does not. Both skills should
  point at each other, so `skills/learn/SKILL.md` gains a line as part
  of this work.
- `commit` — (a) already converted. Handoff target.
- `drift-audit` / `drift-handoff` / `drift-update` — (a) already
  converted. `/drift-audit` produces the new-skill candidates that are
  this skill's most likely upstream input; `/drift-update` escalates the
  scoping decision that authorizes a run.
- `skill-creator`, `plugin-dev:skill-development` — (c) external. Not
  dependencies; named in the body only to justify the overlap.
- `docs/handoff-briefs/README.md` and root `README.md` — **done.** Both
  carried the two-surface split; both were rewritten to be
  surface-agnostic before drafting began, so this skill now implements
  documented practice rather than contradicting it. The duplication is
  worth remembering: root `CLAUDE.md` names drifting project-scope
  instruction files as this repo's recurring failure mode, and this
  brief originally listed only the first of the two.
- `docs/handoff-briefs/skill-handoff-template.md` — (a) already
  converted. Consumed as-is; this brief does not propose changing it.

> Verbatim — do not edit. Brief-specific observations belong in the
> Notes section above.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit (YAML hygiene rule).
4. If batch is 3+ skills, return a proposal before writing, per batch-conversion convention.

## Notes

**The README convention change has landed.** Both
`docs/handoff-briefs/README.md` and root `README.md` now describe the
pattern without naming a surface, and the stale "None are open right
now" line has been corrected. What is *not* resolved is
`drift-handoff-skill.md`, still sitting at that level with its change
already shipped — it needs deleting or promoting into `examples/`. The
README now says so explicitly rather than pretending the level is
clean. That the delete-once-landed rule failed on its first real test
is the argument for `/author-skill` performing the promotion-or-deletion
itself at step 9 instead of trusting the convention to hold.

**This brief is its own first dogfood.** It was written by hand against
`skill-handoff-template.md`, which is exactly what the skill will
automate at step 5. If the skill's generated briefs do not look like this
one, that is a finding about the skill, not about this brief.

**Ordering risk worth naming.** The first real use of `/author-skill`
will be `fabric-mirroring`, whose scoping input is written and waiting.
That is a reference skill with no enforcement contract — the easy case.
It will not exercise step 1's routing logic or step 2's stop-and-propose
path, so a clean first run is weak evidence that those work.

## Confidence

- **Structure**: H — the brief pattern, the directory, and the template
  all exist and have a shipped precedent in `drift-handoff-skill.md`.
- **Field specs**: M — the `description` is close enough to the 1,024
  cap that it will likely need a trim, and the exact final wording
  decides trigger quality. Re-count is mandatory, not advisory.
- **Body content**: M — steps 2, 4 and 6 carry the real editorial
  judgement (what counts as existing coverage, what counts as drilled
  enough, what belongs in `references/` versus the body) and prose alone
  is the only enforcement. Expect to tighten those after the first two
  real runs.
