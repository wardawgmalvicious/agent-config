# Skill handoff brief: test-skill

Last verified: 2026-09-02

> Guidance: Re-verify when referenced platform behaviors in project instructions get re-verified. For v1 briefs, use the date Claude Code creates the brief. Every section heading in this template stays in the filled brief; sections that don't apply get `N/A — <brief reason>` under the heading.

## Artifact path

Personal scope, deployed by `scripts/link-claude.ps1`:

- Repo: `skills/workflow/test-skill/SKILL.md`
- Deployed: `~/.claude/skills/test-skill/SKILL.md`

`workflow` is in this machine's standing `-SkillGroups workflow`, so
unlike the platform skills this one **is** live in ordinary sessions the
moment it is written. No `references/` file — see Body structure
outline.

## Scope

The other half of `author-skill`. That skill stops at a linted draft and
explicitly writes no test fixtures; nothing picked up from there, so a
drafted skill stayed unvalidated indefinitely. `test-skill` takes a
skill name or brief path, **reads the brief from disk**, and runs two
phases in one invocation: the **activation contract** (write or extend
the trigger fixtures, update `expected_activations.md`, run the static
check, then the real-path test) and the **behavioural test** (deploy the
needed groups, cold session, `--safe-mode` baseline, the brief's named
trigger queries, restore the prune). Runs inline, user-invocable and
model-invocable, no `paths:`. `effort: max`, `model: inherit`.

**Skills only**, deliberately — matching `author-skill`'s own scope.
Rules are exercised incidentally because the activation harness checks
them alongside skills, but this skill does not *author* rule fixtures.
Subagents and enforcement hooks keep the manual procedure in root
`CLAUDE.md` and `tests/agents/security-reviewer/README.md`.

## Sources drilled

Drilled — all repo bytes; this is a harness skill, not a platform one:

- `scripts/test-activation.ps1` — read in full for the parameter block
  and the comment header. Established the real signature
  (`-Set pbip|fabric` mandatory, `-StaticOnly`, `-ProbeRoot`,
  `-Model` defaulting to `opus[1m]`, `-KeepProbe`), that the static
  check runs **first and unconditionally** and exits non-zero before any
  session is spent, and the four safety guards: refuses a `ProbeRoot`
  inside the repo, refuses user scope as a deploy target, refuses to
  reuse a directory lacking the `.activation-probe` marker, and tears
  down in a `finally`. Its header also documents the three traps that
  each report "nothing loaded" — undeployed platform skills, reading the
  debug log instead of the transcript, and the probe reaching for `cat`.
- `scripts/activation_expect.py` — the CLI surface only: three
  subcommands, `static --set <set> [--show-rules]`, `files --set <set>`,
  and `check --set <set> --transcript <path> --fixtures-root <path>`.
- `tests/skills/fabric-triggers/README.md` — the static-check snippet
  including the two flags that matter (`GLOBSTAR | DOTGLOB`, the latter
  required because `.platform` and `.children/` are dotted), the
  instruction to **run it a second time over `claude/rules/*.md`**
  keyed on `p.stem`, the pinned-tools probe invocation
  (`--allowedTools Read --disallowedTools Bash PowerShell Glob Grep Agent`),
  the transcript assertion (`attachment.type` of `skill_listing` with
  `isInitial` **false**), and the `control/notes.md` negative control.
- `tests/skills/code-review/README.md` — the behavioural procedure: cold
  session, the four-mode matrix (slash review / NL review / slash
  adversarial / NL adversarial), `/context` to confirm rule co-load,
  the ≥80%-of-findings pass bar, severity drift being observation-worthy
  rather than a hard fail, `git status` afterwards, and the re-run
  triggers.
- Root `CLAUDE.md` — "Validating a change", the `--safe-mode` baseline
  as the control condition, the hot-reload asymmetry (skills reload,
  subagents/commands/rules do not), and the `-SkillGroups` prune
  semantics including the 2026-08-31 bare-run incident.
- `scripts/link-claude.ps1` — the parameter block
  (`-Force`, `-ClaudeDir`, `-SkillGroups`, `-SkillsOnly`).
- `docs/handoff-briefs/execute/README.md` — wave 9 (activation is keyed
  to `Read`, not to any directory property) and wave 10 (per-session
  cumulative delta; batched attachment flushes; both groups must deploy
  for either set).

Not drilled — **nothing in this skill describes any of it**:

- **`claude --safe-mode`, `--allowedTools` and `--disallowedTools` were
  not confirmed against the Claude Code CLI documentation this run.**
  They are taken from root `CLAUDE.md` and the fixture READMEs, which
  record them as measured on 2.1.252. If a flag has been renamed
  upstream the skill will be wrong about it, and a `/drift-audit` on the
  `claude-code` CHANGELOG source is what would catch that.
- **`activation_expect.py` internals** beyond its CLI surface — the
  delta computation, the `realpath` comparison and the casing rules were
  not read. The skill treats the script as a black box with a contract.
- **The subagent and hook validation procedure**
  (`tests/agents/security-reviewer/README.md`) — out of scope by
  decision, referenced only as a pointer.
- **`expected_findings.md`'s rubric internals** — the severity
  calibration is cited as a pass bar, not re-derived.
- **The ruled-out alternatives** in `tests/skills/pbip-triggers/README.md`
  (why not the debug log, why not self-report) — cited by link rather
  than transcribed, because that file is the maintained copy.

## Frontmatter

```yaml
---
name: test-skill  # repo linter requires it; max 64 chars; lowercase/digits/hyphens
description: <see Description char count>  # gated at 1,024, the Agent Skills spec cap
argument-hint: "[skill-name]"  # autocomplete hint shown in the / menu
disable-model-invocation: false  # ALWAYS PRESENT; repo policy: false everywhere
model: inherit  # ALWAYS PRESENT; repo policy: inherit everywhere except commit
effort: max  # ALWAYS PRESENT; repo policy: max on the workflow skills that drive this repo
---
```

No `paths:` — this is invoked, not path-triggered. No `allowed-tools`:
the skill needs Bash, PowerShell, Read, Write, Edit, Glob and Grep, which
is close enough to the full set that an allowlist would only create a
maintenance burden and a failure mode when it drifts.

**`effort: max` makes seven, not six.** Root `CLAUDE.md` line 274 reads
"`effort` is `max` on the six workflow skills that drive this repo" and
names them. That line and `skills/README.md`'s Behavioral section both
need updating. `CLAUDE.md` is outside `author-skill`'s allowed edit set,
so it is flagged here rather than changed.

## Description char count

- `description`: 1,005 / 1,024
- `when_to_use`: N/A — not set

## Body structure outline

Two phases, ten numbered steps, then a failure-reading table.

1. **What this validates and what it does not** — skills only; where the
   subagent, hook and rule procedures live.
2. **Step 1 — read the brief from disk.** The input contract. Never take
   the skill's details from session context, so the skill runs cold.
   Modelled on `/drift-update`.
3. **Step 2 — pick the fixture set** from the skill's `paths:` glob:
   `fabric-triggers` or `pbip-triggers`. What to do when a skill is
   unconditional (no `paths:`) — Phase A is skipped, not faked.
4. **Step 3 — write or extend the fixtures.** Model on real exports;
   mark any fixture built on an unverified shape.
5. **Step 4 — update `expected_activations.md`.** A row reading
   *(none)* that should now name the skill **is the assertion being
   changed** — say so in the commit.
6. **Step 5 — the static check.** `-StaticOnly` first, always; it costs
   no session and the script refuses to continue past a failure anyway.
   Run the rules pass too.
7. **Step 6 — the real-path test.** `./scripts/test-activation.ps1 -Set
   <set>`. One session covers the whole set because activation is a
   delta.
8. **Step 7 — deploy for the behavioural test**, and the prune
   restoration that must follow. The single most dangerous step in the
   skill.
9. **Step 8 — the cold behavioural session.** `--safe-mode` baseline
   first, then the brief's trigger queries, then the adversarial modes
   where the skill has refusal behaviour.
10. **Step 9 — confirm fixtures unmodified.** `git status`; a run that
    edits its own inputs invalidates every later comparison.
11. **Step 10 — report and hand off to `/commit`.**
12. **Reading a failure** — a table mapping each "nothing activated"
    symptom to its real cause, since four different bugs produce
    identical output.
13. **Constraints.**

No `references/` file. Everything the skill needs is either short enough
for the body or already lives in a maintained file it links to — the two
trigger READMEs and root `CLAUDE.md`. Duplicating those here would create
a third copy to keep in sync, which is the failure this repo already hit
with `.github/copilot-instructions.md` and `AGENTS.md`.

## Changes from source proposal

Derived from a design conversation in this session rather than a written
proposal. Three decisions were put to the user and settled before
drafting:

1. **Not folded into `author-skill`.** That skill is already ten steps
   at `effort: max`, its deliverable is deliberately an unvalidated
   draft, and fixtures written for a draft that is then abandoned are
   waste.
2. **Not coupled to `author-skill` through session state.** The user's
   own instinct — "that seems a bit rigid" — matches how the rest of
   this repo works: `/drift-update` reads briefs from disk and never
   from the conversation. The coupling is the brief file.
3. **One skill, not two.** `author-fixtures` + `test-skill` was
   considered and rejected: you only ever write fixtures in order to run
   the test, and wave 10's finding is that batching into **one** cold
   session is what makes this affordable at all. Two skills would mean
   two cold sessions and a handoff that carries no decision.

## Tag

`personal`

## Portability caveats

N/A — personal scope. The skill is Windows- and PowerShell-shaped by
necessity (`test-activation.ps1`, `link-claude.ps1`) and assumes this
repo's directory layout throughout, so it is not portable by design
rather than by omission.

## Cross-reference dependencies

- `author-skill` — (a) already converted. The upstream half. Its step 9
  and its "No test fixtures" constraint should point here; that edit is
  outside this run's allowed set and is proposed separately.
- `commit` — (a) already converted. The hand-off target.
- `drift-audit` — (a) already converted. Named as what would catch a
  renamed CLI flag, per the undrilled set.
- `scripts/test-activation.ps1`, `scripts/activation_expect.py`,
  `scripts/link-claude.ps1` — (c) external/standard, in-repo tooling.
- `tests/skills/fabric-triggers/`, `tests/skills/pbip-triggers/`,
  `tests/skills/code-review/` — (c) the fixture sets it operates on.

## Claude Code's post-draft checklist

> Guidance: Reproduced verbatim in every filled brief as standing reminders. Do not edit per-brief; brief-specific observations belong in Notes below.

1. Re-verify frontmatter fields against current docs before writing.
2. Re-count description chars after drafting (Windows + Edit-tool fragility).
3. `cat` the full SKILL.md after any edit — an edit landing inside the frontmatter can leave YAML that still parses, into the wrong shape, with nothing warning.
4. If the run drafts 3+ skills, return a proposal covering all of them before writing any.

## Notes

**This skill has a bootstrapping problem and should say so.** Phase A
does not apply to `test-skill` itself: it has no `paths:` glob, so there
is no activation contract to write and no fixture set it belongs to.
Only Phase B applies. That is not a defect — it is the same reason
`author-skill` has no fixtures — but the first person to run
`/test-skill test-skill` will otherwise expect Phase A to do something.

**The prune restoration is the one step that can damage the machine.**
Everything else this skill does is confined to `tests/` and a throwaway
probe directory. Step 7 writes to `~/.claude/skills`, which serves every
session on this machine, and the documented incident (2026-08-31, a bare
`link-claude.ps1` run re-linking 37 platform skills with no error and no
wrong-looking output line) came from exactly this operation. The body
should carry the verification command, not just the warning.

**`test-activation.ps1` already refuses the dangerous shapes**, which
means the skill can lean on it rather than re-implementing guards: it
will not accept a `ProbeRoot` inside the repo, will not deploy to user
scope, and will not reuse a directory that lacks its marker file. Say
that, so a reader does not add belt-and-braces checks that duplicate the
script's.

## Confidence

- **Structure**: H. Two-phase numbered procedure, the same shape as
  `drift-update` (read from disk → checkpoint per unit → stop on first
  failure → hand off to `/commit`), which is the closest in-repo model.
- **Field specs**: H. Every command, parameter and flag was read out of
  the script or README that defines it during this run, not recalled.
- **Body content**: M-H. The mechanics are solid. The soft spot is the
  behavioural half: `tests/skills/code-review/README.md` gives a
  four-mode matrix that is specific to a skill with refusal behaviour,
  and generalising it to *any* skill is an editorial judgement this
  brief makes rather than a procedure the repo has already validated.
- **CLI flags**: M. See the undrilled set — `--safe-mode`,
  `--allowedTools` and `--disallowedTools` are carried forward from
  in-repo notes dated 2026-09-01/02 on 2.1.252, not re-confirmed against
  upstream documentation this run.
