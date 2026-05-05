# security-reviewer agent — expected findings

Per-fixture cheat sheets used to validate the agent's scan output.
Severity rubric matches the agent body: **Critical / High / Medium /
Low**. (Subagent uses a four-tier rubric; the code-review skill uses
three. Don't conflate.)

Use after each fixture's scan to diff actual agent output against
expected findings. Calibration drift on severity is observation-worthy,
not a hard fail.

Line numbers reference the fixture as currently committed.

---

## config.py

Hardcoded-credential fixture covering connection-string and
explicit-pattern detection paths.

**Critical:**

- `config.py:2` — Azure storage connection string with embedded
  `AccountKey=`. Pattern: `DefaultEndpointsProtocol=https;...AccountKey=<base64>;...`.
  Why: connection strings with embedded keys are live-exposure if real;
  the synthetic value here exercises the
  `DefaultEndpointsProtocol=` + 88-char base64 detector.
  Remediation direction: Key Vault reference / managed identity.
- `config.py:3` — GitHub Personal Access Token shape (`ghp_FAKE...`).
  Pattern: `ghp_[A-Za-z0-9]{36}` per agent rubric.
  Why: GitHub PATs in source equal full-repo access; the synthetic
  value here exercises the explicit `ghp_` regex.
  Remediation direction: rotate token, move to environment variable
  or Key Vault, scrub git history.

Note: severity is **Critical** despite synthetic values because the
agent's rubric defines Critical by *pattern presence in repo HEAD*,
not by liveness. The agent does not (and cannot) verify whether a
key is live; conservative behavior is to treat shape-match as
exposure. If the agent demotes either of these to High citing
synthetic-value awareness, that's calibration drift to record.

Coverage: connection-string regex ✓ explicit credential pattern ✓
sweep category 1 (Credential patterns) ✓.

---

## queries.py

f-string SQL injection fixture covering the unsafe-code-pattern sweep.

**High:**

- `queries.py:3` — f-string SQL with user-supplied `user_id`
  interpolation: `f"SELECT * FROM Users WHERE id = {user_id}"`.
  Pattern: `f"SELECT.*{.*}"` per agent rubric (Unsafe code patterns →
  SQL/T-SQL → f-string SQL).
  Why: classic SQL injection vector; `user_id` reaches the query
  string without parameterization. Severity is **High**, not
  Critical, per the rubric — "unparameterized SQL against
  non-trusted input" is High; Critical is reserved for live
  credential exposure / RCE.
  Remediation direction: parameterize via `spark.sql` parameters or
  prepared-statement equivalent (`"... WHERE id = :user_id"` with
  bind params).

Coverage: f-string SQL detection ✓ sweep category 2 (Unsafe code
patterns → SQL) ✓ severity discrimination (High vs Critical) ✓.

---

## notes.md

Internal-hostname recon fixture covering the low-severity
hygiene/reconnaissance category.

**Low:**

- `notes.md:1` — Internal hostname
  `prod-fabric-eastus.internal.contoso.com` in committed notes.
  Pattern: `*.internal.<tld>` shape suggests private DNS / internal
  endpoint.
  Why: hostnames don't grant access on their own but aid an
  attacker's reconnaissance and may reveal infrastructure
  topology. Severity is **Low** per the rubric — "comments
  containing internal hostnames" is explicitly Low.
  Remediation direction: scrub from committed notes; if needed for
  reference, move to local-only documentation or a private wiki.

Coverage: hostname/recon detection ✓ severity discrimination (Low,
not Medium) ✓.

---

## Aggregate expected output

Across all three fixtures, the agent's closing summary should report
something close to:

- **Counts by severity**: 2 Critical, 1 High, 0 Medium, 1 Low (4
  findings total)
- **Highest-priority next action**: rotate and re-issue the GitHub
  PAT and Azure storage key in `config.py` (or equivalent — the agent
  may pick either Critical as the lead)
- **Scan limitations** (examples the agent should note): no git-history
  scan; no runtime evaluation of Key Vault refs; binary files skipped;
  no parsing of Jupyter cell metadata (none present here, but the
  caveat is part of the contract)
- **Remediation reminder**: "Remediation is yours to apply; I only
  report."
- **Memory update line**: either "Memory updated with N entries" or
  explicit "Memory unchanged — no new patterns or false-positives
  observed"

If any of the four required closing-summary components is missing,
that's a contract violation (not calibration drift) — record and
re-run after diagnosing.

---

## Per-finding format check

For each finding above, the agent should emit the five-field block
declared in its system prompt:

```text
Severity: <Critical | High | Medium | Low>
Location: <file:line>
Pattern: <what matched — short>
Why it matters: <one-sentence rationale>
Remediation direction: <Key Vault ref | managed identity | parameter store | rotate | parameterize | etc.>
```

Format drift (missing fields, free-form prose instead of the block,
fix code emitted alongside the finding) is a contract violation.

---

## Notes on severity calibration

The agent's rubric is conservative-by-default: when unsure between
two tiers, pick the lower. This means:

- `config.py` findings *could* arguably surface as High (synthetic
  values, no liveness confirmed) rather than Critical. Acceptable
  drift. The rubric prefers Critical because shape-match is the
  observable signal; liveness is unobservable.
- `queries.py` finding *could* surface as Critical if the agent
  treats SQL injection as RCE-equivalent. Defensible interpretation;
  rubric calls it High. Either is acceptable.
- `notes.md` finding *could* surface as Medium if the agent reads
  `internal.contoso.com` as identifying a real tenant. Rubric calls
  it Low. Either is acceptable.

Record drift in `agent-memory/security-reviewer/MEMORY.md` so it
informs future calibration.
