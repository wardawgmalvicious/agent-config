# Handoff: a LinkedIn article skill, derived from two drafts that already exist

- **Written**: 2026-09-22. Revised the same day, after a `machine-config`
  session was found to have already written a complete article draft and
  parked it pending exactly this skill.
- **Kind**: one deployable skill in `skills/social/`, plus its
  `references/`. Two article drafts already exist and are the material
  it is derived from, not output waiting on it.
- **Status**: **Open, nothing drafted.** Not blocked on finding a
  format — see below, that framing was wrong in this brief's first
  revision.
- **Run in**: this repo. The drafts live in `~/drafts/linkedin/`, a
  machine-local folder in no repo, the same reasoning as
  `~/handoff-inbox/`.
- **Queue**: [README.md](README.md) has the execution order. This brief
  does not carry its own position.

## The governing instruction, and it is not this brief's

`~/drafts/linkedin/README.md`, written by the `machine-config` session:

> The skill should be measured against this draft rather than the draft
> rewritten to fit an invented format.

That is the right way round and it overrides anything here that conflicts
with it. A skill that makes the existing drafts worse has failed, whatever
a style guide says.

## What already exists

| File | State |
| --- | --- |
| `2026-09-22-tenant-is-a-folder.md` | **Complete**, 1,496 words. Five items open before publishing, listed in that folder's README. |
| `2026-09-22-peer-session-behaviour.md` | **Analysis, not an article.** 1,601 words. Blocked on evidence. |
| `2026-09-22-source-posts.md` | Three other people's public posts, source material only. Alluded to, never quoted. |

Two samples at different maturities is enough to derive a house format
from. One was not, which is why the first revision of this brief went
looking outside for one.

## The first revision was built on the wrong frame

Recorded so it is not repeated rather than silently fixed.

That revision drilled a LinkedIn writing guide and vendor blogs, and
organized the work around reach, ranking, hook formulas and "optimal
length for Google ranking". The user's stated intent is the opposite of
that frame: **not selling anything** — sharing observations, with an
interest in the AI landscape and agent harnesses specifically. A
marketing template applied to that register would strip exactly the
parts that make both drafts credible.

What survives from that pass is small and mechanical:

- The supplied guide (Jahangard, "The Ultimate Guide to Writing LinkedIn
  Articles") gives a five-item structure and **no numbers at all**. It
  was read. It does not need re-reading.
- Hard limits worth confirming once, in the composer, because they are
  format facts rather than advice: body limit ~110,000 characters,
  headline ~220 characters, cover image 1200 × 644. All third-party and
  **unverified against LinkedIn's own docs**, whose obvious help URL
  404s.
- One fact that is instrument selection rather than marketing: **posts
  out-reach articles roughly 5×, and articles are indexed by search
  while posts are not.** So the article is the durable artifact and a
  post is the discovery vehicle pointing at it. Judge an article on
  whether it is findable in a year, not on its first week.

Ignore the engagement and ranking figures. They are unverifiable by hand
and they encode the frame being rejected.

## The format is already in the drafts — derive it, do not invent it

Both drafts, written independently in different sessions, share a shape.
That convergence is the evidence the format is real:

1. **A concrete, dated observation** — a scene or a measurement, not a
   thesis statement.
2. **The mechanism, stated precisely**, with the wrong-but-obvious
   summary explicitly ruled out.
3. **Subtraction before novelty.** The peer draft's "Subtract what the
   payload already said" separates what was already prescribed from what
   was not, so the interesting part is not credited to the wrong cause.
4. **A named limits section.** The tenant draft calls it "Where this
   stops working" and opens it: *"Two honest limits, because a write-up
   without them is marketing."* That sentence is the register in one
   line and should be the skill's governing rule.
5. **An unfinished answer, kept.** *"I do not have a finished answer. I
   have a confirmed diagnosis and two candidate remedies I have not yet
   verified."* The folder README flags this as the paragraph a
   promotional edit would cut. The skill should refuse to cut it.
6. **A reframed question rather than a call to action**, and no repo,
   client or product named.

Most of this is already written down elsewhere in this repo and should
be cited rather than restated: `claude/rules/coding-markdown.md` §
"Prose discipline" — front-load the conclusion, date a measured claim,
correct in place, say what the failure looks like, bold only the
load-bearing clause. The LinkedIn-specific part is thinner than it
looks.

## Check overlap before authoring anything

`skills/social/linkedin-highlights/` is the near neighbour and
**explicitly stops** on posts and articles — "different length,
different register, different conventions, and none of them were
drilled." That states the boundary; it does not prove a second skill is
right. `author-skill` §2 requires:

```bash
uv run --with pyyaml scripts/skill-overlap.py overlap --skill linkedin-highlights
uv run --with pyyaml scripts/skill-overlap.py routing
```

"Write this up for LinkedIn" matches both on its face. A high score
means one skill with a mode split, the shape `learn` uses, rather than
two.

**Inherit, do not re-derive:**

- That skill's **step 7 scrub**. The folder README already reports using
  it. Its justification applies harder here: the `identity-guard` hook
  gates `git commit` and `git push` only, so anything leaving for a
  profile passes **no gate at all** — and an article quotes transcripts
  rather than summarising commits. Both drafts' source material is a
  client tree.
- `references/repo-evidence.md`, which `linkedin-highlights` already
  says a later skill "will read". This is that skill.
- **Not** its format rules. The README is right that they were measured
  from a 2,000-character profile field and do not transfer.

**Placement and frontmatter**, in `skills/social/`:

- Deployed by `link-claude.ps1 -SkillGroups workflow,social,meta`, so
  live at user scope in every session on this machine.
- `social` carries **no `.no-copilot` marker**, so `lint-frontmatter.py`
  treats it as Copilot-reachable and an active `model:` key fails the
  lint. Keep it commented, as `linkedin-highlights` does.
- Names are one flat namespace across both trees.

## The peer-behaviour piece stays blocked, and the fix pays twice

`2026-09-22-peer-session-behaviour.md` rests on one incident, with no
control, and both sessions were the same model carrying the same
instructions. Its own Limits section says so. 1,500 words on that is
padding.

The fix is the ablation that doc names as missing: two cold sessions in
a shared tree with a scripted collision, once with the peer subsection
loaded and once with it stripped. That is close to the cold-probe re-run
[peer-coordination-open-questions.md](peer-coordination-open-questions.md)
is still open for — **run it once and it settles both.** Whichever brief
runs it should keep the transcript so the other does not repeat it.

The tenant draft is **not** blocked this way and should not wait on it.

## Not in scope

- Publishing anything. Both drafts stay drafts until the user posts
  them.
- Editing `2026-09-22-tenant-is-a-folder.md`. Its five open items belong
  to the session that wrote it, or to the user.
- A resume or CV skill. Still out of scope, still not drilled.

## Dependencies

- `~/drafts/linkedin/` and its `README.md`, which carries both drafts'
  publishing state and is the index for that folder.
- The ablation overlaps
  [peer-coordination-open-questions.md](peer-coordination-open-questions.md).
- The tenant draft's "small bug" section is now
  `claude/rules/coding-bash.md` § "Output streams", in **past tense**.
  machine-config `c9a2ed4` fixed it on 2026-09-22, and a snapshot taken
  on 2026-09-23 confirmed the fix. The draft's MCP remedies are
  `claude/mcp/README.md` § "The helper's login is the harness's, not
  the folder's", and they are still unverified by anyone. Separately,
  `claude/CLAUDE.md` now records **two** Bash launch modes, so a draft
  saying the Bash tool is never a login shell would disagree with it.
  All three came from `bash-snapshot-and-mcp-credential-env.md`, which
  was executed and deleted on 2026-09-23. Keep the draft consistent
  with the payload, since the two should not disagree about the same
  machine.
- No rule, hook or `paths:` glob changes. A new skill does need
  `/test-skill`.
