# Skill handoff brief: linkedin-highlights

Last verified: 2026-09-10

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

`skills/workflow/linkedin-highlights/SKILL.md`, plus two reference files:

- `skills/workflow/linkedin-highlights/references/repo-evidence.md`
- `skills/workflow/linkedin-highlights/references/highlights-format.md`

Deploys by junction to `~/.claude/skills/linkedin-highlights/` via
`./scripts/link-claude.ps1 -SkillGroups workflow` — never bare. The
skill is **new**, so it has no junction until that run: until then it is
absent from every listing and `/linkedin-highlights` answers
`Unknown command`.

`skills/workflow/` is the correct tree because the skill acts on **the
user's own work in any repo**, not on agent-config. It must fire from a
session sitting inside a work repo, which is exactly the argument that
keeps `code-review` and `commit` deployable. It is the third skill in
that group and the listing cost is accepted knowingly.

## Scope

Takes a git repo the user worked in and produces the prose for one
LinkedIn role's **Highlights** field — a single free-text box, capped at
2,000 characters, prompting "Projects, problems you solved, or results
you achieved". The skill reads the repo's own documentation before its
git history, builds a deliverable inventory that counts *items* rather
than *files*, sorts every candidate claim by evidence strength, returns
the impact numbers the repo cannot support as questions to the user
rather than inventing them, and scrubs the finished draft against the
local identity denylist before emitting it. Runs **inline**, is
model-invocable (`disable-model-invocation: false`), and carries **no**
`paths:` glob — a glob would withhold it from the startup listing and
make `/linkedin-highlights` unreachable cold, which is the opposite of
what a user-typed career task needs.

## Sources drilled

Drilled:

- **The user's own screenshot of the LinkedIn "Edit role" dialog**
  (2026-09-10) — primary evidence, and the best available. Establishes
  that the field is labelled **Highlights**, is a single plain textarea
  with no formatting toolbar, carries the helper text "Projects,
  problems you solved, or results you achieved", and shows a live
  counter reading `0/2,000`. The 2,000 cap rests on this, not on any
  article.
- **`https://www.linkedin.com/in/<the user's profile>`** via WebFetch,
  2026-09-10 — established what is reachable unauthenticated: the About
  headline, location, current organization, follower/connection counts
  and the full certifications list render; the **Experience section
  returns role locations with no titles and no description text**. So
  prior-role Highlights prose is behind the auth wall and cannot be read
  by this skill or by its author. Style exemplars must come from the
  user.
- **LinkedIn Pulse / advice articles via WebSearch**, 2026-09-10 —
  corroborate the 2,000 cap and supply the formatting conventions:
  bullets are not a supported rich-text feature but a literal U+2022
  character the author types; blank lines between paragraphs survive;
  pasting from Word / Notion / Google Docs can destroy line breaks
  because the editor is rich-text HTML handling plain-text paste poorly;
  the profile telescopes a long description behind "see more", loading
  the opening lines disproportionately; 3–5 bullets per role is the
  common convention. **All of this is user-generated content, not
  official LinkedIn Help** — see Not drilled.
- **`claude/hooks/identity-guard.sh`** (repo source, read directly) —
  establishes the denylist contract exactly: the file is
  `~/.config/identity-denylist.txt` with `IDENTITY_DENYLIST` as an
  override; entries are **one literal per line, matched as a
  case-insensitive fixed string**; `#` comments and blank lines are
  dropped; `exempt: <path-prefix>` names repo roots where the guard
  **skips the entire run** (`exit 0`); a missing denylist **fails open**.
  It scans only the added lines and messages of `git commit` and
  `git push`.
- **The denylist itself, probed for membership without printing it**
  (2026-09-10) — 12 active entries, 1 `exempt:` line. Of three probes,
  the organization's short-form abbreviation and a second repo's name
  are listed; the full company name is **not**. That asymmetry is
  correct and is the model the skill should reason from: the employer
  name is public — it is the profile's own Organization field — while
  internal identifiers are not.
- **A real sole-authored work repo, 363 commits, June–September 2026**
  (structure and history only; no file contents beyond word counts) —
  established the evidence-quality facts the extraction method is built
  on. Conventional-commit prefixes appear on roughly **14 of 363**
  commits, so commit-subject mining is unreliable. The repo's own docs
  are substantial by comparison (a 5,533-word / 31-heading architecture
  document, a 2,208-word README, a 1,607-word contributing guide).
  Whole-history line totals are ~684k insertions against ~219k
  deletions — a **trap number**, inflated by generated item
  serialization.
- **The file-count-versus-item-count trap, measured and then verified a
  second way by an independent command** (2026-09-10) — the finding the
  skill is built around. In that repo a naive per-extension or
  per-directory-suffix count yields *91 Reports, 48 Warehouses, 23
  Semantic Models*; the true counts are **1, 1 and 1**, because Fabric
  and PBIR serialization explode one item into dozens of files. The
  honest inventory is 4 workspaces, 14 notebooks, 8 eventstreams, 2 KQL
  databases, 2 data pipelines, and one each of report, warehouse,
  semantic model, eventhouse and lakehouse.

Not drilled:

- **Official LinkedIn Help documentation for profile-field limits and
  formatting.** One Help URL was attempted and returned HTTP 404; no
  official page was located. Everything in the format reference beyond
  the 2,000 cap — the 200-character minimum, the bullet-character
  mechanic, the "see more" telescoping, and the rich-text paste
  behaviour — rests on user-generated LinkedIn articles and **must be
  written into the skill marked as convention, dated, not as verified
  platform behaviour**.
- **Whether "Highlights" is the same field as the "description" older
  articles describe.** The screenshot shows a field named Highlights
  with a 2,000 cap; the articles describe an Experience "description"
  with the same cap. Same limit, possibly a rename, possibly two
  fields. Not established. The skill should describe the field as the
  screenshot shows it and avoid asserting the equivalence.
- **Any LinkedIn API or MCP server** for reading or writing profile
  data. Deliberately deferred — the user raised it as a separate
  question. Nothing in this skill assumes programmatic profile access;
  its output is text the user pastes.
- **Resume / CV bullet conventions**, and any format other than this one
  field. Out of scope by decision.
- **Multi-author attribution beyond an author filter**, and non-git
  repos. The design case is a repo the user substantially or solely
  authored. The skill establishes authorship and stops if it cannot.
- **The user's prior-role Highlights text.** Not readable (auth wall),
  and by the user's decision not committed here either. The format
  reference carries an abstracted spec plus one **synthetic** worked
  example, not real entries.

## Frontmatter

```yaml
---
name: linkedin-highlights  # repo linter requires it; lowercase/digits/hyphens; no "anthropic"/"claude"
description: {{see Description char count — drafted at step 6, counted before commit}}  # gated at 1,024, the Agent Skills spec cap
when_to_use: {{optional second field, gated separately at 512}}
argument-hint: "[repo-path]"  # autocomplete hint in the / menu
disable-model-invocation: false  # ALWAYS PRESENT; repo policy: false everywhere
allowed-tools: Read Grep Glob AskUserQuestion Bash(git log *) Bash(git ls-files *) Bash(git shortlog *) Bash(git show *) Bash(git rev-parse *)  # space form per template; permission pre-approval only, not a restriction
# model: inherit  # ALWAYS PRESENT but COMMENTED — an active model: key of any value blocks GitHub Copilot slash dispatch
effort: max  # ALWAYS PRESENT; pinned as a floor, not to match the session default
context: inline
---
```

`effort: max` is a deliberate pin rather than an inherit. The repo's
stated policy pins `max` on the skills that drive this repo, and this
one does not — but the pin is a **floor**, and it earns its place on
consequence rather than on ownership: the output is public, permanent
in practice, and wrong in two directions that are both expensive. An
inflated claim is checkably false to a peer in the field; a leaked
internal identifier cannot be recalled once posted. Neither failure has
a cheap reversal, which is the same argument that pins `code-review`.

No `paths:` glob, deliberately. This skill must be reachable cold by
name from a session in any repo.

## Description char count

- `description`: {{N}} / 1,024 — **count after drafting and before
  commit**; the trigger surface has to carry the user's vocabulary
  ("LinkedIn", "job description", "role description", "Highlights",
  "Experience section", "what did I accomplish"), the anti-inflation and
  scrub behaviours, and the resume exclusion, so it will run long and
  needs a real measurement rather than an estimate.
- `when_to_use`: {{N / 512 | N/A — not set}}

## Body structure outline

1. **Scope and stop conditions** — this one field only. Stop if the
   target is a resume, a CV, a cover letter or a LinkedIn post. Stop if
   the repo is not a git repo, or if authorship cannot be established.
2. **Step 1 — Fix the role boundary.** Which repo, which role, which
   date range. Establish authorship with `git shortlog -sne` and filter
   history by author and date, so a multi-author repo cannot attribute
   someone else's work. Tenure bounds claim size: a three-month role
   cannot support a multi-year narrative, and the date range is the
   check on that.
3. **Step 2 — Read the docs before the history.** README, ARCHITECTURE,
   CONTRIBUTING and any `docs/` tree state purpose and design intent in
   the author's own words; git history cannot. Cite the measured
   asymmetry as the reason — a 5,533-word architecture document against
   conventional-commit prefixes on 4% of commits.
4. **Step 3 — Build the inventory, counting items and not files.** The
   centerpiece. State the trap with its numbers (91/48/23 naive against
   1/1/1 true), give the counting rule — count the distinct item
   *directories*, not the files beneath them — and require every count
   be verified a second way by a different command before it reaches
   prose. Name the sibling trap: whole-history insertion counts are
   generated-content artefacts and never a claim.
5. **Step 4 — Sort claims by evidence strength.** Three tiers.
   (a) Countable from the repo now. (b) Documented as design intent in
   the repo's own docs. (c) Knowable only to the user — users served,
   uptime, cost, hours saved, business outcome, team size, stakeholders.
   Tier (c) never becomes prose from inference.
6. **Step 5 — Ask for what the repo cannot know.** Put tier (c) to the
   user as a short explicit question list. Do not silently emit prose
   with placeholders, and do not quietly drop the claim either — a
   Highlights entry with no outcome in it is the common failure this
   step exists to prevent.
7. **Step 6 — Draft to the format.** Points at
   `references/highlights-format.md`. Budget 2,000 characters including
   spaces; front-load the opening lines against telescoping; emit
   literal `•` characters and real line breaks rather than markdown
   list syntax; plain text only.
8. **Step 7 — Scrub before emitting.** Points at the denylist contract.
   Read `~/.config/identity-denylist.txt`, honouring `IDENTITY_DENYLIST`.
   Match case-insensitively as fixed strings. **Deliberately ignore
   `exempt:` lines** — the rule and its reason are the most important
   sentence in the skill. Follow with a heuristic sweep for what a
   12-entry list cannot know: tenant GUIDs, internal hostnames and
   server names, workspace and environment names, account names,
   internal URLs, customer names. If no denylist exists the hook fails
   open — this skill must **not**: say so and scrub heuristically anyway.
9. **Step 8 — Emit with a character count and a paste warning.** Report
   `N/2,000`. Warn that pasting through a rich-text editor can destroy
   the line breaks, so the text should go in as plain text.
10. **Constraints.**

Reference split, per the scope decision:

- `references/repo-evidence.md` — the extraction procedure end to end:
  author filtering, doc-first ordering, the item-versus-file counting
  rule with its worked numbers, trap numbers, and the three-tier
  classification. Written to be reusable, so a future resume skill
  points at it rather than re-deriving it.
- `references/highlights-format.md` — the field spec: the 2,000 cap and
  its primary source, the convention-sourced items each marked as such
  and dated, and **one synthetic worked example** using invented
  organization and item names.

## Changes from source proposal

Departures from the proposal put to the user in conversation:

1. **Name** chosen as `linkedin-highlights` from three candidates. The
   house rule is "name the job, not the target" — here the target *is*
   the job, since the cap, the register and the field prompt all come
   from LinkedIn, and a later resume skill then sits beside it with a
   disjoint trigger surface rather than competing for one.
2. **Style exemplars are abstracted, not committed.** The proposal
   assumed the user's real prior-role entries would live in
   `references/`. The user's call was a format spec plus a synthetic
   sample, for repo cleanliness rather than privacy. This is the better
   outcome regardless: it keeps the skill portable instead of personal,
   and it survives the profile being unreadable.
3. **Extraction split into `references/` now** rather than left inline
   against a possible future resume skill.
4. **The `exempt:`-ignoring rule was discovered during drilling and is
   new.** The original proposal said only "scrub against the denylist".
   Reading the hook showed the guard skips exempt repo roots entirely
   and only ever scans git operations — so inside a work repo the
   existing protection is doubly absent, and a scrub that inherited
   `exempt:` would inherit the wrong semantics. Exempt means "this name
   belongs in this repo", never "this name belongs on the public
   internet".
5. **Profile access was measured rather than assumed.** Partial, not
   nil — which changes nothing about the design but retires the
   question.

## Tag

`personal` — v1 default, and the subject is the user's own career.
Worth noting the artifact is structurally `publishable`: by the
exemplar decision above, nothing in the skill or its references is
specific to this user, this employer or this repo.

## Portability caveats

Two, both machine-local rather than harness-specific:

- The scrub reads `~/.config/identity-denylist.txt`, a file that exists
  on this machine by convention and in no repo. On a machine without it
  the skill must degrade to the heuristic sweep and say so, never
  silently skip the gate.
- The evidence commands are `git` through Bash. Nothing depends on
  PowerShell, `context: fork`, hooks, or an `effort` level beyond the
  standard set.

## Cross-reference dependencies

- `claude/hooks/identity-guard.sh` — **(a) already exists.** Not
  invoked; the skill shares its denylist file and reimplements the
  matching contract, deliberately diverging on `exempt:`. A change to
  the denylist format is a future-edit dependency on this skill.
- A future `resume-bullets` (or similarly named) skill — **(b) pending,
  not authored.** `references/repo-evidence.md` is written to be its
  extraction source. Nothing in this skill blocks on it.
- `/commit` — **(c) standard.** Only as the handoff at the end of
  authoring, not a runtime dependency.

## Claude Code's post-draft checklist

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**The scrub is the reason this is a skill and not a prompt.** Every
other step is careful writing that a capable model does reasonably well
unaided. The scrub encodes something no unaided run would reconstruct:
that `identity-guard` gates `git commit` and `git push` only, that it
skips exempt repo roots wholesale, and that the one path carrying
client-repo internals into public text therefore passes no gate at all.

**Two denylisted literals were kept out of this brief on purpose.** The
organization's short-form abbreviation and a second repo's name are on
the list, so the work repo is referred to descriptively throughout and
the worked example uses invented names. This is the guard working as
designed on the brief itself.

**Style exemplars are still owed.** The user will supply one or two real
entries to derive the format spec from; the abstracted spec and the
synthetic sample are written from those and the real text is not
retained. Drafting `references/highlights-format.md` is blocked on that
input; nothing else in the skill is.

## Confidence

- **Structure — H.** Tree, group, naming and the reference split follow
  settled repo convention and were confirmed with the user before
  drilling.
- **Field specs — H.** All frontmatter values are repo policy or
  template-documented; the one judgment call (`effort: max`) is argued
  above rather than assumed.
- **Body content, extraction half — H.** Every claim is measured
  against a real repo and the load-bearing one was verified twice by
  independent commands.
- **Body content, format half — M.** The 2,000 cap has primary
  evidence. Everything else about the field's behaviour comes from
  user-generated articles with no official page located, and must ship
  marked as convention and dated. The Highlights-versus-description
  question is open.
