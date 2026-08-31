---
name: author-skill
description: "Author a new skill for this repo end to end — take a topic, check for existing coverage, drill the official docs behind it, write a filled handoff brief to docs/handoff-briefs/, then draft the SKILL.md and run the post-draft checks. Use when asked to write, author, create, or scaffold a new skill, or when a drift-audit new-skill candidate has been accepted. Encodes this repo's own conventions rather than generic skill advice — verb naming for behavioral skills and fabric-/pbir-/pbid- prefixes for platform ones, the description as the entire trigger mechanism, long detail split into references/, lint-frontmatter.py, and the junction deployment that makes a skill live immediately. Drills before it writes and never encodes an unverified claim. Ends at a linted draft plus a fresh-session test plan; writes no test fixtures and does not commit. To fold a session learning into guidance that already exists, use learn instead."
argument-hint: "[topic]"
allowed-tools: Read Write Edit Glob Grep Bash WebFetch
model: inherit
context: inline
---

# Author a skill

Take a **topic** and end at a linted `SKILL.md` draft plus a runnable
fresh-session test plan. The input is a subject, not a specification —
deciding the name, the boundaries, and what the skill deliberately will
not cover is the work, not a precondition for it.

This skill is house-style. It encodes how *this* repo builds skills; the
generic mechanics of the Agent Skills format are somebody else's job
(see step 1).

Repo-relative paths below are relative to the agent-config repo
(`C:\Repos\Personal\agent-config`), not the session's cwd. `~/.claude/skills`
is a junction into that repo, so this skill can fire from a session in any
repo — resolve paths against agent-config regardless of where it fired.

**Deployment is immediate and needs no step.** `scripts/link-claude.ps1`
junctions `skills/` wholesale, so the file is live in `~/.claude/skills/`
the moment it is written. There is nothing to copy and no linker to
re-run. That also means a half-drafted skill is a live half-drafted
skill; finish the frontmatter before walking away.

## 1. Check this is the right skill

Two routes out, both cheap to check first.

**Guidance that already exists → `/learn`.** The dividing line is whether
the destination exists. `/learn` folds a session learning into a skill,
rule, or `CLAUDE.md` that should already have covered it. This skill
creates guidance that has no home yet. A learning that arrives as "the
`fabric-cicd` skill was wrong about X" is `/learn` work even if the fix
is large.

**Generic skill-authoring help → `skill-creator` or
`plugin-dev:skill-development`.** Both are loaded and both are good.
They are not wrong, only generic: they know the Agent Skills format,
progressive disclosure, and description tuning in the abstract. They do
not know this repo's naming rules, its lint command, its `references/`
split, its junction deployment, or the discipline of writing a handoff
brief first. That gap is the entire reason this skill exists alongside
them. Say so plainly when the overlap comes up, so the duplication reads
as deliberate rather than as something nobody noticed.

If the user wants a *subagent* rather than a skill, this is the wrong
skill: the artifact lives in `claude/agents/` and uses
`subagent-handoff-template.md`. Stop and say so.

## 2. Check for existing coverage

Before naming anything, find out whether the topic is already covered.

```
grep -rli "<topic term>" skills/*/SKILL.md
grep -rn -i "<topic term>" skills/fabric-gotchas/SKILL.md
```

Check `fabric-gotchas` explicitly. `/learn` treats it as the default
home for cross-product troubleshooting content, so a topic can be
half-covered there without any dedicated skill existing.

**An incidental grep hit is not coverage.** The worked failure is a
Mirroring search matching "Spark History Server mirror" in
`fabric-spark-monitoring` — same substring, unrelated subject. Read the
surrounding heading before counting a hit. Conversely, a topic can be
genuinely covered under vocabulary you did not grep for; skim the
`skills/README.md` section list for the relevant domain as a second
pass.

Three outcomes:

- **Covered correctly** — stop. Say where, and that nothing is needed.
- **Covered partially, in a skill that owns the domain** — stop and
  propose *extending* that skill instead. A second skill splitting one
  domain makes both harder to trigger, because the model is choosing
  between two descriptions that both half-match.
- **Not covered** — continue.

The stop cases are real stops. Do not proceed to drilling because the
topic is interesting.

## 3. Decide the name and namespace

Put the proposal to the user before drilling. Naming is cheap to change
now and expensive later — the name is in the directory, the slash
command, and every cross-reference.

- **Behavioral, cross-domain skills take the verb you invoke** —
  `commit`, `learn`, `code-review`, `drift-audit`. Read the name as the
  user typing it.
- **Platform skills take a namespace prefix** — `fabric-`, `pbir-`, or
  `pbid-`.
- **`powerbi-*` is reserved.** Those are vendored from
  `microsoft/skills-for-fabric` and keep upstream naming so re-sync
  diffs stay clean. Never take that prefix for a local skill.
- **Name the job, not the target**, where they differ. `drift-audit` is
  named that way because it audits rules, `CLAUDE.md`, and the MCP
  templates too — `skill-audit` would have named a quarter of its scope
  and collided with a plausible future skill.
- The linter enforces the mechanics: lowercase letters, digits and
  hyphens only, ≤ 64 chars, and no `anthropic` or `claude` anywhere in
  the name.

**Check the name against the loaded plugin skills, not just this repo.**
A local skill competing with `skill-creator` or a `plugin-dev:*` skill
for the same trigger surface is a real collision even though the
directories never touch.

Also settle the scope question at this point: **is this one skill or
two?** A topic that splits cleanly into a reference half and a workflow
half is often two skills (`pbir-cli` and `pbir-report-workflow` are the
in-repo example). Decide with the user now; discovering it during
drafting means rewriting the brief.

## 4. Drill the sources

Do not write from training data. The point of this step is that every
claim in the finished skill traces to something read during this run.

- **Microsoft Learn** — `microsoft_docs_search` to find the pages, then
  `microsoft_docs_fetch` for the ones that matter. Search returns
  500-token excerpts, which are enough to locate a page and never enough
  to encode a constraint from.
- **Exact repo bytes, changelogs, release notes** — `github-mcp`.
- **Anything else** — `WebFetch`.

MCP servers are deliberately absent from this skill's `allowed-tools`
so it does not fail closed on a machine without them. Prefer them when
present; fall back without ceremony when not.

**Record what was drilled and what was not.** The undrilled set is what
bounds the draft, and it is the part that gets lost if it is not written
down at the time. A brief that says "the REST surface was not drilled;
nothing in this skill describes it" is what stops the next reader
assuming the omission was an oversight.

Stop drilling when new pages stop changing the outline, not when the
source list is exhausted.

## 5. Write the handoff brief

The target is `docs/handoff-briefs/<name>.md`, built from
`docs/handoff-briefs/skill-handoff-template.md`.

**Check whether that path is already occupied before writing a byte.**
A `/drift-update` escalation leaves its scoping input at exactly this
name, so the file that authorizes the work and the file this step
produces collide by default. Such a file is normally untracked, which
makes an overwrite unrecoverable — git has nothing to restore.

If something is there, read it in full and treat it as source rather
than as an obstacle. Carry across everything that outlives it — the
authorization, the audit evidence, the undrilled set, and anything
citing a gitignored path that will not survive on its own — then
confirm with the user that the file may be replaced. **Never overwrite
a brief path unread.**

**Every heading in the template survives into the filled brief.**
Sections that do not apply get `N/A — <brief reason>` under the heading,
never deletion.

**Strip the per-section `> Guidance:` notes.** They are instructions for
filling the template, not content, and a brief that keeps them reads as
half-finished. Exactly two blocks are reproduced verbatim: the guidance
note directly under the title, and Claude Code's post-draft checklist.
`docs/handoff-briefs/author-skill.md` is the reference — two guidance
blocks in the finished brief, not one per heading.

Fill `Last verified` with today's date.

The brief is not ceremony and not a handoff to another surface. It is
the record of what was decided and what was deliberately left out, and
the excluded set is the half that cannot be reconstructed from the
finished skill. Write it before drafting even though the same session
does both — the ordering is what makes the scope decisions explicit
instead of emergent.

If an existing brief in `docs/handoff-briefs/examples/` matches the new
skill's shape, lift it as design source and record that lineage in
`Changes from source proposal` using the wording that
`examples/README.md` specifies, rather than re-narrating the design.

Show the brief to the user before drafting from it.

## 6. Draft the SKILL.md

Write `skills/<name>/SKILL.md` from the brief.

**The `description` is the entire model-invoked trigger mechanism.**
Write it to fire on the queries the skill should answer — the user's
vocabulary, error strings, tool and command names — not to summarize the
body. A description that reads as an accurate abstract and never
triggers has failed at its only job. Where the skill neighbours another,
spend a clause on the disambiguation.

**Long detail goes to `skills/<name>/references/`, not the body.** Root
`CLAUDE.md` is explicit about this. Command flag tables, per-item-type
matrices, and long worked examples belong in a reference file the body
points at. The linter caps the body at 500 lines, but that is a
backstop, not a target.

Match the house voice: numbered steps, bold lead-ins for the rule being
stated, an explicit constraints section at the end, and reasons attached
to rules that would otherwise look arbitrary.

**Nothing goes in that drilling did not establish.** A plausible claim
with no source behind it is the failure mode this whole procedure exists
to prevent. If something is believed but unverified, mark it as such
inline with the date and version, the way `/learn` does, so a later
`/drift-audit` can confirm or remove it.

## 7. Post-draft checks

Run all four. Each catches something the others do not.

```
uv run --with pyyaml scripts/lint-frontmatter.py skills/<name>/SKILL.md
```

**Re-count the description.** The linter reports overflow only after the
fact, and it does not warn on the near miss:

```
uv run --with pyyaml python -c "import sys,yaml; print(len(yaml.safe_load(open(sys.argv[1],encoding='utf-8').read().split('---')[1])['description']))" skills/<name>/SKILL.md
```

Target ≤ 1,024 for portability. Re-count after *any* wording change,
not once at the end.

**`cat` the whole file after any edit.** YAML frontmatter is a single
malformed line away from the skill silently not loading, and the Edit
tool on Windows is where that line comes from.

```
pre-commit run --all-files
```

## 8. Register it in skills/README.md

Add the entry to the section the namespace implies — Behavioral,
Microsoft Fabric platform, or Power BI Desktop / Reports. Update the
count in the section heading where one is present.

Match the house style there: what the skill covers, and — where the name
is not self-evident — **why it is named that**. The `drift-audit` and
`drift-handoff` entries are the model for the second half. An entry that
only restates the description earns nothing the description does not
already do.

This is the one place this skill edits a file it did not create. Keep
the diff to the single added entry and the count.

## 9. Report, sweep, hand off

Report:

1. **What was drilled and what was not.** The undrilled set, verbatim
   from the brief.
2. **The scope decisions** — what the skill deliberately does not cover,
   and why.
3. **Check results** — lint, description count, `pre-commit`.
4. **That the skill is not behaviourally tested.** Say it plainly. A
   changed `SKILL.md` does not reliably reload mid-session on Windows,
   so trigger behaviour cannot be validated in the session that wrote
   it. Name the specific queries it should fire on, so the fresh-session
   test is runnable rather than aspirational.

Then **sweep `docs/handoff-briefs/`** for briefs whose work has landed.
The convention is that open briefs sit at that level and are deleted
once the change lands, or promoted into `examples/` when they are worth
keeping as design source. That convention has already failed once
unattended, which is why the sweep is a step here instead of a habit.

- The brief written at step 5 **stays open**. `examples/` holds briefs
  derived from *validated* artifacts, and nothing is validated until the
  fresh-session test has run.
- For any other brief whose skill or subagent now exists, **propose**
  deletion or promotion and name which. Do not delete anything without
  the user saying so — a brief is cheap to keep and impossible to
  recover.

Hand off to `/commit`. Do not commit here.

## 10. Constraints

- **No unverified claims.** If step 4 did not establish it, it does not
  go in the skill. Marked-unverified is the only exception, and it
  carries a date.
- **The stop cases in steps 1 and 2 are stops.** Route to `/learn`,
  propose an extension, or hand off to a generic authoring skill — do
  not author anyway.
- **Name before drilling.** Naming and the one-skill-or-two call go to
  the user first; both are cheap now and expensive after a draft exists.
- **Brief before draft**, even in one session.
- **No test fixtures.** `tests/` is a separate, deliberate exercise.
- **No commit**, no push.
- **Do not edit other skills.** Only `skills/<name>/`, the new brief, and
  the single `skills/README.md` entry. `Edit` is available for those two
  existing files and nothing else — adjacent cleanups are `/learn` and
  `/simplify` territory, and an unbriefed edit made here has no evidence
  behind it.
- **Deletion is the user's call.** Step 9 proposes; it does not sweep
  files away.
