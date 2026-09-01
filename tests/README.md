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
- [skills/pbip-triggers/](skills/pbip-triggers/) — a minimal but
  structurally real PBIP project used to test **`paths:` activation**:
  which conditional skills load when a given file enters session scope.
  Covers ten of the payload's 19 conditional skills. Assertions live in
  [expected_activations.md](skills/pbip-triggers/expected_activations.md);
  the load-bearing one is that `visual.json` does *not* pull in
  `pbip-project-structure`.
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

**Trigger fixtures** (`skills/pbip-triggers/`) cover a different
contract: whether a skill fires at all. Note that **no log on this
machine records conditional skill activation** — `instructions-loaded.log`
tracks rules and `CLAUDE.md`, while `skills-invoked.log` and `skillUsage`
count *invocations*, and a path-triggered skill is loaded rather than
invoked. Verify by observing what is in context, never by reading a
counter.

**Agent fixtures** cover the enforcement floors that gate behavior:
refusal language, the PreToolUse hook block on out-of-scope writes,
memory hygiene (pre-scan read of `MEMORY.md`, post-scan update,
self-attestation), and the scripted "I report findings; remediation
is yours to apply." line.

Test fixtures contain intentional credential-shaped strings — the
[gitleaks allowlist](../.gitleaks.toml) excludes `tests/` from the
hardcoded-secrets check.
