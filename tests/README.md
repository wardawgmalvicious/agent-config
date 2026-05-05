# Tests

Synthetic fixtures for validating skills and subagents in this repo.
Run manually; not wired into CI.

## Layout

- [skills/code-review/](skills/code-review/) — fixtures for the
  [code-review skill](../skills/code-review/SKILL.md). Synthetic files
  with seeded issues across Python, PySpark, T-SQL, Spark SQL, KQL,
  DAX, TMDL, and Fabric pipeline expressions. Each fixture has a
  paired entry in [expected_findings.md](skills/code-review/expected_findings.md)
  describing what the skill should catch.
- [agents/security-reviewer/](agents/security-reviewer/) — fixtures
  for the [security-reviewer agent](../agents/security-reviewer.md).
  Synthetic files with seeded credential exposure, injection, and
  recon patterns matching the agent's sweep categories.

Each test directory has its own `README.md` documenting the validation
procedure.

## What's tested

**Skill fixtures** cover invocation modes (slash and NL) as separate
behavioral contracts, severity rubric adherence, refusal patterns
under "fix this" follow-ups, and path-scoped rule co-loading
(`coding-<lang>.md`).

**Agent fixtures** cover the enforcement floors that gate behavior:
refusal language, the PreToolUse hook block on out-of-scope writes,
memory hygiene (pre-scan read of `MEMORY.md`, post-scan update,
self-attestation), and the scripted "I report findings; remediation
is yours to apply." line.

Test fixtures contain intentional credential-shaped strings — the
[gitleaks allowlist](../.gitleaks.toml) excludes `tests/` from the
hardcoded-secrets check.
