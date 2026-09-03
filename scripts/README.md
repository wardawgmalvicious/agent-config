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
- [bootstrap-pre-commit](bootstrap-pre-commit) — install the
  [pre-commit](https://pre-commit.com/) framework via
  [uv](https://docs.astral.sh/uv/) and wire git hooks for this repo.
  Idempotent; safe to re-run. Run on a fresh clone before committing.
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
  needed). **Skills are the only junction**: they are the one payload
  Claude Code hot-reloads, so edit-to-live is the authoring loop there,
  while the other four are not watched and a junction only made every
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
- [lint-frontmatter.py](lint-frontmatter.py) — validate `SKILL.md` and
  `rules/*.md` frontmatter against repo conventions. Kind is inferred from
  the path: files under `rules/` need `paths:` and are exempt from
  `name`/`description`; everything else is linted as a skill (name regex,
  length limits, reserved words). Both get body-line cap, UTF-8/BOM, and
  glob checks. Used by the pre-commit `Validate SKILL.md frontmatter` and
  `Validate rules frontmatter` hooks; can also run manually as
  `python scripts/lint-frontmatter.py <path>...`.
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
  in the script.
- [test-activation.ps1](test-activation.ps1) — the real-path test for
  `paths:` activation: does Claude Code actually load the conditional
  skills the globs say it should? Deploys the platform skills to a
  throwaway probe, opens one cold `claude -p` session, has it Read every
  fixture, then asserts the activations recorded in the session
  transcript. `-Set pbip|fabric` picks the fixture set; **`-StaticOnly`
  runs the glob-vs-contract check alone**, which needs no session and is
  the cheap regression. Deriving a conditional-skill count is a side
  effect of the static run — see the "don't restate a total" note in
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

There is deliberately **no `link-copilot.ps1`**. It existed to junction
skills one-by-one into the shared `~/.agents/skills`, on the premise that
`chat.agentSkillsLocations` had no entry for `~/.claude/skills` — which
was already false when it was written. That location has been documented
since at least 2026-06-26, so every artifact Copilot needs reaches it
through the `~/.claude` paths `link-claude.ps1` already creates — rules,
hooks, subagents, skills, and user-scope instructions alike. Enabling
them is a `chat.*Locations` settings decision; see the Tool support
section of the [root README](../README.md#tool-support).

## Pre-commit

Fresh-clone bootstrap:

```bash
scripts/bootstrap-pre-commit
```

That installs `pre-commit` via `uv tool install`, then runs `pre-commit install`
to wire `.git/hooks/pre-commit`. The configured hooks live in
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
