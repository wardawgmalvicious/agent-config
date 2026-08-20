---
name: learn
description: "Use when the user says 'learn!', 'capture this', 'update the skill', 'remember this for next time', or when a session surfaces a non-obvious pitfall, a doc-vs-reality gap, or a missing step in a skill/rule that was in use. Routes session learnings back into this repo's persistent guidance — skills/*/SKILL.md (+ references/), rules/coding-*.md, CLAUDE.md — rather than auto-memory. Automatically identifies which skills and rules were loaded during the session, checks for existing coverage (especially fabric-gotchas), verifies the learning against official docs before encoding it, proposes the edit at the right heading as a diff for approval, then hands off to /commit. Never edits silently, never writes domain knowledge to memory."
---

# Learn: capture session learnings into skills and rules

Turn something discovered during this session into a durable, verified
edit to the guidance that *should* have covered it. The goal is that the
next session never has to rediscover it.

This skill **proposes**; it does not commit. Edits land only after the
user approves the diff, and committing is handed to `/commit`.

## Step 1 — Identify what was learned

Reflect on the session, not just the last message. Candidate learnings:

- A skill or rule said X; reality was Y (doc-vs-reality gap).
- A step was missing and cost debugging time.
- An error message whose cause was non-obvious.
- A constraint / limit / version change not documented anywhere here.
- A user correction that reveals a general principle.

For each candidate, state in one or two sentences: **problem → root
cause → correct approach → generalization**. Drop anything that is
one-off, already obvious from the code, or only matters to this
conversation. Confirm the list with the user before proceeding if it
contains more than one item or you're unsure which matters.

## Step 2 — Identify which guidance was in use (automatic)

Do **not** ask the user which skill was used. Reconstruct it:

1. **Skills invoked this session** — every `Skill` tool call and every
   skill whose content appears in context (the `<command-name>` /
   loaded-skill blocks). Record the `name:` of each.
2. **Rules auto-loaded** — any `rules/coding-*.md` content present in
   context, triggered by files in session scope (`paths:` globs).
3. **CLAUDE.md sections** relied on — e.g. the Fabric serialization
   or `uv` guidance.
4. **Tools used** — MCP servers / CLIs (`fab`, `pbir`, fabric-cicd,
   Fabric REST) point at the skill that owns them even if it wasn't
   explicitly invoked. Map by the skill's `description`.
5. If nothing was loaded but a skill *should* have triggered, that is
   itself a learning: the fix is the skill's `description` (trigger
   phrases), not its body.

Output a short table: `learning → owning skill/rule → section`.

## Step 3 — Map to the destination

| Learning is… | Destination |
| --- | --- |
| Domain procedure, API shape, syntax, gotcha for one product area | `skills/<name>/SKILL.md` at the heading where it belongs; detail or long examples go in `skills/<name>/references/REFERENCE.md` |
| Cross-product troubleshooting symptom (error text → cause) | `skills/fabric-gotchas/SKILL.md` **and** a one-line cross-reference from the owning skill |
| Language / style convention that should apply whenever a file type is open | `rules/coding-<lang>.md` (path-scoped via `paths:`) |
| Environment or repo-wide constraint for every session | `CLAUDE.md` — then mirror to `~/.claude/CLAUDE.md` by hand (it is a copy, not a junction) |
| Skill didn't trigger when it should have | the skill's frontmatter `description` (≤ 1024 chars, see `scripts/lint-skills.py`) |
| Fact about the **user** or their workflow preference | auto-memory (`~/.claude/projects/.../memory/`) — never domain knowledge |

Weave the learning into the existing structure. Do **not** append a
`## Learnings` changelog section — skills here are curated reference,
not logs. Update the relevant heading, table row, or gotcha entry so a
reader finds it where they'd look.

## Step 4 — Check existing coverage

Before writing anything:

```
grep -rn -i "<key term>" skills/ rules/ CLAUDE.md
```

- Already covered correctly → nothing to do; say so.
- Covered but wrong or stale → the edit is a **correction**; quote the
  current text in the proposal.
- Covered in `fabric-gotchas` but missing from the owning skill (or
  vice versa) → add the cross-reference only.

`fabric-gotchas` is the natural magnet for everything; guard against
duplicates there most carefully.

## Step 5 — Verify before encoding

A thing that failed once is not yet a rule. Before proposing, confirm
at least one of:

- Official docs (`microsoft_docs_search` / `microsoft_docs_fetch`, or
  the library's README / changelog) state or corroborate it.
- A second reproduction in the session (different input, same result).
- The user explicitly confirms it's known behaviour, not a fluke.

If it can't be verified, still propose it but mark it clearly as
**unverified** in the text (e.g. "Observed Aug 2026 with v1.3; not yet
documented") so a future `drift-audit` can confirm or remove it.
Include the date and version where relevant — these learnings age.

## Step 6 — Propose the edit

For each learning, show the user:

1. Destination file and heading.
2. The exact text to add / replace, as a diff or before/after block.
3. Verification source (link, or "unverified — see note").

Keep the addition as short as a reader needs: typically 1–6 lines in
`SKILL.md`, with anything longer in `references/`. Match the surrounding
voice and formatting. If a `description` is edited, state the new
length.

Wait for approval. Apply only what is approved, using `Edit` so the
rest of the file is untouched. Then run:

```
uv run --with pyyaml scripts/lint-skills.py skills/<name>/SKILL.md
```

## Step 7 — Hand off

Report what changed and where, then hand off to `/commit` (do not
commit yourself). Suggested subject shape:

- `docs(fabric-cicd): note parameter.yml regex is case-sensitive`
- `fix(fabric-gotchas): correct cause of 24556 snapshot conflict`
- `feat(rules): add KQL materialize() guidance`

If `CLAUDE.md` changed, remind the user to mirror it to
`~/.claude/CLAUDE.md`.

## Example (illustrative — not a real fabric-cicd fact)

Session: user deployed with fabric-cicd; `publish_all_items` skipped a
Warehouse because the item folder name contained a space, which the
skill didn't mention. Docs confirm folder names must match item
display names exactly.

```
learning → owning skill → section
folder name with space skipped silently → fabric-cicd → "Per-item-type caveats"
```

Proposal:

> **skills/fabric-cicd/SKILL.md → ## Per-item-type caveats**
> ```diff
> + - **Folder names must match the item display name exactly** — a
> +   mismatch (including whitespace) is skipped with no error; check
> +   `change_log_level("DEBUG")` output. (Docs: <link>, verified v1.3.)
> ```
> Also add to `fabric-gotchas` under "Deployment" as a one-liner
> pointing here.

Not a learning (skip): "the deploy took four minutes" — one-off,
not actionable.
