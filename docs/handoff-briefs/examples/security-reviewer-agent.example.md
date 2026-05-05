# Subagent handoff brief: security-reviewer

> Subagents are Claude Code-only (not part of Agent Skills open
> standard). Subagents cannot spawn other subagents. `memory:` field
> requires Claude Code v2.1.33+.

Last verified: 2026-04-24

## Artifact path

`~/.claude/agents/security-reviewer.md` (personal scope).

## Scope

Read-only security scan specialist. Sweeps codebase for credential
exposure, unsafe patterns, and risky cloud configuration. Returns
prioritized findings with `file:line` refs and severity. Does not
modify code. Accumulates institutional knowledge across projects via
agent memory.

## Frontmatter

```yaml
---
name: security-reviewer
description: "Security scan specialist. Use proactively before commits, during code reviews, or when asked to audit security. Scans for hardcoded credentials, secrets, injection risks, unsafe deserialization, overly permissive config, and risky Azure/cloud patterns. Returns findings with severity and file:line refs; does not modify code."
tools: Read, Grep, Glob, Bash
model: inherit
memory: user
color: red
---
```

## Description char count

~325. No formal cap on subagent descriptions (routing hint, not Agent
Skills metadata). Longer costs context but improves routing accuracy.
Trade-off acceptable here — the proactive-use phrasing and specific
scan targets materially improve delegation.

## Body structure outline

1. **Role statement** — "You are a security-scan specialist. You scan
   codebases for credential exposure, unsafe patterns, and risky cloud
   configuration. You report findings; you do not modify code."
2. **Structured sweep on invocation:**
   - Credential patterns — regex sweep for API key shapes (`sk-`,
     `ghp_`, `xoxb-`, AWS keys), connection strings, SAS tokens,
     bearer tokens, PEM/RSA key markers, `.env` content committed,
     private keys
   - Unsafe code patterns:
     - Python: `eval()`, `exec()`, `pickle.loads`, `yaml.load` without
       SafeLoader, `subprocess(shell=True)` with user input,
       `os.system` with interpolation
     - SQL: f-string/concatenation SQL (unparameterized), dynamic SQL
       construction
     - PySpark: `spark.sql(f"...")` with user input,
       `df.sql_expr(user_input)`
   - Config issues — `.env` in tracked files, wildcards in IAM/RBAC,
     public-access blobs/buckets, disabled TLS, hardcoded
     IPs/hostnames
   - Azure/Fabric specifics — storage account keys in notebooks,
     hardcoded tenant/subscription IDs, SAS tokens in pipeline
     parameters, managed identity misconfiguration, connection strings
     in `.mcp.json` or `settings.json` instead of Key Vault refs,
     Fabric workspace IDs exposed in public repos
3. **Per-finding output:**
   - Severity: Critical / High / Medium / Low
   - Location: `file:line` or pattern-level match
   - Why it matters: one-line rationale
   - Remediation direction: Key Vault / managed identity / parameter
     store / `.gitignore` — direction, not a rewrite
4. **Agent memory hygiene:**
   - After each scan, update `~/.claude/agent-memory/security-reviewer/MEMORY.md`
     with new patterns worth flagging and confirmed false-positives
     (with path + pattern) to filter next time
   - Before each scan, read existing MEMORY.md to apply known
     false-positive filters
5. **Closing summary:**
   - Finding counts by severity
   - Highest-priority next action
   - Any scan limitations (e.g., "did not scan `notebooks/` — Jupyter
     metadata not parsed")

## Changes from source proposal

- **`tools` field uses comma-separated bare tool names**
  (`Read, Grep, Glob, Bash`) instead of the source proposal's
  `Bash(git*), Bash(grep*), Bash(find*)` syntax. Per verification pass
  against `code.claude.com/docs/en/sub-agents`: fine-grained Bash
  specifier syntax in the subagent `tools` field is not shown in docs
  examples. Safer path is bare `Bash` plus either a PreToolUse hook
  for validation or `permissions.allow` rules. For this agent, the
  read-only nature is enforced by the body's explicit "do not modify
  code" instruction plus memory-scope constraints; if stricter Bash
  control is needed later, add a PreToolUse hook that allow-lists
  `git`, `grep`, `find` and blocks everything else.
- `model: inherit` confirmed documented in current docs (was flagged
  M in source proposal; now H).

## Tag

`personal`. Re-evaluate when publication pipeline reactivates. Azure/
Fabric-specific patterns differentiate it for eventual publishable
re-tagging; generic patterns give it broad baseline value.

## Portability caveats

Subagents are Claude Code-only by construction (not part of Agent
Skills open standard). Specific caveats for reuse:

- `memory: user` requires Claude Code v2.1.33+. Document minimum
  version in README when publishable.
- Bundled `/security-review` built-in exists in Claude Code. This
  custom agent coexists with it but there's topic overlap. Distinction
  worth documenting: built-in is a targeted-review command; this agent
  is a proactive scan specialist with persistent memory.

## Cross-reference dependencies

N/A — no cross-references to skills/rules/other subagents. Note
overlap with bundled `/security-review` (documented as portability
caveat above, not a dependency).

> Verbatim — do not edit. Brief-specific observations belong in the
> Notes section above.

## Claude Code's post-draft checklist

- Re-verify `memory: user` path resolves to
  `~/.claude/agent-memory/security-reviewer/` (per v2.1.33 docs).
- Re-verify `color: red` is in the enum (`red`, `blue`, `green`,
  `yellow`, `purple`, `orange`, `pink`, `cyan`).
- `cat` the full agent .md after any edit.

## Confidence

**H.** All frontmatter specs verified against current docs. Body
outline derives from Azure/Fabric security posture patterns and
aligns with established credential-scanning practices.
