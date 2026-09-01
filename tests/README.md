# Tests

Synthetic fixtures for validating skills and subagents in this repo.
Run manually; not wired into CI.

## Layout

- [skills/code-review/](skills/code-review/) — fixtures for the
  [code-review skill](../skills/workflow/code-review/SKILL.md). Synthetic files
  with seeded issues across Python, PySpark, T-SQL, Spark SQL, KQL,
  DAX, TMDL, and Fabric pipeline expressions. Each fixture has a
  paired entry in [expected_findings.md](skills/code-review/expected_findings.md)
  describing what the skill should catch.
- [skills/pbip-triggers/](skills/pbip-triggers/) and
  [skills/fabric-triggers/](skills/fabric-triggers/) — minimal but
  structurally real PBIP projects and Fabric item folders, used to test
  **`paths:` activation**: which conditional skills load when a given
  file enters session scope. Disjoint by design — 9 skills in the first,
  10 in the second, which is all 19 conditional skills in the payload.
  Assertions live in each set's `expected_activations.md`; the
  load-bearing ones are the two halves of the A1 fix — `visual.json`
  must *not* pull `pbip-project-structure`, and neither may a
  `.platform` outside a `.Report`/`.SemanticModel` folder.
- [agents/security-reviewer/](agents/security-reviewer/) — fixtures
  for the [security-reviewer agent](../claude/agents/security-reviewer.md).
  Synthetic files with seeded credential exposure, injection, and
  recon patterns matching the agent's sweep categories.

Each test directory has its own `README.md` documenting the validation
procedure.

## What's tested

**Skill fixtures** cover invocation modes (slash and NL) as separate
behavioral contracts, severity rubric adherence, refusal patterns
under "fix this" follow-ups, and path-scoped rule co-loading
(`coding-<lang>.md`).

**Trigger fixtures** (`skills/pbip-triggers/`,
`skills/fabric-triggers/`) cover a different contract: whether a skill
fires at all. Note that **no log on this
machine records conditional skill activation** — `instructions-loaded.log`
tracks rules and `CLAUDE.md`, while `skills-invoked.log` and `skillUsage`
count *invocations*, and a path-triggered skill is loaded rather than
invoked. Verify by observing what is in context, never by reading a
counter.

The cheap regression test is the static glob check in either trigger
README — it needs no session and catches a broken glob directly. A cold
session only proves the harness agrees with the globs.

**Agent fixtures** cover the enforcement floors that gate behavior:
refusal language, the PreToolUse hook block on out-of-scope writes,
memory hygiene (pre-scan read of `MEMORY.md`, post-scan update,
self-attestation), and the scripted "I report findings; remediation
is yours to apply." line.

Test fixtures contain intentional credential-shaped strings — the
[gitleaks allowlist](../.gitleaks.toml) excludes `tests/` from the
hardcoded-secrets check.
