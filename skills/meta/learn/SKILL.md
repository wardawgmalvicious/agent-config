---
name: learn
model: fable  # judgment-heavy; active because skills/meta/ never reaches Copilot
effort: max
disable-model-invocation: false
description: "Routes a session learning into the durable guidance that should have covered it — a SKILL.md and its references/, a path-scoped rule, a CLAUDE.md — rather than into auto-memory. Reconstructs which skills and rules were actually loaded instead of asking, checks existing coverage before writing, verifies the learning against official docs or a second reproduction, and proposes the edit as a diff at the heading where a reader would look. Never edits silently, never writes domain knowledge to memory, never appends a changelog section. Inside the repo that sources ~/.claude it edits the payload directly and hands off to /commit. In any other repo it edits nothing and writes a dated note to the local handoff inbox instead, because the guidance lives in a repo that session is not in. To create guidance that has no home yet, use author-skill."
when_to_use: "Use when the user says 'learn!', 'capture this', 'update the skill', 'remember this for next time', or when a session surfaces a non-obvious pitfall, a doc-vs-reality gap, a wrong or stale claim in guidance that was in use, or a missing step that cost debugging time. Use it in any repo — outside the payload repo it captures the learning to the handoff inbox rather than dropping it, which is the case it exists for."
---

# Learn: capture session learnings into skills and rules

Turn something discovered during this session into a durable, verified
edit to the guidance that *should* have covered it. The goal is that the
next session never has to rediscover it.

This skill **proposes**; it does not commit. Edits land only after the
user approves the diff, and committing is handed to `/commit`.

The inverse skill is `/author-skill`: `/learn` folds a learning into
guidance that already exists, `/author-skill` creates guidance that has
no home yet. If the right destination for a learning turns out to be a
skill that does not exist, that is an `/author-skill` job.

## Step 0 — Which repo is this?

**The guidance this skill edits lives in one repo.** Skills, rules and
the user-scope `CLAUDE.md` are deployed into `~/.claude` from a single
source checkout, whose path `~/.claude/CLAUDE.md` names. Editing
`~/.claude` directly is pointless — the next deploy overwrites it — so
the source checkout is the only real destination.

This skill is deployed payload, so it fires in **every** session on the
machine, and most of them are not in that repo. Establish which case
you are in before anything else:

```bash
git rev-parse --show-toplevel
```

| Where | Mode | What happens |
| --- | --- | --- |
| Inside the payload checkout | **edit** | Steps 1–5, then Step 6 proposes the diff, Step 8 hands off to `/commit` |
| Any other repo, or none | **note** | Steps 1–5, then Step 7 writes a note to `~/handoff-inbox/<target-repo>/` and notifies a live session there |

**In note mode, edit nothing outside the current workspace** — not the
payload checkout, not `~/.claude`, not another repo's files. Reading the
payload to shape the note is fine, and Step 4 asks for exactly that;
writing to it is not, and neither is copying the note into it yourself.
A later session inside that repo does both.

**Note mode is not a degraded mode.** The analysis — what was learned,
which guidance owns it, whether it is already covered, whether it is
verified — is the expensive part, it is only possible in the session
that hit the problem, and it is precisely what is lost if a learning
waits for someone to be in the right repo. Do all of it. The single
thing note mode gives up is applying the edit.

A learning about the **current** repo's own committed guidance — its
`CONTRIBUTING.md`, its `.claude/rules/`, its own `CLAUDE.md` — is that
repo's business, not this skill's. Say so and let the user decide; don't
route it to the inbox, which carries a learning to a repo the session is
*not* in.

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
2. **Rules auto-loaded** — any rule content present in context,
   triggered by files in session scope (`paths:` globs). It appears
   under its deployed path, `~/.claude/rules/`.
3. **User-scope `CLAUDE.md` sections** relied on — e.g. the `uv`
   guidance or a serialization rule.
4. **Tools used** — MCP servers / CLIs (`fab`, `pbir`, fabric-cicd,
   Fabric REST) point at the skill that owns them even if it wasn't
   explicitly invoked. Map by the skill's `description`.
5. If nothing was loaded but a skill *should* have triggered, that is
   itself a learning: the fix is the skill's `description` (trigger
   phrases), not its body.

**Record a skill by its `name:`, not by the path you saw it at.** A
deployed skill sits at `~/.claude/skills/<name>/`, flat — the payload's
group segment (`fabric`, `powerbi`, `workflow`) is not visible there, so
a path copied out of context names a directory the source repo does not
have. Step 3 resolves the group; in note mode the receiving session
does.

Output a short table: `learning → owning skill/rule → section`.

## Step 3 — Map to the destination

Paths below are relative to the **payload checkout**, in both modes. In
note mode you name the destination; you do not open it for writing.

| Learning is… | Destination |
| --- | --- |
| Domain procedure, API shape, syntax, gotcha for one product area | `skills/<group>/<name>/SKILL.md` at the heading where it belongs; detail or long examples go in `skills/<group>/<name>/references/REFERENCE.md` |
| The payload repo's own procedure — the drift pipeline, authoring, testing | `.claude/skills/<name>/SKILL.md` — project scope there, live on save, no deploy step |
| Cross-product troubleshooting symptom (error text → cause) | `skills/fabric/fabric-gotchas/SKILL.md` **and** a one-line cross-reference from the owning skill |
| Language / style convention that should apply whenever a file type is open | `claude/rules/coding-<lang>.md` (path-scoped via `paths:`) |
| Environment or machine-wide constraint for every session | `claude/CLAUDE.md` — a copy, not live until the deploy script runs; see Step 8 |
| Skill didn't trigger when it should have | the skill's frontmatter `description` (≤ 1024 chars) |
| Fact about the **user** or their workflow preference | auto-memory (`~/.claude/projects/.../memory/`) — never domain knowledge |

Weave the learning into the existing structure. Do **not** append a
`## Learnings` changelog section — skills here are curated reference,
not logs. Update the relevant heading, table row, or gotcha entry so a
reader finds it where they'd look.

## Step 4 — Check existing coverage

Before writing or proposing anything, find out whether it is already
there. In **edit mode**, from the repo root:

```bash
grep -rn -i "<key term>" skills/ .claude/skills/ claude/rules/ CLAUDE.md claude/CLAUDE.md
```

In **note mode**, grep the payload checkout read-only at the path
`~/.claude/CLAUDE.md` names. If it isn't readable from here, fall back
to the deployed tree:

```bash
grep -rn -i "<key term>" ~/.claude/skills/ ~/.claude/rules/ ~/.claude/CLAUDE.md
```

**A hit in `~/.claude` proves coverage; a miss proves nothing.**
Deployment prunes — a skill group left off the deploy command is absent
from `~/.claude/skills` while being present in the payload — so the
destination skill for a Fabric or Power BI learning is routinely not
there at all. Record which tree you searched, and never report "not
covered" off the deployed tree alone.

**Grep one distinctive token, not a phrase.** Prose here is hard-wrapped
at 76 columns, so a multi-word term is routinely split across lines and
`grep` cannot match it. On 2026-09-12 a search for "Microsoft 365 group"
reported absent what was sitting in the file, wrapped after "Microsoft
365" — a false "not covered" that would have landed as a duplicate.

**When Step 3 left the destination genuinely ambiguous** — two skills
both look like the owner — ask which of them already holds the
vocabulary rather than choosing by feel. In **edit mode** only, since it
runs the payload repo's own tooling:

```bash
uv run --with pyyaml scripts/skill-overlap.py overlap --skill <candidate>
```

A high-scoring pair between the two candidates says they already compete
for the same requests, and that the learning belongs in whichever of them
the shared tokens came from. Only reach for this when the mapping is
actually unclear; where Step 3 gave one obvious owner, it adds nothing.

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

**Check the shape of the command that took the measurement.** `$?`
after a pipeline — `cmd 2>&1 | head; echo $?` — is `head`'s, with
`cmd`'s error text laid beside it by the `2>&1`, so the message is real
and the code is not; read the bare command or `${PIPESTATUS[0]}`. And
record which **stream** a message was on: stderr is invisible to
`$(...)` and to `| grep` without `2>&1`. This is how `gh pr checks` on a
no-CI repo was noted as exit 0 on 2026-09-16, verbatim from the
terminal, when it exits 1.

If it can't be verified, still carry it forward but mark it clearly as
**unverified** in the text (e.g. "Observed Aug 2026 with v1.3; not yet
documented") so a future `drift-audit` can confirm or remove it.
Include the date and version where relevant — these learnings age.

## Step 6 — Edit mode: propose the edit

Skip this in note mode; go to Step 7.

For each learning, show the user:

1. Destination file and heading.
2. The exact text to add / replace, as a diff or before/after block.
3. Verification source (link, or "unverified — see note").

Keep the addition as short as a reader needs: typically 1–6 lines in
`SKILL.md`, with anything longer in `references/`. Match the surrounding
voice and formatting. If a `description` is edited, state the new
length.

**Check `description` headroom before proposing a trigger phrase.** Many
skills sit within a few characters of the 1,024-char cap, so a new
phrase usually has to displace an existing one rather than extend the
line. Measure the current length first — the frontmatter linter only
reports the overflow after the edit is written. If the budget is tight,
name what to cut; if nothing can go, say so and leave the description
alone rather than silently dropping a trigger that already earns its
place.

Wait for approval. Apply only what is approved, using `Edit` so the
rest of the file is untouched. Then run the repo's frontmatter lint:

```bash
uv run --with pyyaml scripts/lint-frontmatter.py skills/<group>/<name>/SKILL.md
```

The same linter takes `.claude/skills/<name>/SKILL.md` and
`claude/rules/<name>.md`.

## Step 7 — Note mode: write the handoff note

Skip this in edit mode.

The learning is real and analysed, and the repo that owns its
destination is not this one. Write it to the local handoff inbox, which
is a plain folder in no repo, **one subdirectory per target repo**:

```
~/handoff-inbox/<target-repo>/<yyyy-mm-dd>-<topic>.md
```

`<target-repo>` is the directory name of the checkout the note is
addressed to — for this skill, the payload checkout that
`~/.claude/CLAUDE.md` names. Create the directory if it is not there.
The directory is the routing: a note loose in the inbox root is
un-routed, and that is the signal. The inbox's own `README.md` carries
the layout; read it before writing.

**The inbox is private and local, so record what you observed plainly,
including names from this workspace** — the whole point of it sitting
outside every repo is that raw notes have somewhere to go. But say
explicitly which parts are raw, because the session that lands this will
be writing into a repo that may be public, and it is that session's job
to scrub. A note that looks generalized but isn't is the failure mode.

**Then ring the doorbell.** A correctly written note nobody reads is
this inbox's own failure mode — three sat unread for a day from
2026-09-15. If `ListAgents` shows a live session whose name begins with
the target repo, `SendMessage` it one line: the note's path and what it
covers. The note is the artifact; the message is only a pointer to it,
so if no session is live there nothing is lost — the next one finds the
note from the start-of-session check in `~/.claude/CLAUDE.md`.

**Never ask that session to apply the note.** Landing it is that
session's user's call, not yours, and a peer cannot grant the
permission. The message names the note and stops.

Shape:

```markdown
# Handoff: <topic>

**Origin:** <what kind of repo or estate, generalized>. <Month Year>.
**For:** `/learn` in a session inside the payload repo.

**Sources, cited by kind.** <Whether anything below carries a workspace,
tenant, account or host name — so the landing session knows what needs
scrubbing, or that nothing does. Cite client evidence by kind, never by
name.>

**Coverage:** <What Step 4 found, and which tree it was searched
against, so it is not redone. Or: could not be checked, and why.>

Delete this note once its content has landed.

---

## The learnings

### 1. <one-line statement of the fact>

**Problem.** …
**Root cause.** …
**Correct approach.** …
**Generalization.** …
**Destination.** <file and heading from Step 3>
**Verification.** <Step 5's status — documented, reproduced, or
unverified, with the date and version>
```

One section per learning, in descending value. Keep measurements and
dates verbatim: prose can be rewritten later, a measurement cannot be
recovered.

## Step 8 — Hand off

**Edit mode.** Report what changed and where, then hand off to `/commit`
(do not commit yourself). Suggested subject shape:

- `docs(fabric-cicd): note parameter.yml regex is case-sensitive`
- `fix(fabric-gotchas): correct cause of 24556 snapshot conflict`
- `feat(rules): add KQL materialize() guidance`

Anything outside the skills tree deploys by copy, so an edit to a rule,
a hook or the user-scope `CLAUDE.md` is **not live until the deploy
script runs** — remind the user, and check the repo's own instructions
for the exact invocation, since running it bare can deploy more than
intended.

**Note mode.** Tell the user the note's full path, what it covers in one
line, and whether a live session in the target repo was notified. The
next step is `/learn` in a session inside the payload repo. Do not copy
the note into that repo yourself, and do not commit anything here.

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

> **skills/fabric/fabric-cicd/SKILL.md → ## Per-item-type caveats**
> ```diff
> + - **Folder names must match the item display name exactly** — a
> +   mismatch (including whitespace) is skipped with no error; check
> +   `change_log_level("DEBUG")` output. (Docs: <link>, verified v1.3.)
> ```
> Also add to `fabric-gotchas` under "Deployment" as a one-liner
> pointing here.

In note mode the same analysis is written to the inbox instead, with
that destination named rather than opened.

Not a learning (skip): "the deploy took four minutes" — one-off,
not actionable.
