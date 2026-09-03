# Handoff: adopt `when_to_use` across the skill corpus

- **Written**: 2026-09-01.
- **Kind**: content pass over the whole skill corpus (50 as of 2026-09-03), with a per-skill decision
  recorded for every one of them. Not a blanket edit — see the budget below.
- **Status**: not started. The policy it depends on is settled; what is open
  is which skills get the field and what each one says.
- **Run in**: a fresh session. The corpus is ~50 files and the work is
  editorial, so context fills fast, and a changed `description` is a changed
  *trigger* — the session that writes one cannot judge whether it fires.
- **Parent**: `skill-context-cost.md` workstream D. That brief was
  **retired on 2026-09-01** once its last open workstream (C) was declined;
  recover it from git history with
  `git log --diff-filter=D -- 'docs/**/skill-context-cost.md'`
  then `git show <sha>^:<path>`. Everything this brief still needs from D is
  restated in its own budget table below, so it is now self-contained.
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

Every skill in the corpus gets **considered**, with the decision **recorded**
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
| **Conditional** (`paths:`) | 27 | ~0 — withheld from the listing until a matching file is touched | Blanket-eligible. Write one wherever there is something useful to say. |
| **Unconditional** | 23 | ~190 tokens each, paid in **every session on this machine**. All 23 ≈ **~4,400 tokens** onto a listing with ~100 tokens of headroom | Net-neutral or nothing. Every char added has to come out of that skill's own `description`. |

**Counts re-derived 2026-09-03: 50 skills, `27/23`.** They have moved twice
since this brief was written (`19/25` → `24/20` after wave 4 → `27/23` as
skills landed), so **re-derive again before starting** rather than trusting
this row:

```bash
find skills -name SKILL.md | wc -l                              # total
grep -l "^paths:" $(find skills -name SKILL.md) | wc -l         # conditional
```

The six skills added since split evenly — `fabric-data-pipeline`,
`fabric-ontology` and `fabric-operations-agent` conditional;
`fabric-semantic-model-audit`, `land` and `test-skill` not — so the
expensive column grew too, and the budget below got tighter rather than
looser. A blanket pass over the
unconditional 23 would still overrun the `opus[1m]` budget
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
4. **`skillOverrides: name-only`** — already in force here for the 41
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

**Outcome 4 was why the ordering mattered — and wave 4 is now closed.**
Both of its workstreams landed on 2026-09-01, and the corpus they were
going to churn is settled:

- **E is done.** Five unconditional skills gained a `paths:` glob
  (`fabric-copy-job`, `fabric-mirroring`, `fabric-tmdl-api`,
  `fabric-spark-monitoring`, `fabric-warehouse-monitoring`), moving them
  from the expensive column to the free one. That made the split **24
  conditional / 20 unconditional** at the time, not 19/25 — see the budget
  table above for the current figure. No skill was demoted to
  `docs/` and none was removed, so DEFER has no remaining occupants from E.
- **C is declined.** No merges. `fabric-spark` + `fabric-error-handling`
  (C1) and the `pbir-*` trio (C2) all keep their names and stay separate.
  The reasoning is recorded in
  [`../../../tests/skills/pbip-triggers/expected_activations.md`](../../../tests/skills/pbip-triggers/expected_activations.md)
  (assertion 4) and its `fabric-triggers` sibling (assertion 3).

**This brief is therefore unblocked, in full.** Run both halves.

C's decline also *sharpens* the case for this brief rather than removing
it. The `pbir-*` trio was the sharp case all along — three conditional
skills that co-fire on every `visual.json` and cannot be separated by
path. C2 would have collapsed the disambiguation problem by collapsing the
skills; declining C2 leaves it standing, and `when_to_use` is now the only
lever aimed at it. All three are conditional, so the field is near-free on
them. **Start there.**

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

1. Re-derive the split with the two commands in the budget table above. It
   was **27 conditional / 23 unconditional** on 2026-09-03 and has moved
   twice already; do not trust the number in this brief.
2. Take the conditional set first. For each: read the `description`, decide
   ADD or SKIP, and draft ≤ 512 chars that adds trigger surface rather than
   restating the description.
3. Lint after every file:
   `uv run --with pyyaml scripts/lint-frontmatter.py skills/<group>/<name>/SKILL.md`.
   `cat` the file after any edit — an edit landing inside the frontmatter can
   leave YAML that still parses, into the wrong shape.
4. For the unconditional set: decide MOVE, SKIP or DEFER.
   A MOVE must be char-counted **both** before and after; net change ≤ 0.
5. Record the decision for every skill in a table in this brief before deleting
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
`.claude/settings.json` in this repo sets all 41 platform skills to
`name-only` via `skillOverrides`, which suppresses their descriptions from
the listing *here*. A description or `when_to_use` change to a platform skill
will show no listing delta in this repo and will show its full cost in a
client repo like ACME, which has no such override. Either measure in a client
repo, or resolve the `skillOverrides` question first — D flags that setting
as unresolved and field evidence calls it "unnecessary as an emergency
measure" while it is still in force.

## Constraints

- **No blanket add to the unconditional set.** The budget math above is the
  reason, and it is measured rather than assumed.
- **`when_to_use` must not restate `description`.** Duplicated text is paid
  for twice and adds no trigger surface.
- **≤ 512 chars**, enforced. If a skill wants more, the answer is a shorter
  description, not a larger budget.
- **Do not raise `skillListingBudgetFraction` to make room.** D measured that
  even 2% does not close the 200k-window gap; cutting listing content is the
  only lever that helps there, and that is workstream E's job.
- **No commit** from the authoring session beyond the handoff to `/commit`.
