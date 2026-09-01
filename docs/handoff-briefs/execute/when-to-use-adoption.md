# Handoff: adopt `when_to_use` across the skill corpus

- **Written**: 2026-09-01.
- **Kind**: content pass over all 44 skills, with a per-skill decision
  recorded for every one of them. Not a blanket edit — see the budget below.
- **Status**: not started. The policy it depends on is settled; what is open
  is which skills get the field and what each one says.
- **Run in**: a fresh session. The corpus is 44 files and the work is
  editorial, so context fills fast, and a changed `description` is a changed
  *trigger* — the session that writes one cannot judge whether it fires.
- **Parent**: [skill-context-cost.md](skill-context-cost.md) workstream D.
  That brief keeps the cost model and the measurements; this one owns
  adoption. Do not restate D's asymmetry table here — read it there.
- **Queue**: [README.md](README.md) has the execution order and what blocks
  what. This brief does not carry its own position.

## Settled on 2026-09-01 — do not relitigate

Split **A** was adopted: `description` ≤ 1,024, `when_to_use` ≤ 512, each
enforced separately by `scripts/lint-frontmatter.py` (`DESCRIPTION_MAX`,
`WHEN_TO_USE_MAX`, and a `LISTING_MAX` sum assertion that can only fire if
the two are edited apart). Root `CLAUDE.md`, the handoff template, and
`author-skill` step 7 carry the same numbers. All 44 skills passed the
tightened gate unchanged.

The field semantics are **confirmed at source**, not inferred —
`code.claude.com/docs/en/skills`, drilled 2026-09-01:

- `when_to_use` is "Additional context for when Claude should invoke the
  skill, such as trigger phrases or example requests. **Appended to
  `description` in the skill listing and counts toward the 1,536-character
  cap.**"
- The `description` row: "the combined `description` and `when_to_use` text
  is truncated at 1,536 characters in the skill listing."
- The listing-budget section: "each entry's combined text is capped at 1,536
  characters regardless of budget."
- `when_to_use` is **not** among the six fields the claude.ai upload path
  accepts (`name`, `description`, `license`, `compatibility`, `metadata`,
  `allowed-tools`), and an unexpected key there is a hard failure rather than
  an ignored field. A skill that adopts `when_to_use` is Claude Code-only
  from that point on.

## The ask, and the one place it collides with the budget

Every one of the 44 skills gets **considered**, with the decision **recorded**
— that is the requested scope and this brief keeps it.

What it cannot mean is every skill getting the field, and the reason is a
measured hard limit rather than a style preference. From D's measurements
(2026-08-31): the skill listing is **~9,900 tokens against a ~10,000-token
budget on `opus[1m]`** — roughly one skill of headroom — and on a
200k-window session the budget is **2,000 tokens against the same ~9,900
wanted**, i.e. already truncating badly.

At the ~2.7 chars/token that description text measures at, a full 512-char
`when_to_use` is **~190 tokens**. So:

| | n | Listing cost of adding `when_to_use` | Consequence |
| --- | --- | --- | --- |
| **Conditional** (`paths:`) | 19 | ~0 — withheld from the listing until a matching file is touched | Blanket-eligible. Write one wherever there is something useful to say. |
| **Unconditional** | 25 | ~190 tokens each, paid in **every session on this machine**. All 25 ≈ **~4,700 tokens** onto a listing with ~100 tokens of headroom | Net-neutral or nothing. Every char added has to come out of that skill's own `description`. |

A blanket pass over the unconditional 25 would overrun the `opus[1m]` budget
by roughly half again, and the penalty is not an error — Claude Code shortens
descriptions starting with the skills you invoke least, so the cost lands as
*silently weakened triggers on the skills you use rarely*, which is the exact
failure this work is meant to prevent.

## What `when_to_use` is not

It is **additional trigger text**, so its first-order effect is to make a
skill fire *more* readily. It is not a suppression lever, and reaching for it
to stop an unconditional skill loading when it shouldn't is using the wrong
tool. Where it genuinely buys control is **disambiguation** — two neighbouring
skills competing for one trigger surface, where the text says "use this for A;
for B use Y". The `pbir-*` cluster is the standing case.

For a skill that fires when it has no business firing, the levers are, in
descending order of force:

1. **`paths:`** — makes it conditional, so it leaves the listing entirely
   until a matching file is touched. Workstream E, queue wave 4.
2. **`disable-model-invocation: true`** — manual-only; the description leaves
   context. Declined repo-wide, but it is the hard stop.
3. **Narrowing the `description`** — it is the entire trigger mechanism, so a
   tighter one fires less.
4. **`skillOverrides: name-only`** — already in force here for the 37
   platform skills.

The **MOVE** outcome below is the one that serves control at zero budget cost:
relocating trigger phrases out of `description` into `when_to_use` buys
legibility and disambiguation without adding a character to the listing.

## Four outcomes, one recorded per skill

1. **ADD** — conditional skills only. Near-free. Write it if there is a real
   trigger phrase, error string, or example request to add.
2. **MOVE** — unconditional skills. Relocate trigger phrases out of
   `description` into `when_to_use` for a net character change of **≤ 0**.
   The pair is truncated as one string, so a move costs nothing and buys
   legibility: `description` says what the skill is, `when_to_use` says what
   the user might type.
3. **SKIP** — nothing useful to say, or no demonstrated trigger miss. Record
   the reason; a skipped skill that gets re-examined every pass is a cost of
   its own.
4. **DEFER** — the skill is in scope for workstream E (may gain a `paths:`
   glob, be merged, or be removed). Do not write `when_to_use` text for a
   skill that might become conditional or cease to exist.

**Outcome 4 is why the ordering matters.** Workstream E (queue wave 4) moves
unconditional skills into the conditional column or out of the corpus
entirely. A skill that gains a `paths:` glob moves from the expensive side of
the table above to the free side, which can change its answer from MOVE to
ADD. Running the unconditional half of this brief *before* wave 4 means
writing text that wave 4 may invalidate.

**Recommendation: run the whole brief after wave 4, not half of it.**

An earlier draft of this brief said to run the 19 conditional skills
immediately, on the grounds that only the unconditional 25 are affected by
workstream E. That was wrong, and the reason is workstream **C**, not E.
C's merge candidates are **conditional** skills — `fabric-spark` +
`fabric-error-handling` (C1) and the `pbir-visual-json` /
`pbir-conditional-formatting` / `pbir-filters` trio (C2) — so five of the 19
are candidates for being renamed or merged out of existence.

The `pbir-*` trio is the sharp case: it is exactly where `when_to_use`
disambiguation looks most valuable, and C2's proposal is to merge all three
into **one** skill, which would make that disambiguation moot rather than
merely rewritten. Writing three careful `when_to_use` blocks and then
merging their skills is the worst available order.

So both halves wait for wave 4:

- **C** settles which conditional skills still exist and under what names.
- **E** settles which unconditional skills survive, and which have gained a
  `paths:` glob — moving them from the expensive column to the free one and
  potentially changing a MOVE into an ADD.

Wave 4 also *enlarges* the cheap set, so running after it means one pass over
a settled corpus instead of two passes over a moving one.

## What counts as evidence for a trigger miss

- `scripts/instructions-log reasons|paths|skills` — with the standing caveat
  that these record **invocations**, never conditional activation. A zero
  says nothing about whether a glob matched.
- The user's own experience of a skill that should have fired and did not.
  This is the strongest signal available and the only one that catches a
  model-invoked miss.
- Neighbouring skills competing for one trigger surface — the `pbir-*`
  cluster is the known case. Here `when_to_use` earns its place by
  *disambiguating*, which a description edit does less well because the
  description must still stand alone.

Absent any of these, the honest answer for a working skill is SKIP.

## Procedure

1. Read D's asymmetry table and this brief's budget table. Confirm the
   conditional/unconditional split is still 19/25 — wave 4 changes it.
2. Take the conditional 19 first. For each: read the `description`, decide
   ADD or SKIP, and draft ≤ 512 chars that adds trigger surface rather than
   restating the description.
3. Lint after every file:
   `uv run --with pyyaml scripts/lint-frontmatter.py skills/<group>/<name>/SKILL.md`.
   `cat` the file after any edit — an edit landing inside the frontmatter can
   leave YAML that still parses, into the wrong shape.
4. For the unconditional 25 (only after wave 4): decide MOVE, SKIP or DEFER.
   A MOVE must be char-counted **both** before and after; net change ≤ 0.
5. Record the decision for all 44 in a table in this brief before deleting
   it, and carry that table into the commit message. The skipped set is the
   part that cannot be reconstructed from the diff.
6. Hand off to `/commit`.

## Check this on one skill before the corpus pass

**Does GitHub Copilot tolerate `when_to_use`?** Unverified as of 2026-09-01,
and it is a gate rather than a curiosity. `when_to_use` is a Claude Code
extension, not one of the Agent Skills spec's six fields, and Copilot reads
the *same files* out of `~/.claude/skills` via `chat.agentSkillsLocations`.
Ignoring an unknown key is the likely behaviour, but it is not safe to assume:
the claude.ai upload path **hard-fails** on an unexpected key rather than
ignoring it, which is a documented counterexample from the same ecosystem.

Add `when_to_use` to **one** skill, open VS Code, and confirm the skill still
loads and still triggers in Copilot's agent surface. If it hard-fails there,
adoption becomes a Claude-Code-only choice with a real cost to the Copilot
half of this payload, and that changes the scope of this brief rather than
just its verification steps.

## Verifying

Lint is necessary and not sufficient — it bounds one skill, not the listing.
To see the listing itself, use D's recipe:

```bash
cd <repo> && claude -p "Reply with exactly: ok" --model opus[1m] \
  --debug-file /path/to/dbg.log
grep -iE "conditional|unique skills|getSkills|via attachment" /path/to/dbg.log
```

**Measure before and after, on the model you actually run** — the budget is
1% of the running model's context window, so the number moves with the model.

**The local measurement is a no-op, and this is the trap.**
`.claude/settings.json` in this repo sets all 37 platform skills to
`name-only` via `skillOverrides`, which suppresses their descriptions from
the listing *here*. A description or `when_to_use` change to a platform skill
will show no listing delta in this repo and will show its full cost in a
client repo like ACME, which has no such override. Either measure in a client
repo, or resolve the `skillOverrides` question first — D flags that setting
as unresolved and field evidence calls it "unnecessary as an emergency
measure" while it is still in force.

## Constraints

- **No blanket add to the unconditional 25.** The budget math above is the
  reason, and it is measured rather than assumed.
- **`when_to_use` must not restate `description`.** Duplicated text is paid
  for twice and adds no trigger surface.
- **≤ 512 chars**, enforced. If a skill wants more, the answer is a shorter
  description, not a larger budget.
- **Do not raise `skillListingBudgetFraction` to make room.** D measured that
  even 2% does not close the 200k-window gap; cutting listing content is the
  only lever that helps there, and that is workstream E's job.
- **No commit** from the authoring session beyond the handoff to `/commit`.
