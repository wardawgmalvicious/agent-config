---
name: linkedin-highlights
description: "Write the Highlights prose for one LinkedIn Experience role from a git repo the user worked in — the single free-text box, capped at 2,000 characters, prompting 'Projects, problems you solved, or results you achieved'. Reads the repo's own README and architecture docs before its git history, builds a deliverable inventory that counts items and not files (Fabric and PBIR serialization explode one item into dozens, so a naive count reads 91 reports where there is one), ranks every candidate claim by evidence strength, and puts the impact numbers a repo cannot know — users served, hours saved, cost, uptime, team size — back to the user as questions rather than inventing them. Scrubs the finished draft against the local identity denylist before emitting it, deliberately ignoring that list's `exempt:` lines."
when_to_use: "Use when asked to write, update or draft a LinkedIn role description, Experience entry, job description or Highlights field, or to turn a repo or a project into profile prose — 'what did I accomplish here', 'write this role up for LinkedIn'. Not for resumes, CVs, cover letters or LinkedIn posts; those are out of scope and this skill stops."
argument-hint: "[repo-path]"
allowed-tools: Read Grep Glob AskUserQuestion Bash(git log *) Bash(git ls-files *) Bash(git shortlog *) Bash(git show *) Bash(git rev-parse *) Bash(grep *) Bash(wc *)
# model: inherit  # any model: value blocks Copilot slash invocation
effort: max
disable-model-invocation: false
context: inline
---

# LinkedIn Highlights

Produce the prose for **one** LinkedIn Experience role's Highlights
field, from a git repo the user worked in.

The field is a single plain textarea — no formatting toolbar — capped at
**2,000 characters** and prompting *"Projects, problems you solved, or
results you achieved"*. Both facts come from the user's own screenshot of
the Edit-role dialog, 2026-09-10, which is the primary source for this
skill. Field mechanics and the format spec live in
[references/highlights-format.md](references/highlights-format.md); the
extraction procedure in
[references/repo-evidence.md](references/repo-evidence.md).

**The scrub in step 7 is why this is a skill and not a prompt.** Every
other step is careful writing an unaided model does reasonably well. The
scrub encodes something no unaided run would reconstruct: the
`identity-guard` hook gates `git commit` and `git push` only, and skips
exempt repo roots wholesale — so text carried out of a work repo onto a
public profile passes no gate at all.

## Scope and stop conditions

This skill writes **one field**. Stop and say so if:

- The target is a **resume, a CV, a cover letter, or a LinkedIn post**.
  Different length, different register, different conventions, and none
  of them were drilled. A resume skill may exist later and will read
  `references/repo-evidence.md`; it does not exist now.
- The target is **not a git repo**. The evidence method is git history
  plus committed docs. Without both there is nothing to extract from,
  and inventing the content is the failure this skill exists to prevent.
- **Authorship cannot be established** (step 1). Writing someone else's
  work into the user's profile is worse than writing nothing.

Multiple roles means multiple runs. Do not batch them: the character
budget is per role and the evidence boundary is per role.

## 1. Fix the role boundary

Settle three things before reading anything: **which repo, which role,
which date range.** Ask if any is unclear — the answers bound everything
downstream.

Establish authorship and filter by it:

```bash
git shortlog -sne --all
git log --author="<the user>" --since=<start> --until=<end> --oneline | wc -l
```

**Tenure bounds claim size.** A three-month role cannot support a
multi-year narrative, and the date range is the check on that. If the
user's commits sit outside the stated role dates, ask before proceeding
rather than quietly widening the window.

In a multi-author repo, every count from step 3 onward is filtered by
author. In a sole-authored repo say so explicitly in the draft — "sole
author" is itself a claim worth making, and it is checkable.

## 2. Read the docs before the history

**A repo's own documentation states purpose and design intent in the
author's words; git history cannot.** Read, in this order: `README`,
`ARCHITECTURE`, `CONTRIBUTING`, then any `docs/` tree.

The ordering is measured rather than stylistic. In the repo this skill
was built against — 363 commits, sole-authored, June–September 2026 —
conventional-commit prefixes appear on roughly **14 of 363** commits
(~4%), so commit-subject mining is unreliable. The same repo carries a
**5,533-word, 31-heading architecture document**, a 2,208-word README
and a 1,607-word contributing guide. The documentation is where the
substance is; history is corroboration and dating.

Use history for what docs cannot give: **when** work happened, **how
much** of it was the user's, and whether a documented intent actually
shipped.

## 3. Build the inventory — count items, not files

The centerpiece, and the one place a confident wrong number is easy to
produce.

**A naive per-extension or per-directory-suffix count is wrong by one to
two orders of magnitude.** Measured in that same repo: counting
directory suffixes yields *91 Reports, 48 Warehouses, 23 Semantic
Models*. The true counts are **1, 1 and 1**. Fabric and PBIR
serialization explode a single item into dozens of files — a PBIR report
is a directory tree of per-visual JSON, a warehouse a tree of per-object
definitions.

The rule: **count the distinct item *directories*, not the files beneath
them**, and verify every count a second way with a different command
before it reaches prose. The honest inventory for that repo was 4
workspaces, 14 notebooks, 8 eventstreams, 2 KQL databases, 2 data
pipelines, and one each of report, warehouse, semantic model, eventhouse
and lakehouse.

**Line totals are the sibling trap and never a claim.** Whole-history
insertions in that repo run ~684k against ~219k deletions. That number
is generated item serialization, not work done. Never put an insertion
count, a deletion count or a net-lines figure in the prose.

The counting commands, the second-check pattern, and the per-item-type
directory markers are in
[references/repo-evidence.md](references/repo-evidence.md).

## 4. Sort claims by evidence strength

Put every candidate claim in exactly one tier:

1. **Countable from the repo now** — item counts, date ranges, languages
   and platforms in use, sole vs. shared authorship. These can go in the
   prose as stated fact.
2. **Documented as design intent in the repo's own docs** — an
   architecture document's stated goal, a README's stated purpose. These
   go in as intent, phrased as what was *built to do*, not as what it
   *achieved*.
3. **Knowable only to the user** — users served, uptime, cost, hours
   saved, revenue, business outcome, team size, stakeholders, adoption.
   **Tier 3 never becomes prose from inference.** A repo cannot know any
   of it, and every one of these is checkably false to a peer in the
   field if guessed wrong.

Tier 3 goes to step 5. Never silently promote a tier-3 claim to tier 1
because it would read well.

## 5. Ask for what the repo cannot know

Put the tier-3 list to the user as a short, explicit set of questions —
`AskUserQuestion` where the options are enumerable, plain prose
otherwise. Ask for the two or three that would most change the draft,
not for everything at once.

Two failure modes to avoid, in both directions:

- **Do not emit prose with placeholders** — `[N] users`, `<X>% faster`.
  A placeholder that survives into the paste box becomes a public
  profile reading `[N]`.
- **Do not quietly drop the claim either.** A Highlights entry with no
  outcome in it — all activity, no result — is the common failure this
  step exists to prevent. If the user genuinely has no number, say so
  and write the outcome qualitatively instead.

Accept "I don't know" as an answer and move on; do not press twice.

## 6. Draft to the format

Full spec in
[references/highlights-format.md](references/highlights-format.md).
The load-bearing rules:

- **Write prose paragraphs, not bullets.** Three of the user's real
  entries were measured on 2026-09-10 and contain **zero** `•`
  characters and no list markers of any kind; structure is carried by
  paragraph breaks alone. Advice articles say "3–5 bullets per role";
  the real entries overrule them. Offer bullets only if asked.
- **Target ~1,500 characters, not 2,000.** The cap is 2,000 and the
  measured entries run 1,468–1,666 — every one leaves 330–530
  characters unused. Treat 2,000 as a ceiling you never approach.
- **3–4 paragraphs, one theme each**, 2–3 sentences per paragraph, 22–31
  words per sentence. This register is long-sentenced; a draft averaging
  15 words per sentence is in the wrong one.
- **Open paragraph 1 with `At <Organization>, I …`** and open later
  paragraphs on a framing adverbial rather than on "I".
- **Attach the outcome to the activity in the same sentence** — a
  trailing participial clause (`enabling…`, `eliminating…`, `giving…`)
  or an em-dash into the consequence. Two-thirds of the measured
  sentences do this. A sentence that names what was built and stops is
  not finished.
- **One hard number at most, as the closer.** Exactly one figure appears
  across all three measured entries, in the final sentence. Everything
  else is qualitative — which is what makes step 5's "don't drop the
  claim" achievable without inventing one.
- **Front-load.** The profile telescopes a long entry behind "see more",
  so the opening lines carry disproportionate weight.
- **Plain text only.** No headings, no bold, no links, no markdown.

Provenance differs across that list and matters when reporting to the
user. The 2,000 cap is primary evidence. The shape, register and
outcome rules are **measured from real entries**. The "see more"
telescoping is **convention from user-generated LinkedIn articles, dated
2026-09-10** — no official Help page was located — so present it as
such rather than as verified platform behaviour.

## 7. Scrub before emitting

**Nothing reaches the user's clipboard unscrubbed.** This is the step
that has no equivalent anywhere else in the toolchain.

Write the draft to a scratch file, then match it against the denylist
**without reading the list into the transcript**.

**Never point `grep -f` at the raw denylist.** It carries `#` comments
and blank lines, and *a blank pattern matches every line* — so the raw
file reports the whole draft as a hit and the scrub silently becomes
useless. This was hit on 2026-09-10 while building this skill: a
15-line candidate list came back 15 for 15. Parse first, exactly as the
hook does:

```bash
LIST="${IDENTITY_DENYLIST:-$HOME/.config/identity-denylist.txt}"
TERMS=$(mktemp)
while IFS= read -r line || [ -n "$line" ]; do
    line=${line//$'\r'/}                            # CRLF-tolerant
    line="${line%"${line##*[![:space:]]}"}"          # rtrim
    [ -z "$line" ] && continue                       # blank
    case "$line" in \#*) continue ;; esac            # comment
    case "${line,,}" in exempt:*) continue ;; esac   # see below
    printf '%s\n' "$line" >> "$TERMS"
done < "$LIST"
grep -inF -f "$TERMS" <draft-file>; rm -f "$TERMS"
```

`grep -inF -f` is the hook's own matcher: one literal per line,
**case-insensitive fixed string**, no regex. It prints the offending
draft lines and never the list. Reading the list directly is the
fallback when `grep` is unavailable, and it is strictly worse — the list
is the one thing on this machine that must not be reproduced anywhere.

**Sanity-check the parse before trusting a clean result.** A zero-hit
scrub and a broken terms file look identical. Report how many active
terms were loaded (`wc -l < "$TERMS"`); zero means the parse failed, not
that the draft is clean.

**Deliberately ignore the list's `exempt:` lines.** This is the most
important sentence in the skill. `exempt: <path-prefix>` makes
`identity-guard` skip a repo root entirely — because a client's own repo
legitimately carries the client's name. **Exempt means "this name
belongs in this repo". It never means "this name belongs on the public
internet."** Inheriting the hook's exempt semantics here would disable
the scrub in exactly the repos that need it most.

Then sweep heuristically for what a short literal list cannot know:

- Tenant, subscription and workspace GUIDs
- Internal hostnames, server names, connection strings
- Workspace and environment names (`*-dev`, `*-prod`, internal codenames)
- Account names — `AzureAD\…`, Entra UPNs, service principal names
- Internal URLs, including anything on a corporate domain
- Customer and partner names
- Hardcoded profile paths (`C:\Users\<name>`)

**A missing denylist fails open in the hook. It must not here.** If the
file does not exist, say so explicitly in the output — "no denylist
found at `<path>`; scrubbed heuristically only" — and run the heuristic
sweep anyway. Never skip the gate silently.

The employer name itself is normally **fine**: it is the profile's own
Organization field, public by construction. Internal identifiers are
not. That asymmetry is the model to reason from — and when the denylist
disagrees, the denylist wins.

### A hit is an escalation, not an edit

**On any hit, stop and put it to the user.** Do not delete the term, and
do not substitute a public equivalent you inferred. Show the draft
sentence, say a denylisted term appears in it, and ask what should stand
in its place.

This is the one point in the skill where the model must not decide.
Many denylisted tokens have a legitimate public counterpart — an
abbreviation whose expansion is the employer's public name, an internal
codename for work whose underlying commercial product is public and
nameable. **The right rewrite is usually a substitution, not a
deletion**, and only the user knows which. Guessing produces two
failures with no error path: a silent deletion drops real work out of
the entry, and a wrong expansion publishes something inaccurate under
the user's name.

**Do not encode a substitution table anywhere.** A token-to-expansion
mapping would be a second sensitive list to maintain, and pairing each
internal token with its public counterpart is more revealing than either
half alone — the denylist exists in no repo for exactly that reason.
Escalation needs no list.

This also resolves an otherwise real conflict. Step 6 requires paragraph
1 to open `At <Organization>, I …`, so a denylisted organization
abbreviation cannot simply be struck — that would delete a mandated
element. The denylist wins on the **token**; it says nothing about the
**entity**, and the user settles which form of the entity is publishable.

### Reporting the scrub

Report the parse (`N active terms loaded`) and the outcome. Then:

- **A hit that is in the draft** — quote the draft line, so the user can
  adjudicate it. That is their own text, and they cannot resolve a hit
  they cannot see.
- **A term you steered around pre-emptively** — say nothing about which
  term it was. Never volunteer list membership for something that never
  reached the draft.

That second rule is the one a helpful-sounding summary breaks. Writing
"I kept `<term-a>` and `<term-b>` out of the draft" names two entries of
a list that must not be reproduced, and it does so gratuitously: nothing
was at stake, because neither term was in the output. Report avoided
terms as a count, or not at all.

## 8. Emit with a character count and a paste warning

Report the count as `N/2,000` against the same character definition
LinkedIn's own counter uses.

**`wc -m` is wrong on this machine.** `LANG` and `LC_ALL` are empty in
both shells, so `wc -m` falls back to counting bytes and every `•` and
`—` over-counts by 2. Measured 2026-09-10: `• abc` is 5 characters, and both
`wc -c` and `wc -m` return 7. Use one of:

```bash
LC_ALL=C.UTF-8 wc -m < <draft-file>          # returns 5
uv run python -c "import sys;print(len(open(sys.argv[1],encoding='utf-8').read()))" <draft-file>
```

Over-counting is the benign direction, but it makes you cut text that
did not need cutting.

Close with the paste warning: **paste as plain text.** Pasting from
Word, Notion or Google Docs into this field can destroy the line breaks,
because the editor handles rich-text paste poorly. Convention, sourced
2026-09-10, same caveat as step 6.

## Constraints

- **One field, one role, one run.** No resumes, CVs, cover letters or
  posts — those stop at Scope.
- **No claim without evidence in the repo or an answer from the user.**
  Tier 3 is never inferred. This is the constraint the whole procedure
  exists to enforce.
- **No file counts, no line counts.** Items and dates only.
- **Never skip the scrub**, and never inherit `exempt:` semantics into
  it.
- **Never enumerate the denylist**, in whole or in part, into the
  transcript or into any file — and never name a term you merely steered
  around. Quoting a draft line the scrub actually flagged is the one
  exception, because the user cannot adjudicate a hit they cannot see.
- **A hit escalates to the user.** Never resolve one by deleting the
  term or by inferring its public equivalent, and never encode a
  substitution table.
- **Read-only.** This skill reads a repo and writes a draft for the user
  to paste. It does not commit, does not edit the repo, and has no
  programmatic path to the profile — the output is text the user pastes
  by hand.
