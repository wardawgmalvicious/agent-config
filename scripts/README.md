# Scripts

Helper scripts for repo maintenance and observability.

## What's here

- [activation-expect.py](activation-expect.py) — the glob-vs-contract
  engine behind `test-activation.ps1`. `static` compares each skill's
  `paths:` frontmatter against a fixture set's
  `expected_activations.md`; `files` lists a set's fixtures in read
  order; `check` asserts a session transcript's activation attachments
  against the globs. Needs `pyyaml` and `wcmatch`, so run it through
  `uv run --with pyyaml --with wcmatch python` — or just use the
  wrapper, which does.
- [audit-status.py](audit-status.py) — where every drift-audit brief
  stands. Writes a generated `README.md` into each
  `docs/audits/<date>/<source>/`, derived from the briefs' metadata blocks
  and execution logs, so learning which of eleven briefs ran is one file
  rather than eleven. Never edit an index by hand; `--check` is the
  pre-commit gate that fails when one is stale or missing. No
  dependencies.
- [bootstrap-pre-commit](bootstrap-pre-commit) — install the
  [pre-commit](https://pre-commit.com/) framework via
  [uv](https://docs.astral.sh/uv/) and wire git hooks for this repo.
  Idempotent; safe to re-run. Run on a fresh clone before committing.
- [handoff-status.py](handoff-status.py) — every repo's open handoff
  briefs and inbox notes in one view, read out of each repo's own index;
  nothing is kept here. Defaults to every repo two levels under
  `C:/Repos`. Reads, never writes. `--check` exits 1 on an unindexed
  brief, a row whose brief is gone, or an inbox note routed nowhere; its
  negative cases are
  [tests/scripts/handoff-status/test-findings.sh](../tests/scripts/handoff-status/test-findings.sh).
  No dependencies.
- [instructions-log](instructions-log) — query the hook observability
  logs: the [InstructionsLoaded log](../claude/hooks/log-instructions-loaded.sh)
  and the [skill-invocation log](../claude/hooks/log-skill-invocations.sh),
  both pure JSONL. Subcommands: `today`, `reasons`, `paths`, `csv`
  (dump the instruction log as CSV for quick consumption), `skills`
  (count skill invocations by name), `tail`. Requires
  [jq](https://jqlang.org).
- [link-claude.ps1](link-claude.ps1) — link this repo into `~/.claude`
  so Claude Code loads its config from a clone living anywhere on disk.
  Copies `claude/agents`, `claude/hooks`, `claude/rules` and
  `claude/mcp` into `~/.claude/{agents,hooks,mcp,rules}` — see
  `$CopyDirs` in the script for the mapping — and junctions the root
  `skills/` one skill at a time into `~/.claude/skills` (no elevation
  needed). **Skills are the only junction**: edit-to-live is the skill
  authoring loop, while for the other four a junction made every
  uncommitted save — and every `git switch`/`stash`/`rebase` — live
  machine-wide. Converted 2026-09-02. A copied directory takes repo
  content without `-Force`; `-Force` is needed only to delete a
  target-only file the repo no longer has. Mirrors
  `claude/CLAUDE.md` (→ `~/.claude/CLAUDE.md`) and
  `claude/settings.json` as plain copies (file
  symlinks need Developer Mode; hard links break on `git pull`). The
  repo-root `CLAUDE.md` is project-scope and never deployed. `settings.json` is compared at the
  key level — Claude Code adds runtime keys (like the model pin) to
  the live copy, and those are ignored; only repo keys must match.
  Idempotent — re-run any time, including after moving or renaming
  the repo folder, or after payload moves between the root and
  `claude/` (stale skill junctions are re-pointed automatically, and a
  directory left behind as a junction by the pre-2026-09-02 layout is
  migrated to a copy via a staged swap — both with no `-Force`).
  Never overwrites a drifted mirror copy, deletes a real directory, or
  removes a target-only file without `-Force`; exits 1 when anything
  needs attention.
  `-ClaudeDir <repo>/.claude -SkillsOnly -SkillGroups fabric` pushes only
  the Fabric skills into a client repo's `.claude`, without this machine's
  agents, hooks or rules; they are junctions, so every later save to one
  is live in that repo's sessions.
- [copy-copilot.ps1](copy-copilot.ps1) — copy two payloads into a repo's
  `.github` as real, committable files, so GitHub Copilot serves them to
  everyone who clones it: skill groups into `.github/skills`, and the
  pre-translated instruction files from
  [copilot/instructions/](../copilot/instructions/) into
  `.github/instructions`. `-Payload` picks either or both. Deliberately
  **not** a user-scope tool: `-CopilotDir` is mandatory and has no
  default, because Copilot already reads `~/.claude/skills` and
  `~/.claude/rules` directly — `paths:` and all — so a copy there would
  only duplicate the junctions.
  Ownership is the whole difficulty: a client's `.github` may already hold
  skills or instructions this repo did not write, and in a repo that
  authors its own `.instructions.md` a first-run collision is the norm
  rather than a fault. So each payload tracks what it deployed in its own
  manifest beside its own files (`.managed-skills.json`,
  `.managed-instructions.json`), re-syncs and prunes only what it owns,
  and skips a collision it did not create unless `-Force` adopts it. The
  manifests are bare lists of names — no source repo, commit, path, user
  or explanatory note, since they deploy into client repos and this one is
  personal.
  Two asymmetries worth knowing. A payload left out of `-Payload` is left
  **alone**, while a group left out of `-SkillGroups` is **pruned** — the
  first narrows what a run touches, the second narrows what a payload
  contains. And it reports rather than prevents double discovery: with
  `.claude/skills` alongside a skill is merely listed twice, but with
  `.claude/rules` alongside the same guidance *loads* twice on a matching
  file, since Copilot honours `paths:` there and `applyTo` here.
- [lint-claude-md.py](lint-claude-md.py) — cap both `CLAUDE.md` files at
  the memory docs' line target: `claude/CLAUDE.md`, which loads into every
  session on the machine, and root `CLAUDE.md`, which loads into every
  session in this repo. The number lives only in the script. Each failure
  message names that file's own destinations — evidence to its ledger
  (`docs/evidence/user-claude-md.md` or `docs/evidence/root-claude-md.md`),
  file-triggered guidance to a rule (`claude/rules/` or `.claude/rules/`),
  task guidance to a skill — and says why an `@import` or an unscoped rule
  would not help: both still load at launch. With no argument it checks
  both files; a path lints one scratch copy, which is how a failing arm is
  proved, and a copy inside a directory named `claude/` gets the
  user-scope message. Fails, rather than passing, on a missing file. No
  dependencies. Run by pre-commit.
- [lint-frontmatter.py](lint-frontmatter.py) — validate `SKILL.md` and
  `rules/*.md` frontmatter against repo conventions. Kind is inferred from
  the path: files under `rules/` need `paths:` and are exempt from
  `name`/`description`; everything else is linted as a skill (name regex,
  length limits, reserved words). Both get body-line cap, UTF-8/BOM, and
  glob checks. Used by the pre-commit `Validate SKILL.md frontmatter` and
  `Validate rules frontmatter` hooks; can also run manually as
  `python scripts/lint-frontmatter.py <path>...`.
- [lint-instructions.py](lint-instructions.py) — validate
  `copilot/instructions/*.instructions.md` and guard them against drift from
  the `claude/rules/*.md` they were hand-translated from. Three checks in one
  pass. **Frontmatter**: `applyTo` is one comma-separated glob string, not a
  list — a list parses as valid YAML and then matches nothing, and
  `lint-frontmatter.py` cannot check these at all since it *requires*
  `paths:`. **Leakage**: a personal-repo name or profile path must never
  reach a client repo, so the hand-stripping is checkable rather than
  remembered. **Drift**: each port is one-time and hand-written, so an edit
  to a rule otherwise leaves its port stale with nothing anywhere to say so
  — the exact way the two previous parallel instruction payloads here died.
  Hashes live in `copilot/.source-hashes.json`, which stays in this repo and
  is never deployed; it also lists the rules deliberately **not** ported and
  why, so a newly added rule surfaces as a decision to make rather than an
  omission. Re-record after a deliberate port with `--stamp`. Run by
  pre-commit.
- [lint-skill-scopes.py](lint-skill-scopes.py) — enforce the flat skill-name
  namespace across both trees. Claude Code addresses a skill by name alone —
  no group segment, no scope qualifier — so two skills sharing a name is
  never a merge, it is one of them winning. Runs over the whole set rather
  than the changed files, because a collision belongs to a **pair**: neither
  file is wrong on its own, so no per-file hook could ever see it. Catches
  two cases with opposite noise levels. **Cross-scope** is the silent one: a
  name in both `skills/` and `.claude/skills/` resolves to the user-scope
  copy, and the project-scope one just stops loading, symptomless apart from
  a skill behaving like an older version of itself. **Cross-group** is
  already fatal in both deploy scripts; it is caught here only so it fails
  before the commit instead of at the next deploy. Also fails — rather than
  passing silently — when either tree is missing or empty, since both
  collectors return nothing for an absent root and a check that compared
  nothing must not report a pass. No dependencies. Run by pre-commit.
- [lint-skill-overrides.py](lint-skill-overrides.py) — check that every
  `fabric/` and `powerbi/` skill has a `name-only` `skillOverrides` entry
  in `.claude/settings.json`, which collapses their descriptions in
  sessions here. Runs over the whole set: the block is a by-name map with
  no pattern form, so a new platform skill is silently uncovered, and the
  defect is a pair — a new skill plus a settings file nobody changed —
  that no per-file hook sees. Also fails on a value that is not
  `name-only`, an override a rename left behind under one of this repo's
  platform prefixes, and a skill group it cannot classify: add a new group
  to `PLATFORM_GROUPS` or `BEHAVIOURAL_GROUPS`. No dependencies. Run by
  pre-commit.
- [payload-coverage.py](payload-coverage.py) — report which of a repo's
  files activate **nothing** in this payload. Every rule and every
  conditional skill declares `paths:` globs, so "what does this repo
  contain that no rule and no skill will ever see" is a measurement rather
  than a judgement call. Answers it for one repo, or `--sweep` a parent
  directory for every repo under it and get the uncovered extensions ranked
  by weight across all of them. Exists because the gap is otherwise
  discovered by tripping over it — landing in an unfamiliar repo, a missing
  rule surfaces one file at a time, or never.

  **Counts per file, never per extension**, and that distinction is the
  whole accuracy of the report. The first draft marked an extension covered
  when *any* of its files matched: one `claude/rules/README.md` matching
  `claude/rules/*.md` made all 230 `.md` files in this repo read as covered,
  and the repo scored 88% instead of its actual **37%**. An extension can
  now come back partial (`~`), which is the common case and the interesting
  one.

  Its matcher must agree with [activation-expect.py](activation-expect.py) —
  wcmatch, `GLOBSTAR | DOTGLOB` — or it reports coverage the activation
  harness would not confirm. Both still hold their own copy of the flags, so
  **change them together** — but the reason recorded here until 2026-09-15,
  that a hyphen in the filename makes the code unshareable, was backwards. A
  hyphenated script cannot be imported *from*; it can import. The canonical
  value now lives in [_skill_inventory.py](_skill_inventory.py)'s
  `glob_flags()`, and neither script was migrated only because neither needs
  anything else that module offers.

  Findings are candidates, not work. `NON_TEXT` filters what cannot carry a
  convention (images, binaries, signing material) and deliberately stops
  there: `.csv`, `.toml` and `.xml` stay in the uncovered list where a person
  decides, rather than being filtered into invisibility by a list nobody
  re-reads. First sweep, 2026-09-10 — a client repo scored **0%**, no glob
  matching any of its 200 files, and `.md` came back the largest uncovered
  surface anywhere at 187 files across seven repos. Needs `pyyaml` and
  `wcmatch`. Not run by pre-commit; there is no pass/fail here to gate on.

- [_skill_inventory.py](_skill_inventory.py) — one walk of both skill
  trees, imported by the scripts that need more than names. Underscore-named
  because it is a module rather than a command; it has no CLI.

  **Returns a list, not a dict keyed by name**, and that is load-bearing:
  [lint-skill-scopes.py](lint-skill-scopes.py) exists to find two skills
  sharing one name, and a name-keyed inventory silently drops one of every
  pair it is looking for. `by_name()` is there for callers that know
  uniqueness is already gated. Needs `pyyaml` only — `glob_flags()` imports
  wcmatch lazily so a pyyaml-only caller never pays for a dependency it does
  not use.

- [skill-overlap.py](skill-overlap.py) — measure skills as **pairs**, which
  is the unit every other checker here misses. `lint-frontmatter.py` caps one
  description, `payload-coverage.py` asks what matches one file,
  `skill-telemetry.py` asks whether one skill was listed. Consolidation is a
  property of a pair, the way a name collision is: neither file is wrong on
  its own.

  Three subcommands. `routing` finds a skill whose text names a skill that is
  not installed — the only signal here that is a bug by default, and the one
  wired into pre-commit. `overlap` ranks pairs of descriptions by shared
  distinctive tokens, weighted by inverse document frequency, so two skills
  that both half-match one request surface without embeddings: a
  deterministic score can be re-run and reviewed, a model score can be
  neither. `coactivation REPO...` sweeps real repos for conditional skills
  whose globs match the same files, and reports subset and identical
  relations — if every file matching A also matches B, the harness never sees
  A apart from B. `overlap --usage` joins `skill-telemetry.py coverage`
  by name and prints its caveats verbatim, because they decide whether a zero
  means anything. No output line recommends deleting anything: an overlap
  or a co-activation is a question for a person, not a verdict.

  **Only a description fails the gate.** A prose mention is reported and
  never gates, because a body may legitimately discuss a skill that was
  deliberately not installed — the two vendored `powerbi-report-*`
  descriptions route to `powerbi-report-planning`, which was left unvendored
  on purpose in `1fa3061`, and the script reports that as an accepted
  override citing the commit. The signal is only as good as its allowlist:
  on 2026-09-15, 17 of 19 raw hits were MCP servers, rules, CLIs, GitHub
  repos, drift-audit source ids, or names `skills/README.md` invents to
  explain a name it did **not** choose. Everything with a machine source is
  derived; seven names are hand-kept and `skills/README.md` is excluded by
  path, because a list that grows by hand goes stale silently.

  The gate's negative case is proved by
  [tests/scripts/skill-overlap/test-routing.sh](../tests/scripts/skill-overlap/test-routing.sh),
  which builds throwaway payloads — the live repo passing says nothing,
  since a gate that never fires produces the same output. Needs `pyyaml`;
  `coactivation` also needs `wcmatch`.

- [push-gate.sh](push-gate.sh) — the pre-push hook that refuses any
  push not issued from a Claude Code session, so nothing another
  harness wrote reaches this public repo unreviewed. Keys on
  `CLAUDECODE=1`; a human override lasts one command,
  `git -c agentconfig.push=reviewed push ...`, in either shell. Wired by
  [.pre-commit-config.yaml](../.pre-commit-config.yaml); the header
  says why the override is not an environment variable and why the
  marker is not `CLAUDE_CODE_SSE_PORT`.
- [repo-settings.ps1](repo-settings.ps1) — keep this repo's GitHub
  settings in [.github/repo-settings.json](../.github/repo-settings.json):
  `-Export` snapshots the live repo into it, `-Check` (the default) reports
  drift and exits 1 on any, `-Apply` restores the file's values. Exists
  because GitHub holds settings server-side only: the 2026-09-10
  delete-and-recreate reset every toggle to its default, and there was no
  record of the old values to restore from. **Export after changing a
  setting in the UI**, or the file silently stops describing the repo.
  Visibility and the social preview image are deliberately outside it.
  `-Apply` refuses unless `gh` acts as the repo's owner.

- [skill-status.py](skill-status.py) — which skills have been tested, and
  what has changed in each since. Derived from the stamps `/test-skill`
  writes to `tests/skills/.tested.json`, each holding a hash of what that
  phase tested, never kept by hand. `--stale` is the to-do list; `--check`
  is the pre-commit orphan check, failing on a stamp whose skill is gone.
  Record a run with `--stamp <skill> --phase activation,behaviour` (or
  `real-use`). Needs `pyyaml`.
- [skill-telemetry.py](skill-telemetry.py) — post-hoc answer to "which
  skills are earning their listing budget?". Three subcommands:
  `coverage` (per skill: how many startup listings it appeared in, how
  many path activations, slash vs auto invocations, `skillUsage`),
  `listing` (listing size per project, and the standing check for a
  deployed-but-never-offered skill), `triggers` (slash-vs-auto ratio —
  a skill only ever reached by name has a description that is not
  matching). Needs `pyyaml`, so run it through
  `uv run --with pyyaml python`. Reads only what already exists; writes
  nothing and adds no hook. It is a **sibling of `instructions-log`, not
  a subcommand of it**, for two reasons: the data is different —
  `instructions-log` owns the two hook logs, while everything here comes
  from the session transcripts, which are the only complete record — and
  bash+jq cannot do the job, since reading ~270 transcripts one `jq`
  process at a time did not finish inside two minutes on this machine,
  where the same scan in-process takes about a second. Its flags
  deliberately never say "delete this": zero invocations is not disuse if
  the skill was withheld by design or covers a rare path; see `verdict`
  in the script. Below `MIN_SESSIONS` recorded sessions the flags are
  suppressed outright rather than filled in — on a thin or empty corpus
  every conditional skill otherwise reads as never-activated and every
  unconditional one as evidence of truncation, which is missing history
  and not a finding.
  Its inventory walks **both** skill trees and carries the scope, which
  the `coverage` table shows as `user` or `proj`. Scope is not decoration:
  a user-scope skill is offered in every session on this machine while a
  project-scope one is offered only in sessions inside this repo, so the
  two are counted against different denominators and a `proj` row's
  `listed` counts this repo's sessions alone. The six skills at project
  scope were at user scope until the 2026-09-09 split, and the listings
  they earned before it are reported as a separate `[+N pre-split]` note
  rather than added in — a count drawn from a period when a skill was a
  different kind of skill explains a low number without being evidence
  about the skill as it is deployed now. Walking `skills/` alone was this
  script's own bug until 2026-09-15: project-scope skills were absent
  from `coverage` entirely and so could never be flagged, while
  `triggers` listed them throughout because it reads transcripts rather
  than disk — which is precisely what made the gap survive unnoticed.
- [test-activation.ps1](test-activation.ps1) — the real-path test for
  `paths:` activation: does Claude Code actually load the conditional
  skills the globs say it should? Deploys the platform skills to a
  throwaway probe, opens one cold `claude -p` session, has it Read every
  fixture, then asserts the activations recorded in the session
  transcript. `-Set pbip|fabric` picks the fixture set; **`-StaticOnly`
  runs the glob-vs-contract check alone**, which needs no session and is
  the cheap regression. The static run prints the fixtures it checked, not
  a skill count; the total is stated once, in the fabric set's
  `expected_activations.md` — see the "don't restate a total" note in
  [CLAUDE.md](../CLAUDE.md#validating-a-change).
- [test-semantic-model-audit.ps1](test-semantic-model-audit.ps1) — the
  behaviour test for
  [`fabric-semantic-model-audit`](../skills/fabric/fabric-semantic-model-audit/SKILL.md),
  a skill with no `paths:` glob at all: given it *is* loaded, does it
  produce the right findings? `-Mode shipped|baseline|nocarveout|all`.
  The third mode is the one that discriminates — it strips the
  planning-model carve-out from a copy of the skill and re-runs, which
  is the only control that can show the carve-out doing any work.
  Deploys **project-scoped**, so the user-scope prune is never touched;
  it compares the user-scope skill list before and after and fails on a
  difference. It produces the runs and does not grade them — compare
  each against
  [expected_findings.md](../tests/skills/fabric-semantic-model-audit/expected_findings.md).

There is still deliberately **no `link-copilot.ps1`**, and
`copy-copilot.ps1` is not one: it copies rather than links, for the
reasons its header gives. It has two targets. A client repo's `.github`
gets **committable** files, so a teammate cloning it gets the skills
without this repo, without a script, and without a machine that has
either. And `~/.copilot` is this machine's user scope:

```powershell
./scripts/copy-copilot.ps1 -CopilotDir ~/.copilot -SkillGroups workflow
```

That second target was pointless until 2026-09-09, because Copilot read
the `~/.claude` paths `link-claude.ps1` creates — measured that day, when
a `.sql` file open in a client repo loaded exactly the two rules in
`~/.claude/rules` whose globs matched. The same day every Claude root was
switched off for Copilot, so `~/.copilot` is now the only way this
payload reaches it outside a repo. First deployed 2026-09-11. Copies are
not live: re-run it after editing `commit`, `code-review` or a ported
rule. `workflow` alone, never `social` — a workplace Copilot has no use
for `linkedin-highlights`. See the Tool support section of the
[root README](../README.md#tool-support).

## Pre-commit

Fresh-clone bootstrap:

```bash
scripts/bootstrap-pre-commit
```

That installs `pre-commit` via `uv tool install`, then runs `pre-commit install`
to wire `.git/hooks/pre-commit`, `commit-msg` and `pre-push` — the three
types `default_install_hook_types` lists. The configured hooks live in
[.pre-commit-config.yaml](../.pre-commit-config.yaml).

### `claude plugin validate` — evaluated 2026-08-31, declined

Claude Code 2.1.233 taught `claude plugin validate` to check a bare
`.claude/skills` directory rather than requiring a `plugin.json`, which
made it applicable here for the first time. It was evaluated against
`lint-frontmatter.py` on 2.1.251 and **not** wired in. Two reasons, in
order of weight:

- **It reads neither of this repo's layouts.** Pointed at repo `skills/`
  it finds nothing, because that is `skills/<group>/<name>/SKILL.md` and
  the command looks exactly one level down — a scratch copy of the same
  shape holding two deliberately broken skills exited 0 with no findings.
  Pointed at `~/.claude/skills` it reports `7 entries here are symlinks
  and were not read`, so the deployed junctions are skipped too. Both
  failure modes are silent passes.
- **What it does catch is a strict subset.** On flat fixtures it flags
  unparseable YAML frontmatter (error) and a missing `description`
  (warning). `lint-frontmatter.py` catches both, plus the length caps and
  the `paths:` glob shape — the leading-`/` and backslash-separator
  checks that have no upstream error path at all. Nothing was found that
  only the upstream tool catches.

To its credit it is not noisy: `--strict` over a flattened copy of all 44
real skills passed clean, so `paths:` and other repo-specific frontmatter
fields draw no false positives. That is why this is "declined", not
"rejected" — if the skills layout ever flattens, re-evaluate. It does not
replace `lint-frontmatter.py` in any case; the repo-specific checks above
are the whole reason that script exists.
