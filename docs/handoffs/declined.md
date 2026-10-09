# Declined

Learnings that reached this repo's inbox and were refused. `/triage`
reads this before it gives a verdict, and is its only writer. Entries
are dated and never corrected in place: a learning that comes back with
new evidence gets a verdict, or a new entry.

## 2026-10-06 — An `HTTPS_PROXY` for Claude Code on the corporate network

- **From**: a note of 2026-10-02, updated 2026-10-05, by a VS Code
  Local-agent session in a client Fabric repo.
- **Why not**: that network has no proxy. WinHTTP goes direct, WinINET
  has neither a proxy nor a PAC URL, `wpad` does not resolve and the
  .NET system proxy is direct, measured there on 2026-10-05 by the
  note's session. It resets Anthropic's hosts by name as the TLS
  handshake begins, which no proxy setting changes. Before that run, on
  2026-10-02, the user had chosen a machine-local overlay: the address
  in a User-scope variable that machine-config sets, copied into the
  live `env` as `HTTPS_PROXY` by `link-claude.ps1` only on that network.
  A committed `HTTPS_PROXY` breaks every other network, `-Force` replaces
  the live `env` whole, settings `env` values are literal strings, and
  the docs say the `processWrapper` launcher is ignored on Windows.
- **Would change it**: a network Claude Code has to work on that does
  route through a proxy.

## 2026-10-08 — Removing dated incident evidence from skills and rules

- **From**: a prompt audit of 2026-10-08, run against Claude Opus 5.5 by
  a session in a client Fabric repo: findings R9, C4, C5, L2, L3, L4,
  N2, N3, H2, H3, B3, B4, B5, Q1 and Q2.
- **Why not**: each removes a claim's only date or its failure
  description, such as an observed run, a dated incident, or a pointer
  to the tests that pin a claim, and `coding-markdown.md` asks a
  measured claim to carry its date and a rule to say what its failure
  looks like. The same audit's trims that kept both landed that day.
- **Would change it**: a decision to move such evidence out of skill and
  rule bodies into `references/` or a ledger, its own brief, or a
  measurement showing the history costs adherence.

## 2026-10-08 — "Since" dates in claude/rules/README.md

- **From**: the same prompt audit, finding R17.
- **Why not**: that README is where the rules' reasoning and history
  live, and its own `paths:` loads it only while the rules themselves
  are being worked on, so its dates cost little and tell a reader when
  each piece arrived.
- **Would change it**: the README loading in sessions that are not
  working on rules.

## 2026-10-08 — Softening code-review's read-only wording and dropping its invocation caveat

- **From**: the same prompt audit, findings K2 and K3.
- **Why not**: K2's caveat states the failure mode that
  `tests/skills/code-review/README.md` tests as its item 5, a "fix
  this" follow-up under natural-language invocation, and K3 rewrites
  the guard against it in calmer words, untested. A guard's wording
  changes after a run shows it holds.
- **Would change it**: a `/test-skill code-review` run, slash and
  natural language, in which the calmer wording refuses as reliably.

## 2026-10-08 — linkedin-highlights' worked inventory and sentence targets

- **From**: the same prompt audit, findings H1 and H4.
- **Why not**: H1 cuts the worked example of counting item directories,
  and H4 swaps the measured targets, 2–3 sentences of 22–31 words, for
  "a few long, complete sentences". The example and the numbers are
  what make the rule checkable.
- **Would change it**: a draft run showing the numbers over-constrain
  the prose.

## 2026-10-08 — learn naming skills a client session lacks

- **From**: the same prompt audit's flagged decisions.
- **Why not**: `author-skill`, `drift-audit` and `triage` are
  agent-config's own skills, at project scope by design, and `learn`'s
  note mode names `/triage` as the receiver of the note it leaves, which
  is right in a session that cannot run it.
- **Would change it**: `learn` telling a session in another repo to run
  one of them itself.

## 2026-10-09 — Trimming the procedure from recreate-repo's, commit's and land's descriptions

- **From**: a note of 2026-10-09, by a prompt-audit session in the
  personal machine-config repo, which proposed no edit.
- **Why not**: each description is within `lint-frontmatter.py`'s
  caps, and the `workflow` group's listing text was 5,984 characters on
  2026-10-08, beside an overflow in the platform groups that
  `platform-skill-portfolio.md` Part 1 closes. The steps a description
  names are what tell a session the skill applies before it acts, as
  `recreate-repo`'s "before the delete" does, and a reworded trigger
  owes an activation retest.
- **Would change it**: a client listing still over its cap after Part
  1, or a transcript where a session followed a description's steps
  without invoking the skill.

## 2026-10-09 — Cutting code-review's checklist as standard review knowledge

- **From**: the same note, offered for a `/test-skill` comparison rather
  than as an edit.
- **Why not**: the checklist is body text, paid only when `code-review`
  runs and never in the listing, and no run has measured what it adds
  over a bare model.
- **Would change it**: the `/test-skill code-review` run that the K2
  and K3 entry above already waits on, if its baseline arm catches what
  the checklist lists.

## 2026-10-09 — Edits to the four platform skills Part 1 archives

- **From**: a note of 2026-10-08, the platform half of a prompt audit
  run against Claude Opus 5.5 by a session in a client Fabric repo:
  findings X3, X13 and X14 (`fabric-copy-job`), Y8 and Y9
  (`fabric-mirroring`), V16 (`pbid-tom-live`), and V4, V7b, V8a and
  V11a (`powerbi-report-authoring`), with its flagged conflict between
  `pbir-cli` and `powerbi-report-authoring` over which CLI and
  validator lead.
- **Why not**: `platform-skill-portfolio.md` Part 1 archives all four
  skills, as the user decided on 2026-10-09, and their word that day
  was to drop these hunks rather than apply them. Two would correct a
  claim, unverified here: X3 gives a Git-synced Copy job a
  `<name>.CopyJob/` folder, against the skill's "no local file-based
  artifact", and Y8 names `mirroring.json` as the mirroring item's
  definition part.
- **Would change it**: a restore of any of the four, from the commit
  its `skills/README.md` line names; re-measure these hunks then.

## 2026-10-09 — Removing dated incident evidence from the platform skills

- **From**: the same note: findings Y6 and Y7 (`fabric-eventhouse`),
  Z10 and Z12 (`fabric-rest-api`), Z17 (`fabric-variable-library`), Z18
  and Z19 (`fabric-warehouse`), V9 and V11b (`powerbi-report-design`),
  and V12 (`pbir-themes`).
- **Why not**: the reason of the 2026-10-08 entry above, for the
  platform half. Each cut removes an observed run, a dated incident, a
  measurement's strength, a failure description or the hashes that pin
  a claim. The note's trims that kept those landed in this run.
- **Would change it**: what the 2026-10-08 entry names.

## 2026-10-09 — Trimming fabric-gotchas' best-practice lists as standard knowledge

- **From**: the same note, findings Y4a to Y4e: seven PREFER and AVOID
  items, from medallion layering to integer keys and `UNION ALL`.
- **Why not**: as with code-review's checklist above, it is body text,
  paid only when `fabric-gotchas` runs and never in the listing, and no
  run has measured what it adds over a bare model.
- **Would change it**: the second wave in `fabric-deploy-skill.md`,
  which turns the gotchas into a symptom-to-owner index, or a run whose
  baseline arm states these preferences unprompted.

## 2026-10-09 — Rewording powerbi-report-design's triggers, review step and archetype default

- **From**: the same note, findings V8b and V10, and its flagged
  conflict between the skill's lines 91 and 93.
- **Why not**: V8b cuts the trigger phrases that tell a session the
  skill applies, and the PBIR fold carries them into
  `pbir-report-workflow`'s entry. V10 drops the independent-review step
  rather than rewording it. Lines 91 and 93 order themselves: ask when
  a prompt is vague, and after at most two rounds pick, record the
  assumption and default as line 91 says. All three are vendored text,
  which the fold keeps verbatim apart from its hand-offs.
- **Would change it**: the fold's `/test-skill pbir-report-workflow`
  design case showing the reference over-asks, skips its review, or
  defaults where it should ask.
